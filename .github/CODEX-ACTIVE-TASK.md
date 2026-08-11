# RVTT Current Executable Task

- executionAuthority: `ONLY_CURRENT_EXECUTABLE_TASK`
- status: `READY_FOR_ARCHITECTURE_FIRST_GREENFIELD_BUILD`
- commandId: `RVTT-GREENFIELD-FOUNDATION-EXPLORATION-001`
- repository: `Kaetaeru/RVTT`
- pullRequest: `2`
- branch: `agent/survival-logistics-token-authoring`
- taskMode: `STUDIO_IMPLEMENTATION`
- buildMode: `GREENFIELD_ARCHITECTURE_FIRST`
- feedbackMode: `TIGHT_USER_FEEDBACK_LOOP`
- legacySourcePolicy: `REFERENCE_OR_EXPLICIT_REUSE_ONLY`
- legacyPlacePolicy: `DO_NOT_USE_AS_BASELINE`
- commandPath: `.github/CODEX-STUDIO-GREENFIELD-FOUNDATION-EXPLORATION-001.md`
- targetMode: `CURRENT_PR_HEAD_AT_START`
- updatedAt: `2026-08-12`

## 지금 바로 해야 할 일

**기능을 한두 Script에 몰아 빠르게 흉내 내는 작업이 아니다. 새 RVTT의 시스템 골격을 먼저 세우고, 그 골격을 통해 첫 플레이 기능을 만든다.**

```text
Product·ADR 확인
→ Greenfield Module Contract 확인
→ 필요한 시스템 책임·Authority 확정
→ 새 Studio Build에 Client/Server Composition Root 구축
→ Command·Authorization·Projection·Input·World System 경계 구축
→ Foundation Boot 확인
→ 첫 사용자 기능: Hero Token Selection 구현
→ 사용자가 직접 테스트
→ 마음에 안 들면 Selection을 즉시 수정·재테스트
→ 사용자 수용 후 Camera → Move → Context → Interaction 순으로 확장
```

## 첫 사용자 체크포인트

첫 Human Checkpoint는 `Hero Token Selection`이다.

- Selection이 마음에 들지 않으면 다음 기능으로 넘어가지 않는다.
- 피드백을 "나중에 정리할 UX"로 적재하지 않는다.
- 같은 Checkpoint에서 즉시 수정하고 다시 Play 가능한 상태로 만든다.
- 사용자가 명시적으로 수용하거나 다음으로 가라고 할 때만 Camera 작업으로 넘어간다.

## 반드시 이해할 것

- Bootstrap Script는 Client/Server 각각 하나여도 되지만 **조립과 start 호출만** 한다.
- Bootstrap, LocalScript, ServerScript에 Selection·Camera·Move·Context·Rules 로직을 몰아넣지 않는다.
- 시스템 책임은 `module-contracts.json`의 Greenfield 계약을 따른다.
- 기존 `src/` Module Contract와 Source는 Legacy Reference다. 재사용은 opt-in이다.
- 기존 Production Place/UI/Instance Tree는 새 Build의 Baseline이 아니다.
- 과거 Acceptance PASS/FAIL은 현재 Greenfield 구현의 TODO나 PASS가 아니다.

## 사용자에게 먼저 보고해야 하는 것

현재보다 더 좋아 보이는 방향이 있더라도 다음을 바꾸려면 먼저 사용자에게 제안한다.

- Product·Accepted ADR
- 핵심 입력 의미
- Server/Client Authority 또는 Data ownership
- Greenfield Module 책임의 실질적인 분리·통합
- 개발 방식
- Release 범위·우선순위

기존 결정 안에서의 버그 수정, UX 미세 조정, helper 분해는 즉시 수행할 수 있다.

## 지금 하지 않는 것

- 기존 Production Place를 열고 이어서 수정
- 기능 데모용 monolithic LocalScript/ServerScript 작성
- Foundation 없이 Selection·Move부터 직접 구현
- 과거 Codex Command 재개
- Acceptance/Grand Campaign을 개발 시작 Gate로 사용
- ADR-0092 Phase 선행 착수
- ready-for-review / merge / force push
