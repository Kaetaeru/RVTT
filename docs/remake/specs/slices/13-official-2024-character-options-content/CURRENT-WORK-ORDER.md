# Slice 13 Work Order — Official 2024 Character Options Content

- 상태: CHECKPOINT_COMPLETE
- 문서 종류: Slice Implementation Spec Work Order
- 즉시 구현 명세 가능성: BLOCKED
- 작성일: 2026-08-05
- 전체 Roadmap: [`SLICE-ROADMAP.md`](../../SLICE-ROADMAP.md)
- 선행 Slice: [`Character Foundation`](../05-character-foundation-creation/implementation-contract.md), [`Content Platform`](../12-content-pack-localization-trusted-extension/implementation-contract.md)
- 통합 계약: [`implementation-contract.md`](implementation-contract.md)
- 검수 감사: [`Slice 13 Spec Checkpoint Audit`](../../../audits/slices/13-official-2024-character-options-content-spec-checkpoint-audit.md)

## 사용자 완료 결과

```text
공식 지원 Source Pack 활성화
→ Species·Background·Class·Subclass·Feat 선택
→ Character 생성·Level Up
→ Grant·Capability·Resource·Choice 적용
→ Character Sheet·Rules·저장 연결
→ Level 1–20 Coverage 검증
```

## 명세 작업 순서

| 순서 | 상태 | 작업 | 완료 기준 |
|---:|---|---|---|
| 1 | DONE | Content Scope·Source Metadata | 지원 Source·Version·권리·Citation Metadata 경계 정의 |
| 2 | DONE | Character Option Definition Schema | Species·Background·Class·Subclass·Feat 공통 Definition 정의 |
| 3 | DONE | Progression·Grant·Choice | Level Table·Feature·Resource·Stored Selection 연결 |
| 4 | DONE | Creation·Level Up Integration | Character Compiler·Migration·Review 경로 정의 |
| 5 | DONE | Localization·Sheet Projection | 한국어 표시와 Stable ID·공개 Summary 분리 |
| 6 | DONE | Content Wave·Coverage Matrix | 의존성이 완결된 Wave와 완료 기준 정의 |
| 7 | DONE | Scenario·Regression·Migration | 생성·성장·재접속·Pack Upgrade 검증 정의 |
| 8 | BLOCKED | Official Data·Rights Review | 실제 수치·명칭·설명·Source 권리와 배포 허용 범위 확인 필요 |
| 9 | BLOCKED | Production Content Pipeline Mapping | 실제 Pack·Catalog·Localization·CI 경로 조사 필요 |

## 구현 시 추출할 세부 명세

```text
content-2024/character-option-schema
content-2024/species-background
content-2024/class-subclass-progression
content-2024/feat-ability-choice
content-2024/resource-feature-grants
content-2024/creation-level-up-integration
content-2024/localization-source-metadata
content-2024/coverage-regression-migration
```

## 금지

- 공식 규칙 본문을 구현 명세에 장문 복제
- Source Citation·권리 검토 없는 배포 데이터
- Runtime 계약을 우회하는 Class별 임의 Store Mutation
- 이름·한국어 문자열을 Content ID로 사용
- Test 없이 이름과 설명만 등록한 Placeholder Content