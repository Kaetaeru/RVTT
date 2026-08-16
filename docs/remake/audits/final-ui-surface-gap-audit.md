# Final UI Surface Gap Audit

- 상태: `COMPLETE · RELEASE UI CONTRACT CLOSED · ADR-0092 EXTENDED`
- 감사일: 2026-08-06
- 상위 결정:
  - [`ADR-0092`](../decisions/ADR-0092-campaign-survival-logistics-and-dm-authored-actor-tokens.md)
  - [`ADR-0091`](../decisions/ADR-0091-asset-registry-interactive-sheet-dice-and-core-rules.md)

## 1. 감사 범위

Session Entry, Player Direct Play, Character, Inventory, Dice, Journal, Rules Reader, Settings, Recovery, Campaign Survival, Supply Settlement, DM Workspace, Actor Token Authoring, Scene Editor와 Content Asset authoring을 다시 대조했다.

## 2. 폐쇄한 공백

| 영역 | 이전 공백 | 확정 계약 |
|---|---|---|
| Session discovery | Entry 화면 이전 진입 수단 미정 | Invite Link·Join Code·Recent Session, Membership 재검증 |
| Asset authoring | Prefab Source·Runtime 위치 미정 | Content Source·Server Pack·Client-safe Runtime 3계층 |
| Asset failure | Missing Dependency UI 미정 | Placeholder·Repair 선택·Validation Result |
| Official Sheet | 비율 불일치·부분 읽기 전용 | 2024 2-page 비율·Roll·Equip·Prepare·Use Command |
| Dice Notice | 결과 완성 후 즉시 표시 | Natural Slot Spin→Formula Expand→Adjudication |
| Rules content | Campaign Journal 문서만 존재 | Core Rules Collection·Module·Chunk·Search·Attribution |
| Large documents | 전체 본문 Load 위험 | Virtualized Chunk Reader |
| Content rights | 권리 상태 UI 부족 | Package License·Attribution·Entitlement State |
| Campaign survival | 일수 진행과 보급 자원 분리 | Policy Module·Supply Settlement·Ledger |
| Survival optionality | 모든 Campaign 강제 위험 | Narrative·Standard·Survival·Custom Preset |
| Mid-campaign toggle | 소급·환불·Effect 처리 불명 | Candidate Snapshot·비소급 기본·Reconcile Tool |
| Supply safety | 이름으로 Food 자동 소비 위험 | 명시적 Supply Metadata·Protected Stack |
| Custom actor model | DM Token 추가 경로 없음 | Actor Model Registry·Validation·Campaign Package |
| AI stat block | Prompt·Schema·Asset 이름 제공 미정 | Strict Schema·전체 Catalog Projection·Prompt Builder |
| AI trust | 코드·가짜 Asset ID·자동 Publish 위험 | Untrusted Draft·Script 금지·Reference Validation·DM Publish |
| Settings | Audio Tab가 범위를 암시 | Audio Mixer Tab 제거, 현재 범위 밖 명시 |
| Tool close | Unsaved Window 처리 미정 | Save·Discard·Cancel, Q는 현재 Context만 |
| Key binding | 충돌 Capture UI 미정 | Duplicate Conflict·Swap·Unbind·Cancel |
| Stale state | Permission/Scene 변경 후 잔존 위험 | Window별 Refresh·Safe Empty·Close |
| First run | 입력 학습 UI 미정 | 1회 Control Primer, User Guide에서 재실행 |

## 3. 공통 상태 매트릭스

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

Blank Panel·무응답 Button·Spinner-only 상태는 허용하지 않는다.

## 4. Release UI에 포함하지 않는 항목

- Touch 전용 HUD
- Controller 전용 Radial Menu
- Audio Mixer·Music Library
- 공개 Matchmaking
- Player Map·Minimap·Objective Tracker
- Client 내부 AI API Key 입력·보관

해당 기능은 빈 Tab·Disabled Placeholder로 노출하지 않는다.

## 5. 최종 Release-blocking Acceptance

- Invite/Join→Observer→DM Assignment→Player 흐름
- 1–4행 Character Console과 Hover Panel
- 2024 비율 Interactive Official Sheet
- VTT Inventory와 동일 Revision
- Dice Notice 모든 변형과 Reduced Motion
- Core Rules Module Reader와 권리 경계
- Campaign Survival Toggle의 비소급·안전 경계 적용
- 여러 날 Time Advance의 Checkpoint별 Supply Settlement
- Protected Item·Hidden Supply Source 미소비·미노출
- Actor Model Registry·Strict Stat Block JSON·Campaign Publish
- Prompt에 현재 보이는 Model Catalog 전체 포함
- 가짜 Model ID·Script·미등록 Recipe·자동 Publish 차단
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
- Rule Reader large-module memory test
- Supply Settlement Transaction·Rollback Test
- Actor Model Security Scan·Budget Test
- Campaign-local Actor Package Publish·Migration Test
- Studio Human usability evidence
