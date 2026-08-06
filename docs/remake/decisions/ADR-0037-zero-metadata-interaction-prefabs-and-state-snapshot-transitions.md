# ADR-0037: 상호작용 프리팹은 무설정 원본과 상태 스냅샷 규칙으로 제작한다

- 상태: 확정
- 결정일: 2026-08-03
- 관련 문서:
  - [`ADR-0009`](ADR-0009-selection-volume-inclusion-preference.md)
  - [`ADR-0023`](ADR-0023-composable-targeting-and-spatial-query-model.md)
  - [`ADR-0028`](ADR-0028-effect-recipes-pending-effects-and-commit-groups.md)
  - [`ADR-0030`](ADR-0030-item-instances-attack-profiles-and-weapon-mastery.md)
  - [`ADR-0036`](ADR-0036-observer-relative-perception-senses-stealth-and-rule-points.md)
  - [`31. 무설정 상호작용 프리팹과 상태 전환 모델`](../systems/interaction/zero-metadata-interaction-prefab-and-state-transition-model.md)

## 배경

RVTT에는 문, 레버, 상자, 함정 장치, 버튼, 석상과 퍼즐 장치처럼 상태가 변하는 모델이 많이 필요하다.

상호작용 오브젝트마다 제작자가 Attribute, ValueBase, Attachment, 스크립트 또는 고유 설정 파일을 직접 넣어야 한다면 다음 문제가 생긴다.

- 외부 모델을 가져올 때마다 반복적인 설정 작업이 필요하다.
- Attribute 이름 오타와 누락 때문에 오브젝트가 작동하지 않는다.
- 원본 모델이 런타임 메타데이터와 섞여 재사용하기 어려워진다.
- 문, 레버와 상자마다 별도 스크립트를 만들게 된다.
- 열린 상태와 닫힌 상태의 부품 위치, 크기와 색상 차이를 코드로 다시 작성해야 한다.

사용자는 `ReplicatedStorage`에 처음 모델을 넣을 때 아무 Value나 Attribute 없이 사용할 수 있기를 원한다. 또한 하나의 프리팹 폴더 안에 상태 모델 `1`과 `2`를 두고, 같은 구성요소가 상태 `1`에서 상태 `2`의 위치·회전·크기·색상 등으로 Tween되기를 원한다.

## 결정

상호작용 프리팹의 원본은 폴더 구조와 이름만으로 인식한다.

```text
ReplicatedStorage
└─ RVTTContent
   └─ InteractionObjects
      ├─ Lever
      │  └─ IronLever
      │     ├─ 1
      │     └─ 2
      ├─ Door
      │  └─ OakDoor
      │     ├─ 1
      │     └─ 2
      └─ Chest
         └─ IronChest
            ├─ 1
            └─ 2
```

- `Lever`, `Door`, `Chest`는 기본 상호작용 프로필을 선택하는 분류 폴더다.
- `IronLever`, `OakDoor`, `IronChest`는 프리팹 ID의 원본이 되는 제작자 지정 이름이다.
- `1`은 초기 상태 모델이다.
- `2`는 전환 목표 상태 모델이다.
- 원본 프리팹에는 Attribute, ValueBase, Script와 RemoteEvent를 요구하지 않는다.
- 프리팹 등록 과정은 원본을 수정하지 않는다.

## 상태 구성요소 대응

상태 `1`과 `2`의 구성요소는 상대 경로와 클래스가 같아야 한다.

```text
1/Body/Handle
2/Body/Handle

1/Base/Lamp
2/Base/Lamp
```

`InteractionPrefabCompiler`는 같은 상대 경로의 구성요소를 하나의 전환 채널로 컴파일한다.

초기 지원 대상:

- `BasePart`
- `Attachment`
- `Decal`과 `Texture`
- `PointLight`, `SpotLight`, `SurfaceLight`
- 등록된 안전한 프레젠테이션 구성요소

같은 부모 아래 중복 이름을 사용하거나 상태 사이에서 클래스가 다르면 검증 오류로 처리한다.

## 피벗과 상대 좌표

상태 모델 `1`과 `2`는 `ReplicatedStorage` 안에서 서로 다른 위치에 놓여 있어도 된다.

각 상태의 구성요소 값은 해당 상태 모델의 `GetPivot()`에 대한 상대 값으로 저장한다.

```text
stateLocalCFrame
= stateModel:GetPivot():ToObjectSpace(component.CFrame)
```

따라서 제작자는 Studio에서 상태 `1`과 `2`를 나란히 놓고 편집할 수 있으며, 실제 장면에서는 프리팹 인스턴스의 배치 피벗을 기준으로 전환된다.

## 컴파일 결과

```text
InteractionPrefabSource
→ 구조 검증
→ 상태별 구성요소 스냅샷
→ 상대 경로 대응
→ 속성 전환 채널 생성
→ 기본 상호작용 프로필 결합
→ CompiledInteractionPrefab
```

컴파일 결과는 서버 레지스트리에 저장한다. 원본 모델에 Attribute나 Value를 생성하지 않는다.

## 장면 배치

프리팹을 장면에 배치할 때는 상태 `1`만 실제 오브젝트로 복제한다. 상태 `2`는 장면에 숨겨 두는 복제 모델이 아니라 전환 목표 스냅샷으로만 사용한다.

```text
CompiledInteractionPrefab
+ placement transform
→ 상태 1의 Live Model 생성
→ InteractionInstanceBinder
→ SceneInteractionObject 등록
```

배치 후에는 시스템이 다음 런타임 정보를 부여할 수 있다.

