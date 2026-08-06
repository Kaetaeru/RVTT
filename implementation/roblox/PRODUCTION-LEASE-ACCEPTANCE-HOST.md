# Production Lease Integration Acceptance Host

- 상태: `STATIC_VALIDATION_PENDING`
- 목적: 실제 Campaign Store를 건드리지 않고 Production `ServerBoot`의 Lease Ownership·Atomic Fence Claim·Fenced Flush·Release를 게시된 Studio 환경에서 검증한다.
- Seed Project: [`production-lease-seed.project.json`](production-lease-seed.project.json)
- Verify Project: [`production-lease-verify.project.json`](production-lease-verify.project.json)

## 안전 경계

두 Place는 다음 Acceptance 전용 값만 사용한다.

```text
Authority Store
→ RVTT_ProductionLeaseAcceptance_Authority_v1

Lease Store
→ RVTT_ProductionLeaseAcceptance_Lease_v1

Authority Key
→ acceptance:production-lease:default

Seed Owner
→ acceptance:production-lease:seed

Verify Owner
→ acceptance:production-lease:verify
```

`ServerBoot`는 Acceptance Phase가 설정되면 Studio 실행과 위 접두사를 강제한다. 실제 `RVTT_Authority_v1`·`campaign:default` 조합으로는 Acceptance Mode를 실행할 수 없다.

## Seed 실행

```text
Acceptance Key Cleanup
→ Production ServerBoot Lease Acquire
→ Atomic Fence Claim fence=1
→ 실제 Remote session.join
→ Authority Revision Commit
→ Studio 종료
→ BindToClose Fenced Flush
→ Seed Fence Metadata 기록
→ Lease Release
```

성공 Summary:

```text
[RVTT Production Lease Seed] result=PASS failed=0 checks=true flush=true metadata=true release=true ...
```

## Verify 실행

```text
Production ServerBoot Lease Acquire
→ Higher Fence Claim
→ Seed Membership Restore
→ 실제 Remote session.join
→ 이전 Seed Fence로 Revision 99 지연 저장 시도
→ PERSISTENCE_FENCED
→ 현재 Authority Revision·Fence 불변 확인
→ Studio 종료
→ Fenced Flush
→ Lease Release
→ Authority·Metadata·Lease Key Cleanup
```

성공 Summary:

```text
[RVTT Production Lease Verify] result=PASS failed=0 checks=true flush=true release=true cleanup=true staleBlocked=true ...
```

## 자동 Gate

- 두 Project JSON 계약과 안전 Store·Key 접두사
- Seed·Verify 동일 Store·Authority Key와 서로 다른 Owner
- 실제 `session.join` Remote Command·Sync Projection
- Seed Fence 1과 Verify Higher Fence
- 이전 Fence Revision 99 저장의 `PERSISTENCE_FENCED`
- Flush-before-Release와 Verify Cleanup-after-Release
- Grand Manifest Seed→Verify 순서·Summary Regex
- StyLua·Selene·Rojo Build·Luau Type

자동 Gate가 통과해도 실제 Studio Runtime PASS를 뜻하지 않는다. Runtime Evidence는 Grand Persistence Milestone에서만 기록한다.
