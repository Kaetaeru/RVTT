# Main System Guide: Extension, Plugin과 Content Pack

- Guide Status: CURRENT
- 적용 시스템 상태: GUIDE_CURRENT
- 작성일: 2026-08-05
- 마지막 권위 문서 검토일: 2026-08-05
- Completion Audit: [`Runtime Architecture Completion과 Main System Guide 준비도 감사`](../../audits/runtime-architecture-completion-and-main-guide-readiness-audit.md)
- 대체하는 Guide: 없음
- 대체된 Guide: 없음

> 이 Guide는 기존 권위 문서를 연결하고 설명한다. 새로운 규칙·결정·API·데이터 구조를 정의하지 않는다.

## 1. 시스템 목적과 사용자 결과

이 Guide는 새 규칙 콘텐츠, 공식 출처, 홈브루 NPC, Scene 제작 도구, Compiler Layer와 VFX를 RVTT에 추가할 때 Core Runtime을 직접 수정하거나 신뢰되지 않은 코드를 실행하지 않고 기존 Registry·Compiler·Command·Transaction·Projection 경계 안에 연결하는 전체 흐름을 설명한다.

RVTT에서 `Extension`, `Plugin`과 `Content Pack`은 같은 개념이 아니다.

- **Content Pack·Source Pack**은 고정 ID, Version, Ruleset, Dependency, Content Index, Localization, Asset와 명시적 Patch를 가진 개발자 관리 콘텐츠 묶음이다.
- **Trusted Module Extension**은 저장소와 배포 Build에 포함되고 Registry 검증을 통과한 Handler·Provider·Tool·Presentation Module이다.
- **Campaign Authored Content**는 DM이 JSON이나 인게임 Authoring으로 만든 제한된 데이터이며, Schema·Semantic·Budget 검증 후 기존 Definition·Recipe·Scene Source로 컴파일된다.
- **Runtime Instance**는 활성 Content Definition이나 Compiled Build를 참조하는 Actor, Item, Effect, RuleExecution, Scene Object와 Playback의 권위 또는 비권위 실행 상태다.

사용자와 개발자에게 보장하는 결과:

