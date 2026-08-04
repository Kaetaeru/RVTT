# UI·UX Global Policy Completion Audit

- 상태: COMPLETE
- 문서 종류: UI·UX Policy Completion Audit
- 감사일: 2026-08-05
- Policy Hub: [`UI·UX Global Policies`](../ui/policies/README.md)
- Policy Work Order: [`UI·UX Policy Work Order`](../ui/policies/CURRENT-WORK-ORDER.md)
- Review Checklist: [`UI·UX Review Checklist`](../ui/policies/UI-UX-REVIEW-CHECKLIST.md)
- UI Main Guide: [`UI, Camera와 Presentation Guide`](../guides/ui/README.md)

## 1. 목적

Production Luau Script 작성 전에 RVTT 전체가 공유할 시각 언어와 UX 행동 기준이 존재하는지 검수한다.

검사 대상:

- Visual Design과 Semantic Token
- Input Context·Q/E·1–5·Pointer·Focus·Selection
- 정보 위계·전장 안전 영역·Panel·Navigation
- Pending·Receipt·Projection·Error·Retry·Resync·Reconnect·Rollback
- UI Scale·Contrast·Keyboard·Motion·Flash·Camera Comfort·저사양 Fallback
- Player·DM·Observer 공개 경계
- 구현 검수 Checklist와 Build Acceptance Gate

## 2. 산출물

```text
Visual Design Policy
→ COMPLETE

Interaction and Input Policy
→ COMPLETE

Information Architecture and Density Policy
→ COMPLETE

Feedback, Error and Recovery Policy
→ COMPLETE

Accessibility and Motion Policy
→ COMPLETE

UI·UX Review Checklist
→ COMPLETE
```

## 3. 기존 권위와의 정합성

### UI Runtime

정책은 다음 기존 경계를 유지한다.

- UI는 사용자별 Projection만 표시한다.
- Component는 Remote·Domain Store를 직접 호출하지 않는다.
- Command Result만으로 권위 수치를 변경하지 않는다.
- Projection Batch는 원자 적용한다.
- Authority Prompt와 Local Modal을 구분한다.
- Reconnect·Rollback 후 이전 Epoch UI Token을 폐기한다.

판정: `PASS`

### Input·Selection

- 물리 키와 Semantic Action을 분리한다.
- 가장 위의 Input Context 하나만 입력을 소비한다.
- Q는 한 단계 취소, E는 현재 공개된 확정·실행·상호작용이다.
- Hover·Focus·Selection·Camera Focus를 분리한다.
- Target·Binding은 Server 최신 Snapshot에서 재검증한다.

판정: `PASS`

### Camera·Presentation

- Camera와 Presentation은 Gameplay Authority가 아니다.
- Hover만으로 Camera를 이동하지 않는다.
- Presentation 실패가 Gameplay 결과를 변경하지 않는다.
- Reduced Motion·Flash·Shake Hard Limit이 DM 요청보다 우선한다.

판정: `PASS`

### Visibility·Security

- DM 전용 정보를 Player Client에 전달한 뒤 숨기지 않는다.
- Color, Tooltip, Error, Search Count와 Diagnostic으로 비밀 정보를 누출하지 않는다.
- Player View Preview와 DM-only Source를 분리한다.

판정: `PASS`

## 4. 새로 고정된 구현 정책

기존 문서에 흩어져 있던 다음 사항을 전역 Gate로 통합했다.

- Dark Tactical Fantasy + Professional Tool 시각 정체성
- Semantic Color·Typography·Spacing·Radius·Motion Token
- Component 상태 Variant의 공통 이름
- 위험도 Tier 0–3 확인 정책
- Primary Surface·정보 Priority 1–3·Progressive Disclosure Level 0–3
- Action Lifecycle `submitted → receipt → awaiting_projection → reconciled`
- Error Surface 선택과 사용자 메시지 문법
- Full·Reduced·Minimal Motion Profile
- UI Scale 0.80–1.40 구조
- Low-end Fallback에서 절대 제거하지 않을 핵심 정보
- 화면·Component·Flow별 Review Checklist

이 항목은 Gameplay 규칙이나 Authority를 새로 만들지 않는다.

## 5. 기존 화면 문서와의 관계

다음 화면별 문서는 유지한다.

- Combat HUD
- Character Sheet
- Shared Wireframe
- Common Input
- DM Workspace
- Scene Editor

Global Policy는 이 문서들의 시각·행동 공통 기준이다. 기존 문서의 픽셀 수치·Wireframe·화면별 Flow가 Policy와 충돌하면 다음 순서로 처리한다.

```text
Architecture·ADR 확인
→ Global Policy
→ 화면별 문서 갱신
→ Implementation Spec·Script
```

기존 `common-input-grammar.md`의 Q/E·1–5 의미는 유지한다. 문서 안의 폐기된 Product 문서 링크는 권위 근거로 사용하지 않고 현재 Architecture와 Policy를 우선한다.

## 6. 구현 Gate 판정

Production UI Script는 다음을 모두 만족해야 한다.

- Policy Hub와 Review Checklist 연결
- Semantic Token 사용
- Input Context 사용
- Authority Result와 Local Preview 분리
- Loading·Empty·Denied·Stale·Error·Recovery 상태
- Player·DM·Observer Projection 분리
- Accessibility·Motion Profile 대응
- Slice별 UI Scenario와 Roblox Integration Test 계획

판정:

```text
UI·UX Policy Foundation
→ COMPLETE

Production Script 자동 승인
→ NO

다음 단계
→ implementation/roblox Workspace 생성
→ Slice 01 Script Manifest
→ Script를 하나씩 작성·검수
```

## 7. 남은 측정 항목

다음은 실제 Roblox Prototype과 Profile 이후 확정한다.

- Font Family와 한국어 렌더링
- Theme 대비·저사양 표시 검증
- Animation Duration 조정
- Tooltip Delay
- Panel·List Virtualization Budget
- UI Commit Frame Budget
- Camera 감도·Zoom·Occlusion 보정 속도
- Flash·Shake 실제 Hard Limit

현재 Policy의 구조를 바꾸지 않는 측정형 기본값이다.

## 8. 최종 판정

```text
UI Visual Policy
→ COMPLETE

UX Interaction·Information·Feedback·Recovery·Accessibility Policy
→ COMPLETE

Implementation Review Gate
→ COMPLETE

Production UI Implementation
→ NOT STARTED
```
