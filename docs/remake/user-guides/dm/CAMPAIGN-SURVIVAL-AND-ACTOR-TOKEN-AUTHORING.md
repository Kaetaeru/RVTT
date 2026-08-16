# DM Guide: Campaign Survival과 Actor Token 저작

- 상태: `CURRENT · TARGET_EXPERIENCE`
- 최종 갱신일: 2026-08-06
- 상위 결정: [`ADR-0092`](../../decisions/ADR-0092-campaign-survival-logistics-and-dm-authored-actor-tokens.md)
- HTML 제작 기준: [`survival-and-token-authoring.html`](../html/survival-and-token-authoring.html)

## 1. Campaign 생성 시 생존 규칙 선택

Campaign 생성의 `Rules & Survival` 단계에서 다음 Preset을 선택한다.

```text
Narrative
→ 식량·물 자동 차감 없음
→ 필요한 경우 Supply Ledger에 수동 기록

Standard
→ 식량·물 예상량과 부족 경고
→ 시간 진행 전 DM 확인

Survival
→ 활성 규칙 팩의 요구량과 결핍 결과 자동 적용
→ 여행·휴식·일수 진행과 함께 정산

Custom
→ Module별 개별 설정
```

Custom에서 조정 가능한 Module:

- Food
- Water
- Mount Feed
- Exposure
- Encumbrance
- Ammunition
- Rest Quality
- Spoilage

정확한 하루 소비량은 Campaign이 사용하는 Rule Profile에서 가져온다. 설정 화면이 별도 숫자를 복사해 갖지 않는다.

## 2. Campaign 진행 중 변경

상단 `Campaign Rules` Tool을 열어 변경한다.

```text
현재 Snapshot 확인
→ Module 또는 Preset 변경
→ 영향 Preview
→ 적용 경계 선택
→ 적용
```

적용 경계 예:

```text
다음 시간 진행부터
다음 여행·휴식 시작부터
현재 활동 종료 뒤
Campaign Maintenance에서
```

기본적으로 과거 날짜를 다시 계산하지 않는다.

기능을 끄더라도 이미 소비된 식량은 돌아오지 않고, 이미 발생한 결핍 상태는 자동으로 사라지지 않으며, Ledger와 과거 기록은 유지된다.

기능을 켜더라도 지난 날짜의 식량을 갑자기 한꺼번에 차감하지 않는다. 다음 미정산 경계부터 시작한다.

과거 재정산은 `Retroactive Reconcile`에서 날짜 범위와 Item·Effect Diff를 보고 별도로 실행한다.

## 3. Time Advance Supply Preview

DM이 수일 여행, 휴식 또는 시간 진행을 승인하면 Supply Preview를 먼저 볼 수 있다.

```text
기간
→ 1492-08-06 08:00 ~ 1492-08-09 08:00

Consumer
→ Player Character 4
→ Follower 1
→ Mount 2

공급원
→ 개인 인벤토리
→ Party Supply Chest
→ Wagon Storage

결과
→ 소비 예정 Stack
→ 예상 남은 일수
→ 부족량
→ 적용될 결핍 규칙
```

`Adjust Sources`에서 공급원 순서를 바꾸거나 특정 Stack을 보호할 수 있다.

다음 Item은 기본적으로 자동 소비하지 않는다.

- Quest·Key Item
- 보호된 Stack
- 다른 사용자의 비공개 Container
- 다른 Transaction에서 사용 중인 Item
- Supply Metadata가 없는 일반 Item

## 4. Inventory Supply Summary

Inventory의 Supply Summary는 다음을 표시한다.

```text
Food       7.5일
Water      3.0일
Mount Feed 1.5일
```

이 값은 현재 Frozen Policy와 현재 접근 가능한 Supply 기준 예상치다. 미래 날씨, 획득, 분실, Party 변경을 보장하지 않는다.

Player에게 숨겨진 NPC나 비공개 Storage의 수량은 포함하거나 노출하지 않는다.

## 5. Actor Model Registry

DM Workspace에서 `Actor Model Registry`를 연다.

```text
Model Source 선택
→ Rights·Provenance 입력
→ Feet Pivot 확인
→ Size Compatibility 선택
→ Footprint·Scale Range 설정
→ Script·Dependency·Budget 검사
→ Thumbnail 생성
→ Publish Asset
```

Model과 Stat Block은 별개다. 같은 Model을 여러 NPC Template에서 재사용할 수 있다.

현재 등록된 Actor Model이 없으면 Registry에는 빈 상태와 `Actor Model 추가` 버튼만 표시한다. 존재하지 않는 기본 Model 이름을 문서에 가정하지 않는다.

## 6. Actor & Token Builder

```text
1. Stat Block Source 선택
2. Actor Model 선택
3. Size·Footprint·Scale 확인
4. Action·Trait 검토
5. Token Preview
6. Campaign Draft 저장
7. Publish
```

Source 종류:

```text
Rules Package Definition
Campaign Homebrew
Imported Reference
Unknown Draft
```

Rules Package Definition은 Stable Source Anchor가 있어야 한다. Source Anchor가 없는 AI 결과는 공식 콘텐츠로 표시되지 않는다.

## 7. AI Prompt Builder

`AI Prompt Builder`는 AI를 직접 호출하지 않는다. DM이 다른 AI 도구에 붙여 넣을 Prompt를 생성한다.

Prompt 생성 입력:

- 현재 Ruleset·Rule Profile
- Stat Block 원문 또는 Homebrew 요구
- Strict JSON Schema
- Trusted Recipe 목록
- 현재 보이는 Actor Model Catalog 전체

`모델 목록 포함`은 일부 추천만 넣는 옵션이 아니다. 현재 DM에게 보이는 모든 Entry를 Stable Asset ID 순으로 넣는다.

Catalog가 비어 있으면 다음이 들어간다.

```json
{"catalogRevision":0,"models":[]}
```

이 상태에서 AI가 Model ID를 만들어도 Import Validator가 거부한다.

## 8. JSON 가져오기

AI 결과나 직접 작성한 JSON을 `Stat Block JSON Validator`에 붙여 넣는다.

```text
JSON Parse
→ Schema
→ Stat Block 의미
→ Rule Reference
→ Actor Model Reference
→ Rights·Provenance
→ Trusted Automation
→ Preview
```

오류 등급:

```text
Blocker
→ Publish 불가

Warning
→ DM 확인 필요

Info
→ 권장 정리
```

대표 Blocker:

- 존재하지 않는 Actor Model ID
- Script 또는 실행 코드 Field
- 미등록 Recipe
- Rights 누락
- 필수 AC·HP·Ability 누락
- Size와 Model 호환 불가
- 중복 Action ID

## 9. Publish와 Scene 배치

Publish하면 Campaign-local Content Package에 새 Version이 생긴다.

```text
Campaign Draft
→ Validation Report
→ Published Actor Template Version
→ Scene Catalog 표시
→ SceneNpc 생성 가능
```

새 Template Version은 이미 배치된 NPC를 자동으로 바꾸지 않는다. 기존 NPC에 적용하려면 HP·Action·Token Size·현재 위치와 Encounter 영향을 검토하는 Migration이 필요하다.

## 10. 안전 원칙

- AI JSON을 자동 Publish하지 않는다.
- AI가 만든 코드를 실행하지 않는다.
- Model 안의 Script 계열 Instance를 허용하지 않는다.
- 공식 Stat Block을 자동으로 밸런싱하거나 CR 조정하지 않는다.
- Campaign Homebrew와 Core Definition을 분리한다.
- Player에게 DM 전용 Model Registry·Source·Hidden Actor Count를 노출하지 않는다.
