# Final UI·Content Implementation Contract

- 상태: `CURRENT · IMPLEMENTATION READY`
- 최종 갱신일: 2026-08-06
- 상위 결정: [`ADR-0091`](../../decisions/ADR-0091-asset-registry-interactive-sheet-dice-and-core-rules.md)

## 1. Developer Asset Registry

### Authoring Source

```text
implementation/roblox/content-source/packages/<packageId>/
├─ package.manifest.json
├─ prefabs/tokens
├─ prefabs/props
├─ prefabs/tiles
├─ prefabs/volumes
├─ materials
├─ vfx
├─ animations
├─ ui/icons
├─ ui/textures
├─ ui/gizmos
├─ ui/thumbnails
├─ rules
├─ localization
└─ validation
```

Source Binary는 Git LFS 또는 승인된 외부 Source URI를 사용하며 Source Hash·Rights·Provenance를 보존한다.

### Server-authoritative Package

```text
implementation/roblox/src/ServerStorage/RVTT/Content/Packs/<packageId>/
├─ Manifest.lua
├─ AssetRegistry.lua
├─ PrefabDefinitions
├─ RuleModuleDefinitions
├─ LocalizationIndex.lua
└─ ValidationProfile.lua
```

### Client-safe Runtime View

```text
implementation/roblox/src/ReplicatedStorage/RVTT/ContentRuntime/
├─ CatalogViews
├─ ThumbnailViews
├─ UiAssets
├─ PlacementPreviewViews
└─ RuleReaderViews
```

비밀 Definition·미공개 Asset·권한 밖 Count는 복제하지 않는다.

### Stable Asset Record

```text
ContentAssetRecord
├─ assetId
├─ packageId
├─ version
├─ kind
├─ displayNameKey
├─ sourceContentHash
├─ runtimeContentAddress
├─ publishedAssetId?
├─ thumbnailAssetId
├─ bounds
├─ pivot
├─ placementProfile
├─ collisionProfile
├─ navigationProfile
├─ interactionCapabilities[]
├─ performanceBudget
├─ dependencies[]
├─ rights
└─ provenance
```

Token Prefab은 feet pivot, footprint, selection bounds, rig, animation, camera focus를 필수로 가진다. Prop은 placement surface, collision, navigation, interaction sockets와 state variants를 가진다. Tile은 cell·snap·edge connector·walkability를 가진다. Volume은 fog·light·trigger·hazard와 replication policy를 가진다.

Package Compile은 Stable ID 중복, Rights 누락, Pivot·Bounds·Thumbnail 누락, 허용되지 않은 Script·Remote, Dependency cycle, Performance Budget, Client-safe leak와 Rule Anchor 누락을 차단한다.

Broken Asset은 Missing Asset Placeholder와 Stable ID를 표시한다. `Locate Package`, `Replace`, `Remove`, `Keep Placeholder`를 제공하고 자동 대체하지 않는다.

## 2. Interactive Official 2024 Character Sheet

Reference Page Ratio는 `8.5:11` Portrait다.

### Page 1

```text
Top Header                   13%
Main Content                 87%
Main Left                    35%
Main Right                   65%

Main Left
→ Proficiency · 6 Ability · Saves · Skills · Inspiration · Training

Main Right
→ Initiative · Speed · Size · Passive Perception
→ Weapons & Damage Cantrips 24%
→ Class Features            43%
→ Species Traits / Feats    33%
```

Top Header는 Character Name·Background·Species·Class·Subclass, 원형 Level/XP, AC Shield, HP, Hit Dice, Death Saves 순서를 유지한다.

### Page 2

```text
Left                         68%
Right                        32%

Left Top
→ Spellcasting Ability 24% · Spell Slots 76%

Left Body
→ Cantrips & Prepared Spells

Right
→ Appearance 14%
→ Backstory & Personality 30%
→ Languages 10%
→ Equipment 34%
→ Coins 12%
```

기본 상태는 종이 시트처럼 보이고 Hover·Keyboard Focus 때만 Action Ring과 짧은 Label을 추가한다.

Roll 가능한 Field:

- Ability·Saving Throw·Skill
- Initiative
- Weapon Attack·Damage·Damage Cantrip
- Spell Attack 관련 Roll
- Hit Dice·Death Save
- Feature Roll

변경 가능한 Field:

- HP·Temporary HP
- Equipment equip·unequip
- Magic Item attune·unattune
- Prepared·Memorized spell toggle
- Inventory item use·split·send
- Hotbar pinning
- Inspiration spend

Click은 Client Roll을 만들지 않고 `RollRequest` 또는 권한 있는 서버 Command를 제출한다. Page 2 Equipment Row는 `SheetItemActionPopover`에서 장착·해제·사용·조율·Hotbar·상세·보내기를 제공한다. VTT Inventory와 같은 `CharacterSheetProjection.revision`과 Command Binding을 사용한다.

Wide·Reference는 2-page spread, Compact는 Page Tab `1/2`를 사용한다. Compact에서 Column을 재배치하지 않는다.

## 3. Dice Slot Reveal Notice

```text
DiceNoticeProjection
├─ rollId
├─ audience
├─ diceMode
├─ naturalResults[]
├─ appliedIndex
├─ modifierTerms[]
├─ total
├─ adjudication
├─ semanticCritical
├─ subjectLabel
├─ actionLabel
├─ revealRevision
└─ timingProfile
```

Client는 Applied Die·Total·Success·Critical을 계산하지 않는다.

### Normal d20

```text
hidden
→ square_enter        120 ms
→ slot_spin           420–720 ms
→ natural_lock        180 ms
→ formula_expand      260 ms
→ adjudication_append 180 ms
→ hold                1600–2600 ms
→ dismiss             240 ms
```

초기 Frame은 `64×64 px` Square다. 숫자는 위에서 아래로 흐르고 Natural Result에 멈춘다. 높이를 유지하며 오른쪽으로 확장한 뒤 Subject·Formula·Total과 서버 Adjudication을 붙인다.

### Advantage·Disadvantage

처음부터 `148×64 px` 이상의 Rectangle과 두 Natural Cell을 사용한다. Applied Cell은 Accent·Scale·Connector로 Formula에 연결하고 Discarded Cell은 45–55% 대비로 낮춘다. Natural 1·20 Effect는 Applied Cell에만 적용한다.

### Natural 1·20

Natural 1은 Lock 직후 한 번 큰 감쇠 Horizontal Shake 후 Danger Red로 전환한다. Natural 20은 같은 방식으로 Success Green으로 전환한다. Natural 값만으로 자동 성공·실패를 Client가 결정하지 않는다.

Reduced Motion은 Slot Spin을 2–3단계 Crossfade로 축약하고 Shake를 제거하며 Outline Pulse·Tint Fade를 사용한다. 공개 순서는 동일하다.

Top Center에 표시하며 Initiative와 겹치면 아래로 Offset한다. 여러 Roll은 Queue로 순차 표시하고 동시에 필요한 경우 Stack 2개까지 허용한다.

## 4. Core Rules Module과 Journal Reader

`rvtt.core.rules`는 단일 거대 문서가 아니라 Module Container다.

```text
RuleContentPackage
→ RuleModule
→ RuleDocument
→ RuleSection
→ RuleChunk
```

Module 총 길이는 제한하지 않지만 Rule Chunk는 UTF-8 약 `4–16 KB`를 목표로 하고 표·목록·문단 중간에서 임의 분할하지 않는다.

Journal UI:

```text
Left
→ Collection · Module · Document Tree

Center
→ Virtualized Rule Article

Right
→ Outline · Source · Related Rules · Backlinks

Top
→ Search · Module Filter · Font Size · Copy Rule Link · Active Profile Badge
```

Stable URI:

```text
rvtt-rule://<packageId>/<moduleId>/<documentId>#<anchorId>
```

Character Sheet, ActionHoverPanel, Condition, Spell, Dice Formula와 DM Tool은 정확한 Rule Section을 연다. Search 결과·Snippet·Backlink는 권한 있는 Module에서만 생성한다. Client는 현재 Viewport 주변 Chunk만 Lazy Load한다.

Reader 상태:

- Module Loading Skeleton
- Search Index Updating
- No Result
- Package Missing
- Dependency Broken
- Private Source Missing
- Source Revision Mismatch
- Expected Count Mismatch
- Entitlement Expired
- License Attribution Required
- Unsupported Locale
- Offline Unavailable

## 5. Rule Content Profile Resolution

Rule Package는 실행 목적에 따라 명시적으로 선택한다.

```text
development
 test
 studio-acceptance
→ rvtt.test.rules.2024.integrated.ko

public
 release
 artifact
→ rvtt.core.rules
```

