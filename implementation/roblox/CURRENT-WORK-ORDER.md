# RVTT Roblox Implementation 현재 작업 순서

- 상태: `STUDIO_FIRST_CONTEXT_ONLY`
- 최종 갱신일: 2026-08-12
- 현재 실행 포인터: [`../../.github/CODEX-ACTIVE-TASK.md`](../../.github/CODEX-ACTIVE-TASK.md)
- 상위 작업: [`docs/remake/CURRENT-WORK-ORDER.md`](../../docs/remake/CURRENT-WORK-ORDER.md)
- 개발·검증 규칙: [`EXECUTION-TEST-RULES.md`](EXECUTION-TEST-RULES.md)
- Studio MCP: [`ROBLOX-STUDIO-MCP-TEST-POLICY.md`](ROBLOX-STUDIO-MCP-TEST-POLICY.md)

## 1. 이 문서의 역할

이 문서는 Production 단계와 기능군 우선순위를 설명한다. **현재 실행할 명령은 `.github/CODEX-ACTIVE-TASK.md`만 소유한다.**

Repository 스캔에서 아래 내용을 backlog로 이해할 수는 있지만 동시에 실행할 TODO로 만들지 않는다.

## 2. 현재 상태

16개 Slice Production Source와 Full UI·UX 관련 Source는 넓게 존재하고 Static 검증도 상당 부분 완료됐다. 문제는 실제 Studio 결과와 사용자 경험을 너무 늦게 확인했다는 것이다.

따라서 현재 개발은 Acceptance 확장이 아니라 기존 Production Source를 Studio에서 직접 열고 실제 제품으로 다듬는 것이다.

## 3. 기본 구현 루프

```text
GitHub Product·ADR
→ Module Contract
→ 현재 Source·함수·require 관계
→ Studio 현재 DataModel
→ 직접 구현
→ Play
→ 즉시 수정
→ 사용자 판단
→ Source·필요한 Contract 정규화
→ Focused Test
```

## 4. 현재 기능군 우선순위 — Context only

1. Exploration·World Interaction
2. Encounter·Character Console
3. Inventory·Journal·Character Sheet·Settings
4. Entry·Role·Recovery
5. DM Workspace
6. ADR-0091 Runtime Surface
7. ADR-0092 Slice 06→07→11→12→15→16

현재 Active Task가 1번 Exploration을 가리키고 있다. 그 Task가 끝나기 전에는 이 목록의 후속 항목을 자동 착수하지 않는다.

## 5. 현재 Exploration 범위

현재 Command가 다루는 사용자 흐름:

```text
Token 선택
→ Camera
→ Move
→ Context Action
→ 상호작용
→ Character Console 연결 확인
```

Acceptance 재실행을 기본 시작 작업으로 삼지 않는다. Production Place를 먼저 직접 확인한다.

## 6. 기존 Acceptance·Historical Evidence

다음은 보존하지만 현재 실행 명령이 아니다.

- `FULL-UI-UX-ACCEPTANCE.md` — Release/Regression reference
- `slice01-acceptance.project.json` — Focused regression harness
- `acceptance-batch.json`
- `GRAND-ACCEPTANCE-CAMPAIGN.md` — Release regression tooling
- Persistence acceptance projects
- `contextual-pointer-actions` 9/9 — harness runtime evidence
- 과거 Slice 01 16/16 — old input contract historical evidence

Historical Evidence를 현재 변경된 UX 전체 PASS 또는 현재 TODO로 사용하지 않는다.

## 7. 사용자 결정 보호

Studio 구현 중 현재 방향보다 더 나은 제품 방향, 입력 체계, Architecture, 개발 방식, 범위 변경이 떠오르면 자동 적용하지 않는다. 사용자에게 현재 문제와 대안을 먼저 설명한다.

## 8. 다음 작업으로 넘어가는 조건

현재 Active Task가 완료되고 사용자가 결과를 받아들인 뒤에만 다음 기능군을 선택한다.

```text
현재 Studio 흐름 확인
→ 문제 수정
→ 사용자 확인
→ Source 정규화
→ Focused Test
→ Active Task 완료
→ 다음 Active Task 선택
```
