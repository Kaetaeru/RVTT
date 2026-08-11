# RVTT Current Executable Task

- executionAuthority: `ONLY_CURRENT_EXECUTABLE_TASK`
- status: `READY_FOR_ORDERED_GREENFIELD_FOUNDATION`
- commandId: `RVTT-GREENFIELD-FOUNDATION-EXPLORATION-001`
- repository: `Kaetaeru/RVTT`
- pullRequest: `2`
- branch: `agent/survival-logistics-token-authoring`
- taskMode: `STUDIO_IMPLEMENTATION`
- buildMode: `GREENFIELD_ARCHITECTURE_FIRST`
- sequenceAuthority: `implementation/roblox/GREENFIELD-SYSTEM-SEQUENCE.md`
- acceptancePromotionGate: `implementation/roblox/AUTHORITY-RECONCILIATION-POLICY.md`
- feedbackMode: `TIGHT_USER_FEEDBACK_LOOP`
- legacySourcePolicy: `REFERENCE_OR_EXPLICIT_REUSE_ONLY`
- legacyPlacePolicy: `DO_NOT_USE_AS_BASELINE`
- commandPath: `.github/CODEX-STUDIO-GREENFIELD-FOUNDATION-EXPLORATION-001.md`
- targetMode: `CURRENT_PR_HEAD_AT_START`
- updatedAt: `2026-08-12`

## 지금 바로 해야 할 일

**`GREENFIELD-SYSTEM-SEQUENCE.md`의 Foundation 순서를 그대로 실행한다.**

```text
G0_SHARED_CONTRACTS
→ G1_SERVER_AUTHORITY_CORE
→ G2_COMMAND_TRANSPORT
→ G3_PROJECTION_PIPELINE
→ G4_CLIENT_WORLD_SHELL
→ G5_COMPOSITION_BOOT
→ S1_SELECTION
```

- 이전 Stage가 Gate를 만족하기 전 다음 Stage를 구현하지 않는다.
- Foundation을 만들기 위해 미래 기능 Manager를 미리 만들지 않는다.
- G5가 Boot되면 Foundation 확장을 멈추고 S1 Selection을 구현한다.
- S1이 `READY_FOR_USER`가 되면 Camera 작업을 시작하지 않는다.
- 사용자가 Selection을 수정하라고 하면 즉시 같은 Checkpoint를 수정·재Play한다.

## 사용자 확정 처리

사용자가 현재 Checkpoint를 몇 차례 수정한 뒤 `좋다`, `이걸로`, `확정`, `다음`처럼 최종 수용하면 **다음 기능을 시작하지 않는다.** 먼저 `AUTHORITY-RECONCILIATION-POLICY.md`를 실행한다.

```text
사용자 최종 수용
→ Authority Impact Scan
→ 충돌하는 현재 Product·ADR·Architecture·Spec을 상위부터 수정
→ Module Contract 정합화
→ Studio 결과를 greenfield/src로 정규화
→ Rojo 재현 확인
→ Focused Test
→ 현재 문서 충돌 재검색
→ ACCEPTED
→ 다음 Checkpoint
```

- 반복 수정 중에는 상위 문서를 매번 고치지 않는다.
- 확정 뒤에는 충돌하는 현재 Authority를 남겨두지 않는다.
- 과거 Audit·Acceptance·Review·Codex Command는 Historical Evidence이므로 새 결정에 맞춰 다시 쓰지 않는다.
- 화면/동작 수용을 내부 Architecture 변경의 승인으로 확대 해석하지 않는다.
- Reconciliation 중 미승인 Authority·Architecture 변경이 필요하면 사용자에게 먼저 제안한다.
- `UNRESOLVED CONFLICTS`가 하나라도 남으면 Checkpoint를 `ACCEPTED`로 바꾸지 않는다.

## 안전 규칙

Prototype이라도 다음을 우회하지 않는다.

- Server authoritative mutation
- untrusted client input
- bounded/rate-limited Remote
- client role claim 불신
- commandId + epoch/revision 검증
- viewer-safe Projection
- no Roblox Instance over network
- UI→Remote 직접 호출 금지
- Bootstrap gameplay logic 금지
- Studio-only Production truth 금지

## 스캔 순서

1. `AGENTS.md`
2. `.github/README.md`
3. 이 파일
4. `implementation/roblox/GREENFIELD-SYSTEM-SEQUENCE.md`
5. `implementation/roblox/AUTHORITY-RECONCILIATION-POLICY.md`
6. 현재 `commandPath`
7. `implementation/roblox/MODULE-CONTRACTS.md`
8. `implementation/roblox/manifests/module-contracts.json`
9. 관련 Product·ADR·Spec
10. 필요한 Legacy Source — 참고용

## 지금 하지 않는 것

- 기존 Production Place 이어서 수정
- monolithic LocalScript/ServerScript로 기능 완성
- G0~G5 순서 건너뛰기
- Selection 수용 전 Camera/Move 선행 구현
- 사용자 수용 직후 Authority Reconciliation 없이 다음 Checkpoint 진행
- 과거 Codex Command 재개
- Acceptance/Grand Campaign을 개발 시작 Gate로 사용
- ADR-0092 Phase 선행 착수
- ready-for-review / merge / force push

더 좋은 Architecture·순서·Authority 방향이 보이면 적용하지 말고 사용자에게 먼저 제안한다.
