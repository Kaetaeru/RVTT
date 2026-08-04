# Character 시스템

캐릭터 성장 원본, Compiled Character Build, 캠페인 영구 현재 상태, 주문 획득과 주문책, HP 0·휴식·회복, NPC 스탯블록과 Scene Actor Binding을 다룬다.

## 최상위 권위 계약

- [`../../architecture/compiled-build-and-authoritative-state-pattern.md`](../../architecture/compiled-build-and-authoritative-state-pattern.md)
  - Source, 불변 Compiled Build, 버전된 Authoritative State와 Projection을 분리한다.
- [`../../architecture/character-runtime-and-compiled-character-build-contract.md`](../../architecture/character-runtime-and-compiled-character-build-contract.md)
  - Character Progression Source와 Compiled Character Build
  - Persistent Character State, Scene Actor State와 Encounter State의 수명주기 분리
  - Derived Statistics, Modifier, Resource와 Capability Binding
  - 레벨업·재구성 시 Build 교체와 State Migration
  - Persistence, Rollback과 Character Projection

## 세부 권위 문서

- [`spell-acquisition-preparation-and-cast-access-model.md`](spell-acquisition-preparation-and-cast-access-model.md)
- [`spellbook-repository-and-copying-model.md`](spellbook-repository-and-copying-model.md)
- [`zero-hit-points-death-saves-rest-and-resource-recovery-model.md`](zero-hit-points-death-saves-rest-and-resource-recovery-model.md)
- [`monster-npc-statblock-and-ingame-json-import-model.md`](monster-npc-statblock-and-ingame-json-import-model.md)

## Character와 Scene Actor 경계

- [`../../decisions/ADR-0014-character-data-and-scene-actor-separation.md`](../../decisions/ADR-0014-character-data-and-scene-actor-separation.md)
  - Character 영구 원본과 Scene CharacterActor를 분리한다.
- [`../../architecture/runtime-object-system-and-entity-lifecycle-contract.md`](../../architecture/runtime-object-system-and-entity-lifecycle-contract.md)
  - ActorId는 Actor Component가 있는 RuntimeObjectId의 타입 있는 Scene Presence 참조다.
  - CharacterId와 NPC 영구 원본 ID는 Scene Runtime Object와 별도로 유지한다.
  - Scene Transfer는 같은 CharacterId를 새 Actor Runtime Object에 연결한다.
  - Actor Spawn·Suspend·Archive·Destroy와 Presentation Materialization은 공통 Lifecycle을 사용한다.

## 고정 권위 경계

```text
Character Progression Source
→ 성장 출처, 선택과 예외 획득

Compiled Character Build
→ Grant, Capability, Modifier, Resource Definition과 Derived Plan

Persistent Character State
→ 현재 HP, 장기 자원, 장비·조율과 지속 상태

Scene Actor State
→ 위치, 회전, Scene Presence와 공개 상태

Encounter State
→ Initiative, 행동 경제와 이번 턴 이동력
```

한 계층의 값을 다른 계층에 복사해 독립 원본으로 만들지 않는다.

아이템은 [`../inventory/`](../inventory/), 실행 규칙은 [`../rules/`](../rules/)를 참고한다.

## Guide 상태

```text
Guide Status: NOT_READY
```

Character Main System Guide는 Effect·Inventory 관련 권위 문서, 구현 명세와 Completion Audit가 완료된 뒤 작성한다.
