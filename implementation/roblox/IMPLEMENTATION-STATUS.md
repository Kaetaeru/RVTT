# RVTT Production Implementation Status

- 상태: `IMPLEMENTED_STUDIO_BASELINE_VERIFIED`
- 작성일: 2026-08-05
- 범위: 16개 Slice 계약의 Greenfield Runtime·Domain·Client·UI·Test baseline
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

## 검증 완료

### GitHub Actions

- Structure·Security·Policy Validator
- StyLua Format
- Selene Lint
- Production·Test·Multi-client Rojo Build
- Production·Test Luau Type Analysis

### Roblox Studio

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

`IMPLEMENTED_STUDIO_BASELINE_VERIFIED`는 Source baseline이 정적 Toolchain과 Roblox Studio Runtime 기본 검증을 통과했다는 뜻이다.

다음을 의미하지 않는다.

- Slice 01 전체 사용자 흐름 Acceptance 완료
- Slices 02–16 Build Acceptance 완료
- 서버 종료·재시작과 Cross-server 저장 복구 완료
- Navigation·Physics·Streaming 검증 완료
- UI 최종 시각 품질·접근성 완료
- 성능·장시간 Soak 완료
- Production Ready 또는 Release Ready

## 아직 미검증

- Slice 01 `Join → Select → Ready → Scene → Move → Reconnect`
- Slices 02–16 사용자·보안·복구 Scenario
- DataStore server restart·Cross-server Lease·Migration Recovery
- Navigation·Physics·Streaming·Large Scene
- UI Visual QA와 Accessibility User Test
- Performance·Memory·Network·Fault·Soak Evidence

## 데이터 차단

Slices 13–15의 Runtime과 Rights Gate는 구현했지만 공식 D&D 데이터는 포함하지 않았다. 승인된 Source Version·권리·배포 범위를 가진 별도 Content Pack만 등록할 수 있다.
