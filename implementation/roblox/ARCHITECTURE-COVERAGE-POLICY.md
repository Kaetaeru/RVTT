# RVTT Architecture Coverage Policy

- 상태: `ACTIVE · SYSTEM_MODEL_V2_REPAIRED · SEMANTIC_AUDIT_V3_VALIDATED`
- System Authority: `SYSTEMS.md`
- Canonical Base Scenario source: `manifests/scenario-base-catalog.json`
- Canonical Expanded Scenario source: `manifests/scenario-expanded-catalog.json`
- Direct model: `manifests/implementation-system-model.json`
- Semantic classification evidence: `manifests/scenario-semantic-audit.json` (v2)
- Effective Scenario audit: `manifests/scenario-semantic-audit-v3.json`
- Historical legacy coverage: `manifests/architecture-coverage.json`, `manifests/architecture-scenarios.json`

이 문서는 Product/ADR/Architecture/UI 요구가 구현 모델에서 빠지는 것을 막는 Coverage 방법을 소유한다. 폐기된 Greenfield 25 Module / 10 System / 64 Stable Function 모델은 새 구현 권위가 아니다.

## 1. 현재 추적 구조

```text
Product / Accepted ADR / Current Architecture / UI
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
Scenario Semantic Audit v3 clean-source binding
↕
R3 execution boundary
↕
R4 Module / Stable Function / E0 Checkpoint
↕
Source / Test / Runtime Evidence / Human Acceptance
```

Requirement Capability는 System 이름의 별칭이 아니다. 하나의 Requirement가 여러 System을 압박하고 하나의 System도 여러 Requirement를 만족해야 한다.

## 2. 권위 역할

- `scenario-base-catalog.json`: Base 14 canonical body. legacy Greenfield capability/system/module mapping 금지.
- `scenario-expanded-catalog.json`: Expanded 47 canonical body. legacy Greenfield capability/system/module mapping 금지.
- `implementation-system-model.json`: 34 System, 30 Requirement Capability, 61 direct Scenario Requirement/System trace, v1 semanticStages.
- `scenario-semantic-audit.json`: v2 immutable evidence. mutation semantic, typed ingress/recovery expansion, LKG owner set, 61 classification, semantic schema digest를 보존한다.
- `scenario-semantic-audit-v3.json`: clean Base/Expanded blobs + direct trace + immutable v2 audit blob + semantic schema를 묶는 현재 effective audit.
- `architecture-coverage.json`: authority corpus snapshot과 과거 Greenfield coverage/gap evidence.
- `architecture-scenarios.json`: 과거 Expanded Scenario Greenfield registry evidence. `capabilityRefs`는 historical vocabulary일 뿐 구현 권위가 아니다.

v3 validator는 historical `architecture-scenarios.json`의 `id/phase/steps/expectedOutcome/negativeCases` projection이 clean Expanded 47과 정확히 같은지 검사한다. 따라서 historical evidence를 보존하면서 구현 AI는 legacy mapping을 읽지 않는다.

## 3. Scenario Semantic Audit v3

현재 digest:

```text
v1 direct trace digest
sha256:57e485a0cec6d753542e4bc202a881e10e2bd5ae63e314cc609c7e2d99f38140

v2 semanticSchemaDigest
sha256:dcc766c1161332789e91aadc362c4765687af3efc2f7193cf23f748df0eb6489

v3 combinedAuditDigest
sha256:3d548607d17c7ca7fb13cb44b6b3e8f305f0cb5e5a3a46eacdae7ee19497e46e
```

v3 감사 단위:

```text
Clean Base Scenario blob SHA
+ Clean Expanded Scenario blob SHA
+ v1 direct trace digest
+ immutable v2 classification-audit blob SHA
+ v2 semantic schema digest
→ v3 combinedAuditDigest
```

Clean catalog에는 다음 key가 들어가면 실패한다.

```text
capabilityRefs
systemRefs
moduleRefs
knownGapRefs
```

Ingress는 System과 Requirement를 함께 검증한다.

```text
COMMAND
→ A2 + A1
→ REQ_REQUEST_PROTOCOL + REQ_CONTROL_PERMISSION

READ_REQUEST
→ A2
→ REQ_REQUEST_PROTOCOL

SYNC_CONTROL
→ A6 + A1
→ REQ_SESSION_PLAYABILITY

EVENT_TRIGGER
→ A8
→ REQ_COMMITTED_EVENT_PROPAGATION

TEST_HARNESS
→ S2
→ REQ_DIAGNOSTICS_REPRODUCIBILITY
```

Typed recovery kinds:

```text
CLIENT_RESYNC
RECONNECT
SERVER_RESTART
ROLLBACK_BRANCH
RETRY_AFTER_RESTART
LAST_KNOWN_GOOD
CONTROL_FAILOVER
```

현재 전수감사 결과 **27개 Scenario**가 typed recovery pressure를 가진다.

강제 sentinel:

```text
SCN_ATTACK_REACTION_RESOLUTION → RECONNECT
SCN_CHARACTER_SHEET_LIVE_DAMAGE_SYNC → CLIENT_RESYNC
SCN_SCENE_CANDIDATE_TEST_PUBLISH → LAST_KNOWN_GOOD
SCN_DM_RECOVERY_REVIEW_BRANCH → SERVER_RESTART + ROLLBACK_BRANCH + CLIENT_RESYNC
```

## 4. Cross-cutting Coverage

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

## 5. R3 불변식

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

## 6. REPOSITORY_LOGIC와 E0_CORE_ENGINE

`REPOSITORY_LOGIC`는 Roblox 없이 구현 가능한 production logic의 분류다. `E0_CORE_ENGINE`은 Studio 전에 반드시 완성할 Foundation subset이다. 둘은 같은 뜻이 아니다.

E1 Provider가 소비하는 Core contract/policy/state-machine은 반드시 E0에 포함한다. E0 Core Engine 전체 완료 전 Studio/MCP 구현은 금지한다.

## 7. 구현 AI 읽기 정책

Planning 기본 표면:

```text
AGENTS.md
→ .github/CODEX-ACTIVE-TASK.md
→ IMPLEMENTATION-MODEL.md
→ SYSTEMS.md
→ implementation-system-model.json
→ scenario-semantic-audit-v3.json
→ scenario-semantic-audit.json
→ scenario-base-catalog.json
→ scenario-expanded-catalog.json
→ 필요한 상위 Authority만 선택적으로
```

`architecture-coverage.json`과 `architecture-scenarios.json`의 legacy Greenfield mapping은 구현 AI 기본 읽기 대상이 아니다.

미모델링 책임이나 미래 충돌을 발견하면 helper로 우회하지 않고 `ESCALATE_TO_PLANNING`한다.

## 8. 변경 Gate

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

## 9. 현재 Gate

```text
SYSTEM_MODEL_V2_REPAIRED
REQUIREMENT_CAPABILITY_V3_ACTIVE
SCENARIO_SEMANTIC_AUDIT_V3_VALIDATED
R3_VALIDATED_NOT_FROZEN
AWAITING_USER_FREEZE_DECISION
SOURCE = BLOCKED
STUDIO = BLOCKED
```

검증이 통과해도 R3는 자동 Freeze하지 않는다. 사용자 결정 후에만 R4로 넘어간다.
