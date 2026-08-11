# Codex Studio 구현·검수 정책

- 상태: `확정`
- 문서 종류: Product·Engineering Process Policy
- 최종 갱신일: 2026-08-12
- 최종 제품 결정: 사용자
- 구현 환경: GitHub + Roblox Studio MCP

## 1. 목적

RVTT에서 Codex를 단순 코드 생성기나 자동 승인자로 사용하지 않는다. Codex는 작업 종류에 따라 **Studio Implementer**, **Fixer**, **Reviewer** 역할을 수행한다.

기본 개발 방향은 다음과 같다.

```text
GitHub Product·Architecture 조사
→ Module Contract에서 안정 책임·의존·Authority 확인
→ 현재 Source와 실제 함수·require 관계 조사
→ Roblox Studio MCP로 실제 구현
→ Play·관찰·즉시 수정
→ 사용자 판단이 필요한 부분 확인
→ 확정 결과를 GitHub Source·필요한 Module Contract로 정규화
→ 자동 회귀 검증
→ Stabilization·Merge·Release에서 독립 Review
```

GitHub는 영구 Source of Truth이고 Studio는 실제 작업장이다.

Module Contract 규칙은 `implementation/roblox/MODULE-CONTRACTS.md`와 `implementation/roblox/manifests/module-contracts.json`이 소유한다. 이 Registry는 Product 결정을 만들지 않고 Contract-bearing Production Module의 안정적인 코드 경계만 기록한다.

## 2. 역할

### 사용자

- 제품 방향과 최종 수용을 결정한다.
- 새로운 방향, 범위, 우선순위, Architecture 변경을 승인하거나 거부한다.
- 실제 조작 감각, 가독성, DM 부담, 재미처럼 Human Judgment가 필요한 항목을 판단한다.

### ChatGPT

- 현재 Authority와 GitHub 상태를 해석한다.
- 필요한 경우 Work Order, 문서, Codex Task를 정리한다.
- Codex Finding과 Runtime 결과를 제품 Authority에 대조한다.
- 사용자 결정이 필요한 변경을 사용자에게 올린다.

### Codex Studio Implementer

- 구현 시작 전 관련 GitHub Product·ADR·Spec, Module Contract, 현재 Source, Remote, Schema, Test를 읽는다.
- Registry의 `dependsOn`을 모든 `require()` 목록으로 착각하지 않고 실제 함수·호출 관계는 현재 Source에서 확인한다.
- MCP로 현재 Studio Place와 Instance Tree를 조사한다.
- 기존 Source 책임을 이해한 뒤 Studio에서 실제 UI·Instance·Script 연결을 만든다.
- Play를 반복하면서 Output, Instance 상태, 화면과 동작을 확인하고 즉시 수정한다.
- 만족한 Production 변경을 GitHub Source·Rojo Project에서 재현할 수 있게 정규화한다.
- 안정적인 Module 책임, Entry Point, Contract-level dependency, Authority 또는 State ownership이 바뀌면 Module Contract도 갱신한다.
- private/helper 함수만 바뀌었다면 수동 Call Graph 문서를 만들지 않는다.
- 사용자 결정이 필요한 새로운 방향을 발견하면 적용하지 않고 보고한다.

### Codex Reviewer

- 구현자와 별도의 검수 역할이 필요할 때 Authority 위반, Module Contract drift, Security·Disclosure, Persistence, Migration, 회귀, Evidence 과장을 검사한다.
- 직접 PASS·Merge를 결정하지 않는다.

## 3. Codex 작업 모드

```text
STUDIO_IMPLEMENTATION
FOCUSED_FIX
REVIEW
POST_RUNTIME_REVIEW
```

### STUDIO_IMPLEMENTATION

기본 개발 모드다. 매 반복마다 별도 Review Command나 PR 댓글을 요구하지 않는다.

필수 순서:

