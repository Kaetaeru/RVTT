# Roblox Studio MCP 개발·Runtime 정책

- 상태: `ACTIVE_DEFAULT_DEVELOPMENT_PATH`
- 최종 갱신일: 2026-08-12
- 상위 규칙: [`AGENTS.md`](../../AGENTS.md)
- 실행 규칙: [`EXECUTION-TEST-RULES.md`](EXECUTION-TEST-RULES.md)

## 1. 목적

Roblox Studio MCP를 RVTT의 **직접 구현·실행·관찰 환경**으로 사용한다. MCP는 Release 테스트만 돌리는 도구가 아니라 Codex가 GitHub의 기존 구조를 이해한 뒤 실제 Studio 결과물을 만들고 빠르게 수정하기 위한 개발 도구다.

```text
GitHub 조사
→ Studio 조사
→ 직접 구현
→ Play
→ 관찰
→ 수정
→ Source 정규화
```

## 2. Capability Handshake

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

없는 Capability를 사용한 것처럼 보고하지 않는다.

## 3. 구현 전 GitHub 조사

Codex는 Studio를 수정하기 전에 관련 GitHub Source를 읽는다.

필수 확인:

- 현재 Branch·PR·HEAD
- Product·ADR·UI·Spec Authority
- 대상 Module과 공개 함수
- Server Command·Authorization·Projection
- Remote·Schema·Registry
- 기존 UI·Controller·Runtime 연결
- 관련 Test

기존 책임을 찾지 않고 새 Manager, Remote, Registry 또는 병렬 Script를 만들지 않는다.

## 4. Studio 직접 구현

MCP가 허용하는 범위에서 Codex는 Studio에서 직접 다음을 수행할 수 있다.

- 실제 UI Hierarchy 구성
- Instance Property와 Layout 조정
- 기존 Production Script 연결
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

이 과정에 전체 Acceptance Harness나 Grand Campaign을 선행시키지 않는다.

## 5. Studio와 GitHub 동기화

Studio는 작업장이고 GitHub는 Canonical Source다.

작업이 안정되면:

1. Studio에서 확정된 Script Source를 Repository의 올바른 Module로 반영한다.
2. 필요한 Production Instance 구조를 Rojo Project·Source Mapping으로 표현한다.
3. 임시 Studio-only Object와 우회 코드를 제거한다.
4. Clean Source에서 Rojo Build 또는 Sync로 재현 가능한지 확인한다.
5. 관련 Test를 갱신한다.

Studio 파일을 직접 저장한 것만으로 Production 완료 처리하지 않는다.

## 6. 사용자 판단

다음은 사용자에게 직접 확인받을 수 있다.

- 입력 감각
- Camera 감각
- UI 크기·가독성
- 정보 밀도
- DM 작업 부담
- 게임 흐름·리듬
- 재미와 만족도

MCP는 상태를 준비하고 Evidence를 수집할 수 있지만 Human Judgment를 대신하지 않는다.

## 7. 새로운 방향 발견 시

Codex가 구현 중 더 좋은 제품 방향, Architecture, 핵심 UX, 개발 방식 또는 범위 변경을 발견하면 **직접 적용하지 않는다.**

다음을 보고한다.

```text
현재 문제
제안 방향
기대 효과
비용·위험
영향받는 Authority·Source
```

사용자 승인 후에만 Accepted 문서와 Production 의미를 변경한다.

## 8. Development Runtime과 Stabilization Runtime

### Development Runtime

- 빠른 Play와 수정용
- Commit SHA 고정 필수 아님
- Focused Observation 허용
- Evidence Bundle 필수 아님

### Stabilization Runtime

- 기능이 Source에 정규화된 뒤 수행
- 정확한 Branch·SHA 기록
- 실행 범위와 예상 결과 명시
- 필요한 Log·Screenshot·State 보존

### Release Runtime

- Multi-client, Persistence, Migration, Accessibility, Performance, Grand Acceptance 등 필요한 Gate 수행
- 실행하지 않은 범위를 PASS로 확대하지 않음

## 9. 실패 처리

다음이면 현재 실행을 중단하고 원인을 먼저 고친다.

- Studio crash
- unhandled runtime error
- Authority·Permission leak
- DataStore mode 오사용
- MCP disconnect로 결과가 불완전함
- 수정한 흐름을 재현할 수 없음

개발 단계에서는 해당 흐름만 빠르게 재실행한다. 전체 Release Campaign 재실행은 Release Candidate에서 수행한다.

## 10. MCP가 없을 때

MCP 연결이 없으면 GitHub Source + Rojo + 일반 Studio 실행으로 작업할 수 있다. 다만 MCP로 Studio를 직접 확인했다고 주장하지 않는다.

MCP 부재는 제품 개발 전체를 Block하지 않지만, MCP에서만 확인하려던 Evidence는 미실행으로 남긴다.
