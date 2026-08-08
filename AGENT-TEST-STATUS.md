# RVTT Agent Test Status

- 상태: `ACTIVE`
- 최종 갱신일: `2026-08-08`
- 목적: 새 에이전트가 저장소를 열었을 때 현재 테스트 진행 상태, 다음 사용자 수동 Gate, 남은 Runtime 범위를 한눈에 확인하게 한다.
- 적용 범위: RVTT 구현·Runtime·Acceptance·검증 작업

> 이 문서는 **현재 상태 대시보드**다. 테스트 정의의 원본을 대체하지 않는다.
> 상세 계약은 `implementation/roblox/EXECUTION-TEST-RULES.md`, `implementation/roblox/GRAND-ACCEPTANCE-CAMPAIGN.md`, `implementation/roblox/grand-acceptance-manifest.json`을 따른다.

---

## 1. 에이전트 필수 규칙

RVTT에서 구현, 테스트, 검증, Acceptance, Release 관련 작업을 하는 모든 에이전트는 다음을 지킨다.

1. 작업 시작 시 루트 `AGENTS.md` 다음으로 이 파일을 읽는다.
2. 현재 단계가 `PASS`, `FAIL`, `BLOCKED`, `DEFERRED`, `PENDING` 중 무엇인지 확인한 뒤 작업한다.
3. 테스트를 실제 수행했거나 테스트 가능 상태가 바뀌었으면 **같은 작업에서 이 파일도 갱신**한다.
4. 테스트를 실행하지 않았으면 `PASS`로 바꾸지 않는다.
5. Static·Build·Lint·Type PASS를 Studio Runtime PASS로 확대하지 않는다.
6. 일반 Runtime PASS를 Persistence, Multi-client, Accessibility, Performance, Full Release PASS로 확대하지 않는다.
7. 결과를 갱신할 때 최소한 테스트 대상 Head/SHA, 실행일, 결과, 실패 또는 Blocker, 다음 행동을 남긴다.
8. 세부 체크 항목을 새로 정의하거나 변경할 때는 먼저 원본 테스트 문서를 수정하고, 이 문서는 그 상태만 요약한다.
9. 사용자에게 작은 변경마다 Studio 실행을 요구하지 않는다. `EXECUTION-TEST-RULES.md`의 Batch Acceptance 원칙을 따른다.
10. 이 파일이 오래됐거나 원본 Manifest와 충돌하면 원본을 기준으로 확인하고 이 파일을 즉시 정정한다.

---

## 2. Codex와 사용자 수동 테스트 역할

현재 운영 결정:

```text
Codex
→ 코드·문서 검수
→ 구조·권한·회귀 위험 검수
→ Static Gate와 자동 검증처럼 토큰·시간 대비 이득이 큰 작업

사용자 직접 확인
→ Roblox Studio 실행
→ 실제 화면·입력·조작
→ Play Runtime
→ UI·UX
→ Output 확인
→ 기능 동작·플레이 감각
```

기본적으로 **Codex ↔ Roblox Studio MCP 자동 Smoke를 필수 사용자 흐름으로 사용하지 않는다.**
Studio MCP 자동화는 반복 작업 절감 효과가 명확하거나 사용자가 다시 명시적으로 요청할 때만 사용한다.

이 결정은 테스트를 생략한다는 뜻이 아니다. Runtime 검증 책임을 Codex MCP 자동화에서 **Batch 기반 사용자 직접 확인**으로 옮긴 것이다.

---

## 3. 현재 상태 한눈에 보기

| 영역 | 상태 | 현재 판정 |
|---|---|---|
| ADR/설계 및 Studio Preflight 문서 검수 | `PASS` | 마지막 Codex Delta 결과 `NO_SUPPORTED_FINDINGS` |
| Implementation Static Gate | `PASS` | 검증 대상 `ef99a0740711b4f00fac0d5c8d0599f238ea48e9` |
| 사용자 Studio Runtime | `PENDING` | 아직 사용자 직접 Runtime Acceptance 결과 없음 |
| Codex Studio MCP Smoke | `NOT_DEFAULT` | 현재 운영에서는 사용자 수동 Runtime으로 대체 |
| 일반 Runtime 실행 그룹 | `0 / 3 PASS` | 다음 Gate부터 시작 |
| Persistence 실행 그룹 | `0 / 7 PASS` | 전용 Milestone까지 `DEFERRED` |
| UI Visual / Accessibility Human Review | `PLANNED` | 아직 Human Evidence 없음 |
| Performance / Soak / Capacity | `PLANNED` | 아직 Runtime Evidence 없음 |
| Full-session Release Gate | `PLANNED` | 선행 Gate 미완료 |

### 마지막 검증된 구현 Snapshot

```text
PR: #2
branch: agent/survival-logistics-token-authoring
staticGateTargetSha: ef99a0740711b4f00fac0d5c8d0599f238ea48e9
staticGate: PASS
studioManualRuntime: NOT_EXECUTED
humanPlaytest: NOT_EXECUTED
```

이 상태 문서나 다른 문서만 변경한 후에는 새로운 Git Head가 생길 수 있다. 그 경우에도 위 SHA에서 확보한 Static PASS의 사실은 보존하되, **새 Head 전체가 Runtime 검증됐다고 주장하지 않는다.**

---

## 4. 사용자 직접 Runtime 테스트 횟수

현재 사용자 관점의 Runtime 실행 그룹은 **총 10개**로 관리한다.

