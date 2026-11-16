# Skills

Skills are upgrades the player learns at a skill shrine, paid for with [currency](/systems/currency). They unlock new moves for existing abilities. The first set upgrades the ground combo with finishers, see [Combat](/systems/combat#ground-combo).

## How it works

1. Every skill is a `PlayerSkill` resource (`actors/player/skills/*.tres`): an `id`, a title and description for the menu, a `tier`, a `cost` and an optional `parent` skill.
2. The player's `Skills` node (`PlayerSkills`, `actors/player/abilities/skills.gd`) lists every skill in `all` and remembers which ones are learned.
3. A skill is **learnable** when it isn't learned yet, its parent is learned and its tier is at most `max_tier`. It can be **learned** when it is learnable and the wallet holds at least its cost.
4. The player presses interact at a `SkillShrine` (`levels/objects/skill_shrine.tscn`). It pauses the game and opens a `PausingMenu` with a `SkillsScreen`.
5. The screen shows the currency and one row per skill: its cost, "learned" or "locked". The focused skill's description shows below, with the reason it is locked or that the currency is short. Choosing a skill the player can pay for asks to confirm, then `PlayerSkills.learn()` spends the currency (`PlayerWallet.spend()`) and learns it.
6. Abilities check `skills.has(id)`, or `skills.highest(ids)` for a skill that upgrades one ability in steps (`combo_1` to `combo_3`), and only offer the move when it is learned.

`PlayerSkills` is a global save system (`skills`, see [Save system](/systems/save-system)): the learned ids are saved when the player rests or dies, together with the wallet. Quitting before that loses the skill and gives the currency back.

### Skill list

| Id | Title | Tier | Cost | Parent | Unlocks |
|---|---|---|---|---|---|
| `combo_1` | Finishing blow | 1 | 100 | none | Attack after the heavy combo swing: forward finisher |
| `combo_2` | Rising blow | 2 | 250 | `combo_1` | Up + attack after the heavy combo swing: rising finisher |
| `combo_3` | Crushing blow | 3 | 500 | `combo_2` | Down + attack after the heavy combo swing: ground slam on both sides |

## Files

| File | Role |
|---|---|
| `actors/player/skills/player_skill.gd` | `PlayerSkill` resource: id, text, tier, cost, parent |
| `actors/player/skills/*.tres` | One file per skill |
| `actors/player/abilities/skills.gd` | `PlayerSkills`: the list of skills, learned ids, rules, saved |
| `actors/player/abilities/wallet.gd` | `PlayerWallet.spend()` pays for a skill |
| `levels/objects/skill_shrine.gd` / `.tscn` | `SkillShrine`: interact to open the skill menu |
| `ui/menus/pausing_menu.gd` | `PausingMenu`: a menu that pauses the game while open (also the base of the pause menu) |
| `ui/menus/skills/skills_screen.gd` | `SkillsScreen`: the shrine's list, description and confirm |

## Tuning

| Value | Default | Effect |
|---|---|---|
| `PlayerSkills.max_tier` | 3 | Highest tier the player can learn. Every tier is open until a progression item raises it |
| `PlayerSkill.cost` | per skill | Currency to learn it, see the skill list |
| `PlayerSkill.tier` | per skill | Tier needed to learn it |

## Extending

- **A new skill:** create a `PlayerSkill` `.tres` in `actors/player/skills/` with a new `id`, add it to `Skills.all` on the player scene (the order is the menu order) and check `player.skills.has(&"your_id")` where the move starts. Never rename an `id` that has been saved.
- **Skills that upgrade one ability in steps:** chain them with `parent` and read the best one with `skills.highest([...])`, as `combo_heavy.gd` does.
- **Raising tiers through progression:** have the progression item raise `PlayerSkills.max_tier` and add it to the skills save data.
- **Reacting to a new skill** (a sound, a tutorial prompt): connect to `PlayerSkills.learned`.

## Known limitations

- Plain text rows in the default menu style: no skill icons, tree layout or learn animation.
- The shrine is grey rectangles with a blue gem.
- Nothing raises `max_tier` yet, so every tier is open from the start.
