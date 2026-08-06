# StarterGui / RVTT

Screen, HUD, Panel, Shared Component Composition, Theme·Token Binding과 Loading·Prompt·Recovery UI를 둔다.

금지:

- Domain Store·DataStore 직접 접근
- RemoteEvent 직접 호출
- 화면별 임의 Hex·Font·Spacing 값
- UI Animation을 Gameplay Authority로 사용
- Player·DM 데이터를 같은 ViewModel에서 `Visible`만 변경

모든 UI Script는 UI·UX Review Checklist를 통과해야 한다.
