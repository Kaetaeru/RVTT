# ADR-0035: Fog of War는 두 개의 수동 마스크를 권위 원본으로 하고 자동화는 선택형 보조로 제한한다

- 상태: 확정
- 결정일: 2026-08-03
- 관련 문서:
  - [`ADR-0007`](ADR-0007-view-y-and-world-scale.md)
  - [`ADR-0009`](ADR-0009-selection-volume-inclusion-preference.md)
  - [`ADR-0023`](ADR-0023-composable-targeting-and-spatial-query-model.md)
  - [`ADR-0034`](ADR-0034-encounter-initiative-turn-order-and-control-authority.md)
  - [`29. 수동 Fog of War와 선택형 Assist 모델`](../29-manual-fog-of-war-and-optional-assist-model.md)

## 배경

RVTT는 연속적인 3D 공간, 복층 구조, 실제 Y 좌표, 계단, 난간, 문, 창문과 복잡한 장식 메시를 사용한다.

순수 자동 시야 기반 Fog of War는 다음 문제를 일으키기 쉽다.

- 고저차와 복층 때문에 보여야 할 장소가 가려지거나 반대 층이 노출된다.
- 작은 장식, 난간과 메시 틈이 시야 결과를 불안정하게 만든다.
- 문틈이나 창문 때문에 방 전체가 의도치 않게 공개된다.
- 물리적으로 보이는 영역과 DM이 서사적으로 공개하려는 영역이 다르다.
- 잘못된 자동 공개는 숨겨진 방과 장면 정보를 되돌릴 수 없게 노출한다.

사용자는 기존에 기획한 3차원 셀렉션 박스 방식의 수동 안개 조정을 선호한다. 따라서 자동 계산의 정확도를 높이기 위해 수동 방식을 희생하지 않는다.

## 결정

Fog of War의 권위 원본은 DM이 편집하는 두 개의 독립 수동 마스크다.

```text
DiscoveryMask
→ 해당 공간을 한 번이라도 탐험했는가

CurrentRevealMask
→ 해당 공간을 지금 완전히 공개할 것인가
```

두 마스크를 조합하여 세 가지 플레이어 표시 상태를 만든다.

```text
DiscoveryMask = false
→ Unexplored
→ 완전한 안개

DiscoveryMask = true
CurrentRevealMask = false
→ Remembered
→ 지형 기억만 표시하고 현재 Actor·변화는 표시하지 않음

CurrentRevealMask = true
→ Revealed
→ 현재 지형과 공개 가능한 장면 상태 표시
```

`CurrentRevealMask`가 켜질 때 해당 공간은 자동으로 `DiscoveryMask`에도 기록된다.

## 3차원 FogVolume

수동 마스크 편집 결과는 실제 Y 범위를 가진 `FogVolume`으로 저장한다.

```text
FogVolume
├─ fogVolumeId
├─ maskKind
├─ shape
├─ footprint
├─ minimumY
├─ maximumY
├─ audienceBinding
├─ operation
├─ priority
└─ revision
```

`maskKind`:

```text
discovery
current_reveal
```

`operation`:

```text
add
subtract
replace
```

이를 통해 같은 XY 위치의 1층과 2층 안개를 독립적으로 편집한다.

## 수동 편집 도구

DM은 기존 3차원 선택 박스 조작을 사용한다.

```text
Fog Selection Tool
├─ 마스크 종류 선택
├─ 박스 드래그
├─ 선택 높이 조절
├─ 추가 또는 제거
├─ 미리보기
└─ 서버 확정
```

높이 프리셋:

```text
current_band
room_height
floor_to_ceiling
infinite_vertical
custom
```

모든 수동 변경은 실행 취소·다시 실행과 감사 로그를 지원한다.

## Fog Assist

자동 기능은 권위 원본이 아니라 수동 마스크 변경을 제안하는 보조 기능이다.

```text
FogAssistSetting
├─ enabled
├─ mode
├─ proposalAudience
├─ autoApprovedRegionIds[]
└─ revision
```

