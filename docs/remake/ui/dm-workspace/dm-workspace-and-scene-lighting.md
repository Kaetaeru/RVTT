# 39. DM 작업공간과 Scene 라이팅 모델

- 상태: 초안
- 작성일: 2026-08-03
- 관련 결정: [`ADR-0045`](../../../../decisions/ADR-0045-dm-workspace-and-scene-lighting-authoring.md)

## 1. DMWorkspace

DM 작업공간은 플레이어 HUD와 같은 전장을 사용하지만 추가 도구를 도킹 가능한 패널로 제공한다.

```text
상단: 세션 상태·일시정지·저장
왼쪽: Scene·Actor·Asset
오른쪽: Inspector·Journal·Player Control
하단: Fog·Encounter·Timeline·Roll
```

기본 레이아웃은 제공하지만 사용자는 패널을 이동, 도킹, 접기, 탭 결합하고 초기화할 수 있다.

## 2. 플레이 중 모드와 편집 모드

```text
Live DM Mode
→ 플레이어 진행을 유지
→ Fog, Actor, 판정, 제어권, 저널, 핑, 빠른 오브젝트 수정

Full Scene Edit
→ 세션 일시정지
→ 구조·라이팅·이동 레이어·대량 편집
```

패널은 같은 컴포넌트를 사용하고 권한 및 실행 가능한 명령만 달라진다.

## 3. 주요 패널

### ScenePanel
- 장면 전환
- 초안·게시본
- 카메라 북마크
- Scene 설정

### ActorPanel
- 참가 Actor와 숨겨진 Actor
- 선택·카메라 이동
- 소환·제거
- 제어권 배정

### EncounterPanel
- 참가자
- 이니셔티브
- 현재 턴
- 증원
- 종료

### FogPanel
- DiscoveryMask
- CurrentRevealMask
- Assist On/Off
- 선택 박스 도구

### TimelinePanel
- 턴별 체크포인트
- 변경 비교
- 분기 복구

### JournalPanel
- 현재 Scene 문서
- Actor·오브젝트 링크
- DM 전용 제목 탐색

### RollPanel
- 공개·비밀 굴림
- 대상과 DC
- 굴림 공개 범위

### PlayerControlPanel
- 중도 참가자
- Character/NPC 배정
- 즉시·행동 후·턴 종료 후 제어권 변경
- Observer 전환

## 4. SceneLightingProfile

```text
SceneLightingProfile
├─ clockTime
├─ brightness
├─ ambient
├─ outdoorAmbient
├─ exposureCompensation
├─ environmentDiffuseScale
├─ environmentSpecularScale
├─ atmosphereProfileId?
├─ colorCorrectionProfileId?
├─ skyProfileId?
└─ rulesLightingProfile
```

Roblox Lighting 속성은 게시 시 이 프로필에서 생성한다. 원본 Instance를 저장 데이터의 권위 원본으로 사용하지 않는다.

## 5. 지역 조명

횃불, 마법 구체, 창문 빛 등은 `LocalLightObject`로 Scene에 배치한다.

```text
LocalLightObject
├─ transform
├─ visualLight
├─ rulesLightVolume
├─ enabledState
├─ linkedInteractionIds
└─ transitionProfile
```

시각용 Light와 D&D 시야 판정용 밝은 빛·약한 빛 범위를 분리한다. 시각 품질 때문에 밝기를 조정해도 규칙 범위가 우연히 바뀌지 않는다.

## 6. EnvironmentVolume

지역마다 안개, 색보정, 노출과 분위기를 바꿀 수 있다.

```text
EnvironmentVolume
├─ shape
├─ priority
├─ blendDistance
├─ visualOverrides
└─ rulesOverrides?
```

동굴 내부, 수중, 독 안개, 마법 어둠 같은 영역을 표현한다. 마법 어둠처럼 규칙 효과가 있는 경우에는 별도 EffectInstance와 연결한다.

## 7. 라이팅 전환

```text
즉시
시간 기반 Tween
게임 시간 연동
오브젝트 신호 연동
EffectRecipe 연동
```

예: 레버를 내리면 방의 수정등이 켜지고, 시각 조명과 규칙 조명 범위가 같은 트랜잭션에서 갱신된다.

## 8. 저장과 복구

라이팅 프로필, 지역 조명과 환경 볼륨은 Scene 초안·게시본에 저장한다. Tween 중간값은 저장하지 않고 목표 상태와 시작 시점만 복구한다.

## 9. 성능

- 지역 조명은 거리·ViewY·실내 구역으로 컬링
- 규칙 조명은 공간 인덱스로 질의
- 모든 조명을 매 프레임 전체 순회하지 않음
- 편집 변경은 영향 영역만 재계산
