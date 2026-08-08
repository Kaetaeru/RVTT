[CmdletBinding()]
param(
    [string]$Project = "default.project.json",
    [string]$Output = "",
    [switch]$NoOpen,
    [switch]$SelfTest
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

$RobloxRoot = Split-Path -Parent $PSScriptRoot
$Importer = Join-Path $PSScriptRoot "build_private_rules_runtime.py"
$SourceBindingEnv = "RVTT_PRIVATE_DND2024_KO_SOURCE"

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

function Invoke-NativeChecked {
    param(
        [string]$Executable,
        [string[]]$Arguments
    )

    $global:LASTEXITCODE = 0
    & $Executable @Arguments
    $exitCode = $LASTEXITCODE
    if ($exitCode -ne 0) {
        throw "native command failed · executable=$Executable · exitCode=$exitCode"
    }
}

function Invoke-SelfTest {
    if (-not (Test-Path -LiteralPath $Importer)) {
        throw "private rules importer가 없습니다."
    }
    $projectPath = Join-Path $RobloxRoot $Project
    if (-not (Test-Path -LiteralPath $projectPath)) {
        throw "Rojo project가 없습니다: $Project"
    }
    if ($SourceBindingEnv -ne "RVTT_PRIVATE_DND2024_KO_SOURCE") {
        throw "private source binding key가 변경되었습니다."
    }
    Write-Host "RVTT private rules Studio runner SelfTest passed" -ForegroundColor Green
}

if ($SelfTest) {
    Invoke-SelfTest
    return
}

$sourceRepo = [Environment]::GetEnvironmentVariable($SourceBindingEnv)
if ([string]::IsNullOrWhiteSpace($sourceRepo)) {
    throw "$SourceBindingEnv 환경 변수가 없습니다. Private integrated rules build는 fail closed입니다."
}
$sourceRepo = [IO.Path]::GetFullPath($sourceRepo)
if (-not (Test-Path -LiteralPath (Join-Path $sourceRepo ".git"))) {
    throw "$SourceBindingEnv 가 Git repository를 가리키지 않습니다: $sourceRepo"
}

$projectPath = Join-Path $RobloxRoot $Project
if (-not (Test-Path -LiteralPath $projectPath)) {
    throw "Rojo project가 없습니다: $Project"
}

$pythonPath = Resolve-ApplicationPath @("python.exe", "python", "py.exe", "py")
$rojoPath = Resolve-ApplicationPath @("rojo.exe", "rojo")
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$workspace = Join-Path ([IO.Path]::GetTempPath()) "RVTT-PrivateRules\$timestamp-$PID"
New-Item -ItemType Directory -Force $workspace | Out-Null

Write-Host "[RVTT Private Rules] validating pinned source and generating temporary RuleContentPackage" -ForegroundColor Cyan
Invoke-NativeChecked $pythonPath @(
    $Importer,
    "--source-repo-root", $sourceRepo,
    "--output-root", $workspace,
    "--base-project", $projectPath
)

$generatedProject = Join-Path $workspace "private-rules.generated.project.json"
$runtimeRoot = Join-Path $workspace "runtime\RVTTPrivateRuleContent"
foreach ($required in @(
    $generatedProject,
    (Join-Path $runtimeRoot "Readiness.json"),
    (Join-Path $runtimeRoot "RuleReaderPackage.json"),
    (Join-Path $workspace "private-rules.import-manifest.json")
)) {
    if (-not (Test-Path -LiteralPath $required)) {
        throw "private rules generated output이 없습니다: $required"
    }
}

if ([string]::IsNullOrWhiteSpace($Output)) {
    $Output = Join-Path $workspace "RVTT-private-rules.rbxlx"
} else {
    $Output = [IO.Path]::GetFullPath($Output)
}

Write-Host "[RVTT Private Rules] building generated Rojo overlay" -ForegroundColor Cyan
Invoke-NativeChecked $rojoPath @("build", $generatedProject, "--output", $Output)
if (-not (Test-Path -LiteralPath $Output)) {
    throw "Rojo output이 생성되지 않았습니다: $Output"
}

Write-Host ""
Write-Host "RVTT private rules Studio build ready" -ForegroundColor Green
Write-Host "  Source binding: $SourceBindingEnv"
Write-Host "  Project: $Project"
Write-Host "  Generated project: $generatedProject"
Write-Host "  Place: $Output"
Write-Host "  Temporary workspace: $workspace"
Write-Host "  Private rule body is not written into the RVTT Git tree."

if (-not $NoOpen) {
    $studioPath = Resolve-StudioPath
    if (-not [string]::IsNullOrWhiteSpace([string]$studioPath)) {
        Start-Process -FilePath $studioPath -ArgumentList "`"$Output`""
    } else {
        Start-Process -FilePath $Output
    }
}
