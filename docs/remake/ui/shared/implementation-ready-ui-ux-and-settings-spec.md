# RVTT 구현 직전 UI·UX·Settings 명세

- 상태: `SUPERSEDED IN PART · ADR-0091`
- 최종 갱신일: 2026-08-06
- 현재 최종 계약: [`final-ui-content-implementation-contract.md`](final-ui-content-implementation-contract.md)
- 최상위 결정: [`ADR-0091`](../../decisions/ADR-0091-asset-registry-interactive-sheet-dice-and-core-rules.md)

이 문서의 Observer-first Entry, Character Console Matrix, DM Window Module과 공통 입력 계약은 유지한다. 다음 영역은 ADR-0091과 최종 구현 계약이 대체한다.

- Official Character Sheet 비율·기능
- Dice Result Notice 상태 기계
- Core Rules Journal Reader
- Content Asset Registry·Prefab 위치
- Final UI Gap Matrix

구현자는 다음 순서로 읽는다.

```text
ADR-0091
→ final-ui-content-implementation-contract.md
→ ADR-0090·ADR-0089·ADR-0088
→ 세부 UI 문서
→ High-Fidelity HTML
```

기존 전체 상세 내용은 Git history에 보존한다. 충돌 시 ADR-0091과 최종 구현 계약이 우선한다.
