# RVTT Codex Task Routing

- 상태: `CURRENT · R3_VALIDATED_AWAITING_FREEZE_DECISION`
- 최종 갱신일: 2026-08-13

현재 실행 권위는 파일명이나 과거 command를 추측해서 고르지 않는다.

```text
사용자의 최신 명시적 지시
→ AGENTS.md
→ .github/CODEX-ACTIVE-TASK.md
→ Active Task가 명시한 현재 권위/read path
```

## 현재 작업 선택 규칙

1. 루트 `AGENTS.md`를 먼저 읽는다.
2. `.github/CODEX-ACTIVE-TASK.md`를 읽는다.
3. Active Task의 `status`, Source/Studio gate, canonical read path를 그대로 따른다.
4. 현재 Active Task에 존재하지 않는 `commandPath`를 추측하거나 과거 command에서 복구하지 않는다.
5. 현재 상태는 `R3_VALIDATED_AWAITING_FREEZE_DECISION`이며 Source와 Studio/MCP 구현은 금지된다.
6. 사용자 R3 Freeze 결정 후에만 R4 E0 Checkpoint Freeze로 이동한다.

## 금지

- 파일명이 `CODEX-*`라는 이유만으로 현재 작업으로 간주하지 않는다.
- `.github/archive/**`, 과거 PR comment/review/audit/acceptance snapshot에서 현재 TODO를 복구하지 않는다.
- retired Greenfield command, 25 Module / 10 System / 64 Stable Function 모델을 현재 구현 권위로 사용하지 않는다.
- `CORE_ENGINE_COMPLETE` 전에 Studio/MCP 구현을 시작하지 않는다.

## 보존 기록

과거 Codex Command는 `.github/archive/codex-history/`의 역사적 evidence다. 현재 작업으로 승격하지 않는다.

현재 planning authority는 `AGENTS.md`와 `CODEX-ACTIVE-TASK.md`가 소유한다.
