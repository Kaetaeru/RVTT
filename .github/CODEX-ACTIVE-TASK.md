# RVTT Current Executable Task

- executionAuthority: `ONLY_CURRENT_EXECUTABLE_TASK`
- status: `READY_FOR_STUDIO_IMPLEMENTATION`
- commandId: `RVTT-STUDIO-EXPLORATION-ITERATION-001`
- repository: `Kaetaeru/RVTT`
- pullRequest: `2`
- branch: `agent/survival-logistics-token-authoring`
- taskMode: `STUDIO_IMPLEMENTATION`
- commandPath: `.github/CODEX-STUDIO-IMPLEMENTATION-EXPLORATION-001.md`
- targetMode: `CURRENT_PR_HEAD_AT_START`
- updatedAt: `2026-08-12`

## 지금 바로 해야 할 일

Repository 스캔 결과로 과거 TODO를 복구하지 않는다. 현재 실행할 일은 아래 하나다.

```text
현재 Exploration 관련 Product·Module Contract·Production Source 조사
→ Roblox Studio MCP로 Production Place 직접 열기
→ 현재 실제 동작 확인
→ Token 선택·Camera·Move·Context Action·상호작용 흐름을 실제 제품 기준으로 구현·수정
→ Play하며 즉시 재확인
→ 사용자 판단이 필요한 UX/Architecture 변화만 보고
→ 받아들인 결과를 GitHub Source·필요한 Module Contract·Rojo Mapping으로 정규화
→ Focused Test
```

**Acceptance 재실행, 과거 Static Gate, 과거 Phase Fix, Grand Campaign은 지금 시작할 작업이 아니다.**

## 스캔할 때 읽는 것

1. `AGENTS.md`
2. `.github/README.md`
3. 이 파일
4. `commandPath`가 가리키는 현재 Command
5. 관련 Product·ADR
6. 관련 Module Contract
7. 현재 Production Source·Test

`.github/archive/**`는 현재 작업 파악을 위해 읽지 않는다.

## 보존 Evidence — 작업 지시 아님

```text
contextual-pointer-actions = PASS · 9/9 · revision 35
historical slice01-world-interaction = PASS · 16/16 · OLD INPUT CONTRACT
ADR-0091 Source/Static = STATIC_VERIFIED
```

위 값은 역사/회귀 참고이며 현재 Production UX 전체 PASS도, 다음 실행 작업도 아니다.

## 사용자 결정 규칙

더 좋아 보이는 제품 방향, Architecture, 핵심 입력 체계, 개발 방식 또는 범위 변경이 발견되면 적용하지 않는다. 문제와 대안을 사용자에게 먼저 보고한다.

## 금지

- Archive에서 TODO 복구
- Acceptance Harness를 Product UI 기준으로 사용
- 기존 책임 조사 없이 새 병렬 Manager·Remote·Registry 생성
- Studio-only Production 변경 방치
- 실행하지 않은 Runtime PASS 주장
- 사용자 승인 없는 새 제품 결정
- ready-for-review / merge / force push
