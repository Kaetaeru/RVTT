# RVTT Architecture Coverage Policy

- 상태: `ACTIVE · IMPLEMENTATION_MODEL_NEUTRAL`
- 최종 갱신일: 2026-08-13
- Capability/Base Scenario Registry: [`manifests/architecture-coverage.json`](manifests/architecture-coverage.json)
- Expanded Scenario Registry: [`manifests/architecture-scenarios.json`](manifests/architecture-scenarios.json)
- Current implementation model authority: [`IMPLEMENTATION-MODEL.md`](IMPLEMENTATION-MODEL.md)

이 문서는 **Product/ADR/Architecture/UI의 중요한 요구가 구현 모델에서 빠지는 것을 막는 Coverage 방법**을 소유한다.

## 1. 현재 리셋 상태

기존 Greenfield 25 Module / 10 System / 64 Stable Function 모델은 폐기됐다.

따라서 `architecture-coverage.json`의 기존 `systemRefs`와 `moduleRefs`는 **이전 Greenfield Audit 당시의 역사적 매핑**이다.

현재 리셋 중에는:

- Capability의 존재와 의미
- Authority Evidence
- Flow
- Cross-cutting Matrix
- Known Gap Evidence
- 61 Representative Scenario

만 요구사항/압력 권위로 사용한다.

옛 `systemRefs/moduleRefs`를 새 System Model에 자동 승계하지 않는다.

## 2. 추적 구조

리셋 중:

```text
Product / Accepted ADR / Current Architecture / UI
↕
Capability
↕
Representative Scenario
↕
Cross-cutting Constraints
↕
NEW System Model
```

새 System Model이 승인된 뒤:

```text
Requirement
↕
Capability / Scenario
↕
System
↕
Module
↕
Stable Function
↕
Source
↕
Test / Runtime Evidence / Human Acceptance
```

로 다시 양방향 추적을 연결한다.

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

현재 Registry의 Tree SHA Snapshot은 마지막 전체 Audit의 기준점을 나타낸다.

상위 Authority가 바뀌면 단순 SHA 교체가 아니라 Capability/Scenario 영향 검토를 다시 한다.

Historical/Archive/Legacy Source는 요구사항 Authority가 아니다.

## 4. Capability Catalog

Capability는 Module 이름이 아니라 제품/Architecture가 제공해야 하는 능력이다.

현재 Registry의 22 Capability를 리셋 입력으로 유지한다.

각 Capability의 핵심 필드:

```text
id
title
plannedPhase
authorityRefs
flow
crossCutting
knownGapRefs
```

현재 `coverageState`, `systemRefs`, `moduleRefs`는 이전 구현 모델에 대한 감사 결과일 수 있으므로 **새 모델 설계 결과로 재평가하기 전 구현 권위로 사용하지 않는다.**

## 5. Representative Scenario

Base + Expanded Registry를 하나의 Catalog로 취급한다.

현재 총 61개 Scenario는 다음 목적을 가진다.

- System 사이 연결 누락 발견
- 미래 기능이 현재 shared boundary를 압박하는 방식 발견
- concurrency/disclosure/recovery/failure negative path 발견
- 사용자/DM/운영 결과를 End-to-End로 검증

Scenario 추가는 Architecture 변경 승인 자체가 아니다.

새 System Model은 61개 Scenario를 다시 통과해야 한다.

## 6. Cross-cutting Matrix

각 Capability는 다음을 검토한다.

```text
AUTHORITY
PERMISSION
STATE_OWNERSHIP
COMMAND
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

## 7. Known Gap의 의미

현재 GAP-001~012는 이전 Greenfield 모델에서 발견된 **요구사항 누락 증거**다.

새 모델을 기존 Gap 목록에 맞춰 패치하지 않는다.

새 System Model을 처음부터 만들 때 해당 Evidence를 반드시 고려하되:

- 새 모델이 자연스럽게 책임을 포함하면 기존 Gap은 해소 후보가 된다.
- 새 모델 관점에서 다른 구조적 문제가 발견되면 새 Finding을 만들 수 있다.
- Gap 번호를 보존하기 위해 잘못된 System split을 만들지 않는다.

## 8. 현재 Implementation Gate

현재 상태:

```text
IMPLEMENTATION_MODEL_RESET
SOURCE = BLOCKED
STUDIO = BLOCKED
```

Source Gate 해제 조건은 기존 Greenfield Module mapping 복구가 아니다.

```text
R0 Requirement Distillation 완료
+ R1 New System Model 사용자 승인
+ R2 61 Scenario Pressure Review 통과
+ R3 Core/Runtime/Presentation Boundary 승인
+ R4 E0 Checkpoint Freeze
→ Dedicated Implementation Branch 생성 가능
```

## 9. 구현 AI가 읽는 방식

구현 AI는 전체 Planning 문서를 매번 읽지 않는다.

Planning 단계에서 전체 Authority/Scenario를 스캔한 뒤, E0 Checkpoint가 Freeze되면 관련 Current Scenario + Future Pressure만 구현 Branch의 압축된 Pack에 내린다.

구현 중 미모델링 책임이나 미래 충돌을 발견하면 helper로 우회하지 않고 `ESCALATE_TO_PLANNING`한다.

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

`GAP-002`를 기존 Module에 끼워 넣지 않는다.

다음은 **22 Capability + 61 Scenario를 책임/상태/권위 기준으로 다시 클러스터링해 Whole-product System Model Draft를 만드는 것**이다.
