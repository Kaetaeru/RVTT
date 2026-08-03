# 002. Standard Recipe Step Handler Contracts

- 상태: 준비 완료
- 문서 종류: Implementation Spec
- 구현 상태: 미구현
- 즉시 구현 가능성: READY
- 선행 명세:
  - [`001. Recipe Step Runtime Foundation`](001-recipe-step-runtime-foundation.md)
- 관련 기획:
  - [`표준 Recipe Step Library`](../../systems/rules/standard-recipe-step-library.md)
  - [`EffectRecipe 해결·확정 모델`](../../architecture/effect-recipe-resolution-and-commit-model.md)
- 관련 ADR:
  - [`ADR-0053`](../../decisions/ADR-0053-step-level-automation-and-standard-recipe-step-library.md)

## 1. 목적

이 명세는 `StepExecutor`가 호출하는 모든 표준 Step handler의 공통 인터페이스와 안전 경계를 정의한다.

개별 Step의 D&D 규칙 계산은 후속 명세에서 다루지만, 모든 handler는 이 문서의 계약을 반드시 따른다.

핵심 목표:

- handler가 권위 상태를 직접 변경하지 못한다.
- 같은 입력과 같은 권위 snapshot에서는 재현 가능한 결과를 만든다.
- Guided·Assisted 입력과 실행 재개가 동일한 경로를 사용한다.
- 굴림, PendingEffect, TimingWindow와 Presentation 요청의 생성 위치가 명확하다.
- handler 오류가 실행 전체와 서버 프로세스로 확산되지 않는다.
- 새로운 Step을 추가할 때 런타임 코어를 수정하지 않는다.

## 2. 모듈 구조

```text
ServerScriptService/RVTT/RecipeRuntime/StepHandlers/
├─ StepHandlerTypes.lua
├─ StepHandlerRegistry.lua
├─ StepHandlerInvoker.lua
├─ HandlerServices.lua
│
├─ Selection/
├─ Validation/
├─ Resource/
├─ Roll/
├─ Effect/
├─ Control/
├─ Decision/
├─ Presentation/
├─ Persistence/
├─ Cleanup/
└─ Advanced/
```

`StepRegistry`는 데이터 정의를 등록하고, `StepHandlerRegistry`는 신뢰된 서버 ModuleScript 구현을 등록한다.

```text
StepDefinition.handlerId
→ StepHandlerRegistry
→ StepHandler
```

콘텐츠 데이터는 ModuleScript 경로나 함수를 직접 지정하지 않는다.

## 3. StepHandler 계약

```lua
export type StepHandlerId = string

export type StepHandler = {
    handlerId: StepHandlerId,
    handlerVersion: integer,
    supportedStepTypeIds: {string},

    validateConfig: (
        config: unknown,
        services: CompileTimeHandlerServices
    ) -> HandlerConfigValidationResult,

    estimateBudget: (
        validatedConfig: unknown,
        compileContext: HandlerCompileContext
    ) -> HandlerBudgetEstimate,

    execute: (
        request: StepHandlerRequest,
        services: RuntimeHandlerServices
    ) -> StepHandlerResult,

    resume: ((
        request: StepHandlerResumeRequest,
        services: RuntimeHandlerServices
    ) -> StepHandlerResult)?,
}
```

규칙:

- `handlerId`는 전역에서 유일하다.
- 하나의 handler가 여러 StepType을 지원할 수 있지만, 의미가 다른 Step을 만능 handler 하나로 합치지 않는다.
- `validateConfig`는 콘텐츠 로딩 중 실행되며 Roblox Instance나 런타임 월드 상태를 읽지 않는다.
- `execute`와 `resume`은 서버에서만 호출한다.
- handler 함수는 coroutine을 임의 생성하거나 yield하지 않는다.
- 대기는 반드시 `Suspend` 결과와 `PendingInput` 또는 `TimingWindow`로 표현한다.

