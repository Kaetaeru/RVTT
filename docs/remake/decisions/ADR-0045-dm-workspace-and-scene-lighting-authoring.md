# ADR-0045: DM 기능은 통합 작업공간으로 제공하고 라이팅은 Scene 데이터로 제작한다

- 상태: 확정
- 결정일: 2026-08-03
- 관련 문서:
  - [`07. 장면 편집 상호작용과 레이아웃`](../ui/scene-editor/scene-editor-interaction-and-layout.md)
  - [`29. 수동 Fog 모델`](../systems/perception/manual-fog-of-war-and-optional-assist-model.md)
  - [`33. 전투 HUD`](../ui/combat-hud/baldurs-gate-style-combat-hud.md)
  - [`39. DM 작업공간과 Scene 라이팅`](../ui/dm-workspace/dm-workspace-and-scene-lighting.md)

## 결정

DM UI는 플레이어 HUD 위에 임시 버튼을 계속 추가하지 않고, 도킹 가능한 `DMWorkspace`로 구성한다.

핵심 패널:

- Scene과 Actor
- Encounter와 Initiative
- Fog
- Journal
- Player와 Control Assignment
- Roll과 Override
- Timeline과 Rollback
- Object Inspector
- Lighting
- Asset Library

각 패널은 공통 도킹·플로팅·레이아웃 저장 시스템을 사용한다. DM은 플레이 중 필요한 패널만 열고, 전체 Scene 편집에서는 확장된 작업공간을 사용한다.

오디오 시스템은 현재 제품 범위에서 제외한다.

라이팅은 Scene 편집 데이터로 관리한다. Roblox Lighting 전역 속성과 지역 조명·환경 볼륨을 직접 흩어 놓지 않고 타입 있는 Scene 설정과 오브젝트로 저장한다.

```text
SceneLightingProfile
LocalLightObject
EnvironmentVolume
LightingTransition
```

라이팅은 화면 연출뿐 아니라 시야 규칙에 필요한 의미 조명 데이터를 별도로 제공한다.
