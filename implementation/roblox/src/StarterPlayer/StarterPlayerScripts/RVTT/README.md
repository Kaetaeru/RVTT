# StarterPlayerScripts / RVTT

Client Projection Replica, ViewModel, Semantic Input, Selection, Camera, Presentation와 UI Intent Route를 둔다.

금지:

- Gameplay Authority 계산
- Permission 최종 판정
- DataStore 접근
- Domain Store 직접 Mutation
- 물리 키를 기능별 Script가 직접 감시

Client Script는 UI·UX Global Policy와 Slice Integration Contract를 모두 통과한 뒤 추가한다.
