# 32. 무설정 함정·비밀문·파괴 오브젝트 모델

- 상태: 초안
- 작성일: 2026-08-03
- 관련 문서:
  - [`06. 인게임 장면 편집기 도구`](../../../scene/ingame-scene-editor-tools.md)
  - [`07. 장면 편집 상호작용과 레이아웃`](../../../../ui/scene-editor/scene-editor-interaction-and-layout.md)
  - [`17. 주문 대상·범위·공간 질의 모델`](../../../rules/spell-targeting-area-and-spatial-query-model.md)
  - [`21. 패시브 특성 모델`](../../../../architecture/passive-modifier-and-rule-override-model.md)
  - [`22. EffectRecipe와 효과 해결·확정 모델`](../../../../architecture/effect-recipe-resolution-and-commit-model.md)
  - [`30. 시야·감각·은신·탐지 모델`](../../../perception/visibility-senses-stealth-and-detection-model.md)
  - [`31. 무설정 상호작용 프리팹과 상태 전환 모델`](../../../../zero-metadata-interaction-prefab-and-state-transition-model.md)
  - [`ADR-0038`](../../../../decisions/ADR-0038-zero-metadata-hazards-secret-passages-and-destructible-objects.md)

## 1. 문서 목적

이 문서는 함정, 비밀문, 파괴 가능한 오브젝트를 원본 모델에 Attribute, ValueBase, Script나 별도 설정 파일을 넣지 않고 RVTT에 추가하는 구조를 정의한다.

가장 중요한 제작 경험은 다음과 같다.

```text
상태 모델을 만든다
→ InteractionObjects의 올바른 카테고리 폴더에 넣는다
→ 상태 폴더 이름을 1, 2, 3으로 정한다
→ 장면 편집기에서 배치한다
→ 자동으로 생성된 규칙 프로필을 확인한다
→ 필요한 값만 배치 후 수정한다
→ 사용한다
```

이 문서의 대상:

- 함정 프리팹
- 비밀문과 숨겨진 통로
- 파괴 가능한 문, 상자, 엄폐물과 장치
- 2개 이상의 상태 스냅샷
- 상태 간 Tween과 즉시 속성 전환
- 탐지와 관찰자별 공개
- 함정 발동, 해제와 재설정
- 오브젝트 HP, 방어, 피해 임계치와 손상 단계
- 장면 오브젝트 간 링크
- Feature, Feat, 주문, 장비와의 호환
- 배치 후 인스펙터와 빠른 설정 흐름
- 저장, 복구, 버전과 성능

핵심 원칙:

```text
원본 에셋
→ 시각 상태만 제공

배치된 장면 인스턴스
→ 규칙, DC, HP, 링크와 현재 상태를 보유
```

---

## 2. 원본 프리팹 폴더 구조

기본 카탈로그 위치:

```text
ReplicatedStorage
└─ RVTTContent
   └─ InteractionObjects
      ├─ Trap
      ├─ SecretDoor
      └─ Destructible
```

예시:

```text
InteractionObjects
├─ Trap
│  ├─ SpikePlate
│  │  ├─ 1
│  │  ├─ 2
│  │  └─ 3
│  ├─ DartLauncher
│  │  ├─ 1
│  │  └─ 2
│  └─ GasVent
│     ├─ 1
│     └─ 2
├─ SecretDoor
│  ├─ StoneWallDoor
│  │  ├─ 1
│  │  ├─ 2
│  │  └─ 3
│  └─ BookshelfPassage
│     ├─ 1
│     └─ 2
└─ Destructible
   ├─ WoodenBarricade
   │  ├─ 1
   │  ├─ 2
   │  └─ 3
   ├─ CrackedPillar
   │  ├─ 1
   │  └─ 2
   └─ MagicCrystal
      ├─ 1
      ├─ 2
      └─ 3
```

프리팹 루트 이름이 카탈로그 ID의 기본 이름이 된다.

```text
Trap/SpikePlate
SecretDoor/StoneWallDoor
Destructible/WoodenBarricade
```

정식 내부 ID 예시:

```text
interaction.trap.spike_plate
interaction.secret_door.stone_wall_door
interaction.destructible.wooden_barricade
```

ID 충돌 시 카탈로그 컴파일러가 해당 프리팹을 비활성화하고 진단을 표시한다.

---

## 3. 원본 모델에 요구하지 않는 것

제작자는 원본 모델에 다음을 넣지 않는다.

```text
Attribute
BoolValue
IntValue
NumberValue
StringValue
ObjectValue
Script
LocalScript
ModuleScript
RemoteEvent
RemoteFunction
CollectionService Tag
PrimaryPart
특수 이름의 Attachment
```

상태 모델의 Pivot과 구성요소 이름만으로 컴파일한다.

원본 모델에 우연히 Script나 Remote가 포함되어 있으면 실행하지 않으며 카탈로그 검사에서 경고 또는 오류로 표시한다.

```text
PREFAB_EXECUTABLE_CONTENT_IGNORED
```

원본은 시각 에셋일 뿐 규칙 코드가 아니다.

---

## 4. 상태 폴더 규칙

프리팹은 최소 두 개의 상태 모델을 가진다.

```text
1
2
```

다중 상태는 연속된 양의 정수 이름을 사용한다.

```text
1
2
3
4
```

허용하지 않는 예:

```text
Closed
Open
Damaged

1
3

01
02
```

숫자 이름을 사용하는 이유:

