# RVTT Roblox Implementation 현재 작업 순서

- 상태: `STUDIO_FIRST_ITERATION`
- 최종 갱신일: 2026-08-12
- 상위 작업: [`docs/remake/CURRENT-WORK-ORDER.md`](../../docs/remake/CURRENT-WORK-ORDER.md)
- 개발·검증 규칙: [`EXECUTION-TEST-RULES.md`](EXECUTION-TEST-RULES.md)
- Studio MCP: [`ROBLOX-STUDIO-MCP-TEST-POLICY.md`](ROBLOX-STUDIO-MCP-TEST-POLICY.md)

## 1. 현재 상태

16개 Slice Production Source와 Full UI·UX 관련 Source는 이미 넓게 존재하고 Static 검증도 상당 부분 완료됐다. 문제는 실제 Studio 결과와 사용자 경험을 너무 늦게 확인했다는 것이다.

따라서 현재 작업은 **Acceptance를 더 확장하는 것**이 아니라 기존 Production Source를 Studio에서 직접 열고 실제 제품으로 다듬는 것이다.

## 2. 기본 구현 루프

```text
A. GitHub 조사
   관련 Product·ADR·UI·Spec
   기존 Module·함수·Remote·Schema·Test

B. Studio 조사
   현재 Instance Tree
   실제 UI·World 상태
   MCP Capability

C. 직접 구현
   기존 함수 재사용
   실제 UI·Instance·Script 연결

D. Play
   Output·상태·화면 확인

E. 즉시 수정
   같은 흐름을 다시 Play

F. 사용자 판단
   입력 감각·Camera·가독성·흐름

G. Canonicalize
   Studio 결과를 GitHub Source·Rojo Mapping으로 정규화
   Focused Test 실행
```

## 3. 현재 우선 작업

현재 `contextual-pointer-actions` 9/9 PASS는 해당 Acceptance Harness 동작 증거로 보존한다. 하지만 이 결과만으로 실제 제품 UX를 완료 처리하지 않는다.

다음 개발 세션에서는 Acceptance 재실행을 기본 작업으로 삼지 않고 **Production Place에서 Exploration 흐름 자체를 직접 확인**한다.

우선 확인할 흐름:

```text
Token 선택
→ Camera
→ Move
→ Context Action
→ 상호작용
→ Character Console 진입
```

이 흐름에서 실제 불편·Runtime 결함·UI 문제를 발견하면 즉시 고친다.

## 4. 기능군 진행 순서

1. Exploration·World Interaction
2. Encounter·Character Console
3. Inventory·Journal·Character Sheet·Settings
4. Entry·Role·Recovery
5. DM Workspace
6. ADR-0091 Runtime Surface
7. ADR-0092 Slice 06→07→11→12→15→16

순서는 제품 방향을 바꾸지 않는 범위에서 실제 Studio 의존성에 따라 좁게 조정할 수 있다.

## 5. 기존 Acceptance 상태

다음은 유지하지만 **현재 개발 선행 Gate가 아니다.**

- `FULL-UI-UX-ACCEPTANCE.md`
- `slice01-acceptance.project.json`
- `acceptance-batch.json`
- `GRAND-ACCEPTANCE-CAMPAIGN.md`
- `grand-acceptance-manifest.json`
- Persistence acceptance projects

사용 시점:

```text
Focused regression 필요
Stabilization
Merge candidate
Release candidate
```

## 6. Evidence

현재 증거는 용도를 구분한다.

- 과거 Static PASS: Source 구조 회귀 참고
- `contextual-pointer-actions` 9/9: 해당 Harness Runtime Observation
- 과거 Slice 01 16/16: 과거 Contract Historical Evidence
- 새 Studio Development Play: 현재 UX·Runtime 수정의 즉시 피드백
- Release Evidence: 기능 안정 후 별도 실행

Historical Evidence를 현재 변경된 UX 전체 PASS로 사용하지 않는다.

## 7. 사용자 결정 보호

Studio 구현 중 현재 방향보다 더 나은 제품 방향, 입력 체계, Architecture, 개발 방식이 떠오르면 자동 적용하지 않는다. 사용자에게 현재 문제와 대안을 먼저 설명한다.

## 8. 다음 Gate

현재의 다음 Gate는 Batch가 아니라:

```text
Production Studio 직접 실행
→ Exploration 흐름 실제 확인
→ 문제 즉시 수정
→ 사용자 확인
→ Source 정규화
```

기능군이 안정된 뒤에만 해당 영역의 Stabilization Gate를 연다.
