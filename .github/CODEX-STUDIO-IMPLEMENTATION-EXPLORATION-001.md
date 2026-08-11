# RVTT Studio Implementation — Exploration Iteration 001

- 상태: `ACTIVE · CURRENT_COMMAND`
- 상위 포인터: [`CODEX-ACTIVE-TASK.md`](CODEX-ACTIVE-TASK.md)
- 과거 Command: `.github/archive/codex-history/` — 실행 금지

MODE: `STUDIO_IMPLEMENTATION`

## 목표

현재 Production Exploration 흐름을 실제 Roblox Studio에서 직접 열어 사용 가능한 제품 상태로 다듬는다.

대상 사용자 흐름:

```text
Token 선택
→ Camera 조작
→ 이동
→ Right-click Context Action
→ 상호작용
→ Character Console과의 연결 확인
```

## 구현 전에 반드시 읽을 것

1. `AGENTS.md`
2. `.github/README.md`
3. `.github/CODEX-ACTIVE-TASK.md`
4. `docs/remake/CURRENT-WORK-ORDER.md`
5. `implementation/roblox/CURRENT-WORK-ORDER.md`
6. `implementation/roblox/MODULE-CONTRACTS.md`와 관련 Registry Entry
7. ADR-0088과 관련 Input·UI Authority
8. 관련 Production Source와 직접 Dependency
   - Semantic input router
   - World token runtime/input/controller
   - World camera
   - Context action resolver/menu
   - Gameplay HUD / Character Console 연결
9. 관련 Focused Test

Repository를 넓게 스캔할 수는 있지만 **Archive, 과거 Command, 과거 Acceptance Status에서 새 TODO를 만들지 않는다.** 파일명이나 API를 추측하지 말고 실제 현재 Source에서 책임을 확인한다.

## 지금 하지 않는 것

- 과거 `CODEX-IMPLEMENTATION-*` 작업 재개
- 과거 `CODEX-FIX-*` 작업 재개
- Broad Static Gate 재실행
- `slice01-world-interaction`을 개발 시작 Gate로 재실행
- Grand Acceptance Campaign 시작
- ADR-0092 Phase 착수

## Studio 작업

1. 사용 가능한 Studio MCP Capability를 확인한다.
2. Production Place와 현재 Instance Tree를 조사한다.
3. 기존 Source가 Studio에서 실제로 어떻게 보이고 동작하는지 Play한다.
4. 작은 문제 하나씩 실제 Production 경로에서 수정한다.
5. 매 수정 후 해당 흐름을 다시 Play한다.
6. Output, Server·Client 상태, UI, Camera와 입력 동작을 확인한다.

Acceptance Harness는 필요한 회귀 확인용으로만 사용한다. 개발 UI나 Product UX 기준으로 사용하지 않는다.

## 사용자에게 먼저 물어야 하는 변경

다음이 더 좋다고 판단되면 바로 적용하지 않는다.

- Left/Right/Middle/Q/E/ESC 의미 변경
- Exploration 또는 Encounter 이동 방식 변경
- Character Console의 제품 역할 변경
- 서버 Authority·Data ownership 변경
- Module 분리·통합 등 Architecture 경계 변경
- 새 핵심 UI 패턴 또는 전체 Layout 방향 변경
- 개발 프로세스 변경
- Release 범위·우선순위 변경

보고 형식:

```text
현재 문제
제안 방향
장점
비용·위험
영향 범위
```

## Canonicalization

사용 가능한 결과가 나오면:

1. Studio에서 확정된 Production Script를 Repository의 올바른 Source로 반영한다.
2. 필요한 Instance 구조를 Rojo Mapping으로 재현 가능하게 만든다.
3. 안정적인 Module 책임·Entry Point·의존·Authority가 바뀌었으면 Module Contract도 함께 갱신한다.
4. 임시 Studio-only Production 의존성을 제거한다.
5. 변경 영역 Focused Test를 실행한다.
6. 필요할 때만 Stabilization Runtime을 실행한다.

## 완료 보고

- 조사한 기존 책임
- Studio에서 확인한 실제 문제
- 수정한 사용자 흐름
- GitHub Source 변경
- Module Contract 변경 여부
- 실행한 Focused Test
- 사용자 결정 필요 항목
- 남은 Risk

PR Ready, Merge, Force Push는 하지 않는다.
