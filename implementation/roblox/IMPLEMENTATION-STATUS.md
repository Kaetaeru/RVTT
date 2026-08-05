# RVTT Production Implementation Status

- 상태: `IMPLEMENTED_STUDIO_BASELINE_VERIFIED`
- 작성일: 2026-08-05
- 최종 갱신일: 2026-08-05
- 범위: 16개 Slice 계약의 Greenfield Runtime·Domain·Client·UI·Test baseline
- 최신 구현 Head: `fee64cf527cc914ded7f81879f64f51eeab9ee5c`
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
- 16개 Slice Domain Command baseline
- Unit·Integration·Security·Disclosure Test Source

## 사용자 Accent Theme 변경

상태:

```text
Implementation
→ DONE

Static·Toolchain CI
→ PASSED

Automated Studio Tests
→ PASSED

Visual·Input Studio Acceptance
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
- State Banner·Action Prompt·Panel Shell의 Semantic Theme 적용

추가 Test Source:

- `Unit/AccentTheme.spec.lua`
- `Integration/UiPreferenceFlow.spec.lua`

2026-08-05 18:04 KST Studio 실행 결과:

```text
[RVTT Tests] passed=173 failed=0
[RVTT Live DataStore] passed=10 failed=0
```

`173/0`은 깨끗하게 새로 Build한 Test Place에서도 재현된 현재 기준값이다.

## Studio Boot 동기화 교착 수정

관찰된 문제:

```text
default.project.json Play
→ RVTT · 동기화 중
→ UI가 열리지 않고 무기한 대기
```

원인:

- Server가 Remote를 생성하기 전에 기본 캠페인 DataStore Load를 동기식으로 기다렸다.
- Client는 최초 Full Resync가 끝난 뒤에만 `ClientRuntime`을 공개했다.
- DataStore 또는 Sync 응답이 지연되면 App과 Loading 종료가 모두 차단됐다.

수정:

- Remote·Projection Publisher를 Persistence Load보다 먼저 시작한다.
- 기본 Studio Play에서는 Live Persistence를 비활성화한다.
- Studio Live Persistence는 `RVTT_EnableStudioPersistence=true`일 때만 활성화한다.
- Client Runtime을 최초 Full Resync 전에 공개한다.
- `clientReady` Projection을 우선 사용하고 Full Resync는 비동기 Fallback으로 실행한다.
- Remote 대기에 10초 제한과 화면 진단 메시지를 추가한다.

수정 Head `fee64cf`는 다음 GitHub Actions를 모두 통과했다.

- Structure·Security·Policy Validator
- StyLua Format
- Selene Lint
- Production·Test·Multi-client Rojo Build
- Production·Test Luau Type Analysis

수정 후 실제 Studio UI 재검수는 아직 필요하다.

## 기존 Roblox Studio Baseline

2026-08-05 15:42 KST 실행 결과:

```text
[RVTT Tests] passed=108 failed=0
[RVTT Live DataStore] passed=10 failed=0
[RVTT MultiClient] passed=56 failed=0 clients=3 staleRetries=3
```

검증된 Runtime baseline:

- Unit·Integration Runtime
- 실제 DataStoreService Save·Load·Conflict·Cleanup
- DM·Player·Observer 3-client Remote 흐름
- Authorization과 Unauthorized State 불변
- Concurrent Join·Stale Revision Recovery·중복 Commit 방지
- Viewer별 Private Projection과 DM 정보 은닉
- Disconnect·Reconnect와 Full Resync

## 상태 해석

현재 Accent Theme Delta는 다음 상태다.

```text
ACCENT_THEME_AUTOMATED_TESTS_VERIFIED_UI_PENDING
```

다음을 의미하지 않는다.

- 부팅 수정 후 실제 Studio UI 표시 확인 완료
- 여섯 Palette의 시각·입력·접근성 Acceptance 완료
- Studio Play 종료 후 Preference 영구 복구 완료
- Slice 01 전체 사용자 흐름 Acceptance 완료
- Slices 02–16 Build Acceptance 완료
- 서버 종료·재시작과 Cross-server 저장 복구 완료
- Navigation·Physics·Streaming 검증 완료
- UI 최종 시각 품질·접근성 완료
- 성능·장시간 Soak 완료
- Production Ready 또는 Release Ready

## Studio Persistence 주의

기본 `default.project.json` Studio Play는 UI 검수를 막지 않도록 Live Persistence를 사용하지 않는다.

```text
Default Studio Play
→ Session 내 Accent 선택·Projection 검수

Live Persistence 검수
→ live-datastore.project.json
또는
→ DataModel Attribute RVTT_EnableStudioPersistence=true
```

Play 종료 후 마지막 Accent 복구는 Live Persistence를 명시적으로 활성화한 별도 Gate에서 검증한다.

## 아직 미검증

- 수정 Head에서 Loading 화면이 정상 종료되는지 확인
- 기본 Gold Theme의 실제 Studio 렌더링
- 여섯 Accent Palette의 Hover·Selected·Focus·Contrast
- Settings Q 종료와 Keyboard Focus 순서
- Accent 선택 후 Projection Reconciliation
- Live Persistence 활성화 상태의 Accent Preference 복구
- 의미색이 사용자 Accent에 의해 변경되지 않는지 확인
- Slice 01 `Join → Select → Ready → Scene → Move → Reconnect`
- Slices 02–16 사용자·보안·복구 Scenario
- DataStore server restart·Cross-server Lease·Migration Recovery
- Navigation·Physics·Streaming·Large Scene
- UI Visual QA와 Accessibility User Test
- Performance·Memory·Network·Fault·Soak Evidence

## 데이터 차단

Slices 13–15의 Runtime과 Rights Gate는 구현했지만 공식 D&D 데이터는 포함하지 않았다. 승인된 Source Version·권리·배포 범위를 가진 별도 Content Pack만 등록할 수 있다.
