# RVTT Remake Documentation

- 상태: ACTIVE
- 문서 종류: Documentation Index
- 현재 단계: `IMPLEMENTATION SPECS`
- Runtime Architecture: `COMPLETE`
- Main System Guides: `COMPLETE`
- Player·DM User Guides와 Quick Flow: `COMPLETE`
- 구현 명세 전 최종 문서 연결 감사: `COMPLETE`

RVTT Remake의 제품 결정, Architecture, 기능 기획, UI, 사용자 경험, Main System Guide, Implementation Spec과 Audit을 역할별로 관리한다.

## 현재 작업

- 단일 작업 순서: [`CURRENT-WORK-ORDER.md`](CURRENT-WORK-ORDER.md)
- Implementation Spec Hub: [`specs/README.md`](specs/README.md)
- Implementation Spec Template: [`templates/implementation-spec-template.md`](templates/implementation-spec-template.md)
- 최종 문서 연결 감사: [`audits/pre-implementation-document-linkage-audit.md`](audits/pre-implementation-document-linkage-audit.md)

현재 첫 작업은 `specs/CURRENT-SPEC-WORK-ORDER.md`를 만들고, 초기 Shared Spec 001·002를 재검토한 뒤 첫 수직 Slice를 확정하는 것이다. Production Implementation은 아직 시작하지 않는다.

## 처음 읽는 경로

### RVTT가 어떻게 플레이되는지 볼 때

```text
한눈에 보는 세션 흐름
→ Player Guide 또는 DM Guide
```

- [`한눈에 보는 세션 흐름`](user-guides/QUICK-FLOW.md)
- [`Player Guide`](user-guides/player/README.md)
- [`DM Guide`](user-guides/dm/README.md)
- [`User Guide Hub`](user-guides/README.md)

### 구현 명세를 작성할 때

```text
CURRENT-WORK-ORDER
→ Quick Flow의 대상 사용자 구간
→ 관련 Player 또는 DM Guide
→ Runtime Foundation Guide
→ 현재 Domain Main System Guide
→ 직접 인접 Guide
→ Guide가 연결한 Product·Architecture·System·UI·ADR
→ 기존 관련 Spec
→ Implementation Spec Template
→ 새 수직 Spec
```

읽을 문서:

1. 저장소 루트 [`AGENTS.md`](../../AGENTS.md)
2. [`AGENTS.md`](AGENTS.md)
3. [`AGENTS-PLANNING-ADDENDUM.md`](AGENTS-PLANNING-ADDENDUM.md)
4. [`CURRENT-WORK-ORDER.md`](CURRENT-WORK-ORDER.md)
5. [`Quick Flow`](user-guides/QUICK-FLOW.md)
6. 관련 [`User Guide`](user-guides/README.md)
7. [`Main System Guide Hub`](guides/README.md)
8. Guide가 연결한 직접 Authority Documents와 ADR
9. [`DOCUMENT-GUIDE.md`](DOCUMENT-GUIDE.md)
10. [`Implementation Spec Template`](templates/implementation-spec-template.md)

## 문서 역할

| 경로 | 역할 | 권위 |
|---|---|---|
| [`user-guides/`](user-guides) | Quick Flow와 Player·DM 목표 사용자 경험 | 비권위 Reference |
| [`product/`](product) | 제품 범위·지원 정책·비목표 | 권위 |
| [`architecture/`](architecture) | 공통 Runtime·Source·Build·State·통합 계약 | 권위 |
| [`systems/`](systems) | 기능 영역별 동작과 사용자 흐름 | 권위 |
| [`ui/`](ui) | 화면·입력 문맥·표시와 사용자 피드백 | 권위 |
| [`decisions/`](decisions) | 되돌리기 어려운 Architecture Decision | 권위 |
| [`guides/`](guides) | 권위 문서 관계·경계·읽기 순서 | 비권위 Reference |
| [`specs/`](specs) | Module·Type·Command·저장·Test 구현 계약 | 준비 완료 시 권위 |
| [`audits/`](audits) | 충돌·완료·단계·연결 판정 | 판정 문서 |
| [`templates/`](templates) | 문서 필수 항목 누락 방지 | 형식 |
| [`archive/`](archive) | 현재 판단에 사용하지 않는 역사 기록 | 비권위 |

## 권위 방향

```text
사용자의 최신 명시적 결정
→ 확정 ADR
→ 확정 Product·Architecture·System·UI
→ 준비 완료 Implementation Spec
```

