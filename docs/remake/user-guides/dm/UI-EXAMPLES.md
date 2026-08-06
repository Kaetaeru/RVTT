# RVTT DM UI HTML 예시

- 상태: `CURRENT · TARGET_EXPERIENCE`
- 대상: DM
- 최종 갱신일: 2026-08-06
- DM Guide: [`README.md`](README.md)
- 전체 HTML Gallery: [`../html/index.html`](../html/index.html)

이 문서는 DM Guide의 세션 운영·저작·복구 흐름을 인터랙티브 HTML 화면 예시로 연결한다.

HTML 예시는 화면 구조를 설명하는 비권위 Reference다. 실제 DM 권한, 감사 기록, Player Projection과 Runtime 동작은 Roblox Studio와 다중 Client Acceptance로 별도 검증한다.

## Live Session 운영

- [`DM Live Workspace`](../html/index.html#dm-live)
- [`DM Quick Action`](../html/index.html#dm-quick)
- [`DM Encounter·Fog Control`](../html/index.html#dm-encounter)

확인할 것:

- Player 전장 셸 위에 Scene·Actor·Inspector·Journal·Player Control·Encounter·Fog Panel을 Dock한다.
- 일반 Player Route와 감사되는 DM Override를 Section과 Label로 구분한다.
- Tier 3 Override는 Context Action Table에서 바로 Commit하지 않고 영향 Preview와 Confirm으로 이동한다.
- 숨은 Actor·Fog Source·비밀 수치는 DM Projection에서만 보인다.

## Player 공개 상태 확인

- [`DM Player View Preview`](../html/index.html#player-preview)
- [`Observer 공개 HUD`](../html/index.html#observer)

확인할 것:

- DM Source와 Player Permission Projection을 같은 데이터에 `Visible`만 바꿔 표시하지 않는다.
- Player View Preview를 열어도 Player Camera·Selection·Control Assignment를 바꾸지 않는다.
- 권한 밖 Entity·Action·Document는 Player Preview에 자리나 개수도 남기지 않는다.

## Scene 제작과 검증

- [`Scene Editor·Test Play·Publish`](../html/index.html#scene-editor)

확인할 것:

- Source, Local Draft, Candidate, Published와 Live Runtime 상태를 분리한다.
- Auto Save, Compile, Test Play, Publish와 Live Patch를 하나의 상태로 합치지 않는다.
- Preview Ghost·Gizmo·Fog·Lighting은 Source Commit이나 Gameplay Authority가 아니다.

## Recovery와 Rollback

- [`DM Recovery·Rollback Review`](../html/index.html#rollback)
- [`Reconnect·Resync·Recovery`](../html/index.html#reconnect)

확인할 것:

- Rollback 전에 Checkpoint, 현재와 대상 Diff, 영향 범위와 Player Knowledge 경고를 표시한다.
- Rollback 후 새 AuthorityEpoch에서 이전 Prompt·Command·Selection·ACK를 폐기한다.
- 복구 화면은 Spinner 하나가 아니라 Session·Role·Snapshot·Scene·UI 준비 단계를 구분한다.

## DM 설정·공통 상태

- [`Settings · Interface`](../html/index.html#settings-interface)
- [`Settings · Camera·Accessibility`](../html/index.html#settings-accessibility)
- [`Tooltip·Toast·Component 상태`](../html/index.html#component-states)
- [`Key Binding 충돌`](../html/index.html#binding-conflict)
- [`System Menu·세션 나가기`](../html/index.html#system-menu)

DM Workspace도 사용자 Accent와 접근성 Preference를 사용하지만 DM Authority Accent·Label과 State 의미색은 변경하지 않는다.

## 공통 입력 요약

```text
Left Click
→ 선택 또는 표시된 기본 행동

Right Click
→ Context Action Table

Middle-button Drag
→ Camera Orbit

Q
→ 최상위 Context 한 단계 취소·거절

E
→ 현재 Confirm 하나 제출

ESC
→ Gameplay 의미 없음
```

Scene Editor Tool은 공통 Input Context·Selection·Preview Host를 재사용하며 Tool마다 별도 물리 키 문법을 만들지 않는다.
