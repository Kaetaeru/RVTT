# ADR-0081: Versioned Policy Composition과 Frozen Ruleset Snapshot을 사용한다

- 상태: 확정
- 결정일: 2026-08-04
- 관련 문서:
  - [`ADR-0003`](ADR-0003-ruleset-source-packs-localization.md)
  - [`ADR-0054`](ADR-0054-compiled-semantic-runtime-and-query-authority-principles.md)
  - [`ADR-0064`](ADR-0064-immutable-compiled-builds-and-versioned-authoritative-state.md)
  - [`ADR-0070`](ADR-0070-orthogonal-session-modes-contexts-overlays-and-transitions.md)
  - [`ADR-0078`](ADR-0078-authoritative-game-time-boundary-durations-and-scheduled-execution.md)
  - [`ADR-0079`](ADR-0079-policy-driven-encounter-timelines-and-opportunity-gated-turns.md)
  - [`ADR-0080`](ADR-0080-downtime-as-time-coordinated-activity-sessions-with-domain-owned-completion.md)
  - [`Ruleset Policy Runtime 계약`](../architecture/ruleset-policy-registry-composition-and-frozen-snapshot-runtime-contract.md)

## 배경

RVTT의 Encounter, Game Time, Downtime, Visibility, Migration과 Presentation은 플레이테스트와 캠페인 설정에 따라 바뀔 수 있는 Policy를 사용한다.

예:

- Initiative와 Turn 방식
- Action Economy
- Objective와 Encounter 종료
- 1 Round의 Campaign Time 반영
- Downtime 중단·환불
- 공개 정보 제한
- Runtime Budget
- Presentation과 접근성

각 Runtime이 자신의 Registry, Load Order와 Override 우선순위를 따로 구현하면 같은 Campaign 설정이 서로 다르게 적용되고, 활성 실행 중 Policy Version이 섞이며, DM Override나 Source Pack Patch가 보안·권위 경계를 우회할 수 있다.

또한 Character·Item·Effect가 제공하는 일시적 RuleOverride는 필요하지만, 이를 이유로 전역 Campaign Policy Snapshot을 계속 다시 작성하면 캐시·복구·재현성이 무너진다.

## 결정

모든 교체형 Policy는 공통 `Policy Registry`와 결정적 Composition을 사용한다.

```text
Policy Family·Implementation Registry
+ Ruleset·Source Pack·Campaign·Scope Binding
→ Candidate Composition
→ Conflict·Invariant 검증
→ Immutable Frozen Policy Snapshot
→ Domain Policy View
→ Execution Effective Policy View
```

## Policy Plane

Policy는 다음 Plane으로 분리한다.

```text
gameplay_authority
disclosure_security
operational_safety
presentation_accessibility
```

서로 다른 Plane을 하나의 단순 우선순위 숫자로 비교하지 않는다.

- Gameplay Policy는 규칙 결과와 진행 방식을 결정한다.
- Disclosure Policy는 Client-safe 정보 공개 한계를 결정한다.
- Operational Policy는 Budget과 신뢰 경계를 결정한다.
- Presentation Policy는 권위 결과를 바꾸지 않는 표현과 접근성을 결정한다.

Disclosure와 Operational Hard Invariant는 일반 Campaign 설정과 DM Override로 완화할 수 없다. 사용자 접근성 제한은 DM Presentation Preference보다 우선할 수 있지만 Gameplay Authority를 변경하지 않는다.

## Registry와 Composition

Policy Family는 다음을 선언한다.

```text
stable family ID
input·output·parameter schema
allowed source kinds
allowed scopes
composition mode
conflict class
invariant validators
fallback
```

Policy Implementation은 Version, Ruleset 호환성, 신뢰된 Evaluator, Dependency, Budget과 Migration을 가진다.

합성은 Family별 계약으로 수행한다.

일반적인 Gameplay 기본 흐름:

```text
Product Fallback
→ Ruleset Policy Pack
→ 명시적 Source Pack Patch
→ Campaign Binding
→ Scene·Session·Encounter·Downtime Binding
→ Execution 범위 Rule Contribution
→ 명시적 DM Adjudication Override
→ Hard Invariant 검증
```

하지만 Family의 Composition Mode가 최종 의미를 소유한다. 공개 제한은 `most_restrictive`, 상한은 `minimum_cap`, Initiative 방식은 `replace_by_precedence`처럼 서로 다르게 합성할 수 있다.

같은 Tier의 배타적 Binding이 충돌하면 Stable ID로 임의 승자를 고르지 않고 Snapshot 활성화를 차단한다.

## Frozen Snapshot

Policy Composition 결과는 불변 Snapshot이다.

```text
CampaignPolicySnapshot
→ Ruleset + Source Pack + Campaign

ScopePolicySnapshot
→ Campaign + Scene·Session·Encounter·Downtime

ExecutionEffectivePolicyView
→ Scope Snapshot + Character·Item·Effect Contribution + DM Override
```

Snapshot은 생성 후 제자리에서 수정하지 않는다. 새 Binding과 Policy Version은 새 Snapshot을 만든다.

