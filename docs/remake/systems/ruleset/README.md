# Ruleset와 Policy 시스템

규칙 세트, Source Pack Policy Patch, Campaign·Scope 설정, Policy Composition과 Frozen Snapshot을 다룬다.

## 상위 권위 문서

- [`Ruleset Policy Registry, Composition과 Frozen Snapshot Runtime 계약`](../../architecture/ruleset-policy-registry-composition-and-frozen-snapshot-runtime-contract.md)
  - Policy Family·Implementation·Merger Registry
  - Gameplay, Disclosure, Operational, Presentation Policy Plane
  - Ruleset·Source Pack·Campaign·Scope Binding과 결정적 Composition
  - Campaign·Scope Frozen Snapshot과 Execution Effective Policy View
  - Conflict, Hard Invariant, DM Override, Hot Swap와 Migration
  - Persistence, Recovery, Rollback과 Last Known Good Snapshot
- [`Compiled Build와 Authoritative State 분리 패턴`](../../architecture/compiled-build-and-authoritative-state-pattern.md)
  - Policy Source, Candidate Build, 불변 Snapshot과 활성 Reference 분리
- [`Runtime Architecture Principles`](../../architecture/runtime-architecture-principles.md)
  - 신뢰된 Registry, 결정적 Query, Command·Transaction 권위 경계
- [`ADR-0081`](../../decisions/ADR-0081-versioned-policy-composition-and-frozen-ruleset-snapshots.md)
  - 공통 Policy Composition과 Frozen Ruleset Snapshot 결정
- [`ADR-0003`](../../decisions/ADR-0003-ruleset-source-packs-localization.md)
  - 기본 Ruleset `dnd5e-2024`, Source Pack과 명시적 Patch·Version 계약

## Policy 계층

```text
Policy Family·Implementation Registry
→ Ruleset Policy Pack
→ Source Pack Patch
→ Campaign Policy Binding
→ Scene·Session·Encounter·Downtime Binding
→ Frozen Scope Policy Snapshot
→ Character·Item·Effect Rule Contribution
→ Execution Effective Policy View
```

Policy는 권위 상태를 직접 변경하지 않는다. Encounter, Game Time, Downtime, Rule Runtime과 다른 Domain은 Policy 결과를 사용해 Command, RuleExecution과 Transaction을 생성한다.

## Policy Plane

```text
gameplay_authority
→ 게임 규칙 결과와 진행 방식

disclosure_security
→ Client-safe 공개 한계

operational_safety
→ Budget, Trust와 서버 안전 상한

presentation_accessibility
→ 권위 결과를 바꾸지 않는 표현과 접근성
```

서로 다른 Plane에 하나의 단순 우선순위를 적용하지 않는다.

## 고정 경계

- Policy Family는 안정적 ID, Schema, 허용 Source·Scope와 Composition Mode를 가진다.
- Source Pack은 대상 Ruleset·Family·Version을 명시한 Patch만 제공한다.
- 같은 Tier의 배타적 Binding 충돌은 임의 승자를 선택하지 않고 활성화를 차단한다.
- 진행 중 Encounter, Downtime과 RuleExecution은 생성 당시 Snapshot을 유지한다.
- Character·Item·Effect Contribution은 전역 Campaign Snapshot을 수정하지 않는다.
- DM Override는 타입, Scope, 이유, 만료와 Audit Record를 가진다.
- Disclosure, Authorization, Transaction과 Product Hard Budget은 DM Override로 우회하지 않는다.
- 사용자 Accessibility 설정은 Gameplay Authority를 변경하지 않는다.
- Policy Evaluator와 Merger는 신뢰된 Registry 항목만 사용한다.
- Snapshot 누락 시 최신 Version을 자동 적용하지 않는다.
- Candidate Compile과 Migration 실패 시 Last Known Good Snapshot을 유지한다.

## Runtime 연결

- Encounter Policy는 [`Combat 시스템`](../combat/README.md)을 따른다.
- Campaign Time과 Round Duration은 [`Time 시스템`](../time/README.md)을 따른다.
- 장기 활동 Policy는 [`Downtime 시스템`](../downtime/README.md)을 따른다.
- Character·Item·Effect Contribution은 [`Rules 시스템`](../rules/README.md)과 각 Domain 계약을 따른다.
- Projection과 Disclosure는 Visibility·Networking 계약을 따른다.

## 추천 읽기 순서

1. `../../architecture/runtime-architecture-principles.md`
2. `../../architecture/compiled-build-and-authoritative-state-pattern.md`
3. `../../decisions/ADR-0003-ruleset-source-packs-localization.md`
4. `../../architecture/ruleset-policy-registry-composition-and-frozen-snapshot-runtime-contract.md`
5. `../../decisions/ADR-0081-versioned-policy-composition-and-frozen-ruleset-snapshots.md`
6. Policy를 사용하는 관련 Runtime Architecture

## Guide 상태

```text
Guide Status: READY_TO_WRITE
```

최신 Completion Audit와 Main System Guide 작업 순서에서 Policy·Rules 실행 Guide 작성 조건을 통과했다.
