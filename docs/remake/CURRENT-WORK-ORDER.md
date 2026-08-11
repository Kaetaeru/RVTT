# RVTT Remake 현재 작업 순서

- 상태: `ACTIVE · STUDIO_FIRST_DEVELOPMENT`
- 최종 갱신일: 2026-08-12
- 구현 작업 기준: [`implementation/roblox/CURRENT-WORK-ORDER.md`](../../implementation/roblox/CURRENT-WORK-ORDER.md)

## 현재 결정

기존 제품·Architecture·Accepted ADR은 유지한다. 바뀐 것은 **개발 방식**이다.

```text
이전
대량 Source 구현
→ Static Gate
→ Acceptance Build
→ 뒤늦은 Studio 검증

현재
GitHub Authority·Source 조사
→ Studio MCP 직접 구현
→ Play·관찰·즉시 수정
→ 사용자 판단
→ GitHub Source 정규화
→ Stabilization·Release 검증
```

새 제품 방향이나 Architecture 변경 아이디어가 생기면 자동 적용하지 않고 사용자에게 먼저 제안한다.

## 현재 Product Authority

Accepted 상태를 유지한다.

- ADR-0088 Direct Play
- ADR-0089 Observer-first Surface
- ADR-0090 Console Matrix·DM Windows
- ADR-0091 Asset·Official Sheet·Dice·Core Rules
- ADR-0092 Survival Logistics·DM Actor Token Authoring

이 문서는 위 제품 결정을 다시 정의하지 않는다.

## 현재 Production 우선순위

현재는 기존 Full UI·UX Source를 **실제 Studio 제품으로 다시 확인하고 다듬는 단계**다.

```text
1. Studio에서 현재 Production UI·입력·World 흐름 열기
2. GitHub의 기존 함수·Module 책임과 실제 Studio 결과 대조
3. 사용자에게 보이는 핵심 흐름을 작은 단위로 직접 수정
4. Play하며 UX·Runtime 결함 즉시 수정
5. 받아들인 결과를 GitHub Source로 정규화
6. 관련 Focused Test·Static 검증
7. 기능군이 안정되면 Multi-client·Persistence·Accessibility·Performance 검증
```

기존 `slice01-world-interaction`, `contextual-pointer-actions`, Full UI Acceptance, Grand Campaign은 삭제하지 않는다. 이들은 개발 시작 Gate가 아니라 회귀·Stabilization·Release Tooling이다.

## 현재 기능 작업 순서

세부 순서는 Studio에서 실제 결과를 보면서 작은 사용자 흐름 기준으로 조정한다. 기본 우선순위는 다음과 같다.

1. Exploration 직접 조작·Camera·Context Action
2. Character Console·Encounter HUD
3. Inventory·Journal·Character Sheet·Settings
4. Entry·Role·Recovery
5. DM Live Workspace
6. ADR-0091 실제 Runtime Surface
7. ADR-0092 Production — Slice 06 → 07 → 11 → 12 → 15 → 16

각 항목은 “문서상 구현됨”이 아니라 **실제 Studio에서 쓸 만한 상태**를 목표로 한다.

## ADR-0092

ADR-0092 Product·Architecture·Slice 06·07 Delta는 유효하다. Production 구현은 기존 Source Mapping을 읽고 Studio-first 방식으로 진행한다.

```text
Slice 06 Supply Foundation
→ Slice 07 Policy·Settlement
→ Slice 11 DM Tool
→ Slice 12 Content Registry
→ Slice 15 Actor·Token Pipeline
→ Slice 16 Integration·Release Evidence
```

다음 Phase의 제품 의미를 선행 구현 중 임의로 확정하지 않는다.

## 완료 판정

개발 중:

```text
Studio Development Observation
+ GitHub Source 정규화
+ Focused Test
```

Release 후보:

```text
Current-SHA CI
+ 필요한 Human UI·UX
+ 필요한 Multi-client
+ 필요한 Persistence·Migration
+ Accessibility·Performance
+ Release Acceptance
```

한 Evidence를 다른 Evidence로 확대 해석하지 않는다.
