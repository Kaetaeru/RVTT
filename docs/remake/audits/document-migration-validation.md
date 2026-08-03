# 문서 마이그레이션 검증

- 상태: 검증 중
- 문서 종류: Audit
- 즉시 구현 명세 가능성: 해당 없음

## 검증 범위

- 이동 매핑: 46개 (`02`와 `04`~`48`)
- 기존 번호형 루트 문서 잔존 여부
- 새 대상 경로 누락 여부
- Markdown 상대 링크 유효성
- 기존부터 잘못된 별칭 링크 교정

## 실행 도구

```text
python scripts/docs/rewrite_remake_doc_links.py --check
python scripts/docs/validate_remake_docs.py
```

GitHub Actions의 `Validate remake documentation` 워크플로 결과를 최종 근거로 사용한다.

## 완료 조건

```text
mapped documents: 46
old numbered root documents: 0
broken relative links: 0
links requiring rewrite: 0
```