## 4. 실행 요청

```lua
export type StepHandlerRequest = {
    executionId: string,
    resolutionId: string,
    stepInstanceId: string,
    stepTypeId: string,
    stepOrdinal: integer,

    validatedConfig: unknown,
    inputs: ReadonlyBindingView,
    executionRevision: integer,

    sourceContext: SourceContext,
    targetContext: TargetContext?,
    authoritySnapshot: AuthoritySnapshotView,

    deterministicSeed: string?,
    cancellationToken: CancellationToken,
}
```

### ReadonlyBindingView

handler는 현재 Step에 선언된 입력 port만 읽을 수 있다.

```lua
inputs:get(portName: string, expectedType: string): Result<unknown, HandlerInputError>
inputs:getOptional(portName: string, expectedType: string): Result<unknown?, HandlerInputError>
inputs:list(): {ReadonlyPortValue}
```

다른 Step의 임의 slot 번호를 직접 조회하는 것은 금지한다.

### AuthoritySnapshotView

읽기 전용 권위 상태다.

허용 예:

```text
Actor HP·상태·위치 조회
Item 소유권·수량 조회
SceneObject 상태 조회
현재 Encounter·Turn 조회
거리·시야·공간 질의 요청
```

금지:

```text
HP 직접 수정
CollectionService tag 변경
Instance Attribute 변경
DataStore 쓰기
Actor Model 이동
RemoteEvent 발송
```

## 5. HandlerServices

handler는 전역 singleton에 직접 접근하지 않고 제한된 service facade만 받는다.

```lua
export type RuntimeHandlerServices = {
    rollService: HandlerRollService,
    spatialQueryService: HandlerSpatialQueryService,
    predicateService: HandlerPredicateService,
    pendingEffectFactory: PendingEffectFactory,
    pendingInputFactory: PendingInputFactory,
    timingWindowFactory: TimingWindowFactory,
    presentationFactory: PresentationRequestFactory,
    referenceResolver: AuthoritativeReferenceResolver,
    diagnostics: HandlerDiagnosticsSink,
}
```

서비스별 원칙:

- `rollService`는 서버 권위 RollRecord만 생성한다.
- `spatialQueryService`는 연속 무격자 좌표와 `5 ft = 4 studs` 비율을 사용한다.
- `pendingEffectFactory`는 영구 상태를 바꾸지 않고 검증된 PendingEffect만 만든다.
- `presentationFactory` 결과는 권위 Binding이나 분기에 사용하지 않는다.
- `referenceResolver`는 ID와 expected revision을 함께 검증한다.

## 6. 실행 결과

```lua
export type HandlerOutputValue = {
    portName: string,
    valueType: string,
    value: unknown,
}

export type StepHandlerResult =
    {
        status: "Continue",
        outputs: {HandlerOutputValue},
        pendingEffects: {PendingEffectDraft}?,
        presentationRequests: {PresentationRequestDraft}?,
        diagnostics: {HandlerDiagnostic}?,
    }
    | {
        status: "Branch",
        outcome: string,
        outputs: {HandlerOutputValue}?,
        pendingEffects: {PendingEffectDraft}?,
        presentationRequests: {PresentationRequestDraft}?,
        diagnostics: {HandlerDiagnostic}?,
    }
    | {
        status: "Suspend",
        suspension: HandlerSuspensionDraft,
        outputs: {HandlerOutputValue}?,
        diagnostics: {HandlerDiagnostic}?,
    }
    | {
        status: "Fail",
        error: HandlerExecutionError,
        diagnostics: {HandlerDiagnostic}?,
    }
```

`StepHandlerInvoker`가 결과를 받은 뒤 다음을 재검사한다.

- 출력 port 존재 여부와 타입
- 최대 출력 개수
- PendingEffect 허용 여부
- TimingWindow 허용 여부
- automation level과 Suspend 종류의 일치
- 실행 예산
- 참조 ID와 revision
- 직렬화 가능 여부

