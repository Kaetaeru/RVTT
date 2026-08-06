# RVTT Live DataStore Tests

This directory contains Studio-only tests that call the real Roblox DataStore API.
It is intentionally excluded from `test.project.json` and is mapped only by
`live-datastore.project.json`.

Run these tests only in a separately published test experience with Studio API
access enabled. The runner uses the isolated store
`RVTT_Authority_Integration_v1` and removes its temporary GUID key after the run.
