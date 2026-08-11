# RVTT Agent Rules

- 상태: `CURRENT`
- 최종 갱신일: 2026-08-12
- 적용 범위: RVTT 저장소에서 작업하는 모든 AI 에이전트와 자동화 도구

이 문서는 RVTT의 최상위 작업 규약이다. 제품의 권위 경계를 지키면서 **GitHub에서 현재 구조를 이해하고, Roblox Studio에서 실제로 만들고 플레이하며, 확정된 결과를 다시 GitHub Source에 정규화하는 것**을 기본 개발 방식으로 한다.

## 1. 한 줄 원칙

```text
GitHub에서 이해
→ Studio MCP에서 직접 구현·Play
→ 즉시 관찰·수정
→ 만족한 결과를 GitHub Source로 정규화
→ 자동 회귀 검증
→ Stabilization·Release에서 Acceptance
```

- GitHub는 영구 Source of Truth다.
- Roblox Studio는 실제 구현·조립·실행·관찰 환경이다.
- Rojo는 Source와 Studio를 연결하고 재현 가능한 Build를 보장하는 도구다. 매 작은 변경마다 Acceptance Build를 만드는 개발 Gate가 아니다.
- Codex는 단순 코드 생성기가 아니다. 구현 작업에서는 관련 GitHub 문서와 Source를 먼저 읽고 Studio MCP로 실제 결과물을 만들고 수정한다.
- Studio에만 남아 GitHub에서 재현할 수 없는 Production 변경은 완료가 아니다.

### 사용자 결정 보호

작업 중 현재 방향보다 더 좋아 보이는 제품 방향, Architecture, 개발 방식, 범위 변경이 떠올라도 **바로 적용하지 않는다.** 근거와 영향을 사용자에게 먼저 설명하고 명시적 결정을 받은 뒤 반영한다.

기존에 확정된 범위 안에서의 버그 수정, 코드 정리, 배치 조정, 수치 튜닝처럼 제품 결정을 바꾸지 않는 구현 수정은 이 규칙에 해당하지 않는다.

## 2. 작업 시작 순서

모든 작업은 다음 순서를 따른다.

1. 현재 Repository, Branch, Open PR, PR HEAD를 확인한다.
2. `AGENTS.md`를 읽는다.
3. `docs/remake/CURRENT-WORK-ORDER.md`를 읽는다.
4. 관련 Product·Architecture·System·UI·Accepted ADR을 읽는다.
5. Roblox 구현이면 `implementation/roblox/CURRENT-WORK-ORDER.md`와 `implementation/roblox/EXECUTION-TEST-RULES.md`를 읽는다.
6. 변경 대상과 직접 연결된 기존 Module, 함수, Remote, Schema, Registry, Test를 조사한다.
7. Studio MCP를 사용할 수 있으면 현재 Place·Instance Tree·Runtime 상태를 확인한다.
8. 가장 작은 사용자 흐름 하나를 실제로 동작하게 만들고 Play한다.

파일명, 함수 책임, API, Instance 위치를 추측해 중복 구조를 만들지 않는다.

## 3. 권위 순서

저장소 내용이 충돌하면 다음 순서를 따른다.

1. 사용자의 최신 명시적 결정
2. 상태가 `Accepted` 또는 `확정`인 ADR
3. 확정 Product·Architecture·System·Global UI Policy
4. 준비 완료 Implementation Spec·승인된 Additive Delta
5. 현재 Work Order — 실행 순서와 상태만 소유
6. Production Source·Test
7. User Guide·HTML·Audit·과거 Review Artifact

- Work Order는 제품 결정을 새로 만들지 않는다.
- Audit, 과거 Codex Command와 PR 댓글은 역사적 Evidence이며 현재 Authority를 대체하지 않는다.
- `SUPERSEDED`, `DISCONTINUED`, `ARCHIVED` 문서는 현재 판단 근거로 사용하지 않는다.
- 확정 Authority끼리 충돌하면 임의로 선택하지 말고 충돌을 보고한다.

## 4. 고정 제품 경계

별도의 사용자 결정과 Accepted ADR 없이 다음을 바꾸지 않는다.

