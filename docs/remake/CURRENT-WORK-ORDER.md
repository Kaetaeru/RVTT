# RVTT Remake 현재 작업 순서

- 상태: `ACTIVE · CONTEXT_ONLY`
- 최종 갱신일: 2026-08-12
- 현재 실행 포인터: [`.github/CODEX-ACTIVE-TASK.md`](../../.github/CODEX-ACTIVE-TASK.md)

## 현재 결정

기존 Product·Architecture·Accepted ADR은 제품 요구사항으로 보존한다. **현재 Roblox 구현은 Architecture-first Greenfield로 처음부터 다시 구축한다.**

기존 Production Source는 Legacy Reference이며 현재 Build Baseline이 아니다.

## 현재 구현 순서

```text
Greenfield Module Contract
→ Foundation Composition/Authority/Input/Projection/World 경계
→ Foundation Boot
→ S1 Selection
→ 사용자 확인·즉시 수정
→ C1 Camera
→ M1 Move
→ X1 Context
→ I1 Interaction
```

사용자가 현재 Checkpoint를 마음에 들어 하지 않으면 다음 항목으로 넘어가지 않는다.

## 이후 큰 기능군

현재 Exploration 흐름이 수용된 뒤 별도 Active Task로 선택한다.

1. Encounter·Character Console
2. Inventory·Journal·Character Sheet·Settings
3. Entry·Role·Recovery
4. DM Workspace
5. ADR-0091 Runtime Surface
6. ADR-0092 Production

이 목록은 Context이며 자동 TODO가 아니다.

## Historical Tooling

기존 Acceptance, Grand, Persistence, 과거 Runtime Evidence는 Stabilization·Release 및 회귀 참고용이다. Greenfield 기능의 현재 PASS를 대신하지 않는다.