- 기본 Ruleset은 `dnd5e-2024`로 식별되고, 추가 공식 출처와 개발자 관리 홈브루는 Source Pack 단위로 등록된다.
- Campaign은 표시 이름이나 최신값이 아니라 정확한 `rulesetId + enabled Source Pack Version Set`을 저장한다.
- Character, Actor, Item, Effect, Scene과 Journal은 번역 이름이나 파일 경로가 아니라 언어와 무관한 Stable Content ID를 참조한다.
- 이름·설명·로그·선택 문구는 Locale Resource가 제공하고, 규칙 수치·비용·사거리·실행 순서와 Targeting은 번역 파일에 넣지 않는다.
- Source Pack은 Class·Subclass·Species·Background·Feat·Spell·Item·Monster·Condition·Effect·선택 규칙·Presentation Asset와 Locale을 포함할 수 있다.
- Source Pack이 기존 규칙이나 Policy를 수정하려면 대상 ID, Family, Base Version Range와 Patch 관계를 명시한다.
- 동일 이름, 폴더 순서, Roblox Instance 이름, Module Load 시각과 Lua Table 순서로 기존 콘텐츠를 덮어쓰지 않는다.
- 해결되지 않은 ID 충돌, Dependency Cycle, Base Version 불일치와 Schema 불일치는 Pack 또는 Candidate 활성화를 차단한다.
- Pack을 추가·제거·업데이트할 때 Character Choice, Item, Actor, Scene, Journal, Pending Execution과 저장 Snapshot의 참조를 영향 분석한다.
- 사용 중인 Pack을 제거할 때 참조를 조용히 삭제하거나 이름이 비슷한 다른 콘텐츠로 자동 교체하지 않고 제거를 막거나 명시적 Migration을 요구한다.
- 이미 생성된 Character Build, Actor Definition, RuleExecution, Encounter, Downtime, Policy Snapshot, Scene Build와 Presentation Playback은 시작 당시 Version Reference를 유지한다.
- 새 Version을 등록해도 진행 중 실행과 Playback을 제자리에서 변경하지 않는다.
- 변경은 각 권위 Domain의 Candidate Compile·Validation·Migration·Safe Activation 절차를 사용한다.
- Candidate 실패 시 Last Known Good Catalog·Snapshot·Build·Recipe를 유지하고 실패한 일부만 활성 상태에 섞지 않는다.
- RulesContentCatalog는 획득 출처, Feature·Spell·Item Definition과 실행 Capability를 분리한다.
- Character Source에는 고정 Feature Definition 사본이나 최종 행동 버튼을 저장하지 않고 선택·예외 Grant와 고정 Content Version Reference를 저장한다.
- Grant Graph와 Capability Compiler는 활성 Ruleset·Source Pack Version Set에서 Character 기능을 다시 구성한다.
- 콘텐츠 전용 Handler가 필요하더라도 Character Store, Combat Timeline, Workspace, Remote와 DataStore를 직접 수정하지 않는다.
- 행동·주문·특성·아이템·몬스터 능력은 공통 RuleExecution과 Recipe Runtime을 사용한다.
- 반복 가능한 규칙 동작은 버전된 Step·SubRecipe Registry로 제공하고, 한 콘텐츠에만 필요한 특수 동작은 상한이 있는 AdvancedOperation으로 등록한다.
- AdvancedOperation은 Stable ID, Version, Input·Output Schema, 실행 시간·생성 효과 수 상한, Permission, Persistence와 Rollback Policy를 가진다.
- Rule Handler·Step·AdvancedOperation은 PendingEffect·CommitGroup·Transaction과 서버 권위 검증을 우회하지 않는다.
- 콘텐츠 JSON 안의 임의 코드, 무한 반복, 동적 Module 경로, Client가 확정한 피해·명중·권한과 내부 Service 참조를 실행하지 않는다.
- DM이 붙여 넣은 NPC JSON은 구문·크기·깊이·Schema·Reference·수치·Graph·Budget·Semantic 검증 후에만 Campaign Content Definition으로 승격한다.
- DM JSON은 `campaign_authored` 신뢰 범위에서 등록된 공격·굴림·피해·효과·Capability·Prefab 참조만 사용할 수 있다.
- `developer_signed` 콘텐츠만 신뢰된 Advanced Handler나 Engine Extension을 참조할 수 있다.
- Session Temporary Content도 저장 여부만 다를 뿐 동일한 검증과 Budget 제한을 통과한다.
- 실패한 Import는 활성 Catalog, Character와 Scene State를 변경하지 않는다.
- Scene Editor 확장은 Registry 기반 Tool Module로 추가되며 Selection·Placement·Snap·ViewY·Input·Inspector·History를 다시 구현하지 않는다.
- Tool Module은 제한된 Context를 주입받고 Tool Command를 생성하며 RemoteEvent, UserInputService와 Workspace 권위 변경을 직접 소유하지 않는다.
- Parametric Tool 결과는 Tool ID·Object Type·Schema Version과 원본 Parameter를 가진 Scene Source Object로 저장한다.
- 누락 Tool Module이나 지원하지 않는 Object Version은 원본 데이터를 삭제하지 않고 읽기 전용 Fallback, Diagnostic과 Publish Gate를 사용한다.
- Scene Compiler 확장은 등록된 Provider가 Normalized Semantic Contribution을 받아 자신의 Layer Artifact와 Source Lineage를 생성하는 방식으로 추가된다.
- Compiler Provider는 Scene Source, Authoritative Dynamic State, UI, Remote와 Workspace를 직접 수정하지 않는다.
- Provider Dependency는 Registry에 명시하고 Cycle, Version 불일치, 비결정 결과와 필수 Provider 실패를 Build Gate로 처리한다.
- Scene Build의 부분 Compile은 내부 최적화이며 확장 Provider가 추가돼도 게시 결과는 완전하고 결정적인 Build Manifest를 유지한다.
- Prefab은 Stable `PrefabId`와 Metadata를 가진 신뢰 Catalog에서 제공되며 Client Ghost가 아니라 서버가 같은 Catalog Definition으로 실제 Scene Source를 생성한다.
- Scene 저장 데이터는 Model 전체가 아니라 Prefab ID, Transform과 허용된 Override를 저장한다.
- Presentation 확장은 데이터 기반 Recipe, Module, Step Handler와 Augment Registry로 추가된다.
- Presentation Module은 Authority State, Selection, Navigation, Visibility, Encounter와 Roll 결과를 변경하지 않는다.
- Presentation Module은 Camera를 직접 조작하지 않고 CameraRequest를 제출한다.
- Audience별 Projection에 공개되지 않은 Actor·Object·Content Identity와 World Anchor를 Presentation Parameter로 전달하지 않는다.
- Campaign Theme, Feature, Item과 Effect는 Recipe 전체를 복제하지 않고 등록된 Slot에 PresentationAugment를 기여할 수 있다.
- 진행 중 Playback은 Recipe Version과 Content Hash를 고정하고 새 Recipe Hot Swap은 새 Playback부터 적용한다.
- Presentation Module 실패는 해당 Module을 Fallback 또는 생략하고 Gameplay Transaction과 다른 Playback을 가능한 범위에서 계속한다.
- DM Presentation 설정과 Source Pack은 Player의 Accessibility Hard Limit과 Product Performance Guardrail을 우회하지 않는다.
- Policy Extension은 Family, Implementation, Merger와 Migration을 신뢰 Registry에 등록한다.
- Policy Evaluator와 Merger는 타입 있는 값·Plan·Constraint만 반환하며 Authority Store, Workspace, Remote, DataStore, 현실 Clock과 난수를 직접 사용하지 않는다.
- Source Pack Policy Patch는 대상 Ruleset·Policy Family·Base Implementation Range와 Patch Mode를 명시한다.
- Gameplay, Disclosure, Operational과 Presentation Policy Plane은 별도로 합성되며 Source Pack과 DM Override가 Security·Operational Hard Invariant를 제거하지 못한다.
- 진행 중 Encounter, Downtime과 RuleExecution은 생성 당시 Frozen Policy Snapshot이나 Effective Policy View를 유지한다.
- Domain Event 확장은 Commit된 Event를 구독할 수 있지만 Subscriber가 Store를 직접 수정하지 않고 필요하면 새 Command나 RuleExecution을 제출한다.
- 새 확장이 독립 Authority Store, 독립 Transaction, 독립 Permission 체계나 새로운 Core Engine을 요구하면 기존 Plugin 등록만으로 처리하지 않고 별도 Architecture·ADR을 먼저 작성한다.
- Diagnostics 확장은 등록된 Span·Observation·Error Code·Budget·Redaction·Health Probe를 사용하고 자체 무제한 문자열 Log와 Raw Payload 수집을 만들지 않는다.
- Simulation 확장은 Versioned Fixture·Assertion·Fault Point·Normalization·Shrinker Registry를 사용하고 생산 Handler를 우회하는 Test-only Mutation을 만들지 않는다.
- 모든 신뢰 Module은 ID·Version·Schema·Dependency·Capability·Trust·Determinism·Budget·Migration·Deprecation Metadata를 가진다.
- Extension의 오류는 Module·Provider·Candidate·Playback·Import 범위로 격리하고 기존 활성 Runtime과 다른 확장을 가능한 범위에서 유지한다.
- Player Client는 허용된 Content Projection과 사용 가능한 Capability만 받으며 전체 Content Catalog, 비밀 Pack, Source Lineage와 개발자 Handler 목록을 받지 않는다.
- DM은 Campaign에서 허용된 Pack, Migration Impact, Import Diagnostic과 Presentation·Scene Authoring 도구를 볼 수 있지만 Product Credential과 다른 Campaign 자료를 받지 않는다.
- Content Developer는 신뢰된 저장소와 Build Pipeline을 통해 Pack·Module을 추가하며 일반 플레이어가 런타임에 코드를 설치하는 Marketplace·Plugin Sandbox는 현재 제공하지 않는다.

적용 범위:

- Ruleset와 Source Pack Manifest·Version·Dependency·Content Index·Locale
- Stable Content ID, Source Pack Patch와 Campaign Enabled Version Set
- RulesContentCatalog, Grant Graph, Capability와 Content Handler
- RuleRecipe, Step·SubRecipe Registry와 AdvancedOperation
- Policy Family·Implementation·Merger·Migration Registry와 Frozen Snapshot
- Campaign Authored NPC JSON의 Schema·Semantic Validation과 Content Promotion
- Prefab Catalog, Stable PrefabId와 Scene Source Reference
- Scene Editor Tool Module·Object Type·Command·Inspector·Snap Provider
- SceneCompilerProvider, Semantic Contribution, Layer Artifact와 Source Lineage
- Presentation Recipe·Module·Step Handler·Augment·Profile·Fallback
- Event Subscriber, Diagnostics Registry와 Simulation Registry의 확장 경계
- Trust Class, Capability, Budget, Determinism, Version, Hash와 Deprecation
- Pack·Module Discovery, Validation, Compile, Activation, Migration와 Removal
- Persistence, Recovery, Rollback, Disclosure와 Production-parity Validation

