# Getting started

## Requirements

| Tool | Version | Used for |
|---|---|---|
| Godot | 4.7 | The game |
| [mise](https://mise.jdx.dev) | any | Installs the tool versions pinned in `mise.toml` |
| Node.js | 24 | Docs site, commit hooks, releases, linting. Installed by mise. |
| pnpm | 12 | Package manager for the tooling. Installed by mise. |
| gdtoolkit | 4.x | GDScript linter and formatter (`gdlint`, `gdformat`). Installed by mise. |

## First-time setup

```sh
mise install   # Node 24, pnpm 12 and gdtoolkit, as pinned in mise.toml
pnpm install   # tooling packages and git hooks
```

Node 24 is required because the tooling scripts and configs are TypeScript files that Node runs directly, with no build step.

See [Versioning & releases](/guide/versioning) for what the git hooks check.

## Run the game

1. Open Godot and import `project.godot` from the repository root.
2. Press **F5** (Run Project). The main scene is `levels/world.tscn`, which starts in `levels/rooms/test_room.tscn`.

The debug label in the top-left corner shows the player's current state, velocity and whether they are on the floor.

## Controls

| Action | Keyboard | Gamepad |
|---|---|---|
| Move | A / D, or arrow keys | Left stick or D-pad |
| Jump | Space or Z | A (bottom face button) |
| Dash | K, C or Shift | Right shoulder |
| Attack | J or X | X (left face button). Not implemented yet. |

See [Input](/systems/input) for the full input map.

## Run the documentation site

```sh
pnpm docs:dev      # local site with live reload
pnpm docs:build    # static site in docs/.vitepress/dist
```

::: tip
`docs/` and `node_modules/` both contain a `.gdignore` file, so Godot never scans them.
:::
