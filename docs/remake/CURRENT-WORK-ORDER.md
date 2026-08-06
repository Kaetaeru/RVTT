# RVTT Remake 현재 작업 순서

- 상태: `ACTIVE · FULL_UI_UX_SOURCE_ALIGNMENT`
- 문서 종류: Planning·Implementation Work Order
- 최종 갱신일: 2026-08-06
- 직접 플레이 UX: [`ADR-0088`](decisions/ADR-0088-direct-play-pointer-grammar-and-feedback.md)
- 구현 직전 UI·UX: [`implementation-ready-ui-ux-and-settings-spec.md`](ui/shared/implementation-ready-ui-ux-and-settings-spec.md)
- UI·UX Gap Audit: [`ui-ux-implementation-readiness-gap-audit.md`](audits/ui-ux-implementation-readiness-gap-audit.md)
- 공통 입력 교과서: [`ui/common-input/common-input-grammar.md`](ui/common-input/common-input-grammar.md)
- UI Policy Work Order: [`ui/policies/CURRENT-WORK-ORDER.md`](ui/policies/CURRENT-WORK-ORDER.md)
- 전체 Slice Roadmap: [`specs/SLICE-ROADMAP.md`](specs/SLICE-ROADMAP.md)
- Production Workspace: [`implementation/roblox`](../../implementation/roblox/README.md)
- Production Work Order: [`Roblox Implementation Work Order`](../../implementation/roblox/CURRENT-WORK-ORDER.md)
- Grand Campaign: [`Grand Acceptance Campaign`](../../implementation/roblox/GRAND-ACCEPTANCE-CAMPAIGN.md)

## 1. 현재 단계

```text
Product·Architecture·기존 ADR·16 Slice Specification
→ IMPLEMENTED BASELINE

Global UI·UX Policy Foundation
→ COMPLETE

Direct Play Pointer·Feedback UX
→ TOP-LEVEL ACCEPTED · ADR-0088

Full Screen·Settings·Flow Implementation Specification
→ COMPLETE · IMPLEMENTATION READY

Production Runtime·Domain·Client·UI·Test Source
→ IMPLEMENTED BASELINE · FULL UI/UX ALIGNMENT REQUIRED

Static·Security·Formatter·Lint·Rojo·Luau Type
→ PREVIOUS HEAD PASSED · ALIGNMENT HEAD REVALIDATION REQUIRED

Historical Studio Baseline
→ VERIFIED

Slice 01 기존 Token Pick·Move·Projection
→ USER VERIFIED · OLD INPUT CONTRACT

Grand Persistence Execution Contract
→ READY · RUNTIME EVIDENCE NOT EXECUTED

현재 작업
→ 구현 직전 UI·UX 명세 기준 하위 문서·Source·Acceptance 정합화
```

기존 Slice 01 사용자 PASS는 회귀 기준선으로 유지한다. ADR-0088과 새 전체 화면 UX의 Runtime PASS로 재해석하지 않는다.

## 2. 확정된 직접 플레이 입력

```text
왼쪽 클릭
→ 선택 또는 클릭 전에 표시된 기본 행동

오른쪽 클릭
→ Capability 기반 전체 행동표

마우스 휠 클릭 드래그
→ Camera Orbit

Q
→ 최상위 Context 하나만 닫기·취소·거절

E
→ Preview·선택·승인·확정 실행

ESC
→ Gameplay 의미 없음
```

- 권한에 없는 Action과 미인지 정보는 Projection하지 않는다.
- 권한에는 있으나 현재 불가능한 Action은 비활성색과 Hover·Focus Reason을 가진다.
- 행동 후 Actor Selection을 유지한다.
- 턴 전환은 Camera를 강제로 이동하지 않는다.
- Local Preview·Pending·Denied·Stale·Projection Reconciliation을 구분한다.

## 3. 구현 직전 UI·UX 범위

```text
Global Shell
→ Mode·Role·Party·Actor·Hotbar·Map·Journal·System

Exploration
→ World Action Label·Movement Preview·Objective

Encounter
→ Initiative·Resource·End Turn·Reaction·Dice·HP 0

Inventory·Loot
→ Equipment·Container·Transfer·Identification·Capacity

Journal·Map·Ping
→ Stable Navigation·Permission Projection

Character·Rest·Downtime·Death
→ Sheet·Recovery Preview·Death Save

Session·Settings·Recovery
→ Entry·Role·Preference·Bindings·Reconnect·Resync

DM Live
→ Docked Workspace·Player View Preview·Override
```

초기 설정값, Tooltip·Toast Timing, Camera·Hotbar·Accessibility 기본값과 저장 범위는 구현 직전 명세를 따른다.

## 4. 상위 작업 순서

