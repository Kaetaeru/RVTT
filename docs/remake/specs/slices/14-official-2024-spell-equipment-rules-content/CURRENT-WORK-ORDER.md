# Slice 14 Work Order — Official 2024 Spell·Equipment·Rules Content

- 상태: CHECKPOINT_COMPLETE
- 문서 종류: Slice Implementation Spec Work Order
- 즉시 구현 명세 가능성: BLOCKED
- 작성일: 2026-08-05
- 전체 Roadmap: [`SLICE-ROADMAP.md`](../../SLICE-ROADMAP.md)
- 선행 Slice: [`Core Rules`](../02-core-rules-kernel/implementation-contract.md), [`Inventory`](../06-inventory-equipment-world-items/implementation-contract.md), [`Content Platform`](../12-content-pack-localization-trusted-extension/implementation-contract.md), [`Character Content`](../13-official-2024-character-options-content/implementation-contract.md)
- 통합 계약: [`implementation-contract.md`](implementation-contract.md)
- 검수 감사: [`Slice 14 Spec Checkpoint Audit`](../../../audits/slices/14-official-2024-spell-equipment-rules-content-spec-checkpoint-audit.md)

## 사용자 완료 결과

```text
Character Capability에서 Spell·Weapon·Item·Rule Action 선택
→ Target·Cost·Casting·Use Route 검증
→ Roll·Save·Effect·Damage·Condition 실행
→ Resource·Item·Duration Commit
→ UI·Presentation·저장
→ Content Coverage 검증
```

## 명세 작업 순서

| 순서 | 상태 | 작업 | 완료 기준 |
|---:|---|---|---|
| 1 | DONE | Spell Definition·Casting Route | Acquisition·Preparation·Resource·Component·Target 연결 |
| 2 | DONE | Weapon·Armor·Gear·Consumable | Item Definition·Attack Profile·Use Capability 연결 |
| 3 | DONE | Condition·Duration·Concentration | Effect Contribution·Expiry·Cleanup 정의 |
| 4 | DONE | Core Action·Reaction·Rest Rule Content | Runtime 계약을 사용하는 데이터·Recipe 정의 |
| 5 | DONE | Recipe·Step·Advanced Operation Coverage | Standard Step 우선과 예외 승인 Gate 정의 |
| 6 | DONE | Localization·Source Metadata·Rights | 규칙 본문 복제 없이 Summary·Citation·권리 Gate 정의 |
| 7 | DONE | Content Wave·Coverage Matrix | Family별 Compile·Scenario·Migration 상태 정의 |
| 8 | BLOCKED | Official Data·Rights Review | 실제 Spell·Item·Rule 수치·명칭·배포 허용 범위 확인 필요 |
| 9 | BLOCKED | Production Pipeline Mapping | 실제 Recipe·Item·Locale·Asset·CI 경로 조사 필요 |

## 구현 시 추출할 세부 명세

```text
content-2024/spell-definition-casting-route
content-2024/weapon-armor-gear-consumable
content-2024/condition-duration-concentration
content-2024/core-action-reaction-rest
content-2024/recipe-step-coverage
content-2024/advanced-operation-exceptions
content-2024/localization-source-metadata
content-2024/coverage-migration-regression
```

## 금지

- 규칙 본문·설명을 장문 복제
- 이름만 등록하고 실행 Recipe·Scenario가 없는 Placeholder
- Content별 직접 Store Mutation·Remote·Client Script
- Roll·Damage·Effect Runtime을 주문마다 재구현
- Rights Review 없는 공식 Asset·본문 배포