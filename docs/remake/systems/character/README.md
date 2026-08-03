# Character 시스템

캐릭터 영구 데이터, 주문 획득과 주문책, HP 0·휴식·회복, NPC 스탯블록과 Scene Actor Binding을 다룬다.

## 권위 문서

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

아이템은 [`../inventory/`](../inventory/), 실행 규칙은 [`../rules/`](../rules/)를 참고한다.
