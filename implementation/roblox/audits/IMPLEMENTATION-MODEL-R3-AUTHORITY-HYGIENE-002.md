# RVTT R3 Authority Hygiene Audit 002

- 상태: `RECONCILED · VALIDATED_PENDING_FINAL_HEAD_CI · R3_NOT_FROZEN`
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

## 6. Completion Condition

다음이 동일 최종 HEAD에서 모두 성공해야 이 reconciliation을 완료로 본다.

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

R3는 이 검증이 성공해도 자동 Freeze하지 않는다.
