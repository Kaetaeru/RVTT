# RVTT Studio Greenfield Build — Exploration 001

- 상태: `ACTIVE · CURRENT_COMMAND`
- Build mode: `GREENFIELD`
- 상위 포인터: [`CODEX-ACTIVE-TASK.md`](CODEX-ACTIVE-TASK.md)

## 목표

새/깨끗한 Roblox Studio 작업물에서 RVTT Exploration의 첫 실제 사용자 흐름을 처음부터 구축한다.

```text
World
→ Hero Token
→ Selection
→ Camera
→ Move
→ Right-click Context Action
→ Interaction
```

기존 Production Place나 기존 UI를 열어 수정하는 것이 목표가 아니다.

## 구현 전 조사

1. `AGENTS.md`
2. `.github/README.md`
3. `.github/CODEX-ACTIVE-TASK.md`
4. 관련 Product·ADR·Spec
5. `implementation/roblox/MODULE-CONTRACTS.md`와 관련 Registry Entry
6. 기존 Source에서 관련 Script·함수의 책임
7. 관련 Focused Test와 Protocol·Schema

### Legacy Source 사용 규칙

기존 Source는 참고 또는 선택적 재사용 후보다.

재사용하려면:

- 현재 Product·ADR에 맞아야 한다.
- 현재 Module Contract의 책임·Authority에 맞아야 한다.
- 낡은 UI/Acceptance 구조를 새 Build에 끌고 오지 않아야 한다.
- 새 Greenfield 흐름을 단순하게 만드는 경우여야 한다.

그렇지 않으면 새로 구현한다.

## Studio 작업

1. Studio MCP Capability를 확인한다.
2. 새/깨끗한 작업물의 DataModel을 확인한다.
3. Exploration에 필요한 최소 Service/Folder/Script/Instance만 만든다.
4. 화면에 실제 World와 Hero Token을 띄운다.
5. 선택을 구현하고 Play한다.
6. Camera를 연결하고 Play한다.
7. Move를 연결하고 Play한다.
8. Context Action과 Interaction을 연결하고 Play한다.
9. 각 단계에서 Output·Server/Client State·화면·입력 결과를 확인하고 즉시 수정한다.

한 번에 기존 16 Slice 전체를 가져오지 않는다. 현재 흐름에 필요한 책임만 도입한다.

## 사용자에게 먼저 보고할 것

- 핵심 입력 의미 변경
- Server/Client Authority 변경
- Module 경계를 새로 나누거나 합치는 변경
- 기존 Accepted ADR과 다른 UX 방향
- 개발 방식 변경
- 현재 범위를 크게 넓히는 변경

## Canonicalization

사용자가 실제 흐름을 받아들이면:

1. 새 Studio 구현을 Repository의 Canonical Source로 정리한다.
2. 필요한 Instance 구조를 Rojo Mapping으로 재현 가능하게 만든다.
3. 재사용한 Legacy Module과 새 Module의 책임을 명확히 한다.
4. 안정적인 책임·Entry Point·의존·Authority가 달라졌다면 Module Contract 변경안을 사용자 승인 범위 안에서 반영한다.
5. Focused Test를 실행한다.

## 완료 보고

- 새로 만든 Studio 구조
- 선택적으로 재사용한 Legacy Module과 이유
- 새로 작성한 Module
- 실제 Play 결과
- 사용자 판단 필요 항목
- GitHub에 정규화한 Source
- 실행한 Focused Test
- 남은 Risk
