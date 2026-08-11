# RVTT Codex Task Routing

- 상태: `CURRENT`
- 최종 갱신일: 2026-08-12

이 디렉터리에서 **현재 실행할 작업을 고르는 방법은 하나뿐**이다.

```text
사용자의 최신 명시적 지시
→ CODEX-ACTIVE-TASK.md
→ 그 파일의 commandPath
```

## 현재 작업 선택 규칙

1. 먼저 루트 `AGENTS.md`를 읽는다.
2. 다음으로 `.github/CODEX-ACTIVE-TASK.md`를 읽는다.
3. `status`가 실행 가능한 상태인지 확인한다.
4. `commandPath`가 가리키는 **한 파일만** 현재 실행 명령으로 읽는다.
5. `docs/remake/CURRENT-WORK-ORDER.md`와 `implementation/roblox/CURRENT-WORK-ORDER.md`는 현재 단계와 우선순위를 설명하지만 Active Task를 대체하지 않는다.

## 절대 금지

- 파일명이 `CODEX-*`라는 이유만으로 작업 후보로 간주하지 않는다.
- Repository 전체 검색 결과에서 과거 Command를 수집해 TODO 목록으로 만들지 않는다.
- `.github/archive/**`를 현재 작업, 현재 우선순위, 미완료 TODO의 근거로 사용하지 않는다.
- 과거 PR Comment, Review Result, Audit, Acceptance Snapshot을 현재 실행 명령으로 승격하지 않는다.

## 보존 기록

과거 Codex Command는 `.github/archive/codex-history/`에 보존한다. 해당 디렉터리는 역사적 Evidence와 원인 추적용이며 **사용자가 과거 이력을 명시적으로 요청한 경우에만 읽는다.**

새 Active Task가 생기면 `CODEX-ACTIVE-TASK.md`의 포인터를 바꾼다. 과거 Command를 `.github/` 루트에 다시 늘어놓지 않는다.
