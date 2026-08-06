# RVTT Accessibility and Motion Policy

- 상태: CURRENT
- 문서 종류: Global UX Accessibility Policy
- 작성일: 2026-08-05
- Policy Work Order: [`CURRENT-WORK-ORDER`](CURRENT-WORK-ORDER.md)
- Visual Policy: [`Visual Design Policy`](visual-design-policy.md)
- Interaction Policy: [`Interaction and Input Policy`](interaction-and-input-policy.md)
- UI Runtime 권위: [`UI Projection Runtime`](../../architecture/ui-projection-view-model-input-context-and-recovery-runtime-contract.md)

이 문서는 PC 키보드·마우스 초기 범위에서 UI 가독성, 입력 접근성, Motion Safety와 Camera Comfort의 최소 기준을 정의한다.

## 1. 기본 원칙

- 접근성은 별도 Mode가 아니라 모든 Component의 기본 계약이다.
- 색, Motion, Hover, 소리 중 하나만으로 의미를 전달하지 않는다.
- 사용자의 Hard Limit은 DM Presentation 요청과 Campaign Theme보다 우선한다.
- 접근성 설정은 Local Preference이며 Gameplay Authority를 바꾸지 않는다.
- 낮은 품질·Reduced Motion에서도 규칙 결과와 위험 정보는 유지한다.

## 2. UI Scale과 해상도

- User UI Scale은 0.80–1.40 구조를 지원한다.
- Scale 변경 후 Button, Text, Tooltip과 Focus Ring이 겹치지 않아야 한다.
- 좁은 화면에서는 핵심 조작을 유지하고 부가 정보는 접기·Scroll·Side Sheet로 이동한다.
- Roblox CoreGui Inset과 안전 영역을 반영한다.
- 절대 픽셀 위치만으로 주요 Control을 배치하지 않는다.
- 확대 시 중앙 전장 안전 영역이 완전히 사라지면 HUD 축약 Mode를 사용한다.

## 3. 텍스트 가독성

- 기본 본문은 Visual Policy의 `type.body` 이상을 사용한다.
- 작은 Caption은 핵심 규칙·비용·오류 메시지에 사용하지 않는다.
- 긴 한국어 문구가 잘릴 때 Ellipsis만 사용하지 않고 전체 내용을 확인할 경로를 제공한다.
- 배경 Texture·VFX 위 Text에는 읽기 가능한 Surface 또는 Outline을 제공한다.
- 숫자와 단위는 분리되지 않게 표시한다.
- 한 문단이 길어지면 Heading, Bullet, Table 또는 Details로 구조화한다.

## 4. 색과 대비

- Text·Icon·Focus·State는 배경과 구분 가능한 대비를 가져야 한다.
- 색상 구분에는 Icon, Label, Pattern, Stroke 중 하나를 함께 사용한다.
- 적·아군·중립·선택·위험을 빨강·초록만으로 구분하지 않는다.
- Color Vision Profile을 추가할 수 있도록 Team·State 색을 Semantic Token으로 유지한다.
- Disabled는 단순 Opacity 감소만 사용하지 않고 상태와 이유를 제공한다.
- Focus Ring은 Theme Accent와 독립된 `focus.ring` Token을 사용한다.

## 5. Keyboard와 Focus

- 모든 핵심 Panel Action은 Keyboard Focus로 접근 가능해야 한다.
- Focus 이동 순서는 화면의 시각·의미 순서와 일치해야 한다.
- Focus를 잃는 Panel Rebuild를 피하고, Replica Commit 후 가능한 동일 Stable Control로 복원한다.
- Modal은 Focus를 내부에 제한하며 종료 시 안전한 이전 Focus로 돌아간다.
- Text Input 중 Gameplay Shortcut을 실행하지 않는다.
- Key Hint는 현재 Binding Profile에서 생성하며 문구에 물리 키를 하드코딩하지 않는다.

## 6. Pointer 접근성

- 주요 Action Target은 충분한 크기를 갖는다.
- 작은 Icon이 필요하면 주변 Hit Area를 확장한다.
- Hover 정보는 Focus 또는 Click으로도 열 수 있다.
- Drag만 가능한 기능에는 Click→선택→목적지 Confirm 같은 대체 경로를 고려한다.
- 정밀 조작에는 Snap, Numeric Input, Reset과 Cancel 경로를 제공한다.
- Pointer Capture가 해제되면 Drag·Camera·Gizmo 상태를 안전하게 종료한다.

## 7. Motion 단계

사용자 Preference:

```text
Full Motion
Reduced Motion
Minimal Motion
```

### Full Motion

기본 Camera·Panel·Presentation Motion을 사용하되 과도한 반복을 피한다.

### Reduced Motion

- 큰 위치 이동과 Zoom Transition을 짧은 Fade·Cut로 변경한다.
- Camera Shake를 제거한다.
- 반복 Pulse와 Parallax를 제거한다.
- UI Scale Pop을 제거한다.
- 중요한 결과는 Text·Icon으로 유지한다.

### Minimal Motion

