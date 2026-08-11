# RVTT Roblox Implementation Workspace

이 디렉터리는 RVTT의 Production Source, Test, Rojo Project, Runtime·Release Tooling을 둔다.

## 현재 기준

- [`CURRENT-WORK-ORDER.md`](CURRENT-WORK-ORDER.md) — 현재 구현 순서
- [`EXECUTION-TEST-RULES.md`](EXECUTION-TEST-RULES.md) — Studio-first 개발과 Release 검증 구분
- [`ROBLOX-STUDIO-MCP-TEST-POLICY.md`](ROBLOX-STUDIO-MCP-TEST-POLICY.md) — MCP 직접 구현 규칙
- [`CODEX-REVIEW-TEST-GATE.md`](CODEX-REVIEW-TEST-GATE.md) — Stabilization·고위험 Review Gate
- [`FULL-UI-UX-ACCEPTANCE.md`](FULL-UI-UX-ACCEPTANCE.md) — UI 회귀·Release Acceptance
- [`GRAND-ACCEPTANCE-CAMPAIGN.md`](GRAND-ACCEPTANCE-CAMPAIGN.md) — Release 통합 Campaign
- [`ADR-0092-PHASED-PRODUCTION-PLAN.md`](ADR-0092-PHASED-PRODUCTION-PLAN.md) — ADR-0092 기능 순서

## 현재 개발 루프

```text
GitHub Authority·Source 조사
→ Studio MCP로 현재 DataModel 조사
→ 실제 UI·Instance·Script 구현
→ Play
→ 즉시 수정
→ 사용자 판단
→ GitHub Source·Rojo Mapping 정규화
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
- `slice01-acceptance.project.json` — World Interaction Regression Harness

Rojo는 Source↔DataModel 연결, 재현 가능한 Build와 CI를 담당한다. 매 개발 Play마다 Acceptance Place를 새로 Build할 필요는 없다.

## Studio MCP

Codex는 Studio를 수정하기 전에 GitHub의 관련 Module·함수·Remote·Schema·Test를 읽는다. 그 뒤 MCP로 실제 Place를 조사하고 작은 사용자 흐름을 직접 구현·Play한다.

Studio에서 안정된 Production 변경은 반드시 Repository Source와 Project Mapping으로 환원한다.

## 기존 Acceptance Tooling

기존 Batch·Grand Tooling은 삭제하지 않는다.

용도:

- Focused regression
- Stabilization
- Multi-client·Persistence 검증
- Merge·Release Candidate

Harness UI는 제품 UI가 아니다. Product UX를 Harness 편의에 맞추지 않는다.

## 핵심 Production 경계

- Client는 Intent만 제출한다.
- Server가 Authorization·Rules·Transaction·Projection을 소유한다.
- UI는 Remote를 직접 호출하지 않는다.
- Player·DM·Observer 정보는 Viewer별 Projection으로 분리한다.
- Private Content와 Credential을 Public Source·Client에 노출하지 않는다.
- Studio-only Production 의존성을 남기지 않는다.
- AI Draft와 Campaign Data를 실행 Code로 사용하지 않는다.
- 문서·Static·Codex Review PASS는 Runtime PASS가 아니다.
