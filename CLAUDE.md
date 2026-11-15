# The Last Sich

2D pixel-art action-platformer in **Godot 4.7** (GDScript). Targets desktop (Forward+) and mobile (Mobile renderer). Base resolution 640×360.

## Documentation is required

Developer docs live in `docs/` (VitePress). **Every finished feature must update the docs in the same commit.** A feature is not done until:

1. The relevant page in `docs/systems/` or `docs/architecture/` is created or updated. New pages are added to the sidebar in `docs/.vitepress/config.mts`.
2. Tuning tables match the `@export` defaults in code.
3. `docs/changelog.md` has an entry and `docs/roadmap.md` is updated.
4. `docs/guide/project-structure.md` is updated if files or folders were added or moved.

Follow the page template in `docs/guide/writing-docs.md`. Check that the site builds: `cd docs && npm run build`.

## Commits

- Do **not** add `Co-Authored-By: Claude` or any other Claude/AI attribution lines to commit messages or PR descriptions.
- Write a short summary line, then a body describing what changed.

## Content rules

- Never mention or reference other commercial games (by name or otherwise) in code, comments, docs or commit messages. Describe patterns on their own merits.

## Code organization

Full rules: `docs/guide/code-organization.md`. Keep files small and the hierarchy predictable:

- **File size:** aim for 100 lines or fewer. Over 200 is a warning, over 300 is not allowed. Run `tools/check_file_sizes.sh` before committing.
- **Functions** fit on one screen (~30 lines).
- **Organize by feature, then concern:** `actors/<actor>/` holds the scene, the root script (data and helpers only), `states/` (one behaviour per file) and optional `attacks/`, `abilities/`, `audio/`. Every actor uses the same layout.
- **Bosses:** one attack pattern per state file. No monolithic behaviour scripts.
- **Reusable pieces** go in `components/`, global managers in `autoload/` (one per file), shared actor code in base classes. Never import across sibling actor folders.
- **One class per file**, named after the class in snake_case. No `utils`/`helpers`/`misc` dumping grounds.
- **Folders:** split into subfolders past ~10 files; max 4 levels below `res://`. Don't create empty placeholder folders.

## Code conventions

See `docs/guide/conventions.md`. In short: static typing, `class_name` for shared types, `@export` tuning values, one behaviour per state script, global events through the `Events` autoload, physics layers as named in `project.godot`.

## Verifying changes

Godot binary: `/Applications/Godot.app/Contents/MacOS/Godot`.

```sh
# Import and check for script errors
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --import
# Run the main scene for 300 frames
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --quit-after 300
```

Autoloads aren't available by name in `-s` test scripts. Use `root.get_node("Events")` there.
