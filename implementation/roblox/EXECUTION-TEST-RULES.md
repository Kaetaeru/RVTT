# RVTT 실행 테스트 규칙

- 상태: `ACTIVE`
- 채택일: 2026-08-05
- 목적: Roblox Studio 게시·실행·수동 확인 횟수를 줄이면서, 한 번의 Acceptance에서 여러 기능과 실패 원인을 함께 검증한다.

## 1. 기본 원칙

수동 Studio 검사는 개별 커밋이나 단일 버그 수정마다 수행하지 않는다.

```text
여러 관련 기능 구현
→ 자동 테스트·정적 CI
→ 구조화된 진단 로그와 Self-check 추가
→ 하나의 Acceptance Build 생성
→ 한 번 게시
→ 한 번의 사용자 검증
```

사용자에게 새 Place 게시와 수동 검사를 요청할 수 있는 시점은 명시적인 `Batch Acceptance Gate`뿐이다.

## 2. Batch 단위

하나의 Batch는 서로 연결된 사용자 흐름 또는 기술 Milestone을 완성해야 한다.

권장 범위:

- 하나의 End-to-End 흐름
- 5개 이상의 관련 동작 또는 Acceptance 항목
- 정상 경로, 거부 경로, 저장·복구 경로
- 필요한 진단 로그와 자동 회귀 테스트
- 한 개의 재사용 가능한 Acceptance Place

다음은 별도 수동 게시를 요청하지 않는다.

- 단일 Raycast 수정
- 로그 한 줄 추가
- 스타일 또는 문구 수정
- 작은 타입 경계 수정
- 자동 테스트로 확인 가능한 Domain 변경
- CI에서 재현 가능한 Build·Format·Lint 오류

## 3. 중간 검증 책임

사용자 수동 검사 전까지 중간 변경은 다음 자동 Gate가 담당한다.

- Structure·Security·Policy Validator
- StyLua
- Selene
- Production·Test·Multi-client·Persistence·Acceptance Rojo Build
- Production·Test Luau Type Analysis
- Unit·Integration·Security·Recovery Test

자동 Gate가 실패한 상태에서는 사용자에게 Studio 게시를 요청하지 않는다.

## 4. 진단 로그 규칙

각 Batch는 실패 원인을 한 번의 실행으로 분리할 수 있는 로그를 포함해야 한다.

로그 형식:

```text
[RVTT <Subsystem>] event=<event> key=value key=value
```

필수 항목:

- Boot 시 활성화된 Project Flag와 Runtime Mode
- Command 제출·승인·거부·Revision
- 입력 대상과 해석 결과
- Projection 생성·갱신·제거 요약
- Persistence Load·Save·Restore 결과
- Reconnect Recovery 결과
- 최종 Batch Summary의 PASS·FAIL 항목

로그는 상태 전환과 명령 경계에서만 출력한다. Render frame, Heartbeat, 반복 Raycast처럼 고빈도 경로의 무제한 출력은 금지한다. 반복 로그는 집계하거나 Acceptance Debug Flag가 있을 때만 제한적으로 출력한다.

## 5. Acceptance Harness 규칙

Acceptance Harness는 다음 기능을 제공한다.

- 실제 Production Command·Projection·Persistence 사용
- 단계별 수동 버튼보다 가능한 한 자동 준비 사용
- 현재 상태를 읽어 이미 완료된 단계는 자동으로 건너뜀
- 한 화면에서 전체 Batch 상태와 실패 항목 표시
- 최종 `PASS` 또는 실패 항목 목록 출력
- 테스트 전용 Flag·Board·Camera·Diagnostics를 Production 구성과 분리

사용자는 정상적인 경우 최종 Summary만 확인한다. 실패한 경우에는 최종 Summary와 첫 번째 관련 오류 로그만 공유한다.

## 6. 단일 실행 스크립트

모든 수동 Batch는 다음 스크립트로 실행한다.

```powershell
& .\implementation\roblox\tooling\run-studio-acceptance-batch.ps1 `
    -ExpectedHead <검증된 Head> `
    -Project slice01-acceptance.project.json
```

스크립트 책임:

- 기존 Roblox Studio 종료
- 지정 Branch Fetch·Fast-forward Pull
- Dirty Worktree 차단
- 검증된 Head 확인
- Implementation 구조 Validator 실행
- Acceptance Place 한 번 Build
- 실행 Manifest 생성
- Build된 Place 열기

Roblox Studio의 Experience 게시 자체는 사용자가 Batch당 한 번 수행한다.

## 7. 예외 Gate

다음 경우에만 Milestone 완료 전 조기 수동 검사를 허용한다.

- 데이터 손실 위험이 있는 Persistence Schema·Migration
- Authorization·정보 공개와 관련된 Security Boundary
- CI 또는 자동 테스트로 재현할 수 없는 Roblox Engine API 불확실성
- 전체 개발을 막는 Boot·Publish·DataStore 차단 문제

예외 검사도 가능한 최소 횟수로 수행하며, 단일 증상마다 반복 게시하지 않는다.

## 8. 현재 Batch

현재 `Slice 01 World Interaction Batch`에 다음 항목을 묶는다.

```text
3D Token Projection 안정화
→ 화면·월드 좌표 기반 Token Picking
→ Raycast 실패 시 Screen-space Picking Fallback
→ 선택 Highlight·선택 상태 표시
→ Board Destination 표시
→ 서버 권위 movement.commit
→ Command Receipt·Revision 진단
→ 3D Camera Pan·Zoom·Frame
→ Persistence Save·Reconnect Restore
→ 최종 Batch Summary
```

현재 관측된 결함:

```text
WT-PICK-01
사용자가 보이는 3D Token을 클릭했지만 Raycast가 MoveSurface를 반환함
```

이 결함만을 위한 추가 게시 검사는 요청하지 않는다. 위 Batch 구현과 자동 Gate가 완료된 뒤 한 번의 Studio Acceptance에서 다시 확인한다.

## 9. 완료 판정

Batch는 다음 조건을 모두 만족해야 수동 Gate로 이동한다.

```text
관련 기능 구현 완료
자동 회귀 테스트 추가
진단 로그와 최종 Summary 추가
단일 실행 스크립트 적용 가능
Implementation·Documentation CI PASS
검증 Head 고정
```

이 규칙은 이후 Slice 02–16, DataStore Recovery, UI Redesign, Performance Gate에도 동일하게 적용한다.
