[CmdletBinding()]
param(
    [string]$ExpectedHead = "",
    [switch]$IncludePersistence,
    [switch]$NoOpen,
    [switch]$SelfTest
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

$RobloxRoot = Split-Path -Parent $PSScriptRoot
$RepoRoot = Split-Path -Parent (Split-Path -Parent $RobloxRoot)
$ManifestPath = Join-Path $RobloxRoot "grand-acceptance-manifest.json"
$DefaultJsonReportName = "RVTT-grand-acceptance-report.json"
$DefaultMarkdownReportName = "RVTT-grand-acceptance-report.md"
$StudioProcessNames = @("RobloxStudioBeta", "RobloxStudio")

function Write-Step {
    param([string]$Text)
    Write-Host "[RVTT Grand] $Text" -ForegroundColor Cyan
}

function Resolve-ApplicationPath {
    param([string[]]$Names)

    foreach ($name in $Names) {
        $commands = @(Get-Command $name -CommandType Application -All -ErrorAction SilentlyContinue)
        foreach ($command in $commands) {
            $candidate = [string]$command.Source
            if (-not [string]::IsNullOrWhiteSpace($candidate) -and (Test-Path -LiteralPath $candidate)) {
                return [IO.Path]::GetFullPath($candidate)
            }
        }
    }
    throw "실행 파일을 찾지 못했습니다: $($Names -join ', ')"
}

function Invoke-NativeCapture {
    param(
        [string]$Executable,
        [string[]]$Arguments
    )

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
    param(
        [datetime]$StartedAt,
        [string]$SummaryToken
    )

    if ([string]::IsNullOrWhiteSpace($env:LOCALAPPDATA)) {
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
            if ($text.Contains($SummaryToken)) {
                $results.Add($text.Trim())
            }
        }
    }
    return @($results | Select-Object -Unique)
}

function New-PhaseResult {
    param(
        [string]$Id,
        [string]$Name,
        [string]$Status,
        [string]$Detail,
        [string[]]$Evidence = @()
    )

    return [pscustomobject][ordered]@{
        id = $Id
        name = $Name
        status = $Status
        detail = $Detail
        evidence = @($Evidence)
    }
}

function Invoke-SelfTest {
    if (-not (Test-Path -LiteralPath $ManifestPath)) {
        throw "grand acceptance manifest가 없습니다."
    }
    $manifest = Get-Content -Raw -Encoding UTF8 $ManifestPath | ConvertFrom-Json
    if ($manifest.schemaVersion -ne 1) {
        throw "grand acceptance manifest schemaVersion은 1이어야 합니다."
    }
    if ([string]$manifest.runner -ne "tooling/run-grand-acceptance.ps1") {
        throw "grand acceptance runner 경로 계약이 잘못되었습니다."
    }
    if ([string]$manifest.report.json -ne $DefaultJsonReportName) {
        throw "grand acceptance JSON report 이름이 잘못되었습니다."
    }
    if ([string]$manifest.report.markdown -ne $DefaultMarkdownReportName) {
        throw "grand acceptance Markdown report 이름이 잘못되었습니다."
    }

    $ids = @($manifest.phases | ForEach-Object { [string]$_.id })
    if ($ids.Count -lt 20) {
        throw "grand acceptance phase registry가 불완전합니다."
    }
    if (@($ids | Sort-Object -Unique).Count -ne $ids.Count) {
        throw "grand acceptance phase id가 중복되었습니다."
    }

    $orders = @($manifest.phases | ForEach-Object { [int]$_.order })
    if (@($orders | Sort-Object -Unique).Count -ne $orders.Count) {
        throw "grand acceptance phase order가 중복되었습니다."
    }

    foreach ($project in @($manifest.staticProjects)) {
        if (-not (Test-Path -LiteralPath (Join-Path $RobloxRoot ([string]$project)))) {
            throw "grand acceptance 정적 Project가 없습니다: $project"
        }
    }

    foreach ($phase in @($manifest.phases)) {
        if ([string]$phase.status -eq "ready" -and [string]$phase.execution -ne "automated") {
            if ([string]::IsNullOrWhiteSpace([string]$phase.project)) {
                throw "ready Studio phase에 project가 없습니다: $($phase.id)"
            }
            if ([string]::IsNullOrWhiteSpace([string]$phase.summaryToken)) {
                throw "ready Studio phase에 summaryToken이 없습니다: $($phase.id)"
            }
            if ([string]::IsNullOrWhiteSpace([string]$phase.passRegex)) {
                throw "ready Studio phase에 passRegex가 없습니다: $($phase.id)"
            }
        }
    }

    Write-Host "RVTT grand acceptance runner SelfTest passed" -ForegroundColor Green
}

if ($SelfTest) {
    Invoke-SelfTest
    return
}

if ([Environment]::OSVersion.Platform -ne [PlatformID]::Win32NT) {
    throw "Grand Acceptance Campaign은 Windows PowerShell에서 실행해야 합니다."
}
if (-not (Test-Path -LiteralPath (Join-Path $RepoRoot ".git"))) {
    throw "Git 저장소를 찾지 못했습니다: $RepoRoot"
}

