# ADR-0038: 함정·비밀문·파괴 오브젝트도 무설정 상태 프리팹과 배치 후 규칙 프로필로 제작한다

- 상태: 확정
- 결정일: 2026-08-03
- 관련 문서:
  - [`ADR-0023`](ADR-0023-composable-targeting-and-spatial-query-model.md)
  - [`ADR-0027`](ADR-0027-passive-modifiers-rule-overrides-and-conditional-activation.md)
  - [`ADR-0028`](ADR-0028-effect-recipes-pending-effects-and-commit-groups.md)
  - [`ADR-0036`](ADR-0036-observer-relative-perception-senses-stealth-and-rule-points.md)
  - [`ADR-0037`](ADR-0037-zero-metadata-interaction-prefabs-and-state-snapshot-transitions.md)
  - [`32. 무설정 함정·비밀문·파괴 오브젝트 모델`](../32-zero-metadata-trap-secret-door-and-destructible-object-model.md)

## 배경

RVTT에는 압력판, 화살 함정, 가스 분출구, 함정 상자, 비밀문, 부서지는 문, 파괴 가능한 엄폐물, 마법 수정과 퍼즐 장치처럼 서로 다른 장면 오브젝트가 많이 필요하다.

각 오브젝트를 추가할 때마다 제작자가 원본 모델에 Attribute, ValueBase, Attachment, Script, RemoteEvent 또는 별도 설정 파일을 넣어야 한다면 모델 수가 늘수록 제작 비용과 오류가 급격히 증가한다.

사용자가 원하는 제작 흐름은 다음과 같다.

```text
ReplicatedStorage에 상태 모델 폴더를 넣는다
→ 원본에는 Attribute·Value·Script가 없다
→ 장면 편집기에서 배치한다
→ 배치 후 함정·비밀문·파괴물 규칙을 선택하거나 수정한다
→ 바로 사용한다
```

또한 단순한 `1 ↔ 2` 전환뿐 아니라 다음과 같은 다중 상태도 필요하다.

```text
파괴 오브젝트
1 = 온전함
2 = 손상됨
3 = 파괴됨

비밀문
1 = 위장된 닫힘
2 = 발견된 닫힘
3 = 열림

함정
1 = 대기
2 = 발동
3 = 해제 또는 재장전
```

그러나 `발견됨`과 같은 정보 상태는 관찰자마다 다를 수 있고, `열림`이나 `파괴됨`은 월드 전체에 공통인 실제 상태다. 이 둘을 하나의 숫자 상태로만 처리하면 비밀 정보가 잘못 복제되거나 동일 오브젝트가 플레이어마다 다른 물리 상태를 가지는 문제가 생긴다.

## 결정

함정, 비밀문, 파괴 가능한 오브젝트는 ADR-0037의 무설정 상태 프리팹 계약을 그대로 확장한다.

```text
원본 상태 모델 폴더
→ PrefabCompiler
→ StateSnapshotCatalog
→ 장면 배치
→ 카테고리 기본 프로필 적용
→ 배치 후 인스턴스 규칙 설정
→ 서버 권위 SceneObjectInstance
```

원본 에셋은 폴더 위치와 상태 번호, 구성요소 상대 경로만으로 인식한다.

```text
ReplicatedStorage
└─ RVTTContent
   └─ InteractionObjects
      ├─ Trap
      │  └─ SpikePlate
      │     ├─ 1
      │     ├─ 2
      │     └─ 3
      ├─ SecretDoor
      │  └─ StoneWallDoor
      │     ├─ 1
      │     ├─ 2
      │     └─ 3
      └─ Destructible
         └─ WoodenBarricade
            ├─ 1
            ├─ 2
            └─ 3
```

원본에는 다음을 요구하지 않는다.

```text
Attribute 없음
ValueBase 없음
Script 없음
RemoteEvent 없음
Attachment 없음
PrimaryPart 지정 없음
```

상태 폴더는 `1`, `2`, `3`처럼 연속된 양의 정수 이름을 사용하며, 최소 `1`과 `2`가 필요하다. 각 상태 모델은 자신의 Pivot을 기준으로 구성요소의 상대 위치와 속성을 제공한다.

## 시각 상태와 규칙 상태 분리

