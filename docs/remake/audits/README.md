# Audit 문서

- 상태: ACTIVE
- 문서 종류: Audit Index
- 현재 단계: `SLICE 01 STUDIO ACCEPTANCE`
- 상위 작업 순서: [`CURRENT-WORK-ORDER`](../CURRENT-WORK-ORDER.md)
- Production Work Order: [`implementation/roblox/CURRENT-WORK-ORDER`](../../../implementation/roblox/CURRENT-WORK-ORDER.md)
- 전체 Slice Roadmap: [`SLICE-ROADMAP`](../specs/SLICE-ROADMAP.md)

Audit은 제품 동작을 새로 정의하지 않는다. 권위 문서·사용자 흐름·Policy·명세·구현 Evidence의 정합성과 완료 Gate를 판정한다.

## 현재 핵심 감사

1. [`Roblox Studio Runtime Baseline Validation Audit`](roblox-studio-runtime-baseline-validation-audit.md)
   - Unit·Integration `108/0`
   - Live DataStore `10/0`
   - 3-client MultiClient `56/0`, `staleRetries=3`
   - 현재 다음 Gate: Slice 01 Studio Acceptance
2. [`All-slice Script Transfer Audit`](all-slice-script-transfer-audit.md)
   - 16개 Slice 계약의 Script·Test baseline 인계
3. [`Implementation Workspace Bootstrap Audit`](implementation-workspace-bootstrap-audit.md)
   - Greenfield Production Root와 Roblox Service 구조 생성 시점 감사
4. [`UI·UX Global Policy Completion Audit`](ui-ux-policy-completion-audit.md)
   - Visual·Interaction·Information·Feedback·Recovery·Accessibility Policy 완료
5. [`All-slice Specification Checkpoint Completion Audit`](all-slice-specification-checkpoint-completion-audit.md)
   - 16개 Package·Audit와 4개 Recovery Checkpoint 완료

## 현재 감사 흐름

```text
All-slice Contract→Script Transfer
→ Static·Toolchain Validation
→ Roblox Studio Runtime Baseline Validation
→ Slice 01 Studio Acceptance
→ Slice 01 Production Build Acceptance Audit
→ Slices 02–16 Acceptance
→ Release Hardening
```

## 현재 구현 감사 대상

Slice 01 Studio Acceptance에서 다음을 확인한다.

- Join→Select→Ready→Scene→Move→Reconnect 사용자 흐름
- Client Intent와 Server Authority 결과 일치
- Player·DM·Observer Projection 분리
- Unauthorized·Stale·Disconnect 실패 처리
- Revision·AuthorityEpoch·Projection Sequence
- 재접속 후 중복 Membership·Command 없음
- UI·UX Review Checklist

## Slice 감사

- [`16개 Slice Checkpoint Audit Index`](slices/README.md)
- [`4개 Cross-Slice Checkpoint와 Recovery Branch`](slice-checkpoints/README.md)

## 문서 수명주기

- [`문서 구조와 작성 가이드`](../DOCUMENT-GUIDE.md)
- [`문서 수명주기와 Discontinuation`](../DOCUMENT-LIFECYCLE-AND-DISCONTINUATION.md)
- [`보관된 Discontinued Audits`](../archive/discontinued/audits/README.md)

`SUPERSEDED`, `DISCONTINUED`, `ARCHIVED` 문서는 현재 Authority나 완료 근거로 다시 사용하지 않는다.
