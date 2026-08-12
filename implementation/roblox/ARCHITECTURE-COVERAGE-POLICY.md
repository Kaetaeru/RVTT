# RVTT Architecture Coverage Policy

- 상태: `ACTIVE · SYSTEM_MODEL_V2_REPAIRED`
- 최종 갱신일: 2026-08-13
- System Authority: [`SYSTEMS.md`](SYSTEMS.md)
- Machine-readable Current Model: [`manifests/implementation-system-model.json`](manifests/implementation-system-model.json)
- Legacy Capability/Base Scenario Registry: [`manifests/architecture-coverage.json`](manifests/architecture-coverage.json)
- Expanded Scenario Registry: [`manifests/architecture-scenarios.json`](manifests/architecture-scenarios.json)
- R2 Pressure Evidence: [`audits/IMPLEMENTATION-MODEL-R2-SCENARIO-PRESSURE-001.md`](audits/IMPLEMENTATION-MODEL-R2-SCENARIO-PRESSURE-001.md)
- R3 Repaired Boundary: [`audits/IMPLEMENTATION-MODEL-R3-BOUNDARY-001.md`](audits/IMPLEMENTATION-MODEL-R3-BOUNDARY-001.md)

이 문서는 Product/ADR/Architecture/UI의 중요한 요구가 구현 모델에서 빠지는 것을 막는 Coverage 방법을 소유한다.

## 1. 현재 모델 상태

기존 Greenfield 25 Module / 10 System / 64 Stable Function 모델은 폐기됐다.

현재 구현 책임/요구 추적 모델:

```text
34 System Responsibility Model v2
30 Requirement Capability Catalog v3
61 Representative Scenarios
```

기존 `architecture-coverage.json`의 22 Capability, `coverageState`, `systemRefs`, `moduleRefs`는 R0/R1의 historical requirement evidence로 보존한다. 새 System 경계를 복원하는 권위가 아니다.

## 2. 추적 구조

Canonical trace는 다음과 같다.

```text
Product / Accepted ADR / Current Architecture / UI
↕
Requirement Capability v3
↕ many-to-many
34 System Responsibility Model v2
↕
Representative Scenario
↕
R3 Repository/E0/Runtime/Human boundary
↕
R4 Module / Stable Function / E0 Checkpoint
↕
Source
↕
Test / Runtime Evidence / Human Acceptance
```

Requirement Capability는 System 이름의 별칭이 아니다. Requirement가 여러 System을 압박하고, System 하나가 여러 Requirement를 만족해야 Coverage가 구현 모델을 독립적으로 검사할 수 있다.

61개 Scenario의 현재 Requirement/System trace는 `implementation-system-model.json`이 machine-readable하게 소유한다.

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

상위 Authority가 바뀌면 단순 SHA 교체가 아니라 Requirement Capability/System/Scenario 영향 검토를 다시 한다.

## 4. Requirement Capability Catalog v3

현재 Catalog는 30개이며 `implementation-system-model.json`이 ID, title, sourceRefs, systemRefs를 소유한다.

설계 규칙:

- 각 Requirement Capability는 최소 2개 System을 참조한다.
- 하나의 System을 그대로 이름만 바꾼 Capability를 만들지 않는다.
- Requirement Capability는 Product/Architecture 결과를 설명한다.
- System은 그 결과를 제공하는 책임 구조다.
- 새 System을 만들었다고 자동으로 새 Requirement Capability를 만들지 않는다.
- 새 Product/Architecture 요구가 기존 Capability로 표현되지 않을 때만 Catalog를 확장한다.

대표 예:

```text
REQ_SESSION_PLAYABILITY
→ A1 + A6 + A7 + W7 + C1

REQ_COMMITTED_EVENT_PROPAGATION
→ A3 + A8 + A5 + A7 + S1

REQ_SELECTION_TARGETING
→ C1 + W3 + W4 + W5 + R2
```

## 5. Representative Scenario

Base 14 + Expanded 47 = 총 61개 Scenario를 하나의 Catalog로 취급한다.

Scenario의 목적:

- System 사이 연결 누락 발견
- 미래 기능이 현재 shared boundary를 압박하는 방식 발견
- concurrency/disclosure/recovery/failure negative path 발견
- 사용자/DM/운영 결과 End-to-End 검증

새 모델에서 각 Scenario는 다음을 반드시 가진다.

```text
Scenario ID
Requirement Capability refs[]
System refs[]
```

