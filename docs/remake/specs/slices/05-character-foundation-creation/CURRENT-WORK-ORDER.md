# Slice 05 Work Order — Character Foundation·Creation

- 상태: CHECKPOINT_COMPLETE
- 문서 종류: Slice Implementation Spec Work Order
- 즉시 구현 명세 가능성: BLOCKED
- 작성일: 2026-08-05
- 전체 Roadmap: [`SLICE-ROADMAP.md`](../../SLICE-ROADMAP.md)
- 선행 Slice: [`Core Rules Kernel`](../02-core-rules-kernel/implementation-contract.md)
- 통합 계약: [`implementation-contract.md`](implementation-contract.md)
- 검수 감사: [`Slice 05 Spec Checkpoint Audit`](../../../audits/slices/05-character-foundation-creation-spec-checkpoint-audit.md)

## 1. 사용자 완료 결과

```text
새 Character 생성
→ Species·Background·Class 등 생성 선택
→ Candidate Source 검증
→ Compiled Character Build
→ Persistent State 초기화
→ Player·DM 검토
→ Atomic Activation
→ Character Sheet 확인
→ Session Character로 선택
```

## 2. 명세 작업 순서

| 순서 | 상태 | 작업 | 완료 기준 |
|---:|---|---|---|
| 1 | DONE | Character Identity·Ownership | Campaign-scoped CharacterId, Owner, Actor Binding 분리 |
| 2 | DONE | Character Source Schema | 선택 입력과 출처 Ref가 Versioned Source로 저장됨 |
| 3 | DONE | Compiler·Build Registry | Candidate 검증, 불변 Build, Last Known Good 정의 |
| 4 | DONE | Persistent State 초기화 | HP·Resource·Usage·Preparation 같은 현재 State가 Build와 분리됨 |
| 5 | DONE | Grant·Capability·Derived View | 고정 Grant 파생과 Stored Selection 분리 |
| 6 | DONE | Creation Session·Review·Activation | Draft, Error, Player·DM 승인과 원자 활성화 정의 |
| 7 | DONE | Actor Binding·Session Selection | Character와 Scene Actor의 수명주기·Control 연결 |
| 8 | DONE | Sheet Projection·Migration·Test | Viewer별 Sheet, Compile 실패, Reconnect·Rollback Scenario 정의 |
| 9 | BLOCKED | Production Source Mapping | 실제 Character Schema·Compiler·UI·Legacy Data 조사 필요 |

## 3. 구현 시 추출할 세부 명세

```text
character/identity-ownership-source
character/creation-session-selection
character/compiler-build-registry
character/persistent-state-initialization
rules/grant-capability-derived-view
character/actor-binding-session-selection
ui/character-sheet-foundation
persistence/character-migration-recovery
```

## 4. 차단 사항

- 기존 Character JSON·Token·Attribute 구조
- 공식 2024 Character Option 데이터 Packaging
- Character Sheet 실제 UI Component 구조
- Legacy Character Migration과 Owner Mapping
- Compiler·Build Cache·Validation Test Host