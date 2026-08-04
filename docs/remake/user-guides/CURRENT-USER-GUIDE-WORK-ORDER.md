# Player·DM User Guide 현재 작업 순서

- 상태: COMPLETE
- 문서 종류: User Guide Work Order
- 최종 갱신일: 2026-08-05
- 상위 작업 순서: [`../CURRENT-WORK-ORDER.md`](../CURRENT-WORK-ORDER.md)
- 선행 단계: Main System Guides `COMPLETE`
- 완료 감사: [`Player·DM User Guide 완료 감사`](../audits/player-and-dm-user-guide-completion-audit.md)

이 문서는 구현 명세 전에 작성한 **플레이어와 DM 관점의 사용자 가이드** 세부 작업 순서 기록이다.

Player·DM User Guide 단계는 완료됐다. 실제 구현이나 사용자 경험 권위 문서가 변경되면 관련 Guide를 `UPDATE_REQUIRED`로 다시 연다.

## 운영 규칙

1. User Guide는 확정된 Product·Architecture·System·UI·ADR과 Main System Guide를 사용자 언어로 번역한다.
2. 아직 구현되지 않은 기능을 현재 사용할 수 있는 기능처럼 표현하지 않고 `목표 사용자 경험`임을 명시한다.
3. 확정되지 않은 버튼 위치, 단축키, 수치, 화면 이름과 자동화 범위를 임의로 만들지 않는다.
4. 확정된 입력 의미인 `Q`, `E`, `1–5`와 Exploration·Encounter 이동 차이는 그대로 사용한다.
5. 내부 Type·Schema·Command·Transaction 이름은 사용자 이해에 꼭 필요한 경우가 아니면 본문에서 사용하지 않는다.
6. Player Client에 공개되지 않는 비밀 정보, 내부 진단 정보와 DM 전용 흐름을 Player Guide에 노출하지 않는다.
7. 제품 비목표인 NPC 대화 시스템, 음악, 환경음과 규칙 효과음을 지원 기능처럼 설명하지 않는다.
8. 권위 문서나 실제 Build가 변경되어 사용자 경험이 달라지면 관련 User Guide를 `UPDATE_REQUIRED`로 되돌린다.

상태 값:

```text
IN_PROGRESS
QUEUED
BLOCKED
DONE
UPDATE_REQUIRED
DEFERRED
```

## 완료 순서

| 순서 | 상태 | 작업 | 완료 조건 |
|---:|---|---|---|
| 1 | `DONE` | User Guide 허브와 공통 범위 | 목표 경험 상태, Player·DM 문서 구분, 확정·미확정 정보 표기 규칙과 탐색 경로 확정 |
| 2 | `DONE` | Player Guide | 접속·Character·Exploration·행동·Encounter·Sheet·Inventory·Journal·Reconnect 흐름을 Player 언어로 통합 |
| 3 | `DONE` | DM Guide | Campaign 준비·세션 시작·진행·Fog·판정·Encounter·Scene 편집·Rollback·종료 흐름을 DM 언어로 통합 |
| 4 | `DONE` | User Guide 일관성 감사와 문서 허브 갱신 | Player·DM 책임 분리, 비목표·확정 상태·링크 검사와 User Guide 단계 완료 판정 |

## 완료 문서

- [`User Guide Hub`](README.md)
- [`Player Guide`](player/README.md)
- [`DM Guide`](dm/README.md)
- [`Player·DM User Guide 완료 감사`](../audits/player-and-dm-user-guide-completion-audit.md)

## 완료 결과

```text
User Guide Hub
→ DONE

Player Guide
→ DONE

DM Guide
→ DONE

Role·Disclosure Audit
→ PASS

Input·Movement Audit
→ PASS

Recovery·Rollback Guidance
→ PASS

Player·DM User Guide Phase
→ COMPLETE

Next Phase
→ Implementation Specs
```

현재 두 Guide의 상태는 구현 전 목표 경험인 `TARGET_EXPERIENCE`다.

실제 Build와 Release 단계에서는 다음 상태로 다시 검증한다.

```text
TARGET_EXPERIENCE
→ CURRENT_FOR_BUILD
→ RELEASE_VERIFIED
```

## 공통 완료 조건 확인

- [x] 문서 첫머리에 구현 전 목표 경험임을 명시했다.
- [x] Architecture 문서를 읽지 않고 기본 세션 흐름을 이해할 수 있다.
- [x] Exploration, Encounter, Downtime과 DM Authoring 상태를 사용자 관점에서 구분했다.
- [x] Q·E와 현재 화면에 표시되는 1–5 행동 슬롯의 의미를 설명했다.
- [x] Player Guide에서 DM 비밀과 내부 권위 데이터를 노출하지 않았다.
- [x] DM Guide에서 Live DM Mode, Quick Edit와 Full Scene Edit를 구분했다.
- [x] 재접속, 동기화, Rollback과 오류 상태의 사용자 대응을 설명했다.
- [x] 확정되지 않은 키·수치·레이아웃에 임의 기본값을 넣지 않았다.
- [x] Root·Remake·Audit·Spec Hub에서 User Guide로 이동할 수 있다.
- [x] 최신 확정 Product Scope와 비목표를 사용했다.

## 알려진 후속 정리

- [`product/core-session-loop.md`](../product/core-session-loop.md)는 오래된 `상태: 초안` 문서다.
- 현재 범위와 다른 Encounter Token WASD·Audio 표현이 남아 있다.
- 현재 User Guide와 Implementation Spec의 권위 읽기 순서에서 제외한다.
- 후속 문서 수명주기 정리에서 User Guide로 대체하거나 최신 Product Scope에 맞게 갱신한다.

이 항목은 현재 User Guide 완료를 차단하지 않는다. 이동과 제외 기능은 최신 확정 Product Scope가 명확히 소유한다.

## 변경 기록

| 날짜 | 변경 |
|---|---|
| 2026-08-05 | Player Guide, DM Guide, Hub와 Completion Audit을 완료하고 User Guide 단계를 `COMPLETE`로 종료했다. 다음 단계는 Implementation Specs다. |
| 2026-08-05 | Implementation Specs 전에 Player·DM User Guide 단계를 삽입하고 최초 작업 순서를 확정했다. |
