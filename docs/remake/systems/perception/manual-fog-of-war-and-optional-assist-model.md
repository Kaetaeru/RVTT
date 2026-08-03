# 29. 수동 Fog of War와 선택형 Assist 모델

- 상태: 초안
- 작성일: 2026-08-03
- 관련 문서:
  - [`04. 장면과 월드`](../scene/scenes-and-world.md)
  - [`07. 장면 편집 상호작용과 레이아웃`](../../ui/scene-editor/scene-editor-interaction-and-layout.md)
  - [`08. 공통 입력 교과서`](../../ui/common-input/common-input-grammar.md)
  - [`17. 주문 대상·범위·공간 질의 모델`](../rules/spell-targeting-area-and-spatial-query-model.md)
  - [`28. 인카운터·주도권·턴과 제어권 모델`](../combat/encounter-initiative-turn-and-control-authority-model.md)
  - [`ADR-0035`](../../decisions/ADR-0035-manual-fog-masks-and-optional-region-assist.md)

## 1. 문서 목적

이 문서는 RVTT의 Fog of War를 완전 자동 시야 계산이 아니라 DM 권위의 수동 3차원 마스크로 운영하는 구조를 정의한다.

대상:

- 완전 미탐험 영역
- 이전에 본 지형
- 현재 공개된 영역
- 셀렉션 박스 기반 수동 편집
- 복층과 Y 높이 범위
- 플레이어·파티별 공개 범위
- Fog Assist 켜기·끄기
- 방·복도·계단 기반 공개 제안
- 문과 관측 지점 연결
- 지형 공개와 Actor 탐지 분리
- 저장, 동기화, 실행 취소와 재접속

핵심 원칙:

```text
수동 Fog 마스크
→ 권위 원본

Fog Assist
→ 수동 마스크 변경 후보를 만드는 선택형 보조 기능
```

---

## 2. 두 개의 수동 마스크

Fog 상태를 세 종류의 서로 배타적인 페인트로 저장하지 않는다.

```text
DiscoveryMask
CurrentRevealMask
```

### DiscoveryMask

해당 공간을 플레이어가 한 번이라도 탐험했는지를 기록한다.

```text
false
→ 지형 정보를 표시하지 않음

true
→ 현재 공개되지 않더라도 기억된 지형으로 표시 가능
```

### CurrentRevealMask

해당 공간을 지금 완전히 공개할지를 기록한다.

```text
false
→ 현재 장면 상태를 직접 표시하지 않음

true
→ 현재 표시 가능한 지형과 장면 요소를 표시
```

### 합성 결과

| Discovery | Current Reveal | 표시 상태 |
|---|---:|---|
| false | false | `Unexplored` |
| true | false | `Remembered` |
| true | true | `Revealed` |
| false | true | 정규화 시 Discovery도 true로 변경 |

`CurrentRevealMask`에 추가하는 명령은 같은 영역을 `DiscoveryMask`에도 추가한다.

현재 공개를 제거해도 Discovery는 자동 제거하지 않는다. 완전 미탐험으로 되돌리려면 DM이 Discovery를 명시적으로 제거해야 한다.

---

## 3. 플레이어 표시 상태

### Unexplored

- 불투명 안개 또는 장면 테마에 맞는 가림 효과
- 지형 메시, 장식, Actor와 상호작용 프롬프트 미표시
- 가려진 콘텐츠는 권한 없는 클라이언트에 전송하지 않는 것을 우선

### Remembered

- 이전에 본 바닥과 주요 구조를 저채도·어둡게 표시
- 현재 문 상태, 이동한 오브젝트와 파괴 상태를 실시간으로 보장하지 않음
- 현재 Actor, VFX, 함정, 비밀문과 변화 가능한 상세 정보 미표시
- 기억 표현은 실제 장면의 라이브 복사본이 아니라 안전한 지형 표현 또는 마지막 허용 스냅샷을 사용

### Revealed

- 현재 장면 지형 표시
- Actor와 비밀 요소는 별도 DetectionState와 권한 정책을 통과한 경우에만 표시

