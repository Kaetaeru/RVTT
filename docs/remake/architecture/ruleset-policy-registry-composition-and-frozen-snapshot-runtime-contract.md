# Ruleset Policy Registry, Composition과 Frozen Snapshot Runtime 계약

- 상태: 확정
- 문서 종류: Architecture
- 즉시 구현 명세 가능성: `READY_WITH_DEFAULTS`
- 남은 기본값:
  - 단일 Frozen Snapshot에 허용할 Policy Family·Binding 수와 직렬화 크기 상한
  - Policy Composition Trace의 기본 보존 수준과 장기 보존 기간
  - Campaign Policy 변경 시 기본 승인 UI와 안전 경계
  - 사용되지 않는 이전 Snapshot의 Reference 보존 기간
  - Policy Candidate Compile과 Effective View Cache의 기본 Budget
  - DM Override의 기본 만료 방식과 장기 Override 경고 기준
- 작성일: 2026-08-04
- 관련 ADR:
  - [`ADR-0003`](../decisions/ADR-0003-ruleset-source-packs-localization.md)
  - [`ADR-0054`](../decisions/ADR-0054-compiled-semantic-runtime-and-query-authority-principles.md)
  - [`ADR-0061`](../decisions/ADR-0061-persistent-rule-execution-orchestrator-and-nested-timing-windows.md)
  - [`ADR-0063`](../decisions/ADR-0063-manifest-chunk-snapshots-commit-journal-and-branch-recovery.md)
  - [`ADR-0064`](../decisions/ADR-0064-immutable-compiled-builds-and-versioned-authoritative-state.md)
  - [`ADR-0070`](../decisions/ADR-0070-orthogonal-session-modes-contexts-overlays-and-transitions.md)
  - [`ADR-0077`](../decisions/ADR-0077-transactional-domain-events-with-outbox-and-projection-boundaries.md)
  - [`ADR-0078`](../decisions/ADR-0078-authoritative-game-time-boundary-durations-and-scheduled-execution.md)
  - [`ADR-0079`](../decisions/ADR-0079-policy-driven-encounter-timelines-and-opportunity-gated-turns.md)
  - [`ADR-0080`](../decisions/ADR-0080-downtime-as-time-coordinated-activity-sessions-with-domain-owned-completion.md)
  - [`ADR-0081`](../decisions/ADR-0081-versioned-policy-composition-and-frozen-ruleset-snapshots.md)
- 상위 문서:
  - [`Runtime Architecture Principles`](runtime-architecture-principles.md)
  - [`Compiled Build와 Authoritative State 분리 패턴`](compiled-build-and-authoritative-state-pattern.md)
  - [`Session Play Mode, Context, Overlay와 Transition 계약`](session-play-mode-context-overlay-and-transition-contract.md)
  - [`Domain Event, Outbox, Subscription과 Projection Runtime 계약`](domain-event-outbox-subscription-and-projection-runtime-contract.md)
  - [`Persistence와 Session Recovery 모델`](persistence-and-session-recovery-model.md)
- 관련 Runtime:
  - [`Encounter Runtime 계약`](encounter-timeline-turn-opportunity-and-objective-runtime-contract.md)
  - [`Game Time Runtime 계약`](game-time-calendar-duration-and-scheduler-runtime-contract.md)
  - [`Downtime Runtime 계약`](downtime-activity-time-coordination-and-atomic-completion-runtime-contract.md)
  - [`Character Runtime 계약`](character-runtime-and-compiled-character-build-contract.md)
  - [`Rule Runtime Orchestrator 계약`](rule-runtime-orchestrator-and-pending-execution-contract.md)
  - [`Effect Runtime 계약`](effect-condition-and-ongoing-runtime-contract.md)
  - [`Presentation Runtime 계약`](presentation-recipe-playback-priority-and-extension-runtime-contract.md)

## 1. 목적

RVTT의 여러 Runtime은 플레이테스트와 캠페인 설정에 따라 교체 가능한 Policy를 사용한다.

예:

```text
Initiative Policy
Turn·Action Economy Policy
Objective·End Policy
Round Duration Policy
Downtime Entry·Interruption·Refund Policy
Visibility·Disclosure Policy
Timeout·Join·Leave Policy
Build Migration Policy
Presentation Quality·Accessibility Policy
```

각 Runtime이 자신의 Policy Registry, 우선순위와 Override 규칙을 따로 구현하면 다음 문제가 생긴다.

