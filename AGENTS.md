# RVTT Agent Rules

- 상태: `CURRENT`
- 최종 갱신일: 2026-08-12
- 적용 범위: RVTT 저장소에서 작업하는 모든 AI 에이전트와 자동화 도구

이 문서는 RVTT의 최상위 작업 규약이다.

## 1. 현재 작업을 고르는 규칙

**실행할 일의 권위와 제품 설계의 권위를 섞지 않는다.**

현재 실행할 작업은 아래 순서로만 결정한다.

```text
사용자의 최신 명시적 지시
→ .github/CODEX-ACTIVE-TASK.md
→ 그 파일의 commandPath
```

- `.github/CODEX-ACTIVE-TASK.md`가 가리키지 않는 `CODEX-*` 파일은 현재 작업이 아니다.
- `.github/archive/**`는 역사 기록이다. 사용자가 과거 이력을 명시적으로 요청한 경우가 아니면 읽지 않는다.
- 과거 PR 댓글, Review Result, Audit, Acceptance Snapshot에서 현재 TODO를 추론하지 않는다.
- `docs/remake/CURRENT-WORK-ORDER.md`와 `implementation/roblox/CURRENT-WORK-ORDER.md`는 현재 단계와 우선순위를 설명하지만 Active Task를 대체하지 않는다.
- Repository 전체를 스캔하라는 지시는 **현재 구조를 이해하라는 뜻이지, 발견한 과거 TODO를 다시 실행하라는 뜻이 아니다.**

현재 Task routing 상세는 [`.github/README.md`](.github/README.md)를 따른다.

## 2. 기본 개발 루프

```text
GitHub Product·ADR 이해
→ Module Contract 확인
→ 현재 Production Source와 실제 함수·require 관계 확인
→ Roblox Studio MCP에서 직접 구현·Play
→ 관찰·즉시 수정
→ 필요한 사용자 판단
→ 받아들인 결과를 GitHub Source·Rojo Mapping으로 정규화
→ Focused Test
→ Stabilization·Release에서 종합 Acceptance
```

- GitHub는 영구 Canonical Source다.
- Roblox Studio는 실제 구현·조립·실행·관찰 환경이다.
- Rojo는 Source↔DataModel 연결과 재현 도구다. 매 작은 변경의 선행 Gate가 아니다.
- Acceptance Harness는 개발 UI가 아니라 회귀·Stabilization·Release 도구다.
- Studio에만 남아 GitHub Source에서 재현되지 않는 Production 변경은 완료가 아니다.

## 3. 작업 시작 순서

1. 현재 Repository, Branch, Open PR, PR HEAD를 확인한다.
2. `AGENTS.md`와 `.github/README.md`를 읽는다.
3. `.github/CODEX-ACTIVE-TASK.md`를 읽는다.
4. Active Task의 `commandPath` 하나만 현재 실행 명령으로 읽는다.
5. 관련 Product·Architecture·System·UI·Accepted ADR을 읽는다.
6. `implementation/roblox/MODULE-CONTRACTS.md`와 관련 Registry Entry를 읽는다.
7. 대상 Production Source를 직접 읽어 함수, `require()`, Remote, Schema, Registry, Test를 조사한다.
8. Studio MCP에서 현재 Place·Instance Tree·Runtime 상태를 확인한다.
9. 가장 작은 사용자 흐름 하나를 구현·Play·수정한다.

기존 책임을 조사하지 않고 병렬 Manager, Remote, Registry, Controller를 만들지 않는다.

## 4. 설계 권위 순서

제품·Architecture 의미가 충돌할 때의 권위는 다음과 같다.

1. 사용자의 최신 명시적 결정
2. `Accepted` / `확정` ADR
3. 확정 Product·Architecture·System·Global UI Policy
4. 준비 완료 Implementation Spec·승인된 Additive Delta
5. Module Contract — 코드 구조의 안정적인 책임·경계
6. Production Source·Test
7. User Guide·HTML·Audit·Historical Evidence

Work Order와 Active Task는 **무엇을 지금 할지**를 정할 뿐 제품 의미를 새로 만들지 않는다.

Module Contract와 Source가 어긋나면 `CONTRACT_DRIFT`로 보고 어느 한쪽을 추측으로 덮지 않는다.

## 5. Module Contract

`implementation/roblox/MODULE-CONTRACTS.md`와 `implementation/roblox/manifests/module-contracts.json`은 Contract-bearing Module의 다음 항목만 소유한다.

```text
responsibility
stable entry points
contract-level dependencies
authority
state ownership
focused tests
```

private/helper 함수 분해와 세부 호출 순서는 현재 Source에서 판단한다. 수동 Call Graph를 별도 Authority로 유지하지 않는다.

안정적인 Module 경계가 바뀌면 Source와 Module Contract를 함께 갱신한다. helper 내부 구현만 바뀌면 Contract를 억지로 수정하지 않는다.

## 6. 사용자 결정 보호

다음이 더 좋아 보이더라도 자동 적용하지 않는다.

