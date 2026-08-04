# Main System Guide: <시스템 이름>

- Guide Status: CURRENT
- 적용 시스템 상태: GUIDE_CURRENT
- 작성일:
- 마지막 권위 문서 검토일:
- Completion Audit:
- 대체하는 Guide:
- 대체된 Guide:

> 이 Guide는 기존 권위 문서를 연결하고 설명한다. 새로운 규칙·결정·API·데이터 구조를 정의하지 않는다.

## 1. 시스템 목적과 사용자 결과

- 이 시스템이 해결하는 문제
- DM과 플레이어가 최종적으로 경험하는 결과
- 시스템 범위와 명시적 비범위

## 2. 전체 구조

```text
상위 입력
→ 핵심 구성 요소
→ 권위 상태 변경
→ Projection·Presentation 결과
```

각 구성 요소의 역할을 한두 문장으로 설명한다.

## 3. 주요 데이터 흐름

```text
Authoring 또는 Persistent Source
→ Compiler·Resolver
→ Runtime State
→ Snapshot·Journal
```

저장 원본, 파생 Runtime, Client View와 Presentation을 구분한다.

## 4. 주요 실행 흐름

대표 사용자 흐름을 처음부터 완료까지 연결한다.

```text
Intent
→ Command
→ Validation
→ Runtime Service
→ Transaction
→ Projection
→ Presentation
```

필요하면 정상 흐름, 대기·재개 흐름, 실패·복구 흐름을 분리한다.

## 5. 문서 관계도

### Parent Authority

- 문서명 — 상대 경로 — 직접 상위 권위와 이유

### Child Authority

- 문서명 — 상대 경로 — 이 시스템을 구체화하는 역할

### References

- 문서명 — 상대 경로 — 인접 시스템 또는 보조 계약

Guide 자신을 Parent Authority로 기록하지 않는다.

## 6. 다른 시스템과의 경계

| 인접 시스템 | 이 시스템이 제공하는 것 | 상대 시스템이 제공하는 것 | 권위 경계 문서 |
|---|---|---|---|
| 예시 |  |  |  |

중복 계산·중복 저장·직접 Store 접근이 생기지 않도록 경계를 설명한다.

## 7. 추천 읽기 순서

1. 최상위 원칙
2. 핵심 ADR
3. Architecture 계약
4. System·UI 기획
5. Specs
6. Audit

각 문서를 왜 해당 순서로 읽는지 짧게 적는다.

## 8. 구현·검증 순서

권위 문서에서 이미 확정된 구현 의존 순서만 정리한다. Guide에서 새 순서를 발명하지 않는다.

```text
Foundation Spec
→ Domain Spec
→ Client Projection
→ UI·Presentation
→ Recovery·Migration
→ Integration Audit
```

## 9. 변경 영향 지도

다음 변경이 발생할 때 함께 확인할 문서를 연결한다.

| 변경 유형 | 영향받는 권위 문서 | 영향받는 Specs | Guide 조치 |
|---|---|---|---|
| Schema 변경 |  |  | UPDATE_REQUIRED |
| 권위 경계 변경 |  |  | UPDATE_REQUIRED |
| 측정형 기본값 변경 |  |  | 필요 시 갱신 |

## 10. Authority Documents

### Product

- 

### Architecture

- 

### Systems·UI

- 

### Specs

- 

### Audits

- 

## 11. ADR References

- ADR 번호 — 실제 상대 경로 — 결정 요약

## 12. 알려진 비목표와 측정형 기본값

- 권위 문서에서 확정된 비목표
- 아직 측정으로 정할 수치 기본값
- Guide 작성 이후 남은 비차단 작업

## 13. Guide 검증 체크리스트

- [ ] 모든 핵심 문장이 Authority Document에 근거한다.
- [ ] 새로운 제품 규칙이나 Architecture 결정을 추가하지 않았다.
- [ ] 모든 링크가 존재한다.
- [ ] Parent·Children·References를 구분했다.
- [ ] 최신 ADR과 Specs를 반영했다.
- [ ] 권위 문서와 충돌하는 요약이 없다.
- [ ] 변경 영향 지도가 최신이다.
- [ ] Guide Status가 실제 상태와 일치한다.
