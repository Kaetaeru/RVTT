# RVTT System & Stable Function Contracts

- 상태: `ACTIVE · GREENFIELD_CODE_BOUNDARY_AUTHORITY`
- 최종 갱신일: 2026-08-12
- Registry: [`manifests/system-function-contracts.json`](manifests/system-function-contracts.json)
- Module Registry: [`manifests/module-contracts.json`](manifests/module-contracts.json)
- 시스템 순서: [`GREENFIELD-SYSTEM-SEQUENCE.md`](GREENFIELD-SYSTEM-SEQUENCE.md)

이 문서는 **시스템이 왜 존재하고, Module이 누구와 연결되며, 다른 Module이 호출할 수 있는 안정 함수가 어떤 의미를 갖는지**를 소유한다.

## 1. 설계 깊이

Greenfield 구현은 다음 네 층으로 설계한다.

```text
System Contract
→ Module Contract
→ Stable Function Contract
→ Private/Internal Implementation
```

- **System Contract**: 사용자 기능 또는 기반 시스템의 책임, Authority, state owner, input/output, invariant, Module flow.
- **Module Contract**: 파일 경계, 책임, dependency, Authority, state ownership, stable entry point index.
- **Stable Function Contract**: 다른 Contract-bearing Module이 의존할 수 있는 함수의 입력, 출력, 권한, read/write, side effect, failure, idempotency, validation, permission, revision 의미.
- **Private/Internal Implementation**: helper 분해, local function, 정확한 내부 call graph. 현재 Source에서 읽으며 수동 Authority로 만들지 않는다.

## 2. 선언 시점

구현보다 계약이 먼저다.

```text
다음 Checkpoint 확정
→ 필요한 System Contract 확인/추가
→ 필요한 Module Contract 확인/추가
→ Stable Function Contract 확인/추가
→ Contract Validator
→ Source 구현
→ Studio Play
```

아직 가까운 구현 대상이 아닌 P2~P10 시스템의 내부 Module/함수를 상상으로 대량 생성하지 않는다. 큰 제품 순서는 미리 고정하지만 **구체 Module/Function 계약은 해당 시스템이 현재 또는 다음 구현 범위에 들어오기 직전에 작성한다.**

현재 Registry는 Foundation G0~G5와 Exploration S1/C1/M1/X1/I1에 필요한 범위를 완전하게 선언한다.

## 3. Stable Function의 기준

다음 중 하나면 Stable Function Contract가 필요하다.

- 다른 Contract-bearing Module이 호출한다.
- Bootstrap/App이 lifecycle 또는 composition을 위해 호출한다.
- Test가 안정 경계로 직접 호출해야 한다.
- Server Authority, transport, projection, persistence 같은 중요한 경계를 통과한다.
- 반환값/side effect/failure 의미가 Architecture의 일부다.

다음은 Stable Function Contract가 아니다.

- 한 Module 내부에서만 쓰는 local/private helper.
- 구현 편의를 위한 작은 변환 함수.
- 호출 그래프를 설명하기 위해 억지로 노출한 함수.
- 실제 필요가 확인되지 않은 미래 API.

## 4. Cross-Module 호출 규칙

Contract-bearing Module A가 Module B의 함수를 호출한다면 그 함수는 B의 `functionContracts`에 먼저 존재해야 한다.

```text
undeclared cross-module call
= CONTRACT_DRIFT
```

Codex는 구현 중 필요해진 안정 함수가 Registry에 없으면 private helper처럼 몰래 추가하지 않는다.

- 기존 Architecture 의미 안에서 필요한 명백한 API 보완이면 Contract를 먼저 갱신하고 구현한다.
- Authority, state owner, Module 책임, 시스템 흐름을 바꾸는 API라면 사용자에게 먼저 제안한다.

## 5. Function Contract 필드

각 안정 함수는 다음을 가진다.

```text
name
kind
purpose
inputs
output
authority
reads
writes
sideEffects
failureModes
idempotency
validation
permission
revisionBehavior
```

### `kind`

함수의 Architecture 역할을 나타낸다. 예: `CONSTRUCTOR`, `LIFECYCLE`, `VALIDATOR`, `QUERY`, `MUTATION`, `AUTHORIZATION`, `REGISTRATION`, `COMMAND`, `TRANSPORT`, `SUBSCRIPTION`, `PROJECTION`.

### `authority`

