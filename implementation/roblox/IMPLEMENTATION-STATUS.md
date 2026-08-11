# RVTT Production Implementation Status

- 상태: `STUDIO_FIRST_ITERATION`
- 최종 갱신일: 2026-08-12
- 현재 작업 순서: [`CURRENT-WORK-ORDER.md`](CURRENT-WORK-ORDER.md)

## 현재 요약

```text
16 Slice Production Baseline
→ EXISTS

Full UI·UX / ADR-0091 Source·Static
→ BROADLY VERIFIED

현재 개발 단계
→ STUDIO-FIRST PRODUCT ITERATION

Multi-client·Persistence·Performance·Grand Acceptance
→ STABILIZATION / RELEASE EVIDENCE
```

기존 Production Authority·Persistence·Projection·Recovery 구조와 기존 자동 Test/Runner는 유지한다. 이번 전환은 그 기반을 폐기하는 작업이 아니라 **실제 Studio 제품을 더 일찍 보고 수정하는 개발 방식 변경**이다.

## 현재 개발 우선순위

```text
Production Place 직접 실행
→ Exploration·World Interaction
→ Encounter·Character Console
→ Management UI
→ Entry·Role·Recovery
→ DM Workspace
→ ADR-0091 Runtime Surface
→ ADR-0092 Production
```

각 기능은 Studio에서 실제 사용 흐름을 확인한 뒤 GitHub Source로 정규화한다.

## 보존된 기술 기반

- Versioned Command·Authorization·Transaction·Idempotency
- Revision·AuthorityEpoch·Projection·Negative Disclosure
- Full Resync·Reconnect·Recovery
- Persistence·Migration·Lease·Fence Tooling
- Unit·Integration·Security·Disclosure Test
- Multi-client·Persistence·Grand Acceptance Runner
- Rojo Projects와 CI Validators

이 목록은 해당 기능의 현재 Studio/Human PASS를 의미하지 않는다.

## 현재 Evidence

- `contextual-pointer-actions`: `PASS 9/9`, revision 35 — current harness observation
- historical `slice01-world-interaction`: `PASS 16/16` — old input contract
- ADR-0091 / Full UI static: `STATIC_VERIFIED`
- current Production Studio UX: `IN_PROGRESS`
- current multi-client: `NOT_EXECUTED`
- current persistence release runtime: `DEFERRED`
- performance·soak: `PENDING`

상세 상태는 루트 `AGENT-TEST-STATUS.md`를 따른다.

## Release Tooling

기존 Grand Runner, Persistence Acceptance Host와 관련 Project는 유지한다. 기능 개발 중 매 수정마다 실행하지 않고 Stabilization·Release Candidate에서 사용한다.