handler가 반환했다고 바로 BindingStore나 PendingEffect queue에 기록하지 않는다.

## 7. AutomationLevel별 handler 규칙

### Executable

```text
입력 검증
→ 서버 계산
→ Continue 또는 Branch
```

허용되는 `Suspend`:

- 명시적인 TimingWindow
- 서버 권위 외부 작업의 완료 대기가 아니라, 규칙상 반응 선택 대기만 허용

금지:

- 클라이언트에게 계산 결과 요청
- DM에게 의미 판단 요청

### Guided

최초 `execute`는 구조화된 입력 요청을 반환할 수 있다.

```lua
{
    status = "Suspend",
    suspension = {
        kind = "GuidedInput",
        inputSchemaId = "target.single.creature",
        responderPolicy = ...,
        candidateSnapshot = ...,
    },
}
```

응답 후 `resume`에서 반드시 다시 검증한다.

- 응답자 권한
- 대상 존재
- 거리와 시야
- expected revision
- 현재 Step과 execution revision
- 입력 schema

### Assisted

DM에게 구조화된 판정 항목을 제공한다.

```text
자유 텍스트 설명
→ 참고 정보

기계적 결과
→ 등록된 enum/schema
```

`custom_no_mechanical_effect`는 허용할 수 있지만 임의 스크립트나 임의 PendingEffect를 생성하게 하지 않는다.

## 8. Config 검증 계약

```lua
export type HandlerConfigValidationResult =
    { ok: true, value: unknown, diagnostics: {CompileDiagnostic}? }
    | { ok: false, errors: {CompileDiagnostic} }
```

검증 항목:

- 필수 필드
- enum 값
- 수치 범위
- DiceExpression 문법
- Predicate ID 존재
- SubRecipe ID 존재
- PresentationRecipe ID 존재
- 반복·대상·출력 상한
- StepDefinition metadata와 config 의미의 일치

예:

```text
ApplyDamage handler
+ StepDefinition.emitsPendingEffects = false
→ STEP_HANDLER_DEFINITION_MISMATCH
```

config 검증 결과는 immutable canonical form으로 변환한다. 런타임 handler는 원본 JSON을 다시 파싱하지 않는다.

## 9. Handler 등록

```lua
StepHandlerRegistry.register(handler: StepHandler): Result<nil, HandlerRegistryError>
StepHandlerRegistry.get(handlerId: string): StepHandler?
StepHandlerRegistry.require(handlerId: string): StepHandler
StepHandlerRegistry.freeze(): nil
```

부팅 순서:

```text
1. Handler Module 로드
2. StepHandlerRegistry 등록
3. StepDefinition 등록
4. handlerId와 supportedStepTypeIds 교차 검증
5. Registry freeze
6. 콘텐츠 Recipe 컴파일
```

오류:

```text
STEP_HANDLER_DUPLICATE
STEP_HANDLER_INVALID
STEP_HANDLER_VERSION_INVALID
STEP_HANDLER_STEP_TYPE_MISMATCH
STEP_HANDLER_MISSING_IMPLEMENTATION
STEP_HANDLER_REGISTRY_FROZEN
```

한 handler가 로드 실패하면 해당 handler를 요구하는 콘텐츠 팩은 비활성화한다. 핵심 handler 실패는 서버 부팅 실패로 처리한다.

## 10. 결정론과 굴림

handler가 난수를 직접 호출하는 것은 금지한다.

```text
math.random
Random.new
시간 기반 난수
→ 금지
```

모든 규칙 굴림은 `rollService`를 사용한다.

```lua
rollService:createRoll(request: AuthoritativeRollRequest): RollRecord
```

RollRecord는 다음을 포함한다.

```text
rollId
executionId
stepInstanceId
공식 DiceExpression
수정치 출처
advantage/disadvantage 출처
서버 결과
공개 정책
```

