# Discontinued 문서 보관소

현재 판단에 사용할 수 없지만 역사적 맥락을 보존할 가치가 있는 문서를 기록한다.

규칙은 [`문서 수명주기와 Discontinuation 정책`](../../DOCUMENT-LIFECYCLE-AND-DISCONTINUATION.md)을 따른다.

## 사용 규칙

- 이 폴더의 문서는 권위 문서가 아니다.
- 구현·기획 우선순위를 정할 때 이 문서의 이전 `BLOCKED`, `MISSING`, `CONFLICT` 판정을 사용하지 않는다.
- 각 기록이 연결한 최신 대체 문서를 먼저 읽는다.
- 원문 전체가 필요하면 해당 문서의 Git 기록을 확인한다.
- Guide의 Authority Documents와 Implementation Spec의 근거 목록에 이 폴더를 넣지 않는다.

## 보관 영역

- [`audits/`](audits/README.md)
  - 특정 시점의 공백·완성도 판단이 이후 설계로 해소되어 폐기된 Audit
- [`product/core-session-loop.md`](product/core-session-loop.md)
  - 최신 이동·Audio 범위와 충돌해 Quick Flow, 상세 User Guide와 확정 Product Scope로 대체된 초기 세션 흐름 초안