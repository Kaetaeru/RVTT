# Slice 01 Work Order — First Session Walking Skeleton

- 상태: CHECKPOINT_COMPLETE
- 문서 종류: Slice Implementation Spec Work Order
- 즉시 구현 명세 가능성: BLOCKED
- 작성일: 2026-08-05
- 전체 Roadmap: [`SLICE-ROADMAP.md`](../../SLICE-ROADMAP.md)
- 현재 Spec 작업 순서: [`CURRENT-SPEC-WORK-ORDER.md`](../../CURRENT-SPEC-WORK-ORDER.md)
- 통합 계약: [`implementation-contract.md`](implementation-contract.md)
- 검수 감사: [`Slice 01 Spec Checkpoint Audit`](../../../audits/slices/01-first-session-walking-skeleton-spec-checkpoint-audit.md)

이 문서는 Slice 01의 구현 명세 작성 순서를 고정한다. 제품 동작과 Architecture 의미는 기존 권위 문서를 따르며, 실제 Production Source Tree가 확인되기 전에는 최종 Module 경로를 확정하지 않는다.

## 1. 사용자 완료 결과

```text
Campaign 참가
→ Character 선택
→ User Ready
→ DM Session Start
→ Scene Entry Essential 동기화
→ Controlled Token 선택
→ 목적지 클릭 이동
→ Authority Position Commit
→ Disconnect
→ Reconnect·Full Resync
→ 같은 Character·Scene·Position으로 복귀
```

## 2. 명세 작업 순서

| 순서 | 상태 | 작업 | 완료 기준 |
|---:|---|---|---|
| 1 | DONE | Core Authority Identity·Version·Result 계약 | Stable ID, Epoch, Revision, Result와 Error 의미가 고정됨 |
| 2 | DONE | Command·Projection·Resync 계약 | Receipt와 Terminal Result, Snapshot·Delta·Gap·Full Resync가 구분됨 |
| 3 | DONE | Campaign Join·Character Selection·Ready 계약 | Membership, Role, Owner, Controller, User Ready와 Client Ready가 분리됨 |
| 4 | DONE | Scene Entry Essential·Actor Bootstrap 계약 | Published Build Ref, Runtime Presence와 Gameplay Gate가 고정됨 |
| 5 | DONE | Click Movement·Position Commit 계약 | Client Destination Intent, Server Path·Occupancy·Revision 검증과 Commit 경계가 고정됨 |
| 6 | DONE | Snapshot·Journal·Reconnect 계약 | Character·Control·Scene·Position·Projection Cursor 복구 경계가 고정됨 |
| 7 | DONE | Diagnostics·Security·Deterministic Test 계약 | Trace, Stable Error, Negative Disclosure, Restart와 Roblox Integration Scenario가 정의됨 |
| 8 | DONE | Slice 통합 계약과 검수 감사 | [`implementation-contract.md`](implementation-contract.md)와 Audit이 연결됨 |
| 9 | BLOCKED | Production Source Mapping | 실제 Server·Client·Shared·Persistence·Test 경로 확인 필요 |

## 3. 구현 시 추출할 세부 명세

통합 계약은 다음 책임을 포함한다. 실제 Source Tree가 확인되면 구현 단위에 맞춰 별도 파일로 추출할 수 있으나 의미를 바꾸지 않는다.

```text
runtime/core-authority
networking/command-projection-resync
session/join-selection-ready
scene/entry-essential-bootstrap
exploration/click-movement
persistence/reconnect-resume
testing/join-move-disconnect-reconnect
```

기존 초안 [`runtime/001`](../../runtime/001-core-authority-identity-version-and-result.md)은 Core Authority 세부 계약으로 유지하며, 통합 계약과 충돌하면 권위 문서를 재검토한 뒤 갱신한다.

## 4. 체크포인트 Gate

- Player와 DM Acceptance Flow가 모두 추적된다.
- Client가 Character, Scene, Actor와 Position Authority를 직접 생성하지 않는다.
- User Ready와 Client Essential Ready가 구분된다.
- Scene Essential 이전 Gameplay Command가 거부된다.
- Position Commit과 Projection이 같은 Authority Revision을 참조한다.
- Disconnect 전 제출과 Reconnect 후 제출이 Connection Epoch로 구분된다.
- Snapshot·Journal·Projection Cursor가 서로 다른 저장 의미를 가진다.
- DM-only Membership·Hidden Actor·Scene Secret이 Player Payload와 Diagnostic에 노출되지 않는다.
- 문서 검증 Workflow가 성공한다.

## 5. 차단 사항

현재 GitHub Branch에서 Production Module·Schema·Test 트리를 확인하지 못했다. 따라서 다음은 구현 직전 조사 대상으로 남긴다.

- Rojo 또는 Place Source 동기화 방식
- Server·Client·Shared Package Root
- 기존 Remote·ID·Result·Persistence Registry
- 기존 Token·Session·Permission 구현의 재사용 여부
- Test Runner와 Roblox Integration 실행 방식

이 차단은 계약 의미 작성을 막지 않지만, 파일 경로·Package 이름과 실제 Migration 대상을 확정하지 못하게 한다.