- Encounter는 활성화 시 Scope Snapshot을 고정한다.
- DowntimeSession과 Activity는 시작 시 Snapshot을 고정한다.
- Root RuleExecution은 생성 시 Effective Policy View를 고정한다.
- Duration과 ScheduledExecution은 필요한 Snapshot Ref 또는 Compiled Decision을 보존한다.
- 기존 실행은 최신 Policy를 매 Step 다시 읽지 않는다.

기존 문서의 `rulesetSnapshotRef`, `policySetRef`와 유사한 필드는 이 Frozen Snapshot 또는 그 Domain View를 참조한다.

## Dynamic Rule Contribution

Character, Item과 Effect의 일시적 규칙 기여는 전역 Campaign Snapshot을 수정하지 않는다.

```text
Frozen Scope Snapshot
+ 타입 있는 RuleOverrideContribution
+ 현재 Execution Context
→ EffectivePolicyView
```

일반 수치 보정은 기존 Modifier Resolver에 남긴다. 규칙 방식 자체를 바꾸는 허용된 Family만 Policy Contribution을 사용한다.

## Source Pack Patch

Source Pack은 다른 Policy를 이름이나 Load Order만으로 덮어쓰지 않는다.

Patch는 다음을 명시한다.

```text
target ruleset
target policy family
required base implementation range
patch mode
version과 dependency order
```

대상 Version이 맞지 않거나 충돌이 해결되지 않으면 Candidate Snapshot을 활성화하지 않는다.

## DM Override

DM Override는 타입 있고 Scope와 만료 조건이 있는 권위 기록이다.

- 이유와 Source Trace를 남긴다.
- 이미 Commit된 과거 결과를 바꾸지 않는다.
- 진행 중 실행에는 안전한 Rebind·Migration이 필요하다.
- Disclosure, Authorization, Transaction과 Product Hard Budget을 우회하지 않는다.
- 임의 Luau와 Raw State Patch를 포함하지 않는다.

## Hot Swap과 Migration

Policy 변경은 영향 등급을 가진다.

```text
display_only
new_execution_only
new_scope_only
compatible_parameter_migration
scope_restart_required
explicit_state_migration_required
prohibited_while_active
```

Candidate Compile과 Migration이 실패하면 Last Known Good Snapshot과 현재 권위 상태를 유지한다.

Snapshot이나 Implementation을 찾지 못했다는 이유로 최신 Version을 자동 적용하지 않는다.

## Persistence와 Rollback

다음을 저장한다.

- 활성 Campaign·Scope Snapshot Ref와 Hash
- Ruleset·Source Pack·Registry Version Set
- Policy Binding과 DM Override
- 진행 중 Encounter·Downtime·RuleExecution·Schedule의 Snapshot Ref
- Migration과 Last Known Good 기록

복구 시 Snapshot Blob을 조회하거나 결정적으로 재컴파일해 Hash를 검증한다. Hash가 다르거나 Implementation이 누락되면 `recovery_required`로 전환한다.

Rollback은 해당 AuthorityEpoch의 Snapshot Ref와 Override를 함께 복원하며 이전 Epoch의 비동기 Compile·Migration 결과를 무효화한다.

## 금지 사항

- Runtime마다 별도 Load Order와 Override 규칙 구현
- Lua Table 순서, Module 로드 시각과 표시 이름으로 Policy 승자 결정
- 활성 Snapshot 제자리 수정
- 진행 중 실행이 매 단계 최신 Policy 조회
- Source Pack의 암묵적 Core Policy 덮어쓰기
- Character·Item·Effect가 전역 Campaign Snapshot 수정
- DM Override로 보안·권위·Budget Guardrail 우회
- 사용자 접근성 설정으로 Gameplay Authority 변경
- Policy Evaluator의 Workspace·DataStore·Remote 직접 접근
- 누락된 Snapshot 대신 최신 Version 자동 사용
- 일반 사용자의 임의 Luau Policy·Merger·Migration 등록

## 결과

### 장점

- 모든 Runtime이 같은 Policy Version과 Override 의미를 사용한다.
- 진행 중 Encounter, Downtime과 RuleExecution의 규칙이 중간에 섞이지 않는다.
- Source Pack, Campaign 설정과 DM 판정의 출처를 설명할 수 있다.
- 저장·복구·Rollback과 Replay가 같은 규칙 결과를 재현할 수 있다.
- Character·Item·Effect의 일시적 규칙 변경과 전역 Policy를 분리할 수 있다.
- Disclosure, Operational Safety와 Accessibility를 Gameplay 우선순위와 혼합하지 않는다.

### 비용

- Policy Family Schema, Registry와 Snapshot Compiler가 필요하다.
- 이전 Snapshot 보존과 Migration 관리 비용이 생긴다.
- DM 설정 변경이 즉시 모든 진행 중 실행에 적용되지 않을 수 있다.
- 각 Policy Family가 자신의 합성 방식과 Conflict 규칙을 명시해야 한다.

이 비용은 Runtime별 하드코딩과 재현 불가능한 Hot Swap을 나중에 제거하는 비용보다 작다.
