# RVTT Remake 현재 작업 순서

- 상태: `ACTIVE · CONTEXT_ONLY`
- 최종 갱신일: 2026-08-12
- 현재 실행 포인터: [`.github/CODEX-ACTIVE-TASK.md`](../../.github/CODEX-ACTIVE-TASK.md)
- 구현 작업 기준: [`implementation/roblox/CURRENT-WORK-ORDER.md`](../../implementation/roblox/CURRENT-WORK-ORDER.md)

## 이 문서의 역할

이 문서는 **현재 제품 단계와 큰 우선순위만 설명한다. 실행할 Task를 직접 발행하지 않는다.**

지금 무엇을 실행할지는 다음 순서만 따른다.

```text
사용자의 최신 지시
→ .github/CODEX-ACTIVE-TASK.md
→ commandPath
```

과거 Spec, Audit, Acceptance Snapshot, Archived Codex Command에서 현재 TODO를 복구하지 않는다.

## 현재 결정

기존 제품·Architecture·Accepted ADR은 유지한다. 바뀐 것은 개발 방식이다.

```text
이전 · 폐기된 기본 개발 루프
대량 Source 구현
→ Static Gate
→ Acceptance Build
→ 뒤늦은 Studio 검증

현재
GitHub Authority·Module Contract·Source 조사
→ Studio MCP 직접 구현
→ Play·관찰·즉시 수정
→ 사용자 판단
→ GitHub Source 정규화
→ Focused Test
→ Stabilization·Release 검증
```

이전 루프는 역사적 설명일 뿐 현재 작업 지시가 아니다.

새 제품 방향이나 Architecture 변경 아이디어가 생기면 자동 적용하지 않고 사용자에게 먼저 제안한다.

## 현재 Product Authority

Accepted 상태를 유지한다.

- ADR-0088 Direct Play
- ADR-0089 Observer-first Surface
- ADR-0090 Console Matrix·DM Windows
- ADR-0091 Asset·Official Sheet·Dice·Core Rules
- ADR-0092 Survival Logistics·DM Actor Token Authoring

이 문서는 위 제품 결정을 다시 정의하지 않는다.

## 현재 Production 단계

현재는 기존 Full UI·UX Source를 **실제 Studio 제품으로 다시 확인하고 다듬는 단계**다.

큰 우선순위:

1. Exploration 직접 조작·Camera·Context Action
2. Character Console·Encounter HUD
3. Inventory·Journal·Character Sheet·Settings
4. Entry·Role·Recovery
5. DM Live Workspace
6. ADR-0091 실제 Runtime Surface
7. ADR-0092 Production — Slice 06 → 07 → 11 → 12 → 15 → 16

이 목록은 backlog context다. **지금 당장 여러 항목을 실행하라는 명령이 아니다.** 현재 하나의 실행 작업은 Active Task가 소유한다.

기존 `slice01-world-interaction`, `contextual-pointer-actions`, Full UI Acceptance, Grand Campaign은 회귀·Stabilization·Release Tooling/Evidence로 보존한다. 개발 시작 Gate가 아니다.

## 완료 판정

개발 중:

```text
Studio Development Observation
+ GitHub Source 정규화
+ 필요한 Module Contract 정합화
+ Focused Test
```

Release 후보:

```text
Current-SHA CI
+ 필요한 Human UI·UX
+ 필요한 Multi-client
+ 필요한 Persistence·Migration
+ Accessibility·Performance
+ Release Acceptance
```

한 Evidence를 다른 Evidence로 확대 해석하지 않는다.
