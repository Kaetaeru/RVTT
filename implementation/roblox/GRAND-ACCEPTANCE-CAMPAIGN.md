# RVTT Grand Acceptance Campaign

- 상태: `FOUNDATION_IMPLEMENTED`
- 목적: 사용자가 한 번의 Windows PowerShell 실행으로 현재 실행 가능한 모든 Acceptance 환경을 순차 실행하고 하나의 결함 보고서를 얻는다.
- Manifest: [`grand-acceptance-manifest.json`](grand-acceptance-manifest.json)
- Runner: [`tooling/run-grand-acceptance.ps1`](tooling/run-grand-acceptance.ps1)

## 1. 실행 모델

Grand Acceptance는 하나의 Roblox Studio Play 세션이 아니다.

```text
PowerShell 실행 1회
→ 정적·Rojo Build 전체 실행
→ Unit·Integration Studio Phase
→ Slice 01 World Interaction Phase
→ Multi-client Authority Phase
→ 선택적 Persistence Phase
→ 향후 Slice·Fault·UI·Performance Phase
→ JSON·Markdown 통합 보고서
```

Studio Phase가 끝나면 Studio를 닫는다. 같은 PowerShell Process가 다음 Phase를 자동으로 시작한다.

## 2. 핵심 원칙

- 첫 실패에서 Campaign을 중단하지 않는다.
- 가능한 모든 Phase를 끝까지 실행해 실패를 한 번에 수집한다.
- 각 Phase는 독립 Summary Token과 PASS Regex를 가진다.
- Studio 종료 후 최근 Roblox Log에서 Summary를 수집한다.
- 모든 Phase 결과를 하나의 JSON·Markdown 보고서로 합친다.
- 아직 구현되지 않은 Phase는 `blocked`로 표시하며 PASS로 위장하지 않는다.
- 일반 기능과 Persistence Evidence는 같은 보고서에 들어가더라도 Phase 단위로 분리한다.
- 공식 데이터·권리 검토가 필요한 Content Phase는 승인 전까지 `blocked`다.

## 3. 현재 실행 가능한 범위

```text
static-build
unit-integration-baseline
slice01-world-interaction
multi-client-authority
```

선택적으로 `-IncludePersistence`를 사용하면 다음 Deferred Phase도 Campaign에 포함한다.

```text
live-datastore-baseline
persistence-restart-recovery
```

Persistence Phase는 게시된 Experience와 Studio API Access가 필요하다.

## 4. 아직 Blocked인 범위

- Slices 02–12 전용 Grand Harness
- Slices 13–15 공식 데이터·권리·Asset 승인
- UI Visual·Accessibility Human Review 자동 수집
- Network·Storage Fault Injection Host
- Performance·Soak·Capacity Host
- Slice 16 Full-session Release Gate

Blocked Phase는 Manifest에 이미 등록한다. 구현이 완료되면 `status`, `project`, `summaryToken`, `passRegex`를 갱신해 같은 Runner에 연결한다.

## 5. 보고서

기본 출력 위치:

```text
%TEMP%\RVTT-Grand-Acceptance\<timestamp>-<head>\
```

생성 파일:

```text
RVTT-grand-acceptance-report.json
RVTT-grand-acceptance-report.md
places\*.rbxlx
```

최종 로그:

```text
[RVTT Grand Summary] campaign=rvtt-grand-acceptance result=... execution=... passed=... failed=... incomplete=... prepared=... blocked=... head=...
```

판정:

- `PASS`: 선택된 Phase가 모두 PASS이고 Blocked·Prepared가 없음
- `PARTIAL`: 선택된 Phase는 PASS했지만 아직 Blocked 또는 `-NoOpen` Prepared Phase가 있음
- `FAIL`: 실행한 Phase에 FAIL 또는 Summary 미발견이 있음

## 6. 결함 처리

```text
Grand Campaign 끝까지 실행
→ 실패 목록 수집
→ 동일 Root Cause끼리 통합
→ Subsystem별 수정 Batch
→ 자동 Gate
→ Grand Campaign 전체 재실행
```

카메라·입력·Projection·Persistence처럼 같은 원인에서 파생된 실패를 항목별 Micro-fix로 처리하지 않는다.

## 7. 사용자 실행 계약

사용자에게는 항상 다음 요소를 포함한 완전한 다중 행 Windows PowerShell 블록을 제공한다.

```text
$ErrorActionPreference = "Stop"
RobloxStudioBeta 종료
$HOME\RVTT 저장소 이동
planning/rvtt-remake fetch·switch·pull
정확한 7자리 Head 검사
run-grand-acceptance.ps1 실행
```

한 줄 Bootstrap, 원격 `Invoke-Expression`, 중첩 `powershell -Command`는 제공하지 않는다.
