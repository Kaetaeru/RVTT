# Implementation Spec — Slice 13 Official 2024 Character Options Content

- 상태: SPEC_CHECKPOINT_COMPLETE
- 문서 종류: Content Coverage Implementation Spec
- 구현 상태: 미구현
- 즉시 구현 명세 가능성: BLOCKED
- 작성일: 2026-08-05
- 차단 이유:
  - 공식 데이터의 실제 Source·Version·권리·배포 허용 범위를 검토하지 않았다.
  - Production Pack·Localization·Coverage CI 경로를 확인하지 못했다.
- Work Order: [`CURRENT-WORK-ORDER.md`](CURRENT-WORK-ORDER.md)
- Roadmap: [`SLICE-ROADMAP.md`](../../SLICE-ROADMAP.md)
- 선행 계약: [`Character Foundation`](../05-character-foundation-creation/implementation-contract.md), [`Progression`](../07-rest-time-downtime-progression/implementation-contract.md), [`Content Platform`](../12-content-pack-localization-trusted-extension/implementation-contract.md)
- 관련 Guide: [`Character`](../../../guides/character/README.md), [`Rules`](../../../guides/rules/README.md), [`Extension`](../../../guides/extension/README.md), [`UI`](../../../guides/ui/README.md), [`Diagnostics`](../../../guides/diagnostics/README.md)

> 이 Spec은 공식 2024 Character Option을 데이터와 Scenario로 공급하는 계약을 정의한다. 규칙 본문이나 장문의 설명을 복제하지 않고, 구현에 필요한 Stable ID·구조화된 수치·출처 Metadata·Localization Key·검증 Scenario만 관리한다.

## 1. Acceptance Flow

```text
공식 Character Source Pack 선택
→ Species·Background·Class Option 조회
→ Level 1 Character 생성
→ Feature·Resource·Choice 확인
→ Level Up 2–20
→ Subclass·Feat·Ability·Spell 선택
→ Sheet·Capability·Rules 결과 확인
→ 저장·Migration·Reconnect
```

## 2. 직접 권위 문서

- [`Character Runtime과 Compiled Character Build`](../../../architecture/character-runtime-and-compiled-character-build-contract.md)
- [`Rules Content Grant와 Capability`](../../../architecture/rules-content-grant-capability-model.md)
- [`Ruleset Policy Registry와 Frozen Snapshot`](../../../architecture/ruleset-policy-registry-composition-and-frozen-snapshot-runtime-contract.md)
- [`Compiled Build와 Authoritative State 분리`](../../../architecture/compiled-build-and-authoritative-state-pattern.md)
- [`Character Action·2024 Core Action Runtime`](../../../architecture/character-action-opportunity-and-2024-core-action-runtime-contract.md)
- [`Spell Acquisition·Preparation·Cast Access`](../../../systems/character/spell-acquisition-preparation-and-cast-access-model.md)
- [`공식 2024 Character Sheet`](../../../ui/character-sheet/official-2024-character-sheet-and-live-player-ui.md)
- [`Content Platform Spec`](../12-content-pack-localization-trusted-extension/implementation-contract.md)

## 3. 범위

포함:

- 지원 Source Pack과 Source Metadata
- Species·Background·Class·Subclass·Feat Definition
- Ability Score·Proficiency·Language·Tool·Equipment·Spell Choice Descriptor
- Level 1–20 Progression Table·Feature Grant·Resource Definition
- Stored Selection·Derived Grant·Capability 연결
- Character Creation·Level Up·Build Migration
- Character Sheet·Localization·Help Summary
- Content Wave·Coverage Matrix·Regression Scenario

조건부 범위:

- Multiclass는 Product·Policy에서 지원을 확정하고 별도 Coverage Gate를 통과한 경우에만 포함한다.

제외:

- 규칙 본문 장문 저장·표시
- 공식 Artwork·Asset의 무검토 배포
- Spell·Equipment Definition 전체: Slice 14
- Monster·NPC: Slice 15

## 4. Source와 Definition Type

```lua
export type OfficialSourceMetadata = {
    sourceId: string,
    sourceVersion: string,
    publicationRef: string,
    rulesEdition: string,
    rightsReviewStatus: "unreviewed" | "approved_metadata_only" | "approved_distribution",
    attributionRef: string?,
}

export type CharacterOptionDefinition = {
    contentRef: string,
    optionKind: "species" | "background" | "class" | "subclass" | "feat",
    sourceMetadataRef: string,
    schemaVersion: number,
    prerequisiteExpressionRef: string?,
    grantRefs: {string},
    choiceDescriptorRefs: {string},
    progressionRef: string?,
    localizationKeyPrefix: string,
    rulesSummaryKey: string?,
}

export type ProgressionTable = {
    progressionId: string,
    classRef: string,
    levelEntries: {[number]: ProgressionEntry},
    version: number,
}

export type ProgressionEntry = {
    level: number,
    grantRefs: {string},
    choiceRefs: {string},
    resourceUpgradeRefs: {string},
    migrationCheckRefs: {string},
}
```

표시 이름·정렬 순서·한국어 문자열은 Stable Content ID가 아니다. Source Pack Version과 Definition Version을 모든 Character Source·Build에 기록한다.

## 5. Character Option Compiler

```text
Definition Set
→ Source·Schema·Reference Validation
→ Prerequisite·Dependency Graph
→ Grant·Choice·Progression Compile
→ Character Creation Catalog
→ Level Up Catalog
→ Coverage Artifact
```

