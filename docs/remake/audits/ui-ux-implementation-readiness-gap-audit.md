# UI·UX 구현 준비도와 빈 영역 감사

- 상태: `COMPLETE · IMPLEMENTATION ALIGNMENT REQUIRED`
- 문서 종류: UI·UX Screen·Settings·Flow Gap Audit
- 감사일: 2026-08-06
- 구현 직전 명세: [`implementation-ready-ui-ux-and-settings-spec.md`](../ui/shared/implementation-ready-ui-ux-and-settings-spec.md)
- 직접 플레이 결정: [`ADR-0088`](../decisions/ADR-0088-direct-play-pointer-grammar-and-feedback.md)
- 기존 정책 완료 감사: [`ui-ux-policy-completion-audit.md`](ui-ux-policy-completion-audit.md)

## 1. 감사 목적

2026-08-05의 기존 감사는 전역 시각·입력·정보·피드백·접근성 정책이 존재하는지를 검증했다. 이번 감사는 구현 직전 관점에서 실제 화면, 상태 전환, 설정 기본값과 Acceptance가 비어 있는지를 별도로 검증한다.

```text
정책이 존재함
≠ 화면 구성이 정해짐
≠ 기본값이 정해짐
≠ 상태 전환이 정해짐
≠ Runtime이 구현·검증됨
```

이번 감사는 Baldur's Gate형 전술 RPG의 전장 중심·직접 조작·Progressive Disclosure를 RVTT 권위 구조에 맞게 적용하는 데 필요한 빈 영역을 찾고 채운다. 특정 게임의 그래픽·자산·고유 화면을 복제하지 않는다.

## 2. 감사 결과 요약

```text
전역 Visual·Input·Feedback·Accessibility Policy
→ 기존 COMPLETE

전투 HUD·Character Sheet·DM Workspace 상세
→ 기존 상세 문서 존재

직접 플레이 Pointer·Q·Disabled Reason
→ ADR-0088로 상위 확정

전역 화면 셸·모드별 HUD
→ 기존 PARTIAL
→ 구현 직전 명세로 RESOLVED

Inventory·Loot·Journal·Map·Settings 화면
→ 기존 Domain·Guide 중심, 화면 계약 MISSING
→ 구현 직전 명세로 RESOLVED

Tooltip·Toast·Hotbar·Camera·Accessibility 초기값
→ 기존 범위만 존재, 수치 MISSING
→ 구현 직전 명세로 INITIAL DEFAULTS 확정

Entry·Role Change·Rest·Death·Reconnect 상태 전환
→ 기존 원칙 존재, 화면 상태 MISSING
→ 구현 직전 명세로 RESOLVED

Production Script·Studio Runtime Evidence
→ NOT EXECUTED
```

## 3. 기존에 충분히 정의된 영역

| 영역 | 기존 근거 | 판정 |
|---|---|---|
| Semantic Design Token·Dark Tactical Fantasy | Visual Policy | READY |
| 사용자 Accent·기본 Gold | Accent Policy | READY |
| Q/E·Input Context 기본 원칙 | Common Input·ADR-0071 | READY |
| 직접 포인터 문법·선택 연속성 | ADR-0088 | READY |
| BG3형 Encounter HUD 정보 위계 | ADR-0039·Combat HUD | READY |
| 공식 2024형 Character Sheet | ADR-0040·Character Sheet | READY |
| DM Workspace·Quick Action | ADR-0045·0047·DM UI | READY |
| Authority Action Lifecycle | Feedback Policy | READY |
| Projection·Reconnect 원칙 | UI Runtime·Feedback Policy | READY |
| 접근성·Motion Profile 구조 | Accessibility Policy | READY |

이 판정은 문서 설계 준비도이며 Runtime PASS가 아니다.

## 4. 발견된 화면 공백

### 4.1 전역 셸과 Mode Composition

기존 문서는 전투 HUD와 캐릭터 시트는 상세했지만 다음 구성이 한 문서에 고정되지 않았다.

- Exploration 상시 HUD
- Encounter 진입 시 추가·제거되는 영역
- Downtime·Rest 화면
- Observer 전용 셸
- DM Live Mode와 Player View Preview 분리
- Map·Journal·System 진입점

해결:

- 구현 직전 명세 2–3절에서 전역 셸과 Mode별 구성 확정.

### 4.2 Inventory·Equipment·Loot·Transfer

기존 ADR-0051과 Character Guide는 Authority와 Item Location을 정의했지만 다음 UI가 없었다.

- Character Inventory 화면 구성
- Container·Ground Loot 비교 화면
- Take All·Send To·Split·Equip의 Preview
- Drag 이외 대체 조작
- 식별되지 않은 Item의 안전한 표현
- Capacity·동시 획득 충돌·절도 경고

해결:

- 구현 직전 명세 8절에서 화면과 입력·Pending·Transfer 계약 확정.

### 4.3 Journal·Map·Ping

Journal Guide는 Stable ID와 안전 Navigation을 정의했지만 최종 화면 배치와 Q/History 경계가 비어 있었다.

해결:

- 구현 직전 명세 9절에서 Folder·Document·Outline, Map, Ping과 권한 경계 확정.

### 4.4 Settings·System Menu

Accent 설정 경로 외에 전체 설정 화면과 기본값이 없었다.

누락:

- Interface·Gameplay UX·Camera·Accessibility·Bindings·Performance Category
- Tooltip·Toast Duration
- Hotbar·PartyRail·Log·Minimap 기본값
- Camera·Motion·Cursor 기본값
- Category Reset·Binding Conflict·Leave Session

해결:

- 구현 직전 명세 12절에서 화면 구조와 초기값 확정.