```text
일반 Runtime 3개
+
Persistence Runtime 7개
=
총 10개 실행 그룹
```

Grand Manifest의 내부 Phase 수와 사용자에게 요구하는 실행 횟수는 동일하지 않다. 여러 내부 Phase와 Assertion은 하나의 Batch 실행에서 함께 검증할 수 있다.

### 일반 Runtime — 3개

| # | 실행 그룹 | 범위 | 상태 |
|---:|---|---|---|
| G1 | Grand Single-client | Unit·Integration baseline + Slice 01 실제 입력 + Slices 02–12 자동 Authority Scenario | `PENDING` |
| G2 | Grand Multi-client | DM·Player·Observer 권한, Projection, Negative Disclosure, Stale Revision | `PENDING` |
| G3 | Grand Real Transport | 실제 Player 종료·재접속·Full Sync | `PENDING` |

### Persistence Runtime — 7개

| # | 실행 그룹 | 범위 | 상태 |
|---:|---|---|---|
| P1 | Live DataStore Baseline | 실제 DataStore 기본 Load·Save | `DEFERRED` |
| P2 | Restart Seed | Shutdown Dirty Snapshot·Flush Seed | `DEFERRED` |
| P3 | Restart Verify | Fresh Server Restore·Epoch Rotation·Stale 거부 | `DEFERRED` |
| P4 | Injected DataStore Outage | Retry 고갈·Dirty 보존·복구 | `DEFERRED` |
| P5 | Cross-server Lease Pair | Holder·Contender 충돌·Renew·Takeover·Fencing | `DEFERRED` |
| P6 | Production Lease Seed | Production ServerBoot·Lease·Fenced Flush | `DEFERRED` |
| P7 | Production Lease Verify | Higher Fence Restore·Stale Writer 거부·Cleanup | `DEFERRED` |

Persistence 7개는 `GRAND-ACCEPTANCE-CAMPAIGN.md`의 Persistence 전용 Milestone에서만 진행한다. 일반 기능 테스트에서 DataStore를 억지로 함께 검증하지 않는다.

---

## 5. 현재 다음 Gate — Slice 01 World Interaction

현재 사용자가 가장 먼저 직접 확인할 Runtime Gate다.

**현재 결과: `0 / 12 PASS` — 아직 실행하지 않음**

- [ ] 1. 3D Token Projection이 정상 표시된다.
- [ ] 2. 화면·월드 좌표 기반 Token Picking이 동작한다.
- [ ] 3. Raycast 실패 시 Screen-space Picking Fallback이 동작한다.
- [ ] 4. 선택 Highlight와 선택 상태 표시가 맞다.
- [ ] 5. Board Destination 표시가 맞다.
- [ ] 6. Token 이동이 서버 권위 `movement.commit` 경로로 확정된다.
- [ ] 7. Command Receipt·Revision 진단이 정상이다.
- [ ] 8. 중클릭 Camera Pan이 동작한다.
- [ ] 9. Character 이동 모드가 아닐 때 WASD Camera Pan이 동작한다.
- [ ] 10. Mouse Wheel Zoom이 동작한다.
- [ ] 11. `F` / Token Frame이 동작한다.
- [ ] 12. 최종 Batch Summary가 실패 없이 완료된다.

### Slice 01 판정 기록

```text
status: PENDING
testedHead: NOT_EXECUTED
testedAt: NOT_EXECUTED
tester: USER_MANUAL
result: NOT_EXECUTED
failedChecks: []
notes: 사용자 직접 Studio Runtime Acceptance 대기
```

Slice 01을 실제로 실행한 에이전트는 위 체크박스와 판정 기록을 같은 작업에서 갱신한다.

---

## 6. 이후 예정 범위

아래는 현재 10개 Runtime 실행 그룹 외에 Release까지 남아 있는 품질·기능 검증 범위다. 준비가 완료되기 전에는 사용자 실행 횟수에 포함하지 않는다.

- Slice 02–12의 전체 사용자 흐름·Disclosure·Recovery 보강
- Slice 13–15 공식 Content 권리·Asset·Production Catalog
- UI Visual Redesign
- Accessibility Human Review
- Network/Storage/Restart 추가 Fault Evidence
- Performance Budget
- Memory·Network·Capacity·Soak
- Slice 16 Full-session Release Hardening

---

## 7. 상태 갱신 형식

테스트 결과가 바뀌면 최소 다음 형식을 남긴다.

```text
Test/Batch: <id or name>
Target Head: <sha>
Executed At: <YYYY-MM-DD>
Executor: USER_MANUAL | CODEX | CI | OTHER
Result: PASS | FAIL | BLOCKED | DEFERRED | PARTIAL
Passed: <n>
Failed: <n>
Blocked: <n>
Evidence: <log/report/screenshot path or summary>
Failure/Blocker: <none or concise reason>
Next: <next required action>
```

실패를 수정한 뒤에는 기존 실패 기록을 지우지 말고, 최신 결과와 재검증 여부가 보이게 남긴다.

---

## 8. 원본 테스트 문서

현재 테스트 Authority:

- `implementation/roblox/EXECUTION-TEST-RULES.md`
- `implementation/roblox/GRAND-ACCEPTANCE-CAMPAIGN.md`
- `implementation/roblox/grand-acceptance-manifest.json`
- 필요 시 개별 Acceptance Project와 Runner

이 문서는 위 Authority를 **한눈에 보는 현재 상태 인덱스**로 유지한다.
