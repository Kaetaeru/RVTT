# UI·UX Global Policy Completion Audit

- 상태: COMPLETE
- 문서 종류: UI·UX Policy Completion Audit
- 감사일: 2026-08-05
- 최종 개정일: 2026-08-05
- Policy Hub: [`UI·UX Global Policies`](../ui/policies/README.md)
- Policy Work Order: [`UI·UX Policy Work Order`](../ui/policies/CURRENT-WORK-ORDER.md)
- Review Checklist: [`UI·UX Review Checklist`](../ui/policies/UI-UX-REVIEW-CHECKLIST.md)
- Accent Policy: [`Accent Theme and Color Consistency`](../ui/policies/accent-theme-and-color-consistency-policy.md)
- UI Main Guide: [`UI, Camera와 Presentation Guide`](../guides/ui/README.md)

## 1. 목적

Production UI와 Slice Acceptance 전에 RVTT 전체가 공유할 시각 언어와 UX 행동 기준이 존재하는지 검수한다. 2026-08-05 사용자 결정에 따라 깔끔하면서 화려한 디자인, 일관된 색상 체계, 사용자 선택형 Accent와 기본 Gold를 추가 검수했다.

검사 대상:

- Visual Design과 Semantic Token
- User Accent Theme과 Color Consistency
- Input Context·Q/E·1–5·Pointer·Focus·Selection
- 정보 위계·전장 안전 영역·Panel·Navigation
- Pending·Receipt·Projection·Error·Retry·Resync·Reconnect·Rollback
- UI Scale·Contrast·Keyboard·Motion·Flash·Camera Comfort·저사양 Fallback
- Player·DM·Observer 공개 경계
- 구현 검수 Checklist와 Build Acceptance Gate

## 2. 산출물

```text
Visual Design Policy
→ COMPLETE

Accent Theme and Color Consistency Policy
→ COMPLETE

Interaction and Input Policy
→ COMPLETE

Information Architecture and Density Policy
→ COMPLETE

Feedback, Error and Recovery Policy
→ COMPLETE

Accessibility and Motion Policy
→ COMPLETE

UI·UX Review Checklist
→ COMPLETE
```

## 3. Accent Theme 개정 판정

최신 사용자 결정:

```text
시각 방향
→ 깔끔하면서 화려함

색상 체계
→ 일관된 Semantic Color

사용자 설정
→ Accent Color 선택 가능

기본값
→ gold
```

정책은 다음 계약으로 구체화했다.

- Neutral Surface와 사용자 Accent를 분리한다.
- 사용자 Accent는 일반 선택·Primary Action·Navigation·장식에만 적용한다.
- Role·Authority·Success·Warning·Danger·Pending·Hidden·Content 의미색은 변경하지 않는다.
- 초기 Preset은 `gold·azure·emerald·amethyst·teal·silver`다.
- 알 수 없는 Palette ID는 `gold`로 복구한다.
- 초기 구현에는 자유 RGB·Hex Picker를 제공하지 않는다.
- Theme 변경 중 Focus·Selection·Pending·Modal·Input Context를 유지한다.
- Accent Preference는 Campaign·Character·Combat Authority와 분리한다.

판정: `PASS`

## 4. 시각 정체성 판정

```text
정돈된 Layout과 중성 Surface
+ 하나의 User Accent
+ 제한된 Glow·Gradient·Motion
```

- 화려함은 Header, 주요 선택, 핵심 결과, Dice Reveal과 Authority Prompt에 제한한다.
- 모든 Button과 Card에 상시 Glow·Gradient·Particle을 적용하지 않는다.
- 한 Surface에 여러 Accent가 경쟁하지 않는다.
- 장식이 정보와 조작을 가리지 않는다.
- Reduced Motion과 저사양 Fallback에서 핵심 의미를 유지한다.

판정: `PASS`

## 5. 기존 권위와의 정합성

### UI Runtime