---

## 4. FogVolume

마스크는 2D 이미지 한 장이 아니라 실제 높이 범위를 가진 볼륨 집합으로 저장한다.

```text
FogVolume
├─ fogVolumeId
├─ maskKind
├─ shapeKind
├─ transform
├─ dimensions
├─ minimumY
├─ maximumY
├─ audienceBinding
├─ blendOperation
├─ priority
├─ createdByUserId
└─ revision
```

### shapeKind

초기 지원:

```text
box
polygon_prism
region_reference
```

기본 편집은 `box`다. 복잡한 방 윤곽은 여러 박스를 조합하거나 제작된 Region을 참조한다.

### blendOperation

```text
add
subtract
replace
```

최종 마스크는 안정적인 priority와 생성 순서가 아니라 명시적인 명령 순서 기록으로 재구성한다. 저장 시에는 필요에 따라 병합된 최적화 표현을 생성한다.

---

## 5. 셀렉션 박스 편집 흐름

```text
Fog Tool 진입
→ Discovery / Current Reveal 선택
→ Add / Subtract 선택
→ 화면에서 3D 박스 드래그
→ 높이 범위 조절
→ DM 전용 미리보기
→ E 확정 또는 Q 취소
→ 서버 검증
→ FogCommand 확정
```

### 기본 조작

- 좌클릭 드래그: 바닥 footprint 지정
- 높이 핸들 드래그: minimumY와 maximumY 조절
- Shift: 스냅 임시 해제
- Q: 현재 미완성 선택 취소
- E: 현재 마스크 변경 확정
- Ctrl+Z / Ctrl+Y: FogCommand 실행 취소·다시 실행

물리 키는 입력 문맥을 통해 의미 동작으로 변환한다.

### 빠른 도구 프리셋

```text
Reveal Now
→ CurrentRevealMask 추가
→ DiscoveryMask도 함께 추가

Hide Current
→ CurrentRevealMask 제거
→ DiscoveryMask 유지

Forget Area
→ CurrentRevealMask 제거
→ DiscoveryMask 제거

Mark Explored
→ DiscoveryMask만 추가
```

DM UI에서는 이 네 동작을 직접 선택할 수 있게 한다.

---

## 6. 높이 프리셋

```text
current_band
→ 현재 ViewY 주변의 얕은 높이 범위

room_height
→ 선택 지점의 제작된 방 또는 천장 정보 사용

floor_to_ceiling
→ 감지된 바닥부터 천장까지

infinite_vertical
→ 모든 Y 범위

custom
→ 핸들로 직접 설정
```

높이 자동 감지가 불확실하면 DM 미리보기에서만 제안하고, 확정 전에 수동 수정할 수 있어야 한다.

예시:

```text
1층 공개
minimumY = 0
maximumY = 14

2층 유지
minimumY = 15
maximumY = 28
```

명시적인 층 시스템 없이 실제 Y 좌표로 분리한다.

---

## 7. AudienceBinding

Fog 상태는 장면 전체 공통으로만 고정하지 않는다.

```text
AudienceBinding
├─ all_players
├─ party_id
├─ player_ids[]
├─ control_group_id
└─ custom_registered
```

초기 제품 기본값은 `all_players` 또는 현재 파티 공유다.

개인별 분리는 정찰, 분리된 파티와 비밀 장면에 사용할 수 있지만, DM UI 복잡도를 줄이기 위해 고급 옵션으로 둔다.

DM은 항상 모든 FogVolume과 실제 장면을 볼 수 있으며, 플레이어 시점 미리보기 모드로 특정 Audience의 합성 결과를 확인할 수 있다.

---

## 8. FogCommand

```text
FogCommand
├─ commandId
├─ sceneId
├─ maskKind
├─ operation
├─ volumePayload
├─ audienceBinding
├─ expectedRevision
├─ sourceKind
└─ createdByUserId
```

`sourceKind`:

```text
manual_selection
assist_proposal
approved_region_auto
imported_scene_data
dm_scripted_event
```

모든 출처는 같은 명령·검증·이력 파이프라인을 사용한다.

