# 08. RVTT 공통 입력 교과서

- 상태: 확정
- 작성일: 2026-08-03
- 최종 갱신일: 2026-08-06
- 상위 결정: [`ADR-0088 직접 플레이 포인터 문법과 피드백 연속성`](../../decisions/ADR-0088-direct-play-pointer-grammar-and-feedback.md)
- 관련 문서:
  - [`02-core-session-loop.md`](../../product/core-session-loop.md)
  - [`ADR-0039 전투 HUD와 문맥 행동 UI`](../../decisions/ADR-0039-baldurs-gate-style-combat-hud-and-contextual-action-ui.md)
  - [`ADR-0050 자유 전술 카메라`](../../decisions/ADR-0050-free-tactical-camera-and-presentation-priority.md)
  - [`ADR-0071 Input Context와 Selection Session`](../../decisions/ADR-0071-input-context-selection-sessions-and-frozen-bindings.md)
  - [`ADR-0072 Capability 기반 문맥 상호작용`](../../decisions/ADR-0072-contextual-interactions-as-capability-derived-commands.md)
  - [`06-ingame-scene-editor-tools.md`](../../systems/scene/ingame-scene-editor-tools.md)
  - [`07-scene-editor-interaction-and-layout.md`](../scene-editor/scene-editor-interaction-and-layout.md)

## 1. 범위

이 문서는 씬 편집기의 단축키 표가 아니라 **RVTT 전체의 입력 교과서**다.

적용 범위:

- 플레이어 탐험
- 전투 행동과 대상 지정
- 주문과 능력 사용
- DM 승인, 거절과 판정
- 토큰과 오브젝트 상호작용
- 자유 전술 카메라
- 씬 편집
- 모달, 경고와 수치 입력

모든 화면이 같은 입력을 모두 사용해야 한다는 뜻은 아니다. 각 Input Context는 필요한 Semantic Action만 활성화한다.

핵심 원칙:

```text
Q
→ 닫기, 취소, 거절 또는 한 단계 뒤로

E
→ 승인, 확정, 실행 또는 상호작용

왼쪽 클릭
→ 선택 또는 화면에 표시된 기본 행동

오른쪽 클릭
→ 대상 기준 전체 행동표

마우스 휠 클릭 드래그
→ 카메라 Orbit

1 2 3 4 5
→ 화면에 표시된 현재 문맥의 주요 행동 슬롯
```

ESC에는 Gameplay 의미를 부여하지 않는다.

---

## 2. 물리 입력과 의미 동작을 분리한다

기능 코드가 Q, E 또는 마우스 버튼을 직접 감시하지 않는다.

공통 Semantic Action:

```text
Cancel
Confirm
Interact
PrimaryPointer
ContextActionPointer
CameraOrbitPointer
CameraZoom
CameraPivotElevation
CameraFrame
PrimaryAction1
PrimaryAction2
PrimaryAction3
PrimaryAction4
PrimaryAction5
TemporarySnapBypass
SecondaryModifier
```

PC 기본 바인딩:

```text
Q → Cancel
E → Confirm 또는 Interact
왼쪽 클릭 → PrimaryPointer
오른쪽 클릭 → ContextActionPointer
마우스 휠 클릭 드래그 → CameraOrbitPointer
Wheel → CameraZoom
Ctrl+Wheel → CameraPivotElevation
F 또는 Space → CameraFrame
1–5 → PrimaryAction1–5
Shift → TemporarySnapBypass
```

현재 Input Context가 같은 E를 `Confirm`으로 쓸지 `Interact`로 쓸지 결정한다.

키 재설정, 게임패드와 접근성 입력을 추가해도 의미 동작과 우선순위는 유지한다.

---

## 3. Q: 단일 Back·Cancel·Reject

Q는 현재 가장 높은 Input Context에서 가장 가까운 미완성 상태 하나만 닫거나 취소한다.

