# RVTT Remake Documentation

- 상태: `ACTIVE`
- 최종 갱신일: 2026-08-12
- 현재 개발 방식: `GITHUB-UNDERSTANDING → STUDIO-MCP IMPLEMENTATION → PLAY ITERATION → SOURCE CANONICALIZATION`

RVTT 문서는 역할에 따라 분리한다. 모든 문서를 순서대로 읽을 필요는 없다.

## 처음 읽을 문서

### 작업하는 에이전트

```text
AGENTS.md
→ docs/remake/CURRENT-WORK-ORDER.md
→ 관련 Authority
→ implementation/roblox/CURRENT-WORK-ORDER.md
```

### 제품 범위

- [`product/`](product) — 제품 범위·지원 정책·비목표
- [`decisions/`](decisions) — Accepted ADR
- [`architecture/`](architecture) — Runtime·Data·Authority 계약
- [`systems/`](systems) — 기능 동작
- [`ui/`](ui) — UI·입력·Presentation Authority

### 구현

- [`specs/`](specs) — 준비 완료 구현 계약
- [`implementation/roblox`](../../implementation/roblox/README.md) — 실제 Production Source·Test·Tooling

### 사용자 경험 참고

- [`user-guides/`](user-guides) — Player·DM 흐름 Reference
- [`guides/`](guides) — 문서 읽기 가이드

### 역사와 검수

- [`audits/`](audits) — 특정 시점의 감사·판정 기록
- 과거 Codex Review Command와 PR 댓글 — Historical Evidence
- [`archive/`](archive) — 현재 판단에 사용하지 않는 기록

## 권위 순서

```text
사용자의 최신 명시적 결정
→ Accepted ADR
→ Product·Architecture·System·Global UI Policy
→ 준비 완료 Implementation Spec·Delta
→ 현재 Work Order (순서·상태만)
→ Production Source·Test
→ Guide·Audit·Historical Review
```

Work Order, Audit, Review Artifact는 Accepted Product 결정을 새로 만들지 않는다.

## 현재 개발 방식

```text
GitHub에서 기존 문서·함수·Module 책임 이해
→ Roblox Studio MCP에서 실제 구현
→ Play하며 즉시 수정
→ 사용자 판단이 필요한 UX 확인
→ 확정 결과를 GitHub Source·Rojo Mapping에 반영
→ Focused Test
→ Stabilization·Release에서 종합 Acceptance
```

Rojo와 Acceptance Tooling은 유지한다. 다만 `.rbxlx`를 매 작은 수정마다 새로 만들어 사용자에게 전달하는 것을 기본 개발 방식으로 사용하지 않는다.

## 제품 고정 전제 요약

- Roblox에서 DM이 실시간으로 진행하는 게임형 D&D VTT
- `dnd5e-2024`, `ko-KR`
- PC 키보드·마우스 우선
- 리그 없는 OBJ·MeshPart 3D Token
- 연속 무격자 이동, `5 ft = 4 studs`
- Exploration Click/WASD, Encounter Preview/Confirm 이동
- Q=한 단계 취소, E=확정, ESC=Gameplay 의미 없음
- 서버 권위, Viewer별 Projection, Negative Disclosure
- Player·Observer 상시 Minimap·별도 Map·Objective Tracker 없음
- Character Console과 DM Modular Windows
- Private/Public Rule Profile 분리
- Survival Profile과 DM-authored Actor Pipeline
- AI Draft 자동 Publish 금지, 공식 Stat Block·CR 자동 재조정 금지
- Reconnect·Migration·Rollback·Accessibility·Performance는 완료 조건

세부 내용은 관련 Authority 문서를 따른다.

## 새로운 방향 제안 규칙

에이전트가 현재보다 좋아 보이는 제품·Architecture·개발 방식 변경을 발견해도 자동 반영하지 않는다. 사용자에게 먼저 제안하고 승인 후 Authority를 수정한다.