- 같은 Campaign 설정이 Encounter와 Downtime에서 다른 우선순위로 적용됨
- Source Pack이 Core 규칙을 조용히 덮어씀
- 활성 Encounter 중 Policy Version이 바뀌어 한 라운드 안에서 규칙이 섞임
- DM Override가 Disclosure·보안 제한까지 우회함
- Character·Item·Effect의 일시적 RuleOverride가 전역 Campaign Policy를 오염시킴
- 저장·복구 시 최신 Policy를 임의로 사용해 이전 결과를 재현할 수 없음

따라서 이 문서는 다음 공통 흐름을 정의한다.

```text
Policy Family와 Implementation 등록
+ Ruleset·Source Pack·Campaign·Scope Binding
→ 검증된 Policy Composition
→ Immutable Frozen Policy Snapshot
→ Runtime별 Domain Policy View
→ Execution별 Effective Policy View
```

핵심 원칙:

```text
Policy는 규칙을 선택하고 합성한다.
Policy는 권위 Store를 직접 변경하지 않는다.
```

```text
진행 중 권위 실행은 생성 당시의 Frozen Snapshot을 사용한다.
최신 Policy를 조용히 다시 조회하지 않는다.
```

## 2. 책임 경계

### 2.1 Policy Runtime이 소유한다

- Policy Family Schema와 안정적 Identity
- 신뢰된 Policy Implementation Registry
- Ruleset Policy Pack과 Source Pack Patch Binding
- Campaign·Scene·Encounter·Downtime Scope Policy Binding
- Policy Source의 허용 범위와 Composition 규칙
- 결정적 우선순위·Specificity·Conflict Resolution
- Candidate Policy Snapshot Compile과 정적 진단
- Immutable Frozen Policy Snapshot Identity·Hash·Version
- Domain Policy View와 Execution Effective Policy View 해결
- Policy Hot Swap Impact와 Migration Plan
- Last Known Good Snapshot과 이전 Snapshot 보존
- Persistence·Recovery·Rollback용 Policy Reference
- DM용 설명 가능한 Composition Trace와 Audit Metadata

### 2.2 Policy Runtime이 소유하지 않는다

- 공격·주문·효과·휴식·이동의 실제 규칙 실행
- Character Progression Source와 Capability Grant
- ItemInstance·EffectInstance·Encounter·Downtime 상태
- Command Authorization과 Authority Transaction Commit
- Dice 난수 생성
- Visibility 결과와 Knowledge State의 직접 변경
- UI Layout, Camera와 VFX 재생
- 사용자 접근성 설정의 저장 UI

Policy Runtime은 Runtime이 사용할 결정적 규칙 View를 제공한다. 실제 상태 변경은 해당 Domain의 Command, RuleExecution과 Transaction이 수행한다.

## 3. Policy와 다른 규칙 요소의 구분

### 3.1 Policy

여러 실행에 공통으로 적용되는 규칙 방식, 기본값 또는 합성 전략이다.

예:

- Initiative 계산 방식
- Encounter Timeline 구성 방식
- Round가 Campaign Time에 반영되는 방식
- Downtime 중단 시 진행도 보존 방식
- 공개 정보의 최소 제한
- Query Budget 상한

### 3.2 Capability

특정 Character·Item·Effect가 현재 사용할 수 있는 행동이나 기능이다.

```text
Policy
→ 행동 기회와 규칙 방식

Capability
→ 실제 사용할 수 있는 행동 후보
```

### 3.3 Modifier와 RuleOverride Contribution

Character, Item과 Effect가 특정 Actor·Target·Execution Context에 기여하는 일시적 규칙 변경이다.

예:

- 특정 공격에 Advantage
- Reaction 사용 가능 횟수 증가
- Difficult Terrain 무시
- 한 주문의 구성요소 변경

이 기여는 Campaign Policy Snapshot을 다시 쓰지 않는다. Execution 시 Frozen Baseline Snapshot 위에 타입 있는 Contribution으로 합성한다.

### 3.4 Command와 Domain Event

Policy는 Command가 아니며 Event Handler도 아니다.

- Policy 평가가 직접 HP를 변경하지 않는다.
- Policy가 임의 후속 Event를 발행하지 않는다.
- 상태 변경이 필요하면 Runtime이 Policy 결과를 사용해 Command·RuleExecution·Transaction을 만든다.

## 4. Policy Plane

모든 Policy를 하나의 전역 우선순위 목록에 넣지 않는다. 성격이 다른 Policy는 서로 다른 Plane에서 합성한다.

```text
PolicyPlane
├─ gameplay_authority
├─ disclosure_security
├─ operational_safety
└─ presentation_accessibility
```

### 4.1 gameplay_authority

게임 규칙 결과와 권위 진행 방식을 결정한다.

예:

- Initiative
- Action Economy
- Objective 종료
- Round Duration
- Downtime 중단·환불
- Rest Eligibility 기본값

