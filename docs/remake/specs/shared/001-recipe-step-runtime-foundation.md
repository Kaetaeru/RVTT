# 001. Recipe Step Runtime Foundation

- 상태: 준비 완료
- 문서 종류: Implementation Spec
- 구현 상태: 미구현
- 즉시 구현 가능성: READY
- 관련 기획:
  - [`표준 Recipe Step Library`](../../systems/rules/standard-recipe-step-library.md)
  - [`EffectRecipe 해결·확정 모델`](../../architecture/effect-recipe-resolution-and-commit-model.md)
  - [`규칙 콘텐츠 공통 실행 계약`](../../architecture/rules-content-execution-and-spell-contract.md)
- 관련 ADR:
  - [`ADR-0053`](../../decisions/ADR-0053-step-level-automation-and-standard-recipe-step-library.md)

## 1. 목적

이 명세는 모든 주문, 공격, Feature, Item, Hazard와 상호작용 Recipe가 공유하는 실행 기반을 정의한다.

구현 대상은 다음 다섯 축이다.

```text
StepDefinition
StepRegistry
RecipeCompiler
BindingStore
StepExecutor
```

이 기반은 다음을 보장해야 한다.

- 콘텐츠 데이터가 임의 Luau를 실행하지 않는다.
- 모든 Recipe는 실행 전에 정적 검증과 컴파일을 거친다.
- 클라이언트 입력은 선택 결과일 뿐 권위 결과가 아니다.
- 영구 상태 변경은 PendingEffect와 CommitGroup을 우회하지 않는다.
- Guided·Assisted Step은 안전하게 중단·저장·재개할 수 있다.
- 같은 실행 요청이 재전송되어도 중복 피해·소모가 발생하지 않는다.
- Presentation 실패가 규칙 해결을 실패시키지 않는다.

## 2. 구현 경계

### 포함

- Step 타입 계약
- Step 등록과 조회
- Recipe 그래프 정적 컴파일
- 바인딩 타입 검사
- 실행 상태기계
- Guided·Assisted 입력 대기
- Step 실행 결과와 오류 계약
- 실행 예산
- 멱등성, 취소, 복구
- 진단과 테스트 기반

### 제외

- `RollAttack`, `ApplyDamage` 등 개별 Step의 실제 규칙 구현
- 콘텐츠별 Recipe 데이터
- 구체적인 UI 디자인
- VFX 모듈 내부 구현
- DataStore chunk 포맷의 전체 명세

## 3. 권장 모듈 구조

실제 저장소 구조와 조정할 수 있지만 책임 경계는 유지한다.

```text
ReplicatedStorage/RVTT/Shared/RecipeRuntime/
├─ RecipeTypes.lua
├─ StepTypes.lua
├─ StepRegistry.lua
├─ BindingTypes.lua
├─ RecipeDiagnostics.lua
├─ Result.lua
└─ ErrorCodes.lua

ServerScriptService/RVTT/RecipeRuntime/
├─ RecipeCompiler.lua
├─ RecipeExecutionService.lua
├─ StepExecutor.lua
├─ BindingStore.lua
├─ PendingInputService.lua
├─ RecipeBudget.lua
├─ RecipeRecovery.lua
└─ StepHandlers/

StarterPlayerScripts/RVTT/RecipeRuntime/
├─ RecipePromptController.lua
└─ RecipePresentationController.lua
```

클라이언트에는 Step handler를 두지 않는다. 클라이언트는 선택·표현 요청을 표시하고 응답할 뿐이다.

## 4. 핵심 식별자

```lua
export type RecipeId = string
export type RecipeVersion = string
export type StepTypeId = string
export type StepInstanceId = string
export type ExecutionId = string
export type ResolutionId = string
export type PendingInputId = string
export type CommitGroupId = string
export type BindingKey = string
```

요구사항:

