# RVTT Agent Test Status

- 상태: `ACTIVE`
- 최종 갱신일: `2026-08-12`
- 목적: 현재 Evidence와 다음 검증 수준을 간단히 추적한다.

이 문서는 상태 대시보드다. 개발 방식은 `AGENTS.md`, 구현 순서는 `implementation/roblox/CURRENT-WORK-ORDER.md`, 테스트 정의는 `implementation/roblox/EXECUTION-TEST-RULES.md`가 소유한다.

## 현재 운영 모드

```text
STUDIO_FIRST_ITERATION
```

```text
GitHub 조사
→ Studio MCP 직접 구현·Play
→ 즉시 수정
→ 사용자 판단
→ GitHub Source 정규화
→ Focused Test
→ Stabilization·Release Evidence
```

## 현재 Evidence

| 영역 | 상태 | 의미 |
|---|---|---|
| Production Source baseline | `EXISTS` | 16 Slice와 주요 UI Source 존재 |
| ADR-0091 Source/Static | `STATIC_VERIFIED` | Runtime·Human PASS 아님 |
| Full UI·UX Static Matrix | `STATIC_VERIFIED` | Runtime·Human PASS 아님 |
| contextual-pointer-actions | `PASS · 9/9` | 현재 G1 Harness에서 사용자 실행 확인 |
| historical slice01-world-interaction | `HISTORICAL_PASS · 16/16` | OLD INPUT CONTRACT; 현재 UX 전체 PASS 아님 |
| Production Studio UX | `IN_PROGRESS` | 이제 직접 제품 흐름을 반복 확인·수정 |
| Human UI·UX | `IN_PROGRESS_BY_FEATURE` | 작은 기능별 판단 후 Release 전 종합 확인 |
| Multi-client | `NOT_EXECUTED_CURRENT_CONTRACT` | Stabilization 이후 |
| Persistence | `DEFERRED_TO_RELEVANT_STABILIZATION` | Persistence 변경/Release에서 실행 |
| Performance·Soak | `PENDING` | 기능 안정 후 측정 |
| Grand Acceptance | `RELEASE_TOOLING` | 개발 선행 Gate 아님 |

## 현재 다음 행동

```text
Production Studio에서 Exploration 흐름 직접 실행
→ 실제 UI·입력·Camera·Move·Context 문제 확인
→ Studio에서 즉시 수정
→ 받아들인 결과를 Source에 정규화
```

`slice01-world-interaction` 재실행 자체를 다음 개발 목표로 삼지 않는다.

## Evidence 규칙

```text
Development Observation
≠ Static
≠ Stabilization Runtime
≠ Human Final
≠ Multi-client
≠ Persistence
≠ Performance
≠ Release
```

- 실행하지 않은 범위를 PASS로 바꾸지 않는다.
- 개발 중 빠른 Play는 SHA-fixed Release Evidence와 구분한다.
- 기능이 안정되면 그 시점의 정확한 Branch·SHA에서 필요한 검증을 다시 수행한다.
