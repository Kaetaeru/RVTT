# Camera Policy, Focus, Follow와 Presentation Runtime 계약

- 상태: 확정
- 문서 종류: Architecture
- 즉시 구현 명세 가능성: `READY_WITH_DEFAULTS`
- 남은 기본값:
  - 이동·회전·줌 감도와 제한 범위
  - Selection Focus 화면 여백과 최소 보정량
  - Presentation Request별 기본 지속 시간과 강제 종료 상한
  - 카메라 충돌 여유 거리와 복구 속도
  - Bookmark 기본 개수와 단축키
- 작성일: 2026-08-04
- 관련 ADR:
  - [`ADR-0050`](../decisions/ADR-0050-free-tactical-camera-and-presentation-priority.md)
  - [`ADR-0070`](../decisions/ADR-0070-orthogonal-session-modes-contexts-overlays-and-transitions.md)
  - [`ADR-0071`](../decisions/ADR-0071-input-context-selection-sessions-and-frozen-bindings.md)
  - [`ADR-0074`](../decisions/ADR-0074-projection-only-camera-policies-with-separate-focus-and-follow.md)
- 상위 문서:
  - [`Session Play Mode, Context, Overlay와 Transition 계약`](session-play-mode-context-overlay-and-transition-contract.md)
  - [`Selection, Targeting, Preview와 Frozen Binding Runtime 계약`](selection-targeting-preview-and-frozen-binding-runtime-contract.md)
  - [`Visibility, Knowledge, Detection과 Hover Information Runtime 계약`](visibility-knowledge-detection-and-hover-information-runtime-contract.md)
  - [`Scene Streaming, Client Interest와 Ready Activation 계약`](scene-streaming-client-interest-and-ready-activation-contract.md)
- 관련 시스템:
  - [`자유 전술 카메라 모델`](../systems/camera/free-tactical-camera-model.md)

## 1. 목적

이 문서는 탐험, Encounter, DM 관전, Selection, Presentation, Replay와 Scene 전환에서 공통으로 사용하는 카메라 권위 경계를 정의한다.

핵심 원칙:

```text
Gameplay Authority
≠ Camera Authority
```

카메라는 로컬 Projection과 Presentation만 변경한다. 카메라 위치, 가림 보정, Focus와 Follow 상태는 Actor 위치, 시야 판정, Selection 결과, RuleExecution 또는 권위 게임 상태를 변경하지 않는다.

## 2. 전체 구조

```text
Session·Selection·Presentation·DM Intent
→ CameraRequest
→ CameraPolicyResolver
→ CameraController
→ Local Camera Projection
```

다른 시스템은 Roblox Camera를 직접 조작하지 않고 타입 있는 `CameraRequest`를 제출한다.

```text
CameraRequest
├─ requestId
├─ requestKind
├─ requesterKind
├─ audienceUserIds[]
├─ targetProjectionRef?
├─ framingProfile?
├─ priority
├─ interruptPolicy
├─ durationPolicy
├─ cancelPolicy
└─ revision
```

카메라 대상은 Workspace Instance가 아니라 권한 검사를 마친 `CameraTargetProjection` 또는 안전한 Transform Snapshot이다.

## 3. Focus와 Follow 분리

```text
Follow Target
→ 카메라의 장기 기준점

Focus Target
→ 현재 화면 안에 유지하거나 강조할 관심 대상
```

예시:

```text
Follow: 플레이어 캐릭터
Focus: 현재 공격 대상으로 선택한 고블린
```

Focus가 바뀌어도 Follow는 자동 해제되지 않는다. 카메라는 Follow를 중심으로 유지하면서 Focus가 화면 밖으로 벗어날 때 최소한의 Pan·Zoom 보정만 제안할 수 있다.

Hover는 Focus를 변경하지 않고 카메라 이동을 유발하지 않는다.

## 4. Camera Policy

지원 정책:

```text
free
follow_actor
selection_focus
presentation_focus
dm_observe
replay
scene_transition
restoring_previous
```

정책은 상호 배타적인 거대 Mode가 아니라 우선순위와 복원 스택을 가진 요청 결과다.

