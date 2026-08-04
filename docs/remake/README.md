# RVTT Remake Documentation

- 상태: 활성 문서 허브
- 문서 종류: Documentation Index
- 현재 단계: `IMPLEMENTATION SPECS`
- Main System Guide 단계: `COMPLETE`

RVTT 리메이크의 제품 결정, Architecture, 시스템 기획, UI, Main System Guide, 구현 명세와 감사를 역할·영역별로 관리한다.

## 현재 작업

- 단일 작업 순서: [`CURRENT-WORK-ORDER.md`](CURRENT-WORK-ORDER.md)
- Main System Guide 허브: [`guides/README.md`](guides/README.md)
- Guide 완료 감사: [`audits/main-system-guide-consistency-and-document-hub-completion-audit.md`](audits/main-system-guide-consistency-and-document-hub-completion-audit.md)
- Implementation Specs 허브: [`specs/README.md`](specs/README.md)

현재 제품 범위의 Runtime Architecture와 12개 Main System Guide 통합은 완료됐다. 다음 활성 단계는 Implementation Specs다. Production Implementation은 아직 시작하지 않는다.

## 문서를 수정하기 전 읽기 순서

1. 저장소 루트 [`AGENTS.md`](../../AGENTS.md)
2. [`AGENTS.md`](AGENTS.md)
3. [`AGENTS-PLANNING-ADDENDUM.md`](AGENTS-PLANNING-ADDENDUM.md)
4. [`CURRENT-WORK-ORDER.md`](CURRENT-WORK-ORDER.md)
5. 현재 작업의 [`Main System Guide`](guides/README.md)
6. Guide가 연결한 Product·Architecture·System·UI·ADR
7. [`DOCUMENT-GUIDE.md`](DOCUMENT-GUIDE.md)
8. 해당 Implementation Spec

모든 작업에서 Architecture 문서 전체를 처음부터 읽지 않는다.

```text
Runtime Foundation Guide
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
- Exploration에서는 클릭 이동과 WASD 이동, Encounter에서는 클릭 경로 이동만 지원
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
- NPC 대화 시스템, 음악과 모든 사운드 이펙트는 비목표
- 최적화, 안정성, 오류 격리와 클린코드는 모든 기능의 완료 조건

제품 범위와 비목표의 상세 권위는 [`product/`](product)와 관련 ADR을 따른다.

## 문서 구조

| 경로 | 역할 |
|---|---|
| [`product/`](product) | 제품 범위, 비목표, 전체 사용자 흐름과 지원 정책 |
| [`architecture/`](architecture) | 여러 시스템이 공유하는 권위, Source·Build·State, Runtime과 Integration 계약 |
| [`systems/`](systems) | 기능 영역별 사용자 흐름과 시스템 동작 |
| [`ui/`](ui) | 화면 배치, 입력 문맥, Panel 상태와 사용자 피드백 |
| [`decisions/`](decisions) | 전역 번호를 가진 Architecture Decision Record |
| [`guides/`](guides) | 완료된 권위 문서의 관계, 전체 흐름과 구현 진입 순서 |
| [`specs/`](specs) | 구현 직전 Module·Type·Command·Network·Persistence·Test 계약 |
| [`audits/`](audits) | 기획 완성도, 충돌, 준비도, 단계 전환과 마이그레이션 감사 |
| [`templates/`](templates) | 기획·ADR·Guide·구현 명세·감사 Template |
| [`archive/`](archive) | 현재 권위가 아닌 역사적 문서 |

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

Guide
→ 위 문서를 설명하는 비권위 Leaf
```

- Guide가 권위 문서와 충돌하면 권위 문서가 우선한다.
- Guide를 Product·Architecture·System·Spec의 Parent로 기록하지 않는다.
- `SUPERSEDED`, `DISCONTINUED`, `ARCHIVED` 문서는 현재 권위와 추천 읽기 순서에서 제외한다.
- 새 결정이 필요하면 Guide나 Spec에 숨겨 넣지 않고 관련 Architecture와 ADR을 먼저 수정한다.
- Source·Build·State·Migration 변경은 영향받는 Guide와 Spec을 함께 검사한다.

## 현재 유효한 Completion Audit

1. [`Runtime Architecture Completion과 Main System Guide 준비도 감사`](audits/runtime-architecture-completion-and-main-guide-readiness-audit.md)
   - 현재 제품 범위의 Core·Support Runtime과 Cross-System Integration 완료 근거
2. [`Main System Guide 일관성과 문서 허브 완료 감사`](audits/main-system-guide-consistency-and-document-hub-completion-audit.md)
   - 12개 Guide, Authority 계층, 문서 수명주기와 Hub 완료 근거
3. [`Document Migration Validation`](audits/document-migration-validation.md)
   - 문서 이동과 링크 정합성 근거

이전 Planning·Gap Audit은 역사 기록이며 현재 작업의 판단 근거로 사용하지 않는다.

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

세부 상태와 현재 명세는 [`specs/README.md`](specs/README.md)를 따른다.

## 문서 이동과 수명주기

기존 번호형 상세 기획은 [`DOCUMENT-MIGRATION-MAP.md`](DOCUMENT-MIGRATION-MAP.md)에 따라 역할·영역별 폴더로 이동됐다.

문서 중단·대체·보관은 [`DOCUMENT-LIFECYCLE-AND-DISCONTINUATION.md`](DOCUMENT-LIFECYCLE-AND-DISCONTINUATION.md)를 따른다.

이 브랜치는 리메이크 기획·명세 브랜치다. 사용자가 명시적으로 구현을 요청하고 승인된 Implementation Spec이 준비되기 전에는 Production Code를 작성하지 않는다.
