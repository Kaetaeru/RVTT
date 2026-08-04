# 주사위 굴림·연출·결과 확정 모델

- 문서 상태: `SUPERSEDED`
- 판정일: 2026-08-04
- 원래 상태: 초안

이 문서의 서버 권위 주사위, 봉인 결과, 카메라 기준 3D 연출과 공개 게이트 방향은 유효했다.

그러나 이후 다음 공통 계약이 확정되면서 현재 권위 문서로 사용할 수 없다.

- [`Dice Roll, Check, Save, Attack과 Resolution Runtime 계약`](../../architecture/dice-roll-check-save-attack-and-resolution-runtime-contract.md)
- [`Rule Runtime Orchestrator`](../../architecture/rule-runtime-orchestrator-and-pending-execution-contract.md)
- [`Command Ordering과 Transaction Coordinator`](../../architecture/command-ordering-logical-time-and-transaction-coordinator-contract.md)
- [`ADR-0069`](../../decisions/ADR-0069-authoritative-roll-records-and-presentation-gated-resolution.md)

현재 구현과 후속 기획은 새 Architecture를 따른다.

이전 상세 본문은 Git 이력에서 확인할 수 있다. 특히 카메라 뒤에서 화면 중앙으로 진입하는 주사위, 면 정렬, ACK와 timeout 설계의 역사적 맥락을 보존한다.
