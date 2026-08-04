# RVTT Roblox Tests

이 폴더는 Production 경로를 우회하지 않는 Test를 둔다.

예정 영역:

```text
unit/
integration/
virtual-client/
roblox-studio/
fixtures/
```

원칙:

- Test-only Store Mutation과 Authorization 우회를 만들지 않는다.
- Named RNG·Clock·ID·Network·Storage Adapter를 사용한다.
- Scenario는 같은 Version·Seed·Schedule에서 결정적으로 재현돼야 한다.
- 실제 Roblox Timing·Memory·Instance Benchmark는 Headless Test와 분리한다.
- 실패 Artifact에는 Secret·Production Seed·사용자 원문을 넣지 않는다.

첫 Test 파일은 Slice 01 Script Manifest에서 대상 Production Script와 함께 정의한다.
