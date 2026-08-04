# RVTT Implementation Slice Roadmap

- 상태: ACTIVE
- 문서 종류: Implementation Slice Roadmap
- 작성일: 2026-08-05
- 상위 작업 순서: [`../CURRENT-WORK-ORDER.md`](../CURRENT-WORK-ORDER.md)
- 세부 Spec 작업 순서: [`CURRENT-SPEC-WORK-ORDER.md`](CURRENT-SPEC-WORK-ORDER.md)
- 완료 감사: [`Implementation Slice Roadmap 완전성 감사`](../audits/implementation-slice-roadmap-completeness-audit.md)

이 문서는 RVTT 리메이크의 전체 Production Implementation을 **사용자가 실제로 검증할 수 있는 수직 Slice**로 나눈 장기 순서 기준이다.

각 Slice는 기능 목록이 아니라 다음을 모두 포함하는 완성 단위다.

```text
사용자 Acceptance Flow
→ Server Authority와 Domain State
→ Command·Projection·UI
→ Persistence·Reconnect·Recovery
→ Diagnostics·Security·Deterministic Test
→ Slice Integration Audit
```

이 Roadmap은 각 Slice의 범위와 순서를 확정한다. 실제 Type·Module·Command·Schema와 파일 분할은 Slice별 Work Order와 Implementation Spec이 소유한다.

---

## 1. 전체 순서

```text
01 First Session Walking Skeleton
→ 02 Core Rules Kernel
→ 03 Exploration Interaction·Perception
→ 04 Encounter Core Loop
→ 05 Character Foundation·Creation
→ 06 Inventory·Equipment·World Items
→ 07 Rest·Time·Downtime·Progression
→ 08 Player UI·Camera·Presentation
→ 09 Journal·Ping·Knowledge Navigation
→ 10 Scene Authoring·Compile·Publish
→ 11 Live DM Workspace·Quick Actions·Recovery
→ 12 Content Pack·Localization·Trusted Extension Platform
→ 13 Official 2024 Character Options Content
→ 14 Official 2024 Spell·Equipment·Rules Content
→ 15 NPC·Monster·Campaign Authored Content
→ 16 Full-session Integration·Release Hardening
```

### 상태

| Slice | 상태 |
|---:|---|
| 01 | `IN_PROGRESS` |
| 02–16 | `QUEUED` |

순서를 바꾸려면 이 Roadmap, `CURRENT-SPEC-WORK-ORDER.md`와 관련 Guide 영향 지도를 함께 갱신한다.

---

## 2. 모든 Slice에 적용되는 공통 레일

다음은 마지막 Slice에 몰아서 추가하지 않는다. 각 Slice의 완료 조건에 포함한다.

### Authority와 데이터

- Stable ID, Version, Epoch, Revision과 Incarnation
- Source·Compiled Build·Authoritative State·Projection·Presentation 분리
- Client Intent와 Server Authority 재검증
- Ordering·Reservation·Transaction·Outbox·Projection Barrier
- Version Migration, Deprecation, Last Known Good와 Rollback

### 사용자 경험

- Player·DM Acceptance Flow
- Loading·Waiting·Denied·Retrying·Resync·Recovery 상태
- Q·E와 현재 Input Context의 단일 소비
- 한국어 표시와 언어 독립 Stable ID
- PC 키보드·마우스 기준 접근성

### 안정성

- Snapshot·Journal·Reconnect·Server Restart
- Correlated Trace·Stable Error·Support Reference·Health
- Negative Disclosure와 역할별 Projection
- Deterministic Scenario·Fault Injection·Roblox Integration
- 측정 기반 Budget·Performance·Memory·Network 검증

### 금지

- Test-only Store Mutation과 Authorization 우회
- Client Physics·UI·VFX를 권위 원본으로 사용
- 실제 Repository 조사 없이 최종 Module 경로 확정
- 다음 Slice의 전체 Framework를 미리 구현
- `SUPERSEDED`, `DISCONTINUED`, `ARCHIVED` 문서를 Authority로 사용

---

# Slice 정의

## Slice 01 — First Session Walking Skeleton

### 사용자 결과

Player가 세션에 참가해 Character를 선택하고, Scene에 입장해 Token을 클릭 이동한 뒤 재접속해 같은 권위 상태로 돌아온다.

