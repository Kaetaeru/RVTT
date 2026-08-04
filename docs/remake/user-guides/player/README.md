# RVTT Player Guide

- 사용자 가이드 상태: `TARGET_EXPERIENCE`
- 대상: Player, Observer
- 최종 갱신일: 2026-08-05
- User Guide Hub: [`../README.md`](../README.md)
- 세부 작업 순서: [`../CURRENT-USER-GUIDE-WORK-ORDER.md`](../CURRENT-USER-GUIDE-WORK-ORDER.md)

> 이 문서는 구현 전 목표 사용자 경험이다. 실제 Release가 나온 뒤 화면 배치와 조작을 다시 검증해 `RELEASE_VERIFIED`로 갱신한다.

RVTT는 DM이 실시간으로 진행하는 D&D 세션을 전술 RPG처럼 플레이하도록 만든 가상 테이블탑이다. 플레이어는 복잡한 편집 도구나 서버 상태를 직접 다루지 않고, 자신의 Character를 선택해 이동하고, 주변을 조사하고, 행동·주문·아이템을 사용한다.

## 1. 빠른 시작

처음 참가할 때의 기본 흐름은 다음과 같다.

```text
캠페인 접속
→ 자신에게 허용된 Character 선택
→ Character Sheet와 현재 상태 확인
→ Ready
→ DM의 시작 승인 대기
→ Scene 동기화
→ 자신의 Token 선택
→ Exploration 시작
```

세션이 이미 진행 중이라면 현재 Scene과 Character 상태를 받은 뒤 안전한 시점에 합류한다. 화면이 보인다고 바로 조작 가능한 것은 아니다. 동기화가 끝나고 Gameplay Ready 안내가 표시된 뒤 행동한다.

## 2. 플레이 전에 알아둘 것

### 지원 환경

- 초기 지원 환경은 PC 키보드·마우스다.
- 기본 표시 언어는 한국어다.
- 기본 Ruleset은 D&D `dnd5e-2024`다.
- 모바일·게임패드·터치는 초기 지원 범위가 아니다.

### Character와 Token

Character는 레벨, 능력치, 주문, 아이템과 장기 상태를 가진 캠페인상의 인물이다. Token은 현재 Scene에 놓인 3D 미니어처다.

Scene을 이동하거나 Token이 새로 배치돼도 Character의 레벨, HP, 아이템과 장기 상태는 유지된다. 반대로 화면에 보이는 Token Model이나 Animation이 Character 데이터의 원본은 아니다.

### 내 Character와 현재 조작권

Character를 소유하고 있다는 것과 지금 Token을 조작할 수 있다는 것은 다를 수 있다.

예를 들어:

- 연결이 끊긴 동안 DM이 Token을 대신 조작할 수 있다.
- 한 플레이어가 임시 NPC를 함께 조작할 수 있다.
- Character Owner는 유지한 채 현재 전투에서 다른 사람이 조작할 수 있다.

현재 자신이 조작 가능한 대상은 화면에 명확히 표시된다.

## 3. 기본 입력

RVTT는 현재 상황에 따라 같은 키의 의미를 바꾸되, 화면에 현재 의미를 표시한다.

### Q

```text
Q
→ 현재 단계 취소
→ 요청 거절
→ 한 단계 뒤로
```

Q 한 번은 가장 가까운 미완성 단계 하나만 취소한다.

예:

- 주문 대상 지정 중: 대상 지정만 취소
- 이동 경로 확인 중: 아직 실행하지 않은 경로 취소
- 반응 사용 요청 중: 반응 거절
- 열린 메뉴의 하위 선택 중: 이전 단계로 이동

이미 확정된 주사위 결과나 Commit된 행동은 Q로 되돌리지 않는다.

### E

```text
E
→ 승인
→ 확정
→ 실행
→ 기본 상호작용
```

예:

- Focus된 문 열기
- 선택이 끝난 행동 실행
- 현재 경로 이동 승인
- 시스템 질문에 동의

유효한 E 행동이 없으면 아무것도 실행하지 않는다.

### 1–5

숫자 키는 현재 화면에 Label이 표시된 경우에만 주요 행동 슬롯으로 사용한다.

예:

```text
[1 이동] [2 행동] [3 추가 행동] [4 반응] [5 기타]
```

또는 현재 선택한 주문·능력에 따라 다른 선택지가 표시될 수 있다. 화면에 의미가 없는 숨은 숫자 단축키는 사용하지 않는다.

### 마우스

- 왼쪽 클릭: 선택, 위치 지정, 대상 지정, UI 조작
- 오른쪽 드래그: Camera 회전 등 Camera 조작
- 휠: 확대·축소 등 현재 Camera 조작

