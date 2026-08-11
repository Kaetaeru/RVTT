# RVTT Grand Acceptance Campaign

- 상태: `RELEASE_REGRESSION_TOOLING`
- 최종 갱신일: 2026-08-12
- Manifest: [`grand-acceptance-manifest.json`](grand-acceptance-manifest.json)
- Runner: [`tooling/run-grand-acceptance.ps1`](tooling/run-grand-acceptance.ps1)

## 목적

Grand Acceptance는 **개발 루프가 아니라 Release·대규모 통합 회귀 도구**다.

개발 중 결함을 고칠 때마다 전체 Campaign을 다시 실행하지 않는다. 관련 Focused Test와 Studio 흐름으로 빠르게 확인하고, Release Candidate 또는 대규모 통합 시 전체 Campaign을 실행한다.

## 실행 범위

기존 Manifest와 Runner 계약은 유지한다.

- single-client authority·integration
- multi-client DM·Player·Observer
- real transport·reconnect
- 선택적 Persistence·Restart·Outage·Lease
- 통합 JSON·Markdown Report

일반 Run과 Persistence Run의 Evidence는 계속 분리한다.

## 상태 의미

```text
pass
fail
incomplete
blocked
prepared
```

Summary가 없으면 PASS가 아니다. Static·Build·Type PASS도 Studio Runtime PASS를 대신하지 않는다.

## 언제 실행하는가

- Release Candidate
- Persistence/Migration Milestone
- 대규모 Cross-slice Integration
- 사용자가 전체 회귀를 요청한 경우

작은 UI 조정, 단일 입력 수정, Focused Runtime 버그 수정의 기본 검증으로 사용하지 않는다.

## 실패 후

개발 단계에서는 실패 Root Cause와 관련된 Focused Phase만 재실행해도 된다. 수정이 안정된 뒤 Release Candidate에서 전체 Campaign을 다시 실행한다.

## Historical Tooling

기존 PowerShell Runner, Manifest, Place Project는 그대로 보존한다. 과거 문서에 기록된 특정 Branch 이름과 Head 예시는 역사적 실행 기록이며 현재 Branch를 의미하지 않는다.
