# 47. 콘텐츠 범위·자동화 등급·롤백·청크 저장·제외 기능

- 상태: 확정
- 즉시 구현 명세 가능성: `READY_WITH_DEFAULTS`
- 남은 기본값: chunk 목표 크기, manifest 세대 보존 수, 무효화 로그 표시 기간
- 관련 결정: ADR-0052

## 2024 기본 구현 범위

2024 기본 규칙에 수록된 플레이어 캐릭터용 종, 배경, 직업, 하위직업, Feat, 주문, 장비, 일반 아이템과 성장 선택을 모두 구현 대상으로 등록한다.

`모두 지원`은 첫 구현 단계에서 동시에 완성한다는 뜻이 아니다. 콘텐츠 카탈로그와 구현 추적표에는 모든 항목이 등록되고 다음 상태를 가진다.

```text
not_started
specified
implemented
verified
```

MVP 순서는 별도 로드맵에서 나누되 최종 기본 범위에서 임의로 제외하지 않는다.

## 자동화 등급의 간단한 의미

### Executable

컴퓨터가 규칙 결과를 확실히 계산할 수 있는 기능이다.

```text
공격 굴림
→ 명중 판정
→ 피해
→ HP 변경
```

### Guided

시스템이 진행을 맡지만 사람의 선택이 중간에 필요하다.

```text
여러 대상 중 선택
→ DM 승인
→ 시스템이 피해와 상태 적용
```

### Assisted

주문 설명처럼 결과가 매우 자유로워 시스템이 정답을 정할 수 없는 기능이다.

```text
대상·굴림·설명 제공
→ DM이 실제 결과 결정
→ 시스템이 결정된 변경을 기록
```

세 등급 모두 실제 구현이다. `Assisted`가 미완성이라는 뜻은 아니다. 중요한 것은 콘텐츠마다 어느 수준인지 사전에 표시해 구현자가 임의로 자동화하거나 텍스트만 남기지 않게 하는 것이다.

## 롤백

롤백은 과거 branch의 권위 상태에서 새 branch를 만든다.

복구 대상:

- HP, 자원, 위치, 장비, 아이템 소유권
- 상태·집중·소환체·장면 효과
- 문·함정·상자·파괴 오브젝트
- Fog Discovery와 CurrentReveal
- 관찰자별 DetectionState
- 숨겨진 Actor 복제 여부
- 이니셔티브, 턴과 제어권

로그는 물리적으로 삭제하지 않는다.

```text
기존 로그
→ 보존
→ 롤백 이후 기록은 invalidatedBranchId 표시
→ 현재 branch 로그와 시각적으로 분리
```

플레이 화면과 현재 계산에서는 무효화된 로그를 사용하지 않는다.

## 청크 저장

대형 도메인은 다음 구조로 저장한다.

```text
SaveManifest
├─ saveGeneration
├─ authorityRevision
├─ schemaVersion
├─ chunkDescriptors[]
└─ complete

ChunkDescriptor
├─ chunkId
├─ domain
├─ index
├─ checksum
└─ byteLength
```

저장 절차:

1. 새 generation의 chunk들을 임시 상태로 기록
2. 각 chunk 검증
3. 완전한 manifest 기록
4. manifest를 current로 원자적 전환
5. 이전 정상 generation을 복구용으로 유지

로드 절차:

1. current manifest 읽기
2. chunk 병렬 또는 제한 병렬 로드
3. checksum·순서·schema 검증
4. 모두 성공한 경우에만 권위 상태 생성
5. 실패하면 이전 정상 manifest 사용

chunk 경계는 장면, 저널 문서 묶음, Actor 묶음, 인벤토리, 전투 타임라인 등 도메인 의미를 우선한다. 임의 바이트 절단만 사용하지 않는다.

## 제외 기능

다음은 구현하지 않는다.

- 음악 재생과 플레이리스트
- 환경음
- 주문·공격·UI SFX
- 음성 채팅과 음성 대사
- NPC 대화 트리와 대화 전용 UI

텍스트 저널, DM 설명, 캐릭터·NPC 이름표와 일반 판정 UI로 세션을 진행한다.
