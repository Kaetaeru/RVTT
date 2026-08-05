# RVTT UI·UX Review Checklist

- 상태: CURRENT
- 문서 종류: UI·UX Policy Review Checklist
- 작성일: 2026-08-05
- 최종 개정일: 2026-08-05
- Policy Hub: [`UI·UX Global Policies`](README.md)
- Visual: [`Visual Design`](visual-design-policy.md)
- Accent: [`Accent Theme and Color Consistency`](accent-theme-and-color-consistency-policy.md)
- Interaction: [`Interaction and Input`](interaction-and-input-policy.md)
- Information: [`Information Architecture and Density`](information-architecture-and-density-policy.md)
- Feedback: [`Feedback, Error and Recovery`](feedback-error-and-recovery-policy.md)
- Accessibility: [`Accessibility and Motion`](accessibility-and-motion-policy.md)

이 Checklist는 새 화면, Shared Component, 사용자 Flow와 Slice Build Acceptance에서 사용한다.

판정:

```text
PASS
PASS_WITH_MEASURED_DEFAULTS
FAIL
NOT_APPLICABLE — 이유 필수
```

`FAIL` 항목이 하나라도 있으면 Production Build Acceptance를 통과시키지 않는다.

## 1. 화면 목적과 정보 구조

- [ ] 사용자의 현재 Primary Surface와 결정이 명확하다.
- [ ] 현재 Mode·Context·Role이 구분된다.
- [ ] 지금 필요한 대상·비용·위험·예상 결과가 우선 표시된다.
- [ ] 세부 근거는 선택을 잃지 않고 확장할 수 있다.
- [ ] 같은 Authority 값을 여러 Surface에서 독립 편집하지 않는다.
- [ ] 중앙 전장 안전 영역을 지속 Panel이 가리지 않는다.
- [ ] Loading·Empty·Filtered Empty·Denied·Not Ready·Stale·Unavailable·Error가 구분된다.
- [ ] Player·DM·Observer 정보가 단순 `Visible` 차이가 아니라 별도 Projection이다.

## 2. Visual Token과 Component

- [ ] 임의 Hex·Font Size·Spacing·Corner·Stroke 값 대신 Semantic Token을 사용한다.
- [ ] Component의 idle·hover·focus·pressed·selected·pending·disabled·denied·stale·error 상태가 필요한 범위에서 정의됐다.
- [ ] Disabled 이유를 확인할 수 있다.
- [ ] 색만으로 상태를 전달하지 않는다.
- [ ] 한국어 긴 Label과 큰 수치에서 Layout이 깨지지 않는다.
- [ ] UI Scale 0.80과 1.40에서 핵심 조작이 유지된다.
- [ ] Layer가 HUD·Panel·Tooltip·Prompt·Modal·Recovery 순서를 지킨다.
- [ ] Presentation VFX가 Prompt·Modal·Recovery Surface를 가리지 않는다.
- [ ] 화면은 정돈된 Layout과 제한된 장식을 사용해 깔끔하면서 화려하다.
- [ ] 한 Surface에 여러 Accent가 경쟁하지 않는다.
- [ ] Glow·Gradient·Particle이 모든 Component에 상시 적용되지 않는다.
- [ ] 중요한 선택·결과가 일반 상태보다 강한 시각 위계를 가진다.

## 3. Accent Theme과 색상 일관성

