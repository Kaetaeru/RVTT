# RVTT R3 Authority Hygiene Audit 003

- 상태: `RECONCILED · PENDING_FINAL_HEAD_CI · R3_NOT_FROZEN`
- 작성일: 2026-08-13
- 대상: `current execution/status surfaces + current authority corpus direction`
- Architecture/System/Requirement/Scenario 의미 변경: `없음`
- Source/Studio gate 변경: `없음`

## 1. 독립 재검증 Finding

R3 Freeze 전 반복 재검증에서 semantic model 자체가 아니라 현재 실행 방식을 안내하는 상위/진입 문서가 오래된 Greenfield/Studio-first 상태를 계속 노출하고 있음을 확인했다.

대표 충돌:

```text
.github/README.md
→ 존재하지 않는 commandPath 중심 라우팅

implementation/roblox/README.md
→ legacy src/**를 현재 Production Source처럼 소개
→ Studio MCP 구현을 현재 개발 루프로 안내

EXECUTION-TEST-RULES.md / ROBLOX-STUDIO-MCP-TEST-POLICY.md
→ Studio-first / immediate Studio implementation을 현재 기본값으로 선언

IMPLEMENTATION-STATUS.md / AGENT-TEST-STATUS.md
→ READY_FOR_G0_PREFLIGHT / STUDIO_FIRST_ITERATION 등 retired 상태 노출

docs/remake/CURRENT-WORK-ORDER.md / specs indexes
→ retired Module Contract / S1-C1-M1-X1-I1 / Studio-first handoff를 현재 순서처럼 노출

codex-supervised-review-and-test-policy.md
→ 확정 Process Policy가 retired Module Contract + legacy Source + immediate Studio MCP를 기본 개발 방향으로 고정
```

## 2. Current Process Reconciliation

이미 승인된 현재 순서는 다음으로 통일했다.

```text
R3 validation complete
→ USER R3 FREEZE
→ R4 E0 Checkpoint Freeze
→ Dedicated Implementation Branch
→ E0 Repository Core Engine
→ CORE_ENGINE_COMPLETE
→ E1 Runtime Checkpoint Freeze
→ Studio/MCP Runtime Provider + Integration
→ INTEGRATION_READY
→ U0 Product UI Shell
→ UI_SHELL_READY
→ E2
```

해석:

```text
legacy implementation/roblox/src/**
= READ_ONLY_REFERENCE
= new Greenfield baseline 아님

greenfield/src/**
= new Greenfield Source root
= 현재 NOT STARTED / BLOCKED

Studio/MCP
= 폐기하지 않음
= CORE_ENGINE_COMPLETE 후 E1에서 직접 구현/Play loop 활성화
```

`validate_greenfield_boundary.py`와 Workflow trigger를 확장해 current routing/status/process surface가 위 gate와 어긋나면 실패하도록 했다.

## 3. Historical Authority Snapshot Reverse-coupling

위 current Product/Spec/Work Order 문서를 정상적으로 정합화하자 `Validate RVTT architecture coverage`와 `Validate RVTT implementation system model`이 실패했다.

원인:

```text
ARCHITECTURE-COVERAGE-POLICY.md
→ architecture-coverage.json = historical evidence

하지만 validate_architecture_coverage.py
→ architecture-coverage.json.authorityCorpus의 과거 tree/blob SHA를
  current HEAD authority lock처럼 계속 강제
```

즉 historical evidence가 current authority의 정상적인 변경을 막는 역방향 의존성이었다.

Historical `architecture-coverage.json`은 다시 쓰지 않는다.

## 4. Current R3 Authority Corpus

현재 authority binding을 새 manifest로 분리했다.

```text
implementation/roblox/manifests/r3-authority-corpus.json
```

현재 snapshot 대상은 정확히:

```text
docs/remake/product
docs/remake/decisions
docs/remake/architecture
docs/remake/systems
docs/remake/ui
```

`docs/remake/specs/**`는 requirement/reference corpus이며 current implementation model authority가 아니다. Current Work Order와 routing/status surface는 planning-boundary validator가 별도로 검증한다.

현재 tree binding:

```text
product      32338e3ddccbf6497d806ceb1e649f2a2c809329
decisions    54125338b3af1650b4bce9d7e3ff31496ae7e03c
architecture 249d9a7293380c33f6d7195ddfa38da58fe86979
systems      742efb372264b85fa26a3f57b2541fd0405d26e2
ui           2effbddd018b02074daa2becc3d7d0b72e6e438b
```

`validate_architecture_coverage.py`는 이제 이 current manifest만 HEAD와 비교한다. legacy `architecture-coverage.json.authorityCorpus`는 historical identity/evidence로만 보존하고 current SHA lock으로 사용하지 않는다.

## 5. Workflow Hardening

`validate-architecture-coverage.yml`과 `validate-module-contracts.yml`은 `r3-authority-corpus.json`과 current authority tree 변경을 감시한다.

System-model Workflow의 기존 blind spot도 함께 수정했다.

```text
clean Base/Expanded Scenario
v2/v3 semantic audit
current authority corpus
Product/ADR/Architecture/System/UI
```

변경 시 재실행되며, push branch에 `main`도 포함한다.

## 6. 실행 권위 Read Path

`AGENTS.md`와 `.github/CODEX-ACTIVE-TASK.md`에도 `r3-authority-corpus.json`을 current read path로 추가했다.

```text
AGENTS / Active Task
→ Implementation Model / Systems
→ r3-authority-corpus.json
→ implementation-system-model.json
→ semantic audit v3/v2
→ clean Scenario catalogs
```

Historical coverage/snapshot은 current implementation input에서 제외한다.

## 7. 보존된 불변식

이번 reconciliation은 다음을 바꾸지 않았다.

```text
34 Systems
30 Requirement Capabilities
61 Scenarios
27 typed recovery Scenarios
A3/A8/A7 event ownership
A1 Ready gate
Reservation taxonomy
Provider contracts
Authority/state ownership
input grammar
E0 → E1 → U0 → E2 sequence
Source = BLOCKED
Studio/MCP = BLOCKED
R3 = NOT FROZEN
```

## 8. 완료 조건

이 Audit 003과 current authority corpus 변경을 포함한 **동일 최종 HEAD**에서 다음 9개 Pull Request Workflow가 모두 `completed / success`여야 한다.

```text
Validate RVTT architecture coverage
Validate RVTT implementation planning boundary
Validate RVTT implementation system model
Validate RVTT implementation
Validate Grand harness
Validate acceptance bootstrap
Validate production lease
Validate RVTT content templates
Validate remake documentation
```

검증 성공은 R3 자동 Freeze가 아니다. 사용자 Freeze 결정 후에만 R4로 이동한다.
