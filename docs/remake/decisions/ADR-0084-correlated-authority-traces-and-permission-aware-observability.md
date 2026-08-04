# ADR-0084: Correlated Authority Trace와 Permission-aware Observability

- 상태: 확정
- 결정일: 2026-08-04
- 관련 문서:
  - [`Diagnostics, Observability, Correlated Trace와 Incident Runtime 계약`](../architecture/diagnostics-observability-correlated-trace-and-incident-runtime-contract.md)
  - [`Networking Command, Event와 Client Synchronization 계약`](../architecture/networking-command-event-and-client-synchronization-contract.md)
  - [`Command Ordering, Logical Time와 Transaction Coordinator 계약`](../architecture/command-ordering-logical-time-and-transaction-coordinator-contract.md)
  - [`Domain Event Runtime 계약`](../architecture/domain-event-outbox-subscription-and-projection-runtime-contract.md)
  - [`UI Runtime 계약`](../architecture/ui-projection-view-model-input-context-and-recovery-runtime-contract.md)

## 배경

RVTT의 한 사용자 입력은 Network, Command, RuleExecution, Transaction, Domain Event, Projection과 UI를 차례로 통과한다.

각 Runtime이 자신의 문자열 로그만 남기면 다음 문제가 발생한다.

- 같은 오류의 단계별 기록을 연결할 수 없음
- 어떤 Policy Snapshot과 Modifier가 사용됐는지 알 수 없음
- Transaction Commit과 Projection·UI 적용 사이의 단절을 찾기 어려움
- Rollback 이전 Epoch의 비동기 작업이 다시 실행됐는지 판단하기 어려움
- Player Diagnostic에 숨은 정보가 포함될 위험
- 진단 기록량이 Gameplay 성능을 침해하거나 진단 실패가 Commit을 방해할 위험
- 복구용 Journal, 관리 Audit와 일반 Trace가 혼합됨

## 결정

### 1. Server가 발급한 Trace Context를 전체 권위 흐름에 전파한다

```text
Input Intent
→ Command
→ RuleExecution
→ Transaction
→ Domain Event
→ Projection
→ UI·Presentation
```

각 단계는 공통 `traceId`, `spanId`, `parentSpanId`, `causationRefs`와 `authorityEpoch`를 사용한다.

Client가 Server Trace Identity를 임의로 확정하지 못한다. Client Interaction ID는 연결 힌트로만 사용한다.

### 2. Trace는 Tree가 아니라 인과 Graph를 지원한다

Domain Event Fan-out, Subscriber, Retry와 Transaction Join을 표현하기 위해 단일 Parent 관계 외에 타입 있는 Causation Link를 허용한다.

### 3. 구조화되고 Versioned된 Record Registry를 사용한다

문자열 로그만으로 계약을 만들지 않는다.

- Span Type
- Observation Type
- Stable Error Code
- Budget Profile
- Redaction Rule
- Incident Rule
- Diagnostic Query Type

을 신뢰된 Registry에 등록한다.

### 4. Recovery Journal, Mandatory Audit와 Observability를 분리한다

- Recovery Journal은 서버 복구와 Rollback을 위한 권위 기록이다.
- Mandatory Audit는 DM Override와 권한 변경처럼 Commit과 함께 반드시 남아야 하는 기록이다.
- Observability Trace는 원인과 성능을 설명하는 비권위 자료다.

일반 Trace 저장 실패는 이미 검증된 Gameplay Transaction을 되돌리지 않는다.

### 5. Raw Trace를 사용자에게 직접 제공하지 않는다

Diagnostic Query는 역할, Campaign Scope, Ownership, Knowledge, Disclosure와 Security Redaction을 적용한 별도 Diagnostic Projection을 반환한다.

Player는 자신의 공개 가능한 Command 상태와 Support Reference만 보고, DM은 Campaign Gameplay Trace를 보며, Developer·Operator는 권한이 부여된 기술 Trace만 본다.

