# RVTT Current Executable Task

- executionAuthority: `ONLY_CURRENT_EXECUTABLE_TASK`
- status: `READY_FOR_GREENFIELD_STUDIO_BUILD`
- commandId: `RVTT-GREENFIELD-EXPLORATION-001`
- repository: `Kaetaeru/RVTT`
- pullRequest: `2`
- branch: `agent/survival-logistics-token-authoring`
- taskMode: `STUDIO_IMPLEMENTATION`
- buildMode: `GREENFIELD`
- legacySourcePolicy: `REFERENCE_OR_SELECTIVE_REUSE_ONLY`
- legacyPlacePolicy: `DO_NOT_USE_AS_BASELINE`
- commandPath: `.github/CODEX-STUDIO-GREENFIELD-EXPLORATION-001.md`
- targetMode: `CURRENT_PR_HEAD_AT_START`
- updatedAt: `2026-08-12`

## 지금 바로 해야 할 일

**기존 RVTT Production Place를 수정하는 작업이 아니다. 새 Studio 작업물을 처음부터 구축한다.**

```text
관련 Product·ADR 읽기
→ Module Contract에서 필요한 책임·Authority 경계 파악
→ 기존 Source는 역할 참고·선택적 재사용 후보로만 조사
→ 새/깨끗한 Studio 작업물 준비
→ Exploration을 성립시키는 최소 구조부터 직접 구축
→ Token 선택·Camera·Move·Context Action·상호작용을 Play
→ 문제 즉시 수정·재실행
→ 사용자 판단이 필요한 제품/Architecture 변화만 보고
→ 받아들인 결과를 GitHub Canonical Source·필요한 Module Contract·Rojo Mapping으로 정규화
→ Focused Test
```

## 반드시 이해할 것

- 기존 UI를 다듬는 작업이 아니다.
- 기존 Production Instance Tree를 유지하는 작업이 아니다.
- 기존 Source를 모두 재사용하는 작업이 아니다.
- 과거 Slice/Phase를 이어서 완료하는 작업이 아니다.
- Acceptance에서 실패한 항목을 순서대로 고치는 작업이 아니다.

기존 Source가 현재 계약에 정확히 맞고 새 구조를 오염시키지 않을 때만 해당 Module을 선택적으로 재사용할 수 있다. 재사용하지 않아도 된다.

## 현재 첫 사용자 흐름

```text
새 Studio Build 진입
→ Exploration World 표시
→ Hero Token 표시
→ Token 선택
→ Camera 조작
→ 이동
→ Right-click Context Action
→ 상호작용
```

Character Console은 위 핵심 흐름이 안정된 뒤 필요한 최소 연결만 확인한다.

## 스캔 순서

1. `AGENTS.md`
2. `.github/README.md`
3. 이 파일
4. 현재 `commandPath`
5. 관련 Product·ADR·Spec
6. 관련 Module Contract
7. Legacy Source — 참고용
8. 현재 새 Studio DataModel

`.github/archive/**`에서 TODO를 복구하지 않는다.

## 지금 하지 않는 것

- 기존 Production Place를 Baseline으로 열고 수정
- 과거 `CODEX-IMPLEMENTATION-*` / `CODEX-FIX-*` 재개
- 과거 Static Gate 재개
- `slice01-world-interaction` 재실행을 개발 시작 조건으로 사용
- Grand Acceptance 시작
- ADR-0092 Phase 선행 착수
- 사용자 승인 없는 새 Architecture 결정
- ready-for-review / merge / force push
