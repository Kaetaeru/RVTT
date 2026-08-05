# RVTT Production Implementation Status

- 상태: `IMPLEMENTED_STUDIO_BASELINE_VERIFIED`
- 작성일: 2026-08-05
- 최종 갱신일: 2026-08-05
- 범위: 16개 Slice 계약의 Greenfield Runtime·Domain·Client·UI·Test baseline
- 3D World Token 정적 검증 Implementation Head: `f011991828c417cb9d98819e2eb6c77dc9667971`
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

## Slice 01 3D World Token

상태:

```text
Authority·Scene·Movement Contract
→ IMPLEMENTED

Projection-driven 3D Renderer
→ IMPLEMENTED

Model·MeshPart Asset Resolver
→ IMPLEMENTED

World Selection·Destination Input
→ IMPLEMENTED

Persistence·Reconnect Acceptance Place
→ IMPLEMENTED

Structure·Format·Lint·Rojo Build·Type Analysis
→ PASSED

Studio 3D End-to-End Acceptance
→ PENDING
```

현재 Delta:

```text
SLICE_01_3D_WORLD_TOKEN_IMPLEMENTED_STUDIO_PENDING
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
Token 클릭
→ actorId 해석
→ owner·controller·DM control 확인
→ 선택 Highlight

Move Surface 클릭
→ Raycast destination 생성
→ movement.commit 제출
→ 서버 Validation·Commit
→ 새 Projection 수신
→ 3D Token 위치 갱신
```

클라이언트는 클릭 직후 Token을 임의로 이동하지 않는다. 신규 Projection Revision이 도착하기 전에는 Model Transform을 바꾸지 않는다.

### 자동 검증

`WorldTokenContract.spec.lua`가 다음을 검사한다.

- 공개 Actor 조회
- Character 이름 Label
- Owner·DM Control과 비소유자 거부
- 유한 3D Position 변환
- 비유한 값 거부
- plain destination payload
- Actor identity fingerprint
- 이동 Surface ancestor 계약

기존 `Slice01Flow.spec.lua`는 실제 명령 Sequence와 Authority Snapshot 복구를 계속 검증한다.

## Slice 01 3D Acceptance Place

`slice01-acceptance.project.json`은 기존 2D 원형 계측 Token 대신 실제 Workspace 3D Token Acceptance를 실행한다.

사용 범위:

- Production Server·Client·Networking·Projection Source
- Production `movement.commit`
- Production Persistence
- Acceptance 전용 DM Override
- Acceptance 전용 이동 Board와 Scriptable Camera
- 3D Token 선택·이동·재접속 복구 Panel

수동 Gate:

```text
Scene 준비·재개
→ 3D Token 생성
→ Token 클릭 선택
→ Board 클릭 이동 요청
→ Projection Revision 증가
→ 3D Token 서버 위치 반영
→ Persistence Save
→ Stop·Play
→ Character·Scene·Position·3D Token 복구
```

최종 3D Studio Evidence는 아직 기록하지 않았다.

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
- 전면 수정은 별도 `UI Visual Redesign Gate`에서 일괄 수행

## 정적 검증 결과

Implementation Head `f011991828c417cb9d98819e2eb6c77dc9667971`:

- Structure·Security·Policy Validator: PASS
- StyLua: PASS
- Selene: PASS
- Production Rojo Build: PASS
- Unit Test Place Rojo Build: PASS
- Multi-client Place Rojo Build: PASS
- Persistence Acceptance Place Rojo Build: PASS
- Slice 01 3D Acceptance Place Rojo Build: PASS
- Production·Test Luau Type Analysis: PASS

## 다음 Gate

```text
Slice 01 3D World Token Studio Acceptance
→ Slice 01 Production Build Acceptance Audit
→ Slice 02 Rules·D20 Acceptance
```

## 아직 미검증

- 실제 Studio에서 3D Token 생성·선택·서버 이동·복구
- 최종 OBJ·MeshPart Art Pack과 Asset QA
- Slice 01 Production Build Acceptance Audit
- Slices 02–16 사용자·보안·복구 Scenario
- DataStore server restart·Cross-server Lease·Migration·Conflict Recovery
- Navigation·Physics·Streaming·Large Scene
- 전면 UI Visual Redesign와 Accessibility User Test
- Performance·Memory·Network·Fault·Soak Evidence

## 데이터 차단

Slices 13–15의 Runtime과 Rights Gate는 구현했지만 공식 D&D 데이터는 포함하지 않았다. 승인된 Source Version·권리·배포 범위를 가진 별도 Content Pack만 등록할 수 있다.
