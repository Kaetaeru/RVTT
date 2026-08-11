# RVTT Agent Rules

- 상태: `CURRENT`
- 최종 갱신일: 2026-08-12
- 적용 범위: RVTT 저장소에서 작업하는 모든 AI 에이전트와 자동화 도구

## 1. 현재 작업 선택

현재 실행할 작업은 아래 순서로만 결정한다.

```text
사용자의 최신 명시적 지시
→ .github/CODEX-ACTIVE-TASK.md
→ commandPath
```

- `.github/archive/**`와 과거 `CODEX-*` Command는 역사 기록이다.
- 과거 PR 댓글, Audit, Acceptance Snapshot, 옛 Work Order에서 현재 TODO를 복구하지 않는다.
- Repository 전체 스캔은 현재 구조를 이해하기 위한 것이지 옛 작업을 재개하기 위한 것이 아니다.
- Work Order는 배경과 우선순위 Context만 소유하고 Active Task를 대체하지 않는다.

## 2. 현재 개발 방식 — GREENFIELD

RVTT의 현재 Studio 구현은 **기존 Production Place나 기존 UI를 고쳐 이어가는 작업이 아니다. 새 Studio 작업물을 처음부터 구축하는 Greenfield Build다.**

```text
Product·ADR 이해
→ Module Contract로 필요한 책임·경계 파악
→ 기존 Source는 참고·재사용 후보로만 조사
→ 새/깨끗한 Studio 작업물에서 최소 구조부터 직접 구축
→ Play
→ 관찰·즉시 수정
→ 사용자 판단
→ 받아들인 결과를 GitHub Canonical Source로 정규화
→ Focused Test
→ Stabilization·Release 검증
```

### 기존 Source 정책

기존 GitHub Production Source는 다음 용도로만 사용한다.

- 기존 함수와 Script가 어떤 책임을 맡았는지 파악
- 이미 검증된 Protocol·Schema·Authority 아이디어 참고
- 현재 계약과 정확히 맞는 Module의 선택적 재사용 후보 확인
- 과거 실패와 회귀 위험 파악

기존 Source를 다음처럼 취급하지 않는다.

- 현재 구현의 출발점
- 그대로 유지해야 하는 구조
- 현재 UX의 정답
- 새 Studio Place에 통째로 가져와야 하는 Baseline

재사용은 **opt-in**이다. Codex는 현재 Product·ADR·Module Contract에 맞고 오래된 구조를 끌고 오지 않는다고 확인한 Module만 선택적으로 재사용한다. 그렇지 않으면 새로 구현한다.

## 3. Studio 시작 규칙

Greenfield Task에서는:

1. 현재 Repository·PR·HEAD를 확인한다.
2. `AGENTS.md`, `.github/README.md`, `.github/CODEX-ACTIVE-TASK.md`, 현재 `commandPath`를 읽는다.
3. 관련 Product·ADR·Implementation Spec을 읽는다.
4. `MODULE-CONTRACTS.md`와 관련 Registry Entry를 읽어 필요한 책임·Authority 경계를 파악한다.
5. 기존 Source를 읽되 **참고 자료로만** 본다.
6. 새/깨끗한 Studio 작업물의 현재 DataModel을 확인한다.
7. 필요한 최소 Instance·Script·Runtime 구조를 Studio MCP로 처음부터 만든다.
8. 가장 작은 사용자 흐름을 Play한다.
9. 문제를 바로 수정하고 다시 Play한다.

기존 Production Place를 열어 “무엇을 고칠지” 찾는 것으로 작업을 시작하지 않는다.

## 4. Canonical Source

- GitHub는 영구 Canonical Source다.
- Roblox Studio는 실제 구현·조립·실행·관찰 환경이다.
- Rojo는 받아들인 Studio 결과를 Source↔DataModel로 재현하는 도구다.
- Studio-only Production 변경은 완료가 아니다.
- 새 구현이 안정되면 현재 Canonical Source 구조로 정리하되, 기존 낡은 구현과 충돌하면 새 구현의 의도를 먼저 확인하고 필요한 Source 교체·삭제 범위를 명확히 한다.

