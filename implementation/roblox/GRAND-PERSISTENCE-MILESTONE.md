# RVTT Grand Persistence Milestone

- 상태: `EXECUTION_CONTRACT_READY`
- 최종 갱신일: 2026-08-06
- 목적: 전용 게시 Place에서 7개 Persistence 검증 단계를 고정 순서로 실행하고 하나의 보고서를 만든다.
- Runner: [`tooling/run-grand-persistence.ps1`](tooling/run-grand-persistence.ps1)
- 설정 예제: [`grand-persistence-config.example.json`](grand-persistence-config.example.json)

## 1. 실행 경계

Grand Persistence는 로컬 `.rbxlx` 파일에서 실행하지 않는다.

```text
Rojo Project
→ 전용 Acceptance Place 업로드
→ Universe ID·Place ID로 최신 게시 Place 열기
→ Studio Play
→ Summary 수집
→ Studio 종료
→ 다음 Phase
```

일반 기능 Grand Runner와 분리한다. 이 Milestone은 DataStore와 게시 Runtime을 다루므로 명시적인 설정 파일과 API Access 확인이 필요하다.

## 2. 전용 Place

하나의 Acceptance Universe 안에 다음 8개 Place를 준비한다.

| 순서 | Project | 역할 |
|---:|---|---|
| 1 | `live-datastore.project.json` | Live DataStore baseline |
| 2 | `restart-seed.project.json` | Restart checkpoint seed |
| 3 | `restart-verify.project.json` | Fresh server restore verify |
| 4 | `datastore-outage.project.json` | Injected outage and recovery |
| 5 | `lease-holder.project.json` | Lease pair holder |
| 5 | `lease-contender.project.json` | Lease pair contender |
| 6 | `production-lease-seed.project.json` | Production ServerBoot seed |
| 7 | `production-lease-verify.project.json` | Higher fence restore and stale writer rejection |

실제 Campaign Universe나 Campaign Store를 사용하지 않는다.

## 3. 로컬 설정

`grand-persistence-config.example.json`을 `grand-persistence-config.json`으로 복사하고 실제 값을 입력한다.

```json
{
  "schemaVersion": 1,
  "universeId": 123456789,
  "apiAccessConfirmed": true,
  "placeIds": {
    "live-datastore.project.json": 100000001,
    "restart-seed.project.json": 100000002,
    "restart-verify.project.json": 100000003,
    "datastore-outage.project.json": 100000004,
    "lease-holder.project.json": 100000005,
    "lease-contender.project.json": 100000006,
    "production-lease-seed.project.json": 100000007,
    "production-lease-verify.project.json": 100000008
  }
}
```

실제 ID가 들어간 `grand-persistence-config.json`은 로컬 전용이다. 저장소에 커밋하지 않는다.

## 4. 고정 실행 순서

```text
1. Live DataStore
2. Restart Seed
3. Restart Verify
4. Injected DataStore Outage
5. Lease Holder·Contender Pair
6. Production Lease Seed
7. Production Lease Verify
```

Seed Phase의 PASS 없이 Verify Phase를 PASS로 해석하지 않는다. Runner는 첫 실패 뒤에도 다음 Phase를 실행해 전체 결함을 수집하지만, 최종 결과는 `FAIL`이다.

Lease Pair에서는 두 Studio 창을 연다. Holder에서 먼저 Play를 시작하고 Contender에서 Play를 시작한다.

## 5. 사전조건

- Windows PowerShell
- Roblox Studio 로그인
- Rojo `7.7.0`
- Acceptance Universe와 8개 Place에 대한 게시 권한
- Studio의 API Services Access 활성화
- 실제 Campaign Store와 분리된 Acceptance Store·Key
- 저장소 HEAD 정확성 확인

`apiAccessConfirmed=false`, 누락된 Universe ID 또는 Place ID가 있으면 Runner는 게시 전에 중단한다.

## 6. 게시와 실행

Runner는 각 Project를 대응 Place에 다음 방식으로 업로드한다.

```text
rojo upload <project> --asset_id <placeId>
```

그 뒤 Roblox Studio의 게시 Place 명령줄 계약을 사용한다.

```text
RobloxStudioBeta.exe
--task EditPlace
--placeId <placeId>
--universeId <universeId>
```

`-NoUpload`은 이미 동일 HEAD를 게시했다고 확인한 재실행에서만 사용한다. `-NoOpen`은 게시와 설정 사전검증만 수행하고 Runtime Evidence를 생성하지 않는다.

## 7. 사용자 실행 블록

HEAD가 확정된 뒤 다음 형식으로 실행한다.

```powershell
$ErrorActionPreference = "Stop"

Get-Process RobloxStudioBeta -ErrorAction SilentlyContinue |
    Stop-Process -Force

$repo = Join-Path $HOME "RVTT"
$runner = Join-Path $repo "implementation\roblox\tooling\run-grand-persistence.ps1"
$config = Join-Path $repo "implementation\roblox\grand-persistence-config.json"

Set-Location $repo

git fetch origin
git switch planning/rvtt-remake
git pull --ff-only origin planning/rvtt-remake

$head = (git rev-parse --short=7 HEAD).Trim()
Write-Host "현재 Head: $head"

if ($head -ne "<EXPECTED-HEAD>") {
    throw "예상 Head는 <EXPECTED-HEAD>이지만 현재 Head는 $head입니다."
}

& $runner -ExpectedHead $head -ConfigPath $config
```

## 8. Evidence와 판정

각 Phase는 Manifest의 `summaryToken`과 `passRegex`를 사용한다.

- Summary 없음: `incomplete`
- Summary 존재, PASS 계약 불일치: `fail`
- PASS 계약 일치: `pass`
- `-NoOpen`: `prepared`

출력:

```text
%TEMP%\RVTT-Grand-Persistence\<timestamp>-<head>\
RVTT-grand-persistence-report.json
RVTT-grand-persistence-report.md
```

## 9. 실패와 정리

- 첫 실패에서 Runner 전체를 중단하지 않는다.
- Verify·Cleanup Summary가 없으면 Key가 정리됐다고 가정하지 않는다.
- Production Lease Verify가 `cleanup=true`를 출력하지 않으면 Acceptance Key를 수동 확인한다.
- 실제 Campaign Store를 대상으로 재실행하지 않는다.
- 실패 수정 후 선택 Phase만 Release Evidence로 사용하지 않고 전체 7단계를 다시 실행한다.

## 10. 완료 조건

```text
설정 Validation PASS
→ 8개 Project Upload PASS
→ 7개 Run Summary 수집
→ failed=0
→ incomplete=0
→ Production Lease Verify cleanup=true
→ JSON·Markdown Report 보존
```

즉시 구현 명세 가능성: READY