### 서버 검증

- 요청자가 해당 장면의 Fog 편집 권한을 가졌는가
- 볼륨 크기와 좌표가 허용 상한 안에 있는가
- audience가 유효한가
- revision이 최신인가
- 한 명령이 지나치게 많은 조각을 생성하지 않는가

---

## 9. Fog Assist 설정

```text
FogAssistSetting
├─ enabled
├─ mode
├─ showProposalPreview
├─ proposalCooldown
├─ autoApprovedRegionIds[]
├─ actorEligibilityPolicy
└─ revision
```

### enabled

DM은 장면 설정 또는 세션 퀵 토글에서 즉시 켜고 끌 수 있다.

```text
Fog Assist: OFF
Fog Assist: ON — Proposal Only
Fog Assist: ON — Approved Regions
```

OFF로 전환하면 기존 수동 마스크는 그대로 유지하고, 대기 중인 제안만 취소한다.

### 기본값

```text
enabled: false
mode: proposal_only
```

Assist를 한 번도 설정하지 않은 장면에서는 어떠한 자동 공개도 발생하지 않는다.

### 설정 범위

- 캠페인 기본값
- 장면별 저장 설정
- 현재 세션의 임시 DM 오버라이드

우선순위:

```text
세션 임시 오버라이드
→ 장면 설정
→ 캠페인 기본값
```

---

## 10. FogRegion

Assist는 렌더 메시를 분석하여 임의의 가시 영역을 만들지 않는다.

```text
FogRegion
├─ fogRegionId
├─ sceneId
├─ volume
├─ regionKind
├─ connectedPortalIds[]
├─ defaultRevealPreset
├─ assistPolicy
├─ displayName
└─ revision
```

`regionKind` 예시:

```text
room
corridor
stair_lower
stair_upper
balcony
courtyard
cave_section
outdoor_zone
custom
```

Region은 DM이 직접 만들거나 방·벽 제작 도구가 초안을 생성할 수 있다. 자동 생성 결과는 편집 가능한 장면 의미 데이터로 저장한다.

---

## 11. Assist 제안 흐름

```text
적격 플레이어 Actor가 Region 진입
또는 연결된 Portal 상태 변경
→ FogAssistEvaluator
→ 현재 Audience 마스크 확인
→ 이미 공개된 영역 제외
→ FogProposal 생성
→ DM 화면에만 후보 볼륨 표시
→ E 승인 / Q 거절
```

```text
FogProposal
├─ proposalId
├─ triggeringActorId
├─ sourceRegionId
├─ proposedCommands[]
├─ reason
├─ expiresAt
└─ state
```

상태:

```text
pending
approved
rejected
expired
cancelled
```

한 Actor가 경계에서 흔들릴 때 같은 제안이 반복되지 않도록 Region 진입 occurrence와 cooldown을 사용한다.

---

## 12. Approved Regions 모드

DM이 특정 Region을 자동 승인 목록에 넣을 수 있다.

```text
Region A
assistPolicy: proposal_only

Region B
assistPolicy: approved_auto

비밀 방 C
assistPolicy: dm_only
```

`approved_auto`도 다음 조건을 만족해야 한다.

- Fog Assist가 켜져 있음
- 현재 mode가 `approved_regions`
- 적격 플레이어 Actor가 실제로 트리거함
- Portal과 Region 조건이 유효함
- 서버 revision 검증 성공

자동 적용 결과도 `FogCommand` 이력에 기록하고 DM이 즉시 되돌릴 수 있다.

---

## 13. 문과 FogPortal

```text
FogPortal
├─ portalId
├─ sceneObjectId
├─ regionA
├─ regionB
├─ stateBinding
├─ revealPolicy
└─ revision
```

`revealPolicy`:

```text
never
propose_on_open
propose_on_enter
approved_auto_on_enter
dm_only
```

문이 열렸다고 반대편 방 전체를 항상 공개하지 않는다.

예시:

```text
일반 방문
→ propose_on_enter

철창문
→ never 또는 별도 ObservationLink

비밀문
→ dm_only

문을 열면 내부가 바로 보이는 작은 방
→ propose_on_open
```

