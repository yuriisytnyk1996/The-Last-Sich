# Skills

Skills are upgrades the player learns at a skill shrine, paid for with [currency](/systems/currency). They make up a skill tree of five lines with three levels each. Every line unlocks or upgrades one ability: combo finishers, a charged slash, a lunge, a dive and a ranged bolt. Tiers gate the stronger levels; tier relics found in the world open them.

## How it works

1. Every skill is a `PlayerSkill` resource (`actors/player/skills/<line>/<line>_<level>.tres`): an `id`, a title and description for the menu, a `tier`, a `cost` and a `parent` skill (the level before it).
2. The player's `Skills` node (`PlayerSkills`, `actors/player/abilities/skills.gd`) lists every skill in `all`, remembers which ones are learned and holds `max_tier`.
3. A skill is **learnable** when it isn't learned yet, its parent is learned and its tier is at most `max_tier`. It can be **learned** when it is learnable and the wallet holds at least its cost.
4. The player presses interact at a `SkillShrine` (`levels/objects/skill_shrine.tscn`). It pauses the game and opens a `PausingMenu` with a `SkillsScreen`.
5. The screen shows the currency and tier, then the tree as a grid: one line per row, one level per column. Each cell shows the cost, "learned", the tier it needs, or "locked" (parent missing). The focused skill's description shows below, with what is missing. Choosing a skill the player can pay for asks to confirm, then `PlayerSkills.learn()` spends the currency (`PlayerWallet.spend()`) and learns it.
6. Each line's ability asks `skills.level(&"<line>")` (0 when nothing is learned, else the highest level) before it runs and to pick its strength.

### Tiers

`max_tier` starts at `start_tier` (1). Touching a `TierRelic` (`levels/objects/tier_relic.tscn`) raises it by one (`raise_tier()`), up to `TIER_CAP` (6). A relic is taken once; its room remembers that through the `persistent` group. The test rooms hold four relics, enough for every skill.

### Saving

`PlayerSkills` is a global save system (`skills`, see [Save system](/systems/save-system)): the learned ids and `max_tier` are saved when the player rests or dies, together with the wallet. Quitting before that loses the skill and gives the currency back.

### Debug

In debug builds (running from the editor, or a debug export):

- **F9** in game learns every skill for free and raises the tier to `TIER_CAP` (`PlayerSkills.unlock_all()`).
- The skill shrine shows two extra buttons: **Debug: unlock all** (the same) and **Debug: lock all**, which forgets every skill and resets the tier to `start_tier` (`lock_all()`). Spent currency is not given back.

Both change only the running game; they are saved like normal skills the next time the game saves. Release builds have neither.

### Skill tree

| Line | Level 1 | Level 2 | Level 3 |
|---|---|---|---|
| `combo` | Finishing blow: forward finisher after the heavy combo swing. Tier 1, 100 | Rising blow: up + attack, rising finisher. Tier 2, 250 | Crushing blow: down + attack, slam on both sides. Tier 3, 500 |
| `charged` | Charged slash: hold attack after a ground slash, let go when charged. Tier 1, 150 | Swift charge: charges twice as fast. Tier 2, 300 | Charged wave: the slash also sends a wave along the ground. Tier 4, 600 |
| `lunge` | Lunge: attack during a dash, a piercing thrust. Tier 1, 150 | Long lunge: faster and longer. Tier 3, 350 | Piercing lunge: longer still, hits much harder. Tier 4, 600 |
| `dive` | Dive strike: in the air, down + hold attack. Tier 2, 200 | Wide dive: wider landing. Tier 3, 400 | Shockwave dive: a dive from high up ends in a shockwave. Tier 5, 800 |
| `ranged` | Spirit bolt: let go of ranged to throw a bolt, costs spirit. Tier 2, 200 | Returning bolt: it flies back, hitting again. Tier 3, 400 | Bursting bolt: it bursts where it turns. Tier 5, 800 |

How each ability works is on [Combat](/systems/combat#skill-attacks).

## Files

| File | Role |
|---|---|
| `actors/player/skills/player_skill.gd` | `PlayerSkill` resource: id, text, tier, cost, parent |
| `actors/player/skills/<line>/` | The line's three `.tres` files and, except for `combo`, its ability script |
| `actors/player/abilities/skills.gd` | `PlayerSkills`: the tree, learned ids, tier, rules, saved. Its children are the line abilities |
| `actors/player/skills/charged/charged_attack.gd` | `PlayerChargedAttack`: when to charge, charge time, the wave |
| `actors/player/skills/lunge/lunge_attack.gd` | `PlayerLungeAttack`: speed, length and damage per level |
| `actors/player/skills/dive/dive_attack.gd` | `PlayerDiveAttack`: when to dive, ground height, the shockwave |
| `actors/player/skills/ranged/ranged_attack.gd` | `PlayerRangedAttack`: when to throw, spirit cost, the bolt |
| `actors/player/abilities/wallet.gd` | `PlayerWallet.spend()` pays for a skill |
| `levels/objects/skill_shrine.gd` / `.tscn` | `SkillShrine`: interact to open the skill menu |
| `levels/objects/tier_relic.gd` / `.tscn` | `TierRelic`: raises the tier once |
| `ui/menus/pausing_menu.gd` | `PausingMenu`: a menu that pauses the game while open (also the base of the pause menu) |
| `ui/menus/skills/skills_screen.gd` | `SkillsScreen`: the shrine's grid, description and confirm |

## Tuning

| Value | Default | Effect |
|---|---|---|
| `PlayerSkills.start_tier` | 1 | Tier at the start of a new game |
| `PlayerSkills.TIER_CAP` | 6 | Highest tier (constant) |
| `PlayerSkill.cost` / `tier` | per skill | See the skill tree |

The abilities' own values are on [Combat](/systems/combat#skill-attacks-1).

## Extending

- **A new level or line:** create `PlayerSkill` `.tres` files in `actors/player/skills/<line>/` with ids `<line>_1` to `<line>_3`, each level's `parent` set to the one before, and add them to `Skills.all` on the player scene in line order (the menu shows `PlayerSkills.LEVELS` per row). Read the level with `player.skills.level(&"<line>")`. Never rename an `id` that has been saved.
- **A new line ability:** put its script in the line's folder, add it as a child of `Skills` and an `@onready` reference on `PlayerSkills`, as the four existing ones are.
- **Other ways to raise the tier** (a boss reward, an altar): call `player.skills.raise_tier()`.
- **Reacting to a new skill or tier** (a sound, a tutorial prompt): connect to `PlayerSkills.learned` or `tier_raised`.

## Known limitations

- Plain text cells in the default menu style: no skill icons, tree lines or learn animation.
- The shrine is grey rectangles with a blue gem; tier relics are blue diamonds with no pickup effect.
- Nothing in the HUD shows the tier; only the shrine does.