### 4.2 disclosure_security

누가 어떤 권위 정보를 받을 수 있는지의 최소 공개 한계를 결정한다.

예:

- 숨은 Actor Identity
- 비밀 DC와 실제 HP
- Journal 비공개 제목
- Fog·Knowledge Disclosure

이 Plane은 Gameplay 규칙보다 더 높은 정보 보호 제약을 가진다. 일반 DM Gameplay Override로 Client-safe Projection 경계를 우회할 수 없다.

### 4.3 operational_safety

서버 안정성, Budget과 신뢰 경계를 결정한다.

예:

- Query 후보 상한
- Reaction 중첩 깊이
- Scheduler 연쇄 실행 Budget
- 등록 가능한 Module Trust Class
- Payload 크기와 Rate Limit

Campaign과 Source Pack은 Product Hard Cap보다 더 느슨한 값을 선택할 수 없다.

### 4.4 presentation_accessibility

권위 결과를 바꾸지 않는 사용자별 표현과 접근성 설정이다.

예:

- Camera Shake 감소
- Flash 억제
- Animation 속도와 Skip
- Floating Text 상세 수준
- 색각 보조 표시

사용자의 접근성 제한은 DM Presentation Preference보다 우선할 수 있다. 그러나 이 Plane의 값으로 Roll, 피해, 이동 거리나 공개 권한을 바꿀 수 없다.

## 5. Policy Registry 구조

Policy Registry는 Family와 Implementation을 분리한다.

```text
PolicyRegistry
├─ PolicyFamilyDefinition[]
├─ PolicyImplementationDefinition[]
├─ PolicyMergerDefinition[]
├─ PolicyMigrationDefinition[]
└─ registryVersion
```

### 5.1 PolicyFamilyDefinition

하나의 안정적인 Policy 의미와 합성 계약이다.

```text
PolicyFamilyDefinition
├─ policyFamilyId
├─ domain
├─ plane
├─ inputSchemaRef
├─ outputSchemaRef
├─ parameterSchemaRef
├─ allowedSourceKinds[]
├─ allowedScopes[]
├─ compositionMode
├─ conflictClass
├─ invariantValidators[]
├─ defaultFallbackRef
├─ tracePolicy
└─ familySchemaVersion
```

예:

```text
encounter.initiative
encounter.round_duration
encounter.end_confirmation
time.partial_round_advance
downtime.interruption_progress
visibility.actor_identity_disclosure
presentation.camera_shake
```

Family ID는 표시 이름이나 번역 문자열을 사용하지 않는다.

### 5.2 PolicyImplementationDefinition

Family가 사용할 한 가지 검증된 구현이다.

```text
PolicyImplementationDefinition
├─ policyImplementationId
├─ policyFamilyId
├─ implementationVersion
├─ compatibleRulesetIds[]
├─ compatibleFamilySchemaRange
├─ evaluatorRef
├─ defaultParameters
├─ dependencyRefs[]
├─ trustClass
├─ deterministicClass
├─ budgetProfile
├─ migrationRefs[]
├─ deprecationState
└─ implementationHash
```

`evaluatorRef`는 신뢰된 Registry Module 또는 검증된 Compiled Expression만 참조한다. 사용자 입력으로 임의 Luau를 등록하지 않는다.

Policy Evaluator는 다음만 반환할 수 있다.

- 타입 있는 결정값
- 허용·거부 결과와 이유
- 다음 Runtime이 사용할 계산 Plan
- 설명 가능한 Contribution·Constraint

Policy Evaluator가 Authority Store, Workspace, Remote와 DataStore를 직접 변경하거나 조회하지 않는다.

### 5.3 PolicyMergerDefinition

합성 방식도 신뢰된 Registry 항목이다.

초기 지원 형태:

```text
replace_by_precedence
merge_typed_map
append_unique_stable
set_union
ordered_pipeline
minimum_cap
maximum_floor
most_restrictive
registered_deterministic
```

임의 Callback이나 Source Pack이 제공한 무제한 Merger를 실행하지 않는다.

## 6. Policy Pack과 Binding

### 6.1 RulesetPolicyPack

규칙 세트가 기본적으로 사용할 Policy Implementation과 Parameter Binding의 버전된 묶음이다.

```text
RulesetPolicyPack
├─ rulesetId
├─ policyPackId
├─ version
├─ familyBindings[]
├─ dependencies[]
├─ compatibilityClass
├─ sourcePackCompatibility[]
└─ contentHash
```

`dnd5e-2024`는 다음과 같은 기본 Binding을 제공할 수 있다.