## 5. 설계 권위

제품·Architecture 의미가 충돌할 때:

1. 사용자의 최신 명시적 결정
2. `Accepted` / `확정` ADR
3. 확정 Product·Architecture·System·Global UI Policy
4. 준비 완료 Implementation Spec·승인된 Additive Delta
5. Module Contract — 안정적인 책임·경계
6. 현재 새 구현 Source
7. Legacy Production Source·Test·Historical Evidence

Legacy Source는 상위 Authority보다 우선하지 않는다.

## 6. Module Contract

`implementation/roblox/MODULE-CONTRACTS.md`와 `implementation/roblox/manifests/module-contracts.json`은 다음 안정 경계를 기록한다.

```text
responsibility
stable entry points
contract-level dependencies
authority
state ownership
focused tests
```

- private/helper 함수와 내부 호출 순서는 Codex가 현재 구현에서 판단한다.
- 수동 Call Graph를 별도 Authority로 유지하지 않는다.
- Greenfield 구현 중 기존 Contract가 새 구현과 맞지 않는다면 임의로 Contract를 바꾸지 않고 `CONTRACT_DRIFT` 또는 Architecture 변경 후보로 보고한다.

## 7. 사용자 결정 보호

다음 변화가 더 좋아 보이더라도 자동 적용하지 않는다.

- 제품 목표·비목표
- Accepted ADR
- 핵심 입력 문법
- Authority·Data ownership
- Module 분리·통합 등 Architecture 경계
- 개발 방식
- Release 범위·우선순위

현재 문제, 제안 방향, 기대 효과, 비용·위험, 영향 범위를 사용자에게 먼저 설명하고 승인 후 반영한다.

현재 확정 범위 안에서 새 구현의 helper 구조, 내부 코드 분해, 작은 UI 배치 조정, 재현된 버그 수정은 Codex가 직접 처리할 수 있다.

## 8. 고정 제품 경계

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

## 9. 구현 규약

- Client는 Intent를 제출하고 Server가 Authorization·Rules·Transaction·Projection을 소유한다.
- UI Component는 Domain Store나 Remote를 직접 호출하지 않는다.
- 물리 입력은 Semantic Action과 Input Context를 거쳐 Intent로 변환한다.
- Stable ID를 표시 문자열·File Path·Roblox Instance 이름과 분리한다.
- Rule 계산은 가능한 한 순수 함수·Module로 분리한다.
- Production Luau는 가능한 파일에서 `--!strict`를 유지한다.
- Remote Input은 Type·Size·Schema·Role·Ownership·Revision·Context를 검증한다.
- Connection, Task, Instance는 수명주기에 맞게 해제한다.
- 저장 Schema 변경에는 Migration이 필요하다.

## 10. Test·Evidence

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

- Greenfield 개발 중에는 작은 흐름을 즉시 Play하고 반복한다.
- 매 Play마다 Full CI, Acceptance Harness, Grand Campaign을 요구하지 않는다.
- Legacy Acceptance 결과는 새 Build의 PASS 증거가 아니다.
- Stabilization부터 정확한 Branch·SHA와 실행 범위를 고정한다.
- 실행하지 않은 Evidence를 PASS라고 하지 않는다.

## 11. 완료 조건

기능 작업은 필요한 범위에서 다음을 만족한다.

1. 현재 Active Task와 Product Authority를 따른다.
2. 새 Studio Build에서 목표 사용자 흐름이 실제 동작한다.
3. 받아들인 결과가 GitHub Canonical Source에서 재현된다.
4. 필요한 Module Contract와 새 구현 경계가 일치한다.
5. Server Authority·Permission·Disclosure를 지킨다.
6. 관련 Focused Test를 수행하거나 미실행 이유를 기록한다.
7. 남은 Risk와 사용자 결정 필요 항목을 숨기지 않는다.
