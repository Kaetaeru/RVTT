# Shared UI

전투 HUD, 탐험 HUD, 캐릭터 시트, Inventory, Journal, Settings와 Recovery가 공유하는 화면 셸, 안전 영역, 레이어, Component와 사용자 설정을 다룬다.

## 구현 직전 권위 명세

- [`implementation-ready-ui-ux-and-settings-spec.md`](implementation-ready-ui-ux-and-settings-spec.md)
  - 전역 화면 셸과 Exploration·Encounter·Downtime·Observer·DM Live Mode 구성
  - Inventory·Loot·Journal·Map·Settings·Entry·Rest·Death·Recovery 화면
  - Tooltip·Toast·Hotbar·Camera·Accessibility 초기 기본값
  - 사용자 설정 저장 범위와 공통 Component·Acceptance Matrix

## 기존 공통 와이어프레임

- [`combat-hud-character-sheet-wireframe-and-shared-ui.md`](combat-hud-character-sheet-wireframe-and-shared-ui.md)
  - 전투 HUD와 캐릭터 시트의 기준 크기·안전 영역·레이어·Component
  - Hotbar 행 범위는 구현 직전 명세의 최신 결정인 기본 2, 사용자 1–4를 따른다.

## 관련 Main System Guide

- [`UI, Camera와 Presentation Guide`](../../guides/ui/README.md)
  - Projection Replica·ViewModel·Panel·Component와 Presentation Layer의 공통 경계
  - UI Scale·접근성·Responsive Layout, Camera·World Feedback와 실패 격리

## 고정 경계

- 최상위 입력 문법은 [`ADR-0088`](../../decisions/ADR-0088-direct-play-pointer-grammar-and-feedback.md)을 따른다.
- ESC에는 Gameplay 의미가 없다.
- Q는 최상위 Input Context 하나만 닫는다.
- 화면별 구현은 전역 정책과 구현 직전 명세를 모두 통과해야 한다.
- 문서 완료는 Production Script 또는 Studio Runtime PASS가 아니다.