- 제작자가 상태 이름을 규칙 enum과 맞출 필요가 없다.
- 카테고리 기본 프로필이 상태 의미를 자동 제안할 수 있다.
- Generic 상태 전환 엔진이 모든 프리팹에 동일하게 작동한다.
- 상태 의미를 장면 인스턴스마다 다르게 매핑할 수 있다.

---

## 5. 상태 모델 구성요소 대응

상태 모델은 같은 구성요소 계층과 이름을 가져야 한다.

```text
1
├─ Frame
├─ MovingPart
└─ Indicator

2
├─ Frame
├─ MovingPart
└─ Indicator
```

구성요소 대응 키는 상태 모델 루트에서의 상대 경로다.

```text
Frame
MovingPart
Indicator
```

중첩 구조도 지원한다.

```text
1/Mechanism/GearA
↔
2/Mechanism/GearA
```

구성요소 배열 순서, Roblox 내부 참조 순서와 생성 순서는 사용하지 않는다.

### 5.1 V1 일치 규칙

자동 상태 Tween에 참여하는 구성요소는 모든 상태에 존재해야 한다.

```text
상태 1에만 존재
상태 2에는 없음
→ 자동 Tween 대상에서 오류
```

나타나거나 사라지는 요소는 모든 상태에 두고 다음 속성으로 표현한다.

```text
Transparency
Size
Enabled
Brightness
ParticleEmitter.Enabled
```

이 규칙은 제작 오류를 빠르게 발견하고 런타임에 부품을 생성·삭제하는 복잡성을 피하기 위한 것이다.

---

## 6. 상태 스냅샷 컴파일

각 상태 모델은 자신의 Pivot을 기준으로 상대 스냅샷으로 변환된다.

```text
StateSnapshot
├─ stateId
├─ componentSnapshots[]
├─ bounds
├─ pivotProfile
└─ diagnostics
```

구성요소 스냅샷:

```text
ComponentStateSnapshot
├─ componentPath
├─ className
├─ relativeCFrame
├─ size?
├─ color?
├─ transparency?
├─ material?
├─ collisionFlags?
├─ lightProperties?
├─ emitterProperties?
└─ supportedProperties
```

Studio에서 상태 `1`과 `2`를 서로 떨어뜨려 놓아도 무관하다.

```text
상태 모델의 Workspace 절대 위치
→ 사용하지 않음

상태 모델 Pivot 기준 상대 위치
→ 사용
```

장면에는 상태 `1` 기반의 Live Model 하나만 생성한다. 다른 상태 모델은 목표 스냅샷 데이터로만 사용한다.

---

## 7. 지원하는 상태 속성

초기 Tween 가능 속성:

```text
BasePart.CFrame
BasePart.Size
BasePart.Color
BasePart.Transparency
Attachment.CFrame
Light.Color
Light.Brightness
Light.Range
Light.Angle
Decal.Color3
Decal.Transparency
Texture.Color3
Texture.Transparency
```

초기 단계 전환 속성:

```text
BasePart.CanCollide
BasePart.CanQuery
BasePart.CanTouch
BasePart.Material
Light.Enabled
ParticleEmitter.Enabled
Trail.Enabled
Beam.Enabled
```

단계 전환 시점:

```text
transition_start
transition_midpoint
transition_end
```

기본값:

```text
CanCollide
CanQuery
CanTouch
→ transition_end
```

문이 완전히 열리기 전에 통과 가능해지는 문제를 방지하기 위해서다. 배치 후 인스펙터에서 전환 시점을 바꿀 수 있다.

---

## 8. 공통 SceneObjectInstance

세 카테고리는 공통 장면 인스턴스를 사용한다.

```text
SceneObjectInstance
├─ sceneObjectId
├─ prefabId
├─ category
├─ placementTransform
├─ visualStateId
├─ worldRuleState
├─ interactionProfile
├─ perceptionProfile?
├─ durabilityState?
├─ triggerState?
├─ links[]
├─ instanceOverrides
├─ prefabVersion
└─ revision
```

원본 프리팹과 배치된 인스턴스를 분리한다.

```text
PrefabDefinition
≠ SceneObjectInstance
```

같은 SpikePlate 프리팹을 여러 번 배치해도 각각 다른 감지 DC, 피해, 발동 조건과 현재 상태를 가질 수 있다.

---

## 9. 카테고리 자동 인식

프리팹이 위치한 카테고리 폴더가 기본 프로필을 결정한다.

```text
Trap
→ TrapSceneObjectProfile

SecretDoor
→ SecretPassageSceneObjectProfile

Destructible
→ DestructibleSceneObjectProfile
```

카테고리는 원본 프리팹에 Attribute로 저장하지 않는다.

프리팹을 다른 카테고리 폴더로 이동한 뒤 카탈로그를 갱신하면 새 카테고리로 컴파일된다.

이미 장면에 배치된 인스턴스는 기존 prefabVersion을 유지하며 DM이 명시적으로 업데이트해야 한다.

---

# 함정

## 10. 함정의 논리 상태

```text
TrapWorldState
├─ armed
├─ triggered
├─ disabled
├─ resetting
└─ inactive
```

시각 상태와 논리 상태는 직접 같은 값이 아니다.

```text
armed
→ VisualState 1

triggered
→ VisualState 2

disabled
→ VisualState 3
```

위 매핑은 기본 제안일 뿐 배치 후 변경 가능하다.

상태가 두 개인 경우 기본 매핑:

```text
armed → 1
triggered → 2
disabled → 1
```

상태가 세 개인 경우:

```text
armed → 1
triggered → 2
disabled → 3
```

DM은 `disabled`를 상태 1과 동일한 외형으로 유지하거나 별도 상태 3으로 표현할 수 있다.

