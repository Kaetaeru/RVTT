# RVTT Roblox Implementation 현재 작업 순서

- 상태: `IMPLEMENTED_STUDIO_BASELINE_VERIFIED`
- 문서 종류: Production Implementation Work Order
- 최종 갱신일: 2026-08-06
- 실행 테스트 규칙: [`EXECUTION-TEST-RULES.md`](EXECUTION-TEST-RULES.md)
- Script Manifest: [`manifests/all-slices-script-manifest.md`](manifests/all-slices-script-manifest.md)
- 구현 상태: [`IMPLEMENTATION-STATUS.md`](IMPLEMENTATION-STATUS.md)
- Studio 검증 근거: [`Roblox Studio Runtime Baseline Validation Audit`](../../docs/remake/audits/roblox-studio-runtime-baseline-validation-audit.md)
- UI·UX Policy: [`UI·UX Global Policies`](../../docs/remake/ui/policies/README.md)

## 1. 현재 상태

```text
16개 Slice Script Manifest
→ DONE

Shared·Server·Client·UI·Test Source
→ IMPLEMENTED

Structure·Policy·Toolchain CI
→ PASSED

Roblox Studio Runtime Baseline
→ VERIFIED

Accent Theme Visual·Input·Persistence
→ VERIFIED IN STUDIO

Roblox Avatar Auto-Spawn Disable
→ VERIFIED IN STUDIO

Slice 01 Authority·Persistence·Reconnect
→ VERIFIED IN STUDIO

Slice 01 World Interaction Batch
→ VERIFIED IN STUDIO · 16/16 PASS

실행 테스트 방식
→ BATCH ACCEPTANCE RULE ACTIVE

현재 작업
→ Slice 01 Production Build Acceptance Audit
```

기존 Studio Evidence:

```text
Unit·Integration
→ passed=173 failed=0

Live DataStore
→ passed=10 failed=0

3-client MultiClient
→ passed=56 failed=0 clients=3 staleRetries=3

Persistence·Accent Restore
→ PASS

Character·Scene·Position Recovery
→ PASS
```

2026-08-06 Slice 01 World Interaction Evidence:

```text
[RVTT Batch Summary] batch=slice01-world-interaction result=PASS passed=16 failed=0 pending=0 revision=73

Token Pick
→ PASS · method=screen · world ray hit=Workspace.RVTT_AcceptanceBoard.MoveSurface

State Restore
→ PASS · revision=72 · position=(-22.94,0.00,-57.40)

Movement Command
→ PASS · baseRevision=72 · acceptedRevision=73

Projection Move
→ PASS · revision=73 · position=(-15.34,0.00,-56.93)
```

## 2. 실행 테스트 원칙

Studio 수동 검사는 개별 수정마다 요청하지 않는다.

```text
관련 기능 여러 개 구현
→ 자동 회귀 테스트와 정적 CI
→ 구조화된 진단 로그와 Final Summary
→ 단일 Acceptance Place Build
→ 사용자 게시 1회
→ 전체 Batch 검증 1회
```

단일 Raycast 수정, 로그 추가, 문구 변경, 타입 오류 수정은 별도의 수동 게시 Gate가 아니다. 자동 Gate가 실패한 상태에서도 사용자 검사를 요청하지 않는다.

사용자에게 전달하는 Build 명령은 저장소에서 바로 실행 가능한 전체 Windows PowerShell 블록으로 제공한다.

## 3. 현재 작업 순서

| 순서 | 상태 | 작업 | 완료 조건 |
|---:|---|---|---|
| 1 | DONE | 전체 Contract→Script Transfer | 16개 Slice Domain·Manifest·Test Source 존재 |
| 2 | DONE | Authority·Security 보강 | Command Authorization과 서버 계산 경계 |
| 3 | DONE | 정적 Implementation CI | Structure·Policy·Security Validator 성공 |
| 4 | DONE | Luau·Rojo Toolchain 검증 | Build·Type Check·Formatter·Linter 성공 |
| 5 | DONE | Roblox Studio Runtime Baseline | Unit·Integration·Live DataStore·3-client 성공 |
| 6 | DONE | Accent Theme·Avatar·Persistence | Visual·Input·Save·Reload·Character Suppression 확인 |
| 7 | DONE | Slice 01 Authority Acceptance | Join→Select→Ready→Scene→Move→Reconnect 상태 복구 |
| 8 | DONE | Slice 01 3D World Token Baseline | Projection Renderer·Asset Resolver·월드 입력 연결 |
| 9 | DONE | Slice 01 World Interaction Batch | Picking·Selection·Destination·Camera·Move·Diagnostics·Recovery와 Final Summary 구현·CI PASS |
| 10 | DONE | Slice 01 Batch Studio Acceptance | Final Summary `passed=16 failed=0 pending=0` 및 revision 72→73 확인 |
| 11 | IN_PROGRESS | Slice 01 Production Build Acceptance Audit | Production Project의 권위·보안·복구·Acceptance 전용 코드 격리 판정 |
| 12 | QUEUED | Slice 02 Rules·D20 Batch | 판정·Attack·Damage·Projection·복구를 한 묶음으로 구현·검증 |
| 13 | QUEUED | Slices 03–16 Batch Acceptance | 관련 Slice를 Milestone 단위로 묶어 검증 |
| 14 | QUEUED | DataStore·Restart Recovery Batch | Restart·Lease·Migration·Conflict 검증 |
| 15 | QUEUED | UI Visual Redesign Batch | 전체 화면을 Token·공통 Component 기준으로 일괄 개편 |
| 16 | QUEUED | UI Accessibility QA | Keyboard·Focus·Contrast·User Test |
| 17 | QUEUED | Performance·Fault·Soak | 측정 Evidence와 Release Gate |

