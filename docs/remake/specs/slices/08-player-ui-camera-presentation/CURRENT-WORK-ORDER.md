# Slice 08 Work Order — Player UI·Camera·Presentation

- 상태: CHECKPOINT_COMPLETE
- 문서 종류: Slice Implementation Spec Work Order
- 즉시 구현 명세 가능성: BLOCKED
- 작성일: 2026-08-05
- 전체 Roadmap: [`SLICE-ROADMAP.md`](../../SLICE-ROADMAP.md)
- 선행 Slice: [`Slice 01–07 Contracts`](../01-first-session-walking-skeleton/implementation-contract.md)
- 통합 계약: [`implementation-contract.md`](implementation-contract.md)
- 검수 감사: [`Slice 08 Spec Checkpoint Audit`](../../../audits/slices/08-player-ui-camera-presentation-spec-checkpoint-audit.md)

## 사용자 완료 결과

```text
Projection Snapshot·Delta
→ Atomic Client Replica
→ ViewModel·HUD·Panel
→ Semantic Input·Focus
→ Command Pending·Reconciliation
→ CameraRequest
→ PresentationIntent·Playback
→ Reconnect·Rollback UI Recovery
```

## 명세 작업 순서

| 순서 | 상태 | 작업 | 완료 기준 |
|---:|---|---|---|
| 1 | DONE | Projection Replica·Integrity | Snapshot·Batch·Epoch·Sequence의 원자 적용 정의 |
| 2 | DONE | ViewModel·Panel·Component Registry | HUD·Sheet·Inventory·Prompt의 공통 책임 정의 |
| 3 | DONE | Input Context·Focus·Q/E·1–5 | 물리 키와 Semantic Intent·단일 소비 정의 |
| 4 | DONE | Pending Command·Reconciliation | Receipt·Result·Projection Expectation과 Ghost 정리 정의 |
| 5 | DONE | Camera Policy·Focus·Follow·Bookmark | CameraRequest·Priority·Restoration·ViewY 정의 |
| 6 | DONE | Presentation Recipe·Module·Queue | Intent·Audience·Marker·Fallback·Version 고정 정의 |
| 7 | DONE | Accessibility·Quality·Failure Isolation | Reduced Motion·Flash·Shake·Low-end Degradation 정의 |
| 8 | DONE | Reconnect·Role Change·Rollback | Epoch-safe Replica·Panel·Camera·Playback 복구 정의 |
| 9 | DONE | Diagnostics·Virtual Client·Roblox Test | UI 오류 격리·ACK 유실·Disclosure Scenario 정의 |
| 10 | BLOCKED | Production Source Mapping | 실제 Client UI·Camera·VFX·Input·Asset 구조 조사 필요 |

## 구현 시 추출할 세부 명세

```text
client/projection-replica-viewmodel
ui/panel-component-registry
ui/input-context-focus
ui/command-reconciliation
camera/policy-focus-follow-bookmark
presentation/recipe-module-queue-marker
ui/accessibility-quality
client/epoch-safe-recovery
testing/virtual-client-presentation
```

## 차단 사항

- 기존 ScreenGui·Controller·Input Script 구조
- Camera Controller·Bookmark·ViewY 구현
- VFX·Token Motion·Dice Presentation Asset Registry
- Combat HUD·Character Sheet·Inventory 실제 Component
- Client Virtual Test·ACK·Low-end Profile Host