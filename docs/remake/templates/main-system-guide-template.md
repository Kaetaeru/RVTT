# Main System Guide: <시스템 이름>

- Guide Status: CURRENT
- 적용 시스템 상태: GUIDE_CURRENT
- 작성일:
- 마지막 권위 문서 검토일:
- Completion Audit:
- 관련 Quick Flow 구간:
- 관련 Player·DM Guide 절:
- 대체하는 Guide:
- 대체된 Guide:

> 이 Guide는 기존 권위 문서를 연결하고 설명한다. 새로운 규칙·결정·API·데이터 구조를 정의하지 않는다.

## 1. 시스템 목적과 사용자 결과

- 이 시스템이 해결하는 문제
- DM과 Player가 최종적으로 경험하는 결과
- 시스템 범위와 명시적 비범위
- 관련 Quick Flow·User Guide 구간과의 연결

Quick Flow와 User Guide는 사용자 결과를 설명하는 Reference다. 시스템 계약의 직접 근거는 Authority Documents에 둔다.

## 2. 전체 구조

```text
상위 입력
→ 핵심 구성 요소
→ 권위 상태 변경
→ Projection·Presentation 결과
```

각 구성 요소의 역할과 소유하지 않는 책임을 설명한다.

## 3. 주요 데이터 흐름

```text
Authoring 또는 Persistent Source
→ Compiler·Resolver
→ Authoritative Runtime State
→ Event·Projection
→ Snapshot·Journal
```

Source, Build, State, Projection과 Presentation을 구분한다.

## 4. 주요 실행 흐름

대표 사용자 흐름을 처음부터 완료까지 연결한다.

```text
User Intent
→ Command
→ Validation
→ Runtime Service·RuleExecution
→ Transaction
→ Event·Projection
→ User-visible Result
```

필요하면 정상, 대기·재개, 실패·복구와 Rollback 흐름을 분리한다.

## 5. 문서 관계도

### Parent Authority

- 문서명 — 상대 경로 — 직접 상위 권위와 이유

### Child Authority

- 문서명 — 상대 경로 — 이 시스템을 구체화하는 역할

### References

- Quick Flow 또는 User Guide — 사용자 결과 탐색
- 인접 Main System Guide — 경계 탐색
- Audit — 준비도와 완료 근거

Guide 자신과 User Guide를 Parent Authority로 기록하지 않는다.

## 6. 다른 시스템과의 경계

| 인접 시스템 | 이 시스템이 제공하는 것 | 상대 시스템이 제공하는 것 | 권위 경계 문서 |
|---|---|---|---|
|  |  |  |  |

중복 계산·중복 저장·직접 Store 접근이 생기지 않도록 설명한다.

## 7. 추천 읽기 순서

1. [`CURRENT-WORK-ORDER`](../../CURRENT-WORK-ORDER.md)
2. 관련 Quick Flow·Player·DM Guide
3. Runtime Architecture Principles
4. 핵심 ADR
5. Architecture 계약
6. System·UI 기획
7. 기존·후속 Specs
8. Completion Audit

각 문서를 왜 읽는지 적는다.

## 8. 구현·검증 순서

권위 문서에서 이미 확정된 의존 순서만 정리한다. Guide에서 새 순서를 발명하지 않는다.

```text
Foundation Spec
→ Domain Vertical Spec
→ Client Projection·UI
→ Persistence·Recovery·Migration
→ Deterministic Scenario·Integration Test
```

각 Spec은 Quick Flow와 Player·DM Acceptance Flow를 연결해야 한다.

## 9. 변경 영향 지도

| 변경 유형 | 영향받는 User Guide | 영향받는 권위 문서 | 영향받는 Specs | Guide 조치 |
|---|---|---|---|---|
| Schema 변경 |  |  |  | UPDATE_REQUIRED |
| 권위 경계 변경 |  |  |  | UPDATE_REQUIRED |
| 사용자 흐름 변경 |  | Product·UI |  | UPDATE_REQUIRED |
| 측정형 기본값 변경 | 필요 시 |  |  | 필요 시 갱신 |

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

`SUPERSEDED`, `DISCONTINUED`, `ARCHIVED`와 최신 확정 범위에 충돌하는 Draft는 넣지 않는다.

## 11. ADR References

- ADR 번호 — 실제 상대 경로 — 결정 요약 — superseded 여부

## 12. 알려진 비목표와 측정형 기본값

- 권위 문서에서 확정된 비목표
- 아직 측정으로 정할 수치 기본값
- Guide 작성 이후 남은 비차단 작업

## 13. Guide 검증 체크리스트

- [ ] 관련 Quick Flow·User Guide 구간을 Reference로 연결했다.
- [ ] 모든 핵심 문장이 Authority Document에 근거한다.
- [ ] 새로운 제품 규칙·Architecture·API·Schema 결정을 추가하지 않았다.
- [ ] 모든 상대 링크가 존재한다.
- [ ] Parent·Children·References를 구분했다.
- [ ] 최신 ADR과 Specs를 반영했다.
- [ ] 폐기·대체 문서를 Authority Documents에서 제외했다.
- [ ] 권위 문서와 충돌하는 요약이 없다.
- [ ] 변경 영향 지도가 최신이다.
- [ ] Guide Status가 실제 상태와 일치한다.