명시적 비범위:

- 일반 사용자가 Luau·ModuleScript·Remote·DataStore Handler를 런타임에 업로드하거나 설치하는 기능
- 공개 Plugin Marketplace와 임의 외부 URL에서 Code·Content를 자동 다운로드하는 기능
- 플레이어가 주문·Feature 전체를 조립하는 범용 규칙 제작기
- Source Pack이 Product Hard Invariant, Authorization, Disclosure, Transaction과 Budget을 우회하는 기능
- Pack Load Order나 파일명만으로 Core Definition을 암묵적으로 덮어쓰는 기능
- Translation Resource가 규칙 수치와 실행 로직을 변경하는 기능
- Client가 Pack Version, Content Result, Recipe Branch와 Extension Permission을 권위적으로 확정하는 기능
- 진행 중 Execution·Playback·Build를 최신 Module로 제자리 Hot Patch하는 기능
- Extension이 독립된 저장·이벤트·전투·권한 Runtime을 임의로 만드는 기능
- 현재 제품 범위에서 제외된 음악·환경음·SFX·음성·NPC 대화 기능을 Extension이라는 이유만으로 자동 활성화하는 기능
- 배포 권리가 확인되지 않은 공식 텍스트·이미지·음원과 기타 자료를 Pack에 포함하는 기능

## 2. 전체 구조

### Source Pack과 Content Catalog

```text
Developer-managed Source Pack
├─ Manifest·Stable Pack ID·Version·Ruleset
├─ Dependency·Patch·Content Index
├─ Rule Content Definition·Policy Patch
├─ Locale·Icon·Prefab·Presentation Source
└─ Migration·Compatibility Metadata

→ Pack·Schema·Dependency·Rights Validation
→ RulesContentCatalog·Policy Candidate·Compiled Recipe
→ Campaign Enabled Version Set
→ Character·Actor·Item·Scene·UI Projection
```

### 신뢰 Module Extension

```text
Repository·Build에 포함된 Module
→ Registry Discovery
→ ID·Version·Schema·Capability·Trust 검증
→ Dependency Graph·Determinism·Budget 검사
→ Domain Compiler 또는 Runtime Adapter 등록
→ Candidate Build·Snapshot·Recipe 검증
→ 안전 경계에서 활성화
```

### Campaign Authored Data

```text
DM JSON 또는 Authoring Input
→ Size·Depth·Schema·Reference Validation
→ Semantic·Graph·Budget Validation
→ Normalization·Preview
→ DM 확인
→ Campaign Content 또는 Scene Source Revision
→ 기존 Compiler·Command·Runtime 사용
```

### Runtime 실행

```text
Pinned Content·Policy·Recipe·Build Reference
→ Capability 또는 Domain Intent
→ Server Validation
→ RuleExecution·Authoring Command·PresentationIntent
→ Transaction 또는 비권위 Playback
→ Permission-aware Projection·Diagnostics
```

## 3. 주요 데이터 흐름

### 3.1 Source, Compiled Definition, State와 Projection

```text
Source Pack·Campaign Authored Source
→ Schema·Migration·Normalizer
→ Immutable Content·Policy·Recipe·Scene Definition
→ Authoritative Instance·Execution State
→ Permission-aware Projection
→ UI·Presentation
```

다음은 서로 같지 않다.

```text
Pack Source
≠ Compiled Content Definition
≠ Character·Actor·Item·Effect Instance State
≠ Player Projection
≠ Presentation Playback
```

Pack Source와 Compiled Definition은 규칙과 의미를 제공한다. 현재 HP, Resource, Item Location, Effect Duration, Encounter Opportunity와 Runtime Object Presence는 기존 Domain State가 소유한다.

### 3.2 공통 Identity와 Version 축

각 확장 유형의 정확한 Schema는 소유 권위 문서가 정의한다. 공통적으로 다음을 구분한다.

```text
Stable Type·Content·Pack ID
Schema Version
Content·Implementation·Handler Version
Ruleset·Compatibility Range
Dependency Version Range
Source·Compiled Content Hash
Migration·Deprecation State
Trust·Determinism·Budget Class
```

표시 이름, Locale, 파일명과 Module 경로를 영구 Identity로 사용하지 않는다.

### 3.3 Pack Version Set과 장기 참조

```text
Campaign
→ rulesetId
→ enabledSourcePacks[{packId, version}]
→ active Policy Snapshot Ref
→ Character·Scene·Presentation Build Ref
```

영구 선택과 실행은 필요한 Content ID·Source Pack·Version 또는 Compiled Build Reference를 보존한다. 오래된 Version은 참조하는 Character, Actor, Item, Effect, Pending Execution, Snapshot과 Replay가 남아 있는 동안 임의 삭제하지 않는다.

### 3.4 Rules Content와 Capability

```text
Progression Source·Choice·Exceptional Grant
+ Frozen Ruleset·Source Pack Version Set
+ RulesContentCatalog
→ ResolvedGrant
→ Compiled Capability Set
→ Action·Sheet·Spell·Item·Trigger UI
```

ResolvedGrant와 Capability Set은 재생성 가능한 파생 결과다. 저장 원본은 Progression Source, Choice, Exceptional Grant와 Version Reference다.

### 3.5 Rule Recipe 확장

```text
ContentDefinition
→ RecipeDefinition
→ Registered Step·SubRecipe·AdvancedOperation
→ Compiled Execution Plan
→ RuleExecution
→ PendingEffect·CommitGroup
→ Authority Transaction
```

Step Registry는 타입·Automation·Authority·Side Effect·Rollback·Failure·Determinism 계약을 검증한다. AdvancedOperation도 같은 Commit과 Recovery 경계 안에 남는다.

### 3.6 Policy Patch와 Frozen Snapshot

```text
Product Default
+ Ruleset Policy Pack
+ 명시적 Source Pack Patch
+ Campaign·Scope Binding
+ Runtime Contribution·DM Override
→ Family별 결정적 Composition
→ Invariant·Conflict Validation
→ Immutable Frozen Policy Snapshot
```

Snapshot 누락이나 Hash 불일치 시 최신 Policy를 자동 사용하지 않는다.