- `StepTypeId`는 Registry 전역에서 유일하다.
- `StepInstanceId`는 하나의 Recipe 내부에서 유일하다.
- `ExecutionId`는 한 번의 Recipe 실행 전체를 식별한다.
- 모든 네트워크 응답은 `ExecutionId`와 `PendingInputId`를 포함한다.
- 영구 변경 명령은 별도 멱등성 키를 가진다.

## 5. StepDefinition 계약

```lua
export type AutomationLevel = "Executable" | "Guided" | "Assisted"
export type StepAuthority = "Server" | "PresentationOnly"
export type StepPhase =
    "Selection"
    | "Validation"
    | "Resource"
    | "Roll"
    | "Effect"
    | "Control"
    | "Decision"
    | "Presentation"
    | "Persistence"
    | "Cleanup"

export type PortDefinition = {
    name: string,
    valueType: string,
    required: boolean,
    collection: boolean?,
}

export type StepDefinition = {
    stepTypeId: StepTypeId,
    schemaVersion: integer,
    phase: StepPhase,
    automationLevel: AutomationLevel,
    authority: StepAuthority,

    inputPorts: {PortDefinition},
    outputPorts: {PortDefinition},

    configSchemaId: string,
    handlerId: string,

    maySuspend: boolean,
    emitsPendingEffects: boolean,
    opensTimingWindow: boolean,
    deterministicWithoutRoll: boolean,

    maxOutputUnits: integer,
    baseBudgetCost: integer,

    rollbackPolicy: "NoStateChange" | "PendingOnly" | "CommitJournal",
    failurePolicy: "AbortExecution" | "BranchableFailure" | "PresentationFallback",
}
```

### 금지

- StepDefinition 안에 함수나 Luau 소스 저장
- 런타임에 콘텐츠가 `handlerId`를 임의 생성
- `Executable` Step이 클라이언트 결과를 그대로 사용
- `PresentationOnly` Step이 BindingStore의 권위 값을 변경
- 하나의 Step이 선택, 굴림, 피해 확정을 모두 처리하는 만능 handler

## 6. StepRegistry

공개 계약:

```lua
StepRegistry.register(definition: StepDefinition): Result<nil, RegistryError>
StepRegistry.get(stepTypeId: StepTypeId): StepDefinition?
StepRegistry.require(stepTypeId: StepTypeId): StepDefinition
StepRegistry.listByPhase(phase: StepPhase): {StepDefinition}
StepRegistry.freeze(): nil
StepRegistry.isFrozen(): boolean
```

규칙:

- 서버 부팅 중 신뢰된 코드만 등록한다.
- 콘텐츠 로드 전에 `freeze()`한다.
- 중복 ID는 부팅 실패로 처리한다.
- 등록 후 Definition은 불변이다.
- 동일 ID의 schemaVersion 변경은 마이그레이션 없이 허용하지 않는다.
- 클라이언트에는 표시용 축약 메타데이터만 복제한다.

오류:

```text
STEP_TYPE_DUPLICATE
STEP_TYPE_INVALID
STEP_HANDLER_NOT_FOUND
STEP_SCHEMA_NOT_FOUND
STEP_REGISTRY_FROZEN
STEP_DEFINITION_INCONSISTENT
```

## 7. Recipe 원본과 컴파일 결과

### 원본

```lua
export type RecipeNode = {
    stepInstanceId: StepInstanceId,
    stepTypeId: StepTypeId,
    config: unknown,
    inputBindings: {[string]: BindingExpression},
    outputBindings: {[string]: BindingKey},
    transitions: {TransitionDefinition},
}

export type RecipeDefinition = {
    recipeId: RecipeId,
    schemaVersion: integer,
    rulesetId: string,
    nodes: {RecipeNode},
    entryStepId: StepInstanceId,
    outputBindings: {[string]: BindingExpression},
    executionBudget: RecipeBudgetDefinition,
}
```

### 컴파일 결과

