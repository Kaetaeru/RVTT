# ADR-0067: 2024 기본 행동은 등록된 ActionCapability로 지원한다

- 상태: 확정
- 결정일: 2026-08-04
- 관련 문서:
  - [`Character Action Runtime 계약`](../architecture/character-action-opportunity-and-2024-core-action-runtime-contract.md)
  - [`Character Runtime 계약`](../architecture/character-runtime-and-compiled-character-build-contract.md)
  - [`Rule Runtime Orchestrator 계약`](../architecture/rule-runtime-orchestrator-and-pending-execution-contract.md)
  - [`능동형 특성과 행동 내부 실행 모델`](../systems/rules/active-feature-and-action-container-execution-model.md)

## 배경

RVTT는 D&D 2024 5e의 플레이어 캐릭터 콘텐츠를 폭넓게 지원한다. 그러나 공격, 회피, 수색, 물체 사용과 즉흥 행동을 UI 버튼이나 기능별 별도 코드로 구현하면 다음 문제가 생긴다.

- 행동 경제와 비용 소비가 기능마다 달라진다.
- Class Feature, Spell, Item과 기본 행동이 서로 다른 실행 경로를 사용한다.
- Ready, Reaction, Extra Attack과 이동 사이 실행 순서가 깨진다.
- DM 판정이 필요한 Influence와 즉흥 행동을 표현하기 어렵다.
- NPC 대화 시스템 비목표와 Influence 행동 지원이 혼동된다.

## 결정

D&D 2024 기본 규칙의 다음 행동을 등록된 `ActionCapability`로 지원한다.

```text
Attack
Dash
Disengage
Dodge
Help
Hide
Influence
Magic
Ready
Search
Study
Utilize
```

또한 다음 규칙상 파생 행동을 같은 Runtime에 연결한다.

- Grapple과 Shove: Attack 행동의 Unarmed Strike 선택
- Escape Grapple: 별도 Action Capability
- Opportunity Attack: Reaction Capability
- Improvised Action: DM Adjudication 기반 Assisted Capability
- Release Grapple 등 행동 비용 없는 선언: `no_action_required`

## 행동별 구현 원칙

- `Attack`은 여러 공격 Unit을 가질 수 있는 Action Container다.
- `Magic`은 단일 범용 실행이 아니라 Spell, Magic Item과 Magical Feature Capability의 상위 분류다.
- `Ready`는 Action을 소비하고 저장 가능한 Trigger와 Reaction Offer를 만든다.
- `Influence`는 자동 NPC 대화 트리가 아니라 DM 판정 보조 흐름이다.
- `Search`와 `Study`는 숨은 DC와 결과 공개를 DM 권한 아래 둔다.
- `Utilize`는 비마법 Object Interaction을 사용하며 Magic Item은 `Magic`으로 처리한다.
- 즉흥 행동은 완전 자동화를 강제하지 않고 Guided 또는 Assisted 실행으로 전환한다.

## 역할 경계

플레이어는 제어 중인 Actor의 행동 의도, 대상과 접근법을 제출한다.

DM은 비밀 DC, 상황 적격성, Influence와 즉흥 행동의 가능 여부, 결과 공개 범위를 판정한다.

DM Override와 플레이어 정상 행동은 같은 이름으로 합치지 않는다. UI와 Command 권한을 분리한다.

## 결과

### 장점

- 기본 행동, Feature, Spell과 Item이 같은 Capability·RuleExecution 경로를 사용한다.
- 2024 규칙의 행동 목록을 폭넓게 지원하면서 즉흥 행동도 막지 않는다.
- Ready, Reaction, Action Container와 이동 중단을 기존 Runtime에 자연스럽게 연결한다.
- NPC 대화 시스템을 만들지 않고도 Influence 판정을 지원한다.
- 자동화 불가능한 상황을 DM 판정으로 안전하게 넘길 수 있다.

### 비용

- 행동별 Capability Definition과 Projection이 필요하다.
- DM Adjudication Pending 상태와 UI를 구현해야 한다.
- Search, Hide와 Utilize가 Perception·Spatial·Interaction 시스템에 의존한다.
- 공식 규칙 변경 시 기본 행동 Content Pack과 테스트를 갱신해야 한다.

## 대안

### 행동 이름별 하드코딩

초기 구현은 빠르지만 Feature와 예외가 늘어날수록 실행 경로가 분산되어 채택하지 않는다.

### 전투 행동만 지원

Search, Study, Influence와 Utilize가 빠져 탐험과 자유로운 D&D 플레이가 크게 제한되므로 채택하지 않는다.

### 모든 행동 완전 자동화

DM 판정과 자연어 상황에 의존하는 행동이 많아 잘못된 성공·실패를 만들 수 있으므로 채택하지 않는다.