최종 Camera 키와 감도는 설정과 사용성 테스트에서 확정한다.

## 4. Camera 사용

Camera는 Character와 분리된 자유 전술 Camera다.

가능한 경험:

- 전장을 자유롭게 이동
- 회전과 확대·축소
- 높이 조절
- 자신의 Character로 Focus
- Character Follow 켜기·끄기
- 시야를 가리는 벽과 지붕의 표시 보정

Camera가 멀리 이동해도 Character 위치, 이동 가능 거리, 시야 권한과 공개 정보는 바뀌지 않는다. 비공개 Token이나 발견하지 못한 함정이 Camera 범위에 들어왔다고 자동으로 공개되지 않는다.

연출이 Camera를 잠시 이동시킨 경우 종료 후 이전 Camera 상태로 돌아간다. 접근성 설정에서 과도한 Camera Shake, Flash와 Motion을 제한할 수 있다.

## 5. Exploration

Exploration은 자유 이동, 조사, 상호작용과 비전투 행동을 중심으로 진행한다.

### 자신의 Token 선택

Token을 클릭하거나 현재 Character 목록에서 선택한다. Hover, Keyboard Focus, 지속 Selection과 실제 행동 Target은 서로 다르다.

- Hover: Pointer가 잠시 가리키는 대상
- Focus: 키보드나 후보 전환으로 현재 강조된 대상
- Selection: 계속 열람하거나 조작하려고 선택한 대상
- Target: 특정 행동에서 실제로 지정한 대상

Hover만으로 행동이 실행되거나 Camera가 강제로 움직이지 않는다.

### 클릭 이동

1. 자신의 Token을 선택한다.
2. 이동 가능한 바닥에 Pointer를 둔다.
3. Preview 경로와 거리, 험지, 문·점프 같은 주요 전환을 확인한다.
4. 목적지를 선택한다.
5. 필요한 경우 E로 확정한다.
6. 승인된 경로를 따라 Token이 이동한다.

탐험에서는 Turn별 이동력 제한을 기본으로 사용하지 않지만, 이동이 언제나 즉시 끝까지 진행되는 것은 아니다.

다음 상황에서는 중간에 멈출 수 있다.

- 문이나 새로운 장애물
- 상호작용 지점
- 함정·위험·이벤트
- 적대 상황과 Encounter 시작
- DM의 이동 잠금
- 이동 중 경로가 크게 변경됨

경로가 단순히 우회되는 정도라면 목적지를 유지해 다시 계산할 수 있다. 비용·위험·이동 방식이 의미 있게 달라지면 다시 확인한다.

### WASD Token 이동

Exploration에서는 선택한 Token을 WASD로 직접 움직일 수 있다.

WASD는 Token을 Roblox Character처럼 물리적으로 걷게 하는 기능이 아니다. 짧은 방향 이동 의도를 반복 제출하고, 이동 가능한 바닥과 장애물을 계속 확인한다.

- 클릭 이동과 같은 이동 규칙을 사용한다.
- 최종 위치는 서버가 확정한다.
- 벽이나 허용되지 않은 공간을 Client 움직임으로 통과할 수 없다.
- 동기화가 어긋나면 화면 위치가 권위 위치로 보정된다.

## 6. 주변 확인과 정보 공개

화면에 보이는 정보는 현재 Character가 알 수 있는 내용과 세션 권한에 따라 달라진다.

다음은 서로 같은 뜻이 아니다.

```text
현재 눈에 보임
발견함
이전에 알고 있음
상세 정보가 공개됨
```

예를 들어 이전에 본 방의 지형은 기억된 형태로 보이지만, 현재 그 안의 문 상태나 Token 위치가 실시간으로 보장되지는 않는다.

### Fog

Fog는 지형의 탐험 상태를 표시한다.

- 미탐험: 아직 공개되지 않은 지형
- 기억됨: 과거에 확인했지만 현재 직접 보고 있지 않은 지형
- 현재 공개: 지금 볼 수 있는 지형

Fog가 열렸다고 숨은 Actor, 함정과 비밀문이 모두 발견되는 것은 아니다. Search, Study, 감각과 상황에 따라 별도로 발견한다.

### 비밀 정보

발견하지 못한 함정, 비밀문, 숨은 Actor와 실제 비밀 수치는 Player Client에 미리 전달하지 않는다. 단순히 투명하게 숨겨 두는 방식이 아니다.

따라서 Hover, 검색, Tooltip과 오류 메시지를 이용해 숨은 정보를 알아낼 수 없다.

