# Implementation Workspace Bootstrap Audit

- 상태: COMPLETE
- 문서 종류: Production Workspace Bootstrap Audit
- 감사일: 2026-08-05
- Implementation Root: [`implementation`](../../../implementation/README.md)
- Roblox Workspace: [`implementation/roblox`](../../../implementation/roblox/README.md)
- Implementation Work Order: [`Roblox Implementation Work Order`](../../../implementation/roblox/CURRENT-WORK-ORDER.md)
- UI·UX Policy Audit: [`UI·UX Policy Completion Audit`](ui-ux-policy-completion-audit.md)

## 1. 목적

Production Code를 기획 문서와 분리된 `implementation/` Root에서 관리하고, Roblox DataModel Service 구조를 반영하는 실제 Folder가 준비됐는지 검수한다.

## 2. 생성된 구조

```text
implementation/
└─ roblox/
   ├─ src/
   │  ├─ ReplicatedFirst/RVTT/
   │  ├─ ReplicatedStorage/RVTT/
   │  ├─ ServerScriptService/RVTT/
   │  ├─ ServerStorage/RVTT/
   │  ├─ StarterPlayer/StarterPlayerScripts/RVTT/
   │  └─ StarterGui/RVTT/
   ├─ tests/
   ├─ tooling/
   └─ manifests/
```

Git이 빈 Folder를 저장하지 않으므로 각 Folder에 책임·금지 경계 `README.md`를 두었다.

판정: `PASS`

## 3. 책임 분리 검사

| 영역 | 책임 | 판정 |
|---|---|---|
| ReplicatedFirst | 최소 Client Boot·Loading·Recovery Gate | PASS |
| ReplicatedStorage | Shared Type·Version·Result·Protocol·Token Contract | PASS |
| ServerScriptService | Authority Service·Domain·Transaction·Projection | PASS |
| ServerStorage | Server-only Content·Migration·Fixture | PASS |
| StarterPlayerScripts | Replica·Input·Selection·Camera·Intent | PASS |
| StarterGui | Screen·Panel·Component·Theme Composition | PASS |
| tests | Production 경로 기반 Unit·Integration·Roblox Scenario | PASS |
| tooling | Build·Validation·Type·Studio Sync 후보 | PASS |
| manifests | Script 순서·경로·Spec·Test·Migration Index | PASS |

## 4. 구현 방식 검사

확정된 방식:

```text
Slice Contract
→ Script Manifest
→ 가장 위의 IN_PROGRESS Script 하나
→ 대응 Test
→ 검수·Commit
→ 다음 Script
```

금지:

- 전체 빈 Framework 대량 생성
- Manifest 없는 Script
- 여러 Slice의 Script 병렬 착수
- Client Authority 계산
- UI Component Remote 직접 호출
- Test-only Store·Authorization 우회

판정: `PASS`

## 5. Toolchain 판정

현재 Folder Structure는 Roblox Service Mapping만 확정했다.

미확정:

- Rojo Project File
- Package Manager
- Formatter·Linter·Type Check
- Test Runner
- Studio Sync·CI

이 항목은 Slice 01 Script Manifest에서 실제 필요와 환경을 검증한 뒤 확정한다. 검증 없이 `default.project.json`과 Lockfile을 만들지 않았다.

판정: `PASS_WITH_BLOCKER`

## 6. UI·UX Gate

- UI·UX Global Policy: COMPLETE
- Review Checklist: CURRENT
- Production UI Script: 없음
- 모든 향후 UI Script는 Policy Checklist가 완료 조건

판정: `PASS`

## 7. 최종 판정

```text
Production Root 분리
→ COMPLETE

Roblox Folder Structure
→ COMPLETE

Script-by-Script Work Order
→ COMPLETE

Production Luau Scripts
→ NOT STARTED

현재 다음 작업
→ Slice 01 Script Manifest
```

Workspace 생성은 Slice 01 Production 구현 완료를 의미하지 않는다.
