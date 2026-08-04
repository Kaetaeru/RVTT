# 구현 명세

- 상태: ACTIVE
- 문서 종류: Implementation Spec Index
- 현재 단계: `IN_PROGRESS`
- 선행 단계:
  - Main System Guides `COMPLETE`
  - Player·DM User Guides와 Quick Flow `COMPLETE`

확정된 기획과 목표 사용자 경험을 실제 Module, Type, Command, Network, Persistence, Error, Test와 Performance 계약으로 변환한다.

## 현재 작업 기준

- 단일 작업 순서: [`../CURRENT-WORK-ORDER.md`](../CURRENT-WORK-ORDER.md)
- 한눈에 보는 세션 흐름: [`../user-guides/QUICK-FLOW.md`](../user-guides/QUICK-FLOW.md)
- Player·DM User Guide: [`../user-guides/README.md`](../user-guides/README.md)
- Quick Flow 완료 감사: [`../audits/user-guide-quick-flow-and-flowchart-audit.md`](../audits/user-guide-quick-flow-and-flowchart-audit.md)
- Main System Guide 허브: [`../guides/README.md`](../guides/README.md)
- Guide 완료 감사: [`../audits/main-system-guide-consistency-and-document-hub-completion-audit.md`](../audits/main-system-guide-consistency-and-document-hub-completion-audit.md)

Implementation Specs 단계가 현재 활성 단계다. 다음 작업에서 세부 Spec Work Order를 만들고 기존 Shared Spec 001·002를 최신 Runtime 계약과 대조한 뒤 첫 수직 Slice를 확정한다.

## Spec 작성 전 읽기 순서

```text
CURRENT-WORK-ORDER
→ 한눈에 보는 세션 흐름
→ 관련 Player 또는 DM 상세 Guide
→ Runtime Foundation Guide
→ 현재 Domain Main System Guide
→ 직접 인접 Guide
→ Guide가 연결한 Product·Architecture·System·UI·ADR
→ 기존 관련 Spec
→ 새 Implementation Spec
```

Quick Flow, User Guide와 Main System Guide는 탐색·목표 경험 문서이며 구현 계약의 권위 원본이 아니다. Spec은 이 문서들이 연결한 Product·Architecture·System·UI·ADR을 근거로 작성한다.

## User Guide 전달 기준

모든 수직 Slice는 Quick Flow의 한 구간을 사용자 Acceptance Scenario로 연결한다.

### 첫 Player 흐름

```text
세션 참가
→ 캐릭터 선택과 준비 완료
→ 장면 입장
→ 탐험 이동
→ 연결이 끊기면 다시 참가
→ 현재 진행 상황으로 복귀
```

### 첫 DM 흐름

```text
캠페인과 시작 장면 준비
→ 플레이어 준비 상태 확인
→ 세션 시작
→ 탐험 진행
→ 필요한 대상과 정보 조정
→ 현재 상태 확인과 저장
```

Spec에서는 위 사용자 흐름을 내부 계약으로 구체화하되, Acceptance Test 이름과 완료 조건에서는 사용자가 보게 되는 결과를 유지한다.

사용자가 보는 Label·Prompt·오류 안내와 시스템 내부 Error Code를 분리해 정의한다.

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
- Player·DM 화면의 성공·대기·거부·복구 상태
- Roblox Integration Boundary와 Failure Isolation

권위 문서에 없는 제품 동작, Architecture 결정과 임의 기본값을 Spec에서 새로 만들지 않는다. 새 결정이 필요하면 관련 Product·Architecture와 ADR을 먼저 수정하고 User Guide 영향을 확인한다.

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

이 두 Spec은 Main System Guide와 Player·DM User Guide 완료 전에 작성된 초기 Shared Spec이다. 현재 Architecture, Guide와 사용자 Prompt·Recovery 경험에 다시 대조한 뒤 후속 세부 작업 순서에 포함한다.

## Spec 완료 조건

- 관련 Authority Documents와 충돌하지 않음
- Quick Flow와 Player·DM User Guide의 목표 흐름을 Acceptance Scenario로 연결함
- 책임·입출력·권한·실패·복구 경계가 명확함
- Client 입력과 Server Authority 검증을 구분함
- Source·Build·State·Projection·Presentation을 혼합하지 않음
- Version·Migration·Deprecation 경계가 있음
- Persistence와 Rollback 영향을 설명함
- Diagnostics Span·Budget·Error를 정의함
- 사용자에게 보이는 대기·거부·재시도·Resync 안내를 정의함
- Deterministic Scenario와 Roblox Integration Test를 정의함
- 관련 Guide와 User Guide의 변경 영향 지도를 확인함
- 문서 검증 Workflow가 성공함

## 현재 비목표

- 승인된 Spec 없이 Production Code 작성
- 실제 구현보다 먼저 최종 Module 경로를 임의 확정
- 측정 없이 Budget·Timeout·Cache 값을 확정
- Test-only Mutation이나 Authorization 우회 계약 작성
- Guide와 User Guide를 권위 문서로 승격
- Quick Flow와 User Guide에 없는 새 사용자 동작을 Spec에서 몰래 추가

다음 세부 작업은 Implementation Specs 작업 순서와 첫 수직 Slice를 확정하는 것이다.
