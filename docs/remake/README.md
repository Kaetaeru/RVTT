# RVTT Remake Documentation

- 상태: `ACTIVE · R3_VALIDATED_AWAITING_FREEZE_DECISION`
- 최종 갱신일: 2026-08-13
- 현재 개발 방식: `R3 FREEZE DECISION → R4 E0 CHECKPOINT → E0 REPOSITORY → CORE_ENGINE_COMPLETE → E1 STUDIO/MCP`

RVTT 문서는 역할에 따라 분리한다. 모든 문서를 순서대로 읽거나 과거 Implementation Spec을 현재 구현 권위로 자동 승격하지 않는다.

## 처음 읽을 문서

### 작업하는 에이전트

```text
AGENTS.md
→ .github/CODEX-ACTIVE-TASK.md
→ implementation/roblox/IMPLEMENTATION-MODEL.md
→ implementation/roblox/SYSTEMS.md
→ 필요한 현재 Authority
```

### 제품 범위와 권위

- [`product/`](product) — 제품 범위·지원 정책·비목표
- [`decisions/`](decisions) — Accepted ADR
- [`architecture/`](architecture) — Runtime·Data·Authority 계약
- [`systems/`](systems) — 기능 동작 근거
- [`ui/`](ui) — UI·입력·Presentation Authority

### Scenario / 구현 모델

현재 구현 모델과 Scenario 권위는 [`implementation/roblox`](../../implementation/roblox/README.md)에서 관리한다.

- 34 System Responsibility Model v2
- 30 Requirement Capability Catalog v3
- 61 clean canonical Scenario
- Semantic Audit v3

### Implementation Specs

[`specs/`](specs)는 요구·설계 근거와 과거 handoff evidence를 보존한다. 폐기된 Module/Type/Command/Execution split을 새 구현 기본값으로 사용하지 않는다. R4에서 현재 System/Requirement/Scenario 압력으로 Module/Stable Function을 다시 도출한다.

### 역사와 검수

- [`audits/`](audits) — 특정 시점의 감사·판정 기록
- 과거 Codex Review Command와 PR 댓글 — Historical Evidence
- [`archive/`](archive) — 현재 판단에 사용하지 않는 기록

## 현재 Gate

```text
R3 = VALIDATED · NOT FROZEN
SOURCE = BLOCKED
STUDIO/MCP = BLOCKED
NEXT = USER R3 FREEZE DECISION
```

**CORE_ENGINE_COMPLETE 전 Studio/MCP 구현을 시작하지 않는다.** Studio/MCP 직접 구현·Play iteration은 E1 Runtime Integration에서 활성화한다.

## 권위 순서

```text
사용자의 최신 명시적 결정
→ AGENTS.md / CODEX-ACTIVE-TASK.md
→ Product / Accepted ADR / Current Architecture / Global UI
→ Current System / Requirement / Scenario implementation model
→ R4 이후 frozen Checkpoint contracts
→ Source / Test / Runtime / Human evidence
```

Historical spec, legacy source, 과거 PASS는 현재 Authority를 대체하지 않는다.
