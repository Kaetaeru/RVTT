# RVTT Production Implementation Workspace

- 상태: BOOTSTRAPPED
- 작성일: 2026-08-05
- 기획·명세 원본: [`docs/remake`](../docs/remake/README.md)
- 현재 상위 작업 순서: [`docs/remake/CURRENT-WORK-ORDER.md`](../docs/remake/CURRENT-WORK-ORDER.md)
- UI·UX Policy: [`docs/remake/ui/policies`](../docs/remake/ui/policies/README.md)

이 폴더는 RVTT의 실제 Production Source, Test, Migration과 Build 도구만 소유한다.

```text
docs/remake/
→ 사용자 경험·Product·Architecture·Guide·Spec·Audit

implementation/
→ 실제 Roblox Source·Test·Migration·Build Artifact 정의
```

## 운영 원칙

1. Production Script는 이 폴더 밖에 만들지 않는다.
2. Script는 현재 Slice Work Order와 Script Manifest 순서대로 하나씩 추가한다.
3. 빈 Framework 전체를 한 번에 생성하지 않는다.
4. 하나의 Script는 명확한 책임·입출력·의존성·오류 경계·Test를 가진다.
5. Shared, Server, Client와 UI Authority를 혼합하지 않는다.
6. Client Script는 Domain Store와 DataStore에 직접 접근하지 않는다.
7. Remote, Schema, Migration과 Registry 변경은 명세·Test와 같은 변경에 포함한다.
8. UI Script는 [`UI·UX Global Policies`](../docs/remake/ui/policies/README.md)와 Review Checklist를 통과해야 한다.
9. 실제 Roblox Studio·Test Host에서 검증하지 않은 구현을 완료로 표시하지 않는다.
10. 자동 생성 파일과 Runtime Data를 Source 원본으로 Commit하지 않는다.

## 현재 하위 Workspace

- [`roblox/`](roblox/README.md) — Roblox DataModel Service 구조를 반영하는 Production Source

## Script 추가 Gate

```text
Slice Integration Contract
→ 실제 Folder·Package Mapping
→ Script Manifest
→ 첫 Script 책임 검수
→ Script 작성
→ Unit·Integration·Roblox Test
→ UI·UX Checklist 또는 Domain Checklist
→ Commit
→ 다음 Script
```

현재 상태:

```text
Workspace Folder Structure
→ CREATED

Production Luau Script
→ NOT STARTED

현재 다음 작업
→ Slice 01 Script Manifest 작성
```
