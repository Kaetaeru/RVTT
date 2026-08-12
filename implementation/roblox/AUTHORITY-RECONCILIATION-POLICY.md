# RVTT Authority Reconciliation Policy

- 상태: `ACTIVE · ACCEPTANCE_PROMOTION_GATE`
- 최종 갱신일: 2026-08-12
- 적용 범위: Studio 반복 중 사용자가 변경을 요청하고 최종 동작을 확정한 뒤 GitHub Authority·Code Contract·Source·Test를 정합화하는 절차

## 1. 핵심 원칙

사용자가 기능을 몇 차례 수정하게 하는 동안에는 빠른 Studio 반복을 우선한다. Product·ADR·Architecture 문서를 매 클릭 조정마다 고치지 않는다.

반대로 사용자가 `좋다`, `이걸로`, `확정`, `다음으로 가자`처럼 현재 동작을 수용하면 다음 기능을 만들기 전에 **Authority Reconciliation**을 수행한다.

```text
IMPLEMENTING
→ READY_FOR_USER
→ 사용자 수정 요청
→ IMPLEMENTING 반복
→ 사용자 최종 수용
→ AUTHORITY_RECONCILIATION
→ System/Module/Stable Function Contract 정합화
→ Source·Test 정규화
→ Promotion Commit
→ ACCEPTED
→ 다음 Checkpoint
```

사용자 수용만으로 즉시 `ACCEPTED` 처리하지 않는다.

## 2. 반복 중 허용되는 임시 불일치

현재 Checkpoint가 `IMPLEMENTING` 또는 `READY_FOR_USER`인 동안에는 사용자가 방금 요청한 변경 때문에 Studio 구현과 상위 Product 문서가 잠시 다를 수 있다.

조건:

- 현재 사용자 요청이 무엇인지 명확해야 한다.
- 아직 확정되지 않은 변경을 Product·ADR의 새로운 영구 규칙처럼 기록하지 않는다.
- 임시 구현을 다음 Checkpoint의 전제로 사용하지 않는다.
- Server Authority·Security·Disclosure 같은 비협상 안전 경계는 실험 중에도 우회하지 않는다.
- 실험 중간 상태를 Promotion Commit으로 남기지 않는다.
- 실제 cross-module callable boundary가 바뀌면 Stable Function Contract와 Source는 서로 어긋난 채 방치하지 않는다.

private/helper 내부 구현은 반복 중 자유롭게 바꿀 수 있다.

## 3. 사용자 수용의 범위

사용자가 눈으로 보고 조작한 기능을 수용했다고 해서 보이지 않는 내부 Architecture 변경까지 자동 승인한 것으로 해석하지 않는다.

예:

- 버튼 위치·선택 표시·카메라 감각 수용 → 그 사용자 동작은 확정 가능.
- 같은 Module 내부 helper 분해 변경 → 별도 승인 불필요.
- cross-module Stable Function의 입력/출력 보완이 기존 책임 안에서 필요 → Contract를 정합화 가능.
- Server/Client Authority 이동, state owner 변경, Module 책임 통합/분리, System flow 변경 → 별도 Architecture 결정이므로 기존 승인 없이 확정 금지.

Authority Reconciliation 중 미승인 Architecture·Authority 변경이 발견되면 문서를 조용히 맞춰버리지 말고 사용자에게 문제·대안·영향을 먼저 보고한다.

## 4. Authority Impact Scan

사용자 수용 직후 Codex는 Repository에서 현재 효력이 있는 문서·Contract·Source 전체를 검색해 확정된 동작과 충돌하는 내용을 찾는다.

확인 순서:

```text
1. 사용자의 최신 확정 결정
2. Accepted ADR
3. Product / Architecture / System / Global UI Policy
4. Implementation Spec
5. GREENFIELD-SYSTEM-SEQUENCE / GREENFIELD-BUILD-POLICY
6. System Contract / system-function-contracts.json
7. Module Contract / module-contracts.json
8. Stable Function Contract
9. CURRENT-WORK-ORDER / CODEX-ACTIVE-TASK
10. greenfield/src
11. greenfield/tests
12. 현재 User Guide·운영 문서
```

단순 파일명 검색만 하지 않는다. 변경된 개념, 입력 의미, 상태 이름, Authority owner, UX 흐름, System flow, Module 책임, Stable Function name/input/output/read/write/side-effect/failure/revision 의미와 관련된 표현을 검색한다.

## 5. Top-down Reconciliation

충돌이 있으면 상위 Authority부터 아래로 수정한다.

```text
User Decision
→ ADR / Product / Architecture
→ Implementation Spec
→ System Sequence / Build Policy
→ System Contract
→ Module Contract
→ Stable Function Contract
→ Active Task / Work Order
→ Source
→ Focused Test
→ Guide
```

하위 Source에 맞추기 위해 상위 Product 의미를 임의로 바꾸지 않는다. 사용자가 확정한 변경이 상위 의미 자체를 바꾸는 경우에만 해당 Authority를 갱신한다.

## 6. 문서 보존 규칙

### 현재 Authority

현재 효력이 있는 문서가 확정된 결정과 충돌하면:

- 같은 문서가 계속 Authority라면 내용을 직접 갱신한다.
- 역할 자체가 폐기되면 `SUPERSEDED` 또는 `ARCHIVED`로 표시하고 새 Authority를 가리킨다.
- 동일한 현재 규칙을 여러 문서가 서로 다르게 소유하게 두지 않는다.

