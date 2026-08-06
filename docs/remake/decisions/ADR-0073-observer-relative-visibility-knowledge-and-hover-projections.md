# ADR-0073: Observer-relative Visibility, Knowledge와 Hover Projection

- 상태: 채택
- 작성일: 2026-08-04

## Context

RVTT는 수동 Fog, D&D 감각, 은신, 함정·비밀문, 미식별 아이템, 플레이어별 발견 상태와 DM 전용 정보를 동시에 지원해야 한다.

Hover UI가 Authority 데이터를 직접 조회하거나, Client가 전체 정보를 받은 뒤 일부만 숨기면 비밀 HP·AC·상태·함정 Identity가 유출될 수 있다.

또한 보이는 대상, 소리로 위치만 아는 대상, 이전에 발견했지만 현재 보이지 않는 대상을 하나의 `visible` Boolean으로 표현할 수 없다.

## Decision

다음을 독립된 권위 개념으로 관리한다.

```text
Visibility
Detection
Knowledge
Disclosure
```

모든 결과는 Observer Context 기준으로 평가한다.

Client는 Authority Entity 전체를 받지 않고 Observer-relative Projection만 받는다.

Hover는 Selection Candidate에 대해 새 권위 우회 조회를 수행하지 않는다.

```text
Client-safe Candidate
→ Disclosure Evaluation
→ HoverInformationProjection
→ Hover Card
```

Hover Projection에는 허용된 필드만 포함한다. 플레이어 Client에 실제 HP, AC, 숨은 상태, 저항·면역, 미식별 Item Definition과 발견 전 Secret Runtime Identity를 전송하지 않는다.

수동 Fog는 지형 공개 권위로 유지하며 Actor·함정·비밀 요소의 Detection을 대체하지 않는다.

Knowledge는 `character`, `player`, `party`, `faction`, `global`, `DM_only` Scope를 지원한다.

## Consequences

### Positive

- Hover, Selection, Targeting과 Journal이 같은 공개 정책을 사용한다.
- 개인별 발견과 파티 공유를 모두 지원할 수 있다.
- 현재 보이지 않지만 알려진 대상과, 감지됐지만 외형을 모르는 대상을 표현할 수 있다.
- 숨은 정보가 Player Client에 불필요하게 복제되지 않는다.
- Rollback에서 Fog, 발견, 식별 상태를 함께 복원할 수 있다.

### Cost

- Observer별 Projection과 Perception Relation 무효화가 필요하다.
- DM Full View와 Player Preview View를 별도로 생성해야 한다.
- Hover 정보도 Projection Revision과 캐시 정책을 가져야 한다.

## Rejected Alternatives

### 하나의 `visible` Boolean

현재 시야, 감지, 기억과 공개 수준을 표현할 수 없어 거부한다.

### Client에 전체 정보를 보내고 UI에서 숨김

보안과 비밀 정보 유출 위험 때문에 거부한다.

### Hover 시마다 Authority Entity 전체 조회

Hover를 숨은 정보 탐색 API로 악용할 수 있고 서버 부하와 권위 경계를 해치므로 거부한다.

### Fog가 모든 탐지와 공개를 결정

Fog는 지형 공개와 기억을 담당하며 감각·은신·함정 탐지를 대체하지 않으므로 거부한다.

## Related

- [`Visibility, Knowledge, Detection과 Hover Information Runtime 계약`](../architecture/visibility-knowledge-detection-and-hover-information-runtime-contract.md)
- [`Selection, Targeting, Preview와 Frozen Binding Runtime 계약`](../architecture/selection-targeting-preview-and-frozen-binding-runtime-contract.md)
- [`수동 Fog of War와 선택형 Assist 모델`](../systems/perception/manual-fog-of-war-and-optional-assist-model.md)
