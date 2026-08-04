# RVTT Implementation Specs 현재 작업 순서

- 상태: ACTIVE_WITH_BLOCKER
- 문서 종류: Implementation Spec Work Order
- 최종 갱신일: 2026-08-05
- 상위 작업 순서: [`../CURRENT-WORK-ORDER.md`](../CURRENT-WORK-ORDER.md)
- 전체 Slice Roadmap: [`SLICE-ROADMAP.md`](SLICE-ROADMAP.md)
- Slice Package Index: [`slices/README.md`](slices/README.md)
- 전체 명세 완료 감사: [`All-slice Specification Checkpoint Completion Audit`](../audits/all-slice-specification-checkpoint-completion-audit.md)
- Checkpoint Index: [`audits/slice-checkpoints`](../audits/slice-checkpoints/README.md)
- 작성 Template: [`../templates/implementation-spec-template.md`](../templates/implementation-spec-template.md)

이 문서는 Implementation Specs 단계의 현재 실행 순서를 소유한다. 16개 Slice의 통합 명세와 검수는 완료됐으며, 다음 작업은 실제 Repository Source Tree에 계약을 Mapping해 Production Readiness Blocker를 해소하는 것이다.

## 1. 현재 상태

```text
16개 Slice 정의
→ DONE

16개 Work Order
→ DONE

16개 Integration Contract
→ DONE

16개 Slice Checkpoint Audit
→ DONE

4개 Cross-Slice Checkpoint·Recovery Branch
→ DONE

Production Source Mapping
→ IN_PROGRESS·BLOCKED
```

## 2. 현재 작업 순서

| 순서 | 상태 | 작업 | 완료 조건 |
|---:|---|---|---|
| 1 | DONE | 전체 Slice Roadmap·완전성 감사 | 16개 Slice와 12개 Guide 범위 배정 |
| 2 | DONE | Slices 01–04 명세·Checkpoint A | Session·Rules·Exploration·Encounter 계약 검수 |
| 3 | DONE | Slices 05–08 명세·Checkpoint B | Character·Inventory·Downtime·UI 계약 검수 |
| 4 | DONE | Slices 09–12 명세·Checkpoint C | Journal·Authoring·DM Operation·Extension 계약 검수 |
| 5 | DONE | Slices 13–16 명세·Checkpoint D | Content·NPC·Release Gate 계약 검수 |
| 6 | DONE | All-slice Specification Completion Audit | 16/16·4/4 산출물과 공통 Blocker 확인 |
| 7 | IN_PROGRESS | Slice 01 Production Source Mapping | 실제 Server·Client·Shared·Persistence·Test 경로와 Legacy Schema 확인 |
| 8 | BLOCKED | Slice 01 세부 Spec Readiness 전환 | Mapping·Migration·Budget·Roblox Test Host가 연결돼야 함 |
| 9 | BLOCKED | Production Implementation | Slice 01 준비 완료와 사용자 구현 승인 필요 |

## 3. Slice 01 Mapping 대상

현재 Slice:

```text
01 First Session Walking Skeleton
```

연결할 계약:

- [`Slice 01 Work Order`](slices/01-first-session-walking-skeleton/CURRENT-WORK-ORDER.md)
- [`Slice 01 Integration Contract`](slices/01-first-session-walking-skeleton/implementation-contract.md)
- [`Core Authority 세부 초안`](runtime/001-core-authority-identity-version-and-result.md)
- [`Slice 01 Checkpoint Audit`](../audits/slices/01-first-session-walking-skeleton-spec-checkpoint-audit.md)

조사 순서:

```text
Repository·Place Source 동기화 방식
→ Server·Client·Shared Package Root
→ ID·Result·Error·Remote Registry
→ Session·Token·Permission·Scene·Movement 구현
→ Persistence Schema·Journal·Migration
→ Test Runner·Virtual Client·Roblox Integration
→ 논리 Package와 실제 경로 Mapping
→ Readiness 재감사
```

## 4. 운영 규칙

1. 가장 위의 `IN_PROGRESS` 항목을 먼저 처리한다.
2. 통합 계약의 의미를 실제 코드 구조에 맞춘다는 이유로 조용히 변경하지 않는다.
3. 새 Product 동작이나 Architecture 충돌이 발견되면 해당 Authority·Slice Contract·Audit을 `UPDATE_REQUIRED`로 되돌린다.
4. 실제 Source Tree를 확인하지 못한 경로는 계속 `신규 제안`으로 표시한다.
5. Legacy 데이터가 존재하면 Migration·Deprecation·Tombstone과 Last Known Good를 작성한다.
6. 측정 전에 Timeout·Queue·Cache·Payload·Snapshot 수치를 확정하지 않는다.
7. Production Code는 현재 Slice의 Mapping·Readiness 감사와 사용자의 명시적 구현 승인 후 시작한다.
8. 한 Slice의 Production Build Acceptance가 끝나기 전에 여러 Slice 구현을 얕게 병렬 시작하지 않는다.
9. Checkpoint Branch는 복구 기준이며 일반 작업 Branch로 이동시키지 않는다.

## 5. 전체 Production 순서

Specification과 Production은 같은 Slice 순서를 사용한다.

```text
Slice Source Mapping
→ Package·Schema·Migration 세부 Spec
→ Spec Readiness Audit
→ 사용자 구현 승인
→ Production Code·Migration·Test
→ Build Acceptance Audit
→ 다음 Slice
```

Slices 13–15는 추가로 실제 Data·Source Version·Rights Review를 통과해야 한다. Slice 16은 실제 Full-session·Fault·Security·Performance·Soak Evidence 없이는 Release Ready가 될 수 없다.

## 6. 완료 판정

Implementation Specs 단계 전체를 `DONE`으로 닫으려면 다음이 필요하다.

- 16개 Slice 통합 명세와 감사: 완료
- 실제 Source Tree Mapping과 필요한 Package-level Specs
- Legacy Schema·Migration 경계
- Slice별 `READY` 또는 명시적 `DEFERRED`
- 문서 검증 성공
- Production Implementation 순서와 사용자 승인 Gate 유지

현재 판정:

```text
통합 명세 범위
→ COMPLETE

실제 구현 준비도
→ BLOCKED

현재 해소 대상
→ Slice 01 Production Source Mapping
```