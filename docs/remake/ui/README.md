# UI 문서

화면 배치, 입력 문맥, 패널 상태와 사용자 피드백을 정의한다.

## 최상위 권위 계약

- [`UI Projection, ViewModel, Input Context와 Recovery Runtime 계약`](../architecture/ui-projection-view-model-input-context-and-recovery-runtime-contract.md)
  - Permission-aware Projection의 원자적 Client Replica 적용
  - Projection→ViewModel→Component→Semantic Input→UI Intent 흐름
  - Panel·Modal·Tooltip·Prompt와 Focus·Q/E Input Context
  - Command Result와 Projection Reconciliation
  - Reconnect·Resync·Rollback·Role Change 후 UI 복구
  - Local Layout·Accessibility, Ephemeral State와 Authority-bound UI 분리
- [`Networking Command, Event와 Client Synchronization 계약`](../architecture/networking-command-event-and-client-synchronization-contract.md)
  - Projection Snapshot·Event Batch, Readiness와 Command Result
- [`Session Play Mode, Context, Overlay와 Transition 계약`](../architecture/session-play-mode-context-overlay-and-transition-contract.md)
  - UI 화면과 Exploration·Encounter·Downtime Mode의 분리
- [`Selection Runtime 계약`](../architecture/selection-targeting-preview-and-frozen-binding-runtime-contract.md)
  - Selection Session, Frozen Binding과 Q/E 의미 입력
- [`Presentation Runtime 계약`](../architecture/presentation-recipe-playback-priority-and-extension-runtime-contract.md)
  - UI Pulse, Dice Layer, Floating Text와 화면 연출

## 영역

- `common-input/`: RVTT 공통 의미 입력, Q/E, 1–5와 Input Context 표시
- `scene-editor/`: Scene 저작 화면과 조작
- `combat-hud/`: 전투 HUD, 행동·대상 지정과 Prompt UI
- `character-sheet/`: 플레이어 캐릭터 시트
- `dm-workspace/`: DM 작업공간, Quick Action과 도킹 Panel
- `shared/`: 여러 UI가 공유하는 Layout과 Component

## 추천 읽기 순서

1. `../architecture/ui-projection-view-model-input-context-and-recovery-runtime-contract.md`
2. `../architecture/networking-command-event-and-client-synchronization-contract.md`
3. `../architecture/session-play-mode-context-overlay-and-transition-contract.md`
4. `common-input/common-input-grammar.md`
5. 대상 화면의 UI 문서
6. 해당 Gameplay Domain의 Architecture와 System 문서

## 고정 경계

- UI는 Raw Domain State가 아니라 사용자별 Projection을 읽는다.
- 같은 Projection Event Batch를 부분 적용하지 않는다.
- Component는 Remote와 Domain Store를 직접 호출하지 않고 UI Intent를 제출한다.
- Command Result만으로 HP, Item, Turn과 Resource를 직접 변경하지 않는다.
- Character Sheet·Inventory·Journal·Settings Panel은 Gameplay Mode가 아니다.
- Authority Prompt는 로컬 Close로 완료하지 않고 응답 Command와 Projection으로 종료한다.
- Q/E와 물리 키는 공통 Input Context Stack에서 가장 위의 Context 하나만 소비한다.
- Rollback과 재접속 후 이전 AuthorityEpoch의 Prompt·Selection·Command·Focus Token을 재사용하지 않는다.
- DM 전용 정보를 Player Client에 보낸 뒤 화면에서 숨기지 않는다.
- Panel Layout, UI Scale과 접근성 설정은 Gameplay Authority와 분리한다.

## Guide 상태

```text
Guide Status: NOT_READY
```

Diagnostics, Simulation, Journal 공유 계약과 Cross-System Completion Audit가 끝난 뒤 UI Main System Guide를 작성한다.
