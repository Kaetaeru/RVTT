# Compiled Build와 Authoritative State 분리 패턴

- 상태: 확정
- 문서 종류: Architecture
- 즉시 구현 명세 가능성: `READY`
- 작성일: 2026-08-04
- 관련 ADR:
  - [`ADR-0054`](../decisions/ADR-0054-compiled-semantic-runtime-and-query-authority-principles.md)
  - [`ADR-0057`](../decisions/ADR-0057-canonical-scene-source-and-atomic-compiled-build-activation.md)
  - [`ADR-0063`](../decisions/ADR-0063-manifest-chunk-snapshots-commit-journal-and-branch-recovery.md)
  - [`ADR-0064`](../decisions/ADR-0064-immutable-compiled-builds-and-versioned-authoritative-state.md)
- 상위 문서:
  - [`Runtime Architecture Principles`](runtime-architecture-principles.md)
- 관련 문서:
  - [`Scene Compiler와 Compiled Runtime Scene 계약`](scene-compiler-and-compiled-runtime-scene-contract.md)
  - [`Runtime Object System과 Entity Lifecycle 계약`](runtime-object-system-and-entity-lifecycle-contract.md)
  - [`Persistence, Snapshot, Journal과 Recovery 계약`](persistence-and-session-recovery-model.md)
  - [`Rules Content Grant와 Capability 모델`](rules-content-grant-capability-model.md)

## 1. 목적

이 문서는 Scene, Character, Rules Content, Item, Effect와 이후 추가되는 Runtime 도메인이 저장 원본, 컴파일 결과, 플레이 중 상태와 Client 표시를 같은 의미로 섞지 않도록 공통 데이터 계층을 정의한다.

기본 구조는 다음과 같다.

```text
Authoring 또는 Persistent Source
→ Compiler·Resolver
→ Immutable Compiled Build
+ Versioned Authoritative State
→ Runtime Snapshot·Service
→ Permission-aware Projection
→ Presentation
```

이 패턴은 모든 도메인을 같은 Schema로 만들라는 뜻이 아니다. 각 도메인은 자신의 수명주기와 권위 Store를 유지하되, 파생 Build와 변경 가능한 상태를 구분해야 한다.

## 2. 공통 데이터 계층

### 2.1 Source

사람의 선택, 캠페인 기록 또는 콘텐츠 제작 결과처럼 다시 만들어 낼 수 없는 권위 원본이다.

예:

- Scene Source
- Character 성장 출처와 저장된 선택
- Rules Content Definition
- Item Definition과 ItemInstance의 영구 식별 정보
- DM이 부여한 예외 획득

Source에는 파생 결과를 중복 저장하지 않는다.

### 2.2 Compiled Build

Source와 고정된 콘텐츠·Compiler 버전에서 결정적으로 생성되는 불변 파생 데이터다.

예:

- Compiled Runtime Scene Build
- Compiled Character Build
- Character Capability Set
- Modifier Dependency Graph
- Compiled Recipe
- 타입 있는 Binding Layout

Build는 다음 식별 정보를 가진다.

```text
buildId
sourceRevision 또는 sourceHash
compilerVersionSet
contentVersionSet
buildContentHash
compatibilityClass
```

Build는 생성 후 제자리에서 수정하지 않는다. 변경이 필요하면 새로운 Build를 만든다.

### 2.3 Authoritative State

플레이 중 Command와 Authority Transaction으로 변경되는 서버 권위 상태다.

예:

- Character의 현재 HP, 자원과 장기 지속 상태
- Actor의 Scene 위치와 공개 상태
- Encounter의 행동 경제와 이동력
- 문과 상자의 현재 상태
- ItemInstance의 현재 Charge와 소유권
- 활성 EffectInstance와 Resource Reservation

State는 Revision, AuthorityEpoch와 Branch에 묶이며 Snapshot과 Journal의 복구 대상이다.

### 2.4 Projection과 Presentation

Projection은 권한, 소유권, Perception과 Disclosure를 적용한 Client-safe View다.

Presentation은 Workspace Model, UI, Animation, VFX와 Camera다.

둘 다 Source, Build 또는 Authoritative State의 원본이 아니다.

## 3. Build와 State의 결합

Runtime Service는 Build만 또는 State만으로 동작하지 않는다.

```text
Build Reference
+ Authority State Revision
+ Runtime Context
→ Runtime Snapshot
```

Runtime Context 예:

- 현재 Scene Build
- 현재 Ruleset과 Source Pack Version
- Actor·Encounter Binding
- Permission View
- Query Snapshot

