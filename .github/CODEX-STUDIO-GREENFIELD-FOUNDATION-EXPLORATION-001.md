# RVTT Studio Greenfield — Foundation + Exploration 001

- 상태: `ACTIVE · CURRENT_COMMAND`
- Build mode: `GREENFIELD_ARCHITECTURE_FIRST`
- Feedback mode: `TIGHT_USER_FEEDBACK_LOOP`
- 상위 포인터: [`CODEX-ACTIVE-TASK.md`](CODEX-ACTIVE-TASK.md)
- 개발 정책: [`../implementation/roblox/GREENFIELD-BUILD-POLICY.md`](../implementation/roblox/GREENFIELD-BUILD-POLICY.md)

## 목표

새 RVTT를 **시스템 골격부터** 구축하고 그 시스템을 통해 Exploration의 첫 플레이 가능한 기능을 만든다.

이 Command의 성공은 "Hero를 클릭할 수 있다"가 아니다. 다음 두 가지가 모두 성립해야 한다.

1. 기능이 명확한 책임 Module을 통해 동작한다.
2. 사용자가 실제 Studio에서 기능을 테스트하고 마음에 들지 않으면 즉시 수정할 수 있다.

## 구현 전 반드시 읽을 것

1. `AGENTS.md`
2. `.github/README.md`
3. `.github/CODEX-ACTIVE-TASK.md`
4. `implementation/roblox/GREENFIELD-BUILD-POLICY.md`
5. `implementation/roblox/MODULE-CONTRACTS.md`
6. `implementation/roblox/manifests/module-contracts.json`
7. 관련 Product·ADR·Spec
8. 필요한 Legacy Source — 참고/재사용 후보로만

## Phase A — System Foundation

먼저 아래 책임을 새 Greenfield Source에 구현한다.

```text
ClientBootstrap
→ ClientApp
   ├─ SemanticInputRouter
   ├─ CommandClient
   ├─ ProjectionReplica
   └─ WorldSystem

ServerBootstrap
→ ServerApp
   ├─ CommandRuntime
   ├─ AuthorizationService
   ├─ WorldState
   └─ ProjectionService
```

### Bootstrap 규칙

`ClientBootstrap.client.lua`와 `ServerBootstrap.server.lua`는 다음만 한다.

```text
Composition Root 찾기
→ App 생성 또는 require
→ start()
→ 치명적 Boot 실패 보고
```

다음을 Bootstrap에 넣지 않는다.

- 마우스 입력 의미 해석
- Token selection
- Camera movement
- World movement
- Context action
- Gameplay rule
- Command authorization
- Projection 계산
- UI rendering 세부

### Foundation 완료 조건

- 새/깨끗한 Studio Build가 Boot한다.
- ClientApp과 ServerApp이 각 시스템을 명시적으로 조립한다.
- Server authoritative mutation은 CommandRuntime 경계 밖에서 직접 수행하지 않는다.
- Client UI/Presenter는 Remote를 직접 호출하지 않는다.
- 각 Contract-bearing Module의 책임을 한 문장으로 설명할 수 있다.
- Studio-only 숨은 Production 로직이 없다.

Foundation은 사용자에게 보여줄 제품 기능이 없더라도 Codex가 직접 Boot/Output을 확인한다.

## Phase B — 첫 플레이 기능: Selection

Foundation 위에 다음 Module을 연결한다.

```text
SemanticInputRouter
→ SelectionController
→ local selection state
→ WorldPresenter
```

Selection은 서버 권위 Gameplay mutation이 아니다. 필요한 World projection을 읽고 Client local selection 상태만 소유한다.

첫 Play 결과에서 최소 다음을 확인한다.

- Hero Token이 실제 World에 보인다.
- Left Click이 Semantic Primary로 해석된다.
- SelectionController가 target을 결정한다.
- 선택 상태가 한 곳에만 소유된다.
- WorldPresenter가 선택 결과를 표시한다.
- Bootstrap이나 Presenter가 Selection 규칙을 대신하지 않는다.

## Human Checkpoint S1 — Selection

Selection이 처음 동작하면 **다음 기능 구현을 멈추고 사용자가 직접 확인할 수 있는 상태를 만든다.**

Codex 보고:

```text
CHECKPOINT: S1_SELECTION
STATUS: READY_FOR_USER_TEST
어떻게 테스트하는지
현재 Module 흐름
사용자가 봐야 할 항목
```

사용자 반응:

- `ACCEPTED` / 좋다 / 다음 → Camera로 진행
- `CHANGE_REQUESTED` / 마음에 안 듦 / 수정 요청 → **현재 Selection을 즉시 수정**
- `BLOCKED` → 원인을 해결하고 같은 Checkpoint 재시도

`CHANGE_REQUESTED`를 backlog로 보내거나 Camera 작업과 병행하지 않는다. 같은 Checkpoint에서 수정 → Play → 사용자 재확인을 반복한다.

## 이후 Checkpoint

Selection이 수용된 뒤 같은 패턴을 사용한다.

```text
C1 Camera
→ M1 Move
→ X1 Right-click Context Action
→ I1 Interaction
```

각 기능은 기존 시스템 책임을 통해 구현한다. 새 기능 때문에 Module 책임을 실질적으로 바꿔야 한다면 자동으로 구조를 변경하지 말고 사용자에게 먼저 제안한다.

## Move의 필수 시스템 경로

Move는 최소 다음 흐름을 가진다.

```text
MovementController
→ CommandClient
→ CommandRuntime
→ AuthorizationService
→ Movement Domain/handler
→ WorldState authoritative mutation
→ ProjectionService
→ ProjectionReplica
→ WorldPresenter
```

Move를 LocalScript에서 직접 Token Position 변경만으로 완료 처리하지 않는다.

## Legacy Source 사용

Legacy Source는 다음 순서로만 사용한다.

1. 역할과 실패 경험을 읽는다.
2. 현재 Greenfield Contract와 일치하는지 판단한다.
3. 재사용이 새 구조를 단순하게 할 때만 opt-in한다.
4. 재사용했다면 Greenfield 경계 안에서 조립한다.

Legacy Module이 존재한다는 이유만으로 그대로 복사하지 않는다.

## Anti-pattern

다음이면 현재 구현을 완료로 보지 않는다.

- LocalScript 하나가 Input + Selection + Camera + Move + UI를 모두 소유
- ServerScript 하나가 Remote + Authorization + Mutation + Projection을 모두 소유
- Bootstrap에 gameplay logic 존재
- UI가 Remote를 직접 호출
- Client가 authoritative World state를 직접 확정
- 기능을 보여주기 위해 Contract를 우회하는 별도 테스트 경로 생성

## Canonicalization

사용자가 Checkpoint를 수용하면 해당 시점의 Studio 구현을 `greenfield/src` Canonical Source에 정리한다.

- `module-contracts.json`의 해당 Module을 `PLANNED → IMPLEMENTED`로 변경한다.
- 실제 Stable Entry Point와 dependency를 계약과 맞춘다.
- Rojo Mapping에서 새 Source만으로 재현할 수 있게 한다.
- Focused Test를 추가/실행한다.

## 완료 보고

- 현재 Checkpoint
- 실제 시스템 흐름
- 새로 구현한 Module
- 선택적으로 재사용한 Legacy Module
- Studio Play 결과
- 사용자 피드백과 즉시 반영 내용
- Contract 상태 변경
- Focused Test
- 다음 Checkpoint
