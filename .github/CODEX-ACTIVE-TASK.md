# RVTT Current Executable Task

- executionAuthority: `ONLY_CURRENT_EXECUTABLE_TASK`
- status: `READY_FOR_G0_IMPLEMENTATION`
- commandId: `RVTT-GREENFIELD-FOUNDATION-EXPLORATION-001`
- repository: `Kaetaeru/RVTT`
- pullRequest: `2`
- branch: `agent/survival-logistics-token-authoring`
- taskMode: `STUDIO_IMPLEMENTATION`
- buildMode: `GREENFIELD_ARCHITECTURE_FIRST`
- preflightAuthority: `implementation/roblox/GREENFIELD-PREFLIGHT.md`
- greenfieldProject: `implementation/roblox/greenfield.project.json`
- canonicalSourceRoot: `implementation/roblox/greenfield/src`
- canonicalTestRoot: `implementation/roblox/greenfield/tests`
- boundaryConfig: `implementation/roblox/greenfield-boundary.json`
- sequenceAuthority: `implementation/roblox/GREENFIELD-SYSTEM-SEQUENCE.md`
- acceptancePromotionGate: `implementation/roblox/AUTHORITY-RECONCILIATION-POLICY.md`
- feedbackMode: `TIGHT_USER_FEEDBACK_LOOP`
- legacySourcePolicy: `READ_ONLY_REFERENCE_LOCKED`
- legacyPlacePolicy: `DO_NOT_USE_AS_BASELINE`
- commandPath: `.github/CODEX-STUDIO-GREENFIELD-FOUNDATION-EXPLORATION-001.md`
- targetMode: `CURRENT_PR_HEAD_AT_START`
- updatedAt: `2026-08-12`

## 현재 Handoff

Repository 측 Pre-G0 준비는 완료 상태를 목표로 한다.

```text
Greenfield Rojo Project 준비
+ Greenfield Source/Test Root 준비
+ Legacy src/default.project Lock
+ Boundary Validator
+ Pre-G0 실행 정책
= G0 구현 직전
```

이 문서 상태에서 G0 Source를 미리 만들지 않는다.

## 다음 실행의 첫 행동

1. `GREENFIELD-PREFLIGHT.md`를 읽는다.
2. 현재 PR HEAD에서 Boundary/Module Contract/Greenfield Rojo Build를 재확인한다.
3. Studio Place/Session이 Greenfield Workbench인지 확인한다.
4. MCP Capability Handshake를 수행한다.
5. `READY_FOR_G0` 또는 `DEGRADED_READY`이면 **그때** `G0_SHARED_CONTRACTS` 구현을 시작한다.
6. `BLOCKED`이면 G0 Source를 만들지 않고 blocker를 보고한다.

## 고정 실행 순서

```text
PRE-G0 Workbench Gate
→ G0_SHARED_CONTRACTS
→ G1_SERVER_AUTHORITY_CORE
→ G2_COMMAND_TRANSPORT
→ G3_PROJECTION_PIPELINE
→ G4_CLIENT_WORLD_SHELL
→ G5_COMPOSITION_BOOT
→ S1_SELECTION
```

Pre-G0 Gate는 Foundation Stage가 아니다. G0 이후 Stage 순서를 건너뛰지 않는다.

## Legacy 금지

- `implementation/roblox/src/**` 직접 수정 금지
- `implementation/roblox/default.project.json` Greenfield 용도 수정 금지
- 기존 Production Place를 새 Build Baseline으로 사용 금지
- Legacy 코드는 읽기 참고 후 필요한 부분만 Greenfield 책임에 맞게 새 경로로 옮긴다.

Legacy Lock을 바꿔야 한다고 판단하면 적용하지 말고 사용자에게 먼저 제안한다.

## 사용자 확정 처리

사용자가 Playable Checkpoint를 최종 수용하면 다음 기능을 시작하지 않는다.

```text
사용자 최종 수용
→ Authority Impact Scan
→ 현재 상위 Authority 정합화
→ Module Contract 정합화
→ greenfield/src 정규화
→ greenfield.project.json 재현
→ Focused Test
→ 현재 문서 충돌 재검색
→ Checkpoint Promotion Commit
→ ACCEPTED
→ 다음 Checkpoint
```

Promotion Commit 형식:

```text
checkpoint(<CHECKPOINT_ID>): accept <short behavior summary>
```

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
- Greenfield/Legacy workspace isolation

## 스캔 순서

1. `AGENTS.md`
2. `.github/README.md`
3. 이 파일
4. `implementation/roblox/GREENFIELD-PREFLIGHT.md`
5. `implementation/roblox/GREENFIELD-SYSTEM-SEQUENCE.md`
6. `implementation/roblox/AUTHORITY-RECONCILIATION-POLICY.md`
7. 현재 `commandPath`
8. `implementation/roblox/MODULE-CONTRACTS.md`
9. `implementation/roblox/manifests/module-contracts.json`
10. 관련 Product·ADR·Spec
11. 필요한 Legacy Source — 읽기 참고만

## 지금 하지 않는 것

- G0 Source 선행 작성
- 기존 Production Place 이어서 수정
- Legacy `src`/`default.project.json` 수정
- monolithic LocalScript/ServerScript로 기능 완성
- G0~G5 순서 건너뛰기
- Selection 수용 전 Camera/Move 선행 구현
- 사용자 수용 직후 Authority Reconciliation 없이 다음 Checkpoint 진행
- Promotion Commit 없이 다음 Checkpoint 진행
- Acceptance/Grand Campaign을 개발 시작 Gate로 사용
- ADR-0092 Phase 선행 착수
- ready-for-review / merge / force push

더 좋은 Architecture·순서·Authority 방향이 보이면 적용하지 말고 사용자에게 먼저 제안한다.
