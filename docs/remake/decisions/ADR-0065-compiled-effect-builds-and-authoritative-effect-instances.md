# ADR-0065: 효과는 불변 Compiled Build와 권위 EffectInstance로 분리한다

- 상태: 확정
- 결정일: 2026-08-04
- 관련 문서:
  - [`ADR-0029`](ADR-0029-unified-effect-instances-duration-concentration-and-suppression.md)
  - [`ADR-0058`](ADR-0058-stable-runtime-object-identity-and-command-driven-lifecycle.md)
  - [`ADR-0061`](ADR-0061-persistent-rule-execution-orchestrator-and-nested-timing-windows.md)
  - [`ADR-0062`](ADR-0062-ordered-reservations-and-atomic-authority-transactions.md)
  - [`ADR-0063`](ADR-0063-manifest-chunk-snapshots-commit-journal-and-branch-recovery.md)
  - [`ADR-0064`](ADR-0064-immutable-compiled-builds-and-versioned-authoritative-state.md)
  - [`Effect, Condition과 Ongoing Runtime 계약`](../architecture/effect-condition-and-ongoing-runtime-contract.md)

## 배경

ADR-0029는 상태, 버프, 집중, 변신, 지속 영역과 소환을 공통 `EffectInstance` 수명주기로 처리하도록 확정했다.

이후 RVTT는 다음 공통 기반을 추가로 확정했다.

- Source와 불변 Compiled Build 분리
- Character, Actor와 Encounter 상태의 수명주기 분리
- RuleExecution, PendingEffect와 CommitGroup
- Runtime Object의 Identity와 Ownership
- 원자적 Authority Transaction
- Manifest·Chunk Snapshot, Journal과 Rollback Branch

기존 Effect 문서는 이 공통 기반 이전에 작성되어, Definition의 컴파일 결과와 실제 EffectInstance 상태, Character 기여, Runtime Object Ownership과 Build Migration의 경계가 충분히 명확하지 않았다.

## 결정

모든 지속 효과는 다음 구조를 사용한다.

```text
EffectDefinitionSource
→ Effect Compiler
→ Immutable CompiledEffectBuild

PendingEffectCreation
→ Authority Transaction
→ Versioned EffectInstance State
→ Derived Contribution과 Projection
```

`EffectRegistry`는 실제 EffectInstance의 권위 상태를 소유한다. Character, Actor, Encounter와 Runtime Object는 EffectInstance 전체를 복사하지 않고 타입 있는 Binding과 Reference만 유지한다.

## CompiledEffectBuild

Build는 다음을 소유한다.

- 정규화된 Modifier, Capability, Trigger와 Rule Override 기여
- Duration과 End Condition Plan
- Stacking, Suppression과 Cleanup Plan
- Runtime Object Ownership Plan
- Form Overlay Plan
- Disclosure와 Dependency Graph
- Build ID와 Content Hash

Build는 생성 후 수정하지 않는다.

현재 대상, 남은 지속시간, 집중 연결, Suppression Source와 현재 Stack 상태는 Build에 저장하지 않는다.

## EffectInstance

EffectInstance는 다음 권위 상태를 소유한다.

- 고유 ID, Incarnation과 Revision
- Build Reference와 Hash
- Source, Owner, Controller, Target와 Anchor Binding
- Frozen Parameter와 Live Binding Reference
- Duration과 End Condition State
- Stacking Identity
- Concentration Link
- Suppression Sources
- Parent·Child Effect와 Owned Runtime Object Reference
- Lifecycle State와 EndRecord

## 상태 Binding

Effect는 수명주기에 따라 다음 중 하나 이상에 연결할 수 있다.

- Campaign Character
- Scene Actor
- Encounter
- Scene Anchor와 Region
- Runtime Object
- Campaign Scope

Target, Owner, Source와 Controller는 서로 다른 개념으로 유지한다.

## 활성화와 종료

Effect 생성, 교체, 집중 채널 변경, Runtime Object Spawn과 자원 소비는 필요한 경우 하나의 Authority Transaction으로 처리한다.

종료는 단순 삭제가 아니다.

```text
종료 후보
→ 최신 Snapshot 재검증
→ Cleanup Commit Graph
→ Capability·Trigger·Modifier 해제
→ Owned Object와 Child Effect 정리
→ EndRecord와 Journal
```

부분 활성화와 부분 정리 상태를 외부에 공개하지 않는다.

## 집중

집중은 Character가 소유한 타입 있는 Channel State로 관리한다.

새 집중 효과 시작, 기존 집중 종료와 새 Root Effect 생성은 하나의 Transaction으로 처리한다.

집중 Root는 Child Effect와 Owned Runtime Object를 명시적으로 연결한다.

## 중첩과 억제

중첩은 이름과 아이콘이 아니라 타입 있는 `StackingIdentity`와 Compiled Stacking Plan으로 판정한다.

억제는 종료가 아니다. EffectInstance와 Duration State를 유지한 채 Contribution별 활성 정책을 적용한다.

여러 억제 원인은 Source Set으로 관리한다.

## Form Overlay

변신은 Base Character Build를 수정하지 않는다.

```text
Base Character Build
+ Compiled Form Overlay
+ Character State
+ EffectInstance State
→ Effective Character View
```

능력치, HP, 이동, 감각, Capability, 장비 사용과 Presentation에 대한 교체·보존 정책을 Overlay가 선언한다.

## 저장과 복구

Snapshot은 Effect Build Reference·Hash와 EffectInstance State를 저장한다.

Modifier 합계, Capability 복사본, Trigger Cache, UI 아이콘과 VFX는 저장하지 않고 복구 후 재구성한다.

Build Hash가 맞지 않으면 최신 Definition을 조용히 적용하지 않고 Migration 또는 콘텐츠 복구를 요구한다.

Rollback은 과거 Effect State를 새 Authority Branch에서 복원한다.

## 결과

- 상태·버프·집중·변신·소환이 최신 Runtime Architecture와 같은 패턴을 사용한다.
- Character와 Actor에 Effect 데이터를 중복 저장하지 않는다.
- Effect로 인한 수치와 행동 기여를 출처별로 추적할 수 있다.
- 집중 교체와 Effect Graph 정리가 원자적으로 처리된다.
- 저장·재접속·Rollback에서 중복 적용과 부분 정리를 막을 수 있다.
- Form 변화가 Character Build를 오염시키지 않는다.

## 비목표

- 모든 효과를 단순 Modifier로 축약하지 않는다.
- Effect 종류마다 독립된 저장·수명주기 시스템을 만들지 않는다.
- UI 상태 아이콘을 권위 Effect 목록으로 사용하지 않는다.
- Workspace Instance의 존재를 Effect 활성 여부로 사용하지 않는다.
