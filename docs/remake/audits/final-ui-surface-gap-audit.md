# Final UI Surface Gap Audit

- 상태: `COMPLETE · RELEASE UI CONTRACT CLOSED`
- 감사일: 2026-08-06
- 상위 결정: [`ADR-0091`](../decisions/ADR-0091-asset-registry-interactive-sheet-dice-and-core-rules.md)

## 1. 감사 범위

Session Entry, Player Direct Play, Character, Inventory, Dice, Journal, Rules Reader, Settings, Recovery, DM Workspace, Scene Editor, Content Asset authoring과 Rule Content Profile을 다시 대조했다.

## 2. 이번에 폐쇄한 공백

| 영역 | 이전 공백 | 확정 계약 |
|---|---|---|
| Session discovery | Entry 화면 이전 진입 수단 미정 | Invite Link·Join Code·Recent Session, 권한은 Membership 재검증 |
| Asset authoring | Prefab Source·Runtime 위치 미정 | Content Source·Server Pack·Client-safe Runtime 3계층 |
| Asset failure | Missing Dependency UI 미정 | Placeholder·Repair 선택·Validation Result |
| Official Sheet | 비율 불일치·부분 읽기 전용 | 2024 2-page 비율·Roll·Equip·Prepare·Use Command |
| Dice Notice | 결과 완성 후 즉시 표시 | Natural Slot Spin→Formula Expand→Adjudication |
| Rules content | Campaign Journal 문서만 존재 | Core Rules Collection·Module·Chunk·Search·Attribution |
| Test content breadth | SRD 대표 선택지만으로 복합 UI 검증 부족 | 한국어 통합판 12 Class·48 Subclass·16 Background·10 Species·75 Feat·391 Spell을 개발·테스트 기본으로 사용 |
| Rule profile | 개발용 전체 선택지와 공개 배포 범위가 혼합될 위험 | Integrated Test Profile과 SRD Public/Release Profile을 분리 |
| Private source | 번역 본문을 공개 Repo에 복사할 위험 | Pin된 비공개 Source를 Build-time Import하고 공개 Git Tree에는 본문·Chunk·Index를 저장하지 않음 |
| Release leakage | Private Rule Chunk·검색 색인이 Artifact에 남을 수 있음 | Package ID·Source Metadata·본문·Snippet을 검사하는 Fail-closed Release Gate |
| Large documents | 전체 본문 Load 위험 | Virtualized Chunk Reader |
| Content rights | 권리 상태 UI 부족 | Package License·Attribution·Entitlement·Private Source State |
| Settings | Audio Tab가 범위를 암시 | Audio Mixer Tab 제거, 현재 범위 밖 명시 |
| Tool close | Unsaved Window 처리 미정 | Save·Discard·Cancel, Q는 현재 Context만 |
| Key binding | 충돌 Capture UI 미정 | Duplicate Conflict·Swap·Unbind·Cancel |
| Stale state | Permission/Scene 변경 후 잔존 위험 | Window별 Refresh·Safe Empty·Close |
| First run | 입력 학습 UI 미정 | 1회 Control Primer, User Guide에서 재실행 |

## 3. 공통 상태 매트릭스

모든 대형 Surface는 필요한 다음 상태를 가진다.

```text
loading
empty
ready
pending
partial
stale
permission_denied
network_error
validation_error
conflict
recovery
```

Rules Reader와 Package Browser는 다음 전용 상태를 추가한다.

```text
integrated_test_profile
srd_release_profile
private_source_missing
source_revision_mismatch
expected_count_mismatch
srd_fallback_explicit
release_leak_blocked
```

Blank Panel·무응답 Button·Spinner-only 상태는 허용하지 않는다.

## 4. Release UI에 포함하지 않는 항목

- Touch 전용 HUD
- Controller 전용 Radial Menu
- Audio Mixer·Music Library
- 공개 Matchmaking
- Player Map·Minimap·Objective Tracker
- Private Rule Package Export·Download UI

해당 기능은 빈 Tab·Disabled Placeholder로 노출하지 않는다.

## 5. 최종 Release-blocking Acceptance

- Invite/Join→Observer→DM Assignment→Player 흐름
- 1–4행 Character Console과 Hover Panel
- 2024 비율 Interactive Official Sheet
- VTT Inventory와 동일 Revision
- Dice Notice 모든 변형과 Reduced Motion
- Core Rules Module Reader와 권리 경계
- 개발·테스트 기본 통합판의 12/48/16/10/75/391 Count
- Private Source Pin·Count·Hash 불일치 시 Fail Closed
- Public·Release Build의 SRD-only Package Resolution
- 공개 Artifact에 Private Package·본문·검색 자료·Source Metadata가 없음
- Asset Package Import·Validation·Missing Asset Repair
- DM Multi-window Layout·Unsaved Close·Permission Stale
- 한국어 긴 Text·0.80/1.00/1.40 Scale·Keyboard Focus
- 권한 밖 정보의 자리·Count·Search Snippet 미노출

## 6. 잔여 비UI 검증

문서상 UI 공백은 폐쇄했다. 다음은 Runtime Evidence이며 기획 공백이 아니다.

- Browser Screenshot·Pixel Diff
- Roblox ScreenGui 비교
- Multi-client Authority Test
- Content Package Compile Performance
- Private Integrated Import Smoke Test
- Public SRD Release Leak Scan
- Rule Reader large-module memory test
- Studio Human usability evidence
