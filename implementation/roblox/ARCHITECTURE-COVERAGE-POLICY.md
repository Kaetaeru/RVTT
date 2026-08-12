# RVTT Architecture Coverage Policy

- 상태: `ACTIVE · SYSTEM_MODEL_V2_REPAIRED · SEMANTIC_AUDIT_V2_VALIDATED`
- System Authority: `SYSTEMS.md`
- Canonical Base Scenario source: `manifests/scenario-base-catalog.json`
- Expanded Scenario source: `manifests/architecture-scenarios.json`의 `scenarios[]`
- Direct model: `manifests/implementation-system-model.json`
- Effective Scenario audit: `manifests/scenario-semantic-audit.json`
- Historical legacy coverage: `manifests/architecture-coverage.json`

이 문서는 Product/ADR/Architecture/UI 요구가 구현 모델에서 빠지는 것을 막는 Coverage 방법을 소유한다. 폐기된 Greenfield 25 Module / 10 System / 64 Stable Function 모델은 새 구현 권위가 아니다.

## 1. 현재 추적 구조

```text
Product / Accepted ADR / Current Architecture / UI
↕
30 Requirement Capability Catalog v3
↕ many-to-many
34 System Responsibility Model v2
↕
61 Canonical Scenario bodies
  - Base 14: scenario-base-catalog.json
  - Expanded 47: architecture-scenarios.json scenarios[]
↕
Scenario Semantic Audit v1 direct-stage base
↕
Scenario Semantic Audit v2 effective body/ingress/recovery audit
↕
R3 execution boundary
↕
R4 Module / Stable Function / E0 Checkpoint
↕
Source / Test / Runtime Evidence / Human Acceptance
```

Requirement Capability는 System 이름의 별칭이 아니다. 하나의 Requirement가 여러 System을 압박하고 하나의 System도 여러 Requirement를 만족해야 한다.

## 2. 권위 역할

- `scenario-base-catalog.json`: Base 14 Scenario의 canonical body. legacy Greenfield capability/system/module mapping을 포함하지 않는다.
- `architecture-scenarios.json`: Expanded 47 Scenario의 `scenarios[]` body source. top-level legacy metadata와 `capabilityRefs`는 새 Requirement/System mapping 권위가 아니다.
- `implementation-system-model.json`: 34 System, 30 Requirement Capability, 61 direct Scenario Requirement/System trace, v1 semanticStages.
- `scenario-semantic-audit.json`: Scenario source blob binding, mutation semantic, typed ingress/recovery expansion, LKG owner set, 61 classification, full semantic schema digest.
- `architecture-coverage.json`: authority corpus snapshot과 과거 Greenfield coverage/gap evidence 보존용. 안에 남은 Base Scenario 사본 및 system/module refs는 historical evidence일 뿐 canonical Scenario source가 아니다.

완전한 R3 Scenario semantic audit는 **v2**다. v1은 direct-stage base layer이며 단독 완전 권위가 아니다.

## 3. Scenario Semantic Audit v2

다음을 하나의 감사 단위로 묶는다.

```text
Canonical Base Scenario registry blob SHA
+ Expanded Scenario registry blob SHA
+ v1 direct trace digest
+ mutationSemantic
+ entryKindDefinitions
+ entryBoundaryExpansion
+ recoveryKindDefinitions
+ recoveryBoundaryExpansion
+ lastKnownGoodOwnerCandidates
+ 61 scenarioAudit classifications
→ semanticSchemaDigest
→ combinedAuditDigest
```

현재 digest:

```text
semanticSchemaDigest
sha256:dcc766c1161332789e91aadc362c4765687af3efc2f7193cf23f748df0eb6489

combinedAuditDigest
sha256:48477cd70757d4450980162d49c62e12115229762bee4127542d6a167099a723
```

Scenario body뿐 아니라 공통 의미/확장 규칙이 바뀌어도 semantic re-audit 없이 통과하지 못한다.

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
→ scenario-semantic-audit.json
→ scenario-base-catalog.json
→ 필요한 Expanded Scenario의 architecture-scenarios.json scenarios[]
→ 필요한 상위 Authority만 선택적으로
```

`architecture-coverage.json`의 legacy Greenfield system/module/capabilityRefs와 Base Scenario 사본은 구현 AI 기본 읽기 대상이 아니다.

미모델링 책임이나 미래 충돌을 발견하면 helper로 우회하지 않고 `ESCALATE_TO_PLANNING`한다.

## 8. 변경 Gate

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
SCENARIO_SEMANTIC_AUDIT_V2_VALIDATED
R3_NOT_FROZEN
AWAITING_USER_FREEZE_DECISION
SOURCE = BLOCKED
STUDIO = BLOCKED
```

검증이 통과해도 R3는 자동 Freeze하지 않는다. 사용자 결정 후에만 R4로 넘어간다.