기본 우선순위:

```text
hard_scene_transition
> explicit_dm_observe
> replay
> required_resolution_presentation
> optional_presentation
> selection_focus
> follow_actor
> free
```

높은 우선순위 요청이 끝나면 이전 카메라 Transform, Follow, Focus, ViewY와 사용자 자유 조작 상태를 복원한다.

## 5. Exploration 정책

기본값은 `free`다.

- 자유 이동·회전·줌을 허용한다.
- 토큰 WASD 이동과 카메라 이동 입력은 Input Context에서 충돌하지 않게 분리한다.
- 사용자가 Follow를 켜면 제어 중인 Actor를 장기 기준점으로 사용할 수 있다.
- Actor와 멀어져도 기본적으로 강제 귀환시키지 않고 Soft Return Hint를 제공한다.
- Hover는 정보만 표시하고 카메라를 이동시키지 않는다.
- Interaction 또는 Selection Focus는 대상을 화면 안에 유지하는 최소 보정만 요청할 수 있다.

## 6. Encounter 정책

기본값은 `follow_actor + free_override`다.

- 현재 제어 Actor를 Follow 후보로 삼는다.
- 사용자는 언제든 자유 전술 카메라로 이탈할 수 있다.
- 전투 중 토큰 WASD 이동은 금지하지만 카메라 WASD 이동은 허용한다.
- 턴 변경은 강제 점프가 아니라 Follow 복귀 제안을 만들 수 있다.
- Selection Focus, Reaction Offer, 주사위와 주문 연출은 CameraRequest를 제출한다.
- 사용자의 명시적 Free Override 또는 DM Observe가 활성화되면 낮은 우선순위 자동 Focus를 억제한다.

## 7. Selection과 Hover

```text
Selection Changed
→ optional selection_focus request
→ 대상이 화면 밖일 때만 최소 보정
```

Selection Runtime은 카메라를 직접 이동하지 않는다.

Hover는 다음만 수행한다.

- Hover Information Projection 표시
- Outline·Highlight 요청

Hover만으로 CameraRequest를 생성하지 않는다.

## 8. Presentation Request

주사위, 주문, Critical, Reaction과 VFX는 `presentation_focus` 요청을 제출할 수 있다.

```text
Presentation Runtime
→ CameraRequest
→ 사용자 설정·현재 정책·우선순위 검증
→ 허용 / 축약 / 거절
```

지원 정책:

```text
optional
important
required_reveal
```

- `optional`: 사용자 설정이나 현재 Free Override에 따라 무시 가능
- `important`: 짧은 보정을 제안하지만 Q로 종료 가능
- `required_reveal`: 주사위 결과 공개처럼 규칙적으로 필요한 최소 프레이밍만 보장

연출 카메라는 Gameplay Input을 임의로 잠그지 않는다. 입력 잠금이 필요하면 별도 Presentation Overlay 또는 Pause Gate가 책임진다.

## 9. DM Observe와 Player View Preview

DM 전용 기능:

```text
Observe Player
→ 해당 플레이어의 Camera Target·ViewY·Projection Audience를 미리보기
→ DM의 조작 권한과 Actor Controller는 변경하지 않음
```

DM은 다음을 구분한다.

- 특정 플레이어 시점 관찰
- 특정 Actor Follow
- Scene Bookmark 이동
- 플레이어에게 Focus 이동 제안
- 짧은 Presentation Camera 요청

DM Observe는 플레이어 카메라를 강제로 장기 고정하지 않는다. 플레이어 카메라를 움직이는 요청은 대상, 기간, Q 취소 가능 여부를 명시한다.

## 10. Camera Bookmark

```text
CameraBookmark
├─ bookmarkId
├─ ownerUserId
├─ sceneId
├─ pivot
├─ orientation
├─ zoom
├─ viewY
├─ followProjectionRef?
├─ label
└─ revision
```

Bookmark는 사용자별 Presentation 상태다. DM Bookmark는 Scene Authoring과 세션 진행에 사용할 수 있다.

저널의 Actor·Object·Dungeon Room 링크는 권한 검사를 거쳐 안전한 Camera Target Projection을 만든 뒤 Bookmark 또는 Focus 이동에 사용할 수 있다. Journal Link 작성은 DM 전용이다.

