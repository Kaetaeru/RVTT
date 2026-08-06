# Presentation Recipe, Playback Priority와 Extension Runtime 계약

- 상태: 확정
- 문서 종류: Architecture
- 즉시 구현 명세 가능성: `READY_WITH_DEFAULTS`
- 남은 기본값:
  - Presentation Queue 동시 실행 상한
  - 품질 등급별 파티클·데칼·빛 예산
  - Camera Shake와 Flash의 접근성 기본값
  - Marker ACK timeout과 장면별 최대 연출 지연
  - Recipe Hot Reload 보존 버전 수
- 작성일: 2026-08-04
- 관련 ADR:
  - [`ADR-0046`](../decisions/ADR-0046-modular-presentation-recipes-and-extension-contracts.md)
  - [`ADR-0053`](../decisions/ADR-0053-step-level-automation-and-standard-recipe-step-library.md)
  - [`ADR-0069`](../decisions/ADR-0069-authoritative-roll-records-and-presentation-gated-resolution.md)
  - [`ADR-0074`](../decisions/ADR-0074-projection-only-camera-policies-with-separate-focus-and-follow.md)
  - [`ADR-0075`](../decisions/ADR-0075-versioned-data-driven-and-fault-isolated-presentation-runtime.md)
- 상위 문서:
  - [`Runtime Architecture Principles`](runtime-architecture-principles.md)
  - [`Compiled Build와 Authoritative State 분리 패턴`](compiled-build-and-authoritative-state-pattern.md)
  - [`Camera Runtime 계약`](camera-policy-focus-follow-and-presentation-runtime-contract.md)
  - [`Visibility, Knowledge와 Detection Runtime 계약`](visibility-knowledge-detection-and-hover-information-runtime-contract.md)
- 관련 이전 문서:
  - [`모듈형 VFX와 프레젠테이션 레시피 모델`](modular-vfx-and-presentation-recipe-model.md)

## 1. 목적

이 문서는 공격, 주문, 주사위, 상태, 이동, 상호작용, UI와 카메라 연출을 규칙 실행과 분리된 데이터 기반 Runtime으로 재생하는 계약을 정의한다.

```text
Authority Event
→ PresentationIntent
→ CompiledPresentationRecipe
→ PlaybackPlan
→ Client Presentation
```

Presentation 실패, 지연, 생략 또는 교체는 HP, 위치, 판정, 자원, Effect와 Transaction 결과를 바꾸지 않는다.

## 2. 권위 경계

```text
Gameplay Outcome
≠ Presentation Outcome
```

Presentation Runtime은 다음을 직접 변경할 수 없다.

- Actor·Item·Effect 권위 상태
- Roll 결과와 ResolutionOutcome
- Selection과 Frozen Binding
- Navigation과 충돌
- Visibility·Knowledge 권위 상태
- Encounter Turn과 Action Opportunity

규칙적으로 결과 공개 순서가 필요한 경우에도 Presentation은 `Reveal Gate`와 Marker만 제공하며 결과 자체를 결정하지 않는다.

## 3. Source, Build와 Playback 분리

```text
PresentationRecipeSource
→ Presentation Compiler
→ Immutable CompiledPresentationRecipe
→ PresentationPlaybackInstance
```

```text
CompiledPresentationRecipe
├─ recipeId
├─ recipeVersion
├─ timelineGraph
├─ parameterSchema
├─ moduleBindings
├─ markerPlan
├─ audiencePolicy
├─ qualityVariants
├─ accessibilityPolicy
├─ fallbackPlan
└─ contentHash
```

진행 중 Playback은 시작 당시 `recipeVersion`과 `contentHash`를 고정한다. 새 버전을 활성화해도 진행 중 연출은 중간에 바뀌지 않는다.

## 4. PresentationIntent

규칙·UI·Selection·Dice 시스템은 Roblox Instance나 VFX Module을 직접 실행하지 않고 타입 있는 Intent만 제출한다.

```text
PresentationIntent
├─ intentId
├─ intentKind
├─ sourceExecutionId?
├─ sourceProjectionRef?
├─ targetProjectionRefs[]
├─ worldBindings[]
├─ semanticTags[]
├─ frozenParameters
├─ audienceBinding
├─ importance
├─ timingPolicy
└─ revision
```

대표 `intentKind`:

```text
attack
spell_cast
spell_impact
roll_reveal
damage_result
healing_result
condition_applied
condition_removed
interaction_transition
movement_event
turn_change
ping
ui_feedback
custom_registered
```

## 5. Timeline과 표준 Slot

