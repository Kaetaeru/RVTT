# Slice 12 Work Order — Content Pack·Localization·Trusted Extension Platform

- 상태: CHECKPOINT_COMPLETE
- 문서 종류: Slice Implementation Spec Work Order
- 즉시 구현 명세 가능성: BLOCKED
- 작성일: 2026-08-05
- 전체 Roadmap: [`SLICE-ROADMAP.md`](../../SLICE-ROADMAP.md)
- 선행 Slice: [`Core Rules`](../02-core-rules-kernel/implementation-contract.md), [`Scene Authoring`](../10-scene-authoring-compile-publish/implementation-contract.md), [`UI`](../08-player-ui-camera-presentation/implementation-contract.md)
- 통합 계약: [`implementation-contract.md`](implementation-contract.md)
- 검수 감사: [`Slice 12 Spec Checkpoint Audit`](../../../audits/slices/12-content-pack-localization-trusted-extension-spec-checkpoint-audit.md)

## 사용자 완료 결과

```text
Developer가 Versioned Pack 작성
→ Manifest·Dependency·Trust·Budget 검증
→ Catalog·Policy·Content·Provider Compile
→ Candidate Activation·Migration Review
→ Campaign Binding
→ Frozen Snapshot
→ 실패 시 Last Known Good·Rollback
```

## 명세 작업 순서

| 순서 | 상태 | 작업 | 완료 기준 |
|---:|---|---|---|
| 1 | DONE | Pack Manifest·Stable Content ID | Pack·Content·Locale·Dependency Identity 정의 |
| 2 | DONE | Catalog Loader·Dependency Graph | Load Order 결정성·Cycle·Conflict Gate 정의 |
| 3 | DONE | Localization Bundle | 표시 문자열과 Authority Digest 분리 |
| 4 | DONE | Policy Registry·Patch·Snapshot | Product Default·Ruleset·Source Pack·Campaign 합성 정의 |
| 5 | DONE | Grant·Capability·Recipe Registry | Content Compiler와 Missing Content Recovery 정의 |
| 6 | DONE | Trusted Operation·Tool·Provider·Presentation Host | Trust Class·Capability·Budget·Failure Isolation 정의 |
| 7 | DONE | Candidate Activation·Migration·Removal | 사용 중 Ref·Version 고정·Last Known Good 정의 |
| 8 | DONE | Persistence·Disclosure·Load·Contract Test | Restart·Rollback·Secret·대규모 Catalog Scenario 정의 |
| 9 | BLOCKED | Production Build Pipeline Mapping | 실제 Packaging·Signing·Asset·Registry·CI 구조 조사 필요 |

## 구현 시 추출할 세부 명세

```text
content/pack-manifest-catalog
content/dependency-compiler
localization/bundle-fallback
ruleset/policy-registry-snapshot
content/grant-recipe-compiler
extension/trusted-operation-host
extension/tool-provider-presentation-host
content/migration-removal-recovery
```

## 차단 사항

- 실제 Package·Asset·Build·Release Pipeline
- Source Pack·Catalog·Locale Bundle 구조
- Trusted Module Packaging·Signing·권한 검증
- 공식 콘텐츠 Source Metadata와 권리 검토 프로세스
- Registry Budget·Retention·Migration CI Host