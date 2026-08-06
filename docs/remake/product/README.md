# Product 문서

- 상태: ACTIVE
- 문서 종류: Product Index
- 최종 갱신일: 2026-08-06

RVTT가 무엇을 만들고 무엇을 지원하지 않는지 정의하는 권위 문서를 안내한다.

## 먼저 읽기

사용자 관점의 전체 흐름은 Product 문서가 아니라 다음 User Guide에서 시작한다.

1. [`한눈에 보는 세션 흐름`](../user-guides/QUICK-FLOW.md)
2. [`Player Guide`](../user-guides/player/README.md) 또는 [`DM Guide`](../user-guides/dm/README.md)
3. 아래 확정 Product Scope
4. 관련 [`Main System Guide`](../guides/README.md)
5. Guide가 연결한 Architecture·System·UI·ADR
6. 관련 [`Implementation Spec`](../specs/README.md)

User Guide는 사용자 경험을 설명하는 비권위 문서다. 제품 범위가 충돌하면 이 폴더의 확정 Product 문서와 ADR이 우선한다.

## 현재 권위 문서

1. [`플랫폼·이동·입력 범위`](platform-movement-and-input-scope.md)
   - PC 키보드·마우스 초기 지원
   - 연속 무격자 이동과 `5 ft = 4 studs`
   - Exploration 클릭·Token WASD
   - Encounter 클릭 경로 이동과 Token WASD 금지
2. [`콘텐츠 범위·자동화·Rollback·저장·제외 기능`](content-automation-rollback-storage-and-exclusions.md)
   - D&D 2024 플레이어 콘텐츠 최종 범위
   - Executable·Guided·Assisted 자동화
   - Rollback·Chunk 저장
   - NPC 대화와 Audio 비목표
3. [`캠페인 규칙·생존 보급·DM 저작 Actor 제품 범위`](campaign-rules-survival-and-authored-actor-scope.md)
   - Narrative·Standard·Survival·Custom Campaign Rule Profile
   - 식량·물·탈것 사료와 선택적 세부 Module
   - Time Advance와 Supply Settlement의 원자적 연결
   - Actor Model Registry·Strict Stat Block·AI Prompt Builder
   - Campaign-local Actor Template Publish·SceneNpc Migration
4. [`캠페인 Material Component 정책`](campaign-material-component-policy.md)
   - 캠페인 수준 물질 구성요소 정책과 규칙 적용 범위

## Campaign Rule Profile의 공통 해석

캠페인 수준 규칙은 Definition 원본을 수정하는 Boolean 모음이 아니다.

```text
Ruleset·Source Pack Definition
+ Campaign Policy Binding
→ Frozen Policy Snapshot
→ 새 Execution·Settlement에서 사용
```

- 정확한 공식 수치는 Content Definition이 소유한다.
- 진행 중 실행은 생성 당시 Snapshot을 유지한다.
- DM 변경은 Candidate Snapshot·Impact Preview·Safe Boundary를 사용한다.
- 기본 변경은 비소급이며 과거 Item·Effect·Ledger를 조용히 재작성하지 않는다.

## Campaign-authored Content의 공통 해석

Campaign-authored Actor·Token은 신뢰된 Registry를 참조하는 순수 데이터다.

- 외부 AI 결과는 Untrusted Draft다.
- 임의 Script·Remote·URL Callback을 실행하지 않는다.
- Core Definition을 직접 수정하지 않는다.
- Publish와 기존 Actor Migration은 DM의 명시적 검토를 요구한다.

## 사용자 흐름 책임

전체 세션 흐름을 설명하던 초기 `core-session-loop.md`는 최신 확정 범위와 충돌해 `DISCONTINUED`로 전환됐다.

- 활성 경로 안내: [`core-session-loop.md`](core-session-loop.md)
- 보관 기록: [`archive/discontinued/product/core-session-loop.md`](../archive/discontinued/product/core-session-loop.md)
- 현재 사용자 흐름: [`한눈에 보는 세션 흐름`](../user-guides/QUICK-FLOW.md)

현재 Product Authority로 초기 세션 초안을 사용하지 않는다.

## 포함 범위

- 제품 목표와 비목표
- 지원 플랫폼과 입력 범위
- 공식 콘텐츠 지원 범위
- 캠페인 수준 정책과 Profile
- 생존·보급의 최종 제품 범위
- Campaign-authored Actor·Token의 신뢰 경계
- 사용자 경험에 영향을 주는 고정 제품 경계

## 제외 범위

- Module·Remote·파일 설계
- 공통 Runtime과 권위 계약
- 기능별 상세 상태 기계
- 화면 Component 배치
- 구현 파일 경로와 Test 계약

위 내용은 각각 `architecture/`, `systems/`, `ui/`, `specs/`에서 정의한다.

## 연결

- 현재 작업 순서: [`../CURRENT-WORK-ORDER.md`](../CURRENT-WORK-ORDER.md)
- ADR-0092 Slice Sync: [`../specs/ADR-0092-SLICE-SYNC-PLAN.md`](../specs/ADR-0092-SLICE-SYNC-PLAN.md)
- Main System Guides: [`../guides/README.md`](../guides/README.md)
- Architecture: [`../architecture/README.md`](../architecture/README.md)
- Systems: [`../systems/README.md`](../systems/README.md)
- UI: [`../ui/README.md`](../ui/README.md)
- ADR: [`../decisions/README.md`](../decisions/README.md)
- Implementation Specs: [`../specs/README.md`](../specs/README.md)
- 문서 수명주기: [`../DOCUMENT-LIFECYCLE-AND-DISCONTINUATION.md`](../DOCUMENT-LIFECYCLE-AND-DISCONTINUATION.md)
