# RVTT Greenfield Build Policy

- 상태: `ACTIVE · CURRENT_IMPLEMENTATION_POLICY`
- 최종 갱신일: 2026-08-12

## 1. 목적

새 RVTT는 **Architecture-first Greenfield + 빠른 Human Feedback** 방식으로 만든다.

둘 중 하나만 하면 실패다.

- 구조 없이 기능만 빨리 만들기 → 데모 Script가 된다.
- 구조만 오래 만들기 → 실제 제품 피드백이 늦어진다.

따라서 다음 루프를 사용한다.

```text
다음 사용자 기능에 필요한 최소 시스템 경계 설계
→ Module Contract PLANNED
→ Studio에서 시스템 골격 구현
→ 작은 Playable Capability 연결
→ 사용자 테스트
→ 즉시 수정 또는 수용
→ 다음 Capability
```

## 2. 시스템은 기능보다 먼저, 하지만 한 Checkpoint만 앞서간다

현재 Checkpoint에 필요한 책임은 기능 구현 전에 분리한다. 그러나 먼 미래 Slice의 Manager를 미리 만들지 않는다.

예: Selection을 만들기 전에 필요한 것

```text
ClientApp
SemanticInputRouter
WorldSystem
SelectionController
WorldPresenter
ProjectionReplica
```

Move를 시작할 때 추가되는 것

```text
MovementController
CommandClient
CommandRuntime
AuthorizationService
Movement Domain
WorldState
ProjectionService
```

## 3. Composition Root

Client/Server Bootstrap은 허용되며 권장한다.

```text
ClientBootstrap.client.lua → ClientApp.start()
ServerBootstrap.server.lua → ServerApp.start()
```

Bootstrap은 조립·Lifecycle 시작·치명적 Boot 진단만 담당한다. Gameplay logic을 소유하지 않는다.

## 4. 책임 기반 설계

각 시스템은 아래 질문에 답할 수 있어야 한다.

- 누가 이 상태를 소유하는가?
- 누가 입력 의미를 해석하는가?
- 누가 서버에 Intent를 보낼 수 있는가?
- 누가 Authorization을 판정하는가?
- 누가 authoritative state를 바꾸는가?
- 누가 viewer별 Projection을 만드는가?
- 누가 화면에 표시하는가?

답이 "그 LocalScript가 다 한다"면 구조가 잘못된 것이다.

## 5. 첫 Human Feedback Loop

첫 사용자 체크포인트는 `S1_SELECTION`이다.

```text
구현
→ Codex 자체 Play/Output 확인
→ 사용자에게 Studio 상태와 테스트 방법 전달
→ 사용자 직접 조작
```

사용자 결과는 다음 중 하나다.

```text
ACCEPTED
CHANGE_REQUESTED
BLOCKED
```

`CHANGE_REQUESTED`이면:

1. 다음 Checkpoint 착수를 중단한다.
2. 현재 기능을 즉시 수정한다.
3. 같은 기능을 다시 Play한다.
4. 사용자에게 다시 확인받는다.

사용자 피드백을 여러 기능 뒤에 모아서 한 번에 고치지 않는다.

## 6. 자동 수정과 사용자 결정 Gate

바로 수정 가능:

- 명확한 버그
- 현재 UX 의도 안의 위치·크기·반응 조정
- helper 함수 분해
- Contract를 바꾸지 않는 구현 개선

먼저 사용자에게 제안:

- Product 의미 변경
- 입력 문법 변경
- Server/Client Authority 변경
- Module 책임의 실질적 분리·통합
- 새로운 핵심 UX 패턴
- 개발 프로세스 변경

## 7. Legacy Source

Legacy는 실패 이력과 구현 아이디어를 배우기 위한 자료다.

```text
읽기
→ 책임 이해
→ 현재 계약과 비교
→ 재사용 가치 판단
```

재사용은 기본값이 아니다. 재사용 Module도 Greenfield Composition과 Contract 아래에 들어와야 한다.

## 8. Canonicalization

Studio에서 수용된 구현은 곧바로 `greenfield/src`로 정규화한다.

- Studio-only Production logic 금지
- Rojo로 재현 가능한 Instance 구조
- Contract status 갱신
- Focused Test 추가

다음 기능으로 넘어가기 전에 현재 수용된 Checkpoint가 GitHub에서 재현 가능해야 한다.

## 9. 금지되는 완료 판정

다음만으로 완료라고 하지 않는다.

- 화면에서 동작해 보임
- LocalScript 하나로 입력부터 UI까지 처리됨
- ServerScript 하나로 Remote부터 state mutation까지 처리됨
- 과거 Acceptance가 PASS였음
- Static CI가 PASS였음

완료는 **책임 구조 + 실제 Play + 사용자 수용 + Canonical Source**가 함께 있어야 한다.
