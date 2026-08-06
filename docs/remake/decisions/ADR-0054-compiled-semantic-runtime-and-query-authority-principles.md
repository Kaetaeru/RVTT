# ADR-0054. Compiled Semantic Runtime과 Query 권위 원칙

- 상태: 확정
- 작성일: 2026-08-03
- 결정 범위: RVTT 리메이크 전체 런타임 아키텍처
- 관련 문서:
  - [`Runtime Architecture Principles`](../architecture/runtime-architecture-principles.md)
  - [`플랫폼·이동·입력 범위`](../product/platform-movement-and-input-scope.md)
  - [`이동 의미 레이어 자동 제작 파이프라인`](../systems/navigation/navigation-authoring-pipeline.md)
  - [`EffectRecipe 해결·확정 모델`](../architecture/effect-recipe-resolution-and-commit-model.md)
  - [`Recipe Step Runtime Foundation`](../specs/shared/001-recipe-step-runtime-foundation.md)

## 배경

RVTT 리메이크는 연속 무격자 이동, 수동 Fog, 동적 문과 함정, 턴 롤백, 중도 참여, Scene Editor와 2024 D&D 규칙 자동화를 같은 월드 위에서 처리해야 한다.

기능별 코드가 `Workspace`, Roblox 물리, 임의 Attribute와 자체 거리·시야 계산을 직접 사용하면 다음 문제가 생긴다.

- 이동, 공격 사거리, 시야와 범위 효과가 서로 다른 공간 결과를 냄
- 롤백과 재접속 시 같은 입력을 재현하기 어려움
- 숨겨진 정보가 클라이언트에 불필요하게 복제됨
- 문 하나의 상태 변경이 이동·시야·상호작용 캐시에 일관되게 반영되지 않음
- Scene Editor에서 DM이 기술용 Attribute, 폴리곤과 클리어런스를 직접 관리해야 함
- 공식 콘텐츠가 늘어날수록 주문·Feature별 특수 코드가 누적됨

이전 구현에서 사용하던 `Walkable`, `Deniable`, `DifficultTerrain` 같은 모델 내부 Attribute·Value 관례는 리메이크의 권위 데이터로 사용하지 않는다.

## 결정

### 1. 사용성은 내부 아키텍처보다 상위 제약이다

내부 계산과 컴파일 구조는 복잡해질 수 있다. 다만 다음 중 하나를 유발하는 설계는 채택하지 않는다.

- DM이 일반 에셋을 추가하기 위해 기술용 Attribute나 Value를 직접 넣어야 함
- DM이 내비게이션 폴리곤, 포털 폭이나 토큰 클리어런스를 일상적으로 편집해야 함
- 플레이어가 내부 계산 때문에 눈에 띄는 입력 지연이나 불안정한 이동을 경험함
- 기능을 이해하기 위해 엔진 내부 개념을 알아야 함

복잡성은 Compiler와 Runtime 안에 숨기고, Scene Editor는 의미 있는 오브젝트·영역·예외만 편집한다.

### 2. Scene Source와 Runtime Scene을 분리한다

편집·저장되는 Scene Source는 다음을 가진다.

- 배치된 에셋과 변환값
- 에셋에 연결된 외부 Semantic Profile
- Scene 인스턴스 단위 Override
- DM이 만든 명시적 영역·링크·예외

가져온 원본 Model은 내부 Attribute나 Value가 없어도 등록할 수 있다. Semantic Profile은 에셋 정의 또는 Scene 인스턴스 메타데이터에 별도로 저장한다.

Scene Compiler는 Scene Source를 다음 런타임 레이어와 인덱스로 변환한다.

- Navigation
- Visibility
- Interaction
- Rule
- Metadata와 권한별 공개 정보
- 런타임 공간 인덱스

Runtime은 Scene Source나 Model 이름을 즉석에서 해석하지 않고, 검증된 Compiled Runtime Scene을 사용한다.

### 3. 컴파일 결과는 revision이 고정된 Snapshot이다

컴파일된 그래프, 인덱스와 Query Result는 불변으로 취급한다.

문 열림, Actor 이동, 오브젝트 파괴와 같은 동적 변경은 기존 Snapshot을 임의 수정하는 방식이 아니라 서버 권위 Command를 통해 상태 revision을 전진시킨다.

필요한 파생 인덱스는 변경 영역과 의존성만 증분 갱신한다. 작은 변경마다 Scene 전체를 다시 컴파일하는 것은 요구하지 않는다.

### 4. Runtime 월드 조회의 단일 창구는 Spatial Query다

Rules, Recipe, AI, Fog Assist와 상호작용은 `Workspace`와 Roblox 공간 API를 직접 조회하지 않는다.

모든 권위 공간 질문은 revision이 고정된 Runtime Scene Snapshot에 바인딩된 Spatial Query 계약을 사용한다.

Spatial Query는 다음 원칙을 따른다.

- 읽기 전용
- Snapshot과 revision 명시
- 같은 입력에 같은 정렬 결과를 반환하는 결정성
- 불변 Query Result
- 예산과 제한이 있는 실행
- 필요한 경우 추적 가능한 Query Trace
- Runtime Scene Index 우선 사용
- Provider를 통한 레이어별 구현 격리

