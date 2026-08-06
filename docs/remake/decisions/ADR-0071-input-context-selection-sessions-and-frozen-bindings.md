# ADR-0071: Input Context, Selection Session과 Frozen Binding

- 상태: accepted · ADR-0088로 Pointer·Q 세부 보강
- 작성일: 2026-08-04
- 최종 갱신일: 2026-08-06
- 관련 결정: [`ADR-0088 직접 플레이 포인터 문법과 피드백 연속성`](ADR-0088-direct-play-pointer-grammar-and-feedback.md)

## Context

RVTT의 탐험, Encounter, 주문, 공격, 아이템, 상호작용과 DM Authoring은 모두 선택과 대상 지정을 사용한다. 기능별 클릭 처리와 키 감시를 허용하면 Q/E 공통 입력 의미, Pointer 역할, 권한, Preview와 서버 권위가 서로 충돌한다.

기존 공통 입력 계약은 다음을 고정한다.

```text
Q → 닫기·취소·거절·한 단계 뒤로
E → 승인·확정·실행·상호작용
```

PC 기본 Pointer 의미는 다음과 같다.

```text
PrimaryPointer
→ 왼쪽 클릭

ContextActionPointer
→ 오른쪽 클릭

CameraOrbitPointer
→ 마우스 휠 클릭 드래그
```

ESC에는 Gameplay 의미를 부여하지 않는다.

## Decision

1. 물리 입력은 Semantic Action과 분리한다.
2. 현재 Input Context가 Semantic Action을 Intent로 해석한다.
3. 선택이 필요한 Intent는 저장 가능한 Selection Session을 연다.
4. Client Preview는 권위 결과가 아니다.
5. 실행 전 서버가 최신 Snapshot에서 재검증해 FrozenSelectionBinding을 만든다.
6. RuleExecution은 FrozenSelectionBinding만 사용한다.
7. Q는 Universal Back·Cancel·Reject, E는 Universal Confirm·Approve·Execute·Interact로 유지한다.
8. Q는 최상위 Input Context 한 단계만 닫는다. 메뉴, Targeting, 반복 행동과 Actor 선택을 한 입력으로 연속 해제하지 않는다.
9. ESC는 Gameplay Context를 닫거나 취소하지 않는다.
10. Q/E를 Candidate Navigation에 사용하지 않는다.
11. Candidate Navigation은 별도의 재설정 가능한 Semantic Action을 사용한다.
12. `PrimaryPointer`는 선택 또는 현재 Context가 화면에 표시한 기본 행동으로 해석한다.
13. `ContextActionPointer`는 대상 기준 Capability Action Projection을 요청한다.
14. `CameraOrbitPointer`는 월드 Camera Context가 소비하며 Context Action Pointer와 분리한다.
15. Exploration과 Encounter는 같은 Selection Runtime을 사용하되 Context Policy와 Command Gate를 달리한다.
16. DM 승인 요청은 일반 Selection과 Authoring보다 높은 Input Context 우선순위를 가진다.
17. 숨김 대상, Journal Link, Authoring 다중 선택은 DM 전용이다.
18. Text Input이 Focus된 동안 Gameplay Q/E, Pointer 단축 행동과 Camera 키를 실행하지 않는다.

## Q 단계 취소 예시

```text
Context Action Table 열림
→ Q: 표만 닫기

Targeting 또는 Preview
→ Q: 현재 단계만 취소
→ 이전 행동 선택 상태로 복귀

반복 행동 고정
→ Q: 반복 행동 해제

Actor 선택만 남음
→ Q: Actor 선택 해제
```

현재 취소할 Context가 없으면 아무 행동도 하지 않는다.

## Consequences

- 모든 선택 기능이 공통 Spatial Query와 권위 검증을 사용한다.
- 열린 창, Action Table, 다단계 Targeting, DM 승인과 Scene Authoring이 Q/E 의미를 공유한다.
- Primary, Context Action과 Camera Orbit Pointer가 서로 다른 Semantic Action으로 유지된다.
- Candidate 전환은 Q/E와 충돌하지 않는다.
- 재접속 시 Pending Selection과 Frozen Binding을 복구할 수 있다.
- Preview와 실제 결과가 다를 수 있으므로 UI는 Pending·승인·거부와 서버 재검증 실패를 명확히 표시해야 한다.
- Context 종료 시 등록한 Semantic Action과 Focus Token을 반드시 해제해야 한다.

## Rejected Alternatives

### ESC와 Q를 함께 Gameplay Back으로 사용

Universal Back이 두 물리 키로 분산되고 Input Context 우선순위가 모호해지므로 기각한다.

### Q/E로 후보 순환

Universal Back·Confirm 및 DM 승인 계약과 충돌하므로 기각한다.

### 기능별 Workspace 직접 선택

Streaming, 숨김 정보, Rollback과 권위 Identity를 우회하므로 기각한다.

### Client Preview를 실행 대상으로 사용

위치·시야·Revision 경쟁 조건과 조작 가능성이 있으므로 기각한다.

## Related

- [`ADR-0088 직접 플레이 UX`](ADR-0088-direct-play-pointer-grammar-and-feedback.md)
- [`공통 입력 교과서`](../ui/common-input/common-input-grammar.md)
- [`Selection Runtime 계약`](../architecture/selection-targeting-preview-and-frozen-binding-runtime-contract.md)