함수가 결정을 내릴 수 있는 범위를 나타낸다. Module Authority보다 강할 수 없다.

### `reads` / `writes`

무엇을 읽고 누가 소유한 상태를 쓰는지 명시한다. 특히 Server authoritative state와 client-local state를 섞지 않는다.

### `sideEffects`

Remote 전송, Instance 변경, subscription, authoritative mutation처럼 함수 호출 밖에서 관찰되는 효과를 기록한다.

### `failureModes`

정상적으로 거부되어야 하는 조건을 기록한다. 실패를 성공처럼 삼키지 않는다.

### `idempotency`

재호출 의미를 명시한다. `PURE`, `READ_ONLY`, `CONSTRUCTOR`, `IDEMPOTENT`, `REPEAT_SAFE`, `NOT_IDEMPOTENT`, `REGISTRATION`, `LIFECYCLE` 중 하나다.

### `validation` / `permission`

입력 검증과 호출 권한의 위치를 명시한다. Client가 보낸 권한 주장을 Function Contract로 승격하지 않는다.

### `revisionBehavior`

world/projection revision을 읽거나 검증하거나 증가시키는 의미를 명시한다. Revision과 무관하면 `none`이다.

## 6. Module Surface

`moduleFunctionContracts`의 `surface`는 다음 중 하나다.

- `CALLABLE_MODULE`: Stable Function이 존재하는 Module.
- `DATA_ONLY_MODULE`: Runtime callable API 없이 데이터/상수/type-shape 역할만 한다.
- `AUTO_EXEC_SCRIPT`: Roblox Script/LocalScript entrypoint이며 별도 공개 함수가 없다. `scriptEntrypoint`로 실행 책임을 기록한다.

Bootstrap은 `AUTO_EXEC_SCRIPT`다. Bootstrap에 gameplay function을 추가하지 않는다.

## 7. entryPoints 관계

`module-contracts.json`의 `entryPoints`는 빠른 탐색을 위한 **요약 인덱스**다.

실제 함수 의미 Authority는 `system-function-contracts.json`의 `functionContracts`다.

Validator는 다음을 강제한다.

```text
Module.entryPoints
== 해당 Module의 Function Contract name 목록
```

따라서 이름 목록과 함수 의미 계약이 따로 drift할 수 없다.

## 8. 구현 자유도

Stable Function Contract가 같다면 Codex는 다음을 자유롭게 결정할 수 있다.

- private/local helper 개수와 이름
- 내부 자료구조
- 순수 계산 분해
- local caching
- 같은 Module 내부 호출 순서

단, 다음은 자유도가 아니다.

- Stable Function 의미 변경
- 입력/출력 계약 변경
- Authority 또는 state owner 변경
- side effect 추가
- 실패를 성공으로 변경
- revision 의미 변경
- 다른 Module이 private helper를 직접 호출하도록 노출

## 9. 사용자 수정과 확정

사용자가 Studio에서 같은 기능을 여러 번 수정하게 하는 동안 private 구현은 빠르게 바꿀 수 있다.

수정 때문에 Stable Function Contract가 달라져야 하지만 Product/Architecture 의미는 그대로라면 현재 Checkpoint 안에서 Contract를 함께 갱신할 수 있다.

반면 Authority/state owner/Module 책임/System flow가 달라져야 한다면 자동 적용하지 않고 사용자에게 먼저 제안한다.

사용자가 기능을 최종 수용하면 `AUTHORITY-RECONCILIATION-POLICY.md`의 Impact Scan에 **System Contract와 Stable Function Contract**도 포함한다. 최종 Source와 계약이 맞아야 Checkpoint Promotion Commit을 만들 수 있다.

## 10. 검증 목표

`validate_module_contracts.py`는 최소 다음을 검사한다.

- 현재 Module마다 Function Contract record가 정확히 하나 존재.
- `entryPoints`와 안정 함수 이름이 1:1 일치.
- Function 이름/종류/Authority/idempotency/필수 의미 필드가 유효.
- System Contract가 존재하는 Module만 참조.
- 현재 Contract-bearing Module이 최소 하나의 System Contract에 포함됨.
- IMPLEMENTED/ACCEPTED Module의 안정 함수 token이 Source에서 사라지지 않음.
- 기존 Stage/Checkpoint/technicalSafety 검증 유지.

Validator는 private helper 이름이나 private call graph를 검사하지 않는다.
