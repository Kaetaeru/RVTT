# RVTT Roblox Source Workspace

- 상태: BOOTSTRAPPED
- 작성일: 2026-08-05
- 상위 Workspace: [`implementation`](../README.md)
- Slice 명세: [`docs/remake/specs/slices`](../../docs/remake/specs/slices/README.md)
- UI·UX Policy: [`docs/remake/ui/policies`](../../docs/remake/ui/policies/README.md)

이 Workspace는 Roblox DataModel Service 구조를 파일 시스템에 그대로 드러낸다. 실제 Luau Script는 Slice와 Script Manifest 순서대로 하나씩 추가한다.

## 목표 구조

```text
implementation/roblox/
├─ src/
│  ├─ ReplicatedFirst/
│  │  └─ RVTT/
│  ├─ ReplicatedStorage/
│  │  └─ RVTT/
│  ├─ ServerScriptService/
│  │  └─ RVTT/
│  ├─ ServerStorage/
│  │  └─ RVTT/
│  ├─ StarterPlayer/
│  │  └─ StarterPlayerScripts/
│  │     └─ RVTT/
│  └─ StarterGui/
│     └─ RVTT/
├─ tests/
├─ tooling/
└─ manifests/
```

Git은 빈 폴더를 저장하지 않으므로 현재는 각 Service Folder에 책임 설명용 `README.md`를 둔다.

## Service 책임

### ReplicatedFirst

- Client Boot Gate
- 초기 Loading·Reconnect·Recovery Surface
- 최소 Version·Bootstrap 검증

Gameplay Domain과 전체 UI Runtime을 여기 넣지 않는다.

### ReplicatedStorage

- Shared Luau Types
- Stable IDs·Version·Result·Error 계약
- Network Envelope·Registry
- Shared pure utility
- UI Design Token·Component Contract

Server Authority Store와 Client-only State를 넣지 않는다.

### ServerScriptService

- Server Bootstrap
- Authority Services
- Session·Scene·Movement·Rules·Encounter Domain
- Transaction·Event·Projection
- Persistence Coordinator·Diagnostics Adapter

실제 Data Definition·Migration Fixture와 Secret Content Source는 ServerStorage로 분리한다.

### ServerStorage

- Server-only Content Source
- Migration Definition
- Test Fixture
- Candidate Build Artifact Source

Runtime Store의 독립 복사본을 Source Asset처럼 저장하지 않는다.

### StarterPlayerScripts

- Client Bootstrap 이후 Runtime
- Projection Replica·ViewModel
- Semantic Input·Selection
- Camera·Presentation Client
- UI Intent Route

Authority 계산과 Permission 판정을 구현하지 않는다.

### StarterGui

- Screen·Panel·Shared Component Composition
- Theme·Token Binding
- Loading·Prompt·Recovery UI

Domain Store·Remote 직접 호출을 넣지 않는다.

## 비Service Folder

### tests

- Pure Unit Test
- Headless Integration
- Virtual Client·Network·Storage Scenario
- Roblox Studio Integration Test

### tooling

- Build·Validation·Code Generation
- Documentation·Schema Consistency Check
- Local developer command

### manifests

- Script Manifest
- Package·Registry Mapping
- Schema·Migration Version Index
- Content·Asset Manifest Reference

## Script 작성 순서

각 Slice는 먼저 `manifests/slice-XX-script-manifest.md`를 만든다.

Manifest 항목:

```text
순서
Script 경로
Script 종류
단일 책임
공개 API
의존 Script
연결 Spec
Test
Migration 영향
UI·UX Policy 영향
완료 상태
```

그 뒤 가장 위의 `IN_PROGRESS` Script 하나만 작성한다.

## 파일 규칙

- Roblox Service 이름과 Folder 이름을 일치시킨다.
- Package Root는 `RVTT`로 통일한다.
- Script 이름은 역할을 나타내며 `Manager`, `Handler`, `Util`만으로 끝내지 않는다.
- 하나의 Script가 Server·Client 양쪽 분기를 갖지 않는다.
- Circular Dependency를 허용하지 않는다.
- Runtime Instance 이름을 Stable Identity로 사용하지 않는다.
- Shared Module은 순수 계산·Schema·Type·Registry 계약을 우선한다.
- UI Component는 RemoteEvent를 직접 참조하지 않는다.

## Toolchain 결정

현재 폴더 구조는 Roblox Service Mapping을 확정한다. 다음은 Slice 01 Script Manifest에서 선택·검증한다.

- Rojo Project 파일 여부와 정확한 Mapping
- Luau Package Manager 사용 여부
- Test Runner
- Formatter·Linter·Type Check
- Studio Sync·CI 방식

Toolchain 선택 전 임의 `default.project.json`이나 Dependency Lockfile을 만들지 않는다.

## 현재 상태

```text
Roblox Folder Structure
→ CREATED

Service Responsibility
→ DEFINED

Toolchain
→ TO BE VERIFIED

Slice 01 Script Manifest
→ NEXT

Luau Scripts
→ NOT STARTED
```