### 3.7 Scene Tool·Provider·Prefab

```text
Trusted Tool·Prefab·Semantic Profile
→ Editor Local Preview
→ Server Tool Command
→ Scene Source Object·Revision
→ Registered Compiler Provider
→ Immutable Scene Candidate Build
```

Tool Preview와 Prefab Ghost는 Source Commit이 아니다. Compiler Provider Artifact는 파생 Build이며 Scene Source와 Dynamic State를 대체하지 않는다.

### 3.8 Presentation Extension

```text
Presentation Recipe Source
+ Module·Augment Registry
→ Immutable Compiled Recipe Version
→ PresentationIntent
→ Audience·Quality·Accessibility·Budget Resolution
→ Playback Plan
```

Playback과 Module Instance는 저장 원본이나 Gameplay 권위 상태가 아니다.

### 3.9 Trust Class

권위 문서에 정의된 대표 신뢰 범위:

```text
developer_signed
→ 신뢰 Registry Handler·Provider를 사용할 수 있는 개발자 관리 콘텐츠

campaign_authored
→ 검증된 데이터 노드와 기존 Definition Reference만 사용하는 Campaign 콘텐츠

session_temporary
→ 현재 Session에 한정되지만 동일 검증을 통과한 데이터

rejected
→ Schema·Trust·Budget·Reference 검증을 통과하지 못한 입력
```

Trust가 높아도 Product Hard Invariant, Transaction, Disclosure와 Budget을 우회하지 않는다.

## 4. 주요 실행 흐름

### 4.1 Source Pack 등록

```text
Pack Manifest 제출
→ Pack ID·Version·Ruleset·Source·Locale 확인
→ Content ID·Schema·Reference 검사
→ Dependency·Patch Graph 해결
→ Policy·Recipe·Asset·Presentation Source 검사
→ Localization Key와 Distribution 범위 검사
→ Candidate Catalog·Snapshot·Recipe Compile
→ Determinism·Budget·Disclosure Test
→ 등록 가능 또는 구조화된 Diagnostic
```

등록과 Campaign 활성화는 같은 단계가 아니다. 저장소에 존재하는 Pack이 모든 Campaign에 자동 활성화되지 않는다.

### 4.2 Campaign에서 Pack 활성화

```text
DM Pack 변경 Proposal
→ 현재 Enabled Version Set·Reference 확인
→ Dependency·Compatibility·Conflict 검사
→ 영향받는 Policy·Character·Scene·Presentation Candidate 생성
→ Migration Impact와 사용 중 Reference 표시
→ 권위 문서가 정의한 안전 경계에서 승인
→ 새 Version Reference 활성화
→ Projection·Catalog·Cache 재구성
```

각 Domain의 실제 Atomic Activation은 해당 Policy, Character, Scene, Persistence와 Presentation 계약이 소유한다. Guide가 하나의 새로운 전역 Pack Transaction을 정의하지 않는다.

### 4.3 Pack 제거와 Version 교체

```text
제거·교체 Proposal
→ Character·Choice·Item·Actor·Effect·Scene·Journal·Execution 참조 탐색
→ 호환 Migration 또는 Read-only 보존 가능성 검사
→ 제거 차단 | Migration 승인 | 기존 Version 병행 보존
→ Candidate 검증
→ 안전 활성화
```

참조가 남은 Definition을 자동 삭제하거나 비슷한 이름의 Content로 재지정하지 않는다.

### 4.4 Rules Content 사용

```text
활성 Catalog Definition
→ Grant·Equipment·Effect로 Capability 생성
→ 사용자 Intent
→ 서버가 Content·Capability·Version 재검증
→ RuleExecution과 Frozen Policy View
→ Recipe Step·AdvancedOperation
→ PendingEffect·Transaction
→ Projection·Presentation
```

Client는 최종 피해, 성공 여부, Handler ID와 Branch 결과를 보내지 않는다.

### 4.5 DM NPC JSON Import

```text
JSON 입력
→ 문서 크기·깊이·문자열·배열 제한
→ Schema Version·Migration
→ Stable ID·Reference·수치·Graph 검사
→ 허용된 Recipe·Capability·Prefab Node로 정규화
→ Compile Diagnostic·Preview
→ DM 확인
→ CampaignContentDefinition Revision 저장
→ Test Actor 또는 Scene 배치
```

원문, Normalized Definition과 Compiled Result를 구분한다. Definition 수정은 새 Revision을 만들고 기존 Actor 적용 여부는 별도 선택이다.

### 4.6 새 Recipe Step 또는 AdvancedOperation 추가

```text
재사용 필요·전용 처리 이유 검토
→ Stable Step·Operation ID와 Version
→ Input·Output·Authority·Side Effect Schema
→ Loop·Time·Target·Generated Effect Budget
→ Failure·Rollback·Persistence·Permission 계약
→ Registry Contract Test
→ Production Recipe Compile
→ Deterministic Scenario·Disclosure Test
→ Content Pack에서 참조 가능
```

한 콘텐츠의 편의를 위해 CommitGroup, Server Validation과 Recovery를 우회하는 Operation은 등록하지 않는다.

### 4.7 새 Scene Tool·Compiler Provider 추가

```text
Module Definition·Capability·Dependency 선언
→ Registry Validation
→ 제한된 Tool Context 주입
→ Local Preview·Tool Command 생성
→ Source Object Schema·Migration 등록
→ Compiler Contribution·Layer Provider 등록
→ Error Isolation·Determinism·Partial Compile Test
→ Tool Palette·Inspector·Panel Host에 노출
```

중앙 Tool 분기, 독립 Remote와 전역 Workspace 순회를 추가하지 않는다.

### 4.8 새 Presentation Module 추가

```text
Module Type·Handler Version·Parameter Validator
→ Capability·Quality·Fallback·Migration 등록
→ Recipe Compiler 검증
→ Audience·Visibility·Accessibility·Budget Test
→ Candidate Recipe Preview
→ 새 Recipe Version 활성화
→ 새 Playback부터 사용
```

Module 오류는 Gameplay Commit을 변경하지 않는다.

### 4.9 Extension Event Subscriber

```text
Committed Domain Event
→ 등록된 Subscriber
→ Idempotency·Epoch·Budget 검증
→ Read Query
→ 필요 시 새 Command·RuleExecution 제출
→ 별도 Transaction
```

Subscriber가 Event 처리 중 Domain Store를 직접 수정하지 않는다.