무거운 경로 탐색은 Spatial Query의 즉시 조회 API와 분리된 Navigation Planner가 담당하되, 같은 Snapshot과 공간 계약을 사용한다.

### 5. Runtime 상태 변경은 Command만 수행한다

Query, Recipe Step handler, Presentation과 Roblox Instance는 권위 상태를 직접 바꾸지 않는다.

상태 변경 흐름은 다음으로 고정한다.

```text
사용자·DM·규칙 입력
→ 서버 권위 Command
→ validation과 expected revision 검사
→ transaction 또는 CommitGroup
→ 권위 상태 revision 전진
→ 파생 인덱스 무효화·증분 갱신
→ Event와 Presentation 생성
```

### 6. 의존성 방향을 고정한다

런타임 의존성은 다음 방향으로만 흐른다.

```text
Presentation
→ Rules
→ Recipe Runtime
→ Spatial Query와 Runtime Services
→ Runtime Scene Snapshot과 Index
```

저작 경로는 다음과 같다.

```text
Scene Editor
→ Scene Source
→ Scene Compiler
→ Compiled Runtime Scene
```

하위 계층은 상위 계층의 UI, 콘텐츠 또는 표현 모듈을 참조하지 않는다.

### 7. BindingStore는 실행 범위 Blackboard다

Recipe의 Query 결과와 Step 계산 결과는 실행별 `BindingStore`에 저장해 재사용한다.

BindingStore는 전역 월드 상태나 Scene 캐시를 대신하지 않는다. 다른 실행과 공유되는 권위 정보는 Runtime Scene Snapshot과 등록된 서비스가 소유한다.

### 8. 특수 구현보다 등록된 공통 계약을 우선한다

주문, Feature, 아이템과 Scene Object는 가능한 한 다음 조합으로 표현한다.

- 공통 Step
- 공통 Query
- 공통 PendingEffect와 Command
- 공통 Semantic Profile과 Builder
- 공통 Presentation Module

공통 계약으로 표현할 수 없는 기능은 등록된 `AdvancedOperation` 또는 Provider 확장점으로 제한한다. 전용 구현도 권위, revision, Query, 저장과 롤백 계약을 우회하지 않는다.

### 9. 확장점은 신뢰된 Registry 기반이다

Builder, Query Provider, Step Handler와 Presentation Module은 등록 계약으로 확장할 수 있다.

초기 제품은 사용자가 임의 Luau를 실행하는 플러그인을 허용하지 않는다. 확장 가능성은 신뢰된 모듈, 고정 ID, 버전과 검증 가능한 Schema를 의미한다.

## 대안과 기각 이유

### Roblox Workspace와 물리를 권위 원본으로 사용

빠르게 구현할 수 있지만 롤백, 결정성, 비밀 정보 격리와 규칙 일관성을 보장하기 어렵기 때문에 기각한다.

### 모델 내부 Attribute를 의미 데이터의 원본으로 사용

에셋 추가가 불편하고, 같은 모델을 Scene마다 다르게 해석하기 어렵고, 리메이크의 무설정 에셋 등록 목표와 충돌하므로 기각한다.

### 기능별로 거리·시야·충돌을 계산

초기에는 단순하지만 기능 간 결과가 달라지고 캐시 무효화와 성능 측정이 분산되므로 기각한다.

### 모든 동적 변경마다 Scene 전체 재컴파일

일관성은 단순해지지만 플레이 중 문·Actor·파괴 오브젝트 변경 비용이 지나치게 커질 수 있으므로 기각한다. revision이 고정된 Snapshot과 증분 파생 갱신을 사용한다.

### 완전한 범용 플러그인과 사용자 Luau

보안, 결정성, 저장 호환성과 오류 격리를 보장하기 어려우므로 초기 범위에서 제외한다.

## 결과

긍정적 결과:

- 이동, 시야, 범위, 상호작용과 규칙이 같은 공간 원본을 사용함
- 롤백과 재접속에서 특정 revision의 결과를 재현할 수 있음
- DM은 Semantic Object와 예외만 관리하고 기술용 데이터는 Compiler가 생성함
- 공간 질의와 캐시의 성능을 중앙에서 측정·개선할 수 있음
- 콘텐츠와 Provider를 공통 Registry로 확장할 수 있음

비용과 위험:

- Compiler, Snapshot, Index와 증분 무효화 기반을 먼저 구현해야 함
- 단순 기능도 권위 Command와 Query 계약을 따라야 하므로 초기 구현량이 증가함
- Provider 경계가 지나치게 추상적이면 디버깅과 성능이 악화될 수 있음

완화:

- 추상화는 실제 두 개 이상의 호출자가 공유하는 계약에만 둔다.
- Query Trace, Compiler diagnostics와 기준 Scene 프로파일링을 제공한다.
- 사용자 조작이나 플레이 지연이 증가하면 내부 순수성보다 사용자 경험을 우선해 구조를 단순화한다.

## 구현 준비도

이 ADR 자체는 `READY`다.

다만 다음 하위 시스템은 각각 별도 기획과 구현 명세가 필요하다.

- Spatial Query Engine
- Runtime Navigation과 Planner
- Scene Compiler와 증분 빌드
- Runtime Object와 Entity Lifecycle
- Command ordering과 Network Envelope
- Scene Streaming과 권한별 복제
