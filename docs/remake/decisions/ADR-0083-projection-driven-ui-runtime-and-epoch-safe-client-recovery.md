# ADR-0083: Projection 기반 UI Runtime과 Epoch-safe Client Recovery

- 상태: 확정
- 결정일: 2026-08-04
- 관련 결정:
  - [`ADR-0059`](ADR-0059-versioned-command-protocol-and-projection-stream-synchronization.md)
  - [`ADR-0070`](ADR-0070-orthogonal-session-modes-contexts-overlays-and-transitions.md)
  - [`ADR-0071`](ADR-0071-input-context-selection-sessions-and-frozen-bindings.md)
  - [`ADR-0074`](ADR-0074-projection-only-camera-policies-with-separate-focus-and-follow.md)
  - [`ADR-0075`](ADR-0075-versioned-data-driven-and-fault-isolated-presentation-runtime.md)
  - [`ADR-0081`](ADR-0081-versioned-policy-composition-and-frozen-ruleset-snapshots.md)
- 관련 Architecture:
  - [`UI Projection, ViewModel, Input Context와 Recovery Runtime 계약`](../architecture/ui-projection-view-model-input-context-and-recovery-runtime-contract.md)

## 배경

RVTT의 UI는 Combat HUD, Character Sheet, Inventory, Journal, DM Workspace, Scene Editor, Prompt와 설정 화면을 포함한다.

각 화면이 서버 상태를 직접 구독하고, Remote를 직접 호출하며, Q/E 입력과 재접속 복구를 독자적으로 구현하면 다음 문제가 발생한다.

- 같은 Transaction의 여러 변경이 서로 다른 Frame에 부분 적용됨
- Command Result를 받은 UI가 서버 Projection보다 먼저 권위 값을 수정함
- 미발견 대상과 DM 전용 정보를 Client가 받은 뒤 화면에서만 숨김
- Reaction Prompt와 Selection이 재접속 후 사라지거나 중복 생성됨
- Rollback 이전 버튼과 Prompt가 새 AuthorityEpoch에서 다시 실행됨
- Text Input, Modal, Selection과 World Interaction이 같은 키를 동시에 소비함
- Panel 열림 상태가 Encounter·Downtime 같은 Gameplay Mode로 오인됨
- UI Component 오류가 전체 Client Gameplay를 중단함

기존 Networking, Session, Selection, Visibility와 Presentation 계약은 각자의 경계를 정의하지만, Client UI 전체가 공유하는 Replica, ViewModel, Input Context, Pending Command와 Recovery 수명주기는 별도 결정이 필요하다.

## 결정

### 1. UI는 Permission-aware Projection만 읽는다

```text
Projection Snapshot·Event Batch
→ Client Projection Replica
→ ViewModel
→ UI Component
```

일반 UI Component에 Raw Domain State와 Raw Domain Event를 제공하지 않는다.

비밀 정보는 Client에 보낸 뒤 숨기는 것이 아니라 Projection 생성 전에 제거한다.

### 2. Projection Batch는 원자적으로 적용한다

하나의 Transaction에서 공개된 변경은 하나의 Client Replica Commit으로 적용한다.

```text
Batch Staging
→ 전체 검증
→ Replica Revision 교체
→ ViewModel 갱신
→ UI Commit
```

Batch 일부를 먼저 화면에 표시하지 않는다.

### 3. UI 데이터 계층을 분리한다

```text
Projection Replica
Derived ViewModel
Local Workspace State
Ephemeral Interaction State
Authority-bound UI State
Recoverable Draft
```

Panel 위치, 배율과 접근성 설정은 Gameplay Authority가 아니다. Prompt, Selection과 Encounter Turn은 UI가 보여 주더라도 각 서버 Runtime의 권위 상태다.

### 4. Component는 ViewModel과 UI Intent만 사용한다

Component는 Remote, Domain Service, Workspace Query와 권위 Store를 직접 호출하지 않는다.

```text
Component Interaction
→ Semantic Input Action
→ UI Intent
→ Command·Read Request·Selection·Camera·Presentation Route
```

### 5. Q/E와 입력은 공통 Context Stack에서 한 번만 처리한다

기본 우선순위:

```text
Text Input
→ Critical Modal·Authority Prompt
→ Drag·Selection·Multistep Work
→ Focused Panel
→ Base Mode HUD·DM Workspace
→ Global Camera
```

가장 위의 유효 Context 하나만 입력을 소비한다. Component별 물리 키 감시는 금지한다.

### 6. Command Result와 Projection을 분리한다

`committed` Command Result는 서버가 Transaction을 확정했다는 뜻이지만 Client 권위 View가 적용됐다는 뜻은 아니다.

