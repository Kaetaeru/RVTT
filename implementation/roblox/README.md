# RVTT Roblox Implementation Workspace

이 디렉터리는 RVTT 리메이크의 Roblox Production Source, Test Source, Rojo Project와 Acceptance Tooling을 둔다.

## 현재 기준 문서

- [`CURRENT-WORK-ORDER.md`](CURRENT-WORK-ORDER.md) — 현재 구현·검증 순서
- [`IMPLEMENTATION-STATUS.md`](IMPLEMENTATION-STATUS.md) — 구현·Studio Evidence 상태
- [`EXECUTION-TEST-RULES.md`](EXECUTION-TEST-RULES.md) — Batch와 Grand Campaign 실행 규칙
- [`GRAND-ACCEPTANCE-CAMPAIGN.md`](GRAND-ACCEPTANCE-CAMPAIGN.md) — 단일 PowerShell 실행 기반 통합 Acceptance
- [`grand-acceptance-manifest.json`](grand-acceptance-manifest.json) — Grand Phase Registry와 Summary 계약
- [`manifests/all-slices-script-manifest.md`](manifests/all-slices-script-manifest.md) — 16개 Slice Script Coverage

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
- `test.project.json` — Unit·Integration Test Place
- `multi-client.project.json` — DM·Player·Observer Multi-client Place
- `live-datastore.project.json` — Live DataStore Baseline
- `persistence-acceptance.project.json` — Persistence 전용 Acceptance
- `slice01-acceptance.project.json` — DataStore 비활성 Slice 01 World Interaction

## Grand Acceptance

`tooling/run-grand-acceptance.ps1`은 다음을 수행한다.

```text
등록된 Project 전체 Build
→ READY Studio Phase 순차 실행
→ 최근 Roblox Log Summary 수집
→ 실패 후에도 다음 Phase 계속 실행
→ JSON·Markdown 통합 Report 생성
```

아직 구현되지 않은 Slice·Fault·UI·Performance Phase는 `blocked`로 기록한다. 실제 Runtime PASS로 간주하지 않는다.

## 핵심 경계

- Client는 Intent만 제출한다.
- Server가 Authorization·Rules·Transaction·Projection을 소유한다.
- UI는 Remote를 직접 호출하지 않는다.
- Player·DM·Observer 정보는 Viewer별 Projection으로 분리한다.
- 일반 기능 Acceptance는 DataStore를 사용하지 않는다.
- Persistence는 별도 Grand Milestone에서 한 번에 검증한다.
- Acceptance Harness는 실제 사용자 입력을 메서드 직접 호출로 대체하지 않는다.
- 사용자 실행 명령은 저장소 Update와 정확한 Head 검사가 포함된 완전한 Windows PowerShell 블록으로 제공한다.
