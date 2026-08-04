# 위치 핑과 경로 핑 모델

- 상태: ACTIVE
- 문서 종류: System Feature Model
- 작성일: 2026-08-04
- 관련 결정:
  - [`ADR-0044`](../../decisions/ADR-0044-linked-journal-and-two-mode-ping-system.md)
- 관련 Architecture:
  - [`공통 입력 교과서`](../../ui/common-input/common-input-grammar.md)
  - [`UI Runtime 계약`](../../architecture/ui-projection-view-model-input-context-and-recovery-runtime-contract.md)
  - [`Presentation Runtime 계약`](../../architecture/presentation-recipe-playback-priority-and-extension-runtime-contract.md)
  - [`Networking 계약`](../../architecture/networking-command-event-and-client-synchronization-contract.md)
  - [`Runtime Navigation 계약`](../../architecture/runtime-navigation-path-planning-and-movement-execution-contract.md)

## 1. 목적

핑은 전술 설명과 위치 공유를 위한 비권위 Presentation 기능이다.

지원 종류는 두 개다.

```text
짧은 클릭
→ 위치 핑

누른 채 드래그
→ 경로 핑
```

핑은 Actor 이동, 이동 비용, 기회 공격, 충돌, 시야와 규칙 결과를 확정하지 않는다.

## 2. 위치 핑

```text
PingIntent
├─ senderUserId
├─ sceneId
├─ worldPosition
├─ surfaceNormal
├─ audience
├─ presentationProfile
└─ clientInteractionId
```

Server는 Session Role, Audience, Scene Scope, 좌표 범위와 Rate Limit을 검증한다.

검증된 Ping은 Presentation Signal로 전달한다. Campaign Authority State와 Recovery Snapshot에는 저장하지 않는다.

## 3. 경로 핑

```text
시작점
→ 드래그 Sample
→ 표면 투영
→ 간소화
→ 검증
→ Presentation Signal
```

```text
PathPingIntent
├─ senderUserId
├─ sceneId
├─ sampledPoints[]
├─ audience
├─ projectionPreference
└─ clientInteractionId
```

경로는 현재 공개 가능한 Navigation Surface에 시각적으로 투영할 수 있지만 `NavigationPlan`, `Movement Command`와 `Frozen Selection Binding`이 아니다.

허용되지 않는 표면이나 Streaming되지 않은 구간은 끊김 또는 경고 표시로 표현한다.

## 4. 입력 문맥

```text
Q
→ 작성 중인 핑 취소

마우스 버튼 해제
→ 경로 핑 제출
```

Targeting, Scene Editing, Fog Editing, Drag와 텍스트 입력이 더 높은 Input Context를 가진다. Ping 기능은 물리 키를 직접 감시하지 않고 Semantic Input Action을 등록한다.

## 5. Audience

지원 Audience 예:

```text
party
campaign
selected_users
private_dm
```

Player는 자신에게 허용된 Audience만 선택할 수 있다. DM은 전체, 특정 Player와 DM 전용 Ping을 사용할 수 있다.

비공개 대상의 Identity와 숨은 좌표를 Ping Payload에 포함하지 않는다.

## 6. 수명주기와 성능

- Ping은 짧은 Presentation Lifetime 후 완전히 제거한다.
- 동일 Sender의 과도한 Ping은 Rate Limit과 Merge Policy를 적용한다.
- 경로 Sample 수, 총 길이와 Payload Byte에 상한을 둔다.
- Client VFX 실패는 Gameplay에 영향을 주지 않는다.
- 재접속 Client에게 만료된 Ping을 재생하지 않는다.
- 위치와 경로 Ping은 Diagnostics에서 비권위 Client Experience Event로만 기록한다.

## 7. 고정 경계

- Ping은 Journal Anchor가 아니다.
- Ping을 클릭해도 문서 Link, Camera Bookmark와 Selection을 자동 생성하지 않는다.
- Ping은 실제 이동 경로를 확정하지 않는다.
- Client가 보내는 위치를 신뢰하지 않고 Server가 Scene Scope와 범위를 검증한다.
- Presentation Signal 손실을 Authority Event Gap으로 취급하지 않는다.
