# RVTT Authority Reconciliation Policy

- 상태: `ACTIVE · ACCEPTANCE_PROMOTION_GATE`
- 최종 갱신일: 2026-08-12
- 적용 범위: Studio 반복 중 사용자가 변경을 요청하고 최종 동작을 확정한 뒤 GitHub Authority·Source·Test를 정합화하는 절차

## 1. 핵심 원칙

사용자가 기능을 몇 차례 수정하게 하는 동안에는 **빠른 Studio 반복을 우선**한다. Product·ADR·Architecture 문서를 매 클릭 조정마다 고치지 않는다.

반대로 사용자가 `좋다`, `이걸로`, `확정`, `다음으로 가자`처럼 현재 동작을 수용하면 그 순간부터는 다음 기능을 만들기 전에 **Authority Reconciliation**을 수행한다.

```text
IMPLEMENTING
→ READY_FOR_USER
→ 사용자 수정 요청
→ IMPLEMENTING 반복
→ 사용자 최종 수용
→ AUTHORITY_RECONCILIATION
→ Source·Contract·Test 정규화
→ ACCEPTED
→ 다음 Checkpoint
```

사용자 수용만으로 즉시 `ACCEPTED` 처리하지 않는다.

## 2. 반복 중 허용되는 임시 불일치

현재 Checkpoint가 `IMPLEMENTING` 또는 `READY_FOR_USER`인 동안에는 사용자가 방금 요청한 변경 때문에 Studio 구현이 기존 문서와 잠시 다를 수 있다.

조건:

- 현재 사용자 요청이 무엇인지 명확해야 한다.
- 아직 확정되지 않은 변경을 Product·ADR의 새로운 영구 규칙처럼 기록하지 않는다.
- 임시 구현을 다음 Checkpoint의 전제로 사용하지 않는다.
- Server Authority·Security·Disclosure 같은 비협상 안전 경계는 실험 중에도 우회하지 않는다.

## 3. 사용자 수용의 범위

사용자가 눈으로 보고 조작한 기능을 수용했다고 해서 **보이지 않는 내부 Architecture 변경까지 자동 승인한 것으로 해석하지 않는다.**

예:

- 버튼 위치·선택 표시·카메라 감각을 수용함 → 그 사용자 동작은 확정 가능
- 그 구현 과정에서 Server/Client Authority를 옮기거나 Module 책임을 합쳐야 함 → 별도 Architecture 결정이므로 기존 승인 없이 확정 금지

Authority Reconciliation 중 미승인 Architecture·Authority 변경이 발견되면 문서를 조용히 맞춰버리지 말고 사용자에게 문제·대안·영향을 먼저 보고한다.

## 4. Authority Impact Scan

사용자 수용 직후 Codex는 Repository에서 **현재 효력이 있는 문서와 Source 전체**를 검색해 확정된 동작과 충돌하는 내용을 찾는다.

확인 순서:

```text
1. 사용자의 최신 확정 결정
2. Accepted ADR
3. Product / Architecture / System / Global UI Policy
4. Implementation Spec
5. GREENFIELD-SYSTEM-SEQUENCE / GREENFIELD-BUILD-POLICY
6. MODULE-CONTRACTS / module-contracts.json
7. CURRENT-WORK-ORDER / CODEX-ACTIVE-TASK
8. greenfield/src
9. greenfield/tests
10. 현재 User Guide·운영 문서
```

단순 파일명 검색만 하지 않는다. 변경된 개념, 입력 의미, 상태 이름, Authority owner, UX 흐름, Module 책임과 관련된 표현을 검색한다.

## 5. Top-down Reconciliation

충돌이 있으면 **상위 Authority부터 아래로** 수정한다.

```text
User Decision
→ ADR / Product / Architecture
→ Implementation Spec
→ System Sequence / Build Policy
→ Module Contract
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

## 7. Canonicalization Gate

사용자 수용 뒤 다음을 모두 끝내야 Checkpoint를 `ACCEPTED`로 바꿀 수 있다.

1. 확정된 사용자 동작을 한 문장으로 기록
2. Authority Impact Scan 완료
3. 충돌하는 현재 상위 문서 갱신 또는 Supersede
4. Module Contract 정합화
5. Studio 결과를 `greenfield/src` Canonical Source로 정규화
6. Rojo Mapping으로 재현 가능 상태 확인
7. 관련 Focused Test 추가·갱신
8. 현재 문서·Source 재검색으로 남은 충돌 없음 확인
9. 사용자 승인되지 않은 Architecture 변경 없음 확인
10. Checkpoint와 관련 Module을 `ACCEPTED`로 승격

하나라도 미완료면 다음 Checkpoint로 넘어가지 않는다.

## 8. Reconciliation Report

Codex는 확정 처리 시 짧게 다음을 보고한다.

```text
ACCEPTED BEHAVIOR
- 사용자가 최종 수용한 동작

AUTHORITY UPDATED
- 갱신한 Product / ADR / Architecture / Spec

SUPERSEDED
- 더 이상 현재 Authority가 아닌 문서

CANONICALIZED
- Module Contract / Source / Rojo Mapping

TESTED
- Focused Test

UNRESOLVED CONFLICTS
- none 또는 사용자 결정이 필요한 항목
```

`UNRESOLVED CONFLICTS`가 남아 있으면 `ACCEPTED` 처리하지 않는다.

## 9. 다음 Checkpoint Gate

다음 기능 착수 조건은 단순 사용자 만족이 아니다.

```text
사용자 수용
+ Authority Reconciliation 완료
+ Canonical Source 완료
+ Focused Test 완료
= ACCEPTED
```

그 후에만 다음 Checkpoint를 `IMPLEMENTING`으로 바꾼다.