```text
VisualStateId
→ 현재 모델이 어떤 상태 스냅샷을 표시하는가

WorldRuleState
→ armed, triggered, closed, open, damaged, destroyed 등의 실제 상태

PerceptionRelation
→ 어떤 관찰자가 함정·비밀문을 발견했는가
```

비밀문이 발견되었다고 문이 자동으로 열리지는 않는다. 플레이어 A가 비밀문을 발견해도 플레이어 B가 아직 발견하지 못할 수 있다. 반면 문이 실제로 열리면 모든 권한 있는 클라이언트에서 동일한 이동·시야 차단 상태를 사용한다.

## 카테고리 기본 프로필

폴더 카테고리는 배치 직후 적용할 기본 규칙 프로필만 선택한다.

```text
Trap
→ TrapSceneObjectProfile

SecretDoor
→ SecretPassageSceneObjectProfile

Destructible
→ DestructibleSceneObjectProfile
```

세부 DC, HP, 발동 효과, 재설정 여부와 링크 대상은 원본 모델이 아니라 배치된 인스턴스의 장면 데이터에 저장한다.

## 함정

함정은 다음 구성요소를 가진다.

```text
TrapSceneObjectState
├─ armedState
├─ triggerPolicy
├─ detectionProfile
├─ disableProfile
├─ effectRecipeId
├─ repeatPolicy
├─ resetPolicy
├─ linkedObjects[]
└─ revision
```

기본 배치 시 모델 경계에서 TriggerVolume과 InteractionVolume 후보를 자동 생성한다. DM은 인스펙터에서 위치, 크기, 감지 DC, 해제 DC, 발동 방식과 효과를 수정한다.

함정은 매 프레임 모든 토큰을 검사하지 않는다. 토큰 이동 확정, 문 열림, 상호작용, 타이머와 장면 신호 같은 의미 있는 사건으로만 TriggerPolicy를 평가한다.

함정 피해와 상태 적용은 자유 코드가 아니라 기존 EffectRecipe와 PendingEffect/CommitGroup을 사용한다.

## 비밀문

비밀문은 실제 문 상태와 발견 상태를 분리한다.

```text
SecretPassageWorldState
├─ closed
├─ open
├─ locked?
├─ blocked?
└─ revision

PerceptionRelation
├─ unaware
├─ clue_detected
├─ exact_location_known
└─ fully_revealed
```

발견 전에는 권한 없는 클라이언트에 상호작용 프롬프트, 실제 식별자와 비밀 정보를 복제하지 않는다.

기본 상태 매핑은 상태 수에 따라 자동 제안한다.

```text
상태 2개
1 = concealed_closed
2 = open

상태 3개
1 = concealed_closed
2 = revealed_closed
3 = open
```

DM은 배치 후 매핑을 변경할 수 있다.

## 파괴 가능한 오브젝트

파괴 가능한 오브젝트는 생명체의 죽음 규칙을 사용하지 않고 `ObjectDurabilityState`를 가진다.

```text
ObjectDurabilityState
├─ currentHitPoints
├─ maximumHitPoints
├─ armorClassOrDefensePolicy
├─ damageThreshold?
├─ resistances[]
├─ immunities[]
├─ stateThresholds[]
├─ destroyedState
└─ revision
```

공격과 주문은 기존 TargetingPlan과 피해 해결 엔진을 사용하되, 피해 확정 후 `DurabilityPolicy`가 손상 단계와 파괴 상태를 결정한다.

```text
공격 대상 지정
→ 서버가 오브젝트 대상 가능 여부 검증
→ 공격·내성·피해 해결
→ ObjectDurabilityState 갱신
→ 임계치에 따른 VisualState 전환
→ 이동·시야·엄폐 데이터 부분 갱신
```

파괴되었다고 오브젝트 데이터를 삭제하지 않는다. 파괴 상태, 잔해, 수리 가능 여부와 감사 기록을 유지한다.

## 다중 상태 전환

`1 ↔ 2`에 한정하지 않고 임의의 등록된 상태 사이를 전환할 수 있다.

```text
SetVisualState(1)
SetVisualState(2)
SetVisualState(3)
AdvanceVisualState()
PreviousVisualState()
```