### 4.10 Missing·Incompatible Extension 복구

```text
Load·Recovery 중 Version·Hash·Handler 누락
→ 최신 Version 자동 대체 금지
→ unresolved | read_only | recovery_required | activation_blocked
→ 원본 Source·Choice·Reference 보존
→ Last Known Good 또는 호환 Migration 탐색
→ DM·Operator 검토
→ 검증된 Recompile·Migration 후 재활성화
```

Player에게는 내부 Handler 이름이 아니라 안전한 사용 불가 이유와 DM 문의 경로를 표시한다.

### 4.11 Rollback과 Epoch 변경

Rollback은 선택된 Branch의 Ruleset·Source Pack·Policy·Build Reference를 함께 복원한다. 이전 Epoch의 Candidate Compile, Migration, Module Callback, Subscriber, Playback ACK와 Client Request를 새 Branch에 적용하지 않는다.

## 5. 문서 관계도

### Parent Authority

- [`Runtime Architecture Principles`](../../architecture/runtime-architecture-principles.md) — 신뢰 Registry, Server Authority, 결정적 실행과 Client 입력 검증
- [`Compiled Build와 Authoritative State 분리 패턴`](../../architecture/compiled-build-and-authoritative-state-pattern.md) — Source·Candidate·불변 Build·Versioned State·Migration·Last Known Good
- [`Ruleset Policy Registry, Composition과 Frozen Snapshot`](../../architecture/ruleset-policy-registry-composition-and-frozen-snapshot-runtime-contract.md) — Pack Policy Patch, Trust·Operational Guardrail, Version·Conflict·Migration
- [`Command Ordering, Logical Time와 Transaction Coordinator`](../../architecture/command-ordering-logical-time-and-transaction-coordinator-contract.md) — Extension이 권위 변경에 사용하는 Ordering·Reservation·Atomic Commit
- [`Persistence와 Session Recovery`](../../architecture/persistence-and-session-recovery-model.md) — Version Reference, Manifest·Chunk, Migration, Recovery와 Rollback

### Child Authority

- [`Rules Content Grant Graph와 Capability`](../../architecture/rules-content-grant-capability-model.md) — Content Catalog·Grant·Capability와 전용 Handler 경계
- [`규칙 콘텐츠 공통 실행 계약`](../../architecture/rules-content-execution-and-spell-contract.md) — RuleContentDefinition·Recipe·Handler와 실행 생명주기
- [`표준 Recipe Step Library`](../../systems/rules/standard-recipe-step-library.md) — Step·SubRecipe·AdvancedOperation 등록 계약
- [`Scene Compiler와 Compiled Runtime Scene`](../../architecture/scene-compiler-and-compiled-runtime-scene-contract.md) — Compiler Provider, Contribution·Layer·Artifact·Dependency
- [`Scene Editor Tool Module`](../../architecture/scene-editor-tool-module-architecture.md) — Tool Registry·Capability·Context·Command·Object Type·Migration
- [`Presentation Recipe, Playback Priority와 Extension Runtime`](../../architecture/presentation-recipe-playback-priority-and-extension-runtime-contract.md) — Module·Augment·Recipe Version·Fallback·Budget
- [`몬스터·NPC Statblock과 JSON Import`](../../systems/character/monster-npc-statblock-and-ingame-json-import-model.md) — Campaign Authored Content의 제한 Schema와 승격 흐름

### References

- [`Rules Guide`](../rules/README.md) — Capability·RuleExecution·Recipe·Effect 실행
- [`Character Guide`](../character/README.md) — Character Source·Build·Item·Downtime와 Pack Migration 영향
- [`Scene Editor Guide`](../scene-editor/README.md) — Tool·Source·Compiler·Publish·Live Patch
- [`UI Guide`](../ui/README.md) — Presentation Module, Input·Panel·Projection·Accessibility
- [`Diagnostics Guide`](../diagnostics/README.md) — Registry·Compile·Migration·Module 오류와 Incident·Simulation
- [`Domain Event Runtime`](../../architecture/domain-event-outbox-subscription-and-projection-runtime-contract.md) — Subscriber 확장과 Event→Command 경계
- [`Diagnostics Runtime`](../../architecture/diagnostics-observability-correlated-trace-and-incident-runtime-contract.md) — Extension Span·Budget·Health·Redaction
- [`Deterministic Simulation과 Test Harness`](../../architecture/deterministic-simulation-scenario-and-test-harness-runtime-contract.md) — Registry·Fixture·Fault·Assertion 확장 검증

권위 읽기 순서에서 제외:

- `archive/`와 `archive/discontinued/` 아래 이전 설계
- `SUPERSEDED`, `DISCONTINUED`, `ARCHIVED` 상태 문서
- 이름·Load Order·Workspace Attribute와 Client Script를 권위 확장 원본으로 사용하는 구형 관례
- 외부 Plugin API가 이미 제공된다고 가정하는 설계

## 6. 다른 시스템과의 경계

| 인접 시스템 | Extension 영역이 제공하는 것 | 상대 시스템이 제공하는 것 | 권위 경계 문서 |
|---|---|---|---|
| Runtime Foundation | Stable ID·Version·Registry Entry와 Candidate | Authority·Command·Transaction·Projection 공통 원칙 | Runtime Principles, Compiled Build 패턴 |
| Ruleset·Policy | Ruleset Pack·Source Pack Patch·Implementation | Family Composition, Frozen Snapshot, Guardrail·Migration | Policy Runtime |
| Character | Class·Feature·Spell·Item Definition과 Grant | Progression Source, Build Activation과 Persistent State | Grant Capability, Character Runtime |
| Rules | Recipe·Step·AdvancedOperation Definition | RuleExecution, Reservation, PendingEffect와 Commit | Rules Content, Orchestrator, Step Library |
| Inventory | Item Definition과 Item Capability | ItemInstance Identity·Location·Ownership·Transfer | Inventory Runtime |
| Scene | Prefab·Semantic Profile·Compiler Provider | Scene Source, Build, Runtime Object와 Dynamic State | Scene Compiler, Runtime Object |
| Scene Editor | Tool·Object Type·Inspector·Snap Extension | Input·Selection·Placement·Command·History Host | Tool Module Architecture |
| Presentation | Recipe·Module·Augment·Quality Variant | Intent, Audience, Queue, CameraRequest와 Playback | Presentation Runtime |
| Event | Subscriber Definition | Outbox Delivery, Idempotency, Dead Letter와 Projection | Domain Event Runtime |
| Persistence | Schema·Migration Adapter와 Version Reference | Snapshot·Journal·Manifest·Recovery·Rollback | Persistence Runtime |
| UI | Localization·Icon·Panel Schema와 Content Projection | ViewModel·Input Context·Permission-aware Rendering | UI Runtime |
| Diagnostics | Span·Error·Budget·Health Metadata | Trace, Incident, Redaction과 Support Query | Diagnostics Runtime |
| Simulation | Fixture·Assertion·Fault Point Adapter | Production Runtime Boot, Deterministic Schedule와 Artifact | Simulation Runtime |
| Security·Disclosure | Pack Metadata와 Field Classification | Authorization, Knowledge, Projection와 Redaction | Policy, Visibility, Networking |

