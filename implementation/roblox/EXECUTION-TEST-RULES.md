# RVTT 개발·실행·검증 규칙

- 상태: `ACTIVE`
- 최종 갱신일: 2026-08-12
- 목적: Studio-first 개발과 Release 검증을 분리해 빠른 제품 반복과 재현 가능한 품질 검증을 모두 유지한다.

## 1. 기본 개발 흐름

Roblox 기능 개발의 기본은 **Studio-first development**다.

```text
GitHub Source·함수 책임 조사
→ Roblox Studio MCP로 현재 Place 조사
→ 실제 기능을 Studio에서 구현·연결
→ Development Loop: Play → 관찰 → 수정 → 다시 Play
→ 사용자 판단이 필요한 부분 확인
→ GitHub Source로 정규화
→ Stabilization
→ Release Acceptance
```

개발 중 작은 수정마다 Acceptance Build, 전체 CI, Grand Campaign 또는 사용자의 수동 배치를 선행조건으로 요구하지 않는다.

## 2. Development Loop

한 번에 작은 사용자 흐름 하나를 다룬다.

예:

```text
Token 선택
Move
Attack
Character Console
Inventory
Journal
DM Window
```

순서:

1. 관련 Product·ADR·Source·Test를 읽는다.
2. 기존 Module과 함수의 책임을 확인한다.
3. Studio의 현재 Instance Tree와 Runtime 상태를 확인한다.
4. MCP로 실제 Script·UI·Instance를 연결하거나 수정한다.
5. Play한다.
6. Output, 화면, Instance 상태, Server·Client 결과를 확인한다.
7. 즉시 수정하고 필요한 만큼 반복한다.
8. 사용자가 판단해야 하는 조작 감각·가독성·흐름은 사용자에게 보여준다.

개발 Play는 빠른 피드백을 위한 관찰이다. Release Evidence가 아니다.

## 3. GitHub와 Studio의 관계

```text
GitHub = Canonical Source
Studio = 구현·조립·실행 환경
Rojo = Source↔DataModel 연결과 재현 도구
```

- Studio에서 직접 만든 Production 변경은 최종적으로 GitHub Source와 Project Mapping으로 표현한다.
- Studio에만 존재하는 Script, 필수 Instance, Attribute, 설정에 Production 동작을 의존하지 않는다.
- GitHub Source만으로 같은 구조를 재구성할 수 있어야 한다.
- Studio에서 실험 중인 임시 진단 Object는 정규화 전에 제거하거나 명확한 Test 전용 위치로 이동한다.

## 4. Rojo 규칙

Rojo를 적극 사용하되 역할을 개발 Gate와 혼동하지 않는다.

Rojo의 역할:

- Source Tree와 Roblox Service Mapping
- 필요 시 live sync
- Clean Source에서 Place 재현
- CI Build·Sourcemap 검증
- Test·Acceptance Place 생성

기능이 안정되기 전 매 Play마다 `.rbxlx`를 새로 Build해서 사용자에게 전달할 필요는 없다.

기능을 GitHub에 정규화하거나 Stabilization으로 넘길 때는 관련 Rojo Project가 Clean Source에서 Build되는지 확인한다.

## 5. Codex + Studio MCP

Codex Studio Implementer는 구현 시작 전에 GitHub를 읽는다.

최소 확인:

- 현재 Branch·PR
- 관련 Authority
- 대상 Module·함수
- 직접 연결된 Server/Client 경계
- 관련 Test

그 뒤 MCP Capability를 확인하고 가능한 범위에서 Studio를 직접 조작한다.

MCP가 제공하지 않는 기능은 추측하지 않는다. 자동화할 수 없는 Mouse·Keyboard 감각이나 시각 판단은 Human Action으로 남긴다.

상세 MCP 규칙은 `ROBLOX-STUDIO-MCP-TEST-POLICY.md`를 따른다.

## 6. Stabilization

사용자가 기능 방향을 받아들이거나 구현이 충분히 안정됐을 때 수행한다.

```text
Studio 상태를 Source에 정규화
→ Rojo 재현 확인
→ Formatter·Lint·Type
→ Unit·Integration·Security·Disclosure
→ 변경 영역 Focused Runtime
→ 필요한 Human 확인
```

이 단계부터 재현 가능한 결과에는 Branch와 정확한 Commit SHA를 연결한다.

CI가 실패하면 실패 원인을 고치고 관련 검증을 다시 수행한다. 개발 단계의 한 결함 때문에 Grand Campaign 전체를 매번 다시 돌리지 않는다.

## 7. Release Acceptance

다음은 Stabilization 또는 Release에서 사용하는 Gate다.

- Full UI·UX Acceptance Matrix
- Multi-client DM·Player·Observer
- Real Transport·Reconnect
- Persistence·Restart·Outage·Lease
- Migration·Rollback
- Accessibility
- Performance·Soak
- Grand Acceptance Campaign

