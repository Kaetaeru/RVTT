# Extension, Plugin과 Content Pack 시스템

Ruleset, Source Pack, Rule Content, Recipe Step, Policy, Scene Compiler Provider, Scene Editor Tool과 Presentation Module의 신뢰된 확장 경계를 안내한다.

이 영역은 새로운 독립 Gameplay Engine을 소유하지 않는다. 각 확장은 기존 Domain의 Registry, Compiler, Command, Transaction, Projection, Diagnostics와 Simulation 계약 안에서 동작한다.

## Main System Guide

- [`Extension, Plugin과 Content Pack Guide`](../../guides/extension/README.md)
  - Content Pack·Trusted Module·Campaign Authored Data 구분
  - Registry·Compiler·Policy·Recipe·Provider·Presentation Module 등록·검증·Version·Migration
  - Pack 활성화·제거·Last Known Good·Recovery·Disclosure·Simulation 검증

## 핵심 권위 문서

### Content Pack과 Policy

- [`../../decisions/ADR-0001-authored-rules-content.md`](../../decisions/ADR-0001-authored-rules-content.md)
  - 플레이어용 범용 규칙 제작기 대신 개발자 관리 정식 콘텐츠를 직접 구현
- [`../../decisions/ADR-0003-ruleset-source-packs-localization.md`](../../decisions/ADR-0003-ruleset-source-packs-localization.md)
  - Ruleset, Source Pack, 고정 Content ID, Campaign 활성 Version Set과 Localization 분리
- [`../../architecture/ruleset-policy-registry-composition-and-frozen-snapshot-runtime-contract.md`](../../architecture/ruleset-policy-registry-composition-and-frozen-snapshot-runtime-contract.md)
  - Policy Family·Implementation·Merger Registry
  - Source Pack Patch, Candidate Snapshot, Conflict·Invariant·Migration과 Last Known Good

### Rule Content와 Recipe

- [`../../architecture/rules-content-grant-capability-model.md`](../../architecture/rules-content-grant-capability-model.md)
  - RulesContentCatalog, Grant Graph, Capability와 전용 Handler 경계
- [`../../architecture/rules-content-execution-and-spell-contract.md`](../../architecture/rules-content-execution-and-spell-contract.md)
  - RuleContentDefinition, Recipe와 제한된 콘텐츠별 실행 확장
- [`../rules/standard-recipe-step-library.md`](../rules/standard-recipe-step-library.md)
  - 버전된 Step·SubRecipe Registry와 상한이 있는 AdvancedOperation
- [`../../architecture/effect-recipe-resolution-and-commit-model.md`](../../architecture/effect-recipe-resolution-and-commit-model.md)
  - PendingEffect, CommitGroup과 권위 상태 변경 경계

### Scene과 Authoring

- [`../../architecture/scene-compiler-and-compiled-runtime-scene-contract.md`](../../architecture/scene-compiler-and-compiled-runtime-scene-contract.md)
  - SceneCompilerProvider, Semantic Contribution, Layer Artifact와 결정적 Build
- [`../../architecture/scene-editor-tool-module-architecture.md`](../../architecture/scene-editor-tool-module-architecture.md)
  - Tool Registry, Capability, Context, Command, Object Type와 Migration
- [`../../decisions/ADR-0010-replicatedstorage-prefab-catalog.md`](../../decisions/ADR-0010-replicatedstorage-prefab-catalog.md)
  - 신뢰된 Prefab Catalog, Stable PrefabId와 서버 검증 배치

### Presentation

- [`../../architecture/presentation-recipe-playback-priority-and-extension-runtime-contract.md`](../../architecture/presentation-recipe-playback-priority-and-extension-runtime-contract.md)
  - Compiled Presentation Recipe, Module·Augment Registry, Version·Fallback·Budget
- [`../../decisions/ADR-0046-modular-presentation-recipes-and-extension-contracts.md`](../../decisions/ADR-0046-modular-presentation-recipes-and-extension-contracts.md)
  - 규칙과 Presentation 분리, 내부 Registry 기반 신뢰 확장
- [`../../decisions/ADR-0075-versioned-data-driven-and-fault-isolated-presentation-runtime.md`](../../decisions/ADR-0075-versioned-data-driven-and-fault-isolated-presentation-runtime.md)
  - Version 고정, Hot Swap, 오류 격리와 자유 Luau 금지

### 안전한 사용자 콘텐츠와 검증

- [`../character/monster-npc-statblock-and-ingame-json-import-model.md`](../character/monster-npc-statblock-and-ingame-json-import-model.md)
  - DM JSON을 검증·정규화·컴파일해 Campaign Content로 승격
- [`../../architecture/diagnostics-observability-correlated-trace-and-incident-runtime-contract.md`](../../architecture/diagnostics-observability-correlated-trace-and-incident-runtime-contract.md)
  - Extension Span·Budget·Health·Redaction과 Incident
- [`../../architecture/deterministic-simulation-scenario-and-test-harness-runtime-contract.md`](../../architecture/deterministic-simulation-scenario-and-test-harness-runtime-contract.md)
  - Registry·Migration·Failure·Disclosure의 생산 경로 검증

## 고정 경계

- 일반 플레이어나 DM이 런타임에 임의 Luau, ModuleScript, Remote, DataStore 경로를 등록하는 Plugin Sandbox는 제공하지 않는다.
- 신뢰 코드 확장은 개발자가 저장소와 배포 Build에 포함하고 Registry 검증을 통과시킨 Module만 사용한다.
- Source Pack은 고정 ID, Version, Ruleset, Dependency, Patch 대상과 Localization을 명시한다.
- Load Order, 파일명, 표시 이름, Roblox Instance 이름과 Lua Table 순서로 충돌 승자를 정하지 않는다.
- Campaign은 정확한 Ruleset·Source Pack Version Set을 고정하며 누락 시 최신 Version을 자동 사용하지 않는다.
- 진행 중 Encounter, Downtime, RuleExecution, Playback과 Scene Runtime은 시작 당시 Policy·Content·Recipe·Build Version을 유지한다.
- Pack·Module 변경은 Candidate Compile, Compatibility·Migration 검증과 안전 경계의 원자 활성화를 사용한다.
- 실패한 Candidate 일부를 활성 상태에 섞지 않고 Last Known Good Version을 유지한다.
- Rule Handler, Step, AdvancedOperation, Policy Evaluator, Compiler Provider와 Tool Module은 권위 Store를 직접 수정하지 않는다.
- 영구 Gameplay 변경은 기존 Command·RuleExecution·PendingEffect·Transaction 경계를 사용한다.
- Presentation Module은 Authority State, Visibility, Camera Policy와 접근성 Hard Limit을 우회하지 않는다.
- DM JSON과 Campaign Authored Content는 등록된 데이터 노드와 참조만 사용하며 개발자 전용 Handler를 호출하지 않는다.
- 제거·업데이트할 Pack이 Character, Item, Actor, Scene, Journal, Pending Execution이나 Snapshot에서 참조되면 명시적 Migration 또는 제거 차단이 필요하다.
- 비밀 Content Definition, Source Lineage, Handler ID와 Pack Metadata를 Player Client에 모두 복제한 뒤 UI에서만 숨기지 않는다.

## Guide Status

```text
CURRENT
```

현재 Source Pack·Trusted Module·Campaign Authored Content와 각 Registry 확장 경계는 Main System Guide에 반영되어 있다. 관련 권위 계약이 변경되면 Guide를 `UPDATE_REQUIRED`로 전환한다.