고정 경계:

- Registry는 Extension Identity와 Handler를 찾지만 Domain Store의 새 권위 원본이 아니다.
- Pack Definition은 Character·Item·Effect·Actor Instance State를 저장하지 않는다.
- Extension Module은 Local UI, Workspace와 Client Prediction을 Authority Result로 사용하지 않는다.
- Source Pack Patch는 명시적 대상과 Compatibility 없이는 Core Definition을 대체하지 않는다.
- Presentation과 Diagnostics 확장은 Gameplay Outcome을 변경하지 않는다.
- Event·Compiler·Tool·Policy Provider는 다른 Domain Store를 직접 수정하지 않는다.
- Extension 활성 실패가 기존 Last Known Good Runtime을 손상시키지 않는다.

## 7. 추천 읽기 순서

1. [`Runtime Architecture Principles`](../../architecture/runtime-architecture-principles.md)
   - 신뢰 Registry, Server Authority, Client 검증과 오류 격리 원칙을 먼저 확인한다.
2. [`Compiled Build와 Authoritative State 패턴`](../../architecture/compiled-build-and-authoritative-state-pattern.md)
   - Source·Build·State·Migration·Last Known Good를 구분한다.
3. [`ADR-0001`](../../decisions/ADR-0001-authored-rules-content.md), [`ADR-0003`](../../decisions/ADR-0003-ruleset-source-packs-localization.md)
   - 플레이어용 범용 제작기를 제외하고 Source Pack·Stable ID·Locale을 채택한 제품 결정을 읽는다.
4. [`Policy Runtime`](../../architecture/ruleset-policy-registry-composition-and-frozen-snapshot-runtime-contract.md), [`ADR-0081`](../../decisions/ADR-0081-versioned-policy-composition-and-frozen-ruleset-snapshots.md)
   - Pack Patch·Trust·Conflict·Frozen Version·Migration과 Hard Invariant를 읽는다.
5. [`Grant·Capability`](../../architecture/rules-content-grant-capability-model.md), [`Rules Content Execution`](../../architecture/rules-content-execution-and-spell-contract.md)
   - Content Catalog가 Character Capability와 RuleExecution으로 연결되는 방식을 읽는다.
6. [`ADR-0024`](../../decisions/ADR-0024-hybrid-rule-recipes-and-reusable-advanced-operations.md), [`ADR-0053`](../../decisions/ADR-0053-step-level-automation-and-standard-recipe-step-library.md), [`Step Library`](../../systems/rules/standard-recipe-step-library.md)
   - 공통 Recipe·Step와 제한된 AdvancedOperation을 읽는다.
7. [`ADR-0032`](../../decisions/ADR-0032-monster-npc-statblocks-and-safe-ingame-json-import.md), [`NPC Import 모델`](../../systems/character/monster-npc-statblock-and-ingame-json-import-model.md)
   - 신뢰되지 않은 DM Data를 안전한 Campaign Content로 승격하는 경계를 읽는다.
8. [`ADR-0010`](../../decisions/ADR-0010-replicatedstorage-prefab-catalog.md), [`Scene Compiler`](../../architecture/scene-compiler-and-compiled-runtime-scene-contract.md), [`Tool Module`](../../architecture/scene-editor-tool-module-architecture.md)
   - Prefab·Editor Tool·Compiler Provider 확장을 읽는다.
9. [`ADR-0046`](../../decisions/ADR-0046-modular-presentation-recipes-and-extension-contracts.md), [`ADR-0075`](../../decisions/ADR-0075-versioned-data-driven-and-fault-isolated-presentation-runtime.md), [`Presentation Runtime`](../../architecture/presentation-recipe-playback-priority-and-extension-runtime-contract.md)
   - Presentation Recipe·Module·Augment·Hot Swap과 실패 격리를 읽는다.
10. [`Persistence`](../../architecture/persistence-and-session-recovery-model.md), [`Diagnostics`](../../architecture/diagnostics-observability-correlated-trace-and-incident-runtime-contract.md), [`Simulation`](../../architecture/deterministic-simulation-scenario-and-test-harness-runtime-contract.md)
    - Version 보존·Migration·Recovery·Incident·Regression을 읽는다.
11. [`Completion Audit`](../../audits/runtime-architecture-completion-and-main-guide-readiness-audit.md)
    - 확장성을 새 Core Engine이 아닌 기존 Registry·Module 조합으로 판정한 근거를 확인한다.

## 8. 구현·검증 순서

권위 문서에 이미 제시된 의존 관계를 통합하면 다음 순서로 내려간다.

```text
Stable ID·Schema·Version·Trust·Localization Foundation
→ Registry·Dependency·Capability·Budget Foundation
→ Ruleset·Source Pack Manifest와 Catalog Loader
→ Policy Pack·Patch·Frozen Snapshot Compiler
→ Grant Graph·Capability와 Content Definition Compiler
→ Recipe Step·SubRecipe·AdvancedOperation Runtime
→ Campaign Authored Content Validator·Normalizer
→ Prefab Catalog·Scene Tool·Compiler Provider Host
→ Presentation Recipe·Module·Augment Host
→ Candidate Activation·Migration·Deprecation·Last Known Good
→ Persistence·Recovery·Rollback과 Permission Projection
→ Diagnostics·Deterministic Scenario·Disclosure·Load Validation
```

기존 구현 Spec 진입점:

- [`Recipe Step Runtime Foundation`](../../specs/shared/001-recipe-step-runtime-foundation.md)
- [`Standard Step Handler Contracts`](../../specs/shared/002-standard-step-handler-contracts.md)

후속 Spec에서 분리할 수직 단위:

```text
Content Pack Manifest·Catalog·Dependency Compiler
Policy Registry·Source Pack Patch·Snapshot Activation
Content ID·Localization·Pack Projection
Grant·Capability Compiler와 Missing Content Recovery
AdvancedOperation Registry·Trust·Budget
Campaign Authored Content Import·Publication
Prefab Catalog·Tool Module·Compiler Provider Registry
Presentation Module·Recipe Version·Fallback
Pack Migration·Removal·Rollback·Recovery
Extension Contract Test·Scenario·Disclosure Scanner
```

필수 검증 Scenario:

- 같은 Pack ID·Version·Content Hash의 결정적 Catalog 결과
- Pack Load Order와 Lua Table 순서가 결과에 영향을 주지 않음
- 중복 Content ID·Dependency Cycle·Patch Base Mismatch 활성 차단
- Localization 변경이 Authority Digest를 변경하지 않음
- Locale 누락 Fallback과 Missing Key Diagnostic
- Pack 제거 시 사용 중 Character·Item·Actor·Scene·Execution Reference 차단
- Pack Version Migration 성공·실패와 Last Known Good 유지
- Missing Pack·Handler·Recipe Version에서 최신값 자동 대체 금지
- 진행 중 Encounter·Downtime·RuleExecution의 Policy·Content Version 고정
- Source Pack Policy Patch Conflict와 Disclosure·Operational Guardrail 차단
- Grant Graph Cycle·Unresolved Content·Handler 누락의 Read-only Recovery
- Step·SubRecipe Version Compatibility와 Binding Type 검사
- AdvancedOperation Time·Target·Loop·Generated Effect Budget 초과 거부
- AdvancedOperation이 PendingEffect·CommitGroup을 우회하지 못함
- DM JSON의 Code·Module·Remote·URL·무한 Graph 입력 거부
- Campaign Authored NPC Compile 실패가 Catalog·Scene State를 변경하지 않음
- Prefab Client Ghost 변조와 미등록 Prefab ID 서버 거부
- Tool Module Deactivate·오류 후 Input·Ghost·Connection 정리
- Tool Object Migration 누락 시 Source 보존과 Publish 차단
- Compiler Provider Dependency·Version·Determinism·Failure Isolation
- Partial Compile과 Full Compile의 Semantic·Hash 동일성
- Presentation Module 오류·Timeout 후 Gameplay Outcome 동일
- 진행 중 Playback Version 고정과 새 Recipe Hot Swap
- Secret Actor·Content·Pack·Source Lineage의 Player Projection·Diagnostic·Presentation 누출 차단
- Extension Subscriber Retry의 멱등성과 이전 Epoch 차단
- Restart·Rollback 후 정확한 Pack·Policy·Recipe·Build Reference 복구
- Module·Pack Budget과 대규모 Catalog·Scene·Presentation Load Test
- 배포 권한 없는 Asset이 Release Pack에 포함되지 않는 검토 Gate

## 9. 변경 영향 지도

| 변경 유형 | 영향받는 권위 문서 | 영향받는 Specs | Guide 조치 |
|---|---|---|---|
| Pack Manifest·Content ID·Locale | ADR-0003, Grant·Capability, Persistence | Content Pack·Catalog·Localization Specs | `UPDATE_REQUIRED` |
| Trust Class·Plugin 허용 범위 | Runtime Principles, Policy Runtime, ADR-0032 | Trust·Import·Security Specs | `UPDATE_REQUIRED` |
| Policy Family·Patch·Composition | Policy Runtime, ADR-0081 | Policy Registry·Snapshot Specs | `UPDATE_REQUIRED` |
| Recipe Step·AdvancedOperation | Rules Content, Step Library, ADR-0024·0053 | Shared Recipe Specs | `UPDATE_REQUIRED` |
| Character Grant·Capability | Grant Capability, Character Runtime | Character Compiler Specs | `UPDATE_REQUIRED` |
| Prefab·Scene Tool·Provider | ADR-0010, Tool Module, Scene Compiler | Scene Authoring·Compiler Specs | `UPDATE_REQUIRED` |
| Presentation Module·Recipe | Presentation Runtime, ADR-0046·0075 | Presentation Registry Specs | `UPDATE_REQUIRED` |
| Extension Event Subscriber | Domain Event Runtime, Integration 계약 | Event Subscriber Specs | `UPDATE_REQUIRED` |
| Pack Activation·Migration·Removal | Compiled Build, Policy, Persistence | Migration·Recovery Specs | `UPDATE_REQUIRED` |
| Disclosure·Diagnostic Metadata | Visibility, Networking, Diagnostics | Projection·Diagnostic Specs | `UPDATE_REQUIRED` |
| Registry Budget·Retention 수치 | 해당 Registry·Diagnostics·Simulation | Budget Profile Specs | 필요 시 갱신 |

## 10. Authority Documents

### Product

- [`콘텐츠 범위·자동화·롤백·저장·제외 기능`](../../product/content-automation-rollback-storage-and-exclusions.md)

### Architecture

- [`Runtime Architecture Principles`](../../architecture/runtime-architecture-principles.md)
- [`Compiled Build와 Authoritative State 분리 패턴`](../../architecture/compiled-build-and-authoritative-state-pattern.md)
- [`Ruleset Policy Registry, Composition과 Frozen Snapshot`](../../architecture/ruleset-policy-registry-composition-and-frozen-snapshot-runtime-contract.md)
- [`Rules Content Grant Graph와 Capability`](../../architecture/rules-content-grant-capability-model.md)
- [`규칙 콘텐츠 공통 실행 계약`](../../architecture/rules-content-execution-and-spell-contract.md)
- [`Effect Recipe Resolution과 Commit`](../../architecture/effect-recipe-resolution-and-commit-model.md)
- [`Rule Runtime Orchestrator`](../../architecture/rule-runtime-orchestrator-and-pending-execution-contract.md)
- [`Scene Compiler와 Compiled Runtime Scene`](../../architecture/scene-compiler-and-compiled-runtime-scene-contract.md)
- [`Scene Editor Tool Module`](../../architecture/scene-editor-tool-module-architecture.md)
- [`Presentation Recipe, Playback Priority와 Extension Runtime`](../../architecture/presentation-recipe-playback-priority-and-extension-runtime-contract.md)
- [`Domain Event Runtime`](../../architecture/domain-event-outbox-subscription-and-projection-runtime-contract.md)
- [`Persistence와 Session Recovery`](../../architecture/persistence-and-session-recovery-model.md)
- [`Diagnostics Runtime`](../../architecture/diagnostics-observability-correlated-trace-and-incident-runtime-contract.md)
- [`Deterministic Simulation과 Test Harness`](../../architecture/deterministic-simulation-scenario-and-test-harness-runtime-contract.md)

