# PR #2 Studio Preflight Delta 001 Triage

- lead: `ChatGPT Lead Reviewer`
- sourceResultComment: `https://github.com/Kaetaeru/RVTT/pull/2#issuecomment-5208437045`
- sourceCommandId: `RVTT-PR2-STUDIO-PREFLIGHT-DELTA-001`
- sourceTargetSha: `91de98ba72a5a119135ff6de71df82fe0d99e569`
- sourceDisposition: `NEEDS_CORRECTION`
- runtimeCommandId: `RVTT-PR2-STUDIO-SMOKE-001`
- runtimeFixCommit: `23ce78ea7fe6a04242424ce9aa9d16f01d595bfa`
- runtimeExecutionStatus: `NOT_EXECUTED`
- mcpCapabilityHandshakeStatus: `NOT_EXECUTED`

## Finding 분류

### STUDIO-PREFLIGHT-003

```text
leadClassification: CONFIRMED_AND_RESOLVED
codexResolution: RESOLVED
requiredFollowUp: none
```

Core Play·Stop·Output Read의 Human 우회는 제거됐다.

### STUDIO-PREFLIGHT-004

```text
leadClassification: CONFIRMED_AND_RESOLVED
codexResolution: RESOLVED
requiredFollowUp: none
```

Runtime Evidence를 저장소 밖에 기록하고 Source-clean Predicate와 후속 Archive를 분리했다.

### STUDIO-PREFLIGHT-007

```text
leadClassification: CONFIRMED_AND_RESOLVED
codexResolution: RESOLVED
requiredFollowUp: none
```

Forbidden Log Allowlist는 exact 범위·횟수·승인 근거를 가진 구조화 Evidence로 제한됐다.

### STUDIO-PREFLIGHT-008

```text
leadClassification: CONFIRMED
severity: MEDIUM
category: capability
rootCause: MCP_AUTOMATED 분류만 검사하고 실제 Tool identity와 호출 Evidence를 조건부 필수로 요구하지 않음
```

Codex의 재현은 유효하다. `classification=MCP_AUTOMATED`만 기록하고 `actualToolName`과 호출 Evidence를 비워도 이전 A05를 통과할 수 있어, 연결되지 않은 Capability를 있다고 선언할 수 있었다.

## 적용한 최소 수정

`implementation/roblox/runtime-commands/PR-0002-STUDIO-SMOKE-001.md`만 수정했다.

1. 모든 `MCP_AUTOMATED` Mapping에 실제 노출 Tool과 정확히 일치하는 non-empty `actualToolName`을 조건부 필수화했다.
2. 모든 자동 Mapping에 `invocationEvidence[]`를 조건부 필수화했다.
3. 호출 Evidence에 `invocationId`, Tool 이름, 시작·종료 시각, 결과, 요청·응답 Summary와 `evidenceFiles[]`를 요구한다.
4. Core 최소 성공 호출 수를 고정했다.
   - Play Start 1회
   - Play Stop 1회
   - Output Read 2회: running + post-stop
5. 논리 Capability ID를 실제 Tool 이름처럼 복사하거나 일반 `available` 문자열만 기록한 Mapping을 거부한다.
6. F01 actualToolName 누락, F02 invocationEvidence 누락, F03 완전한 Mapping의 세 Fixture 판정을 정의했다.
7. Assertions, Stop Conditions와 Evidence Bundle에 Tool identity·호출 Evidence 검증을 연결했다.

## 검증 경계

이번 수정은 Runtime 계획 문서의 증거 계약만 변경했다.

```text
Roblox Studio: NOT EXECUTED
MCP Capability Handshake: NOT EXECUTED
Rojo Build: NOT EXECUTED
Play Solo: NOT EXECUTED
Human Playtest: NOT EXECUTED
Current-SHA Implementation Static Gate: UNVERIFIED
```

마지막 Delta 검수는 `STUDIO-PREFLIGHT-008`의 원래 재현이 차단됐는지와 새 문서 변경이 기존 003·004·007 해결을 회귀시키지 않았는지만 확인한다.
