# Common Input UI

Q 취소, E 승인, 문맥별 1–5와 입력 문맥 스택의 표시·우선순위를 다룬다.

## 상위 권위 계약

- [`UI Projection, ViewModel, Input Context와 Recovery Runtime 계약`](../../architecture/ui-projection-view-model-input-context-and-recovery-runtime-contract.md)
  - Semantic Input Router, Input Context Stack과 Focus 수명주기
  - Authority Prompt·Local Modal·Panel Context 분리
  - Reconnect·Rollback 후 Context Token 폐기와 복구
- [`Selection Runtime 계약`](../../architecture/selection-targeting-preview-and-frozen-binding-runtime-contract.md)
  - Selection Session과 Frozen Binding에서의 Q/E 의미

## 세부 UI 문서

- [`common-input-grammar.md`](common-input-grammar.md)
  - Q는 취소·거절·한 단계 뒤로
  - E는 승인·확정·실행·상호작용
  - 1–5는 화면에 의미가 표시된 현재 문맥의 주요 슬롯

## 고정 경계

- 기능 Component가 물리 키를 직접 감시하지 않는다.
- 가장 위의 유효 Input Context 하나만 입력을 소비한다.
- Text Input이 활성일 때 Gameplay Q/E·숫자 슬롯을 실행하지 않는다.
- Authority Prompt는 Q/E 입력 직후 로컬에서 완료하지 않고 응답 Command와 Projection을 기다린다.
- Context 소유 Panel·Selection·Prompt가 종료되면 Context Token을 반드시 해제한다.