같은 Build라도 State가 다르면 다른 Runtime 결과가 나오며, 같은 State를 다른 Build와 결합하려면 Compatibility와 Migration 검증이 필요하다.

## 4. Build 교체

Source가 바뀌거나 Content Pack·Compiler가 변경되면 다음 절차를 사용한다.

```text
Source 변경 또는 Version 변경
→ Candidate Build 생성
→ 정적 검증
→ Old Build와 Compatibility 비교
→ State Migration Plan 생성
→ Migration Candidate 검증
→ Authority Transaction으로 Build Reference와 State를 원자 교체
→ 새 Revision과 Projection 발행
```

Build와 State를 서로 다른 Transaction에서 교체하지 않는다.

## 5. State Migration

Migration은 `Old Build + Old State`를 입력으로 `New Build에 적합한 New State`를 생성한다.

```text
Old Build
+ Old State
+ New Build
+ Migration Policy
→ New State Candidate
```

Migration은 다음을 명시해야 한다.

- 유지할 Identity
- 변환할 State Field
- 제거되거나 비활성화되는 State
- 새로 생성되는 기본 State
- Resource 최대치 변경 시 현재값 정책
- 누락된 콘텐츠와 unresolved 기록
- 실패 시 Last Known Good Build·State 유지

Compiler가 Live State를 직접 수정하지 않는다.

## 6. 도메인별 수명주기 분리

전역 패턴을 이유로 서로 다른 수명주기의 상태를 한 Store에 합치지 않는다.

Character 예:

```text
Character Progression Source
→ Compiled Character Build

Persistent Character State
→ 현재 HP, 장기 자원, 장비·조율, 지속 상태

Scene Actor State
→ 위치, 회전, Scene Presence와 공개 상태

Encounter State
→ Initiative, 행동 경제, 이번 턴 이동력
```

Scene Actor와 Encounter State는 Character Build의 일부가 아니며 Character Source에 복사하지 않는다.

## 7. Persistence와 Recovery

Persistence는 재생성 가능한 Build Blob을 항상 Snapshot에 복사하지 않는다.

기본 저장은 다음을 사용한다.

```text
Source Revision·Content Version
+ Build Reference·Hash
+ Authoritative State
+ Migration Metadata
+ Commit Journal
```

복구 시 참조된 Build를 찾거나 결정적으로 재생성하고 Hash를 검증한 뒤 State를 적용한다.

필요한 Build를 찾을 수 없거나 Hash가 맞지 않으면 조용히 최신 Build를 사용하지 않는다. 호환 가능한 재컴파일, 명시적 Migration 또는 DM 검토가 필요하다.

## 8. Query, Rule과 UI 경계

- Spatial Query는 Snapshot에 고정된 Build와 State Index를 읽는다.
- Rule Runtime은 Build를 수정하지 않고 PendingEffect와 Transaction Proposal을 만든다.
- Transaction Coordinator만 Authoritative State와 활성 Build Reference를 Commit한다.
- UI는 Projection만 읽고 Derived 값이나 Capability를 권위 상태로 제출하지 않는다.
- Client가 보낸 Build Hash나 Derived Stat를 최종 권위로 신뢰하지 않는다.

## 9. 캐시

Build, Derived View와 Projection은 캐시할 수 있다.

캐시는 최소한 다음 Key를 사용한다.

```text
sourceRevision 또는 sourceHash
buildContentHash
contentVersionSet
authorityEpoch
domainRevision
projectionPolicyVersion
```

Key가 맞지 않으면 폐기하고 다시 만든다. 캐시 유실은 권위 데이터 유실이 아니다.

## 10. 금지 사항

- Runtime 중 Build Table을 제자리 수정
- Source와 Derived 값을 동일 필드의 공동 원본으로 사용
- Build 교체와 State Migration을 별도 비원자 작업으로 적용
- CharacterActor에 Character 영구 상태를 복사해 독립 원본 생성
- UI에서 계산한 Derived Stat와 Capability Set을 서버에 저장
- 콘텐츠 누락 시 저장된 Source·선택·State를 자동 삭제
- Build Hash가 다른 State를 검증 없이 결합

## 11. 적용 상태

현재 명시적으로 이 패턴을 적용하는 도메인:

- Scene Source / Compiled Runtime Scene / Dynamic Scene State
- Rules Definition / Compiled Recipe / RuleExecution State
- Character Progression Source / Compiled Character Build / 분리된 Character·Actor·Encounter State

Item, Effect, Plugin과 AI 도메인은 각 Architecture 문서를 작성할 때 이 패턴을 구체화한다.