```text
Campaign 참가
→ Character 선택
→ Ready
→ DM 시작
→ Scene Entry Essential
→ Token 선택
→ 클릭 이동
→ 위치 Commit·Projection
→ Disconnect
→ Reconnect·Resync
```

### 핵심 범위

- Core Authority Identity·Version·Result
- Command Receipt·Terminal Result·Projection Sync
- Membership·Role·Owner·Controller·Ready
- Scene Entry Essential·Controlled Actor Bootstrap
- 클릭 이동 Plan·Execution·Checkpoint·Position Commit
- Snapshot·Journal·Reconnect·Full Resync

### 비범위

- WASD Token 이동
- Interaction·Fog·Rules·Encounter
- Character 생성·성장
- 일반 Scene Editor

### 주요 Guide

Runtime, Session, Scene, Exploration, UI, Diagnostics

---

## Slice 02 — Core Rules Kernel

### 사용자 결과

Encounter 없이도 대표 Character가 능력 판정, 기본 공격, 내성 굴림, 피해와 회복을 서버 권위로 실행하고 결과를 저장·재접속 후 유지한다.

```text
Capability 선택
→ 대상·DC·AC 검증
→ D20 Test 또는 Attack·Save
→ RollRecord
→ Pending Effect
→ Transaction Commit
→ 결과 Projection·로그
```

### 핵심 범위

- `dnd5e-2024` Core Policy Profile
- Ability·Proficiency·Skill·Save·AC·HP 파생값
- RuleExecution Orchestrator Adapter
- Shared Recipe Spec 001·002 갱신
- D20 Test, Advantage·Disadvantage, DC·AC
- Attack Roll, Saving Throw, Damage, Healing
- Resource Cost와 Condition 최소 기반
- 대표 Ability Check·Basic Attack·Save 수직 Scenario

### 비범위

- Initiative·Turn·Reaction 전체
- 모든 직업·주문·아이템 콘텐츠
- 복잡한 Timing Window와 고급 예외 전체

### 주요 Guide

Runtime, Rules, Character, UI, Diagnostics, Extension

---

## Slice 03 — Exploration Interaction·Perception

### 사용자 결과

Player가 이동하며 문·상자·레버·바닥 Item을 사용하고 Search·Study로 숨은 정보를 발견하며, DM이 구조화된 판정을 처리한다.

```text
Hover·Focus·Selection
→ Contextual Interaction
→ 필요 시 Ability Check·Save·DM Adjudication
→ Object·Knowledge·Fog State Commit
→ Observer별 Projection
```

### 핵심 범위

- Semantic Input Router와 Selection Session
- Hover·Focus·Selection·Target 분리
- Door·Container·Item Interaction
- Search·Study·Lock·Trap·Secret Object
- Visibility·Knowledge·Detection·Manual Fog
- DM Adjudication과 Interaction Concurrency
- 탐험 WASD Token 이동

### 비범위

- Initiative와 Turn Economy
- 전체 Inventory 관리 화면
- Scene Source 편집

### 주요 Guide

Exploration, Scene, Rules, UI, Session, Diagnostics

---

## Slice 04 — Encounter Core Loop

### 사용자 결과

탐험 중 Encounter를 시작하고, 참가자들이 Initiative·Turn·Movement·Action·Reaction을 진행한 뒤 결과를 유지하며 탐험으로 돌아간다.

```text
Encounter Proposal
→ 참가자·진영·인식 Snapshot
→ Initiative
→ Turn·Opportunity
→ 이동·Action·Bonus Action·Reaction
→ Damage·Condition·Death
→ Encounter 종료
→ Exploration 복귀
```

### 핵심 범위

- Encounter State·Timeline·Cursor
- Initiative·Turn·Opportunity·Reaction
- 전투 클릭 경로 이동과 Movement Budget
- Action Economy와 Core Rules 연결
- HP 0·Death Save·Concentration 최소 전투 경계
- Objective·Encounter 종료
- Turn Snapshot·DM Rollback

### 비범위

- 모든 Class·Spell 콘텐츠
- 대규모 AI 전술 시스템
- 완성된 전투 연출 Asset 전체

### 주요 Guide

