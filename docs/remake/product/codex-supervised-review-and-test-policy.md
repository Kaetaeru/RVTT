# Codex 감독형 검수·테스트 정책

- 상태: 확정
- 문서 종류: Product·Engineering Process Policy
- 최종 갱신일: 2026-08-07
- 적용 대상: 기획, 구현명세, Production Source, Test, Acceptance, Pull Request
- 감독 책임: ChatGPT Lead Reviewer
- 독립 검수자: Codex Reviewer
- 최종 제품 결정: 사용자

## 1. 목적

RVTT 작업에서 Codex를 단순 코드 생성기나 자동 승인자로 사용하지 않는다.

Codex는 GitHub 저장소와 Pull Request를 독립적으로 조사하고 반례, 모순, 회귀, 누락과 검증 공백을 보고하는 검수자다. ChatGPT Lead Reviewer는 검수 범위와 명령문을 작성하고, Codex의 Finding을 상위 권위 문서와 실제 Evidence에 대조해 분류하며, 승인된 수정 작업만 후속 지시한다.

```text
사용자
→ 제품 결정·최종 수용

ChatGPT Lead Reviewer
→ 권위 해석·검수 명령·Finding 분류·수정 지시·최종 보고

Codex Reviewer
→ 독립 조사·반례·Finding·재현·최소 수정안

CI·Roblox Studio
→ 정적·Runtime Evidence
```

Codex Review 완료는 Pull Request PASS나 Roblox Runtime PASS를 의미하지 않는다.

## 2. 권위와 지휘 관계

권위 순서:

```text
사용자의 최신 명시적 결정
→ 확정 ADR
→ 확정 Product·Architecture·System·UI Policy
→ 준비 완료 Slice·Implementation Contract
→ Script Manifest
→ Production Source·Test
→ User Guide·HTML Reference
```

역할:

- 사용자는 제품 방향과 최종 수용 여부를 결정한다.
- ChatGPT Lead Reviewer는 Codex에 내릴 명령과 검수 범위를 작성한다.
- Codex는 명령 범위를 임의로 확대하거나 새 제품 결정을 확정하지 않는다.
- Codex는 Finding을 제출하지만 직접 PASS를 선언하지 않는다.
- Codex가 제안한 패치는 ChatGPT Lead Reviewer의 분류와 사용자 결정 없이 자동 적용하지 않는다.
- CI와 Roblox Studio Evidence는 에이전트의 의견보다 우선한다.

## 3. 언제 Codex 검수를 수행하는가

다음 Gate에는 Codex 검수를 포함한다.

1. 새 ADR 또는 Product Scope가 Slice에 연결될 때
2. Slice Contract가 Production Source·Manifest로 흡수될 때
3. 서버 권위, 저장, 마이그레이션, 권한, 공개 범위가 변경될 때
4. UI·입력·Projection 계약이 변경될 때
5. 새 Acceptance Batch 또는 Grand Campaign Phase를 실행하기 전
6. CI 실패 수정 후 동일 Root Cause 재검증 시
7. Draft PR을 Ready 또는 Merge 상태로 전환하기 전

단순 문구 수정, 오탈자, 링크 정정은 변경 위험이 낮고 권위 의미가 바뀌지 않으면 Codex 검수를 생략할 수 있다. 생략 이유는 완료 보고에 적는다.

## 4. Review Packet

Codex 명령문은 반드시 다음을 포함한다.

```text
Repository
Target PR 또는 Branch
Target Commit SHA
검수 역할 한 가지
권위 문서와 기준 파일
검수 범위
명시적 비범위
금지 사항
필수 출력 Schema
현재 실행된 Evidence
실행되지 않은 Evidence
```

Target SHA를 생략한 검수 결과는 변경 후 재사용하지 않는다.

Codex에는 현재 PR 전체를 막연하게 검수시키지 않는다. 다음 역할 중 하나를 명시한다.

- Authority Chain Reviewer
- Slice Ownership Reviewer
- Source·Security Reviewer
- Test·Acceptance Reviewer
- Evidence Claim Reviewer
- Performance·Leak Reviewer
- Migration·Recovery Reviewer
- Disclosure Reviewer

하나의 Review Task에 서로 독립적인 역할을 과도하게 섞지 않는다.

## 5. Codex 필수 출력

각 Finding은 다음 필드를 가진다.

```text
findingId
severity
category
claim
confidence
evidence
fileAndLine
reproductionOrReasoning
expectedAuthority
minimalCorrection
requiredTest
```

Severity:

```text
BLOCKER
HIGH
MEDIUM
LOW
```

Codex는 다음을 Finding으로 보고하지 않는다.

- 단순 문체 취향
- 근거 없는 대규모 리팩터링 권고
- 현재 PR 비범위의 기능 요구
- 의도적으로 QUEUED된 후속 Slice를 미완성 결함으로 단정
- 실행하지 않은 테스트의 추정 결과

## 6. Finding 분류

ChatGPT Lead Reviewer는 모든 Codex Finding을 다음 중 하나로 분류한다.

