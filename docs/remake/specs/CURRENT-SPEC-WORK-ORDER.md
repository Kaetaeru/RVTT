# RVTT Implementation Specs 현재 작업 순서

- 상태: `COMPLETE_WITH_ADDITIVE_ADR_0092_SYNC`
- 문서 종류: Implementation Spec Work Order
- 최종 갱신일: 2026-08-06
- 상위 작업 순서: [`../CURRENT-WORK-ORDER.md`](../CURRENT-WORK-ORDER.md)
- 전체 Slice Roadmap: [`SLICE-ROADMAP.md`](SLICE-ROADMAP.md)
- Slice Package Index: [`slices/README.md`](slices/README.md)
- ADR-0092 Sync Plan: [`ADR-0092-SLICE-SYNC-PLAN.md`](ADR-0092-SLICE-SYNC-PLAN.md)
- 전체 명세 완료 감사: [`All-slice Specification Checkpoint Completion Audit`](../audits/all-slice-specification-checkpoint-completion-audit.md)
- UI·UX Policy: [`UI·UX Global Policies`](../ui/policies/README.md)
- Production Workspace: [`implementation/roblox`](../../../implementation/roblox/README.md)
- 현재 Production Work Order: [`Roblox Implementation Work Order`](../../../implementation/roblox/CURRENT-WORK-ORDER.md)

이 문서는 16개 Slice의 Baseline 통합 명세 완료와 Production Workspace 인계를 기록한다. 실제 Script 작성 순서는 `implementation/roblox/CURRENT-WORK-ORDER.md`가 소유한다.

ADR-0092는 완료된 Baseline을 폐기하지 않고 Additive Delta로 단계적으로 흡수한다.

## 1. 현재 상태

```text
16개 Slice Baseline 정의
→ DONE

16개 Work Order·Integration Contract·Checkpoint Audit
→ DONE

4개 Cross-Slice Checkpoint·Recovery Branch
→ DONE

UI·UX Global Policy·Checklist
→ DONE

Greenfield Production Root와 Baseline Source
→ DONE

현재 Production 작업
→ Full UI·UX Source·Acceptance 정합화

ADR-0092 Upper Planning Sync
→ DONE

ADR-0092 Slice 06·07 Delta
→ DONE

ADR-0092 Slice 11·12·15·16 Contract Absorption
→ QUEUED
```

## 2. Greenfield 구현 결정

실제 Production Source와 Test는 다음 Root에서 관리한다.

```text
implementation/roblox/
```

구조:

```text
src/<Roblox Service>/RVTT/
tests/
tooling/
manifests/
```

의미:

- 기존 문서·명세는 `docs/remake/`에 유지한다.
- 실제 Production Source와 Test는 `implementation/`에만 둔다.
- Script는 현재 Production Work Order와 Manifest 순서대로 추가·수정한다.
- 새 ADR이 생겨도 관련 Slice 전체의 빈 Script를 한 번에 생성하지 않는다.
- Toolchain·Package·최종 Script 경로는 실제 Source Mapping과 Test에서 확정한다.

## 3. 완료된 Baseline 작업

| 순서 | 상태 | 작업 |
|---:|---|---|
| 1 | DONE | 전체 Slice Roadmap·완전성 감사 |
| 2 | DONE | Slices 01–04 명세·Checkpoint A |
| 3 | DONE | Slices 05–08 명세·Checkpoint B |
| 4 | DONE | Slices 09–12 명세·Checkpoint C |
| 5 | DONE | Slices 13–16 명세·Checkpoint D |
| 6 | DONE | All-slice Specification Completion Audit |
| 7 | DONE | UI·UX Global Policy와 Completion Audit |
| 8 | DONE | Greenfield `implementation/roblox/` Workspace Bootstrap·Baseline |
| 9 | HANDOFF | Production UI·UX 정합화와 Acceptance |

## 4. ADR-0092 Delta 상태

