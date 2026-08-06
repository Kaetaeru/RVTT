# RVTT Roblox Implementation 현재 작업 순서

- 상태: `CONTEXTUAL_POINTER_ACTIONS_STATIC_READY_STUDIO_RETEST_REQUIRED`
- 문서 종류: Production Implementation Work Order
- 최종 갱신일: 2026-08-06
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
→ PASSED

Historical Roblox Studio Baseline
→ VERIFIED

Slice 01 기존 Token Pick·Move·Projection
→ USER VERIFIED · HEAD 582c1c4

기존 Camera WASD·Middle-button Pan·Frame
→ USER VERIFIED · HEAD 582c1c4

Contextual Pointer Actions
→ IMPLEMENTED · STATIC VERIFIED · STUDIO RETEST REQUIRED

Legacy-feel Camera
→ IMPLEMENTED · STATIC VERIFIED · MIDDLE-BUTTON ORBIT RETEST REQUIRED

Context Input Acceptance Host
→ IMPLEMENTED · ROJO BUILD PASS · STUDIO NOT EXECUTED

Grand Persistence Published Runner·Config·CI
→ EXECUTION CONTRACT READY

현재 작업
→ Context Input Runtime Evidence 이후 Human UI·Accessibility Evidence
```

## 2. 새 입력 계약

```text
선택 전 Token 좌클릭
→ Token 선택

Token 선택 후 대상 좌클릭
→ 현재 문맥의 기본 행동 실행 요청
→ 활성 Encounter Actor: rules.attack
→ Exploration Object: exploration.interact
→ Move Surface: movement.commit

Token 선택 후 대상 우클릭
→ 현재 사용자 권한·Turn·Opportunity로 요청 가능한 행동을 2열 버튼 테이블로 표시
→ 서버가 최종 권한과 규칙을 재검증

중클릭 드래그
→ 기존 우클릭 Camera Orbit 감각

Wheel
→ Zoom

Ctrl+Wheel
→ Camera Pivot Y 이동
```

## 3. 카메라 기준

업로드된 기존 CameraManager를 기준으로 다음 값을 적용한다.

- FOV 50
- 거리 65, 범위 20–130
- Pitch 45°, 범위 -85°–85°
- 회전 감도 0.004
- Wheel Step 5
- WASD 55 studs/s
- Smooth Speed 14

## 4. 자동 Gate

최신 Context Input Source에서 다음 Gate가 PASS했다.

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

위 결과는 Source·Build·Type Evidence이며 Studio Runtime PASS가 아니다.

## 5. 기존 Studio Evidence

```text
HEAD 582c1c4
[RVTT Batch Summary] batch=slice01-world-interaction result=PASS passed=16 failed=0 pending=0 revision=12
```

검증된 기존 범위:

- WASD Camera
- Middle-button 평면 Pan
- Wheel Zoom
- F Frame
- Token Pick·Highlight
- Destination Marker
- movement.commit
- Server Acceptance
- Projection Move

새 계약이 중클릭 의미와 좌·우클릭 의미를 변경하므로 기존 결과는 회귀 기준선으로만 유지한다.

## 6. Context Input Acceptance

`slice01-acceptance.project.json`에 별도 Context Input Host를 등록했다.

자동 준비 대상:

- Exploration Console
- Original Training Dummy
- 탐험·전투 모드 전환 버튼
- 9개 Human Input 판정 항목

성공 Summary:

```text
[RVTT Batch Summary] batch=contextual-pointer-actions result=PASS passed=9 failed=0 pending=0 revision=...
```

## 7. 다음 구현·검증 순서

| 순서 | 상태 | 작업 | 완료 조건 |
|---:|---|---|---|
| 1 | DONE | Grand Persistence 실행 계약 | Published Place Runner·Config·Report |
| 2 | STATIC_READY | Contextual Pointer Actions | 좌클릭 Default·우클릭 Action Table·서버 재검증 |
| 3 | RETEST_REQUIRED | Legacy-feel Camera | 중클릭 Orbit·WASD·Wheel·Ctrl+Wheel·F |
| 4 | IN_PROGRESS | UI·Accessibility Evidence | 메뉴 Focus·읽기 순서·대비·Screenshot Reference |
| 5 | QUEUED | Performance·Soak Host | Budget·다중 Client·장시간 Session |
| 6 | BLOCKED | Slices 13–15 Content | Source Version·Rights·Asset 승인 |
| 7 | QUEUED | Slice 16 Release Campaign | 전체 Phase·Migration·Runbook Gate |

## 8. 다음 Gate

```text
Context Pointer Studio Retest
→ 좌클릭 기본 행동·우클릭 행동표·중클릭 Orbit 확인

Human UI·Accessibility Evidence
→ Context Action Table 포함

DM·Player Multi-client Test
→ Context Input과 권한 표시가 안정된 뒤 진행
```
