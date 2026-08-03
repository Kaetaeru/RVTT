# 31. 무설정 상호작용 프리팹과 상태 전환 모델

- 상태: 초안
- 작성일: 2026-08-03
- 관련 문서:
  - [`06. 인게임 장면 편집기 도구`](../../../scene/ingame-scene-editor-tools.md)
  - [`07. 장면 편집 상호작용과 레이아웃`](../../../../ui/scene-editor/scene-editor-interaction-and-layout.md)
  - [`09. 장면 편집 도구 모듈 구조`](../../../../architecture/scene-editor-tool-module-architecture.md)
  - [`22. EffectRecipe와 효과 해결·확정 모델`](../../../../architecture/effect-recipe-resolution-and-commit-model.md)
  - [`29. 수동 Fog of War와 선택형 Assist 모델`](../../../perception/manual-fog-of-war-and-optional-assist-model.md)
  - [`30. 시야·감각·은신·탐지 모델`](../../../perception/visibility-senses-stealth-and-detection-model.md)
  - [`ADR-0037`](../../../../decisions/ADR-0037-zero-metadata-interaction-prefabs-and-state-snapshot-transitions.md)

## 1. 문서 목적

이 문서는 문, 레버, 상자와 기타 상태형 장면 오브젝트를 최소한의 제작 작업으로 RVTT에 추가하는 구조를 정의한다.

가장 중요한 제작 경험은 다음과 같다.

```text
ReplicatedStorage에 모델 추가
→ Attribute 없음
→ ValueBase 없음
→ Script 없음
→ 상태 모델 1과 2만 구성
→ 장면 편집기에서 바로 배치
```

대상:

- 상호작용 프리팹 폴더 규칙
- 상태 `1`과 `2`의 구성요소 대응
- 위치·회전·크기·색상 Tween
- 문·레버·상자의 기본 프로필
- 배치 후 자동 바인딩
- 배치 후 선택적 Attribute와 인스턴스 override
- 상호작용 범위와 프롬프트 자동 생성
- 문과 이동·시야 차단 상태
- 레버와 다른 장면 오브젝트 연결
- 상자와 전리품 컨테이너 연결
- 검증, 저장, 복구와 성능

---

## 2. 제작 폴더 구조

기본 위치:

```text
ReplicatedStorage
└─ RVTTContent
   └─ InteractionObjects
```

분류와 프리팹 구조:

```text
InteractionObjects
├─ Lever
│  ├─ IronLever
│  │  ├─ 1
│  │  └─ 2
│  └─ StoneLever
│     ├─ 1
│     └─ 2
├─ Door
│  ├─ OakDoor
│  │  ├─ 1
│  │  └─ 2
│  └─ Portcullis
│     ├─ 1
│     └─ 2
└─ Chest
   ├─ WoodenChest
   │  ├─ 1
   │  └─ 2
   └─ IronChest
      ├─ 1
      └─ 2
```

### 의미

```text
분류 폴더 이름
→ 기본 상호작용 프로필

프리팹 폴더 이름
→ 프리팹 ID와 에셋 목록 표시 이름

1
→ 기본·초기 상태

2
→ 작동 후 목표 상태
```

프리팹 원본에는 다음 항목을 요구하지 않는다.

- Attribute
- BoolValue, StringValue, NumberValue 등 ValueBase
- CollectionService 태그
- Script 또는 LocalScript
- RemoteEvent 또는 RemoteFunction
- 특수 이름의 PrimaryPart
- 특수 Attachment

`1`과 `2` 자체는 `Model`을 권장하지만, 컴파일러가 하나의 루트로 취급할 수 있는 `Folder`도 허용할 수 있다. 초기 구현의 표준은 `Model`이다.

---

## 3. 기본 제작 절차

레버를 추가하는 예시:

```text
1. InteractionObjects/Lever 아래 IronLever 폴더 생성
2. IronLever 안에 Model `1` 생성
3. Model `1`을 복제해 Model `2` 생성
4. Model `2`에서 손잡이 위치와 회전 변경
5. 필요하면 색상, 투명도와 조명 상태 변경
6. 장면 편집기의 Interaction Objects 목록에서 IronLever 배치
```