- [ ] 기본 Accent Theme이 `gold`다.
- [ ] Settings > Interface > Accent Color에서 현재 Preset을 확인하고 선택할 수 있다.
- [ ] `gold·azure·emerald·amethyst·teal·silver`가 같은 Semantic Token 계약을 사용한다.
- [ ] Component가 Palette ID나 Hex 값을 직접 조건 분기하지 않는다.
- [ ] Accent 선택 시 Sample Component Preview와 즉시 적용 결과가 보인다.
- [ ] `기본값으로 복원`이 `gold`로 돌아간다.
- [ ] 알 수 없거나 제거된 Palette ID가 `gold`로 안전하게 복구된다.
- [ ] Theme 변경 중 Focus·Selection·Pending·Modal·Input Context가 유지된다.
- [ ] Role·Authority·Success·Warning·Danger·Pending·Hidden 색이 Accent 변경으로 바뀌지 않는다.
- [ ] Item 희귀도·피해 유형·조건·거리·범위 의미색이 Accent 변경으로 바뀌지 않는다.
- [ ] 사용자 Accent와 의미색이 유사해도 Icon·Label·Shape·Stroke로 구분된다.
- [ ] 모든 Preset에서 idle·hover·focused·pressed·selected·disabled 상태가 구분된다.
- [ ] Focus 대비가 부족할 때 접근성 `focus.ring`으로 안전하게 대체된다.
- [ ] 자유 RGB·Hex Picker가 초기 구현에 노출되지 않는다.
- [ ] 재접속·Full Resync·Rollback 뒤 사용자 Accent Preference가 유지된다.

## 4. Input·Focus·Selection

- [ ] Component가 물리 키를 직접 감시하지 않는다.
- [ ] 현재 Input Context와 Q/E 의미가 화면에 표시된다.
- [ ] 같은 입력을 두 Context가 동시에 소비하지 않는다.
- [ ] Text Input 중 Gameplay Shortcut이 실행되지 않는다.
- [ ] 1–5는 현재 Label이 보일 때만 활성화된다.
- [ ] Q가 한 단계만 취소한다.
- [ ] E가 현재 공개된 하나의 Confirm·Execute·Interact만 실행한다.
- [ ] Hover·Keyboard Focus·World Focus·Selection·Camera Focus를 구분한다.
- [ ] 핵심 정보와 Action은 Hover 없이도 접근 가능하다.
- [ ] Selection·Targeting은 Server 최신 Snapshot에서 재검증된다.
- [ ] Stale Target에 재선택 또는 최신 상태 경로가 있다.

## 5. Action Safety

- [ ] 제출 전에 대상·비용·범위·결과 종류를 확인할 수 있다.
- [ ] Action 위험도 Tier가 정해졌다.
- [ ] 파괴·권한·Rollback Action은 구체적인 영향과 Diff를 보여준다.
- [ ] 파괴 Action의 기본 Focus가 안전한 선택에 있다.
- [ ] Client Preview·Drag Ghost·Path Preview를 Authority로 저장하지 않는다.
- [ ] 중복 제출을 막고 멱등성·Ordering 정책과 연결된다.
- [ ] DM Override와 일반 Player Route가 구분된다.

## 6. Pending·Result·Error

- [ ] Local Feedback과 Authority Result가 시각적으로 구분된다.
- [ ] submitted·receipt·processing·awaiting projection·reconciled 상태가 필요한 범위에서 표현된다.
- [ ] Command Result만으로 권위 수치를 확정하지 않는다.
- [ ] Denied·Stale·Retryable·Resync Required의 다음 행동이 명확하다.
- [ ] Error가 Inline·Tooltip·Toast·Banner·Prompt·Modal 중 적절한 Surface를 사용한다.
- [ ] 같은 Error Notification이 무한 반복되지 않는다.
- [ ] 사용자가 해결할 수 없는 상태에 Retry를 제공하지 않는다.
- [ ] 사용자 문구에 Raw Code·Stack·Secret ID를 노출하지 않는다.
- [ ] 심각 오류에 안전한 Support Reference가 있다.

## 7. Reconnect·Resync·Rollback

- [ ] Projection Gap에서 부분 Replica를 적용하지 않는다.
- [ ] Last Known Good 상태와 입력 Gate가 정의됐다.
- [ ] Reconnect 단계와 현재 상태가 보인다.
- [ ] 이전 ConnectionEpoch·AuthorityEpoch Prompt·Selection·ACK를 폐기한다.
- [ ] Local Layout·Accent·Accessibility와 Authority-bound State 복구 원본을 분리한다.
- [ ] 사용자 Accent 저장을 읽지 못해도 `gold`로 UI를 계속 표시한다.
- [ ] Rollback 전에 범위·Diff·Knowledge 경고를 보여준다.
- [ ] Rollback 후 Full Resync와 현재 Branch 표시가 있다.
- [ ] Draft를 사용자 승인 없이 자동 제출하지 않는다.