```text
Context Action Table 열림
→ Q: 표만 닫기

대상 지정 중
→ Q: 대상 지정만 취소
→ 행동 선택 상태로 복귀

주문 범위 Preview 중
→ Q: 현재 Preview만 취소
→ 주문 선택 상태로 복귀

반복 행동 고정 중
→ Q: 반복 행동 해제

Actor 선택만 남음
→ Q: Actor 선택 해제

DM 승인 요청 표시 중
→ Q: 요청 거절

미완성 벽·바닥·영역 작업 중
→ Q: 현재 미완성 결과만 취소
→ 같은 배치 모드 유지

배치 대기 상태
→ Q: 배치 모드 종료
→ 선택 모드 복귀
```

한 번의 Q로 메뉴, Preview, 행동 모드와 Actor 선택을 연속해서 모두 닫지 않는다.

현재 취소할 문맥이 없으면 아무 행동도 하지 않는다. Q는 파괴적인 작업을 승인하는 용도로 사용하지 않는다.

---

## 4. E: Confirm·Approve·Execute·Interact

E는 현재 가장 높은 Input Context의 유효한 승인 또는 확정 동작 하나를 실행한다.

```text
DM 승인 요청
→ 승인

행동의 대상·범위·비용 Preview 완료
→ 행동 실행 요청

상호작용 가능한 대상에 Focus
→ 상호작용 확정

다단계 편집 도구의 최종 확인
→ 결과 확정

턴 종료 경고 Preview
→ 턴 종료 확정
```

E는 모든 마우스 클릭을 대체하지 않는다.

- 위치와 대상 지정은 Pointer를 사용할 수 있다.
- 결과가 명확한 단순 행동은 좌클릭으로 즉시 서버 요청할 수 있다.
- 자원 소비, 광역 영향, 다중 선택, 중요한 DM 명령은 Preview 후 E 확인을 요구한다.

유효한 E 동작이 없으면 아무 행동도 실행하지 않는다.

---

## 5. 왼쪽 클릭: 선택과 기본 행동

### 5.1 선택 전

- 조작 가능 Actor 좌클릭: Actor 선택
- 선택 결과는 World Highlight, Party Rail, Initiative Ribbon과 Active Actor UI에 동일하게 반영
- 조작 불가·미인지 대상은 Viewer Projection 범위를 따른다

### 5.2 Actor 선택 후

선택 Actor를 행동 주체로 사용해 화면에 미리 표시된 기본 행동을 요청한다.

결정적 기본 우선순위:

```text
조작 가능한 다른 아군 Actor
→ 해당 Actor로 선택 전환

적대 Actor + 활성 Encounter
→ 현재 기본 공격 또는 명시적으로 지정된 기본 전투 행동

우호·중립 Actor
→ 대화·도움·상호작용
→ 공격을 암묵적 기본 행동으로 사용하지 않음

Exploration Object
→ 현재 상태에 맞는 기본 상호작용

이동 가능한 표면
→ 이동

유효한 기본 행동 없음
→ 실행하지 않고 이유 표시
```

최근 사용 행동만으로 기본 행동을 자동 변경하지 않는다. 사용자가 Action Table에서 명시적으로 지정한 경우에만 변경한다.

### 5.3 클릭 전 표시

좌클릭 결과는 클릭 전에 표시한다.

즉시:

- 대상 윤곽 또는 목적지 표시
- 행동 종류 Cursor
- 기본 행동 이름

짧은 Hover:

- 거리와 비용
- 명중 예상과 Advantage·Disadvantage
- 이동 경로와 남은 이동력
- 사용 불가 사유

긴 Hover 또는 상세 요청:

- 규칙 설명
- 계산 근거
- 상태·자원·출처 상세

---

## 6. 오른쪽 클릭: Context Action Table

오른쪽 클릭은 선택 Actor, 클릭 대상, Session Context와 Viewer Capability를 결합한 전체 행동표를 연다.

기본 표현은 2열 버튼표다. 행동 순서는 가능한 한 안정적으로 유지한다.

```text
기본 행동
→ 행동
→ 추가 행동
→ 이동
→ 상호작용
→ 정보·살펴보기
→ 허용된 DM 전용 행동
```

권한과 현재 가용성을 구분한다.

```text
Viewer 권한에 없는 행동
→ 표시하지 않음

Viewer 권한에는 있으나 현재 조건을 만족하지 못한 행동
→ 비활성 색상 버튼
→ 클릭 불가
→ Hover 시 커서 옆에 불가능한 이유 표시

현재 실행 가능
→ 활성 버튼
```

