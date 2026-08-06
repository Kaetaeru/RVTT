# ServerScriptService / RVTT

Server Bootstrap, Authority Service, Domain Runtime, Transaction, Event, Projection, Persistence Coordinator와 Diagnostics Adapter를 둔다.

금지:

- Client UI·Camera·Presentation Logic
- Workspace Instance를 영구 권위 원본으로 사용
- Domain Store 직접 횡단 수정
- 검증되지 않은 Remote Payload 적용

실제 Script는 Slice 01 Script Manifest 순서대로 하나씩 추가한다.
