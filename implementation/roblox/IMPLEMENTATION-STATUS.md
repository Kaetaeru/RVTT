# RVTT Production Implementation Status

- 상태: `IMPLEMENTED_STUDIO_BASELINE_VERIFIED`
- 작성일: 2026-08-05
- 최종 갱신일: 2026-08-06
- 범위: 16개 Slice 계약의 Greenfield Runtime·Domain·Client·UI·Test baseline
- 실행 테스트 규칙: [`EXECUTION-TEST-RULES.md`](EXECUTION-TEST-RULES.md)
- Studio 검증 근거: [`Roblox Studio Runtime Baseline Validation Audit`](../../docs/remake/audits/roblox-studio-runtime-baseline-validation-audit.md)

## 구현된 공통 계약

- Versioned Command Envelope와 재귀 Payload 제한
- 명시적 Command Authorization 필수 Registry
- 서버 권위 Transaction·Idempotency·Outbox·Projection
- Viewer별 Domain Projection과 DM 정보 Negative Disclosure
- Character·Actor·Item 소유권 및 Runtime Control 검증
- 서버 계산 D20·Attack·Damage·HP 변경
- AuthorityEpoch·Revision·Projection Gap·Full Resync
- Migration·DataStore Adapter·Debounced Persistence Coordinator
- Semantic Input·Client Runtime·Token 기반 UI Shell
- Roblox 기본 아바타와 RVTT Token·Character 모델 분리
- 16개 Slice Domain Command baseline
- Unit·Integration·Security·Disclosure Test Source

## 검증된 Studio Baseline

```text
Unit·Integration
→ passed=173 failed=0

Live DataStore
→ passed=10 failed=0

3-client MultiClient
→ passed=56 failed=0 clients=3 staleRetries=3

Roblox Player.Character 비생성
→ PASS

Accent Visual·Input·Persistence
→ PASS

Canonical Remote Bootstrap
→ PASS

Character·Scene·Position Reconnect Recovery
→ PASS
```

Accent 상태:

```text
ACCENT_THEME_PERSISTENCE_VERIFIED
```

## 실행 테스트 방식

상태:

```text
BATCH_ACCEPTANCE_RULE_ACTIVE
```

개별 수정마다 Roblox Studio Place를 게시하고 수동 검사하는 흐름은 사용하지 않는다.

```text
관련 기능 묶음 구현
→ 자동 회귀 테스트
→ Structure·Format·Lint·Build·Type CI
→ 구조화된 진단 로그와 Final Summary
→ 단일 Acceptance Place
→ 사용자 게시 1회
→ Batch 전체 수동 검증 1회
```

사용자에게 전달하는 실행 방법은 저장소에서 직접 실행 가능한 전체 Windows PowerShell Build 블록으로 제공한다.

## Slice 01 World Interaction Batch

현재 Delta:

```text
SLICE_01_WORLD_INTERACTION_BATCH_STUDIO_VERIFIED
```

2026-08-06 Studio Evidence:

```text
[RVTT Batch Summary] batch=slice01-world-interaction result=PASS passed=16 failed=0 pending=0 revision=73
```

검증된 Check:

```text
boot                  PASS
acceptance dm-role    PASS
active character      PASS
active scene·actor    PASS
3D token projection   PASS
state restore         PASS · revision=72 position=(-22.94,0.00,-57.40)
avatar suppression    PASS · Player.Character=nil
camera frame          PASS
camera pan            PASS
camera zoom           PASS
token pick            PASS · method=screen
selection highlight   PASS
destination marker    PASS · (-15.34,0.00,-56.93)
movement.commit       PASS · baseRevision=72
server acceptance     PASS · revision=73 base=72
projection move       PASS · revision=73 position=(-15.34,0.00,-56.93)
```

### WT-PICK-01 판정

```text
RESOLVED
```

World Raycast는 `Workspace.RVTT_AcceptanceBoard.MoveSurface`를 반환했지만 Screen-space projected bounds fallback이 보이는 Token을 선택했다. 같은 흐름에서 Selection Highlight, Destination Marker, 서버 Command 승인, revision 증가, Projection 기반 위치 갱신이 모두 확인됐다.

### 서버 권위 이동 판정

```text
선택 입력
→ Actor ID 해석
→ movement.commit baseRevision=72
→ Server Command Acceptance revision=73
→ Projection Position Update revision=73
```

클라이언트 입력 직후 임의 Transform 변경이 아니라 서버 Projection 결과로 최종 위치 `(-15.34,0.00,-56.93)`가 적용됐다.

## Slice 01 3D World Token 구현 상태