Recipe는 순차·병렬·조건부·제한 반복 노드를 지원한다.

```text
pre_action
source_signal
source_motion
source_release
travel
warning
impact
target_reaction
environment
camera
screen_overlay
ui_feedback
post_action
```

노드는 Slot 이름별 하드코딩 분기가 아니라 등록된 `PresentationStepHandler`를 참조한다. 자유 Luau 실행과 무제한 반복은 금지한다.

## 6. 모듈과 확장 등록점

```text
PresentationModuleRegistry
├─ moduleTypeId
├─ handlerVersion
├─ parameterValidator
├─ capabilityRequirements
├─ qualityVariants
├─ fallbackModuleTypeId?
├─ migrationAdapter?
└─ diagnostics
```

초기 모듈 예시:

- token motion
- source aura
- weapon trail
- projectile·beam
- impact burst
- hit flash
- ground decal
- floating text
- highlight·outline
- camera request
- camera shake
- screen flash·vignette
- UI pulse
- turn indicator

새 모듈은 Registry 등록으로 추가하며 Presentation Runtime 핵심 코드를 수정하지 않는다.

## 7. Recipe Augment와 교체

Feature, Item, Effect, Critical 결과와 캠페인 Theme는 Recipe를 복제하지 않고 Augment를 기여할 수 있다.

```text
PresentationAugment
├─ targetSlot
├─ insertionPolicy
├─ predicate
├─ moduleOrSubRecipeRef
├─ parameterOverrides
├─ priority
└─ stackingPolicy
```

지원 정책:

```text
before
after
parallel
replace
suppress
```

예시:

- 광분 상태가 공격 전에 외침과 Aura를 추가
- 화염 무기가 Travel과 Impact를 교체
- 치명타가 Camera Shake와 Floating Text를 강화
- 피해 0이 일반 Hit Flash를 저항 표현으로 교체

## 8. 플레이테스트와 Hot Swap

연출 수치와 모듈 조합은 코드가 아니라 Source Recipe에 둔다.

조정 가능한 값 예시:

- 시작 지연과 지속 시간
- 모듈 간 간격
- 이동 속도와 easing
- 파티클 밀도와 잔상 길이
- 화면 흔들림 강도
- 카메라 보정량
- Flash 밝기와 지속 시간
- Floating Text 크기와 체류 시간

```text
Authoring Recipe
→ 검증·Preview
→ Candidate Compiled Version
→ 세션 활성화
→ 이전 버전 보존·Rollback
```

플레이테스트 후 코드 수정 없이 다음이 가능해야 한다.

- Recipe 전체 교체
- 특정 Slot 모듈 교체·비활성화
- 수치 조정
- 품질 프리셋 교체
- 이전 활성 버전 복원
- 캠페인·Scene·사용자별 Presentation Profile 변경

Hot Swap은 새 Playback에만 적용한다.

## 9. 프리셋과 계층형 Override

기본 프리셋:

```text
minimal
standard
cinematic
accessibility_safe
custom
```

최종 Profile은 다음 계층으로 합성한다.

```text
Product Default
→ Campaign Profile
→ Scene Profile
→ DM Presentation Policy
→ User Quality·Accessibility Preference
→ Runtime Budget Degradation
```

하위 계층은 권위 규칙이나 비밀 정보 공개 정책을 Override할 수 없다.

## 10. Playback Queue와 우선순위

```text
PresentationIntent
→ Queue Admission
→ Budget·Audience·Visibility 검사
→ PlaybackPlan
→ 실행·축약·병합·생략
```

중요도:

```text
required_reveal
important
standard
ambient
```

- `required_reveal`: Roll 공개 등 최소 판독성을 보장하되 timeout으로 진행
- `important`: Reaction, Critical 등 우선 재생
- `standard`: 일반 공격·상호작용
- `ambient`: 혼잡 시 먼저 생략 가능

Gameplay 진행을 무기한 기다리지 않는다.

## 11. Marker와 공개 Gate

지원 Marker:

```text
source_release
travel_arrival
impact_reveal
result_reveal
completion
custom_registered
```

Marker는 Presentation 순서와 결과 공개 시점을 연결하지만 RuleExecution 결과를 바꾸지 않는다.

Client ACK가 없거나 Playback이 실패하면 hard timeout 후 안전한 Reveal·Resume을 수행한다.

## 12. Camera 연동

Presentation 모듈은 Camera를 직접 조작하지 않는다.

```text
Presentation Module
→ CameraRequest
→ CameraPolicyResolver
```

