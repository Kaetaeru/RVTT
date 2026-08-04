# Audit 문서

기획 완성도, 문서 충돌, 구현 준비도와 마이그레이션 결과를 검토한다.

Audit은 제품 동작을 새로 정의하지 않는다. 새 결정이 필요하면 관련 Architecture와 ADR에 먼저 반영한다.

## 현재 작업 기준

- [`../CURRENT-WORK-ORDER.md`](../CURRENT-WORK-ORDER.md)
  - 여러 단계의 다음 작업 순서는 이 문서를 먼저 갱신한 뒤 진행한다.
  - 가장 위의 `IN_PROGRESS` 항목을 현재 작업으로 사용한다.

## 현재 유효한 문서

- [`runtime-architecture-completion-and-main-guide-readiness-audit.md`](runtime-architecture-completion-and-main-guide-readiness-audit.md)
  - 이전 감사의 Policy, UI, Diagnostics, Simulation, Journal과 Integration BLOCKER 해소를 재검증한다.
  - 현재 제품 범위의 Core·Support Runtime과 Cross-System Integration을 완료로 판정한다.
  - Main System Guide 단계는 `READY`, Production Implementation은 Guide·Spec 전이므로 아직 미시작으로 판정한다.
- [`document-migration-validation.md`](document-migration-validation.md)
  - 문서 이동 결과, 누락·중복·링크 상태를 검증한다.

## Superseded·Discontinued Audit

다음 Audit은 작성 당시에는 유효했지만 후속 Architecture와 Completion Audit이 핵심 판정을 인계했다.

- [`runtime-architecture-integration-and-engine-completeness-audit.md`](runtime-architecture-integration-and-engine-completeness-audit.md)
  - ADR-0081~0087과 후속 계약이 당시 BLOCKER를 해소했다.
  - 현재 판단에는 최신 Completion Audit을 사용한다.
- [`pre-implementation-planning-readiness-audit.md`](pre-implementation-planning-readiness-audit.md)
- [`planning-audit-resolution-status.md`](planning-audit-resolution-status.md)
- [`cross-system-foundation-contract-gap-audit.md`](cross-system-foundation-contract-gap-audit.md)

보관 이유와 대체 문서는 [`archive/discontinued/audits`](../archive/discontinued/audits/README.md)에서 확인한다.

새 Audit를 시작하기 전에 [`문서 수명주기와 Discontinuation 정책`](../DOCUMENT-LIFECYCLE-AND-DISCONTINUATION.md)에 따라 기존 Audit의 현재 유효성을 먼저 검사한다.
