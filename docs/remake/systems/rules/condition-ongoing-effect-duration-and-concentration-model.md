# 상태·지속 효과·집중 수명주기 모델

- 문서 생명주기: `SUPERSEDED`
- 이전 상태: 초안
- 대체일: 2026-08-04
- 대체 문서:
  - [`Effect, Condition과 Ongoing Runtime 계약`](../../architecture/effect-condition-and-ongoing-runtime-contract.md)
  - [`ADR-0065`](../../decisions/ADR-0065-compiled-effect-builds-and-authoritative-effect-instances.md)
- 관련 기존 결정:
  - [`ADR-0029`](../../decisions/ADR-0029-unified-effect-instances-duration-concentration-and-suppression.md)

이 문서는 상태, 버프, 집중, 변신, 지속 영역과 소환을 공통 `EffectInstance` 수명주기로 관리한다는 초기 상세 기획이었다.

핵심 결정은 여전히 유효하지만, 다음 공통 기반이 확정되기 전에 작성되어 현재 구현·기획 판단의 권위 문서로 사용할 수 없다.

- 불변 Compiled Build와 Authoritative State 분리
- Character·Actor·Encounter 상태 경계
- RuleExecution과 PendingEffect
- Runtime Object Identity와 Ownership
- 원자적 Transaction과 Commit Graph
- Manifest·Chunk Snapshot, Recovery와 Rollback Branch

현재 기준은 대체 Architecture와 ADR-0065를 따른다. 원문은 Git 기록에서 확인할 수 있다.
