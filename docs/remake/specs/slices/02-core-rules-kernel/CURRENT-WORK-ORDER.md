# Slice 02 Work Order — Core Rules Kernel

- 상태: CHECKPOINT_COMPLETE
- 문서 종류: Slice Implementation Spec Work Order
- 즉시 구현 명세 가능성: BLOCKED
- 작성일: 2026-08-05
- 전체 Roadmap: [`SLICE-ROADMAP.md`](../../SLICE-ROADMAP.md)
- 선행 Slice: [`Slice 01`](../01-first-session-walking-skeleton/implementation-contract.md)
- 통합 계약: [`implementation-contract.md`](implementation-contract.md)
- 검수 감사: [`Slice 02 Spec Checkpoint Audit`](../../../audits/slices/02-core-rules-kernel-spec-checkpoint-audit.md)

이 Slice는 D&D 2024 전체 콘텐츠를 작성하는 단계가 아니다. 모든 탐험 판정·전투·주문·아이템이 재사용할 서버 권위 규칙 실행 기반과 대표적인 수직 결과를 확정한다.

## 1. 사용자 완료 결과

```text
Character Capability 선택
→ 대상·DC·AC 검증
→ D20 Test·Attack·Save
→ RollRecord 공개
→ Damage·Healing·최소 Condition 결과
→ Atomic Commit
→ Projection·저장
→ Reconnect 후 동일 결과 유지
```

## 2. 명세 작업 순서

| 순서 | 상태 | 작업 | 완료 기준 |
|---:|---|---|---|
| 1 | DONE | `dnd5e-2024` Core Policy Profile | Ability, Proficiency, D20 Test와 기본 결과 Policy가 Versioned Snapshot으로 고정됨 |
| 2 | DONE | Character Derived Stat·Capability 계약 | Ability Modifier, Skill, Save, AC, HP와 Resource Source 경계가 정의됨 |
| 3 | DONE | RuleExecution Orchestrator Adapter | 실행 수명주기, Pending Input, Reservation, Cancel·Recovery가 정의됨 |
| 4 | DONE | Shared Recipe 001·002 갱신 방향 | Recipe Compiler와 Step Handler가 RuleExecution·Transaction 하위 책임으로 배치됨 |
| 5 | DONE | Dice·RollRecord·Reveal 계약 | D20, Advantage·Disadvantage, Roll Plan, Sealed Result와 공개 경계 정의 |
| 6 | DONE | Attack·Save·Damage·Healing 계약 | Roll Outcome과 HP·Effect Commit이 분리됨 |
| 7 | DONE | 최소 Effect·Condition·Resource 계약 | Duration·Contribution·Cost·Reservation의 확장 가능한 최소 기반 정의 |
| 8 | DONE | Persistence·Diagnostics·Test | Pending Execution, Roll, Version, Restart·Disclosure Scenario 정의 |
| 9 | BLOCKED | Production Source Mapping | 실제 Rules·Character·Dice·Effect Package와 Legacy Schema 조사 필요 |

## 3. 구현 시 추출할 세부 명세

```text
ruleset/core-policy-profile
character/derived-stat-capability
rules/rule-execution-adapter
rules/recipe-definition-compiler
rules/step-handler-provider
rules/d20-roll-record
rules/attack-save-damage-healing
rules/minimum-effect-condition-resource
testing/core-rules-vertical-scenarios
```

기존 [`Shared Spec 001`](../../shared/001-recipe-step-runtime-foundation.md)과 [`Shared Spec 002`](../../shared/002-standard-step-handler-contracts.md)는 폐기하지 않는다. 이 Slice의 통합 계약에 맞춰 책임과 Version·Recovery·Transaction 경계를 갱신해야 한다.

## 4. 대표 수직 Scenario

- Strength Ability Check vs 고정 DC
- Skill Proficiency가 적용되는 Check
- Advantage·Disadvantage 상쇄
- Melee Basic Attack vs AC
- Saving Throw 성공·실패 분기
- Damage와 Temporary HP·Current HP Commit
- Healing과 최대 HP 제한
- Resource Cost 예약 후 실행 취소·완료
- Reconnect 중 Pending RuleExecution과 Roll 공개 복구
- Player·DM·Observer별 비공개 Roll Modifier 누출 검사

## 5. 차단 사항

- 실제 Character Source·Build·State Schema
- 기존 Dice RNG·Remote·Presentation 구현
- 기존 Effect·Resource 저장 방식
- 공식 2024 수치 데이터를 저장할 Source Pack 구조
- Deterministic RNG·Clock·ID Adapter의 실제 Test Host

이 항목은 최종 Module 경로와 Migration 범위를 차단하지만, 규칙 의미와 실행 경계는 본 Slice 계약으로 고정한다.