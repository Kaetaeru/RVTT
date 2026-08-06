# Codex 감독형 검수·테스트 정책

- 상태: 확정
- 문서 종류: Product·Engineering Process Policy
- 최종 갱신일: 2026-08-07
- 적용 대상: 기획, 구현명세, Production Source, Test, Acceptance, Pull Request, Playtest
- 감독 책임: ChatGPT Lead Reviewer
- 독립 검수자: Codex Reviewer
- Runtime 실행자: Roblox Studio·연결된 MCP
- 최종 제품 결정: 사용자

## 1. 목적

RVTT 작업에서 Codex를 단순 코드 생성기나 자동 승인자로 사용하지 않는다.

Codex는 GitHub 저장소와 Pull Request를 독립적으로 조사하고 반례, 모순, 회귀, 누락과 검증 공백을 보고하는 검수자다. ChatGPT Lead Reviewer는 검수 범위와 상세 명령문을 저장소에 작성하고, Codex의 Finding을 상위 권위 문서와 실제 Evidence에 대조해 분류하며, 승인된 수정 작업만 후속 지시한다.

사용자는 긴 Review Prompt를 전달하는 중계자가 아니다. 기본 운영에서는 사용자가 Codex에 짧은 실행 지시만 보내고, Codex가 저장소의 활성 작업 포인터에서 ChatGPT 명령을 찾아 수행한 뒤 해당 PR 댓글에 결과를 남긴다.