```text
User Guide
→ 사용자가 무엇을 보고 무엇을 하는지 설명

Main System Guide
→ 어느 Authority Document를 어떤 순서로 읽는지 설명

Audit
→ 충돌·완료·준비도와 연결을 검사
```

- User Guide와 Main System Guide가 권위 문서와 충돌하면 권위 문서가 우선한다.
- User Guide와 Main System Guide를 Authority Tree의 Parent로 기록하지 않는다.
- 새 Product·Architecture 결정이 필요하면 Guide나 Spec에 숨겨 넣지 않고 직접 권위 문서와 ADR을 먼저 수정한다.

## 제품 고정 전제

- Roblox에서 DM이 실시간으로 진행하는 Baldur's Gate형 D&D VTT
- 기본 Ruleset `dnd5e-2024`, 기본 표시 언어 `ko-KR`
- 초기 지원 플랫폼 PC 키보드·마우스
- Roblox Avatar가 아닌 리그 없는 OBJ·MeshPart 3D Token
- 권위 이동은 연속 무격자 좌표, 월드 비율은 `5 ft = 4 studs`
- Exploration: 목적지 클릭과 Token WASD 이동
- Encounter: 경로 확인 후 클릭 이동, Token WASD 금지
- Q는 취소·거절·한 단계 뒤로, E는 승인·확정·실행·상호작용
- 중요 규칙과 영구 상태는 서버 권위
- Character Owner, Runtime Controller와 Session Role 분리
- 중도 참가·재접속·서버 복구·DM Rollback 지원
- Scene Source, Compiled Build, Authoritative State, Projection, Presentation 분리
- 2024 기본 규칙의 Player Character 콘텐츠 전체를 최종 지원 범위로 설정
- NPC 자동 대화, 음악, 환경음과 모든 SFX는 비목표
- 성능·안정성·오류 격리·수정 가능한 코드 구조는 완료 조건

상세 Product Authority는 [`product/README.md`](product/README.md)를 따른다.

## Main System Guides

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

12개 Guide는 모두 `CURRENT`다. 도메인별 User Flow 대응표와 읽기 순서는 [`guides/README.md`](guides/README.md)를 따른다.

## Implementation Specs

Spec은 다음을 포함한다.

- Quick Flow와 Player·DM Acceptance Flow
- 직접 Authority Requirement 추적성
- Package·Module·Service 책임
- Luau Type와 Versioned Schema
- Command·Read·Network·Projection 계약
- Persistence·Migration·Recovery·Rollback
- Ordering·Reservation·Transaction·Outbox·Projection Barrier
- Diagnostics·Stable Error·Budget·Health
- Deterministic Scenario와 Roblox Integration Test

현재 초기 Shared Spec 001·002는 [`Shared Spec Index`](specs/shared/README.md)에서 `REVIEW_REQUIRED`로 관리한다.

## 문서 수명주기

[`product/core-session-loop.md`](product/core-session-loop.md)는 최신 이동·Audio 범위와 충돌해 `DISCONTINUED`로 전환됐다.

- 보관 기록: [`archive/discontinued/product/core-session-loop.md`](archive/discontinued/product/core-session-loop.md)
- 현재 사용자 흐름: [`user-guides/QUICK-FLOW.md`](user-guides/QUICK-FLOW.md)
- 정책: [`DOCUMENT-LIFECYCLE-AND-DISCONTINUATION.md`](DOCUMENT-LIFECYCLE-AND-DISCONTINUATION.md)

`SUPERSEDED`, `DISCONTINUED`, `ARCHIVED`와 충돌하는 오래된 Draft는 현재 Authority와 추천 읽기 순서에서 제외한다.

## 완료 감사

1. [`Runtime Architecture Completion`](audits/runtime-architecture-completion-and-main-guide-readiness-audit.md)
2. [`Main System Guide Consistency와 Hub Completion`](audits/main-system-guide-consistency-and-document-hub-completion-audit.md)
3. [`Player·DM User Guide Completion`](audits/player-and-dm-user-guide-completion-audit.md)
4. [`Quick Flow와 Flowchart Completion`](audits/user-guide-quick-flow-and-flowchart-audit.md)
5. [`Pre-Implementation Document Linkage`](audits/pre-implementation-document-linkage-audit.md)
6. [`Document Migration Validation`](audits/document-migration-validation.md)

최종 연결 감사 결과 Implementation Specs는 `READY TO START`, Production Implementation은 `NOT STARTED`다.