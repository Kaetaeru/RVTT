# Shared 구현 명세

여러 규칙·전투·아이템·장면 시스템이 공통으로 사용하는 런타임 계약을 정의한다.

## 읽기 순서

1. `001-recipe-step-runtime-foundation.md`

## 범위

- 공통 타입과 Result 계약
- Registry와 Compiler
- BindingStore
- 서버 권위 Step 실행기
- 대기·재개·취소·복구
- 진단, 테스트와 성능 기준

개별 주문, Feature, Item과 특정 Step의 세부 구현은 해당 시스템 명세에서 다룬다.
