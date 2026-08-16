# ChatGPT Rerun Plan

- repository: `Kaetaeru/RVTT`
- branch: `agent/survival-logistics-token-authoring`
- run_id: `rvtt-rerun-20260817-0100-8f6c2d41`
- sequence: `0`
- task_id: `RERUN-RVTT-R3-FREEZE-001`
- project_phase: `R3_VALIDATED_AWAITING_FREEZE_DECISION`

## Project goal

RVTT는 Roblox 기반의 DM 중심 D&D/TRPG VTT다. 현재 리메이크는 폐기된 Greenfield 구현 모델 대신 **34 System Responsibility / 30 Requirement Capability / 61 Scenario** 기반의 R3 모델을 검증 완료했고, 사용자의 명시적 **R3 Freeze 결정**을 기다리고 있다.

현재 프로젝트 권위가 정한 순서는 다음과 같다.

```text
R3 validation complete
→ 사용자 R3 Freeze 결정
→ R4 E0 Checkpoint Freeze
→ Dedicated Implementation Branch
→ E0 Core Engine
→ CORE_ENGINE_COMPLETE
→ E1 Roblox Runtime / Studio MCP Integration
→ INTEGRATION_READY
→ U0 Product UI Shell
→ UI_SHELL_READY
→ E2
```

현재 Source 구현과 Studio/MCP 구현은 금지되어 있다.

## First task

### `RERUN-RVTT-R3-FREEZE-001` — R3 Freeze readiness revalidation and decision handoff

Rerun이 `continue` authorization을 받으면 실제 Production Source나 Studio/MCP 작업을 시작하지 않는다.

대신 다음을 수행한다.

1. 현재 branch/ref와 프로젝트 authority를 다시 읽는다.
2. `.github/CODEX-ACTIVE-TASK.md`, `IMPLEMENTATION-MODEL.md`, `SYSTEMS.md`, R3 authority corpus와 semantic audit의 현재 상태가 여전히 `R3_VALIDATED_AWAITING_FREEZE_DECISION`인지 확인한다.
3. R3 Freeze 전에 새로 생긴 blocker, stale pointer, validator/workflow 실패, authority drift가 없는지 확인한다.
4. 기존 검증이 유효하면 사용자가 결정할 수 있도록 현재 Freeze 대상, 다음 R4 단계, 금지 사항을 짧게 정리한다.
5. **R3를 자동 Freeze하지 않는다.** 사용자의 명시적 Freeze 결정이 없으면 `needs_user`로 checkpoint한다.

## Sequence 0 checkpoint

2026-08-17 재개 preflight에서 readiness revalidation을 완료했다.

- current PR: `#2`, open/draft, head `agent/survival-logistics-token-authoring`
- revalidated head: `9bf13d38f1eebb655a36e03a9985eec72f7b1d78`
- 마지막 프로젝트 검증 상태 이후 변경: `.chatgpt-rerun/` 연결 문서 5개 추가뿐이며 Product/ADR/Architecture/System/UI/Scenario/Source 권위에는 변경 없음
- current authority: `R3_VALIDATED_AWAITING_FREEZE_DECISION`
- Source implementation: `BLOCKED`
- Studio/MCP implementation: `BLOCKED`
- current-head required workflows: 9개 모두 `completed / success`
- new blocker: 없음
- authority drift: 없음

따라서 sequence 0의 다음 단계는 구현이 아니라 **사용자의 명시적 R3 Freeze 결정**이다. 결정 전에는 동일 task를 `needs_user` 상태로 보존한다.

## Dependencies

- `AGENTS.md`
- `.github/CODEX-ACTIVE-TASK.md`
- `implementation/roblox/IMPLEMENTATION-MODEL.md`
- `implementation/roblox/SYSTEMS.md`
- `implementation/roblox/manifests/r3-authority-corpus.json`
- `implementation/roblox/manifests/implementation-system-model.json`
- `implementation/roblox/manifests/scenario-semantic-audit-v3.json`
- `implementation/roblox/manifests/scenario-semantic-audit.json`
- canonical Base/Expanded scenario catalogs when needed
- current GitHub PR/branch/workflow metadata
- explicit user decision for R3 Freeze

## Acceptance criteria

The first task is accepted only when all of the following are true:

- repository and branch/ref still match the active RVTT work context;
- current authority still reports R3 as validated but not frozen, or any deviation is explicitly reported;
- no Production Source or Studio/MCP implementation has been started by this task;
- current GitHub validation state relevant to R3 Freeze has been checked rather than assumed;
- any blocker or authority drift is recorded in STATE;
- if no blocker exists, the exact user decision required to advance to R4 is stated;
- control is checkpointed as `needs_user`, `blocked`, or `complete` as appropriate; `working` is never used.

## Validation method

- Read current repository authority files from the exact branch/ref.
- Inspect current PR/branch metadata and required GitHub workflow results.
- Compare the current execution gate against the R3 semantic/model validation claims.
- Confirm Source/Studio implementation prohibition remains intact until explicit user Freeze.
- Record evidence and the next exact action in `STATE.md` before updating `control.json`.

## Non-goals

- Do not freeze R3 automatically.
- Do not create the dedicated implementation branch.
- Do not begin E0 Source implementation.
- Do not enter Roblox Studio/MCP.
- Do not revive the retired Greenfield implementation model.
- Do not change Accepted ADR, authority/state ownership, system responsibility, input grammar, or development sequence without user approval.
