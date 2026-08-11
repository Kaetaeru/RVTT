# RVTT Roblox Implementation 현재 작업 순서

- 상태: `PRE_G0_PREPARATION_COMPLETE`
- 최종 갱신일: 2026-08-12
- 현재 실행 포인터: [`../../.github/CODEX-ACTIVE-TASK.md`](../../.github/CODEX-ACTIVE-TASK.md)
- Pre-G0 Gate: [`GREENFIELD-PREFLIGHT.md`](GREENFIELD-PREFLIGHT.md)
- 시스템 순서 권위: [`GREENFIELD-SYSTEM-SEQUENCE.md`](GREENFIELD-SYSTEM-SEQUENCE.md)
- Greenfield 정책: [`GREENFIELD-BUILD-POLICY.md`](GREENFIELD-BUILD-POLICY.md)
- 확정 동기화 Gate: [`AUTHORITY-RECONCILIATION-POLICY.md`](AUTHORITY-RECONCILIATION-POLICY.md)

## 현재 상태

Repository 측 G0 사전 준비의 목표 상태는 다음이다.

```text
Greenfield Project = implementation/roblox/greenfield.project.json
Canonical Source   = implementation/roblox/greenfield/src
Focused Tests      = implementation/roblox/greenfield/tests
Legacy src         = READ_ONLY_REFERENCE
G0 Source          = NOT_STARTED
```

다음 실행의 첫 행동은 `GREENFIELD-PREFLIGHT.md`의 Repository 검증과 Studio/MCP Capability Handshake다. 허용 상태가 확인되면 즉시 `G0_SHARED_CONTRACTS` 구현을 시작한다.

## 고정 구현 순서

```text
PRE-G0 Workbench Gate
→ G0 Shared Contracts
→ G1 Server Authority Core
→ G2 Command Transport
→ G3 Projection Pipeline
→ G4 Client World Shell
→ G5 Composition Boot
→ S1 Selection
→ 사용자 확인
```

`PRE-G0 Workbench Gate`는 Foundation Stage가 아니며 `G0→G5` 순서를 바꾸지 않는다.

## Exploration Checkpoint

```text
S1 Selection
→ C1 Camera
→ M1 Move
→ X1 Context
→ I1 Interaction
```

각 Checkpoint는 사용자 최종 수용 뒤 Authority Reconciliation, Canonical Source, Focused Test, Promotion Commit까지 완료되어야 다음 Checkpoint로 간다.

## 금지

- `default.project.json`을 Greenfield 실행 Project로 사용
- Legacy `src/` 직접 수정
- 기존 Production Place를 새 Build Baseline으로 사용
- G0 전에 G1+ 책임 구현
- G0~G5 순서 건너뛰기
- 사용자 Checkpoint 건너뛰기

더 좋은 Architecture·순서·Authority 방향이 보이면 적용하지 말고 사용자에게 먼저 제안한다.
