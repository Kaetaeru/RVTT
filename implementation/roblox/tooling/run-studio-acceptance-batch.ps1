[CmdletBinding()]
param(
    [string]$ExpectedHead = "",
    [string]$Project = "",
    [switch]$NoOpen,
    [switch]$Refresh,
    [switch]$SelfTest
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$Repository = "Kaetaeru/RVTT"
$Branch = "planning/rvtt-remake"
$PreferredRepo = "C:\Users\somsn\RVTT"
$ManifestUrl = "https://raw.githubusercontent.com/$Repository/$Branch/implementation/roblox/acceptance-batch.json"
$CacheRoot = if ($env:LOCALAPPDATA) { Join-Path $env:LOCALAPPDATA "RVTT\AcceptanceBootstrap" } else { Join-Path ([IO.Path]::GetTempPath()) "RVTT-AcceptanceBootstrap" }

function Step([string]$Text) { Write-Host "[RVTT Bootstrap] $Text" -ForegroundColor Cyan }
function Native([string]$Name) { if ($LASTEXITCODE -ne 0) { throw "$Name failed · exitCode=$LASTEXITCODE" } }
function Json([string]$Path) { Get-Content -Raw -Encoding UTF8 $Path | ConvertFrom-Json }
function Download([string]$Url, [string]$Path) {
    New-Item -ItemType Directory -Force (Split-Path -Parent $Path) | Out-Null
    $tmp = "${Path}.partial"
    $errorRecord = $null
    for ($attempt = 1; $attempt -le 3; $attempt++) {
        try {
            Remove-Item $tmp -Force -ErrorAction SilentlyContinue
            Invoke-WebRequest -UseBasicParsing -Uri $Url -OutFile $tmp -TimeoutSec 120
            if ((Get-Item $tmp).Length -le 0) { throw "empty download" }
            Move-Item -Force $tmp $Path
            return
        } catch {
            $errorRecord = $_
            if ($attempt -lt 3) { Start-Sleep -Seconds 2 }
        }
    }
    throw "download failed · url=$Url · error=$errorRecord"
}
function ValidateManifest($Manifest) {
    foreach ($field in @("schemaVersion", "repository", "branch", "verifiedHead", "project", "rojo")) {
        if ($null -eq $Manifest.PSObject.Properties[$field]) { throw "acceptance-batch.json missing $field" }
    }
    if ($Manifest.schemaVersion -ne 1) { throw "unsupported acceptance manifest schema" }
    if ([string]$Manifest.verifiedHead -notmatch "^[0-9a-f]{40}$") { throw "verifiedHead must be a full commit SHA" }
}
function Manifest() {
    $cached = Join-Path $CacheRoot "acceptance-batch.json"
    try {
        $candidate = "${cached}.remote"
        Step "fetching verified acceptance manifest"
        Download $ManifestUrl $candidate
        $value = Json $candidate
        ValidateManifest $value
        Move-Item -Force $candidate $cached
        return $value
    } catch {
        $localManifest = Join-Path $PreferredRepo "implementation\roblox\acceptance-batch.json"
        if (Test-Path $localManifest) {
            Write-Warning "network unavailable; using manifest from $PreferredRepo"
            $value = Json $localManifest
            ValidateManifest $value
            return $value
        }
        if ($PSScriptRoot) {
            $local = Join-Path (Split-Path -Parent $PSScriptRoot) "acceptance-batch.json"
            if (Test-Path $local) {
                Write-Warning "network unavailable; using local acceptance manifest"
                $value = Json $local
                ValidateManifest $value
                return $value
            }
        }
        if (Test-Path $cached) {
            Write-Warning "network unavailable; using Offline cache"
            $value = Json $cached
            ValidateManifest $value
            return $value
        }
        throw
    }
}
function Arch() {
    $value = if ($env:PROCESSOR_ARCHITEW6432) { $env:PROCESSOR_ARCHITEW6432 } else { $env:PROCESSOR_ARCHITECTURE }
    if ($value -match "ARM64") { "windowsArm64" } else { "windowsX64" }
}
function Rojo($Manifest) {
    $architecture = Arch
    $asset = $Manifest.rojo.assets.$architecture
    $root = Join-Path $CacheRoot "tools\rojo-$($Manifest.rojo.version)-$architecture"
    $exe = Join-Path $root "rojo.exe"
    if ($Refresh) { Remove-Item $root -Recurse -Force -ErrorAction SilentlyContinue }
    if (Test-Path $exe) {
        $version = (& $exe --version 2>&1 | Out-String).Trim()
        if ($LASTEXITCODE -eq 0 -and $version -match [regex]::Escape([string]$Manifest.rojo.version)) { return $exe }
        Remove-Item $root -Recurse -Force -ErrorAction SilentlyContinue
    }
    $installed = Get-Command rojo -ErrorAction SilentlyContinue
    if ($installed) {
        $version = (& $installed.Source --version 2>&1 | Out-String).Trim()
        if ($LASTEXITCODE -eq 0 -and $version -match [regex]::Escape([string]$Manifest.rojo.version)) { return $installed.Source }
    }
    Step "installing pinned Rojo $($Manifest.rojo.version)"
    $zip = Join-Path $CacheRoot "downloads\$([IO.Path]::GetFileName([string]$asset.url))"
    Download ([string]$asset.url) $zip
    $hash = (Get-FileHash $zip -Algorithm SHA256).Hash.ToLowerInvariant()
    if ($hash -ne ([string]$asset.sha256).ToLowerInvariant()) { throw "Rojo SHA256 mismatch" }
    $extract = "${root}.extracting"
    Remove-Item $extract -Recurse -Force -ErrorAction SilentlyContinue
    Expand-Archive $zip $extract -Force
    $found = Get-ChildItem $extract -Filter rojo.exe -File -Recurse | Select-Object -First 1
    if (-not $found) { throw "rojo.exe missing from downloaded archive" }
    New-Item -ItemType Directory -Force $root | Out-Null
    Copy-Item -Force $found.FullName $exe
    Remove-Item $extract -Recurse -Force
    return $exe
}
function FindLocalRepo() {
    $candidates = @($PreferredRepo)
    if ($HOME) {
        $homeRepo = Join-Path $HOME "RVTT"
        if ($homeRepo -ne $PreferredRepo) { $candidates += $homeRepo }
    }
    $current = (Get-Location).Path
    if ($current -notin $candidates) { $candidates += $current }
    foreach ($candidate in $candidates) {
        if ((Test-Path (Join-Path $candidate ".git")) -and (Test-Path (Join-Path $candidate "implementation\roblox"))) {
            return [IO.Path]::GetFullPath($candidate)
        }
    }
    return $null
}
function SourceFromLocalRepo([string]$Head, [string]$RepoRoot, [string]$Destination) {
    $git = Get-Command git -ErrorAction SilentlyContinue
    if (-not $git) { return $false }

    Step "using local repository $RepoRoot"
    Set-Location $RepoRoot

    & $git.Source -C $RepoRoot cat-file -e "${Head}^{commit}" 2>$null
    if ($LASTEXITCODE -ne 0) {
        Step "fetching verified commit into local repository"
        & $git.Source -C $RepoRoot fetch origin $Branch --prune
        if ($LASTEXITCODE -ne 0) {
            Write-Warning "branch fetch failed; trying exact verified Head"
            & $git.Source -C $RepoRoot fetch origin $Head
        }
        & $git.Source -C $RepoRoot cat-file -e "${Head}^{commit}" 2>$null
        if ($LASTEXITCODE -ne 0) { return $false }
    }

    $zip = Join-Path $CacheRoot "downloads\RVTT-local-$Head.zip"
    Remove-Item $zip -Force -ErrorAction SilentlyContinue
    New-Item -ItemType Directory -Force (Split-Path -Parent $zip) | Out-Null
    & $git.Source -C $RepoRoot archive --format=zip --output=$zip $Head
    if ($LASTEXITCODE -ne 0 -or -not (Test-Path $zip)) { return $false }

    Remove-Item $Destination -Recurse -Force -ErrorAction SilentlyContinue
    New-Item -ItemType Directory -Force $Destination | Out-Null
    Expand-Archive $zip $Destination -Force
    if (-not (Test-Path (Join-Path $Destination "implementation\roblox"))) {
        Remove-Item $Destination -Recurse -Force -ErrorAction SilentlyContinue
        return $false
    }
    Set-Content -Encoding ASCII (Join-Path $Destination ".rvtt-source-ready") $Head
    return $true
}
function Source([string]$Head) {
    $root = Join-Path $CacheRoot "sources\$Head"
    $ready = Join-Path $root ".rvtt-source-ready"
    if ($Refresh) { Remove-Item $root -Recurse -Force -ErrorAction SilentlyContinue }
    if ((Test-Path $ready) -and (Test-Path (Join-Path $root "implementation\roblox"))) { return $root }

    $localRepo = FindLocalRepo
    if ($localRepo) {
        if (SourceFromLocalRepo $Head $localRepo $root) { return $root }
        Write-Warning "local repository could not provide verified Head; falling back to remote archive"
    }

    Step "downloading isolated verified source $Head"
    $zip = Join-Path $CacheRoot "downloads\RVTT-$Head.zip"
    Download "https://github.com/$Repository/archive/$Head.zip" $zip
    $extract = Join-Path $CacheRoot "extracting\$Head"
    Remove-Item $extract -Recurse -Force -ErrorAction SilentlyContinue
    Expand-Archive $zip $extract -Force
    $first = Get-ChildItem $extract -Directory | Select-Object -First 1
    if (-not $first -or -not (Test-Path (Join-Path $first.FullName "implementation\roblox"))) { throw "verified source archive is incomplete" }
    New-Item -ItemType Directory -Force (Split-Path -Parent $root) | Out-Null
    Remove-Item $root -Recurse -Force -ErrorAction SilentlyContinue
    Move-Item $first.FullName $root
    Set-Content -Encoding ASCII $ready $Head
    Remove-Item $extract -Recurse -Force -ErrorAction SilentlyContinue
    return $root
}
function TryPythonValidator([string]$Executable, [string[]]$Arguments) {
    try {
        $global:LASTEXITCODE = 0
        & $Executable @Arguments
        if ($LASTEXITCODE -eq 0) { return $true }
        Write-Warning "Python validator unavailable or failed · executable=$Executable exitCode=$LASTEXITCODE"
    } catch {
        Write-Warning "Python validator could not start · executable=$Executable error=$($_.Exception.Message)"
    }
    return $false
}
function Validate([string]$RobloxRoot, [string]$ProjectName) {
    $validator = Join-Path $RobloxRoot "tooling\validate_implementation.py"
    $python = Get-Command python -ErrorAction SilentlyContinue
    $py = Get-Command py -ErrorAction SilentlyContinue
    if ($python -and (TryPythonValidator $python.Source @($validator))) { return }
    if ($py -and (TryPythonValidator $py.Source @("-3", $validator))) { return }

    Step "Python unavailable or unusable; using built-in validator"
    Get-Content -Raw -Encoding UTF8 (Join-Path $RobloxRoot $ProjectName) | ConvertFrom-Json | Out-Null
    foreach ($path in @("src\ServerScriptService\RVTT\ServerBoot.server.lua", "src\StarterPlayer\StarterPlayerScripts\RVTT\ClientBoot.client.lua", "tests\WorldTokenAcceptance\WorldTokenAcceptance.client.lua")) {
        if (-not (Test-Path (Join-Path $RobloxRoot $path))) { throw "fallback validator missing $path" }
    }
}
function StopStudio() {
    $running = @(Get-Process -Name RobloxStudioBeta,RobloxStudio -ErrorAction SilentlyContinue)
    if ($running.Count) { Step "closing existing Roblox Studio"; $running | Stop-Process -Force; Start-Sleep -Seconds 2 }
}
function Studio() {
    $root = Join-Path $env:LOCALAPPDATA "Roblox\Versions"
    if (Test-Path $root) {
        $exe = Get-ChildItem $root -Filter RobloxStudioBeta.exe -File -Recurse -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 1
        if ($exe) { return $exe.FullName }
    }
    return $null
}
function RunSelfTest() {
    if (-not $PSScriptRoot) { throw "SelfTest requires file execution" }
    $value = Json (Join-Path (Split-Path -Parent $PSScriptRoot) "acceptance-batch.json")
    ValidateManifest $value
    foreach ($key in @("windowsX64", "windowsArm64")) {
        if ([string]$value.rojo.assets.$key.sha256 -notmatch "^[0-9a-f]{64}$") { throw "invalid $key Rojo hash" }
    }
    if ($PreferredRepo -ne "C:\Users\somsn\RVTT") { throw "preferred repository path contract changed" }
    Write-Host "RVTT acceptance bootstrap SelfTest passed" -ForegroundColor Green
}

if ($SelfTest) { RunSelfTest; return }
if ([Environment]::OSVersion.Platform -ne [PlatformID]::Win32NT) { throw "Windows with Roblox Studio is required" }
New-Item -ItemType Directory -Force $CacheRoot | Out-Null
$manifest = Manifest
$head = [string]$manifest.verifiedHead
if ($ExpectedHead) {
    if (-not $head.StartsWith($ExpectedHead, [StringComparison]::OrdinalIgnoreCase)) { $head = $ExpectedHead }
}
if (-not $Project) { $Project = [string]$manifest.project }
$sourceRoot = Source $head
$robloxRoot = Join-Path $sourceRoot "implementation\roblox"
if (-not (Test-Path (Join-Path $robloxRoot $Project))) { throw "Rojo Project not found: $Project" }
Validate $robloxRoot $Project
$rojo = Rojo $manifest
StopStudio

$short = $head.Substring(0, [Math]::Min(12, $head.Length))
$slug = [IO.Path]::GetFileNameWithoutExtension($Project).Replace(".project", "")
$outputRoot = Join-Path ([IO.Path]::GetTempPath()) "RVTT-Acceptance"
New-Item -ItemType Directory -Force $outputRoot | Out-Null
$output = Join-Path $outputRoot "RVTT-$slug-$short.rbxlx"
$report = Join-Path $outputRoot "RVTT-$slug-$short-manifest.txt"
Remove-Item $output -Force -ErrorAction SilentlyContinue
Step "rojo build $Project from verified Head $short"
Push-Location $robloxRoot
try { & $rojo build $Project --output $output; Native "rojo build" } finally { Pop-Location }
@"
RVTT Studio Acceptance Batch
Generated: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss K")
Verified Head: $head
Project: $Project
Place: $output
Source Cache: $sourceRoot
Preferred Repository: $PreferredRepo

Bootstrap: starts from C:\Users\somsn\RVTT when available; verified Git archive isolates Dirty Worktree; Python failure falls back to built-in validation; pinned Rojo SHA256 verified; Offline cache enabled.
"@ | Set-Content -Encoding UTF8 $report
Write-Host "RVTT Acceptance Batch ready`n  Head: $head`n  Place: $output`n  Manifest: $report" -ForegroundColor Green
if (-not $NoOpen) {
    $studio = Studio
    if ($studio) { Start-Process $studio -ArgumentList "`"$output`"" }
    else { try { Start-Process $output } catch { throw "Roblox Studio is not installed or .rbxlx is not associated · $output" } }
}
