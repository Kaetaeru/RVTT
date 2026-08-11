# RVTT 실행 테스트 규칙

- 상태: `ACTIVE`
- 채택일: 2026-08-05
- 최종 갱신일: 2026-08-06
- 목적: Roblox Studio 게시·실행·수동 확인 횟수를 줄이면서, 한 번의 Acceptance에서 여러 기능과 실패 원인을 함께 검증한다.

## 1. 기본 원칙

수동 Studio 검사는 개별 커밋이나 단일 버그 수정마다 수행하지 않는다.

```text
여러 관련 기능 구현
→ 자동 테스트·정적 CI
→ 구조화된 진단 로그와 Self-check 추가
→ 하나의 Acceptance Build 생성
→ 한 번의 사용자 검증
```

사용자에게 새 Place 게시와 수동 검사를 요청할 수 있는 시점은 명시적인 `Batch Acceptance Gate`뿐이다.

## 2. Batch 단위

하나의 Batch는 서로 연결된 사용자 흐름 또는 기술 Milestone을 완성해야 한다.

권장 범위:

- 하나의 End-to-End 흐름
- 여러 관련 동작과 Acceptance 항목
- 정상 경로와 거부 경로
- 필요한 진단 로그와 자동 회귀 테스트
- 한 개의 재사용 가능한 Acceptance Place

다음 변경만으로 별도 수동 게시를 요청하지 않는다.

- 단일 입력 수정
- 로그 한 줄 추가
- 스타일 또는 문구 수정
- 작은 타입 경계 수정
- 자동 테스트로 확인 가능한 Domain 변경
- CI에서 재현 가능한 Build·Format·Lint 오류

## 3. 중간 검증 책임

사용자 수동 검사 전까지 중간 변경은 다음 자동 Gate가 담당한다.

- Structure·Security·Policy Validator
- StyLua
- Selene
- Production·Test·Multi-client·Persistence·Acceptance Rojo 정적 Build
- Production·Test Luau Type Analysis
- Unit·Integration·Security·Recovery Test
- Windows PowerShell 문서 계약 검사

정적 Persistence Place Build는 계속 수행할 수 있지만, 실제 Studio DataStore 연결·Load·Save·Reconnect 검사는 일반 기능 Build에서 수행하지 않는다.

자동 Gate가 실패한 상태에서는 사용자에게 Studio 검사를 요청하지 않는다.

## 4. 일반 기능 Build와 Persistence Batch 분리

### 일반 기능 Build

`slice01-acceptance.project.json`은 Studio Persistence를 비활성화한다.

```text
EnableStudioPersistence=false
```

일반 기능 Build의 범위:

- 입력
- 카메라
- Token 선택·이동
- Command·Projection
- UI 상태
- 메모리 내 Authority 상태

일반 기능 Build에서는 다음을 요구하지 않는다.

- Experience 게시
- DataStore API 연결
- 저장 로그 대기
- Stop·Play 재실행
- 저장 상태 복구 확인

### Persistence 전용 Batch

DataStore 검증은 관련 Persistence 변경을 충분히 모은 뒤 `persistence-acceptance.project.json`을 사용해 한 번에 수행한다.

Persistence Batch 범위:

- Load·Save
- Dirty·Flush
- Stop·Play Restore
- Reconnect Recovery
- Migration
- Conflict·Failure Recovery
- 필요한 경우 실제 Experience 게시

일반 기능 PASS는 Persistence PASS를 의미하지 않는다. 두 Gate의 Evidence는 분리해서 기록한다.

## 5. WASD 입력 소유권

WASD Character 이동 모드가 비활성화된 동안에는 World Camera가 WASD를 사용해 카메라를 이동한다.

```text
W → 카메라 전진
A → 카메라 좌측 이동
S → 카메라 후진
D → 카메라 우측 이동
```

WASD Character 이동 모드가 활성화되면 해당 모드 소유자는 다음 계약을 호출한다.

```lua
worldTokens.Camera:setMovementModeActive(true)
```

이때 Camera는 눌린 WASD 상태를 해제하고 입력을 Character 이동 모드로 전달한다. 이동 모드 종료 시 다음을 호출한다.

```lua
worldTokens.Camera:setMovementModeActive(false)
```

TextBox에 포커스가 있을 때도 Camera는 WASD를 소비하지 않는다.

## 6. 사용자에게 제공하는 Windows PowerShell Build 형식

사용자가 실행할 수 있는 유일한 기본 제공 형식은 저장소를 직접 갱신하고 정확한 Head를 검사하는 완전한 다중 행 Windows PowerShell 블록이다.

