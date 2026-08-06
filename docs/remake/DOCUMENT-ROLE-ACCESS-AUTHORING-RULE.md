# 역할별 기능 접근 구분 작성 규칙

- 상태: 확정
- 문서 종류: Documentation Rule
- 즉시 구현 명세 가능성: `READY`
- 작성일: 2026-08-04
- 관련 문서:
  - [`DOCUMENT-GUIDE.md`](DOCUMENT-GUIDE.md)
  - [`Runtime Architecture Principles`](architecture/runtime-architecture-principles.md)
  - [`Networking Command, Event와 Client Synchronization 계약`](architecture/networking-command-event-and-client-synchronization-contract.md)

## 1. 목적

RVTT 문서에서 행동, 버튼, 메뉴, Command와 데이터 공개 범위를 나열할 때 DM과 플레이어의 권한을 모호하게 섞지 않는다.

특히 다음과 같은 표현은 금지한다.

```text
사용자는 다음 행동을 할 수 있다.
- 줍기
- 저널에 링크
- 강제 이동
```

위 목록은 플레이어 정상 행동과 DM 전용 관리 기능이 섞여 있어 UI와 권한 구현을 잘못 유도한다.

## 2. 표준 역할 분류

모든 기능은 문맥에 따라 다음 중 하나로 표시한다.

```text
PLAYER_ONLY
→ 플레이어 세션 UI와 정상 규칙 행동에서만 제공

DM_ONLY
→ DM Workspace, Scene Editor, 저널 저작 또는 관리 Override에서만 제공

SHARED
→ DM과 플레이어 모두 같은 의미와 검증 경로로 사용

SYSTEM_ONLY
→ 서버, Compiler, Recovery 또는 자동 규칙 처리만 사용
```

Observer, Assistant DM 등 추가 역할이 필요한 문서는 별도 행을 추가하되 위 네 분류를 생략하지 않는다.

## 3. DM 대행과 공통 기능을 구분한다

DM이 플레이어 행동을 대신 실행할 수 있다는 이유로 해당 기능을 `SHARED`로 표기하지 않는다.

예시:

```text
PLAYER_ONLY 정상 행동
→ 제어 중인 캐릭터로 바닥 아이템 줍기

DM_ONLY 관리 행동
→ 거리·행동 비용을 우회해 아이템 강제 이전
```

두 행동은 결과가 비슷해도 Command, UI Surface, 권한과 Audit 의미가 다르다.

## 4. 필수 작성 형식

행동이나 UI 기능이 세 개 이상 나오는 문서는 다음 중 하나를 반드시 사용한다.

### 역할별 구역

```markdown
### 플레이어 기능
- ...

### DM 전용 기능
- ...

### 공통 기능
- ...

### 시스템 전용 처리
- ...
```

### 역할 접근표

```markdown
| 기능 | Player | DM | System | 비고 |
|---|---:|---:|---:|---|
| Inspect | O | O | - | 공개 Projection만 표시 |
| Link to Journal | - | O | - | DM 저널 저작 기능 |
```

단순히 `권한에 따라 표시한다`고만 적는 것으로 대체할 수 없다.

## 5. UI Surface 분리

역할이 다른 기능은 같은 Context Menu에 무조건 섞지 않는다.

```text
Player Context Menu
→ 플레이어가 현재 사용할 수 있는 규칙 행동

DM Context Menu 또는 DM Workspace
→ 저널 링크, 강제 이동, 숨김 정보, 생성·삭제와 Override
```

DM이 Player View로 테스트할 때는 Player Context Menu를 그대로 볼 수 있지만, DM 전용 기능은 별도 DM Surface에 유지한다.

## 6. 서버 검증

클라이언트 UI에서 버튼을 숨기는 것만으로 권한을 보장하지 않는다.

모든 Command는 서버에서 다음을 검증한다.

- 요청자의 세션 역할
- 현재 Control Assignment
- 대상 데이터의 공개 권한
- Command별 Role Requirement
- DM Override 여부와 Audit 요구

`DM_ONLY` Command를 일반 Player Remote Payload로 보내도 서버가 거부해야 한다.

## 7. 문서 작성 검사

새 문서와 기존 문서를 수정할 때 다음을 확인한다.

```text
□ 플레이어 정상 행동이 명시되어 있는가
□ DM 전용 저작·관리·Override 기능이 분리되어 있는가
□ 공통 기능이 실제로 동일한 의미인지 확인했는가
□ System 자동 처리와 사용자 행동을 섞지 않았는가
□ UI 숨김이 아니라 서버 권한 검증을 명시했는가
```

역할 구분이 없거나 모호하면 해당 문서는 구현 명세 준비도를 `READY`로 판정할 수 없다.

## 8. 대표 예시

### 바닥 아이템

| 기능 | Player | DM | 분류 |
|---|---:|---:|---|
| 공개 정보 살펴보기 | O | O | SHARED |
| 제어 캐릭터로 줍기 | O | O | PLAYER 정상 행동을 DM이 테스트 가능 |
| 위치 핑 | O | O | SHARED |
| 저널에 오브젝트 링크 작성 | - | O | DM_ONLY |
| 강제 이동·회수·삭제 | - | O | DM_ONLY |
| Stream Out Presence 복구 | - | - | SYSTEM_ONLY |

### 저널

- 문서 작성, Actor·Object·Dungeon Room 링크 생성과 DM 전용 정보 설정: `DM_ONLY`
- 플레이어에게 공개된 문서 열람과 허용된 링크 따라가기: `PLAYER_ONLY` 또는 `SHARED`
- 권한별 검색 인덱스 생성: `SYSTEM_ONLY`
