# RVTT Remake 현재 작업 순서

- 상태: ACTIVE · DIRECT_PLAY_UX_ALIGNMENT
- 문서 종류: Planning·Implementation Work Order
- 최종 갱신일: 2026-08-06
- 직접 플레이 UX: [`ADR-0088`](decisions/ADR-0088-direct-play-pointer-grammar-and-feedback.md)
- 공통 입력 교과서: [`ui/common-input/common-input-grammar.md`](ui/common-input/common-input-grammar.md)
- 전체 Slice Roadmap: [`specs/SLICE-ROADMAP.md`](specs/SLICE-ROADMAP.md)
- Production Workspace: [`implementation/roblox`](../../implementation/roblox/README.md)
- Production Work Order: [`Roblox Implementation Work Order`](../../implementation/roblox/CURRENT-WORK-ORDER.md)
- Grand Campaign: [`Grand Acceptance Campaign`](../../implementation/roblox/GRAND-ACCEPTANCE-CAMPAIGN.md)
- Production Lease Host: [`Production Lease Acceptance Host`](../../implementation/roblox/PRODUCTION-LEASE-ACCEPTANCE-HOST.md)

## 1. 현재 단계

```text
Product·Architecture·ADR·16 Slice Specification·UI Policy
→ IMPLEMENTED BASELINE

Direct Play Pointer·Feedback UX
→ TOP-LEVEL ACCEPTED · ADR-0088

Common Input Grammar
→ UPDATED · Q/E/LEFT/RIGHT/MIDDLE CONTRACT ACCEPTED

Production Runtime·Domain·Client·UI·Test Source
→ IMPLEMENTED BASELINE · NEW UX ALIGNMENT REQUIRED

Static·Security·Formatter·Lint·Rojo·Luau Type
→ PREVIOUS HEAD PASSED · ALIGNMENT HEAD REVALIDATION REQUIRED

Historical Studio Baseline
→ VERIFIED

Slice 01 기존 Token Pick·Move·Projection
→ USER VERIFIED · OLD INPUT CONTRACT

Contextual Pointer Actions Implementation
→ EXISTS · ADR-0088 ALIGNMENT REQUIRED

Grand Persistence Execution Contract
→ READY · RUNTIME EVIDENCE NOT EXECUTED

현재 작업
→ ADR-0088 하위 UI·구현·Acceptance 정합화
```

기존 Slice 01 사용자 PASS는 회귀 기준선으로 유지한다. 새 Pointer Grammar와 Direct Play UX의 Runtime PASS로 재해석하지 않는다.

## 2. 확정된 직접 플레이 입력

```text
왼쪽 클릭
→ 선택 또는 클릭 전에 표시된 기본 행동

오른쪽 클릭
→ Capability 기반 전체 행동표

마우스 휠 클릭 드래그
→ Camera Orbit

Q
→ 최상위 문맥 하나만 닫기·취소·거절

E
→ Preview·선택·승인·확정 실행

ESC
→ Gameplay 의미 없음
```

추가 UX 경계:

- 권한에 없는 행동과 미인지 정보는 표시하지 않는다.
- 권한에는 있으나 현재 불가능한 행동은 비활성 색상 버튼으로 표시한다.
- 비활성 버튼 Hover 시 커서 옆에 불가능한 이유를 표시한다.
- 좌클릭 기본 행동은 클릭 전에 이름·대상·비용·유효성을 표시한다.
- 이동·공격·상호작용 후 Actor 선택을 유지한다.
- 턴 전환은 카메라를 강제로 이동하지 않는다.
- 이동 경로, 대상, 범위, 비용과 위험을 실행 전에 Preview한다.
- Pending·승인·거부 피드백을 구분한다.
- 일반 실패는 관련 커서·대상 근처에 표시하고 Modal을 남용하지 않는다.

## 3. 상위 작업 순서

