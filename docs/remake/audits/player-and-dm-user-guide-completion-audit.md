# Player·DM User Guide 완료 감사

- 상태: ACTIVE
- 문서 종류: Completion Audit
- 감사일: 2026-08-05
- 감사 대상:
  - `docs/remake/user-guides/README.md`
  - `docs/remake/user-guides/player/README.md`
  - `docs/remake/user-guides/dm/README.md`
  - `docs/remake/user-guides/CURRENT-USER-GUIDE-WORK-ORDER.md`
  - `docs/remake/README.md`
  - `docs/remake/CURRENT-WORK-ORDER.md`
- 선행 감사: [`Main System Guide 일관성과 문서 허브 완료 감사`](main-system-guide-consistency-and-document-hub-completion-audit.md)

## 1. 감사 목적

이 감사는 구현 명세 전에 작성한 Player·DM User Guide가 현재 제품 범위와 Main System Guide를 사용자 관점으로 정확히 번역했는지 확인한다.

검토 질문:

1. Player와 DM의 한 세션 흐름이 내부 Runtime 설명 없이 이해 가능한가.
2. 현재 문서가 배포 기능 설명이 아니라 구현 전 `TARGET_EXPERIENCE`임을 분명히 하는가.
3. Player Guide와 DM Guide의 권한·비밀 정보 경계가 분리되는가.
4. Q·E·1–5와 Exploration·Encounter 이동 방식이 현재 확정 범위와 일치하는가.
5. Session Join·Hot Join·Reconnect·Recovery·Rollback 흐름을 사용자 행동으로 설명하는가.
6. Live DM Mode, Quick Edit와 Full Scene Edit를 구분하는가.
7. NPC 대화 시스템과 Audio 비목표를 지원 기능처럼 표현하지 않는가.
8. 확정되지 않은 화면 위치, 단축키, 수치와 자동화 범위를 발명하지 않는가.
9. User Guide가 새로운 Product·Architecture 결정을 만들지 않는가.
10. Implementation Specs 단계로 다시 전환할 수 있는가.

## 2. 최종 판정

```text
User Guide Hub
→ PASS

Player Guide
→ PASS

DM Guide
→ PASS

Role·Disclosure Separation
→ PASS

Input·Movement Consistency
→ PASS

Reconnect·Recovery·Rollback Guidance
→ PASS

Product Exclusion Consistency
→ PASS

Unconfirmed UI·Default Invention
→ NONE FOUND

Player·DM User Guide Phase
→ COMPLETE

Implementation Specs Phase
→ READY TO RESUME

Production Implementation
→ NOT STARTED
```

Player·DM User Guide 단계는 현재 제품 범위에서 완료됐다.

두 Guide는 실제 Release가 아닌 구현 전 목표 경험이므로 상태는 `TARGET_EXPERIENCE`다. 실제 구현과 사용성 테스트가 끝난 뒤 `CURRENT_FOR_BUILD`, `RELEASE_VERIFIED` 상태로 별도 검증해야 한다.

## 3. 문서별 판정

| 문서 | 사용자 | 주요 범위 | 상태 | 판정 |
|---|---|---|---|---|
| [`User Guide Hub`](../user-guides/README.md) | 공통 | 상태·범위·읽기 순서·확정/미확정 기준 | `TARGET_EXPERIENCE` | `PASS` |
| [`Player Guide`](../user-guides/player/README.md) | Player·Observer | Join·Input·Exploration·Rules·Encounter·Character·Journal·Recovery | `TARGET_EXPERIENCE` | `PASS` |
| [`DM Guide`](../user-guides/dm/README.md) | DM | 준비·진행·Fog·판정·Encounter·Authoring·Rollback·종료 | `TARGET_EXPERIENCE` | `PASS` |

## 4. 사용자 관점 감사

Player Guide는 다음 흐름을 한 문서에서 제공한다.

```text
Campaign 접속
→ Character 선택·Ready
→ Scene 동기화
→ Exploration
→ Action·Spell·Roll
→ Encounter
→ Character·Inventory·Downtime
→ Journal·Ping
→ Reconnect·Rollback 대응
```

DM Guide는 다음 흐름을 한 문서에서 제공한다.

```text
Campaign·Scene·Character 준비
→ Player Lobby·Control 확인
→ Exploration 진행
→ Fog·판정·Quick Action
→ Encounter 시작·진행·종료
→ Character·Downtime 관리
→ Scene Compile·Publish·Live Patch
→ Recovery·Rollback
→ 세션 종료
```

두 Guide는 내부 Type·Schema·Module 이름보다 사용자가 보게 되는 선택, 상태와 피드백을 우선한다.

판정: `PASS`

## 5. 입력과 이동 일관성

확인한 고정 기준:

```text
Q
→ 취소·거절·한 단계 뒤로

E
→ 승인·확정·실행·상호작용

1–5
→ 현재 화면에 Label이 표시된 주요 행동 슬롯
```

이동 기준:

- Exploration: 목적지 클릭과 Token WASD
- Encounter: 경로 확인 후 클릭 이동만 지원
- Encounter 중 WASD: Camera 이동에 사용 가능
- Client Preview와 움직임은 최종 권위 위치가 아님
- Grid는 제작·표시 보조이며 Token 위치를 5 ft Cell 중심에 강제하지 않음

