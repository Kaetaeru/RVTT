# Implementation Spec — Slice 05 Character Foundation·Creation

- 상태: SPEC_CHECKPOINT_COMPLETE
- 문서 종류: Slice Integration Implementation Spec
- 구현 상태: 미구현
- 즉시 구현 명세 가능성: BLOCKED
- 작성일: 2026-08-05
- 차단 이유: 실제 Character Source·Compiler·Build·State·Sheet 구조와 Legacy 데이터가 확인되지 않았다.
- Work Order: [`CURRENT-WORK-ORDER.md`](CURRENT-WORK-ORDER.md)
- Roadmap: [`SLICE-ROADMAP.md`](../../SLICE-ROADMAP.md)
- 선행 계약: [`Core Rules Kernel`](../02-core-rules-kernel/implementation-contract.md), [`Session Foundation`](../01-first-session-walking-skeleton/implementation-contract.md)
- 관련 Guide: [`Character`](../../../guides/character/README.md), [`Rules`](../../../guides/rules/README.md), [`Session`](../../../guides/session/README.md), [`UI`](../../../guides/ui/README.md), [`Extension`](../../../guides/extension/README.md), [`Diagnostics`](../../../guides/diagnostics/README.md)

> 이 Spec은 Character를 이름과 숫자 Table로 저장하는 방식이 아니라, 수정 가능한 Source, 불변 Compiled Build, 현재 Persistent State, Scene Actor Presence와 사용자별 Projection으로 분리한다.

## 1. Acceptance Flow

### Player

```text
Create Character
→ 생성 단계별 선택
→ 오류·누락 확인
→ Candidate Preview
→ Character 확정
→ Character Sheet 확인
→ Session Character로 선택
```

### DM

```text
Campaign 허용 Ruleset·Source Pack 확인
→ Character Candidate 검토
→ 필요한 승인·수정 요청
→ Character Activation 확인
→ Owner·Session Control·Actor Binding 확인
```

## 2. 직접 권위 문서

- [`Compiled Build와 Authoritative State 분리`](../../../architecture/compiled-build-and-authoritative-state-pattern.md)
- [`Character Runtime과 Compiled Character Build`](../../../architecture/character-runtime-and-compiled-character-build-contract.md)
- [`Rules Content Grant와 Capability`](../../../architecture/rules-content-grant-capability-model.md)
- [`Ruleset Policy Registry와 Frozen Snapshot`](../../../architecture/ruleset-policy-registry-composition-and-frozen-snapshot-runtime-contract.md)
- [`Runtime Object System과 Entity Lifecycle`](../../../architecture/runtime-object-system-and-entity-lifecycle-contract.md)
- [`Session Play Mode와 Transition`](../../../architecture/session-play-mode-context-overlay-and-transition-contract.md)
- [`Command Ordering과 Transaction Coordinator`](../../../architecture/command-ordering-logical-time-and-transaction-coordinator-contract.md)
- [`Domain Event와 Projection Runtime`](../../../architecture/domain-event-outbox-subscription-and-projection-runtime-contract.md)
- [`Persistence와 Session Recovery`](../../../architecture/persistence-and-session-recovery-model.md)
- [`UI Projection·ViewModel·Recovery`](../../../architecture/ui-projection-view-model-input-context-and-recovery-runtime-contract.md)
- [`공식 2024 Character Sheet와 실시간 UI`](../../../ui/character-sheet/official-2024-character-sheet-and-live-player-ui.md)

## 3. 범위

포함:

- Campaign-scoped Character Identity와 Ownership
- Character Source·Revision·Creation Draft
- Creation Slot, Stored Selection과 Source Pack Ref
- Character Compiler·Validation·Immutable Build Registry
- Persistent Current State 초기화
- Grant Graph·Capability·Derived Stat Projection
- Character Sheet Foundation
- CharacterId·ActorId·Session Selection·Control Binding
- Compile Failure·Migration·Reconnect·Rollback

제외:

- 전체 공식 Species·Background·Class·Subclass 데이터
- Level Up·Rest·Downtime
- Inventory·Equipment 전체
- 전체 Spellbook·Preparation

## 4. 계층과 Type