---

## 11. 함정 인스턴스 데이터

```text
TrapSceneObjectProfile
├─ detectionProfile
├─ triggerPolicy
├─ disableProfile
├─ effectRecipeBinding
├─ repeatPolicy
├─ resetPolicy
├─ clueProfile
├─ visualStateMap
└─ defaultInteractionProfile
```

런타임 상태:

```text
TrapRuntimeState
├─ armedState
├─ timesTriggered
├─ lastTriggeredAt
├─ currentResetDeadline?
├─ detectedByScopes[]
├─ disabledByActorId?
└─ revision
```

---

## 12. 배치 직후 자동 생성

Trap 프리팹을 배치하면 시스템이 다음 후보를 자동 생성한다.

```text
TriggerVolume
→ 상태 1 모델의 바닥 경계 기준

InteractionVolume
→ 모델 전체 경계보다 약간 크게

DetectionPoint
→ 모델 경계 중심 또는 표면 중심

기본 상태
→ armed

기본 시각 상태
→ 1
```

자동 생성 결과는 장면 인스펙터에서 즉시 수정할 수 있다.

### 12.1 빠른 함정 설정 카드

배치 직후 선택하면 우측 인스펙터에 다음 카드가 표시된다.

```text
[함정 종류]
압력판 / 접촉 / 상호작용 / 신호 / 타이머

[탐지]
자동 / 수동 지각 DC / 조사 DC / 항상 보임

[해제]
불가 / 도구 판정 / 능력 판정 / 연결 레버

[효과]
피해 / 상태 / 강제 이동 / 연결 오브젝트 / Recipe 선택

[반복]
1회 / 매번 / 재장전 / 수동 초기화
```

기본 프리셋을 선택하면 나머지 값이 채워진다.

---

## 13. TriggerPolicy

```text
TrapTriggerPolicy
├─ triggerKind
├─ triggerVolumeId?
├─ eligibleActorPredicate
├─ requiredWorldState
├─ triggerTiming
├─ debouncePolicy
├─ linkedSignal?
└─ revalidationPolicy
```

초기 triggerKind:

```text
actor_entered_volume
actor_left_volume
object_interacted
object_opened
object_damaged
linked_signal
round_started
timer_elapsed
manual_dm
```

### 13.1 사건 기반 평가

함정은 매 프레임 토큰 위치를 순회하지 않는다.

```text
토큰 이동 명령 확정
→ 이동 경로와 TriggerVolume 교차 검사
→ TrapTriggerCandidate 생성
→ 현재 상태와 조건 재검증
→ 발동
```

토큰이 순간이동한 경우도 이동 실행이 생성한 의미 있는 위치 전이 사건을 사용한다.

### 13.2 이동 경로 교차

압력판은 최종 위치만 확인하지 않는다.

```text
시작 위치
+ 확정 이동 경로
+ TriggerVolume
→ 경로 교차 여부
```

함정을 빠르게 지나가도 발동할 수 있다.

---

## 14. 함정 탐지

함정의 존재와 위치는 ADR-0036의 관찰자별 PerceptionRelation을 사용한다.

```text
observer
+ trap perception profile
+ passive perception
+ active search result
+ lighting and senses
+ Feature·Feat modifiers
→ trap perception relation
```

함정 인식 단계 예시:

```text
unaware
clue_detected
approximate_location_known
exact_location_known
fully_understood
```

각 단계는 다른 정보를 공개할 수 있다.

```text
clue_detected
→ 바닥에 이상한 틈이 있다는 설명

exact_location_known
→ 함정 위치 표시

fully_understood
→ 발동 방식과 해제 상호작용 표시
```

### 14.1 발견 공유 범위

배치 후 설정:

```text
individual
→ 발견한 Actor 또는 플레이어만 앎

party_shared
→ 파티에 즉시 공유

dm_prompted_share
→ DM이 공유 여부 선택
```

기본은 캠페인 설정을 따른다.

### 14.2 클라이언트 복제

감지하지 못한 플레이어에게 다음을 보내지 않는다.

```text
Trap sceneObjectId
TriggerVolume
Detection DC
EffectRecipe
Interaction prompt
Hidden visual marker
```

맵 모델 자체에 함정이 시각적으로 포함되어 있어 숨길 수 없는 경우는 `always_visible_clue`로 처리하고, 규칙 정보만 감춘다.

---

## 15. 능동 수색

```text
Search Action
→ 영역 또는 오브젝트 선택
→ Perception/Investigation 실행
→ 주사위 공개
→ DetectionOutcome
→ 관찰자별 상태 갱신
```

한 번 실패했다고 영구적으로 탐지 불가능해지지 않는다. 재시도 정책은 규칙 세트와 DM 설정이 결정한다.

```text
retry_allowed
retry_after_context_change
once_per_actor
once_per_party
manual_dm
```

---

## 16. 함정 해제

```text
DisableTrapExecution
├─ actorId
├─ trapObjectId
├─ actionCost
├─ toolRequirement?
├─ checkProfile
├─ failureOutcome
├─ successState
└─ revisionSnapshot
```

흐름:

```text
해제 선택
→ 거리·인지·도구·행동 경제 검증
→ 필요한 판정 굴림
→ 결과 공개
→ 성공 또는 실패 EffectRecipe
→ 함정 상태 확정
```

실패 결과 예시:

```text
no_change
trigger_trap
increase_dc
consume_tool_resource
partial_disable
```

자유 코드가 아니라 등록된 결과 정책과 EffectRecipe를 사용한다.

---