## 4. Slice 01 World Interaction Batch 판정

최종 상태:

```text
SLICE_01_WORLD_INTERACTION_BATCH_STUDIO_VERIFIED
```

검증된 범위:

```text
3D Token Projection
→ PASS

Raycast 실패 시 Screen-space Picking Fallback
→ PASS

선택 Highlight와 선택 상태
→ PASS

Board Destination Marker
→ PASS

movement.commit 서버 권위 이동
→ PASS

Command Receipt·Revision·Projection
→ PASS

3D Camera Pan·Zoom·Frame
→ PASS

Persistence Save·Reconnect Restore
→ PASS

Roblox Avatar Suppression
→ PASS

Final Batch Summary
→ passed=16 failed=0 pending=0
```

기존 결함 `WT-PICK-01` 판정:

```text
RESOLVED
```

World Raycast는 `Workspace.RVTT_AcceptanceBoard.MoveSurface`를 반환했지만 Screen-space Token Bounds가 동일 입력에서 Actor를 선택했다. 이후 Highlight, Destination Marker, `movement.commit`, 서버 승인 revision 73, Projection 위치 갱신까지 연결됐다.

## 5. Slice 01 3D World Token 구조

Production Client Boot는 Scene Projection을 `WorldTokenRuntime`에 전달한다.

```text
Scene Projection
→ WorldTokenContract
→ TokenAssetResolver
→ WorldTokenRenderer
→ Workspace 3D Model
```

입력과 이동 경계:

```text
3D Token 선택
→ Actor ID 해석
→ 소유자·Controller·DM 권한 확인

이동 바닥 선택
→ 목적지 제안
→ movement.commit
→ 서버 Validation·Commit
→ 신규 Projection
→ 3D Model Pivot 갱신
```

클라이언트는 입력 직후 Token을 임의 이동하지 않는다. 서버가 승인한 새 Projection 위치만 Renderer가 적용한다.

## 6. 3D Token Asset 계약

`ReplicatedStorage.RVTT.TokenAssets`에서 다음 순서로 `Model` 또는 `MeshPart`를 찾는다.

```text
sourceCharacterId
→ sourceNpcId
→ actorId
→ Default
```

로드된 Token은 다음 계약을 따른다.

- Roblox `Player.Character`·`Humanoid`를 사용하지 않는다.
- 실행 가능한 Script descendant를 제거한다.
- 모든 시각 Part를 Anchored·비충돌 상태로 사용한다.
- Actor ID·소유자·Controller 메타데이터를 Attribute로 유지한다.
- Model 외형과 Actor·Scene 상태를 분리한다.
- 등록된 에셋이 없을 때만 리그 없는 3D 임시 미니어처를 생성한다.

임시 미니어처와 Acceptance Panel은 최종 시각 디자인 후보가 아니다.

## 7. Production Build Acceptance Audit 범위

다음 Gate는 추가 기능 구현이나 개별 Studio 재검사가 아니라 Production Project 판정이다.

- `default.project.json`에 Acceptance 전용 DM Override·Board·Panel이 포함되지 않는지 확인
- Production Client가 서버 Projection으로만 Token Transform을 갱신하는지 확인
- `movement.commit` 권한·Revision·Validation이 서버 경계를 유지하는지 확인
- 공개되지 않은 Actor가 Viewer Projection과 Workspace에 생성되지 않는지 확인
- Roblox Avatar Suppression이 Production Boot에서도 유지되는지 확인
- Persistence Restore가 Acceptance Harness 없이 Production Runtime 계약으로 연결되는지 확인
- Placeholder Visual을 Production Ready Art로 오인하지 않도록 Gate를 분리하는지 확인

Audit 결과가 PASS일 때 Slice 01 Production Build Acceptance를 닫고 Slice 02 Rules·D20 Batch로 이동한다.

## 8. UI 디자인 해석

현재 Production UI와 Acceptance Panel은 기능 검증용 Placeholder다.

- 현재 외형을 최종 디자인으로 확장하지 않는다.
- 화면 로직과 시각 표현을 분리한다.
- Production 색상·간격·Typography는 공통 Token을 사용한다.
- Acceptance 화면은 테스트 조작면으로만 사용한다.
- 전면 수정은 별도 `UI Visual Redesign` Batch에서 일괄 수행한다.
- 기능 테스트는 상태·입력·서버 권위·Persistence 계약을 기준으로 유지한다.

## 9. 현재 상태 해석

Accent Delta:

```text
ACCENT_THEME_PERSISTENCE_VERIFIED
```

Slice 01 Delta:

```text
SLICE_01_WORLD_INTERACTION_BATCH_STUDIO_VERIFIED
```

다음을 의미하지 않는다.

- 실제 최종 OBJ·MeshPart Art Pack 승인 완료
- Slice 02–16 Acceptance 완료
- Cross-server 복구 완료
- UI 최종 디자인 완료
- Production Ready 또는 Release Ready

## 10. 다음 Gate

```text
Slice 01 World Interaction Batch Implementation·자동 Gate
→ PASS

단일 Slice 01 Batch Studio Acceptance
→ PASS · 16/16

Slice 01 Production Build Acceptance Audit
→ IN PROGRESS

Slice 02 Rules·D20 Batch
→ QUEUED
```
