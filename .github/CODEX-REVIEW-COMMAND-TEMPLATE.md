# Codex Review Command Template

아래 템플릿은 PR 댓글 또는 Codex Task에 사용한다. 대괄호 항목을 실제 값으로 교체한다.

```text
@codex review

ROLE
You are the [REVIEWER_ROLE] for Kaetaeru/RVTT.
You report findings to the ChatGPT Lead Reviewer. Do not approve or merge this PR.
Do not modify files unless the task explicitly says FIX MODE.

TARGET
Repository: Kaetaeru/RVTT
Pull Request: #[PR_NUMBER]
Target Commit SHA: [FULL_SHA]
Base Commit SHA: [BASE_SHA]

AUTHORITY ORDER
1. Latest explicit user decision
2. Accepted ADR
3. Accepted Product, Architecture, System, and UI policy
4. Ready Slice or implementation contract
5. Script manifest
6. Production source and tests
7. User guide and HTML reference

PRIMARY SOURCES
- [AUTHORITY_FILE_1]
- [AUTHORITY_FILE_2]
- [SLICE_OR_IMPLEMENTATION_FILE]
- [TEST_OR_ACCEPTANCE_FILE]

REVIEW SCOPE
- [SCOPE_ITEM_1]
- [SCOPE_ITEM_2]
- [SCOPE_ITEM_3]

OUT OF SCOPE
- [OUT_OF_SCOPE_1]
- [OUT_OF_SCOPE_2]

REQUIRED CHECKS
1. Compare the PR behavior with the authority chain.
2. Inspect changed files and directly connected dependencies.
3. Look for normal-path and failure-path regressions.
4. Check permission, revision, idempotency, reconnect, restart, rollback, and disclosure where applicable.
5. Check whether tests genuinely exercise the claimed behavior.
6. Distinguish documentation, static build, CI, Roblox Studio, human input, multi-client, persistence, and performance evidence.
7. Treat intentionally queued work as pending rather than automatically defective.

PROHIBITIONS
- Do not invent new product decisions.
- Do not claim a test passed unless you executed it or a current-SHA artifact proves it.
- Do not treat static analysis as Roblox Studio runtime evidence.
- Do not report style preferences without correctness or maintainability impact.
- Do not recommend broad refactors unless required to fix a demonstrated defect.
- Do not expose secrets, private rulebook content, credentials, or user save data.

AVAILABLE EVIDENCE
- [CI_RUN_OR_ARTIFACT]
- [STATIC_TEST_RESULT]
- [RUNTIME_EVIDENCE_OR_NONE]

OUTPUT FORMAT
Return findings only, followed by a short coverage summary.

For each finding use:

findingId: [ROLE]-NNN
severity: BLOCKER | HIGH | MEDIUM | LOW
category: authority | slice_ownership | source | security | test | evidence | migration | recovery | disclosure | performance
claim: <one precise defect or risk>
confidence: high | medium | low
evidence:
  - <file:line or artifact>
fileAndLine:
  - <path:line-range>
reproductionOrReasoning: <minimal reproducible scenario or reasoning>
expectedAuthority: <controlling document or invariant>
minimalCorrection: <smallest safe correction>
requiredTest: <test or evidence needed>

If no finding is supported, say:
NO_SUPPORTED_FINDINGS

COVERAGE SUMMARY
- files inspected
- tests or commands executed
- areas not verifiable
- runtime evidence status
```

## Delta Review Template

```text
@codex review

ROLE
You are the Delta Reviewer. Review only the fixes for the triaged findings below.
Do not reopen unrelated design questions.

TARGET
Repository: Kaetaeru/RVTT
Pull Request: #[PR_NUMBER]
Previous Reviewed SHA: [PREVIOUS_SHA]
Current Target SHA: [CURRENT_SHA]

TRIAGED FINDINGS
- [FINDING_ID]: CONFIRMED — [EXPECTED_FIX]
- [FINDING_ID]: VALID_RISK — [EXPECTED_TEST]
- [FINDING_ID]: FALSE_POSITIVE — [REJECTION_BASIS]

VERIFY
1. Each CONFIRMED finding is fixed at the correct authority layer.
2. The patch does not introduce adjacent regressions.
3. Required tests exist and test the failure path.
4. No PASS claim exceeds current evidence.

OUTPUT
For each listed finding return:
- findingId
- resolution: RESOLVED | PARTIALLY_RESOLVED | UNRESOLVED | REGRESSION_INTRODUCED
- evidence
- remainingRisk

Report new findings only when directly caused by the fix.
```

## Fix Mode Template

```text
@codex

MODE
FIX MODE. Implement only the CONFIRMED finding below.

TARGET
Repository: Kaetaeru/RVTT
Pull Request: #[PR_NUMBER]
Target Commit SHA: [FULL_SHA]

FINDING
Finding ID: [FINDING_ID]
Classification: CONFIRMED
Severity: [SEVERITY]
Controlling Authority: [AUTHORITY_FILE]
Allowed Files: [FILE_LIST]
Forbidden Scope: [FORBIDDEN_SCOPE]
Required Tests: [TEST_LIST]

GOAL
[MINIMAL_FIX_GOAL]

RULES
- Do not broaden product behavior.
- Do not modify unrelated files.
- Preserve server authority, version, disclosure, and recovery contracts.
- Add or update the required regression test.
- Report changed files, tests executed, and unresolved limitations.
- Do not approve or merge the PR.
```
