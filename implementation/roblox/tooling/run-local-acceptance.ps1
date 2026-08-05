[CmdletBinding()]
param(
    [switch]$NoOpen,
    [switch]$SelfTest
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$RepoRoot = "C:\Users\somsn\RVTT"
$Branch = "planning/rvtt-remake"
$ManifestPath = "implementation/roblox/acceptance-batch.json"
$CacheRoot = if ($env:LOCALAPPDATA) {
    Join-Path $env:LOCALAPPDATA "RVTT\LocalAcceptance"
} else {
    Join-Path ([IO.Path]::GetTempPath()) "RVTT-LocalAcceptance"
}

function Step([string]$Text) {
    Write-Host "[RVTT Local] $Text" -ForegroundColor Cyan
}

function Invoke-NativeChecked {
    param(
        [string]$Executable,
        [string[]]$Arguments,
        [switch]$Quiet
    )

    $global:LASTEXITCODE = 0
    if ($Quiet) {
        & $Executable @Arguments *> $null
    } else {
        & $Executable @Arguments 2>&1 | ForEach-Object { Write-Host $_ }
    }
    $exitCode = $LASTEXITCODE
    if ($exitCode -ne 0) {
        throw "native command failed · executable=$Executable · exitCode=$exitCode · args=$($Arguments -join ' ')"
    }
}

function Download-File {
    param([string]$Url, [string]$Destination)

    New-Item -ItemType Directory -Force (Split-Path -Parent $Destination) | Out-Null
    $partial = "${Destination}.partial"
    $lastError = $null
    for ($attempt = 1; $attempt -le 3; $attempt++) {
        try {
            Remove-Item $partial -Force -ErrorAction SilentlyContinue
            Invoke-WebRequest -UseBasicParsing -Uri $Url -OutFile $partial -TimeoutSec 120
            if ((Get-Item -LiteralPath $partial).Length -le 0) {
                throw "downloaded file is empty"
            }
            Move-Item -Force $partial $Destination
            return
        } catch {
            $lastError = $_
            if ($attempt -lt 3) {
                Start-Sleep -Seconds 2
            }
        }
    }
    throw "download failed · url=$Url · error=$lastError"
}

function Resolve-GitPath {
    $commands = @(Get-Command git.exe -CommandType Application -All -ErrorAction SilentlyContinue)
    foreach ($command in $commands) {
        $candidate = [string]$command.Source
        if (-not [string]::IsNullOrWhiteSpace($candidate) -and (Test-Path -LiteralPath $candidate)) {
            return [IO.Path]::GetFullPath($candidate)
        }
    }
    throw "git.exe를 찾지 못했습니다."
}

function Read-RemoteManifest {
    param([string]$GitPath)

    Step "fetching $Branch"
    Invoke-NativeChecked $GitPath @("-C", $RepoRoot, "fetch", "origin", $Branch, "--prune")

    $global:LASTEXITCODE = 0
    $manifestText = (& $GitPath -C $RepoRoot show "origin/${Branch}:$ManifestPath" 2>&1 | Out-String)
    if ($LASTEXITCODE -ne 0) {
        throw "acceptance manifest를 읽지 못했습니다 · exitCode=$LASTEXITCODE"
    }

    $manifest = $manifestText | ConvertFrom-Json
    if ([string]$manifest.verifiedHead -notmatch "^[0-9a-f]{40}$") {
        throw "acceptance manifest의 verifiedHead가 잘못되었습니다."
    }
    if ([string]::IsNullOrWhiteSpace([string]$manifest.project)) {
        throw "acceptance manifest의 project가 비어 있습니다."
    }
    return $manifest
}

function Ensure-VerifiedSource {
    param(
        [string]$GitPath,
        [string]$Head
    )

    Invoke-NativeChecked $GitPath @("-C", $RepoRoot, "cat-file", "-e", "${Head}^{commit}") -Quiet

    $sourceRoot = Join-Path $CacheRoot "sources\$Head"
    $ready = Join-Path $sourceRoot ".rvtt-source-ready"
    if ((Test-Path -LiteralPath $ready) -and (Test-Path -LiteralPath (Join-Path $sourceRoot "implementation\roblox"))) {
        return [IO.Path]::GetFullPath($sourceRoot)
    }

    Step "extracting verified source $Head from $RepoRoot"
    $zip = Join-Path $CacheRoot "downloads\RVTT-$Head.zip"
    $extract = Join-Path $CacheRoot "extracting\$Head"
    Remove-Item $zip -Force -ErrorAction SilentlyContinue
    Remove-Item $extract -Recurse -Force -ErrorAction SilentlyContinue
    New-Item -ItemType Directory -Force (Split-Path -Parent $zip) | Out-Null
    New-Item -ItemType Directory -Force $extract | Out-Null

    Invoke-NativeChecked $GitPath @("-C", $RepoRoot, "archive", "--format=zip", "--output=$zip", $Head) -Quiet
    Expand-Archive -LiteralPath $zip -DestinationPath $extract -Force

    if (-not (Test-Path -LiteralPath (Join-Path $extract "implementation\roblox"))) {
        throw "검증 Source archive가 불완전합니다."
    }

    Remove-Item $sourceRoot -Recurse -Force -ErrorAction SilentlyContinue
    New-Item -ItemType Directory -Force (Split-Path -Parent $sourceRoot) | Out-Null
    Move-Item $extract $sourceRoot
    Set-Content -Encoding ASCII -Path $ready -Value $Head
    return [IO.Path]::GetFullPath($sourceRoot)
}

function Validate-Source {
    param(
        [string]$RobloxRoot,
        [string]$Project
    )

    Step "running built-in validation"
    $projectPath = Join-Path $RobloxRoot $Project
    Get-Content -Raw -Encoding UTF8 $projectPath | ConvertFrom-Json | Out-Null

    foreach ($relative in @(
        "src\ServerScriptService\RVTT\ServerBoot.server.lua",
        "src\StarterPlayer\StarterPlayerScripts\RVTT\ClientBoot.client.lua",
        "tests\WorldTokenAcceptance\WorldTokenAcceptance.client.lua"
    )) {
        if (-not (Test-Path -LiteralPath (Join-Path $RobloxRoot $relative))) {
            throw "필수 파일이 없습니다: $relative"
        }
    }
}

function Resolve-RojoPath {
    param($Manifest)

    $architecture = if (($env:PROCESSOR_ARCHITEW6432 -match "ARM64") -or ($env:PROCESSOR_ARCHITECTURE -match "ARM64")) {
        "windowsArm64"
    } else {
        "windowsX64"
    }
    $asset = $Manifest.rojo.assets.$architecture
    $version = [string]$Manifest.rojo.version
    $toolRoot = Join-Path $CacheRoot "tools\rojo-$version-$architecture"
    $rojoPath = Join-Path $toolRoot "rojo.exe"

    if (Test-Path -LiteralPath $rojoPath) {
        $global:LASTEXITCODE = 0
        $versionText = (& $rojoPath --version 2>&1 | Out-String).Trim()
        if ($LASTEXITCODE -eq 0 -and $versionText -match [regex]::Escape($version)) {
            return [IO.Path]::GetFullPath($rojoPath)
        }
        Remove-Item $toolRoot -Recurse -Force -ErrorAction SilentlyContinue
    }

    Step "installing pinned Rojo $version"
    $zip = Join-Path $CacheRoot "downloads\$([IO.Path]::GetFileName([string]$asset.url))"
    Download-File ([string]$asset.url) $zip
    $hash = (Get-FileHash -LiteralPath $zip -Algorithm SHA256).Hash.ToLowerInvariant()
    if ($hash -ne ([string]$asset.sha256).ToLowerInvariant()) {
        throw "Rojo SHA256 검증에 실패했습니다."
    }

    $extract = "${toolRoot}.extracting"
    Remove-Item $extract -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item $toolRoot -Recurse -Force -ErrorAction SilentlyContinue
    Expand-Archive -LiteralPath $zip -DestinationPath $extract -Force
    $found = Get-ChildItem -LiteralPath $extract -Filter rojo.exe -File -Recurse | Select-Object -First 1
    if ($null -eq $found) {
        throw "다운로드한 Archive에서 rojo.exe를 찾지 못했습니다."
    }

    New-Item -ItemType Directory -Force $toolRoot | Out-Null
    Copy-Item -LiteralPath $found.FullName -Destination $rojoPath -Force
    Remove-Item $extract -Recurse -Force
    return [IO.Path]::GetFullPath($rojoPath)
}

function Resolve-StudioPath {
    $versionsRoot = Join-Path $env:LOCALAPPDATA "Roblox\Versions"
    if (-not (Test-Path -LiteralPath $versionsRoot)) {
        return $null
    }
    $studio = Get-ChildItem -LiteralPath $versionsRoot -Filter RobloxStudioBeta.exe -File -Recurse -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTime -Descending |
        Select-Object -First 1
    if ($null -ne $studio) {
        return [IO.Path]::GetFullPath($studio.FullName)
    }
    return $null
}

function Run-SelfTest {
    if ($RepoRoot -ne "C:\Users\somsn\RVTT") {
        throw "local repository path contract changed"
    }
    if (-not $PSScriptRoot) {
        throw "SelfTest requires file execution"
    }
    $manifestPath = Join-Path (Split-Path -Parent $PSScriptRoot) "acceptance-batch.json"
    $manifest = Get-Content -Raw -Encoding UTF8 $manifestPath | ConvertFrom-Json
    if ([string]$manifest.verifiedHead -notmatch "^[0-9a-f]{40}$") {
        throw "invalid verifiedHead"
    }
    foreach ($key in @("windowsX64", "windowsArm64")) {
        if ([string]$manifest.rojo.assets.$key.sha256 -notmatch "^[0-9a-f]{64}$") {
            throw "invalid Rojo hash for $key"
        }
    }
    Write-Host "RVTT local acceptance runner SelfTest passed" -ForegroundColor Green
}

if ($SelfTest) {
    Run-SelfTest
    return
}

if ([Environment]::OSVersion.Platform -ne [PlatformID]::Win32NT) {
    throw "Windows PowerShell에서 실행해야 합니다."
}
if (-not (Test-Path -LiteralPath (Join-Path $RepoRoot ".git"))) {
    throw "Git 저장소를 찾지 못했습니다: $RepoRoot"
}

Set-Location $RepoRoot
New-Item -ItemType Directory -Force $CacheRoot | Out-Null
$gitPath = [string](Resolve-GitPath)
$manifest = Read-RemoteManifest $gitPath
$head = [string]$manifest.verifiedHead
$project = [string]$manifest.project
$sourceRoot = [string](Ensure-VerifiedSource $gitPath $head)
$robloxRoot = Join-Path $sourceRoot "implementation\roblox"
Validate-Source $robloxRoot $project
$rojoPath = [string](Resolve-RojoPath $manifest)

$runningStudio = @(Get-Process -Name RobloxStudioBeta,RobloxStudio -ErrorAction SilentlyContinue)
if ($runningStudio.Count -gt 0) {
    Step "closing existing Roblox Studio"
    $runningStudio | Stop-Process -Force
    Start-Sleep -Seconds 2
}

$shortHead = $head.Substring(0, 12)
$slug = [IO.Path]::GetFileNameWithoutExtension($project).Replace(".project", "")
$outputRoot = Join-Path ([IO.Path]::GetTempPath()) "RVTT-Acceptance"
New-Item -ItemType Directory -Force $outputRoot | Out-Null
$output = Join-Path $outputRoot "RVTT-$slug-$shortHead.rbxlx"
$report = Join-Path $outputRoot "RVTT-$slug-$shortHead-manifest.txt"
Remove-Item $output -Force -ErrorAction SilentlyContinue

Step "building $project with $rojoPath"
Push-Location $robloxRoot
try {
    Invoke-NativeChecked $rojoPath @("build", $project, "--output", $output)
} finally {
    Pop-Location
}

@"
RVTT Studio Acceptance Batch
Generated: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss K")
Repository: $RepoRoot
Verified Head: $head
Project: $project
Place: $output
Source Cache: $sourceRoot
Rojo: $rojoPath
"@ | Set-Content -Encoding UTF8 $report

Write-Host ""
Write-Host "RVTT Acceptance Batch ready" -ForegroundColor Green
Write-Host "  Head: $head"
Write-Host "  Place: $output"
Write-Host "  Manifest: $report"

if (-not $NoOpen) {
    $studioPath = Resolve-StudioPath
    if (-not [string]::IsNullOrWhiteSpace([string]$studioPath)) {
        Start-Process -FilePath $studioPath -ArgumentList "`"$output`""
    } else {
        Start-Process -FilePath $output
    }
}