같은 Step의 재실행 시 기존 RollRecord를 재사용할지 새 굴림을 만들지는 `resolutionId`와 replay policy가 결정하며 handler가 임의 선택하지 않는다.

## 11. 멱등성과 재개

handler 자체는 외부 상태를 변경하지 않으므로 재호출 가능해야 한다.

재개 요청:

```lua
export type StepHandlerResumeRequest = {
    baseRequest: StepHandlerRequest,
    pendingInputId: string,
    responseId: string,
    responsePayload: unknown,
    originalSuspensionSnapshot: SerializableSuspensionSnapshot,
}
```

규칙:

- 같은 `responseId`는 한 번만 처리한다.
- 이미 완료된 Step의 resume 요청은 거부한다.
- suspension snapshot과 현재 recipeHash가 다르면 복구를 중단한다.
- resume 결과도 최초 execute와 동일한 출력·효과 검사를 통과한다.
- handler 내부 local table이나 closure를 재개 상태로 사용하지 않는다.

## 12. PendingEffect 생성 규칙

handler는 factory를 통해 draft만 생성한다.

```lua
pendingEffectFactory:createDamage(...)
pendingEffectFactory:createHealing(...)
pendingEffectFactory:createCondition(...)
pendingEffectFactory:createResourceDelta(...)
pendingEffectFactory:createMovement(...)
pendingEffectFactory:createOwnershipTransfer(...)
pendingEffectFactory:createSceneObjectStateChange(...)
```

각 draft에는 최소한 다음이 필요하다.

```text
sourceRef
targetRef
sourceStepInstanceId
operationKind
payload
expectedRevisions
commitGroupHint
rollbackMetadata
```

금지:

- 음수 피해로 회복 표현
- 임의 key-value mutation
- Roblox Instance 직렬화
- target revision 생략
- handler가 commit 완료로 표시

## 13. Control Step과 Branch outcome

Branch outcome은 StepDefinition에 선언된 값만 사용한다.

```text
hit
miss
critical_hit
save_success
save_failure
valid
invalid
```

동적 문자열을 만들어 transition을 선택할 수 없다.

`ForEach`, `Sequence`, `SimultaneousGroup` 같은 Control Step은 자식 Step을 직접 호출하지 않는다. `StepHandlerResult`로 실행 엔진에 다음 ordinal 또는 반복 frame 조작을 요청한다.

이를 통해:

- 실행 예산 추적
- cancellation
- 로그
- suspension
- 복구

가 모든 Step에서 동일하게 유지된다.

## 14. Presentation handler

Presentation Step은 다음만 생성한다.

```text
source VFX
source motion
projectile/travel
impact VFX
target reaction
camera impulse
screen overlay
environment presentation
```

규칙:

- `authority = PresentationOnly`
- PendingEffect 생성 금지
- 권위 Branch outcome 생성 금지
- 실패 시 `PresentationFallback` 사용
- Presentation 완료를 기다려 결과 공개를 지연할 수는 있지만 권위 결과를 바꾸지 못함
- 음악과 모든 SoundEffect는 제품 범위에서 제외

## 15. 오류 격리

`StepHandlerInvoker`는 handler 호출을 보호 경계 안에서 수행한다.

오류 분류:

```text
HANDLER_INPUT_INVALID
HANDLER_CONFIG_INVALID
HANDLER_REFERENCE_STALE
HANDLER_OUTPUT_INVALID
HANDLER_OUTPUT_LIMIT_EXCEEDED
HANDLER_PENDING_EFFECT_NOT_ALLOWED
HANDLER_SUSPENSION_NOT_ALLOWED
HANDLER_BRANCH_UNKNOWN
HANDLER_BUDGET_EXCEEDED
HANDLER_EXCEPTION
HANDLER_CANCELLED
```

정책:

- 예상 가능한 규칙 실패는 `Branch` 또는 typed `Fail`로 반환한다.
- Luau 예외는 `HANDLER_EXCEPTION`으로 변환하고 execution을 안전하게 실패시킨다.
- Presentation handler 예외는 fallback 후 규칙 실행을 계속할 수 있다.
- 오류 로그에 전체 비밀 데이터나 플레이어 전용 Fog 정보를 출력하지 않는다.
- 반복 예외 handler는 diagnostics counter를 올리고 콘텐츠 팩 격리를 제안한다.

## 16. 진단과 추적

각 handler 호출에 다음 trace를 남긴다.

```text
executionId
resolutionId
recipeId + recipeHash
stepInstanceId
stepTypeId
handlerId + handlerVersion
시작·종료 시각
budget 소비량
결과 상태
생성 출력 수
PendingEffect 수
Presentation 요청 수
오류 코드
```

Binding 값 전체는 기본 로그에 기록하지 않는다. 개발자 진단 모드에서도 비밀 정보 redaction을 적용한다.

## 17. 성능 기준

초기 목표:

```text
handler registry 조회
→ 평균 O(1)

일반 Executable handler 호출 오버헤드
→ 규칙 계산 제외 0.2ms 이하 목표

출력·PendingEffect 검증
→ 생성 개수에 선형

매 프레임 handler polling
→ 금지

Guided·Assisted 대기
→ 이벤트 기반 재개
```

실제 수치는 Roblox 프로파일링 결과로 조정하지만 측정 지점은 유지한다.

handler가 매 호출마다 다음을 수행하지 않도록 한다.

- JSON decode
- 전체 Registry 순회
- 전체 Scene descendant 순회
- 전체 Actor 목록 선형 검색
- ModuleScript require

## 18. 테스트

### Registry 단위 테스트

- 중복 handlerId 거부
- freeze 후 등록 거부
- 지원하지 않는 StepType 연결 거부
- handlerVersion 누락 거부

### Config 테스트

- 잘못된 enum 거부
- 범위를 초과한 반복 상한 거부
- 존재하지 않는 Predicate·SubRecipe 참조 거부
- StepDefinition metadata 불일치 거부

### 실행 테스트

- 입력 port 외 접근 차단
- 직접 상태 변경 API가 제공되지 않음
- 출력 타입 불일치 거부
- 허용되지 않은 PendingEffect 거부
- unknown Branch outcome 거부
- 예외가 typed error로 격리됨

### Guided·Assisted 테스트

- 잘못된 응답자 거부
- 중복 responseId 멱등 처리
- stale revision 거부
- 서버 재시작 후 resume 성공
- 자유 텍스트가 기계적 결과로 사용되지 않음

### 장애 테스트

- handler 실행 중 cancellation
- handler 결과 검증 중 대상 삭제
- RollRecord 생성 직후 서버 종료
- suspension 저장 후 Recipe hash 변경
- Presentation handler 예외 후 규칙 실행 지속

## 19. 완료 조건

- `StepHandlerTypes`와 Registry 계약이 구현된다.
- 모든 handler 호출이 `StepHandlerInvoker` 보호 경계를 통과한다.
- handler에 직접 상태 변경 서비스가 제공되지 않는다.
- config·입력·출력·Branch·PendingEffect가 타입 검증된다.
- Guided·Assisted handler가 저장·복구 가능한 snapshot으로 suspend한다.
- 굴림은 모두 서버 `rollService`를 사용한다.
- handler 예외가 서버 전체 오류로 확산되지 않는다.
- 단위·통합·장애 테스트가 통과한다.
- 성능 측정 지점과 diagnostics trace가 구현된다.

## 20. 후속 명세

```text
specs/rules/001-roll-and-outcome-steps.md
specs/rules/002-pending-effect-steps.md
specs/rules/003-guided-and-assisted-input-steps.md
specs/presentation/001-presentation-step-runtime.md
```

개별 Step은 이 공통 handler 계약을 반복 정의하지 않고 차이점만 명시한다.
