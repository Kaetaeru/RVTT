# 40. 모듈형 VFX와 프레젠테이션 레시피 모델

- 상태: 초안
- 작성일: 2026-08-03
- 관련 결정: [`ADR-0046`](../../decisions/ADR-0046-modular-presentation-recipes-and-extension-contracts.md)

## 1. 목적

공격, 주문, Feature, 상태 효과와 오브젝트 행동의 연출을 재사용 가능한 VFX 모듈로 만들고 규칙 해결 단계 사이에 안전하게 배치한다.

```text
규칙 결과
→ 서버 권위

VFX·카메라·화면 흔들림
→ 클라이언트 프레젠테이션
```

## 2. PresentationRecipe

```text
PresentationRecipe
├─ recipeId
├─ timelineNodes[]
├─ synchronizationMarkers[]
├─ visibilityPolicy
├─ qualityPolicy
├─ fallbackPolicy
└─ version
```

노드는 순차, 병렬, 조건부와 제한 반복을 지원한다. 무제한 반복과 콘텐츠 자유 코드는 금지한다.

## 3. 표준 슬롯

```text
pre_action
source_cast
source_motion
source_release
projectile_or_travel
target_warning
impact
target_reaction
environment
camera
screen_overlay
post_action
```

콘텐츠가 모든 슬롯을 채울 필요는 없다.

## 4. VFXModule 계약

```text
VFXModuleDefinition
├─ moduleId
├─ acceptedParameters
├─ anchorRequirements
├─ durationPolicy
├─ cancelPolicy
├─ poolingPolicy
├─ qualityVariants
└─ fallbackModuleId?
```

대표 모듈:

- source aura burst
- shout ring
- weapon trail
- projectile
- beam
- ground decal
- impact burst
- target hit flash
- knockback streak
- camera shake
- camera impulse
- screen vignette
- color flash
- world light pulse
- particle attachment
- floating text

## 5. 앵커

리그가 없는 3D 토큰을 사용하므로 Humanoid 뼈대에 의존하지 않는다.

```text
source.pivot
source.center
source.top
source.weapon_origin
source.custom_socket

target.pivot
target.center
target.top
target.hit_point
world.position
path.sample
camera
screen
```

`custom_socket`이 없으면 안전한 기본 앵커로 대체한다. 원본 토큰 모델에 필수 Attachment를 강제하지 않고, 배치·등록 과정에서 선택적 소켓 프로필을 연결할 수 있다.

## 6. 공격 예시

일반 근접 공격:

```text
source_motion: weapon_swing
parallel: weapon_trail
impact: slash_burst
 target_reaction: hit_flash
camera: light_impulse
```

광분 상태 공격:

```text
pre_action: rage_shout
pre_action: source_aura_pulse
source_motion: weapon_swing
impact: slash_burst
camera: stronger_impulse
```

광분은 별도 공격 레시피를 복제하지 않고 PresentationAugment로 기존 공격에 삽입된다.

## 7. PresentationAugment

Feature, Feat, 장비와 EffectInstance는 다음을 제공할 수 있다.

```text
PresentationAugment
├─ targetSlot
├─ insertion: before | after | replace | parallel
├─ predicate
├─ moduleId 또는 subRecipeId
├─ parameters
├─ priority
└─ stackingPolicy
```

예시:

- 치명타 시 화면 흔들림 강화
- 화염 무기일 때 추가 불꽃 궤적
- 은신 공격일 때 source_motion 축소
- 거대 대상 명중 시 저주파 충격파
- 저항으로 피해가 0이면 다른 impact 사용

## 8. 규칙 동기화 마커

일반 VFX는 규칙을 막지 않지만, 필요한 시점에는 마커를 사용한다.

```text
release_marker
projectile_arrival_marker
impact_reveal_marker
completion_marker
```

서버는 결과를 이미 권위 있게 계산하며, 마커는 공개와 연출 순서만 조정한다. 클라이언트 ACK가 없으면 타임아웃 후 진행한다.

## 9. 카메라와 화면 효과

```text
CameraEffect
├─ impulse
├─ shake
├─ focus
├─ short_zoom
├─ tracked_pan
└─ cinematic_cut

ScreenEffect
├─ vignette
├─ color_flash
├─ blur_pulse
├─ directional_damage
└─ accessibility_safe_flash
```

카메라 연출은 사용자 설정과 멀미 방지 옵션을 존중한다. DM 강제 연출도 최소화·스킵 정책을 가진다.

## 10. 품질 단계

```text
high
medium
low
minimal
```

낮은 품질에서는 파티클 수, 빛, 데칼과 화면 효과를 줄이지만 핵심 타이밍과 판독성은 유지한다.

## 11. 실패 격리

VFX 모듈 오류 시:

```text
해당 모듈 중단
→ fallback 실행 또는 생략
→ 오류 로그
→ 규칙 해결 계속
```

PresentationRecipe 오류가 EffectRecipe를 롤백시키지 않는다.

## 12. 풀링과 최적화

- 파티클·데칼·투사체 표현은 객체 풀 사용
- 멀리 있는 연출은 단순 버전 사용
- 보이지 않는 ViewY 상부와 다른 구역은 컬링
- 카메라 밖 화면 효과 미생성
- 같은 프레임의 다수 충격은 예산에 따라 병합

## 13. 제작 도구

VFX 라이브러리에서 모듈을 검색하고 레시피 슬롯에 드래그한다.

```text
타임라인 미리보기
source/target 더미 지정
속도 조절
중간 마커 확인
품질 단계 비교
취소·중단 테스트
```

## 14. 플러그인과 확장 구조

여기서 말하는 플러그인은 나중에 별도 기능 팩이 RVTT에 새 도구, 가져오기 형식, VFX 모듈 또는 콘텐츠 타입을 등록하는 구조다.

초기에는 사용자 임의 Luau 실행을 지원하지 않는다. 대신 다음 내부 계약을 유지한다.

```text
ToolRegistry
VFXModuleRegistry
PresentationRecipeRegistry
ContentImporterRegistry
PanelRegistry
RulePointCatalog
```

모든 등록 항목은 타입 ID, 버전, 검증기, 마이그레이션과 오류 격리를 가져야 한다. 미래에 확장을 허용하더라도 신뢰된 빌드 포함 모듈 또는 검증된 패키지부터 시작한다.