---

## 14. 계단과 복층

계단은 하나의 거대한 Region이 아니라 전이 구역으로 구성한다.

```text
1층 복도
→ stair_lower
→ stair_upper
→ 2층 복도
```

하단 진입에서는 계단과 필요한 중간 구간만 제안한다. 상단 도달 occurrence가 발생한 뒤 2층 Region 공개를 제안한다.

이 방식은 토큰 눈높이 레이캐스트로 2층 전체가 조기에 노출되는 문제를 피한다.

---

## 15. ObservationLink

고지대, 창문, 절벽과 전망대에서 다른 Region의 일부 지형을 보여주고 싶을 때 사용한다.

```text
ObservationLink
├─ observationLinkId
├─ sourceRegionId
├─ targetRegionId
├─ targetSubvolume?
├─ resultMaskKind
├─ conditionPredicate
└─ assistPolicy
```

예시:

```text
성벽 위 진입
→ 마당 targetSubvolume을 DiscoveryMask에만 추가 제안
→ CurrentRevealMask는 변경하지 않음
```

따라서 지형은 기억 상태로 보이지만 현재 숨은 Actor는 노출되지 않는다.

---

## 16. 지형 공개와 Actor 표시

Fog 합성은 Actor의 탐지 결과를 대신하지 않는다.

```text
TerrainVisibilityResult
+ ActorDetectionResult
+ InformationVisibilityPolicy
→ 최종 클라이언트 표현
```

대표 결과:

```text
Revealed 방
+ 일반 경비병 detected
→ 경비병 표시

Revealed 방
+ 숨은 도적 undetected
→ 도적 미표시

Remembered 방
+ 적이 현재 이동함
→ 적 미표시

Revealed 벽
+ 비밀문 정보 권한 없음
→ 일반 벽으로 표시
```

---

## 17. 규칙 시야와의 경계

FogVolume은 다음 판정을 하지 않는다.

- 공격 이점·불리점
- 대상이 보이는지
- 엄폐
- 효과선
- 투명화 탐지
- 암시야
- 은신 성공·실패

이 판정은 이후 `VisibilityQuery`, `SenseProfile`, `DetectionState`와 의미 차단체가 담당한다.

Fog가 완전히 공개된 장면에서도 규칙상 보이지 않는 대상은 공격 불리점이나 대상 제한을 받을 수 있다.

반대로 DM이 편의를 위해 지형을 미리 공개했더라도 캐릭터가 그 공간을 규칙상 직접 보고 있다는 뜻은 아니다.

---

## 18. 플레이어 시점 미리보기

DM은 실제 확정 전에 다음을 확인할 수 있어야 한다.

```text
현재 파티 시점
특정 플레이어 시점
DiscoveryMask만
CurrentRevealMask만
합성 결과
Assist 후보 포함
```

미리보기는 로컬 편집 상태이며 서버 권위 Fog를 변경하지 않는다.

Assist 후보는 점선 또는 반투명 볼륨으로 표시하고 기존 확정 공개 영역과 명확히 구분한다.

---

## 19. 저장과 동기화

```text
SceneFogState
├─ sceneId
├─ fogEnabled
├─ discoveryVolumesByAudience
├─ currentRevealVolumesByAudience
├─ assistSetting
├─ fogRegions
├─ fogPortals
├─ observationLinks
├─ commandRevision
└─ schemaVersion
```

클라이언트에는 자신의 Audience에 필요한 합성 결과와 안전한 증분만 전송한다.

대규모 마스크 변경 시 전체 볼륨 목록을 매번 재전송하지 않고 다음을 사용한다.

- 초기 압축 스냅샷
- FogCommand 델타
- Region 기반 캐시 무효화
- ViewY와 카메라 범위에 따른 표현 컬링

---

## 20. 실행 취소와 충돌

Fog 편집은 공통 Command History를 사용한다.

```text
FogCommand A 확정
→ inverse command 기록
→ Undo 시 revision 재검증
→ 역연산 확정
```