UI는 관련 Projection이 Replica에 반영된 뒤에만 `reconciled`로 처리한다. Command Result만으로 HP, Item, Turn과 Resource를 직접 수정하지 않는다.

### 7. Authority Prompt는 로컬 Modal과 다르다

Reaction, DM Approval과 Downtime Choice는 서버의 Pending Input이다.

Client가 Prompt 창을 닫아도 권위 Prompt는 완료되지 않는다. Q/E와 Option 선택은 명시적인 응답 Command를 제출하며, Prompt 종료는 Projection으로 확인한다.

### 8. Reconnect와 Rollback은 Epoch-safe Recovery를 사용한다

Projection Gap, 재접속 또는 Rollback 시:

```text
Authority-bound Input Gate 닫기
→ 이전 Epoch Context·Prompt·Selection·Prediction 무효화
→ Snapshot·Catch-up 원자 적용
→ Authority-bound UI를 Projection에서 재생성
→ 안전한 Layout·Preference 재결합
→ Focus 복원
→ Readiness Scope별 입력 활성화
```

이전 AuthorityEpoch의 Command, Prompt Response, Selection Binding과 Focus Token을 새 Branch에 재사용하지 않는다.

### 9. Panel 상태는 Gameplay Mode가 아니다

Character Sheet, Inventory, Journal, Settings와 DM Panel의 열림·닫힘은 기본적으로 Client Workspace State다.

Gameplay Mode와 Overlay는 Session Runtime이 소유하고 Projection으로 전달한다.

### 10. UI 오류는 Gameplay Authority와 격리한다

Panel과 Selector는 Error Boundary를 가진다. UI Animation, Tooltip 또는 Panel 오류가 서버 Transaction을 되돌리지 않는다.

Projection Replica 적용 실패처럼 권위 View의 정합성이 깨진 경우에는 Last Known Good Replica를 유지하고 Authority-bound 입력을 중지한 뒤 Resync한다.

## 결과

### 장점

- 모든 주요 UI가 같은 권위·입력·복구 원칙을 사용한다.
- 정보 공개가 UI 구현 실수에 의존하지 않는다.
- 재접속과 Rollback 후 Prompt·Selection·Pending Command를 안전하게 복구할 수 있다.
- Command Result와 Projection 순서 역전에 견딜 수 있다.
- 패널별 Component를 교체해도 Gameplay Runtime과 Network 계약을 우회하지 않는다.
- 로컬 레이아웃과 접근성 설정을 권위 Gameplay 상태와 독립적으로 유지할 수 있다.

### 비용

- Projection Replica Store, ViewModel Selector와 Intent Registry를 공통 기반으로 구현해야 한다.
- 작은 UI도 직접 Remote 호출 대신 Intent Route를 등록해야 한다.
- Projection Batch 적용과 Command Reconciliation 테스트가 필요하다.
- UI 상태를 Projection, Local, Ephemeral과 Authority-bound로 분류해야 한다.

이 비용은 화면마다 독자적인 상태 복사본과 복구 로직을 유지하는 비용보다 작다.

## 대안과 기각 이유

### 화면마다 서버 상태를 직접 구독

초기 구현은 빠르지만 Projection 적용 순서, 비밀 정보, 재접속과 Pending Command 처리 방식이 화면마다 달라진다. 기각한다.

### Command Result로 UI 상태 즉시 확정

Result 유실과 Projection 순서 역전에서 상태가 갈라지고, 사용자별 Disclosure View와 충돌한다. 기각한다.

### 모든 UI 상태를 서버에 저장

Hover, Tooltip, Panel 위치와 스크롤까지 서버 권위로 만들면 저장량과 결합도가 불필요하게 증가한다. 기각한다.

### UI 창을 Session Mode로 표현

Character Sheet와 Journal을 열 때마다 Gameplay Mode가 변해 Exploration·Encounter·Downtime 구조와 충돌한다. 기각한다.

## 구현 원칙 요약

1. UI는 Client-safe Projection만 읽는다.
2. Projection Batch는 원자적으로 Replica에 적용한다.
3. ViewModel은 Projection과 로컬 설정에서 결정적으로 파생한다.
4. Component는 UI Intent만 제출하고 Remote와 Domain Store를 직접 다루지 않는다.
5. Q/E와 물리 입력은 공통 Input Context Stack을 사용한다.
6. Command Result와 Projection Reconciliation을 분리한다.
7. Authority Prompt는 Projection에서 복구하고 응답 Command로만 종료한다.
8. Rollback과 재접속에서 이전 Epoch의 UI Token을 폐기한다.
9. Panel 상태와 Gameplay Mode를 분리한다.
10. UI 오류는 Gameplay Authority와 격리한다.
