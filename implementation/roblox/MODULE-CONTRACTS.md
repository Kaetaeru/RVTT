# RVTT Module Contracts

- 상태: `ACTIVE · GREENFIELD_V2`
- 최종 갱신일: 2026-08-12
- 현재 Registry: [`manifests/module-contracts.json`](manifests/module-contracts.json)
- Legacy Reference: [`manifests/legacy-module-contracts.json`](manifests/legacy-module-contracts.json)
- Validator: [`tooling/validate_module_contracts.py`](tooling/validate_module_contracts.py)

## 1. 두 Registry의 역할

### `module-contracts.json`

현재 새 RVTT의 **목표 Architecture**다. Source가 생기기 전에 `PLANNED` 상태로 책임을 먼저 정의한다.

### `legacy-module-contracts.json`

기존 Production Source의 구조를 보존한 역사적 Reference다. 현재 Greenfield 구현의 Authority가 아니며 자동 TODO나 재사용 목록이 아니다.

## 2. Lifecycle

```text
PLANNED
→ IMPLEMENTED
→ ACCEPTED
→ DEPRECATED
```

- `PLANNED`: 책임·경계·예정 경로가 합의됐고 Source는 없어도 된다.
- `IMPLEMENTED`: 실제 Source와 Stable Entry Point가 존재하고 Studio에서 연결됐다.
- `ACCEPTED`: 사용자가 해당 Checkpoint/기능을 수용했고 Focused Test까지 정규화됐다.
- `DEPRECATED`: 새 구조에서 더 이상 사용하지 않는다.

## 3. Module Contract 필드

```text
id
status
plannedPath
kind
responsibility
entryPoints
dependsOn
authority
stateOwnership
legacyCandidates
testRefs
```

`dependsOn`은 Architecture-level 의존만 기록한다. 모든 `require()`를 복제하지 않는다.

`legacyCandidates`는 참고할 수 있는 이전 Source 경로다. 재사용 의무를 뜻하지 않는다.

## 4. System-first 원칙

보이는 기능을 만들기 전에 그 기능을 책임지는 경계를 먼저 `PLANNED`로 만든다.

Bootstrap은 별도 계약을 가지지만 Composition Root 역할만 한다.

```text
Bootstrap
→ App Composition
→ System/Controller/Runtime
```

한 Bootstrap이나 Manager에 기능을 몰아서 Contract 수를 줄이는 것을 최적화로 보지 않는다.

반대로 현재 Checkpoint와 무관한 미래 시스템을 미리 계약하지 않는다.

## 5. Source 정합화

`IMPLEMENTED` 또는 `ACCEPTED` Module은:

- `greenfield/src/` 아래 실제 Source가 존재해야 한다.
- Stable Entry Point Token이 Source에 존재해야 한다.
- `dependsOn` 대상이 Registry에 존재해야 한다.
- 선언한 Focused Test가 있으면 실제 파일이 존재해야 한다.

`PLANNED` Source는 아직 없어도 된다.

## 6. 사용자 결정 Gate

Module 책임을 실질적으로 새로 분리하거나 합치려면 Product/Architecture 영향 여부를 확인한다.

- 현재 계약 안의 helper 분해: 즉시 가능
- Architecture 경계 변경: 사용자에게 먼저 제안

## 7. Legacy 재사용

Codex는 `legacyCandidates`를 다음 순서로 본다.

```text
역할 확인
→ 현재 Contract와 비교
→ 좋은 부분만 선택
→ Greenfield 구조에 맞게 조립
```

Legacy의 파일 구조와 Manager 구성을 복제하는 것이 목표가 아니다.

## 8. Call Graph

private/helper 호출 순서와 모든 `require()` 관계는 현재 Source에서 읽는다. 수동 Call Graph를 별도 Authority로 유지하지 않는다.