$manifest = Get-Content -Raw -Encoding UTF8 $ManifestPath | ConvertFrom-Json
$gitPath = Resolve-ApplicationPath @("git.exe", "git")
$rojoPath = Resolve-ApplicationPath @("rojo.exe", "rojo")

$currentHeadResult = Invoke-NativeCapture $gitPath @("-C", $RepoRoot, "rev-parse", "--short=7", "HEAD")
if ($currentHeadResult.ExitCode -ne 0 -or $currentHeadResult.Output.Count -eq 0) {
    throw "현재 Git Head를 확인하지 못했습니다."
}
$currentHead = ([string]$currentHeadResult.Output[-1]).Trim()
if (-not [string]::IsNullOrWhiteSpace($ExpectedHead) -and $currentHead -ne $ExpectedHead) {
    throw "예상 Head는 $ExpectedHead이지만 현재 Head는 $currentHead입니다."
}

$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$reportRoot = Join-Path $env:TEMP "RVTT-Grand-Acceptance\$timestamp-$currentHead"
$placeRoot = Join-Path $reportRoot "places"
New-Item -ItemType Directory -Force $placeRoot | Out-Null

$results = New-Object System.Collections.Generic.List[object]
$buildOutputs = @{}
$buildFailures = @{}

Stop-StudioProcesses
Write-Step "campaign=$($manifest.campaignId) head=$currentHead"
Write-Step "building every registered static project"

foreach ($projectValue in @($manifest.staticProjects)) {
    $project = [string]$projectValue
    $slug = [IO.Path]::GetFileNameWithoutExtension($project).Replace(".project", "")
    $output = Join-Path $placeRoot "RVTT-$slug-$currentHead.rbxlx"
    Remove-Item $output -Force -ErrorAction SilentlyContinue

    Push-Location $RobloxRoot
    try {
        $build = Invoke-NativeCapture $rojoPath @("build", $project, "--output", $output)
    } finally {
        Pop-Location
    }

    if ($build.ExitCode -eq 0 -and (Test-Path -LiteralPath $output)) {
        $buildOutputs[$project] = $output
    } else {
        $buildFailures[$project] = "rojo build exitCode=$($build.ExitCode)"
    }
}

if ($buildFailures.Count -eq 0) {
    $results.Add((New-PhaseResult "static-build" "Static and Rojo build gate" "pass" "all registered projects built"))
} else {
    $failureEvidence = @($buildFailures.GetEnumerator() | ForEach-Object { "$($_.Key): $($_.Value)" })
    $results.Add((New-PhaseResult "static-build" "Static and Rojo build gate" "fail" "one or more projects failed to build" $failureEvidence))
}