다음 형식을 그대로 사용한다.

```powershell
$ErrorActionPreference = "Stop"

Get-Process RobloxStudioBeta -ErrorAction SilentlyContinue |
    Stop-Process -Force

$repo = Join-Path $HOME "RVTT"
$roblox = Join-Path $repo "implementation\roblox"
$output = Join-Path $env:TEMP "RVTT-<BUILD-NAME>-<EXPECTED-HEAD>.rbxlx"

Set-Location $repo

git fetch origin
git switch planning/rvtt-remake
git pull --ff-only origin planning/rvtt-remake

$head = (git rev-parse --short HEAD).Trim()
Write-Host "현재 Head: $head"

if ($head -ne "<EXPECTED-HEAD>") {
    throw "예상 Head는 <EXPECTED-HEAD>이지만 현재 Head는 $head입니다."
}

Set-Location $roblox

Remove-Item $output -Force -ErrorAction SilentlyContinue
rojo build slice01-acceptance.project.json --output $output

Start-Process $output
```

필수 규칙:

- `$repo = Join-Path $HOME "RVTT"`를 사용한다.
- `planning/rvtt-remake` 브랜치를 fetch·switch·pull한다.
- 매 Build마다 정확한 7자리 Head를 검사한다.
- 결과 파일명에 기능명과 Head를 포함한다.
- 기본 Project는 `slice01-acceptance.project.json`이다.
- 사용자가 요청하지 않는 한 한 줄 명령으로 축약하지 않는다.
- 원격 `Invoke-Expression`, 중첩 `powershell -Command`, 인수형 Runner만 단독으로 제공하지 않는다.
- 코드 블록 일부가 아니라 처음부터 끝까지 실행 가능한 전체 블록을 제공한다.

Persistence 전용 Batch일 때만 Project와 출력 이름을 명시적으로 다음처럼 바꾼다.

```text
Project → persistence-acceptance.project.json
Output  → RVTT-persistence-batch-<EXPECTED-HEAD>.rbxlx
```

### PR-bound Batch Acceptance 예외

`planning/rvtt-remake`는 계속 일반 Build의 기본 예시다. 단, active coordinator task가 정확한 repository, Pull Request, branch, 검증된 target/result HEAD와 non-persistence acceptance project를 모두 지정한 경우에만 PR-bound Batch 예외를 사용할 수 있다.

```powershell
$repository = "Kaetaeru/RVTT"
$pullRequest = 2
$branch = "agent/survival-logistics-token-authoring"
$expectedHead = "<EXPECTED-7-CHAR-HEAD>"
$project = "<REQUESTED-NON-PERSISTENCE-ACCEPTANCE-PROJECT>"

git fetch origin $branch
git switch $branch
git pull --ff-only origin $branch

$head = (git rev-parse --short=7 HEAD).Trim()
if ($head -ne $expectedHead) {
    throw "PR #$pullRequest $repository expected Head $expectedHead but found $head"
}

rojo build $project --output (Join-Path $env:TEMP "RVTT-PR$pullRequest-$head.rbxlx")
```

필수 경계:

- coordinator가 지정하지 않은 branch나 project를 추론하지 않는다.
- 정확한 7자리 result HEAD가 아니면 Build하지 않는다.
- PR-bound 예외는 Persistence project에 사용하지 않는다.
- current-head Static Gate와 필수 Actions가 완료되지 않았으면 이 예외를 열지 않는다.
- 이 예외도 처음부터 끝까지 실행 가능한 전체 Windows PowerShell 블록으로 사용자에게 제공한다.

## 7. 진단 로그 규칙

각 Batch는 실패 원인을 한 번의 실행으로 분리할 수 있는 로그를 포함한다.

로그 형식:

```text
[RVTT <Subsystem>] event=<event> key=value key=value
```

일반 기능 Batch 필수 항목:

- Boot Runtime Mode
- Command 제출·승인·거부·Revision
- 입력 대상과 해석 결과
- Projection 생성·갱신·제거 요약
- 최종 Batch Summary의 PASS·FAIL 항목

Persistence Load·Save·Restore 로그는 Persistence 전용 Batch에서만 필수다.

Render frame이나 반복 Raycast 같은 고빈도 경로의 무제한 출력은 금지한다. 지속 입력은 한 입력 세션당 최초 성공 또는 최종 요약만 기록한다.

## 8. Acceptance Harness 규칙

Acceptance Harness는 다음 기능을 제공한다.

