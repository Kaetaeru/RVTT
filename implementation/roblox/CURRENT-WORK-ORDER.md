# RVTT Roblox Implementation 현재 작업 순서

- 상태: `ADR_0088_ALIGNMENT_IN_PROGRESS`
- 문서 종류: Production Implementation Work Order
- 최종 갱신일: 2026-08-06
- 상위 기획: [`ADR-0088 Direct Play UX`](../../docs/remake/decisions/ADR-0088-direct-play-pointer-grammar-and-feedback.md)
- Grand Campaign: [`GRAND-ACCEPTANCE-CAMPAIGN.md`](GRAND-ACCEPTANCE-CAMPAIGN.md)
- Grand Persistence: [`GRAND-PERSISTENCE-MILESTONE.md`](GRAND-PERSISTENCE-MILESTONE.md)
- Context Input: [`CONTEXTUAL-POINTER-ACTIONS.md`](CONTEXTUAL-POINTER-ACTIONS.md)
- Grand Manifest: [`grand-acceptance-manifest.json`](grand-acceptance-manifest.json)
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

기존 Contextual Pointer Actions Source
→ STATIC VERIFIED · ADR-0088 NOT ALIGNED

기존 Context Input Acceptance Host
→ IMPLEMENTED · INSUFFICIENT FOR ADR-0088

Grand Persistence Published Runner·Config·CI
→ EXECUTION CONTRACT READY

현재 작업
→ ADR-0088 Source·UI·Acceptance 정합화
```

기존 Context Input Source는 ESC 사용, 실행 가능 행동 중심 Action Table과 제한된 Preview를 포함하므로 새 Contract의 Studio Retest를 시작하지 않는다.

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

## 3. Action Availability 목표

```text
권한 없음·미인지
→ UI에 표시하지 않음

권한 있음·현재 불가능
→ 비활성 색상 버튼
→ 클릭 차단
→ Hover 시 커서 옆 불가능 사유

권한 있음·현재 가능
→ 활성 버튼
```

버튼 옆에 가능 여부 문장을 상시 표시하지 않는다.

## 4. 직접 플레이 피드백 목표

- 클릭 전 기본 행동 이름·Cursor·윤곽
- 이동 경로·거리·남은 이동력·위험 Preview
- 공격 사거리·범위·영향 대상·명중 조건 Preview
- 이동·공격·상호작용 후 Actor 선택 유지
- 턴 전환 시 Camera 강제 이동 금지
- Pending·승인·거부 피드백 구분
- 일반 거부 사유를 커서·대상·관련 HUD 근처에 표시
- World·Action Table·Hotbar·Turn UI의 Projection Revision 일치

## 5. 카메라 기준

업로드된 기존 CameraManager 감각을 유지한다.

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

## 6. 기존 자동 Gate

ADR-0088 이전 Context Input Source에서 다음 Gate가 PASS했다.

- Structure·Security·Input Policy
- StyLua
- Selene
- Production·Test·Grand·Persistence·Slice 01 Rojo Build
- Production·Test Luau Type Analysis
- Acceptance Bootstrap
- Grand Harness
- Production Lease
- Grand Persistence
- Documentation Validation

위 결과는 이전 Source·Build·Type Evidence이며 ADR-0088 정합화 후 다시 실행해야 한다.

## 7. 기존 Studio Evidence

```text
HEAD 582c1c4
[RVTT Batch Summary] batch=slice01-world-interaction result=PASS passed=16 failed=0 pending=0 revision=12
```

검증된 범위:

- WASD Camera
- 변경 전 Middle-button 평면 Pan
- Wheel Zoom
- F Frame
- Token Pick·Highlight
- Destination Marker
- movement.commit
- Server Acceptance
- Projection Move

새 Contract가 좌·우·중클릭 의미와 UI Feedback을 변경하므로 기존 결과는 회귀 기준선으로만 유지한다.

## 8. Acceptance 재작성 범위

기존 9개 Context Input 항목을 ADR-0088 기준으로 확장한다.

- ESC Gameplay No-op
- Q 단계별 Context Pop
- 아군 좌클릭 선택 전환
- 기본 행동 클릭 전 표시
- 활성·비활성 Action Table
- 비활성 Hover 사유
- 권한 밖·미인지 행동 미노출
- 중클릭 Orbit
- 이동·공격·범위 Preview
- 선택 유지
- Camera Soft Focus
- Pending·승인·거부
- Local Error Feedback
- Projection Revision 일관성

## 9. 다음 구현·검증 순서

| 순서 | 상태 | 작업 | 완료 조건 |
|---:|---|---|---|
| 1 | DONE | Grand Persistence 실행 계약 | Published Place Runner·Config·Report |
| 2 | DONE | ADR-0088 상위 기획 | Pointer·Q/E·Feedback·Continuity 계약 |
| 3 | IN_PROGRESS | Input Source 정합화 | ESC 제거·Q Context Pop·Pointer 재연결 |
| 4 | QUEUED | Action Projection 정합화 | 비활성색·Hover 사유·권한 숨김·안정 정렬 |
| 5 | QUEUED | Direct Feedback 정합화 | Cursor·Preview·Pending·Local Error |
| 6 | QUEUED | Selection·Turn·Camera 연속성 | 선택 유지·Soft Focus·가림 보정 |
| 7 | QUEUED | Acceptance 확장 | ADR-0088 항목 등록 |
| 8 | BLOCKED | Context Input Studio Retest | 정적 Gate PASS 후 실행 |
| 9 | QUEUED | Human UI·Accessibility | Tooltip·Focus·읽기 순서·대비·Screenshot |
| 10 | QUEUED | DM·Player·Observer Test | 권한별 Action Projection |
| 11 | QUEUED | Grand Persistence Runtime | Published 7개 Phase |
| 12 | QUEUED | Performance·Soak Host | Budget·다중 Client·장시간 Session |
| 13 | BLOCKED | Slices 13–15 Content | Source Version·Rights·Asset 승인 |
| 14 | QUEUED | Slice 16 Release Campaign | 전체 Phase·Migration·Runbook Gate |

## 10. 다음 Gate

```text
Input·UI·Acceptance 정합화
→ Structure·Security·StyLua·Selene·Rojo·Luau
→ Context Pointer Studio Retest
→ Human UI·Accessibility Evidence
→ DM·Player·Observer Multi-client Test
→ Grand Persistence Runtime
```