1. 현재 Branch·PR·HEAD 확인
2. 관련 Product·ADR·Spec Authority 확인
3. 관련 Module Contract Entry 확인
4. 현재 Source와 실제 함수·require 관계 조사
5. Studio MCP Capability 확인
6. 현재 Place·Instance Tree 조사
7. 작은 사용자 흐름 하나 구현
8. Play·관찰·수정 반복
9. 사용자 판단 필요 항목 보고
10. 결과를 GitHub Source와 필요한 Module Contract로 정규화
11. 관련 Focused Test와 Module Contract Validator 실행

### FOCUSED_FIX

재현된 결함을 좁은 범위에서 수정한다. 제품 의미를 넓히지 않는다.

### REVIEW

다음과 같은 Stabilization·고위험 변경에서 사용한다.

- Accepted ADR 또는 Product Authority 변경
- Contract-bearing Module 분리·통합 또는 Authority·State ownership 변경
- 서버 Authority·Security·Disclosure 변경
- Persistence·Migration·Rollback 변경
- 공개 Schema·Package 계약 변경
- Merge·Release 후보
- 사용자가 독립 검수를 요청한 경우

### POST_RUNTIME_REVIEW

Runtime Evidence가 실제 주장과 일치하는지 확인할 필요가 있을 때 사용한다. 모든 개발 Play 뒤에 의무적으로 수행하지 않는다.

## 4. GitHub-first 조사 규칙

Codex는 Studio에서 새 구조를 만들기 전에 GitHub의 기존 구조를 먼저 읽는다.

최소 조사 범위:

- 관련 Product·ADR·UI·Spec
- 현재 Work Order
- `implementation/roblox/MODULE-CONTRACTS.md`
- `implementation/roblox/manifests/module-contracts.json`의 관련 Entry와 직접 의존 Entry
- 대상 Production Source와 현재 함수·실제 `require()` 관계
- Server Command·Authorization·Projection
- 관련 Schema·Registry·Stable ID
- 기존 Unit·Integration·Runtime Test

같은 책임의 Module이나 함수를 찾았으면 가능한 한 재사용한다. 파일명이나 API를 추측해 병렬 구현을 만들지 않는다.

Module Contract와 Source가 어긋나면 한쪽을 임의로 정답 처리하지 않고 `CONTRACT_DRIFT`로 보고한다. 상위 Product·Architecture 의도를 확인한 뒤 Source와 Contract를 함께 정리한다.

## 5. Studio MCP 구현 규칙

MCP로 가능한 경우 Studio에서 직접 다음을 수행한다.

- Instance Tree 조사
- Script Source와 연결 상태 확인
- UI·Model·Folder·Attribute 등 실제 Instance 구성
- Production Script 연결과 수정
- Play Solo 또는 필요한 Runtime 실행
- Output·Error·State 확인
- Screenshot·Instance 상태 확인
- 반복 수정

MCP Capability가 없으면 가능한 척하지 않는다. 해당 작업만 로컬 Source/Rojo 또는 Human Action으로 분리한다.

Studio에서 만든 Production 변경은 작업 종료 전에 Repository Source와 Project Mapping으로 환원한다. Studio 파일에만 남는 숨은 Production 변경을 허용하지 않는다.

private/helper 함수 분해는 현재 구현에 맞게 Codex가 판단할 수 있다. 다만 Module Contract가 소유하는 안정 경계를 바꾸는 경우는 단순 내부 Refactor로 숨기지 않는다.

## 6. Rojo의 역할

Rojo는 다음을 담당한다.

- GitHub Source와 Roblox DataModel Mapping
- Studio와 Source의 동기화 지원
- Clean Source에서 재현 가능한 Place Build
- CI용 구조 검증

Rojo Build는 매 작은 UI 조정이나 Play 전에 통과해야 하는 Gate가 아니다. 기능이 안정되거나 GitHub에 정규화할 때 재현성을 확인한다.

## 7. 사용자 결정 보호