```lua
export type CharacterSource = {
    schemaVersion: number,
    characterId: string,
    campaignId: string,
    ownerUserId: number?,
    sourceRevision: number,
    rulesetRef: string,
    sourcePackRefs: {string},
    identityFields: {[string]: unknown},
    storedSelections: {[string]: unknown},
}

export type CompiledCharacterBuild = {
    buildId: string,
    characterId: string,
    sourceRevision: number,
    compilerVersion: string,
    rulesetSnapshotRef: string,
    contentVersionSet: {string},
    grantGraphDigest: string,
    capabilityRefs: {string},
    derivedBaseStats: {[string]: number},
    buildHash: string,
}

export type CharacterPersistentState = {
    characterId: string,
    activeBuildRef: string,
    stateRevision: number,
    currentHitPoints: number,
    temporaryHitPoints: number,
    resourceStates: {[string]: unknown},
    usageStates: {[string]: unknown},
    preparationState: {[string]: unknown},
}

export type CharacterActorBinding = {
    characterId: string,
    actorId: string,
    actorIncarnation: string,
    sceneRuntimeRef: string,
    bindingRevision: number,
}
```

Source는 장기 선택과 정체성을 저장한다. Build는 Source·Ruleset·Content Version에서 결정적으로 Compile한다. State는 현재 HP·Resource·Usage를 저장한다. Actor는 Scene Presence와 Transform을 소유한다.

## 5. Creation Session

```text
Creation Session 시작
→ Campaign Character Policy·Ruleset Snapshot 고정
→ Creation Slot과 Allowed Option Projection
→ Stored Selection 제출
→ Incremental Validation·Preview
→ Candidate Source Revision
→ Full Compile
→ Initial State Plan
→ Player·DM 검토
→ Atomic Activation
```

대표 상태:

```text
draft
→ validating
→ compile_ready
→ review_required | ready_to_activate
→ active

validating | compile_ready
→ error
→ draft
```

Creation Preview는 Candidate Build를 사용하지만 활성 Character State를 변경하지 않는다. 이름, 표시 순서와 Localization Key를 Stable Content ID로 사용하지 않는다.

## 6. Command 계약

| Command | 검증 | Commit |
|---|---|---|
| `CreateCharacterDraft` | Campaign Membership, Character Slot Policy | Draft Identity |
| `SetCharacterSelection` | Draft Owner, Selection Slot, Content Ref, Revision | Source Draft Revision |
| `ValidateCharacterCandidate` | Ruleset·Pack Version, Required Slot | Validation Result·Preview |
| `SubmitCharacterForReview` | Compile 성공, 필수 선택 완료 | Review State |
| `ApproveCharacterCandidate` | DM 또는 Policy 권한 | Approval Record |
| `ActivateCharacter` | Source·Build·State Plan 최신성 | Source + Build Ref + State Atomic Commit |
| `SelectSessionCharacter` | Owner·Membership·Control Policy | Session Binding |

Compile·Migration·State Initialization 중 하나라도 실패하면 Source 일부, Build Pointer와 State 일부를 따로 활성화하지 않는다.

## 7. Compiler와 Grant·Capability

```text
Character Source
+ Ruleset Snapshot
+ Content Version Set
→ Schema·Reference Validation
→ Grant Graph
→ Stored Selection Resolution
→ Capability Compilation
→ Derived Base Stat
→ Immutable Build
```

Compiler 요구:

- 같은 입력과 Version Set에서 같은 Build Hash
- Dependency Cycle·Missing Content·Duplicate Grant 검출
- Localization 변경이 Authority Digest를 바꾸지 않음
- Candidate Build와 Active Build 분리
- Compile 실패 시 Last Known Good 유지

Fixed Grant는 Source에 결과 복사본을 저장하지 않고 Build에서 파생한다. 사용자가 선택한 Option은 Stable Selection Result로 Source에 저장한다.

## 8. Initial Persistent State

Initial State Plan은 Build와 Policy에서 다음을 생성한다.

- Current·Maximum HP 연결
- Resource Pool Identity와 Current Value
- Usage·Charge·Preparation 초기 상태
- DeathSave·Condition·Effect의 빈 또는 Policy 기본 상태

Maximum 값과 Capability는 Build에서 파생될 수 있지만 Current 값은 State다. Build 변경 시 State Migration Plan이 보존·제거·재초기화 규칙을 명시한다.