- RVTT는 Roblox에서 DM이 실시간 진행하는 게임형 D&D VTT다.
- 기본 Ruleset은 `dnd5e-2024`, 기본 표시 언어는 `ko-KR`다.
- 초기 지원 입력은 PC 키보드·마우스다.
- Token은 Roblox Avatar가 아닌 리그 없는 OBJ·MeshPart 기반 3D Token을 기본으로 한다.
- 권위 이동은 연속 무격자 좌표이며 `5 ft = 4 studs`다.
- Exploration은 목적지 Click과 Token WASD 이동을 지원하고, Encounter는 Token WASD 직접 이동을 지원하지 않는다.
- 입력 의미는 Left Click=Primary, Right Click=Context, Middle Drag=Camera Orbit, Q=한 단계 취소, E=확정, ESC=Gameplay 의미 없음이다.
- 중요한 규칙, 권한, Transaction, Roll 결과, 확정 이동과 영구 상태의 최종 권한은 서버가 가진다.
- Character Owner, Runtime Controller, Session Role을 분리한다.
- Source, Compiled Build, Authoritative State, Projection, Presentation을 분리한다.
- Player·Observer 상시 UI에 Minimap·별도 Map·Objective Tracker를 추가하지 않는다.
- 2024 Player Character Content 전체를 최종 지원 범위로 추적한다.
- Private Rule Content와 공개 Release Content를 분리하고 권한 없는 사용자에게 존재 정보까지 누출하지 않는다.
- Campaign Survival은 Narrative·Standard·Survival·Custom Profile을 사용하며 정확한 수치는 Versioned Content Definition이 소유한다.
- AI 결과는 Untrusted Draft이며 자동 Publish하지 않고 Script·Remote·URL Callback으로 실행하지 않는다.
- 공식 Stat Block과 CR을 시스템이 임의로 자동 재조정하지 않는다.
- NPC 자동 대화, 음악, 환경음, 공격·주문·UI SFX, 음성 기능은 현재 비목표다.
- Reconnect, Restart, Rollback, Migration, Permission-safe Resync, 접근성, 성능과 오류 격리는 제품 완료 조건이다.

세부 결정은 `docs/remake/`의 최신 Authority 문서를 따른다.

## 5. 작업 모드

### Planning

- 목표, 비목표, 사용자 흐름, Authority 경계를 먼저 정한다.
- 구현에서 바로 확인 가능한 UI·조작 세부를 문서만으로 과도하게 고정하지 않는다.
- 되돌리기 어려운 제품·Architecture 결정은 ADR 또는 Product Authority에 기록한다.
- 새 방향이 필요한 경우 사용자 승인 전 `Accepted`로 만들지 않는다.

### Studio Implementation

Roblox 기능 개발의 기본 모드다.

```text
관련 GitHub Source·함수 책임 조사
→ Studio 현재 구조 조사
→ MCP로 실제 Script·Instance·UI 연결
→ Play
→ Output·Instance·화면·상태 확인
→ 즉시 수정
→ 다시 Play
```

- 기존 Module과 함수를 가능한 한 재사용한다.
- UI 배치, 카메라 감각, 입력, 흐름처럼 실제 사용에서 판단해야 하는 요소는 Studio에서 빠르게 반복한다.
- 임시 진단은 허용하지만 Production 우회 경로로 굳히지 않는다.
- 실제 Mouse·Keyboard 감각, 가독성, DM 부담, 재미는 필요할 때 Human Judgment를 받는다.

### Canonicalization·Stabilization

사용자가 기능 방향을 받아들이거나 구현이 안정되면 다음을 수행한다.

```text
Studio 결과
→ GitHub Production Source·Project 정의로 정규화
→ Rojo로 재현 가능성 확인
→ Unit·Integration·Static 검증
→ 필요한 Focused Runtime 재검증
```

Studio에서 생성한 Production Script·Instance가 Source Tree와 Project 정의로 복원되지 않으면 완료하지 않는다.

### Release Verification

Multi-client, Persistence, Migration, Disclosure, Accessibility, Performance·Soak, Grand Acceptance는 개발 중 매 반복의 선행 Gate가 아니라 Stabilization·Release Gate다.

## 6. Codex 역할

