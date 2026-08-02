# ADR-0032: 몬스터·NPC 스탯블록은 공통 ActorDefinition으로 컴파일하고 DM JSON은 검증 후 캠페인 콘텐츠로 승격한다

- 상태: 확정
- 결정일: 2026-08-03
- 관련 문서:
  - [`ADR-0014`](ADR-0014-character-data-and-scene-actor-separation.md)
  - [`ADR-0024`](ADR-0024-hybrid-rule-recipes-and-reusable-advanced-operations.md)
  - [`ADR-0028`](ADR-0028-effect-recipes-pending-effects-and-commit-groups.md)
  - [`ADR-0030`](ADR-0030-item-instances-attack-profiles-and-weapon-mastery.md)
  - [`ADR-0031`](ADR-0031-zero-hit-points-death-saves-rests-and-resource-recovery.md)
  - [`26. 몬스터·NPC 스탯블록과 인게임 JSON 가져오기 모델`](../26-monster-npc-statblock-and-ingame-json-import-model.md)

## 배경

RVTT는 공식 몬스터, 캠페인 고유 NPC, 즉석 전투원과 DM이 외부에서 작성한 사용자 스탯블록을 모두 실행해야 한다.

- 공식 몬스터는 개발자 관리 콘텐츠 팩에서 제공된다.
- 캠페인 NPC는 이름, 토큰 외형, 비밀 정보와 개별 상태를 가진다.
- 같은 스탯블록으로 여러 Actor를 생성할 수 있어야 한다.
- 공격, 다중공격, 재충전 능력, 전설적 행동, 반응과 지속 효과가 기존 공통 규칙 엔진을 사용해야 한다.
- DM은 세션 중 JSON을 붙여 넣어 NPC를 즉시 추가할 수 있어야 한다.
- 사용자 JSON은 신뢰할 수 없는 입력이므로 임의 코드, 엔진 함수, 자유로운 Remote 호출과 무제한 반복을 실행해서는 안 된다.

공식 콘텐츠와 사용자 NPC가 서로 다른 실행 엔진을 사용하면 규칙 처리, UI, 저장과 보안이 분리된다.

반대로 사용자 JSON을 내부 런타임 구조 그대로 받아들이면 서버 권한, 콘텐츠 검증, 성능 상한과 데이터 마이그레이션을 보장할 수 없다.

## 결정

모든 몬스터와 NPC는 공통 `ActorDefinition`과 `StatblockDefinition`으로 컴파일한다.

```text
공식 콘텐츠 정의
또는
DM Authored NPC JSON
→ Schema Validation
→ Semantic Validation
→ Content Normalization
→ Capability·Action·Recipe Compilation
→ CampaignContentDefinition
→ ActorInstance 생성
```

DM이 인게임에서 입력한 JSON은 즉시 실행하지 않는다. 검증과 컴파일에 성공한 경우에만 캠페인 범위의 버전 있는 사용자 콘텐츠로 저장한다.

## 정의와 인스턴스

```text
ActorDefinition
├─ actorDefinitionId
├─ actorKind
├─ identityProfile
├─ statblockReference
├─ defaultInventory
├─ defaultEquipment
├─ grantedCapabilities
├─ actionPackages
├─ presentationProfile
└─ deathPolicy
```

```text
StatblockDefinition
├─ size와 creature tags
├─ ability scores
├─ proficiency profile
├─ armor와 hit point profile
├─ movement modes
├─ senses와 languages
├─ saving throws와 skills
├─ resistances·immunities·vulnerabilities
├─ resources
├─ traits
├─ actions
├─ bonus actions
├─ reactions
├─ legendary actions
└─ metadata
```

`ActorDefinition`은 재사용 가능한 콘텐츠이고 `ActorInstance`는 장면에 존재하는 현재 HP, 위치, 효과, 자원과 장비 상태를 가진다.

## 행동 패키지

스탯블록 행동은 설명 문자열이 아니라 기존 Capability와 Recipe로 컴파일한다.

```text
StatblockActionDefinition
→ ActionCapability / TriggerCapability / Passive Capability
→ TargetingPlan
→ EffectRecipe
```

다중공격은 피해를 직접 계산하는 전용 처리기가 아니라 허용된 행동 단위를 조합하는 `ActionContainerProfile`이다.