### Historical Evidence

다음은 당시 기록이므로 새 결정에 맞춰 내용을 다시 쓰지 않는다.

- 과거 Codex Command
- Audit
- 과거 Acceptance Result
- 과거 Runtime Log
- 이미 종료된 Review Result

필요하면 상단에 `HISTORICAL · NON_AUTHORITY` 또는 현재 Authority 링크만 추가한다.

## 7. Code Contract Reconciliation

현재 기능이 확정되면 다음 세 층을 따로 확인한다.

### System Contract

- 책임/입력/출력/invariant/Module flow가 확정된 동작과 맞는가.
- Authority와 state owner가 바뀌지 않았는가.

### Module Contract

- responsibility/dependsOn/authority/stateOwnership가 Source와 맞는가.
- `entryPoints`가 실제 안정 callable surface와 맞는가.

### Stable Function Contract

- `entryPoints`와 Function Contract 이름이 1:1인가.
- purpose/input/output/authority/read/write/side effect/failure/idempotency/validation/permission/revision 의미가 최종 Source와 맞는가.
- 다른 Module이 undeclared function/private helper를 호출하지 않는가.

미승인 Architecture 변경이 필요한 경우 여기서 멈추고 사용자에게 보고한다.

## 8. Canonicalization Gate

사용자 수용 뒤 다음을 모두 끝내야 Promotion Commit을 만들 수 있다.

1. 확정된 사용자 동작을 한 문장으로 기록.
2. Authority Impact Scan 완료.
3. 충돌하는 현재 상위 문서 갱신 또는 Supersede.
4. System Contract 정합화.
5. Module Contract 정합화.
6. Stable Function Contract 정합화.
7. `validate_module_contracts.py` PASS.
8. Studio 결과를 `greenfield/src` Canonical Source로 정규화.
9. `greenfield.project.json`으로 재현 가능 상태 확인.
10. 관련 Focused Test 추가·갱신.
11. 현재 문서·Contract·Source 재검색으로 남은 충돌 없음 확인.
12. 사용자 승인되지 않은 Architecture 변경 없음 확인.
13. Checkpoint와 관련 Module을 `ACCEPTED` 상태로 준비.

하나라도 미완료면 Promotion Commit을 만들거나 다음 Checkpoint로 넘어가지 않는다.

## 9. Checkpoint Promotion Commit

Authority Reconciliation이 끝난 최종 상태는 하나의 명확한 Promotion Commit으로 고정한다.

Promotion Commit이 포함해야 하는 범위:

```text
확정 동작에 영향을 받은 현재 Authority 문서
+ System Contract
+ Module Contract / Checkpoint 상태
+ Stable Function Contract
+ greenfield/src Canonical Source
+ Rojo Mapping 변경
+ Focused Test
+ 필요한 현재 Guide / Work Order
```

관련 없는 다음 기능, 미확정 실험, 임시 디버그 변경을 섞지 않는다.

Commit 제목 형식:

```text
checkpoint(<CHECKPOINT_ID>): accept <short behavior summary>
```

Commit 본문에는 최소 다음 Trailer를 남긴다.

```text
RVTT-Checkpoint: S1_SELECTION
RVTT-User-Acceptance: CONFIRMED
RVTT-Authority-Reconciliation: COMPLETE
RVTT-Unresolved-Conflicts: NONE
```

규칙:

- Promotion Commit은 해당 Checkpoint의 마지막 정합화 작업이어야 한다.
- Promotion Commit 생성 전 Module/Checkpoint 상태를 `ACCEPTED`로 준비하고 Focused Test를 통과시킨다.
- Commit이 성공한 뒤 그 SHA가 해당 Checkpoint의 복원 기준점이 된다.
- 다음 Checkpoint는 이 Promotion Commit을 기반으로 시작한다.
- 이미 Push된 실험 이력을 Promotion Commit을 예쁘게 만들기 위해 Force Push/Rebase하지 않는다.
- `checkpoint(...): accept ...`는 사용자 수용이 완료된 Playable Checkpoint에만 사용한다.
- 확정 동작을 다시 바꾸면 새 사용자 수용과 새 Reconciliation/Promotion Commit을 만든다. 이전 Promotion Commit은 역사적 복원점으로 남긴다.

## 10. Reconciliation Report

Codex는 확정 처리 시 짧게 다음을 보고한다.

```text
ACCEPTED BEHAVIOR
- 사용자가 최종 수용한 동작

AUTHORITY UPDATED
- Product / ADR / Architecture / Spec

CODE CONTRACT UPDATED
- System / Module / Stable Function

SUPERSEDED
- 더 이상 현재 Authority가 아닌 문서

CANONICALIZED
- Source / Rojo Mapping

TESTED
- Contract Validator / Focused Test

PROMOTION COMMIT
- checkpoint id / commit SHA

UNRESOLVED CONFLICTS
- none 또는 사용자 결정이 필요한 항목
```

`UNRESOLVED CONFLICTS`가 남아 있으면 Promotion Commit을 만들거나 `ACCEPTED` 처리하지 않는다.

## 11. 다음 Checkpoint Gate

```text
사용자 수용
+ Authority Reconciliation 완료
+ System/Module/Function Contract 정합
+ Canonical Source 완료
+ Focused Test 완료
+ Promotion Commit 완료
= ACCEPTED
```

그 후에만 다음 Checkpoint를 `IMPLEMENTING`으로 바꾼다.
