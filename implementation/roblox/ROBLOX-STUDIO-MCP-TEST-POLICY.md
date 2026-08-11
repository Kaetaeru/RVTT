# Roblox Studio MCP 개발·Runtime 정책

- 상태: `ACTIVE_DEFAULT_DEVELOPMENT_PATH`
- 최종 갱신일: 2026-08-12
- 상위 규칙: [`AGENTS.md`](../../AGENTS.md)
- Pre-G0 Gate: [`GREENFIELD-PREFLIGHT.md`](GREENFIELD-PREFLIGHT.md)
- 실행 규칙: [`EXECUTION-TEST-RULES.md`](EXECUTION-TEST-RULES.md)
- Module 규칙: [`MODULE-CONTRACTS.md`](MODULE-CONTRACTS.md)

## 1. 목적

Roblox Studio MCP를 RVTT의 **직접 구현·실행·관찰 환경**으로 사용한다. MCP는 Release 테스트만 돌리는 도구가 아니라 Codex가 GitHub의 현재 Greenfield 구조를 이해한 뒤 실제 Studio 결과물을 만들고 빠르게 수정하기 위한 개발 도구다.

```text
GitHub Authority 조사
→ Greenfield Workbench 확인
→ Module Contract 확인
→ Studio Capability Handshake
→ 직접 구현
→ Play
→ 관찰
→ 수정
→ greenfield/src + Contract 정규화
```

## 2. Pre-G0 Workbench 확인

첫 G0 실행 전에 `GREENFIELD-PREFLIGHT.md`를 따른다.

현재 Greenfield 기준:

```text
Rojo Project = implementation/roblox/greenfield.project.json
Source       = implementation/roblox/greenfield/src
Tests        = implementation/roblox/greenfield/tests
```

다음은 Legacy Reference다.

```text
implementation/roblox/default.project.json
implementation/roblox/src
```

Greenfield 구현을 시작할 때 기존 Production Place/UI를 Baseline으로 이어 고치지 않는다. 현재 Studio가 Legacy Place인지 Greenfield Workbench인지 먼저 식별한다. 판별할 수 없으면 수정하지 않고 `HUMAN_REQUIRED` 또는 `BLOCKED`로 보고한다.

## 3. Capability Handshake

Studio 작업 시작 시 실제 제공 Tool을 확인한다. Tool 이름을 미리 있다고 가정하지 않는다.

확인할 대표 Capability:

```text
Place·Session 확인
Instance Tree 읽기
Instance 생성·수정·삭제
Script Source 읽기·수정
Play Start·Stop
Server·Client Output 읽기
Attribute·Property 읽기
Screenshot 또는 화면 상태 확인
Multi-client 실행 여부
Local Save·Export 여부
```

각 항목은 다음 중 하나로 분류한다.

```text
MCP_AVAILABLE
HUMAN_REQUIRED
UNAVAILABLE
```

없는 Capability를 사용한 것처럼 보고하지 않는다. G0 시작 판단에 필요한 최소 Capability와 fallback 규칙은 `GREENFIELD-PREFLIGHT.md`가 소유한다.

## 4. 구현 전 GitHub 조사

Codex는 Studio를 수정하기 전에 관련 GitHub Authority, Module Contract와 현재 Greenfield Source를 읽는다.

필수 확인:

- 현재 Branch·PR·HEAD
- `GREENFIELD-PREFLIGHT.md`와 `greenfield-boundary.json`
- Product·ADR·UI·Spec Authority
- `manifests/module-contracts.json`의 대상 Module Entry
- 대상 Module의 Responsibility·Stable Entry Point·Contract-level dependency·Authority·State ownership
- 현재 `greenfield/src`의 실제 Source와 `require()` 관계
- 필요한 Legacy Source — 읽기 참고만
- 관련 Focused Test

`dependsOn`은 모든 `require()`를 복제한 목록이 아니다. 정확한 내부 호출 관계와 helper 함수 구조는 현재 Source에서 확인한다.

Module Contract와 Source가 어긋나면 `CONTRACT_DRIFT`로 취급한다. 기존 책임을 찾지 않고 새 Manager, Remote, Registry 또는 병렬 Script를 만들지 않는다.

## 5. Studio 직접 구현

MCP가 허용하는 범위에서 Codex는 Greenfield Workbench에서 직접 다음을 수행할 수 있다.