| 순서 | 상태 | 작업 | 완료 조건 |
|---:|---|---|---|
| 1 | DONE | Product·Architecture·기존 ADR | Runtime·Domain·Integration 계약 |
| 2 | DONE | Guides·16 Slice Specs·기존 UI Policy | 사용자 Flow와 Acceptance baseline |
| 3 | DONE | Production Source Baseline | Shared·Server·Client·UI·Test Source |
| 4 | DONE | Static·Toolchain Validation Baseline | Security·StyLua·Selene·Rojo·Luau |
| 5 | DONE | Historical Studio Baseline | Unit·DataStore·3-client Evidence |
| 6 | DONE | Grand Runner Foundation | Grouped Runs·Log Collection·Report |
| 7 | DONE | Slices 02–12 Automated Baseline | Authority·거부·Restore Scenario |
| 8 | DONE | Cross-slice·Fault·Capacity Baseline | 대표 Full-session·Fault·측정 Sample |
| 9 | DONE | Real Transport·Restart·Outage·Lease Source | Lifecycle·Persistence Host |
| 10 | DONE | Production Lease Ownership Source | Acquire·Claim·Guard·Renew·Fenced Save |
| 11 | DONE | Production Lease Acceptance Host | 안전한 Seed·Verify Place와 Summary |
| 12 | DONE | Grand Persistence Execution Contract | 7개 Phase 실행 순서와 게시 안내 |
| 13 | DONE | Direct Play UX 상위 계약 | ADR-0088·공통 입력 교과서 |
| 14 | DONE | Full UI·UX 구현 준비도 감사 | 화면·설정·전환·기본값 Gap 분류 |
| 15 | DONE | Full UI·UX 구현 직전 명세 | Global Shell·전체 화면·Settings·Acceptance |
| 16 | IN_PROGRESS | 하위 UI 문서·Source·Acceptance 정합화 | 전체 Screen·Pointer·Preference·Flow 동기화 |
| 17 | QUEUED | Static·Toolchain Revalidation | Alignment HEAD 전체 Gate PASS |
| 18 | QUEUED | Exploration·Context Input Studio Retest | 새 Contract Human Runtime Evidence |
| 19 | QUEUED | Inventory·Journal·Settings UI Evidence | 화면·상태·Preference Evidence |
| 20 | QUEUED | Player·DM·Observer UI Test | Permission Projection·Role Change·Recovery |
| 21 | QUEUED | Human UI·Accessibility | Scale·Contrast·Focus·Motion·Screenshot |
| 22 | QUEUED | Grand Persistence Runtime | Published 7개 Phase 실행 |
| 23 | QUEUED | Performance·Soak | Budget·Memory·Network·장시간 Session |
| 24 | BLOCKED | Slices 13–15 Content | Rights·Distribution·Asset 승인 |
| 25 | QUEUED | Full Grand Runtime | 대상 Phase가 READY인 Milestone에서 실행 1회 |
| 26 | BLOCKED | Release Hardening | Migration·Fault·Soak·Runbook Evidence |

## 5. 하위 정합화 범위

### Planning

- Combat HUD·Character Sheet·DM Workspace를 새 Global Shell·Settings와 연결
- Exploration·Inventory·Journal·Map·Settings·Entry·Recovery 상세 Screen 문서 분리 여부 결정
- 기존 ESC·Right Camera·Hotbar 행 수 충돌 제거

### Implementation

- Shared Shell·ModeRoleBadge·System Entry
- Q 단일 Context Pop·ESC Gameplay No-op
- Left Default Action Preview·Right Context Action Table·Middle Orbit
- Disabled Color·Hover/Focus Reason
- Tooltip·Toast·Preference Foundation
- Exploration·Encounter·Inventory·Journal·Settings·Recovery Surface
- Selection·Turn·Camera Continuity
- Pending·Denied·Stale·Projection Reconciliation
- Player·DM·Observer Projection 분리

### Acceptance

- Global Shell·Mode Composition
- Pointer Grammar·Default Action Visibility
- Disabled Reason·Hidden Permission Boundary
- Movement·Target Preview·Selection 유지·Soft Focus
- Inventory Transfer·Identification·Conflict
- Journal·Map Permission·Navigation
- Settings Default·Persistence·Binding Conflict
- Entry·Role Change·Reconnect·Recovery
- Scale·Accent·Motion·Focus·Performance

정합화 전 구현 결과는 새 기획의 Runtime Evidence로 인정하지 않는다.

## 6. Grand Persistence 순서

```text
Live DataStore
→ Restart Seed
→ Restart Verify
→ Injected Outage
→ Lease Holder·Contender Pair
→ Production Lease Seed
→ Production Lease Verify
```

Acceptance Mode는 별도 Store·Authority Key·Owner 접두사를 강제하므로 실제 Campaign Store를 사용하지 않는다. 일반 UI 기능 테스트에서는 DataStore를 연결하지 않는다.

## 7. 운영 규칙

1. 가장 위의 `IN_PROGRESS` 작업을 먼저 처리한다.
2. Accepted ADR·Architecture와 하위 구현이 충돌하면 상위 권위를 기준으로 정합화한다.
3. 문서 완료를 Production Script 또는 Studio Runtime PASS로 해석하지 않는다.
4. 자동 Gate 실패 상태에서는 사용자 Studio 실행을 요청하지 않는다.
5. Studio Evidence 없이 Runtime PASS를 주장하지 않는다.
6. 이전 입력 계약의 Studio PASS를 새 UX PASS로 재사용하지 않는다.
7. 권한 밖 Action과 미인지 정보를 Client에 전달한 뒤 숨기지 않는다.
8. 주입 장애를 Roblox 플랫폼 자체 장애로 표현하지 않는다.
9. 정적 Lease Host와 Published Runtime Evidence를 분리한다.
10. Slices 02–12 자동 baseline을 전체 Slice 완료로 해석하지 않는다.
11. 성능 측정 전 임의 Capacity 완료값을 확정하지 않는다.
12. Slices 13–15 공식 Content는 권리 승인 전까지 Release 대상에 포함하지 않는다.
13. 공식 Monster Statblock은 승인된 원본을 그대로 사용하고 임의 CR·수치 재조정을 하지 않는다.
14. 사용자 실행 명령은 완전한 다중 행 Windows PowerShell 블록으로만 제공한다.

## 8. 다음 Gate

```text
Full UI·UX 하위 Source·Acceptance 정합화
→ Static·Security·StyLua·Selene·Rojo·Luau
→ Exploration·Context Input Studio Retest
→ Inventory·Journal·Settings Human Evidence
→ Player·DM·Observer Permission·Role·Recovery Test
→ UI·Accessibility·Performance Evidence
→ Grand Persistence Runtime
→ Full Grand Campaign
→ Release Hardening
```