Combat, Rules, Scene, Session, UI, Character, Diagnostics

---

## Slice 05 — Character Foundation·Creation

### 사용자 결과

Player가 Campaign에서 Level 1 Character를 생성·검토·확정하고, Character Sheet에서 영구 Source·Build·현재 State를 확인해 세션 Character로 선택한다.

```text
생성 선택
→ Character Source Candidate
→ Compile·Validation
→ Compiled Character Build
→ Persistent State 생성
→ Player·DM 검토
→ Atomic Activation
→ Session Character 선택
```

### 핵심 범위

- Character Source·Compiler·Build Registry·State Store
- Species·Background·Class 등 생성 Slot의 범용 계약
- Stored Selection과 Derived Grant 분리
- CharacterId와 Scene Actor Binding
- Level 1 생성, 오류·수정·확정
- Character Sheet Projection과 기본 편집 Intent
- Build Migration과 Last Known Good

### 비범위

- 전체 공식 Character Option 데이터
- Level Up·Rest·Downtime
- 완성된 Inventory·Spellbook

### 주요 Guide

Character, Rules, Session, UI, Extension, Diagnostics

---

## Slice 06 — Inventory·Equipment·World Items

### 사용자 결과

Player가 Item을 획득·이전·장착·해제·드롭하고, 같은 ItemInstance가 Inventory와 World에 중복되지 않으며 공격 Profile과 Capability가 갱신된다.

```text
Item 획득·전리품
→ ItemInstance Transfer
→ Container·Equipment Binding
→ Capability·Attack Profile 재계산
→ World Presence 생성·정리
→ Projection·저장
```

### 핵심 범위

- Item Definition·ItemInstance
- Container·Stack·Currency·Identification
- Equipment·Hand·Attunement
- Weapon Attack Profile·Mastery 연결
- Loot·Pickup·Drop·Transfer
- Transactional World Presence와 Streaming
- Inventory UI와 동시 획득 경쟁

### 비범위

- 전체 공식 Item Catalog
- Crafting·장기 Activity
- 상점·경제 Simulation

### 주요 Guide

Character, Exploration, Scene, Rules, UI, Diagnostics

---

## Slice 07 — Rest·Time·Downtime·Progression

### 사용자 결과

Player와 DM이 Short·Long Rest, Level Up, Spell Preparation, Crafting·Training·Travel 같은 시간 기반 활동을 진행하고 중단·재접속·Encounter 이후 안전하게 재개한다.

```text
Activity 시작
→ Eligibility·Resource Reservation
→ Campaign Time·Checkpoint
→ Choice·DM 승인·중간 사건
→ Domain Completion Proposal
→ Atomic Commit
→ Progression·Item·Recovery Projection
```

### 핵심 범위

- Campaign Time·Calendar·Duration·Scheduler
- Downtime Session·Activity·Participant Window
- Rest와 Resource Recovery
- Level Up Source·Build·State Migration
- Spell Preparation·Spellbook Repository·Copy
- Crafting·Training·Travel
- 중단·취소·Encounter 전환·Rollback

### 비범위

- 모든 Activity 콘텐츠와 공식 비용표 완성
- 오프라인 현실 시간 자동 진행
- 상점·경제 전체

### 주요 Guide

Character, Rules, Combat, Session, UI, Diagnostics

---

## Slice 08 — Player UI·Camera·Presentation

### 사용자 결과

앞선 Slice의 모든 기능이 공통 HUD·Panel·Input·Camera와 안전한 Presentation을 통해 일관되게 보이며, 실패·재접속·Rollback에서도 UI가 권위 Projection과 재결합한다.

```text
Projection Replica
→ ViewModel·Panel·HUD
→ Semantic Input·Focus
→ Command Pending·Reconciliation
→ CameraRequest
→ PresentationIntent·Playback
→ Reconnect·Rollback UI Recovery
```

### 핵심 범위

- UI Replica·ViewModel·Panel·Component Registry
- Common Input, Q·E·1–5, Focus와 Accessibility
- Combat HUD·Character Sheet·Inventory 공통 Surface
- Free·Follow·Focus Camera와 Bookmark·ViewY
- Presentation Recipe·Module·Queue·Marker·Fallback
- Dice Reveal, Attack·Spell·Condition Presentation
- Role Change·Scene Transition·Epoch-safe UI Recovery