버튼 옆에 가능·불가능 문장을 상시 붙이지 않는다.

대표 Tooltip 사유:

- 현재 턴이 아닙니다
- 행동을 이미 사용했습니다
- 남은 이동 거리가 부족합니다
- 대상이 사거리 밖에 있습니다
- 시야가 확보되지 않았습니다
- 필요한 자원이 없습니다
- 이 대상을 조작할 권한이 없습니다

행동표는 Capability Projection이며 규칙 원본이 아니다. 서버가 권한, Turn, Opportunity, 자원, 거리와 대상 유효성을 다시 검증한다.

행동표가 열린 동안:

- Q: 행동표 닫기
- 중클릭 드래그: 카메라 Orbit 유지
- WASD·Wheel: 카메라 조작 유지
- 다른 대상 우클릭: 기존 표를 새 대상 표로 교체
- 월드 좌클릭 기본 행동: 실행하지 않음

---

## 7. 마우스 휠 클릭: 카메라 Orbit

오른쪽 클릭은 카메라에 사용하지 않는다.

```text
마우스 휠 클릭 드래그
→ Yaw·Pitch Orbit

WASD
→ 카메라 기준 수평 이동

Wheel
→ Zoom

Ctrl+Wheel
→ Pivot Y 이동

F 또는 Space
→ 선택 Actor Frame
```

Text Input이 Focus된 동안 WASD와 Camera 단축키를 소비하지 않는다.

턴 전환은 카메라를 강제로 이동하지 않는다. 현재 Actor를 강조하고 Frame 입력을 제안하며, 자동 초점은 사용자 설정 또는 명시적 연출에서만 허용한다.

카메라와 선택 Actor 사이 구조물, 지붕과 상층은 Presentation 계층에서 보정한다. 이 보정은 Viewer Perception과 비밀 정보 공개를 우회하지 않는다.

---

## 8. 이동과 대상 지정 Preview

이동 위치 Hover 또는 행동 Targeting 중 가능한 범위에서 다음을 표시한다.

- 예상 경로와 총 거리
- 남은 이동력과 초과 구간
- 어려운 지형, 점프, 등반과 문 통과
- 위험 지역과 기회 공격 가능 위치
- 최종 위치와 도달 불가 이유
- 사거리와 범위 형태
- 영향을 받는 Actor
- 엄폐, 시야와 예상 명중 조건

유효 대상, 불리한 유효 대상과 현재 불가능한 대상을 구분한다.

미인지 대상, 숨은 정보와 Viewer에게 공개되지 않은 Actor는 비활성 윤곽이나 후보 목록에도 노출하지 않는다.

겹친 후보의 기본 선택 우선순위:

```text
현재 행동에 유효한 Actor
→ 직접 보이는 조작 가능 Actor
→ 상호작용 Object
→ 이동 표면
```

후보가 모호하면 작은 대상 선택 목록을 커서 근처에 열 수 있으며 Q로 닫는다.

---

## 9. 행동 모드와 확인 경계

행동표 또는 Hotbar에서 추가 대상이 필요한 행동을 선택하면 일시적 행동 모드로 진입한다.

```text
행동 선택
→ 유효 대상과 범위 표시
→ 좌클릭으로 대상 또는 위치 지정
→ 필요 시 Preview
→ 서버 실행
→ 일반 기본 행동 문맥 복귀
```

반복 행동 모드는 사용자가 명시적으로 고정한 경우에만 유지하며 Q로 해제한다.

좌클릭 즉시 요청 가능:

- 단순 이동
- 기본 단일 대상 공격
- 문 열기·닫기
- 조사와 비용 없는 기본 상호작용

Preview 후 E 필요:

- 주문 슬롯 또는 중요한 제한 자원 소비
- 희귀 소모품
- 아군 피해 가능 광역 행동
- 여러 대상 또는 여러 변형
- 집중·지속 효과 종료
- 되돌리기 어려운 DM 명령
- 결과가 모호한 행동

---

## 10. Actor 선택과 턴 연속성