| 판정 | 의미 | 후속 조치 |
|---|---|---|
| `CONFIRMED` | 실제 결함·모순·누락 | 수정 및 재검수 |
| `VALID_RISK` | 결함 여부가 Runtime Evidence에 의존 | Acceptance·측정 추가 |
| `DESIGN_DECISION_REQUIRED` | 사용자 제품 결정 필요 | 사용자 결정 전 보류 |
| `INTENTIONALLY_QUEUED` | 단계적 후속 작업으로 이미 기록 | Queue와 Gate 확인 |
| `DUPLICATE` | 다른 Finding과 동일 Root Cause | 대표 Finding에 병합 |
| `FALSE_POSITIVE` | 권위 문서·코드·Evidence가 이미 처리 | 근거와 함께 기각 |
| `OUT_OF_SCOPE` | 현재 PR 범위 밖 | 별도 Backlog 여부 판단 |

Codex Finding을 분류하지 않은 채 PR을 병합하지 않는다. `LOW` Finding은 명시적으로 Deferred할 수 있지만 이유와 Owner를 기록한다.

## 7. 수정 지시

`CONFIRMED` Finding의 수정은 다음 방식으로 지시한다.

```text
Finding ID
→ 변경해야 할 권위 계층
→ 허용 파일 범위
→ 변경 금지 범위
→ 최소 수정 목표
→ 요구 Test
→ 완료 Evidence
```

Codex Fixer에게 여러 Root Cause를 한 번에 맡기지 않는다. 패치 후에는 최초 Review Packet과 같은 Target 범위로 Delta Review를 수행한다.

Codex가 자신의 패치를 단독 승인하지 않는다. 구현 Task와 Review Task는 가능하면 별도 Codex 작업으로 분리한다.

## 8. 테스트 흐름

앞으로 테스트 작업에는 다음 단계가 포함된다.

```text
구현·문서 변경
→ ChatGPT가 Codex Review Command 작성
→ Codex 독립 검수
→ ChatGPT Finding 분류
→ CONFIRMED 수정
→ 자동 CI
→ Codex Delta Review
→ Batch Acceptance 준비
→ Roblox Studio·Human Evidence
→ 최종 판정
```

Codex가 실행할 수 있는 정적·Unit·Integration 테스트는 명령문에 명시한다. Roblox Studio Human Input, 실제 다중 Client, DataStore와 시각적 Acceptance는 Codex 보고만으로 대체하지 않는다.

## 9. Evidence 경계

다음은 서로 다른 Evidence다.

```text
문서 링크 검사
Schema 검사
Formatter·Lint·Type 검사
Rojo Build
Unit·Integration Test
Codex Review
Roblox Studio Runtime
Human Input Acceptance
Multi-client Acceptance
Persistence Acceptance
Performance·Soak
```

한 단계 성공을 다른 단계 성공으로 확대 해석하지 않는다.

Codex는 현재 SHA에 연결된 Artifact만 근거로 사용한다. 과거 Commit의 Studio 로그는 현재 변경이 해당 경로를 수정하지 않았다는 명시적 영향 분석 없이 재사용하지 않는다.

## 10. PR 기록

Codex 검수를 수행한 PR에는 다음을 기록한다.

```text
Codex Review Command
Target SHA
Reviewer Role
Finding Summary
Finding Triage
Applied Fix Commit
Delta Review Result
Unresolved Risk
Runtime Evidence Status
```

명령문과 결과는 PR 댓글, Review Summary 또는 저장소의 Review Artifact로 남긴다. 비밀 정보, Private Content 본문, Credential과 사용자 저장 데이터는 명령문에 포함하지 않는다.

## 11. Merge Gate

다음 조건을 모두 만족해야 Codex 검수 Gate를 통과한다.

1. 요구된 Review Role이 현재 HEAD를 검수했다.
2. 모든 Finding이 분류됐다.
3. `CONFIRMED` BLOCKER·HIGH Finding이 해결됐다.
4. 수정 후 Delta Review가 수행됐다.
5. 자동 CI가 현재 HEAD에서 통과했다.
6. Runtime을 주장하는 경우 해당 Runtime Evidence가 존재한다.
7. 사용자 결정이 필요한 항목을 에이전트가 임의 확정하지 않았다.
8. 남은 Risk·Deferred 항목이 PR에 기록됐다.

Codex 응답이 없거나 GitHub 접근이 실패하면 검수를 성공으로 간주하지 않는다. 해당 Gate를 `BLOCKED_CODEX_REVIEW_UNAVAILABLE`로 기록하거나 사용자가 명시적으로 면제해야 한다.

## 12. 기본 검수 세트

일반적인 중간 PR:

```text
Authority·Slice Reviewer 1회
Source·Test Reviewer 1회
수정 후 Delta Reviewer 1회
```

Release·Persistence·권한·대규모 Migration PR:

```text
Authority Chain
Slice Ownership
Security·Disclosure
Migration·Recovery
Test·Evidence
Performance·Soak
```

Review 수를 늘리는 것보다 역할 중복을 줄이고 각 Finding의 근거 품질을 높이는 것을 우선한다.

## 13. 비목표

- Codex가 사용자 대신 제품 결정을 내리는 구조
- Codex Review 수만으로 품질을 증명
- 모든 작은 Commit마다 과도한 다중 Reviewer 실행
- Codex가 만든 패치를 Codex가 단독 승인
- PR 댓글을 Authority 문서 대신 사용하는 방식
- Runtime Evidence를 정적 분석으로 대체
