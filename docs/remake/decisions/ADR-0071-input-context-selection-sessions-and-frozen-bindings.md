# ADR-0071: Input Context, Selection Session과 Frozen Binding

- 상태: accepted
- 작성일: 2026-08-04

## Context

RVTT의 탐험, Encounter, 주문, 공격, 아이템, 상호작용과 DM Authoring은 모두 선택과 대상 지정을 사용한다. 기능별 클릭 처리와 키 감시를 허용하면 Q/E 공통 입력 의미, 권한, Preview와 서버 권위가 서로 충돌한다.

기존 공통 입력 계약은 다음을 고정한다.

```text
Q → 취소·거절·한 단계 뒤로
E → 승인·확정·실행·상호작용
```

## Decision

1. 물리 입력은 의미 입력과 분리한다.
2. 현재 Input Context가 의미 입력을 Intent로 해석한다.
3. 선택이 필요한 Intent는 저장 가능한 Selection Session을 연다.
4. Client Preview는 권위 결과가 아니다.
5. 실행 전 서버가 최신 Snapshot에서 재검증해 FrozenSelectionBinding을 만든다.
6. RuleExecution은 FrozenSelectionBinding만 사용한다.
7. Q는 Universal Back/Cancel/Reject, E는 Universal Confirm/Approve/Execute/Interact로 유지한다.
8. Q/E를 Candidate Navigation에 사용하지 않는다.
9. Candidate Navigation은 별도의 재설정 가능한 의미 입력을 사용한다.
10. Exploration과 Encounter는 같은 Selection Runtime을 사용하되 Context Policy와 Command Gate를 달리한다.
11. DM 승인 요청은 일반 Selection과 Authoring보다 높은 Input Context 우선순위를 가진다.
12. 숨김 대상, Journal Link, Authoring 다중 선택은 DM 전용이다.

## Consequences

- 모든 선택 기능이 공통 Spatial Query와 권위 검증을 사용한다.
- 열린 창, 다단계 Targeting, DM 승인과 Scene Authoring이 Q/E 의미를 공유한다.
- Candidate 전환은 Q/E와 충돌하지 않는다.
- 재접속 시 Pending Selection과 Frozen Binding을 복구할 수 있다.
- Preview와 실제 결과가 다를 수 있으므로 UI는 서버 재검증 실패를 명확히 표시해야 한다.

## Rejected Alternatives

### Q/E로 후보 순환

Universal Back/Confirm 및 DM 승인 계약과 충돌하므로 기각한다.

### 기능별 Workspace 직접 선택

Streaming, 숨김 정보, Rollback과 권위 Identity를 우회하므로 기각한다.

### Client Preview를 실행 대상으로 사용

위치·시야·Revision 경쟁 조건과 조작 가능성이 있으므로 기각한다.
