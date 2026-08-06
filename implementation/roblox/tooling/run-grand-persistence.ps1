[CmdletBinding()]
param(
    [string]$ExpectedHead = "",
    [string]$ConfigPath = "",
    [switch]$NoUpload,
    [switch]$NoOpen,
    [switch]$SelfTest
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

$RobloxRoot = Split-Path -Parent $PSScriptRoot
$RepoRoot = Split-Path -Parent (Split-Path -Parent $RobloxRoot)
$ManifestPath = Join-Path $RobloxRoot "grand-acceptance-manifest.json"
$DefaultConfigPath = Join-Path $RobloxRoot "grand-persistence-config.json"
$ExampleConfigPath = Join-Path $RobloxRoot "grand-persistence-config.example.json"
$StudioProcessNames = @("RobloxStudioBeta", "RobloxStudio")
$ConfiguredPersistenceExecutions = @("studio-published", "studio-published-pair")
$RequiredProjects = @(
    "live-datastore.project.json",
    "restart-seed.project.json",
    "restart-verify.project.json",
    "datastore-outage.project.json",
    "lease-holder.project.json",
    "lease-contender.project.json",
    "production-lease-seed.project.json",
    "production-lease-verify.project.json"
)

function Write-Step {
    param([string]$Text)
    Write-Host "[RVTT Persistence] $Text" -ForegroundColor Cyan
}

function Resolve-ApplicationPath {
    param([string[]]$Names)
    foreach ($name in $Names) {
        foreach ($command in @(Get-Command $name -CommandType Application -All -ErrorAction SilentlyContinue)) {
            if (-not [string]::IsNullOrWhiteSpace([string]$command.Source)) {
                return [IO.Path]::GetFullPath([string]$command.Source)
            }
        }
    }
    throw "실행 파일을 찾지 못했습니다: $($Names -join ', ')"
}

function Resolve-StudioPath {
    if ([string]::IsNullOrWhiteSpace($env:LOCALAPPDATA)) {
        return $null
    }
    $versionsRoot = Join-Path $env:LOCALAPPDATA "Roblox\Versions"
    if (-not (Test-Path -LiteralPath $versionsRoot)) {
        return $null
    }
    $studio = Get-ChildItem -LiteralPath $versionsRoot -Filter RobloxStudioBeta.exe -File -Recurse -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTime -Descending |
        Select-Object -First 1
    if ($null -eq $studio) {
        return $null
    }
    return [IO.Path]::GetFullPath($studio.FullName)
}

function Invoke-NativeCapture {
    param([string]$Executable, [string[]]$Arguments)
    $global:LASTEXITCODE = 0
    $lines = @(& $Executable @Arguments 2>&1)
    $exitCode = $LASTEXITCODE
    foreach ($line in $lines) {
        Write-Host $line
    }
    return [pscustomobject]@{
        ExitCode = $exitCode
        Output = @($lines | ForEach-Object { [string]$_ })
    }
}

function Stop-StudioProcesses {
    $running = @(Get-Process -Name $StudioProcessNames -ErrorAction SilentlyContinue)
    if ($running.Count -gt 0) {
        Write-Step "closing existing Roblox Studio processes"
        $running | Stop-Process -Force
        Start-Sleep -Seconds 2
    }
}

function Wait-ForStudioExit {
    while (@(Get-Process -Name $StudioProcessNames -ErrorAction SilentlyContinue).Count -gt 0) {
        Start-Sleep -Seconds 2
    }
}

function Get-RecentStudioLines {
    param([datetime]$StartedAt, [string[]]$Tokens)
    if ($Tokens.Count -eq 0 -or [string]::IsNullOrWhiteSpace($env:LOCALAPPDATA)) {
        return @()
    }
    $logsRoot = Join-Path $env:LOCALAPPDATA "Roblox\logs"
    if (-not (Test-Path -LiteralPath $logsRoot)) {
        return @()
    }
    $results = New-Object System.Collections.Generic.List[string]
    $logs = @(Get-ChildItem -LiteralPath $logsRoot -Filter "*.log" -File -ErrorAction SilentlyContinue |
        Where-Object { $_.LastWriteTime -ge $StartedAt.AddSeconds(-5) } |
        Sort-Object LastWriteTime)
    foreach ($log in $logs) {
        foreach ($line in @(Get-Content -LiteralPath $log.FullName -ErrorAction SilentlyContinue)) {
            $text = [string]$line
            foreach ($token in $Tokens) {
                if ($text.Contains($token)) {
                    $results.Add($text.Trim())
                    break
                }
            }
        }
    }
    return @($results | Select-Object -Unique)
}

function Get-PhaseTokens {
    param([object]$Phase)
    $tokens = New-Object System.Collections.Generic.List[string]
    if (-not [string]::IsNullOrWhiteSpace([string]$Phase.summaryToken)) {
        $tokens.Add([string]$Phase.summaryToken)
    }
    if ($null -ne $Phase.PSObject.Properties["evidenceTokens"]) {
        foreach ($token in @($Phase.evidenceTokens)) {
            if (-not [string]::IsNullOrWhiteSpace([string]$token)) {
                $tokens.Add([string]$token)
            }
        }
    }
    return @($tokens | Select-Object -Unique)
}

function Get-ConfiguredPersistencePhases {
    param([object]$Manifest)
    return @(
        $Manifest.phases |
            Where-Object {
                $_.persistence -eq $true -and
                [string]$_.execution -in $ConfiguredPersistenceExecutions
            } |
            Sort-Object { [int]$_.order }
    )
}

function Assert-Config {
    param([object]$Config)
    if ([int]$Config.schemaVersion -ne 1) {
        throw "grand persistence config schemaVersion은 1이어야 합니다."
    }
    if ([int64]$Config.universeId -le 0) {
        throw "grand persistence config에 유효한 universeId가 필요합니다."
    }
    if ($Config.apiAccessConfirmed -ne $true) {
        throw "Studio API Access를 확인한 뒤 apiAccessConfirmed를 true로 설정해야 합니다."
    }
    foreach ($project in $RequiredProjects) {
        $property = $Config.placeIds.PSObject.Properties[$project]
        if ($null -eq $property -or [int64]$property.Value -le 0) {
            throw "grand persistence config에 Place ID가 없습니다: $project"
        }
    }
}

function Invoke-SelfTest {
    if (-not (Test-Path -LiteralPath $ManifestPath)) {
        throw "grand acceptance manifest가 없습니다."
    }
    if (-not (Test-Path -LiteralPath $ExampleConfigPath)) {
        throw "grand persistence example config가 없습니다."
    }
    $manifest = Get-Content -Raw -Encoding UTF8 $ManifestPath | ConvertFrom-Json
    $persistence = Get-ConfiguredPersistencePhases $manifest
    $projects = @($persistence | ForEach-Object { [string]$_.project } | Select-Object -Unique)
    foreach ($project in $RequiredProjects) {
        if ($project -notin $projects) {
            throw "manifest에 Grand Persistence Project가 없습니다: $project"
        }
    }
    $orders = @($persistence | ForEach-Object { [int]$_.order })
    if (($orders -join ",") -ne "40,50,60,70,80,81,90,91") {
        throw "Grand Persistence Phase 순서가 예상 계약과 다릅니다: $($orders -join ',')"
    }
    Write-Host "RVTT grand persistence runner SelfTest passed" -ForegroundColor Green
}

if ($SelfTest) {
    Invoke-SelfTest
    return
}
if ([Environment]::OSVersion.Platform -ne [PlatformID]::Win32NT) {
    throw "Grand Persistence Milestone은 Windows PowerShell에서 실행해야 합니다."
}
if (-not (Test-Path -LiteralPath (Join-Path $RepoRoot ".git"))) {
    throw "Git 저장소를 찾지 못했습니다: $RepoRoot"
}

$resolvedConfigPath = if ([string]::IsNullOrWhiteSpace($ConfigPath)) { $DefaultConfigPath } else { $ConfigPath }
if (-not (Test-Path -LiteralPath $resolvedConfigPath)) {
    throw "Grand Persistence 설정 파일이 없습니다: $resolvedConfigPath`n예제 파일을 복사해 실제 Universe·Place ID를 입력하세요: $ExampleConfigPath"
}
$config = Get-Content -Raw -Encoding UTF8 $resolvedConfigPath | ConvertFrom-Json
Assert-Config $config

$manifest = Get-Content -Raw -Encoding UTF8 $ManifestPath | ConvertFrom-Json
$phases = Get-ConfiguredPersistencePhases $manifest
$gitPath = Resolve-ApplicationPath @("git.exe", "git")
$rojoPath = Resolve-ApplicationPath @("rojo.exe", "rojo")
$studioPath = Resolve-StudioPath
if (-not $NoOpen -and [string]::IsNullOrWhiteSpace([string]$studioPath)) {
    throw "RobloxStudioBeta.exe를 찾지 못했습니다."
}

$headResult = Invoke-NativeCapture $gitPath @("-C", $RepoRoot, "rev-parse", "--short=7", "HEAD")
if ($headResult.ExitCode -ne 0 -or $headResult.Output.Count -eq 0) {
    throw "현재 Git Head를 확인하지 못했습니다."
}
$currentHead = ([string]$headResult.Output[-1]).Trim()
if (-not [string]::IsNullOrWhiteSpace($ExpectedHead) -and $currentHead -ne $ExpectedHead) {
    throw "예상 Head는 $ExpectedHead이지만 현재 Head는 $currentHead입니다."
}

$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$reportRoot = Join-Path $env:TEMP "RVTT-Grand-Persistence\$timestamp-$currentHead"
New-Item -ItemType Directory -Force $reportRoot | Out-Null
$results = New-Object System.Collections.Generic.List[object]

Stop-StudioProcesses
Write-Step "head=$currentHead universeId=$($config.universeId)"

if (-not $NoUpload) {
    foreach ($project in $RequiredProjects) {
        $placeId = [int64]$config.placeIds.PSObject.Properties[$project].Value
        Write-Step "uploading project=$project placeId=$placeId"
        Push-Location $RobloxRoot
        try {
            $upload = Invoke-NativeCapture $rojoPath @("upload", $project, "--asset_id", [string]$placeId)
        } finally {
            Pop-Location
        }
        if ($upload.ExitCode -ne 0) {
            throw "Rojo upload에 실패했습니다: project=$project placeId=$placeId exitCode=$($upload.ExitCode)"
        }
    }
}

$runGroups = [ordered]@{}
foreach ($phase in $phases) {
    $runId = [string]$phase.runId
    if (-not $runGroups.Contains($runId)) {
        $runGroups[$runId] = New-Object System.Collections.Generic.List[object]
    }
    $runGroups[$runId].Add($phase)
}

foreach ($runId in @($runGroups.Keys)) {
    $groupPhases = @($runGroups[$runId])
    $execution = [string]$groupPhases[0].execution
    $projects = @($groupPhases | ForEach-Object { [string]$_.project } | Select-Object -Unique)
    $placeIds = @($projects | ForEach-Object { [int64]$config.placeIds.PSObject.Properties[$_].Value })

    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Yellow
    Write-Host "Grand Persistence run: $runId" -ForegroundColor Yellow
    Write-Host "Projects: $($projects -join ', ')"
    Write-Host "Place IDs: $($placeIds -join ', ')"
    if ($execution -eq "studio-published-pair") {
        Write-Host "Holder Place에서 Play를 먼저 시작한 뒤 Contender Place에서 Play를 시작하세요."
        Write-Host "두 PASS Summary를 확인한 뒤 Studio 창을 모두 닫으세요."
    } else {
        Write-Host "게시 Place에서 Play를 시작하고 PASS Summary를 확인한 뒤 Studio를 닫으세요."
    }
    Write-Host "Studio를 닫으면 다음 Persistence Run이 시작됩니다."
    Write-Host "============================================================" -ForegroundColor Yellow

    if ($NoOpen) {
        foreach ($phase in $groupPhases) {
            $results.Add([pscustomobject][ordered]@{
                runId = $runId; id = [string]$phase.id; status = "prepared"
                detail = "published Place upload completed; Studio launch disabled"; evidence = @()
            })
        }
        continue
    }

    $startedAt = Get-Date
    foreach ($placeId in $placeIds) {
        Start-Process -FilePath $studioPath -ArgumentList @(
            "--task", "EditPlace",
            "--placeId", [string]$placeId,
            "--universeId", [string]$config.universeId
        ) | Out-Null
        if ($execution -eq "studio-published-pair") {
            Start-Sleep -Seconds 3
        }
    }
    Wait-ForStudioExit

    foreach ($phase in $groupPhases) {
        $tokens = Get-PhaseTokens $phase
        $evidence = Get-RecentStudioLines $startedAt $tokens
        $passed = @($evidence | Where-Object { $_ -match [string]$phase.passRegex }).Count -gt 0
        $status = if ($passed) { "pass" } elseif ($evidence.Count -gt 0) { "fail" } else { "incomplete" }
        $detail = if ($passed) {
            "expected PASS summary found"
        } elseif ($evidence.Count -gt 0) {
            "summary found but PASS contract did not match"
        } else {
            "expected summary was not found in recent Studio logs"
        }
        $results.Add([pscustomobject][ordered]@{
            runId = $runId; id = [string]$phase.id; status = $status
            detail = $detail; evidence = @($evidence)
        })
    }
}

$passedCount = @($results | Where-Object { $_.status -eq "pass" }).Count
$failedCount = @($results | Where-Object { $_.status -eq "fail" }).Count
$incompleteCount = @($results | Where-Object { $_.status -eq "incomplete" }).Count
$preparedCount = @($results | Where-Object { $_.status -eq "prepared" }).Count
$result = if ($failedCount -gt 0 -or $incompleteCount -gt 0) { "FAIL" } elseif ($preparedCount -gt 0) { "PREPARED" } else { "PASS" }

$report = [pscustomobject][ordered]@{
    schemaVersion = 1
    campaignId = "rvtt-grand-persistence"
    generatedAt = (Get-Date).ToString("o")
    head = $currentHead
    universeId = [int64]$config.universeId
    uploadSkipped = [bool]$NoUpload
    openSkipped = [bool]$NoOpen
    result = $result
    counts = [pscustomobject][ordered]@{
        passed = $passedCount; failed = $failedCount
        incomplete = $incompleteCount; prepared = $preparedCount
    }
    phases = @($results)
}

$jsonPath = Join-Path $reportRoot "RVTT-grand-persistence-report.json"
$markdownPath = Join-Path $reportRoot "RVTT-grand-persistence-report.md"
$report | ConvertTo-Json -Depth 10 | Set-Content -Encoding UTF8 $jsonPath

$markdown = New-Object System.Collections.Generic.List[string]
$markdown.Add("# RVTT Grand Persistence Report")
$markdown.Add("")
$markdown.Add("- Head: ``$currentHead``")
$markdown.Add("- Universe ID: ``$($config.universeId)``")
$markdown.Add("- Result: ``$result``")
$markdown.Add("- Passed: ``$passedCount``")
$markdown.Add("- Failed: ``$failedCount``")
$markdown.Add("- Incomplete: ``$incompleteCount``")
$markdown.Add("- Prepared: ``$preparedCount``")
$markdown.Add("")
$markdown.Add("| Run | Phase | Status | Detail |")
$markdown.Add("|---|---|---|---|")
foreach ($phaseResult in $results) {
    $detail = ([string]$phaseResult.detail).Replace("|", "\\|")
    $markdown.Add("| ``$($phaseResult.runId)`` | ``$($phaseResult.id)`` | ``$($phaseResult.status)`` | $detail |")
}
$markdown | Set-Content -Encoding UTF8 $markdownPath

Write-Host ""
Write-Host "[RVTT Grand Persistence Summary] result=$result passed=$passedCount failed=$failedCount incomplete=$incompleteCount prepared=$preparedCount head=$currentHead" -ForegroundColor Green
Write-Host "JSON report: $jsonPath"
Write-Host "Markdown report: $markdownPath"
