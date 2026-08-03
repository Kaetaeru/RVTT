# Session 시스템

캠페인 로비, 중도 참여, 영구 Owner, 런타임 Controller, Observer와 Client 동기화를 다룬다.

## 권위 문서

### 사용자 흐름

- [`campaign-lobby-hot-join-ownership-and-control.md`](campaign-lobby-hot-join-ownership-and-control.md)
  - 로비, Character Owner와 Control Assignment
  - Observer와 중도 참여
  - 연결 종료, 재접속과 제어권 복구
  - 사용자 Ready와 기술적 Client Ready 분리

### Network와 동기화

- [`../../architecture/networking-command-event-and-client-synchronization-contract.md`](../../architecture/networking-command-event-and-client-synchronization-contract.md)
  - Protocol Negotiation과 Connection Epoch
  - Projection Snapshot과 Event Catch-up
  - Authority Ready, Presentation Ready와 Gameplay Ready
  - Command Idempotency, Result 복구와 Event Gap 처리
  - 사용자별 Disclosure Projection

### 저장과 서버 복구

- [`../../architecture/persistence-and-session-recovery-model.md`](../../architecture/persistence-and-session-recovery-model.md)
  - Authority Snapshot과 Command Journal
  - Pending Resolution과 안전 경계
  - 서버 종료·새 서버 복구

## 고정 경계

- Character Owner, 현재 Controller와 Session Role을 하나의 필드로 합치지 않는다.
- Lobby Ready는 사용자의 시작 의사이고 Client Ready는 기술 동기화 상태다.
- 중도 참여자는 Raw Server State가 아니라 권한별 Projection Snapshot을 받는다.
- Authority Ready 전에는 권위 Gameplay Command를 허용하지 않는다.
- 재접속 Client가 보낸 로컬 상태를 권위 상태로 사용하지 않는다.
- 이전 Connection Epoch의 Command와 Ready 신호를 무효화한다.
