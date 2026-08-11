# RVTT Roblox Implementation Context

- 상태: `GREENFIELD_STUDIO_BUILD · CONTEXT_ONLY`
- 최종 갱신일: 2026-08-12
- 현재 실행 포인터: [`../../.github/CODEX-ACTIVE-TASK.md`](../../.github/CODEX-ACTIVE-TASK.md)

## 1. 현재 구현 상태의 의미

Repository에는 기존 16 Slice Source, UI Source, Acceptance·Persistence·Grand Tooling이 존재한다. **이 존재 자체는 현재 Build의 Baseline을 뜻하지 않는다.**

현재 Roblox 제품 구현은 새/깨끗한 Studio 작업물에서 처음부터 다시 구축한다.

## 2. 기본 루프

```text
Product·ADR 확인
→ Module Contract로 필요한 책임 파악
→ Legacy Source의 역할·함수 조사
→ 새 Studio DataModel에 필요한 최소 구조부터 직접 생성
→ Play
→ 즉시 수정
→ 사용자 판단
→ 새 결과를 GitHub Canonical Source로 정규화
→ Focused Test
```

## 3. Legacy Source 정책

기존 Module은 자동 재사용하지 않는다.

선택적 재사용 조건:

- 현재 Product·ADR과 일치
- 현재 Authority 경계와 일치
- 낡은 UI/Harness 의존성을 끌고 오지 않음
- Greenfield 구조를 단순하게 함

조건을 만족하지 않으면 새로 작성한다.

## 4. 현재 실행 범위

현재 Active Task는 Exploration의 첫 Vertical Flow다.

```text
World
→ Hero Token
→ Selection
→ Camera
→ Move
→ Context Action
→ Interaction
```

기존 Production Place를 열어 문제를 찾고 수정하는 방식으로 시작하지 않는다.

## 5. 다음 기능군 — Context only

1. Encounter·Character Console
2. Inventory·Journal·Character Sheet·Settings
3. Entry·Role·Recovery
4. DM Workspace
5. ADR-0091 Runtime Surface
6. ADR-0092 Production

현재 Task가 완료되고 사용자가 결과를 받아들인 뒤 다음 Active Task를 선택한다.

## 6. 기존 Acceptance·Evidence

다음은 새 Build의 시작점이 아니다.

- `FULL-UI-UX-ACCEPTANCE.md`
- `slice01-acceptance.project.json`
- `GRAND-ACCEPTANCE-CAMPAIGN.md`
- Persistence acceptance projects
- `contextual-pointer-actions` 9/9
- historical `slice01-world-interaction` 16/16

새 Greenfield Build가 안정된 뒤 필요한 회귀 검증에 사용한다.

## 7. 완료 기준

현재 Vertical Flow가 완료되려면:

1. 새 Studio Build에서 실제 동작한다.
2. 사용자가 UX를 받아들인다.
3. 받아들인 결과가 GitHub Source로 정규화된다.
4. 필요한 Module Contract가 새 구현과 일치한다.
5. 관련 Focused Test가 통과하거나 미실행 이유가 기록된다.
