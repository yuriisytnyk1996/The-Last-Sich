---
name: code-style
description: Code style and refactoring workflow for The Last Sich (GDScript game code and TypeScript tooling). Use whenever writing, editing, reviewing, cleaning up or refactoring any .gd, .ts or config file in this repo, splitting a large script or function, moving files between folders, or when the user says "refactor", "clean up", "tidy", "split this", "fix the style" or "make this readable", even if they don't mention style explicitly.
---

# Code style and refactoring

The rules live in the docs, which are the source of truth. Read the relevant ones before changing code, rather than relying on memory, because they get updated:

- `docs/guide/conventions.md` covers GDScript and TypeScript style, linting commands and the definition of done.
- `docs/guide/code-organization.md` covers file and function size limits, folder layout per actor, and where shared code goes.

## What the tools enforce

Formatting is mechanical, so let the tools do it instead of hand-formatting:

```sh
pnpm format                  # eslint --fix + gdformat
pnpm lint                    # eslint, gdlint, gdformat --check
tools/check_file_sizes.sh    # GDScript size limits
```

The ESLint config encodes the user's TypeScript preferences: block-body arrow functions with an explicit `return`, braces on every `if`/loop body, and blank lines between logical blocks (after declarations, around `if`/loop blocks, before `return`/`throw`). Write code that way from the start so lint passes the first time.

## What the tools can't check

These need judgment. Check them yourself on every file you touch:

1. **Function length.** About 30 lines, one screen. If a function needs comments to separate its sections, each section becomes its own named function.
2. **File length.** Aim for 100 lines or fewer. Over 200 means plan a split, and over 300 is blocked by the size check.
3. **One responsibility per file.** An actor's root script holds data and shared helpers. Behaviour goes in `states/`, one per file. For a boss, each attack pattern is its own state file.
4. **Placement.** Code is organized by feature, then by concern. Reusable pieces go in `components/` and global managers in `autoload/`. Never import across sibling actor folders. If two actors need the same code, move it to a base class or component.
5. **Naming.** One class per file, and the file is named after the class in snake_case. Never create `utils`, `helpers` or `misc` files.
6. **Readability habits in GDScript too.** Use guard clauses with early `return` instead of deep nesting, and leave blank lines between logical blocks.

## Refactoring workflow

A refactor changes structure, not behaviour. That's what makes it safe to review, so keep the two separate.

1. **Read first.** Read the target files and their callers (`grep` the class name and signal names), along with the docs page for that system in `docs/systems/` or `docs/architecture/`.
2. **Plan the split in terms of the folder layout**, e.g. "move the dash logic from `player.gd` into `states/dash.gd`". If the plan moves files or changes a public API, such as a `class_name`, an exported var or a signal, briefly tell the user before doing it.
3. **Change in small steps.** After each step, the game should still import cleanly:
   ```sh
   /Applications/Godot.app/Contents/MacOS/Godot --headless --path . --import
   /Applications/Godot.app/Contents/MacOS/Godot --headless --path . --quit-after 300
   ```
   When moving `.gd` files, move their `.gd.uid` files too and update `.tscn` references, or the scenes break.
4. **Keep `@export` defaults unchanged.** The docs' tuning tables mirror them.
5. **Run `pnpm format`, `pnpm lint` and `tools/check_file_sizes.sh`.**
6. **Update the docs** as `CLAUDE.md` requires. If files moved, `docs/guide/project-structure.md` must reflect it. Commit with `refactor(<scope>): ...`.

## Reporting

When done, summarise what moved where, which checks ran and whether they passed. Call out anything you deliberately left alone, for example a function over 30 lines that reads fine as one unit.
