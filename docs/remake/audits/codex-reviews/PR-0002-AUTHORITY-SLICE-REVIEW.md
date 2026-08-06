# PR #2 Codex Review — Authority·Slice Ownership

- 상태: `FIXES_APPLIED_PENDING_DELTA_REVIEW`
- Pull Request: `#2`
- Original Target Commit: `50538dbf3c1c0150f6e4c20f45ff2b948981b1d5`
- Base Commit: `c4347e5adafe72b3bdf98a9675f6c155a3b95b33`
- Fix Integration Head Before Triage Record: `4d43ed68309c71d672350db9c4ada28bdd27e57e`
- Reviewer Role: `Authority Chain + Slice Ownership Reviewer`
- Lead Reviewer: ChatGPT
- Feedback Channel: `Codex prompt chat, copied by user into ChatGPT`
- 생성일: 2026-08-07

## Review Scope

Codex는 다음을 검수했다.

- ADR-0092 Authority Chain
- Product→Architecture→Slice 연결
- Slice 06→07→11→12→15→16 책임
- Supply Source Priority 권위
- Actor Source Type Stable ID
- Empty Actor Model Catalog canonical format
- 문서·CI·Runtime Evidence 경계

Codex 결과는 GitHub PR 댓글이나 Review Thread가 아니라 사용자가 Codex Prompt Chat 결과를 이 대화에 전달한 것이다. 이 전달 방식도 유효한 Review Input이지만, Target SHA와 원문을 이 Artifact에 기록해야 한다.

## Finding Triage

| Finding | Severity | Lead 판정 | 근거 | 후속 조치 | 상태 |
|---|---:|---|---|---|---|
| `AUTH-SLICE-001` | HIGH | `CONFIRMED` | Slice 06의 mutable `priority`·`ReorderSupplySources`와 Slice 07 Frozen Policy가 동시에 Source 순서를 소유했다. Pending Plan의 결정성·Safe Boundary가 불명확했다. | Source 순서를 `survival.source_priority` Frozen Policy의 단일 권위로 고정. Slice 06은 membership·ACL·revision만 소유. `sourceOrderDigest`, stale Plan, Safe Boundary·Retry Test 계약 추가. | FIX_APPLIED |
| `AUTH-SLICE-002` | MEDIUM | `CONFIRMED` | ADR은 `homebrew | campaign_custom`, Runtime·Schema·Prompt는 `campaign_homebrew | unknown_draft`를 사용했다. | Canonical enum을 `rules_package | campaign_homebrew | imported_reference | unknown_draft`로 고정. `homebrew | campaign_custom`은 legacy rejected alias로 명시하고 fixture 검증 추가. | FIX_APPLIED |
| `AUTH-SLICE-003` | MEDIUM | `CONFIRMED` | Empty Catalog가 `{"models":[]}`, revision 일부 포함 형식, example fixture로 분리됐다. | `rvtt.actor-model-catalog.v1` JSON Schema 추가. 필수 필드와 empty disclosure digest를 고정하고 ADR·Runtime·fixture를 동일하게 정렬. | FIX_APPLIED |

## 적용 파일

### AUTH-SLICE-001

- `docs/remake/decisions/ADR-0092-campaign-survival-logistics-and-dm-authored-actor-tokens.md`
- `docs/remake/architecture/campaign-survival-logistics-and-supply-settlement-runtime-contract.md`
- `docs/remake/specs/slices/06-inventory-equipment-world-items/ADR-0092-DELTA.md`
- `docs/remake/specs/slices/07-rest-time-downtime-progression/ADR-0092-DELTA.md`

### AUTH-SLICE-002

- `docs/remake/decisions/ADR-0092-campaign-survival-logistics-and-dm-authored-actor-tokens.md`
- `docs/remake/architecture/dm-authored-actor-token-and-statblock-import-runtime-contract.md`
- `implementation/roblox/content-templates/actor-statblock-ai-prompt.md`
- `implementation/roblox/content-templates/actor-statblock-source-type-fixtures.json`

### AUTH-SLICE-003

- `docs/remake/decisions/ADR-0092-campaign-survival-logistics-and-dm-authored-actor-tokens.md`
- `docs/remake/architecture/dm-authored-actor-token-and-statblock-import-runtime-contract.md`
- `implementation/roblox/content-templates/actor-model-catalog.schema.json`
- `implementation/roblox/content-templates/actor-model-catalog.example.json`

### Regression Gate

- `implementation/roblox/tooling/validate_content_templates.py`
- `.github/workflows/validate-rvtt-content-templates.yml`

## Lead Resolution

### AUTH-SLICE-001

```text
Supply Source membership·ACL·revision
→ Slice 06 Inventory

Supply Source order
→ Slice 07 survival.source_priority Frozen Policy

Policy reorder
→ Candidate Snapshot
→ Impact Preview
→ Safe Boundary
→ Pending Plan·Reservation stale
→ New sourceOrderDigest로 재계획
```

### AUTH-SLICE-002

Canonical Source Type:

```text
rules_package
campaign_homebrew
imported_reference
unknown_draft
```

Legacy Rejected Alias:

```text
homebrew
campaign_custom
```

### AUTH-SLICE-003

Canonical Empty Catalog:

```json
{
  "schemaVersion": "rvtt.actor-model-catalog.v1",
  "catalogRevision": 0,
  "packageVersionSet": [],
  "models": [],
  "disclosureDigest": "sha256:e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"
}
```

## CI Observation

Original Review는 Target `50538dbf...`에만 유효했다. 사용자가 전달한 Coverage Summary도 현재 PR HEAD가 달라 Merge Gate를 충족하지 않는다고 올바르게 지적했다.

이후 HEAD `2984d4b...`의 `Validate RVTT implementation` 실패는 Test Assertion 실패가 아니라 GitHub Actions가 `actions/checkout` 등 Action Download 정보를 가져오는 단계에서 `Service Unavailable`로 종료된 Runner Infrastructure Failure였다. `structure-and-policy` Job은 성공했다. 새 Fix HEAD의 Workflow 결과를 별도로 사용한다.

## Delta Review Gate

다음 Codex Delta Review는 PR의 최신 HEAD를 Target으로 실행한다.

검증 대상:

1. `AUTH-SLICE-001`의 dual authority가 제거됐는가.
2. Pending Settlement 중 Source Reorder가 stale Plan을 만들고 Safe Boundary 뒤 재계획하는가.
3. `AUTH-SLICE-002` canonical enum과 legacy rejection이 ADR·Runtime·Schema·Prompt·fixture에서 일치하는가.
4. `AUTH-SLICE-003` Catalog Schema·ADR·Runtime·example이 같은 필수 필드를 사용하는가.
5. 새 검증 Script가 세 계약을 실제로 실패시키는 Gate인가.
6. 새 수정이 Runtime PASS나 Roblox Studio PASS로 과장되지 않았는가.

현재 상태는 Fix 적용 완료이며 Codex Delta Review와 최신 HEAD CI 결과 대기다.