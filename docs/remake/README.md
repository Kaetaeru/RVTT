# RVTT Remake Documentation

- 상태: 활성 문서 허브
- 문서 종류: Documentation Index
- 현재 단계: `IMPLEMENTATION SPECS`
- Main System Guide 단계: `COMPLETE`
- Player·DM User Guide 단계: `COMPLETE`

RVTT 리메이크의 제품 결정, Architecture, 시스템 기획, UI, 사용자 가이드, Main System Guide, 구현 명세와 감사를 역할·영역별로 관리한다.

## 현재 작업

- 단일 작업 순서: [`CURRENT-WORK-ORDER.md`](CURRENT-WORK-ORDER.md)
- 한눈에 보는 세션 흐름: [`user-guides/QUICK-FLOW.md`](user-guides/QUICK-FLOW.md)
- Player·DM User Guide: [`user-guides/README.md`](user-guides/README.md)
- Quick Flow 완료 감사: [`audits/user-guide-quick-flow-and-flowchart-audit.md`](audits/user-guide-quick-flow-and-flowchart-audit.md)
- Main System Guide 허브: [`guides/README.md`](guides/README.md)
- Guide 완료 감사: [`audits/main-system-guide-consistency-and-document-hub-completion-audit.md`](audits/main-system-guide-consistency-and-document-hub-completion-audit.md)
- Implementation Specs 허브: [`specs/README.md`](specs/README.md)

현재 제품 범위의 Runtime Architecture, 12개 Main System Guide와 Player·DM 목표 사용자 경험은 완료됐다. 다음 활성 단계는 Implementation Specs다. Production Implementation은 아직 시작하지 않는다.

## 역할별 시작점

### RVTT의 플레이 흐름을 처음 확인할 때

1. [`한눈에 보는 세션 흐름`](user-guides/QUICK-FLOW.md)
2. 역할별 상세 Guide
   - [`Player Guide`](user-guides/player/README.md)
   - [`DM Guide`](user-guides/dm/README.md)

### 플레이어 경험을 자세히 확인할 때

1. [`한눈에 보는 세션 흐름`](user-guides/QUICK-FLOW.md)
2. [`Player Guide`](user-guides/player/README.md)
3. 필요한 경우 관련 Main System Guide
4. 관련 Product·UI 문서

### DM 경험을 자세히 확인할 때

1. [`한눈에 보는 세션 흐름`](user-guides/QUICK-FLOW.md)
2. [`DM Guide`](user-guides/dm/README.md)
3. 필요한 경우 관련 Main System Guide
4. 관련 Product·UI 문서

### 기획·Architecture·Spec을 수정할 때

1. 저장소 루트 [`AGENTS.md`](../../AGENTS.md)
2. [`AGENTS.md`](AGENTS.md)
3. [`AGENTS-PLANNING-ADDENDUM.md`](AGENTS-PLANNING-ADDENDUM.md)
4. [`CURRENT-WORK-ORDER.md`](CURRENT-WORK-ORDER.md)
5. [`한눈에 보는 세션 흐름`](user-guides/QUICK-FLOW.md)
6. 관련 [`User Guide`](user-guides/README.md)
7. 관련 [`Main System Guide`](guides/README.md)
8. Guide가 연결한 Product·Architecture·System·UI·ADR
9. [`DOCUMENT-GUIDE.md`](DOCUMENT-GUIDE.md)
10. 해당 Implementation Spec

모든 작업에서 Architecture 문서 전체를 처음부터 읽지 않는다.

```text
Quick Flow의 사용자 목표
+ 관련 User Guide
+ Runtime Foundation Guide
+ 현재 Domain Guide
+ 직접 인접 Guide
+ 연결된 Authority Documents
→ Implementation Spec
```

을 기본 탐색 경로로 사용한다.

## 제품 고정 전제