Codex, ChatGPT 또는 다른 에이전트가 현재 방향보다 낫다고 판단한 아이디어가 다음을 바꾸면 자동 적용하지 않는다.

- 제품 목표·비목표
- Accepted ADR
- 핵심 UX·입력 문법
- Authority·Data ownership
- Architecture
- Contract-bearing Module의 실질적인 책임 분리·통합
- 개발 프로세스
- Release 범위·우선순위

현재 문제와 제안 방향, 장단점, 영향받는 Authority·Module·Source 범위를 사용자에게 먼저 보고한다.

## 8. Active Task

`.github/CODEX-ACTIVE-TASK.md`는 긴 구현 작업이나 Review의 단일 포인터로 사용할 수 있다. 모든 작은 Studio 반복에 필수는 아니다.

Active Task가 존재하면 최소 다음을 가진다.

```text
status
repository
pullRequest
branch
taskMode
scope
commandPath 또는 inlineGoal
targetMode
```

`targetMode` 기본값은 `CURRENT_PR_HEAD_AT_START`다.

**Active Task가 가리키지 않는 과거 `.github/CODEX-*` Command는 현재 지시가 아니다.** 과거 PR 댓글과 Audit도 역사적 Evidence로만 사용한다.

## 9. Review 결과

독립 Review를 수행할 때 결과는 PR Top-level Comment에 남길 수 있다.

기본 Marker:

```text
<!-- RVTT_CODEX_REVIEW_RESULT -->
```

각 Finding은 최소 다음을 포함한다.

```text
findingId
severity
claim
evidence
minimalCorrection
requiredTest
```

Finding 분류:

```text
CONFIRMED
VALID_RISK
CONTRACT_DRIFT
DESIGN_DECISION_REQUIRED
INTENTIONALLY_QUEUED
DUPLICATE
FALSE_POSITIVE
OUT_OF_SCOPE
```

`DESIGN_DECISION_REQUIRED`는 사용자 결정 전 자동 수정하지 않는다.

`CONTRACT_DRIFT`는 현재 Source와 Module Contract가 일치하지 않는 상태다. Product 방향 변경이 필요하지 않으면 실제 의도에 맞춰 둘을 함께 고치고, Architecture 변경이 필요하면 사용자 결정을 먼저 받는다.

## 10. Test·Evidence 경계

서로 다른 Evidence를 섞지 않는다.

```text
Development Play Observation
Module Contract Structural Validation
Static·Lint·Type
Unit·Integration
Studio Stabilization Runtime
Human UI·UX
Multi-client
Persistence·Migration
Performance·Soak
Release Acceptance
```

Module Contract PASS는 Source 경로·Coverage·Contract-level dependency·Test Ref·Stable Entry Point의 구조적 일치만 의미한다. Runtime 또는 UX PASS를 의미하지 않는다.

개발 중 빠른 Play는 매우 중요하지만 Release PASS를 의미하지 않는다. 반대로 Release 수준 Evidence가 준비되지 않았다는 이유로 초기 UX 반복을 막지 않는다.

정확한 SHA 고정과 Evidence Bundle은 Stabilization, Review, Merge, Release처럼 재현성이 필요한 시점에 사용한다.

## 11. Merge·Release

Merge·Release 후보에서는 변경 위험에 맞는 검수와 Evidence를 수행한다.

필수 범위는 변경 내용에 따라 다르지만 다음 경계는 생략하지 않는다.

- 자동 CI와 Module Contract Validator
- Server Authority·Security·Disclosure
- 필요한 Runtime
- Persistence·Migration 영향이 있으면 해당 검증
- Multi-client 영향이 있으면 해당 검증
- 사용자에게 보이는 UI·조작 변경이면 필요한 Human 확인
- 미해결 Contract Drift·Risk 기록

Codex는 사용자 요청 없이 PR을 Ready, Merge 또는 Force Push하지 않는다.
