# PR #2 Codex Review — Authority·Slice Ownership

- 상태: `PENDING_CODEX_FEEDBACK`
- Pull Request: `#2`
- Target Commit: `50538dbf3c1c0150f6e4c20f45ff2b948981b1d5`
- Base Commit: `c4347e5adafe72b3bdf98a9675f6c155a3b95b33`
- Reviewer Role: `Authority Chain + Slice Ownership Reviewer`
- Lead Reviewer: ChatGPT
- 생성일: 2026-08-07

## Codex 명령문

```text
@codex review

ROLE
You are the Authority Chain and Slice Ownership Reviewer for Kaetaeru/RVTT.
You report findings to the ChatGPT Lead Reviewer. Do not approve, merge, or modify this PR.

TARGET
Repository: Kaetaeru/RVTT
Pull Request: #2
Target Commit SHA: 50538dbf3c1c0150f6e4c20f45ff2b948981b1d5
Base Commit SHA: c4347e5adafe72b3bdf98a9675f6c155a3b95b33

AUTHORITY ORDER
1. Latest explicit user decision
2. Accepted ADR
3. Accepted Product, Architecture, System, and UI policy
4. Ready Slice or implementation contract
5. Script manifest
6. Production source and tests
7. User guide and HTML reference

PRIMARY SOURCES
- docs/remake/decisions/ADR-0092-campaign-survival-logistics-and-dm-authored-actor-tokens.md
- docs/remake/product/campaign-rules-survival-and-authored-actor-scope.md
- docs/remake/architecture/campaign-survival-logistics-and-supply-settlement-runtime-contract.md
- docs/remake/architecture/dm-authored-actor-token-and-statblock-import-runtime-contract.md
- docs/remake/specs/ADR-0092-SLICE-SYNC-PLAN.md
- docs/remake/specs/SLICE-ROADMAP.md
- docs/remake/specs/slices/06-inventory-equipment-world-items/ADR-0092-DELTA.md
- docs/remake/specs/slices/07-rest-time-downtime-progression/ADR-0092-DELTA.md
- docs/remake/product/codex-supervised-review-and-test-policy.md

REVIEW SCOPE
1. Verify ADR-0092 is connected from user decision through Product, Architecture, Slice, and Production planning.
2. Verify responsibility is correctly divided across Slice 06, 07, 11, 12, 15, and 16.
3. Verify Slice 01 has not absorbed survival or actor-authoring behavior.
4. Verify intentionally queued Slice 11, 12, 15, and 16 work is not falsely marked complete.
5. Verify Supply Metadata, requirement values, policy snapshots, settlement, DM UI, content registry, actor model registry, JSON import, prompt builder, publish, and migration have one clear owner.
6. Verify the new supervised Codex policy does not let Codex replace user decisions, CI, Roblox Studio, or human acceptance.
7. Identify obsolete status claims or links introduced or left unresolved by this PR.

OUT OF SCOPE
- Implementing Production Luau for ADR-0092
- Visual redesign of the supplemental HTML
- Reopening accepted product decisions without a documented contradiction
- Treating future queued work as a defect solely because it is not implemented

REQUIRED CHECKS
1. Compare changed documents with directly connected authority documents.
2. Look for duplicated or missing state ownership.
3. Check that UI modules do not own Inventory, Time, Content, or Actor authority.
4. Check that exact official consumption values remain Content Pack data rather than engine constants.
5. Check that AI output remains untrusted draft and cannot auto-publish.
6. Check that Codex Review, documentation CI, static build, Roblox Studio, human input, persistence, and performance evidence are not conflated.

PROHIBITIONS
- Do not invent new product decisions.
- Do not modify files.
- Do not approve or merge the PR.
- Do not report style-only findings.
- Do not claim a test passed unless a current-SHA artifact proves it.
- Do not expose private rulebook content or credentials.

AVAILABLE EVIDENCE
- Validate remake documentation: PASS for target SHA
- Validate RVTT implementation: running or pending final completion for target SHA
- Roblox Studio Runtime Evidence for this policy change: none
- Human Acceptance for this policy change: none

OUTPUT FORMAT
Return findings only, followed by a short coverage summary.

For each finding use:

findingId: AUTH-SLICE-NNN
severity: BLOCKER | HIGH | MEDIUM | LOW
category: authority | slice_ownership | evidence | test | process
claim: <one precise defect or risk>
confidence: high | medium | low
evidence:
  - <file:line or artifact>
fileAndLine:
  - <path:line-range>
reproductionOrReasoning: <minimal reasoning>
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

## Finding Triage

Codex 응답이 도착하면 다음 표를 채운다.

| Finding | Severity | Lead 판정 | 근거 | 후속 조치 | 상태 |
|---|---|---|---|---|---|
| 대기 | - | - | - | - | PENDING |

허용 Lead 판정:

```text
CONFIRMED
VALID_RISK
DESIGN_DECISION_REQUIRED
INTENTIONALLY_QUEUED
DUPLICATE
FALSE_POSITIVE
OUT_OF_SCOPE
```

## Evidence 경계

이 Artifact의 생성은 Codex가 실제로 검수를 수행했다는 증거가 아니다. Codex 응답이 PR 또는 연결된 Review 결과로 확인되기 전까지 상태는 `PENDING_CODEX_FEEDBACK`이다.
