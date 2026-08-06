# RVTT Grand Acceptance Campaign

- 상태: `PRODUCTION_LEASE_ACCEPTANCE_HOST_STATIC_VERIFIED`
- 목적: 사용자가 한 번의 Windows PowerShell 실행으로 실행 가능한 Acceptance 환경을 순차 처리하고 하나의 결함 보고서를 얻는다.
- Manifest: [`grand-acceptance-manifest.json`](grand-acceptance-manifest.json)
- Runner: [`tooling/run-grand-acceptance.ps1`](tooling/run-grand-acceptance.ps1)
- Production Lease Host: [`PRODUCTION-LEASE-ACCEPTANCE-HOST.md`](PRODUCTION-LEASE-ACCEPTANCE-HOST.md)

## 1. 실행 모델

```text
PowerShell 실행 1회
→ 모든 등록 Rojo Project Build
→ 일반 Grand Runs
→ 선택적 Grand Persistence Runs
→ JSON·Markdown 통합 보고서
```

첫 실패에서 중단하지 않는다. 가능한 모든 Phase를 실행하고 `pass`, `fail`, `incomplete`, `blocked`, `prepared`를 구분한다.

## 2. 일반 Grand Run

### `grand-single-client`

- Unit·Integration·Security·Disclosure
- Slices 02–12 자동 Authority Scenario
- Cross-slice Full-session
- Authority·Network·Storage Fault
- Capacity Sample
- Slice 01 실제 카메라·Token 입력

### `grand-multi-client`

- DM·Player·Observer Authority
- Viewer별 Projection·Negative Disclosure
- Stale Revision Recovery

### `grand-real-transport`

- 실제 Player Client 종료
- `PlayerRemoving`
- Replacement Client 추가
- `PlayerAdded`
- 같은 논리 사용자 Full Sync

일반 Run은 DataStore를 사용하지 않는다.

## 3. Grand Persistence Run

`-IncludePersistence`에서만 실행한다. 게시된 Experience와 Studio API Access가 필요하다.

```text
1. Live DataStore Baseline
2. Restart Seed
3. Restart Verify
4. Injected DataStore Outage
5. Lease Holder·Contender Pair
6. Production Lease Seed
7. Production Lease Verify
```

### Production Lease Seed

```text
Acceptance Key Cleanup
→ 실제 Production ServerBoot
→ Lease Acquire·Fence 1 Claim
→ Sync·Remote session.join
→ Authority Commit
→ Studio 종료
→ Fenced Flush·Metadata·Release
```

Summary:

```text
[RVTT Production Lease Seed] result=PASS failed=0 checks=true flush=true metadata=true release=true ...
```

### Production Lease Verify

```text
실제 Production ServerBoot
→ Higher Fence Claim
→ Seed Membership Restore
→ Sync·Remote session.join
→ 이전 Seed Fence Revision 99 저장 시도
→ PERSISTENCE_FENCED
→ Authority Revision·Fence 불변
→ Fenced Flush·Release·Key Cleanup
```

Summary:

```text
[RVTT Production Lease Verify] result=PASS failed=0 checks=true flush=true release=true cleanup=true staleBlocked=true ...
```

두 Place는 Acceptance 전용 Store·Authority Key·Owner만 사용하며 실제 Campaign Store를 건드리지 않는다.

## 4. Persistence 안전 계약

```text
Lease Acquire
→ Remote Verify
→ Atomic Authority Fence Claim
→ Latest Document Load·Restore
→ Command Guard
→ Background Renew
→ Fenced Save
→ Flush-before-Release
```

- Lease 미획득 서버는 Authority 문서를 Load하지 않는다.
- Persistence 준비 전이나 Lease Lost 뒤 Command를 실행하지 않는다.
- 이전 Fence·Unfenced Writer는 `PERSISTENCE_FENCED`다.
- Higher Fence도 Revision·AuthorityEpoch 단조성 검사를 우회하지 않는다.
- Verify 종료 후 Acceptance Authority·Metadata·Lease Key를 정리한다.

## 5. 다른 Persistence Host

### Restart

- Shutdown-only Dirty Snapshot
- Bounded `BindToClose` Retry
- Fresh Server Restore
- AuthorityEpoch 교체와 이전 Epoch 거부

### Injected Outage

- 실제 DataStore 호출 전에 retryable 장애 주입
- Retry 고갈과 Dirty 보존
- 장애 해제 후 실제 저장·재로드
- Roblox 플랫폼 자체 Outage Evidence는 아님

### Cross-server Lease Pair

- Holder 활성·갱신 중 Contender 차단
- 만료 후 Higher Fencing Token Takeover
- 이전 Holder Verify·Release 거부

## 6. 보고서

기본 출력 위치:

```text
%TEMP%\RVTT-Grand-Acceptance\<timestamp>-<head>\
```

생성 파일:

```text
RVTT-grand-acceptance-report.json
RVTT-grand-acceptance-report.md
places\*.rbxlx
```

Summary가 없으면 PASS가 아니라 `incomplete`다. 정적·Build·Type PASS는 Studio Runtime PASS를 대신하지 않는다.

## 7. 자동 Gate

- Grand Contract Validator: PASS
- Production Lease Contract Validator: PASS
- Production Lease Seed·Verify Place Build: PASS
- Structure·Security·Policy: PASS
- PowerShell Parser·Runner SelfTest: PASS
- StyLua·Selene: PASS
- Production·Test Luau Type: PASS
- Documentation Validation: PASS

## 8. 남은 범위

- Grand Persistence 7개 Phase의 실제 게시·순서 안내 최종화
- 최신 Camera 실제 입력
- UI Visual Redesign·Accessibility Human Review
- Performance Budget·Memory·Network·Soak
- Slices 13–15 공식 Content 권리·Asset
- Slice 16 Release Gate·Runbook

현재는 Grand Persistence Milestone의 사용자 실행 계약을 정리하는 중이므로 Studio 실행을 요청하지 않는다.

## 9. 사용자 실행 계약

사용자에게는 항상 다음 요소를 포함한 완전한 다중 행 Windows PowerShell 블록을 제공한다.

```text
$ErrorActionPreference = "Stop"
RobloxStudioBeta 종료
$HOME\RVTT 저장소 이동
planning/rvtt-remake fetch·switch·pull
정확한 7자리 Head 검사
run-grand-acceptance.ps1 실행
```

한 줄 Bootstrap, 원격 `Invoke-Expression`, 중첩 `powershell -Command`는 제공하지 않는다.