이 Gate들은 제품 방향을 탐색하기 위한 개발 UI가 아니다.

Acceptance Harness는 실제 Production 경로의 회귀를 검증하기 위한 도구다. Harness가 사용하기 불편하다고 해서 Product UX를 Harness에 맞추지 않는다.

## 8. Focused Test와 Full Campaign

개발·수정 중:

```text
변경 영역 Focused Test
→ 필요한 Focused Studio Play
```

Release Candidate:

```text
자동 Gate 전체
→ 필요한 Human·Multi-client·Persistence
→ Grand Acceptance Campaign
```

수정 후 선택 Phase만 재실행해 원인을 빠르게 확인할 수 있다. 전체 Grand Campaign 재실행은 Release Candidate, 대규모 통합 변경 또는 사용자가 요청한 경우에 수행한다.

## 9. Human Test

Human Test가 필요한 대표 항목:

- 실제 Mouse·Keyboard 감각
- 화면 가독성
- 정보 계층 이해
- Camera 감각
- DM 진행 부담
- 전투·탐험 흐름
- 재미와 만족도

Codex와 MCP가 이 판단을 대신하지 않는다. 반대로 Human에게 자동화 가능한 정적·구조 검사를 반복해서 맡기지 않는다.

## 10. Persistence

일반 개발 Play에서는 필요하지 않으면 DataStore를 켜지 않는다.

Persistence 변경을 다룰 때는 별도 안전 환경에서 다음을 검증한다.

- Load·Save
- Dirty·Flush
- Restart Restore
- Reconnect
- Migration
- Conflict·Failure Recovery
- Lease·Fence

현재 `persistence-acceptance.project.json`과 관련 Runner는 Release/Stabilization Tooling으로 유지한다.

## 11. Evidence

Evidence Class를 구분한다.

```text
DEVELOPMENT_OBSERVATION
STATIC
UNIT_INTEGRATION
STUDIO_STABILIZATION
HUMAN_UI_UX
MULTI_CLIENT
PERSISTENCE
PERFORMANCE_SOAK
RELEASE_ACCEPTANCE
```

- 실행하지 않은 Class를 PASS로 기록하지 않는다.
- 과거 SHA의 Runtime 결과를 변경된 경로에 자동 재사용하지 않는다.
- Development Observation은 빠른 의사결정에 사용할 수 있지만 Merge·Release Evidence로 승격하려면 정확한 Target SHA와 재현 범위를 기록한다.

## 12. 기존 Acceptance Tooling

다음은 삭제하지 않고 Release·Regression Tooling으로 유지한다.

- `slice01-acceptance.project.json`
- `acceptance-batch.json`
- `FULL-UI-UX-ACCEPTANCE.md`
- `grand-acceptance-manifest.json`
- `GRAND-ACCEPTANCE-CAMPAIGN.md`
- `tooling/run-studio-acceptance-batch.ps1`
- `tooling/run-grand-acceptance.ps1`

기존 `Batch Acceptance Gate`는 **개발 시작 조건이 아니다.** Stabilization 또는 Release에서 필요한 범위만 활성화한다.

`EnableStudioPersistence=false`, `Persistence 전용 Batch`, `Batch Summary` 같은 기존 Harness 계약은 해당 Acceptance Tooling 내부에서만 계속 유효하다.

## 13. 재현 가능한 수동 Runner

Release 또는 정확한 SHA Evidence를 위해 사용자가 로컬 Runner를 실행해야 하는 경우에는 그 시점의 실제 Branch, Project와 HEAD를 조회해 완전한 명령을 제공한다. 과거 Branch 이름을 기본값으로 하드코딩하지 않는다.

과거 문서에서 사용하던 `완전한 다중 행 Windows PowerShell 블록`, `$ErrorActionPreference = "Stop"`, `git switch planning/rvtt-remake`, `git pull --ff-only origin planning/rvtt-remake`, `$head = (git rev-parse --short HEAD).Trim()`, `rojo build slice01-acceptance.project.json --output $output`, `Start-Process $output` 형식은 **historical acceptance bootstrap 예시**이며 현재 기본 개발 흐름이 아니다.

## 14. 완료 판정

기능 구현 완료에는 최소 다음이 필요하다.

1. Studio에서 목표 사용자 흐름이 실제 동작한다.
2. Production 변경이 GitHub Source에서 재현된다.
3. 관련 Focused Test가 통과하거나 미실행 이유가 기록된다.
4. 서버 Authority·Permission·Disclosure 경계를 유지한다.
5. 후속 Release Gate가 필요한 경우 명확히 기록한다.

Release 완료는 별도의 Release Acceptance 결과로 판단한다.
