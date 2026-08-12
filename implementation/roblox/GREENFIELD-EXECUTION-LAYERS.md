# RVTT Greenfield Execution Layers

- 상태: `RETIRED_IMPLEMENTATION_MODEL`
- 퇴역일: 2026-08-13
- 대체 권위: [`IMPLEMENTATION-MODEL.md`](IMPLEMENTATION-MODEL.md)

이 문서의 기존 E0/E1/E2 module classification은 폐기됐다.

다만 다음 **개발 원칙 자체**는 사용자 결정으로 유지된다.

```text
Repository Core Engine 전체 구현/자동 검증
→ CORE_ENGINE_COMPLETE
→ Roblox Runtime Engine / Integration을 Studio/MCP에서 구현/자동 검증
→ INTEGRATION_READY
→ U0 Product UI Shell Session
→ UI_SHELL_READY
→ Presentation / Feel 사용자 Checkpoint
```

새 System Model이 승인된 뒤 각 책임을 Core / Runtime / Presentation에 다시 분류한다.

기존 Module classification은 새 분류의 기본값이 아니다.