- 실제 Production Command·Projection 경로 사용
- 단계별 수동 버튼보다 가능한 한 자동 준비 사용
- 한 화면에서 전체 Batch 상태와 실패 항목 표시
- 실제 사용자 입력을 받은 뒤에만 입력 Check PASS
- 최종 `PASS` 또는 실패 항목 목록 출력
- 테스트 전용 Flag·Board·Camera·Diagnostics를 Production 구성과 분리

일반 Acceptance Harness는 Persistence를 사용하지 않는다. Persistence 전용 Harness만 실제 Production Persistence 경로를 사용한다.

## 9. 현재 Slice 01 World Interaction Batch

현재 일반 기능 Batch 범위:

```text
3D Token Projection
→ 화면·월드 좌표 기반 Token Picking
→ Raycast 실패 시 Screen-space Picking Fallback
→ 선택 Highlight·선택 상태 표시
→ Board Destination 표시
→ 서버 권위 movement.commit
→ Command Receipt·Revision 진단
→ 중클릭 Camera Orbit
→ WASD Camera Pan · Character 이동 모드 비활성 시
→ Mouse Wheel Zoom
→ F·Token Frame
→ 최종 Batch Summary
```

현재 Batch에서 제외하고 Persistence 전용 Batch로 이관한 항목:

```text
DataStore 연결
Persistence Save
Stop·Play Restore
Reconnect Recovery
Migration·Conflict Recovery
```

## 10. 완료 판정

일반 기능 Batch는 다음 조건을 모두 만족해야 수동 Gate로 이동한다.

```text
관련 기능 구현 완료
자동 회귀 테스트 추가
진단 로그와 최종 Summary 추가
DataStore 비활성 Acceptance Project 적용
Implementation·Documentation CI PASS
검증 Head 고정
전체 Windows PowerShell Build 블록 준비
```

Persistence Batch는 별도 Gate와 별도 Summary로 판정한다.

## 11. Grand Acceptance Campaign

개별 Batch 실행은 Grand Campaign Phase로 흡수한다.

```text
여러 Slice·복구·보안 변경 축적
→ Grand Manifest에 Phase 등록
→ 자동 Gate 전체 PASS
→ PowerShell 실행 1회
→ 여러 Studio Phase 순차 실행
→ 모든 실패 수집
→ JSON·Markdown 통합 Report
```

Grand Campaign은 하나의 Studio Play 세션이 아니다. 하나의 PowerShell Process가 필요한 Place를 모두 Build하고 Studio Phase를 순서대로 시작한다. 사용자가 각 Phase를 끝내고 Studio를 닫으면 다음 Phase가 자동으로 시작된다.

핵심 규칙:

- 첫 실패에서 Campaign을 중단하지 않는다.
- Summary가 없는 Phase는 PASS가 아니라 `incomplete`다.
- 아직 구현되지 않은 Phase는 `blocked`다.
- `blocked` Phase가 존재하면 전체 결과는 `PARTIAL`이며 Release PASS가 아니다.
- 일반 기능과 Persistence 결과는 같은 Report에서 별도 Phase로 보존한다.
- Persistence는 관련 변경을 축적한 Milestone에서만 `-IncludePersistence`로 포함한다.
- 공식 데이터·권리·Asset 승인이 필요한 Phase는 승인 전까지 실행하지 않는다.
- 결함은 Phase별 Micro-fix가 아니라 동일 Root Cause별 수정 Batch로 처리한다.
- 수정 후 선택 Phase만 재실행하지 않고 Grand Campaign 전체를 다시 실행한다.

Grand Campaign 사용자 실행 형식도 완전한 다중 행 Windows PowerShell 블록이어야 한다.

```powershell
$ErrorActionPreference = "Stop"

Get-Process RobloxStudioBeta -ErrorAction SilentlyContinue |
    Stop-Process -Force

$repo = Join-Path $HOME "RVTT"
$runner = Join-Path $repo "implementation\roblox\tooling\run-grand-acceptance.ps1"

Set-Location $repo

git fetch origin
git switch planning/rvtt-remake
git pull --ff-only origin planning/rvtt-remake

$head = (git rev-parse --short HEAD).Trim()
Write-Host "현재 Head: $head"

if ($head -ne "<EXPECTED-HEAD>") {
    throw "예상 Head는 <EXPECTED-HEAD>이지만 현재 Head는 $head입니다."
}

& $runner -ExpectedHead $head
```

DataStore Grand Milestone에서만 마지막 줄을 다음처럼 변경한다.

```powershell
& $runner -ExpectedHead $head -IncludePersistence
```

Grand Campaign Runner만 한 줄로 보내지 않는다. 저장소 Update, Branch 이동, 정확한 Head 검사와 Runner 실행이 모두 포함된 전체 블록을 제공한다.