`enabled`는 장면 설정에서 켜고 끌 수 있다. DM은 세션 중에도 즉시 토글할 수 있다.

모드:

```text
off
→ 제안과 자동 공개를 모두 사용하지 않음

proposal_only
→ 후보 영역을 DM에게만 미리보기
→ E 승인 / Q 거절

approved_regions
→ DM이 사전 승인한 FogRegion만 자동 적용
```

기본값은 `off`다. 캠페인 또는 장면 템플릿에서 기본값을 바꿀 수 있지만, 자동 공개를 강제하지 않는다.

## FogRegion

Assist는 픽셀 또는 레이캐스트 결과로 안개를 직접 자르지 않고, 제작된 의미 구역을 사용한다.

```text
FogRegion
├─ fogRegionId
├─ volume
├─ connectedPortalIds[]
├─ revealPreset
├─ assistPolicy
├─ audienceBinding
└─ revision
```

대표 구역:

- 방
- 복도 구간
- 계단 하단과 상단
- 발코니
- 마당
- 동굴 구획

Actor가 구역에 들어가거나 연결된 문을 열면 Assist는 해당 `FogRegion`을 수동 마스크 변경 후보로 제안할 수 있다.

## 문·계단·관측 연결

```text
FogPortal
├─ portalId
├─ regionA
├─ regionB
├─ portalStateBinding
└─ revealPolicy
```

`revealPolicy`:

```text
never
propose_on_open
propose_on_enter
approved_auto_on_enter
dm_only
```

복층 관측은 `ObservationLink`로 명시한다.

```text
ObservationLink
├─ sourceRegionId
├─ targetRegionId
├─ resultMaskKind
├─ targetSubvolume?
└─ condition
```

예를 들어 성벽 위에서 마당 지형만 `DiscoveryMask`에 추가하되, 마당을 현재 공개하거나 숨겨진 Actor를 노출하지 않을 수 있다.

## Fog와 Actor 탐지 분리

Fog of War는 지형 공개 시스템이다. Actor, 함정, 비밀문과 투명 효과의 노출 여부는 별도 탐지·정보 권한 시스템이 결정한다.

```text
FogMaskState
→ 지형과 장면 구조 표시

DetectionState / VisibilityPolicy
→ Actor와 비밀 요소 표시
```

따라서 방을 `Revealed`로 만들어도 은신한 도적이나 비밀문이 자동 노출되지 않는다.

## Fog와 규칙 시야 분리

```text
Fog of War
→ 플레이어에게 맵을 어느 정도 보여줄 것인가

Line of Sight
→ 규칙상 대상을 볼 수 있는가

Line of Effect
→ 공격이나 효과가 도달할 수 있는가
```

Fog 마스크는 명중, 은신, 대상 적격성과 엄폐 판정을 직접 결정하지 않는다.

규칙 시야는 실제 렌더 메시가 아니라 등록된 의미 차단체와 별도 공간 질의를 사용한다.

## 안전 원칙

- Assist 계산은 플레이어에게 직접 비밀 정보를 전송하지 않는다.
- `proposal_only` 후보는 DM 클라이언트에만 표시한다.
- 잘못된 후보는 승인 전까지 권위 Fog 상태를 변경하지 않는다.
- 승인된 변경도 서버 권한과 revision 검증을 통과한다.
- 권한 없는 클라이언트에 가려진 Actor나 비밀 장면 데이터 자체를 보내지 않는다.

## 결과

- DM이 선호하는 수동 셀렉션 박스 조작을 Fog의 중심으로 유지한다.
- 두 마스크만으로 완전 미탐험, 기억된 지형과 현재 공개 상태를 표현한다.
- 실제 Y 범위를 사용하여 복층과 고저차를 처리한다.
- 자동 안개의 오판으로 비밀이 노출되는 위험을 줄인다.
- 필요할 때만 Fog Assist를 켜서 방·복도 단위 공개를 빠르게 처리할 수 있다.
- Fog, Actor 탐지와 전투 규칙 시야가 서로 독립적으로 발전할 수 있다.
