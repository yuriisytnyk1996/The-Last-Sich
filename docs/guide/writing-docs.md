# Writing docs

Documentation is part of every feature, not an afterthought. When a feature is done, its docs are updated in the same commit.

## Where things go

| Change | Update |
|---|---|
| New system (combat, save, audio...) | New page under `docs/systems/`, add it to the sidebar in `docs/.vitepress/config.mts` |
| New shared building block | New page under `docs/architecture/` |
| New or changed tuning values | The tuning table on the system's page |
| New input action | [Input](/systems/input) |
| New folder or moved files | [Project structure](/guide/project-structure) |
| Any finished feature | [Roadmap](/roadmap). The [Changelog](/changelog) is generated from commit messages, see [Versioning & releases](/guide/versioning). |

## Page template

```md
# System name

One or two sentences: what it does and why it exists.

## How it works
The flow, step by step. Reference files as `path/to/file.gd`.

## Files
| File | Role |

## Tuning
| Value | Default | Effect |

## Extending
How to add a new variant (a new state, enemy, room...).

## Known limitations
What is missing or placeholder.
```

## Tips

- Write for someone opening the project for the first time.
- Explain **why**, not just what. The code already shows what.
- Keep defaults in tables in sync with the `@export` values in code.
- Preview locally with `pnpm docs:dev`.
