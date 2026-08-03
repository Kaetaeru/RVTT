# 41. DM Quick Action과 문맥 명령 실행 모델

- 상태: 초안
- 작성일: 2026-08-03
- 관련 문서:
  - [`08. 공통 입력 교과서`](08-common-input-grammar.md)
  - [`28. 인카운터·주도권·턴과 제어권 모델`](28-encounter-initiative-turn-and-control-authority-model.md)
  - [`37. 전투 턴 스냅샷 타임라인`](37-encounter-turn-snapshot-timeline-and-dm-rollback-model.md)
  - [`39. DM 작업공간과 씬 라이팅 모델`](39-dm-workspace-and-scene-lighting-model.md)
  - [`ADR-0047`](decisions/ADR-0047-contextual-dm-quick-actions-and-safe-command-execution.md)

## 1. 목적

DM이 현재 선택한 Actor나 오브젝트를 기준으로 가장 자주 쓰는 명령을 즉시 실행하게 한다. Quick Action은 Command Palette보다 문맥 중심이고, Inspector보다 빠르다.

```text
Command Palette
→ 전체 기능 검색

Quick Action
→ 현재 선택 대상에 가능한 명령만 표시
```

## 2. 열기와 종료

Quick Action은 의미 입력 `OpenQuickAction`으로 등록한다. 기본 키는 사용자 설정에서 정하며 특정 물리 키에 엔진을 하드코딩하지 않는다.

```text
OpenQuickAction
→ 오버레이 표시

Q
→ 하위 단계 취소
→ 최상위에서는 오버레이 닫기

E
→ 선택 항목 확정

1–5
→ 상단 우선 행동 즉시 선택
```

마우스와 키보드를 모두 지원한다. 오버레이는 커서 주변 또는 화면 중앙 안전 영역에 표시하며 전장을 과도하게 가리지 않는다.

## 3. 문맥 수집

```text
QuickActionContext
├─ selectedEntityIds
├─ primaryEntityId
├─ hoveredEntityId
├─ worldPosition
├─ activeSceneId
├─ encounterId
├─ currentTurnId
├─ actingUserId
├─ dmPermissionSet
└─ authorityRevision
```

선택 우선순위:

```text
명시적 선택
→ Hover 대상
→ 커서 월드 위치
→ 현재 Actor
→ 장면 전체
```

다중 선택에서는 모든 대상에 공통으로 적용 가능한 명령과 일괄 명령만 표시한다.

## 4. Registry

```text
QuickActionRegistry:Register({
    actionId,
    category,
    supportedContexts,
    predicate,
    buildLabel,
    buildPreview,
    executionAdapter,
    confirmationPolicy,
    dangerLevel,
    undoPolicy,
})
```

중앙 UI 코드는 Door, Trap, Actor 같은 구체 타입을 분기하지 않는다. 각 시스템이 자신의 Quick Action을 등록한다.

## 5. 기본 분류

```text
Primary
State
Combat
Visibility
Control
Journal
Scene
Utility
Dangerous
Recent
Favorite
```

첫 화면에는 최대 5개의 우선 행동을 크게 표시한다. 나머지는 분류별 하위 목록이나 검색으로 연다.

## 6. Actor 문맥

플레이어 캐릭터 또는 NPC를 선택하면 다음 후보를 제공한다.

```text
시트 열기
HP 변경
임시 HP 변경
상태 추가·제거
숨기기·공개
이동 또는 순간이동
주도권에 추가·제거
제어권 배정·회수
판정 요청
복제
삭제
```

현재 상황에 맞지 않는 명령은 숨기거나 비활성화 이유를 표시한다.

```text
전투 참가 중이 아님
→ 턴 종료 명령 숨김

플레이어에게 제어권 없음
→ 회수 명령 숨김

집중 중이 아님
→ 집중 종료 명령 숨김
```

HP 변경은 빠른 프리셋과 직접 입력을 모두 지원한다.

```text
피해 1 / 5 / 10
회복 1 / 5 / 10
값 직접 입력
최대치로 회복
HP 0 설정
```

`HP 0 설정`은 위험 명령으로 분류하고 결과를 미리 보여준다.

## 7. 문·상자·레버·함정

```text
Door
├─ 열기
├─ 닫기
├─ 잠금
├─ 잠금 해제
├─ 상태 강제 지정
├─ 연결된 레버 보기
└─ Inspector 열기

Chest
├─ 열기
├─ 닫기
├─ 잠금
├─ 내용물 열기
├─ 함정 활성화·해제
└─ 플레이어에게 공개

Trap
├─ 활성화
├─ 해제
├─ 즉시 발동
├─ 발견 상태 변경
├─ TriggerVolume 표시
└─ EffectRecipe 미리보기
```

상태 전환은 기존 InteractionObject 명령과 Tween 시스템을 사용한다.

## 8. Light와 Scene

