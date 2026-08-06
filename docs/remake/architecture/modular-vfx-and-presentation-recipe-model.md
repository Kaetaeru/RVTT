# 모듈형 VFX와 프레젠테이션 레시피 모델

- 상태: `SUPERSEDED`
- 이전 상태: 초안
- 대체 권위 문서:
  - [`Presentation Recipe, Playback Priority와 Extension Runtime 계약`](presentation-recipe-playback-priority-and-extension-runtime-contract.md)
  - [`ADR-0075`](../decisions/ADR-0075-versioned-data-driven-and-fault-isolated-presentation-runtime.md)
- 역사적 관련 결정:
  - [`ADR-0046`](../decisions/ADR-0046-modular-presentation-recipes-and-extension-contracts.md)

이 문서에서 제안한 다음 방향은 새 권위 문서에 계승되었다.

- 공격 시전자·모션·이동·피격자·카메라·화면 효과의 모듈 분리
- Slot 기반 Presentation Recipe
- Feature·Item·Effect의 Presentation Augment
- 품질 Variant, Fallback과 오류 격리
- 리그 없는 토큰을 위한 의미 Anchor
- 신뢰된 Registry 기반 확장 구조

다만 이 문서는 다음 최신 기반을 완전히 반영하지 못한다.

- 불변 Compiled Presentation Recipe와 버전 고정 Playback
- 플레이테스트용 Hot Swap과 이전 버전 복원
- Presentation Queue, Budget와 Marker timeout
- CameraRequest 전용 연동
- Observer별 Visibility·Knowledge Projection
- 사용자 접근성 Hard Limit
- 재접속·Rollback과 Pending Reveal 복구

현재 설계·구현 판단에는 반드시 새 권위 문서를 사용한다. 이전 본문은 Git 이력에서 확인할 수 있다.
