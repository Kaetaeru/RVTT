# RVTT Roblox Implementation 현재 작업 순서

- 상태: IMPLEMENTED_UNVERIFIED
- 문서 종류: Production Implementation Work Order
- 최종 갱신일: 2026-08-05
- Script Manifest: [`manifests/all-slices-script-manifest.md`](manifests/all-slices-script-manifest.md)
- 구현 상태: [`IMPLEMENTATION-STATUS.md`](IMPLEMENTATION-STATUS.md)
- 계약→Script 감사: [`All-slice Contract-to-Script Transfer Audit`](../../docs/remake/audits/all-slice-script-transfer-audit.md)
- UI·UX Policy: [`UI·UX Global Policies`](../../docs/remake/ui/policies/README.md)

## 현재 상태

```text
16개 Slice Script Manifest
→ DONE

Shared·Server·Client·UI·Test Source
→ IMPLEMENTED

정적 Structure·Policy Validation
→ READY FOR CI

Luau·Rojo·Roblox Studio Validation
→ NOT RUN
```

## 다음 작업 순서

1. GitHub Actions `Validate RVTT implementation` 통과
2. Rojo 설치 후 `default.project.json` build
3. StyLua·Selene·Luau typecheck 실행과 수정
4. `test.project.json`을 Roblox Studio에서 실행
5. Slice 01 Join→Select→Ready→Scene→Move→Reconnect 검증
6. Slice별 Studio Integration과 Build Acceptance
7. 공식 콘텐츠 Data·Rights Review
8. Full-session fault·performance·soak evidence

## 완료 해석

`IMPLEMENTED_UNVERIFIED`는 계약을 Script 구조와 실행 경로로 옮겼다는 뜻이다. Roblox Studio 실행, 실제 DataStore와 사용자 Acceptance가 통과하기 전에는 Production Ready 또는 Release Ready로 전환하지 않는다.