## 7. 상호작용과 조사

문, 상자, 레버, 바닥 Item과 기타 상호작용 가능한 대상을 Focus하면 현재 가능한 행동이 표시된다.

기본 흐름:

```text
대상 Focus
→ E 기본 상호작용
또는 Context Action 열기
→ 행동 선택
→ 필요한 대상·옵션·판정
→ 결과 표시
```

가능한 행동은 대상 종류만으로 고정되지 않는다. 현재 Character의 능력, 아이템, Effect, 거리, 상황과 Exploration·Encounter 상태에 따라 달라진다.

예:

- 문 열기·닫기·잠금 해제 시도
- 상자 열기·내용물 확인
- 레버 사용
- Item 줍기
- Search·Study
- Hide
- 특수 능력이나 주문 사용

자동화하기 어려운 즉흥 행동은 DM에게 구조화된 판정 요청을 보낼 수 있다. DM이 자유 텍스트로 임의 코드를 실행하는 방식은 아니다.

## 8. 행동, 주문과 아이템

Character Sheet, Combat HUD 또는 Context Action에서 사용할 행동을 선택한다.

일반 흐름:

```text
행동 선택
→ 사용 방식 선택
→ 대상·위치·경로 선택
→ 비용과 경고 확인
→ 실행 확정
→ 주사위·반응·결과 해결
→ HP·자원·상태 갱신
```

### Preview와 실제 결과

Range, Area, 경로와 예상 대상 Preview는 결정을 돕는 표시다. 실행 순간의 실제 대상, 시야, 거리, 자원과 상태는 다시 확인된다.

Preview가 가능하다고 표시했더라도 다음과 같은 이유로 실행이 거부될 수 있다.

- 대상이 이동함
- 문이나 장애물 상태가 바뀜
- 필요한 자원이 이미 사용됨
- 현재 조작권이 바뀜
- 다른 행동이 먼저 확정됨
- Scene이나 권위 상태가 갱신됨

거부되면 권위 상태는 바뀌지 않으며, 가능한 경우 다시 선택할 수 있다.

### 주문 시전 방식

같은 주문도 여러 방식으로 사용할 수 있다.

예:

- Class Spell Slot
- 무료 시전 Feature
- Item Charge
- Ritual
- 임시 Effect가 제공한 시전

화면에는 현재 사용할 수 있는 방식과 필요한 비용이 표시된다. 주문을 쓰기 위해 장비를 몰래 자동 해제하거나 Inventory를 임의로 바꾸지 않는다.

### 반응

Reaction은 언제든 누르는 일반 버튼이 아니다. 규칙상 가능한 사건이 발생했을 때 Prompt가 열린다.

```text
반응 가능 사건
→ 사용할 수 있는 Reaction 표시
→ Q 거절 또는 행동 선택
→ 필요한 경우 E 확정
→ 결과 해결
```

Prompt가 닫혔거나 시간이 끝났다고 Client가 임의로 반응 결과를 확정하지 않는다.

## 9. 주사위와 결과

주사위 결과는 서버가 생성한다. 화면의 3D 주사위 Animation이나 물리 결과가 실제 난수의 원본이 아니다.

다음 단계를 구분한다.

```text
굴림 생성
→ 필요한 대상에게 공개
→ 반응과 수정 처리
→ 최종 결과 확정
→ 실제 상태 변경
```

공개된 굴림은 결과가 마음에 들지 않는다는 이유로 다른 숫자로 덮어쓰지 않는다. 규칙상 Reroll이나 Modifier가 적용되면 별도 근거와 함께 결과가 계산된다.

비밀 굴림은 DM이나 허용된 Audience에게만 표시될 수 있다.

## 10. Encounter

Encounter는 Combat뿐 아니라 Chase, Hazard, Escape와 제한 시간 목표를 포함할 수 있다.

Encounter가 시작되면 같은 Scene과 현재 Token 위치를 유지한 채 UI와 이동·행동 제한이 바뀐다.

### 시작

```text
적대 행동·위험·DM 시작
→ 참가자와 진영 확인
→ 필요한 이니셔티브 굴림
→ 순서 공개
→ 첫 Turn 시작
```

필수 이니셔티브 결과와 동률 처리가 끝나기 전에는 임시 순서로 Turn을 시작하지 않는다.

### 자신의 Turn

화면에서 다음을 확인한다.

- 현재 Turn과 다음 순서
- 남은 이동력
- Action·Bonus Action·Reaction 등 현재 기회
- 사용할 수 있는 행동·주문·아이템
- Objective와 중요한 상태