```text
encounter.initiative
→ dnd5e2024.individual_dexterity_initiative

encounter.round_duration
→ fixed_game_time_duration(6 seconds)

encounter.delay
→ disabled

encounter.ready
→ action_plus_reaction_release
```

정확한 게임 수치는 Policy Pack 데이터에 있고 Encounter Core에 하드코딩하지 않는다.

### 6.2 SourcePackPolicyPatch

Source Pack이 기존 Family를 변경해야 하면 명시적 Patch Binding을 선언한다.

```text
SourcePackPolicyPatch
├─ sourcePackId와 version
├─ targetRulesetId
├─ targetPolicyFamilyId
├─ requiredBaseImplementationRange
├─ patchMode
├─ implementationRef 또는 parameterPatch
├─ explicitPriority
├─ dependencyOrder
└─ patchHash
```

동일 이름이나 Load Order만으로 Core Policy를 덮어쓰지 않는다. 대상 Family와 호환 범위를 명시하지 않은 Patch는 활성화하지 않는다.

### 6.3 PolicyBinding

각 Source가 특정 Scope에 Policy를 적용하는 권위 기록이다.

```text
PolicyBinding
├─ bindingId
├─ sourceKind
├─ sourceRef
├─ targetPolicyFamilyId
├─ implementationRef?
├─ parameterOverrides?
├─ scope
├─ activationPredicate?
├─ explicitPriority?
├─ validityInterval?
├─ issuedBy?
├─ reason?
└─ revision
```

## 7. Policy Source와 Scope

초기 Source 종류:

```text
product_default
ruleset_pack
source_pack_patch
campaign_binding
scene_binding
session_binding
encounter_binding
downtime_binding
runtime_rule_contribution
dm_adjudication_override
user_accessibility_profile
system_safety_constraint
```

초기 Scope 종류:

```text
product
ruleset
campaign
scene
session
encounter
downtime_session
actor
target
observer
user
execution
```

Policy Family는 어떤 Source와 Scope를 허용하는지 선언한다. 예를 들어 `encounter.initiative`에 `user_accessibility_profile`을 적용하거나 `presentation.camera_shake`에 `runtime_rule_contribution`을 적용하는 요청은 Schema 오류다.

## 8. Composition은 Family별 계약이다

모든 Policy에 하나의 단순 우선순위 숫자를 적용하지 않는다.

```text
Policy Family
→ 허용 Source
→ Scope Specificity
→ Composition Mode
→ Conflict Class
→ Invariant Validator
```

을 함께 사용한다.

일반적인 Gameplay Authority 기본 흐름은 다음과 같다.

```text
Product Fallback
→ Ruleset Policy Pack
→ 명시적 Source Pack Patch
→ Campaign Binding
→ Scene·Session·Encounter·Downtime Binding
→ Execution 범위 Rule Contribution
→ 명시적 DM Adjudication Override
→ Product·Security·Operational Invariant 검증
```

단, 이 순서는 기본값일 뿐이다. 각 Family의 `allowedSourceKinds`, `specificityRule`과 `compositionMode`가 최종 결정을 소유한다.

예:

- 수치 상한은 `minimum_cap`으로 가장 엄격한 값을 선택할 수 있다.
- 공개 권한은 `most_restrictive`로 합성할 수 있다.
- Initiative 방식은 `replace_by_precedence`를 사용할 수 있다.
- Presentation Augment는 `append_unique_stable`을 사용할 수 있다.

## 9. Scope Specificity와 안정적 정렬

같은 Precedence Tier 안에서는 다음 순서로 안정적으로 정렬한다.

```text
scope specificity
→ explicit priority
→ dependency order
→ source version
→ stable source ID
→ binding ID
```

Lua Table 순서, Module 로드 시각, Instance 생성 순서와 Remote 도착 순서를 사용하지 않는다.

Scope Specificity 예:

```text
campaign
< scene
< encounter 또는 downtime_session
< actor·target·observer
< execution
```

서로 비교할 수 없는 Scope가 충돌하면 임의로 하나를 고르지 않고 Family Conflict 규칙을 적용한다.

## 10. Dynamic Rule Contribution 경계

Character, Item과 Effect의 일시적 규칙 기여는 전역 Frozen Campaign Snapshot을 매번 다시 컴파일하지 않는다.

```text
Frozen Scope Policy Snapshot
+ Character·Item·Effect의 RuleOverrideContribution
+ 현재 Actor·Target·Execution Context
→ EffectivePolicyView
```

```text
EffectivePolicyView
├─ baselineSnapshotRef
├─ contextDigest
├─ contributionSnapshotRefs[]
├─ dmOverrideRefs[]
├─ resolvedEntries[]
├─ effectiveHash
└─ traceRef
```

