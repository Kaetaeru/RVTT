# 문서 템플릿

- 상태: ACTIVE
- 문서 종류: Template Index

새 문서는 [`DOCUMENT-GUIDE.md`](../DOCUMENT-GUIDE.md), [`AGENTS.md`](../AGENTS.md)와 현재 [`CURRENT-WORK-ORDER.md`](../CURRENT-WORK-ORDER.md)를 따른다.

템플릿은 내용을 기계적으로 채우기 위한 것이 아니라 필수 결정, 연결과 검증 항목의 누락을 막기 위한 것이다.

## 현재 템플릿

- [`Main System Guide Template`](main-system-guide-template.md)
  - Parent·Children·References
  - Authority Documents
  - 구현·검증 순서와 변경 영향
- [`Implementation Spec Template`](implementation-spec-template.md)
  - Quick Flow·Player·DM Acceptance Flow
  - 직접 Authority 추적성
  - Module·Type·Command·Persistence·Migration
  - Transaction·Projection·Diagnostics·Budget
  - Deterministic Scenario와 Roblox Integration Test

## 사용 순서

### Main System Guide

```text
Guide 작성 조건 통과
→ Main System Guide Template
→ Authority 관계와 경계 작성
→ Completion Audit
```

### Implementation Spec

```text
CURRENT-WORK-ORDER
→ Quick Flow와 관련 User Guide
→ Runtime·Domain Main System Guide
→ 직접 Authority Documents
→ Implementation Spec Template
→ Spec 준비 완료 Gate
```

## 아직 제공하지 않는 템플릿

다음 문서는 필요 시 별도 Template을 추가한다.

- Product·Architecture·System Planning
- ADR
- Audit

존재하지 않는 템플릿 이름을 현재 사용 가능한 파일처럼 안내하지 않는다.