## 17. 함정 발동

```text
TrapTriggerCandidate
→ 서버 재검증
→ TrapTriggered RuleEvent
→ 발동 VisualState 전환
→ EffectRecipe 실행
→ 연결 신호 발행
→ 반복·재설정 정책 적용
```

시각 Tween이 끝날 때까지 피해 확정을 무조건 지연할 필요는 없다. 각 함정 프로필이 효과 시점을 지정한다.

```text
effect_at_transition_start
effect_at_transition_marker
effect_at_transition_end
```

예:

```text
화살 발사기
→ 시작 시 장치 움직임
→ 중간 marker에서 공격 굴림

낙하 바닥
→ 전환 시작 시 바닥 열림
→ 끝 시 추락 위치 확정
```

---

## 18. 함정 EffectRecipe

함정은 기존 EffectRecipe를 사용한다.

초기 템플릿:

```text
trap.attack_single_target
trap.save_for_half_damage
trap.area_damage
trap.apply_condition
trap.forced_movement
trap.drop_or_fall
trap.spawn_hazard
trap.signal_only
```

배치 인스펙터에서 템플릿을 선택하고 안전한 파라미터를 입력한다.

```text
피해 주사위
피해 유형
내성 능력치
DC
범위
지속 시간
상태 ID
```

원본 모델에는 Recipe ID도 넣지 않는다.

---

## 19. 반복과 재설정

```text
TrapRepeatPolicy
├─ once
├─ every_eligible_entry
├─ once_per_round
├─ charges
├─ reset_after_game_time
└─ manual_reset
```

```text
TrapResetPolicy
├─ resetDelay?
├─ visualResetState
├─ requireNoActorInVolume
├─ rechargeResource?
└─ linkedResetSignal?
```

게임 시간 재설정은 EffectInstance 또는 예약 사건을 사용하며 실시간 대기 루프를 만들지 않는다.

---

# 비밀문

## 20. 비밀문의 상태 분리

비밀문은 두 종류의 상태를 가진다.

```text
세계 상태
→ 닫힘, 열림, 잠김, 막힘

관찰자 인식 상태
→ 존재를 아는가, 위치를 아는가, 구조를 이해하는가
```

```text
SecretPassageWorldState
├─ closed
├─ open
├─ locked
├─ blocked
└─ revision
```

```text
SecretPassagePerceptionState
├─ unaware
├─ clue_detected
├─ location_known
└─ fully_revealed
```

같은 문은 월드에서 하나의 실제 열린 상태만 가진다. 발견 여부만 관찰자마다 다르다.

---

## 21. 비밀문 상태 자동 매핑

상태 모델이 두 개인 경우:

```text
1 = concealed_closed
2 = open
```

상태 모델이 세 개인 경우:

```text
1 = concealed_closed
2 = revealed_closed
3 = open
```

상태 모델이 네 개인 경우 자동 제안:

```text
1 = concealed_closed
2 = revealed_closed
3 = open
4 = blocked_or_destroyed
```

DM은 인스펙터에서 의미를 다시 매핑할 수 있다.

---

## 22. 비밀문 배치 후 자동 생성

```text
InteractionVolume
→ 문 경계 앞뒤에 생성

MovementBlocker
→ 닫힌 상태 경계에서 생성

VisionBlocker
→ 닫힌 상태 경계에서 생성

EffectBlocker
→ 닫힌 상태 경계에서 생성

DetectionPoint
→ 문 표면 중심
```

각 볼륨은 자동 후보이며 인스펙터에서 수정할 수 있다.

문의 열린 상태 스냅샷에서 통로 폭을 추정하여 이동 연결 후보를 생성할 수 있다.

```text
닫힌 상태
→ surface connection disabled

열린 상태
→ surface connection enabled
```

자동 연결이 불확실하면 DM 검토 항목으로 남긴다.

---

## 23. 비밀문 발견

```text
Passive Detection Event
또는
Search Action
→ DetectionOutcome
→ PerceptionRelation 갱신
```

발견했다고 즉시 VisualState 2로 전환할지는 표시 정책이 결정한다.

```text
observer_overlay_only
→ 발견한 플레이어에게만 윤곽 또는 상호작용 표시
→ 월드 모델은 상태 1 유지

world_reveal
→ 월드 VisualState를 revealed_closed로 전환
→ 모든 플레이어가 물리적 표시 변화를 볼 수 있음

dm_choice
→ DM에게 공개 전환 여부 제안
```

기본은 `observer_overlay_only`다. 다른 플레이어에게 비밀문의 존재가 자동 노출되는 것을 막는다.

### 23.1 발견된 플레이어 UI

```text
벽 표면 윤곽
상호작용 아이콘
"비밀문" 또는 DM이 정한 이름
마지막 탐지 출처
```

미발견 플레이어에게는 표시하지 않는다.

---

## 24. 비밀문 열기

비밀문을 발견한 뒤 열기 방법은 일반 상호작용 오브젝트와 동일하다.

```text
직접 열기
잠금 해제
레버 링크
퍼즐 링크
강제 개방
파괴
주문 효과
```

열림 상태 확정 시:

```text
VisualState 전환
→ MovementBlocker 비활성화
→ VisionBlocker 비활성화 또는 수정
→ EffectBlocker 비활성화 또는 수정
→ 이동 의미 레이어 부분 갱신
→ SceneObjectStateChanged 이벤트
```

---

## 25. 가짜 문과 일방향 통로

같은 프로필로 다음을 지원한다.

