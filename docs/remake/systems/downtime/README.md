# Downtime 시스템

휴식, 레벨업, 주문 준비·주문책 작업, 제작, 훈련과 여행 정산을 하나의 Campaign Time Window에서 조정한다.

## 관련 Main System Guide

- `Character, Inventory와 Downtime Guide`
  - 현재 Main System Guide 작업 순서 7번에서 작성 중이다.
  - Character Source·Build·State, Item·Equipment와 Rest·Level Up·Crafting·Travel Completion을 통합한다.
- [`Combat와 Encounter Guide`](../../guides/combat/README.md)
  - Downtime 중 사건으로 Encounter가 시작될 때 Suspend·Mode Transition·복귀 경계
- [`Rules, Character Action, Spell, Dice와 Effect Guide`](../../guides/rules/README.md)
  - Downtime Activity가 주문·Effect·Resource RuleExecution과 연결되는 경계

## 상위 권위 문서

- [`Session Play Mode, Context, Overlay와 Transition 계약`](../../architecture/session-play-mode-context-overlay-and-transition-contract.md)
  - Downtime은 Exploration·Encounter와 구분되는 Base Play Mode다.
  - Pause·선택창·Character Sheet는 Downtime Mode 자체가 아니라 Overlay다.
  - 활성 적대 Encounter가 있으면 기본적으로 Downtime 시작을 차단한다.
- [`Downtime Activity, Time Coordination과 Atomic Completion Runtime 계약`](../../architecture/downtime-activity-time-coordination-and-atomic-completion-runtime-contract.md)
  - 참가자별 Activity 배정과 동시 활동 Window
  - 선택·승인·장기 Reservation·Progress와 중단
  - Rest·Level Up·Spell Preparation·Spellbook·Crafting·Training·Travel 연결
  - Domain Completion Plan과 Atomic Transaction
  - 재접속·복구·Rollback
- [`Game Time, Calendar, Duration과 Scheduler Runtime 계약`](../../architecture/game-time-calendar-duration-and-scheduler-runtime-contract.md)
  - Campaign Time 권위와 TimeAdvancePlan
  - 병렬 활동, Scheduler와 중간 Checkpoint
  - 현실 시간과 게임 시간의 분리
- [`Character Runtime과 Compiled Character Build 계약`](../../architecture/character-runtime-and-compiled-character-build-contract.md)
  - 레벨업의 Progression Source 변경
  - Candidate Character Build와 State Migration
  - Source·Build Ref·Persistent State의 원자 교체
- [`Inventory, ItemInstance와 World Presence Runtime 계약`](../../architecture/inventory-item-instance-and-world-presence-runtime-contract.md)
  - 제작 재료 Reservation, Output ItemInstance와 Container·Ground Presence
- [`Transaction Coordinator`](../../architecture/command-ordering-logical-time-and-transaction-coordinator-contract.md)
  - 재료 소비·완성품 생성, Build 교체와 Recovery의 원자적 Commit
- [`Runtime Architecture Completion과 Main System Guide 준비도 감사`](../../audits/runtime-architecture-completion-and-main-guide-readiness-audit.md)
  - Downtime·Character·Inventory Integration 완료와 Main Guide 단계 준비 판정

## 세부 시스템 문서

- [`../character/zero-hit-points-death-saves-rest-and-resource-recovery-model.md`](../character/zero-hit-points-death-saves-rest-and-resource-recovery-model.md)
  - RestSession, Activity Ledger, RecoveryPlan과 Resource 회복
- [`../character/spell-acquisition-preparation-and-cast-access-model.md`](../character/spell-acquisition-preparation-and-cast-access-model.md)
  - 준비 주문 선택과 SpellcastingProfile
- [`../character/spellbook-repository-and-copying-model.md`](../character/spellbook-repository-and-copying-model.md)
  - 주문책 Repository와 복사 작업
- [`../inventory/README.md`](../inventory/README.md)
  - 제작 재료 ItemInstance Reservation과 Output 배치
- [`../combat/README.md`](../combat/README.md)
  - Downtime 중 사건으로 Encounter가 시작될 때의 전환과 복귀

## 고정 경계

- 참가자마다 독립 Campaign Clock을 만들지 않는다.
- 서로 독립적인 활동은 같은 시간 Window에서 병렬 진행한다.
- 긴 시간 진행은 가장 가까운 Activity·Scheduler·사건 Checkpoint에서 멈춘다.
- Downtime Runtime은 HP, Resource, Character Source, 주문 준비와 ItemInstance를 직접 수정하지 않는다.
- 휴식 완료는 RecoveryPlan, 레벨업은 Candidate Build·Migration, 제작은 Inventory Completion Provider를 사용한다.
- 장시간 Ordering Lock을 유지하지 않고 타입 있는 Domain Reservation을 사용한다.
- 현실 시간 경과나 오프라인 상태로 Activity를 자동 완료하지 않는다.
- 중간 Encounter가 끝나도 남은 Activity를 자동 재개하지 않고 자격·예약·진행도를 재검증한다.
- 제작 입력 소비와 Output 생성은 하나의 Transaction이어야 한다.
- 레벨업 Compile 또는 Migration이 실패하면 기존 Character Source·Build·State를 유지한다.

## 역할 경계

### 플레이어

- 자신의 Character Activity를 제안한다.
- 레벨업, 주문 준비, Hit Dice, 제작 대상과 비용 선택을 제출한다.
- 자신의 Activity 취소·재개를 요청한다.

### DM

- DowntimeSession Scope와 시간 진행을 확정한다.
- 숨은 사건·비용·자격과 Interruption을 판정한다.
- 미응답 참가자 Fallback, Override와 복구를 수행한다.

### 시스템

- Activity Registry, 참가자 Window와 Checkpoint를 계산한다.
- Reservation·Progress·TimeAdvance와 Completion Plan을 조정한다.
- Snapshot, Projection, Transaction과 Domain Event를 생성한다.

## 관련 ADR

- [`ADR-0031`](../../decisions/ADR-0031-zero-hit-points-death-saves-rests-and-resource-recovery.md)
- [`ADR-0064`](../../decisions/ADR-0064-immutable-compiled-builds-and-versioned-authoritative-state.md)
- [`ADR-0070`](../../decisions/ADR-0070-orthogonal-session-modes-contexts-overlays-and-transitions.md)
- [`ADR-0078`](../../decisions/ADR-0078-authoritative-game-time-boundary-durations-and-scheduled-execution.md)
- [`ADR-0080`](../../decisions/ADR-0080-downtime-as-time-coordinated-activity-sessions-with-domain-owned-completion.md)
- [`ADR-0087`](../../decisions/ADR-0087-atomic-immediate-closure-and-event-driven-deferred-consequences.md)

## Guide 상태

```text
Guide Status: READY_TO_WRITE
```

최신 Completion Audit에서 Downtime Activity·Game Time·Domain Completion과 Character·Inventory 연결이 Main System Guide 작성 가능 상태로 판정됐다.
