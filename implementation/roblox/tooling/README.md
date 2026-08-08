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

### `run-private-rules-studio.ps1`

Owner-only integrated 2024 rules를 포함한 Studio place를 준비하는 fail-closed 진입점이다.

- Local Secret `RVTT_PRIVATE_DND2024_KO_SOURCE`가 private source Git repository를 가리켜야 한다.
- `build_private_rules_runtime.py`가 `BuiltinPackIndex.lua`의 pinned revision, integrated subtree digest와 12/48/16/10/75/391 count를 검증한다.
- Source root에 tracked/untracked 변경이 있거나 revision/digest/count가 맞지 않으면 build를 중단한다.
- Markdown을 임시 workspace에서 Module/Document/Section과 최대 16KB RuleChunk, localized search index로 변환한다.
- `Readiness.json`과 `RuleReaderPackage.json`을 `RVTTPrivateRuleContent`로 생성하고 temporary Rojo project에 overlay한다.
- 생성 workspace는 RVTT Git working tree 밖이어야 하며 private 본문이나 generated chunk를 public repository에 쓰지 않는다.
- 검증된 generated project만 Rojo build하고 필요하면 Studio에서 연다.

Public GitHub Actions는 private repository를 checkout하지 않는다. 대신 `validate_private_rules_runtime_pipeline.py`가 공개-safe synthetic Git fixture로 같은 importer를 실행하고 generated `RVTTPrivateRuleContent` overlay를 실제 Rojo build하며 revision/digest/count/dirty/missing source fail-closed 회귀를 검증한다.

### `run-studio-acceptance-batch.ps1`

기존 단일 Acceptance Batch용 일반 Runner다. Grand Campaign 이전 호환 경로로 유지한다.

### `run-local-acceptance.ps1`

고정된 로컬 저장소에서 검증 Source를 분리 Build하는 보조 Runner다. Private integrated Core Rules를 검증하는 Studio build에서는 이 generic runner를 단독 사용하지 않고 `run-private-rules-studio.ps1`의 generated overlay 경로를 사용한다.

### `validate_implementation.py`

Structure·Security·Manifest·Runner·Project 계약을 검증한다.

## 운영 원칙

- 사용자 수동 검사는 Grand Acceptance Milestone에서만 요청한다.
- 사용자는 저장소 Update와 정확한 Head 검사가 포함된 완전한 Windows PowerShell 블록을 받는다.
- Private integrated Core Rules가 필요한 Studio evidence는 반드시 fail-closed private importer/overlay를 먼저 통과한다.
- Tooling은 Production Authorization·Transaction·Projection을 우회하지 않는다.
- Runner Self-check가 실제 사용자 입력을 대신하지 않는다.
- 아직 구현되지 않은 Phase는 PASS가 아니라 `blocked`다.