Encounter는 행동 자체를 새로 제공하지 않는다. Character가 가진 행동·주문·아이템 중 현재 Turn에 사용할 수 있는 것이 표시된다.

### 전투 이동

Encounter에서는 Token WASD 이동을 사용하지 않는다.

1. 목적지나 경유점을 선택한다.
2. 경로, 거리, 남은 이동력과 예상 중단 지점을 확인한다.
3. 경로를 확정한다.
4. Token이 안전한 Checkpoint 단위로 이동한다.

Encounter 중 WASD는 Camera 이동에 사용할 수 있다.

이동 중 Reaction, 함정, 위험 영역이나 동적 장애물이 발생하면 가장 가까운 안전 지점에서 멈춘다. 이미 실제로 통과한 거리와 비용은 단순 취소로 환불되지 않는다.

### HP 0과 사망

HP, Temporary HP, 의식불명, 죽어감, 안정화, Death Save와 사망은 서로 다른 상태다. HP가 0이 됐다고 Character, Inventory와 Token이 즉시 삭제되지 않는다.

현재 상태와 가능한 행동은 Character Sheet와 Combat HUD에 표시된다.

### Encounter 종료

Objective 달성, 도주, 항복, 규칙 결과 또는 DM 결정으로 종료 후보가 만들어진다. 열린 행동과 반응이 정리된 뒤 Exploration 또는 다른 세션 상태로 돌아간다.

종료 후에도 다음은 현재 결과를 유지한다.

- Token 위치
- HP와 자원
- 문·함정·바닥 Item 상태
- 지속 Effect
- 발견 정보

## 11. Character Sheet와 Inventory

Character Sheet는 현재 Character의 공개 가능한 정보를 보여준다.

주요 내용:

- 기본 능력과 파생 수치
- 현재 HP·Temporary HP·Resource
- 종·배경·직업·하위직업·Feat
- 숙련과 Weapon Mastery
- 행동·특성·주문
- Condition·Effect·Concentration
- Inventory·Equipment·Attunement

화면의 최종 수치나 버튼 목록이 Character 데이터의 저장 원본은 아니다. 장비, Effect와 상황이 바뀌면 현재 표시가 다시 계산된다.

### Item

하나의 실제 Item은 한 위치에만 존재한다.

가능한 위치:

- Character Inventory
- 장착 상태
- Container
- Scene 바닥
- Campaign Storage
- 소비·파괴됨

바닥 Item을 주울 때 새 복사본을 만드는 것이 아니라 같은 Item의 위치가 바뀐다. Stack을 실제로 나누는 경우에만 별도 Item 단위가 생성된다.

미확인 Item은 허용된 정보만 보이며 숨은 효과나 저주를 미리 표시하지 않는다.

## 12. Downtime

Downtime은 휴식, 레벨업, 주문 준비, 주문책 작업, 제작, 훈련과 여행처럼 시간이 필요한 활동을 처리하는 별도 플레이 상태다.

Downtime은 Character Sheet를 열었다는 뜻이나 세션 Pause와 같지 않다.

일반 흐름:

```text
활동 선택
→ 참가자와 필요한 Item·Resource 확인
→ 시간과 선택 확인
→ 진행
→ 중간 사건 또는 완료 후보
→ 결과 확정
```

현실 시간이 지났거나 사용자가 Offline이었다는 이유만으로 활동이 자동 완료되지 않는다.

Encounter 같은 사건이 발생하면 활동이 중단될 수 있다. 사건이 끝난 뒤 남은 시간과 자격을 다시 확인해 재개한다.

## 13. Journal과 Ping

### Journal

Journal은 캠페인의 문서, 메모, 핸드아웃과 월드 Link를 제공한다.

가능한 경험:

- 문서와 Folder 탐색
- 현재 문서의 `##` 이상 Heading을 왼쪽 Outline에서 선택
- 공개된 문서 검색
- 다른 문서·Section·Character·Scene Object Link 열기
- 허용된 Target으로 Camera Focus·선택·Scene 이동 요청

문서 제목이나 Heading Text가 바뀌어도 같은 문서·Section으로 유지되는 Link는 계속 작동한다.

권한 없는 문서와 Section은 본문뿐 아니라 제목, 검색 결과, Backlink와 존재 자체가 공개되지 않을 수 있다.

### Ping

Ping은 지금 보고 있는 위치나 경로를 다른 참가자에게 잠시 보여 주는 표시다.

- 클릭 Ping: 한 위치 표시
- 경로 Ping: 드래그한 경로 표시

Ping은 실제 이동 명령, Target 지정, Journal Anchor와 영구 지도 주석이 아니다. 잠시 후 사라지며 세션 복구의 영구 상태로 저장하지 않는다.

