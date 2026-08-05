# Slice 01 Camera Input Correction

- 상태: `STUDIO_RETEST_PENDING`
- 기록일: 2026-08-06
- 관련 Delta: `SLICE_01_WORLD_INTERACTION_BATCH_CAMERA_INPUT_PENDING`

## 사용자 관측

```text
Mouse Wheel Zoom
→ PASS

F / Token Frame
→ FAIL

Middle-button Drag Pan
→ FAIL
```

기존 `passed=16 failed=0` Summary는 Camera 메서드를 Harness가 직접 호출한 허위 양성 결과였으므로 전체 사용자 흐름 PASS 근거에서 철회한다.

## 원인

- Camera Controller가 `gameProcessedEvent=true`인 `F`와 중클릭 입력을 무시했다.
- Acceptance Harness가 `frameAll()`, `panPixels()`, `zoomBy()`를 직접 호출해 실제 입력 결함을 감췄다.

## 수정 계약

- `ContextActionService` 고우선순위 Action으로 `F`와 `MouseButton3`을 수신한다.
- 활성 중클릭 Drag 중 MouseMovement는 processed 상태와 무관하게 처리한다.
- 실제 입력 결과를 `InputResolved`로 전달한다.
- Camera Check는 실제 입력 전까지 `pending`이다.
- Frame은 요청 적용, Pan·Zoom은 Camera CFrame 변화가 확인되어야 PASS다.

## 재검증 로그

```text
[RVTT WorldCamera Input] action=frame source=keyboard-f applied=true ...
[RVTT WorldCamera Input] action=pan-start source=mouse-middle
[RVTT WorldCamera Input] action=pan source=mouse-middle-drag applied=true changed=true ...
[RVTT WorldCamera Input] action=pan-end source=mouse-middle
[RVTT WorldCamera Input] action=zoom source=mouse-wheel applied=true changed=true ...

[RVTT Batch Camera] action=frame ... result=PASS ...
[RVTT Batch Camera] action=pan ... result=PASS ...
[RVTT Batch Camera] action=zoom ... result=PASS ...
```

실제 Camera Frame·Pan·Zoom 입력이 모두 통과하기 전에는 Slice 01 Production Build Acceptance Audit로 이동하지 않는다.