규칙:

- Contribution은 허용된 Policy Family에만 기여한다.
- Contribution은 자신의 source identity와 lifecycle을 유지한다.
- Effect 종료 후 새 Execution에는 기여하지 않는다.
- 이미 생성된 RuleExecution은 생성 당시 EffectivePolicyView를 고정한다.
- Contribution이 Campaign·Scene·Encounter Policy Binding을 직접 수정하지 않는다.
- Character Capability와 Modifier Resolver의 기존 책임을 대체하지 않는다.

일반 수치 보정은 Modifier Runtime에 남긴다. Policy Contribution은 규칙 방식 자체를 교체하거나 Family가 허용한 합성에 참여할 때만 사용한다.

## 11. Frozen Policy Snapshot 계층

Policy Snapshot은 사용 범위에 따라 계층화할 수 있다.

```text
CampaignPolicySnapshot
→ Ruleset + Source Pack + Campaign Binding

ScopePolicySnapshot
→ Campaign Snapshot + Scene·Session·Encounter·Downtime Binding

ExecutionEffectivePolicyView
→ Scope Snapshot + Runtime Contribution + 명시적 DM Override
```

공통 구조:

```text
FrozenPolicySnapshot
├─ policySnapshotId
├─ snapshotKind
├─ authorityEpoch
├─ rulesetRef와 version
├─ sourcePackVersionSet
├─ policyRegistryVersion
├─ familySchemaVersionSet
├─ parentSnapshotRef?
├─ sourceBindingRefs[]
├─ resolvedPolicyEntries
├─ invariantSetRef
├─ provenanceIndex
├─ compatibilityClass
├─ snapshotHash
├─ createdAuthorityRevision
├─ activationState
└─ migrationMetadata
```

`resolvedPolicyEntries`의 각 값은 다음을 유지한다.

```text
ResolvedPolicyEntry
├─ policyFamilyId
├─ implementationRef와 version
├─ resolvedParameters
├─ compositionMode
├─ sourceTrace[]
├─ constraintTrace[]
├─ dependencyDigest
└─ entryHash
```

## 12. Frozen 의미

Snapshot은 생성 후 제자리에서 수정하지 않는다.

- 새 Policy Binding은 새 Candidate Snapshot을 만든다.
- 기존 Snapshot ID와 Hash는 바뀌지 않는다.
- 진행 중 Runtime은 자신이 고정한 Snapshot을 계속 사용한다.
- 오래된 Snapshot은 참조하는 Encounter, Downtime, RuleExecution, Schedule과 Replay가 남아 있는 동안 보존한다.

### Encounter

Encounter는 활성화 시 ScopePolicySnapshot을 고정한다. Initiative, Timeline, Turn, Objective와 Round Duration이 같은 Snapshot을 사용한다.

### Downtime

DowntimeSession과 Activity는 시작 시 Policy Snapshot을 고정한다. 중단·환불·필요 시간 의미가 완료 직전에 조용히 바뀌지 않는다.

### RuleExecution

Root RuleExecution이 ExecutionEffectivePolicyView를 고정한다. Child Execution은 기본적으로 부모 View를 상속하되 Capability가 명시적으로 새 Context 해결을 요구하면 안전 경계에서 별도 View를 생성한다.

### Duration과 ScheduledExecution

미래 실행의 의미가 Policy에 의존하면 Schedule에 Policy Snapshot Ref 또는 필요한 Compiled Decision을 저장한다. Due 시 최신 Campaign Policy로 조용히 재해석하지 않는다.

### Projection과 Presentation

권위 결과의 Policy Snapshot은 고정하지만, 권위 결과를 바꾸지 않는 사용자 접근성 Profile은 Presentation 재생 시 최신 안전 설정을 적용할 수 있다.

## 13. Candidate Compile과 활성화

```text
Policy 변경 Proposal
→ Candidate Binding Set
→ Family·Implementation·Version 검증
→ Dependency Graph 해결
→ Deterministic Composition
→ Invariant와 Conflict 검증
→ Candidate Frozen Snapshot
→ Impact·Migration 분석
→ 안전 경계에서 Atomic Activation
→ Domain Event와 Projection 갱신
```

활성 Snapshot Reference와 Campaign·Scope Binding Revision은 하나의 Authority Transaction으로 교체한다.

Candidate Compile 실패 시:

```text
기존 Last Known Good Snapshot 유지
+ 실패 진단
+ 활성 Session 계속 진행
```

실패한 Candidate 일부만 적용하지 않는다.

## 14. Conflict 처리

Conflict 종류:

