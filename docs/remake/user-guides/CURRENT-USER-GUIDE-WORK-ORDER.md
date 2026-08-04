# Player·DM User Guide 현재 작업 순서

- 상태: COMPLETE
- 문서 종류: User Guide Work Order
- 최종 갱신일: 2026-08-05
- 상위 작업 순서: [`../CURRENT-WORK-ORDER.md`](../CURRENT-WORK-ORDER.md)
- 선행 단계: Main System Guides `COMPLETE`
- 최초 완료 감사: [`Player·DM User Guide 완료 감사`](../audits/player-and-dm-user-guide-completion-audit.md)
- 간소화 완료 감사: [`User Guide Quick Flow와 Flowchart 보완 감사`](../audits/user-guide-quick-flow-and-flowchart-audit.md)

이 문서는 구현 명세 전에 작성한 **플레이어와 DM 관점의 사용자 가이드** 세부 작업 순서 기록이다.

기존 상세 Player·DM Guide와 코딩 용어 없는 Quick Flow·Flowchart 보완은 완료됐다. 실제 구현이나 사용자 경험 권위 문서가 변경되면 관련 문서를 `UPDATE_REQUIRED`로 다시 연다.

## 운영 규칙

1. User Guide는 확정된 Product·System·UI와 Main System Guide를 사용자 언어로 번역한다.
2. 아직 구현되지 않은 기능은 `목표 사용자 경험`으로 표시한다.
3. Quick Flow에는 Module, Type, Command, Schema, Transaction, Projection 같은 구현 용어를 사용하지 않는다.
4. 확정되지 않은 버튼 위치, 단축키, 수치와 화면 이름을 만들지 않는다.
5. Quick Flow는 한 문서에서 전체 흐름을 빠르게 이해할 수 있게 유지한다.
6. Player에게 공개되지 않는 DM 비밀과 내부 진단 정보를 노출하지 않는다.
7. 제품 비목표인 NPC 자동 대화, 음악, 환경음과 효과음을 지원 기능처럼 설명하지 않는다.

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
| 1 | `DONE` | User Guide 허브와 공통 범위 | 목표 경험 상태와 Player·DM 문서 구분 확정 |
| 2 | `DONE` | Player Guide | 접속부터 종료까지 상세 Player 흐름 작성 |
| 3 | `DONE` | DM Guide | 준비부터 종료까지 상세 DM 흐름 작성 |
| 4 | `DONE` | 최초 User Guide 완료 감사 | 역할·비밀·입력·비목표 정합성 검사 |
| 5 | `DONE` | 간단한 Session Flow와 Flowchart | 코딩 용어 없는 전체·Player·DM 흐름과 분기 Flowchart 작성 |
| 6 | `DONE` | User Guide Hub·상세 Guide 연결 | Quick Flow를 첫 읽기 문서로 연결하고 상세 Guide를 후속 참고로 배치 |
| 7 | `DONE` | 간소화 보완 감사와 문서 검증 | 흐름 누락·과도한 세부사항·링크와 문서 검증 확인 |

## 완료 문서

- [`한눈에 보는 세션 흐름`](QUICK-FLOW.md)
- [`User Guide Hub`](README.md)
- [`Player Guide`](player/README.md)
- [`DM Guide`](dm/README.md)
- [`Player·DM User Guide 완료 감사`](../audits/player-and-dm-user-guide-completion-audit.md)
- [`User Guide Quick Flow와 Flowchart 보완 감사`](../audits/user-guide-quick-flow-and-flowchart-audit.md)

## Quick Flow 구조

```text
30초 요약
→ 전체 세션 Flowchart
→ Player Flowchart
→ DM Flowchart
→ Exploration·Encounter 반복
→ Scene 전환
→ 재접속
→ DM 복구
→ 역할 한 줄 정리
```

Flowchart는 사용자 행동과 보이는 세션 상태만 사용한다. 자세한 조작과 상황 설명은 Player Guide와 DM Guide가 담당한다.

## 완료 결과

```text
Quick Flow Readability
→ PASS

Implementation Terminology Removal
→ PASS

Whole Session Flowchart
→ PASS

Player·DM Role Separation
→ PASS

Exploration·Encounter Loop
→ PASS

Scene Change·Reconnect·Recovery
→ PASS

Player·DM User Guide Phase
→ COMPLETE

Next Phase
→ Implementation Specs
```

현재 문서 상태는 구현 전 목표 경험인 `TARGET_EXPERIENCE`다.

실제 Build와 Release 단계에서는 다음 상태로 다시 검증한다.

```text
TARGET_EXPERIENCE
→ CURRENT_FOR_BUILD
→ RELEASE_VERIFIED
```

## 공통 완료 조건 확인

- [x] Quick Flow에 구현·코딩 용어를 넣지 않았다.
- [x] 전체 세션 흐름을 한 개의 주 Flowchart로 제공한다.
- [x] Player와 DM의 역할별 Flowchart를 제공한다.
- [x] Exploration과 Encounter가 반복되는 구조를 보여 준다.
- [x] Scene 전환, 일시정지, 재접속과 DM 복구 경로를 보여 준다.
- [x] Player Guide와 DM Guide를 상세 참고 문서로 연결한다.
- [x] User Guide Hub에서 Quick Flow를 가장 먼저 읽게 한다.
- [x] Player 비밀 정보 경계를 지켰다.
- [x] 확정되지 않은 키·수치·레이아웃을 발명하지 않았다.
- [x] Root·Remake·Audit·Spec Hub에서 Quick Flow로 이동할 수 있다.
- [x] 최신 확정 Product Scope와 비목표를 유지했다.

## 알려진 후속 정리

- [`product/core-session-loop.md`](../product/core-session-loop.md)는 오래된 `상태: 초안` 문서다.
- 현재 범위와 다른 Encounter Token WASD·Audio 표현이 남아 있다.
- 현재 User Guide와 Implementation Spec의 권위 읽기 순서에서 제외한다.
- 후속 문서 수명주기 정리에서 Quick Flow로 대체하거나 최신 Product Scope에 맞게 갱신한다.

## 변경 기록

| 날짜 | 변경 |
|---|---|
| 2026-08-05 | 코딩 용어 없는 Quick Flow, 7개 Flowchart, Hub 연결과 간소화 보완 감사를 완료했다. 다음 단계는 Implementation Specs다. |
| 2026-08-05 | 사용자 요청에 따라 완료된 User Guide 단계를 다시 열고 간단한 Session Flow와 Flowchart 보완을 시작했다. |
| 2026-08-05 | Player Guide, DM Guide, Hub와 최초 Completion Audit을 완료했다. |
| 2026-08-05 | Implementation Specs 전에 Player·DM User Guide 단계를 삽입했다. |
