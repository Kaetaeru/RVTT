# 구현 명세

- 상태: ACTIVE
- 문서 종류: Implementation Spec Index
- 현재 단계: `IN_PROGRESS`
- 현재 Slice: `01 FIRST SESSION WALKING SKELETON`
- 전체 Slice 수: `16`
- 다음 Slice: `02 CORE RULES KERNEL`

확정된 사용자 경험과 권위 문서를 실제 Module, Type, Command, Network, Persistence, Migration, Diagnostics와 Test 계약으로 변환한다.

## 핵심 진입점

- 전체 16개 Slice: [`SLICE-ROADMAP.md`](SLICE-ROADMAP.md)
- 현재 Slice 세부 작업: [`CURRENT-SPEC-WORK-ORDER.md`](CURRENT-SPEC-WORK-ORDER.md)
- Slice Roadmap 완전성 감사: [`implementation-slice-roadmap-completeness-audit.md`](../audits/implementation-slice-roadmap-completeness-audit.md)
- 상위 작업 순서: [`../CURRENT-WORK-ORDER.md`](../CURRENT-WORK-ORDER.md)
- Implementation Spec Template: [`../templates/implementation-spec-template.md`](../templates/implementation-spec-template.md)
- Quick Flow: [`../user-guides/QUICK-FLOW.md`](../user-guides/QUICK-FLOW.md)
- Main System Guide Hub: [`../guides/README.md`](../guides/README.md)

## 전체 Slice

```text
01 First Session Walking Skeleton
02 Core Rules Kernel
03 Exploration Interaction·Perception
04 Encounter Core Loop
05 Character Foundation·Creation
06 Inventory·Equipment·World Items
07 Rest·Time·Downtime·Progression
08 Player UI·Camera·Presentation
09 Journal·Ping·Knowledge Navigation
10 Scene Authoring·Compile·Publish
11 Live DM Workspace·Quick Actions·Recovery
12 Content Pack·Localization·Trusted Extension Platform
13 Official 2024 Character Options Content
14 Official 2024 Spell·Equipment·Rules Content
15 NPC·Monster·Campaign Authored Content
16 Full-session Integration·Release Hardening
```

각 Slice의 사용자 결과, 범위, 비범위, 의존 관계와 Guide 배정은 [`SLICE-ROADMAP.md`](SLICE-ROADMAP.md)를 단일 기준으로 사용한다.

## 현재 작업

```text
Slice 01 First Session Walking Skeleton
→ runtime/001 Core Authority Identity·Version·Result
```

현재 `runtime/001`은 계약 초안이 작성됐지만 실제 Production Source Tree가 확인되지 않아 `초안·BLOCKED` 상태를 유지한다. Module 경로를 추측해 확정하지 않는다.

### Slice 01 흐름

```text
세션 참가
→ Character 선택
→ Ready
→ Scene Entry Essential
→ Token 선택
→ 클릭 이동
→ 위치 Commit·Projection
→ Disconnect
→ Reconnect·Resync
```

### Slice 01 명세 순서

```text
Core Identity·Version·Result
→ Command·Projection Protocol
→ Campaign Join·Character Selection·Ready
→ Scene Entry Essential·Controlled Actor Bootstrap
→ Click Movement·Position Projection
→ Snapshot·Journal·Reconnect
→ Deterministic·Roblox Integration
→ Slice Completion Audit
```

## Spec 작성 전 읽기 순서

```text
CURRENT-SPEC-WORK-ORDER
→ SLICE-ROADMAP의 현재 Slice
→ Quick Flow 대상 구간
→ Player·DM User Guide
→ Runtime Foundation Guide
→ Domain Main System Guide
→ 직접 Authority Documents
→ 기존 Spec·Audit
→ 실제 Code·Schema·Test 조사
→ Implementation Spec Template
```

## 문서 역할

```text
Quick Flow·User Guide
→ Acceptance Flow

Main System Guide
→ Authority 탐색 경로

Product·Architecture·System·UI·ADR
→ 직접 구현 근거

Implementation Spec
→ Code·Schema·Network·Persistence·Test 계약
```

User Guide와 Main System Guide를 Type·Schema·Command의 권위 원본으로 사용하지 않는다.

## 준비 완료 Gate

Spec은 다음 조건을 모두 만족할 때만 `준비 완료`로 전환한다.

- 관련 Authority가 `READY` 또는 허용된 `READY_WITH_DEFAULTS`
- Player·DM Acceptance Flow 연결
- 실제 Code·Schema·Test 조사 기록
- 책임·입출력·권한·실패·복구 경계 명시
- Source·Build·State·Projection·Presentation 분리
- Client Intent와 Server Authority 분리
- Version·Migration·Deprecation·Last Known Good
- Transaction·Outbox·Projection Barrier
- Snapshot·Journal·Reconnect·Rollback
- Trace·Stable Error·Budget·Health·Support Reference
- Deterministic·Fault·Negative Disclosure·Roblox Integration
- 문서 검증 성공

## 파일 규칙

```text
specs/<영역>/<3자리 번호>-<기능명>.md
```

현재 예정 파일:

```text
runtime/001-core-authority-identity-version-and-result.md
networking/001-command-projection-and-resync-protocol.md
session/001-campaign-join-character-selection-and-ready.md
scene/001-scene-entry-essential-and-controlled-actor-bootstrap.md
exploration/001-click-movement-plan-execution-and-reconciliation.md
persistence/001-first-slice-snapshot-journal-and-reconnect.md
testing/001-join-move-disconnect-reconnect.md
```

## 현재 명세

### Runtime

- [`001. Core Authority Identity, Version과 Result`](runtime/001-core-authority-identity-version-and-result.md) — `초안·BLOCKED`

### Shared Rules — `UPDATE_REQUIRED`

- [`Shared Spec Index`](shared/README.md)
- [`001. Recipe Step Runtime Foundation`](shared/001-recipe-step-runtime-foundation.md)
- [`002. Standard Recipe Step Handler Contracts`](shared/002-standard-step-handler-contracts.md)
- [`재검토 감사`](../audits/shared-spec-001-002-revalidation-audit.md)

Shared 001·002는 Slice 01 선행 조건이 아니며 Slice 02 `Core Rules Kernel`에서 최신 RuleExecution·Transaction·Outbox·Projection·Recovery 계약에 맞춰 갱신한다.

## 공통 비목표

- 승인된 Spec 없이 Production Code 작성
- 조사하지 않은 최종 Module 경로 확정
- 현재 Slice와 무관한 전면 Foundation 구현
- 측정 없이 Budget·Timeout·Cache 수치 확정
- Test-only Authorization·Mutation 우회
- Client UI·Physics·Presentation을 권위로 사용
- 폐기 문서를 Authority로 재사용
