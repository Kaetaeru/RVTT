# Camera 시스템

PC 키보드·마우스용 자유 전술 카메라, 추적, Focus, 북마크, DM Observe와 연출 우선순위를 다룬다.

## 관련 Main System Guide

- [`UI, Camera와 Presentation Guide`](../../guides/ui/README.md)
  - CameraRequest, 안전한 CameraTargetProjection, Focus·Follow와 Restoration Stack
  - Exploration·Encounter·Selection·Presentation·DM Observe·Scene Transition Camera 흐름
  - ViewY·Bookmark·Streaming·Reconnect·Rollback과 사용자 Motion Safety 경계

## 권위 문서

### 공통 Runtime 권위

- [`../../architecture/camera-policy-focus-follow-and-presentation-runtime-contract.md`](../../architecture/camera-policy-focus-follow-and-presentation-runtime-contract.md)
  - Gameplay Authority와 Camera Projection 분리
  - CameraRequest, 정책 우선순위와 복원 스택
  - Focus Target과 Follow Target 분리
  - Exploration Free Camera와 Encounter Follow + Free Override
  - Selection Focus, Presentation Focus, DM Observe, Replay와 Scene Transition
  - Streaming·Reconnect·Rollback과 안전한 Camera Target Projection

### 기능 모델

- [`free-tactical-camera-model.md`](free-tactical-camera-model.md)
  - 기본 조작
  - ViewY와 가림 보정
  - 북마크와 저널 링크
  - DM 카메라 유도

## 고정 경계

- Camera는 사용자별 Projection·Presentation이며 Gameplay Authority가 아니다.
- Hover만으로 카메라를 이동하지 않는다.
- Selection·Spell·Dice·VFX는 Roblox Camera를 직접 조작하지 않고 CameraRequest를 제출한다.
- Follow와 Focus는 독립 상태다.
- DM Observe는 Actor 제어권을 변경하지 않는다.
- 카메라 가림 보정은 Visibility·Knowledge Projection을 우회해 비밀 정보를 공개하지 않는다.

## Guide 상태

```text
Guide Status: CURRENT
```

현재 Camera Runtime과 UI·Presentation 연동, 사용자 흐름과 복구 경계는 Main System Guide에 반영되어 있다. 관련 권위 계약이 변경되면 Guide를 `UPDATE_REQUIRED`로 전환한다.