```text
Light
├─ 켜기·끄기
├─ 밝기 프리셋
├─ 규칙 조명 범위 보기
└─ Inspector 열기

WorldPosition
├─ NPC 소환
├─ 오브젝트 배치
├─ 위치 핑
├─ Fog 공개·숨김
├─ 카메라 북마크 생성
└─ 저널 링크 생성
```

Quick Action에서 배치를 선택하면 기존 연속 배치 모드로 들어간다. 임의로 Workspace에 복제하지 않는다.

## 9. Player 문맥

```text
플레이어에게 핑
현재 위치로 카메라 이동 요청
캐릭터 또는 NPC 제어권 배정
Observer 전환
DM 제어권 인수
연결 상태 보기
강퇴
```

제어권 변경은 즉시, 현재 행동 종료 후, 현재 턴 종료 후 또는 다음 라운드 시작 시점으로 예약할 수 있다.

## 10. Encounter 문맥

```text
전투 시작
참가자 추가
참가자 제거
이니셔티브 굴림
현재 턴 종료
라운드 진행
전설적 행동 기회 열기
전투 일시정지
턴 타임라인 열기
전투 종료
```

전투 종료와 타임라인 복구는 확인 창과 변경 비교가 필요하다.

## 11. Journal 링크

Actor, 오브젝트 또는 방에 연결된 문서가 있으면 Quick Action 상단에 표시한다.

```text
12번 방 문서 열기
선택 Actor 문서 열기
새 연결 문서 만들기
현재 선택을 문서에 링크 복사
```

DM 전용 문서는 플레이어 클라이언트에 노출하지 않는다.

## 12. 최근 사용과 즐겨찾기

```text
RecentQuickActions
→ 최근 실행한 actionId와 문맥 타입

FavoriteQuickActions
→ DM이 고정한 actionId
```

최근 기록에는 대상의 실제 비밀 이름이나 민감한 상태를 영구 문자열로 저장하지 않고 안전한 참조와 표시 메타데이터만 저장한다.

## 13. 확인 정책

```text
none
→ 즉시 실행

inline
→ E 한 번으로 확인

modal
→ 변경 요약 후 명시적 확인

typed_confirmation
→ 캠페인 삭제처럼 극단적 작업에만 사용
```

위험도:

```text
safe
caution
high
critical
```

예시:

```text
문 열기
→ safe

Actor 10 피해
→ caution

Actor 삭제
→ high

전투 타임라인 복구
→ high
```

## 14. 실행 경계

Quick Action은 직접 상태를 수정하지 않는다.

```text
QuickAction 선택
→ 현재 authorityRevision 재검사
→ 실행 명령 생성
→ 서버 권한·대상·상태 검증
→ CommandJournal 기록
→ Commit
→ UI 갱신
```

가능한 실행 Adapter:

```text
ActionIntentAdapter
SceneCommandAdapter
InteractionCommandAdapter
ControlAssignmentAdapter
DmOverrideAdapter
JournalCommandAdapter
FogCommandAdapter
EncounterCommandAdapter
```

## 15. Undo와 Rollback

단순 장면 명령은 History의 Undo를 사용할 수 있다. 공격, 피해, 자원 소모와 전투 상태 변경은 임의 역명령을 만들지 않고 전투 타임라인 또는 명시적 DM Override를 사용한다.

```text
문 열기
→ Undo 가능

오브젝트 이동
→ Undo 가능

공격 결과 취소
→ 턴 타임라인 복구

HP 수동 수정 취소
→ 감사 기록이 있는 반대 Override
```

## 16. 비활성화 이유

명령을 숨기는 것만으로 원인을 알기 어려운 경우 비활성 상태와 이유를 표시한다.

```text
사거리 밖
현재 안전 경계가 아님
다른 DM 명령 처리 중
대상 revision 변경됨
필요 권한 없음
전투 중 사용 불가
게시된 장면에서 편집 불가
```

상태가 바뀌면 전체 Registry를 재검색하지 않고 관련 의존성 이벤트만 다시 평가한다.

## 17. 성능

- 오버레이가 닫혀 있을 때 후보를 매 프레임 계산하지 않는다.
- 열 때 Registry 인덱스에서 문맥 타입에 맞는 후보만 수집한다.
- Predicate는 순수하고 짧은 검사로 제한한다.
- 비싼 공간 질의나 전체 장면 검색은 비동기 Preview 단계에서 수행한다.
- 아이콘과 목록은 공통 컴포넌트와 가상화 목록을 사용한다.

## 18. 테스트

필수 테스트:

- Actor, Door, Trap, Light, Player, WorldPosition 문맥별 후보
- 다중 선택 공통 명령
- 권한 없는 명령 제거
- revision 변경 후 실행 거부
- 위험 명령 확인
- Q/E/1–5 입력 우선순위
- 전투 해결 중 안전 경계 대기
- 명령 저널과 감사 로그 생성
- Registry 모듈 오류 격리
- 재접속 후 최근 사용과 즐겨찾기 복원
