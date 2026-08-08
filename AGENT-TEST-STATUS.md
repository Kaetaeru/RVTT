# RVTT Agent Test Status

- 상태: `ACTIVE`
- 최종 갱신일: `2026-08-08`
- 목적: 새 에이전트가 저장소를 열었을 때 현재 구현·테스트 진행 상태, 다음 Gate, 남은 사용자 Runtime 범위를 한눈에 확인하게 한다.
- 적용 범위: RVTT 구현·Runtime·Acceptance·검증·Release 작업

> 이 문서는 **현재 상태 대시보드**다. 테스트 정의나 구현 순서의 원본을 대체하지 않는다.
> 현재 작업 순서는 `implementation/roblox/CURRENT-WORK-ORDER.md`를 따르고,
> 테스트 상세 계약은 `implementation/roblox/EXECUTION-TEST-RULES.md`, `implementation/roblox/GRAND-ACCEPTANCE-CAMPAIGN.md`, `implementation/roblox/grand-acceptance-manifest.json`을 따른다.

---

## 1. 에이전트 필수 규칙

RVTT에서 구현, 테스트, 검증, Acceptance, Release 관련 작업을 하는 모든 에이전트는 다음을 지킨다.

1. 작업 시작 시 루트 `AGENTS.md` 다음으로 이 파일과 `implementation/roblox/CURRENT-WORK-ORDER.md`를 읽는다.
2. 현재 구현 단계와 테스트 단계가 각각 `PASS`, `FAIL`, `BLOCKED`, `DEFERRED`, `PENDING`, `IN_PROGRESS` 중 무엇인지 확인한 뒤 작업한다.
3. 테스트를 실제 수행했거나 테스트 가능 상태, 다음 Gate, 구현 선행조건이 바뀌었으면 **같은 작업에서 이 파일도 갱신**한다.
4. 테스트를 실행하지 않았으면 `PASS`로 바꾸지 않는다.
5. Static·Build·Lint·Type PASS를 Studio Runtime PASS로 확대하지 않는다.
6. 일반 Runtime PASS를 Persistence, Multi-client, Accessibility, Performance, Full Release PASS로 확대하지 않는다.
7. 결과를 갱신할 때 최소한 테스트 대상 Head/SHA, 실행일, 결과, 실패 또는 Blocker, 다음 행동을 남긴다.
8. 세부 체크 항목을 새로 정의하거나 변경할 때는 먼저 원본 작업 순서·테스트 문서를 수정하고, 이 문서는 그 상태만 요약한다.
9. 사용자에게 작은 변경마다 Studio 실행을 요구하지 않는다. `EXECUTION-TEST-RULES.md`의 Batch Acceptance 원칙을 따른다.
10. 이 파일이 `CURRENT-WORK-ORDER.md`나 Grand Manifest와 충돌하면 원본을 기준으로 확인하고 이 파일을 즉시 정정한다.

---

## 2. Codex와 사용자 수동 테스트 역할

현재 운영 결정:

