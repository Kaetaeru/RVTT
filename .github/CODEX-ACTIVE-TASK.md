# RVTT Execution State

- status: `READY_FOR_STUDIO_IMPLEMENTATION`
- commandId: `RVTT-STUDIO-EXPLORATION-ITERATION-001`
- repository: `Kaetaeru/RVTT`
- pullRequest: `2`
- branch: `agent/survival-logistics-token-authoring`
- taskMode: `STUDIO_IMPLEMENTATION`
- commandPath: `.github/CODEX-STUDIO-IMPLEMENTATION-EXPLORATION-001.md`
- targetMode: `CURRENT_PR_HEAD_AT_START`
- updatedAt: `2026-08-12`

## 현재 목표

기존 Acceptance Harness를 다시 통과시키는 것을 개발 목표로 삼지 않는다.

```text
GitHub의 현재 Exploration·World·Input Source 조사
→ Studio MCP로 Production Place 직접 확인
→ Token 선택·Camera·Move·Context Action·상호작용 흐름 Play
→ 실제 UX·Runtime 문제 즉시 수정
→ 사용자 판단이 필요한 항목 보고
→ 확정 결과를 GitHub Source·Rojo Mapping에 정규화
→ Focused Test
```

## 보존 Evidence

```text
contextual-pointer-actions = PASS · 9/9 · revision 35
historical slice01-world-interaction = PASS · 16/16 · OLD INPUT CONTRACT
ADR-0091 Source/Static = STATIC_VERIFIED
```

위 Evidence를 현재 Production UX 전체 PASS로 확대하지 않는다.

## 사용자 결정 규칙

더 좋아 보이는 제품 방향, Architecture, 핵심 입력 체계, 개발 방식 또는 범위 변경이 발견되면 적용하지 않는다. 현재 문제와 대안을 사용자에게 먼저 보고한다.

## 금지

- Acceptance Harness를 Product UI 기준으로 사용
- 기존 책임 조사 없이 새 병렬 Manager·Remote·Registry 생성
- Studio-only Production 변경 방치
- 실행하지 않은 Runtime PASS 주장
- 사용자 승인 없는 새 제품 결정
- ready-for-review / merge / force push
