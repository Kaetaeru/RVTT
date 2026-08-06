# RVTT Implementation Manifests

이 폴더는 Script 작성 순서와 Package·Registry·Schema·Migration 연결을 기록한다.

예정 파일:

```text
slice-01-script-manifest.md
package-mapping.md
registry-index.md
schema-version-index.md
migration-index.md
```

각 Script Manifest 항목:

| 필드 | 의미 |
|---|---|
| 순서 | 작성·검수 순서 |
| 경로 | Roblox Service 기준 실제 파일 경로 |
| 종류 | ModuleScript·Script·LocalScript·Data·Test |
| 책임 | 하나의 단일 책임 |
| 공개 API | 입력·출력·오류 계약 |
| 의존성 | 선행 Script·Registry·Schema |
| 명세 | Slice·Package Spec 링크 |
| Test | Unit·Integration·Roblox Scenario |
| Migration | 저장·Schema 영향 |
| UI·UX | 적용 Policy와 Checklist |
| 상태 | QUEUED·IN_PROGRESS·BLOCKED·DONE |

가장 위의 `IN_PROGRESS` Script 하나만 작성한다. Manifest 없이 Script를 추가하지 않는다.
