# State machine

A generic, node-based finite state machine in `components/state_machine/`. It is used by the player and the enemies, and will be reused for bosses.

## Files

| File | Role |
|---|---|
| `state_machine.gd` | `StateMachine`: collects states, runs the current one, switches between them |
| `state.gd` | `State`: base class every state extends |

## How it works

1. `StateMachine` is a child node of an actor. Every child of `StateMachine` that extends `State` is a state, keyed by its **node name**.
2. On `_ready`, it waits for its `owner` (for example `Player`) to be ready, then enters `initial_state`.
3. Each frame it forwards `_physics_process`, `_process` and `_unhandled_input` to the **current state only**.
4. A state leaves by emitting `finished` with the next state's name. The machine calls `exit()` on the old state, then `enter(previous)` on the new one, and emits `state_changed(from, to)`.

States decide their own exits. The machine has no transition table, so each state script fully describes its own behaviour.

## State API

| Function | Called when |
|---|---|
| `enter(previous_state: StringName)` | The machine switches into this state |
| `exit()` | Right before the machine leaves this state |
| `physics_update(delta)` | Every physics tick while active |
| `update(delta)` | Every rendered frame while active |
| `handle_input(event)` | Unhandled input events while active |

## Forcing a transition

Outside code can switch states directly, for example on respawn:

```gdscript
state_machine.transition_to(&"Idle")
```

An unknown state name logs an error and is ignored.

## Adding a state

1. Create a script that extends `State`, or an actor-specific base such as `PlayerState`.
2. Override `enter`, `exit` and `physics_update` as needed.
3. Add a `Node` child under the actor's `StateMachine`, name it after the state, and attach the script.
4. Emit `finished(&"YourState")` from other states where they should switch into it.
