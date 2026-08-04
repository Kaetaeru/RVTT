# User Guide Quick Flow와 Flowchart 보완 감사

- 상태: ACTIVE
- 문서 종류: Completion Audit
- 감사일: 2026-08-05
- 선행 감사: [`Player·DM User Guide 완료 감사`](player-and-dm-user-guide-completion-audit.md)
- 감사 대상:
  - [`한눈에 보는 세션 흐름`](../user-guides/QUICK-FLOW.md)
  - [`User Guide Hub`](../user-guides/README.md)
  - [`Player Guide`](../user-guides/player/README.md)
  - [`DM Guide`](../user-guides/dm/README.md)
  - [`User Guide Work Order`](../user-guides/CURRENT-USER-GUIDE-WORK-ORDER.md)

## 1. 감사 목적

기존 Player·DM Guide는 역할별 상황을 상세히 설명하지만, 처음 보는 사용자가 전체 세션 구조를 빠르게 파악하기에는 길다.

이번 보완은 다음 질문을 검사한다.

1. 코딩이나 내부 시스템을 모르는 사람도 세션 흐름을 이해할 수 있는가.
2. 전체 흐름이 한 개의 주 Flowchart로 보이는가.
3. Player와 DM이 각각 무엇을 하는지 분리되어 있는가.
4. Exploration과 Encounter가 반복되는 구조가 명확한가.
5. Scene 전환, 일시정지, 재접속과 DM 복구 경로가 포함되는가.
6. Flowchart가 새 Product 동작이나 미확정 조작을 발명하지 않는가.
7. 긴 Player·DM Guide를 삭제하지 않고 상세 참고 문서로 연결하는가.

## 2. 최종 판정

```text
Quick Flow Readability
→ PASS

Implementation Terminology Removal
→ PASS

Whole Session Flowchart
→ PASS

Player Flowchart
→ PASS

DM Flowchart
→ PASS

Exploration·Encounter Loop
→ PASS

Scene Change·Reconnect·Recovery Paths
→ PASS

Detailed Guide Handoff
→ PASS

New Product Decision
→ NONE

User Guide Simplification
→ COMPLETE

Implementation Specs
→ READY TO RESUME
```

## 3. 문서 구조 판정

새 Quick Flow는 다음 순서로 구성된다.

```text
30초 요약
→ 전체 세션 흐름
→ Player 흐름
→ DM 흐름
→ Exploration·Encounter 반복
→ Scene 전환
→ 재접속
→ DM 복구
→ 역할 한 줄 정리
```

처음 읽는 사용자는 한 문서에서 전체 구조를 보고, 추가 설명이 필요할 때만 Player Guide 또는 DM Guide로 이동한다.

판정: `PASS`

## 4. Flowchart 판정

| Flowchart | 설명 | 판정 |
|---|---|---|
| 전체 세션 | 준비·입장·탐험·전투·장면 전환·일시정지·종료 | `PASS` |
| Player | 캐릭터 선택·탐험 행동·전투 차례·종료 | `PASS` |
| DM | 준비·설명·공개·판정·전투·수정·종료 | `PASS` |
| 탐험과 전투 | 탐험에서 전투로 전환하고 다시 탐험으로 복귀 | `PASS` |
| 장면 전환 | 현재 장소에서 다음 장소로 이동해 탐험 재개 | `PASS` |
| 재접속 | 다시 참가하고 현재 상태를 불러온 뒤 복귀 | `PASS` |
| DM 복구 | 일시정지·시점 선택·변경 확인·복구·재개 | `PASS` |

각 차트는 하나의 목적만 다룬다. 모든 상황을 하나의 거대한 도표에 넣지 않아 작은 화면에서도 흐름을 따라갈 수 있다.

## 5. 사용자 언어 검사

Flowchart의 단계는 다음 종류로 제한된다.

- 사용자가 하는 행동
- DM이 하는 진행 행동
- 사용자가 보는 세션 상태
- 다음으로 갈 방향을 정하는 질문

다음 구현 용어는 Quick Flow 본문과 Flowchart 단계에서 사용하지 않는다.

```text
Module
Type
Schema
Command
Network
Transaction
Projection
Authority Revision
Persistence Chunk
```

`Q`, `E`, WASD와 같은 입력은 실제 사용자가 알아야 하는 확정 조작이므로 Player 요약에만 포함한다.

판정: `PASS`

## 6. 핵심 흐름 연속성 검사

### 세션 시작

```text
DM 준비
→ Player 입장
→ 캐릭터 선택과 준비 완료
→ DM 시작
→ 탐험
```

### 전투

```text
탐험
→ 전투 발생
→ 차례대로 진행
→ 전투 종료
→ 같은 세션의 탐험으로 복귀
```

### 장면 전환

```text
현재 장소에서 이동 결정
→ DM이 다음 장면 선택
→ 새 장면 확인
→ 현재 캐릭터 상태로 탐험 계속
```

### 재접속

```text
연결 끊김
→ 다시 참가
→ 현재 상태 불러오기
→ 준비 완료 뒤 복귀
```

### DM 복구

```text
문제 발견
→ 잠시 멈춤
→ 되돌릴 시점과 변경 내용 확인
→ 복구 또는 취소
→ 세션 계속
```

모든 예외 경로는 종료 상태에 고립되지 않고 정상 진행으로 돌아갈 수 있다.

판정: `PASS`

## 7. 역할과 정보 경계

Player Flow에는 숨은 Actor, Trap 원본, 비공개 DC, DM 메모와 복구 내부 기록을 넣지 않았다.

DM Flow는 상세 시스템 구조 대신 다음 사용자 책임만 설명한다.

- 준비
- 설명
- 정보 공개
- 판정
- NPC와 환경 진행
- 전투
- 장면 전환
- 일시정지와 복구
- 종료

판정: `PASS`

## 8. 기존 상세 Guide와의 관계

```text
Quick Flow
→ 전체 흐름과 역할을 빠르게 이해

Player Guide
→ Player 조작과 상황별 자세한 설명

DM Guide
→ DM 진행과 상황별 자세한 설명
```

Quick Flow는 상세 Guide를 대체하지 않는다. User Guide Hub에서는 Quick Flow를 첫 진입점으로, Player·DM Guide를 후속 문서로 배치한다.

판정: `PASS`

## 9. Product 범위 검사

새 Flowchart는 다음 기존 범위를 유지한다.

- Exploration: 클릭과 Token WASD 이동
- Encounter: 경로 확인 후 클릭 이동
- Encounter 종료 후 Exploration 복귀
- Scene 전환 중 Character 상태 유지
- 중도 참가와 재접속 지원
- DM 일시정지와 복구 지원
- Player와 DM 정보 범위 분리
- NPC 자동 대화와 Audio는 범위 밖

새로운 버튼, 수치, 자동화 수준, 화면 위치와 규칙 결과는 추가하지 않았다.

판정: `PASS`

## 10. 완료 조건

- Quick Flow 작성: `DONE`
- 전체·Player·DM Flowchart: `DONE`
- 반복·Scene 전환·재접속·복구 Flowchart: `DONE`
- User Guide Hub 첫 진입점 변경: `DONE`
- Root·Remake Hub 연결: 완료 갱신 대상
- User Guide Work Order 종료: 완료 갱신 대상
- GitHub Actions 문서 검증: 최종 Commit에서 확인

허브와 Work Order 갱신 및 문서 검증이 성공하면 User Guide 간소화 보완을 `COMPLETE`로 종료하고 Implementation Specs로 복귀한다.