```text
unknown_policy_family
unknown_implementation
schema_incompatible
ruleset_incompatible
source_not_allowed
scope_not_allowed
exclusive_binding_collision
patch_base_version_mismatch
dependency_cycle
missing_dependency
non_deterministic_order
invariant_violation
forbidden_guardrail_override
migration_required
```

### Blocking Conflict

Gameplay Authority, Disclosure Security와 Operational Safety의 해결되지 않은 Conflict는 Snapshot 활성화를 차단한다.

### Degradable Conflict

Presentation 전용 선택 항목은 안전한 Fallback이 등록되어 있으면 해당 Family만 Fallback으로 낮출 수 있다. 이 경우에도 진단과 Source Trace를 남긴다.

### 같은 Tier 충돌

같은 Family, 같은 Scope Specificity와 같은 Priority에서 서로 다른 `replace_by_precedence` Binding이 충돌하면 Stable ID로 임의 승자를 고르지 않는다. 명시적 Patch 관계, 더 구체적 Scope 또는 DM 선택이 필요하다.

## 15. Hard Invariant와 Guardrail

다음은 일반 Policy Layer가 아니라 최종 Validator 또는 Clamp다.

예:

- Client가 Raw 비밀 Authority State를 받지 않음
- Workspace와 Client Physics가 권위 판정 원본이 아님
- Authority Mutation은 Command와 Transaction을 사용
- Query·Reaction·Scheduler의 Product Hard Budget
- 사용자 접근성의 Flash·Motion Safety 제한
- 신뢰되지 않은 임의 Luau 실행 금지

DM Override, Campaign Setting과 Source Pack도 이를 제거할 수 없다.

```text
Resolved Policy Candidate
→ Hard Invariant Validation
→ Valid Snapshot 또는 Activation Rejection
```

## 16. DM Override

DM Override는 타입 있고 범위가 제한된 권위 기록이다.

```text
PolicyOverrideRecord
├─ overrideId
├─ targetPolicyFamilyId
├─ scope
├─ replacement 또는 parameterPatch
├─ issuedByUserId
├─ issuedAtAuthorityRevision
├─ reason
├─ validityCondition
├─ expiresAtBoundary?
├─ disclosurePolicy
└─ revision
```

지원 Scope 예:

```text
single_execution
current_turn
current_encounter
current_downtime_session
scene
campaign_until_revoked
```

규칙:

- Override는 허용된 Family와 Scope에만 적용한다.
- 모든 Override는 이유와 적용 Trace를 남긴다.
- 이미 Commit된 결과를 과거로 되돌려 바꾸지 않는다.
- 진행 중 Execution에 적용하려면 해당 Runtime의 안전한 Rebind 또는 Migration 절차가 필요하다.
- Disclosure·Authorization·Transaction·Product Hard Cap을 우회하지 않는다.
- 임의 Luau, Workspace Mutation과 Raw State Patch를 포함하지 않는다.

## 17. Policy 변경과 Migration

변경 영향 등급:

```text
display_only
new_execution_only
new_scope_only
compatible_parameter_migration
scope_restart_required
explicit_state_migration_required
prohibited_while_active
```

### display_only

권위 결과를 바꾸지 않는 설명·표시 변경이다. Presentation·Localization Cache만 갱신할 수 있다.

### new_execution_only

기존 Execution은 이전 View를 유지하고 새 Execution부터 새 Snapshot을 사용한다.

### new_scope_only

기존 Encounter·Downtime은 이전 Snapshot을 유지하고 새 Scope부터 적용한다.

### compatible_parameter_migration

Migration Plan과 검증을 거쳐 안전 경계에서 Scope Snapshot을 교체할 수 있다.

### explicit_state_migration_required

Policy 변경이 현재 Encounter Timeline, Duration, Downtime Progress나 Character State 의미를 바꾸면 Domain별 State Migration과 Atomic Commit이 필요하다.

### prohibited_while_active

활성 Session 종료 또는 Campaign Maintenance가 필요하다.

Snapshot을 찾지 못했다는 이유로 자동으로 최신 Policy를 사용하지 않는다.

## 18. Policy Query와 Runtime API 경계

Runtime은 Registry Table을 직접 읽지 않는다.

```text
PolicyResolveContext
├─ policyFamilyId
├─ campaignId
├─ sceneId?
├─ sessionId?
├─ encounterId?
├─ downtimeSessionId?
├─ actorRef?
├─ targetRefs[]
├─ observerRef?
├─ executionId?
├─ policySnapshotRef
├─ authorityRevision
└─ tracePolicy
```

```text
PolicyResolver
→ ResolvedPolicyValue 또는 EffectivePolicyView
```

