# Codex Task Template

- 최종 갱신일: 2026-08-12
- 참고: 파일명은 기존 링크 호환을 위해 유지한다.

Codex는 `STUDIO_IMPLEMENTATION`, `FOCUSED_FIX`, `REVIEW` 중 하나의 명확한 역할로 작업한다. 사용자는 긴 Prompt를 반복 복사할 필요가 없고, 긴 작업은 `.github/CODEX-ACTIVE-TASK.md`가 실제 Command를 가리키게 할 수 있다.

## 1. Studio Implementation Template

```text
MODE
STUDIO_IMPLEMENTATION

TARGET
Repository: Kaetaeru/RVTT
Pull Request: #[PR_NUMBER]
Target Mode: CURRENT_PR_HEAD_AT_START

GOAL
[ONE_USER_FACING_FLOW]

BEFORE EDITING STUDIO
1. Read AGENTS.md.
2. Read current Work Orders and relevant Product/ADR/UI/Spec.
3. Inspect existing modules, public functions, remotes, schema, registry and tests connected to the goal.
4. Resolve the current PR head.
5. Inspect the current Studio place and available MCP capabilities.

ITERATION
1. Reuse existing responsibilities instead of creating parallel systems.
2. Build or modify the real Studio UI/Instance/Script path.
3. Play the smallest useful flow.
4. Inspect output, runtime state and visible behavior.
5. Fix and replay as needed.
6. Ask the user before applying a new product, architecture, workflow or scope direction.

CANONICALIZE
1. Move accepted Production changes back into repository source.
2. Make required Instance structure reproducible through the source/Rojo mapping.
3. Remove temporary Studio-only production dependencies.
4. Run relevant focused tests.

REPORT
- what was implemented
- Studio observations
- repository files changed
- tests run
- user decision needed
- remaining risk
```

## 2. Focused Fix Template

```text
MODE
FOCUSED_FIX

DEFECT
[REPRODUCED_DEFECT]

ALLOWED SCOPE
[FILES_OR_SYSTEM]

RULES
- Fix the demonstrated root cause.
- Do not broaden product behavior.
- Re-run the affected Studio flow.
- Add or update focused regression coverage when appropriate.
- If the fix requires a new product/architecture decision, stop and ask the user.
```

## 3. Independent Review Template

```text
MODE
REVIEW

TARGET
Repository: Kaetaeru/RVTT
Pull Request: #[PR_NUMBER]
Target Mode: CURRENT_PR_HEAD_AT_START
Reviewer Role: [ROLE]

AUTHORITY
- latest explicit user decision
- Accepted ADR
- Product/Architecture/System/UI authority
- ready implementation contract

SCOPE
[REVIEW_SCOPE]

CHECK
- authority mismatch
- server authority and input validation
- security and negative disclosure
- persistence/migration/recovery where applicable
- regression coverage
- evidence overclaim

OUTPUT
Post a top-level PR comment beginning with:
<!-- RVTT_CODEX_REVIEW_RESULT -->

Include:
commandId
targetSha
reviewPhase
reviewerRole
resultStatus

For each finding:
findingId
severity
claim
evidence
minimalCorrection
requiredTest
```

## 4. Review 결과 규칙

- 검수 종료 시 HEAD가 바뀌었으면 현재 SHA PASS로 사용하지 않는다.
- 실행하지 않은 Runtime을 PASS라고 하지 않는다.
- Style 취향만으로 Finding을 만들지 않는다.
- 과도한 대규모 Refactor를 근거 없이 요구하지 않는다.
- 사용자가 승인하지 않은 제품 결정을 Fix에 숨겨 넣지 않는다.
- Codex는 사용자 요청 없이 PR을 Ready, Merge 또는 Force Push하지 않는다.