### 비범위

- 음악과 모든 규칙 효과음
- Gameplay Authority를 바꾸는 Presentation
- 최종 개별 Content Asset 전체

### 주요 Guide

UI, Rules, Combat, Character, Session, Scene, Diagnostics

---

## Slice 09 — Journal·Ping·Knowledge Navigation

### 사용자 결과

DM과 Player가 Markdown Journal을 작성·검색·링크하고, 권한에 맞는 World Link로 안전하게 이동하며 위치·경로 Ping을 공유한다.

```text
Document Source·Compile
→ Permission Projection·Search
→ Link·Anchor Resolution
→ Camera·Selection·Scene Navigation Proposal
→ 위치·경로 Ping
```

### 핵심 범위

- Document·Folder·Section Stable Identity와 Revision
- Markdown Compiler·Outline·Link Graph
- Permission-partitioned Search·Backlink
- World Anchor Lifecycle와 Safe Navigation
- Edit Conflict·Import·Export·Draft Recovery
- Scene 기본 문서와 Journal UI
- Point·Path Ping, Audience·Rate Limit·Presentation

### 비범위

- Journal이 다른 Domain을 직접 수정
- Ping을 Movement·Targeting 권위로 사용
- 외부 협업 Docs 서비스

### 주요 Guide

Journal, UI, Scene, Exploration, Session, Diagnostics

---

## Slice 10 — Scene Authoring·Compile·Publish

### 사용자 결과

DM이 게임 안에서 Scene Source를 제작하고 검증된 Candidate Build를 Test Play한 뒤 원자적으로 Publish하며, 실패 시 기존 Published Scene을 유지한다.

```text
Scene Source 편집
→ Authoring Command·History
→ Semantic Compile
→ Diagnostic·Critical Route 검사
→ Candidate Test Play
→ Atomic Publish
→ Runtime Scene 사용
```

### 핵심 범위

- Scene Source·Stable Object ID·Schema·Migration
- Editor Core·Selection·Placement·Snap·ViewY·Preview
- Tool Registry와 Wall·Floor·Prefab·Door·Stair·Region Tool
- Inspector·Blueprint·Lighting Authoring
- Semantic Profile·Compiler Provider·Build Artifact
- Diagnostic·Disclosure·Critical Route
- Candidate·Test Play·Atomic Publish
- Draft·History·Reconnect·Recovery

### 비범위

- Runtime 중 자동 Live Patch
- 범용 3D 모델링·NavMesh 수동 편집
- 공개 사용자 코드 Plugin

### 주요 Guide

Scene Editor, Scene, UI, Extension, Diagnostics

---

## Slice 11 — Live DM Workspace·Quick Actions·Recovery

### 사용자 결과

DM이 진행 중 세션에서 Player 상태를 보며 Control, Fog, Actor·Object, Scene 전환과 안전한 Quick Edit를 수행하고, 문제 발생 시 Pause·Recovery·Rollback을 검토·실행한다.

```text
DM Workspace
→ Context Quick Action
→ Player Route 또는 DM Override 분리
→ Runtime Quick Edit·Scene Transition
→ Save·Checkpoint·Recovery Review
→ Resume
```

### 핵심 범위

- Dockable DM Workspace와 Player View Preview
- Control Assignment·Observer·Takeover
- Context Quick Action과 Mandatory Audit
- Fog·Actor·Object·Lighting Runtime Command
- Runtime Quick Edit와 Source Promotion
- Live Patch·Build Rebase·Client Ready
- Save·Checkpoint·Recovery Review·Rollback UI
- Session Pause·Resume·Normal Shutdown

### 비범위

- DM이 Workspace Instance를 직접 권위 Store로 사용
- Runtime Quick Edit의 자동 Source 영구화
- NPC 대화 AI

### 주요 Guide

Session, Scene Editor, UI, Diagnostics, Exploration, Combat

---

## Slice 12 — Content Pack·Localization·Trusted Extension Platform

### 사용자 결과

개발자가 Versioned Source Pack과 신뢰된 Extension을 검증·활성화하고, Campaign은 정확한 Pack·Policy·Localization Version을 고정하며 실패 시 Last Known Good를 유지한다.

