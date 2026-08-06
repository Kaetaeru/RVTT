# ADR-0064. 불변 Compiled Build와 버전된 Authoritative State 분리

- 상태: 확정
- 작성일: 2026-08-04
- 결정 범위: Source, Compiler, Runtime Build, Dynamic State, State Migration, Persistence와 Projection
- 관련 문서:
  - [`Compiled Build와 Authoritative State 분리 패턴`](../architecture/compiled-build-and-authoritative-state-pattern.md)
  - [`Runtime Architecture Principles`](../architecture/runtime-architecture-principles.md)
  - [`Scene Compiler와 Compiled Runtime Scene 계약`](../architecture/scene-compiler-and-compiled-runtime-scene-contract.md)
  - [`Persistence, Snapshot, Journal과 Recovery 계약`](../architecture/persistence-and-session-recovery-model.md)
  - [`Character 원본 데이터와 Scene Actor 분리`](ADR-0014-character-data-and-scene-actor-separation.md)
  - [`고정 획득 파생과 선택 저장`](ADR-0017-derived-fixed-grants-and-stored-selections.md)

## 배경

RVTT는 Scene, Character, Recipe, Item과 Effect에서 사용자가 편집하거나 캠페인이 보존해야 하는 원본, 런타임 성능을 위한 파생 데이터, 플레이 중 변경되는 상태와 Client 표시를 함께 다룬다.

이들을 같은 데이터 구조에서 직접 수정하면 다음 문제가 생긴다.

- 파생 능력치와 저장 원본이 서로 어긋남
- 레벨업과 Scene 게시 중 기존 Runtime을 제자리 수정함
- Build 변경과 State 변경이 부분 적용됨
- Rollback과 서버 복구에서 어떤 값이 원본인지 판정하기 어려움
- UI와 Workspace가 권위 데이터처럼 사용됨
- Character 원본, Scene Actor와 Encounter State의 수명주기가 섞임
- 콘텐츠 버전이 바뀌었을 때 기존 State가 검증 없이 새 정의에 결합됨

Scene Compiler에서는 이미 불변 Build와 Dynamic State를 분리하고 있으며 Character의 Grant Graph도 고정 획득과 Capability Set을 파생하도록 결정되어 있다. 이 원칙을 전역 계약으로 명시할 필요가 있다.

## 결정

### 1. Runtime 도메인은 Source, Compiled Build, Authoritative State와 Projection을 구분한다

```text
Source
→ Compiler·Resolver
→ Immutable Compiled Build
+ Versioned Authoritative State
→ Runtime Snapshot
→ Projection
→ Presentation
```

각 도메인은 자신의 Source와 State Store를 정의하되 이 계층을 의미 없이 합치지 않는다.

### 2. Compiled Build는 생성 후 수정하지 않는다

Build 변경은 기존 Table이나 Registry를 제자리 수정하는 것이 아니라 새로운 `buildId`와 `buildContentHash`를 가진 Build를 생성한다.

### 3. Authoritative State만 Command와 Transaction으로 변경한다

Rule, UI, Compiler와 Presentation은 권위 State Store를 직접 수정하지 않는다.

### 4. Build 교체와 State Migration은 하나의 Authority Transaction이다

새 Build를 활성화하면서 기존 State를 별도 단계에서 나중에 보정하지 않는다.

```text
Candidate Build
+ State Migration Candidate
→ Validation
→ Atomic Activation
```

둘 중 하나가 실패하면 기존 Build와 State를 유지한다.

### 5. Compiler와 Migration 책임을 분리한다

Compiler는 Source에서 Build를 생성한다.

Migration은 Old Build, Old State와 New Build를 바탕으로 New State Candidate를 생성한다.

Compiler가 Live State를 직접 수정하지 않는다.

### 6. 서로 다른 수명주기의 State를 강제로 하나로 합치지 않는다

Character는 다음을 분리한다.

- Character Progression Source
- Compiled Character Build
- Persistent Character State
- Scene Actor State
- Encounter State

Actor 위치와 Encounter 행동 경제를 Character Build나 Persistent Character State에 복사하지 않는다.

### 7. Persistence는 Build Reference와 State를 저장한다

Build가 Source와 버전에서 결정적으로 재생성 가능하면 Build Blob 전체를 항상 Snapshot에 복제하지 않는다.

Snapshot은 Source·Content Version, Build Reference·Hash와 Authoritative State를 기록한다.

복구 시 Build Hash가 맞지 않으면 자동으로 최신 Build에 결합하지 않고 호환성 검증 또는 Migration을 요구한다.

### 8. Projection과 Presentation은 권위 원본이 아니다

Character Sheet, Combat HUD, Workspace Model과 Client Cache가 계산한 값은 Source, Build와 State를 대체하지 않는다.

## 결과

- Scene, Character와 Rules Runtime이 같은 데이터 철학을 사용한다.
- 파생 값과 저장 원본의 불일치를 줄인다.
- Build 변경과 State Migration의 부분 적용을 막는다.
- Rollback, 재접속과 서버 복구에서 재구성 경계가 분명해진다.
- Character와 Actor, Encounter의 서로 다른 수명주기를 유지할 수 있다.
- 이후 Item, Effect와 Plugin Runtime을 같은 원칙으로 설계할 수 있다.

## 비용과 주의점

- Build Registry와 Content Hash 관리가 필요하다.
- 도메인별 State Migration 계획과 호환성 검사가 필요하다.
- Cached Build와 Projection의 무효화 Key가 늘어난다.
- Build가 누락된 과거 저장본을 위한 보존 또는 재컴파일 정책이 필요하다.

## 비목표

- 모든 도메인을 하나의 공통 Schema나 Store로 통합하지 않는다.
- 모든 값의 런타임 계산을 금지하지 않는다.
- 성능 캐시를 금지하지 않는다.
- Character의 모든 현재 상태를 Build로 이동하지 않는다.
- Scene Actor와 Encounter 상태를 Character 원본에 합치지 않는다.