- 비필수 Tween을 즉시 전환한다.
- Presentation Camera 이동을 기본 거절 또는 고정 Focus로 축약한다.
- Particle·Trail·Screen Distortion을 최소화한다.
- Authority Reveal 순서만 유지하고 연출 대기는 최소화한다.

Motion Setting은 Gameplay Timeout, Roll Outcome와 Turn Order를 변경하지 않는다.

## 8. Flash·Shake·Screen Effect

- 빠른 전체 화면 Flash를 기본 연출로 사용하지 않는다.
- Flash는 밝기·빈도·면적 Hard Limit을 가진다.
- Critical Hit도 강한 Flash 없이 Icon·Text·Color·Motion 조합으로 표현할 수 있어야 한다.
- Camera Shake는 강도 설정과 완전 Off를 제공한다.
- 지속 Blur·Chromatic Aberration·Vignette가 Text 판독을 방해하지 않아야 한다.
- Damage Screen Effect가 상태 UI와 Targeting을 가리지 않는다.

정확한 수치는 Roblox 실제 화면과 저사양 환경에서 측정 후 별도 Performance·Accessibility Spec에서 확정한다.

## 9. Camera Comfort

- Camera Auto Movement는 시작·대상·종료를 예측할 수 있어야 한다.
- Hover만으로 Camera를 이동하지 않는다.
- 사용자가 수동 조작하면 낮은 우선순위 Auto Focus를 중단할 수 있다.
- High-priority Presentation 후 이전 Camera Transform·Follow·Focus를 복원한다.
- Follow와 Focus를 분리한다.
- Occlusion Correction은 급격한 진동을 만들지 않는다.
- Reduced Motion 사용자는 큰 Sweep·Orbit·Rapid Zoom을 받지 않는다.
- DM Observe와 Player Preview 전환에는 현재 View Mode Label을 표시한다.

## 10. 시간 압박과 Prompt

- Authority Timeout은 Server Time을 사용한다.
- 남은 시간은 Text와 시각 Progress를 함께 표시한다.
- 시간 만료 시 기본 결과를 숨기지 않는다.
- 읽기 어려울 정도로 짧은 Client Animation이 응답 시간을 소비하지 않는다.
- 연결 문제 중 Prompt Timeout을 조용히 진행하지 않고 서버 정책에 따라 Pause·Grace·Fallback을 적용한다.
- 반복 입력이 어려운 사용자를 위해 Hold 대신 Toggle 또는 단일 Confirm 경로를 우선한다.

## 11. 정보 이해 지원

- 전문 용어에는 짧은 설명 또는 Journal Link를 제공한다.
- Action은 이름뿐 아니라 비용·대상·결과 종류를 보여준다.
- 계산 결과에는 필요할 때 Breakdown을 펼쳐볼 수 있다.
- 오류 문구는 다음 행동을 포함한다.
- Icon-only Control에는 Label·Tooltip·Accessible Name을 제공한다.
- Status Badge는 텍스트 요약 View를 제공할 수 있어야 한다.

## 12. 저사양·성능 Fallback

줄일 수 있는 것:

- Particle 수
- Trail·Decal
- Ambient Animation
- 비필수 Shadow·Blur
- 동시에 재생되는 Presentation

줄이면 안 되는 것:

- 결과 Text
- 위험·Target·Range 표시
- Focus Ring
- Prompt와 Confirm 상태
- 현재 Turn·Mode
- 오류·복구 상태
- Player·DM 공개 경계

성능 저하 때문에 Gameplay 상태를 숨기거나 Authority 적용 순서를 바꾸지 않는다.

## 13. 현재 비범위

- 모바일·Touch 전용 Layout
- 게임패드 전체 Binding
- Screen Reader 플랫폼 통합
- Audio Cue·SFX·Voice 지원

다만 현재 Component는 Semantic Action, Accessible Name과 Text Alternative를 유지해 후속 지원을 막지 않아야 한다.

## 14. 금지 패턴

- 색으로만 적·아군·성공·실패 구분
- Hover만 가능한 설명
- Focus Ring 제거
- Text Input 중 Q/E Gameplay Action 실행
- Motion Off가 Gameplay 결과를 생략
- 강한 Flash·Shake를 끌 수 없음
- Camera 연출 완료를 Authority Commit 조건으로 사용
- UI Scale 변경 시 Confirm Button이 화면 밖으로 나감
- 낮은 품질에서 Warning·Range·Target 표시 제거
- Timeout을 Animation 종료 시각으로 계산

## 15. 구현 검수

- UI Scale 최소·최대에서 핵심 경로가 유지된다.
- Keyboard Focus 순서와 복원이 동작한다.
- Color-only·Hover-only 정보가 없다.
- Reduced·Minimal Motion에서 같은 결과를 이해한다.
- Camera Shake·Flash를 제한하거나 끌 수 있다.
- 저사양 Fallback에서 핵심 판독성이 유지된다.
- Prompt Timeout과 연결 상태가 명확하다.
- 한국어 긴 문구와 큰 숫자에서 Layout이 깨지지 않는다.