- UI는 사용자별 Projection만 표시한다.
- Component는 Remote·Domain Store를 직접 호출하지 않는다.
- Command Result만으로 권위 수치를 변경하지 않는다.
- Projection Batch는 원자 적용한다.
- Authority Prompt와 Local Modal을 구분한다.
- Accent Theme은 사용자별 비권위 Preference다.

판정: `PASS`

### Input·Selection

- 물리 키와 Semantic Action을 분리한다.
- 가장 위의 Input Context 하나만 입력을 소비한다.
- Q는 한 단계 취소, E는 현재 공개된 확정·실행·상호작용이다.
- Hover·Focus·Selection·Camera Focus를 분리한다.
- Theme 변경이 Input Context와 Selection을 초기화하지 않는다.

판정: `PASS`

### Visibility·Security

- DM 전용 정보를 Player Client에 전달한 뒤 숨기지 않는다.
- Color, Tooltip, Error, Search Count와 Diagnostic으로 비밀 정보를 누출하지 않는다.
- 사용자 Accent는 비공개·미식별 상태 표현을 변경하지 않는다.
- Player View Preview와 DM-only Source를 분리한다.

판정: `PASS`

## 6. 새로 고정된 구현 정책

- Dark Tactical Fantasy + Professional Tool 시각 정체성
- 깔끔한 정보 구조와 제한된 극적 장식
- Semantic Color·Typography·Spacing·Radius·Motion Token
- 사용자 Accent Token과 Palette Resolver
- 기본 `gold`와 승인된 여섯 Preset
- Settings > Interface > Accent Color
- Component 상태 Variant의 공통 이름
- 위험도 Tier 0–3 확인 정책
- Primary Surface·정보 Priority·Progressive Disclosure
- Action Lifecycle `submitted → receipt → awaiting_projection → reconciled`
- Error Surface 선택과 사용자 메시지 문법
- Full·Reduced·Minimal Motion Profile
- UI Scale 0.80–1.40 구조
- Low-end Fallback에서 절대 제거하지 않을 핵심 정보
- 화면·Component·Flow·Accent별 Review Checklist

이 항목은 Gameplay 규칙이나 Authority를 새로 만들지 않는다.

## 7. 구현 Gate 판정

Production UI는 다음을 모두 만족해야 한다.

- Policy Hub와 Review Checklist 연결
- Semantic Token과 Theme Resolver 사용
- 기본 Accent `gold`
- 설정에서 Preset 선택·Preview·복원
- 사용자 Accent와 역할·상태·콘텐츠 의미색 분리
- Input Context 사용
- Authority Result와 Local Preview 분리
- Loading·Empty·Denied·Stale·Error·Recovery 상태
- Player·DM·Observer Projection 분리
- Accessibility·Motion Profile 대응
- Palette별 Screenshot·Contrast·Focus 검수
- Slice별 UI Scenario와 Roblox Integration Test 계획

판정:

```text
UI·UX Policy Foundation
→ COMPLETE

Accent Theme Policy
→ COMPLETE

Production Script 자동 승인
→ NO

현재 다음 단계
→ Slice 01 Studio UI Acceptance
```

## 8. 남은 측정 항목

- 실제 Roblox Font와 한국어 렌더링
- 여섯 Palette의 실제 Display 대비
- Gradient·Glow 강도와 저사양 Fallback
- Animation Duration
- Tooltip Delay
- Panel·List Virtualization Budget
- UI Commit Frame Budget
- Camera 감도·Zoom·Occlusion 보정 속도
- Flash·Shake 실제 Hard Limit

현재 Policy의 구조를 바꾸지 않는 측정형 기본값이다.

## 9. 최종 판정

```text
UI Visual Policy
→ COMPLETE

Accent Theme·Color Consistency Policy
→ COMPLETE

UX Interaction·Information·Feedback·Recovery·Accessibility Policy
→ COMPLETE

Implementation Review Gate
→ COMPLETE

현재 Production 상태
→ STUDIO BASELINE VERIFIED

다음 검증
→ Slice 01 Visual·Accessibility Acceptance
```