```text
fake_secret_door
→ 발견되지만 열리지 않음

one_way_secret_door
→ 특정 방향 또는 특정 Actor만 상호작용

linked_only
→ 직접 상호작용 불가, 링크 신호로만 열림

teleport_passage
→ 열림 후 다른 SceneAnchor로 이동
```

이 차이는 원본 모델이 아니라 배치된 인스턴스 설정이다.

---

# 파괴 가능한 오브젝트

## 26. ObjectDurabilityState

파괴 가능한 오브젝트는 Actor의 HP 0·죽음 내성 규칙을 사용하지 않는다.

```text
ObjectDurabilityState
├─ currentHitPoints
├─ maximumHitPoints
├─ temporaryDurability?
├─ defensePolicy
├─ damageThreshold?
├─ resistances[]
├─ immunities[]
├─ vulnerabilities[]
├─ stateThresholds[]
├─ destroyed
├─ repairState?
└─ revision
```

최대 HP는 장면 인스턴스 설정으로 저장한다. 원본 모델에는 HP Attribute를 넣지 않는다.

---

## 27. 배치 직후 파괴물 기본값

Destructible 프리팹을 배치하면 카테고리 프리셋을 선택할 수 있다.

```text
약한 목재
단단한 목재
석재
금속
마법 구조물
사용자 정의
```

프리셋은 다음 후보를 채운다.

```text
최대 HP
방어 정책
피해 임계치
저항·면역
손상 상태 임계치
파괴 시 충돌 정책
수리 가능 여부
```

프리셋은 규칙 데이터이며 원본 모델을 변경하지 않는다.

---

## 28. 오브젝트 대상 지정

공격과 주문은 TargetingPlan에 오브젝트 대상 가능 여부를 명시한다.

```text
TargetCategory
├─ creature
├─ object
├─ point
└─ scene_effect
```

오브젝트 공격 흐름:

```text
오브젝트 선택
→ 공격이 object 대상을 허용하는지 검증
→ 사거리·시야·효과선 검증
→ 공격 또는 내성 굴림
→ 피해 해결
→ ObjectDurabilityState 확정
```

모든 주문이 오브젝트를 대상으로 할 수 있다고 가정하지 않는다. 각 ActionCapability와 EffectRecipe가 허용 대상 범주를 가진다.

---

## 29. 방어 정책

```text
ObjectDefensePolicy
├─ fixedArmorClass
├─ automaticHit
├─ savingThrowProfile?
├─ attackModeRestrictions[]
└─ contextualOverrides[]
```

예:

```text
일반 문
→ fixedArmorClass

넓은 벽
→ automaticHit, 단 유효 피해 유형 필요

흔들리는 사슬
→ fixedArmorClass + 원거리 공격 허용

마법 수정
→ 특정 내성 굴림 또는 특수 Recipe
```

---

## 30. 피해 해결

오브젝트 피해도 공통 피해 파이프라인을 사용한다.

```text
PendingDamage
→ 피해 유형별 수정
→ 저항·면역·취약성
→ damage threshold
→ 최종 내구도 피해
→ DurabilityTransitionEvaluation
```

### 30.1 피해 임계치

```text
finalDamage < damageThreshold
→ 내구도 감소 없음

finalDamage >= damageThreshold
→ 전체 최종 피해 적용
```

정확한 규칙은 ruleset policy로 관리한다.

### 30.2 피해 출처 태그

Feature, Feat와 몬스터 특성이 특정 오브젝트 피해를 수정할 수 있도록 피해 문맥에 태그를 보존한다.

```text
weapon
spell
siege
critical
bludgeoning
fire
magical
structure_damage
```

---

## 31. 손상 단계와 VisualState

상태 모델이 두 개인 경우 기본:

```text
HP > 0
→ VisualState 1

HP = 0
→ VisualState 2
```

상태 모델이 세 개인 경우 기본:

```text
HP 비율 > 50%
→ VisualState 1

0% < HP 비율 <= 50%
→ VisualState 2

HP = 0
→ VisualState 3
```

상태 모델이 네 개인 경우 기본:

```text
> 66%
→ 1

> 33%
→ 2

> 0%
→ 3

0%
→ 4
```

DM은 임계치를 직접 수정할 수 있다.

```text
DurabilityStateThreshold
├─ conditionExpression
├─ targetVisualStateId
├─ transitionProfile
└─ sideEffects[]
```

손상 단계 변화는 피해 한 번당 한 번 평가하며, 여러 임계치를 넘으면 최종 상태로 직접 전환하거나 단계별 연출을 실행하는 정책을 선택할 수 있다.

```text
jump_to_final
play_intermediate_fast
play_all_states
```

기본은 `jump_to_final`이다.

---

## 32. 파괴 상태

파괴 시 다음을 별도로 결정한다.

```text
visual transition
collision state
movement blocker state
vision blocker state
cover state
interaction availability
linked signals
loot or debris policy
```

파괴되었다고 SceneObjectInstance를 삭제하지 않는다.

```text
SceneObjectInstance
├─ destroyed = true
├─ currentHitPoints = 0
├─ VisualState = destroyed state
└─ repair information retained
```

### 32.1 물리 잔해

무제한 물리 파편을 자동 생성하지 않는다.

초기 지원:

```text
visual_state_only
registered_debris_vfx
registered_static_debris_prefab
none
```

물리 잔해가 이동·시야 판정에 참여하려면 별도 등록된 SceneObject로 생성한다.

---

## 33. 엄폐와 파괴

파괴 가능한 오브젝트는 CoverProvider를 가질 수 있다.

```text
CoverProvider
├─ coverVolume
├─ coverGrade
├─ activeVisualStates[]
└─ destroyedPolicy
```

