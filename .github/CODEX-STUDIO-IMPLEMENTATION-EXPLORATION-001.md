# RVTT Studio Implementation — Exploration Iteration 001

MODE: `STUDIO_IMPLEMENTATION`

## 목표

현재 Production Exploration 흐름을 실제 Roblox Studio에서 직접 열어 사용 가능한 제품 상태로 다듬는다.

대상 사용자 흐름:

```text
Token 선택
→ Camera 조작
→ 이동
→ Right-click Context Action
→ 상호작용
→ Character Console과의 연결 확인
```

## 구현 전에 반드시 읽을 것

1. `AGENTS.md`
2. `docs/remake/CURRENT-WORK-ORDER.md`
3. `implementation/roblox/CURRENT-WORK-ORDER.md`
4. ADR-0088과 관련 Input·UI Authority
5. 다음 Production Source와 직접 연결된 Dependency
   - Semantic input router
   - World token runtime/input/controller
   - World camera
   - Context action resolver/menu
   - Gameplay HUD / Character Console 연결
6. 관련 Unit·Integration·Acceptance Test

파일명이나 API를 추측하지 말고 실제 Repository에서 책임을 확인한다.

## Studio 작업

1. 사용 가능한 Studio MCP Capability를 확인한다.
2. Production Place와 현재 Instance Tree를 조사한다.
3. 기존 Source가 Studio에서 실제로 어떻게 보이고 동작하는지 Play한다.
4. 작은 문제 하나씩 실제 Production 경로에서 수정한다.
5. 매 수정 후 해당 흐름을 다시 Play한다.
6. Output, Server·Client 상태, UI, Camera와 입력 동작을 확인한다.

Acceptance Harness는 필요할 때 회귀 확인용으로만 사용한다. 개발 UI나 Product UX 기준으로 사용하지 않는다.

## 사용자에게 먼저 물어야 하는 변경

다음이 더 좋다고 판단되면 바로 적용하지 않는다.

- Left/Right/Middle/Q/E/ESC 의미 변경
- Exploration 또는 Encounter 이동 방식 변경
- Character Console의 제품 역할 변경
- 서버 Authority·Data ownership 변경
- 새 핵심 UI 패턴 또는 전체 Layout 방향 변경
- 개발 프로세스 변경
- Release 범위·우선순위 변경

보고 형식:

```text
현재 문제
제안 방향
장점
비용·위험
영향 범위
```

## Canonicalization

사용 가능한 결과가 나오면:

1. Studio에서 확정된 Production Script를 Repository의 올바른 Source로 반영한다.
2. 필요한 Instance 구조를 Rojo Mapping으로 재현 가능하게 만든다.
3. 임시 Studio-only Production 의존성을 제거한다.
4. 변경 영역 Focused Test를 실행한다.
5. 필요할 때만 Stabilization Runtime을 실행한다.

## 완료 보고

- 조사한 기존 책임
- Studio에서 확인한 실제 문제
- 수정한 사용자 흐름
- GitHub Source 변경
- 실행한 Focused Test
- 사용자 결정 필요 항목
- 남은 Risk

PR Ready, Merge, Force Push는 하지 않는다.