반환값:

```text
ResolvedPolicyValue
├─ policyFamilyId
├─ typedValue 또는 compiledPlanRef
├─ snapshotRef
├─ effectiveHash
├─ provenanceSummary
├─ constraintSummary
└─ diagnosticsRef?
```

- Query는 읽기 전용이다.
- 같은 Snapshot과 Context Digest는 같은 결과를 반환한다.
- 호출자가 반환 Table을 수정해 Registry나 다른 실행 결과를 바꾸지 못한다.
- 권위 Runtime은 Client가 제출한 Policy 값, Hash와 Trace를 신뢰하지 않는다.

## 19. Randomness와 외부 서비스

Policy Implementation이 주사위 결과를 직접 생성하지 않는다.

예:

```text
Initiative Policy
→ RollPlan 생성
→ Dice Runtime이 서버 권위 난수 해결
→ Policy가 공개된 RollRecord로 Timeline Key 계산
```

시간, 공간, 인벤토리와 Visibility가 필요하면 해당 Runtime의 Snapshot-bound Query를 사용한다. Policy Evaluator가 Workspace, DataStore, Remote 또는 현실 Clock을 직접 호출하지 않는다.

## 20. Persistence, Recovery와 Rollback

저장 대상:

- 활성 CampaignPolicySnapshot Ref와 Hash
- 활성 Scene·Session·Encounter·Downtime ScopePolicySnapshot Ref
- Ruleset·Source Pack Version Set
- Registry와 Family Schema Version Set
- Campaign·Scope PolicyBinding과 Revision
- PolicyOverrideRecord
- 진행 중 RuleExecution·Duration·Schedule의 Policy Snapshot Ref
- Snapshot Migration Record와 Last Known Good Reference

재생성 가능 항목:

- Candidate Snapshot Blob
- Domain Policy View Cache
- EffectivePolicyView Cache
- Composition Trace의 파생 Index

복구 절차:

```text
Snapshot Ref와 Hash 확인
→ Registry·Ruleset·Source Pack Version 확인
→ Snapshot Blob 조회 또는 결정적 재컴파일
→ Hash 검증
→ 참조 중인 Runtime에 Rebind
```

Hash가 다르거나 Implementation을 찾을 수 없으면 조용히 최신 Version을 사용하지 않는다. `recovery_required`로 전환하고 호환 Migration 또는 DM 검토가 필요하다.

Rollback은 선택한 AuthorityEpoch의 Snapshot Ref, Binding Revision과 Override Record를 함께 복원한다. 이전 Epoch에서 늦게 도착한 Policy Compile, Override와 Migration 결과는 새 Epoch에 적용하지 않는다.

## 21. Projection과 비밀 정보

Client는 전체 Policy Registry, 비밀 Campaign 설정과 모든 Composition Trace를 받지 않는다.

```text
Frozen Policy Snapshot
→ Role·Ownership·Disclosure 적용
→ PolicyProjection
```

### Player

현재 행동과 선택에 필요한 공개 Policy 결과, 설명 가능한 제한과 오류 이유를 받는다.

### DM

활성 Snapshot, Source Trace, Conflict, Migration Impact와 Override 도구를 볼 수 있다. 비밀 정보는 DM Projection에만 유지한다.

### Observer

공개된 Encounter·Session 규칙 요약만 받는다.

### Developer Diagnostics

신뢰된 개발 환경에서 Family, Implementation, Hash, Cache와 Budget Trace를 볼 수 있다. 이 정보가 일반 Client에 자동 전송되지 않는다.

Disclosure Policy가 숨긴 Source 이름이나 비밀 목표를 오류 메시지와 Tooltip로 누출하지 않는다.

## 22. Cache와 성능

캐시 Key 최소 항목:

```text
policySnapshotId
snapshotHash
policyFamilyId
contextDigest
authorityEpoch
domainRevisionSet
contributionRevisionSet
dmOverrideRevision
```

무효화 원인:

- 활성 Snapshot Reference 교체
- Scope Binding Revision 변경
- Character·Item·Effect Contribution Revision 변경
- DM Override 시작·종료
- AuthorityEpoch 변경
- Family Schema·Registry Version 변경

전역 Snapshot을 Actor별 Effect 하나가 바뀔 때마다 다시 컴파일하지 않는다. Baseline Snapshot과 Execution Effective View Cache를 분리한다.

## 23. 역할 경계

### SYSTEM_ONLY

- Registry와 Schema 검증
- Candidate Composition과 Snapshot Hash 생성
- Conflict·Invariant 검사
- Snapshot 활성화와 Reference 보존
- Runtime Policy Query와 Trace 생성

