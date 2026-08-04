# RVTT 문서 구조와 작성 가이드

- 상태: 확정
- 문서 종류: Documentation Guide
- 즉시 구현 명세 가능성: READY

이 문서는 `docs/remake/` 아래의 문서를 어디에 두고, 어떤 역할로 작성하며, 어떤 순서로 읽어야 하는지 정의한다.

## 1. 문서 계층

```text
guides/
→ 완료된 주요 시스템의 권위 문서 관계, 전체 흐름과 읽기 순서

product/
→ 제품 목표, 지원 범위, 비목표, 전체 사용자 흐름

architecture/
→ 여러 기능이 공유하는 권위, 데이터, Registry, Runtime, 저장 계약

systems/
→ 기능 영역별 사용자 흐름과 시스템 동작

ui/
→ 화면 구조, 패널, 입력, 표시 우선순위

decisions/
→ 되돌리기 어렵거나 여러 시스템에 영향을 주는 ADR

specs/
→ 실제 코드를 시작하기 위한 구현 계약

audits/
→ 기획 완성도, 충돌, 누락과 준비도 검사

templates/
→ 새 문서 작성용 표준 형식

archive/
→ 최신 기준으로 사용하지 않지만 역사적 보존이 필요한 문서
```

## 2. 문서 종류 선택

- 완료된 주요 시스템의 문서 관계와 흐름을 안내한다면 `guides/`
- 제품 전체 범위나 경험을 정한다면 `product/`
- 여러 기능이 공유하는 공통 계약이라면 `architecture/`
- 하나의 기능 영역이 어떻게 작동하는지 정한다면 `systems/<영역>/`
- 화면과 조작 구조를 정한다면 `ui/<영역>/`
- 중요한 대안을 비교하고 하나를 확정한다면 `decisions/`
- 구현자가 추가 질문 없이 코드를 시작할 계약이라면 `specs/<영역>/`
- 기존 문서의 충돌과 완성도를 검사한다면 `audits/`

한 문서가 여러 역할을 동시에 갖지 않게 한다. 제품 의미와 구현 방법이 모두 필요하면 기획 문서와 구현 명세를 분리한다.

Guide는 설계 문서가 아니다. 새로운 규칙이나 결정을 추가하지 않고 기존 권위 문서를 연결한다.

## 3. 공통 메타데이터

기획 문서에는 다음을 둔다.

```markdown
- 상태: 초안 | 확정 | 대체됨
- 문서 종류: Product | Architecture | System | UI | Audit
- 즉시 구현 명세 가능성: READY | READY_WITH_DEFAULTS | BLOCKED
- 관련 ADR:
- 상위 문서:
- 관련 시스템:
- 대체하는 문서:
- 대체된 문서:
```

Guide에는 다음을 둔다.

```markdown
- Guide Status: NOT_READY | READY_TO_WRITE | CURRENT | UPDATE_REQUIRED
- 적용 시스템 상태:
- Completion Audit:
- 마지막 권위 문서 검토일:
```

구현 명세는 `docs/remake/AGENTS.md`의 별도 상태 체계를 따른다.

## 4. 권위와 우선순위

1. 사용자의 최신 명시적 결정
2. 확정 ADR
3. 확정 Product·Architecture·System·UI 문서
4. 준비 완료 구현 명세
5. Audit 문서
6. Guide
7. 초안과 보관 문서

Audit는 문제를 보고하지만 제품 결정을 직접 대체하지 않는다.

Guide는 비권위 탐색 문서다. Guide와 권위 문서가 충돌하면 권위 문서가 우선한다.

## 5. 폴더별 README

각 주요 폴더의 `README.md`는 다음만 간결하게 안내한다.

- 폴더가 다루는 범위
- 권위 있는 문서
- 추천 읽기 순서
- 관련 ADR과 구현 명세
- 현재 BLOCKED 항목
- 해당 영역의 Guide Status

상세 규칙을 README에 중복 작성하지 않는다.

## 6. Main System Guide 작성 조건

Main System Guide는 해당 시스템의 기획이 완료된 뒤에만 작성한다.

필수 조건:

1. 시스템 범위와 사용자 결과가 확정됨
2. 핵심 Architecture가 `READY`임
3. 관련 System·UI가 `READY`임
4. 되돌리기 어려운 결정이 ADR로 기록됨
5. 중대한 `BLOCKED` 항목이 없음
6. Parent·Children·References 관계가 정리됨
7. 구현 명세 관계 또는 작성 순서를 설명할 수 있음
8. Completion Audit가 Guide 작성 가능으로 판정함

`READY_WITH_DEFAULTS`가 남아 있다면 시스템 의미를 바꾸지 않는 측정형 기본값뿐이어야 하며 Completion Audit가 예외를 승인해야 한다.

미완성 시스템의 폴더와 빈 Guide를 미리 생성하지 않는다.

## 7. Guide의 역할과 금지 사항

Guide가 다루는 것:

- 시스템 목적과 전체 구조
- 데이터·실행 흐름
- 권위 문서 관계도
- 다른 시스템과의 경계
- 추천 읽기 순서
- 권위 문서에 이미 확정된 구현·검증 순서
- 변경 영향 지도

Guide에서 금지하는 것:

- 새로운 제품 동작
- 새로운 Architecture 원칙
- 새로운 ADR 결정
- 새로운 API, Type, Schema와 Command
- 권위 문서에 없는 예외 처리
- 미정 사항의 임의 기본값

새 결정이 필요하면 먼저 권위 문서를 수정하고 Guide를 `UPDATE_REQUIRED`로 갱신한다.

## 8. Authority Tree

권위 문서는 관계를 세 종류로 구분한다.

```text
Parent
→ 직접 상위 권위 문서

Children
→ 이 문서를 구체화하는 하위 권위 문서

References
→ 인접 시스템과 보조 근거
```

Guide는 Authority Tree의 Parent가 될 수 없다. Guide는 권위 문서를 설명하는 비권위 Leaf다.

## 9. Guide 상태

```text
NOT_READY
→ 시스템 기획 미완성

READY_TO_WRITE
→ 작성 조건 통과, Guide 없음

CURRENT
→ 최신 권위 문서와 일치

UPDATE_REQUIRED
→ 권위 문서 변경으로 갱신 필요
```

Guide 상태는 시스템 준비도나 구현 상태를 대신하지 않는다.

## 10. Architecture Freeze와 영향 분석

Architecture를 기반으로 Spec 작성이 시작되면 핵심 계약 변경 전 다음을 확인한다.

1. 새 ADR 또는 기존 ADR 대체 필요 여부
2. 영향받는 Systems·UI
3. 영향받는 Specs와 구현
4. 저장·Migration 영향
5. 영향받는 Main System Guide

Architecture 변경이 승인되면 관련 Guide를 `UPDATE_REQUIRED`로 표시한다.

## 11. 시스템 완료 단계

```text
PLANNING
→ ARCHITECTURE_READY
→ SYSTEM_READY
→ SPEC_READY
→ IMPLEMENTATION_READY
→ IMPLEMENTED
→ GUIDE_CURRENT
→ AUDITED
```

Guide가 기획을 완료시키는 것은 아니다. 완료된 기획·구현 관계를 탐색 가능하게 정리한다.

## 12. 파일 이름

기획 문서는 전역 연속 번호 대신 의미 있는 kebab-case 이름을 사용한다.

```text
systems/combat/encounter-initiative-and-turns.md
systems/combat/rollback-timeline.md
```

ADR은 기존 전역 번호를 유지한다.

```text
decisions/ADR-0053-step-level-automation-classification.md
```

구현 명세는 영역 안에서 3자리 번호를 사용한다.

```text
specs/combat/001-encounter-bootstrap.md
```

Guide는 시스템 이름을 사용한다.

```text
guides/runtime/runtime-system-guide.md
guides/combat/combat-system-guide.md
```

단, 작성 조건을 통과한 뒤에만 경로를 만든다.

## 13. 링크 규칙

- 저장소 내부 문서는 상대 링크를 사용한다.
- 파일 이동 시 원문 복사, 링크 갱신, 대상 존재 확인, 기존 경로 삭제 순서로 진행한다.
- 이동과 내용 변경을 가능하면 분리한다.
- 같은 내용을 두 경로에 장기간 중복 유지하지 않는다.
- 대체 문서는 새 권위 문서를 명확히 링크하고 `대체됨`으로 표시한다.
- Guide의 모든 핵심 설명은 Authority Documents 섹션에서 근거 문서를 찾을 수 있어야 한다.

## 14. 새 ADR이 필요한 경우

다음 중 하나라도 해당하면 ADR을 작성한다.

- 여러 시스템이 공유하는 계약이 바뀜
- 저장 데이터나 권위 경계가 바뀜
- 되돌리기 비용이 큼
- 둘 이상의 타당한 대안 중 하나를 선택함
- 기존 확정 문서를 대체하거나 충돌을 해결함

단순 기본값과 국소 UI 배치는 ADR을 강제하지 않는다.

## 15. 문서 이동 절차

1. `DOCUMENT-MIGRATION-MAP.md`에서 원본과 대상 경로를 확인한다.
2. 원본 내용을 수정하지 않고 대상 경로로 이동한다.
3. 대상 파일의 내부 상대 링크를 수정한다.
4. 해당 폴더 README와 상위 README를 갱신한다.
5. ADR의 관련 문서 링크를 갱신한다.
6. 원본 경로 참조를 검색한다.
7. 깨진 링크가 없을 때 원본을 삭제한다.
8. Git에서 rename으로 인식되는지 확인한다.
9. 문서 수와 매핑 수가 일치하는지 검사한다.

## 16. 에이전트 작업 규칙

- 새 문서를 만들기 전에 이 가이드와 가장 가까운 폴더 README를 읽는다.
- 두 개 이상의 파일을 연속 수정하면 먼저 체크리스트를 제시한다.
- 새 기획 문서에는 구현명세 준비도를 표시한다.
- 경로를 추측해 중복 문서를 만들지 않는다.
- 이동 중인 문서는 `DOCUMENT-MIGRATION-MAP.md`를 기준으로 찾는다.
- Main System Guide 작성 전 `guides/README.md`와 Completion Audit를 확인한다.
- Guide에서 새로운 결정을 만들지 않는다.
- 권위 문서 변경 시 관련 Guide의 갱신 필요 여부를 검사한다.
