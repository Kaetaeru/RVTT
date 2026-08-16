# RVTT R3 Authority Hygiene Audit 002

- 상태: `RECONCILED · VALIDATED · R3_NOT_FROZEN · AWAITING_USER_FREEZE_DECISION`
- 작성일: 2026-08-13
- 대상: `R3 current-state / Scenario source / validator authority hygiene`
- Architecture 변경: `없음`
- System / Requirement / Scenario 의미 변경: `없음`
- Source / Studio gate 변경: `없음`

## 1. 발견 사항

Freeze 전 독립 재검증에서 다음 authority hygiene 문제가 발견됐다.

```text
AGENTS.md
→ 실제 상태는 R3 validation complete인데 validation-in-progress로 남음

validate_greenfield_boundary.py / validate_execution_layers.py
→ current status가 아니라 prior repaired status substring으로 false-green 가능

Expanded 47 Scenario
→ canonical body가 legacy Greenfield architecture-scenarios.json 안에 있어 CAP_* capabilityRefs와 같은 object에 공존
```

## 2. 즉시 수정 정책

사용자 지시에 따라 앞으로 현재 합의 방향 안의 명백한 문서 정합성, stale pointer, validator false-green, workflow trigger 누락은 발견 즉시 수정한다.

다음은 계속 사용자 결정이 필요하다.

```text
Product / Accepted ADR 변경
Authority / State owner 변경
핵심 System / Module responsibility 변경
입력 문법 변경
개발 순서 / Checkpoint 변경
Release scope / priority 변경
```

## 3. Clean Scenario Authority

현재 canonical Scenario body source:

```text
Base 14
→ implementation/roblox/manifests/scenario-base-catalog.json

Expanded 47
→ implementation/roblox/manifests/scenario-expanded-catalog.json
```

두 clean catalog는 다음 legacy mapping key를 허용하지 않는다.

```text
capabilityRefs
systemRefs
moduleRefs
knownGapRefs
```

과거 `architecture-scenarios.json`은 historical Greenfield evidence로 유지한다.

Validator는 historical Expanded에서 다음 body projection만 추출해 clean Expanded와 exact equality를 검사한다.

```text
id
phase
steps
expectedOutcome
negativeCases
```

따라서 Scenario 의미는 유지하면서 구현 AI 기본 읽기 경로에서 legacy `CAP_*` vocabulary를 제거한다.

## 4. Semantic Audit Layering

```text
v1
= implementation-system-model.json direct Requirement/System/semanticStages trace

v2
= scenario-semantic-audit.json
= 61 entry/recovery classification + mutation/ingress/recovery semantic schema evidence

v3
= scenario-semantic-audit-v3.json
= clean Base/Expanded source binding + v1 trace + immutable v2 audit + v2 semantic schema
```

v3 combined digest:

```text
sha256:3d548607d17c7ca7fb13cb44b6b3e8f305f0cb5e5a3a46eacdae7ee19497e46e
```

v3는 Scenario 의미를 새로 정의하지 않는다. v2 classification evidence를 clean Scenario sources에 다시 묶는다.

## 5. Current-state Validator Reconciliation

Planning boundary와 execution-layer validator는 이제 current Active Task status를 exact marker로 검사한다.

```text
- status: `R3_VALIDATED_AWAITING_FREEZE_DECISION`
```

`priorRepairedBaseStatus` 같은 historical substring으로 통과하는 경로는 제거했다.

AGENTS.md도 다음 현재 상태와 일치해야 통과한다.

```text
R3 = VALIDATED · NOT FROZEN · AWAITING USER FREEZE DECISION
NEXT = USER R3 FREEZE DECISION
```

## 6. Validation Evidence

Reconciliation 구현이 완료된 HEAD `702bc4777c605822da5f2e13f9dad412cfe16b53`에서 9개 Pull Request Workflow가 모두 `completed / success`를 기록했다.

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

이 상태 표기 커밋이 만든 최종 HEAD에서도 동일 9개 Workflow 성공을 다시 확인하는 것을 최종 완료 조건으로 한다.

R3는 검증 성공으로 자동 Freeze되지 않는다.

## 7. Second Independent Revalidation · Authority Direction Repair

