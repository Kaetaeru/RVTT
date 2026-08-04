# RVTT Remake 현재 작업 순서

- 상태: ACTIVE
- 문서 종류: Planning Work Order
- 최종 갱신일: 2026-08-05
- Architecture 완료 근거: [`Runtime Architecture Completion과 Main System Guide 준비도 감사`](audits/runtime-architecture-completion-and-main-guide-readiness-audit.md)
- Guide 완료 근거: [`Main System Guide 일관성과 문서 허브 완료 감사`](audits/main-system-guide-consistency-and-document-hub-completion-audit.md)
- User Guide 완료 근거: [`Player·DM User Guide 완료 감사`](audits/player-and-dm-user-guide-completion-audit.md)
- Quick Flow 완료 근거: [`User Guide Quick Flow와 Flowchart 보완 감사`](audits/user-guide-quick-flow-and-flowchart-audit.md)
- 문서 연결 완료 근거: [`구현 명세 전 최종 문서 연결 감사`](audits/pre-implementation-document-linkage-audit.md)
- Spec 세부 작업 순서: [`specs/CURRENT-SPEC-WORK-ORDER.md`](specs/CURRENT-SPEC-WORK-ORDER.md)

이 문서는 RVTT 리메이크 기획·사용자 가이드·명세·구현의 **단일 상위 작업 순서 기준**이다.

## 운영 규칙

1. 가장 위의 `IN_PROGRESS` 항목을 먼저 완료한다.
2. 둘 이상의 세부 작업 순서는 해당 단계의 별도 Work Order로 관리하고 이 문서에서 연결한다.
3. 별도 대화·메모가 이 문서 또는 세부 Work Order와 충돌하면 Work Order를 따른다.
4. 각 단계는 권위 문서, Hub 연결, 완료 감사와 문서 검증까지 끝나야 `DONE`으로 전환한다.
5. `BLOCKED`를 건너뛸 때는 이유와 임시 진행 대상을 기록한다.
6. Production Code는 승인된 현재 Slice Spec과 사용자의 명시적 구현 요청 없이 시작하지 않는다.

상태 값:

```text
IN_PROGRESS
QUEUED
BLOCKED
DONE
DEFERRED
```

## 현재 순서

| 순서 | 상태 | 작업 | 완료 조건 |
|---:|---|---|---|
| 1 | `DONE` | Ruleset Policy Registry, Composition과 Frozen Snapshot Runtime | Architecture 계약, ADR-0081과 문서 검증 완료 |
| 2 | `DONE` | Encounter–Game Time Boundary 통합 계약 | Campaign Time·Scheduler 통합과 원자 경계 완료 |
| 3 | `DONE` | UI Runtime | Projection→ViewModel→Input→Intent와 Recovery 계약 완료 |
| 4 | `DONE` | Diagnostics와 Observability Runtime | Correlated Trace·Error·Budget·Health 계약 완료 |
| 5 | `DONE` | Deterministic Simulation과 Test Harness | Production-parity Scenario·Fault·Disclosure 계약 완료 |
| 6 | `DONE` | Journal Anchor, Permission과 Projection 계약 | Stable Identity·Permission·Search·Navigation 계약 완료 |
| 7 | `DONE` | Cross-System Integration Contracts와 Completion Audit | Domain Outcome·Event·Projection 연결과 재감사 완료 |
| 8 | `DONE` | Main System Guides | 12개 Guide와 문서 Hub·완료 감사 확정 |
| 9 | `DONE` | Player·DM User Guides와 Quick Flow | 상세 Guide와 전체·역할·반복·예외 Flowchart 완료 |
| 10 | `DONE` | 구현 명세 전 최종 문서 연결 감사 | Root→User Flow→Guide→Authority→Spec 경로와 수명주기 검사 완료 |
| 11 | `IN_PROGRESS` | Implementation Specs | 수직 Slice별 Type·Module·Command·Network·Persistence·Migration·Diagnostics·Test 계약 작성 |
| 12 | `QUEUED` | Production Implementation | 승인된 Spec 순서대로 구현·테스트·리뷰·마이그레이션 수행 |