- 제품 목표·비목표 변경
- Accepted ADR 변경
- 핵심 입력 문법 변경
- Authority·Data ownership 변경
- Module 분리·통합 등 Architecture 경계 변경
- 개발 방식 변경
- Release 범위·우선순위 변경

현재 문제, 제안 방향, 기대 효과, 비용·위험, 영향 범위를 사용자에게 먼저 설명하고 승인 후 반영한다.

기존 확정 범위 안의 버그 수정, helper 정리, 배치 조정, 시각적 미세 조정은 이 Gate를 요구하지 않는다.

## 7. 고정 제품 경계

별도의 사용자 결정과 Accepted ADR 없이 다음을 바꾸지 않는다.

- RVTT는 Roblox에서 DM이 실시간 진행하는 게임형 D&D VTT다.
- 기본 Ruleset은 `dnd5e-2024`, 기본 표시 언어는 `ko-KR`다.
- 초기 지원 입력은 PC 키보드·마우스다.
- Token은 Roblox Avatar가 아닌 리그 없는 OBJ·MeshPart 기반 3D Token을 기본으로 한다.
- 권위 이동은 연속 무격자 좌표이며 `5 ft = 4 studs`다.
- Exploration은 목적지 Click과 Token WASD 이동을 지원하고 Encounter는 Token WASD 직접 이동을 지원하지 않는다.
- Left Click=Primary, Right Click=Context, Middle Drag=Camera Orbit, Q=한 단계 취소, E=확정, ESC=Gameplay 의미 없음이다.
- 중요한 규칙, 권한, Transaction, Roll, 확정 이동, 영구 상태의 최종 권한은 Server가 가진다.
- Character Owner, Runtime Controller, Session Role을 분리한다.
- Source, Compiled Build, Authoritative State, Projection, Presentation을 분리한다.
- Player·Observer 상시 UI에 Minimap·별도 Map·Objective Tracker를 추가하지 않는다.
- Private Rule Content와 공개 Release Content를 분리하고 권한 없는 사용자에게 존재 정보까지 누출하지 않는다.
- AI 결과는 Untrusted Draft이며 자동 Publish하거나 Script·Remote·URL Callback으로 실행하지 않는다.
- 공식 Stat Block과 CR을 시스템이 임의로 자동 재조정하지 않는다.
- Reconnect, Restart, Rollback, Migration, Permission-safe Resync, 접근성, 성능과 오류 격리는 제품 완료 조건이다.

세부 제품 계약은 `docs/remake/`의 최신 Authority 문서를 따른다.

## 8. 구현 규약

- Client는 Intent를 제출하고 Server가 Authorization·Rules·Transaction·Projection을 소유한다.
- UI Component는 Domain Store나 Remote를 직접 호출하지 않는다.
- 물리 입력은 Semantic Action과 Input Context를 거쳐 Intent로 변환한다.
- Stable ID를 표시 문자열, File Path, Roblox Instance 이름과 분리한다.
- Rule 계산은 가능한 한 순수 함수·Module로 분리한다.
- Production Luau는 가능한 파일에서 `--!strict`를 유지한다.
- Remote Input은 Type·Size·Schema·Role·Ownership·Revision·Context를 검증한다.
- 오류를 빈 `pcall`로 삼키지 않고 구조화된 실패와 진단 Context를 남긴다.
- Connection, Task, Instance는 수명주기에 맞게 해제한다.
- 매 Frame 전체 Scene 검색, 불필요한 Polling, 대량 반복 Raycast를 피한다.
- 저장 Schema 변경에는 Migration이 필요하며 복합 Commit은 중간 상태를 남기지 않는다.

## 9. Test·Evidence

```text
Development Observation
≠ Module Contract Structural Validation
≠ Static·Unit·Integration
≠ Studio Stabilization Runtime
≠ Human UI·UX
≠ Multi-client
≠ Persistence·Migration
≠ Performance·Soak
≠ Release Acceptance
```

- 개발 중에는 변경한 흐름을 즉시 Play하고 Focused Test를 반복한다.
- 매 Play마다 Commit SHA 고정, Full CI, Acceptance Harness, Grand Campaign을 요구하지 않는다.
- Stabilization·PR Evidence부터 정확한 Branch·SHA와 실행 범위를 고정한다.
- 실행하지 않은 Evidence Class를 PASS라고 하지 않는다.
- Grand Campaign 전체 재실행은 Release Candidate, 대규모 통합 또는 사용자 요청 시 수행한다.

## 10. 완료 조건

기능 작업은 필요한 범위에서 다음을 만족한다.

1. 현재 Active Task와 Product Authority를 따른다.
2. Studio에서 목표 사용자 흐름을 실제로 확인한다.
3. 받아들인 Production 변경을 GitHub Source에서 재현할 수 있다.
4. 안정적인 Module 경계가 바뀌었다면 Module Contract가 일치한다.
5. Server Authority·Permission·Disclosure 경계를 유지한다.
6. 관련 Focused Test가 통과하거나 미실행 이유를 기록한다.
7. 후속 Release Gate와 남은 Risk를 숨기지 않는다.

테스트하지 않은 것을 PASS라고 보고하지 않는다.
