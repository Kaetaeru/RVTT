# Systems 문서

- 상태: ACTIVE
- 문서 종류: System Index

기능 영역별 사용자 흐름과 시스템 동작을 정의한다.

System 문서는 Product와 Architecture를 구체화하는 권위 문서다. 전체 시스템 흐름과 인접 경계는 [`Main System Guide 허브`](../guides/README.md)에서 먼저 확인한다.

## 기본 탐색 순서

```text
현재 Work Order
→ Runtime Foundation Guide
→ 현재 Domain Main System Guide
→ 해당 System README
→ 연결된 Architecture·ADR
→ Implementation Spec
```

- 현재 작업 순서: [`../CURRENT-WORK-ORDER.md`](../CURRENT-WORK-ORDER.md)
- Main System Guides: [`../guides/README.md`](../guides/README.md)
- Implementation Specs: [`../specs/README.md`](../specs/README.md)

## 영역

- `scene/`
- `navigation/`
- `character/`
- `ruleset/`
- `rules/`
- `extension/`
- `inventory/`
- `combat/`
- `perception/`
- `interaction/`
- `session/`
- `exploration/`
- `events/`
- `time/`
- `downtime/`
- `camera/`
- `journal/`
- `diagnostics/`
- `testing/`
- `integration/`

각 영역 README는 직접 상위 Architecture와 ADR, 현재 권위 System 문서, 관련 Main System Guide, 고정 책임 경계, 추천 읽기 순서와 후속 Implementation Spec 위치를 안내한다.

## Guide 묶음

| System 영역 | 기본 Main System Guide |
|---|---|
| session | [`Session, Networking, Persistence와 Recovery`](../guides/session/README.md) |
| scene·navigation | [`Scene, Streaming, Runtime Object, Spatial Query와 Navigation`](../guides/scene/README.md) |
| exploration·interaction·perception | [`Exploration, Selection, Interaction과 Perception`](../guides/exploration/README.md) |
| ruleset·rules | [`Rules, Character Action, Spell, Dice와 Effect`](../guides/rules/README.md) |
| combat·time | [`Combat와 Encounter`](../guides/combat/README.md) |
| character·inventory·downtime | [`Character, Inventory와 Downtime`](../guides/character/README.md) |
| camera와 Client Presentation | [`UI, Camera와 Presentation`](../guides/ui/README.md) |
| journal | [`Journal과 Ping`](../guides/journal/README.md) |
| Scene Authoring | [`Scene Editor와 Authoring`](../guides/scene-editor/README.md) |
| diagnostics·testing | [`Diagnostics, Simulation과 Operations`](../guides/diagnostics/README.md) |
| extension | [`Extension, Plugin과 Content Pack`](../guides/extension/README.md) |
| integration | 현재 작업과 직접 관련된 여러 Guide + [`Integration README`](integration/README.md) |

공통 권위 기반은 [`Runtime Foundation과 Authority Guide`](../guides/runtime/README.md)를 먼저 읽는다.

## 고정 문서 원칙

- System 문서는 Guide를 권위 Parent로 사용하지 않는다. Guide 링크는 탐색 Reference다.
- 공통 기반 계약은 `../architecture/`, 화면 배치는 `../ui/`에 둔다.
- `SUPERSEDED`, `DISCONTINUED`, `ARCHIVED` 문서는 현재 권위 읽기 순서에서 제외한다.
- 같은 Authority State를 둘 이상의 System이 독립 원본으로 소유하지 않는다.
- 영역 간 상태 변경은 Command·RuleExecution·Transaction·Event 경계를 사용한다.
- 실제 파일·Type·Remote·Persistence·Test 계약은 `../specs/`에 둔다.

문서 이동과 역사 경로는 [`../DOCUMENT-MIGRATION-MAP.md`](../DOCUMENT-MIGRATION-MAP.md)를 따른다.