- Roblox에서 DM이 실시간으로 진행하는 Baldur's Gate형 D&D VTT
- 기본 Ruleset `dnd5e-2024`, 기본 표시 언어 `ko-KR`
- 초기 지원 플랫폼은 PC 키보드·마우스
- Roblox 아바타가 아닌 리그 없는 OBJ·MeshPart 3D Token
- 권위 이동은 연속 무격자 좌표, 월드 비율은 `5 ft = 4 studs`
- Exploration에서는 클릭 이동과 Token WASD, Encounter에서는 클릭 경로 이동만 지원
- Encounter 중 WASD는 Camera 이동에 사용할 수 있음
- `Q`는 취소·거절·한 단계 뒤로, `E`는 승인·확정·실행·상호작용
- `1–5`는 현재 화면에 의미가 표시된 경우에만 주요 행동 슬롯으로 사용
- 서버가 중요 규칙과 영구 상태의 최종 권위를 소유
- Client는 Intent를 제출하고 Permission-aware Projection을 받음
- Scene Source, Compiled Build, Authoritative Dynamic State와 Presentation을 분리
- Character, Actor, ItemInstance, EffectInstance와 Runtime Object Identity를 분리
- RuntimeObjectId를 재사용하지 않고 Incarnation과 AuthorityEpoch로 오래된 참조를 차단
- 사용자 Lobby Ready와 기술적 Client Ready를 분리
- Scene Entry Essential 준비 전 관련 Gameplay Command를 허용하지 않음
- 권위 공간 질문은 Snapshot-bound Spatial Query를 사용하고 전체 경로 탐색은 Navigation Planner가 담당
- 진행 중 Encounter·Downtime·RuleExecution·Build·Playback은 시작 당시 Version을 유지
- Candidate Compile·Migration 실패 시 Last Known Good를 유지
- Rollback은 역연산이 아니라 새 Branch·AuthorityEpoch 복원
- Player Client에 Raw 비밀 Authority를 전달한 뒤 UI에서만 숨기지 않음
- 일반 사용자가 임의 Luau를 설치하는 Plugin Sandbox는 제공하지 않음
- 2024 기본 규칙의 플레이어 캐릭터 콘텐츠 전체를 최종 지원 범위로 삼음
- NPC 대화 시스템, 음악, 환경음과 모든 규칙 효과음은 비목표
- 최적화, 안정성, 오류 격리와 클린코드는 모든 기능의 완료 조건

제품 범위와 비목표의 상세 권위는 [`product/`](product)와 관련 ADR을 따른다.

## 문서 구조

| 경로 | 역할 |
|---|---|
| [`user-guides/`](user-guides) | 코딩 용어 없는 Quick Flow와 Player·DM 실제 세션 설명 |
| [`product/`](product) | 제품 범위, 비목표, 지원 정책과 사용자 경험의 권위 결정 |
| [`architecture/`](architecture) | 여러 시스템이 공유하는 권위, Source·Build·State, Runtime과 Integration 계약 |
| [`systems/`](systems) | 기능 영역별 사용자 흐름과 시스템 동작 |
| [`ui/`](ui) | 화면 배치, 입력 문맥, Panel 상태와 사용자 피드백 |
| [`decisions/`](decisions) | 전역 번호를 가진 Architecture Decision Record |
| [`guides/`](guides) | 완료된 권위 문서의 관계, 전체 흐름과 구현 진입 순서 |
| [`specs/`](specs) | 구현 직전 Module·Type·Command·Network·Persistence·Test 계약 |
| [`audits/`](audits) | 기획 완성도, 사용자 경험, 충돌, 준비도, 단계 전환과 마이그레이션 감사 |
| [`templates/`](templates) | 기획·ADR·Guide·구현 명세·감사 Template |
| [`archive/`](archive) | 현재 권위가 아닌 역사적 문서 |

## Player·DM User Guide

### Quick Flow

- [`user-guides/QUICK-FLOW.md`](user-guides/QUICK-FLOW.md)
- 30초 세션 요약
- 전체 Session Flowchart
- Player Flowchart
- DM Flowchart
- Exploration·Encounter 반복
- Scene 전환·재접속·DM 복구

### Player Guide

- [`user-guides/player/README.md`](user-guides/player/README.md)
- 세션 접속·Character 선택·Ready
- Q·E·1–5와 Camera
- Exploration 이동·상호작용·Fog
- 행동·주문·Roll·Reaction
- Encounter·Character Sheet·Inventory·Downtime
- Journal·Ping·Reconnect·Rollback

### DM Guide

- [`user-guides/dm/README.md`](user-guides/dm/README.md)
- Campaign·Scene·Character 준비
- Lobby·Role·Owner·Control
- DM Workspace·Quick Action·Player View Preview
- Exploration·Fog·Adjudication
- Encounter·Objective·Time·Rollback
- Journal·Scene Editor·Compile·Publish·Live Patch
- Recovery·세션 종료

현재 Quick Flow와 두 상세 Guide는 구현 전 목표 사용자 경험인 `TARGET_EXPERIENCE`다. 실제 Build와 Release가 준비되면 구현·사용성 테스트를 기준으로 다시 검증한다.

## Main System Guide 읽기 순서

1. [`Runtime Foundation과 Authority`](guides/runtime/README.md)
2. [`Session, Networking, Persistence와 Recovery`](guides/session/README.md)
3. [`Scene, Streaming, Runtime Object, Spatial Query와 Navigation`](guides/scene/README.md)
4. [`Exploration, Selection, Interaction과 Perception`](guides/exploration/README.md)
5. [`Rules, Character Action, Spell, Dice와 Effect`](guides/rules/README.md)
6. [`Combat와 Encounter`](guides/combat/README.md)
7. [`Character, Inventory와 Downtime`](guides/character/README.md)
8. [`UI, Camera와 Presentation`](guides/ui/README.md)
9. [`Journal과 Ping`](guides/journal/README.md)
10. [`Scene Editor와 Authoring`](guides/scene-editor/README.md)
11. [`Diagnostics, Simulation과 Operations`](guides/diagnostics/README.md)
12. [`Extension, Plugin과 Content Pack`](guides/extension/README.md)