```text
SceneObjectId
InteractionPrefabId
CurrentStateId
Revision
```

이 정보는 서버 상태 저장소가 권위 원본이다. 장면 모델의 Attribute는 디버깅과 편집기 식별을 위한 선택적 미러이며, 원본 프리팹에는 기록하지 않는다.

## 상태 전환

```text
InteractionRequest
→ 권한·거리·상태·잠금 검증
→ transition 예약
→ 상태 1 스냅샷에서 상태 2 스냅샷으로 Tween
→ 규칙상 commit point
→ CurrentStateId 변경
→ 연결된 행동과 장면 의미 갱신
→ InteractionStateChanged 사건
```

반대 전환이 허용된 프리팹은 동일한 채널을 역방향으로 사용한다.

전환 중에는 새로운 상호작용 요청을 정책에 따라 거절, 대기 또는 역전한다. 기본 정책은 현재 전환이 끝날 때까지 추가 요청을 거절하는 것이다.

## 전환 가능한 속성

초기 기본 Tween 속성:

- 상대 `CFrame`
- `Size`
- `Color`
- `Transparency`
- Light의 `Brightness`, `Range`, `Angle`, `Color`
- Decal과 Texture의 `Transparency`, `Color3`

불연속 속성은 Tween하지 않고 전환 단계에 맞춰 교체한다.

- `Material`
- `CanCollide`
- `CanQuery`
- `CanTouch`
- Light `Enabled`
- ParticleEmitter `Enabled`
- 기타 boolean 또는 enum 속성

불연속 속성의 기본 적용 시점은 `transition_start`, `commit_point`, `transition_end` 중 등록된 타입 프로필이 결정한다.

## 기본 타입 프로필

분류 폴더는 별도 Attribute 없이 기본 동작을 선택한다.

```text
Lever
→ 양방향 toggle
→ 기본 상호작용 문구: 작동
→ 연결된 출력 사건 발생

Door
→ 열기·닫기 toggle
→ 충돌·이동 차단·시야 차단 상태 갱신
→ 기본 상호작용 문구: 열기 / 닫기

Chest
→ 열기·닫기 상태 전환
→ 저장된 컨테이너 또는 전리품 행동과 연결 가능
→ 기본 상호작용 문구: 열기 / 살펴보기
```

분류는 기본값일 뿐이다. 장면에 배치한 뒤 인스펙터에서 잠금, 열쇠, 판정, 상호작용 거리, 반복 가능 여부, Tween 시간과 연결 대상을 수정할 수 있다.

## 자동 생성과 배치 후 편집

원본에 별도 설정이 없어도 배치 시 다음을 자동 생성한다.

- 모델 경계 기반 상호작용 범위
- 기본 상호작용 지점
- 분류별 기본 문구와 동작
- 상태별 충돌·가시성·이동 의미 후보
- 기본 Tween 시간과 easing

DM은 배치 후 인스펙터에서 자동 생성 결과를 수정할 수 있다. 수정값은 장면 인스턴스의 override로 저장하며 원본 프리팹을 변경하지 않는다.

## 문과 장면 의미

문의 시각적 Tween과 이동·시야 규칙은 연결되지만 같은 데이터는 아니다.

```text
Door visual transition
→ 모델 구성요소 Tween

Door semantic transition
→ NavigationBlocker 상태
→ VisionBlocker 상태
→ LineOfEffect 차단 상태
```

기본 의미 볼륨은 상태 모델의 충돌 가능한 부품 경계에서 자동 생성한다. 자동 결과가 부정확하면 배치 후 편집기에서 수정한다.

## 서버 권위

- 클라이언트는 프리팹 ID, 목표 상태, 최종 CFrame과 현재 상태를 결정하지 않는다.
- 서버가 상호작용 가능 여부와 상태 전이를 검증한다.
- 서버 TweenService 또는 등록된 서버 전환 어댑터가 권위 모델을 전환한다.
- 순수 VFX와 사운드는 클라이언트 프레젠테이션으로 분리할 수 있다.
- 전환 완료 신호는 `interactionInstanceId + revision + transitionId`로 멱등 처리한다.

## 저장

장면 저장에는 생성된 부품 목록이 아니라 다음을 저장한다.

```text
SceneInteractionObjectRecord
├─ sceneObjectId
├─ interactionPrefabId
├─ placementTransform
├─ currentStateId
├─ instanceOverrides
├─ linkedInteractionIds[]
└─ revision
```

재접속이나 서버 복구 시 현재 상태 스냅샷을 즉시 적용하고, 이미 완료된 Tween을 다시 재생하지 않는다.

## 금지 사항

- 원본 프리팹마다 Script 삽입
- 원본에 필수 Attribute 또는 ValueBase 요구
- 상태 `1`과 `2` 전체 모델을 장면에 동시에 복제
- 부품 배열 순서로 상태 대응
- 클라이언트가 최종 상태를 직접 확정
- 문의 시각 모델만 보고 이동·시야 차단을 즉석 추론
- 매 프레임 모든 상호작용 오브젝트 검사

## 결과

제작자는 다음 세 단계만으로 기본 상호작용 오브젝트를 추가할 수 있다.

```text
1. 타입 폴더 아래 프리팹 폴더 생성
2. 같은 구성요소를 가진 상태 모델 1과 2 배치
3. RVTT 장면 편집기에서 해당 프리팹 배치
```

추가 Attribute, Value와 스크립트 작업 없이 기본 문·레버·상자 동작이 생성된다.