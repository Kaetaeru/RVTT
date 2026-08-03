# Architecture 문서

여러 기능이 공유하는 권위, 데이터와 실행 계약을 정의한다.

## 최상위 권위 문서

- [`Runtime Architecture Principles`](runtime-architecture-principles.md)
  - 사용자 경험을 상위 제약으로 둔다.
  - Scene Source, Compiled Runtime, Dynamic State와 Presentation을 분리한다.
  - Runtime 계층, Query와 Command 경계를 고정한다.
  - Legacy `Walkable` Attribute 관례를 리메이크 권위 데이터에서 제외한다.
  - 모든 하위 Architecture·System·Spec 문서가 따라야 하는 공통 원칙이다.

## 포함 범위

- 서버·클라이언트 책임
- Command, revision, transaction과 Result
- Registry와 고정 ID
- Compiled Runtime Scene, Snapshot과 Spatial Query
- Capability, Recipe와 Effect
- 저장·복구와 마이그레이션
- PresentationRecipe와 확장 계약

기능별 사용자 흐름은 `../systems/`, 화면 구조는 `../ui/`, 실제 파일 계약은 `../specs/`에 둔다.

## 작성 원칙

새 Architecture 문서는 먼저 [`Runtime Architecture Principles`](runtime-architecture-principles.md)를 따른다.

동일한 결정을 여러 문서에 반복하지 않는다. 전체 계층과 권위 원칙은 이 문서에 연결하고, 각 하위 문서는 자신의 데이터·상태·실패·성능 계약만 추가한다.
