# ADR-0047: DM Quick Action은 선택 문맥에서 안전한 명령을 즉시 제공한다

- 상태: 확정
- 결정일: 2026-08-03
- 관련 문서:
  - [`ADR-0010`](../ui/common-input/common-input-grammar.md)
  - [`ADR-0034`](ADR-0034-encounter-initiative-turn-order-and-control-authority.md)
  - [`ADR-0039`](ADR-0039-baldurs-gate-style-combat-hud-and-contextual-action-ui.md)
  - [`ADR-0042`](ADR-0042-authoritative-checkpoints-command-journal-and-session-recovery.md)
  - [`ADR-0045`](ADR-0045-dm-workspace-and-scene-lighting-authoring.md)
  - [`41. DM Quick Action과 문맥 명령 실행 모델`](../ui/dm-workspace/dm-quick-action-and-context-command.md)

## 배경

DM은 세션 중 Actor, 문, 조명, Fog, 저널, 플레이어 제어권과 전투 상태를 반복해서 수정한다. 모든 작업을 개별 패널에서 찾아 실행하면 세션 진행 속도가 느려진다.

## 결정

RVTT는 DM 전용 `QuickActionOverlay`를 제공한다. 현재 선택 대상, 커서 위치, 세션 상태와 DM 권한을 입력으로 받아 실행 가능한 명령만 표시한다.

```text
SelectionContext
+ HoverContext
+ SessionContext
+ PermissionContext
+ RegisteredQuickActions
→ QuickActionResolver
→ QuickActionOverlay
```

Quick Action은 상태를 직접 수정하지 않는다. 선택된 항목은 기존 서버 명령, ActionIntent, SceneCommand, OverrideCommand 또는 ControlAssignment 요청으로 변환되어 동일한 권한·revision·멱등성 검증을 통과한다.

## 기본 문맥

```text
Actor
SceneObject
Door
Trap
Light
FogRegion
JournalLink
Player
Encounter
WorldPosition
MultiSelection
NoSelection
```

## 실행 안전성

각 명령은 다음 메타데이터를 가진다.

```text
QuickActionDefinition
├─ actionId
├─ supportedContexts
├─ predicate
├─ requiredPermission
├─ executionAdapter
├─ confirmationPolicy
├─ dangerLevel
├─ undoPolicy
├─ auditPolicy
└─ presentation
```

삭제, 전투 종료, HP 0 설정, 대규모 Fog 변경, 타임라인 복구처럼 위험한 명령은 즉시 실행하지 않고 명시적 확인과 변경 요약을 요구한다.

## 결과

- DM은 선택 후 한 번의 오버레이로 자주 쓰는 작업을 실행할 수 있다.
- 기능별 별도 단축키와 거대 분기문을 만들지 않는다.
- 새 시스템은 Registry에 Quick Action 정의만 등록하면 자동으로 통합된다.
- 모든 변경은 기존 저장·감사·되돌리기 구조를 유지한다.