### DM_ONLY

- Campaign·Scene·Encounter·Downtime에서 허용된 Policy Binding 선택
- Candidate 변경 검토와 Migration 승인
- 명시적 Policy Override 제출·취소
- Conflict와 Last Known Good 상태 확인

### PLAYER_ONLY

- Character 생성·레벨업에서 허용된 규칙 선택을 일반 Domain 흐름으로 제출
- 자신의 Presentation·Accessibility Profile 변경
- 자신의 행동에 적용된 공개 Policy 설명 확인

플레이어가 Campaign Gameplay Policy, Disclosure Guardrail과 Operational Limit을 직접 수정하지 않는다.

### OBSERVER

공개된 Policy 요약과 Session 규칙만 열람한다.

### CONTENT_DEVELOPER

신뢰된 저장소와 Content Pack을 통해 Policy Family 호환 Implementation, Patch와 Migration을 등록한다. 일반 플레이어가 런타임에서 임의 코드를 등록하는 Plugin 시스템은 제공하지 않는다.

## 24. D&D 2024 기본 예시

```text
CampaignPolicySnapshot
├─ ruleset: dnd5e-2024
├─ initiative: individual_d20_plus_dexterity
├─ round_duration: 6 game seconds
├─ turn_campaign_time: no additional advance
├─ delay: disabled
├─ ready: action_plus_reaction
├─ default_encounter_end: dm_confirmation
└─ long_rest·spell_preparation·other bindings...
```

특정 Encounter가 Side Initiative를 사용하면:

```text
CampaignPolicySnapshot
+ Encounter Binding: side_initiative
→ 새 Encounter ScopePolicySnapshot
```

기존 Encounter는 이전 Snapshot을 유지하고 새 Encounter만 새 Snapshot을 사용할 수 있다.

특정 Effect가 Reaction 규칙을 수정하면:

```text
Encounter ScopePolicySnapshot
+ Effect RuleOverrideContribution
→ 해당 RuleExecution의 EffectivePolicyView
```

CampaignPolicySnapshot 자체는 변경되지 않는다.

## 25. 실패 정책

- Registry 항목 누락: 관련 Candidate Snapshot 활성화 금지
- Source Pack Patch 대상 Version 불일치: Patch 거부, 기존 Snapshot 유지
- 해결되지 않은 Gameplay Conflict: Scope 시작 또는 Policy 전환 차단
- Disclosure·Operational Invariant 위반: 활성화 거부
- Candidate Compile Budget 초과: 안전 중단, Last Known Good 유지
- Snapshot Hash 불일치: Recovery Required
- Migration 실패: 이전 Snapshot과 State 유지
- Projection 실패: Policy Authority 유지, Client 재동기화
- Presentation Policy 실패: 등록된 안전 Fallback 사용 가능
- DM Override 만료 처리 실패: 새 Command 차단 후 최신 권위 상태에서 재평가

## 26. 금지 사항

- Runtime별로 독립적인 Load Order와 Override 우선순위 구현
- Policy 이름 문자열과 Lua Table 순서로 승자 결정
- 활성 Snapshot의 Table을 제자리 수정
- 진행 중 Encounter·Downtime·RuleExecution이 매 Step 최신 Policy 조회
- Source Pack이 대상 Family·Version 없이 Core Policy 덮어쓰기
- Character·Item·Effect Contribution으로 전역 Campaign Snapshot 수정
- DM Override로 Disclosure·Authorization·Transaction·Hard Budget 우회
- 사용자 Accessibility 설정으로 Gameplay Authority 변경
- Policy Evaluator의 Workspace·DataStore·Remote 직접 접근
- Client가 보낸 Policy 결과와 Snapshot Hash를 권위로 신뢰
- Snapshot 누락 시 자동으로 최신 Version 적용
- 임의 사용자 Luau Policy·Merger·Migration 등록

## 27. 구현 명세 준비도

```text
Guide Status: NOT_READY
```

Architecture와 ADR 수준의 Policy 권위 결정은 완료됐다.

구현 명세는 다음 수직 순서로 분리한다.

```text
Policy Family·Implementation Registry Foundation
→ Ruleset·Source Pack Policy Pack Compiler
→ Campaign·Scope Binding과 Candidate Snapshot
→ Composition·Conflict·Invariant Engine
→ Frozen Snapshot Registry와 Persistence
→ Domain Policy View와 Execution EffectivePolicyView
→ Hot Swap·Migration·Last Known Good
→ DM Override·Projection·Diagnostics Adapter
```

Main System Guide는 UI, Diagnostics, Simulation과 남은 통합 계약이 완료된 뒤 작성한다.
