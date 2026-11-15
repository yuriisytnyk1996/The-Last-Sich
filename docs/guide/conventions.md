# Conventions

## GDScript style

- Follow the official [GDScript style guide](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_styleguide.html): tabs, `snake_case` for files, functions and variables, `PascalCase` for classes and nodes.
- **Static typing everywhere**: `var speed := 140.0`, `func get_move_axis() -> float`.
- Add `class_name` to scripts other scripts need to reference by type (`Player`, `State`, `StateMachine`, `Room`).
- Private members start with an underscore: `_coyote_timer`.
- Document classes and exported values with `##` comments. Godot shows them as tooltips in the Inspector.

Formatting is enforced by `gdformat` and `gdlint` ([gdtoolkit](https://github.com/Scony/godot-gdscript-toolkit)). Run `pnpm format` to fix formatting, `pnpm lint` to check.

## JavaScript / TypeScript style

Applies to the tooling code (release scripts, configs, the docs site config). Enforced by ESLint, see `eslint.config.ts`.

- No semicolons, single quotes, 2-space indent, trailing commas on multiline literals.
- **Arrow functions use a block body** with an explicit `return`, never an implicit-return expression.
- **Every `if`/`else`/loop body is wrapped in braces** on its own line, never `if (x) throw ...`.
- **Blank lines between logical blocks**: after declarations, around `if`/loop blocks and before `return`/`throw`.

```js
module.exports.readVersion = (contents) => {
  const match = contents.match(VERSION_LINE)

  if (!match) {
    throw new Error('project.godot has no config/version line')
  }

  return match[1]
}
```

## Linting

| Command | What it does |
|---|---|
| `pnpm lint` | ESLint, `gdlint` and `gdformat --check` over the whole repo |
| `pnpm lint:js` / `pnpm lint:gd` | Only one language |
| `pnpm format` | Auto-fixes ESLint issues and reformats GDScript |

The lefthook `pre-commit` hook runs the same checks on staged files.

## Design rules

File size limits and folder layout are covered in [Code organization](/guide/code-organization).

1. **One responsibility per script.** The player script holds data and helpers; each state holds one behaviour.
2. **Tuning values are `@export` variables**, grouped with `@export_group`, so they can be adjusted in the Inspector without editing code.
3. **Systems communicate through signals.** Global events go through [`Events`](/architecture/events). Avoid `get_node("../../Something")` across systems.
4. **Never move physics bodies inside a physics callback.** Use `call_deferred` (see `Room._on_kill_zone_body_entered`).
5. **No placeholders left behind silently.** Placeholder art and debug tools are fine, but list them on the [Roadmap](/roadmap).

## Physics layers

Defined in `project.godot` under `[layer_names]`:

| Layer | Name | Used by |
|---|---|---|
| 1 | `world` | Platforms, walls, ground |
| 2 | `player` | The player body |
| 3 | `enemies` | Enemy bodies (planned) |
| 4 | `player_attacks` | Player hitboxes (planned) |
| 5 | `enemy_attacks` | Enemy hitboxes (planned) |
| 6 | `hazards` | Kill zones, spikes |

## Definition of done

A feature is finished when:

1. It works in the game and has no errors or warnings in the Godot output.
2. `tools/check_file_sizes.sh` and `pnpm lint` pass.
3. Its documentation page is created or updated (see [Writing docs](/guide/writing-docs)).
4. The [Roadmap](/roadmap) is updated.
5. It is committed with a [Conventional Commit](/guide/versioning#commit-messages) message, which becomes its changelog entry.