## 8. Accessibility·Motion

- [ ] Keyboard Focus 순서가 시각·의미 순서와 일치한다.
- [ ] Focus Ring과 Accessible Name이 있다.
- [ ] Color-only·Hover-only·Motion-only 의미가 없다.
- [ ] 모든 Accent Preset에서 Text·Icon·Control 경계가 판독 가능하다.
- [ ] Reduced Motion에서 큰 이동·Shake·Pulse가 제거된다.
- [ ] Minimal Motion에서도 결과 공개와 위험 정보가 유지된다.
- [ ] Flash·Shake·Screen Effect를 제한하거나 끌 수 있다.
- [ ] Camera Auto Movement를 사용자가 중단하거나 축약할 수 있다.
- [ ] 저사양 Fallback에서 Target·Range·Warning·Prompt·Focus가 유지된다.
- [ ] Timeout이 Client Animation에 의존하지 않는다.

## 9. Performance·Scale

- [ ] 긴 목록은 가상화 또는 Paging을 사용한다.
- [ ] ViewModel은 같은 Replica Revision에서 결정적으로 생성된다.
- [ ] Projection Batch를 한 UI Commit으로 적용한다.
- [ ] Theme 변경은 전체 Gameplay UI를 불필요하게 재생성하지 않는다.
- [ ] Panel·Component 오류가 다른 HUD와 Gameplay에 확산되지 않는다.
- [ ] 실제 Roblox 환경에서 Frame·Memory·Network 측정 계획이 있다.
- [ ] 측정 전 임의 Capacity·Timeout·Queue 수치를 완료값으로 확정하지 않는다.

## 10. 화면별 추가 검사

### Combat HUD

- [ ] 현재 Turn·Opportunity·Movement Budget이 즉시 보인다.
- [ ] Targeting·Reaction·Dice Reveal이 Input Context를 명확히 소유한다.
- [ ] Dice·Critical 연출이 Theme Accent를 사용하더라도 결과 의미색을 침범하지 않는다.
- [ ] UI Ribbon을 권위 Timeline으로 사용하지 않는다.

### Character·Inventory

- [ ] Character Source·Compiled Build·Current State가 구분된다.
- [ ] Item Definition·ItemInstance·Location이 구분된다.
- [ ] Derived 값의 근거를 펼쳐볼 수 있다.
- [ ] 희귀도와 장비 상태가 사용자 Accent로 재색칠되지 않는다.

### Journal

- [ ] Stable Document·Section·Anchor ID를 사용한다.
- [ ] 비공개 문서가 Search·Count·Backlink에 나타나지 않는다.
- [ ] World Link가 안전한 Camera·Selection·Transition Proposal만 만든다.

### Scene Editor

- [ ] Source·Candidate·Published·Live Runtime 상태가 구분된다.
- [ ] Tool이 공통 Input·Selection·Preview Host를 사용한다.
- [ ] Compile·Publish·Live Patch를 같은 상태로 표현하지 않는다.

### DM Workspace

- [ ] Player View Preview와 DM-only Source가 분리된다.
- [ ] User Accent와 DM Authority Accent·Label이 혼동되지 않는다.
- [ ] Quick Action의 대상·공개 범위·영향·Audit이 보인다.
- [ ] Recovery Review가 Store를 직접 수정하지 않는다.

## 11. Review 기록 Template

```text
Surface 또는 Flow:
Slice:
Reviewer:
Build·Commit:
Viewport·UI Scale:
Role·Projection:
Accent Theme:
Motion Profile:
결과: PASS | PASS_WITH_MEASURED_DEFAULTS | FAIL

FAIL 항목:
근거 Screenshot·Scenario:
수정 책임:
재검수 결과:
```