검증:

- Required Choice의 선택 수·중복·호환성
- Progression Level 누락·중복
- Subclass Parent·Level Gate
- Feat Prerequisite와 Ability Choice
- Resource Identity와 Upgrade Path
- Grant Cycle·Duplicate Capability
- Spell·Item Ref의 Slice 14 Catalog 존재 여부
- Localization Key와 Source Metadata

Definition별 전용 Luau Callback은 금지한다. 공통 Recipe·Grant·Operation으로 표현할 수 없는 예외는 별도 Architecture·Spec·Scenario 승인 후 Trusted Operation을 사용한다.

## 6. Creation·Level Up Integration

Creation:

```text
Allowed Source Pack Snapshot
→ Option Projection
→ Stored Selection
→ Character Source Candidate
→ Compile
→ Initial State
→ Review·Activation
```

Level Up:

```text
Current Source·Build·State
→ Target Level Progression
→ Required Choice·Prerequisite
→ Candidate Source
→ Candidate Build
→ State Migration Plan
→ Review·Atomic Activation
```

Level Up 중 새 Maximum Resource·Feature·Spell Access를 일부만 적용하지 않는다. 이전 Build와 State는 Activation 전까지 유지한다.

## 7. Localization과 사용자 설명

Locale Bundle에는 다음만 둔다.

- Name·Short Label
- UI Summary·Choice Prompt
- 접근성 설명
- Source 표시 Metadata

수치·Formula·Prerequisite·Grant 의미는 구조화된 Definition에 둔다. 공식 본문 전체를 복제하지 않고 필요한 경우 Source Reference와 짧은 자체 작성 Summary를 제공한다.

Player Projection은 자신이 선택할 수 있는 Option과 공개 Summary만 제공한다. 숨은 Future Feature, DM 제한 Option, 미활성 Pack Definition을 Raw Catalog로 보내지 않는다.

## 8. Content Wave와 Coverage Matrix

전체 데이터를 한 번에 병합하지 않는다.

```text
Wave Candidate
→ Dependency Closure
→ Definition Compile
→ Creation·Progression Scenario
→ Localization·Source Metadata 검사
→ Migration·Disclosure 검사
→ Coverage Matrix 갱신
→ Pack Candidate Activation
```

Coverage Matrix 최소 축:

- Species
- Background
- Class
- Subclass
- Feat
- Level 1–20
- Choice 종류
- Resource 종류
- Spell·Item Dependency
- Character Creation·Level Up·Migration Scenario
- ko-KR Locale

상태:

```text
not_started | definition_complete | compile_pass | scenario_pass | rights_approved | active
```

`active`가 아닌 Content를 일반 Campaign 기본 Catalog에 노출하지 않는다.

## 9. Migration·Deprecation

Pack Upgrade:

```text
Old Definition·Character Source·Build
→ Definition Diff
→ Stored Selection Compatibility
→ Candidate Recompile
→ State·Resource Migration
→ Player·DM Review
→ Atomic Activation
```

삭제·이름 변경·Progression 조정 시 Stable ID Mapping과 Migration Adapter를 사용한다. 이름이 비슷한 Option으로 자동 대체하지 않는다. 지원 중단 Content는 기존 Character의 Read-only 또는 Migration 정책을 가진다.

## 10. Diagnostics·Rights·Security

필수 Diagnostic:

- Missing Source Metadata
- Rights Review 미완료
- Missing Localization
- Invalid Grant·Choice·Progression
- Unsupported Spell·Item Dependency
- Migration 불가 Character
- Coverage Scenario 누락

Security:

- Content Data에 Code·Remote·URL·Callback 금지
- Client가 Feature·Resource·Prerequisite 결과를 제출하지 못함
- 미활성·비공개 Content Catalog 누출 금지
- Source Metadata와 권리 상태가 Release Gate에 포함됨

## 11. Test 계획

1. 각 Species·Background·Class의 Level 1 생성.
2. Class별 1–20 Progression 누락·중복 검사.
3. Subclass 선택 Level·Parent 검증.
4. Feat·Ability·Proficiency Choice Cardinality.
5. Grant·Capability·Resource 결정성.
6. Character Sheet Projection과 ko-KR Locale.
7. Pack Version Upgrade·Stored Selection Migration.
8. Missing Spell·Item Dependency 차단.
9. Compile 실패 후 기존 Character Last Known Good.
10. Reconnect·Rollback 후 exact Content Version 복원.
11. 미활성·권리 미승인 Content Release 차단.
12. Content Wave Coverage Matrix와 Scenario 누락 검사.

## 12. 구현 순서와 완료 기준

```text
Source·Rights Metadata
→ Common Definition Schema
→ Species·Background Wave
→ Class·Subclass Progression Wave
→ Feat·Choice·Resource Wave
→ Creation·Level Up Integration
→ Localization·Sheet
→ Migration·Coverage Regression
```

Spec 완료 기준:

- 전체 Character Option Family가 공통 Schema와 Compiler를 사용한다.
- Level 1–20 Progression·Choice·Resource 연결이 Coverage Matrix로 추적된다.
- Runtime 전용 예외가 명시적 Trusted Operation과 Scenario를 가진다.
- 공식 본문·Asset을 무검토 복제하지 않는다.
- Rights Review·Source Metadata가 Activation Gate다.

Production 구현은 공식 Source Data 확보·권리 검토와 실제 Pack Pipeline Mapping 전에는 시작할 수 없다.