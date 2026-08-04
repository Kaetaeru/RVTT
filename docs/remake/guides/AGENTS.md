# Main System Guide Agent Rules

이 문서는 `docs/remake/guides/` 아래의 모든 Guide 작성·수정 작업에 적용된다.

루트 `AGENTS.md`, `docs/remake/AGENTS.md`, `docs/remake/AGENTS-PLANNING-ADDENDUM.md`, `docs/remake/DOCUMENT-GUIDE.md`와 `guides/README.md`를 함께 따른다.

## 1. Guide는 기획 완료 후에만 작성한다

새 Main System Guide를 만들기 전에 반드시 관련 Completion Audit 또는 영역 README에서 `Guide Status: READY_TO_WRITE`를 확인한다.

다음 조건이 충족되지 않으면 Guide 작성을 중단하고 권위 문서의 미완성 항목을 먼저 정리한다.

- 핵심 Architecture가 `READY`
- 관련 System·UI가 `READY`
- 필요한 ADR이 확정
- 중대한 `BLOCKED` 항목 없음
- Parent·Children·References 관계 정리
- 구현 명세 관계 또는 작성 순서 설명 가능
- Completion Audit 통과

`READY_WITH_DEFAULTS`가 남아 있다면 Completion Audit가 측정형 기본값만 남았다고 명시적으로 승인해야 한다.

## 2. Guide에서 새로운 결정을 만들지 않는다

Guide는 다음을 추가할 수 없다.

- 새로운 제품 동작
- 새로운 Architecture 원칙
- 새로운 ADR 결정
- 새로운 API, Type, Schema, Command
- 권위 문서에 없는 실패 정책
- 미정 사항의 임의 기본값

새 결정이 필요하면 Guide를 수정하지 말고 먼저 해당 권위 문서를 작성·수정한다.

## 3. Authority Documents를 먼저 수집한다

작성 전 다음을 확인한다.

1. Parent Authority
2. Child Authority
3. References
4. 관련 ADR
5. 관련 Specs
6. 최신 Audit
7. 대체되거나 Archive된 문서

Guide는 이 문서들의 관계와 흐름만 설명한다.

## 4. 표준 템플릿을 사용한다

새 Guide는 `../templates/main-system-guide-template.md`를 사용한다.

필수 절을 임의로 제거하지 않는다. 해당 없는 절은 `해당 없음`과 이유를 적는다.

## 5. Guide Status를 정확히 유지한다

- 작성 전: `READY_TO_WRITE`
- 최신 권위 문서 반영 완료: `CURRENT`
- 권위 문서 변경 감지: `UPDATE_REQUIRED`
- 기획이 다시 열림: `NOT_READY`

Guide가 오래되었는데 `CURRENT`로 유지하지 않는다.

## 6. 권위 충돌 검증

완료 전 다음을 확인한다.

- Guide의 모든 핵심 설명이 Authority Documents에 근거하는가
- Guide와 ADR이 충돌하지 않는가
- Guide가 Spec보다 더 구체적인 구현을 새로 지시하지 않는가
- 대체된 문서를 현재 권위로 소개하지 않는가
- 권위 문서의 준비도와 Guide Status가 일치하는가
- 상대 링크가 모두 존재하는가

## 7. Guide는 Authority Tree의 Leaf다

Guide를 Product, Architecture, System 또는 Spec의 Parent로 기록하지 않는다.

다른 권위 문서가 Guide를 규칙 근거로 참조하도록 만들지 않는다. Guide 링크는 탐색 편의를 위한 보조 링크로만 사용한다.

## 8. 변경 영향

권위 Architecture, System, ADR 또는 Spec이 변경되면 관련 Guide를 검사한다.

의미·관계·흐름이 바뀌면 즉시 `UPDATE_REQUIRED`로 표시한다. 단순 오탈자나 링크 교정만으로 내용이 바뀌지 않으면 상태를 유지할 수 있다.