### 6. 모든 권위 실행은 최소 Terminal Marker를 남긴다

상세 Span은 Sampling할 수 있지만 Command, RuleExecution과 Transaction의 최종 처리 상태와 핵심 Authority Reference는 유지한다.

Rollback, 보안·Disclosure 위반 후보, Transaction Abort, Projection Gap, Dead Letter와 Hard Budget 초과는 일반 Sampling으로 제거하지 않는다.

### 7. Diagnostics 자체 Budget과 Drop 우선순위를 둔다

진단 수집은 CPU, Allocation, Byte, Record와 Queue Budget을 가진다.

Budget 초과 시 Cosmetic Detail과 Routine Success Detail부터 축약한다. Mandatory Audit Reference, Critical Incident와 Authority Terminal Marker를 우선 보존한다.

### 8. 권위 시간과 성능 시간을 분리한다

Latency와 Timeout 측정은 Authority Monotonic Time을 사용한다. Campaign Game Time을 성능 시간으로 사용하지 않는다.

### 9. Rollback과 Recovery에서 Epoch를 보존한다

이전 AuthorityEpoch의 Trace는 역사 기록으로 남을 수 있지만 현재 Branch Trace로 재분류하거나 새 Incident 상태를 변경하지 않는다.

### 10. Incident Bundle은 Sanitized Data Package다

Incident Bundle은 Trace Graph, Policy·Build Hash, Command·Transaction Summary, Projection Integrity와 Budget 자료를 포함할 수 있다.

Recovery Snapshot 전체, 인증 정보, 비밀 Journal 원문과 실행 가능한 임의 코드를 자동 포함하지 않는다.

## 선택하지 않은 대안

### Runtime마다 독립 로그를 유지

인과 연결, 공통 오류 코드, Budget과 정보 공개 정책이 분산되므로 선택하지 않았다.

### 모든 Trace를 영구 저장

장기 세션의 저장량과 검색 비용이 과도하고 비밀 정보 보존 위험이 커지므로 선택하지 않았다.

### Trace를 Recovery Journal로 사용

Sampling과 Drop이 가능한 관측 자료는 권위 복구 원본으로 적합하지 않으므로 선택하지 않았다.

### Raw Trace를 DM과 Player에게 그대로 제공

비밀 정보, 내부 Module Path와 Security Detail이 유출될 수 있으므로 선택하지 않았다.

### Diagnostics 실패 시 Gameplay Transaction 실패

관측 기반의 일시적 장애가 정상 Gameplay를 차단할 수 있으므로 선택하지 않았다. Mandatory Audit가 필요한 관리 Transaction은 별도 Audit 계약을 따른다.

### Client Report를 권위 사실로 신뢰

조작, 오래된 Connection Epoch와 로컬 오류로 인해 신뢰할 수 없으므로 선택하지 않았다.

## 결과

### 장점

- 입력부터 UI까지 하나의 Trace로 원인을 추적할 수 있다.
- Policy·Rule·Authorization 결과를 설명할 수 있다.
- Rollback·Reconnect·Subscriber Retry 문제를 Epoch와 Causation으로 구분할 수 있다.
- 권한별 진단 정보 공개를 일관되게 적용한다.
- 진단 오버헤드를 Budget과 Sampling으로 제한한다.
- Simulation Harness와 Incident 재현에 구조화된 자료를 제공한다.

### 비용

- 모든 주요 Runtime이 Trace Context와 Registry Adapter를 구현해야 한다.
- Redaction Metadata와 Stable Error Code 관리가 필요하다.
- Sampling, Retention, Incident Bundle과 Query 권한을 별도로 구현해야 한다.
- Client와 Server Trace 연결을 위한 Schema와 Version 관리가 필요하다.

이 비용은 플레이테스트 후 원인을 찾을 수 없는 시스템을 유지하는 비용보다 작다.