사용자 요청으로 Freeze 전 다시 독립 재검증했다. 이 과정에서 Architecture 변경이 아닌 세 가지 추가 authority-hygiene 결함을 발견했다.

```text
Clean Base 14
→ legacy coverage status(BLOCKED/MAPPED/DEFERRED...)가 Scenario object에 남아 있었음

Clean Base/Expanded policy
→ semanticAuditOwnedBy가 effective v3가 아니라 v2 classification evidence를 가리키고 있었음

Historical Expanded validation
→ historical-only라고 선언하면서 매 실행 clean Expanded와 exact equality를 요구해
  향후 canonical Scenario 변경이 historical evidence 재작성까지 요구하는 역방향 의존성이 생김
```

즉시 수정 결과:

```text
Clean Base/Expanded Scenario object
→ id / phase / steps / expectedOutcome / negativeCases만 허용
→ legacy coverage status/mapping metadata 금지

semanticAuditOwnedBy
→ scenario-semantic-audit-v3.json

architecture-scenarios.json
→ immutable historical evidence blob
→ clean Expanded 추출 당시 equivalence는 과거 검증 evidence로 보존
→ 이후 canonical Scenario의 정상적 semantic re-audit와 독립
→ historical evidence를 canonical 변화에 맞춰 재작성하지 않음
```

이 섹션의 규칙이 §3의 동적 exact-equality 설명과 §4의 이전 v3 digest를 **현재 상태에 대해 supersede**한다. §3~§4는 당시 reconciliation 이력으로 보존하며 다시 쓰지 않는다.

현재 v3 combined digest:

```text
sha256:bd2db9a2d97c224c73265cd11dc6db32e81a17fc24b7fe6909254a5185196f38
```

현재 combined binding:

```text
Clean Base blob
+ Clean Expanded blob
+ immutable Historical Expanded evidence blob
+ v1 direct trace digest
+ immutable v2 classification-audit blob
+ v2 semantic schema digest
```

이번 변경은 System 34, Requirement 30, Scenario 61의 의미, Authority/state ownership, ingress grammar, 개발 순서, Source/Studio gate를 변경하지 않는다.

최종 완료 조건은 이 second revalidation 변경을 포함한 동일 HEAD에서 9개 Pull Request Workflow가 모두 성공하는 것이다.

## 8. Third Independent Revalidation · Immutable Evidence Guard

추가 독립 재검증에서 v3가 historical Expanded와 v2 classification audit를 `immutable evidence`로 선언하면서도, 기존 validator가 단지 `현재 blob SHA == v3 manifest에 기록된 SHA`만 확인한다는 false-green 가능성을 발견했다.

즉 evidence 파일과 v3 manifest의 SHA/digest를 동시에 변경하면 자기일관성 검증만으로는 통과할 수 있었다.

이를 막기 위해 다음 승인 evidence SHA를 별도 validator trust pin으로 고정했다.

```text
architecture-scenarios.json
→ 93f275b373c9f88b12ed3078149ff562642a5b1d

scenario-semantic-audit.json (v2)
→ 839f05d0d7ba1f53eec87fd35981d4b961d513ef
```

`validate_r3_immutable_evidence.py`는 실제 HEAD blob과 v3 `sourceBinding`이 모두 위 고정 SHA와 일치하는지 검사한다. `validate-architecture-coverage.yml`은 이 guard 자체의 변경도 trigger하고 매 실행에서 guard를 수행한다.

`SYSTEMS.md`의 v3 설명도 실제 binding과 맞게 `immutable Historical Expanded evidence blob`을 포함하도록 정합화했다.

이 변경 역시 Architecture/System/Requirement/Scenario 의미나 Source/Studio gate를 바꾸지 않는다. 최종 완료 조건은 이 guard와 문서 정합화를 포함한 동일 HEAD에서 9개 Pull Request Workflow가 모두 성공하는 것이다.

## 9. Fourth Independent Revalidation · Current Status Surface / Process Policy Repair

추가 재검증에서 Scenario/semantic audit 자체가 아니라 **현재 작업과 구현 방식을 안내하는 문서 표면**에 오래된 Greenfield/Studio-first 상태가 남아 있음을 발견했다.

