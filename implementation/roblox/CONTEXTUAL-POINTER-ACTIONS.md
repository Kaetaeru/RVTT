# Contextual Pointer Actions · Camera Contract

- 상태: `ADR-0088 ALIGNMENT REQUIRED · STUDIO RETEST BLOCKED`
- 최초 구현일: 2026-08-06
- 최종 기획 변경일: 2026-08-06
- 상위 권위: [`ADR-0088 직접 플레이 포인터 문법과 피드백 연속성`](../../docs/remake/decisions/ADR-0088-direct-play-pointer-grammar-and-feedback.md)
- 공통 입력: [`RVTT 공통 입력 교과서`](../../docs/remake/ui/common-input/common-input-grammar.md)
- 적용 대상: PC 키보드·마우스 플레이와 DM 직접 Actor 조작

## 1. 상태 경계

기존 Context Input Source와 Acceptance Host는 정적 Gate를 통과했지만, ADR-0088 이전 계약을 구현한다.

다음 차이 때문에 현재 Source를 새 기획의 Runtime Candidate로 사용하지 않는다.

- 기존 구현 문서가 `Esc`로 메뉴와 선택을 닫도록 정의함
- 기존 기본 행동 우선순위가 조작 가능한 아군 선택 전환을 먼저 보장하지 않음
- 기존 Action Resolver가 현재 실행 가능한 행동 중심으로 메뉴를 구성함
- 비활성 색상 버튼과 Hover 불가능 사유 계약이 없음
- 클릭 전 기본 행동 이름·비용·유효성 Preview가 충분하지 않음
- 이동·대상·범위·위험 Preview와 Selection Continuity Acceptance가 부족함
- 턴 전환 Soft Focus와 Pending·승인·거부 피드백 Acceptance가 없음

따라서 기존 `contextual-pointer-actions` 9개 Summary는 폐기하지 않지만 ADR-0088 합격 기준으로 사용하지 않는다.

## 2. 목표 포인터 문법

```text
선택 전 왼쪽 클릭
→ 조작 가능 Actor 선택

선택 후 왼쪽 클릭
→ 클릭 전에 표시된 상황별 기본 행동 요청 또는 Preview

오른쪽 클릭
→ 선택 Actor·대상·Viewer Capability 기준 전체 행동표

마우스 휠 클릭 드래그
→ Camera Yaw·Pitch Orbit

Q
→ 최상위 Context 한 단계만 닫기·취소

E
→ 현재 Preview·선택·승인·확정 실행

ESC
→ Gameplay 의미 없음
```

### 기본 행동 우선순위

```text
조작 가능한 다른 아군 Actor
→ 선택 전환

적대 Actor + 활성 Encounter
→ 기본 공격 또는 명시적 기본 전투 행동

우호·중립 Actor
→ 대화·도움·상호작용

Exploration Object
→ 상태 기반 기본 상호작용

이동 가능한 표면
→ movement.commit Preview 또는 요청
```

기본 행동은 클릭 전에 Cursor와 World Feedback으로 표시한다.

## 3. Context Action Table 목표

- 2열 버튼표
- 안정적인 카테고리 정렬
- Viewer 권한에 없는 행동과 미인지 정보는 표시하지 않음
- Viewer 권한에는 있으나 현재 불가능한 행동은 비활성 색상 버튼으로 표시
- 비활성 버튼은 클릭 불가
- 비활성 버튼 Hover 시 커서 옆에 구체적인 불가능 사유 표시
- 버튼 옆에 가능·불가능 문장을 상시 표시하지 않음
- Q로 Action Table만 닫음
- 다른 대상 우클릭 시 기존 표 교체
- 표가 열린 동안 월드 좌클릭 기본 행동 잠금
- 중클릭 Orbit, WASD와 Wheel Camera 유지
- 서버 Domain authorize가 최종 권한·Turn·Opportunity·자원·거리·대상을 재검증

대표 불가능 사유:

- 현재 턴이 아닙니다
- 행동을 이미 사용했습니다
- 남은 이동 거리가 부족합니다
- 대상이 사거리 밖에 있습니다
- 시야가 확보되지 않았습니다
- 필요한 자원이 없습니다

## 4. 카메라 감각 기준

기존 CameraManager의 조작 상수를 유지한다.