### 4.5 Entry·Role·Recovery

Reconnect 원칙은 있었지만 다음 실제 화면 상태가 없었다.

- Session Entry·Character Assignment·Ready
- Observer 진입
- Role Change 중 오래된 정보 제거
- 단계형 Reconnect Surface
- Local Preference와 Authority State 복구 분리

해결:

- 구현 직전 명세 11·14절에서 상태 기계 확정.

### 4.6 Rest·Death·Downtime

Domain 규칙은 있었지만 Player UI 전환이 비어 있었다.

해결:

- 구현 직전 명세 3.3·10절에서 Rest Preview, HP 0, Death Save와 Downtime Surface 확정.

### 4.7 Onboarding

기존 문서는 Input Hint를 요구했지만 최초 학습 흐름, 완료 조건과 Reset이 없었다.

해결:

- 구현 직전 명세 15절에서 Contextual Hint 방식 확정.

## 5. 발견된 수치·기본값 공백

| 항목 | 기존 상태 | 새 초기값 |
|---|---|---|
| UI Scale | 범위만 있음 | 1.00, 0.80–1.40 |
| Text Scale | 누락 | 1.00, 0.90–1.30 |
| Hotbar Rows | 문서 간 1–3·1–4 충돌 | 기본 2, 범위 1–4 |
| Tooltip Delay | 측정 항목만 존재 | 일반 0.25초, 상세 0.75초 |
| Disabled Reason | 누락 | 0.15초 |
| Toast | Surface 원칙만 존재 | 종류별 2.5–6초, 최대 3개 |
| Minimap | 크기 문서만 존재 | medium·camera_up |
| PartyRail | 펼침/축소만 존재 | auto |
| Combat Log | 상태만 존재 | recent |
| Turn Focus | 원칙만 존재 | soft_notification |
| Camera Shake | Off 지원만 존재 | 35% |
| Motion | Profile만 존재 | full |
| Cursor Scale | 누락 | 1.00, 0.80–1.50 |

이 값은 Production 초기값이며 Studio 측정으로 조정할 수 있다. 조정 시 Acceptance Evidence를 남긴다.

## 6. 발견된 충돌

### 6.1 Right Pointer

기존 `interaction-and-input-policy.md`는 Right Pointer를 Camera 회전에 우선한다고 기록했다.

최신 결정:

```text
Right Pointer
→ Context Action Table

Middle Pointer Drag
→ Camera Orbit
```

조치:

- Interaction Policy를 ADR-0088 기준으로 수정해야 한다.

### 6.2 ESC

기존 일부 Implementation·Acceptance에는 ESC로 메뉴를 닫는 흐름이 있었다.

최신 결정:

```text
ESC
→ Gameplay 의미 없음

Q
→ 최상위 Context 한 단계 닫기
```

조치:

- Source·Acceptance·Hint에서 ESC Gameplay 처리를 제거해야 한다.

### 6.3 Hotbar 행 수

- Shared Wireframe: 1–3
- Combat HUD: 1–4

해결:

```text
기본 2
사용자 범위 1–4
```

### 6.4 정책 완료와 화면 완료

기존 Policy Work Order가 `COMPLETE`여서 전체 UI 화면이 구현 준비 완료로 오해될 수 있었다.

해결:

- Policy Foundation 완료는 유지한다.
- Screen·Settings·Flow Implementation Readiness를 별도 단계로 추가한다.

## 7. 새 구현 Gate

Production UI 구현 전에 다음이 모두 필요하다.

- ADR-0088와 Interaction Policy 정합성
- 구현 직전 UI·UX 명세 연결
- Screen별 ViewModel·Intent·Permission Projection 정의
- 모든 설정 기본값과 저장 범위 구현
- Exploration·Encounter·Inventory·Journal·Settings·Recovery Acceptance Host
- Q 한 단계 취소·ESC No-op 검증
- Disabled Color·Hover/Focus Reason 검증
- 권한 밖 Action·미인지 정보 부재 검증
- Local Preview·Pending·Projection Reconciliation 검증
- UI Scale·Accent·Motion·Role별 Screenshot Evidence

## 8. Runtime에서 아직 증명되지 않은 항목

- Exploration 전체 셸의 실제 Roblox Layout
- Inventory·Loot·Journal·Map·Settings 화면
- Tooltip·Toast Timing의 실제 조작감
- Camera Occlusion·Sensitivity와 Motion Comfort
- Keyboard Focus·Q 단계 복원
- UI Scale 0.80·1.40와 한국어 긴 문구
- Player·DM·Observer Projection 분리
- Role Change·Reconnect·Recovery 화면
- 대량 목록 Virtualization과 UI Commit Budget

이 항목은 문서 완료만으로 PASS 처리하지 않는다.

## 9. 구현 우선순위 판정

```text
P0
→ Interaction Policy 충돌 제거
→ Shared Shell·Q·Pointer·Tooltip·Settings Preference 기반

P1
→ Exploration·Encounter Direct Play
→ Inventory·Loot

P2
→ Journal·Map·Rest·Death·Entry·Recovery

P3
→ DM Workspace 정합화·전체 Accessibility·Performance
```

## 10. 최종 판정

```text
Global Policy Foundation
→ COMPLETE

Direct Play Top-level Decision
→ COMPLETE

Screen·Settings·Flow Implementation Specification
→ COMPLETE

Existing Production Source Alignment
→ REQUIRED

Static Gate on Alignment Head
→ NOT EXECUTED

Studio Human Runtime Evidence
→ NOT EXECUTED
```

다음 작업은 추가 기획 탐색이 아니라 구현 직전 명세에 맞춘 하위 문서·Source·Acceptance 정합화다.
