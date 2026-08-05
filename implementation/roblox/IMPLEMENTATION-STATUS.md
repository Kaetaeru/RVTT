# RVTT Production Implementation Status

- 상태: `IMPLEMENTED_STUDIO_BASELINE_VERIFIED`
- 작성일: 2026-08-05
- 최종 갱신일: 2026-08-05
- 범위: 16개 Slice 계약의 Greenfield Runtime·Domain·Client·UI·Test baseline
- 최신 구현 Head: `a23baf9815b2b52cafb0e2c7530c4131546d2fce`
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

## 사용자 Accent Theme

상태:

```text
Implementation
→ DONE

Static·Toolchain CI
→ PASSED

Automated Studio Tests
→ PASSED

Visual·Input Studio Acceptance
→ PASSED

Persistence Studio Acceptance
→ PENDING
```

구현 범위:

- 기본 Accent `gold`
- 검수된 Palette `gold·azure·emerald·amethyst·teal·silver`
- Shared `AccentPreference` 계약과 안전한 Gold Fallback
- Palette별 Primary·Hover·Pressed·Soft·On·Focus·Glow Token
- 기존 `ui.set_preference`를 이용한 Server Validation과 저장 상태 변경
- Viewer별 `ui_preferences` Projection을 통한 사용자 설정 격리
- Settings Modal과 즉시 미리보기
- Q 입력을 이용한 Settings Context 종료
- Server Projection 도착 후 권위값 Reconciliation
- 일반 Accent와 Role·Success·Warning·Danger 의미색 분리

2026-08-05 18:04 KST Studio 자동 테스트:

```text
[RVTT Tests] passed=173 failed=0
[RVTT Live DataStore] passed=10 failed=0
```

`173/0`은 깨끗하게 새로 Build한 Test Place에서도 재현된 현재 기준값이다.

2026-08-05 18:31 KST Studio Visual·Input Acceptance:

- Loading 화면 종료와 RVTT App 표시
- 기본 Gold 표시
- 6개 Palette 전환
- 선택됨 Label·Stroke 이동
- 3초 후 선택 Accent 유지
- Q로 Settings 닫기
- 다시 열었을 때 선택값 유지
- 관련 Output 오류 없음

## Studio Boot 동기화 교착 수정

원인:

- Server가 Remote 생성 전에 기본 캠페인 DataStore Load를 동기식으로 기다렸다.
- Client가 최초 Full Resync 이후에만 `ClientRuntime`을 공개했다.

수정:

- Remote·Projection Publisher를 Persistence Load보다 먼저 시작
- 기본 Studio Play Live Persistence 비활성화
- `RVTT_EnableStudioPersistence=true`에서만 Studio Live Persistence 활성화
- Client Runtime 조기 공개
- `clientReady` 우선 Projection과 비동기 Full Resync Fallback
- Remote 대기 10초 제한과 진단 메시지

수정 후 실제 Studio에서 Loading 종료와 App 표시를 확인했다.

## Roblox 기본 캐릭터 비활성화

제품 계약상 플레이어 표현은 Roblox 아바타가 아니라 RVTT의 리그 없는 OBJ·MeshPart Token이다.

구현:

- `default.project.json`의 `Players.CharacterAutoLoads=false`
- `ServerBoot.server.lua`에서 `Players.CharacterAutoLoads=false` 재강제
- 이미 생성된 `Player.Character`가 있으면 접속 처리 시 제거
- RVTT Character·Actor·Token 도메인 상태에는 영향 없음

구현 Head `a23baf9`에서 다음 GitHub Actions가 모두 통과했다.

- Structure·Security·Policy Validator
- StyLua Format
- Selene Lint
- Production·Test·Multi-client Rojo Build
- Production·Test Luau Type Analysis

실제 Studio에서 기본 Roblox 아바타가 생성되지 않는지는 다음 Acceptance Gate에서 확인한다.

## UI 시각 디자인 상태

현재 UI는 기능·입력 검증용 Placeholder Shell이다. 최종 시각 디자인으로 간주하지 않는다.

추후 전면 개편 시 일관성을 유지하기 위해 다음 구조를 보존한다.

- 화면 로직과 시각 표현 분리
- 색상·간격·Typography·Radius의 Token 관리
- 공통 Button·Panel·Modal·Banner 컴포넌트 사용
- Accent와 Semantic Status Color 계약 유지
- 기능 테스트를 외형이 아닌 상태·입력·권위 동기화 기준으로 유지

부분적인 화면별 미화는 보류하고 별도 `UI Visual Redesign Gate`에서 일괄 교체한다.

## 기존 Roblox Studio Baseline

2026-08-05 15:42 KST:

```text
[RVTT Tests] passed=108 failed=0
[RVTT Live DataStore] passed=10 failed=0
[RVTT MultiClient] passed=56 failed=0 clients=3 staleRetries=3
```

## 상태 해석

현재 Accent Theme Delta 상태:

```text
ACCENT_THEME_VISUAL_INPUT_VERIFIED_PERSISTENCE_PENDING
```

다음을 의미하지 않는다.

- Live Persistence 상태의 Accent 재접속 복구 완료
- Roblox 기본 아바타 비생성 Studio 확인 완료
- Slice 01 전체 사용자 흐름 Acceptance 완료
- Slices 02–16 Acceptance 완료
- 서버 종료·재시작과 Cross-server 저장 복구 완료
- UI 최종 시각 품질·접근성 완료
- 성능·장시간 Soak 완료
- Production Ready 또는 Release Ready

## Studio Persistence 주의

기본 `default.project.json` Studio Play는 UI 검수를 막지 않도록 Live Persistence를 사용하지 않는다.

```text
Default Studio Play
→ Session 내 UI 검수

Live Persistence 검수
→ live-datastore.project.json
또는
→ DataModel Attribute RVTT_EnableStudioPersistence=true
```

## 아직 미검증

- 기본 Roblox 아바타가 생성되지 않는지 실제 Studio 확인
- Live Persistence 활성화 상태의 Accent Preference 복구
- Slice 01 `Join → Select → Ready → Scene → Move → Reconnect`
- Slices 02–16 사용자·보안·복구 Scenario
- DataStore server restart·Cross-server Lease·Migration Recovery
- Navigation·Physics·Streaming·Large Scene
- 전면 UI Visual Redesign와 Accessibility User Test
- Performance·Memory·Network·Fault·Soak Evidence

## 데이터 차단

Slices 13–15의 Runtime과 Rights Gate는 구현했지만 공식 D&D 데이터는 포함하지 않았다. 승인된 Source Version·권리·배포 범위를 가진 별도 Content Pack만 등록할 수 있다.
