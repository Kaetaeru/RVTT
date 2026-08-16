# PR #2 Codex Delta Review 001 — Triage

- 상태: `FIX_APPLIED_PENDING_DELTA_002`
- Pull Request: `#2`
- Command ID: `RVTT-PR2-ADR0092-DELTA-001`
- Codex Result Comment: `https://github.com/Kaetaeru/RVTT/pull/2#issuecomment-5207508456`
- Reviewed Target SHA: `6052808ab36adf1918c056792eaf132bf47c8528`
- Result Marker: `RVTT_CODEX_REVIEW_RESULT`
- Lead Reviewer: ChatGPT
- 결과 확인일: 2026-08-07

## Result Authenticity

Codex 댓글의 다음 값이 활성 작업 및 검수 시점 PR HEAD와 일치했다.

```text
commandId: RVTT-PR2-ADR0092-DELTA-001
targetSha: 6052808ab36adf1918c056792eaf132bf47c8528
reviewPhase: DELTA_REVIEW
resultStatus: FINDINGS_REPORTED
```

따라서 이 댓글은 현재 검수 입력으로 수용했다.

## Original Finding Resolution

| Finding | Codex Resolution | Lead 판정 | 남은 경계 |
|---|---|---|---|
| `AUTH-SLICE-001` | `RESOLVED` | `RESOLVED_CONFIRMED` | Production Source와 stale Plan·Safe Boundary·Retry·Restart·Rollback Runtime Test는 후속 Slice 06·07 구현 시 필요 |
| `AUTH-SLICE-002` | `RESOLVED` | `RESOLVED_CONFIRMED` | 실제 Importer의 legacy alias rejection Integration Test는 후속 구현 시 필요 |
| `AUTH-SLICE-003` | `RESOLVED` | `RESOLVED_CONFIRMED` | Prompt Builder Serializer와 viewer-filtered disclosure digest Runtime Test는 후속 구현 시 필요 |

세 항목의 문서·Schema·fixture 수준 모순은 해결됐다. 이는 Production Runtime이나 Roblox Studio PASS가 아니다.

## New Finding Triage

### DELTA-NEW-001

```text
severity: MEDIUM
category: test
Lead 판정: CONFIRMED
```

Codex 주장:

- `validate_content_templates.py`가 Template 파일만 읽고 Accepted ADR와 Runtime 계약을 읽지 않았다.
- 전용 Workflow의 path filter도 ADR와 Runtime 문서 변경에 반응하지 않았다.
- 따라서 문서만 다시 drift해도 Template Gate가 PASS할 수 있었다.

Lead 재검증:

- 기존 Validator의 입력은 `implementation/roblox/content-templates`로 제한돼 있었다.
- 기존 Workflow는 Content Template, Validator와 Workflow 파일만 감시했다.
- ADR Source Type 또는 Runtime Empty Catalog canonical block만 변경하는 경우 전용 Gate가 실행되지 않거나 drift를 탐지하지 못했다.

판정 근거가 충분하므로 `CONFIRMED`로 분류했다.

## Applied Fix

### Validator

`implementation/roblox/tooling/validate_content_templates.py`를 다음과 같이 확장했다.

- Source Type fixture와 Empty Catalog fixture를 machine-readable 기준으로 사용
- ADR-0092의 no-source canonical Source Type·legacy alias·empty Catalog block 검사
- Actor Import Runtime 계약의 전체 canonical Source Type block·legacy alias·empty Catalog block 검사
- 전용 Workflow가 두 Authority 문서를 감시하는지 검사
- ADR Source Type drift, Runtime Empty Catalog drift, Workflow path drift를 인메모리 변형으로 검출하는 negative regression self-test 추가

### Workflow

`.github/workflows/validate-rvtt-content-templates.yml`의 Pull Request와 Push path filter에 다음을 추가했다.

```text
docs/remake/decisions/ADR-0092-campaign-survival-logistics-and-dm-authored-actor-tokens.md
docs/remake/architecture/dm-authored-actor-token-and-statblock-import-runtime-contract.md
```

이제 두 Authority 문서가 변경되면 Content Template Gate가 실행된다.

## Evidence Boundary

현재 Fix는 다음을 증명한다.

- Authority 문서와 machine-readable fixture 사이 정적 drift를 검출하도록 Gate가 확장됨
- Workflow가 Authority 문서 변경에 반응하도록 설정됨
- 세 종류의 negative mutation을 Validator self-test가 검출하도록 정의됨

현재 Fix가 증명하지 않는 것:

- Production Importer Runtime
- Prompt Builder Runtime Serializer
- Roblox Studio
- Multi-client
- Persistence
- Human Playtest

## Next Gate

다음 Codex Delta Review는 `DELTA-NEW-001` 수정만 검수한다.

검증 항목:

1. Validator가 실제 ADR와 Runtime 문서를 읽는가.
2. machine-readable fixture가 canonical 기준인가.
3. 문서 drift가 실제 오류로 보고되는가.
4. Workflow가 두 Authority 문서 변경에 실행되는가.
5. negative regression self-test가 잘못된 경로가 아니라 목표 drift를 검출하는가.
6. 수정이 Runtime PASS로 과장되지 않았는가.