문과 상자도 같은 방식이다.

```text
Door/OakDoor/1
→ 닫힌 문

Door/OakDoor/2
→ 열린 문
```

```text
Chest/WoodenChest/1
→ 닫힌 뚜껑

Chest/WoodenChest/2
→ 열린 뚜껑
```

---

## 4. 구성요소 대응 규칙

상태 모델의 구성요소는 배열 순서가 아니라 **루트 아래 상대 경로**로 대응한다.

```text
1/Frame
2/Frame

1/DoorPanel
2/DoorPanel

1/Handle/Metal
2/Handle/Metal
```

### 유효 조건

- 상대 경로가 같다.
- Instance 클래스가 같다.
- 같은 부모 아래 이름이 중복되지 않는다.
- 필수 상태 모델 `1`, `2`가 모두 존재한다.

### 오류 예시

```text
1/Handle     = MeshPart
2/Handle     = Part
→ 클래스 불일치
```

```text
1/Lid/Hinge
2/Top/Hinge
→ 상대 경로 불일치
```

```text
1/Body/Part
1/Body/Part
→ 같은 부모 아래 중복 이름
```

### 오류 표시

```text
ERROR INTERACTION_COMPONENT_MISSING
프리팹: Chest/WoodenChest
경로: 2/Lid/Lock
내용: 상태 1에 존재하는 구성요소가 상태 2에 없습니다.
```

에셋 하나가 잘못되어도 전체 InteractionObjects 카탈로그를 중단하지 않는다. 해당 프리팹만 비활성화하고 다른 프리팹은 계속 사용할 수 있다.

---

## 5. 프리팹 컴파일

```text
InteractionAssetScanner
→ 분류 폴더 검색
→ 프리팹 폴더 검색
→ 상태 모델 검색
→ 구조 검증
→ 상태 스냅샷 생성
→ 구성요소 채널 생성
→ 기본 타입 프로필 결합
→ InteractionPrefabRegistry 등록
```

```text
CompiledInteractionPrefab
├─ prefabId
├─ categoryId
├─ sourcePath
├─ stateSnapshots
├─ transitionChannels
├─ defaultInteractionProfile
├─ generatedSemanticProfiles
├─ boundsProfile
├─ diagnostics
└─ contentRevision
```

컴파일러는 원본 폴더에 어떤 Instance도 추가하지 않는다.

---

## 6. 상태 스냅샷

```text
InteractionStateSnapshot
├─ stateId
├─ statePivot
├─ componentSnapshots[]
├─ bounds
├─ generatedCollisionProfile
└─ generatedPresentationProfile
```

```text
InteractionComponentSnapshot
├─ relativePath
├─ className
├─ localCFrame?
├─ size?
├─ color?
├─ transparency?
├─ continuousProperties
├─ discreteProperties
└─ extensionProperties
```

상태 모델의 실제 월드 위치는 사용하지 않는다.

```text
localCFrame
= statePivot:ToObjectSpace(component.CFrame)
```

장면에서의 목표 위치:

```text
worldTargetCFrame
= placedInstancePivot * stateLocalCFrame
```

이 방식 때문에 상태 모델 `1`과 `2`를 Studio에서 떨어뜨려 놓아도 실제 전환 결과에는 영향이 없다.

---

## 7. 배치 파이프라인

```text
DM이 프리팹 선택
→ 상태 1 고스트 표시
→ 배치 위치 확정
→ 서버가 prefabId와 위치 검증
→ 상태 1 Live Model 생성
→ InteractionInstanceBinder 실행
→ 장면 의미 데이터 생성
→ 저장 기록 생성
```

상태 `2` 모델은 Workspace에 복제하지 않는다.

### 배치 후 생성되는 정보

```text
SceneInteractionObject
├─ sceneObjectId
├─ prefabId
├─ categoryId
├─ currentStateId
├─ transitionState
├─ interactionProfile
├─ interactionVolume
├─ instanceOverrides
├─ linkedObjects
└─ revision
```

서버 저장소가 권위 원본이다.

디버깅과 Studio 탐색을 위해 Live Model 루트에 다음 Attribute를 선택적으로 미러할 수 있다.