판정: `PASS`

## 6. 역할과 비밀 정보 경계

Player Guide는 다음 DM 전용 정보를 사용자 기능으로 설명하지 않는다.

- 숨은 Actor·Trap·Secret Object 원본
- 실제 비밀 HP·AC·DC
- DM 전용 Journal·Anchor·Search Index
- Raw Diagnostic과 내부 Runtime ID
- Scene Source와 Compiler Diagnostic
- 비공개 Roll·Objective

DM Guide는 Player View Preview가 실제 Player 공개 범위를 사용해야 한다고 설명한다. Camera 이동, Observer Role과 Control Assignment도 정보 공개와 별개로 유지한다.

판정: `PASS`

## 7. User Guide가 유지한 핵심 제품 경계

- Character와 Scene Token을 같은 데이터로 설명하지 않음
- Character Owner, 현재 Controller와 Session Role을 구분
- Camera 이동이 Character 위치·시야·공개 정보를 바꾸지 않음
- Preview가 최종 행동 결과를 보장하지 않음
- Dice Animation과 Client Physics를 권위 결과로 사용하지 않음
- Encounter 종료 후 HP·위치·Object·Effect 상태 유지
- Item Pickup·Drop을 복사본 생성으로 설명하지 않음
- Downtime을 현실 Offline 시간 자동 진행으로 설명하지 않음
- Quick Edit를 Scene Source 자동 저장으로 설명하지 않음
- Publish와 현재 Session Live Patch를 구분
- Rollback을 반대 명령 반복이나 사람의 기억 삭제로 설명하지 않음

판정: `PASS`

## 8. 비목표 일관성

두 Guide와 Hub는 다음 기능을 현재 범위 밖으로 명시한다.

- NPC 자동 대화 Tree와 전용 대화 UI
- 음악 재생과 Playlist
- 환경음
- 주문·공격·UI SFX
- 음성 채팅과 음성 대사
- 모바일·게임패드·터치 초기 지원
- 일반 사용자 임의 Luau Plugin
- 외부 URL Code 자동 설치
- 모든 즉흥 행동의 완전 자동화

판정: `PASS`

## 9. 오래된 사용자 흐름 초안

감사 중 [`product/core-session-loop.md`](../product/core-session-loop.md)에 현재 확정 범위와 다른 오래된 표현이 남아 있음을 확인했다.

대표 차이:

- Encounter에서도 Token WASD를 사용할 수 있다는 표현
- 세션 시작 준비에 음악과 오디오 연출을 포함하는 표현

현재 판정에는 다음 최신 확정 문서를 사용한다.

- [`플랫폼·이동·입력 범위`](../product/platform-movement-and-input-scope.md)
- [`콘텐츠 범위·자동화·Rollback·저장·제외 기능`](../product/content-automation-rollback-storage-and-exclusions.md)
- 현재 Main System Guides
- Player·DM User Guides

`core-session-loop.md`는 `상태: 초안`이며 Player·DM User Guide의 Authority Documents와 추천 읽기 순서에서 제외한다. 후속 문서 수명주기 정리에서 현재 User Guide로 대체하거나 최신 범위에 맞게 갱신해야 한다.

이 오래된 초안은 현재 User Guide 완료를 차단하지 않는다. 최신 확정 Product Scope가 이동과 제외 기능을 명확히 소유하고 있고, 새 User Guide가 그 범위를 따르기 때문이다.

## 10. 미확정 정보 검사

User Guide가 임의로 확정하지 않은 항목:

- Q·E·1–5 외 최종 기본 단축키
- 최종 Panel 위치와 Pixel Layout
- Camera 감도·속도·확대 범위
- Timeout·Retry·Auto Save 주기
- Fog Assist의 수치 기본값
- 성능 Budget과 최대 표시 수
- Animation·VFX 정확한 시간
- Quick Action을 여는 물리 키

판정: `PASS`

## 11. Implementation Specs로의 전달 사항

Implementation Specs는 User Guide의 목표 흐름을 다음 수직 Slice와 Acceptance Scenario에 연결해야 한다.

### 첫 Player Slice

```text
Join
→ Character·Control 확인
→ Scene Ready
→ Exploration 이동
→ Projection 적용
→ Disconnect·Reconnect
```

### 첫 DM Slice

```text
Campaign Resume
→ Player Ready 확인
→ Scene Start
→ Actor·Fog Quick Action
→ Player View Preview
→ Save·Recovery 상태 확인
```

Spec은 User Guide 문장을 Type·Command 권위로 사용하지 않는다. User Guide가 연결한 Product·Architecture·System·UI·ADR을 근거로 실제 계약을 작성한다.

## 12. 완료 조건

- Player Guide 작성: `DONE`
- DM Guide 작성: `DONE`
- Hub와 역할 분리: `DONE`
- 최신 Product Scope와 비목표 대조: `DONE`
- 오래된 초안 제외 기록: `DONE`
- Root·Remake·Audit Hub 연결: 완료 갱신 대상
- User Guide Work Order 종료: 완료 갱신 대상
- GitHub Actions 문서 검증: 최종 Commit에서 확인

허브와 Work Order 갱신 및 문서 검증이 성공하면 Player·DM User Guide 단계를 `COMPLETE`로 종료한다.