```text
Pack Manifest·Catalog
→ Dependency·Trust·Budget 검증
→ Policy·Content·Provider Compile
→ Candidate Activation·Migration
→ Campaign Binding
→ Frozen Snapshot·Recovery
```

### 핵심 범위

- Pack Manifest·Catalog·Dependency·Stable Content ID
- Localization Bundle과 Authority Digest 분리
- Policy Pack·Patch·Frozen Snapshot
- Grant·Capability·Recipe·AdvancedOperation Registry
- Prefab·Scene Tool·Compiler Provider Host
- Presentation Module·Recipe Host
- Candidate Activation·Migration·Removal·Rollback
- Extension Contract·Disclosure·Load Test

### 비범위

- 공개 Marketplace와 일반 사용자 코드 Plugin
- 외부 URL Runtime Code Download
- 플레이어용 범용 Spell·Feature 제작기

### 주요 Guide

Extension, Runtime, Rules, Scene Editor, UI, Diagnostics

---

## Slice 13 — Official 2024 Character Options Content

### 사용자 결과

Player가 지원 대상인 공식 2024 Character Option으로 Character를 생성하고 Level 1–20 성장시키며, 모든 선택·Grant·Capability가 Sheet·Rules·저장과 연결된다.

### 핵심 범위

- Species·Background·Class·Subclass
- Feat와 Ability Score 선택
- Level 1–20 Progression Table과 Grant
- Class Resource·Feature·Choice
- Multiclass가 범위에 포함될 경우 별도 Policy·Spec Gate
- 한국어 Localization과 Source Citation Metadata
- Character Creation·Level Up·Migration Scenario

### 완료 방식

전체 데이터를 한 번에 병합하지 않는다. 의존성이 완결된 Content Wave별로 Compile·Scenario·Audit을 통과한 뒤 Coverage Matrix를 증가시킨다.

### 비범위

- 공식 권리 검토가 끝나지 않은 Asset·본문 복제
- Runtime 계약을 Content 예외로 우회

### 주요 Guide

Character, Rules, Extension, UI, Diagnostics

---

## Slice 14 — Official 2024 Spell·Equipment·Rules Content

### 사용자 결과

지원 대상 공식 주문·무기·방어구·장비·상태와 행동 규칙이 Character Capability, RuleExecution, Inventory와 Presentation에 연결된다.

### 핵심 범위

- Spell Definition·Casting Route·Preparation·Repository
- Weapon·Armor·Gear·Consumable Definition
- Weapon Mastery와 Attack Profile
- Condition·Duration·Concentration·Ongoing Effect
- 공식 Action·Reaction·Rest 관련 규칙 콘텐츠
- Recipe·Step·AdvancedOperation Coverage
- Localization·Migration·Coverage Matrix

### 완료 방식

Spell·Item·Rule Family별 Content Wave가 동일 Runtime을 재사용하고, 개별 전용 코드는 명시적 예외 Spec과 Scenario를 가진다.

### 비범위

- 임의 Script 기반 Content
- 테스트 없이 이름과 설명만 등록된 Placeholder Content

### 주요 Guide

Rules, Character, Combat, Extension, UI, Diagnostics

---

## Slice 15 — NPC·Monster·Campaign Authored Content

### 사용자 결과

DM이 검증된 NPC·Monster Statblock을 배치·조작하고, 안전한 JSON Import와 Campaign Authored Content를 통해 새 Actor Definition을 추가할 수 있다.

```text
Statblock Source·Import
→ Schema·Content Ref 검증
→ Actor Definition Compile
→ Scene Presence 생성
→ Capability·Encounter 사용
→ 저장·Migration·Export
```

### 핵심 범위

- Monster·NPC Actor Definition·Instance
- Safe JSON Import·Normalizer·Diagnostic
- Campaign Authored Content Candidate·Publish
- NPC·Monster Token·Prefab Binding
- Encounter·Rules·Loot·Journal Integration
- Missing Content·Pack Removal Recovery
- Starter DM Catalog와 Fixture 대체

### 비범위

- NPC Dialogue Tree와 생성형 대화 AI
- 전체 공식 Monster Catalog 자동 포함 약속
- Import된 임의 Luau·Remote·URL 실행

