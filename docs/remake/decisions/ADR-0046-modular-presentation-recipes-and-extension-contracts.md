# ADR-0046: VFX와 애니메이션은 규칙 해결 사이에 삽입되는 모듈형 프레젠테이션 레시피로 구성한다

- 상태: 확정
- 결정일: 2026-08-03
- 관련 문서:
  - [`22. EffectRecipe`](../22-effect-recipe-resolution-and-commit-model.md)
  - [`27. 주사위 연출`](../27-dice-roll-presentation-and-resolution-gating-model.md)
  - [`33. 전투 HUD`](../33-baldurs-gate-style-combat-hud-and-contextual-action-ui-model.md)
  - [`40. 모듈형 VFX와 프레젠테이션 레시피`](../40-modular-vfx-and-presentation-recipe-model.md)

## 결정

규칙 효과를 만드는 `EffectRecipe`와 시각·음향·카메라 연출을 만드는 `PresentationRecipe`를 분리한다.

```text
ActionExecution
├─ authoritative EffectRecipe
└─ non-authoritative PresentationRecipe
```

PresentationRecipe는 다음 슬롯을 조합할 수 있다.

- pre_action
- source_cast
- source_motion
- projectile_or_travel
- target_warning
- impact
- target_reaction
- environment
- camera
- screen_overlay
- post_action

각 VFX는 Registry에 등록된 독립 모듈이며, 콘텐츠는 모듈 ID와 파라미터만 참조한다. 자유 Luau 코드나 ModuleScript 경로를 콘텐츠 데이터에서 직접 실행하지 않는다.

Feature, Feat, 상태 효과와 장비는 PresentationAugment를 제공해 기존 연출 앞·뒤·사이에 모듈을 삽입할 수 있다.

예를 들어 광분 상태의 공격은 `pre_action`에 함성 연출을 삽입한 뒤 원래 무기 공격 모션과 명중 연출을 이어서 실행한다.

연출은 권위 규칙을 변경하지 않는다. 필수 공개 게이트가 아닌 일반 VFX가 실패하거나 생략되어도 공격, 피해와 자원 소모는 서버 규칙에 따라 계속 진행한다.

외부 플러그인 API는 당장 제공하지 않는다. 대신 내부 Registry와 버전 있는 계약을 유지하여 미래에 신뢰된 확장 팩이나 도구 모듈을 추가할 수 있게 한다.