Validator는 legacy/base+expanded Scenario ID set과 새 trace ID set이 정확히 같은지 검사한다.

Scenario 추가는 Architecture 변경 승인 자체가 아니다.

## 6. Cross-cutting Matrix

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

## 7. R3 Self Review에서 추가된 Coverage 불변식

### Event Delivery

```text
A3 transaction + outbox
→ A8 committed event delivery
→ subscribers
```

Outbox append와 subscriber delivery/retry/receipt를 한 실패 도메인으로 합치지 않는다.

### Ready Gate

```text
A7 authorityRecoveryReady
A6 projectionSyncReady
W7 sceneEssentialReady
C1 clientReplicaReady
→ A1 final EffectiveGameplayReady
```

A1만 final gameplay Command gate를 연다.

### Reservation

```text
OrderingReservation              A3
ResourceReservation              R3
OccupancyReservation             W6
ActivityReservation              D5
LogisticsAllocationReservation   D7
```

범용 ReservationManager로 합치지 않는다.

### Shared Provider

```text
AuthorityMonotonicClock
DeterministicIdFactory
RngProvider
TransportAdapter
StorageAdapter
```

각 System의 임의 직접 선택을 금지하고 S2 deterministic adapter와 production interface 동일성을 보존한다.

## 8. REPOSITORY_LOGIC와 E0_CORE_ENGINE

```text
REPOSITORY_LOGIC
= Roblox 없이 구현 가능한 모든 production logic의 분류

E0_CORE_ENGINE
= Studio 전에 반드시 완성해야 하는 Foundation subset
```

`CORE_ENGINE_COMPLETE`는 모든 미래 Repository feature 구현 완료가 아니다.

반대로 E1 Provider가 소비하는 Core contract/policy/state-machine은 반드시 E0 pre-Studio seam에 포함되어야 한다.

현재 E0 seam set은 `implementation-system-model.json`의 `e0RequiredSystemSeams`가 소유한다.

## 9. 기존 GAP-001~012의 의미

GAP-001~012는 폐기된 Greenfield 모델에서 발견한 요구사항 누락 증거다.

새 모델을 기존 Gap 목록에 맞춰 패치하지 않는다.

- 새 System/Capability가 책임을 자연스럽게 포함하면 기존 Gap은 historical evidence가 된다.
- 새 모델 관점에서 구조 문제가 발견되면 새 Finding을 만든다.
- Gap 번호 보존을 위해 잘못된 System split을 만들지 않는다.

## 10. 현재 Implementation Gate

현재:

```text
SYSTEM_MODEL_V2_REPAIRED
REQUIREMENT_CAPABILITY_V3_ACTIVE
R3_NOT_FROZEN
SOURCE = BLOCKED
STUDIO = BLOCKED
```

Gate 해제 순서:

```text
Repaired Model 전체 검증
→ 사용자 R3 Freeze 결정
→ R4 E0 Checkpoint Freeze
→ Dedicated Implementation Branch
→ E0 Core Engine
```

**E0 Core Engine 전체 완료 전 Studio/MCP 구현은 금지한다.**

## 11. 구현 AI 읽기 정책

Planning 단계 기본 표면은 짧게 유지한다.

```text
AGENTS.md
→ .github/CODEX-ACTIVE-TASK.md
→ IMPLEMENTATION-MODEL.md
→ SYSTEMS.md
→ implementation-system-model.json
→ 필요한 Scenario/Evidence만 선택적으로
```

구현 Branch가 생긴 뒤에는 Planning Tree 전체를 기본 검색하지 않고 압축된 Implementation Pack만 사용한다.

미모델링 책임이나 미래 충돌을 발견하면 helper로 우회하지 않고 `ESCALATE_TO_PLANNING`한다.

## 12. 변경 Gate

다음은 사용자 결정 없이 자동 적용하지 않는다.

- 새로운 핵심 System boundary
- state owner 변경
- Server/Client Authority 변경
- 입력 문법 변경
- 실행 순서 변경
- Module 실질 분리/통합
- Product/ADR 변경

Coverage Finding은 Architecture 변경 승인과 동일하지 않다.

## 13. 현재 다음 작업

**34 System / 30 Requirement Capability / 61 Scenario trace와 R3 invariant 전체를 한 번 검증한다.**

통과해도 R3를 자동 Freeze하지 않는다. 사용자 결정 후에만 R4로 넘어간다.