## 11. ViewY와 가림 보정

ViewY, 지붕·벽 투명화와 카메라 충돌 보정은 사용자별 표시 상태다.

- 권위 이동·Navigation·Visibility·Fog를 변경하지 않는다.
- 숨겨진 Object나 미공개 공간을 드러내지 않는다.
- 가림 보정 대상은 현재 사용자에게 이미 Disclosure된 Presentation만 사용한다.
- Camera Runtime은 Workspace 전체를 순회해 비밀 대상을 찾지 않는다.

## 12. Replay와 Rollback

Replay는 Gameplay Camera와 분리된 `replay` Controller를 사용한다.

Rollback 확정 시 권위 게임 상태는 복원되지만 카메라는 기본적으로 현재 사용자 상태를 유지한다.

DM 또는 사용자가 선택한 경우에만 다음을 복원한다.

```text
camera transform
follow target
focus target
viewY
bookmark reference
```

Rollback Preview 중에는 `rollback_review` Overlay가 CameraRequest를 제출할 수 있지만 실제 Authority Branch를 변경하지 않는다.

## 13. Scene Transition·Reconnect·Streaming

Scene Transition에서는 Target Scene의 Entry Essential과 Camera Target Projection이 준비된 뒤 카메라를 활성화한다.

Reconnect에서는 마지막 카메라를 무조건 복원하지 않는다.

```text
Projection Ready
→ 안전한 Follow 후보 확인
→ 저장된 로컬 Camera Preference 적용
→ 유효하지 않으면 Scene 기본 Bookmark 또는 Controlled Actor로 복구
```

스트림 아웃된 대상을 Follow·Focus 중이면 마지막 안전 Transform을 잠시 유지하고, Ready timeout 후 정책에 따라 Follow를 해제하거나 대체 Target으로 전환한다.

## 14. 역할 경계

### PLAYER_ONLY

- 자신의 자유 카메라 조작
- 자신의 Follow 켜기·끄기
- 허용된 공개 Selection Focus
- 자신의 Bookmark 생성·이동
- optional Presentation Focus 거절 또는 Q 종료

### DM_ONLY

- Player View Preview와 DM Observe
- DM Bookmark와 Scene 진행 Bookmark
- 플레이어에게 Camera Focus 제안
- 제한된 짧은 Presentation Camera 요청
- 숨겨진 Authoring Object Focus
- Replay·Rollback Review Camera 제어

### SHARED

- 공개 Actor·Object Focus
- 공개 Journal Link를 통한 카메라 이동
- 공개 Replay Presentation 보기

### SYSTEM_ONLY

- CameraRequest 우선순위와 복원 스택
- 안전한 Camera Target Projection 생성
- Scene Transition Camera Gate
- Streaming Target 복구
- 사용자 설정과 Motion Safety 적용

## 15. 저장과 권위

서버 권위로 저장할 수 있는 것:

- DM이 캠페인·Scene에 저장한 Bookmark
- 공유 Presentation Camera Request의 Audit Record
- Replay Camera Track Definition

사용자 로컬 또는 개인 설정으로 저장할 것:

- 마지막 자유 카메라 Transform
- 감도·줌·Motion Safety 설정
- 개인 Bookmark
- Follow 선호

저장하지 않는 것:

- 매 프레임 Camera CFrame
- 임시 Hover
- Tween 진행률
- 일시적 벽 투명도

## 16. 금지 사항

- 카메라 위치를 Gameplay Authority 입력으로 사용하지 않는다.
- Camera Runtime이 Workspace를 직접 순회해 Target을 찾지 않는다.
- Hover만으로 카메라를 움직이지 않는다.
- Selection·Spell·Dice·VFX 코드가 Roblox Camera를 직접 조작하지 않는다.
- DM Observe를 Actor 제어권 이전으로 취급하지 않는다.
- 연출 카메라 종료 후 사용자의 이전 카메라 상태를 잃지 않는다.
- 카메라 가림 보정으로 비밀 정보를 공개하지 않는다.
