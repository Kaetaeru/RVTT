# RVTT Greenfield Build Policy

- 상태: `RETIRED_IMPLEMENTATION_MODEL`
- 퇴역일: 2026-08-13
- 대체 권위: [`IMPLEMENTATION-MODEL.md`](IMPLEMENTATION-MODEL.md)

기존 Greenfield Build Policy는 현재 구현 권위가 아니다.

유지되는 프로세스 결정은 오직 다음이다.

```text
새 System Model From Scratch
→ E0 Repository Core Engine 전체 완료
→ CORE_ENGINE_COMPLETE
→ Studio Runtime Engine / Integration
→ INTEGRATION_READY
→ U0 Product UI Shell
→ UI_SHELL_READY
→ Presentation / Feel
```

구체 System/Module/Controller/Manager/Service는 새 모델에서 다시 도출한다.