$studioPath = Resolve-StudioPath
$phases = @($manifest.phases | Sort-Object { [int]$_.order })
foreach ($phase in $phases) {
    $phaseId = [string]$phase.id
    if ($phaseId -eq "static-build") {
        continue
    }

    $phaseStatus = [string]$phase.status
    $isPersistence = $phase.persistence -eq $true
    $selected = $phaseStatus -eq "ready" -or ($IncludePersistence -and $isPersistence -and $phaseStatus -eq "deferred")

    if (-not $selected) {
        $blocker = if (-not [string]::IsNullOrWhiteSpace([string]$phase.blocker)) {
            [string]$phase.blocker
        } elseif ($phaseStatus -eq "deferred") {
            "deferred until the dedicated persistence milestone"
        } else {
            "phase harness or production evidence is not implemented"
        }
        $results.Add((New-PhaseResult $phaseId ([string]$phase.name) "blocked" $blocker))
        continue
    }

    $project = [string]$phase.project
    if (-not $buildOutputs.ContainsKey($project)) {
        $detail = if ($buildFailures.ContainsKey($project)) {
            [string]$buildFailures[$project]
        } else {
            "project was not registered in staticProjects"
        }
        $results.Add((New-PhaseResult $phaseId ([string]$phase.name) "fail" $detail))
        continue
    }

    $place = [string]$buildOutputs[$project]
    if ($NoOpen) {
        $results.Add((New-PhaseResult $phaseId ([string]$phase.name) "prepared" "place built; Studio launch disabled" @($place)))
        continue
    }

    if ([string]::IsNullOrWhiteSpace([string]$studioPath)) {
        $results.Add((New-PhaseResult $phaseId ([string]$phase.name) "fail" "RobloxStudioBeta.exe was not found"))
        continue
    }

    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Yellow
    Write-Host "Grand phase: $phaseId" -ForegroundColor Yellow
    Write-Host "Project: $project"
    Write-Host "Studio에서 이 Phase를 끝까지 실행한 뒤 Studio를 닫으세요."
    if ([string]$phase.execution -eq "studio-multi-client") {
        Write-Host "Test 탭에서 Server 1개와 Client 3개를 시작하고 최종 Summary를 확인하세요."
    }
    if ([string]$phase.execution -eq "studio-published") {
        Write-Host "이 Phase는 게시된 Experience와 Studio API Access가 필요합니다."
    }
    Write-Host "Studio를 닫으면 다음 Phase가 자동으로 시작됩니다."
    Write-Host "============================================================" -ForegroundColor Yellow

    $startedAt = Get-Date
    Start-Process -FilePath $studioPath -ArgumentList "`"$place`"" | Out-Null
    Wait-ForStudioExit

    $evidence = Get-RecentStudioLines $startedAt ([string]$phase.summaryToken)
    $passed = $false
    foreach ($line in $evidence) {
        if ($line -match [string]$phase.passRegex) {
            $passed = $true
            break
        }
    }

    if ($passed) {
        $results.Add((New-PhaseResult $phaseId ([string]$phase.name) "pass" "expected PASS summary found" $evidence))
    } elseif ($evidence.Count -gt 0) {
        $results.Add((New-PhaseResult $phaseId ([string]$phase.name) "fail" "summary found but PASS contract did not match" $evidence))
    } else {
        $results.Add((New-PhaseResult $phaseId ([string]$phase.name) "incomplete" "expected summary was not found in recent Studio logs"))
    }
}

$passedCount = @($results | Where-Object { $_.status -eq "pass" }).Count
$failedCount = @($results | Where-Object { $_.status -eq "fail" }).Count
$incompleteCount = @($results | Where-Object { $_.status -eq "incomplete" }).Count
$preparedCount = @($results | Where-Object { $_.status -eq "prepared" }).Count
$blockedCount = @($results | Where-Object { $_.status -eq "blocked" }).Count
$executionResult = if ($failedCount -gt 0 -or $incompleteCount -gt 0) { "FAIL" } else { "PASS" }
$grandResult = if ($executionResult -eq "FAIL") {
    "FAIL"
} elseif ($blockedCount -gt 0 -or $preparedCount -gt 0) {
    "PARTIAL"
} else {
    "PASS"
}

$report = [pscustomobject][ordered]@{
    schemaVersion = 1
    campaignId = [string]$manifest.campaignId
    generatedAt = (Get-Date).ToString("o")
    repository = $RepoRoot
    head = $currentHead
    includePersistence = [bool]$IncludePersistence
    noOpen = [bool]$NoOpen
    result = $grandResult
    executionResult = $executionResult
    counts = [pscustomobject][ordered]@{
        passed = $passedCount
        failed = $failedCount
        incomplete = $incompleteCount
        prepared = $preparedCount
        blocked = $blockedCount
    }
    phases = @($results)
}

$jsonReportName = if ([string]::IsNullOrWhiteSpace([string]$manifest.report.json)) {
    $DefaultJsonReportName
} else {
    [string]$manifest.report.json
}
$markdownReportName = if ([string]::IsNullOrWhiteSpace([string]$manifest.report.markdown)) {
    $DefaultMarkdownReportName
} else {
    [string]$manifest.report.markdown
}
$jsonPath = Join-Path $reportRoot $jsonReportName
$markdownPath = Join-Path $reportRoot $markdownReportName
$report | ConvertTo-Json -Depth 10 | Set-Content -Encoding UTF8 $jsonPath

$markdown = New-Object System.Collections.Generic.List[string]
$markdown.Add("# RVTT Grand Acceptance Report")
$markdown.Add("")
$markdown.Add("- Head: ``$currentHead``")
$markdown.Add("- Result: ``$grandResult``")
$markdown.Add("- Execution: ``$executionResult``")
$markdown.Add("- Passed: ``$passedCount``")
$markdown.Add("- Failed: ``$failedCount``")
$markdown.Add("- Incomplete: ``$incompleteCount``")
$markdown.Add("- Prepared: ``$preparedCount``")
$markdown.Add("- Blocked: ``$blockedCount``")
$markdown.Add("")
$markdown.Add("| Phase | Status | Detail |")
$markdown.Add("|---|---|---|")
foreach ($result in $results) {
    $detail = ([string]$result.detail).Replace("|", "\\|")
    $markdown.Add("| ``$($result.id)`` | ``$($result.status)`` | $detail |")
    if (@($result.evidence).Count -gt 0) {
        $markdown.Add("")
        $markdown.Add("### $($result.id) evidence")
        $markdown.Add("")
        $markdown.Add("``````text")
        foreach ($line in @($result.evidence)) {
            $markdown.Add([string]$line)
        }
        $markdown.Add("``````")
        $markdown.Add("")
    }
}
$markdown | Set-Content -Encoding UTF8 $markdownPath

Write-Host ""
Write-Host "[RVTT Grand Summary] campaign=$($manifest.campaignId) result=$grandResult execution=$executionResult passed=$passedCount failed=$failedCount incomplete=$incompleteCount prepared=$preparedCount blocked=$blockedCount head=$currentHead" -ForegroundColor Green
Write-Host "JSON report: $jsonPath"
Write-Host "Markdown report: $markdownPath"
