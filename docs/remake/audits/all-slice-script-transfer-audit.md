# All-slice Script Transfer Audit

- 상태: `IMPLEMENTED_UNVERIFIED`
- 감사일: 2026-08-05
- 구현 Root: `implementation/roblox/`
- Script Manifest: `implementation/roblox/manifests/all-slices-script-manifest.md`

## 결과

16개 Slice 계약을 Greenfield Roblox Service 구조의 Runtime·Domain·Client·UI·Test Source로 이전했다.

```text
Luau Source·Test
→ 76 files

Domain Script
→ 18 files

Registered Command
→ 53 commands

Explicit Authorization
→ 53 / 53
```

## 보안·권위 검수

- 모든 Remote Command가 명시적 Authorization을 가진다.
- Character·Actor·Item Ownership과 Runtime Controller를 구분한다.
- Movement·Interaction·Attack·Turn End는 제어 가능한 Actor만 요청할 수 있다.
- D20 Modifier·DC·AC·Damage는 Client Payload가 아니라 Server State에서 계산한다.
- System-only Command는 Remote Client가 호출할 수 없다.
- Player Projection에서 DM Workspace·Scene Source·비공개 Character 세부 정보를 제거한다.
- `_G`, `shared`와 UI Component의 Remote 직접 호출을 금지한다.

## Persistence·Recovery

- Schema Migration Registry
- DataStore Adapter
- Debounced Persistence Coordinator
- In-memory Snapshot Journal
- AuthorityEpoch 재발급 Restore·Rollback
- Projection Sequence Gap 감지와 Full Resync

실제 DataStore·Server Restart·Rollback은 Roblox 환경에서 아직 검증하지 않았다.

## Test Source

- Core·Envelope Unit Spec
- Domain Registration과 Authorization Spec
- Authority Idempotency Flow Spec
- Security Boundary Spec
- Projection Negative Disclosure Spec
- Static Structure·Policy Validator

## 판정

```text
계약의 Script 구조 이전
→ COMPLETE

정적 보안·구조 검사
→ PASS

Roblox Studio·DataStore·Physics·UI·Performance
→ UNVERIFIED

공식 D&D Data
→ BLOCKED BY SOURCE·RIGHTS REVIEW
```

따라서 상태는 `IMPLEMENTED_UNVERIFIED`이며 Release Ready가 아니다.