| 순서 | 상태 | 작업 | 완료 조건 |
|---:|---|---|---|
| 1 | DONE | Product·Architecture·기존 ADR | Runtime·Domain·Integration 계약 |
| 2 | DONE | Guides·16 Slice Specs·기존 UI Policy | 사용자 Flow와 Acceptance baseline |
| 3 | DONE | Production Source Baseline | Shared·Server·Client·UI·Test Source |
| 4 | DONE | Static·Toolchain Validation | Security·StyLua·Selene·Rojo·Luau |
| 5 | DONE | Historical Studio Baseline | Unit·DataStore·3-client Evidence |
| 6 | DONE | Grand Runner Foundation | Grouped Runs·Log Collection·Report |
| 7 | DONE | Slices 02–12 Automated Baseline | Authority·거부·Restore Scenario |
| 8 | DONE | Cross-slice·Fault·Capacity Baseline | 대표 Full-session·Fault·측정 Sample |
| 9 | DONE | Real Transport·Restart·Outage·Lease Pair Source | Lifecycle·Persistence Host |
| 10 | DONE | Production Lease Ownership Source | Acquire·Claim·Guard·Renew·Fenced Save |
| 11 | DONE | Production Lease Acceptance Host | 안전한 Seed·Verify Place와 Summary |
| 12 | DONE | Grand Persistence Execution Contract | 7개 Phase 실행 순서와 게시 안내 |
| 13 | DONE | Direct Play UX 상위 계약 | ADR-0088·공통 입력 교과서 |
| 14 | IN_PROGRESS | 하위 문서·구현·Acceptance 정합화 | ESC 제거·Q 단계 취소·Pointer·Preview·가용성 동기화 |
| 15 | QUEUED | Context Input Studio Retest | 새 Contract 기준 Human Runtime Evidence |
| 16 | QUEUED | Human UI·Accessibility | Tooltip·비활성색·Focus·읽기 순서·Screenshot Evidence |
| 17 | QUEUED | DM·Player·Observer Context Input | 권한별 Action Projection과 비밀 정보 검증 |
| 18 | QUEUED | Grand Persistence Runtime | Published 7개 Persistence Phase 실행 |
| 19 | QUEUED | Performance·Soak | Budget·Memory·Network·장시간 Session |
| 20 | BLOCKED | Slices 13–15 Content | Rights·Distribution·Asset 승인 |
| 21 | QUEUED | Full Grand Runtime | 대상 Phase가 READY인 Milestone에서 실행 1회 |
| 22 | BLOCKED | Release Hardening | Migration·Fault·Soak·Runbook Evidence |

## 4. ADR-0088 하위 정합화 범위

```text
Planning
→ 관련 UI·Guide·Spec Link와 용어 정리

Implementation
→ ESC Gameplay 처리 제거
→ Q 단일 Context Pop
→ Left Default Action Preview
→ Right Context Action Table
→ Middle-button Camera Orbit
→ Disabled Color + Hover Reason
→ Selection·Turn·Camera Continuity
→ Pending·Accepted·Rejected Feedback

Acceptance
→ Pointer Grammar
→ Default Action Visibility
→ Disabled Hover Reason
→ Hidden Permission Boundary
→ Movement·Target Preview
→ Q 단계 취소
→ ESC No-op
→ Selection 유지
→ Soft Focus
```

정합화 전 구현 결과는 새 기획의 Runtime Evidence로 인정하지 않는다.

## 5. Grand Persistence 순서

```text
Live DataStore
→ Restart Seed
→ Restart Verify
→ Injected Outage
→ Lease Holder·Contender Pair
→ Production Lease Seed
→ Production Lease Verify
```

Acceptance Mode는 별도 Store·Authority Key·Owner 접두사를 강제하므로 실제 Campaign Store를 사용하지 않는다.

DataStore 검사는 관련 변경을 축적한 뒤 Milestone에서 한 번에 한다. 일반 기능 테스트에서는 DataStore를 연결하지 않는다.

## 6. 운영 규칙

1. 가장 위의 `IN_PROGRESS` 작업을 먼저 처리한다.
2. 상위 ADR과 하위 구현이 충돌하면 상위 ADR을 기준으로 하위 문서를 정합화한다.
3. 자동 Gate 실패 상태에서는 사용자 Studio 실행을 요청하지 않는다.
4. Studio Evidence 없이 Runtime PASS를 주장하지 않는다.
5. 이전 입력 계약의 Studio PASS를 ADR-0088 PASS로 재사용하지 않는다.
6. 주입 장애를 Roblox 플랫폼 자체 장애로 표현하지 않는다.
7. 정적 Lease Host와 실제 Published Runtime Evidence를 분리한다.
8. Slices 02–12 자동 baseline을 전체 Slice 완료로 해석하지 않는다.
9. 성능 측정 전 임의 합격선을 확정하지 않는다.
10. Slices 13–15 공식 Content는 권리 승인 전까지 Release 대상에 포함하지 않는다.
11. 공식 Monster Statblock은 승인된 원본을 그대로 사용하고 임의 CR·수치 재조정을 하지 않는다.
12. 사용자 실행 명령은 완전한 다중 행 Windows PowerShell 블록으로만 제공한다.

## 7. 다음 Gate

```text
ADR-0088 하위 정합화
→ Static·Toolchain Validation
→ Context Input Studio Retest
→ Human UI·Accessibility Evidence
→ DM·Player·Observer Context Input
→ Grand Persistence Runtime
→ Performance·Soak Host
→ Target Phase READY
→ Full Grand Campaign 사용자 실행 1회
→ 전체 실패 Root Cause 수정
→ Grand Campaign 전체 재실행
→ Release Hardening
```