## 9. Actor·Session Binding

Character 생성만으로 Scene Actor를 항상 Materialize하지 않는다.

```text
Session Character 선택
→ Scene Entry Policy
→ Actor Definition·Prefab Ref
→ Runtime Actor Presence 생성
→ CharacterActorBinding
→ Controller Assignment
```

Scene 전환이나 Respawn에서 CharacterId는 유지될 수 있지만 ActorId·Incarnation은 새로 생길 수 있다. Actor Transform·Visibility·Collision은 Character Source에 저장하지 않는다.

## 10. Projection·Character Sheet

Player Sheet Projection:

- 공개 Identity·Appearance Summary
- Ability·Skill·Save·AC·HP·Resource
- Source Option과 Feature·Capability Summary
- Build·State Sync 상태
- 수정 가능한 Draft Selection과 수정 불가 Active Source 구분

DM Projection은 Campaign Policy, Validation·Migration Warning과 승인 상태를 추가할 수 있다. 다른 Player의 비공개 선택·Resource·Notes는 Viewer Policy를 따른다.

필수 UI 상태:

```text
생성 Draft
필수 선택 누락
Content Version 없음
Compile 중
검토 대기
승인 거부·수정 필요
Activation 실패·Last Known Good 유지
Character Sheet 동기화 중
Actor Binding 없음·Scene 입장 대기
```

## 11. Persistence·Migration·Rollback

저장:

- Character Source와 Revision History Pointer
- Active Build Ref와 Build Version Set
- Persistent State와 Revision
- Owner·Campaign Binding
- Approval·Activation Record
- Actor Binding은 현재 Runtime Snapshot 범위

Migration:

```text
Old Source·Build·State
→ Target Ruleset·Content Version
→ Candidate Recompile
→ Compatibility Diff
→ State Migration Plan
→ Review·Atomic Activation
```

Missing Content를 이름이 같은 최신 Content로 자동 대체하지 않는다. Migration 실패 시 Active Build·State를 유지하거나 Read-only Recovery를 사용한다. Rollback은 Snapshot의 Source·Build Ref·State를 새 AuthorityEpoch에서 복원한다.

## 12. Diagnostics·Security·Test

Trace:

```text
character.draft_create
character.selection_set
character.validate
character.compile
character.review
character.activate
character.state_initialize
character.actor_bind
character.migrate
```

Security:

- Client가 Derived Stat·Grant·Capability·Build Hash를 제출하지 않는다.
- Campaign에 허용되지 않은 Pack·Content Ref를 거부한다.
- Player는 다른 Owner의 Draft를 수정하지 않는다.
- Import된 Character Source에 임의 Luau·Remote·URL을 허용하지 않는다.

Test:

1. 정상 Level 1 Candidate Compile·Activate.
2. Required Selection 누락과 구조화된 오류.
3. Duplicate·Cycle·Missing Content Compile 차단.
4. 같은 입력·Version의 Build Hash 결정성.
5. Localization 변경 후 Authority Build Digest 불변.
6. Activation 중 State Initialization 실패와 Last Known Good.
7. Owner가 아닌 사용자 수정·선택 거부.
8. CharacterId 유지·Scene 전환 후 새 ActorId Binding.
9. Reconnect 후 Sheet·State·Actor Binding 복구.
10. Rollback 이전 Draft·Approval Command 차단.
11. Player Projection에 다른 Character Secret Canary 미노출.
12. Build Version Migration 성공·실패·Review.

## 13. 구현 순서와 완료 기준

```text
Identity·Ownership·Source
→ Creation Session·Selection
→ Compiler·Build Registry
→ Grant·Capability·Derived View
→ Persistent State Initialization
→ Review·Atomic Activation
→ Actor·Session Binding
→ Sheet·Migration·Integration Test
```

완료 기준:

- Source·Build·State·Actor·Projection이 분리된다.
- Character 생성은 Compile·Validation·Activation을 거친다.
- Stored Selection과 Derived Grant가 분리된다.
- Compile 실패와 Migration 실패가 Active Character를 손상하지 않는다.
- Character Sheet가 Projection만 사용한다.

Production 구현 전 실제 Character·Compiler·Sheet·Legacy Source Mapping과 공식 Content Packaging 검토가 필요하다.