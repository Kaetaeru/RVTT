# RVTT Remake Documentation

- 상태: 활성 문서 허브
- 문서 종류: Documentation Index
- 즉시 구현 명세 가능성: 해당 없음

RVTT 리메이크의 제품 결정, 시스템 기획, UI, 구현 명세와 감사를 역할·영역별로 관리한다.

문서를 작성하거나 수정하기 전에 다음 순서로 읽는다.

1. 저장소 루트 [`AGENTS.md`](../../AGENTS.md)
2. [`AGENTS.md`](AGENTS.md)
3. [`AGENTS-PLANNING-ADDENDUM.md`](AGENTS-PLANNING-ADDENDUM.md)
4. [`Runtime Architecture Principles`](architecture/runtime-architecture-principles.md)
5. [`DOCUMENT-GUIDE.md`](DOCUMENT-GUIDE.md)
6. 관련 ADR과 영역 README

## 제품 고정 전제

- Roblox에서 DM이 실시간으로 진행하는 Baldur's Gate형 D&D VTT
- 기본 규칙 세트 `dnd5e-2024`, 기본 표시 언어 `ko-KR`
- 초기 지원 플랫폼은 PC 키보드·마우스
- Roblox 아바타가 아닌 리그 없는 OBJ·MeshPart 3D 토큰
- 권위 이동은 연속 무격자 좌표, 월드 비율은 `5 ft = 4 studs`
- 탐험에서는 클릭 이동과 WASD 이동, 전투에서는 클릭 경로 이동만 지원
- 서버가 중요 규칙과 영구 상태의 최종 권한을 소유
- Scene Editor는 Semantic Object와 명시적 예외를 편집하고, Compiler가 Runtime Layer와 Index를 생성
- 가져온 원본 Model은 기술용 Attribute와 Value가 없어도 등록 가능
- Workspace와 Roblox Physics는 권위 규칙 상태의 원본이 아님
- 2024 기본 규칙의 플레이어 캐릭터 콘텐츠 전체를 최종 지원 범위로 삼음
- NPC 대화 시스템, 음악과 모든 사운드 이펙트는 비목표
- 최적화, 안정성, 오류 격리와 클린코드를 모든 기능의 완료 조건으로 적용

## 문서 구조

| 경로 | 역할 |
|---|---|
| [`product/`](product) | 제품 범위, 비목표, 전체 사용자 흐름과 지원 정책 |
| [`architecture/`](architecture) | Runtime 원칙, 권위·Query·Recipe·Capability·저장·확장 계약 |
| [`systems/`](systems) | 기능 영역별 사용자 흐름과 시스템 동작 |
| [`ui/`](ui) | 화면 배치, 입력 문맥, 패널 상태와 사용자 피드백 |
| [`decisions/`](decisions) | 전역 번호를 가진 Architecture Decision Record |
| [`audits/`](audits) | 기획 완성도, 충돌, 준비도와 마이그레이션 감사 |
| [`specs/`](specs) | 구현 직전 모듈·타입·명령·네트워크·테스트 계약 |
| [`templates/`](templates) | 기획·ADR·구현 명세·감사 템플릿 |
| [`archive/`](archive) | 현재 권위가 아닌 역사적 문서 |

## 추천 읽기 순서

### 전체 아키텍처

1. [`architecture/runtime-architecture-principles.md`](architecture/runtime-architecture-principles.md)
2. [`decisions/ADR-0054-compiled-semantic-runtime-and-query-authority-principles.md`](decisions/ADR-0054-compiled-semantic-runtime-and-query-authority-principles.md)
3. [`audits/cross-system-foundation-contract-gap-audit.md`](audits/cross-system-foundation-contract-gap-audit.md)

### 제품과 세션

1. [`product/platform-movement-and-input-scope.md`](product/platform-movement-and-input-scope.md)
2. [`product/core-session-loop.md`](product/core-session-loop.md)
3. [`systems/session/campaign-lobby-hot-join-ownership-and-control.md`](systems/session/campaign-lobby-hot-join-ownership-and-control.md)
4. [`systems/camera/free-tactical-camera-model.md`](systems/camera/free-tactical-camera-model.md)

### 장면 제작

1. [`systems/scene/scenes-and-world.md`](systems/scene/scenes-and-world.md)
2. [`systems/navigation/navigation-authoring-pipeline.md`](systems/navigation/navigation-authoring-pipeline.md)
3. [`systems/scene/ingame-scene-editor-tools.md`](systems/scene/ingame-scene-editor-tools.md)
4. [`ui/scene-editor/scene-editor-interaction-and-layout.md`](ui/scene-editor/scene-editor-interaction-and-layout.md)
5. [`architecture/scene-editor-tool-module-architecture.md`](architecture/scene-editor-tool-module-architecture.md)

### 규칙과 전투

1. [`architecture/rules-content-grant-capability-model.md`](architecture/rules-content-grant-capability-model.md)
2. [`architecture/rules-content-execution-and-spell-contract.md`](architecture/rules-content-execution-and-spell-contract.md)
3. [`architecture/effect-recipe-resolution-and-commit-model.md`](architecture/effect-recipe-resolution-and-commit-model.md)
4. [`systems/combat/encounter-initiative-turn-and-control-authority-model.md`](systems/combat/encounter-initiative-turn-and-control-authority-model.md)
5. [`systems/combat/dice-roll-presentation-and-resolution-gating-model.md`](systems/combat/dice-roll-presentation-and-resolution-gating-model.md)
6. [`systems/combat/encounter-turn-snapshot-and-dm-rollback-model.md`](systems/combat/encounter-turn-snapshot-and-dm-rollback-model.md)

### 플레이어와 DM UI

1. [`ui/common-input/common-input-grammar.md`](ui/common-input/common-input-grammar.md)
2. [`ui/combat-hud/baldurs-gate-style-combat-hud.md`](ui/combat-hud/baldurs-gate-style-combat-hud.md)
3. [`ui/character-sheet/official-2024-character-sheet-and-live-player-ui.md`](ui/character-sheet/official-2024-character-sheet-and-live-player-ui.md)
4. [`ui/dm-workspace/dm-workspace-and-scene-lighting.md`](ui/dm-workspace/dm-workspace-and-scene-lighting.md)
5. [`ui/dm-workspace/dm-quick-action-and-context-command.md`](ui/dm-workspace/dm-quick-action-and-context-command.md)

## 문서 상태와 구현 준비도

기획 문서는 다음 구현 명세 준비도 중 하나를 표시한다.

- `READY`: 중요한 제품 결정이 끝남
- `READY_WITH_DEFAULTS`: 구조는 확정됐고 수치·표시 기본값만 남음
- `BLOCKED`: 구현자가 추측해야 하는 제품 결정이나 문서 충돌이 남음

`BLOCKED` 문서를 근거로 프로덕션 구현을 시작하지 않는다.

## 문서 이동 상태

기존 번호형 상세 기획 46개는 [`DOCUMENT-MIGRATION-MAP.md`](DOCUMENT-MIGRATION-MAP.md)에 따라 역할·영역별 폴더로 이동되었다. 내부 상대 링크, ADR 참조와 문서 메타데이터 정합성 검사는 마이그레이션 감사 절차를 따른다.

이 브랜치는 리메이크 기획 브랜치다. 사용자가 명시적으로 구현을 요청하기 전에는 프로덕션 코드를 작성하지 않는다.