| 항목 | 값 |
|---|---:|
| Field of View | 50 |
| 기본 거리 | 65 |
| 최소·최대 거리 | 20·130 |
| 기본 Pitch | 45° |
| Pitch 범위 | -85°–85° |
| 회전 감도 | 0.004 |
| Wheel Zoom Step | 5 |
| Ctrl+Wheel Pivot Y Step | 5 |
| WASD 이동 속도 | 55 studs/s |
| 지수형 Smooth Speed | 14 |

입력:

- `W/A/S/D`: 카메라 기준 수평 이동
- 마우스 휠 클릭 드래그: Yaw·Pitch Orbit
- Wheel: Zoom
- `Ctrl+Wheel`: Pivot Y 이동
- `F` 또는 `Space`: 선택 Actor Frame
- TextBox Focus 중 Gameplay Camera 키 소비 금지
- 턴 전환 시 Camera 강제 이동 금지

## 5. 직접 플레이 피드백 목표

### 클릭 전

- 기본 행동 이름
- 대상 윤곽과 Cursor
- 거리·비용·유효성
- 공격 명중 예상과 조건
- 이동 경로·남은 이동력·위험

### 서버 요청

```text
입력 직후
→ Pending 대상·목적지 표시

서버 승인
→ 확정 표시와 실행

서버 거부
→ Authority 상태 복구
→ 커서·대상·관련 HUD 근처에 이유 표시
```

일반 실패는 화면 중앙 Modal을 사용하지 않는다.

### 연속성

- 이동·공격·상호작용 후 행동 주체 Actor 선택 유지
- Party Rail·Initiative Ribbon·World Selection 동기화
- 턴 시작 시 현재 Actor 강조만 수행
- Camera Frame은 사용자 입력 또는 설정에 의해서만 수행

## 6. 권한 경계

클라이언트 Action Projection은 편의 UI이며 권위 원본이 아니다.

최종 서버 명령은 기존 Domain authorize를 반드시 통과한다.

- `rules.attack`: Attacker 제어 권한, Encounter Turn, Action Opportunity 검증
- `exploration.interact`: Actor 제어 권한, Object 공개·Interaction 허용 검증
- `exploration.search`: Actor 제어 권한과 Object 존재 검증
- `movement.commit`: Actor 제어 권한과 Movement 규칙 검증

미인지 Actor, 숨은 Object와 DM 전용 Capability는 Viewer Projection에 포함하지 않는다.

## 7. 기존 Evidence

2026-08-06 HEAD `582c1c4`에서 변경 전 Slice 01 World Interaction 16개 항목은 사용자 PASS였다.

```text
[RVTT Batch Summary] batch=slice01-world-interaction result=PASS passed=16 failed=0 pending=0 revision=12
```

이 결과는 기존 Token Pick·Move·Projection의 회귀 기준선이다. ADR-0088 Pointer Grammar와 Direct Play UX의 Runtime Evidence가 아니다.

ADR-0088 이전 Context Input Source는 다음 정적 Gate를 통과했다.

- Structure·Input Policy
- StyLua·Selene
- 전체 Rojo Project Build
- Luau Type Analysis
- Acceptance Bootstrap
- Grand·Persistence·Production Lease·Documentation Gate

상위 계약 변경 후 Source와 Acceptance를 수정하고 모든 정적 Gate를 다시 실행해야 한다.

## 8. 필요한 Acceptance 확장

1. ESC Gameplay No-op
2. Q Action Table 닫기
3. Q Targeting·Preview 한 단계 취소
4. Q 반복 행동 해제
5. Q Actor 선택 해제
6. 조작 가능한 아군 좌클릭 선택 전환
7. 좌클릭 기본 행동 이름·유효성 사전 표시
8. 오른쪽 클릭 활성·비활성 행동 동시 표시
9. 비활성 색상과 Hover 불가능 사유
10. 권한 밖 행동·미인지 정보 미노출
11. 중클릭 Orbit과 우클릭 Action Table 비충돌
12. 이동 경로·비용·위험 Preview
13. 공격·범위·영향 대상 Preview
14. 행동 후 Actor 선택 유지
15. 턴 전환 Camera Soft Focus
16. Pending·승인·거부 피드백
17. 일반 실패의 Local Tooltip·World Feedback
18. 동일 Projection Revision의 World·HUD 일관성

## 9. 다음 상태 전이

```text
ADR-0088 하위 Source 정합화
→ Acceptance 확장
→ Static·Security·StyLua·Selene·Rojo·Luau PASS
→ Context Input Studio Retest
→ Human UI·Accessibility Evidence
→ DM·Player·Observer 권한별 Runtime Test
```
