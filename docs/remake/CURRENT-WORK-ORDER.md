# RVTT Remake 현재 작업 순서

- 상태: `ACTIVE · ADR_0092_SURVIVAL_AND_TOKEN_AUTHORING_SOURCE`
- 최종 갱신일: 2026-08-06
- 최신 결정: [`ADR-0092`](decisions/ADR-0092-campaign-survival-logistics-and-dm-authored-actor-tokens.md)
- Survival Runtime: [`campaign-survival-logistics-and-supply-settlement-runtime-contract.md`](architecture/campaign-survival-logistics-and-supply-settlement-runtime-contract.md)
- Actor Token Runtime: [`dm-authored-actor-token-and-statblock-import-runtime-contract.md`](architecture/dm-authored-actor-token-and-statblock-import-runtime-contract.md)
- DM Guide: [`CAMPAIGN-SURVIVAL-AND-ACTOR-TOKEN-AUTHORING.md`](user-guides/dm/CAMPAIGN-SURVIVAL-AND-ACTOR-TOKEN-AUTHORING.md)
- Supplemental HTML: [`survival-and-token-authoring.html`](user-guides/html/survival-and-token-authoring.html)

## 현재 단계

```text
ADR-0088 Direct Play
→ ACCEPTED

ADR-0089 Observer-first Surface
→ ACCEPTED

ADR-0090 Console Matrix·DM Windows
→ ACCEPTED

ADR-0091 Asset·Official Sheet·Dice·Core Rules
→ ACCEPTED

ADR-0092 Survival Logistics·DM Actor Token Authoring
→ ACCEPTED · SOURCE IMPLEMENTATION REQUIRED

High-Fidelity HTML
→ BASE 33 + SUPPLEMENTAL 6 SCREENS
```

## Production 작업 순서

1. Campaign Detail Policy Family와 Preset Resolver
2. Rule Profile Consumption Requirement Import
3. Supply Metadata와 Inventory Allocation Planner
4. Game Time·Supply Settlement Transaction
5. Supply Ledger·Projection·Rollback Idempotency
6. Campaign Rules·Time Advance Preview UI
7. Actor Model Asset Registry·Validation
8. Strict Stat Block JSON Schema Validator
9. Actor Model Catalog Projection·AI Prompt Builder
10. Campaign-local Actor Template Package Publish
11. SceneNpc Spawn·Template Migration
12. Static·Security·Disclosure·Performance Gate
13. Studio Multi-client Acceptance

## 첫 Runtime Gate

- Narrative·Standard·Survival·Custom Candidate Snapshot Compile
- Toggle On·Off 비소급 동작
- 3일 Advance에서 일별 Supply Checkpoint
- Item Reservation 충돌과 Retry 중복 소비 방지
- Hidden Consumer·Container 미노출
- 빈 Actor Model Catalog Prompt 생성
- Catalog에 없는 Model ID Validation 거부
- Script·Remote·미등록 Recipe Import 거부
- Campaign Draft→Publish→SceneNpc Spawn Smoke

문서·HTML·Schema PASS는 Roblox Runtime PASS가 아니다.