- 실제 UI Hierarchy 구성
- Instance Property와 Layout 조정
- Greenfield Script 연결
- Script Source 수정
- Token·Camera·World Object 구성
- Test Fixture 구성
- Play 실행
- Output·Runtime State 확인
- 결함 즉시 수정

작업 단위는 작은 사용자 흐름 하나를 권장한다.

```text
구현
→ Play
→ 확인
→ 수정
→ 다시 Play
```

private/helper 함수의 분해와 내부 호출 순서는 현재 문제를 가장 단순하게 해결하도록 Codex가 판단할 수 있다. 단, Module의 안정적인 책임·Authority·State ownership이나 다른 Contract-bearing Module과의 경계를 바꾸는 수정은 Contract 변경이다.

## 6. Studio와 GitHub 동기화

Studio는 작업장이고 GitHub Greenfield Source는 Canonical Source다.

작업이 안정되면:

1. Studio에서 확정된 Script Source를 `greenfield/src`의 올바른 Module로 반영한다.
2. 필요한 Instance 구조를 `greenfield.project.json`과 Source Mapping으로 표현한다.
3. Module의 안정 책임, Stable Entry Point, Contract-level dependency, Authority 또는 State ownership이 바뀌었으면 `manifests/module-contracts.json`을 갱신한다.
4. private/helper 함수만 바뀌었다면 수동 Call Graph 문서를 만들지 않는다.
5. 임시 Studio-only Object와 우회 코드를 제거한다.
6. Clean Source에서 `rojo build greenfield.project.json` 또는 Sync로 재현 가능한지 확인한다.
7. 관련 `greenfield/tests` Focused Test와 Contract/Boundary Validator를 실행한다.

Legacy `src`와 `default.project.json`은 이 동기화 경로의 대상이 아니다.

## 7. 사용자 판단

다음은 사용자에게 직접 확인받을 수 있다.

- 입력 감각
- Camera 감각
- UI 크기·가독성
- 정보 밀도
- DM 작업 부담
- 게임 흐름·리듬
- 재미와 만족도

MCP는 상태를 준비하고 Evidence를 수집할 수 있지만 Human Judgment를 대신하지 않는다.

## 8. 새로운 방향 발견 시

Codex가 구현 중 더 좋은 제품 방향, Architecture, 핵심 UX, 개발 방식, 범위 또는 Greenfield/Legacy 경계 변경을 발견하면 직접 적용하지 않는다.

다음을 보고한다.

```text
현재 문제
제안 방향
기대 효과
비용·위험
영향받는 Authority·Module Contract·Source
```

사용자 승인 후에만 변경한다.

## 9. Development Runtime과 Stabilization Runtime

### Development Runtime

- 빠른 Play와 수정용
- Commit SHA 고정 필수 아님
- Focused Observation 허용
- Evidence Bundle 필수 아님

### Stabilization Runtime

- 기능이 Source와 필요한 Module Contract에 정규화된 뒤 수행
- 정확한 Branch·SHA 기록
- 실행 범위와 예상 결과 명시
- 필요한 Log·Screenshot·State 보존

### Release Runtime

- Multi-client, Persistence, Migration, Accessibility, Performance, Grand Acceptance 등 필요한 Gate 수행
- 실행하지 않은 범위를 PASS로 확대하지 않음

## 10. 실패 처리

다음이면 현재 실행을 중단하고 원인을 먼저 고친다.

- Studio crash
- unhandled runtime error
- Authority·Permission leak
- DataStore mode 오사용
- MCP disconnect로 결과가 불완전함
- 수정한 흐름을 재현할 수 없음
- Contract-bearing Module의 Source와 Contract가 모순됨
- Legacy Source/Project Lock이 깨짐
- 현재 Studio Workbench가 Legacy인지 Greenfield인지 판별 불가

개발 단계에서는 해당 흐름만 빠르게 재실행한다. 전체 Release Campaign 재실행은 Release Candidate에서 수행한다.

## 11. MCP가 없을 때

MCP 연결이 없으면 GitHub Greenfield Source + Rojo + 일반 Studio 실행으로 작업할 수 있다. 다만 MCP로 Studio를 직접 확인했다고 주장하지 않는다.

MCP 부재는 제품 개발 전체를 자동 Block하지 않지만, `GREENFIELD-PREFLIGHT.md`의 최소 검증 경로조차 확보할 수 없으면 G0를 시작하지 않는다.