동일 Build가 두 프로필의 본문을 자동 병합하지 않는다. `RulePackageResolver`는 정확히 하나의 기본 Rule Package를 선택하고, 명시적으로 허용된 House Rule Overlay만 추가한다.

### Integrated Korean Test Pack

```text
packageId
→ rvtt.test.rules.2024.integrated.ko

sourceRepository
→ Kaetaeru/D-D-2024-

sourceRevision
→ d3d574725e0ecdfd05cb69fa32cf66196e3a8ee4

sourceRoot
→ 10-RULEBOOKS/integrated-2024

sourceBindingKey
→ RVTT_PRIVATE_DND2024_KO_SOURCE
```

기대 Content Count:

```text
classes       12
subclasses    48
backgrounds   16
species       10
feats         75
spells        391
```

이 Package는 `developer_private`, `owner_only`, `redistributable=false`, `publicBuildAllowed=false`, `clientExportAllowed=false`다. 공개 Git Tree에는 Source 본문·변환 Chunk·Search Index를 저장하지 않는다.

Private Import 단계:

```text
resolve private source binding
→ verify repository and pinned revision
→ enumerate integrated-2024 documents
→ validate expected content counts
→ normalize headings, tables and links
→ assign stable document/section anchors
→ create 4–16 KB semantic chunks
→ create Korean search index
→ emit temporary RuleContentPackage
→ scan for forbidden public output
```

Importer 산출물은 Local Build Cache 또는 권한 제한 CI Workspace에만 존재한다. Roblox Client에는 현재 세션·현재 사용자에게 허용된 RuleReader View만 Projection한다. Source Credential·Repository URL Token·Raw Git Metadata는 Client에 보내지 않는다.

Pin·Count·Hash가 다르면 Test Build는 Fail Closed한다. 개발자가 명시적으로 `allowSrdFallback=true`를 켠 경우에만 `rvtt.core.rules`로 대체하며, Rules Reader와 Test Report에 Fallback 상태를 지속 표시한다.

### Public SRD Package

`rvtt.core.rules`는 SRD 5.2.1 기반 공개·Release Package다.

기본 Module 예시:

```text
srd521.playing-the-game
srd521.character-creation
srd521.classes
srd521.feats
srd521.equipment
srd521.spells
srd521.rules-glossary
srd521.conditions
srd521.creatures
```

Package Manifest에 License ID, Attribution, Source Version, Source URL·Hash를 기록한다. 공개 Release에서는 Private Test Pack의 Package ID·본문·검색 자료가 없어야 한다.

## 6. Release Content Leak Gate

공개 산출물 생성 전에 다음을 검사한다.

- `rvtt.test.rules.2024.integrated.ko` Package ID가 Client·Server Output에 없음
- `Kaetaeru/D-D-2024-` Source Path와 Private Commit Metadata가 Runtime Output에 없음
- Private Rule Chunk·Search Index·Snippet Cache가 Artifact에 없음
- 비-SRD 서브클래스·배경·재주·주문 본문이 없음
- SRD Attribution과 CC BY 4.0 고지가 있음
- 모든 `rvtt-rule://` Link가 공개 Package Anchor로 Resolve됨

검사 실패 시 Release Build·Artifact Upload·Publish를 차단한다.

## 7. Acceptance

- Asset Source·Server Registry·Client-safe View가 분리된다.
- 모든 Prefab이 Stable ID·Rights·Pivot·Bounds·Validation을 가진다.
- Official Sheet 영역 비율은 정의값 ±2%다.
- Official Sheet Roll·Equip·Unequip·Use·Prepare·Attune가 서버 Command다.
- Official Sheet와 VTT Inventory는 같은 Revision이다.
- Dice Natural 값이 Formula와 판정보다 먼저 보인다.
- Advantage·Disadvantage와 Natural 1·20·Reduced Motion이 동작한다.
- 200,000자 이상 Rule Package를 전체 String 없이 탐색한다.
- 개발·테스트 기본 Profile이 통합 한국어 Package를 선택한다.
- 통합 Package가 12/48/16/10/75/391 Count를 검증한다.
- Private Source가 없거나 Pin이 다르면 Fail Closed한다.
- Public·Release Profile은 SRD Package만 선택한다.
- 공개 Artifact에 Private Rule Content·Source Metadata가 없다.
- 권한 없는 Rule Module의 제목·Count·Snippet이 없다.
