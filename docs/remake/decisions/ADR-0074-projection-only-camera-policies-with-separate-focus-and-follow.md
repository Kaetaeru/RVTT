# ADR-0074: Projection-only Camera Policies with Separate Focus and Follow

- 상태: Accepted
- 작성일: 2026-08-04

## Context

RVTT의 카메라는 탐험, Encounter, Selection, 주사위·주문 연출, DM 관전, Replay, Rollback과 Scene 전환에서 공통으로 사용된다.

각 시스템이 Roblox Camera를 직접 조작하면 다음 문제가 생긴다.

- 높은 우선순위 연출이 낮은 우선순위 Focus와 충돌한다.
- 연출 종료 후 사용자의 이전 카메라 상태를 복원하기 어렵다.
- Selection과 Hover가 과도한 자동 이동을 유발한다.
- 스트리밍·재접속·Replay에서 Workspace Instance 참조가 깨진다.
- DM Observe가 제어권 이전과 혼동될 수 있다.
- 카메라 가림 보정이 비밀 정보를 유출할 수 있다.

또한 현재 따라가는 대상과 현재 관심 대상은 서로 다를 수 있다.

## Decision

카메라는 Gameplay Authority가 아닌 사용자별 Projection·Presentation Runtime으로 취급한다.

모든 시스템은 Camera를 직접 조작하지 않고 타입 있는 `CameraRequest`를 제출한다. Camera Runtime은 요청의 우선순위, 취소 정책, 지속 시간, 사용자 설정과 현재 정책을 평가한다.

`Follow Target`과 `Focus Target`을 독립적으로 관리한다.

- Follow Target은 카메라의 장기 기준점이다.
- Focus Target은 현재 화면 안에 유지하거나 강조할 관심 대상이다.
- Hover는 Focus를 변경하거나 CameraRequest를 생성하지 않는다.

카메라 Target은 Workspace Instance가 아니라 권한 검사를 마친 Projection Reference 또는 안전한 Transform Snapshot을 사용한다.

기본 요청 우선순위는 다음과 같다.

```text
hard_scene_transition
> explicit_dm_observe
> replay
> required_resolution_presentation
> optional_presentation
> selection_focus
> follow_actor
> free
```

높은 우선순위 요청이 끝나면 이전 Transform, Follow, Focus, ViewY와 자유 조작 상태를 복원한다.

Exploration은 Free Camera를 기본으로 하고, Encounter는 Follow Actor와 Free Override를 결합한다. 전투 중 토큰 WASD 이동은 금지하지만 카메라 WASD 이동은 허용한다.

DM Observe와 Player View Preview는 카메라·Projection Audience만 바꾸며 Actor 제어권을 변경하지 않는다.

## Consequences

### Positive

- Selection, Spell, Dice와 VFX가 같은 카메라 요청 경계를 사용한다.
- 사용자 자유 카메라와 자동 Focus가 충돌하지 않는다.
- Replay, Rollback, Reconnect와 Streaming에서 Target 복구가 가능하다.
- DM Observe와 Gameplay Control의 권위가 분리된다.
- 비밀 정보가 Workspace 탐색이나 가림 보정으로 노출되는 것을 막는다.
- Focus와 Follow를 함께 사용해 전술 카메라 움직임을 최소화할 수 있다.

### Negative

- CameraRequest 우선순위·복원 스택·timeout 관리가 필요하다.
- 각 Presentation 기능이 직접 Camera를 조작하는 것보다 초기 구현량이 늘어난다.
- 사용자 설정과 Motion Safety를 요청 해석에 함께 반영해야 한다.

## Rejected Alternatives

### 각 시스템이 Camera를 직접 조작

우선순위와 복원이 분산되고 테스트가 어려워 거부한다.

### Focus와 Follow를 하나의 Target으로 통합

전투에서 자신의 캐릭터를 따라가며 적을 화면에 유지하는 요구를 표현하지 못하므로 거부한다.

### Hover가 Camera Focus를 자동 변경

마우스 이동마다 카메라가 흔들리고 정보 확인과 카메라 이동이 결합되므로 거부한다.

### 카메라 위치를 시야·Selection 권위에 사용

카메라는 사용자별 Presentation이며 Character의 규칙상 관찰 위치가 아니므로 거부한다.