## 현재 단계

```text
Implementation Specs
```

현재 수직 Slice:

```text
First Session Walking Skeleton
```

현재 세부 작업:

```text
runtime/001-core-authority-identity-version-and-result.md 정제
→ Command·Projection Protocol Spec
```

상세 순서와 완료 조건은 [`specs/CURRENT-SPEC-WORK-ORDER.md`](specs/CURRENT-SPEC-WORK-ORDER.md)를 따른다.

## First Session Walking Skeleton

### Player

```text
세션 참가
→ Character 선택
→ Ready
→ Scene 동기화
→ Token 선택
→ 클릭 이동
→ 연결 종료
→ 재접속
→ 같은 권위 상태로 복귀
```

### DM

```text
Campaign·Scene·Player 상태 확인
→ User Ready·Client Ready 확인
→ 세션 시작
→ Player 입장·이동 확인
→ Disconnect·Reconnect와 상태 복귀 확인
```

명세 의존 순서:

```text
Core Authority Identity·Version·Result
→ Command·Projection Protocol
→ Campaign Join·Character Selection·Ready
→ Scene Entry Essential·Controlled Actor Bootstrap
→ Click Movement·Position Projection
→ Snapshot·Journal·Reconnect
→ Deterministic·Roblox Integration Scenario
→ First Slice Spec Audit
```

첫 Slice는 WASD 이동, Interaction, Fog, Rules Recipe, Encounter와 Scene Editor 전체를 포함하지 않는다.

## 첫 Slice 다음 단계

First Session Walking Skeleton이 완료되면 바로 **Core Rules Kernel**로 진행한다.

```text
First Session Walking Skeleton
→ Core Rules Kernel
→ Exploration Interaction
→ Encounter
```

Core Rules Kernel에서 처음 넣는 핵심 규칙:

- `dnd5e-2024` Ruleset Core Profile
- 능력치·숙련 보너스·Skill·Save·AC·HP 파생 계산
- D20 Test, Advantage·Disadvantage, DC·AC 비교
- Attack Roll·Saving Throw·Damage·Healing
- 최소 Resource Cost와 Condition 기반
- RuleExecution Adapter
- Shared Recipe Runtime 001·002 갱신
- 대표 Ability Check·Basic Attack·Save 수직 검증

전체 직업·하위직업·Feat·Spell·Item 콘텐츠와 Initiative·Turn·Reaction은 이 단계에서 한꺼번에 넣지 않는다. Core Rules Kernel을 먼저 완성한 뒤 Exploration Interaction과 Encounter가 같은 판정 엔진을 재사용한다.

## Shared Spec 001·002 재검토 결과

- 완료 감사: [`Shared Spec 001·002 재검토 감사`](audits/shared-spec-001-002-revalidation-audit.md)
- Shared Index: [`specs/shared/README.md`](specs/shared/README.md)

판정:

```text
001 Recipe Step Runtime Foundation
→ UPDATE_REQUIRED

002 Standard Recipe Step Handler Contracts
→ UPDATE_REQUIRED
```

두 문서는 폐기하지 않지만 현재 `준비 완료`로 사용할 수 없다. First Session Walking Skeleton의 선행 조건에서는 제외하고, 바로 다음 Core Rules Kernel에서 최신 RuleExecution·Transaction·Outbox·Projection·Recovery·Diagnostics·Simulation 계약에 맞춰 갱신한다.

## Implementation Specs 단계 원칙