예:

```text
VisualState 1
→ 큰 엄폐

VisualState 2
→ 작은 엄폐

VisualState 3
→ 엄폐 없음
```

상태 전환 시 해당 지역의 엄폐 인덱스만 부분 갱신한다.

---

## 34. 수리

수리 가능 오브젝트는 ActionCapability로 처리한다.

```text
RepairObjectExecution
├─ actorId
├─ objectId
├─ actionCost
├─ toolRequirement?
├─ resourceCost?
├─ checkProfile?
├─ repairAmount
└─ maximumRepairState
```

수리 결과:

```text
내구도 회복
→ 손상 임계치 재평가
→ VisualState 역전환
→ 충돌·엄폐·시야 데이터 갱신
```

한 번 파괴되면 수리 불가인 오브젝트는 `repairPolicy = none`으로 설정한다.

---

# 장면 오브젝트 링크

## 35. 링크의 목적

복잡한 장치는 원본 프리팹에 ObjectValue를 넣지 않고 배치 후 장면에서 연결한다.

예:

```text
압력판
→ 화살 발사기

레버
→ 함정 해제

마법 수정 파괴
→ 비밀문 열림

상자 열림
→ 가스 함정 발동

기둥 파괴
→ 천장 낙하 함정 발동
```

---

## 36. SceneObjectLink

```text
SceneObjectLink
├─ linkId
├─ sourceObjectId
├─ signalType
├─ targetObjectId
├─ commandType
├─ commandArguments
├─ conditions[]
├─ delayPolicy?
├─ oncePolicy?
└─ revision
```

초기 신호:

```text
on_interacted
on_actor_entered
on_actor_left
on_detected
on_disabled
on_triggered
on_state_entered
on_state_exited
on_damaged
on_destroyed
on_repaired
on_opened
on_closed
on_timer
on_dm_signal
```

초기 명령:

```text
set_state
advance_state
previous_state
toggle_state
arm
disarm
reset
trigger_effect
reveal
hide
lock
unlock
open
close
damage_object
repair_object
spawn_registered_object
emit_signal
```

---

## 37. 링크 편집 UI

장면 편집기 흐름:

```text
소스 오브젝트 선택
→ 연결 만들기
→ 발생 신호 선택
→ 대상 오브젝트 클릭
→ 대상 명령 선택
→ 미리보기
→ 저장
```

빠른 연결 예:

```text
레버 선택
→ 연결 만들기
→ 문 클릭
→ "레버 상태를 문 상태와 동기화"
```

자동 생성 링크:

```text
lever state 1 → door state 1
lever state 2 → door state 2
```

복잡한 조건은 고급 링크 패널에서 수정한다.

---

## 38. 링크 실행

```text
SceneObjectSignal
→ LinkIndex에서 대상 링크 조회
→ 조건 평가
→ SceneObjectCommand 생성
→ 대상 revision 재검증
→ 명령 실행
→ 후속 신호 발행
```

순환 링크 보호:

```text
executionChainId
visitedLinkIds
maximumLinkDepth
maximumCommandsPerChain
```

같은 레버와 문이 서로를 무한히 토글하지 못하게 한다.

---

# Feature·Feat·주문 호환

## 39. RulePointCatalog

함정, 비밀문과 오브젝트 규칙은 다음 RulePoint를 제공한다.

```text
perception.trap_detection
perception.secret_passage_detection
interaction.trap_disable
interaction.secret_passage_open
interaction.force_object
interaction.repair_object
trap.trigger_avoidance
trap.effect_saving_throw
trap.damage_resolution
object.attack_roll
object.damage_resolution
object.damage_threshold
object.durability_transition
object.cover_evaluation
```

새 Feature와 Feat는 특정 ID 분기 없이 이 지점을 수정한다.

---

## 40. Capability 예시

### 40.1 함정 탐지 보정

```text
ContextModifierCapability
├─ rulePoint: perception.trap_detection
├─ predicate: trap tag matches
└─ modifier: advantage or bonus
```

### 40.2 함정 피해 감소

```text
ContextModifierCapability
├─ rulePoint: trap.damage_resolution
├─ predicate: source is detected trap
└─ modifier: damage reduction policy
```

### 40.3 특정 피해로 구조물 피해 증가

```text
ContextModifierCapability
├─ rulePoint: object.damage_resolution
├─ predicate: target has structure tag
└─ modifier: additional or multiplied damage contribution
```

### 40.4 피해 임계치 무시

```text
RuleOverrideCapability
├─ rulePoint: object.damage_threshold
├─ predicate: attack has required tag
└─ override: ignore threshold
```

### 40.5 행동 없이 함정 해제

```text
RuleOverrideCapability
├─ rulePoint: interaction.trap_disable
└─ override: action economy cost
```

### 40.6 파괴 직전 반응

```text
TriggerCapability
├─ event: ObjectWouldBeDestroyed
├─ timingWindow: before durability commit
└─ response: protective reaction
```

---

## 41. 주문 효과

주문과 마법 효과는 SceneObjectCommand 또는 일반 EffectRecipe를 통해 오브젝트에 영향을 준다.

```text
unlock object
open object
close object
damage object
repair object
reveal secret passage
disable trap
trigger trap
set visual state
```

주문 이름을 오브젝트 엔진에 하드코딩하지 않는다.

---

# 배치 후 제작 경험

## 42. 빠른 배치 흐름

### 함정

```text
1. Trap 프리팹 선택
2. 장면에 배치
3. TriggerVolume 자동 생성
4. 함정 프리셋 선택
5. EffectRecipe 선택
6. 저장
```

