# RVTT Roblox Implementation 현재 작업 순서

- 상태: `IMPLEMENTED_STUDIO_BASELINE_VERIFIED`
- 문서 종류: Production Implementation Work Order
- 최종 갱신일: 2026-08-05
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

Slice 01 3D World Token Layer
→ IMPLEMENTED · CI PASSED

현재 작업
→ Slice 01 3D World Token Studio Acceptance
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

## 2. 현재 작업 순서

| 순서 | 상태 | 작업 | 완료 조건 |
|---:|---|---|---|
| 1 | DONE | 전체 Contract→Script Transfer | 16개 Slice Domain·Manifest·Test Source 존재 |
| 2 | DONE | Authority·Security 보강 | Command Authorization과 서버 계산 경계 |
| 3 | DONE | 정적 Implementation CI | Structure·Policy·Security Validator 성공 |
| 4 | DONE | Luau·Rojo Toolchain 검증 | Build·Type Check·Formatter·Linter 성공 |
| 5 | DONE | Roblox Studio Runtime Baseline | Unit·Integration·Live DataStore·3-client 성공 |
| 6 | DONE | Accent Theme·Avatar·Persistence | Visual·Input·Save·Reload·Character Suppression 확인 |
| 7 | DONE | Slice 01 Authority Acceptance | Join→Select→Ready→Scene→Move→Reconnect 상태 복구 |
| 8 | DONE | Slice 01 3D World Token Implementation | Projection Renderer·Asset Resolver·월드 선택·서버 이동 연결 |
| 9 | IN_PROGRESS | Slice 01 3D World Token Studio Acceptance | 3D 생성·선택·이동·저장·복구 확인 |
| 10 | QUEUED | Slice 01 Production Build Acceptance Audit | 실행 Evidence와 권위·복구 Checklist 판정 |
| 11 | QUEUED | Slice 02 Rules·D20 Acceptance | 서버 계산 판정·결과 Projection 검증 |
| 12 | QUEUED | Slices 03–16 Studio Acceptance | Slice별 사용자·보안·복구 Scenario 통과 |
| 13 | QUEUED | DataStore·Restart Recovery | Restart·Lease·Migration·Conflict 검증 |
| 14 | QUEUED | UI Visual Redesign | 전체 화면을 Token·공통 Component 기준으로 일괄 개편 |
| 15 | QUEUED | UI Accessibility QA | Keyboard·Focus·Contrast·User Test |
| 16 | QUEUED | Performance·Fault·Soak | 측정 Evidence와 Release Gate |

## 3. Slice 01 3D World Token 구조

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
3D Token 클릭
→ Actor ID 선택
→ 소유자·Controller·DM 권한 확인

이동 바닥 클릭
→ 목적지 제안
→ movement.commit
→ 서버 Validation·Commit
→ 신규 Projection
→ 3D Model Pivot 갱신
```

클라이언트는 클릭 직후 Token을 임의 이동하지 않는다. 서버가 승인한 새 Projection 위치만 Renderer가 적용한다.

## 4. 3D Token Asset 계약

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

## 5. 3D Acceptance Place

`slice01-acceptance.project.json`은 실제 Production Server·Client·Networking·Projection·Persistence를 사용하고 테스트 전용 보드와 카메라만 추가한다.

```text
Scene 준비·재개
→ Workspace 3D Token 생성
→ Token 직접 클릭
→ Highlight 선택 표시
→ 바닥 클릭
→ movement.commit
→ Projection Revision 증가 후 3D 이동
→ Persistence Save
→ Stop·Play
→ 같은 Character·Scene·Position·3D Token 복구
```

Acceptance 전용 DM Override와 이동 보드는 이 프로젝트에만 존재한다. `default.project.json`의 권한·월드 구성에는 포함되지 않는다.

## 6. UI 디자인 해석

현재 Production UI와 Acceptance Panel은 기능 검증용 Placeholder다.

- 현재 외형을 최종 디자인으로 확장하지 않는다.
- 화면 로직과 시각 표현을 분리한다.
- Production 색상·간격·Typography는 공통 Token을 사용한다.
- Acceptance 화면은 테스트 조작면으로만 사용한다.
- 전면 수정은 별도 `UI Visual Redesign` Gate에서 일괄 수행한다.
- 기능 테스트는 상태·입력·서버 권위·Persistence 계약을 기준으로 유지한다.

## 7. 현재 상태 해석

Accent Delta:

```text
ACCENT_THEME_PERSISTENCE_VERIFIED
```

Slice 01 Delta:

```text
SLICE_01_3D_WORLD_TOKEN_IMPLEMENTED_STUDIO_PENDING
```

최종 정적 검증 Implementation Head:

```text
f011991828c417cb9d98819e2eb6c77dc9667971
```

검증 결과:

- Structure·Policy Validator: PASS
- StyLua: PASS
- Selene: PASS
- Production·Test·Multi-client·Persistence·Slice 01 Rojo Build: PASS
- Production·Test Luau Type Analysis: PASS

다음을 의미하지 않는다.

- 3D World Token Studio Acceptance 완료
- 실제 최종 OBJ·MeshPart Art Pack 승인 완료
- Slice 02–16 Acceptance 완료
- Cross-server 복구 완료
- UI 최종 디자인 완료
- Production Ready 또는 Release Ready

## 8. 다음 Gate

```text
Slice 01 3D World Token Studio Acceptance
→ Slice 01 Production Build Acceptance Audit
→ Slice 02 Rules·D20 Acceptance
→ Slices 03–16 Studio Acceptance
→ DataStore·Restart Recovery
→ UI Visual Redesign
```
