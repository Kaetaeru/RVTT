# RVTT Production Implementation Status

- 상태: `IMPLEMENTED_STUDIO_BASELINE_VERIFIED`
- 작성일: 2026-08-05
- 최종 갱신일: 2026-08-05
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

2026-08-05에 다음 항목을 확인했다.

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

수동 Gate 이전에는 다음 조건을 모두 충족해야 한다.

- 관련 사용자 흐름 구현 완료
- 정상·거부·저장·복구 자동 테스트 추가
- Input·Command·Projection·Persistence 진단 추가
- 최종 PASS·FAIL Summary 제공
- `tooling/run-studio-acceptance-batch.ps1`로 한 번에 Build 가능
- Implementation·Documentation CI PASS

정확한 검증 Head는 장기 상태 문서에 매 커밋마다 기록하지 않는다. 최종 Batch Gate에서 Runner가 생성하는 Manifest와 Draft PR에 고정한다.

## 현재 Slice 01 World Interaction Batch

현재 Delta:

```text
SLICE_01_WORLD_INTERACTION_BATCH_IN_PROGRESS
```

이번 Batch 범위:

```text
3D Token Projection 안정화
→ 화면·월드 좌표 Token Picking
→ Raycast 실패 시 Screen-space Picking Fallback
→ 선택 Highlight·선택 상태 표시
→ Board Destination Marker
→ 서버 권위 movement.commit
→ Command Receipt·Revision 진단
→ 3D Camera Pan·Zoom·Frame
→ Persistence Save·Reconnect Restore
→ Final Batch Summary
```

현재 관측된 결함:

```text
WT-PICK-01
보이는 3D Token을 클릭했지만 Raycast가
Workspace.RVTT_AcceptanceBoard.MoveSurface를 반환함
```

이 결함은 단독 Studio 재검사를 요청하지 않는다. Picking Fallback, Camera, Selection Feedback, Movement Diagnostics와 함께 구현한 뒤 한 번의 Batch Acceptance에서 확인한다.

## Slice 01 3D World Token Baseline

구현 상태:

```text
Authority·Scene·Movement Contract
→ IMPLEMENTED

Projection-driven 3D Renderer
→ IMPLEMENTED

Model·MeshPart Asset Resolver
→ IMPLEMENTED

World Input Baseline
→ IMPLEMENTED

Persistence·Reconnect Acceptance Place
→ IMPLEMENTED

Studio World Interaction Batch
→ IN PROGRESS
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

### World Input과 서버 권위

```text
Token 선택
→ actorId 해석
→ owner·controller·DM control 확인
→ 선택 상태 표시

Move Surface 선택
→ destination 생성
→ movement.commit 제출
→ 서버 Validation·Commit
→ 새 Projection 수신
→ 3D Token 위치 갱신
```

클라이언트는 입력 직후 Token을 임의로 이동하지 않는다. 신규 Projection Revision이 도착하기 전에는 Model Transform을 바꾸지 않는다.

## Acceptance Harness와 Diagnostics

`slice01-acceptance.project.json`은 실제 Production Server·Client·Networking·Projection·Persistence를 사용한다.

향후 Batch Harness는 다음을 제공한다.

- 저장 상태 자동 재개
- 준비 단계 자동화
- 전체 Batch 상태를 한 화면에 표시
- 안정된 `[RVTT <Subsystem>] event=...` 형식의 로그
- 반복 입력 로그 집계
- Command ID·Actor ID·Revision·Result 표시
- 최종 Batch Summary

정상일 때 사용자는 Final Summary만 확인한다. 실패하면 Final Summary와 첫 번째 관련 오류 로그만 공유한다.

## 재사용 Batch Runner

```text
tooling/run-studio-acceptance-batch.ps1
```

Runner는 다음을 한 번에 수행한다.

- Dirty Worktree 차단
- Branch Fetch·Fast-forward Pull
- 검증 Head 확인
- Implementation Validator 실행
- Acceptance Place Build
- Batch Manifest 생성
- Roblox Studio Place 열기

Experience 게시 자체는 Batch당 한 번만 사용자가 수행한다.

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

## 다음 Gate

```text
Slice 01 World Interaction Batch Implementation
→ 자동 회귀·정적 CI PASS
→ 단일 Slice 01 Batch Studio Acceptance
→ Slice 01 Production Build Acceptance Audit
→ Slice 02 Rules·D20 Batch
```

## 아직 미검증

- Slice 01 World Interaction Batch 최종 Studio Acceptance
- 최종 OBJ·MeshPart Art Pack과 Asset QA
- Slice 01 Production Build Acceptance Audit
- Slices 02–16 사용자·보안·복구 Scenario
- DataStore server restart·Cross-server Lease·Migration·Conflict Recovery
- Navigation·Physics·Streaming·Large Scene
- 전면 UI Visual Redesign와 Accessibility User Test
- Performance·Memory·Network·Fault·Soak Evidence

## 데이터 차단

Slices 13–15의 Runtime과 Rights Gate는 구현했지만 공식 D&D 데이터는 포함하지 않았다. 승인된 Source Version·권리·배포 범위를 가진 별도 Content Pack만 등록할 수 있다.
