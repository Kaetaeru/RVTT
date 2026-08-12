# RVTT 개발·실행·검증 규칙

- 상태: `ACTIVE · STAGED_EXECUTION_POLICY`
- 최종 갱신일: 2026-08-13
- 현재 단계: `R3_VALIDATED_AWAITING_FREEZE_DECISION`
- 상위 권위: [`../../AGENTS.md`](../../AGENTS.md), [`.github/CODEX-ACTIVE-TASK.md`](../../.github/CODEX-ACTIVE-TASK.md)

## 1. 현재 R3/R4 규칙

현재는 구현 단계가 아니다.

```text
R3 validation complete
→ 사용자 R3 Freeze 결정
→ R4 E0 Checkpoint Freeze
```

R3/R4 동안:

- 새 Greenfield Source 구현 금지.
- Studio/MCP 구현 금지.
- 기존 `src/**` 수정 금지. `READ_ONLY_REFERENCE`다.
- Module/Stable Function은 R4 Checkpoint에서 JIT로 선언한다.

## 2. E0 Repository 개발

R4 E0 Checkpoint Freeze 후 Dedicated Implementation Branch에서 `greenfield/src/**`를 구현한다.

```text
Frozen E0 contract
→ Repository Source
→ focused automated tests
→ negative/fail-closed tests
→ future-compatibility contract tests
→ CORE_ENGINE_COMPLETE
```

E0는 Roblox runtime 없이 검증 가능한 mandatory pre-Studio foundation subset이다. 모든 Repository-capable 미래 feature를 E0에서 구현한다는 뜻은 아니다.

## 3. E1 Studio/MCP 개발

**CORE_ENGINE_COMPLETE 이후에만** Studio/MCP 직접 구현 루프를 활성화한다.

```text
E1 Runtime Checkpoint Freeze
→ Studio/MCP DataModel 조사
→ Roblox-dependent provider/integration 구현
→ Play
→ 관찰
→ 수정
→ GitHub greenfield source로 정규화
→ focused runtime verification
→ INTEGRATION_READY
```

Studio는 hidden production truth가 아니다. 결과는 GitHub Source/Rojo에서 재현 가능해야 한다.

## 4. U0 / E2

```text
INTEGRATION_READY
→ U0-A HTML/UI Reference Distillation
→ U0-B Product UI Shell Scaffold
→ U0-C Human Shell Review
→ UI_SHELL_READY
→ E2 Presentation / Feel Checkpoints
```

UI_SHELL_READY 이후 throwaway test UI를 별도 product path로 만들지 않는다.

## 5. Legacy regression 해석

기존 `src/**`, `tests/**`, legacy Rojo project를 검사하는 Workflow는 잠긴 reference의 regression/재현성 검증이다. 그 PASS는 새 Greenfield 구현 완료나 `CORE_ENGINE_COMPLETE`를 의미하지 않는다.

## 6. 공통 검증 원칙

- Authority/state ownership 위반은 fail closed.
- Client authority claim을 신뢰하지 않는다.
- Viewer-safe projection과 recovery semantics를 검증한다.
- 문서/static/legacy regression PASS를 현재 runtime acceptance와 혼동하지 않는다.
- Architecture/Authority 변경은 사용자 결정 없이 자동 적용하지 않는다.
