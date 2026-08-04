# RVTT Information Architecture and Density Policy

- 상태: CURRENT
- 문서 종류: Global UX Information Policy
- 작성일: 2026-08-05
- Policy Work Order: [`CURRENT-WORK-ORDER`](CURRENT-WORK-ORDER.md)
- Visual Policy: [`Visual Design Policy`](visual-design-policy.md)
- UI Guide: [`UI, Camera와 Presentation Guide`](../../guides/ui/README.md)

이 문서는 Player HUD, Character Sheet, Inventory, Journal, DM Workspace와 Scene Editor에서 무엇을 먼저 보여주고, 어디에 배치하며, 언제 확장하는지를 정의한다.

## 1. 핵심 원칙

```text
현재 결정
→ 현재 대상
→ 비용·위험·제약
→ 예상 결과
→ 세부 근거·기록
```

- 사용자의 현재 결정을 방해하지 않는 범위에서 정보를 제공한다.
- 모든 정보를 동시에 보여주는 것을 완전성으로 취급하지 않는다.
- 전장, 선택 대상과 현재 Prompt가 지속 Panel보다 우선한다.
- 정보는 중요도, 시간 민감도, 행동 가능성에 따라 배치한다.
- Player와 DM은 같은 데이터를 더 많이/적게 보여주는 관계가 아니라 서로 다른 Permission Projection을 받는다.

## 2. 정보 우선순위

### Priority 1 — 지금 행동에 필수

- 현재 Mode·Turn·Prompt
- 현재 선택 대상
- Action 적격성·비용·범위
- 위험·차단 이유
- Confirm·Cancel 의미

항상 즉시 보이거나 한 번의 Focus 안에 있어야 한다.

### Priority 2 — 현재 상황 판단

- HP·Resource·Condition
- Party·Initiative·Objective
- 이동 가능 거리·Cover·Detection 상태
- Item·Spell 핵심 설명

HUD·Side Panel·Context Card에 표시한다.

### Priority 3 — 상세 설명과 근거

- 계산 Breakdown
- 규칙 출처
- 전체 Feature 설명
- 변경 History·Backlink·Diagnostic

Tooltip, Details, Journal, Log 또는 전문 Panel로 확장한다.

## 3. 전장 우선 원칙

- 지속 HUD는 화면 가장자리에 둔다.
- 중앙 전장 안전 영역에는 지속 Panel을 두지 않는다.
- World Feedback은 대상과 가까워야 하지만 Token·경로·범위 중심을 덮지 않는다.
- 화면이 좁아질 때 중앙 시야보다 부가 정보를 먼저 축약한다.
- Camera가 Panel을 피하도록 Gameplay Authority를 바꾸지 않는다. 필요한 경우 User Camera Framing만 보정한다.

## 4. 화면별 Primary Surface

한 시점에 하나의 Primary Surface가 있어야 한다.

예:

```text
Exploration
→ World + Context Action

Encounter
→ World + Action HUD

Character 관리
→ Character Sheet

Scene 제작
→ World + Tool Host + Inspector

DM 운영
→ World + DM Workspace
```

Secondary Panel은 Primary Surface의 현재 작업을 보조하며, 같은 값을 서로 다른 편집 원본으로 제공하지 않는다.

## 5. Panel 유형

### Persistent HUD

현재 상태와 빠른 행동. 상세 문서를 담지 않는다.

### Docked Panel

Inventory, Journal, DM Workspace, Inspector처럼 반복적으로 참조하는 도구.

### Side Sheet

대상을 유지하면서 세부 정보를 확인한다.

### Modal

외부 상호작용을 막아야 하는 Critical 결정에만 사용한다.

### Authority Prompt

서버가 소유하는 응답 대기 상태. 일반 Modal과 시각적으로 구분한다.

### Tooltip·Context Card

짧은 보조 정보. 핵심 행동 경로의 유일한 설명이 되지 않는다.

### Toast·Banner

작업을 차단하지 않는 결과·경고. 영구 기록의 대체물이 아니다.

## 6. Progressive Disclosure 단계

```text
Level 0 — Icon·Badge·한 줄 상태
Level 1 — Context Card·짧은 Tooltip
Level 2 — Side Sheet·Expanded Panel
Level 3 — Full Sheet·Journal·Log·Diagnostic
```

- 각 단계는 동일 Stable ID와 Projection을 기반으로 한다.
- 더 자세히 보기 위해 현재 선택이 사라지지 않아야 한다.
- Back 동작은 이전 정보 단계로 한 단계만 돌아간다.
- 상세 Panel을 닫아도 Gameplay Mode와 Authority 상태는 유지된다.

## 7. 목록과 대량 정보