```text
RVTT_SceneObjectId
RVTT_InteractionPrefabId
RVTT_CurrentState
```

이 Attribute는 배치 후 생성되며 `ReplicatedStorage`의 원본 프리팹에는 추가되지 않는다.

---

## 8. 자동 상호작용 범위

원본에 Attachment나 ProximityPrompt를 요구하지 않는다.

배치 시 모델의 BoundingBox를 기준으로 기본 상호작용 범위를 생성한다.

```text
GeneratedInteractionVolume
├─ 중심: 모델 경계 중심
├─ 크기: 모델 경계 + 분류별 여유 거리
├─ 접근 지점: 가장 가까운 유효 표면
└─ 최대 거리: 분류 기본값
```

분류 기본값 예시:

```text
Lever
→ 비교적 작은 범위

Door
→ 문 양쪽에서 접근 가능한 범위

Chest
→ 정면 우선 범위
```

DM은 배치 후 다음을 수정할 수 있다.

- 범위 위치
- 범위 크기
- 최대 상호작용 거리
- 상호작용 방향 제한
- 문 양쪽 허용 여부
- 특정 진영 또는 Actor만 허용

---

## 9. 상호작용 실행

```text
플레이어 E 입력
→ InteractionIntent
→ 서버가 제어권·거리·인지·상태 검증
→ 잠금과 요구 조건 검증
→ transitionId 발급
→ transitioning 상태 진입
→ Tween 시작
→ commit point
→ CurrentState 변경
→ 연결 효과 실행
→ transition 종료
```

```text
InteractionIntent
├─ actorId
├─ sceneObjectId
├─ requestedActionId
├─ expectedRevision
└─ clientIntentId
```

클라이언트는 목표 상태, 최종 위치와 성공 여부를 직접 전송하지 않는다.

---

## 10. Tween 채널

각 상대 경로 구성요소마다 독립 전환 채널을 만든다.

```text
TransitionChannel
├─ componentPath
├─ propertyId
├─ sourceValue
├─ targetValue
├─ interpolationAdapter
├─ easingProfile
└─ applicationPhase
```

### 연속 Tween

초기 지원:

```text
BasePart.CFrame
BasePart.Size
BasePart.Color
BasePart.Transparency
Attachment.CFrame
Light.Brightness
Light.Range
Light.Angle
Light.Color
Decal.Transparency
Decal.Color3
Texture.Transparency
Texture.Color3
```

### 불연속 전환

다음 값은 보간하지 않고 지정된 시점에 바꾼다.

```text
Material
CanCollide
CanTouch
CanQuery
CastShadow
Light.Enabled
ParticleEmitter.Enabled
Decal.Face
enum 또는 boolean 속성
```

적용 시점:

```text
transition_start
commit_point
transition_end
```

### 기본 Tween 설정

```text
Lever
→ 짧은 시간, 빠른 감속

Door
→ 중간 시간, 부드러운 가속·감속

Chest
→ 중간 시간, 열림 말단 감속
```

DM은 배치 후 Tween 시간과 easing을 바꿀 수 있다.

---

## 11. 서버 Tween 방식

초기 구현에서는 상호작용이 자주 발생하지 않는 정적 장면 오브젝트라는 전제 아래 서버 `TweenService`가 권위 모델을 전환한다.

장점:

- 문 충돌과 시각 위치가 같은 모델을 사용한다.
- 모든 클라이언트가 같은 진행 상태를 본다.
- 서버가 commit point를 정확히 관리할 수 있다.
- 별도 로컬 복제 프록시가 필요 없다.

제한:

- 매 프레임 직접 Lua 루프로 CFrame을 전송하지 않는다.
- 동시에 과도한 수의 대형 모델을 Tween하지 않도록 상한을 둔다.
- 불꽃, 먼지와 사운드 같은 순수 연출은 클라이언트에서 재생한다.

향후 대량 애니메이션이 필요할 경우 같은 스냅샷 계약을 유지한 채 클라이언트 프록시 어댑터로 교체할 수 있다.

---

## 12. 물리와 구조 제한

