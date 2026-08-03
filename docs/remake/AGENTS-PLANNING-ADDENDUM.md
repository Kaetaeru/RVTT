# RVTT Remake Agent Planning Addendum

이 문서는 `docs/remake/`에서 기획·ADR·구현명세를 작성하는 에이전트가 루트 `AGENTS.md`와 `docs/remake/AGENTS.md`에 추가로 따라야 하는 규약이다.

## 1. 모든 기획 문서에 구현명세 준비도를 표시한다

새 기획 문서 또는 기존 기획 문서를 실질적으로 수정할 때 문서 상단에 다음 필드를 반드시 둔다.

```markdown
- 즉시 구현 명세 가능성: READY | READY_WITH_DEFAULTS | BLOCKED
```

### READY

중대한 제품 결정이 모두 끝나 곧바로 구현명세를 작성할 수 있다.

문서에는 최소한 다음이 확정되어 있어야 한다.

- 사용자 흐름
- 권위 상태와 소유자
- 정상 상태 전이
- 취소·실패·재접속 흐름
- 저장 여부
- 다른 시스템과의 경계

### READY_WITH_DEFAULTS

구조와 의미는 확정됐고, 수치·시간·표시 방식 같은 기본값만 남았다.

반드시 남은 기본값을 바로 아래에 적는다.

```markdown
- 남은 기본값: 자동 저장 간격, 패널 기본 폭
```

기본값은 구현명세 작성 중 측정 또는 프로토타입으로 정할 수 있지만 제품 의미를 바꾸면 안 된다.

### BLOCKED

둘 이상의 제품 동작이 가능하거나 다른 문서와 충돌해 구현명세를 만들면 추측이 필요한 상태다.

반드시 차단 이유와 결정 질문을 적는다.

```markdown
- 차단 이유: 전투 중 이동 확정 시점 미정
- 결정 질문: 클릭 시 전체 경로를 확정하는가, 이동 구간마다 확정하는가
```

`BLOCKED` 문서를 근거로 프로덕션 구현을 시작하지 않는다.

## 2. 연속 작업 전에 체크리스트를 작성한다

한 요청을 완료하기 위해 두 번 이상의 연속 작업 또는 둘 이상의 독립 문서·파일 수정이 예상되면, 작업 시작 전에 사용자에게 짧은 체크리스트를 먼저 제시한다.

체크리스트는 다음을 포함한다.

- 수정할 큰 영역
- 확인할 충돌이나 전제
- 최종 검증 항목

예시:

```text
- 관련 ADR과 기존 문서 확인
- 상세 기획과 상태 전이 작성
- 에이전트 규약·README 참조 갱신
- 최신 브랜치와 문서 상태 검증
```

체크리스트는 내부 도구 호출 목록이 아니다. `파일 열기`, `API 호출` 같은 저수준 작업을 나열하지 않는다.

작업 중 범위가 달라지면 체크리스트를 갱신해 사용자에게 알린다.

## 3. 문서 완료 전 준비도 재평가

문서를 작성한 직후 처음 표시한 준비도를 그대로 두지 않는다. 다음을 다시 확인한다.

1. 구현자가 사용자 결정을 다시 물어야 하는가
2. 서버·클라이언트 권위가 모호한가
3. 실패 후 남아야 할 상태가 모호한가
4. 저장·재접속·롤백 영향이 빠졌는가
5. 기존 확정 문서와 충돌하는가
6. 비목표가 명확한가

하나라도 중대한 추측이 필요하면 `READY`로 표시하지 않는다.

## 4. 최신 고정 전제

리메이크 문서 작성 시 다음을 기본 전제로 사용한다.

- 권위 이동은 연속 무격자 좌표다.
- 월드 비율은 `5 ft = 4 studs`다.
- 전투에서 토큰 WASD 이동을 지원하지 않는다.
- 초기 지원 플랫폼은 PC 키보드·마우스다.
- NPC 대화 시스템을 만들지 않는다.
- 음악과 모든 사운드 이펙트를 만들지 않는다.
- PresentationRecipe는 VFX, 토큰 모션, 카메라와 화면 효과만 다룬다.
- 2024 기본 규칙의 플레이어 캐릭터 콘텐츠 전체가 최종 지원 범위다.
- 저장 한도 초과 데이터는 manifest와 chunk로 나눈다.