Camera Runtime은 사용자 설정, Free Override, DM Observe와 우선순위를 검사해 요청을 허용·축약·거절한다.

Hover는 Presentation Camera를 요청하지 않는다.

## 13. Audience와 비밀 정보

PresentationIntent는 관찰자별 Projection만 사용한다.

- 숨은 Actor의 위치를 VFX Anchor로 플레이어 Client에 전달하지 않는다.
- 미식별 주문·아이템의 실제 이름을 Floating Text에 넣지 않는다.
- DM 전용 Trigger와 Secret Object 연출은 Player Audience에 생성하지 않는다.
- 플레이어별 Visibility가 다르면 Audience별 PlaybackPlan을 만들 수 있다.

## 14. 실패 격리와 Fallback

```text
모듈 오류
→ 해당 모듈 중단
→ Fallback 또는 생략
→ 진단 기록
→ 나머지 Playback과 Gameplay 계속
```

Recipe 컴파일 오류는 해당 Recipe 버전만 비활성화하고 마지막 정상 버전 또는 안전 기본 Recipe를 사용한다.

Presentation 오류는 Authority Transaction을 롤백하지 않는다.

## 15. 성능과 품질 저하

Presentation Budget은 사용자별로 적용한다.

저하 순서 예시:

```text
파티클 수 감소
→ 잔상·데칼 축소
→ 화면 효과 제거
→ 먼 거리 연출 단순화
→ 중복 충격 병합
→ ambient 생략
```

핵심 판독성, 결과 공개와 위험 영역 Warning은 유지한다.

Pooling, 거리 컬링, 화면 밖 생략과 품질 Variant를 사용하며 성능 측정 없이 최적화 완료를 선언하지 않는다.

## 16. 역할 경계

### PLAYER_ONLY

- 자신의 품질·접근성 프리셋 선택
- 선택형 Camera·Shake·Flash 축소 또는 비활성화
- Q로 취소 가능한 연출 종료

### DM_ONLY

- Campaign·Scene Presentation Profile 선택
- 신뢰된 Recipe 버전 활성화·이전 버전 복원
- 중요 연출 요청과 Player Focus 제안
- Authoring Preview와 진단 확인

### SHARED

- 공개된 결과 연출 확인
- 공개된 Ping·Highlight·Turn Indicator

### SYSTEM_ONLY

- Recipe 컴파일과 버전 고정
- Queue·Budget·Marker·timeout
- Audience Projection과 Secret 차단
- Module Handler 실행과 오류 격리
- Telemetry와 Fallback

DM이 연출을 강화해도 플레이어의 접근성 Hard Limit을 무시하지 않는다.

## 17. 저장·복구·롤백

영구 저장:

- 활성 Presentation Profile과 Recipe Version Map
- 사용자 품질·접근성 설정
- DM Scene Profile과 Bookmark 참조

필요한 경우 Pending Reveal 복구용 저장:

- Playback 식별자
- 고정 Recipe 버전
- 대기 Marker
- sourceExecutionId
- timeout Deadline

저장하지 않는 것:

- Particle Instance
- Tween 진행률
- Camera Shake 현재 Offset
- Floating Text UI Instance

재접속 시 진행 중 일반 VFX를 재현할 의무는 없지만, 아직 공개되지 않은 권위 결과는 안전하게 공개하고 실행을 재개해야 한다.

전투 롤백은 권위 상태를 복원하며 이전 VFX를 역재생하지 않는다. 필요하면 새 Branch 상태를 설명하는 짧은 복원 연출만 재생한다.

## 18. 완료 조건

- 플레이테스트 후 코드 수정 없이 Recipe·모듈·수치·프리셋 교체 가능
- 진행 중 Playback의 버전 안정성 보장
- 모듈 하나의 실패가 Gameplay와 다른 연출을 중단하지 않음
- Camera·Visibility·Accessibility 계약을 우회하지 않음
- 저사양 저하 후에도 결과와 위험 정보가 판독 가능
- 새 신뢰 모듈을 Runtime 핵심 수정 없이 Registry에 등록 가능

## 19. 금지 사항

- VFX 완료 여부로 명중·피해를 결정하지 않는다.
- Presentation Module에서 Authority State를 직접 수정하지 않는다.
- Workspace 전체를 탐색해 숨은 Anchor를 찾지 않는다.
- Client가 보낸 Recipe ID와 Parameter를 검증 없이 실행하지 않는다.
- 진행 중 Playback의 Recipe 버전을 Hot Reload로 교체하지 않는다.
- 사용자 접근성 Hard Limit을 DM 연출 요청이 무시하지 않는다.