상호작용 프리팹은 기본적으로 장면에 고정된 구조물이다.

배치 시 Live Model의 BasePart는 서버가 Anchored 상태로 정규화할 수 있다.

초기 버전에서 다음 요소는 경고 또는 미지원으로 처리한다.

- Tween과 충돌하는 물리 Constraint
- BodyMover와 VectorForce 기반 지속 물리
- 상태 사이에서 달라지는 Bone 구조
- 상태마다 다른 MeshPart 계층
- 복잡한 Motor6D 애니메이션

```text
WARNING INTERACTION_PHYSICS_CONSTRAINT
이 프리팹은 Tween과 충돌할 수 있는 HingeConstraint를 포함합니다.
초기 구현에서는 상태 모델의 CFrame 스냅샷을 사용합니다.
```

제작자는 HingeConstraint를 직접 설정할 필요가 없다. 문의 회전도 상태 `1`과 `2`에서 문짝 CFrame만 다르게 두면 된다.

---

## 13. Lever 기본 프로필

```text
LeverInteractionProfile
├─ states: 1 ↔ 2
├─ repeatable: true
├─ promptState1: 작동
├─ promptState2: 되돌리기
├─ transitionPolicy: reject_while_transitioning
└─ outputEvent: LeverStateChanged
```

레버 자체는 어떤 문을 여는지 원본 모델에서 알 필요가 없다.

장면에 배치한 뒤 링크 도구로 연결한다.

```text
레버 선택
→ 연결 만들기
→ 문 또는 함정 선택
→ 상태 매핑 지정
```

```text
Lever state 2
→ Door target state 2

Lever state 1
→ Door target state 1
```

링크는 장면 데이터에 저장한다.

---

## 14. Door 기본 프로필

```text
DoorInteractionProfile
├─ states: 1 ↔ 2
├─ state1Meaning: closed
├─ state2Meaning: open
├─ promptState1: 열기
├─ promptState2: 닫기
├─ navigationPolicy
├─ visionPolicy
└─ lineOfEffectPolicy
```

### 시각 상태와 규칙 상태

```text
문짝 Tween
≠ 이동 차단 상태
≠ 시야 차단 상태
≠ 효과선 차단 상태
```

세 의미 상태는 commit point에서 함께 갱신한다.

### 자동 의미 데이터

초기 기본값은 상태별로 `CanCollide`가 활성화된 부품의 단순 경계를 사용하여 생성한다.

```text
state 1
→ 닫힌 문의 충돌 부품에서 blocker 생성

state 2
→ 열린 상태의 충돌 부품에서 blocker 갱신 또는 제거
```

DM은 배치 후 이동·시야·효과선 차단 볼륨을 별도로 조정할 수 있다.

### 잠금

잠금은 원본 모델 Attribute가 아니라 배치 인스턴스 설정이다.

```text
locked
requiredKeyId
pickLockCheck
breakCheck
openFromSidePolicy
```

잠긴 문은 같은 모델을 재사용하면서 장면마다 다른 열쇠와 난이도를 가질 수 있다.

---

## 15. Chest 기본 프로필

```text
ChestInteractionProfile
├─ states: 1 ↔ 2
├─ state1Meaning: closed
├─ state2Meaning: open
├─ containerBinding?
├─ locked?
├─ trapBinding?
└─ searchedState?
```

상자의 시각 상태와 내용물은 분리한다.

```text
Chest visual state
→ 뚜껑 열림·닫힘

Container state
→ 아이템 목록과 약탈 상태

Trap state
→ 발견·해제·발동 상태
```

같은 상자 프리팹을 빈 상자, 보물 상자와 함정 상자로 모두 사용할 수 있다. 내용물과 함정은 배치 후 연결한다.

---

## 16. Generic 상호작용 오브젝트

문·레버·상자 외 모델도 동일한 방식으로 추가할 수 있다.

```text
InteractionObjects
└─ Generic
   └─ RotatingStatue
      ├─ 1
      └─ 2
```

기본 프로필:

```text
GenericToggleProfile
├─ states: 1 ↔ 2
├─ prompt: 상호작용
├─ semanticChanges: none
└─ outputEvent: InteractionStateChanged
```