```lua
export type CompiledStep = {
    ordinal: integer,
    stepInstanceId: StepInstanceId,
    definition: StepDefinition,
    validatedConfig: unknown,
    compiledInputs: {[string]: CompiledBindingExpression},
    outputSlots: {[string]: integer},
    transitions: CompiledTransitions,
}

export type CompiledRecipe = {
    recipeId: RecipeId,
    recipeHash: string,
    schemaVersion: integer,
    rulesetId: string,
    steps: {CompiledStep},
    entryOrdinal: integer,
    bindingLayout: CompiledBindingLayout,
    budget: CompiledRecipeBudget,
    diagnostics: {RecipeDiagnostic},
}
```

컴파일된 Recipe는 불변이며 `recipeId + recipeHash`로 캐시한다.

## 8. RecipeCompiler 단계

```text
1. Recipe 구조 파싱
2. StepTypeId 조회
3. config schema 검증
4. StepInstanceId 중복 검사
5. 입력 바인딩 존재 검사
6. 입력·출력 타입 검사
7. 그래프 도달 가능성 검사
8. 금지된 순환 검사
9. 반복 상한 검사
10. 최대 효과 수와 실행 예산 계산
11. Guided·Assisted 중단 지점 검사
12. Binding slot 배치
13. recipeHash 생성
14. CompiledRecipe 동결
```

컴파일 실패는 콘텐츠 로딩 실패이며 세션 중 실행 오류로 미루지 않는다.

주요 오류:

```text
RECIPE_STEP_NOT_FOUND
RECIPE_DUPLICATE_STEP_ID
RECIPE_ENTRY_NOT_FOUND
RECIPE_BINDING_NOT_FOUND
RECIPE_BINDING_TYPE_MISMATCH
RECIPE_INVALID_TRANSITION
RECIPE_UNBOUNDED_LOOP
RECIPE_UNREACHABLE_STEP
RECIPE_BUDGET_EXCEEDED
RECIPE_CONFIG_INVALID
RECIPE_SUSPENSION_UNSAFE
```

## 9. BindingStore

BindingStore는 Recipe 실행 중 계산된 값을 보관하는 타입 있는 슬롯 저장소다.

```lua
export type BindingValue = {
    valueType: string,
    value: unknown,
    provenance: BindingProvenance,
    revision: integer,
}

export type BindingProvenance = {
    sourceKind: "Input" | "StepOutput" | "System" | "Restored",
    sourceId: string,
}
```

공개 계약:

```lua
BindingStore.new(layout: CompiledBindingLayout): BindingStore
BindingStore:set(slot: integer, valueType: string, value: unknown, provenance: BindingProvenance): Result
BindingStore:get(slot: integer, expectedType: string): Result<unknown, BindingError>
BindingStore:snapshotSerializable(): SerializableBindingSnapshot
BindingStore:restore(snapshot: SerializableBindingSnapshot): Result
BindingStore:sealStepOutputs(stepOrdinal: integer): nil
```

규칙:

- 컴파일된 슬롯만 사용한다.
- 임의 문자열 key로 런타임 테이블을 확장하지 않는다.
- 출력이 seal된 Step은 같은 실행에서 다시 덮어쓰지 못한다.
- Actor, Item, SceneObject 참조는 ID와 expected revision을 함께 저장한다.
- Roblox Instance 자체를 저장하거나 직렬화하지 않는다.
- 비직렬화 가능 값은 suspension 경계 전에 남아 있어서는 안 된다.

## 10. 실행 상태기계

```text
Created
→ ValidatingContext
→ Running
→ WaitingForGuidedInput
→ WaitingForAssistedDecision
→ WaitingForTimingWindow
→ PreparingCommit
→ Committing
→ Completed

어느 상태에서든
→ Cancelling
→ Cancelled

복구 불가능 오류
→ Failed
```

### Running

서버가 Step을 순서대로 실행한다.

### WaitingForGuidedInput

대상, 위치, 옵션 등 구조화된 입력을 기다린다.

### WaitingForAssistedDecision

DM이 의미 판단과 구조화된 결과를 제출할 때까지 기다린다.

### PreparingCommit

PendingEffect를 CommitGroup으로 묶고 revision을 재검사한다.