- 긴 목록은 가상화한다.
- 검색, 필터, 정렬은 의미가 명확한 경우에만 제공한다.
- 현재 적용 중인 Filter를 항상 표시한다.
- 빈 검색 결과와 데이터 없음 상태를 구분한다.
- Item·Spell·Feature는 이름만 나열하지 않고 사용 가능 여부와 핵심 상태를 함께 표시한다.
- 같은 종류의 Badge는 최대 수를 제한하고 나머지는 요약한다.
- 긴 이름과 한국어 Localization이 잘리지 않도록 Tooltip 또는 Wrap을 제공한다.

## 8. Navigation

### Panel Navigation

- 현재 위치를 Header, Tab, Breadcrumb 또는 Outline으로 보여준다.
- Tab은 같은 정보 계층의 형제 View에만 사용한다.
- Button을 Tab처럼, Tab을 Action처럼 사용하지 않는다.
- 브라우저식 Back History와 Gameplay Q Cancel을 혼합하지 않는다.

### Journal Navigation

- Stable Document·Section·Anchor ID를 사용한다.
- Rename 후에도 Link가 유지돼야 한다.
- 권한 없는 Target은 Search·Backlink·Recent에 나타나지 않는다.
- World Link는 Camera·Selection·Transition Proposal을 만들 뿐 직접 이동·선택을 확정하지 않는다.

### Scene·World Navigation

- Camera Focus, Follow와 Selection을 분리한다.
- 동명 Target을 자동 재연결하지 않는다.
- Stream Out·삭제·Rollback된 대상에는 구조화된 Unavailable 상태를 보여준다.

## 9. DM 정보 밀도

DM Workspace는 Player UI보다 높은 밀도를 허용하지만 다음을 지킨다.

- Session, Scene, Player, Encounter, Prompt와 Recovery 영역을 구획한다.
- Player View Preview와 DM-only Source를 같은 Panel에서 혼합하지 않는다.
- 위험 Quick Action을 일반 상태 Badge 옆에 무분별하게 배치하지 않는다.
- 여러 Player 요청은 Queue·대상·만료·우선순위로 정리한다.
- Inspector와 Runtime State, Authoring Source를 명확히 구분한다.
- 권한이 높은 정보일수록 장식보다 Label과 Provenance를 강조한다.

## 10. Character Sheet·Inventory

- Sheet는 Source 선택, Compiled 결과와 현재 State를 시각적으로 구분한다.
- Derived 값은 근거를 펼쳐볼 수 있어야 한다.
- Inventory는 Item Definition과 ItemInstance를 혼동하지 않는다.
- Equipment, Container, Ground Presence는 서로 다른 위치 상태로 표시한다.
- 행동 가능한 Item은 비용·사용 Context와 연결한다.
- 전체 공식 설명을 HUD에 복제하지 않고 상세 View로 보낸다.

## 11. Editor 정보 구조

기본 순서:

```text
Tool Palette
→ World Preview
→ Selection
→ Inspector
→ Diagnostics·Publish Status
```

- Auto Save, Compile, Candidate Ready, Published와 Live Patched를 별도 상태로 표시한다.
- Source Object와 Runtime Object를 같은 Inspector에서 혼동하지 않는다.
- Tool별 설정은 공통 Inspector Pattern을 사용한다.
- 오류는 Object·Field·Source 위치로 이동할 수 있어야 한다.
- Publish 전에 Critical Route·Disclosure·Migration 결과를 요약한다.

## 12. Empty·Loading·Blocked 상태

모든 주요 Surface는 다음을 구분한다.

```text
Loading
Empty
Filtered Empty
Permission Denied
Not Ready
Stale
Unavailable
Error
```

- 빈 화면만 보여주지 않는다.
- 다음 행동이 있으면 하나의 명확한 Primary Action을 제공한다.
- 사용자가 해결할 수 없는 상태에 Retry Button을 남용하지 않는다.
- 권한 거부는 비밀 Target 존재 여부를 암시하지 않는다.

## 13. 금지 패턴

- 같은 값을 여러 Panel에서 동시에 편집
- 모든 세부 설명을 HUD에 상시 표시
- 현재 Filter·Sort가 보이지 않는 목록
- 빈 상태와 오류 상태를 동일하게 표현
- 권한 없는 정보의 Count·Facet·자리만 남김
- 동명 표시 이름으로 Navigation Target 결정
- Character Source와 현재 HP를 하나의 편집 Form에 혼합
- Scene Source와 Runtime Instance를 같은 상태로 표시
- Modal 안에 Modal을 반복 중첩

## 14. 구현 검수

- 현재 Primary Surface와 결정이 분명하다.
- Priority 1 정보가 즉시 보인다.
- 상세 정보는 선택을 잃지 않고 확장된다.
- 목록은 대량 데이터에서 사용할 수 있다.
- Loading·Empty·Denied·Stale·Error가 구분된다.
- DM-only와 Player Preview가 분리된다.
- Stable ID 기반 Navigation을 사용한다.
- 중앙 전장 안전 영역이 유지된다.
