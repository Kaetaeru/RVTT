# RVTT Architecture Coverage Policy

- 상태: `ACTIVE · SYSTEM_MODEL_V2_REPAIRED · SEMANTIC_AUDIT_V3_VALIDATED`
- System Authority: `SYSTEMS.md`
- Current Authority Corpus: `manifests/r3-authority-corpus.json`
- Canonical Base Scenario source: `manifests/scenario-base-catalog.json`
- Canonical Expanded Scenario source: `manifests/scenario-expanded-catalog.json`
- Direct model: `manifests/implementation-system-model.json`
- Semantic classification evidence: `manifests/scenario-semantic-audit.json` (v2)
- Effective Scenario audit: `manifests/scenario-semantic-audit-v3.json`
- Historical legacy coverage: `manifests/architecture-coverage.json`, `manifests/architecture-scenarios.json`

이 문서는 Product/ADR/Architecture/UI 요구가 현재 구현 모델에서 빠지는 것을 막는 Coverage 방법을 소유한다. 폐기된 Greenfield 25 Module / 10 System / 64 Stable Function 모델은 새 구현 권위가 아니다.

## 1. 현재 추적 구조

```text
Current Product / Accepted ADR / Architecture / System / UI corpus
→ r3-authority-corpus.json current tree binding
↕
30 Requirement Capability Catalog v3
↕ many-to-many
34 System Responsibility Model v2
↕
61 Clean Canonical Scenario bodies
  - Base 14: scenario-base-catalog.json
  - Expanded 47: scenario-expanded-catalog.json
↕
Scenario Semantic Audit v1 direct-stage base
↕
Scenario Semantic Audit v2 classification/schema evidence
↕
Scenario Semantic Audit v3 clean-source + immutable-evidence binding
↕
R3 execution boundary
↕
R4 Module / Stable Function / E0 Checkpoint
↕
Source / Test / Runtime Evidence / Human Acceptance
```

Requirement Capability는 System 이름의 별칭이 아니다. 하나의 Requirement가 여러 System을 압박하고 하나의 System도 여러 Requirement를 만족해야 한다.

## 2. Current Authority Corpus

현재 R3 authority snapshot은 `r3-authority-corpus.json`이 소유한다.

정확히 다음 tree를 current HEAD에 고정한다.

```text
docs/remake/product
docs/remake/decisions
docs/remake/architecture
docs/remake/systems
docs/remake/ui
```

이 tree 중 하나가 바뀌면 R3 coverage revalidation이 필요하다.

`docs/remake/specs/**`는 requirement/reference corpus이며 현재 implementation model authority가 아니다. Current Work Order와 routing/status 문서는 planning-boundary validator가 별도로 검증한다.

## 3. Historical Coverage Evidence

`architecture-coverage.json`은 과거 Greenfield coverage/gap audit와 당시 `authorityCorpus` snapshot을 보존하는 **historical evidence**다.

따라서:

```text
architecture-coverage.json.authorityCorpus
≠ current HEAD authority lock
≠ current implementation input
```

현재 Product/ADR/Architecture/UI 변경에 맞춰 historical snapshot을 재작성하지 않는다. 현재 authority binding은 오직 `r3-authority-corpus.json`에서 갱신하고 전체 R3 coverage를 다시 검증한다.

`architecture-scenarios.json`도 historical Expanded Greenfield evidence다. legacy capabilityRefs/status는 현재 구현 권위가 아니다.

## 4. 권위 역할

- `r3-authority-corpus.json`: 현재 Product/ADR/Architecture/System/UI tree snapshot.
- `scenario-base-catalog.json`: Base 14 canonical body. legacy Greenfield coverage/mapping metadata 금지.
- `scenario-expanded-catalog.json`: Expanded 47 canonical body. legacy Greenfield coverage/mapping metadata 금지.
- `implementation-system-model.json`: 34 System, 30 Requirement Capability, 61 direct Scenario Requirement/System trace, v1 semanticStages.
- `scenario-semantic-audit.json`: v2 immutable classification/schema evidence.
- `scenario-semantic-audit-v3.json`: clean Base/Expanded + immutable historical Expanded evidence + v1 + immutable v2 evidence + semantic schema를 묶는 effective audit.
- `architecture-coverage.json`: historical Greenfield coverage/gap/authority snapshot evidence.
- `architecture-scenarios.json`: historical Expanded Greenfield registry evidence.

## 5. Scenario Semantic Audit v3

현재 digest:

