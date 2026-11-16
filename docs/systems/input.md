# Input

All controls are **actions** defined in `project.godot` (**Project Settings → Input Map**). Code only refers to action names, never to keys, so rebinding and adding devices doesn't touch gameplay code.

## Actions

Every action has **one key and one gamepad button**, so each control is easy to learn and to show in prompts. Movement also works on the D-pad.

| Action | Keyboard | Gamepad | Used by |
|---|---|---|---|
| `move_left` | A | Left stick left, D-pad left | `Player.get_move_axis()` |
| `move_right` | D | Left stick right, D-pad right | `Player.get_move_axis()` |
| `move_up` | W | Left stick up, D-pad up | Up attack (`PlayerState.attack_state()`); held, grabs and climbs ladders; while hanging from a ledge, climbs onto it |
| `move_down` | S | Left stick down, D-pad down | Crouch attack (`PlayerState.attack_state()`); held on top of a ladder, climbs down it; held with jump, drops through one-way platforms (`PlayerDropThrough.wants()`); while hanging from a ledge, lets go |
| `jump` | Space | A / Cross | Jump buffer, variable jump height |
| `attack` | J | X / Square | Attack buffer, `Player.wants_attack()`. With [skills](/systems/skills): held after a ground slash, charges; during a dash, lunges; held with down in the air, dives |
| `parry` | K | Left shoulder | `PlayerParry.wants()`: raise the guard in Idle or Run, on the ground only |
| `dash` | Shift | Right shoulder | `Player.wants_dash()`, on the ground only |
| `heal` | F | Y / Triangle | `PlayerFlasks.wants()`: drink a healing flask in Idle or Run |
| `interact` | E | B / Circle | `Player.can_interact()`: use doors, rest points and skill shrines, in Idle or Run |
| `ranged` | L | Right stick click | `PlayerRangedAttack.wants()`: press and let go to throw a spirit bolt (with the skill) |
| `pause` | Escape | Start | `World` opens the [pause menu](/systems/menus); closes it again |
| `toggle_fullscreen` | F11, Alt+Enter | — | `DisplaySettings` |

The left hand stays on WASD with dash (Shift), interact (E), heal (F) and jump (Space) in reach; the right hand has attack (J), parry (K) and ranged (L).

All actions use a dead zone of 0.3. Debug-only keys are not actions: F8 deletes the save and restarts (see [Save system](/systems/save-system)), F9 learns every skill (see [Skills](/systems/skills#debug)). Keys are bound by **physical** position, so the layout works the same on QWERTY, AZERTY and Cyrillic keyboards.

## Reading input in code

```gdscript
Input.get_axis("move_left", "move_right")  # -1..1, works with sticks
Input.is_action_just_pressed("jump")       # this frame only
Input.is_action_pressed("jump")            # held
```

Menus use Godot's built-in `ui_*` actions: arrow keys, D-pad and left stick to move, Enter / Space / A to confirm, Escape / B to go back.

## Rebinding

Players rebind the gameplay actions in **Options → Controls**. `InputSettings` swaps the key or button event in the `InputMap`, so code reading action names is unaffected. Escape, F11, F8, F9 and Start are reserved. See [Options](/systems/options#controls).

## Planned

- On-screen touch controls for mobile, mapped to the same actions.
