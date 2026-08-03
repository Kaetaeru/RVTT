# 46. 인벤토리·전리품·아이템 이전 모델

- 상태: 확정
- 즉시 구현 명세 가능성: `READY_WITH_DEFAULTS`
- 남은 기본값: 기본 컨테이너 정렬, 화폐 자동 분배 기본 정책, 전투 중 전달의 기본 거리 표시
- 관련 결정: ADR-0051

## 권위 위치

```text
character_inventory
container_inventory
scene_ground
campaign_storage
consumed_or_destroyed
```

ItemInstance는 동시에 두 위치에 존재할 수 없다. 모든 이동은 `TransferItemTransaction`으로 처리한다.

## 전리품 획득

```text
컨테이너 열기
→ 권한 있는 내용만 표시
→ 아이템 선택
→ 서버 예약
→ 수량·무게·소유권·revision 검증
→ 이전 확정
→ 양쪽 UI 델타 갱신
```

같은 아이템을 두 플레이어가 선택하면 먼저 유효하게 확정된 요청만 성공한다. 실패한 사용자는 즉시 최신 컨테이너 상태를 받는다.

## 바닥 아이템

투척·드롭·무장 해제로 생긴 아이템은 장면 위치를 가진다. 줍기에는 거리, 접근 가능성, 제어권과 전투 행동 비용을 검증한다.

## 플레이어 간 이전

- 탐험: 양쪽이 허용되고 접근 가능한 경우 즉시 이전 요청
- 전투: 규칙에 맞는 행동·상호작용 비용과 거리 사용
- 수신자는 수락이 필요한 정책과 즉시 수령 정책을 캠페인 설정으로 선택 가능
- DM은 강제 이전 가능

## 화폐

화폐는 `CurrencyLedger`로 관리한다.

```text
currencyTypeId
amount
ownerId
revision
```

컨테이너에서 가져올 때 개인 수령, 균등 분배 또는 DM 배분을 선택할 수 있다.

## 미확인 아이템

서버는 실제 itemDefinitionId를 유지하지만 권한 없는 플레이어에게는 `UnknownItemPresentation`만 보낸다.

```text
실제: item.magic.sword.flame_tongue
표시: 장식된 장검
```

식별이 확정되면 공개 Presentation과 사용 가능한 Capability가 갱신된다.

## DM 도구

- 아이템 생성과 삭제
- 소유자·위치 이전
- 수량과 충전 수정
- 식별·미식별 전환
- 캠페인 보관함으로 회수
- 전리품 묶음 생성과 배분

모든 작업은 Override 명령, 감사 로그와 저장 저널을 사용한다.
