# RVTT Planning Agent Addendum

이 문서는 리메이크 기획과 구현명세 작업에서 루트 `AGENTS.md`에 추가로 적용된다. 최신 확정 ADR과 충돌하는 기존 문구는 최신 ADR을 따른다.

## 필수 규칙

1. 새 기획 문서와 실질적으로 수정한 기획 문서에는 다음 중 하나를 적는다.

```text
즉시 구현 명세 가능성: READY
즉시 구현 명세 가능성: READY_WITH_DEFAULTS
즉시 구현 명세 가능성: BLOCKED
```

- `READY`: 추가 제품 결정 없이 구현명세 작성 가능
- `READY_WITH_DEFAULTS`: 구조는 확정됐고 기본 수치·표시값만 남음. 남은 기본값을 함께 기재
- `BLOCKED`: 구현자가 중요한 동작을 추측해야 함. 차단 이유와 결정 질문을 함께 기재

2. 한 요청에 두 번 이상의 연속 작업 또는 둘 이상의 독립 파일 수정이 필요하면 작업 시작 전에 사용자에게 짧은 체크리스트를 제시한다.

3. 문서 완료 전에 준비도를 다시 평가한다. 권위, 상태 전이, 실패, 저장, 재접속, 롤백과 비목표 중 하나라도 중대한 추측이 필요하면 `READY`로 표시하지 않는다.

## Codex 감독형 검수

기획, Slice 동기화, 구현명세와 테스트 계획을 실질적으로 변경하는 작업은 [`Codex 감독형 검수·테스트 정책`](docs/remake/product/codex-supervised-review-and-test-policy.md)을 따른다.

역할:

```text
사용자
→ 제품 결정·최종 수용

ChatGPT Lead Reviewer
→ Codex 명령 작성·권위 해석·Finding 분류·후속 지시

Codex Reviewer
→ 독립 검수·반례·Finding·재현·최소 수정안
```

필수 규칙:

1. Codex 검수에는 정확한 PR·Target Commit SHA·검수 역할·권위 문서·비범위·출력 형식을 제공한다.
2. Codex는 직접 PASS·Merge를 결정하지 않는다.
3. Codex Finding은 `CONFIRMED`, `VALID_RISK`, `DESIGN_DECISION_REQUIRED`, `INTENTIONALLY_QUEUED`, `DUPLICATE`, `FALSE_POSITIVE`, `OUT_OF_SCOPE` 중 하나로 분류한다.
4. `CONFIRMED` BLOCKER·HIGH Finding은 수정과 Delta Review 전까지 완료 처리하지 않는다.
5. Codex 검수나 정적 CI를 Roblox Studio·Human Input·Multi-client·Persistence Runtime Evidence로 해석하지 않는다.
6. 새 Batch Acceptance 또는 Merge Gate에는 Codex 명령문과 Finding Triage를 포함한다.
7. Codex 접근 실패는 자동 면제가 아니다. `BLOCKED_CODEX_REVIEW_UNAVAILABLE`로 기록하거나 사용자의 명시적 면제를 받는다.

명령문 템플릿:

```text
.github/CODEX-REVIEW-COMMAND-TEMPLATE.md
```

테스트 Gate:

```text
implementation/roblox/CODEX-REVIEW-TEST-GATE.md
```

## 최신 고정 전제

- 5피트 논리 이동 격자를 사용하지 않는다.
- 권위 이동은 연속 좌표이며 `5 ft = 4 studs` 비율을 사용한다.
- 전투에서 토큰 WASD 이동을 지원하지 않는다.
- 초기 지원 기기는 PC 키보드·마우스뿐이다.
- NPC 대화 시스템을 만들지 않는다.
- 음악, 환경음, 공격·주문·UI SFX를 만들지 않는다.
- VFX, 토큰 모션, 카메라와 화면 효과만 PresentationRecipe로 처리한다.
- 2024 기본 규칙의 플레이어 캐릭터 콘텐츠 전체를 최종 지원 범위로 삼는다.
- 저장 한도를 넘는 데이터는 manifest와 chunk로 나눈다.

관련 상세 규약은 `docs/remake/AGENTS-PLANNING-ADDENDUM.md`와 ADR-0048~ADR-0052를 따른다.