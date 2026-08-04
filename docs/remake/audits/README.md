# Audit 문서

- 상태: ACTIVE
- 문서 종류: Audit Index
- 현재 활성 감사: 없음
- 현재 단계: `IMPLEMENTATION SPECS`
- 현재 Spec 작업 순서: [`CURRENT-SPEC-WORK-ORDER.md`](../specs/CURRENT-SPEC-WORK-ORDER.md)

기획 완성도, 문서 충돌, 사용자 경험, 구현 준비도, 연결과 마이그레이션 결과를 검토한다.

Audit은 제품 동작을 새로 정의하지 않는다. 새 결정이 필요하면 관련 Product·Architecture와 ADR에 먼저 반영한다.

## 현재 작업 기준

- [`현재 상위 작업 순서`](../CURRENT-WORK-ORDER.md)
- [`Implementation Spec 작업 순서`](../specs/CURRENT-SPEC-WORK-ORDER.md)
- [`Implementation Spec Hub`](../specs/README.md)
- [`문서 구조와 작성 가이드`](../DOCUMENT-GUIDE.md)
- [`문서 수명주기와 Discontinuation 정책`](../DOCUMENT-LIFECYCLE-AND-DISCONTINUATION.md)

## 현재 유효한 완료 감사

1. [`Shared Spec 001·002 재검토 감사`](shared-spec-001-002-revalidation-audit.md)
   - 초기 Recipe Step Runtime·Handler Spec을 최신 RuleExecution·Transaction·Outbox·Recovery·Diagnostics·Simulation 계약과 비교했다.
   - 001·002 모두 `UPDATE_REQUIRED`, `SUPERSEDED`는 아님으로 판정했다.
   - First Session Walking Skeleton의 선행 조건에서 제외하고 Character Action·Rules Slice에 배치했다.
2. [`구현 명세 전 최종 문서 연결 감사`](pre-implementation-document-linkage-audit.md)
   - Root → Quick Flow → User Guide → Main Guide → Authority → Spec 경로를 검사했다.
   - User Guide 계층, Template, Shared Spec 진입, Hub 역방향 링크와 수명주기를 정리했다.
   - Implementation Specs를 `READY TO START`로 판정했다.
3. [`User Guide Quick Flow와 Flowchart 보완 감사`](user-guide-quick-flow-and-flowchart-audit.md)
   - 코딩 용어 없는 Quick Flow와 전체·Player·DM·반복·예외 Flowchart 완료 근거
4. [`Player·DM User Guide 완료 감사`](player-and-dm-user-guide-completion-audit.md)
   - 역할·비밀 정보·입력·이동·Recovery·Rollback User Guide 완료 근거
5. [`Main System Guide 일관성과 문서 허브 완료 감사`](main-system-guide-consistency-and-document-hub-completion-audit.md)
   - 12개 Guide의 상태·Template·Authority 계층과 Hub 완료 근거
6. [`Runtime Architecture Completion과 Main System Guide 준비도 감사`](runtime-architecture-completion-and-main-guide-readiness-audit.md)
   - Core·Support Runtime과 Cross-System Integration 완료 근거
7. [`Document Migration Validation`](document-migration-validation.md)
   - 문서 이동과 상대 링크 정합성 근거

## 감사 관계

```text
Runtime Architecture Completion Audit
→ Main System Guide 작성
→ Guide Consistency·Hub Completion Audit
→ Player·DM User Guide 작성
→ User Guide Completion Audit
→ Quick Flow·Flowchart Audit
→ Pre-Implementation Document Linkage Audit
→ Shared Spec 001·002 Revalidation Audit
→ First Session Walking Skeleton Specs
→ First Slice Spec Integration Audit
```

각 Completion Audit은 이전 단계의 권위 판정을 대체하지 않는다. 자신의 단계 결과와 다음 단계 Gate만 추가로 판정한다.

## 현재 Spec 감사 예정

First Session Walking Skeleton의 관련 Spec이 모두 작성되면 다음 감사를 수행한다.

```text
audits/first-session-walking-skeleton-spec-audit.md
```

검사 범위:

- Quick Flow·Player·DM Acceptance Flow 추적성
- Runtime·Protocol·Session·Scene·Movement·Persistence 계약 연결
- Version·Migration·Recovery·Rollback
- Ordering·Transaction·Outbox·Projection Barrier
- Diagnostics·Budget·Health
- Deterministic·Roblox Integration·Negative Disclosure Test
- 문서 검증과 Production Implementation Gate

## 수명주기 정리

초기 `product/core-session-loop.md`는 최신 이동·Audio 범위와 충돌해 `DISCONTINUED`로 전환됐다.

- 활성 안내: [`product/core-session-loop.md`](../product/core-session-loop.md)
- 보관 기록: [`archive/discontinued/product/core-session-loop.md`](../archive/discontinued/product/core-session-loop.md)
- 현재 흐름: [`한눈에 보는 세션 흐름`](../user-guides/QUICK-FLOW.md)

## Superseded·Discontinued Audit

다음 Audit은 후속 Architecture와 Completion Audit이 핵심 판정을 인계했다.

- [`runtime-architecture-integration-and-engine-completeness-audit.md`](runtime-architecture-integration-and-engine-completeness-audit.md)
- [`pre-implementation-planning-readiness-audit.md`](pre-implementation-planning-readiness-audit.md)
- [`planning-audit-resolution-status.md`](planning-audit-resolution-status.md)
- [`cross-system-foundation-contract-gap-audit.md`](cross-system-foundation-contract-gap-audit.md)

보관 이유와 대체 문서는 [`archive/discontinued/audits`](../archive/discontinued/audits/README.md)에서 확인한다.

새 Audit를 시작하기 전에 기존 Audit의 현재 유효성과 대체 관계를 확인한다.