재충전 능력은 `ResourceCapability`와 `RechargePolicy`로 표현한다.

전설적 행동과 은신처 행동은 전용 전투 엔진을 만들지 않고 명시적 행동 기회와 타이밍 이벤트를 사용한다.

## DM Authored NPC JSON

인게임 JSON 입력은 외부 작성용 안정 스키마만 허용한다.

허용되는 내용:

- 이름, 설명과 표시 정보
- 크기, 유형, 능력치, HP와 AC
- 이동, 감각, 언어와 숙련
- 피해 저항·면역과 상태 면역
- 등록된 공격·내성·피해·회복·상태·이동 노드
- 등록된 주문, 아이템, Condition과 EffectDefinition 참조
- 제한된 다중공격, 자원, 재충전과 사용 횟수
- 허용된 토큰 프리팹 또는 캠페인 에셋 참조

금지되는 내용:

- Luau 또는 기타 실행 코드
- ModuleScript·RemoteEvent·DataStore 경로
- 임의 함수 이름과 엔진 내부 서비스 참조
- 무제한 반복, 재귀와 동적 노드 생성
- URL에서 런타임 코드나 데이터를 자동 다운로드하는 기능
- 클라이언트가 최종 피해·명중·권한을 확정하는 필드

## 가져오기 단계

```text
1. JSON 구문 분석
2. 문서 크기와 깊이 제한 검사
3. schemaVersion 확인 및 마이그레이션
4. 구조 스키마 검증
5. ID와 참조 해석
6. 수치 범위·그래프·실행 상한 검증
7. 규칙 의미 검증
8. 정규화된 미리보기 생성
9. DM 확인 후 캠페인 정의 저장
10. 테스트 Actor 생성 또는 장면 배치
```

검증 실패는 가능한 한 JSON 경로, 오류 코드와 수정 제안을 제공한다.

## 콘텐츠 신뢰 등급

```text
ContentTrustLevel
├─ developer_signed
├─ campaign_authored
├─ session_temporary
└─ rejected
```

DM JSON은 기본적으로 `campaign_authored`다. 개발자 서명 콘텐츠처럼 엔진 확장 처리기나 비공개 내부 노드를 사용할 수 없다.

세션 임시 NPC는 저장하지 않고 현재 세션에서만 사용할 수 있지만 동일한 검증을 통과해야 한다.

## 편집과 버전

가져온 JSON은 원문, 정규화 정의와 컴파일 결과를 구분한다.

```text
CampaignContentEntry
├─ contentId
├─ schemaVersion
├─ revision
├─ sourceJson
├─ normalizedDefinition
├─ compileDiagnostics
├─ createdBy
├─ createdAt
└─ publicationState
```

이미 생성된 Actor는 사용한 정의 버전에 고정한다. 정의를 수정하면 새 revision을 만들고 기존 Actor에 적용할지는 DM이 명시적으로 선택한다.

## 보안과 성능

- JSON 파싱과 컴파일은 서버에서 수행한다.
- 입력 크기, 문자열 길이, 배열 크기, 그래프 깊이, 대상 수, 반복 수와 생성 효과 수에 상한을 둔다.
- 등록된 타입과 ID만 허용하고 알 수 없는 필드는 정책에 따라 오류 또는 경고로 처리한다.
- 사용자 콘텐츠는 개발자 전용 handler와 engine extension을 참조할 수 없다.
- 컴파일된 정의는 캐시하고 Actor마다 원본 JSON을 재파싱하지 않는다.
- 저장과 배포는 DM 권한과 캠페인 revision 검증을 요구한다.
- 실패한 가져오기는 활성 콘텐츠나 장면 상태를 변경하지 않는다.

## 결과

- 공식 몬스터와 DM 제작 NPC가 같은 행동·효과·상태·자원 엔진을 사용한다.
- 같은 스탯블록으로 여러 Actor를 안전하게 생성할 수 있다.
- DM이 인게임에서 JSON을 붙여 넣어 NPC를 즉시 만들고 저장할 수 있다.
- 사용자 JSON이 임의 코드나 내부 엔진 경로를 실행하지 못한다.
- 오류 위치와 정규화 미리보기로 비개발자도 스탯블록을 수정할 수 있다.
- 캠페인 콘텐츠의 버전, 재사용, 내보내기와 재가져오기를 지원할 수 있다.