기존 문서가 이 전제와 충돌하면 새 기능을 덧붙이기 전에 충돌을 표시하고 수정 대상으로 등록한다.

## 5. 공통 런타임 아키텍처 게이트

기획과 구현명세를 작성하기 전에 [`Runtime Architecture Principles`](architecture/runtime-architecture-principles.md)와 [`ADR-0054`](decisions/ADR-0054-compiled-semantic-runtime-and-query-authority-principles.md)를 확인한다.

### 사용자 경험이 상위 제약이다

내부 계산, Compiler와 Index는 복잡해질 수 있다. 다만 다음을 요구하는 설계는 채택하지 않는다.

- DM이 일반 에셋 내부에 기술용 Attribute나 Value를 직접 추가
- DM이 내비게이션 Polygon, Portal 폭과 Clearance를 일상적으로 관리
- 플레이어가 내부 계산 때문에 눈에 띄는 입력 지연과 불안정한 이동을 경험
- Scene 제작자가 엔진 내부 Graph와 Cache를 이해해야 함

복잡성은 Compiler와 Runtime이 소유한다.

### 권위와 계층을 명시한다

새 문서는 최소한 다음 질문에 답해야 한다.

1. 저장 원본은 무엇인가
2. 어떤 Compiled Runtime 데이터가 생성되는가
3. 어느 Layer와 Provider가 책임지는가
4. 어떤 Snapshot과 revision을 읽는가
5. 조회는 어떤 Query를 사용하는가
6. 변경은 어떤 Command 또는 CommitGroup을 사용하는가
7. Cache와 Index는 무엇에 의해 무효화되는가
8. 롤백·재접속·중도 참여 시 무엇을 복구하는가
9. Roblox Instance와 Physics를 어디까지 사용하는가
10. DM과 플레이어에게 추가되는 조작 부담은 무엇인가

중요한 답이 빠져 있으면 `READY`로 표시하지 않는다.

### 직접 Workspace 조회를 권위 판정에 사용하지 않는다

Rules, Recipe, UI와 일반 기능 서비스는 `Workspace` 탐색, Raycast와 overlap을 직접 호출해 권위 결과를 만들지 않는다.

필요한 Roblox 공간 API는 다음 경계 안에 둔다.

- Scene Compiler Geometry Adapter
- 등록된 Spatial Provider
- 비권위 Presentation
- 검증·진단 도구

### Legacy Attribute 관례를 복원하지 않는다

리메이크의 권위 데이터로 다음 모델 내부 관례를 다시 도입하지 않는다.

```text
Walkable
Deniable
IsDeniable
DifficultTerrain
IsDifficultTerrain
```

Semantic Profile은 Asset Definition, Content Pack, Scene Metadata 또는 명시적 Override에 저장한다. 원본 Model은 Attribute와 Value가 없어도 등록 가능해야 한다.

### Query와 Mutation을 분리한다

- Query는 Snapshot-bound, 읽기 전용, 결정적이며 불변 결과를 반환한다.
- 상태 변경은 서버 권위 Command, transaction 또는 CommitGroup만 수행한다.
- Presentation, Query와 Step Handler는 권위 상태를 직접 변경하지 않는다.
- Recipe의 BindingStore는 실행 범위 Blackboard이며 전역 월드 상태를 소유하지 않는다.

### 확장은 신뢰된 Registry로 제한한다

Builder, Provider, Step Handler와 Presentation Module은 고정 ID, 버전, Schema와 Budget을 가진 신뢰된 모듈만 등록한다.

사용자 콘텐츠가 임의 Luau, 무제한 반복, 전체 Workspace 접근과 권위 Command 우회를 제공하도록 설계하지 않는다.

### 한 결정에는 하나의 권위 문서만 둔다

하위 문서는 전체 원칙을 다시 정의하지 않는다. 해당 개념의 권위 문서를 링크하고, 자신의 범위에서 추가되는 계약만 기록한다.