배치 후 이를 퍼즐 장치, 함정 스위치 또는 장면 연출과 연결할 수 있다.

---

## 17. 배치 후 인스펙터

원본 제작 단계는 간단하게 유지하고, 세션별 규칙은 배치 후 설정한다.

```text
상호작용
├─ 표시 이름
├─ 프롬프트 문구
├─ 상호작용 거리
├─ 반복 가능 여부
├─ 시작 상태
├─ 전환 시간
├─ easing
├─ 잠금과 요구 조건
├─ 사용 가능한 Actor
├─ 실패 동작
└─ 연결된 오브젝트
```

```text
장면 의미
├─ 이동 차단
├─ 시야 차단
├─ 효과선 차단
├─ 엄폐
├─ 상호작용 범위
└─ 소리 발생 범위
```

인스펙터 override는 해당 장면 인스턴스에만 적용한다.

---

## 18. Feature·Feat·판정 연결

상호작용 규칙은 단순 E 입력 외에도 기존 Capability 구조와 연결한다.

예시:

```text
문 따기
→ AbilityCheck 또는 ToolCheck EffectRecipe

강제로 열기
→ Strength Check 또는 오브젝트 공격

함정 감지
→ PerceptionRelation과 Search Action

마법적 잠금 무시
→ RuleOverrideCapability

상호작용 거리 증가
→ ContextModifierCapability

행동 없이 문 열기
→ ActionEconomy RuleOverride
```

오브젝트마다 Feat ID를 하드코딩하지 않는다.

```text
InteractionRuleContext
+ Actor Capability Set
+ Object InteractionProfile
→ 사용 가능한 InteractionActionCapability 목록
```

---

## 19. 오브젝트 연결 그래프

```text
InteractionLink
├─ sourceObjectId
├─ sourceStatePredicate
├─ targetObjectId
├─ targetCommand
├─ delay?
├─ repeatPolicy
└─ visibilityPolicy
```

대상 명령 예시:

```text
set_state
advance_state
toggle
lock
unlock
enable
disable
trigger_effect_recipe
request_dm_decision
```

레버 하나가 문 여러 개를 열거나, 문이 열릴 때 함정을 활성화하는 것도 같은 링크 그래프를 사용한다.

순환 링크는 실행 ID와 깊이 제한으로 무한 반복을 막는다.

---

## 20. 전환 중 요청

```text
TransitionState
├─ idle
├─ transitioning
├─ committed
├─ failed
└─ interrupted
```

기본 정책:

```text
transitioning 중 추가 입력
→ 거절
```

선택 가능한 정책:

```text
queue_latest
reverse_from_current_progress
ignore
request_dm_decision
```

초기 문·레버·상자의 기본값은 `reject_while_transitioning`이다. 빠른 연속 입력 때문에 상태가 꼬이는 것을 막는다.

---

## 21. 저장과 복구

```text
SceneInteractionObjectRecord
├─ sceneObjectId
├─ prefabId
├─ prefabContentRevision
├─ placementTransform
├─ currentStateId
├─ instanceOverrides
├─ semanticOverrides
├─ interactionLinks
└─ revision
```

서버 시작 또는 장면 로드:

```text
프리팹 컴파일 결과 조회
→ 상태 1 모델 생성
→ 저장된 currentState 스냅샷 즉시 적용
→ 상호작용·장면 의미 바인딩 복구
```

로드 시에는 상태 `1`에서 현재 상태로 Tween하지 않는다. 저장된 상태를 즉시 적용한다.

프리팹 구조가 변경되어 상대 경로가 달라지면 마이그레이션 또는 DM 검토를 요구한다.

---

## 22. 성능

- 프리팹 상태 스냅샷은 콘텐츠 로드 시 한 번 컴파일한다.
- 장면 인스턴스마다 상태 `2` 모델을 보관하지 않는다.
- 상호작용 가능 여부는 공간 인덱스로 가까운 오브젝트만 조회한다.
- 모든 상호작용 모델을 매 프레임 순회하지 않는다.
- 정지 상태에서는 Tween 업데이트 비용이 없다.
- Tween 중인 구성요소만 활성 전환 목록에 존재한다.
- 동일 프리팹 인스턴스는 컴파일 결과를 공유한다.
- 원본 모델 변경 시 영향받는 프리팹만 다시 컴파일한다.