1. Spec은 Quick Flow와 Player·DM User Guide의 대상 구간을 Acceptance Flow로 연결한다.
2. 직접 구현 계약은 Product·Architecture·System·UI·ADR을 근거로 한다.
3. User Guide와 Main System Guide를 Type·Schema·Command의 권위 원본으로 사용하지 않는다.
4. 새 Product 동작이나 Architecture 결정이 필요하면 Spec을 멈추고 권위 문서를 먼저 수정한다.
5. Source·Build·State·Projection·Presentation을 혼합하지 않는다.
6. Client Intent와 Server Authority 검증을 구분한다.
7. Version·Migration·Deprecation·Recovery·Rollback을 포함한다.
8. Ordering·Reservation·Transaction·Outbox·Projection Barrier를 필요한 범위에서 명시한다.
9. Trace·Stable Error·Budget·Health·Support Reference를 포함한다.
10. 사용자에게 보이는 Loading·Waiting·Denied·Retrying·Resync 상태를 정의한다.
11. Deterministic Scenario·Fault Injection·Negative Disclosure와 실제 Roblox Integration 경계를 포함한다.
12. 측정 근거 없이 Budget·Timeout·Cache 수치를 확정하지 않는다.
13. `SUPERSEDED`, `DISCONTINUED`, `ARCHIVED`와 충돌 Draft를 근거로 사용하지 않는다.
14. 실제 코드·Schema·Test 조사가 없는 Spec은 `준비 완료`로 올리지 않는다.
15. 승인된 Spec 없이 Production Code를 작성하지 않는다.

## 표준 작업 흐름

```text
CURRENT-SPEC-WORK-ORDER 확인
→ Quick Flow 대상 구간 확인
→ 관련 Player·DM Guide 확인
→ Runtime·Domain Guide 확인
→ 직접 Authority Documents 수집
→ 기존 Code·Schema·Test 조사
→ Implementation Spec Template 작성
→ Acceptance·Migration·Diagnostics·Test Gate 검사
→ 문서 검증
→ 현재 Spec DONE
→ 다음 Spec IN_PROGRESS
```

## 완료된 문서 단계

### Main System Guides

- [`Guide Work Order`](guides/CURRENT-GUIDE-WORK-ORDER.md)
- [`Guide Hub`](guides/README.md)
- [`Guide 완료 감사`](audits/main-system-guide-consistency-and-document-hub-completion-audit.md)

### Player·DM User Guides

- [`Quick Flow`](user-guides/QUICK-FLOW.md)
- [`Player Guide`](user-guides/player/README.md)
- [`DM Guide`](user-guides/dm/README.md)
- [`User Guide Hub`](user-guides/README.md)

현재 User Guide 상태는 구현 전 목표 경험인 `TARGET_EXPERIENCE`다. 실제 Build에서는 `CURRENT_FOR_BUILD`, Release에서는 `RELEASE_VERIFIED`로 다시 검증한다.

### 문서 연결

- [`최종 문서 연결 감사`](audits/pre-implementation-document-linkage-audit.md)
- [`문서 구조와 작성 가이드`](DOCUMENT-GUIDE.md)
- [`문서 수명주기 정책`](DOCUMENT-LIFECYCLE-AND-DISCONTINUATION.md)
- [`Implementation Spec Template`](templates/implementation-spec-template.md)

## Production Implementation Gate

Production Implementation은 다음 조건 전에는 시작하지 않는다.

- First Session Walking Skeleton의 관련 Spec이 모두 `준비 완료`
- Type·Command·Network·Persistence·Migration 계약 완료
- Acceptance·Failure·Recovery·Security Test 정의
- 관련 User Guide·Main Guide·Authority 정합성 확인
- First Slice Spec 통합 감사 완료
- 문서 검증 성공
- 사용자의 명시적 Production Implementation 시작 요청

## 변경 기록

| 날짜 | 변경 |
|---|---|
| 2026-08-05 | Core Rules Kernel을 First Session Walking Skeleton 바로 다음 단계로 앞당겼다. Exploration Interaction과 Encounter는 같은 핵심 판정 엔진을 재사용한다. |
| 2026-08-05 | Implementation Spec 세부 Work Order를 만들고 First Session Walking Skeleton을 첫 수직 Slice로 확정했다. |
| 2026-08-05 | Shared Spec 001·002를 `UPDATE_REQUIRED`로 판정했다. |
| 2026-08-05 | 최종 문서 연결 감사를 완료하고 Implementation Specs 단계로 전환했다. |
| 2026-08-05 | Player·DM User Guides, Quick Flow와 12개 Main System Guide를 완료했다. |
| 2026-08-04 | Runtime Architecture와 Cross-System Integration 완료 감사를 통과했다. |