### 비밀문

```text
1. SecretDoor 프리팹 선택
2. 벽에 배치
3. 차단 볼륨 자동 생성
4. 감지 정책 선택
5. 열기 방식 선택
6. 저장
```

### 파괴물

```text
1. Destructible 프리팹 선택
2. 장면에 배치
3. 재질·내구도 프리셋 선택
4. 상태 임계치 확인
5. 엄폐·차단 정책 확인
6. 저장
```

기본값으로 즉시 작동하며 고급 설정은 선택 사항이어야 한다.

---

## 43. 인스펙터 구성

공통 섹션:

```text
기본 정보
상태 미리보기
상태 매핑
전환 시간과 easing
상호작용 범위
권한과 공개
링크
저장·버전
```

함정 전용:

```text
탐지
발동 범위
발동 조건
해제
효과
반복·재설정
```

비밀문 전용:

```text
발견 정책
공유 범위
열림·잠금
이동·시야 차단
표시 정책
```

파괴물 전용:

```text
HP와 방어
저항·면역
피해 임계치
손상 단계
엄폐
파괴·잔해
수리
```

---

## 44. 미리보기

편집기에서 실제 세션 상태를 변경하지 않고 미리볼 수 있다.

```text
상태 1 보기
상태 2 보기
상태 3 보기
상태 전환 재생
충돌 볼륨 보기
시야 차단 보기
TriggerVolume 보기
탐지 범위 보기
손상 임계치 테스트
링크 신호 테스트
```

DM 전용 미리보기는 플레이어 클라이언트에 복제하지 않는다.

---

## 45. 자동 검사

프리팹 검사 항목:

```text
상태 번호 연속성
최소 상태 수
상태별 구성요소 경로 일치
구성요소 클래스 일치
Pivot 유효성
지원 속성 여부
실행 가능한 Script 포함 여부
지나치게 큰 구성요소 수
지나치게 큰 상태 모델 크기
```

장면 인스턴스 검사 항목:

```text
TriggerVolume 누락
차단 볼륨 누락
잘못된 상태 매핑
존재하지 않는 EffectRecipe
끊어진 SceneObjectLink
순환 링크 위험
HP 임계치 순서 오류
탐지 DC 누락
해제 성공 상태 누락
```

오류 예:

```text
ERROR PREFAB_STATE_COMPONENT_MISSING
경로: Trap/SpikePlate/3/Mechanism/Plate
내용: 상태 1과 2에 존재하는 구성요소가 상태 3에 없습니다.
```

```text
WARNING SECRET_DOOR_BLOCKER_UNCERTAIN
내용: 열린 상태에서 통로 폭을 확정할 수 없습니다. 이동 차단 볼륨을 검토하세요.
```

---

# 서버 권위와 네트워크

## 46. 명령 검증

상호작용 요청:

```text
InteractSceneObjectRequest
├─ actorId
├─ sceneObjectId
├─ interactionId
├─ declaredToolOrItem?
├─ expectedRevision
└─ clientRequestId
```

서버 검증:

```text
제어권
거리
인지 수준
시야 또는 위치 요구
행동 경제
도구·자원
현재 오브젝트 상태
잠금·차단
revision
중복 요청
```

클라이언트는 상태 번호, 함정 성공 결과나 피해량을 직접 보낼 수 없다.

---

## 47. 상태 전환과 Tween

서버가 상태 전환을 확정하면 클라이언트에 표현 패킷을 보낸다.

```text
SceneObjectTransitionPresentation
├─ sceneObjectId
├─ fromVisualState
├─ toVisualState
├─ transitionProfileId
├─ startedAtServerTime
├─ duration
└─ revision
```

충돌과 규칙 상태는 서버가 정한 전환 marker에서 갱신한다.

클라이언트가 Tween을 완료하지 못해도 서버 규칙 진행은 멈추지 않는다.

재접속한 클라이언트는 현재 VisualState와 전환 진행도를 받아 올바른 상태로 복원한다.

---

## 48. 숨겨진 정보 복제

권한 없는 클라이언트에 숨겨야 하는 정보:

```text
함정의 존재와 정확한 위치
TriggerVolume
감지·해제 DC
EffectRecipe
비밀문 식별자와 상호작용 범위
숨겨진 링크
파괴 시 비밀 후속 효과
```

플레이어가 발견한 정보만 PerceptionRelation 수준에 맞게 복제한다.

DM 클라이언트는 편집 모드에서 모든 숨겨진 정보를 볼 수 있다.

---

# 저장과 버전

## 49. 저장 데이터

```text
SavedSceneObjectInstance
├─ sceneObjectId
├─ prefabId
├─ prefabVersion
├─ category
├─ placementTransform
├─ visualStateId
├─ worldRuleState
├─ interactionProfileOverrides
├─ triggerState?
├─ durabilityState?
├─ perceptionSharingPolicy?
├─ links[]
├─ generatedVolumeOverrides[]
└─ revision
```

관찰자별 PerceptionRelation은 캠페인 저장 정책에 따라 별도 저장한다.

```text
persistent discovery
session-only discovery
scene-reset discovery
```

---

## 50. 프리팹 업데이트

원본 프리팹을 수정해도 장면 인스턴스를 자동으로 강제 변경하지 않는다.

DM 선택:

```text
이후 배치부터 새 버전 사용
선택한 인스턴스만 업데이트
모든 인스턴스 업데이트
현재 상태와 HP 유지
상태 초기화 후 업데이트
```

