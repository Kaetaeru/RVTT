# RVTT Production Implementation Status

- 상태: `IMPLEMENTED_STUDIO_BASELINE_VERIFIED`
- 작성일: 2026-08-05
- 최종 갱신일: 2026-08-05
- 범위: 16개 Slice 계약의 Greenfield Runtime·Domain·Client·UI·Test baseline
- 최신 Runtime Head: `cf66ee90b015948bddc36079315c0bb52b0692a7`
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
→ PASSED
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

`173/0`은 깨끗하게 새로 Build한 Test Place에서도 재현된 기준값이다.

2026-08-05 18:31 KST Visual·Input Acceptance:

- Loading 화면 종료와 RVTT App 표시
- 기본 Gold 표시
- 6개 Palette 전환
- 선택됨 Label·Stroke 이동
- 3초 후 선택 Accent 유지
- Q로 Settings 닫기
- 다시 열었을 때 선택값 유지
- 관련 Output 오류 없음

2026-08-05 20:08 KST Persistence Acceptance:

- 게시된 테스트 Experience와 Studio API Services 접근 사용
- `persistence-acceptance.project.json`의 Project Config로 Studio Persistence 활성화
- 기존 Authority 문서 Load 성공
- Accent 변경 후 신규 Revision Save 성공
- Play 종료 후 재실행 시 신규 Revision Load 성공
- 마지막 Accent와 선택 표시 화면 복구 성공
- `ClientBoot runtime ready` 확인

최종 판정:

```text
ACCENT_THEME_PERSISTENCE_VERIFIED
```

## Studio Boot과 Remote Bootstrap 보강

초기 동기화 교착 수정:

- Remote·Projection Publisher를 Persistence Load보다 먼저 시작
- 기본 Studio Play Live Persistence 비활성화
- Client Runtime 조기 공개
- `clientReady` 우선 Projection과 비동기 Full Resync Fallback
- Remote 대기 제한과 진단 메시지

Remote 세트 복구:

- Command·Receipt·Projection·Sync·ClientReady 전체 세트를 비공개 상태에서 완성한 뒤 게시
- 오래된 부분 Remote 폴더, 잘못된 형식, 동명 중복 폴더 제거
- 클라이언트는 전체 Remote가 완비된 Canonical Folder만 선택
- 실패 시 후보 폴더와 자식 형식을 진단 로그로 출력
- 중복·부분 폴더 복구 Unit Test 추가

수정 후 실제 Studio에서 Persistence Load·Save와 `ClientBoot runtime ready`를 동시에 확인했다.

## Roblox 기본 캐릭터 비활성화

제품 계약상 플레이어 표현은 Roblox 아바타가 아니라 RVTT의 리그 없는 OBJ·MeshPart Token이다.

구현과 Studio Acceptance:

- `Players.CharacterAutoLoads=false`
- 이미 생성된 `Player.Character`가 있으면 접속 처리 시 제거
- RVTT UI를 `StarterPlayerScripts`에서 실행해 Character 생성과 분리
- Roblox 기본 Character Model 비생성
- `Player.Character == nil`
- Humanoid·HumanoidRootPart 비생성
- RVTT UI·Settings·Accent 정상 작동
- RVTT Character·Actor·Token Domain 상태에는 영향 없음

## Persistence 진단과 검증 보강

- DataStore Load·Save 예외 원문과 Revision을 Output에 표시
- 실제 저장 문서의 비직렬화 Roblox 값, 비유한 수, 잘못된 UTF-8, 순환 참조, 혼합·희소 키를 저장 전에 경로와 함께 차단
- 실제 18개 Domain Authority 스냅샷과 Accent 값을 저장·재로드하는 Live DataStore 검증 추가
- `persistence-acceptance.project.json`은 `ServerStorage.RVTT.EnableStudioPersistence=true`를 빌드에 포함

실제 게시된 테스트 Experience Evidence:

```text
[RVTT Persistence] enabled gameId=10633802552 placeId=139617657977397 studio=true source=project-config
[RVTT Persistence] loaded key=campaign:default revision=5
[RVTT Persistence] saved key=campaign:default revision=6
[RVTT ClientBoot] runtime ready
```

이후 재실행과 화면 확인에서 마지막 Accent 복구가 통과했다.

## UI 시각 디자인 상태

현재 UI는 기능·입력 검증용 Placeholder Shell이다. 최종 시각 디자인으로 간주하지 않는다.

추후 전면 개편 시 일관성을 유지하기 위해 다음 구조를 보존한다.

- 화면 로직과 시각 표현 분리
- 색상·간격·Typography·Radius의 Token 관리
- 공통 Button·Panel·Modal·Banner 컴포넌트 사용
- Accent와 Semantic Status Color 계약 유지
- 기능 테스트를 외형이 아닌 상태·입력·권위 동기화 기준으로 유지

부분적인 화면별 미화는 보류하고 별도 `UI Visual Redesign Gate`에서 일괄 교체한다.

## 상태 해석

현재 완료된 사용자 설정 범위:

```text
Accent Implementation
→ VERIFIED

Visual·Input Behavior
→ VERIFIED

Server Validation·Projection
→ VERIFIED

DataStore Save·Reload·UI Restore
→ VERIFIED
```

다음을 의미하지 않는다.

- Slice 01 전체 사용자 흐름 Acceptance 완료
- Slices 02–16 Acceptance 완료
- Cross-server Lease·Migration·Conflict Recovery 완료
- UI 최종 시각 품질·접근성 완료
- 성능·장시간 Soak 완료
- Production Ready 또는 Release Ready

## 다음 Gate

Slice 01 Studio Acceptance:

```text
Join
→ Character Select
→ Ready
→ Scene Projection
→ Token Select
→ Server-authoritative Move
→ Disconnect
→ Reconnect
→ Character·Scene·Position Recovery
```

## 아직 미검증

- Slice 01 `Join → Select → Ready → Scene → Move → Reconnect`
- Slices 02–16 사용자·보안·복구 Scenario
- DataStore server restart·Cross-server Lease·Migration·Conflict Recovery
- Navigation·Physics·Streaming·Large Scene
- 전면 UI Visual Redesign와 Accessibility User Test
- Performance·Memory·Network·Fault·Soak Evidence

## 데이터 차단

Slices 13–15의 Runtime과 Rights Gate는 구현했지만 공식 D&D 데이터는 포함하지 않았다. 승인된 Source Version·권리·배포 범위를 가진 별도 Content Pack만 등록할 수 있다.