### 주요 Guide

Character, Rules, Combat, Scene, Extension, Journal, Diagnostics

---

## Slice 16 — Full-session Integration·Release Hardening

### 사용자 결과

DM과 Player가 장시간 Campaign Session을 생성·준비·탐험·전투·휴식·편집·저장·재접속·롤백하며, 지원 환경에서 안정적으로 Release 가능한 상태가 된다.

```text
Campaign 준비
→ Character·Scene·Content 선택
→ Exploration·Interaction·Encounter
→ Journal·Downtime·Scene Transition
→ Disconnect·Restart·Rollback
→ Session 종료·다음 Session Resume
```

### 핵심 범위

- 전체 Slice 간 Contract·Migration·Coverage Audit
- 장시간 Session·다중 Client·대형 Scene Soak Test
- Network Drop·Duplicate·Reorder·Latency
- Storage Limit·Retry·Restart·Recovery Review
- Projection·Secret Canary·Permission Matrix
- Performance·Memory·Network·Instance Budget
- Accessibility·Input·Reduced Motion·Low-end Fallback
- Schema·Pack·Build Upgrade와 Legacy Migration
- Security·Abuse·Rate Limit·Incident Replay
- Release Checklist·Support Artifact·Operational Runbook

### 완료 기준

- 모든 앞선 Slice가 `DONE` 또는 명시적으로 `DEFERRED`
- 주요 Player·DM User Guide가 실제 Build 기준 `CURRENT_FOR_BUILD`
- 전체 Deterministic·Roblox Integration·Soak Suite 통과
- 알려진 데이터 손실·권한 누출·중복 Commit Blocker 없음
- Production Implementation Completion Audit 완료

### 주요 Guide

12개 Main System Guide 전체

---

## 3. Guide와 Slice 대응

| Main System Guide | 주 Slice | 보조 Slice |
|---|---|---|
| Runtime Foundation | 01, 02, 16 | 전체 |
| Session·Networking·Persistence | 01, 11, 16 | 03, 04, 07, 08 |
| Scene·Streaming·Navigation | 01, 03, 10 | 04, 06, 11, 15 |
| Exploration·Interaction·Perception | 03 | 01, 09, 11 |
| Rules·Action·Spell·Dice·Effect | 02, 14 | 03, 04, 07, 13, 15 |
| Combat·Encounter | 04 | 02, 07, 08, 15 |
| Character·Inventory·Downtime | 05, 06, 07 | 13, 14, 15 |
| UI·Camera·Presentation | 08 | 01–11, 14 |
| Journal·Ping | 09 | 03, 11, 15 |
| Scene Editor·Authoring | 10, 11 | 12, 15 |
| Diagnostics·Simulation·Operations | 16 | 전체 |
| Extension·Plugin·Content Pack | 12 | 02, 10, 13, 14, 15 |

어떤 Guide도 Slice 배정 없이 남지 않는다.

---

## 4. Slice별 문서 패턴

각 Slice 시작 시 다음 문서를 순서대로 만든다.

```text
specs/<slice>/CURRENT-<SLICE>-WORK-ORDER.md
→ Foundation·Domain Implementation Specs
→ UI·Projection·Persistence·Testing Specs
→ audits/<slice>-spec-completion-audit.md
```

Slice 완료 후 다음을 갱신한다.

- `CURRENT-SPEC-WORK-ORDER.md`
- 이 Roadmap의 상태표
- 관련 Guide의 Spec 링크와 변경 영향
- Player·DM User Guide의 Build 상태
- 상위 `CURRENT-WORK-ORDER.md`

---

## 5. Production 구현 원칙

Spec 작성 순서와 Production 구현 순서는 같은 Slice 순서를 사용한다.

```text
해당 Slice Specs 준비 완료
→ Slice Spec Completion Audit
→ 사용자 명시적 구현 요청
→ Production Code·Migration·Test
→ Slice Build Acceptance Audit
→ 다음 Slice
```

여러 Slice의 Production Code를 동시에 얕게 시작하지 않는다. 다만 공통 기반이 다음 Slice의 필수 선행 조건이면 현재 Slice 범위 안에서 최소 계약으로 구현하고 Versioned Extension Point를 남긴다.
