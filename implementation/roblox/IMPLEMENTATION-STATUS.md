# RVTT Production Implementation Status

- 상태: `IMPLEMENTED_UNVERIFIED`
- 작성일: 2026-08-05
- 범위: 16개 Slice 계약의 Greenfield Runtime·Domain·Client·UI·Test baseline

## 구현된 공통 계약

- Versioned Command Envelope와 재귀 Payload 제한
- 명시적 Command Authorization 필수 Registry
- 서버 권위 Transaction·Idempotency·Outbox·Projection
- Viewer별 Domain Projection과 DM 정보 Negative Disclosure
- Character·Actor·Item 소유권 및 Runtime Control 검증
- 서버 계산 D20·Attack·Damage·HP 변경
- AuthorityEpoch·Revision·Projection Gap·Full Resync
- Migration·DataStore Adapter·Debounced Persistence Coordinator
- Semantic Input·Client Runtime·Token 기반 UI Shell
- 16개 Slice Domain Command baseline
- Unit·Integration·Security·Disclosure Test Source

## 자동 검증

- 모든 Luau 파일 `--!strict`
- 모든 Command 명시적 `authorize`
- UI Script의 Remote 직접 호출 금지
- `_G`·`shared` 숨은 전역 상태 금지
- Rules Domain의 Client 권위 수치 사용 금지
- 필수 Runtime·Projection·Persistence·Rules·Client 경로 존재

## 아직 미검증

- Luau compiler/type checker
- StyLua·Selene 실제 실행
- Rojo build·Studio sync
- Roblox Studio single/multi-client test
- DataStore API와 server restart recovery
- Navigation·physics·streaming·large scene
- UI visual QA와 accessibility user test
- Performance·memory·network·soak evidence

## 데이터 차단

Slices 13–15의 Runtime과 Rights Gate는 구현했지만 공식 D&D 데이터는 포함하지 않았다. 승인된 Source Version·권리·배포 범위를 가진 별도 Content Pack만 등록할 수 있다.
