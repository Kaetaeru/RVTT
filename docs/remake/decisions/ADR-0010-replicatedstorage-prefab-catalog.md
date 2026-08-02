# ADR-0010: ReplicatedStorage 기반 프리팹 카탈로그

- 상태: 확정
- 결정일: 2026-08-03
- 관련 문서:
  - [`06-ingame-scene-editor-tools.md`](../06-ingame-scene-editor-tools.md)
  - [`09-scene-editor-tool-module-architecture.md`](../09-scene-editor-tool-module-architecture.md)

## 배경

씬 편집기는 건축물, 가구, 자연물, 소품과 조명 같은 프리팹 에셋을 빠르게 미리보고 배치해야 한다.

클라이언트가 배치 고스트를 만들 수 있어야 하지만, 실제 씬 생성 권한과 프리팹 원본의 신뢰성은 서버가 보장해야 한다.

씬 저장 데이터에 모델 전체를 직렬화하면 중복, 용량 증가와 에셋 업데이트 문제가 생긴다.

## 결정

RVTT가 기본 제공하는 신뢰된 프리팹 원본은 `ReplicatedStorage`의 전용 카탈로그 아래에 둔다.

개념 구조:

```text
ReplicatedStorage
└─ RVTT
   └─ SceneEditor
      └─ Prefabs
         ├─ Architecture
         ├─ Furniture
         ├─ Nature
         ├─ Props
         └─ Lighting
```

각 프리팹은 전역적으로 고유한 `PrefabId`를 가진다.

예시:

```text
rvtt.architecture.stone_wall_01
rvtt.furniture.wooden_chair_01
rvtt.nature.oak_tree_02
```

파일명이나 Roblox Instance 이름만을 영구 저장 ID로 사용하지 않는다.

## 배치 흐름

```text
에셋 브라우저에서 프리팹 선택
→ 클라이언트가 ReplicatedStorage 원본을 Clone해 로컬 고스트 생성
→ 사용자가 위치, 회전, 크기와 허용된 오버라이드 조정
→ 클라이언트가 PrefabId와 배치 파라미터만 서버에 요청
→ 서버가 PrefabId, 권한, 범위와 파라미터 검증
→ 서버가 같은 카탈로그 원본을 직접 Clone
→ 씬 원본 데이터와 Workspace 인스턴스 생성
```

클라이언트가 만든 Model 또는 임의 Instance를 서버가 그대로 신뢰하거나 Workspace에 삽입하지 않는다.

## 저장 데이터

씬에는 프리팹 모델 전체를 저장하지 않고 참조와 변경값만 저장한다.

개념 예시:

```lua
{
    objectType = "rvtt.scene.prefab-instance",
    prefabId = "rvtt.furniture.wooden_chair_01",
    transform = ...,
    scale = ...,
    overrides = {
        color = ...,
        materialVariant = ...,
    },
}
```

씬 로드 시 서버가 `PrefabId`를 카탈로그에서 해석하고 원본을 다시 생성한다.

## 프리팹 등록 정보

각 프리팹은 모델 원본과 별도로 또는 Attribute·정의 모듈을 통해 다음 메타데이터를 제공한다.

- `PrefabId`
- 표시 이름과 카테고리
- 아이콘 또는 썸네일 참조
- 기본 피벗과 배치 기준
- 허용된 스케일과 오버라이드
- 충돌과 선택 범위
- 이동, 시야와 상호작용 프로필
- 배치 가능 표면과 부착 규칙
- 버전과 필요 시 마이그레이션 정보

프리팹 원본은 직접 수정하지 않으며, 모든 고스트와 실제 배치 인스턴스는 Clone으로 생성한다.

## 서버 검증

서버는 최소한 다음을 확인한다.

- 등록된 `PrefabId`인지
- 요청 사용자가 해당 프리팹과 씬을 편집할 권한이 있는지
- 위치와 크기가 씬 경계 및 제한 안에 있는지
- 스케일과 오버라이드가 프리팹 허용 범위인지
- 금지된 교차 또는 부모 관계가 없는지
- 씬과 사용자별 배치 수 제한을 넘지 않는지

## 성능과 후속 확장

초기 에셋 규모에서는 신뢰된 프리팹을 `ReplicatedStorage`에 두는 방식을 사용한다.

에셋 규모가 커져 전체 복제 비용이 문제가 되면 다음을 후속 검토한다.

- 에셋 팩별 분리
- 장소 또는 캠페인별 카탈로그 구성
- 선택적 로딩과 캐시
- 썸네일과 실제 모델의 지연 로딩

이후 확장이 생겨도 씬 저장 형식의 `PrefabId` 참조 원칙은 유지한다.

## 결과

클라이언트는 빠른 고스트 미리보기를 제공하고, 서버는 동일한 신뢰된 카탈로그에서 실제 인스턴스를 생성한다.

씬 데이터는 모델 복사본이 아니라 `PrefabId`와 변경값을 저장하므로 프리팹 업데이트, 저장 용량과 보안 검증을 일관되게 관리할 수 있다.
