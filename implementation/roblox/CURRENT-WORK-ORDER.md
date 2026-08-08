# RVTT Roblox Implementation 현재 작업 순서

- 상태: `FULL_UI_UX_ALIGNMENT_REQUIRED`
- 문서 종류: Production Implementation Work Order
- 최종 갱신일: 2026-08-06
- 상위 직접 플레이: [`ADR-0088`](../../docs/remake/decisions/ADR-0088-direct-play-pointer-grammar-and-feedback.md)
- 구현 직전 UI·UX: [`Full UI·UX Specification`](../../docs/remake/ui/shared/implementation-ready-ui-ux-and-settings-spec.md)
- UI·UX Gap Audit: [`Implementation Readiness Audit`](../../docs/remake/audits/ui-ux-implementation-readiness-gap-audit.md)
- UI Review Checklist: [`UI·UX Review Checklist`](../../docs/remake/ui/policies/UI-UX-REVIEW-CHECKLIST.md)
- Grand Campaign: [`GRAND-ACCEPTANCE-CAMPAIGN.md`](GRAND-ACCEPTANCE-CAMPAIGN.md)
- Grand Persistence: [`GRAND-PERSISTENCE-MILESTONE.md`](GRAND-PERSISTENCE-MILESTONE.md)
- Context Input: [`CONTEXTUAL-POINTER-ACTIONS.md`](CONTEXTUAL-POINTER-ACTIONS.md)
- 실행 테스트 규칙: [`EXECUTION-TEST-RULES.md`](EXECUTION-TEST-RULES.md)

## 1. 현재 상태

```text
16개 Slice Production Source
→ IMPLEMENTED BASELINE

Static·Security·Formatter·Lint·Rojo·Luau Type
→ PREVIOUS HEAD PASSED

Historical Roblox Studio Baseline
→ VERIFIED

Slice 01 기존 Token Pick·Move·Projection
→ USER VERIFIED · HEAD 582c1c4 · OLD INPUT CONTRACT

ADR-0088 Direct Play UX
→ TOP-LEVEL ACCEPTED

Full Screen·Settings·Flow Specification
→ IMPLEMENTATION READY

기존 Contextual Pointer Actions Source
→ ADR-0088 ALIGNED · LOCAL STATIC VERIFIED

기존 Player UI Source
→ BASELINE EXISTS · FULL SCREEN SPEC NOT ALIGNED

Grand Persistence Published Runner·Config·CI
→ EXECUTION CONTRACT READY

현재 작업
→ Full UI·UX Acceptance 확장
```

Input·Context Action, Exploration·Encounter HUD, Inventory·Journal·Settings, Entry·Role·Recovery, DM Workspace Source는 현재 계약에 정합화됐다. Acceptance 정합화와 새 current-HEAD Static Gate가 남아 있으므로 Studio Retest를 시작하지 않는다.

## 2. 목표 입력 계약

```text
선택 전 왼쪽 클릭
→ 조작 가능 Actor 선택

선택 후 왼쪽 클릭
→ 클릭 전에 표시된 기본 행동 요청 또는 Preview

오른쪽 클릭
→ Capability 기반 전체 Action Table

마우스 휠 클릭 드래그
→ Camera Orbit

Q
→ 최상위 Context 한 단계만 닫기·취소

E
→ Preview·선택·승인·확정 실행

ESC
→ Gameplay 의미 없음
```

### 기본 행동 우선순위

```text
조작 가능한 다른 아군
→ 선택 전환

적대 Actor + Encounter
→ 기본 공격 또는 지정된 기본 전투 행동

우호·중립 Actor
→ 대화·도움·상호작용

Exploration Object
→ 상태 기반 기본 상호작용

Move Surface
→ movement.commit
```

## 3. Full UI 화면 범위

### Shared Shell

- ModeRoleBadge
- PartyRail·ActiveActorPanel·ActionHotbar
- Minimap·Map·Journal·System Entry
- Tooltip·Toast·AuthorityPrompt·Recovery Layer

### Gameplay

- Exploration HUD·World Action Label·Movement Preview
- Encounter Initiative·Resource·EndTurn·Reaction·Dice·HP 0
- Downtime·Rest·Death Save
- Observer HUD

### Management

- Inventory·Equipment·Loot·Transfer·Identification
- Character Sheet
- Journal·Map·Ping
- Settings·Bindings·Accessibility

### Session·DM

- Entry·Character Assignment·Ready·Observer
- Role Change·Reconnect·Resync·Recovery
- DM Live Workspace·Player View Preview·Override

## 4. Action Availability 목표

```text
권한 없음·미인지
→ UI에 표시하지 않음

권한 있음·현재 불가능
→ 비활성 색상 버튼
→ 클릭 차단
→ Hover·Focus 시 커서 또는 Control 근처에 이유

권한 있음·현재 가능
→ 활성 버튼
```

버튼 옆에 가능 여부 문장을 상시 표시하지 않는다.

## 5. 직접 플레이 피드백 목표