```text
Authority·Scene·Movement Contract
→ IMPLEMENTED · VERIFIED

Projection-driven 3D Renderer
→ IMPLEMENTED · VERIFIED

Model·MeshPart Asset Resolver
→ IMPLEMENTED

World Raycast Picking
→ IMPLEMENTED

Screen-space Picking Fallback
→ IMPLEMENTED · VERIFIED

Selection Highlight·Destination Marker
→ IMPLEMENTED · VERIFIED

Camera Frame·Pan·Zoom
→ IMPLEMENTED · VERIFIED

Persistence·Reconnect Restore
→ IMPLEMENTED · VERIFIED

Roblox Avatar Suppression
→ IMPLEMENTED · VERIFIED
```

### Projection Renderer

`WorldTokenRuntime`은 Client Runtime의 `ProjectionReplica.Changed`를 구독한다.

- 활성 Scene의 공개 Actor만 Workspace에 렌더링
- Actor ID·incarnation·source identity로 시각 Model 수명 관리
- 서버 Projection의 Position으로만 `Model:PivotTo`
- Projection에서 사라진 Actor의 Model 제거
- Viewer에게 공개되지 않은 Actor는 생성하지 않음
- 재접속 후 Projection을 기준으로 Token 재생성

### Asset Resolver

`ReplicatedStorage.RVTT.TokenAssets`에서 다음 이름을 순서대로 탐색한다.

1. `sourceCharacterId`
2. `sourceNpcId`
3. `actorId`
4. `Default`

지원 형식:

- `Model`
- `MeshPart`를 포함한 `BasePart`

안전 계약:

- Script·LocalScript·ModuleScript descendant 제거
- Anchored 사용
- 충돌·Touch 비활성화
- `Humanoid`·Roblox Character Model 비사용
- Model visual을 Actor Authority 상태와 분리
- 등록된 에셋이 없을 때만 primitive 3D miniature fallback 생성

## Acceptance Harness와 Diagnostics

`slice01-acceptance.project.json`은 실제 Production Server·Client·Networking·Projection·Persistence 경로를 사용한다.

Batch Harness는 다음을 제공한다.

- 저장 상태 자동 재개
- 준비 단계 자동화
- 전체 Batch 상태 표시
- Input·Command·Projection·Persistence 구조화 로그
- Command ID·Actor ID·Revision·Result 표시
- 최종 Batch Summary

정상일 때 사용자는 Final Summary만 확인하고, 실패할 때만 Summary와 최초 관련 오류를 공유한다.

## Roblox 기본 캐릭터 비활성화

제품 내 플레이어 표현은 Roblox 아바타가 아니라 RVTT의 리그 없는 OBJ·MeshPart Token이다.

- `Players.CharacterAutoLoads=false`
- 이미 생성된 `Player.Character` 제거
- UI와 World Token Runtime은 Character 생성과 독립 부팅
- `Player.Character == nil`
- Humanoid·HumanoidRootPart 비생성
- RVTT Character·Actor·Token Domain에는 영향 없음

## UI 시각 디자인 상태

현재 Production UI, Acceptance Panel, primitive fallback miniature는 기능 검증용 Placeholder다. 최종 시각 디자인으로 간주하지 않는다.

- 화면 로직과 시각 표현 분리
- 공통 색상·간격·Typography Token 유지
- 기능 테스트를 상태·입력·서버 권위·Persistence 기준으로 유지
- Acceptance 화면을 Production UI 후보로 취급하지 않음
- 전면 수정은 별도 `UI Visual Redesign Batch`에서 일괄 수행

## 현재 Gate

```text
Slice 01 World Interaction Batch Implementation·자동 Gate
→ PASS

Slice 01 World Interaction Studio Acceptance
→ PASS · 16/16 · revision=73

Slice 01 Production Build Acceptance Audit
→ IN PROGRESS

Slice 02 Rules·D20 Batch
→ QUEUED
```

Production Build Acceptance Audit는 다음을 판정한다.

- Acceptance 전용 DM Override·Board·Panel이 `default.project.json`에 포함되지 않음
- Production Token 이동이 서버 Projection 경계를 유지함
- Actor visibility와 Negative Disclosure가 Workspace 생성에도 적용됨
- Production Boot에서 Avatar Suppression 유지
- Persistence Restore가 Acceptance Harness에 종속되지 않음
- Placeholder Asset과 최종 Art 승인 Gate가 분리됨

## 아직 미검증

- 최종 OBJ·MeshPart Art Pack과 Asset QA
- Slice 01 Production Build Acceptance Audit
- Slices 02–16 사용자·보안·복구 Scenario
- DataStore server restart·Cross-server Lease·Migration·Conflict Recovery
- Navigation·Physics·Streaming·Large Scene
- 전면 UI Visual Redesign와 Accessibility User Test
- Performance·Memory·Network·Fault·Soak Evidence

## 데이터 차단

Slices 13–15의 Runtime과 Rights Gate는 구현했지만 공식 D&D 데이터는 포함하지 않았다. 승인된 Source Version·권리·배포 범위를 가진 별도 Content Pack만 등록할 수 있다.
