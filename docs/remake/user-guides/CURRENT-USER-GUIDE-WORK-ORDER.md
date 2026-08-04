# Player·DM User Guide 현재 작업 순서

- 상태: ACTIVE
- 문서 종류: User Guide Work Order
- 최종 갱신일: 2026-08-05
- 상위 작업 순서: [`../CURRENT-WORK-ORDER.md`](../CURRENT-WORK-ORDER.md)
- 선행 단계: Main System Guides `COMPLETE`

이 문서는 구현 명세 전에 작성하는 **플레이어와 DM 관점의 사용자 가이드** 세부 작업 순서다.

User Guide는 내부 Runtime 구조를 설명하는 Main System Guide가 아니다. 사용자가 세션에 들어와 무엇을 보고, 어떤 순서로 조작하고, 문제가 생겼을 때 어떻게 대응하는지를 실제 플레이 흐름으로 설명한다.

## 운영 규칙

1. User Guide는 확정된 Product·Architecture·System·UI·ADR과 Main System Guide를 사용자 언어로 번역한다.
2. 아직 구현되지 않은 기능을 현재 사용할 수 있는 기능처럼 표현하지 않고 `목표 사용자 경험`임을 명시한다.
3. 확정되지 않은 버튼 위치, 단축키, 수치, 화면 이름과 자동화 범위를 임의로 만들지 않는다.
4. 확정된 입력 의미인 `Q`, `E`, `1–5`와 탐험·전투 이동 차이는 그대로 사용한다.
5. 내부 Type·Schema·Command·Transaction 이름은 사용자 이해에 꼭 필요한 경우가 아니면 본문에서 사용하지 않는다.
6. Player Client에 공개되지 않는 비밀 정보, 내부 진단 정보와 DM 전용 흐름을 Player Guide에 노출하지 않는다.
7. 제품 비목표인 NPC 대화 시스템, 음악, 환경음과 규칙 효과음을 지원 기능처럼 설명하지 않는다.
8. 권위 문서가 변경되어 사용자 경험이 달라지면 관련 User Guide를 `UPDATE_REQUIRED`로 되돌린다.

상태 값:

```text
IN_PROGRESS
QUEUED
BLOCKED
DONE
UPDATE_REQUIRED
DEFERRED
```

## 현재 순서

| 순서 | 상태 | 작업 | 완료 조건 |
|---:|---|---|---|
| 1 | `IN_PROGRESS` | User Guide 허브와 공통 범위 | 목표 경험 상태, Player·DM 문서 구분, 확정·미확정 정보 표기 규칙과 탐색 경로 확정 |
| 2 | `QUEUED` | Player Guide | 접속·캐릭터·탐험·행동·전투·시트·인벤토리·저널·재접속 흐름을 플레이어 언어로 통합 |
| 3 | `QUEUED` | DM Guide | 캠페인 준비·세션 시작·진행·Fog·판정·Encounter·Scene 편집·Rollback·종료 흐름을 DM 언어로 통합 |
| 4 | `QUEUED` | User Guide 일관성 감사와 문서 허브 갱신 | Player·DM 책임 분리, 비목표·확정 상태·링크 검사와 User Guide 단계 완료 판정 |

## 작성 순서

```text
현재 제품 상태와 비목표 확인
→ 역할별 한 세션 흐름 정리
→ 화면에서 보이는 행동과 피드백 정리
→ 오류·재접속·복구 안내 정리
→ 내부 용어 제거 또는 사용자 표현으로 치환
→ Player·DM 사이의 비밀 정보 경계 검사
→ 문서 허브와 Work Order 갱신
→ 문서 검증
```

## 공통 완료 조건

- 문서 첫머리에 현재 문서가 구현 전 목표 경험임을 명시한다.
- 처음 접속한 사용자가 별도 Architecture 문서를 읽지 않고 기본 흐름을 이해할 수 있다.
- 탐험, Encounter, Downtime과 DM Authoring 상태를 사용자 관점에서 구분한다.
- Q·E와 현재 화면에 표시되는 1–5 행동 슬롯의 의미를 설명한다.
- Player Guide는 DM 비밀과 내부 권위 데이터를 노출하지 않는다.
- DM Guide는 Live DM Mode와 Full Scene Edit의 차이를 설명한다.
- 재접속, 동기화, Rollback과 오류 상태에서 사용자가 해야 할 일을 설명한다.
- 확정되지 않은 키·수치·레이아웃에는 임의 기본값을 넣지 않는다.
- 관련 문서 허브에서 Player·DM Guide로 이동할 수 있다.
- 문서 검증 Workflow가 성공한다.

## 변경 기록

| 날짜 | 변경 |
|---|---|
| 2026-08-05 | Implementation Specs 전에 Player·DM User Guide 단계를 삽입하고 최초 작업 순서를 확정했다. |
