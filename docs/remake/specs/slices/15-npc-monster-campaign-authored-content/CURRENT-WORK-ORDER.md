# Slice 15 Work Order — NPC·Monster·Campaign Authored Content

- 상태: CHECKPOINT_COMPLETE
- 문서 종류: Slice Implementation Spec Work Order
- 즉시 구현 명세 가능성: BLOCKED
- 작성일: 2026-08-05
- 전체 Roadmap: [`SLICE-ROADMAP.md`](../../SLICE-ROADMAP.md)
- 선행 Slice: [`Core Rules`](../02-core-rules-kernel/implementation-contract.md), [`Encounter`](../04-encounter-core-loop/implementation-contract.md), [`Character Foundation`](../05-character-foundation-creation/implementation-contract.md), [`Content Platform`](../12-content-pack-localization-trusted-extension/implementation-contract.md), [`Spell·Equipment Content`](../14-official-2024-spell-equipment-rules-content/implementation-contract.md)
- 통합 계약: [`implementation-contract.md`](implementation-contract.md)
- 검수 감사: [`Slice 15 Spec Checkpoint Audit`](../../../audits/slices/15-npc-monster-campaign-authored-content-spec-checkpoint-audit.md)

## 사용자 완료 결과

```text
NPC·Monster Statblock 선택 또는 JSON Import
→ Schema·Content Ref·Budget 검증
→ Actor Definition Compile
→ DM Review·Campaign Publish
→ Scene Token·Prefab 배치
→ Exploration·Encounter·Loot·Journal 사용
→ 저장·Migration·Export
```

## 명세 작업 순서

| 순서 | 상태 | 작업 | 완료 기준 |
|---:|---|---|---|
| 1 | DONE | Actor Definition·Instance | Definition·Compiled Build·Persistent State·Scene Presence 분리 |
| 2 | DONE | Statblock Schema·Normalizer | Ability·Defense·HP·Speed·Capability·Sense·Language 구조 정의 |
| 3 | DONE | Safe JSON Import | 크기·깊이·Enum·Content Ref·Code·URL 차단 정의 |
| 4 | DONE | Campaign Authored Candidate·Publish | Draft·Compile·Diagnostic·Review·Activation 정의 |
| 5 | DONE | Token·Prefab·Scene Binding | Actor Definition과 Runtime Presence·Incarnation 분리 |
| 6 | DONE | Rules·Encounter·Loot·Journal Integration | Capability·Item·Objective·Anchor 재사용 정의 |
| 7 | DONE | Missing Content·Migration·Export | Pack 제거·Version 누락·Redacted Export 정의 |
| 8 | DONE | Starter Catalog·Fixture Replacement | Test Fixture와 Release Content 분리·Coverage 정의 |
| 9 | DONE | Diagnostics·Disclosure·Test | Import 공격·Secret·Restart·Rollback Scenario 정의 |
| 10 | BLOCKED | Data·Rights·Production Mapping | 실제 Statblock 데이터·권리·Actor·Prefab·Import 구조 확인 필요 |

## 구현 시 추출할 세부 명세

```text
actor/npc-monster-definition-build-state
actor/statblock-schema-normalizer
content-import/safe-json-validation
campaign-content/candidate-compile-publish
actor/token-prefab-scene-binding
actor/rules-encounter-loot-journal-integration
campaign-content/missing-version-migration-export
content/npc-monster-coverage-regression
```

## 금지

- Import JSON의 Luau·Module·Remote·URL 실행
- 이름 문자열만으로 Spell·Item·Capability 연결
- Actor Definition에 Scene Transform·현재 HP·Token Instance 복사
- NPC Dialogue Tree·생성형 대화 AI 추가
- 전체 공식 Monster Catalog 자동 포함 약속
- 권리 검토 없는 공식 본문·Artwork·Asset 배포