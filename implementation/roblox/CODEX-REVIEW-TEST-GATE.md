# Codex Stabilization·Review Gate

- 상태: `ACTIVE · STAGED_BY_CURRENT_EXECUTION_GATE`
- 최종 갱신일: 2026-08-13
- 상위 정책: [`Codex 구현·검수 정책`](../../docs/remake/product/codex-supervised-review-and-test-policy.md)
- Studio MCP: [`ROBLOX-STUDIO-MCP-TEST-POLICY.md`](ROBLOX-STUDIO-MCP-TEST-POLICY.md)
- 실행 규칙: [`EXECUTION-TEST-RULES.md`](EXECUTION-TEST-RULES.md)

이 문서는 모든 작은 반복을 막는 Gate가 아니라 Stabilization·고위험 변경·Merge·Release용 Review Gate다. 다만 **어떤 반복이 허용되는지는 현재 execution gate가 먼저 결정한다.**

## 1. 현재 R3

```text
R3 = VALIDATED · NOT FROZEN
SOURCE = BLOCKED
STUDIO/MCP = BLOCKED
```

현재는 Studio 반복이 기본 개발 모드가 아니다. planning validation과 합의된 방향 안의 정합성 fix만 수행한다.

## 2. E0 반복

R4 E0 Checkpoint Freeze와 Dedicated Implementation Branch 이후에는 별도 독립 Review 없이도 frozen contract 안의 작은 Repository 구현·focused test 반복을 진행할 수 있다.

```text
GitHub current Authority
→ frozen E0 contract
→ greenfield Repository 구현
→ focused automated test
→ 즉시 수정
```

Architecture/Authority 변경이 필요하면 사용자에게 먼저 올린다.

## 3. E1 Studio 반복

`CORE_ENGINE_COMPLETE` 후 E1 Runtime Checkpoint가 Freeze되면 Studio/MCP 직접 구현·Play 반복을 활성화한다.

```text
GitHub current Authority
→ frozen E1 contract
→ Studio MCP 구현
→ Play
→ Focused 수정
→ GitHub greenfield Source 정규화
```

## 4. 독립 Review가 필요한 경우

- Accepted ADR·Product Authority 변경
- Authority·State ownership·핵심 System/Module responsibility 변경
- 서버 Authority·Permission·Security·Disclosure 변경
- Persistence·Migration·Rollback·Lease 변경
- 공개 Schema·Package·Stable ID 계약 변경
- Merge·Release 후보
- 사용자가 Review를 요청한 경우

## 5. Review 절차

```text
정확한 PR·Target SHA 확인
→ Current Authority와 변경 범위 검수
→ Finding 게시
→ Finding Triage
→ 필요한 수정
→ Focused Delta Review
```

Finding이 현재 합의 방향 안의 명백한 bug/validator/current-state drift라면 즉시 수정할 수 있다. Product/ADR/Authority/개발 순서 변경은 사용자 결정이 필요하다.

## 6. Evidence

Planning/static, Repository test, legacy regression, E1 Studio runtime, Human UX, Multi-client, Persistence, Performance, Release evidence를 구분한다. Legacy implementation Workflow PASS를 새 Greenfield 구현 PASS로 해석하지 않는다.
