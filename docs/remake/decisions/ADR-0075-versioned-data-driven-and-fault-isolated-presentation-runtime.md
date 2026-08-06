# ADR-0075: Versioned, Data-Driven and Fault-Isolated Presentation Runtime

- 상태: 승인
- 결정일: 2026-08-04

## Context

RVTT의 공격, 주문, 주사위, 상태, 상호작용, 카메라와 UI 연출은 플레이테스트 후 반복 조정될 가능성이 높다. 이를 기능 코드와 RuleExecution에 직접 결합하면 연출 수정이 규칙 회귀, 배포 위험과 시스템별 중복을 만든다.

기존 ADR-0046은 모듈형 Presentation Recipe와 확장 등록점을 채택했다. 이후 Camera, Visibility, RuleExecution, Roll Reveal과 Compiled Build 계약이 추가되었으므로 Presentation의 버전, Hot Swap, 오류 격리와 사용자별 접근성 경계를 상위 결정으로 확정할 필요가 있다.

## Decision

1. 모든 연출은 `PresentationIntent → CompiledPresentationRecipe → PlaybackPlan` 흐름을 사용한다.
2. Presentation Recipe는 데이터 기반 Source에서 컴파일되는 불변 버전으로 관리한다.
3. 진행 중 Playback은 시작 당시 Recipe Version과 Content Hash를 고정한다.
4. 플레이테스트 변경은 새 Recipe 버전 활성화로 처리하고, 이전 정상 버전으로 즉시 복원할 수 있어야 한다.
5. Presentation Module은 Registry 기반 타입으로 등록하며 Runtime 핵심 코드의 이름별 분기를 금지한다.
6. Presentation은 Authority State를 변경하지 않으며 실패가 Gameplay Transaction을 롤백시키지 않는다.
7. Camera는 직접 조작하지 않고 CameraRequest를 제출한다.
8. Audience별 Visibility·Knowledge Projection을 통과한 Anchor와 정보만 사용한다.
9. 품질·접근성·성능 저하는 계층형 Profile로 적용하며 핵심 판독성을 보존한다.
10. DM 연출 정책은 플레이어의 접근성 Hard Limit을 무시할 수 없다.
11. Marker와 Reveal Gate는 연출 순서를 조정하지만 hard timeout 후 반드시 진행한다.
12. 신뢰되지 않은 자유 Luau 실행은 Presentation Recipe에 허용하지 않는다.

## Consequences

### Positive

- 플레이테스트 후 코드 수정 없이 연출 조정과 교체가 가능하다.
- 공격·주문·UI가 같은 Playback, Queue와 실패 처리 계약을 사용한다.
- 한 모듈의 오류가 규칙과 다른 연출에 전파되지 않는다.
- 품질·접근성·캠페인 Theme를 같은 Recipe에서 파생할 수 있다.
- Hot Reload와 Rollback의 버전 경계가 명확해진다.

### Negative

- Recipe Compiler, Version Registry, Preview Tool과 Migration Adapter가 필요하다.
- Audience별 PlaybackPlan과 품질 Variant가 콘텐츠 제작 비용을 늘릴 수 있다.
- Marker와 CameraRequest의 디버깅을 위한 진단 도구가 필요하다.

## Rejected Alternatives

### 연출을 각 Action·Spell 코드에 직접 작성

수정 속도는 빠르지만 중복과 규칙 결합이 커지고 플레이테스트 변경 시 회귀 위험이 높아 거부한다.

### 진행 중 Playback도 최신 Recipe로 즉시 교체

연출 중간의 Module과 Marker가 달라져 공개 순서와 복구가 불안정해지므로 거부한다.

### Client가 Recipe와 Parameter를 자유롭게 선택

비밀 정보 유출, 자원 남용과 검증 우회 위험이 있어 거부한다.

### Presentation 실패 시 Gameplay도 롤백

시각 표현 오류가 권위 게임 결과를 무효화하는 구조이므로 거부한다.

## Related

- [`Presentation Runtime 계약`](../architecture/presentation-recipe-playback-priority-and-extension-runtime-contract.md)
- [`모듈형 VFX와 프레젠테이션 레시피 모델`](../architecture/modular-vfx-and-presentation-recipe-model.md)
- [`Camera Runtime 계약`](../architecture/camera-policy-focus-follow-and-presentation-runtime-contract.md)
- [`Dice와 Resolution Runtime 계약`](../architecture/dice-roll-check-save-attack-and-resolution-runtime-contract.md)
- [`Visibility, Knowledge와 Detection Runtime 계약`](../architecture/visibility-knowledge-detection-and-hover-information-runtime-contract.md)
