# Slice Checkpoint B Audit — Slices 05–08

- 상태: COMPLETE_WITH_SHARED_BLOCKER
- 문서 종류: Cross-Slice Specification Checkpoint Audit
- 즉시 구현 명세 가능성: BLOCKED
- 감사일: 2026-08-05
- 범위:
  - [`Slice 05`](../../specs/slices/05-character-foundation-creation/implementation-contract.md)
  - [`Slice 06`](../../specs/slices/06-inventory-equipment-world-items/implementation-contract.md)
  - [`Slice 07`](../../specs/slices/07-rest-time-downtime-progression/implementation-contract.md)
  - [`Slice 08`](../../specs/slices/08-player-ui-camera-presentation/implementation-contract.md)

## 1. 통합 사용자 흐름

```text
Character 생성·활성화
→ Item 획득·장착·드롭
→ Rest·Level Up·Preparation·Downtime
→ Sheet·Inventory·HUD·Camera·Presentation
→ Reconnect·Rollback
```

## 2. 공통 계약 검사

| 공통 계약 | 결과 |
|---|---|
| Character Source·Build·State·Actor 분리 | 일관됨 |
| Item Definition·Instance·Location·Presence 분리 | 일관됨 |
| Grant·Capability·Derived View | Character·Item·Rule에서 공유 |
| Campaign Time·Activity·Domain Completion | Character·Inventory 직접 수정 없이 연결 |
| Character Sheet·Inventory·Downtime UI | Projection·ViewModel 기반 |
| Atomic Activation·Transfer·Completion | Transaction·Outbox·Projection Barrier 사용 |
| Version·Migration·Last Known Good | 모든 Slice에 포함 |
| Reconnect·Restart·Rollback | 모든 Slice에 포함 |
| Viewer별 Disclosure·Accessibility | 모든 Slice에 포함 |
| Deterministic·Fault·Roblox Integration | 모든 Slice에 포함 |

## 3. 충돌·중복 검사

발견되지 않은 문제:

- Character Source에 Current HP·Actor Transform·Inventory 복사본 저장
- Item을 Inventory와 Ground에 중복 저장
- Downtime이 Character·Item Store 직접 수정
- 현실 시간 기반 자동 Progress
- UI가 Derived Stat·Item Location·Activity Progress 확정
- VFX·Camera·Panel State 기반 Authority

공통 차단 사항:

- 실제 Character·Inventory·Time·UI Package 경로
- Legacy Data·Migration 대상
- 공식 Content Packaging·권리·Source Metadata
- UI Asset·Camera·Presentation Registry
- 측정형 Cache·Queue·Payload·Snapshot Budget

## 4. Checkpoint 판정

```text
Checkpoint B — Slices 05–08
→ SPECIFICATION CHECKPOINT COMPLETE

Cross-Slice Contract Consistency
→ PASS

Production Implementation Readiness
→ BLOCKED BY REPOSITORY MAPPING
```

다음 Slice 09–12는 이 사용자·데이터 기반 위에 Journal, Scene Authoring, Live DM Operation과 Content Platform을 추가한다.

## 5. 복구 기준

이 Audit이 포함된 Commit을 `checkpoint/specs-slices-05-08-2026-08-05` Branch로 고정한다. 이후 Character·Inventory·Time·UI 계약의 의미가 훼손되면 해당 Branch와 비교·복구한다.