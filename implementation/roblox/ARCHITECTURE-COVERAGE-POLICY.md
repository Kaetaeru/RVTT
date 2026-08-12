# RVTT Architecture Coverage Policy

- 상태: `ACTIVE · SYSTEM_MODEL_V1`
- 최종 갱신일: 2026-08-13
- System + Capability v2 Authority: [`SYSTEMS.md`](SYSTEMS.md)
- Legacy Capability/Base Scenario Registry: [`manifests/architecture-coverage.json`](manifests/architecture-coverage.json)
- Expanded Scenario Registry: [`manifests/architecture-scenarios.json`](manifests/architecture-scenarios.json)
- R2 Pressure Evidence: [`audits/IMPLEMENTATION-MODEL-R2-SCENARIO-PRESSURE-001.md`](audits/IMPLEMENTATION-MODEL-R2-SCENARIO-PRESSURE-001.md)

이 문서는 Product/ADR/Architecture/UI의 중요한 요구가 구현 모델에서 빠지는 것을 막는 Coverage 방법을 소유한다.

## 1. 현재 모델 상태

기존 Greenfield 25 Module / 10 System / 64 Stable Function 모델은 폐기됐다.

현재 승인된 구현 책임 모델:

```text
33 System Model v1
34 Capability Catalog v2
61 Representative Scenarios
```

권위 System/Capability 목록은 `SYSTEMS.md`에 있다.

`architecture-coverage.json`의 기존 22 Capability, `coverageState`, `systemRefs`, `moduleRefs`는 R0/R1 이전의 **legacy coverage vocabulary/evidence**로 보존한다. 새 구현 경계를 복원하는 권위로 사용하지 않는다.

## 2. 추적 구조

현재 canonical trace:

```text
Product / Accepted ADR / Current Architecture / UI
↕
Capability v2
↕
33 System Model v1
↕
Representative Scenario Pressure Path
↕
R3 Core / Roblox Runtime / Presentation boundary
↕
R4 Module / Stable Function / E0 Checkpoint
↕
Source
↕
Test / Runtime Evidence / Human Acceptance
```

Scenario Registry의 legacy `capabilityRefs`는 요구사항 태그로 유지하되, 새 구현 책임 추적은 R2 Pressure Map의 System ID와 `SYSTEMS.md`의 System→Capability v2 mapping을 사용한다.

## 3. Authority Corpus

Coverage Review의 상위 Authority Corpus:

```text
docs/remake/product
docs/remake/decisions
docs/remake/architecture
docs/remake/systems
docs/remake/ui
docs/remake/specs
```

Historical/Archive/Legacy Source는 요구사항 Authority가 아니다.

상위 Authority가 바뀌면 단순 SHA 교체가 아니라 Capability/System/Scenario 영향 검토를 다시 한다.

## 4. Capability Catalog v2

Capability는 Module 이름이 아니라 제품/Architecture가 제공해야 하는 능력이다.

현재 Capability v2는 34개이며 `SYSTEMS.md`가 목록과 System mapping을 소유한다.

legacy 22 중 과도하게 합쳐졌던 책임은 다음처럼 해소됐다.

```text
Projection + Sync
→ Projection Runtime + Client Synchronization

Scene identity + Runtime Object
→ Scene Runtime Activation + Runtime Object Lifecycle

Time + Downtime + Persistence
→ Game Time/Scheduler + Downtime/Activity + Persistence/Branch Recovery

UI + Camera + Presentation
→ UI/Input + Camera + Presentation Runtime

Diagnostics + Simulation
→ Diagnostics/Observability + Deterministic Simulation
```

legacy catalog에 독립 ID가 없던 다음 책임도 v2에 추가됐다.

```text
Cross-Domain Outcome
Dice / Resolution
Effect / Ongoing
Scene Authoring
Scene Delivery / Ready
```

## 5. Representative Scenario

Base 14 + Expanded 47 = 총 61개 Scenario를 하나의 Catalog로 취급한다.

R2에서 61/61을 33-System Model에 다시 통과시켰고 책임 경로가 빈 Scenario는 없었다.

Scenario의 목적:

- System 사이 연결 누락 발견
- 미래 기능이 현재 shared boundary를 압박하는 방식 발견
- concurrency/disclosure/recovery/failure negative path 발견
- 사용자/DM/운영 결과 End-to-End 검증

Scenario 추가는 Architecture 변경 승인 자체가 아니다.

## 6. Cross-cutting Matrix

Capability/System 경계를 검토할 때 최소 다음을 확인한다.

```text
AUTHORITY
PERMISSION
STATE_OWNERSHIP
COMMAND / READ
PROJECTION_DISCLOSURE
PERSISTENCE
RECONNECT
ROLLBACK
MULTIPLAYER_CONCURRENCY
FAILURE
OBSERVABILITY
SECURITY
AUTOMATED_TEST
HUMAN_TEST
```

`N/A`와 `DEFERRED`도 이유가 있어야 한다.

## 7. 기존 GAP-001~012의 의미

GAP-001~012는 폐기된 Greenfield 모델에서 발견한 요구사항 누락 증거다.

새 모델을 기존 Gap 목록에 맞춰 패치하지 않는다.

- v1 System이 책임을 자연스럽게 포함하면 기존 Gap은 해소 후보다.
- 새 모델 관점에서 다른 구조적 문제가 발견되면 새 Finding을 만든다.
- Gap 번호 보존을 위해 잘못된 System split을 만들지 않는다.

## 8. 현재 Implementation Gate

현재:

```text
SYSTEM_MODEL_V1_APPROVED
R3_BOUNDARY_FREEZE_ACTIVE
SOURCE = BLOCKED
STUDIO = BLOCKED
```

Source Gate 해제 순서:

```text
R3 Core/Runtime/Presentation Boundary Freeze 승인
+ R4 E0 Checkpoint Freeze
→ Dedicated Implementation Branch 생성
→ Repository Core Engine 구현
```

**Repository Core Engine 전체 완료 전 Studio/MCP 구현은 금지한다.**

## 9. 구현 AI 읽기 정책

Planning 단계 기본 표면은 짧게 유지한다.

```text
AGENTS.md
→ .github/CODEX-ACTIVE-TASK.md
→ IMPLEMENTATION-MODEL.md
→ SYSTEMS.md
→ 필요한 Scenario/Evidence만 선택적으로
```

구현 Branch가 생긴 뒤에는 Planning Tree 전체를 기본 검색하지 않고 압축된 Implementation Pack만 사용한다.

미모델링 책임이나 미래 충돌을 발견하면 helper로 우회하지 않고 `ESCALATE_TO_PLANNING`한다.

## 10. 변경 Gate

다음은 사용자 결정 없이 자동 적용하지 않는다.

- 새로운 핵심 System boundary
- state owner 변경
- Server/Client Authority 변경
- 입력 문법 변경
- 실행 순서 변경
- Module 실질 분리/통합
- Product/ADR 변경

Coverage Finding은 Architecture 변경 승인과 동일하지 않다.

## 11. 현재 다음 작업

**R3 — 33개 System의 책임을 Repository Core Engine / Roblox Runtime Engine·Adapter / Presentation·Human Feel로 분해한다.**

System 전체를 한 환경에 배치하지 않는다. 예를 들어 Navigation은 Core policy와 Roblox Pathfinding provider, Presentation preview/feel을 서로 분리한다.
