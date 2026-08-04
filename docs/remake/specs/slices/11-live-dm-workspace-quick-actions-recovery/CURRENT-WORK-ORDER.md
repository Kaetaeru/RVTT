# Slice 11 Work Order — Live DM Workspace·Quick Actions·Recovery

- 상태: CHECKPOINT_COMPLETE
- 문서 종류: Slice Implementation Spec Work Order
- 즉시 구현 명세 가능성: BLOCKED
- 작성일: 2026-08-05
- 전체 Roadmap: [`SLICE-ROADMAP.md`](../../SLICE-ROADMAP.md)
- 선행 Slice: [`Session`](../01-first-session-walking-skeleton/implementation-contract.md), [`Scene Authoring`](../10-scene-authoring-compile-publish/implementation-contract.md), [`UI`](../08-player-ui-camera-presentation/implementation-contract.md)
- 통합 계약: [`implementation-contract.md`](implementation-contract.md)
- 검수 감사: [`Slice 11 Spec Checkpoint Audit`](../../../audits/slices/11-live-dm-workspace-quick-actions-recovery-spec-checkpoint-audit.md)

## 사용자 완료 결과

```text
DM Workspace에서 Session·Player·Scene 상태 확인
→ Context Quick Action
→ Control·Fog·Actor·Object·Lighting Command
→ Scene Transition·Runtime Quick Edit
→ 필요 시 Source Promotion·Live Patch
→ Save·Checkpoint·Recovery Review·Rollback
→ Session Resume
```

## 명세 작업 순서

| 순서 | 상태 | 작업 | 완료 기준 |
|---:|---|---|---|
| 1 | DONE | DM Workspace Projection | Player View Preview·Dock Panel·상태 Summary 정의 |
| 2 | DONE | Control·Observer·Takeover | Owner·Controller·Role·Disclosure 분리 |
| 3 | DONE | Context Quick Action | Player Route·DM Override·Mandatory Audit 분리 |
| 4 | DONE | Runtime Fog·Actor·Object·Lighting Command | 직접 Workspace Mutation 금지와 Transaction 경계 정의 |
| 5 | DONE | Scene Transition·Pause·Resume | Mode·Overlay·Command Gate 정의 |
| 6 | DONE | Runtime Quick Edit·Source Promotion | Dynamic State와 Source 영구화 분리 |
| 7 | DONE | Live Patch·Build Rebase | Checkpoint·Client Ready·Failure Fallback 정의 |
| 8 | DONE | Save·Recovery Review·Rollback·Shutdown | Snapshot·Branch·Operator Flow 정의 |
| 9 | DONE | Diagnostics·Security·Test | Override Audit·Player View·Patch·Recovery Scenario 정의 |
| 10 | BLOCKED | Production Source Mapping | 실제 DM UI·Runtime Command·Recovery·Patch 구조 조사 필요 |

## 구현 시 추출할 세부 명세

```text
dm-workspace/projection-player-preview
dm-workspace/control-observer-takeover
dm-workspace/context-quick-action
dm-workspace/runtime-scene-commands
session/pause-transition-resume
scene-runtime/quick-edit-source-promotion
scene-runtime/live-patch-rebase
operations/save-recovery-rollback-shutdown
```

## 차단 사항

- 기존 DM Panel·Quick Action·Permission 구조
- Runtime Fog·Actor·Object·Lighting Command
- Scene Transition·Pause·Control Assignment 구현
- Snapshot·Recovery Review·Rollback UI
- Live Patch·Build Rebase·Client Ready Legacy 흐름