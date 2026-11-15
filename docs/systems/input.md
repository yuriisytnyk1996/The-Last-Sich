# Input

All controls are **actions** defined in `project.godot` (**Project Settings → Input Map**). Code only refers to action names, never to keys, so rebinding and adding devices doesn't touch gameplay code.

## Actions

| Action | Keyboard | Gamepad | Used by |
|---|---|---|---|
| `move_left` | A, ← | Left stick left, D-pad left | `Player.get_move_axis()` |
| `move_right` | D, → | Left stick right, D-pad right | `Player.get_move_axis()` |
| `move_up` | W, ↑ | Left stick up, D-pad up | Not used yet |
| `move_down` | S, ↓ | Left stick down, D-pad down | Not used yet |
| `jump` | Space, Z | A / Cross | Jump buffer, variable jump height |
| `dash` | K, C, Shift | Right shoulder | `Player.wants_dash()` |
| `attack` | J, X | X / Square | Not used yet |
| `toggle_fullscreen` | F11, Alt+Enter | — | `DisplaySettings` |

All actions use a dead zone of 0.3. Debug-only keys (F3, scaling mode) are not actions; see [Rendering](/systems/rendering). Keys are bound by **physical** position, so the layout works the same on QWERTY, AZERTY and Cyrillic keyboards.

## Reading input in code

```gdscript
Input.get_axis("move_left", "move_right")  # -1..1, works with sticks
Input.is_action_just_pressed("jump")       # this frame only
Input.is_action_pressed("jump")            # held
```

## Planned

- On-screen touch controls for mobile, mapped to the same actions.
- In-game rebinding menu.
