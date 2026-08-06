# RVTT 고정밀 UI HTML 제작 가이드

- 상태: `CURRENT · HIGH_FIDELITY_PRODUCTION_TARGET · ADR-0092 EXTENDED`
- 최종 갱신일: 2026-08-06
- 기본 실행 파일: [`index.html`](index.html)
- Survival·Token Supplemental: [`survival-and-token-authoring.html`](survival-and-token-authoring.html)
- Loader: [`rvtt-ui.js`](rvtt-ui.js)
- Loading Fallback: [`rvtt-ui.css`](rvtt-ui.css)
- 압축 제작 자산: [`assets/`](assets/)
- 최상위 결정:
  - [`ADR-0092`](../../decisions/ADR-0092-campaign-survival-logistics-and-dm-authored-actor-tokens.md)
  - [`ADR-0091`](../../decisions/ADR-0091-asset-registry-interactive-sheet-dice-and-core-rules.md)

```text
High-Fidelity HTML Production Target
≠ Roblox Studio Runtime Evidence
≠ Release Screenshot
```

## 제작 기준

- Reference Viewport `1920 × 1080`
- Safe Inset X `32 px`, Y `24 px`
- UI Scale `0.80–1.40`
- Text Scale `0.90–1.30`
- Character Console Action Rows `1–4`
- Official Sheet Page `8.5:11`, 2-page spread
- Dice Normal Start `64×64`, Advantage Start `148×64`
- DM Window Module Move·Resize·Dock·Tab·Close
- Rules Reader Chunk `4–16 KB` 목표
- Campaign Rule 변경은 Candidate Snapshot·Impact Preview·Safe Boundary를 표시
- Supply Settlement는 Time·Inventory·Shortage를 하나의 Confirm Surface로 표시
- Actor Import는 Model·Stat Block·Token·SceneNpc 경계를 분리

## 포함 범위

기본 Gallery는 33개 화면이다.

```text
제작 기준       3
세션·공통       5
Player 전장     8
Player 관리     7
설정·복구       3
Observer        1
DM              6
합계           33
```

ADR-0092 Supplemental은 6개 제작 화면을 추가한다.

```text
Campaign Rules                  1
Time Advance Supply Settlement  1
Supply Ledger                   1
Actor Model Registry            1
AI Prompt Builder               1
JSON Validator & Actor Preview  1
추가                            6
```

총 제작 대상 Surface는 기본 33 + Supplemental 6이다. Supplemental은 독립 self-contained HTML이며 기본 Gallery Runtime 증거를 대체하지 않는다.

## Official 2024 Sheet

- Page 1 Body `35% / 65%`
- Page 2 Body `68% / 32%`
- Compact는 Column 재배치가 아니라 Page 전환
- Ability·Save·Skill·Attack·Death Save·Spell Roll
- Equipment Equip·Unequip·Use·Attune
- Spell Prepare·Cast·Rule Link
- VTT Inventory와 동일 Revision·Command

외부 Logo·Artwork·고유 Typeface를 복제하지 않고 RVTT 시각 체계를 사용한다.

## Dice Notice

```text
Natural Square Spin
→ Natural Lock
→ Formula Rectangle Expand
→ Adjudication Append
```

Advantage·Disadvantage는 두 Natural Cell을 가진 Rectangle로 시작한다. Applied Die에만 Natural 1·20 Effect를 적용한다. Reduced Motion도 공개 순서를 유지한다.

## Core Rules

Journal의 `Core Rules` Collection은 Package→Module→Document→Section→Chunk 구조다. 200,000자 이상 Package도 전체를 한 번에 Client에 보내지 않는다. HTML은 Reader 구조만 표현하며 실제 비공개 규칙 본문 전체를 포함하지 않는다.

## Campaign Survival

```text
Campaign Preset·Module
→ Candidate Policy Snapshot
→ Time Advance Supply Preview
→ Supply Settlement Transaction
→ Ledger·Projection
```

정확한 일일 소비 수치는 HTML에 고정하지 않는다. 활성 Rule Profile의 Requirement Definition과 Rule Anchor를 표시하는 구조만 고정한다.

## Actor Token Authoring

```text
Actor Model Registry
→ AI Prompt Builder
→ Strict JSON Validator
→ Actor Preview
→ Campaign-local Publish
```

현재 Asset Registry에 실제 Actor Model Entry가 없으면 빈 Catalog를 그대로 표현한다. 문서가 모델 이름을 임의로 만들어 넣지 않는다.

## Asset Registry

```text
content-source/packages/<packageId>
→ 개발 원본

ServerStorage/RVTT/Content/Packs/<packageId>
→ 권위 Manifest·Definition

ReplicatedStorage/RVTT/ContentRuntime
→ Client-safe Catalog·Preview
```

## 정적 검증

- HTML parse
- JavaScript syntax
- 기본 33 Screen ID unique·Renderer smoke
- Supplemental 6 Screen ID unique·Navigation smoke
- Official Sheet proportion contract
- Dice Slot Reveal contract
- Core Rules Module contract
- Campaign Rule Toggle·Supply Settlement surface
- Actor Model Catalog empty state
- Strict JSON·Prompt·Validation surface
- Audio Mixer Tab 없음
- Objective·Map·Minimap 없음

자동 Browser Screenshot·Roblox Runtime 비교는 별도 Evidence다.
