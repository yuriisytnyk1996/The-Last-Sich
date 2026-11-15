# Getting started

## Requirements

| Tool | Version | Used for |
|---|---|---|
| Godot | 4.7 | The game |
| Node.js | 22+ | Docs site, commit hooks, releases |
| pnpm | 10+ | Package manager for the tooling |

## First-time setup

```sh
pnpm install
```

This installs the docs site and release tooling, and sets up the git hooks (see [Versioning & releases](/guide/versioning)).

## Run the game

1. Open Godot and import `project.godot` from the repository root.
2. Press **F5** (Run Project). The main scene is `levels/test_room.tscn`.

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
