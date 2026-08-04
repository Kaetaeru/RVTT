# 공통 기반 규약 공백 감사 — Discontinued 기록

- 상태: `DISCONTINUED`
- 원래 경로: `docs/remake/audits/cross-system-foundation-contract-gap-audit.md`
- 폐기 판정일: 2026-08-04
- 마지막 유효 범위: Spatial Query·Navigation·Lifecycle·Networking·Streaming·Transaction 계약 작성 전

## 폐기 이유

이 Audit은 다음 영역을 `BLOCKED` 또는 `MISSING`으로 판정했다.

- Runtime Navigation과 이동 실행
- 통합 Spatial Query
- Runtime Object 생명주기
- Command Ordering과 논리 시간
- Network Envelope와 Client Sync
- 비밀 정보 Projection
- Scene Streaming
- Persistence와 Recovery

이후 ADR-0054~0064와 관련 Architecture 문서가 해당 공백을 대부분 해소했다. 현재 이 Audit을 읽으면 이미 해결된 항목을 다시 미결정으로 오인하게 되므로 활성 Audit에서 제외한다.

## 대체 문서

- [`Runtime Architecture Principles`](../../../architecture/runtime-architecture-principles.md)
- [`Scene Compiler 계약`](../../../architecture/scene-compiler-and-compiled-runtime-scene-contract.md)
- [`Spatial Query 계약`](../../../architecture/spatial-query-engine-and-provider-contract.md)
- [`Runtime Navigation 계약`](../../../architecture/runtime-navigation-path-planning-and-movement-execution-contract.md)
- [`Runtime Object 계약`](../../../architecture/runtime-object-system-and-entity-lifecycle-contract.md)
- [`Networking 계약`](../../../architecture/networking-command-event-and-client-synchronization-contract.md)
- [`Scene Streaming 계약`](../../../architecture/scene-streaming-client-interest-and-ready-activation-contract.md)
- [`Transaction Coordinator 계약`](../../../architecture/command-ordering-logical-time-and-transaction-coordinator-contract.md)
- [`Persistence 계약`](../../../architecture/persistence-and-session-recovery-model.md)
- 향후 작성할 최신 Foundation Completion Audit

원문 전체는 원래 경로의 Git 기록에서 확인한다.