---

## 23. 제작 검증 도구

장면 편집기에 `Interaction Assets 검사` 기능을 제공한다.

```text
검사
→ 유효 프리팹 수
→ 오류 프리팹 수
→ 상태 구성요소 차이
→ Tween 가능 속성 차이
→ 미지원 물리 요소
→ 자동 생성 범위 미리보기
```

프리팹 선택 시 상태 전환 미리보기를 제공한다.

```text
1 표시
2 표시
1 → 2 재생
2 → 1 재생
구성요소 대응 보기
```

미리보기는 원본 프리팹을 수정하지 않는다.

---

## 24. 예시

### 레버

```text
Lever/IronLever
├─ 1
│  ├─ Base
│  ├─ Handle
│  └─ Lamp
└─ 2
   ├─ Base
   ├─ Handle
   └─ Lamp
```

상태 차이:

```text
Handle.CFrame
Lamp.Color
Lamp.Brightness
```

결과:

```text
Handle 회전
+ Lamp 색상 전환
+ 연결된 문 열림 요청
```

### 문

```text
Door/OakDoor
├─ 1
│  ├─ Frame
│  ├─ Panel
│  └─ Handle
└─ 2
   ├─ Frame
   ├─ Panel
   └─ Handle
```

상태 차이:

```text
Panel.CFrame
Handle.CFrame
Panel.CanCollide
```

결과:

```text
문짝 회전
→ commit point에서 이동·시야 차단 갱신
```

### 상자

```text
Chest/WoodenChest
├─ 1
│  ├─ Body
│  ├─ Lid
│  └─ Lock
└─ 2
   ├─ Body
   ├─ Lid
   └─ Lock
```

상태 차이:

```text
Lid.CFrame
Lock.CFrame
```

결과:

```text
뚜껑 열림
→ 컨테이너 UI 사용 가능
```

---

## 25. 필수 테스트

1. Attribute와 Value가 전혀 없는 프리팹이 등록된다.
2. 상태 `1`과 `2`가 서로 다른 Studio 위치에 있어도 올바르게 Tween된다.
3. 같은 상대 경로의 부품이 정확히 대응된다.
4. 누락된 부품과 클래스 불일치가 명확한 오류를 낸다.
5. 상태 `2` 모델이 Workspace에 복제되지 않는다.
6. CFrame, Size, Color와 Transparency가 올바르게 전환된다.
7. 불연속 속성이 지정된 commit point에 적용된다.
8. 배치 후 생성된 Attribute가 원본 프리팹에 역으로 기록되지 않는다.
9. 문을 열면 NavigationBlocker와 VisionBlocker가 갱신된다.
10. 레버 링크가 대상 문의 상태를 전환한다.
11. 상자의 시각 상태와 컨테이너 상태가 독립적으로 저장된다.
12. 전환 중 중복 입력이 상태를 손상시키지 않는다.
13. 재접속 시 저장된 상태가 Tween 없이 즉시 복구된다.
14. 클라이언트가 잘못된 목표 상태를 보내도 서버가 거부한다.
15. 프리팹 하나의 오류가 다른 프리팹 등록을 중단하지 않는다.
16. 동일 프리팹 수십 개가 컴파일 결과를 공유한다.
17. 모델 수정 후 콘텐츠 revision 불일치가 감지된다.
18. Feat와 Feature가 InteractionRuleContext를 통해 행동 비용과 판정을 수정한다.

---

## 26. 최종 제작 원칙

```text
원본 모델
→ 시각적 상태만 표현

폴더 위치와 이름
→ 기본 타입과 프리팹 식별

배치 파이프라인
→ 런타임 정보와 기본 규칙 생성

장면 인스펙터
→ 잠금·판정·링크·범위 등 세션별 설정
```

모델 제작자는 상태 `1`과 `2`를 만드는 데 집중한다. RVTT가 필요한 상호작용 정보는 배치 이후 자동 생성하고, DM이 필요한 부분만 수정한다.