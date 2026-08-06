# RVTT 고정밀 UI HTML 제작 가이드

- 상태: `CURRENT · FINAL HIGH_FIDELITY_PRODUCTION_TARGET · ADR-0091 ALIGNED`
- 최종 갱신일: 2026-08-06
- 실행 파일: [`index.html`](index.html)
- Loader: [`rvtt-ui.js`](rvtt-ui.js)
- Loading Fallback: [`rvtt-ui.css`](rvtt-ui.css)
- 압축 제작 자산: [`assets/`](assets/)
- 최상위 결정: [`ADR-0091`](../../decisions/ADR-0091-asset-registry-interactive-sheet-dice-and-core-rules.md)

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

## 포함 범위

총 33개 화면이다.

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

신규·재작성 화면:

- Invite·Join Session
- First-run Control Primer
- Dice Notice State Matrix
- Dice Slot Reveal Runtime
- Interactive Official 2024 Sheet
- Core Rules Module Reader
- Content Package·Asset Registry

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

Journal의 `Core Rules` Collection은 Package→Module→Document→Section→Chunk 구조다. 200,000자 이상 Package도 전체를 한 번에 Client에 보내지 않는다. HTML은 Reader 구조만 표현하며 실제 SRD 본문 전체를 포함하지 않는다.

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
- 33 Screen ID unique
- 33 Renderer registration·smoke
- Official Sheet proportion contract
- Dice Slot Reveal contract
- Core Rules Module contract
- Asset Registry contract
- Audio Mixer Tab 없음
- Objective·Map·Minimap 없음

자동 Browser Screenshot·Roblox Runtime 비교는 별도 Evidence다.