이동, 공격과 상호작용 완료 후 행동 주체 Actor 선택을 유지한다. 결과 대상, 임시 범위와 Preview만 제거한다.

Party Rail, Initiative Ribbon과 월드 Actor 선택은 같은 Selection Projection을 사용한다.

다른 조작 가능한 아군 Actor 좌클릭은 항상 선택 전환이 우선이다.

턴 시작 시:

- 현재 Actor를 HUD와 월드에서 강조
- 필요하면 `F/Space: 현재 Actor 보기` 안내
- 카메라 위치는 유지

턴 종료가 불가능하면 버튼을 비활성 색상으로 표시하고 Hover 시 이유를 커서 옆에 표시한다.

턴 종료가 가능하지만 남은 이동·추가 행동이 있으면 버튼을 막지 않고 경고 Preview를 제공한다.

```text
E → 턴 종료
Q → 경고 닫기
```

---

## 11. 서버 요청과 오류 피드백

입력 직후 성공을 가정하지 않되 접수 피드백은 즉시 제공한다.

```text
입력 직후
→ 대상·목적지 Pending 표시

서버 승인
→ 확정 표시와 실제 실행

서버 거부
→ Pending 제거 또는 Authority 상태 복구
→ 커서·대상·관련 HUD 근처에 사유 표시
```

일반 행동 실패는 화면 중앙 Modal을 사용하지 않는다.

Modal 사용 범위:

- 세션 연결 상실
- 복구 불가 저장·권위 오류
- 위험한 DM 명령 확인
- 반드시 응답해야 하는 Authority Prompt

World Feedback, Context Action Table, Hotbar, Party Rail, Initiative Ribbon과 End Turn UI는 같은 Projection Revision을 사용한다.

---

## 12. 정보 밀도와 접근성

```text
항상 표시
→ HP, 현재 행동 자원, 턴, 선택 Actor

행동 선택 시
→ 비용, 사거리, 대상 조건

Hover 시
→ 불가능 사유와 상세 규칙

확장 패널
→ 계산식, 출처와 전체 상태
```

비활성 상태의 기본 시각 표현은 비활성 색상이다. 동시에 Pointer 입력 차단, Hover Tooltip과 Focus 상태가 동일한 `availabilityState`를 사용한다.

지원 설정:

- UI Scale
- Tooltip Delay
- 색각 보조
- 화면 흔들림과 연출 감소
- 중요한 오류의 텍스트 표시
- 길게 누르기 대신 클릭 확정

Tooltip은 클릭 대상과 중요 HUD를 가리지 않도록 커서 진행 방향 반대쪽을 우선 사용한다.

---

## 13. 1–5: 주요 행동 슬롯

1–5는 플레이와 DM 진행에서 화면에 표시된 주요 행동에만 대응한다.

예:

```text
일반 턴
→ 사용자 지정 주요 행동

주문 변형
→ 주문 슬롯 레벨 또는 변형

반응 Prompt
→ 사용 가능한 반응 선택
```

규칙:

- 의미가 표시되지 않은 숨은 숫자 단축키를 만들지 않는다.
- 같은 시스템에서는 가능한 한 같은 슬롯 위치를 유지한다.
- 사용할 수 없는 슬롯은 비활성 상태로 유지할 수 있다.
- 행동이 여섯 개 이상이면 핵심 다섯 개만 슬롯에 두고 나머지는 Action Table이나 확장 메뉴에 둔다.
- 위험하거나 되돌리기 어려운 결과는 숫자 입력만으로 확정하지 않고 필요 시 E를 요구한다.
- 씬 편집기는 기본적으로 1–5를 사용하지 않는다.

---

## 14. 입력 문맥 스택

높은 우선순위부터:

```text
1. 텍스트, 검색과 수치 입력
2. Authority Prompt, 경고와 필수 선택 Modal
3. Context Action Table, Targeting, Preview와 진행 중 드래그
4. 현재 주요 모드: 전투, 탐험, DM 진행, 씬 편집
5. 전역 카메라와 일반 단축키
```

가장 위의 유효 Input Context 하나만 입력을 소비한다.

예를 들어 DM이 씬을 편집하던 중 승인 요청이 도착하면:

```text
E
→ 승인 요청 처리
→ 편집 결과는 확정하지 않음

Q
→ 승인 요청 거절
→ 편집 모드는 종료하지 않음
```

---

## 15. DM 승인 요청

기본 입력:

```text
E → 승인
Q → 거절
```

추가 선택지가 필요한 경우에만 1–5를 사용한다.

승인 요청에는 최소한 다음 정보를 표시한다.

- 요청 플레이어와 Actor
- 행동·주문 이름
- 대상과 범위
- 필요한 자원
- 자동 판정 결과
- DM이 확인할 예외
- 현재 Q와 E 의미

서버가 요청 상태와 DM 권한을 검증한다. 클라이언트 입력만으로 승인 상태를 완료하지 않는다.

---

## 16. 씬 편집에서의 적용

씬 편집은 공통 Q와 E를 사용하되 플레이 Context의 좌클릭 기본 행동과 Action Table을 그대로 적용하지 않는다. 활성 Scene Edit Context가 Pointer 의미를 소유한다.

```text
미완성 작업 중 Q
→ 현재 결과만 취소
→ 도구 유지

배치 대기 상태에서 Q
→ 도구 종료
→ 선택 모드 복귀

최종 확인 대기 중 E
→ 결과 확정
```

- Shift 유지: 이동·회전·스케일·배치 스냅 임시 해제
- 숫자 입력란 Focus 중 Gameplay 입력 차단
- 편집 Component는 물리 키를 직접 감시하지 않음
- Scene Edit Context 종료 시 등록한 Semantic Action을 반드시 해제

---

## 17. 구현 책임

- `InputRouterService`: 물리 입력을 Semantic Action으로 변환
- `InputContextService`: 활성 Context 스택과 단일 소비
- `InputBindingService`: 기본 바인딩과 사용자 재설정
- `InputHintService`: 현재 Q, E, Pointer와 1–5 의미 표시
- `ContextActionProjectionService`: Capability 기반 Action Table과 가용성
- `PointerFeedbackService`: Cursor, Hover, Tooltip과 기본 행동 표시
- `TargetingPreviewService`: 경로·범위·대상 Preview
- `SelectionService`: Actor 선택 연속성과 Candidate 처리
- `ModalActionService`: Authority Prompt와 필수 응답 입력 독점

각 Context는 자신이 처리할 Semantic Action만 등록하고 종료 시 반드시 해제한다.

---

## 18. 확정 사항

1. ESC에는 Gameplay 의미를 부여하지 않는다.
2. Q는 최상위 문맥 하나만 닫거나 취소한다.
3. E는 현재 Preview·선택·승인·확정을 실행한다.
4. 왼쪽 클릭은 선택 또는 클릭 전에 표시된 기본 행동이다.
5. 오른쪽 클릭은 Capability 기반 전체 행동표다.
6. 마우스 휠 클릭 드래그는 카메라 Orbit이다.
7. 권한에 없는 행동은 숨기고, 현재 불가능한 행동은 비활성 색상으로 표시한다.
8. 비활성 버튼 Hover 시 커서 옆에 구체적 불가능 사유를 표시한다.
9. 이동·공격·상호작용 후 Actor 선택을 유지한다.
10. 턴 전환은 카메라를 강제 이동하지 않는다.
11. 이동·대상·범위·비용은 실행 전에 Preview한다.
12. 서버 Pending·승인·거부를 구분한다.
13. 일반 오류는 관련 위치에 표시하고 Modal을 남용하지 않는다.
14. World Feedback과 HUD는 같은 Projection Revision을 사용한다.
15. 서버가 최종 권한, 자원과 실행 가능 여부를 검증한다.

---

## 19. 후속 기획·검증

1. 기본 전투 행동 지정 UI와 저장 범위
2. 겹친 대상 선택 목록의 키보드 탐색
3. Tooltip Delay 기본값과 화면 경계 배치
4. 이동 위험·기회 공격 시각 문법
5. Pending·승인·거부 애니메이션과 지속 시간
6. Human UI·Accessibility Evidence
7. Player·DM·Observer별 Context Action Projection 검증
8. 게임패드와 모바일 입력 어댑터