구성요소 대응은 상태 모델의 동일한 상대 경로를 사용한다. V1에서는 자동 Tween 대상 구성요소가 모든 상태에 존재해야 한다. 나타나거나 사라지는 부품도 모든 상태에 두고 Transparency, Size, Enabled 등으로 표현한다.

## 장면 링크

원본 프리팹에는 다른 오브젝트 참조를 넣지 않는다. 배치 후 편집기에서 타입 있는 링크를 생성한다.

```text
SceneObjectLink
├─ sourceObjectId
├─ signalType
├─ targetObjectId
├─ commandType
├─ commandArguments
├─ conditions[]
└─ revision
```

초기 신호:

```text
on_interacted
on_actor_entered
on_detected
on_disabled
on_triggered
on_state_entered
on_damaged
on_destroyed
on_timer
```

초기 명령:

```text
set_state
advance_state
toggle_state
arm
disarm
trigger_effect
reveal
unlock
open
close
spawn_registered_object
```

레버가 함정을 해제하거나, 압력판이 화살 발사기를 작동시키거나, 수정이 파괴되면 비밀문이 열리는 구성을 같은 링크 그래프로 만든다.

## Feature·Feat 호환

함정 탐지, 해제, 회피, 비밀문 탐색과 오브젝트 파괴는 기존 Capability와 RulePoint를 사용한다.

```text
DerivedValueModifierCapability
→ 수동 지각, 조사, 도구 판정, 오브젝트 피해 수치 수정

ContextModifierCapability
→ 함정 탐지·해제·회피 문맥에 이점 또는 보너스

RuleOverrideCapability
→ 특정 함정 피해 감소, 특정 오브젝트 저항 무시, 상호작용 비용 변경

TriggerCapability
→ 함정 발동 직전 반응, 오브젝트 파괴 시 후속 특성

ActionCapability
→ 조사, 해제, 수리, 강제 개방
```

특정 Feat 이름을 엔진에 하드코딩하지 않는다.

## 서버 권위와 보안

- 클라이언트는 함정 발동, 비밀문 발견, 오브젝트 HP와 상태를 직접 확정하지 않는다.
- 상호작용 요청은 거리, 인식 수준, 행동 경제, 도구, 권한, 현재 상태와 revision을 검증한다.
- 숨겨진 함정과 비밀문 데이터는 감지 전 권한 없는 클라이언트에 복제하지 않는다.
- 상태 전환 Tween은 표현이며, 실제 충돌·시야·효과 상태는 서버가 확정한다.
- 원본 모델의 Script와 실행 가능한 임의 코드는 카탈로그 컴파일 대상에서 제외한다.

## 결과

### 장점

- 제작자는 상태 모델만 만들어도 문, 함정, 비밀문과 파괴물을 추가할 수 있다.
- 원본 에셋이 런타임 Attribute와 규칙 설정으로 오염되지 않는다.
- 다중 상태 모델을 동일한 Tween 엔진으로 재사용한다.
- 함정·비밀문 탐지가 관찰자별 Perception 시스템과 자연스럽게 연결된다.
- 파괴 오브젝트가 기존 공격·피해·Feature·Feat 시스템과 호환된다.
- 장면별 규칙 변경이 원본 프리팹 복제 없이 가능하다.

### 비용

- 상태 모델의 구성요소 상대 경로를 일관되게 유지해야 한다.
- 복잡한 함정은 배치 후 EffectRecipe와 링크 설정이 필요하다.
- 자동 생성된 TriggerVolume, 차단 볼륨과 상태 매핑은 일부 모델에서 DM 수정이 필요할 수 있다.

## 구현 제약

- 프리팹 카탈로그 스캔은 시작 또는 명시적 갱신 시 수행하며 매 프레임 검색하지 않는다.
- 상태 스냅샷은 컴파일·캐시하고 장면 인스턴스마다 상태 모델 전체를 복제하지 않는다.
- 오브젝트 감지와 트리거 평가는 사건 기반으로 수행한다.
- 파괴 상태 변화 시 전체 장면이 아니라 영향받는 이동·시야·엄폐 영역만 갱신한다.
- 잘못된 프리팹은 해당 항목만 비활성화하고 전체 카탈로그를 중단하지 않는다.
