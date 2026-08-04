# Audit 문서

기획 완성도, 문서 충돌, 구현 준비도와 마이그레이션 결과를 검토한다.

Audit은 제품 동작을 새로 정의하지 않는다. 새 결정이 필요하면 관련 기획 문서와 ADR에 반영한다.

## 현재 유효한 문서

- [`document-migration-validation.md`](document-migration-validation.md)
  - 문서 이동 결과, 누락·중복·링크 상태를 검증한다.

## Discontinued Audit

다음 Audit은 작성 당시에는 유효했지만 이후 결정과 Architecture 계약으로 핵심 판정이 해소되어 현재 판단에 사용할 수 없다.

- [`pre-implementation-planning-readiness-audit.md`](pre-implementation-planning-readiness-audit.md)
- [`planning-audit-resolution-status.md`](planning-audit-resolution-status.md)
- [`cross-system-foundation-contract-gap-audit.md`](cross-system-foundation-contract-gap-audit.md)

보관 이유와 대체 문서는 [`archive/discontinued/audits`](../archive/discontinued/audits/README.md)에서 확인한다.

새 Audit를 시작하기 전에 [`문서 수명주기와 Discontinuation 정책`](../DOCUMENT-LIFECYCLE-AND-DISCONTINUATION.md)에 따라 기존 Audit의 현재 유효성을 먼저 검사한다.
