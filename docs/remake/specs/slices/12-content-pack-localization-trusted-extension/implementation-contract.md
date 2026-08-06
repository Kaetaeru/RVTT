# Implementation Spec — Slice 12 Content Pack·Localization·Trusted Extension Platform

- 상태: SPEC_CHECKPOINT_COMPLETE
- 문서 종류: Slice Integration Implementation Spec
- 구현 상태: 미구현
- 즉시 구현 명세 가능성: BLOCKED
- 작성일: 2026-08-05
- 차단 이유: 실제 Packaging·Signing·Asset·Registry·Build Pipeline과 권리 검토 경로가 확인되지 않았다.
- Work Order: [`CURRENT-WORK-ORDER.md`](CURRENT-WORK-ORDER.md)
- Roadmap: [`SLICE-ROADMAP.md`](../../SLICE-ROADMAP.md)
- 관련 Guide: [`Extension`](../../../guides/extension/README.md), [`Runtime`](../../../guides/runtime/README.md), [`Rules`](../../../guides/rules/README.md), [`Scene Editor`](../../../guides/scene-editor/README.md), [`UI`](../../../guides/ui/README.md), [`Diagnostics`](../../../guides/diagnostics/README.md)

> Extension은 신뢰된 Registry·Provider·Module을 추가하지만 Authority Store, Transaction, Disclosure와 Operational Hard Cap을 우회하지 않는다. 공개 사용자 코드 Plugin·Marketplace는 현재 범위가 아니다.

## 1. Acceptance Flow

```text
Pack Candidate 준비
→ Manifest·Catalog·Locale·Dependency 검증
→ Policy·Content·Recipe·Provider Compile
→ Contract·Disclosure·Budget Test
→ Migration Review
→ Candidate Activation
→ Campaign Binding·Frozen Snapshot
→ Restart·Rollback 후 같은 Version 복원
```

Player와 DM은 표시 언어에 맞는 문자열을 보지만 Stable Content ID와 규칙 결과는 Locale 변경으로 달라지지 않는다.

## 2. 직접 권위 문서

- [`Compiled Build와 Authoritative State 분리`](../../../architecture/compiled-build-and-authoritative-state-pattern.md)
- [`Ruleset Policy Registry와 Frozen Snapshot`](../../../architecture/ruleset-policy-registry-composition-and-frozen-snapshot-runtime-contract.md)
- [`Rules Content Grant와 Capability`](../../../architecture/rules-content-grant-capability-model.md)
- [`Rules Content Execution과 Spell Contract`](../../../architecture/rules-content-execution-and-spell-contract.md)
- [`Effect Recipe Resolution과 Commit`](../../../architecture/effect-recipe-resolution-and-commit-model.md)
- [`Rule Runtime Orchestrator`](../../../architecture/rule-runtime-orchestrator-and-pending-execution-contract.md)
- [`Scene Compiler와 Compiled Runtime Scene`](../../../architecture/scene-compiler-and-compiled-runtime-scene-contract.md)
- [`Scene Editor Tool Module Architecture`](../../../architecture/scene-editor-tool-module-architecture.md)
- [`Presentation Recipe와 Extension Runtime`](../../../architecture/presentation-recipe-playback-priority-and-extension-runtime-contract.md)
- [`Domain Event와 Projection Runtime`](../../../architecture/domain-event-outbox-subscription-and-projection-runtime-contract.md)
- [`Persistence와 Session Recovery`](../../../architecture/persistence-and-session-recovery-model.md)
- [`Deterministic Simulation과 Test Harness`](../../../architecture/deterministic-simulation-scenario-and-test-harness-runtime-contract.md)
- [`Extension 시스템`](../../../systems/extension/README.md)

## 3. 범위

포함:

- Pack Manifest·Stable Pack·Content·Version ID
- Catalog·Dependency·Patch·Conflict Compiler
- Localization Bundle·Fallback·Authority Digest 분리
- Policy Registry·Composition·Frozen Snapshot
- Grant·Capability·Recipe·Step·Advanced Operation Registry
- Trusted Prefab·Scene Tool·Compiler Provider Host
- Trusted Presentation Module·Recipe·Augment Host
- Candidate Activation·Migration·Deprecation·Removal·Rollback
- Permission Projection·Diagnostics·Deterministic Contract Test

제외:

