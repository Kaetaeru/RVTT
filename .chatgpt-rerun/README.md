# ChatGPT Rerun Protocol

이 디렉터리는 `Kaetaeru/RVTT`의 ChatGPT Rerun 실행 상태를 GitHub에 보존하기 위한 제어 계층이다. Rerun 문서는 RVTT의 제품·Architecture·ADR·Authority·구현 계약을 대체하지 않는다. 실제 작업 의미와 우선순위는 항상 저장소의 최신 프로젝트 지침과 현재 Work Order를 따른다.

## Mandatory read order

모든 Rerun 실행·재개는 아래 순서를 반드시 따른다.

```text
1. .chatgpt-rerun/README.md
2. .chatgpt-rerun/control.json
3. .chatgpt-rerun/STATE.md
4. .chatgpt-rerun/PLAN.md
```

위 네 문서를 reconciliation한 뒤 실제 작업 전에 현재 branch의 프로젝트 권위를 확인한다.

```text
README.md
AGENTS.md
AGENTS-PLANNING-ADDENDUM.md
→ 현재 task가 가리키는 Work Order / Implementation Status
→ Accepted ADR / Product / Architecture / UI·UX / System 계약
→ 관련 Source / Test / Validator
```

문서 간 시점이 다르면 더 구체적이고 현재 실행을 직접 지시하는 Work Order와 Accepted authority를 우선하되, 상위 제품·ADR·Authority를 암묵적으로 변경하지 않는다.

## Preflight reconciliation

실행 시작 전에 `control.json`, `STATE.md`, `PLAN.md`를 다음 규칙으로 맞춘다.

1. `run_id`, `sequence`, `task_id`가 같은 active run을 가리키는지 확인한다.
2. `control.json`의 dispatch 상태와 `STATE.md`의 checkpoint가 모순되지 않는지 확인한다.
3. 기존 run이 있으면 run_id, sequence, 현재 task, 완료된 검증 기록을 초기화하거나 반복하지 않는다.
4. 불일치가 있으면 임의로 sequence를 되감거나 새 run으로 덮지 않는다. 마지막으로 안전하게 일치하는 checkpoint를 사용하고 필요하면 `blocked` 또는 `needs_user`로 게시한다.
5. 프로젝트 branch/ref와 현재 Work Order가 바뀌었으면 실제 작업 전에 drift를 기록하고 PLAN/STATE를 안전하게 reconcile한다.
6. 이미 검증된 DONE 작업은 현재 task의 의존성으로만 취급하고 이유 없이 다시 수행하지 않는다.

`STATUS.md`는 사람이 GitHub에서 빠르게 읽는 projection일 뿐 reconciliation source of truth가 아니다.

## Dispatch status semantics

허용되는 `control.json.status`는 다음과 같다.

- `continue`: 현재 `run_id` / `sequence` / `task_id`에 대한 work start 또는 resume authorization.
- `complete`: 현재 dispatch 작업이 완료되어 다음 authorization을 기다리는 상태.
- `needs_user`: 사용자 결정·입력·승인을 기다리는 상태.
- `blocked`: 외부 의존성, 권한, 검증 실패, 선행 gate 때문에 진행할 수 없는 상태.

`working` 상태는 사용하지 않는다.

`complete`, `needs_user`, `blocked`는 Chrome watcher를 종료시키는 신호가 아니다. watcher가 켜져 있으면 계속 polling한다. terminal 상태 이후에도 **같은 sequence에서 `continue`가 다시 게시되면 새로운 work authorization**으로 해석하고 기존 run과 검증 기록을 보존한 채 자동 재개할 수 있어야 한다.

## Chrome Side Panel semantics

Chrome Side Panel의 **Start / Stop은 tab watcher on/off**이며 GitHub control 상태와 독립적이다.

- Start: tab watcher를 켜고 GitHub control polling/dispatch 감시를 시작한다.
- Stop: tab watcher를 끈다.
- GitHub가 `complete`, `needs_user`, `blocked`여도 watcher는 켜진 채 polling을 계속할 수 있다.
- GitHub의 `continue`는 watcher를 켜는 명령이 아니라 현재 work의 start/resume authorization이다.

## Time budget and checkpoint discipline

한 번의 active 실행은 **20분 hard stop**을 넘기지 않는다.

- 약 18분에 반드시 durable checkpoint를 만든다.
- 18분 전이라도 의미 있는 상태 변화, 검증 결과, blocker, 사용자 결정 필요가 생기면 즉시 checkpoint한다.
- 20분 전에 안전한 중단 지점을 확보하고 `STATE.md`에 완료된 작업·검증·미완료 지점·Next Exact Action을 남긴다.
- 시간이 부족하면 범위를 축소해 완료한 것과 남은 것을 분리하고 완료한 척하지 않는다.

## Authoritative write order

의미 있는 checkpoint를 게시할 때 authoritative write 순서는 반드시 아래와 같다.

```text
1. PLAN.md
2. STATE.md
3. control.json
```

`control.json`은 해당 checkpoint의 **마지막 authoritative write**다. control을 먼저 바꾼 뒤 PLAN/STATE를 뒤늦게 맞추지 않는다.

`STATUS.md`는 사람용 projection이므로 위 authoritative reconciliation 순서의 일부가 아니다. 의미 있는 상태 변화가 있으면 즉시 갱신하고, 긴 active 실행 중에는 가능하면 약 **5분 freshness**를 유지한다.

## Project safety rules

- 저장소의 Accepted ADR, Authority/state ownership, 입력 계약, 개발 순서, release scope를 Rerun 문서가 임의로 변경하지 않는다.
- 현재 Work Order에서 DONE으로 검증된 항목은 새 실패 근거가 없는 한 반복하지 않는다.
- Studio/Human retest가 repository/static gate 뒤로 차단되어 있으면 해당 gate를 우회하지 않는다.
- GitHub 쓰기 권한이나 프로젝트 목표가 불명확하면 성공 상태나 `continue` control을 추측해서 게시하지 않는다.
- 검증하지 않은 결과를 `complete`로 기록하지 않는다.
