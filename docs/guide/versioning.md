# Versioning & releases

Versions, the changelog and git tags are generated from commit messages. Nobody edits the version number or writes changelog entries by hand.

| Tool | Job |
|---|---|
| [Conventional Commits](https://www.conventionalcommits.org) | Commit message format |
| [commitlint](https://commitlint.js.org) | Rejects commits that don't follow the format |
| [lefthook](https://lefthook.dev) | Runs git hooks: commitlint on every commit message, the file size check before every commit |
| [commit-and-tag-version](https://github.com/absolute-version/commit-and-tag-version) | Bumps the version, writes `CHANGELOG.md`, creates the release commit and git tag |

All are installed with `pnpm install`, which also sets up the git hooks.

## Commit messages

```
type(scope): short summary in lowercase

Optional body explaining what and why.
```

Examples:

```
feat(player): add wall jump
fix(rooms): respawn player facing right
refactor(state-machine): rename transition_to to change_state
docs: explain coyote time
```

### Types

| Type | Use for | In changelog |
|---|---|---|
| `feat` | New gameplay, system or visible feature | Features |
| `fix` | Bug fix | Bug Fixes |
| `perf` | Performance improvement | Performance |
| `refactor` | Code change with no behaviour change | Refactoring |
| `docs` | Documentation only | hidden |
| `style` | Formatting only | hidden |
| `test` | Tests | hidden |
| `build` | Tooling, dependencies | hidden |
| `ci` | Automation | hidden |
| `chore` | Anything else, release commits | hidden |

### Scopes

`player`, `enemies`, `bosses`, `combat`, `rooms`, `ui`, `input`, `rendering`, `audio`, `save`, `currency`, `spirit`, `death-penalty`, `state-machine`, `events`, `docs`, `tooling`, `release`.

Other scopes are allowed but produce a warning. Add new ones to `commitlint.config.ts` when a new system appears.

### Breaking changes

Add `!` after the type, or a `BREAKING CHANGE:` footer, when a change breaks save files, renames input actions, or changes something other systems depend on:

```
feat(save)!: store inventory by item id
```

## Version numbers

Versions use `MAJOR.MINOR.PATCH`. The game is in early development, so it starts at **0.0.1**.

| Stage | Versions | Meaning |
|---|---|---|
| Prototype | `0.0.x` | Core systems being built. Nothing is stable. |
| Development | `0.x.0` | Playable milestones (first enemy, first area, first boss...). |
| Launch | `1.0.0` | Released game. |

Before 1.0.0, the tool bumps conservatively:

| Commits since last release | Bump |
|---|---|
| `fix`, `feat` | patch: `0.0.1` → `0.0.2` |
| Breaking change | minor: `0.0.5` → `0.1.0` |

To mark a milestone, bump the minor version explicitly (see below).

## Making a release

```sh
pnpm release                     # bump from commits, e.g. 0.0.1 → 0.0.2
pnpm release --release-as minor  # milestone, e.g. 0.0.7 → 0.1.0
pnpm release --dry-run           # preview without changing anything
```

A release:

1. Reads the commits since the last tag and works out the next version.
2. Updates the version in `package.json` **and** `project.godot` (`application/config/version`). The bump for `project.godot` is done by `tools/release/godot-version-updater.ts`.
3. Adds a new section at the top of `CHANGELOG.md`.
4. Commits as `chore(release): x.y.z` and creates the tag `vx.y.z`.

The version appears in-game in the bottom-right corner (`ui/version_label.gd`), so screenshots and bug reports always show which build they come from.

The [Changelog](/changelog) page in these docs shows `CHANGELOG.md` directly.

## When to release

- After finishing a feature or a group of related fixes that you want to play-test as a unit.
- Before sending a build to anyone.
- At every milestone (with `--release-as minor`).

## Files

| File | Role |
|---|---|
| `package.json` | Tooling dependencies, scripts, version |
| `commitlint.config.ts` | Commit rules and scopes |
| `lefthook.yml` | Git hooks |
| `.versionrc.json` | Changelog sections and files to bump |
| `tools/release/godot-version-updater.ts` | Reads and writes the version in `project.godot` |
| `CHANGELOG.md` | Generated changelog |

::: tip Godot and node_modules
`pnpm install` runs a `postinstall` script that writes `node_modules/.gdignore`, so Godot never scans the tooling dependencies.
:::
