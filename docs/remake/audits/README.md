# Audit 문서

기획 완성도, 문서 충돌, 구현 준비도와 마이그레이션 결과를 검토한다.

Audit은 제품 동작을 새로 정의하지 않는다. 새 결정이 필요하면 관련 기획 문서와 ADR에 반영한다.

## 현재 작업 기준

- [`../CURRENT-WORK-ORDER.md`](../CURRENT-WORK-ORDER.md)
  - 여러 단계의 다음 작업 순서는 이 문서를 먼저 갱신한 뒤 진행한다.
  - 가장 위의 `IN_PROGRESS` 항목을 현재 작업으로 사용한다.

## 현재 유효한 문서

- [`runtime-architecture-integration-and-engine-completeness-audit.md`](runtime-architecture-integration-and-engine-completeness-audit.md)
  - 전체 Runtime의 의존 방향, 권위, Policy, 역할, 수명주기와 Engine 누락을 검토한다.
  - Gameplay Engine은 조건부 완성으로 판정하고 Policy Composition, UI, Diagnostics, Simulation을 구현 전 BLOCKER로 분류한다.
  - Journal 공유 계약과 Encounter↔Game Time 통합 경계를 후속 과제로 기록한다.
- [`document-migration-validation.md`](document-migration-validation.md)
  - 문서 이동 결과, 누락·중복·링크 상태를 검증한다.

## Discontinued Audit

다음 Audit은 작성 당시에는 유효했지만 이후 결정과 Architecture 계약으로 핵심 판정이 해소되어 현재 판단에 사용할 수 없다.

- [`pre-implementation-planning-readiness-audit.md`](pre-implementation-planning-readiness-audit.md)
- [`planning-audit-resolution-status.md`](planning-audit-resolution-status.md)
- [`cross-system-foundation-contract-gap-audit.md`](cross-system-foundation-contract-gap-audit.md)

보관 이유와 대체 문서는 [`archive/discontinued/audits`](../archive/discontinued/audits/README.md)에서 확인한다.

새 Audit를 시작하기 전에 [`문서 수명주기와 Discontinuation 정책`](../DOCUMENT-LIFECYCLE-AND-DISCONTINUATION.md)에 따라 기존 Audit의 현재 유효성을 먼저 검사한다.
