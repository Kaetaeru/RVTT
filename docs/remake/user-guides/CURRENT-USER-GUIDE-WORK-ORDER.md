# Player·DM User Guide 현재 작업 순서

- 상태: ACTIVE
- 문서 종류: User Guide Work Order
- 최종 갱신일: 2026-08-05
- 상위 작업 순서: [`../CURRENT-WORK-ORDER.md`](../CURRENT-WORK-ORDER.md)
- 선행 단계: Main System Guides `COMPLETE`
- 기존 완료 감사: [`Player·DM User Guide 완료 감사`](../audits/player-and-dm-user-guide-completion-audit.md)

이 문서는 구현 명세 전에 작성하는 **플레이어와 DM 관점의 사용자 가이드** 세부 작업 순서다.

기존 Player Guide와 DM Guide는 상세 참고 문서로 유지한다. 현재 보완 작업은 내부 구조와 코딩 용어를 모두 제거한 짧은 Session Flow와 명확한 Flowchart를 먼저 제공하는 것이다.

## 운영 규칙

1. User Guide는 확정된 Product·System·UI와 Main System Guide를 사용자 언어로 번역한다.
2. 아직 구현되지 않은 기능은 `목표 사용자 경험`으로 표시한다.
3. Module, Type, Command, Schema, Transaction, Projection 같은 구현 용어를 Quick Flow에 사용하지 않는다.
4. 확정되지 않은 버튼 위치, 단축키, 수치와 화면 이름을 만들지 않는다.
5. Quick Flow는 한 화면에서 전체 흐름을 이해할 수 있을 정도로 짧게 유지한다.
6. Flowchart는 Player 행동, DM 행동, 공통 세션 상태를 구분한다.
7. Player에게 공개되지 않는 DM 비밀과 내부 진단 정보를 노출하지 않는다.
8. 제품 비목표인 NPC 자동 대화, 음악, 환경음과 효과음을 지원 기능처럼 설명하지 않는다.

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
| 1 | `DONE` | User Guide 허브와 공통 범위 | 목표 경험 상태와 Player·DM 문서 구분 확정 |
| 2 | `DONE` | Player Guide | 접속부터 종료까지 상세 Player 흐름 작성 |
| 3 | `DONE` | DM Guide | 준비부터 종료까지 상세 DM 흐름 작성 |
| 4 | `DONE` | 최초 User Guide 완료 감사 | 역할·비밀·입력·비목표 정합성 검사 |
| 5 | `IN_PROGRESS` | 간단한 Session Flow와 Flowchart | 코딩 용어 없는 전체·Player·DM 흐름과 분기 Flowchart 작성 |
| 6 | `QUEUED` | User Guide Hub·상세 Guide 연결 | Quick Flow를 첫 읽기 문서로 연결하고 상세 Guide를 후속 참고로 배치 |
| 7 | `QUEUED` | 간소화 보완 감사와 문서 검증 | 흐름 누락·과도한 세부사항·Mermaid 링크와 문서 검증 확인 |

## Quick Flow 작성 기준

```text
전체 Session Flow
→ Player Flow
→ DM Flow
→ Exploration·Encounter 반복 흐름
→ Scene 전환·중단·재접속·종료 예외 흐름
```

각 단계는 사용자가 실제로 하는 행동이나 눈으로 확인하는 상태만 적는다.

좋은 표현:

```text
캐릭터 선택
→ 준비 완료
→ 장면 입장
→ 탐험
```

사용하지 않는 표현:

```text
Control Assignment
→ Scene Projection 동기화
→ Command 검증
→ Transaction Commit
```

## 공통 완료 조건

- [ ] Quick Flow에 구현·코딩 용어가 없다.
- [ ] 전체 세션 흐름이 한 개의 주 Flowchart로 보인다.
- [ ] Player와 DM의 역할이 Swimlane 또는 Subgraph로 구분된다.
- [ ] Exploration과 Encounter가 같은 세션 안에서 반복되는 구조가 보인다.
- [ ] Scene 전환, 일시정지, 재접속과 종료 경로가 보인다.
- [ ] Player Guide와 DM Guide는 상세 참고 문서로 연결된다.
- [ ] User Guide Hub에서 Quick Flow를 가장 먼저 읽게 한다.
- [ ] 현재 확정 범위와 비목표를 위반하지 않는다.
- [ ] 문서 검증 Workflow가 성공한다.

## 변경 기록

| 날짜 | 변경 |
|---|---|
| 2026-08-05 | 사용자 요청에 따라 완료된 User Guide 단계를 다시 열고, 코딩 요소 없는 간단한 Session Flow와 명확한 Flowchart 보완을 시작했다. |
| 2026-08-05 | Player Guide, DM Guide, Hub와 최초 Completion Audit을 완료했다. |
| 2026-08-05 | Implementation Specs 전에 Player·DM User Guide 단계를 삽입했다. |