## 14. 재접속과 동기화

연결이 끊겨도 Character, HP, Item, Effect, Token과 Encounter 상태는 서버에 남는다.

재접속 흐름:

```text
다시 연결
→ 현재 역할과 조작권 확인
→ 공개 가능한 현재 상태 동기화
→ 누락된 변경 적용
→ 열린 Prompt·Turn·Selection 복원
→ Gameplay Ready
```

동기화 중에는 화면 일부가 보여도 행동 입력이 잠시 제한될 수 있다.

### 화면과 권위 상태가 다를 때

다음 안내 중 하나가 표시될 수 있다.

- 잠시 기다리기
- 다시 동기화
- View 다시 열기
- 행동 다시 선택
- DM에게 문의
- Support Reference 생성

Client 화면을 기준으로 HP, Item이나 위치를 강제로 덮어쓰지 않는다.

## 15. DM Rollback 이후

DM이 과거 Checkpoint로 Rollback하면 현재 상태를 하나씩 역산하는 대신 선택한 시점의 상태를 새 진행 Branch로 복원한다.

Player에게 보이는 변화:

- Scene·Character·Encounter 상태가 다시 동기화됨
- 이전에 열려 있던 Prompt와 Selection이 닫히거나 새 상태로 다시 열림
- 이전 Branch에서 제출한 입력이 더 이상 유효하지 않음
- 현재 상태에 맞는 UI와 Camera가 다시 구성됨

이미 본 비밀 정보를 사람의 기억에서 지우지는 못한다. 그러나 새 Branch의 Client 데이터와 행동 가능 여부는 복원된 상태를 따른다.

## 16. Observer

Observer는 캠페인에 참가하지만 Character를 직접 조작하지 않는 역할이다.

Observer가 볼 수 있는 정보는 DM 설정과 공개 범위를 따른다. Observer라는 이유로 DM 전용 정보나 모든 Player의 비밀 Character 정보를 받지 않는다.

DM이 허용하면 이후 Player Role과 Character Control을 받을 수 있다. 안전하지 않은 행동 중간에 즉시 조작권이 바뀌지 않고 적절한 경계에서 적용된다.

## 17. 현재 제품 범위가 아닌 것

Player Guide에서 다음 기능을 기대하지 않는다.

- NPC 자동 대화 Tree나 AI 대화 시스템
- 음악 재생 시스템
- 환경음과 모든 규칙 효과음
- 모바일·게임패드·터치 초기 지원
- 임의 Luau Plugin 설치
- Client 물리로 판정하는 Token 이동과 주사위
- 발견하지 못한 정보를 Client에 보내고 화면에서만 숨기는 방식
- 모든 D&D 즉흥 행동의 완전 자동화

DM과 대화하거나 역할극을 진행하는 것은 Voice·Text 등 세션 외부 또는 별도 소통 방식으로 이루어지며, RVTT가 NPC 대사를 자동 생성·진행하지 않는다.

## 18. Player Quick Reference

```text
세션 참가
→ Character 선택 → Ready → 동기화 완료 대기

Q
→ 취소·거절·한 단계 뒤로

E
→ 승인·확정·실행·상호작용

Exploration 이동
→ 목적지 클릭 또는 Token WASD

Encounter 이동
→ 경로 확인 후 클릭 확정
→ Token WASD 사용 안 함

행동
→ 행동 선택 → 대상·비용 확인 → 실행 → 결과 동기화

연결 문제
→ 임의 재입력보다 현재 동기화 안내를 따름

Rollback
→ 이전 Prompt·Selection을 재사용하지 않고 새 상태 확인
```

## 19. 근거 문서

이 Player Guide는 다음 현재 문서를 사용자 언어로 통합한다.

- [`플랫폼·이동·입력 범위`](../../product/platform-movement-and-input-scope.md)
- [`Session, Networking, Persistence와 Recovery Guide`](../../guides/session/README.md)
- [`Exploration, Selection, Interaction과 Perception Guide`](../../guides/exploration/README.md)
- [`Rules, Character Action, Spell, Dice와 Effect Guide`](../../guides/rules/README.md)
- [`Combat와 Encounter Guide`](../../guides/combat/README.md)
- [`Character, Inventory와 Downtime Guide`](../../guides/character/README.md)
- [`UI, Camera와 Presentation Guide`](../../guides/ui/README.md)
- [`Journal과 Ping Guide`](../../guides/journal/README.md)

이 문서와 권위 문서가 충돌하면 Product·Architecture·System·UI·ADR이 우선한다.
