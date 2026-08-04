# RVTT Player·DM User Guides

- 상태: ACTIVE
- 문서 종류: User Guide Index
- 사용자 가이드 상태: `TARGET_EXPERIENCE`
- 최종 갱신일: 2026-08-05
- 세부 작업 순서: [`CURRENT-USER-GUIDE-WORK-ORDER.md`](CURRENT-USER-GUIDE-WORK-ORDER.md)

이 폴더는 RVTT의 내부 시스템 구조가 아니라 **플레이어와 DM이 실제 세션에서 무엇을 보고 어떻게 행동하는지**를 설명한다.

현재 RVTT Remake는 구현 전 설계 단계다. 따라서 이 문서들은 현재 배포된 기능의 사용 설명서가 아니라, 구현과 테스트가 따라야 할 **목표 사용자 경험**이다.

## 사용자 가이드

### 플레이어

- [`Player Guide`](player/README.md)
  - 세션 접속과 캐릭터 선택
  - 카메라와 공통 입력
  - 탐험 이동과 상호작용
  - 행동·주문·주사위·반응
  - Encounter 진행
  - Character Sheet·Inventory·Downtime
  - Journal·Ping
  - 재접속·동기화·Rollback 대응

### DM

- [`DM Guide`](dm/README.md)
  - 캠페인과 세션 준비
  - Lobby·Role·Character·Control 관리
  - Live DM Mode와 DM Workspace
  - 탐험·Fog·비밀 정보·판정 진행
  - Encounter 시작·진행·종료
  - Quick Action과 수동 개입
  - Scene Editor·Test Play·Publish·Live Patch
  - Journal·Player View Preview
  - Recovery·Rollback·세션 종료

## 처음 읽는 순서

플레이어:

```text
Player Guide
→ Quick Start
→ 기본 입력
→ 탐험
→ Encounter
→ 문제 발생 시 대응
```

DM:

```text
DM Guide
→ 세션 전 준비
→ 세션 시작
→ Live DM 진행
→ Encounter
→ Scene 관리
→ Recovery·종료
```

개발자와 기획자는 User Guide를 읽은 뒤 관련 [`Main System Guide`](../guides/README.md)와 권위 문서를 확인한다.

## 확정된 사용자 경험 기준

- 초기 지원 환경은 PC 키보드·마우스다.
- 기본 Ruleset은 `dnd5e-2024`, 기본 표시 언어는 `ko-KR`이다.
- 플레이어와 DM은 Roblox 아바타가 아니라 3D 미니어처 Token을 다룬다.
- Exploration에서는 목적지 클릭과 Token WASD 이동을 지원한다.
- Encounter에서는 Token WASD 이동을 사용하지 않고 경로를 확인한 뒤 클릭으로 이동한다.
- Encounter 중 WASD는 자유 Camera 이동에 사용할 수 있다.
- `Q`는 현재 단계의 취소·거절·한 단계 뒤로다.
- `E`는 현재 단계의 승인·확정·실행·상호작용이다.
- `1–5`는 현재 화면에 의미가 표시된 경우에만 주요 행동 슬롯으로 사용한다.
- Camera를 움직이는 것만으로 Character 위치나 공개 정보가 바뀌지 않는다.
- Player와 DM은 서로 다른 권한과 공개 범위를 받는다.
- 세션 중도 참가, 재접속, 서버 복구와 DM Rollback을 지원하는 경험을 목표로 한다.
- NPC 자동 대화 시스템, 음악, 환경음과 모든 규칙 효과음은 현재 제품 범위가 아니다.
- 모바일·게임패드·터치는 초기 지원 범위가 아니다.

## 아직 확정하지 않는 것

다음은 구현 명세·사용성 테스트 전까지 User Guide에서 임의로 정하지 않는다.

- 최종 화면의 픽셀 배치
- Q·E·1–5 외 기능의 최종 기본 단축키
- Camera 감도와 확대 범위
- Tooltip·Prompt·Toast의 정확한 지속 시간
- 자동 저장 주기와 재시도 횟수
- Animation·VFX의 정확한 시간
- 성능 Budget과 표시 가능한 최대 개수

가이드에 없는 세부 조작을 구현자가 임의로 추가하지 않는다. 새로운 사용자 동작이 필요하면 Product·UI·Architecture 결정에 먼저 반영한 뒤 User Guide를 갱신한다.

## User Guide와 Main System Guide의 차이

```text
User Guide
→ 사용자가 무엇을 보고 무엇을 해야 하는가

Main System Guide
→ 여러 권위 문서가 어떤 흐름과 책임으로 연결되는가

Implementation Spec
→ 실제 Module·Type·Command·Network·Test를 어떻게 구현하는가
```

User Guide는 Product·Architecture·System·UI·ADR의 내용을 쉬운 사용자 언어로 설명한다. 사용자 가이드 자체가 새로운 규칙의 권위 원본은 아니다.

## 변경과 상태

사용자 경험에 영향을 주는 권위 문서가 변경되면 관련 Guide 상태를 다음처럼 관리한다.

```text
TARGET_EXPERIENCE
UPDATE_REQUIRED
CURRENT_FOR_BUILD
RELEASE_VERIFIED
```

- `TARGET_EXPERIENCE`: 구현 전 목표 흐름
- `UPDATE_REQUIRED`: 현재 권위 문서와 차이가 생김
- `CURRENT_FOR_BUILD`: 현재 구현 대상 Spec과 일치함
- `RELEASE_VERIFIED`: 실제 Release와 사용성 테스트에서 검증됨

현재 Player·DM Guide는 `TARGET_EXPERIENCE`다.
