# Contextual Pointer Actions · Camera Contract

- 상태: `STATIC VERIFIED · STUDIO RETEST REQUIRED`
- 결정일: 2026-08-06
- 적용 대상: PC 키보드·마우스 플레이와 DM 조작

## 1. 포인터 문법

### 선택 전 좌클릭

- Token 좌클릭: 해당 Token을 선택한다.
- 선택 결과는 Highlight로 표시한다.

### Token 선택 후 좌클릭

선택한 Token을 행동 주체로 사용하여 클릭 대상에 가장 적합한 기본 행동 하나를 즉시 요청한다.

우선순위:

1. 활성 Encounter에서 다른 Actor Token 클릭: 첫 번째 사용 가능한 `rules.attack`
2. Exploration Object 클릭: Object 상태에 맞는 `exploration.interact`
   - 열린 대상: `close`
   - 활성 대상: `deactivate`
   - 비활성 대상: `activate`
   - 그 외: `open`, 없으면 `inspect`
3. 이동 가능한 바닥 클릭: `movement.commit`

클라이언트가 기본 행동을 선택하더라도 서버가 Actor 제어 권한, 활성 Turn, 행동 기회와 대상 유효성을 다시 판정한다.

### Token 선택 후 우클릭

- 클릭 대상과 현재 Session 상태를 기준으로 사용자가 요청할 수 있는 모든 행동을 2열 버튼 테이블로 표시한다.
- 전투 Actor 대상: 현재 Turn과 Action Opportunity가 있는 경우 공격 Profile별 공격 버튼
- Exploration Object 대상: 허용된 Interaction과 Search
- 이동 바닥: 이동 권한·Turn·거리 Budget을 만족하는 경우 이동
- 메뉴는 클라이언트 편의 필터이며 권한의 최종 근거가 아니다.
- 서버 거부 결과는 성공으로 표시하지 않는다.
- `Esc`는 먼저 메뉴만 닫는다. 메뉴가 닫힌 상태의 다음 `Esc`가 선택과 목적지를 해제한다.

### 중클릭 드래그

기존 우클릭 카메라 궤도 회전을 중클릭 드래그로 이동한다. 우클릭은 카메라를 조작하지 않는다.

## 2. 카메라 감각 기준

기존 CameraManager의 조작 상수를 기준으로 한다.

| 항목 | 값 |
|---|---:|
| Field of View | 50 |
| 기본 거리 | 65 |
| 최소·최대 거리 | 20·130 |
| 기본 Pitch | 45° |
| Pitch 범위 | -85°–85° |
| 회전 감도 | 0.004 |
| Wheel Zoom Step | 5 |
| Ctrl+Wheel 수직 이동 Step | 5 |
| WASD 이동 속도 | 55 studs/s |
| 지수형 Smooth Speed | 14 |

입력:

- `W/A/S/D`: 카메라 기준 수평 이동
- 중클릭 드래그: Yaw·Pitch 궤도 회전
- Wheel: Zoom
- `Ctrl+Wheel`: Pivot Y 이동
- `F` 또는 `Space`: 선택 Token Frame
- UI 위 포인터 입력은 카메라가 소비하지 않는다.
- TextBox가 Focus된 동안 WASD와 Camera 단축키를 소비하지 않는다.

## 3. 권한 경계

클라이언트 Action Resolver는 다음 경우에만 행동 버튼을 만든다.

- 현재 사용자가 선택 Actor의 Owner 또는 Controller
- 현재 사용자가 DM
- Encounter Action은 선택 Actor가 현재 Turn을 보유하고 해당 Opportunity가 남아 있음
- Encounter Movement는 현재 Turn과 남은 이동 거리를 만족함

최종 서버 명령은 기존 Domain authorize를 반드시 통과해야 한다.

- `rules.attack`: Attacker 제어 권한, Encounter Turn, Action Opportunity 검증
- `exploration.interact`: Actor 제어 권한, Object 공개·Interaction 허용 검증
- `exploration.search`: Actor 제어 권한과 Object 존재 검증
- `movement.commit`: Actor 제어 권한과 Movement 규칙 검증

## 4. Acceptance Host

`slice01-acceptance.project.json`에는 다음 두 패널이 함께 실행된다.

1. 기존 `slice01-world-interaction` 16개 회귀 항목
2. 신규 `contextual-pointer-actions` 9개 항목

신규 Host는 실제 서버 명령으로 다음 대상을 준비한다.

- 파란색 Exploration Console: `scene.spawn_object`
- Original Training Dummy: `npc.register_definition` + `npc.spawn`
- Hero만 참가하는 결정적 Encounter: `encounter.start`

사용자 순서:

1. Hero를 선택한다.
2. 중클릭 드래그로 Yaw·Pitch가 회전하는지 확인한다.
3. 바닥 우클릭으로 `이동` 버튼을 확인하고 `Esc`로 닫은 뒤 바닥 좌클릭으로 이동한다.
4. 파란 Console 우클릭으로 2열 행동표를 확인하고 `Esc`로 닫은 뒤 좌클릭으로 기본 상호작용을 실행한다.
5. `전투 시작` 버튼을 누르고 Hero를 다시 선택한다.
6. Dummy 우클릭으로 `공격`을 확인하고 `Esc`로 닫은 뒤 Dummy 좌클릭으로 기본 공격을 실행한다.
7. 우클릭 중 카메라가 움직이지 않는지 확인한다.

성공 Summary:

```text
[RVTT Batch Summary] batch=contextual-pointer-actions result=PASS passed=9 failed=0 pending=0 revision=...
```

## 5. Evidence 상태

2026-08-06 HEAD `582c1c4`에서 기존 Slice 01 World Interaction 16개 항목은 사용자 PASS였다.

```text
[RVTT Batch Summary] batch=slice01-world-interaction result=PASS passed=16 failed=0 pending=0 revision=12
```

해당 결과는 변경 전 입력 계약의 기준선이다.

신규 Context Input Source는 다음 정적 Gate를 통과했다.

- Structure·Input Policy
- StyLua·Selene
- 전체 Rojo Project Build
- Luau Type Analysis
- Acceptance Bootstrap
- Grand·Persistence·Production Lease·Documentation Gate

우클릭 Action Table, 좌클릭 Context Default와 중클릭 Orbit의 Studio Runtime 결과는 아직 없다.
