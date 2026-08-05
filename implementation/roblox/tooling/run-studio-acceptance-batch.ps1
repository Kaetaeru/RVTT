[CmdletBinding()]
param(
    [string]$Branch = "planning/rvtt-remake",
    [string]$Project = "slice01-acceptance.project.json",
    [string]$ExpectedHead = "",
    [switch]$SkipPull,
    [switch]$SkipValidator,
    [switch]$NoOpen
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Assert-NativeSuccess {
    param([string]$Operation)

    if ($LASTEXITCODE -ne 0) {
        throw "$Operation 실패 · exitCode=$LASTEXITCODE"
    }
}

$repo = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot "..\..\.."))
$roblox = Join-Path $repo "implementation\roblox"
$projectPath = Join-Path $roblox $Project

if (-not (Test-Path (Join-Path $repo ".git"))) {
    throw "Git 저장소를 찾지 못했습니다: $repo"
}
if (-not (Test-Path $projectPath)) {
    throw "Rojo Project를 찾지 못했습니다: $projectPath"
}
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    throw "git 명령을 찾지 못했습니다."
}
if (-not (Get-Command rojo -ErrorAction SilentlyContinue)) {
    throw "rojo 명령을 찾지 못했습니다."
}

$dirty = @(git -C $repo status --porcelain)
Assert-NativeSuccess "git status"
if ($dirty.Count -gt 0) {
    Write-Host "변경된 파일:" -ForegroundColor Yellow
    $dirty | ForEach-Object { Write-Host "  $_" -ForegroundColor Yellow }
    throw "Dirty Worktree에서는 Acceptance Batch를 실행하지 않습니다. 변경을 Commit 또는 Stash하세요."
}

if (-not $SkipPull) {
    git -C $repo fetch origin
    Assert-NativeSuccess "git fetch"

    git -C $repo switch $Branch
    Assert-NativeSuccess "git switch"

    git -C $repo pull --ff-only origin $Branch
    Assert-NativeSuccess "git pull --ff-only"
}

$head = (git -C $repo rev-parse --short HEAD).Trim()
Assert-NativeSuccess "git rev-parse"

if ($ExpectedHead -ne "" -and $head -ne $ExpectedHead) {
    throw "검증된 Head 불일치 · expected=$ExpectedHead actual=$head"
}

if (-not $SkipValidator) {
    $validator = Join-Path $roblox "tooling\validate_implementation.py"
    $python = Get-Command python -ErrorAction SilentlyContinue
    $py = Get-Command py -ErrorAction SilentlyContinue

    if ($python) {
        & $python.Source $validator
        Assert-NativeSuccess "Implementation Validator"
    }
    elseif ($py) {
        & $py.Source -3 $validator
        Assert-NativeSuccess "Implementation Validator"
    }
    else {
        throw "python 또는 py 명령을 찾지 못했습니다. -SkipValidator로 명시적으로 건너뛸 수 있습니다."
    }
}

Get-Process RobloxStudioBeta -ErrorAction SilentlyContinue |
    Stop-Process -Force

$outputRoot = Join-Path $env:TEMP "RVTT-Acceptance"
New-Item -ItemType Directory -Force -Path $outputRoot | Out-Null

$projectSlug = [System.IO.Path]::GetFileNameWithoutExtension($Project)
if ($projectSlug.EndsWith(".project")) {
    $projectSlug = $projectSlug.Substring(0, $projectSlug.Length - ".project".Length)
}
$output = Join-Path $outputRoot ("RVTT-{0}-{1}.rbxlx" -f $projectSlug, $head)
$manifest = Join-Path $outputRoot ("RVTT-{0}-{1}-manifest.txt" -f $projectSlug, $head)

Remove-Item $output -Force -ErrorAction SilentlyContinue

Push-Location $roblox
try {
    rojo build $Project --output $output
    Assert-NativeSuccess "rojo build"
}
finally {
    Pop-Location
}

$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss K"
$manifestContent = @"
RVTT Studio Acceptance Batch
Generated: $timestamp
Branch: $Branch
Head: $head
Project: $Project
Place: $output

Execution rule:
1. Publish this Place to the existing designated test Place once.
2. Do not connect the Rojo plugin after opening the built Place.
3. Run the complete Batch Acceptance flow once.
4. On PASS, report the final Batch Summary only.
5. On FAIL, report the final Batch Summary and the first related [RVTT ...] error line.
"@
Set-Content -Path $manifest -Value $manifestContent -Encoding UTF8

Write-Host ""
Write-Host "RVTT Acceptance Batch 준비 완료" -ForegroundColor Green
Write-Host "  Branch : $Branch"
Write-Host "  Head   : $head"
Write-Host "  Project: $Project"
Write-Host "  Place  : $output"
Write-Host "  Manifest: $manifest"
Write-Host ""
Write-Host "게시와 수동 검사는 이 Batch에서 한 번만 수행합니다." -ForegroundColor Cyan

if (-not $NoOpen) {
    Start-Process -FilePath $output
}
