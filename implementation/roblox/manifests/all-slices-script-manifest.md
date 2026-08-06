# RVTT All-slices Script Manifest

- 상태: `IMPLEMENTED_UNVERIFIED`
- 작성일: 2026-08-05
- Production Root: `implementation/roblox/`
- 총 Domain: `18`
- 검증 기준: 명시적 Authorization·Server Authority·Viewer Projection·Persistence·Test

## 공통 Runtime

| 영역 | 주요 Script | 상태 |
|---|---|---|
| Shared Core | `Identity`, `Version`, `Result`, `ValueGuard`, `Signal` | DONE |
| Protocol | `Envelope`, `RemoteNames`, `ProjectionContract` | DONE |
| Server Runtime | `AuthorityRuntime`, `CommandRegistry`, `TransactionCoordinator`, `EventOutbox` | DONE |
| Security | `RateLimiter`, Domain Authorization, Ownership·Control Helpers | DONE |
| Rules | `ActorProfileResolver`, `RuleResolver`, `RulesDomain` | DONE |
| Projection | `DomainProjectionPolicy`, `ProjectionBuilder`, `ProjectionPublisher` | DONE |
| Persistence | `MigrationRegistry`, `ProfileStore`, `PersistenceCoordinator`, `SnapshotJournal` | DONE_UNVERIFIED |
| Client | `ProjectionReplica`, `CommandClient`, `ClientRuntime`, Semantic Input | DONE_UNVERIFIED |
| UI | Loading, Token-based HUD Shell, State Banner, Action Prompt | DONE_UNVERIFIED |
| Test | Unit·Integration·Security·Disclosure Specs, Static Validator | DONE_UNVERIFIED |

## Slice Domain Coverage

| Slice | Domain Script | 상태 |
|---:|---|---|
| 01 | `SessionDomain`, `SceneDomain`, `MovementDomain` | IMPLEMENTED_UNVERIFIED |
| 02 | `RulesDomain` | IMPLEMENTED_UNVERIFIED |
| 03 | `ExplorationDomain` | IMPLEMENTED_UNVERIFIED |
| 04 | `EncounterDomain` | IMPLEMENTED_UNVERIFIED |
| 05 | `CharacterDomain` | IMPLEMENTED_UNVERIFIED |
| 06 | `InventoryDomain` | IMPLEMENTED_UNVERIFIED |
| 07 | `TimeDomain` | IMPLEMENTED_UNVERIFIED |
| 08 | `UiPreferenceDomain` | IMPLEMENTED_UNVERIFIED |
| 09 | `JournalDomain` | IMPLEMENTED_UNVERIFIED |
| 10 | `SceneAuthoringDomain` | IMPLEMENTED_UNVERIFIED |
| 11 | `DmWorkspaceDomain` | IMPLEMENTED_UNVERIFIED |
| 12 | `ContentDomain` | IMPLEMENTED_UNVERIFIED |
| 13 | `CharacterContentDomain` | IMPLEMENTED_WITH_DATA_BLOCKER |
| 14 | `RulesContentDomain` | IMPLEMENTED_WITH_DATA_BLOCKER |
| 15 | `NpcContentDomain` | IMPLEMENTED_WITH_DATA_BLOCKER |
| 16 | `ReleaseDomain` | IMPLEMENTED_UNVERIFIED |

`IMPLEMENTED_UNVERIFIED`는 Source와 Test Source가 존재하고 정적 정책 검사를 통과했지만 Roblox Studio·DataStore·Performance 증거가 없음을 뜻한다.