- 공개 Marketplace·일반 사용자 코드 Plugin
- 외부 URL Runtime Code Download
- 플레이어용 범용 Spell·Feature 제작기
- Audio·NPC Dialogue를 Extension으로 우회 구현

## 4. Pack와 Catalog Type

```lua
export type ContentPackManifest = {
    packId: string,
    packVersion: string,
    manifestSchemaVersion: number,
    contentDigest: string,
    dependencyRefs: {string},
    optionalDependencyRefs: {string},
    trustClass: "official" | "developer_trusted" | "campaign_authored_data",
    localeBundleRefs: {string},
    policyPatchRefs: {string},
    migrationRefs: {string},
}

export type ContentDefinitionRef = {
    packId: string,
    packVersion: string,
    contentType: string,
    contentId: string,
    contentVersion: number,
}

export type RegistryVersionSet = {
    policyRegistryVersion: string,
    recipeRegistryVersion: string,
    operationRegistryVersion: string,
    toolRegistryVersion: string,
    providerRegistryVersion: string,
    presentationRegistryVersion: string,
}

export type CampaignContentBinding = {
    campaignId: string,
    packVersionRefs: {string},
    policySnapshotRef: string,
    registryVersionSet: RegistryVersionSet,
    bindingRevision: number,
}
```

Pack·Content ID는 이름·파일 경로·Instance 순서와 분리한다. 같은 Pack ID·Version·Digest는 결정적 Catalog 결과를 만들어야 한다.

## 5. Dependency·Catalog Compile

```text
Pack Candidate Set
→ Manifest Schema
→ Dependency Version·Cycle
→ Content ID 충돌
→ Patch Base·Priority
→ Trust·Capability·Budget
→ Deterministic Sort
→ Candidate Catalog
```

Lua Table 순서, 파일 시스템 순서와 Instance 자식 순서가 결과에 영향을 주지 않는다. Duplicate Content ID, Dependency Cycle, Patch Base 불일치와 Missing Required Dependency는 Activation을 차단한다.

Pack Compile 실패 시 현재 Active Catalog와 Session을 유지한다.

## 6. Localization

```text
Stable Content ID
+ Locale Key
→ Locale Bundle
→ Locale Fallback Chain
→ Display String
```

규칙 수치·Binding·Target·Formula·Capability 의미를 번역 문자열에 저장하지 않는다. Locale Bundle 변경은 Authority Content Digest와 진행 중 Execution Version을 바꾸지 않는다.

Missing Key는 구조화된 Diagnostic과 Fallback을 제공한다. 권한 없는 Content·Secret Actor의 Locale Key와 Label도 Player에게 전달하지 않는다.

## 7. Policy Composition

```text
Product Safe Default
+ Ruleset Policy Pack
+ Source Pack Patch
+ Campaign Binding
+ Scene·Encounter·Downtime Scope Binding
→ Frozen Policy Snapshot
```

Composition은 Family별 Conflict·Priority·Guardrail을 검증한다. Pack이 Security·Disclosure·Operational Hard Cap을 낮출 수 없다. 진행 중 RuleExecution·Encounter·Downtime은 시작 당시 Snapshot을 유지한다.

새 Policy Activation은 기존 진행 실행을 제자리 교체하지 않고 새 실행부터 적용한다.

## 8. Content·Recipe·Operation Registry

Content Compiler는 Character Grant, Spell·Item·Actor Definition, Effect Recipe와 Capability를 검증된 Build로 만든다.

Recipe·Step:

```text
Definition Source
→ Schema·Binding Type·Dependency Validation
→ Compiled Recipe
→ RuleExecution Adapter
```

Advanced Operation은 Trusted Code Registry에서만 등록한다. Time, Target, Loop, Generated Effect, Query와 Output Budget을 가진다. PendingEffect·Transaction·Outbox를 우회하는 직접 Store Mutation은 금지한다.

Missing Handler·Recipe Version에서 최신 Version을 자동 대체하지 않는다. Migration Adapter, Read-only Recovery 또는 안전 취소를 사용한다.

## 9. Tool·Provider·Presentation Host

Trusted Scene Tool·Compiler Provider:

- Tool ID·Version·Capability·Object Schema
- Dependency·Migration·Lifecycle
- Deterministic Semantic Contribution
- Failure Isolation·Budget

Presentation Module·Recipe:

