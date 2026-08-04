# Perception 시스템

수동 Fog of War, 시야·감각·은신, 관찰자별 탐지, 지식 상태와 정보 공개를 다룬다.

## 상위 권위 문서

- [`Visibility, Knowledge, Detection과 Hover Information Runtime 계약`](../../architecture/visibility-knowledge-detection-and-hover-information-runtime-contract.md)
  - Visible·Detected·Known·Disclosed 분리
  - Observer별 Perception Relation과 Knowledge Scope
  - Sense Capability, Stealth Contest, Search·Study Discovery
  - Player·DM·Observer별 정보 공개
  - Hover Information Projection과 비밀 정보 차단
  - 저장·재접속·Rollback과 성능 무효화

## 시스템 문서

1. [`manual-fog-of-war-and-optional-assist-model.md`](manual-fog-of-war-and-optional-assist-model.md)
   - 수동 Discovery·Current Reveal 마스크와 선택형 Assist
   - 지형 공개 권위 문서로 계속 유효
2. [`visibility-senses-stealth-and-detection-model.md`](visibility-senses-stealth-and-detection-model.md)
   - `SUPERSEDED`
   - 감각·은신·탐지의 초기 상세 모델이며, 현재 권위는 상위 Architecture와 ADR-0073

## 고정 경계

- Fog는 지형 공개 권위이며 Actor·함정·비밀문 Detection을 대체하지 않는다.
- Visibility, Detection, Knowledge와 Disclosure를 하나의 Boolean으로 합치지 않는다.
- Hover는 Client-safe Candidate에 대한 정보 Projection이며 Authority 전체 조회가 아니다.
- 실제 HP·AC·숨은 상태·미식별 Item Definition을 Player Client에 보내고 UI에서만 숨기지 않는다.
- 발견 전 Secret Runtime Identity를 Player Projection에 포함하지 않는다.
- DM Full View와 Player Preview View는 서로 다른 Observer Projection을 사용한다.

## 역할 경계

- 플레이어는 공개 Candidate Hover, Search·Study·Hide와 공개 정보 Inspection을 사용한다.
- DM은 수동 Fog, 숨은 정보, Knowledge Scope, 강제 발견·은폐·식별과 Player Preview를 관리한다.
- 시스템은 감각 평가, Perception Relation, Disclosure와 Hover Projection을 생성한다.

## Guide Status

```text
READY_TO_WRITE
```

최신 Visibility·Knowledge·Detection·Hover Architecture, Selection·Interaction 계약과 Completion Audit에서 통합 Guide 작성 조건이 충족되었다.