```text
v1 direct trace digest
sha256:57e485a0cec6d753542e4bc202a881e10e2bd5ae63e314cc609c7e2d99f38140

v2 semanticSchemaDigest
sha256:dcc766c1161332789e91aadc362c4765687af3efc2f7193cf23f748df0eb6489

v3 combinedAuditDigest
sha256:bd2db9a2d97c224c73265cd11dc6db32e81a17fc24b7fe6909254a5185196f38
```

Clean Scenario object에는 retired Greenfield `status/capabilityRefs/systemRefs/moduleRefs/knownGapRefs`를 허용하지 않는다.

Ingress는 System과 Requirement를 함께 검증한다.

```text
COMMAND → A2 + A1 → REQ_REQUEST_PROTOCOL + REQ_CONTROL_PERMISSION
READ_REQUEST → A2 → REQ_REQUEST_PROTOCOL
SYNC_CONTROL → A6 + A1 → REQ_SESSION_PLAYABILITY
EVENT_TRIGGER → A8 → REQ_COMMITTED_EVENT_PROPAGATION
TEST_HARNESS → S2 → REQ_DIAGNOSTICS_REPRODUCIBILITY
```

현재 typed recovery pressure를 가진 Scenario는 27개다.

## 6. Cross-cutting Coverage

Requirement/System 경계를 검토할 때 최소 다음을 확인한다.

```text
AUTHORITY
PERMISSION
STATE_OWNERSHIP
COMMAND / READ
PROJECTION_DISCLOSURE
EVENT_DELIVERY
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

## 7. R3 불변식

```text
A3 transaction + transactional outbox
→ A8 committed delivery
→ subscribers

A8 delivery semantics → A7 durability seam → StorageAdapter
```

```text
A7 authorityRecoveryReady
A6 projectionSyncReady
W7 sceneEssentialReady
C1 clientReplicaReady
→ A1 final EffectiveGameplayReady
```

```text
OrderingReservation → A3
ResourceReservation → R3
OccupancyReservation → W6
ActivityReservation → D5
LogisticsAllocationReservation → D7
```

Shared providers:

```text
AuthorityMonotonicClock
DeterministicIdFactory
RngProvider
TransportAdapter
StorageAdapter
```

## 8. REPOSITORY_LOGIC와 E0_CORE_ENGINE

`REPOSITORY_LOGIC`는 Roblox 없이 구현 가능한 production logic의 분류다. `E0_CORE_ENGINE`은 Studio 전에 반드시 완성할 Foundation subset이다. 둘은 같은 뜻이 아니다.

E1 Provider가 소비하는 Core contract/policy/state-machine은 E0에 포함한다. `CORE_ENGINE_COMPLETE` 전 Studio/MCP 구현은 금지한다.

## 9. 구현 AI 읽기 정책

Planning 기본 표면:

```text
AGENTS.md
→ .github/CODEX-ACTIVE-TASK.md
→ IMPLEMENTATION-MODEL.md
→ SYSTEMS.md
→ r3-authority-corpus.json
→ implementation-system-model.json
→ scenario-semantic-audit-v3.json
→ scenario-semantic-audit.json
→ scenario-base-catalog.json
→ scenario-expanded-catalog.json
→ 필요한 상위 Authority만 선택적으로
```

`architecture-coverage.json`과 `architecture-scenarios.json`의 legacy Greenfield mapping/snapshot은 구현 AI 기본 읽기 대상이 아니다.

## 10. 변경 Gate

현재 합의 방향 안의 명백한 문서 상태 drift, stale pointer, validator false-green, workflow trigger 누락은 발견 즉시 수정하고 최종 HEAD에서 재검증한다.

다음은 사용자 결정 없이 자동 적용하지 않는다.

- 새로운 핵심 System boundary
- state owner 변경
- Server/Client Authority 변경
- 입력 문법 변경
- 실행 순서 변경
- Module 실질 분리/통합
- Product/ADR 변경

Coverage Finding은 Architecture 변경 승인과 동일하지 않다.

## 11. 현재 Gate

```text
SYSTEM_MODEL_V2_REPAIRED
REQUIREMENT_CAPABILITY_V3_ACTIVE
SCENARIO_SEMANTIC_AUDIT_V3_VALIDATED
CURRENT_AUTHORITY_CORPUS = R3_BOUND
R3_VALIDATED_NOT_FROZEN
AWAITING_USER_FREEZE_DECISION
SOURCE = BLOCKED
STUDIO = BLOCKED
```

검증이 통과해도 R3는 자동 Freeze하지 않는다. 사용자 결정 후에만 R4로 넘어간다.