```text
사용자
→ 제품 결정·최종 수용
→ Codex에 활성 ChatGPT 명령 실행 지시
→ ChatGPT에 Codex 피드백 확인 지시

ChatGPT Lead Reviewer
→ 권위 해석
→ 저장소에 상세 검수·테스트 명령 작성
→ 활성 작업 포인터 갱신
→ PR 댓글의 Finding 수집·분류
→ 수정·재검수 지시
→ 최종 보고

Codex Reviewer
→ 활성 작업 포인터 발견
→ 정확한 PR HEAD 확인
→ 독립 조사·반례·Finding·재현
→ 결과를 해당 PR 댓글로 게시

CI
→ 정적·자동 Evidence

Roblox Studio·MCP
→ Runtime 준비·실행·로그·Screenshot·상태 Evidence

Human Playtester
→ 실제 입력·가독성·진행 감각·주관적 품질 확인
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
- ChatGPT Lead Reviewer는 Codex에 내릴 상세 명령, 검수 범위와 Acceptance 명령을 저장소에 작성한다.
- 사용자는 Codex에 저장소의 활성 ChatGPT 명령을 확인해 실행하라고 지시한다.
- Codex는 명령 범위를 임의로 확대하거나 새 제품 결정을 확정하지 않는다.
- Codex는 Finding을 PR 댓글로 제출하지만 직접 PASS·Ready·Merge를 선언하지 않는다.
- Codex가 제안한 패치는 ChatGPT Lead Reviewer의 분류와 사용자 결정 없이 자동 적용하지 않는다.
- CI와 Roblox Studio Evidence는 에이전트의 의견보다 우선한다.
- MCP는 연결 시점에 실제 노출된 Tool과 Capability만 사용하며, 제공되지 않은 Studio 제어 능력을 있다고 가정하지 않는다.

## 3. 기본 운영 프로토콜

### 3.1 저장소의 활성 작업 포인터

Codex가 상세 명령을 자동 발견할 수 있도록 다음 파일을 단일 진입점으로 사용한다.

```text
.github/CODEX-ACTIVE-TASK.md
```

이 파일은 최소 다음을 가진다.

```text
status
commandId
repository
pullRequest
reviewPhase
commandPath
targetMode
expectedOutputChannel
resultMarker
```

`targetMode`의 기본값은 `CURRENT_PR_HEAD_AT_START`다. 같은 Commit에 자기 자신의 Commit SHA를 기록할 수 없으므로 Codex는 작업 시작 직전에 PR HEAD를 조회해 정확한 40자 SHA를 확정하고 결과 댓글에 기록한다.

Codex는 검수 종료 직전 PR HEAD를 다시 확인한다. 시작 SHA와 다르면 현재 결과를 Merge Gate Evidence로 제출하지 않고 `STALE_TARGET`을 댓글에 기록한다.

### 3.2 사용자의 기본 Codex 지시

사용자가 Codex에 전달해야 하는 기본 문장은 다음 의미면 충분하다.

```text
RVTT 저장소의 .github/CODEX-ACTIVE-TASK.md에서
ChatGPT가 작성한 활성 명령을 확인해 실행하고,
결과를 지정된 Pull Request 댓글로 남겨.
```

사용자는 전체 Review Packet을 복사하지 않는다. 상세 Prompt, 파일 범위, 출력 Schema와 금지 사항은 `commandPath` 문서가 소유한다.

### 3.3 Codex 결과 채널

기본 결과 채널은 활성 작업에 지정된 Pull Request의 Top-level Conversation Comment다. 인라인 파일 위치가 필요한 Finding은 Review Comment를 함께 사용할 수 있지만, 전체 결과 Summary는 반드시 Top-level 댓글에도 남긴다.

결과 댓글은 다음 Marker로 시작한다.

```text
<!-- RVTT_CODEX_REVIEW_RESULT -->
```

필수 Header:

```text
commandId
targetSha
reviewPhase
reviewerRole
resultStatus
```

`resultStatus`:

```text
FINDINGS_REPORTED
NO_SUPPORTED_FINDINGS
STALE_TARGET
BLOCKED
```

Codex는 댓글 게시 후 파일을 수정하거나 PR을 승인·병합하지 않는다. Fix Mode가 별도 활성 작업으로 지정된 경우에만 허용 파일을 변경한다.

### 3.4 ChatGPT의 피드백 확인

사용자가 “Codex 피드백을 확인해”라고 지시하면 ChatGPT Lead Reviewer는 다음을 수행한다.

1. 현재 PR 번호와 HEAD SHA를 확인한다.
2. PR Top-level 댓글, Review Summary와 Inline Thread를 읽는다.
3. `RVTT_CODEX_REVIEW_RESULT` Marker와 `commandId`가 현재 활성 작업과 일치하는지 확인한다.
4. `targetSha`가 현재 HEAD와 일치하는 결과만 현재 검수 결과로 사용한다.
5. Finding을 `CONFIRMED`, `VALID_RISK`, `DESIGN_DECISION_REQUIRED`, `INTENTIONALLY_QUEUED`, `DUPLICATE`, `FALSE_POSITIVE`, `OUT_OF_SCOPE`로 분류한다.
6. 필요한 수정과 Delta Review 명령을 저장소에 작성한다.

과거 SHA, 다른 Command ID, 복사된 Summary 또는 Marker 없는 댓글은 참고 자료일 수 있지만 현재 Merge Gate를 충족하지 않는다.

## 4. 예외 전달 방식

GitHub 댓글 게시가 불가능하거나 Codex 연동이 일시적으로 실패하면 사용자가 Codex Prompt Chat 결과를 ChatGPT에 전달할 수 있다.

이 경우 반드시 다음을 검수 Artifact에 기록한다.

```text
feedbackChannel: prompt_chat_forwarded_by_user
targetSha
원문 Finding
전달 시각
Lead Triage
```

이 방식은 유효한 임시 Review Input이지만 기본 운영은 아니다. GitHub 댓글 연동이 복구되면 이후 Delta Review부터 PR 댓글 방식을 사용한다.

## 5. 언제 Codex 검수를 수행하는가

다음 Gate에는 Codex 검수를 포함한다.

1. 새 ADR 또는 Product Scope가 Slice에 연결될 때
2. Slice Contract가 Production Source·Manifest로 흡수될 때
3. 서버 권위, 저장, 마이그레이션, 권한, 공개 범위가 변경될 때
4. UI·입력·Projection 계약이 변경될 때
5. 새 Acceptance Batch 또는 Grand Campaign Phase를 실행하기 전
6. CI 실패 수정 후 동일 Root Cause 재검증 시
7. Roblox Studio MCP Runtime Batch를 실행하기 전과 후
8. Human Playtest Batch를 시작하기 전과 결과 정리 후
9. Draft PR을 Ready 또는 Merge 상태로 전환하기 전

단순 문구 수정, 오탈자, 링크 정정은 변경 위험이 낮고 권위 의미가 바뀌지 않으면 Codex 검수를 생략할 수 있다. 생략 이유는 완료 보고에 적는다.

## 6. Review Packet

Codex 상세 명령문은 반드시 다음을 포함한다.

```text
commandId
Repository
Target PR 또는 Branch
Target Mode 또는 Target Commit SHA
검수 역할 한 가지
권위 문서와 기준 파일
검수 범위
명시적 비범위
금지 사항
필수 출력 Schema
현재 실행된 Evidence
실행되지 않은 Evidence
결과를 남길 PR과 Marker
```

Codex는 작업 시작 시 정확한 Target SHA를 댓글에 기록한다. Target SHA가 없는 검수 결과는 변경 후 재사용하지 않는다.

Codex에는 현재 PR 전체를 막연하게 검수시키지 않는다. 다음 역할 중 하나를 명시한다.

- Authority Chain Reviewer
- Slice Ownership Reviewer
- Source·Security Reviewer
- Test·Acceptance Reviewer
- Evidence Claim Reviewer
- Performance·Leak Reviewer
- Migration·Recovery Reviewer
- Disclosure Reviewer
- Studio Runtime Preflight Reviewer
- Playtest Scenario Reviewer
- Post-runtime Evidence Reviewer

하나의 Review Task에 서로 독립적인 역할을 과도하게 섞지 않는다.

## 7. Codex 필수 출력

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

## 8. Finding 분류

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

## 9. 수정 지시

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

## 10. 정적 검수와 Runtime 검수 흐름

### 10.1 일반 구현·문서 변경

```text
구현·문서 변경
→ ChatGPT가 상세 Review Command 작성
→ CODEX-ACTIVE-TASK 갱신
→ 사용자가 Codex에 활성 명령 실행 지시
→ Codex가 PR 댓글로 Finding 게시
→ 사용자가 ChatGPT에 피드백 확인 지시
→ ChatGPT Finding 분류
→ CONFIRMED 수정
→ 자동 CI
→ Codex Delta Review
→ Runtime Gate 준비
```

### 10.2 Roblox Studio MCP Runtime

Roblox Studio와 MCP가 연결된 경우 다음 순서를 사용한다.

```text
ChatGPT Runtime Test Command
→ Codex Studio Preflight Review 댓글
→ ChatGPT Triage
→ Studio MCP Capability Handshake
→ 정확한 Branch·HEAD·Project Build 확인
→ MCP가 자동화 가능한 Setup·실행·로그 수집
→ Human Input이 필요한 단계는 사용자 수행
→ Evidence Bundle 저장
→ Codex Post-runtime Evidence Review 댓글
→ ChatGPT 최종 분류
```

Studio MCP 명령에는 최소 다음을 포함한다.

```text
commandId
targetSha
requiredMcpCapabilities
projectFile
placeOrSessionMode
clientRoles
setupSteps
automatedActions
humanActions
expectedLogTokens
failureTokens
screenshotsOrStateCaptures
evidenceOutputPath
cleanupSteps
```

MCP가 요구 Capability를 제공하지 않으면 테스트를 흉내 내지 않고 `BLOCKED_MCP_CAPABILITY_UNAVAILABLE`로 기록한다. MCP가 연결되지 않은 ChatGPT 세션에서는 Studio 실행을 완료했다고 주장하지 않는다.

### 10.3 Playtest

Playtest도 동일한 감독 루프를 사용한다.

```text
ChatGPT Playtest Command·Scenario 작성
→ Codex가 Scenario·Instrumentation·Failure Coverage 검수
→ ChatGPT Triage
→ Studio MCP가 재현 가능한 Campaign·Role·Save 상태 준비
→ Human Playtester가 실제 입력과 판단 수행
→ MCP가 로그·Screenshot·State Snapshot 수집
→ Codex가 Playtest Evidence와 Report의 모순 검수
→ ChatGPT가 버그·UX Risk·제품 결정 필요 항목 분류
```

Human Playtest에서 Codex나 MCP가 대체할 수 없는 항목:

- 실제 조작 감각
- 정보 계층의 이해 가능성
- DM 진행 부담
- 전투·탐험 흐름의 리듬
- 시각적 피로와 가독성
- 재미와 주관적 만족도

Codex는 Playtest Report의 누락, Evidence 불일치, 재현 절차와 권위 위반을 검수한다.

## 11. Evidence 경계

다음은 서로 다른 Evidence다.

```text
문서 링크 검사
Schema 검사
Formatter·Lint·Type 검사
Rojo Build
Unit·Integration Test
Codex Review
Roblox Studio MCP Runtime
Human Input Acceptance
Multi-client Acceptance
Persistence Acceptance
Performance·Soak
Playtest Qualitative Evidence
```

한 단계 성공을 다른 단계 성공으로 확대 해석하지 않는다.

Codex는 현재 SHA에 연결된 Artifact만 근거로 사용한다. 과거 Commit의 Studio 로그는 현재 변경이 해당 경로를 수정하지 않았다는 명시적 영향 분석 없이 재사용하지 않는다.

## 12. PR 기록

Codex 검수를 수행한 PR에는 다음을 기록한다.

```text
Active Command ID·Path
Resolved Target SHA
Reviewer Role
PR Result Comment URL 또는 Comment ID
Finding Summary
Finding Triage
Applied Fix Commit
Delta Review Result
Unresolved Risk
CI Evidence Status
Studio MCP Evidence Status
Human Playtest Evidence Status
```

명령문과 결과는 저장소의 Review Artifact와 PR 댓글에 남긴다. PR 댓글은 Finding 전달 채널이며 Authority 문서를 대체하지 않는다. 비밀 정보, Private Content 본문, Credential과 사용자 저장 데이터는 명령문이나 댓글에 포함하지 않는다.

## 13. Merge Gate

다음 조건을 모두 만족해야 Codex 검수 Gate를 통과한다.

1. 활성 Command가 현재 PR을 가리킨다.
2. 요구된 Review Role이 작업 시작 시 확정한 Target SHA를 검수했다.
3. 검수 종료 시 PR HEAD가 바뀌지 않았다.
4. 현재 Command ID와 Target SHA를 가진 Result 댓글이 존재한다.
5. 모든 Finding이 분류됐다.
6. `CONFIRMED` BLOCKER·HIGH Finding이 해결됐다.
7. 수정 후 Delta Review가 수행됐다.
8. 자동 CI가 현재 HEAD에서 통과했다.
9. Runtime을 주장하는 경우 해당 Studio MCP 또는 Human Runtime Evidence가 존재한다.
10. 사용자 결정이 필요한 항목을 에이전트가 임의 확정하지 않았다.
11. 남은 Risk·Deferred 항목이 PR에 기록됐다.

Codex 응답이 없거나 GitHub 댓글 게시가 실패하면 검수를 성공으로 간주하지 않는다. 해당 Gate를 `BLOCKED_CODEX_REVIEW_UNAVAILABLE`로 기록하거나 사용자가 명시적으로 면제해야 한다.

Studio MCP가 필요한 Gate에서 연결·Capability가 없으면 `BLOCKED_MCP_RUNTIME_UNAVAILABLE` 또는 `BLOCKED_MCP_CAPABILITY_UNAVAILABLE`로 기록한다. 정적 PASS로 대체하지 않는다.

## 14. 기본 검수 세트

일반적인 중간 PR:

```text
Authority·Slice Reviewer 1회
Source·Test Reviewer 1회
수정 후 Delta Reviewer 1회
```

Studio Runtime Batch:

```text
Studio Runtime Preflight Reviewer
Studio MCP·Human Execution
Post-runtime Evidence Reviewer
```

Playtest Batch:

```text
Playtest Scenario Reviewer
Studio MCP Setup·Evidence Capture
Human Playtest
Post-playtest Evidence Reviewer
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

## 15. 비목표

- 사용자가 긴 Codex Review Prompt를 반복 복사하는 구조
- Codex가 사용자 대신 제품 결정을 내리는 구조
- Codex Review 수만으로 품질을 증명
- 모든 작은 Commit마다 과도한 다중 Reviewer 실행
- Codex가 만든 패치를 Codex가 단독 승인
- PR 댓글을 Authority 문서 대신 사용하는 방식
- Runtime Evidence를 정적 분석으로 대체
- MCP Capability를 확인하지 않고 Roblox Studio 실행을 주장하는 방식
- Codex나 MCP가 Human Playtest의 주관적 판단을 대체하는 방식
