# RVTT Roblox Implementation 현재 작업 순서

- 상태: `IMPLEMENTED_STUDIO_BASELINE_VERIFIED`
- 문서 종류: Production Implementation Work Order
- 최종 갱신일: 2026-08-05
- Script Manifest: [`manifests/all-slices-script-manifest.md`](manifests/all-slices-script-manifest.md)
- 구현 상태: [`IMPLEMENTATION-STATUS.md`](IMPLEMENTATION-STATUS.md)
- Studio 검증 근거: [`Roblox Studio Runtime Baseline Validation Audit`](../../docs/remake/audits/roblox-studio-runtime-baseline-validation-audit.md)
- Accent Policy: [`Accent Theme and Color Consistency Policy`](../../docs/remake/ui/policies/accent-theme-and-color-consistency-policy.md)
- 계약→Script 감사: [`All-slice Contract-to-Script Transfer Audit`](../../docs/remake/audits/all-slice-script-transfer-audit.md)
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

Accent Automated Tests
→ VERIFIED

Boot Fix Studio Recheck
→ VERIFIED

Accent Visual·Input Acceptance
→ VERIFIED

Roblox Avatar Auto-Spawn Disable
→ IMPLEMENTED · CI PASSED

현재 작업
→ Roblox Avatar Suppression Studio Recheck
```

Studio 실행 Evidence:

```text
Unit·Integration
→ passed=173 failed=0

Live DataStore
→ passed=10 failed=0

3-client MultiClient
→ passed=56 failed=0 clients=3 staleRetries=3
```

2026-08-05 18:31 KST Accent Visual·Input 결과:

```text
6개 Palette 전환
→ PASS

선택됨 표시 이동
→ PASS

3초 후 선택 유지
→ PASS

Q로 Settings 닫기
→ PASS

다시 열었을 때 선택 유지
→ PASS

Output 오류 없음
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
| 6 | DONE | User Accent Theme Implementation | Gold·6 Palette·Settings·Server Validation·Projection |
| 7 | DONE | Accent Automated Studio Tests | Unit·Integration `173/0`, Live DataStore `10/0` |
| 8 | DONE | Boot Fix Studio Recheck | Loading 종료와 App 표시 |
| 9 | DONE | Accent Visual·Input Acceptance | 6 Palette·Q 종료·Reconciliation·선택 유지 |
| 10 | DONE | Roblox Avatar Auto-Spawn Disable Implementation | CharacterAutoLoads 차단과 기존 Character 제거 |
| 11 | IN_PROGRESS | Avatar Suppression Studio Recheck | Play 시 Roblox 기본 아바타·Humanoid 비생성 |
| 12 | QUEUED | Accent Persistence Acceptance | Live Persistence 상태에서 재접속 복구 |
| 13 | QUEUED | Slice 01 Studio Acceptance | Join→Select→Ready→Scene→Move→Reconnect |
| 14 | QUEUED | Slice 01 Build Acceptance Audit | 실행 Evidence와 UI·UX Checklist 판정 |
| 15 | QUEUED | Slices 02–16 Studio Acceptance | Slice별 사용자·보안·복구 Scenario 통과 |
| 16 | QUEUED | DataStore·Restart Recovery | Restart·Lease·Migration·Conflict 검증 |
| 17 | QUEUED | UI Visual Redesign | 전체 화면을 Token·공통 Component 기준으로 일괄 개편 |
| 18 | QUEUED | UI Accessibility QA | Keyboard·Focus·Contrast·User Test |
| 19 | QUEUED | Performance·Fault·Soak | 측정 Evidence와 Release Gate |

## 3. Roblox 기본 캐릭터 비활성화 계약

제품 내 플레이어 표현은 Roblox 아바타가 아니라 RVTT Token이다.

```text
default.project.json Players.CharacterAutoLoads
→ false

ServerBoot CharacterAutoLoads 재강제
→ DONE

기존 Player.Character 제거
→ DONE

RVTT Character·Actor·Token Domain
→ 변경 없음

Static·Toolchain CI
→ PASSED
```

이 정책은 Roblox `Player.Character`만 차단한다. RVTT의 캐릭터 데이터, 토큰 선택, 권위 이동에는 영향을 주지 않는다.

## 4. 현재 UI 디자인 해석

현재 UI는 기능 검증용 Placeholder Shell이다.

- 현재 외형을 최종 디자인으로 확장하지 않는다.
- 화면별 직접 스타일 추가를 피한다.
- Token과 공통 Component를 유지한다.
- 전면 수정은 별도 `UI Visual Redesign` 작업에서 일관되게 수행한다.
- 기능 테스트는 상태·입력·서버 권위 계약을 기준으로 유지한다.

## 5. 현재 상태 해석

Accent Delta:

```text
ACCENT_THEME_VISUAL_INPUT_VERIFIED_PERSISTENCE_PENDING
```

다음을 의미하지 않는다.

- Accent 재접속 영구 복구 완료
- Roblox 아바타 비생성 Studio 확인 완료
- Slice 01 End-to-End Acceptance 완료
- Slices 02–16 Acceptance 완료
- UI 최종 디자인 완료
- Production Ready 또는 Release Ready

## 6. 현재 실행 Gate: Avatar Suppression

최신 `default.project.json`을 새 Place로 Build한 뒤 Play한다.

```text
Play
→ Loading 종료
→ RVTT App 표시
→ Workspace에 Roblox 기본 캐릭터 Model 없음
→ Player.Character == nil
→ Humanoid·HumanoidRootPart 없음
→ RVTT UI와 Accent 기능 정상
```

통과 기준:

- 플레이어 이름의 Roblox Character Model이 생성되지 않는다.
- Reset Character를 눌러도 자동 재생성되지 않는다.
- RVTT App과 Settings는 계속 작동한다.
- Output에 Character 관련 오류가 없다.

## 7. Persistence 별도 Gate

기본 Studio Play는 Session 내 UI 검수용이다. Play 종료 후 복구는 다음 중 하나로 별도 검증한다.

```text
live-datastore.project.json
또는
DataModel Attribute RVTT_EnableStudioPersistence=true
```

Live Persistence를 활성화한 뒤:

```text
Accent 선택
→ 저장 Flush 대기
→ 재접속
→ 마지막 Accent 복구
```

## 8. 다음 Gate

```text
Avatar Suppression Studio Recheck
→ Accent Persistence Acceptance
→ Slice 01 Join·Select·Ready·Scene·Move·Reconnect
→ Slice 01 Production Build Acceptance Audit
```