```text
Codex
→ 코드·문서 검수
→ 구현 작업 중 반복 탐색·수정처럼 효율 이득이 큰 작업
→ 구조·권한·회귀 위험 검수
→ Static Gate와 자동 검증

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

이 결정은 Runtime 테스트를 생략한다는 뜻이 아니다. Studio Runtime 검증 책임을 Codex MCP 자동화에서 **Batch 기반 사용자 직접 확인**으로 옮긴 것이다.

---

## 3. 현재 상태 한눈에 보기

| 영역 | 상태 | 현재 판정 |
|---|---|---|
| ADR/설계 및 Studio Preflight 문서 검수 | `PASS` | 마지막 Codex Delta 결과 `NO_SUPPORTED_FINDINGS` |
| 마지막 Implementation Static Gate | `PASS` | 검증 대상 `ef99a0740711b4f00fac0d5c8d0599f238ea48e9` |
| Full UI·UX Source·Acceptance 정합화 | `IN_PROGRESS` | `CURRENT-WORK-ORDER.md` 순서 4부터 진행 |
| Shared Shell·Preference Foundation | `IN_PROGRESS` | 현재 구현 작업 |
| Input·Context Action 정합화 | `PENDING` | Shared Shell 이후 |
| Exploration·Encounter HUD | `PENDING` | Input 정합화 이후 |
| Inventory·Journal·Settings | `PENDING` | HUD 이후 |
| Entry·Role·Recovery | `PENDING` | 화면 정합화 이후 |
| DM Live Workspace | `PENDING` | Role·Recovery 이후 |
| Full UI·UX Acceptance 확장 | `PENDING` | Runtime 전에 필요 |
| 현재 사용자 Studio Human Retest | `BLOCKED` | UI·UX Source·Acceptance 정합화 + 새 current-HEAD Static Gate가 먼저 |
| Codex Studio MCP Smoke | `NOT_DEFAULT` | 현재 운영에서는 사용자 수동 Runtime으로 대체 |
| 일반 Runtime 실행 그룹 | `0 / 3 PASS` | G1도 아직 실행 가능 상태가 아님 |
| Persistence 실행 그룹 | `0 / 7 PASS` | 전용 Milestone까지 `DEFERRED` |
| UI Visual / Accessibility Human Review | `PENDING` | Studio Retest 이후 |
| Performance / Soak / Capacity | `PENDING` | Runtime Evidence 이후 |
| Full-session Release Gate | `PENDING` | 선행 Gate 미완료 |

### 마지막 검증된 구현 Snapshot

```text
PR: #2
branch: agent/survival-logistics-token-authoring
staticGateTargetSha: ef99a0740711b4f00fac0d5c8d0599f238ea48e9
staticGate: PASS
studioManualRuntimeCurrentContract: NOT_EXECUTED
humanPlaytestCurrentContract: NOT_EXECUTED
```

`ef99a07...` 이후 현재까지 확인된 변경은 테스트 상태 문서와 에이전트 규칙 문서뿐이다. 따라서 그 Static PASS 기록은 유효한 역사적 증거로 유지한다. 다만 앞으로 Full UI·UX 구현 코드가 변경되면 **새 구현 Head에서 Static Gate를 다시 통과한 뒤** Studio Human Retest를 시작해야 한다.

---

## 4. 현재 작업 순서 — Studio를 아직 켜지 않는다

현재 Authority인 `implementation/roblox/CURRENT-WORK-ORDER.md`의 순서는 다음과 같다.

```text
Shared Shell·Preference Foundation
→ Input·Context Action 정합화
→ Exploration·Encounter HUD
→ Inventory·Journal·Settings
→ Entry·Role·Recovery
→ DM Live Workspace
→ Acceptance 확장
→ 새 current-HEAD Static Gate
→ Exploration·Context Input Studio Human Retest
→ UI·Accessibility Evidence
→ DM·Player·Observer Test
→ Grand Persistence Runtime
→ Performance·Soak
→ Slice 16 Release Campaign
```

따라서 **현재는 사용자에게 Studio 실행을 요청하지 않는다.**
`Studio Human Retest`는 위 구현·Acceptance 정합화가 끝난 후 새 Head의 Static Gate가 PASS했을 때만 `PENDING/READY`로 전환한다.

---

## 5. 사용자 직접 Runtime 테스트 횟수

현재 사용자 관점의 핵심 Runtime 실행 그룹은 **총 10개**로 관리한다.

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
| G1 | Grand Single-client | Unit·Integration baseline + 최신 Slice 01/Direct Play 실제 입력 + Slices 02–12 자동 Authority Scenario | `BLOCKED` — UI·UX/Acceptance 정합화 선행 |
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

## 6. 다음 사용자 Human Retest 체크리스트 — 준비 중

아래 체크리스트는 `CURRENT-WORK-ORDER.md`의 Acceptance 재작성 범위다. **현재 상태는 `BLOCKED / NOT READY`이며 아직 실행하지 않는다.** 구현과 Acceptance 확장이 끝나면 G1 Runtime에 포함해 한 번의 Batch로 확인한다.

### Input·Direct Play — 11개

- [ ] 1. ESC가 Gameplay 의미를 가지지 않는다.
- [ ] 2. Q가 최상위 Context를 한 단계씩 닫거나 취소한다.
- [ ] 3. 조작 가능한 아군 좌클릭으로 선택이 전환된다.
- [ ] 4. 기본 행동이 클릭 전에 Cursor·Outline·Label 등으로 표시된다.
- [ ] 5. Action Table에서 현재 가능한 행동과 불가능한 행동이 구분된다.
- [ ] 6. 비활성 행동 Hover·Focus에서 불가능한 이유가 표시된다.
- [ ] 7. 권한 밖이거나 인지하지 못한 Action은 노출되지 않는다.
- [ ] 8. 중클릭 Camera Orbit이 정상 동작한다.
- [ ] 9. 이동·공격·범위 Preview가 실제 실행 전에 표시된다.
- [ ] 10. 행동 후 Selection이 유지되고 Camera가 강제로 이동하지 않으며 Soft Focus 계약을 따른다.
- [ ] 11. Pending·Denied·Stale·Projection Revision 상태가 일관되게 표시된다.

### Screen·Preference — 7개

- [ ] 12. Exploration·Encounter Mode Composition이 명세와 맞다.
- [ ] 13. Inventory·Loot·Transfer·Identification 흐름이 맞다.
- [ ] 14. Journal·Map Permission·Navigation이 권한과 명세를 따른다.
- [ ] 15. Settings 초기값·Reset·Binding Conflict가 정상이다.
- [ ] 16. Accent·Scale·Motion 변경 중 Focus·Selection이 유지된다.
- [ ] 17. Entry·Role Change·Reconnect·Recovery 흐름이 정상이다.
- [ ] 18. Player·DM·Observer Projection이 서로 올바르게 분리된다.

### 현재 판정 기록

```text
status: BLOCKED
testedHead: NOT_EXECUTED
testedAt: NOT_EXECUTED
tester: USER_MANUAL
result: NOT_EXECUTED
passedChecks: 0
failedChecks: 0
blockedChecks: 18
blocker: Full UI·UX Source·Acceptance alignment and new current-HEAD Static Gate required
next: Shared Shell·Preference Foundation implementation
```

### Historical Studio Evidence — 현재 계약 PASS로 사용 금지

```text
historicalHead: 582c1c4
historicalResult: [RVTT Batch Summary] batch=slice01-world-interaction result=PASS passed=16 failed=0 pending=0 revision=12
scope: old Camera·Token Pick·Move·Projection input contract only
```

이 Historical PASS는 새 Pointer, Screen Shell, Settings, Accessibility, Role/Recovery 계약의 Runtime Evidence가 아니다.

---

## 7. 이후 예정 범위

현재 10개 Runtime 실행 그룹 외에도 Release까지 다음 품질·기능 검증이 남아 있다.

- Slice 02–12 전체 사용자 흐름·Disclosure·Recovery 보강
- Slice 13–15 공식 Content 권리·Asset·Production Catalog
- UI Visual Redesign·Human Review
- Accessibility Evidence
- Network/Storage/Restart 추가 Fault Evidence
- Performance Budget
- Memory·Network·Capacity·Soak
- Slice 16 Full-session Release Hardening

---

## 8. 상태 갱신 형식

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

## 9. 원본 상태·테스트 문서

현재 Authority:

- `implementation/roblox/CURRENT-WORK-ORDER.md` — 현재 구현·검증 순서
- `implementation/roblox/EXECUTION-TEST-RULES.md` — Batch Acceptance 운영 규칙
- `implementation/roblox/GRAND-ACCEPTANCE-CAMPAIGN.md` — Grand Runtime 실행 모델
- `implementation/roblox/grand-acceptance-manifest.json` — Runtime Phase Manifest
- 필요 시 개별 Acceptance Project와 Runner

이 문서는 위 Authority를 **한눈에 보는 현재 상태 인덱스**로 유지한다.