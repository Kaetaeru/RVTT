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
→ VERIFIED IN STUDIO

Accent Persistence Acceptance
→ VERIFIED IN STUDIO

Remote Bootstrap Studio Recheck
→ VERIFIED IN STUDIO

현재 작업
→ Slice 01 Studio Acceptance
```

Studio 실행 Evidence:

```text
Unit·Integration
→ passed=173 failed=0

Live DataStore baseline
→ passed=10 failed=0

3-client MultiClient
→ passed=56 failed=0 clients=3 staleRetries=3

Persistence Acceptance
→ enabled · loaded · saved · runtime ready · Accent restored
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

2026-08-05 20:08 KST Persistence 최종 결과:

```text
Project Config Persistence 활성화
→ PASS

기존 Authority Revision Load
→ PASS

Accent 변경 후 Save
→ PASS

ClientBoot runtime ready
→ PASS

재실행 후 신규 Revision Load
→ PASS

마지막 Accent 화면 복구
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
| 7 | DONE | Accent Automated Studio Tests | Unit·Integration `173/0`, Live DataStore baseline |
| 8 | DONE | Boot Fix Studio Recheck | Loading 종료와 App 표시 |
| 9 | DONE | Accent Visual·Input Acceptance | 6 Palette·Q 종료·Reconciliation·선택 유지 |
| 10 | DONE | Roblox Avatar Auto-Spawn Disable Implementation | CharacterAutoLoads 차단과 기존 Character 제거 |
| 11 | DONE | Avatar Suppression Studio Recheck | 기본 아바타·Humanoid 비생성, UI 정상 |
| 12 | DONE | Accent Persistence Acceptance | Save·Reload·UI Restore 성공 |
| 13 | DONE | Remote Bootstrap Studio Recheck | Canonical Remote 세트와 Client runtime ready |
| 14 | IN_PROGRESS | Slice 01 Studio Acceptance | Join→Select→Ready→Scene→Move→Reconnect |
| 15 | QUEUED | Slice 01 Build Acceptance Audit | 실행 Evidence와 UI·UX Checklist 판정 |
| 16 | QUEUED | Slices 02–16 Studio Acceptance | Slice별 사용자·보안·복구 Scenario 통과 |
| 17 | QUEUED | DataStore·Restart Recovery | Restart·Lease·Migration·Conflict 검증 |
| 18 | QUEUED | UI Visual Redesign | 전체 화면을 Token·공통 Component 기준으로 일괄 개편 |
| 19 | QUEUED | UI Accessibility QA | Keyboard·Focus·Contrast·User Test |
| 20 | QUEUED | Performance·Fault·Soak | 측정 Evidence와 Release Gate |

## 3. Roblox 기본 캐릭터 비활성화 계약

제품 내 플레이어 표현은 Roblox 아바타가 아니라 RVTT Token이다.

```text
default.project.json Players.CharacterAutoLoads
→ false

ServerBoot CharacterAutoLoads 재강제
→ DONE

기존 Player.Character 제거
→ DONE

Studio Avatar Suppression
→ PASS

RVTT Character·Actor·Token Domain
→ 변경 없음
```

이 정책은 Roblox `Player.Character`만 차단한다. RVTT의 캐릭터 데이터, 토큰 선택, 권위 이동에는 영향을 주지 않는다.

## 4. Accent Persistence 계약

기본 Studio Play는 Session 내 UI 검수용이며 Live Persistence는 끈다.

Persistence Acceptance는 다음 전용 프로젝트로 수행한다.

```text
persistence-acceptance.project.json
→ ServerStorage.RVTT.EnableStudioPersistence=true
```

게시된 테스트 Experience에서 확인된 흐름:

```text
Persistence enabled
→ Authority Load
→ Accent 변경
→ Revision Save
→ Play 종료
→ 재실행
→ Revision Load
→ 마지막 Accent 화면 복구
```

최종 상태:

```text
ACCENT_THEME_PERSISTENCE_VERIFIED
```

## 5. Remote Bootstrap 계약

- 서버는 Command·Receipt·Projection·Sync·ClientReady가 모두 준비된 폴더만 공개한다.
- 오래된 부분 폴더, 잘못된 형식, 동명 중복 폴더를 제거한다.
- 클라이언트는 완전한 Canonical Remote 세트만 선택한다.
- 실패 시 후보 폴더와 자식 형식을 Output에 표시한다.

실제 Persistence 실행에서 `ClientBoot runtime ready`를 확인했다.

## 6. 현재 UI 디자인 해석

현재 UI는 기능 검증용 Placeholder Shell이다.

- 현재 외형을 최종 디자인으로 확장하지 않는다.
- 화면별 직접 스타일 추가를 피한다.
- Token과 공통 Component를 유지한다.
- 전면 수정은 별도 `UI Visual Redesign` 작업에서 일관되게 수행한다.
- 기능 테스트는 상태·입력·서버 권위 계약을 기준으로 유지한다.

## 7. 현재 실행 Gate: Slice 01

목표 흐름:

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

통과 기준:

- Join 후 플레이어 Session이 서버 권위 상태에 등록된다.
- Character 선택과 Ready 상태가 Projection에 반영된다.
- Scene과 Token이 Viewer에게 올바르게 표시된다.
- Token 이동은 서버 Command 결과로 확정된다.
- Disconnect 후 Reconnect 시 Character·Scene·Position이 복구된다.
- Roblox 기본 아바타는 생성되지 않는다.
- Accent Preference도 유지된다.
- 관련 Output 오류가 없다.

## 8. 다음 Gate

```text
Slice 01 Studio Acceptance
→ Slice 01 Production Build Acceptance Audit
→ Slices 02–16 Studio Acceptance
→ DataStore·Restart Recovery
→ UI Visual Redesign
```

현재 상태는 Production Ready 또는 Release Ready를 의미하지 않는다.
