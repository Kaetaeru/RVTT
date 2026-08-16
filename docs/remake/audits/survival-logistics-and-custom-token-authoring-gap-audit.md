# Survival Logistics와 Custom Actor Token Authoring Gap Audit

- 상태: `COMPLETE · IMPLEMENTATION CONTRACT READY`
- 감사일: 2026-08-06
- 상위 결정: [`ADR-0092`](../decisions/ADR-0092-campaign-survival-logistics-and-dm-authored-actor-tokens.md)

## 1. 감사 범위

Campaign Rule Setting, Game Time, Travel, Rest, Downtime, Inventory, Item Consumption, Effect, SceneNpc, Token Prefab, Content Package, DM Workspace와 AI-assisted Import를 대조했다.

## 2. 확인된 기존 기반

| 기반 | 기존 상태 | ADR-0092 연결 |
|---|---|---|
| Game Time | TimeAdvancePlan·Checkpoint·Scheduler 확정 | 일일·식사·여행 Supply Boundary 추가 |
| Policy | Campaign Binding·Frozen Snapshot·Migration 확정 | Survival Module과 Toggle 적용 방식 추가 |
| Inventory | ItemInstance·Quantity·Reservation·Atomic Transfer 확정 | Supply Unit·Protected Item·Consumption Plan 추가 |
| Effect | Condition·Ongoing Effect Runtime 확정 | Shortage Consequence Recipe 연결 |
| SceneNpc | Stat Block NPC와 Scene 생명주기 확정 | Campaign-local Actor Template Publish 연결 |
| Prefab | Stable Prefab ID와 Server Validation 확정 | Actor Model Asset Registry와 Token Binding 추가 |
| DM Window | 독립 Tool Module 확정 | Campaign Rules·Supply·Actor Builder 창 추가 |

## 3. 폐쇄한 공백

| 공백 | 확정 계약 |
|---|---|
| 며칠이 지나도 식량이 줄지 않음 | Time Advance와 Supply Settlement Atomic Commit |
| 모든 캠페인에 생존 규칙 강제 위험 | Narrative·Standard·Survival·Custom Preset |
| 정확한 소비량의 위치 불명 | 활성 Rule Content의 Requirement Definition·Rule Anchor |
| 기능 중간 Toggle 의미 불명 | Candidate Snapshot·안전 경계·비소급 기본값 |
| 여러 날 점프의 중간 소비·사건 | Checkpoint별 순차 Settlement |
| 음식처럼 보이는 Item 자동 소비 위험 | 명시적 Supply Metadata만 사용 |
| Party·Follower·Mount 소비 범위 불명 | Consumer Binding과 Supply Group |
| 같은 정산 재시도 시 중복 차감 | Settlement Idempotency와 Reservation |
| DM Custom Token 추가 경로 없음 | Model Registry→Stat Block→Template→Publish Pipeline |
| AI가 존재하지 않는 Model ID 생성 | 전체 Catalog 삽입·Strict Reference Validation |
| AI 출력에서 임의 코드 실행 위험 | Strict Schema·manual/trusted_recipe만 허용 |
| 공식·Homebrew 출처 혼합 | Stable Source Anchor 없는 항목은 Campaign Homebrew/Draft |
| Template 변경이 기존 NPC를 오염 | Versioned Template·new_spawn_only 기본 Migration |

## 4. 아직 Runtime Evidence가 아닌 항목

- 실제 Rule Profile의 식량·물 Requirement Import
- 수일 Time Advance와 Supply Transaction Smoke
- 여러 Client의 Inventory Reservation 충돌
- Rollback 후 Settlement Idempotency
- 실제 Actor Model Package와 Thumbnail 생성
- JSON Schema Validator·Prompt Builder 실행
- Model Script 제거·성능 Budget 검사
- Campaign-local Package Publish·Migration
- HTML과 Roblox ScreenGui 비교

## 5. Release-blocking Acceptance

- Toggle 변경이 과거 Item·Effect를 조용히 바꾸지 않음
- Time·Inventory·Shortage가 하나의 Transaction으로 확정됨
- 권한 밖 Supply Source와 Hidden Consumer가 Projection에서 사라짐
- Prompt에 현재 보이는 Model Entry 전부가 포함됨
- Catalog에 없는 Model ID가 Publish되지 않음
- AI Draft가 자동 Publish되지 않음
- 임의 Script·Luau·Remote·URL Callback이 Import되지 않음
- Campaign-local Content가 Core Package를 직접 수정하지 않음
