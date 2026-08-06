# RVTT Roblox Tooling

Build, Validation, Schema Consistency, Grand Acceptance와 Local Developer Command를 둔다.

## 현재 Runner

### `run-grand-acceptance.ps1`

Grand Acceptance Campaign의 기본 Runner다.

- Manifest의 모든 정적 Project를 Build
- READY Studio Phase를 순서대로 실행
- Studio 종료 후 최근 Roblox Log에서 Summary 수집
- 실패가 있어도 다음 Phase 계속 실행
- JSON·Markdown 통합 Report 생성
- `-IncludePersistence`에서만 Deferred Persistence Phase 포함
- `-NoOpen`으로 Build·Report 준비만 수행
- `-SelfTest`로 Manifest·Project·Phase 계약 검사

Windows PowerShell Parser와 Manifest SelfTest는 GitHub Actions에서 검증한다. 실제 사용자 PC에서의 순차 Studio 실행과 Log 수집은 아직 수행하지 않았다.

### `run-studio-acceptance-batch.ps1`

기존 단일 Acceptance Batch용 일반 Runner다. Grand Campaign 이전 호환 경로로 유지한다.

### `run-local-acceptance.ps1`

고정된 로컬 저장소에서 검증 Source를 분리 Build하는 보조 Runner다.

### `validate_implementation.py`

Structure·Security·Manifest·Runner·Project 계약을 검증한다.

## 운영 원칙

- 사용자 수동 검사는 Grand Acceptance Milestone에서만 요청한다.
- 사용자는 저장소 Update와 정확한 Head 검사가 포함된 완전한 Windows PowerShell 블록을 받는다.
- Tooling은 Production Authorization·Transaction·Projection을 우회하지 않는다.
- Runner Self-check가 실제 사용자 입력을 대신하지 않는다.
- 아직 구현되지 않은 Phase는 PASS가 아니라 `blocked`다.
