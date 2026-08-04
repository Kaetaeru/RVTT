# RVTT Remake Documentation

- 상태: ACTIVE
- 문서 종류: Documentation Index
- 현재 단계: `SLICE 01 SCRIPT MANIFEST`
- Runtime Architecture: `COMPLETE`
- Main System Guides: `COMPLETE`
- Player·DM User Guides와 Quick Flow: `COMPLETE`
- 16 Slice Specification Checkpoints: `COMPLETE`
- UI·UX Global Policies: `COMPLETE`
- Greenfield Production Workspace: `BOOTSTRAPPED`

RVTT Remake의 제품 결정, Architecture, 기능 기획, UI·UX Policy, Main System Guide, Implementation Spec과 Audit을 역할별로 관리한다. 실제 Production Source는 별도 `implementation/` Root에서 관리한다.

## 현재 작업

- 상위 작업 순서: [`CURRENT-WORK-ORDER.md`](CURRENT-WORK-ORDER.md)
- Slice Roadmap: [`specs/SLICE-ROADMAP.md`](specs/SLICE-ROADMAP.md)
- Spec 인계 상태: [`specs/CURRENT-SPEC-WORK-ORDER.md`](specs/CURRENT-SPEC-WORK-ORDER.md)
- UI·UX Policy Hub: [`ui/policies/README.md`](ui/policies/README.md)
- UI·UX Review Checklist: [`ui/policies/UI-UX-REVIEW-CHECKLIST.md`](ui/policies/UI-UX-REVIEW-CHECKLIST.md)
- Production Workspace: [`implementation/README.md`](../../implementation/README.md)
- Roblox Implementation Work Order: [`implementation/roblox/CURRENT-WORK-ORDER.md`](../../implementation/roblox/CURRENT-WORK-ORDER.md)

현재 작업:

```text
Slice 01 First Session Walking Skeleton
→ implementation/roblox/manifests/slice-01-script-manifest.md
```

Production Luau Script는 아직 작성하지 않았다.

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

### UI·UX를 설계·구현할 때

```text
UI·UX Global Policy
→ UI Main Guide
→ 공통 입력
→ 화면별 UI 문서
→ Slice Contract
→ Review Checklist
→ Script
```

- [`UI·UX Policy Hub`](ui/policies/README.md)
- [`UI Main Guide`](guides/ui/README.md)
- [`공통 입력 교과서`](ui/common-input/common-input-grammar.md)
- [`UI 문서 Hub`](ui/README.md)

### Production Script를 작성할 때

```text
Roblox Implementation Work Order
→ 현재 Slice Contract
→ Script Manifest
→ 가장 위의 IN_PROGRESS Script
→ Test
→ Review·Commit
```

- [`Production Root`](../../implementation/README.md)
- [`Roblox Workspace`](../../implementation/roblox/README.md)
- [`Roblox Implementation Work Order`](../../implementation/roblox/CURRENT-WORK-ORDER.md)
- [`Manifest 규칙`](../../implementation/roblox/manifests/README.md)

## 문서 역할

| 경로 | 역할 | 권위 |
|---|---|---|
| [`user-guides/`](user-guides) | Quick Flow와 Player·DM 목표 사용자 경험 | 비권위 Reference |
| [`product/`](product) | 제품 범위·지원 정책·비목표 | 권위 |
| [`architecture/`](architecture) | 공통 Runtime·Source·Build·State·통합 계약 | 권위 |
| [`systems/`](systems) | 기능 영역별 동작과 사용자 흐름 | 권위 |
| [`ui/`](ui) | 화면·입력·Global UI·UX Policy와 사용자 피드백 | 권위 |
| [`decisions/`](decisions) | 되돌리기 어려운 Architecture Decision | 권위 |
| [`guides/`](guides) | 권위 문서 관계·경계·읽기 순서 | 비권위 Reference |
| [`specs/`](specs) | Slice·Module·Type·Command·저장·Test 구현 계약 | 준비 완료 시 권위 |
| [`audits/`](audits) | 충돌·완료·단계·연결 판정 | 판정 문서 |
| [`templates/`](templates) | 문서 필수 항목 누락 방지 | 형식 |
| [`archive/`](archive) | 현재 판단에 사용하지 않는 역사 기록 | 비권위 |
| [`implementation/`](../../implementation) | 실제 Roblox Source·Test·Migration·Tooling | Production Source |

## 권위 방향

```text
사용자의 최신 명시적 결정
→ 확정 ADR
→ 확정 Product·Architecture·System·UI Policy
→ 준비 완료 Implementation Spec
→ Script Manifest
→ Production Script·Test
```

- User Guide와 Main System Guide가 권위 문서와 충돌하면 권위 문서가 우선한다.
- Global UI·UX Policy는 화면별 UI 문서와 Component 구현보다 우선한다.
- 새 Product·Architecture 결정이 필요하면 Guide·Policy·Spec·Script에 숨겨 넣지 않고 직접 권위 문서와 ADR을 먼저 수정한다.

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

## UI·UX Policy 요약

- Dark Tactical Fantasy + Professional Tool 시각 언어
- Semantic Design Token만 사용
- 전장 우선 Layout과 Progressive Disclosure
- Semantic Input·Input Context·Q/E·1–5
- Pending·Receipt·Projection·Error·Resync·Recovery 상태
- Player·DM·Observer Projection 분리
- UI Scale·Keyboard Focus·Reduced Motion·Flash·Camera Comfort
- Low-end Fallback에서도 핵심 결과·Warning·Focus 유지

상세 Policy는 [`ui/policies/README.md`](ui/policies/README.md)를 따른다.

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

## Implementation 상태

```text
16 Slice 통합 명세·감사
→ COMPLETE

UI·UX Policy Foundation
→ COMPLETE

implementation/roblox Service Folder
→ CREATED

Slice 01 Script Manifest
→ IN_PROGRESS

Production Luau Script
→ NOT STARTED
```

구현은 [`implementation/roblox/CURRENT-WORK-ORDER.md`](../../implementation/roblox/CURRENT-WORK-ORDER.md)를 따른다.

## 완료 감사

1. [`Runtime Architecture Completion`](audits/runtime-architecture-completion-and-main-guide-readiness-audit.md)
2. [`Main System Guide Consistency와 Hub Completion`](audits/main-system-guide-consistency-and-document-hub-completion-audit.md)
3. [`Player·DM User Guide Completion`](audits/player-and-dm-user-guide-completion-audit.md)
4. [`All-slice Specification Checkpoint Completion`](audits/all-slice-specification-checkpoint-completion-audit.md)
5. [`UI·UX Global Policy Completion`](audits/ui-ux-policy-completion-audit.md)
6. [`Implementation Workspace Bootstrap`](audits/implementation-workspace-bootstrap-audit.md)
7. [`Document Migration Validation`](audits/document-migration-validation.md)

## 문서 수명주기

[`product/core-session-loop.md`](product/core-session-loop.md)는 최신 이동·Audio 범위와 충돌해 `DISCONTINUED`로 전환됐다.

- 보관 기록: [`archive/discontinued/product/core-session-loop.md`](archive/discontinued/product/core-session-loop.md)
- 현재 사용자 흐름: [`user-guides/QUICK-FLOW.md`](user-guides/QUICK-FLOW.md)
- 정책: [`DOCUMENT-LIFECYCLE-AND-DISCONTINUATION.md`](DOCUMENT-LIFECYCLE-AND-DISCONTINUATION.md)

`SUPERSEDED`, `DISCONTINUED`, `ARCHIVED`와 충돌하는 오래된 Draft는 현재 Authority와 추천 읽기 순서에서 제외한다.
