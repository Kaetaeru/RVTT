# 구현 명세

- 상태: ACTIVE
- 문서 종류: Implementation Spec Index
- 현재 단계: `IN_PROGRESS`
- 선행 단계: Main System Guides `COMPLETE`

확정된 기획을 실제 Module, Type, Command, Network, Persistence, Error, Test와 Performance 계약으로 변환한다.

## 현재 작업 기준

- 단일 작업 순서: [`../CURRENT-WORK-ORDER.md`](../CURRENT-WORK-ORDER.md)
- Main System Guide 허브: [`../guides/README.md`](../guides/README.md)
- Guide 완료 감사: [`../audits/main-system-guide-consistency-and-document-hub-completion-audit.md`](../audits/main-system-guide-consistency-and-document-hub-completion-audit.md)

Implementation Specs 단계가 현재 활성 단계다. 세부 Spec 작업 순서와 수직 Slice는 다음 작업에서 별도로 확정한다.

## Spec 작성 전 읽기 순서

```text
CURRENT-WORK-ORDER
→ Runtime Foundation Guide
→ 현재 Domain Main System Guide
→ 직접 인접 Guide
→ Guide가 연결한 Product·Architecture·System·ADR
→ 기존 관련 Spec
→ 새 Implementation Spec
```

Guide는 탐색 문서이며 구현 계약의 권위 원본이 아니다. Spec은 Guide가 연결한 Product·Architecture·System·ADR을 근거로 작성한다.

## 작성 조건

기획 문서의 `즉시 구현 명세 가능성`이 `READY` 또는 Completion Audit이 허용한 `READY_WITH_DEFAULTS`일 때만 작성한다.

Spec은 최소한 다음을 명확히 한다.

- Package·Module·Service 책임
- Luau Type와 Versioned Schema
- Registry Definition과 Compiler Interface
- Command·Read Request·Result·Error Code
- Network Envelope와 Projection Segment
- Persistence Chunk·Journal·Migration
- Ordering Key·Reservation·Transaction Node
- Trace Span·Budget·Health Probe
- Deterministic Fixture·Scenario·Acceptance Test
- Roblox Integration Boundary와 Failure Isolation

권위 문서에 없는 제품 동작, Architecture 결정과 임의 기본값을 Spec에서 새로 만들지 않는다. 새 결정이 필요하면 관련 Architecture와 ADR을 먼저 수정한다.

## 파일 규칙

영역별 명세는 하위 폴더에 3자리 번호와 의미 있는 이름으로 작성한다.

예:

```text
combat/001-encounter-bootstrap.md
scene/001-scene-source-registry.md
networking/001-command-envelope.md
```

하나의 Spec은 가능한 한 구현·검증 가능한 수직 책임 단위를 다룬다. 여러 Domain을 함께 변경해야 하면 Transaction·Projection·Recovery 경계를 명시한다.

## 현재 명세

### Shared

- [`001. Recipe Step Runtime Foundation`](shared/001-recipe-step-runtime-foundation.md)
  - StepDefinition
  - StepRegistry
  - RecipeCompiler
  - BindingStore
  - StepExecutor
  - Guided·Assisted 대기와 복구

- [`002. Standard Recipe Step Handler Contracts`](shared/002-standard-step-handler-contracts.md)
  - StepHandler와 StepHandlerRegistry
  - 제한된 HandlerServices
  - Config·입력·출력 검증
  - Guided·Assisted Execute·Resume 계약
  - PendingEffect·Branch·Presentation 반환 경계
  - 오류 격리, 멱등성, 진단과 테스트

이 두 Spec은 Main System Guide 완료 전에 작성된 초기 Shared Spec이다. 현재 Architecture와 Guide에 다시 대조한 뒤 후속 세부 작업 순서에 포함한다.

## Spec 완료 조건

- 관련 Authority Documents와 충돌하지 않음
- 책임·입출력·권한·실패·복구 경계가 명확함
- Client 입력과 Server Authority 검증을 구분함
- Source·Build·State·Projection·Presentation을 혼합하지 않음
- Version·Migration·Deprecation 경계가 있음
- Persistence와 Rollback 영향을 설명함
- Diagnostics Span·Budget·Error를 정의함
- Deterministic Scenario와 Roblox Integration Test를 정의함
- 관련 Guide의 변경 영향 지도를 확인함
- 문서 검증 Workflow가 성공함

## 현재 비목표

- 승인된 Spec 없이 Production Code 작성
- 실제 구현보다 먼저 최종 Module 경로를 임의 확정
- 측정 없이 Budget·Timeout·Cache 값을 확정
- Test-only Mutation이나 Authorization 우회 계약 작성
- Guide를 권위 문서로 승격

다음 세부 작업은 Implementation Specs 작업 순서와 첫 수직 Slice를 확정하는 것이다.