### Systems·UI

- [`Extension 시스템 인덱스`](../../systems/extension/README.md)
- [`Ruleset와 Policy`](../../systems/ruleset/README.md)
- [`Rules`](../../systems/rules/README.md)
- [`표준 Recipe Step Library`](../../systems/rules/standard-recipe-step-library.md)
- [`몬스터·NPC Statblock과 JSON Import`](../../systems/character/monster-npc-statblock-and-ingame-json-import-model.md)
- [`Scene`](../../systems/scene/README.md)
- [`Navigation Authoring Pipeline`](../../systems/navigation/navigation-authoring-pipeline.md)
- [`UI`](../../ui/README.md)
- [`Scene Editor UI`](../../ui/scene-editor/README.md)
- [`Diagnostics`](../../systems/diagnostics/README.md)
- [`Testing과 Simulation`](../../systems/testing/README.md)
- [`Cross-System Integration`](../../systems/integration/README.md)

### Specs

- [`Recipe Step Runtime Foundation`](../../specs/shared/001-recipe-step-runtime-foundation.md)
- [`Standard Step Handler Contracts`](../../specs/shared/002-standard-step-handler-contracts.md)
- 나머지 Content Pack·Registry·Migration·Presentation·Scene Provider Spec은 전체 Implementation Specs 단계에서 작성한다.

### Audits

- [`Runtime Architecture Completion과 Main System Guide 준비도 감사`](../../audits/runtime-architecture-completion-and-main-guide-readiness-audit.md)

## 11. ADR References

- [`ADR-0001`](../../decisions/ADR-0001-authored-rules-content.md) — 플레이어 범용 규칙 제작기 대신 개발자 관리 정식 콘텐츠
- [`ADR-0003`](../../decisions/ADR-0003-ruleset-source-packs-localization.md) — D&D 2024, Source Pack, Stable Content ID와 Localization
- [`ADR-0010`](../../decisions/ADR-0010-replicatedstorage-prefab-catalog.md) — 신뢰 Prefab Catalog와 서버 검증 배치
- [`ADR-0024`](../../decisions/ADR-0024-hybrid-rule-recipes-and-reusable-advanced-operations.md) — RuleRecipe와 재사용 가능한 고급 연산
- [`ADR-0032`](../../decisions/ADR-0032-monster-npc-statblocks-and-safe-ingame-json-import.md) — DM JSON 검증과 Campaign Content 승격
- [`ADR-0046`](../../decisions/ADR-0046-modular-presentation-recipes-and-extension-contracts.md) — Presentation Module·Recipe와 내부 확장 계약
- [`ADR-0053`](../../decisions/ADR-0053-step-level-automation-and-standard-recipe-step-library.md) — Step 단위 자동화와 제한된 AdvancedOperation
- [`ADR-0057`](../../decisions/ADR-0057-canonical-scene-source-and-atomic-compiled-build-activation.md) — Canonical Scene Source, Provider Build와 Atomic Publish
- [`ADR-0075`](../../decisions/ADR-0075-versioned-data-driven-and-fault-isolated-presentation-runtime.md) — Versioned Presentation, Hot Swap와 오류 격리
- [`ADR-0081`](../../decisions/ADR-0081-versioned-policy-composition-and-frozen-ruleset-snapshots.md) — Policy Registry·Patch·Frozen Snapshot·Migration

## 12. 알려진 비목표와 측정형 기본값

확정된 비목표:

- 일반 사용자용 코드 Plugin Sandbox와 공개 Marketplace
- 외부 URL Runtime Code Download와 Client-supplied Handler
- 플레이어용 범용 Spell·Feature 제작기
- Translation에 규칙 의미 저장
- 이름·파일 순서·Instance 순서 기반 Override
- 진행 중 Runtime의 제자리 Version 교체
- Source Pack·Tool·Provider·Presentation Module의 Authority Store 직접 수정
- Pack이 Security·Disclosure·Operational Hard Cap을 우회하는 기능
- 현재 제외된 Audio·NPC Dialogue 기능을 확장으로 우회 구현

남은 측정형 기본값:

- Pack·Catalog·Locale Bundle의 목표 크기와 Campaign Pack 수 상한
- Registry Entry·Dependency·Recipe·Tool·Provider·Module 수 상한
- Candidate Compile Queue·Time·Memory Budget
- AdvancedOperation 최대 실행 시간·대상·반복·생성 효과 기본값
- 이전 Pack·Handler·Recipe·Build Version 보존 개수와 기간
- Migration Batch 크기, Retry와 Maintenance Gate Timeout
- Presentation Module·Particle·Decal·Queue Budget
- Import JSON 크기·깊이·문자열·배열 기본 상한
- Extension Diagnostic Sampling·Retention과 Incident 임계값
- PR·Release Extension Matrix Test의 실행 시간과 병렬 수

Guide 이후 남은 비차단 작업:

- Content Pack·Registry·Migration Implementation Specs
- 공식 2024 Content Pack의 실제 수치·Locale·Asset 작성과 권리 검토
- 신뢰 Module Packaging·Signing·Build Pipeline의 구체 구현
- Pack 관리·Migration Review UI의 상세 Layout
- 플레이테스트 기반 Budget·Fallback·Deprecation 기본값 조정

## 13. Guide 검증 체크리스트

- [x] 모든 핵심 문장이 Authority Document에 근거한다.
- [x] 새로운 제품 규칙이나 Architecture 결정을 추가하지 않았다.
- [x] 모든 링크가 존재한다.
- [x] Parent·Children·References를 구분했다.
- [x] 최신 ADR과 기존 Recipe Specs를 반영했다.
- [x] `SUPERSEDED`, `DISCONTINUED`, `ARCHIVED` 문서를 권위 읽기 순서에서 제외했다.
- [x] Content Pack·Trusted Module·Campaign Authored Data를 구분했다.
- [x] 임의 사용자 Luau와 공개 Plugin API가 현재 범위가 아님을 명시했다.
- [x] Version 고정, Migration, Last Known Good와 Recovery를 연결했다.
- [x] Rules·Scene·Presentation·Diagnostics 확장점의 권위 Store 우회를 금지했다.
- [x] 변경 영향 지도가 최신이다.
- [x] Guide Status가 실제 상태와 일치한다.
