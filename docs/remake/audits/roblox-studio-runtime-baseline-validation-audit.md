# Roblox Studio Runtime Baseline Validation Audit

- 상태: COMPLETE
- 문서 종류: Studio Runtime Validation Audit
- 감사일: 2026-08-05
- 실행 시각: 2026-08-05 15:42 KST
- 검증 대상 브랜치: `planning/rvtt-remake`
- 기록 당시 PR Head: `f78266cb75ac55f116e15cbf16b4485734c3394f`
- Implementation Status: [`IMPLEMENTATION-STATUS.md`](../../../implementation/roblox/IMPLEMENTATION-STATUS.md)
- Production Work Order: [`CURRENT-WORK-ORDER.md`](../../../implementation/roblox/CURRENT-WORK-ORDER.md)
- 즉시 구현 명세 가능성: READY

## 1. 목적

정적 CI와 Rojo·Luau Toolchain 검증을 통과한 RVTT 구현 baseline이 실제 Roblox Studio 런타임에서 Unit·Integration, Live DataStore와 3-client Authority·Projection 시나리오를 실행할 수 있는지 판정한다.

이 감사는 전체 제품의 Production Ready 판정이 아니다. Studio Runtime Baseline과 다음 Slice Acceptance 착수 가능성만 판정한다.

## 2. 실행 Evidence

사용자가 Roblox Studio에서 실행한 서버 출력:

```text
15:42:02.149  [RVTT Tests] passed=108 failed=0  -  서버 - TestRunner:46
15:42:04.225  [RVTT Live DataStore] passed=10 failed=0  -  서버 - DataStoreRunner:101
15:42:28.392  [RVTT MultiClient] passed=56 failed=0 clients=3 staleRetries=3  -  서버 - ServerRunner:209
```

전체 결과:

```text
Assertions passed
→ 174

Assertions failed
→ 0

Active multi-client viewers
→ 3
```

Evidence 출처는 사용자가 제공한 Studio Output이다. 별도 동영상, `.rbxlx` 실행 산출물 또는 원본 로그 파일은 이 커밋에 보관하지 않는다.

## 3. Studio Unit·Integration 판정

`implementation/roblox/tests/TestRunner.server.lua`가 연결한 Unit·Integration Spec을 실제 Studio Server에서 실행했다.

검증 영역:

- Core·Envelope 계약
- Persistence·ProfileStore
- Domain Registration
- Authority Flow
- Security Boundary
- Viewer별 Projection Disclosure
- Multi-viewer Runtime Flow

결과:

```text
passed=108
failed=0
```

판정: `PASS`

## 4. Live DataStore 판정

`implementation/roblox/tests/LiveDataStore/DataStoreRunner.server.lua`는 Studio에서 실제 `DataStoreService`를 사용한다.

검증 영역:

- `UpdateAsync` 최초 저장
- `GetAsync` 로드
- Revision·AuthorityEpoch 보존
- 오래된 Revision 저장 거부
- 같은 Revision의 다른 AuthorityEpoch 저장 거부
- 더 높은 Revision 저장·재로드
- 임시 Test Key 정리

결과:

```text
passed=10
failed=0
```

판정: `PASS`

이 결과는 실제 API 기본 읽기·쓰기와 충돌 방지 baseline을 증명한다. 서버 프로세스 종료 후 재시작 복구, Cross-server Lease와 장시간 저장 안정성까지 증명하지는 않는다.

## 5. 3-client Authority·Projection 판정

`implementation/roblox/tests/MultiClient/ServerRunner.server.lua`와 `ClientRunner.client.lua`를 Local Server 3-client 구성으로 실행했다.

검증 영역:

- DM·Player·Observer 역할 할당
- 동일 Authority Revision에서 시작
- 동시 Session Join
- Stale Revision 자동 재시도
- 재시도 중복 Commit 방지
- Player·Observer의 DM Command 거부
- Unauthorized Command의 Authority State 불변
- DM Remote Command 단일 Commit
- DM·Player Private Draft 생성
- Viewer별 Private Projection 분리
- Player·Observer에서 DM Workspace 은닉
- Disconnect·Reconnect 상태 전이
- Full Resync Sequence 증가
- 반복 Full Resync의 Revision·AuthorityEpoch 안정성

결과:

```text
passed=56
failed=0
clients=3
staleRetries=3
```

`staleRetries=3`은 실패가 아니다. 동시 요청에서 의도된 Stale Revision Recovery 경로가 실제로 실행됐음을 의미한다.

판정: `PASS`

## 6. 완료된 Gate

| Gate | 결과 |
|---|---|
| Structure·Security·Policy CI | PASS |
| StyLua·Selene | PASS |
| Production·Test·Multi-client Rojo Build | PASS |
| Luau Type Analysis | PASS |
| Studio Unit·Integration Runtime | PASS |
| Studio Live DataStore Baseline | PASS |
| Studio 3-client Authority·Projection Baseline | PASS |

## 7. 아직 완료되지 않은 Gate

- Slice 01 전용 `Join → Select → Ready → Scene → Move → Reconnect` End-to-End Acceptance
- 실제 서버 종료·재시작 후 DataStore Recovery
- Cross-server Lease·동시 저장 충돌
- Navigation·Physics·Streaming·Large Scene
- Slices 02–16 사용자·보안·복구 Acceptance
- UI Visual·Accessibility QA
- Performance·Memory·Network·Fault·Soak Evidence
- 공식 D&D 데이터의 Source Version·Rights·Distribution Review

## 8. Evidence 제한

- Studio Output은 사용자가 제공했다.
- 기록 당시 PR Head는 `f78266c`다.
- 이후 Source 또는 Test가 변경되면 같은 Runner를 다시 실행해야 한다.
- Console Summary만 보관했으며 개별 Assertion 로그와 실행 화면은 보관하지 않았다.
- 현재 결과를 Production Ready 또는 Release Ready로 확대 해석하지 않는다.

## 9. 최종 판정

```text
Implementation Source Baseline
→ IMPLEMENTED

Static·Toolchain Validation
→ PASSED

Roblox Studio Runtime Baseline
→ VERIFIED

현재 상태
→ IMPLEMENTED_STUDIO_BASELINE_VERIFIED

다음 작업
→ Slice 01 Studio Acceptance
```

최종 판정: `PASS`

## 10. 다음 Gate

```text
Slice 01 Acceptance Scenario 고정
→ Join·Select·Ready·Scene·Move·Reconnect 실행
→ 사용자 화면·오류·Recovery 확인
→ 실행 Evidence 기록
→ Slice 01 Production Build Acceptance Audit
→ Slice 02 Studio Acceptance
```