| Phase | 상태 | Slice | 책임 |
|---:|---|---:|---|
| 0 | DONE | Product·Roadmap | Campaign Rule Profile·Survival·Actor Authoring 제품 범위 연결 |
| 1 | DONE | 06 | Supply Metadata·Protection·Source·Allocation·Reservation Delta |
| 2 | DONE | 07 | Policy·Boundary·Requirement·Atomic Settlement·Ledger Delta |
| 3 | QUEUED | 11 | Campaign Rules·Supply Preview·Ledger·Reconcile DM Tool |
| 4 | QUEUED | 12 | Requirement·Schema·Trusted Recipe·Model Catalog Content Platform |
| 5 | QUEUED | 15 | Model Registry·Strict JSON·Prompt·Template Publish·SceneNpc Migration |
| 6 | QUEUED | 16 | Full-session Fault·Disclosure·Performance·Runbook Gate |

현재 작성된 Delta:

- [`Slice 06 Supply Metadata·Allocation·Reservation`](slices/06-inventory-equipment-world-items/ADR-0092-DELTA.md)
- [`Slice 07 Campaign Policy·Supply Settlement·Ledger`](slices/07-rest-time-downtime-progression/ADR-0092-DELTA.md)

## 5. Production 순서 보호

현재 Production Lane을 ADR-0092가 선점하지 않는다.

```text
Full UI·UX Source 정합화
→ Static Gate
→ Exploration·Context Input Studio Retest
→ Role·Recovery·Accessibility Evidence
```

ADR-0092 Production Lane은 다음 순서를 사용한다.

```text
Slice 06 실제 Source Mapping
→ Supply Metadata·Reservation 구현
→ Slice 07 Policy·Settlement·Ledger 구현
→ Slice 11 DM Tool
→ Slice 12 Content Registry
→ Slice 15 Actor·Token Pipeline
→ Slice 16 통합 Evidence
```

각 단계는 앞 단계의 Source Mapping·Authority Test·Static Gate가 준비된 후 시작한다.

## 6. Slice 06·07 인계 대상

### Slice 06

- [`Work Order`](slices/06-inventory-equipment-world-items/CURRENT-WORK-ORDER.md)
- [`Baseline Integration Contract`](slices/06-inventory-equipment-world-items/implementation-contract.md)
- [`ADR-0092 Delta`](slices/06-inventory-equipment-world-items/ADR-0092-DELTA.md)

### Slice 07

- [`Work Order`](slices/07-rest-time-downtime-progression/CURRENT-WORK-ORDER.md)
- [`Baseline Integration Contract`](slices/07-rest-time-downtime-progression/implementation-contract.md)
- [`ADR-0092 Delta`](slices/07-rest-time-downtime-progression/ADR-0092-DELTA.md)

Delta는 실제 Source Mapping이 완료되면 Baseline Integration Contract와 Script Manifest에 흡수한다.

## 7. 남은 Blocker

공통:

- 실제 Package·Schema·Test Mapping
- 저장 Schema·Migration Version Index
- 측정형 Timeout·Queue·Payload·Render Budget
- Roblox Studio 다중 Client Runtime Evidence

ADR-0092:

- Item Supply Metadata·Reservation 실제 구조
- Campaign Time·Policy Snapshot·Ledger 실제 구조
- Consumption Requirement·Shortage Recipe Content
- Actor Model Registry·Rights·Asset Pipeline
- Campaign-local Package Publish·SceneNpc Migration

Slices 13–15는 실제 공식 Data·Source Version·Rights Review가 추가로 필요하다.

## 8. 인계 판정

```text
16 Slice Baseline Spec
→ COMPLETE

ADR-0092 Upper Planning
→ COMPLETE

Slice 06·07 Delta Spec
→ COMPLETE

Slice 11·12·15·16 Delta
→ QUEUED

현재 Production 실행 기준
→ implementation/roblox/CURRENT-WORK-ORDER.md

ADR-0092 Production Runtime
→ NOT IMPLEMENTED BY THIS SYNC
```