### Completed

영구 변경, 사후 이벤트와 로그가 확정된 상태다.

## 11. StepExecutor 계약

```lua
export type StepExecutionContext = {
    executionId: ExecutionId,
    compiledRecipe: CompiledRecipe,
    compiledStep: CompiledStep,
    bindingStore: BindingStore,
    authoritativeWorld: AuthoritativeWorldView,
    pendingEffectWriter: PendingEffectWriter,
    timingWindowService: TimingWindowService,
    budgetTracker: RecipeBudgetTracker,
    cancellationToken: CancellationToken,
}

export type StepRunResult =
    { status: "Continue", outputs: {[string]: unknown} }
    | { status: "Suspend", pendingInput: PendingInputDefinition }
    | { status: "Branch", outcome: string, outputs: {[string]: unknown}? }
    | { status: "Fail", error: StepExecutionError }

StepExecutor.run(context: StepExecutionContext): StepRunResult
```

실행 규칙:

1. 현재 Step budget 소비
2. 입력 바인딩 타입 확인
3. 현재 권위 상태와 revision 확인
4. handler 실행
5. 출력 타입 검증
6. BindingStore 기록과 seal
7. Step 결과 저널 기록
8. 다음 transition 결정

Handler는 다음만 반환할 수 있다.

- 타입 있는 출력
- PendingEffect
- TimingWindow 요청
- PendingInput 정의
- Branch outcome
- Presentation 요청

Handler가 직접 DataStore를 쓰거나 Actor HP를 변경할 수 없다.

## 12. Guided 입력

```lua
export type PendingInputDefinition = {
    pendingInputId: PendingInputId,
    executionId: ExecutionId,
    stepInstanceId: StepInstanceId,
    inputKind: string,
    responderPolicy: ResponderPolicy,
    inputSchemaId: string,
    candidateSnapshot: unknown?,
    expiresAt: number?,
    cancelPolicy: string,
}
```

클라이언트 응답:

```lua
export type RecipeInputResponse = {
    requestId: string,
    pendingInputId: PendingInputId,
    executionId: ExecutionId,
    payload: unknown,
    expectedExecutionRevision: integer,
}
```

서버는 반드시 다시 검사한다.

- 응답자 권한
- pending input 활성 상태
- payload schema
- 대상 존재와 revision
- 거리, 시야, 자원, 타이밍
- 중복 requestId

UI가 보여준 후보 목록은 권위가 아니다.

## 13. Assisted 결정

Assisted Step은 자유 텍스트를 규칙 결과로 직접 사용하지 않는다.

예시:

```text
Minor Illusion 판단

DM UI 설명:
- 환상 설명
- 관찰자
- 현재 장면 정보

DM 제출 결과:
- believed
- disbelieved
- investigate_required
- custom_no_mechanical_effect
```

필요하면 DM 메모를 추가할 수 있지만, 기계적 결과는 등록된 구조화 enum 또는 schema를 사용한다.

DM이 장기간 응답하지 않으면 Recipe는 안전하게 대기하며 세션 저장 대상이 된다.

## 14. PendingEffect와 Commit

Effect Step은 영구 상태를 직접 변경하지 않는다.

```text
CreateDamage
→ PendingDamage

ApplyCondition
→ PendingConditionApplication

MoveActor
→ PendingMovement
```

Commit 흐름:

```text
PendingEffect 수집
→ 동시성 그룹 정렬
→ 반응·Override 적용
→ 최종 revision 검사
→ CommitGroup 원자 확정
→ 명령 저널 기록
→ 사후 RuleEvent
```

같은 `CommitGroupId`는 한 번만 확정된다.

Commit 실패 시 정책:

- revision 충돌: 안전한 재계산 가능 여부 판단
- 대상 삭제: BranchableFailure 또는 전체 취소
- 일부 성공: 허용하지 않음
- Presentation 실패: Commit 유지

## 15. 실행 예산

RecipeCompiler와 런타임이 모두 제한한다.