정식 설명과 작업별 예시는 [`guides/README.md`](guides/README.md)를 따른다.

## 권위 문서 사용 규칙

```text
Product·Runtime Principles
→ Architecture
→ System·UI
→ Spec

User Guide
→ 사용자의 목표 경험을 설명하는 비권위 문서

Main System Guide
→ 권위 문서 관계를 설명하는 비권위 Leaf
```

- User Guide나 Main System Guide가 권위 문서와 충돌하면 권위 문서가 우선한다.
- User Guide와 Main System Guide를 Product·Architecture·System·Spec의 Parent로 기록하지 않는다.
- `SUPERSEDED`, `DISCONTINUED`, `ARCHIVED` 문서는 현재 권위와 추천 읽기 순서에서 제외한다.
- 새 결정이 필요하면 User Guide·Main Guide·Spec에 숨겨 넣지 않고 관련 Product·Architecture와 ADR을 먼저 수정한다.
- 사용자 경험에 영향을 주는 Source·Build·State·Migration 변경은 User Guide와 관련 Spec을 함께 검사한다.

## 현재 유효한 Completion Audit

1. [`Runtime Architecture Completion과 Main System Guide 준비도 감사`](audits/runtime-architecture-completion-and-main-guide-readiness-audit.md)
   - 현재 제품 범위의 Core·Support Runtime과 Cross-System Integration 완료 근거
2. [`Main System Guide 일관성과 문서 허브 완료 감사`](audits/main-system-guide-consistency-and-document-hub-completion-audit.md)
   - 12개 Guide, Authority 계층, 문서 수명주기와 Hub 완료 근거
3. [`Player·DM User Guide 완료 감사`](audits/player-and-dm-user-guide-completion-audit.md)
   - 역할별 목표 경험, 입력·이동, 비밀 정보, Recovery와 비목표 완료 근거
4. [`User Guide Quick Flow와 Flowchart 보완 감사`](audits/user-guide-quick-flow-and-flowchart-audit.md)
   - 코딩 용어 없는 전체·Player·DM 흐름과 반복·예외 Flowchart 완료 근거
5. [`Document Migration Validation`](audits/document-migration-validation.md)
   - 문서 이동과 링크 정합성 근거

이전 Planning·Gap Audit은 역사 기록이며 현재 작업의 판단 근거로 사용하지 않는다.

## 현재 알려진 문서 수명주기 정리 대상

[`product/core-session-loop.md`](product/core-session-loop.md)는 `상태: 초안`이며 현재 확정 범위와 다른 Encounter Token WASD·Audio 표현이 남아 있다.

현재 User Guide와 Implementation Spec은 다음을 사용한다.

- [`한눈에 보는 세션 흐름`](user-guides/QUICK-FLOW.md)
- [`플랫폼·이동·입력 범위`](product/platform-movement-and-input-scope.md)
- [`콘텐츠 범위·자동화·Rollback·저장·제외 기능`](product/content-automation-rollback-storage-and-exclusions.md)
- 현재 Main System Guides
- Player·DM User Guides

오래된 초안은 후속 문서 수명주기 정리 전까지 현재 Authority와 추천 읽기 순서에서 제외한다.

## 구현 명세 준비도

기획 문서는 다음 구현 명세 준비도 중 하나를 표시한다.

- `READY`: 중요한 제품 결정이 끝남
- `READY_WITH_DEFAULTS`: 구조는 확정됐고 수치·표시 기본값만 남음
- `BLOCKED`: 구현자가 추측해야 하는 제품 결정이나 문서 충돌이 남음

`BLOCKED` 문서를 근거로 구현 명세나 프로덕션 구현을 시작하지 않는다.

Implementation Spec은 다음을 명확히 해야 한다.

- Module·Service·Package 경계
- Luau Type와 Versioned Schema
- Registry와 Compiler Interface
- Command·Result·Error Code
- Network와 Projection 계약
- Persistence·Migration
- Transaction·Ordering·Reservation
- Diagnostics·Budget
- Deterministic Scenario와 Acceptance Test
- Quick Flow와 Player·DM User Guide의 Acceptance Flow

세부 상태와 현재 명세는 [`specs/README.md`](specs/README.md)를 따른다.

## 문서 이동과 수명주기

기존 번호형 상세 기획은 [`DOCUMENT-MIGRATION-MAP.md`](DOCUMENT-MIGRATION-MAP.md)에 따라 역할·영역별 폴더로 이동됐다.

문서 중단·대체·보관은 [`DOCUMENT-LIFECYCLE-AND-DISCONTINUATION.md`](DOCUMENT-LIFECYCLE-AND-DISCONTINUATION.md)를 따른다.

이 브랜치는 리메이크 기획·명세 브랜치다. 사용자가 명시적으로 구현을 요청하고 승인된 Implementation Spec이 준비되기 전에는 Production Code를 작성하지 않는다.
