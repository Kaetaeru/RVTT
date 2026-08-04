# RVTT All-slices Script Manifest

- 상태: IMPLEMENTED_UNVERIFIED
- 작성일: 2026-08-05
- Production Root: `implementation/roblox/`
- 규칙: 각 Script는 단일 책임, 공개 API, 권위 경계, 테스트 또는 검증 경로를 가진다.

## Checkpoint 0 — Toolchain·Shared Runtime

| 순서 | 경로 | 책임 | 상태 |
|---:|---|---|---|
| 001 | `default.project.json` | Production Rojo DataModel mapping | DONE |
| 002 | `test.project.json` | Test-only DataModel mapping | DONE |
| 003 | `Shared/Core/*` | ID·Version·Result·Error·copy | DONE |
| 004 | `Shared/Protocol/*` | Envelope·Remote name·projection contract | DONE |
| 005 | `Server/Runtime/*` | command, transaction, event, authority | DONE |
| 006 | `Server/Persistence/*` | migration, snapshot, journal, DataStore adapter | DONE |
| 007 | `Client/*` | command, projection, input, camera, presentation | DONE |
| 008 | `UI/*` | token-driven shared UI shell | DONE |

## Slice Domain Scripts

| Slice | Domain Script | 주요 계약 | 상태 |
|---:|---|---|---|
| 01 | `Server/Domains/SessionDomain.lua` | Join·Character Select·Ready·Scene Entry·Reconnect | DONE |
| 01 | `Server/Domains/SceneDomain.lua` | Runtime scene·controlled actor·position | DONE |
| 01 | `Server/Domains/MovementDomain.lua` | authoritative click movement·checkpoint | DONE |
| 02 | `Server/Domains/RulesDomain.lua` | D20·attack·save·damage·healing | DONE |
| 03 | `Server/Domains/ExplorationDomain.lua` | interaction·search·knowledge·fog·WASD intent | DONE |
| 04 | `Server/Domains/EncounterDomain.lua` | timeline·turn·opportunity·rollback marker | DONE |
| 05 | `Server/Domains/CharacterDomain.lua` | draft·validation·activation·level progression | DONE |
| 06 | `Server/Domains/InventoryDomain.lua` | item location invariant·equip·ground transfer | DONE |
| 07 | `Server/Domains/TimeDomain.lua` | campaign time·schedule·rest·downtime | DONE |
| 08 | `Server/Domains/UiPreferenceDomain.lua` | safe persistent UI preferences | DONE |
| 09 | `Server/Domains/JournalDomain.lua` | documents·links·knowledge-safe ping | DONE |
| 10 | `Server/Domains/SceneAuthoringDomain.lua` | source·candidate compile·atomic publish | DONE |
| 11 | `Server/Domains/DmWorkspaceDomain.lua` | control·quick action·runtime patch·recovery | DONE |
| 12 | `Server/Domains/ContentDomain.lua` | manifest·dependency·activation·localization | DONE |
| 13 | `Server/Domains/CharacterContentDomain.lua` | coverage registry; official data blocked | DONE_WITH_DATA_BLOCKER |
| 14 | `Server/Domains/RulesContentDomain.lua` | spell/equipment coverage; official data blocked | DONE_WITH_DATA_BLOCKER |
| 15 | `Server/Domains/NpcContentDomain.lua` | actor import·validation·spawn definition | DONE_WITH_DATA_BLOCKER |
| 16 | `Server/Domains/ReleaseDomain.lua` | evidence ledger·release gate evaluation | DONE_UNVERIFIED |

## 검증 상태

- 구조·Manifest·정책 정적 검사: 수행 가능
- Luau typecheck·format·lint: Toolchain 실행 환경 필요
- Roblox Studio integration·DataStore·multi-client·physics: 미실행
- 공식 D&D 데이터: 포함하지 않음. Rights·source review 후 별도 팩으로 추가
