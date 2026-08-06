# High-Fidelity HTML UI Production Guide Audit

- 상태: `COMPLETE · FINAL STATIC TARGET · ADR-0091`
- 감사일: 2026-08-06
- HTML: [`../user-guides/html/index.html`](../user-guides/html/index.html)
- 최종 공백 감사: [`final-ui-surface-gap-audit.md`](final-ui-surface-gap-audit.md)

## 1. 범위

Runtime/Reference 화면 33개를 검증한다.

- 2024 2-page Interactive Official Sheet
- Dice Square→Rectangle Reveal와 모든 d20 변형
- Core Rules Module Reader
- Asset Package Registry
- Invite/Join과 First-run Primer
- 기존 Player·Observer·DM 화면

## 2. 정적 결과

- [x] HTML parse
- [x] JavaScript syntax
- [x] 33 Screen ID unique
- [x] 33 Renderer 등록
- [x] 33 Renderer smoke test
- [x] 압축 CSS·JS 원본 일치
- [x] Page 1 35/65, Page 2 68/32 계약
- [x] Official Sheet Roll·Equipment·Spell Action 표현
- [x] Dice Natural→Formula→Adjudication
- [x] Advantage·Disadvantage·Natural 1·20·Reduced Motion
- [x] Core Rules Chunk Reader·Attribution
- [x] Asset Stable ID·Rights·Validation·Missing Dependency
- [x] Audio Mixer 빈 Tab 제거
- [x] Objective·Map·Minimap 없음

## 3. 저작권·권리 경계

- 공식 D&D 2024 시트는 비율·정보 순서의 Reference다.
- 외부 Logo·Artwork·Font·Icon은 포함하지 않는다.
- Built-in Rule text는 재배포 권리가 확인된 Package만 허용한다.
- 비SRD 공식 서적 본문은 공개 저장소에 포함하지 않는다.

## 4. 미완료 Evidence

- Browser Screenshot·Pixel Diff
- Roblox ScreenGui 비교
- Multi-client Authority
- 대형 Rules Package Memory·Search Performance
- Asset Compile Performance
- Studio Human Usability

이는 기획 공백이 아니라 Runtime Gate다.
