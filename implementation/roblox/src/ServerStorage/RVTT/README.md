# ServerStorage / RVTT

Server-only Content Source, Migration Definition, Test Fixture와 Candidate Build Artifact Source를 둔다.

금지:

- Client에 복제할 Shared Contract
- Live Authority Store의 독립 복사본
- Runtime Instance를 Canonical Source로 저장
- 권한 검증 없이 Import된 Data 활성화

실제 Data·Migration Module은 해당 Slice Manifest와 Rights·Migration Gate를 통과한 뒤 추가한다.