여러 DM이 동시에 편집할 경우:

- 명령은 서버에서 순차 확정
- 오래된 revision 요청은 재기반 또는 거절
- 겹치는 변경은 명령 이력에서 출처 표시
- 실행 취소는 다른 DM의 이후 변경을 무조건 덮지 않고 안전한 역연산을 생성

---

## 21. 실패와 복구

### Assist 실패

Region 또는 Portal 참조가 깨졌다면 자동 공개하지 않고 DM 진단만 표시한다.

### 클라이언트 연결 끊김

FogCommand가 서버에서 확정되었다면 재접속 후 최신 스냅샷과 델타를 받는다. 로컬 미확정 선택은 폐기한다.

### 잘못된 공개

DM은 최근 FogCommand를 즉시 Undo할 수 있다. 다만 이미 플레이어가 본 비밀 정보는 기술적으로 회수할 수 없으므로 Assist는 기본 OFF이고 제안 모드를 우선한다.

---

## 22. 성능 원칙

- 실제 메시 전체에 대한 매 프레임 시야 레이캐스트로 Fog를 갱신하지 않는다.
- Actor 이동마다 모든 FogVolume을 순회하지 않는다.
- Region 진입·이탈은 공간 인덱스와 이벤트로 계산한다.
- 플레이어 표시용 마스크는 볼륨 변경 시에만 다시 합성한다.
- 겹치는 박스는 저장 또는 빌드 단계에서 안전하게 병합할 수 있다.
- 복잡한 polygon 연산은 백그라운드 프레임 분산 또는 사전 계산을 사용하고 전투 입력을 막지 않는다.

---

## 23. UI 제안

```text
Fog 패널
├─ Enabled
├─ Active Mask
│  ├─ 현재 공개
│  └─ 탐험 기록
├─ Operation
│  ├─ 추가
│  └─ 제거
├─ Height Preset
├─ Audience
├─ Fog Assist 토글
├─ Assist Mode
└─ Player View Preview
```

퀵 액션:

```text
현재 공개
현재 숨기기
탐험됨 표시
완전 가리기
Assist 켜기/끄기
```

현재 선택한 마스크와 동작은 커서 옆과 화면 하단 입력 안내에 항상 표시한다.

---

## 24. 대표 테스트

### 두 마스크 합성

- Current Reveal 추가 시 Discovery도 추가된다.
- Current Reveal 제거 후 Remembered 상태가 된다.
- Discovery 제거 시 완전 미탐험 상태가 된다.

### 복층

- 같은 XY의 1층만 공개해도 2층은 유지된다.
- infinite_vertical 프리셋은 모든 높이에 적용된다.

### Assist OFF

- Region 진입과 문 열림이 FogCommand를 만들지 않는다.
- 기존 마스크는 유지된다.

### Proposal Only

- 후보는 DM에게만 보인다.
- E 승인 전 플레이어 상태는 바뀌지 않는다.
- Q 거절 후 같은 occurrence에서 반복 제안하지 않는다.

### Approved Regions

- 사전 승인 Region만 자동 공개된다.
- 비밀 방과 dm_only Portal은 자동 공개되지 않는다.
- 자동 적용도 Undo 가능하다.

### Actor 분리

- Revealed Region 안의 undetected Actor는 보이지 않는다.
- Remembered Region의 이동 Actor는 보이지 않는다.

### 재접속

- Audience별 마스크가 동일하게 복원된다.
- 미확정 로컬 선택은 복원되지 않는다.

---

## 25. 구현 경계

이 문서가 정의하는 것:

- 수동 Fog 마스크
- 셀렉션 박스 편집
- Region 기반 선택형 Assist
- 지형 표시 상태

다음 문서가 정의할 것:

- 일반 시야와 암시야
- 감각별 탐지
- 은신과 관찰자별 DetectionState
- 보이지 않는 대상 공격
- 시야·효과선·엄폐 판정

Fog는 서사적 장면 공개 도구로 유지하고, D&D 규칙 시야는 별도 시스템으로 완성한다.