- 클릭 전 기본 행동 이름·Cursor·Outline
- 이동 경로·거리·남은 이동력·위험 Preview
- 공격 사거리·범위·영향 대상·비용 Preview
- 이동·공격·상호작용 후 Actor Selection 유지
- 턴 전환 시 Camera 강제 이동 금지
- Pending·Denied·Stale·Projection Reconciliation 구분
- 일반 거부 사유를 Cursor·대상·관련 HUD 근처에 표시
- World·Action Table·Hotbar·Turn UI의 Projection Revision 일치

## 6. 초기 사용자 설정 목표

핵심 기본값:

```text
accent = gold
uiScale = 1.00
textScale = 1.00
hotbarRows = 2
partyRailMode = auto
combatLog = recent
minimap = medium · camera_up
tooltip = 0.25s
detailedTooltip = 0.75s
disabledReason = 0.15s
motion = full
turnFocus = soft_notification
edgePan = false
```

전체 Camera·Toast·Accessibility·Persistence 기본값은 상위 Full UI·UX Specification을 따른다.

## 7. 카메라 기준

사용자 제공 CameraManager 감각을 유지한다.

- FOV 50
- 거리 65, 범위 20–130
- Pitch 45°, 범위 -85°–85°
- 회전 감도 0.004
- Wheel Step 5
- WASD 55 studs/s
- Smooth Speed 14
- 중클릭 드래그 Orbit
- Wheel Zoom
- Ctrl+Wheel Pivot Y
- F·Space Frame
- 기본 Turn Focus는 Soft Notification
- Edge Pan 기본 Off

## 8. 기존 Evidence 경계

이전 Context Input Source에서 Static Gate가 통과했으나 새 UI·UX 정합화 뒤 다시 실행해야 한다.

기존 Studio Evidence:

```text
HEAD 582c1c4
[RVTT Batch Summary] batch=slice01-world-interaction result=PASS passed=16 failed=0 pending=0 revision=12
```

검증된 범위는 변경 전 Camera·Token Pick·Move·Projection이다. 새 Pointer, Screen Shell, Settings와 Accessibility의 Runtime Evidence가 아니다.

## 9. Acceptance 재작성 범위

### Input·Direct Play

- ESC Gameplay No-op
- Q 단계별 Context Pop
- 아군 좌클릭 선택 전환
- 기본 행동 클릭 전 표시
- 활성·비활성 Action Table
- 비활성 Hover·Focus 사유
- 권한 밖·미인지 Action 미노출
- 중클릭 Orbit
- 이동·공격·범위 Preview
- Selection 유지·Camera Soft Focus
- Pending·Denied·Stale·Revision 일관성

### Screen·Preference

- Exploration·Encounter Mode Composition
- Inventory·Loot·Transfer·Identification
- Journal·Map Permission·Navigation
- Settings 초기값·Reset·Binding Conflict
- Accent·Scale·Motion 변경 중 Focus·Selection 유지
- Entry·Role Change·Reconnect·Recovery
- Player·DM·Observer Projection 분리

## 10. 구현·검증 순서

| 순서 | 상태 | 작업 | 완료 조건 |
|---:|---|---|---|
| 1 | DONE | Grand Persistence 실행 계약 | Published Place Runner·Config·Report |
| 2 | DONE | ADR-0088 상위 기획 | Pointer·Q/E·Feedback·Continuity |
| 3 | DONE | Full UI·UX 구현 직전 명세 | 화면·Settings·Flow·Acceptance |
| 4 | DONE | Shared Shell·Preference Foundation | Layer·Mode·System·Theme·Settings Store |
| 5 | DONE | Input·Context Action 정합화 | Q·ESC·Left·Right·Middle·Availability |
| 6 | DONE | Exploration·Encounter HUD | Preview·Turn·Reaction·Selection Continuity |
| 7 | DONE | Inventory·Journal·Settings | 화면·Intent·Permission·Preference |
| 8 | DONE | Entry·Role·Recovery | Projection rebuild·Reconnect·Error Boundary |
| 9 | DONE | DM Live Workspace 정합화 | Player Preview·Override·Queue |
| 10 | IN_PROGRESS | Acceptance 확장 | Full UI·UX Matrix 등록 |
| 11 | BLOCKED | Studio Human Retest | Static Gate PASS 후 실행 |
| 12 | QUEUED | UI·Accessibility Evidence | Scale·Focus·Contrast·Motion·Screenshot |
| 13 | QUEUED | DM·Player·Observer Test | 권한별 Projection·Role Change |
| 14 | QUEUED | Grand Persistence Runtime | Published 7개 Phase |
| 15 | QUEUED | Performance·Soak | Budget·다중 Client·장시간 Session |
| 16 | BLOCKED | Slices 13–15 Content | Source Version·Rights·Asset 승인 |
| 17 | QUEUED | Slice 16 Release Campaign | 전체 Phase·Migration·Runbook Gate |

## 11. 다음 Gate

```text
Full UI·UX Source·Acceptance 정합화
→ Structure·Security·StyLua·Selene·Rojo·Luau
→ Exploration·Context Input Studio Retest
→ Inventory·Journal·Settings Human Evidence
→ Player·DM·Observer Role·Permission·Recovery Test
→ UI·Accessibility·Performance Evidence
→ Grand Persistence Runtime
```