- Parameter Schema·Audience·Quality·Accessibility
- Module Version·Fallback·Timeout
- 진행 Playback Version 고정
- Gameplay Outcome 불변

Prefab Catalog는 검증된 Asset·권리·Source Metadata와 Server-side Placement Policy를 가진다. Client Ghost의 Prefab ID·Transform을 신뢰하지 않는다.

## 10. Campaign Authored Data Trust

Campaign Authored NPC·Item·Scene Data는 Code Extension이 아니다.

```text
JSON·Form Input
→ 크기·깊이·String·Array·Reference Validation
→ Normalization
→ Candidate Content Definition
→ Compile·Diagnostic
→ DM Review·Publish
```

Code, Module, Remote, URL, Callback과 무한 Graph 입력을 거부한다. Campaign Data가 Trusted Operation을 새로 등록하지 못한다.

## 11. Activation·Migration·Removal

```text
Candidate Catalog·Registry
→ Contract·Scenario·Disclosure·Load Test
→ 사용 중 Reference Scan
→ Migration Plan
→ DM·Developer Review
→ Atomic Activation
→ Active Version Pointer·Journal
```

Pack 제거 시 Character·Item·Actor·Scene·RuleExecution·Journal Anchor의 사용 중 Ref를 검사한다. Missing Pack을 조용히 최신 Pack이나 이름이 같은 Content로 대체하지 않는다.

Migration 실패 시 Last Known Good Catalog·Build·Campaign Binding을 유지한다. Rollback은 Snapshot에 기록된 Pack·Policy·Recipe·Build Version Set을 새 AuthorityEpoch에서 복원한다.

## 12. Persistence·Projection·Security

저장:

- Pack Manifest·Digest·Active Pointer
- Catalog·Registry Version Set
- Campaign Binding·Frozen Snapshot Ref
- Migration·Deprecation·Removal Record
- Content Source·Compiled Build Ref
- 진행 Execution의 exact Version Ref

Player Projection에는 공개 가능한 Content Summary와 Localization만 포함한다. Secret Actor·Pack Lineage·Source Path·Diagnostic·Migration 내부 정보는 제외한다.

Security:

- Client-supplied Handler·Module·Recipe·URL 실행 금지
- Trust Class별 Capability Allowlist
- Pack·Definition·Graph·Operation·Asset Payload Budget
- Module 오류의 Registry·Gameplay 격리
- Release Asset 권리·접근권 Gate

## 13. Diagnostics·Test

Trace:

```text
pack.load
catalog.compile
locale.resolve
policy.compose
content.compile
recipe.compile
operation.invoke
tool.register
provider.compile
presentation.register
pack.migrate
pack.activate
pack.remove
```

Test:

1. 같은 Pack Set의 Catalog·Digest 결정성.
2. Dependency Cycle·ID 충돌·Patch Base 불일치 차단.
3. Locale 변경 후 Authority Digest 불변.
4. Missing Locale Fallback·Diagnostic.
5. 진행 Execution의 Pack·Policy·Recipe Version 고정.
6. Pack 제거 사용 중 Ref 차단.
7. Migration 성공·실패·Last Known Good.
8. Missing Handler 최신 자동 대체 금지.
9. Grant Graph Cycle·Missing Content Recovery.
10. Advanced Operation Budget·Store Mutation 우회 차단.
11. Campaign JSON Code·URL·무한 Graph 거부.
12. Tool·Provider·Presentation 오류 격리.
13. Secret Content·Source Lineage Negative Disclosure.
14. Restart·Rollback 후 exact Version 복구.
15. 대규모 Catalog·Scene·Presentation Load Test.

## 14. 구현 순서와 완료 기준

```text
Manifest·Stable ID·Localization
→ Dependency·Catalog Compiler
→ Policy Registry·Snapshot
→ Grant·Capability·Recipe Registry
→ Trusted Operation Host
→ Tool·Provider·Presentation Host
→ Activation·Migration·Removal
→ Persistence·Security·Contract Test
```

완료 기준:

- Pack·Content·Registry Version이 결정적이고 저장된다.
- Localization이 규칙 의미와 분리된다.
- Trusted Extension이 Authority·Budget·Disclosure를 우회하지 않는다.
- 진행 실행이 Version을 고정한다.
- Activation 실패가 Last Known Good를 손상하지 않는다.

Production 구현 전 실제 Build·Package·Signing·Asset·CI·권리 검토 Mapping이 필요하다.