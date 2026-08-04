# ADR-0070: Session Mode, Context, Overlay와 Transition을 직교 축으로 분리

- 상태: Accepted
- 작성일: 2026-08-04

## Context

RVTT는 탐험, 전투, 휴식, Scene 편집, Pause, Selection, 주사위 연출, 재접속과 Rollback을 모두 지원해야 한다.

이들을 하나의 전역 Mode 열거형에 넣으면 다음 문제가 생긴다.

- `combat_targeting_paused` 같은 조합 상태가 폭증한다.
- DM만 Scene Editor를 사용하는 동안 모든 플레이어 Mode가 잘못 변경된다.
- Character Sheet와 Inventory 같은 화면 상태가 규칙 권위와 섞인다.
- Scene 전환·복구 중 일반 Command 차단 여부가 UI 상태에 의존한다.
- 탐험 중 은신, 여행과 위험 장면마다 별도 Runtime을 만들게 된다.

반대로 탐험과 전투만 구분하면 Downtime, 중도 참여, Authoring과 Transition 예외가 각 시스템에 흩어진다.

## Decision

Session Runtime 상태를 다음 네 직교 축으로 분리한다.

```text
Base Play Mode
+ Context Set
+ Overlay Stack
+ Transitional State
```

### Base Play Mode

동시에 하나만 활성화된다.

```text
exploration
encounter
downtime
```

- `exploration`: 실시간 Scene 탐색과 일반 상호작용
- `encounter`: Turn, Initiative, Action Opportunity와 Reaction이 필요한 진행
- `downtime`: Rest, Level Up, Spell Preparation, Crafting과 장기 시간 진행

Encounter는 전투에만 한정하지 않고 Chase, Hazard, Escape와 Timed Objective를 포함한다.

### Context

현재 Mode 일부 정책만 조정하는 겹칠 수 있는 기여다.

예시:

```text
stealth
travel
hazard
social_adjudication
rest_preparation
chase
```

Context는 직접 권위 상태를 수정하거나 Mode를 조용히 전환하지 않는다.

### Overlay

현재 Base Mode 위에서 제한된 입력·표현 Scope를 소유한다.

예시:

```text
selection
dm_authoring
pause
presentation_focus
rollback_review
journal_editor
character_sheet
inventory
```

Overlay는 별도 Base Mode가 아니다. DM Authoring Overlay는 DM에게만 활성화될 수 있으며 다른 플레이어의 Base Mode를 바꾸지 않는다.

### Transitional State

정상 Gameplay Command를 안전하게 차단해야 하는 진행 상태다.

예시:

```text
scene_transition
joining
reconnecting
snapshot_sync
recovery
rollback_commit
build_migration
```

Transition이 완료되고 Ready 조건이 충족된 뒤에만 Stable Mode 입력을 허용한다.

## Command 정책

Command 허용 여부는 단일 Mode 검사 대신 다음을 결합한다.

```text
Role
+ Control Assignment
+ Base Mode
+ Context
+ Overlay
+ Pause Gate
+ Transition Gate
+ Capability
```

Transitional State hard gate가 가장 높은 우선순위를 가진다.

## Consequences

### Positive

- 탐험·Encounter·Downtime의 규칙 경계가 명확해진다.
- Scene Authoring, Selection과 Presentation을 기존 Mode에 안전하게 중첩할 수 있다.
- 새로운 기능을 위해 전역 Mode 조합을 추가할 필요가 줄어든다.
- 중도 참여·복구·Scene 전환 중 입력 차단이 일관된다.
- Player와 DM이 서로 다른 Overlay를 동시에 사용할 수 있다.
- UI 화면과 권위 Runtime 상태가 분리된다.

### Negative

- Effective Command Policy를 합성하는 Resolver가 필요하다.
- Overlay 입력 우선순위와 충돌 규칙을 명시해야 한다.
- Mode·Context·Overlay·Transition 상태를 Projection에서 구분해야 한다.
- 테스트 Matrix가 단일 Mode 모델보다 넓다.

## Rejected Alternatives

### 모든 상태를 하나의 Mode enum으로 관리

조합 수가 폭증하고 역할별 비대칭 상태를 표현하기 어렵기 때문에 기각한다.

### Exploration과 Combat 두 Mode만 사용

Downtime, Chase, Hazard, Join·Recovery와 Authoring 예외가 하위 시스템에 흩어지므로 기각한다.

### Scene Editor를 별도 전역 Mode로 사용

DM 한 명의 Authoring 상태가 다른 플레이어의 Gameplay를 강제로 변경하므로 기각한다.

### Pause 시 Pending Execution을 모두 취소

Reaction, DM Adjudication과 Resource Reservation을 손실시킬 수 있으므로 기각한다.

## Follow-up

- Exploration Runtime 계약
- Encounter Runtime 계약 최신화
- Downtime Runtime 계약
- Selection & Targeting Runtime 계약
- Camera와 Presentation Overlay 계약
- Command Policy Resolver 구현 명세