확정 finding:

```text
implementation/roblox/README.md
→ src/**를 현재 Production Source로 소개
→ Studio MCP 직접 구현을 현재 개발 루프로 안내

.github/README.md
→ 현재 Active Task에 없는 commandPath 라우팅 모델을 요구

implementation/roblox/EXECUTION-TEST-RULES.md
→ ACTIVE 상태에서 Studio-first development를 기본값으로 선언

implementation/roblox/ROBLOX-STUDIO-MCP-TEST-POLICY.md
→ ACTIVE_DEFAULT_DEVELOPMENT_PATH로 Studio 직접 구현을 즉시 허용

implementation/roblox/greenfield-boundary.json
→ ACTIVE_PRE_G0_BOUNDARY + retired GREENFIELD-PREFLIGHT 포인터 유지

implementation/roblox/IMPLEMENTATION-STATUS.md
→ READY_FOR_G0_PREFLIGHT / Studio Workbench / G0 시작을 다음 실행으로 기록

AGENT-TEST-STATUS.md
→ STUDIO_FIRST_ITERATION / Production Studio UX IN_PROGRESS

docs/remake/README.md
→ 현재 개발 방식을 STUDIO-MCP IMPLEMENTATION으로 안내

docs/remake/CURRENT-WORK-ORDER.md
→ retired Module Contract → S1/C1/M1/X1/I1 순서를 현재 구현 순서로 기록

docs/remake/specs/README.md + CURRENT-SPEC-WORK-ORDER.md
→ 과거 implementation handoff / Studio-first 상태를 현재 구현 권위처럼 노출

AGENTS-PLANNING-ADDENDUM.md
→ READY/Studio 탐색 일반 원칙이 current execution gate를 우회한다고 오해될 여지

docs/remake/product/codex-supervised-review-and-test-policy.md
→ 확정 Process Policy가 retired Module Contract + legacy Source + immediate Studio MCP를 기본 개발 방향으로 고정

implementation/roblox/CODEX-REVIEW-TEST-GATE.md
→ 기본 Studio 반복을 현재 기본 모드로 선언
```

현재 사용자 결정과 기존 R3 execution invariant는 다음이다.

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
→ U0
→ E2
```

따라서 위 finding은 새 개발 순서를 만드는 변경이 아니라 **이미 승인된 순서를 higher/current authority surface에 top-down으로 reconciliation**하는 작업이다.

수정 결과:

```text
legacy implementation/roblox/src/**
→ READ_ONLY_REFERENCE
→ write lock 유지
→ 새 Greenfield baseline 아님

greenfield/src/**
→ 새 Greenfield Source root
→ 현재 NOT STARTED / BLOCKED

Studio/MCP
→ 폐기하지 않음
→ CORE_ENGINE_COMPLETE 후 E1에서 직접 구현·Play loop 활성화

16 Slice Specs
→ requirement/reference corpus
→ retired implementation split을 현재 권위로 자동 재사용 금지

Current routing/status/process docs
→ R3_VALIDATED_AWAITING_FREEZE_DECISION으로 통일
```

`validate_greenfield_boundary.py`는 이제 Active Task/AGENTS뿐 아니라 routing README, planning addendum, Agent Test Status, Remake current docs, Spec current indexes, Product Process Policy, Workspace README/Work Order/Implementation Status, Execution Rules, Studio Policy, Review Gate와 machine-readable `greenfield-boundary.json`을 직접 검사한다.

또한 `greenfield.project.json`의 모든 `$path`가 `greenfield/src/` 아래인지 검사하고, legacy `src/**`와 `default.project.json`은 기존 reset baseline object와 계속 동일해야 통과한다.

`validate-greenfield-boundary.yml`은 위 current-state/process surface들의 변경을 모두 trigger하도록 확장했다.

이 reconciliation은 Product 목표, Accepted ADR, Authority/state ownership, 34 System, 30 Requirement, 61 Scenario, input grammar, E0→E1→U0 순서를 변경하지 않는다. 최종 완료 조건은 이 변경을 포함한 동일 HEAD에서 planning-boundary validator와 전체 Pull Request Workflow가 모두 성공하는 것이다.
