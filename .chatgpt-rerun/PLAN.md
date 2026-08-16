# ChatGPT Rerun Plan

- repository: `Kaetaeru/RVTT`
- branch: `main`
- run_id: `rvtt-main-rerun-20260817-0312-5c7e91ad`
- sequence: `0`
- task_id: `RERUN-RVTT-MAIN-SHARED-SHELL-PREF-001`
- project_phase: `FULL_UI_UX_ALIGNMENT_REQUIRED`
- updated_at: `2026-08-17T03:12:00+09:00`

## Project goal

RVTT는 Roblox 기반의 DM 중심 D&D/TRPG VTT다. 현재 `main`의 Production Implementation Work Order는 16개 Slice Production Source baseline과 이전 static/Studio evidence 위에서 **Full UI·UX Source·Acceptance 정합화**를 진행하도록 지시한다.

현재 Work Order의 실행 순서에서 다음 상태가 확인됐다.

```text
1. Grand Persistence 실행 계약        = DONE
2. ADR-0088 상위 기획                = DONE
3. Full UI·UX 구현 직전 명세         = DONE
4. Shared Shell·Preference Foundation = IN_PROGRESS
5. Input·Context Action 정합화        = QUEUED
...
11. Studio Human Retest              = BLOCKED until static/source alignment gate
```

따라서 이 run의 첫 task는 이미 완료된 1~3번을 반복하지 않고 **4번 Shared Shell·Preference Foundation의 현재 미완료 지점부터 재개**하는 것이다.

## Current task

### `RERUN-RVTT-MAIN-SHARED-SHELL-PREF-001` — Shared Shell · Preference Foundation reconciliation

다음 표준 재개 실행에서 수행한다. 이번 bootstrap 실행에서는 구현을 시작하지 않는다.

1. Rerun preflight 후 `main`의 현재 HEAD와 Work Order drift를 확인한다.
2. 현재 Source/Test/manifest에서 Shared Shell·Preference Foundation의 실제 구현 상태를 조사한다.
3. `implementation-ready-ui-ux-and-settings-spec.md`, `final-ui-content-implementation-contract.md`, UI·UX gap audit와 현재 Source를 대조해 **이미 구현·검증된 부분과 실제 누락 delta를 분리**한다.
4. Work Order 1~3의 DONE 범위는 새 회귀 근거가 없는 한 반복하지 않는다.
5. P0 task #4에 속하는 누락만 현재 authority와 기존 구조에 맞춰 구현·보완한다.
6. 해당 변경에 필요한 repository/static validators와 tests를 실행하고 결과를 기록한다.
7. Studio/Human retest는 Work Order가 정한 Full UI·UX source/static gate가 열리기 전에는 시작하지 않는다.
8. 18분 checkpoint 또는 의미 있는 상태 변화 시 PLAN → STATE → control 순으로 durable state를 게시한다.

## Dependencies / authority

작업 시작 시 최소 다음을 읽고 현재 HEAD 기준으로 사용한다.

- `README.md`
- `AGENTS.md`
- `AGENTS-PLANNING-ADDENDUM.md`
- `docs/remake/README.md`
- `implementation/roblox/CURRENT-WORK-ORDER.md`
- `implementation/roblox/IMPLEMENTATION-STATUS.md`
- `docs/remake/decisions/ADR-0088-direct-play-pointer-grammar-and-feedback.md`
- `docs/remake/ui/shared/implementation-ready-ui-ux-and-settings-spec.md`
- `docs/remake/ui/shared/final-ui-content-implementation-contract.md`
- `docs/remake/audits/ui-ux-implementation-readiness-gap-audit.md`
- `docs/remake/ui/policies/UI-UX-REVIEW-CHECKLIST.md`
- task와 직접 관련된 current Source / tests / manifests / validation scripts

`AGENTS.md`의 오래된 전제와 `AGENTS-PLANNING-ADDENDUM.md`가 충돌하면 addendum의 명시적 교정을 적용한다. 구현 의미는 Accepted ADR과 더 구체적인 current Work Order를 따른다.

## Acceptance criteria

현재 task는 다음이 모두 충족되어야 완료로 볼 수 있다.

- repository/ref가 여전히 `Kaetaeru/RVTT` / `main`이고 실행 중 drift가 기록되어 있다.
- Work Order item 4의 실제 Source/Test 상태를 먼저 조사하여 이미 완료된 작업을 반복하지 않았다.
- Shared Shell의 현재 P0 범위인 Layer / Mode / System / Theme foundation이 current final UI 계약과 정합한다.
- Preference/Settings foundation이 current Full UI·UX specification의 기본값·상태 소유·저장 경계를 따르며 기존 authority를 우회하지 않는다.
- item 4 때문에 필요한 missing tests/validators가 보완되고 관련 repository/static validation이 통과한다.
- 변경이 Work Order items 1~3의 DONE 결과를 불필요하게 재작성하거나 폐기하지 않는다.
- Studio/Human retest를 source/static alignment gate 전에 실행하지 않는다.
- 남은 gap이나 외부 결정이 있으면 `complete`로 숨기지 않고 `blocked` 또는 `needs_user`로 checkpoint한다.
- task 완료 시 다음 Work Order item으로 넘어갈 수 있는 근거와 Next Exact Action이 STATE에 기록된다.

## Validation method

- exact `main` HEAD에서 관련 Source/Test/manifest를 읽어 baseline을 수집한다.
- canonical UI/settings spec과 gap audit의 요구를 current source 구조에 매핑한다.
- 프로젝트가 제공하는 Structure / Security / StyLua / Selene / Rojo / Luau 및 task 관련 static/test gate를 현재 repository instructions에 따라 실행한다.
- 변경된 Shared Shell·Preference 경계에 대한 targeted test와 기존 관련 regression test 결과를 기록한다.
- GitHub/CI evidence가 필요한 경우 current HEAD의 실제 결과를 확인하며 과거 PASS를 새 HEAD PASS로 간주하지 않는다.
- Studio/Human evidence는 Work Order gate가 열린 이후 별도 단계에서 수행한다.

## Non-goals for task 0

- Work Order items 1~3을 이유 없이 다시 수행하지 않는다.
- item 5 Input·Context Action, item 6 HUD, item 7 전체 Inventory·Journal·Settings 화면까지 범위를 자동 확장하지 않는다.
- Studio Human Retest를 선행하지 않는다.
- Accepted ADR, authority/state ownership, input grammar 또는 product scope를 사용자 승인 없이 변경하지 않는다.
- 이번 bootstrap prompt 자체에서는 Production Source를 수정하지 않는다.