Codex 작업은 역할을 명시한다.

- `STUDIO_IMPLEMENTER`: GitHub를 읽고 Studio MCP에서 기능을 직접 구현·수정·Play한다.
- `FIXER`: 확인된 결함을 제한된 범위에서 수정한다.
- `REVIEWER`: Stabilization, 고위험 변경, Merge·Release 전에 독립 검수한다.

매 작은 수정마다 Reviewer→Delta Reviewer를 반복할 필요는 없다. 서버 Authority, Security·Disclosure, Persistence·Migration, Accepted ADR 변경, Merge·Release처럼 위험이 높은 경계에서는 독립 Review를 사용한다.

`.github/CODEX-ACTIVE-TASK.md`는 긴 작업이나 Review를 지시할 때 사용하는 포인터다. 이 파일이 가리키지 않는 과거 Codex Command는 활성 작업이 아니다.

Codex는 사용자 승인 없이 PR Ready, Merge, Force Push 또는 새로운 제품 결정을 확정하지 않는다.

## 7. 구현 규약

- Client는 Intent를 제출하고 Server가 Authorization·Rules·Transaction·Projection을 소유한다.
- UI Component는 Domain Store나 Remote를 직접 호출하지 않는다.
- 물리 입력은 Semantic Action과 Input Context를 거쳐 Intent로 변환한다.
- Stable ID를 표시 문자열, File Path, Roblox Instance 이름과 분리한다.
- 하나의 거대한 Manager에 서로 다른 책임을 모으지 않는다.
- Rule 계산은 가능한 한 순수 함수·Module로 분리한다.
- Production Luau는 가능한 파일에서 `--!strict`를 유지한다.
- Remote Input은 Type·Size·Schema·Role·Ownership·Revision·Context를 검증한다.
- 오류를 빈 `pcall`로 삼키지 않고 구조화된 실패와 진단 Context를 남긴다.
- Connection, Task, Instance는 수명주기에 맞게 해제한다.
- 매 Frame 전체 Scene 검색, 불필요한 Polling, 대량 반복 Raycast를 피한다.
- 저장 Schema 변경에는 Migration이 필요하며 복합 Commit은 중간 상태를 남기지 않는다.

## 8. Test·Evidence 규칙

개발 중 빠른 Play와 Release Evidence를 구분한다.

```text
Development Observation
≠ Static PASS
≠ Studio Stabilization PASS
≠ Human UI·UX PASS
≠ Multi-client PASS
≠ Persistence PASS
≠ Performance·Soak PASS
≠ Release PASS
```

- 개발 중에는 변경한 흐름을 바로 Play하고 Focused Test를 반복할 수 있다.
- 매 Play마다 Commit SHA 고정, Full CI, Acceptance Harness, Grand Campaign을 요구하지 않는다.
- Stabilization·PR Evidence를 기록할 때는 정확한 Branch·SHA와 실행 범위를 고정한다.
- Release 전에 필요한 자동 CI와 Runtime Gate를 수행한다.
- 한 Gate의 성공을 실행하지 않은 다른 Gate의 성공으로 확대하지 않는다.
- 실패 후 개발 단계에서는 관련 Focused Test만 다시 돌려도 된다. Grand Campaign 전체 재실행은 Release Candidate 또는 사용자가 요청한 시점에 한다.

상세 실행 규칙은 `implementation/roblox/EXECUTION-TEST-RULES.md`가 소유한다.

## 9. 완료 조건

기능 작업은 필요한 범위에서 다음을 만족해야 한다.

1. 현재 사용자 결정과 Authority를 따른다.
2. Studio에서 실제 사용자 흐름이 확인된다.
3. 확정된 Production 변경이 GitHub Source에서 재현 가능하다.
4. Server Authority·Permission·Disclosure 경계를 지킨다.
5. 관련 Unit·Integration·Static Test가 통과하거나 미실행 이유가 기록된다.
6. Persistence·Migration·Performance 등 영향이 있으면 필요한 후속 Gate를 명시한다.
7. 남은 제한, Risk, 제품 결정 필요 항목을 숨기지 않는다.

테스트하지 않은 것을 PASS라고 보고하지 않는다.
