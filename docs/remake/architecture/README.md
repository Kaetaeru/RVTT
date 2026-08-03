# Architecture 문서

여러 기능이 공유하는 권위, 데이터와 실행 계약을 정의한다.

## 포함 범위

- 서버·클라이언트 책임
- Command, revision, transaction과 Result
- Registry와 고정 ID
- Capability, Recipe와 Effect
- 저장·복구와 마이그레이션
- PresentationRecipe와 확장 계약

기능별 사용자 흐름은 `../systems/`, 화면 구조는 `../ui/`, 실제 파일 계약은 `../specs/`에 둔다.

실제 이동이 완료되기 전에는 `../DOCUMENT-MIGRATION-MAP.md`를 따른다.
