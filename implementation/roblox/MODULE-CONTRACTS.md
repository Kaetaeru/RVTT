# RVTT Module Contracts

- 상태: `ACTIVE`
- 최종 갱신일: 2026-08-12
- 기계 가독 레지스트리: [`manifests/module-contracts.json`](manifests/module-contracts.json)
- 검증기: [`tooling/validate_module_contracts.py`](tooling/validate_module_contracts.py)

이 문서는 RVTT Production Module의 **안정적인 책임과 경계**를 정의하는 규칙이다. 코드의 모든 함수 호출 순서를 문서로 복제하지 않는다.

## 1. 목적

Codex가 Roblox Studio에서 작업할 때 다음을 빠르게 알 수 있어야 한다.

```text
이 Module은 무엇을 책임지는가
어떤 안정적인 Entry Point가 있는가
어떤 Contract-bearing Module에 의존하는가
Authority는 어디에 있는가
어떤 상태를 소유하는가
어떤 Test가 직접 연결되는가
```

반대로 private/helper 함수의 정확한 분해, 내부 호출 순서, 일시적인 구현 세부는 현재 Source에서 읽는다.

## 2. 권위 경계

`module-contracts.json`은 Product·ADR·Architecture보다 위에 있지 않다.

권위 순서:

```text
사용자의 최신 결정
→ Accepted ADR / Product / Architecture
→ Implementation Spec
→ Module Contract
→ 현재 Production Source
```

Module Contract는 **코드 구조의 의도된 안정 경계**를 소유한다. Product 의미를 새로 만들지 않는다.

Source와 Module Contract가 어긋나면 한쪽을 자동으로 정답 처리하지 않는다. `CONTRACT_DRIFT`로 보고 실제 의도와 Source를 확인한 뒤 둘을 함께 정리한다.

## 3. 등록 대상

다음 중 하나에 해당하면 Contract-bearing Module로 등록한다.

- Server Runtime, Command Registry, Transaction 경계
- `*Domain.lua`처럼 Authoritative Command를 소유하는 Domain
- Viewer Projection 경계
- Persistence·Migration 경계
- Rules Resolver와 Content Security·Disclosure 경계
- Client Runtime·Transport·Projection Replica
- Input Context·Semantic Input·World Controller
- 여러 Module이 공유하는 Protocol·World Contract
- 다른 Module이 안정적으로 의존해야 하는 Registry·Coordinator·Policy

단순 leaf renderer, 작은 pure helper, 한 Module 내부에서만 사용되는 private helper는 반드시 등록할 필요가 없다.

## 4. 레지스트리 필드

각 Module Entry는 다음을 가진다.

```text
id
path
kind
responsibility
entryPoints
dependsOn
authority
stateOwnership
testRefs
```

### `entryPoints`

다른 코드나 Codex가 구조를 이해할 때 알아야 하는 **안정적인 Entry Point만** 적는다. 모든 public-looking 함수 목록이 아니다.

내부 구현 변경으로 Entry Point가 필요 없어지면 Source와 Contract를 함께 수정한다.

### `dependsOn`

Architecture를 이해하는 데 의미가 있는 Contract-level 의존만 적는다. 모든 `require()`를 복제하지 않는다.

정확한 현재 require graph가 필요하면 Source에서 생성하거나 검색한다.

### `authority`

Module이 상태와 결정에 대해 갖는 권한을 표시한다. Client Module이 `client_intent_only`라면 서버 권한을 대신할 수 없다.

### `stateOwnership`

Module이 소유하거나 유지하는 상태 의미를 적는다. `none`이라는 의미도 명시할 수 있다.

### `testRefs`

해당 Contract를 직접 보호하는 Focused Test만 연결한다. 전체 Release Harness를 무조건 연결하지 않는다.

## 5. 수동 Call Graph 금지

다음과 같은 문서는 유지하지 않는다.

```text
foo()
→ bar()
→ baz()
→ helperA()
→ helperB()
```

이 구조는 Source 변경과 동시에 낡기 쉽다.

필요한 경우 Codex는 현재 Source에서 다음을 즉석 조사한다.

```text
require graph
function references
Remote submission path
signal connection path
command registration path
projection path
```

장기적으로 자동 Call Graph 도구가 필요해지면 Source에서 생성하는 방식만 사용한다. 수동 Call Graph를 Authority로 만들지 않는다.

## 6. Codex 구현 순서

Studio 작업 전:

1. 관련 Product·ADR·Implementation Spec을 읽는다.
2. `module-contracts.json`에서 대상 Module과 직접 의존 Module을 찾는다.
3. 해당 Source를 직접 읽어 현재 함수와 실제 require 관계를 확인한다.
4. Studio MCP로 실제 Instance·Script·Runtime 상태를 확인한다.
5. 기존 책임을 재사용해 작은 사용자 흐름을 구현한다.

작업 후:

1. Studio 결과를 GitHub Source에 정규화한다.
2. Module의 안정 책임, Entry Point, Contract-level dependency, Authority 또는 State ownership이 바뀌었으면 `module-contracts.json`도 갱신한다.
3. private/helper 함수만 바뀌었고 안정 경계가 그대로면 Contract를 억지로 수정하지 않는다.
4. `validate_module_contracts.py`를 통과시킨다.

## 7. Coverage

레지스트리의 `coverage`는 현재 반드시 Contract로 추적할 Source 범위를 지정한다.

- `requiredGlobs`: 한 종류 전체를 추적해야 하는 경계
- `requiredPaths`: 개별적으로 반드시 추적해야 하는 경계

Coverage에서 빠진 모든 `.lua`가 중요하지 않다는 뜻은 아니다. 새 Module이 Contract-bearing 책임을 가지게 되면 Coverage와 Module Entry에 추가한다.

Coverage 자체를 줄이는 변경은 일반 코드 정리가 아니라 Contract 변경으로 취급한다.

## 8. CI가 검사하는 것

CI는 다음을 검사한다.

- JSON Schema 기본 형식
- Module ID와 Source Path 중복
- 등록 Source 존재 여부
- Coverage 누락
- `dependsOn` 대상 존재 여부
- Test Reference 존재 여부
- 선언된 Stable Entry Point Token이 Source에서 사라졌는지
- 허용된 Module Kind·Authority 값

CI는 다음을 검사하지 않는다.

- 문서 문장 그대로의 존재
- private/helper 함수 호출 순서
- 모든 `require()`의 완전한 복제
- 제품 UX의 품질
- Runtime PASS 여부

## 9. 변경 원칙

Module Contract는 구현을 굳히는 문서가 아니라 **중복 구현과 책임 혼선을 막는 최소 설계도**다.

현재보다 더 좋은 Architecture나 책임 분리가 필요하다고 판단되면 자동 적용하지 않는다. 문제, 제안 경계, 영향받는 Module과 Migration 비용을 사용자에게 먼저 설명하고 승인받은 뒤 Contract와 Source를 변경한다.