```lua
export type RecipeBudgetDefinition = {
    maxExecutedSteps: integer,
    maxLoopIterations: integer,
    maxTargets: integer,
    maxPendingEffects: integer,
    maxPresentationRequests: integer,
    maxSuspensions: integer,
    maxNestedSubRecipes: integer,
}
```

초기 기본값은 구현 프로파일에서 관리하며 콘텐츠가 상향할 수 없다.

예산 초과:

```text
RECIPE_RUNTIME_STEP_BUDGET_EXCEEDED
RECIPE_RUNTIME_EFFECT_BUDGET_EXCEEDED
RECIPE_RUNTIME_TARGET_BUDGET_EXCEEDED
RECIPE_RUNTIME_SUSPENSION_BUDGET_EXCEEDED
```

예산 초과는 부분 Commit 전에 실행 실패로 종료한다.

## 16. 취소

### 사용자 취소 가능

- Guided 입력을 아직 제출하지 않은 상태
- Assisted 판단 대기 상태
- Commit 전 선택 단계

### 일반 취소 불가

- 권위 굴림 결과 공개 후
- Commit 진행 중
- Commit 완료 후

`Q`는 현재 PendingInput을 취소 요청할 수 있지만, 이미 제출된 서버 명령을 되돌리는 키가 아니다.

취소 시 예약 자원은 정책에 따라 해제하고, 영구 소모된 자원은 복구하지 않는다.

## 17. 저장과 복구

다음 상태는 직렬화 가능해야 한다.

```text
executionId
recipeId + recipeHash
currentStepOrdinal
executionState
BindingStore snapshot
sealed step ordinals
reservedCosts
PendingEffect draft
PendingInput
TimingWindow state reference
budget counters
processed request IDs
```

복구 순서:

```text
CompiledRecipe hash 확인
→ BindingStore 복원
→ 참조 ID와 revision 검사
→ PendingInput 또는 TimingWindow 재발행
→ 안전한 상태에서 실행 재개
```

Recipe 버전이 사라졌거나 hash가 다르면 자동 재개하지 않고 DM 복구 화면으로 넘긴다.

## 18. 멱등성

다음 키를 중복 방지에 사용한다.

```text
executionId + stepInstanceId
pendingInputId + requestId
resolutionId
commitGroupId
```

동일한 응답 재전송은 이전 결과를 반환하거나 `ALREADY_PROCESSED`로 처리한다.

## 19. Presentation 격리

Presentation Step은 다음 요청만 생성한다.

```lua
export type PresentationRequest = {
    presentationId: string,
    executionId: ExecutionId,
    recipeId: string,
    slot: string,
    moduleId: string,
    bindings: unknown,
    synchronizationPolicy: string,
}
```

Presentation 요청 실패 정책:

- 모듈 없음: fallback 또는 생략
- 대상 소실: 안전한 world position fallback
- 클라이언트 미응답: 서버 해결 계속
- 연출 timeout: 다음 규칙 Step 진행

주사위처럼 결과 공개 시점을 통제하는 연출은 별도 Presentation Gate를 사용하지만, 결과 자체는 서버에서 이미 봉인되어 있어야 한다.

## 20. Result와 오류

```lua
export type Result<T, E> =
    { ok: true, value: T }
    | { ok: false, error: E }
```

오류 공통 필드:

```lua
export type RecipeRuntimeError = {
    code: string,
    executionId: ExecutionId?,
    recipeId: RecipeId?,
    stepInstanceId: StepInstanceId?,
    retryable: boolean,
    userMessageKey: string?,
    diagnosticMessage: string,
    context: {[string]: unknown}?,
}
```

클라이언트에는 diagnosticMessage와 내부 context를 그대로 보내지 않는다.

## 21. 로깅과 진단

구조화 로그 이벤트:

```text
RecipeExecutionStarted
RecipeStepStarted
RecipeStepCompleted
RecipeSuspended
RecipeInputAccepted
RecipeInputRejected
RecipeTimingWindowOpened
RecipeCommitPrepared
RecipeCommitCompleted
RecipeExecutionCancelled
RecipeExecutionFailed
RecipeExecutionRecovered
```

모든 이벤트는 `executionId`, `recipeId`, `stepInstanceId`, elapsed time을 포함한다.

민감한 DM 비밀, 숨겨진 대상과 비공개 Binding은 플레이어 로그에 포함하지 않는다.

## 22. 성능 기준

초기 기준:

- 컴파일된 Recipe는 매 실행마다 재컴파일하지 않는다.
- 일반적인 30 Step 이하 Recipe의 서버 준비 시간은 프레임 장기 정지를 유발하지 않아야 한다.
- Binding 조회는 선형 문자열 검색을 사용하지 않는다.
- 실행 중 전체 Registry 순회를 금지한다.
- `ForEach`는 대상 목록을 한 번 검증한 뒤 제한된 snapshot을 사용한다.
- 긴 다중 대상 처리는 서버 작업 예산에 따라 분할할 수 있지만 Commit 원자성은 유지한다.
- 비활성 실행은 Heartbeat마다 polling하지 않는다.

정확한 ms 예산은 프로파일링 후 별도 성능 ADR로 고정한다.

## 23. 테스트

### 단위 테스트

- StepDefinition 유효성 검사
- Registry 중복·freeze
- Binding 타입 불일치
- 잘못된 transition
- 제한 없는 반복 거부
- budget 정적 계산
- 출력 seal 후 재쓰기 거부

### 컴파일 테스트

- 정상 Sequence
- Branch의 모든 outcome 연결
- ForEach 상한
- SubRecipe 순환 참조
- Guided Step 뒤 직렬화 불가 Binding 탐지
- PresentationOnly Step의 권위 출력 금지

### 실행 테스트

- Executable 연속 실행
- Guided 선택 후 재개
- Assisted DM 결정 후 재개
- 반응 TimingWindow 중단·재개
- Commit 직전 revision 충돌
- 같은 입력 두 번 전송
- 같은 CommitGroup 두 번 요청

### 복구 테스트

- Guided 대기 중 서버 종료
- 굴림 봉인 후 연출 중 종료
- PendingEffect 생성 후 Commit 전 종료
- Recipe hash 불일치
- 참조 Actor 삭제

### 보안 테스트

- 존재하지 않는 StepTypeId
- 클라이언트가 후보 외 대상 제출
- 다른 플레이어의 PendingInput 응답
- 임의 handlerId 주입
- budget 우회 시도
- 숨겨진 Binding 조회 시도

## 24. 완료 조건

- StepRegistry가 부팅 시 등록되고 콘텐츠 로드 전에 동결된다.
- RecipeCompiler가 타입·그래프·예산 오류를 로딩 단계에서 거부한다.
- BindingStore가 타입 있는 슬롯과 직렬화 snapshot을 지원한다.
- StepExecutor가 Executable·Guided·Assisted를 같은 상태기계로 처리한다.
- 모든 영구 변경이 PendingEffect와 CommitGroup을 통과한다.
- 중복 입력과 Commit이 멱등하게 처리된다.
- 대기 중 실행이 저장·복구된다.
- Presentation 오류가 규칙 Commit을 파괴하지 않는다.
- 단위·통합·복구·보안 테스트가 통과한다.
- 구조화 로그와 성능 측정 지점이 존재한다.

## 25. 후속 명세

```text
specs/shared/002-standard-step-handler-contracts.md
→ Selection, Validation, Roll, Effect handler별 공통 인터페이스

specs/rules/001-roll-and-outcome-steps.md
→ 공격·내성·피해·회복 굴림

specs/rules/002-pending-effect-steps.md
→ 피해·회복·상태·이동·자원

specs/rules/003-guided-and-assisted-input-steps.md
→ 대상 선택과 DM 판단

specs/presentation/001-presentation-step-runtime.md
→ VFX·카메라·화면 효과 실행
```
