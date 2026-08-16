# ChatGPT Rerun Protocol

이 디렉터리는 ChatGPT Rerun이 RVTT 작업을 안전하게 재개하기 위한 GitHub 기반 실행 제어 문서다. 프로젝트 자체 권위와 제품 결정은 이 디렉터리가 소유하지 않는다. RVTT의 `AGENTS.md`, `.github/CODEX-ACTIVE-TASK.md`, 현재 Implementation Model/System Authority가 항상 프로젝트 의미와 구현 경계를 결정한다.

## Mandatory read order

Rerun dispatch를 처리할 때 `.chatgpt-rerun` 내부 문서는 반드시 다음 순서로 읽는다.

```text
1. .chatgpt-rerun/README.md
2. .chatgpt-rerun/control.json
3. .chatgpt-rerun/STATE.md
4. .chatgpt-rerun/PLAN.md
```

이 네 문서를 reconciliation한 뒤 실제 작업을 시작하기 전에 RVTT 프로젝트 권위 문서를 읽는다.

```text
AGENTS.md
→ .github/CODEX-ACTIVE-TASK.md
→ implementation/roblox/IMPLEMENTATION-MODEL.md
→ implementation/roblox/SYSTEMS.md
→ 해당 task에 필요한 current authority corpus / scenario / audit 원문
```

`STATUS.md`는 사람이 빠르게 보는 projection일 뿐 reconciliation source of truth가 아니다.

## Preflight reconciliation

매 dispatch 또는 재개 전에 다음을 확인한다.

1. `control.json`, `STATE.md`, `PLAN.md`의 `run_id`, `sequence`, `task_id`가 같은 active run을 가리키는지 확인한다.
2. 기존 active run이 있으면 run_id, sequence, 현재 task, 검증 기록을 초기화하거나 덮어쓰지 않는다.
3. 불일치가 있으면 임의로 새 run을 만들거나 sequence를 되감지 않는다. 안전하게 해석 가능한 마지막 일치 checkpoint까지만 사용하고, 필요한 경우 `blocked` 또는 `needs_user`로 전환한다.
4. 저장소 branch/ref, 현재 프로젝트 authority와 task의 금지 사항을 다시 확인한다.
5. Rerun 문서는 프로젝트의 Accepted ADR, Authority, state ownership, 개발 순서를 암묵적으로 변경할 수 없다.

## Dispatch status semantics

허용 status는 다음 의미를 가진다.

- `continue`: 현재 task의 work start/resume authorization.
- `complete`: 해당 sequence의 task가 완료되어 다음 dispatch를 기다리는 상태.
- `needs_user`: 사용자 결정 또는 입력을 기다리는 dispatch 대기 상태.
- `blocked`: 외부 의존성, 권한, 검증 실패 등으로 진행할 수 없는 dispatch 대기 상태.

`working` 상태는 사용하지 않는다.

`complete`, `needs_user`, `blocked`는 tab watcher를 끄는 terminal 신호가 아니다. watcher는 polling을 계속하며 control 변화를 감시한다.

terminal 상태 뒤에도 **같은 sequence에서 `continue`가 다시 게시되면 새로운 work authorization**으로 간주하고 자동 재개할 수 있어야 한다. 이때 기존 run/task 기록을 삭제하지 않고 해당 authorization 시점부터 resume한다.

## Chrome Side Panel semantics

Chrome Side Panel의 **Start/Stop은 tab watcher on/off**다. GitHub의 `.chatgpt-rerun/control.json` status와 독립적이다.

- Start: watcher가 켜지고 polling/dispatch 감시를 시작한다.
- Stop: watcher가 꺼진다.
- GitHub control이 `complete`, `needs_user`, `blocked`여도 watcher 자체는 켜진 채 polling을 계속할 수 있다.
- GitHub control의 `continue`는 watcher on/off가 아니라 work start/resume 신호다.

## Time budget and checkpoint discipline

한 번의 active execution은 **20분 hard stop**을 넘기지 않는다.

- 18분에 hard checkpoint를 만든다.
- 18분 이전에도 의미 있는 상태 변화, 검증 결과, 의존성 변화가 있으면 즉시 checkpoint한다.
- 20분 전에 안전한 중단 지점을 확보하고 STATE/control에 이어갈 수 있는 정확한 상태를 남긴다.
- 시간이 부족하면 범위를 숨겨서 완료 처리하지 않는다.

## Authoritative write order

의미 있는 상태를 게시할 때 authoritative write 순서는 반드시 다음과 같다.

```text
1. PLAN.md
2. STATE.md
3. control.json
```

`control.json`은 해당 checkpoint의 **마지막 authoritative write**다. control을 먼저 올린 뒤 PLAN/STATE를 나중에 맞추지 않는다.

`STATUS.md`는 사람용 projection이므로 authoritative reconciliation 대상이 아니다. 의미 있는 상태 변화가 발생하면 즉시 갱신하고, 긴 active 실행 중에는 가능하면 약 **5분 freshness**를 유지한다.

## Failure-safe rules

- GitHub 쓰기 권한이 없으면 성공한 척하지 않는다.
- 대상 repository/ref가 불명확하면 파일을 쓰지 않는다.
- 사용자 결정이 필요한 프로젝트 gate를 자동 통과하지 않는다.
- 현재 RVTT gate가 Source/Studio를 금지하면 Rerun도 이를 우회하지 않는다.
- 검증하지 않은 결과를 완료로 기록하지 않는다.