업데이트 시 구성요소 경로가 바뀌면 마이그레이션 진단을 보여준다.

---

# 성능

## 51. 카탈로그 캐시

```text
서버 시작 또는 콘텐츠 갱신
→ 프리팹 스캔
→ 상태 스냅샷 컴파일
→ 진단
→ 캐시
```

장면 인스턴스마다 ReplicatedStorage 상태 모델 전체를 다시 분석하지 않는다.

---

## 52. 공간 인덱스

별도 인덱스:

```text
InteractionVolumeIndex
TriggerVolumeIndex
VisionBlockerIndex
MovementBlockerIndex
CoverProviderIndex
DestructibleTargetIndex
```

오브젝트 상태가 바뀌면 영향받는 인덱스 항목만 갱신한다.

---

## 53. 사건 기반 처리

금지:

```text
모든 함정이 매 프레임 모든 Actor 위치 검사
모든 파괴물이 매 프레임 HP 임계치 검사
모든 비밀문이 매 프레임 수동 지각 재계산
```

사용:

```text
이동 확정
상호작용 확정
조명·감각 변화
수색 실행
피해 확정
상태 전환
게임 시간 사건
장면 링크 신호
```

---

# 테스트

## 54. 프리팹 컴파일 테스트

- Attribute와 Value가 없는 프리팹이 정상 등록된다.
- 상태 `1`, `2`, `3`이 올바르게 컴파일된다.
- 상태 모델의 절대 위치 차이가 Live Model 위치에 영향을 주지 않는다.
- 동일 상대 경로 구성요소가 올바르게 대응된다.
- 누락된 구성요소가 진단된다.
- Script가 실행되지 않는다.
- 잘못된 프리팹 하나가 전체 카탈로그를 중단하지 않는다.

## 55. 함정 테스트

- 배치 직후 TriggerVolume이 생성된다.
- 경로가 압력판을 통과하면 최종 위치가 밖이어도 발동한다.
- 비무장 상태에서는 발동하지 않는다.
- 감지하지 못한 플레이어에게 함정 정보가 복제되지 않는다.
- 개인 발견과 파티 공유가 구분된다.
- 해제 성공·실패·발동 실패 결과가 올바르게 처리된다.
- EffectRecipe가 한 번만 실행된다.
- 반복·재설정 정책이 작동한다.
- 링크 순환이 제한된다.

## 56. 비밀문 테스트

- 감지 전 상호작용 프롬프트가 보이지 않는다.
- 한 플레이어만 발견할 수 있다.
- 발견 상태와 실제 열림 상태가 분리된다.
- 열린 상태에서 이동·시야·효과선 차단이 갱신된다.
- 두 상태와 세 상태 프리팹의 기본 매핑이 다르게 적용된다.
- 재접속 후 발견 정보와 문 상태가 복구된다.

## 57. 파괴물 테스트

- 공격이 object 대상을 허용할 때만 선택할 수 있다.
- 저항·면역·피해 임계치가 적용된다.
- HP 임계치에 따라 상태가 전환된다.
- 파괴 시 SceneObject 데이터가 삭제되지 않는다.
- 엄폐와 이동 차단이 부분 갱신된다.
- 수리 시 이전 상태로 복귀한다.
- 동일 피해 요청 재전송으로 HP가 중복 감소하지 않는다.

## 58. Feature·Feat 테스트

- 함정 탐지 보정이 다른 지각 판정에 잘못 적용되지 않는다.
- 함정 피해 감소가 일반 공격 피해를 감소시키지 않는다.
- 구조물 피해 증가가 생물 대상에 적용되지 않는다.
- 오브젝트 피해 임계치 무시가 적격 공격에만 적용된다.
- 상호작용 행동 비용 수정이 다른 ActionCapability에 영향을 주지 않는다.

---

# 구현 모듈 경계

## 59. 서버 모듈

```text
InteractionPrefabCatalog
StateSnapshotCompiler
SceneObjectInstanceService
SceneObjectTransitionService
TrapService
TrapDetectionService
TrapTriggerService
SecretPassageService
ObjectDurabilityService
SceneObjectLinkService
SceneObjectCommandService
SceneObjectPersistenceService
```

## 60. 공유 모듈

```text
SceneObjectTypes
InteractionProfileTypes
StateSnapshotTypes
TrapProfileTypes
SecretPassageTypes
DurabilityTypes
SceneObjectLinkTypes
SceneObjectRulePointCatalog
```

## 61. 클라이언트 모듈

```text
SceneObjectPresentationController
StateTweenController
InteractionPromptController
TrapDetectionPresentation
SecretPassageOverlayController
DestructibleStatePresentation
SceneObjectInspectorPanel
SceneObjectLinkEditor
PrefabValidationPanel
```

---

## 62. 최종 제작 기준

새 함정, 비밀문 또는 파괴 오브젝트를 추가하는 기본 절차는 다음보다 복잡해지면 안 된다.

```text
1. 상태별 모델을 만든다.
2. 같은 구성요소 이름과 계층을 유지한다.
3. 1, 2, 3 폴더에 넣는다.
4. 올바른 카테고리 폴더에 넣는다.
5. 장면에 배치한다.
6. 자동 프로필을 확인하고 필요한 값만 수정한다.
```

다음 작업은 별도 고급 기능이다.

```text
복잡한 EffectRecipe 연결
여러 오브젝트 링크
사용자 정의 탐지·해제 정책
특수 파괴·수리 규칙
```

기본 모델 제작자는 이 고급 기능을 몰라도 작동 가능한 오브젝트를 만들 수 있어야 한다.
