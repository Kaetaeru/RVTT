# RVTT Roblox Implementation Workspace

이 디렉터리는 RVTT의 Production Source, Test, Rojo Project, Runtime·Release Tooling을 둔다.

## 먼저 읽을 것

현재 실행할 작업은 이 디렉터리의 여러 문서에서 추측하지 않는다.

```text
AGENTS.md
→ .github/README.md
→ .github/CODEX-ACTIVE-TASK.md
→ 그 파일의 commandPath
```

- [`CURRENT-WORK-ORDER.md`](CURRENT-WORK-ORDER.md) — 단계·기능군 우선순위 Context
- [`MODULE-CONTRACTS.md`](MODULE-CONTRACTS.md) — Production Module 안정 경계
- [`EXECUTION-TEST-RULES.md`](EXECUTION-TEST-RULES.md) — Studio-first 개발과 Release 검증 구분
- [`ROBLOX-STUDIO-MCP-TEST-POLICY.md`](ROBLOX-STUDIO-MCP-TEST-POLICY.md) — MCP 직접 구현 규칙
- [`CODEX-REVIEW-TEST-GATE.md`](CODEX-REVIEW-TEST-GATE.md) — Stabilization·고위험 Review Gate
- [`FULL-UI-UX-ACCEPTANCE.md`](FULL-UI-UX-ACCEPTANCE.md) — Release/Regression Acceptance Reference, 현재 작업 아님
- [`GRAND-ACCEPTANCE-CAMPAIGN.md`](GRAND-ACCEPTANCE-CAMPAIGN.md) — Release 통합 Campaign, 현재 작업 아님
- [`ADR-0092-PHASED-PRODUCTION-PLAN.md`](ADR-0092-PHASED-PRODUCTION-PLAN.md) — Queued ADR-0092 기능 순서

## 현재 개발 루프

```text
GitHub Authority·Module Contract·Source 조사
→ Studio MCP로 현재 DataModel 조사
→ 실제 UI·Instance·Script 구현
→ Play
→ 즉시 수정
→ 사용자 판단
→ GitHub Source·필요한 Module Contract·Rojo Mapping 정규화
→ Focused Test
```

Acceptance Harness와 Grand Campaign은 위 루프의 선행조건이 아니다.

## Source 구조

```text
src/ReplicatedFirst
src/ReplicatedStorage
src/ServerScriptService
src/ServerStorage
src/StarterGui
src/StarterPlayer
tests
tooling
```

## Rojo Project

- `default.project.json` — Production Place
- `test.project.json` — Unit·Integration
- `multi-client.project.json` — DM·Player·Observer
- `live-datastore.project.json` — DataStore Baseline
- `persistence-acceptance.project.json` — Persistence Acceptance
- `slice01-acceptance.project.json` — World/Context Focused Regression Harness

Rojo는 Source↔DataModel 연결, 재현 가능한 Build와 CI를 담당한다. 매 개발 Play마다 Acceptance Place를 새로 Build할 필요는 없다.

## Historical / Release reference 주의

- `tests/Slice01Acceptance/`는 현재 `slice01-acceptance.project.json`에 마운트되지 않는 legacy persistence-era harness다.
- 현재 Slice01 focused project는 `tests/WorldTokenAcceptance`와 `tests/ContextInputAcceptance`를 마운트하고 Persistence를 끈다.
- `FULL-UI-UX-ACCEPTANCE.md` 안의 Phase 10 상태는 historical static snapshot이며 현재 개발 작업 순서가 아니다.
- `.github/archive/**`는 과거 Codex Command 보존소다.

## 핵심 Production 경계

- Client는 Intent만 제출한다.
- Server가 Authorization·Rules·Transaction·Projection을 소유한다.
- UI는 Remote를 직접 호출하지 않는다.
- Player·DM·Observer 정보는 Viewer별 Projection으로 분리한다.
- Private Content와 Credential을 Public Source·Client에 노출하지 않는다.
- Studio-only Production 의존성을 남기지 않는다.
- AI Draft와 Campaign Data를 실행 Code로 사용하지 않는다.
- 문서·Static·Codex Review PASS는 Runtime PASS가 아니다.
