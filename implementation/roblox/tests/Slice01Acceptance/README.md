# Slice 01 Studio Acceptance Harness — Legacy

- 상태: `ARCHIVED_LEGACY_HARNESS · NOT_CURRENT_TASK · NOT_MOUNTED_BY_CURRENT_SLICE01_PROJECT`
- 용도: 과거 persistence-era Slice 01 흐름 기록
- 현재 실행 기준: [`../../slice01-acceptance.project.json`](../../slice01-acceptance.project.json)

**이 문서의 아래 절차는 현재 개발 절차가 아니다.** 현재 `slice01-acceptance.project.json`은 이 디렉터리의 `Slice01Acceptance.client.lua`를 마운트하지 않으며, `tests/WorldTokenAcceptance`와 `tests/ContextInputAcceptance`를 마운트하고 `EnableStudioPersistence=false`를 사용한다.

현재 개발 작업은 Acceptance Harness가 아니라 `.github/CODEX-ACTIVE-TASK.md`의 Studio-first Production 작업을 따른다.

---

## Historical procedure

This test-only harness validated the production authority, projection, networking, and persistence path without extending the placeholder production UI.

### Historical Project Assumption

The old procedure built `slice01-acceptance.project.json` and published it to a Studio persistence test Place with assumptions that no longer match the current project mapping.

It expected two test-only flags:

- `ServerStorage.RVTT.EnableStudioPersistence=true`
- `ServerStorage.RVTT.Slice01AcceptanceMode=true`

The current project now sets `EnableStudioPersistence=false` and mounts the newer focused World/Context harnesses instead.

### Historical Flow

1. Join the session and refresh the DM membership.
2. Create and activate a test character.
3. Select the character.
4. Mark ready.
5. Start the acceptance scene.
6. Enter the scene and project the actor.
7. Select the projected token in the scene canvas.
8. Commit a server-authoritative move.
9. Wait for the persistence save log.
10. Stop and Play again.
11. Verify character, scene, actor position, connection, avatar suppression, and Accent recovery.

The old harness resolved `ClientRuntime` dynamically because it was mounted only by the acceptance project at that time. This text is retained only to explain historical evidence and old commits.

The screen was an acceptance instrument, not a production visual design candidate.
