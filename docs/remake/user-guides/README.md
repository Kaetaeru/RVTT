# RVTT Player·DM User Guides

- 상태: ACTIVE
- 문서 종류: User Guide Index
- 사용자 가이드 상태: `TARGET_EXPERIENCE`
- 최종 갱신일: 2026-08-05
- 세부 작업 순서: [`CURRENT-USER-GUIDE-WORK-ORDER.md`](CURRENT-USER-GUIDE-WORK-ORDER.md)

이 폴더는 내부 시스템 구조가 아니라 **플레이어와 DM이 실제 세션에서 무엇을 하는지**를 설명한다.

현재 문서는 구현 전 목표 사용자 경험이다. 실제 Release가 나온 뒤 화면과 조작을 다시 검증한다.

## 처음 읽을 문서

### [`한눈에 보는 세션 흐름`](QUICK-FLOW.md)

코딩 용어 없이 다음을 짧은 설명과 Flowchart로 보여 준다.

- 전체 세션 시작부터 종료까지
- Player의 기본 플레이 흐름
- DM의 기본 진행 흐름
- Exploration과 Encounter의 반복
- Scene 전환
- 재접속
- DM 복구

RVTT를 처음 이해하려면 이 문서 하나를 먼저 읽는다.

```text
한눈에 보는 세션 흐름
→ 필요한 역할의 상세 Guide
```

## 상세 가이드

### [`Player Guide`](player/README.md)

다음 상황의 자세한 설명이 필요할 때 읽는다.

- 세션 접속과 Character 선택
- Camera와 입력
- Exploration 이동과 상호작용
- Action·Spell·Dice·Reaction
- Encounter 진행
- Character Sheet·Inventory·Downtime
- Journal·Ping
- 재접속·동기화·Rollback 대응

### [`DM Guide`](dm/README.md)

다음 상황의 자세한 설명이 필요할 때 읽는다.

- Campaign과 Session 준비
- Lobby·Role·Character·Control 관리
- Live DM 진행
- Exploration·Fog·비밀 정보·판정
- Encounter 시작·진행·종료
- Quick Action과 수동 개입
- Scene Editor·Test Play·Publish
- Journal·Player View 확인
- Recovery·Rollback·세션 종료

## 역할별 가장 짧은 흐름

### Player

```text
세션 참가
→ 캐릭터 선택
→ 준비 완료
→ 탐험
→ 필요하면 전투
→ 다시 탐험
→ 세션 종료
```

### DM

```text
캠페인과 장면 준비
→ 플레이어 준비 확인
→ 세션 시작
→ 탐험 진행
→ 필요하면 전투·장면 전환·일시정지
→ 결과 확인
→ 세션 종료
```

## 확정된 사용자 경험 기준

- 초기 지원 환경은 PC 키보드·마우스다.
- 기본 Ruleset은 `dnd5e-2024`, 기본 표시 언어는 `ko-KR`이다.
- 플레이어와 DM은 3D 미니어처 Token을 다룬다.
- Exploration에서는 목적지 클릭과 Token WASD 이동을 지원한다.
- Encounter에서는 경로를 확인한 뒤 클릭으로 이동한다.
- Encounter 중 WASD는 Camera 이동에 사용한다.
- `Q`는 취소·거절·한 단계 뒤로다.
- `E`는 승인·확정·실행·상호작용이다.
- `1–5`는 현재 화면에 의미가 표시된 경우에만 주요 행동으로 사용한다.
- Camera 이동만으로 Character 위치나 공개 정보가 바뀌지 않는다.
- Player와 DM은 서로 다른 정보와 권한을 본다.
- 중도 참가, 재접속, 복구와 DM Rollback을 목표로 한다.
- NPC 자동 대화, 음악, 환경음과 효과음은 현재 범위가 아니다.
- 모바일·게임패드·터치는 초기 지원 범위가 아니다.

## 아직 확정하지 않는 것

- 최종 화면의 정확한 배치
- Q·E·1–5 외 기능의 최종 기본 단축키
- Camera 감도와 확대 범위
- 안내 메시지의 정확한 표시 시간
- 자동 저장 주기와 재시도 횟수
- Animation·VFX의 정확한 시간
- 성능 수치와 최대 표시 개수

가이드에 없는 조작을 임의로 추가하지 않는다. 새로운 사용자 행동이 필요하면 제품·UI 결정을 먼저 갱신한다.

## 문서 역할

```text
Quick Flow
→ 처음 보는 사용자가 전체 세션을 이해한다

Player·DM Guide
→ 역할별 상황과 조작을 자세히 확인한다

Main System Guide
→ 시스템 문서 사이의 책임과 연결을 확인한다

Implementation Spec
→ 실제 구현 계약을 정의한다
```

현재 Quick Flow, Player Guide와 DM Guide의 상태는 모두 `TARGET_EXPERIENCE`다.
