# Dumas

Dumas are songs the player sings for [spirit](/systems/spirit). They are [items](/systems/inventory) of their own kind, worn one at a time, and sung with the `duma` button: a rising aura, then the duma goes off. Some strike at once (pillars of fire, a thunderbolt, a volley, a stunning burst); others last a while (a ring of sabres, heavy strikes) or summon [companions](#companions) that fight beside the player (a warding circle, a sworn brother's ghost, falcons). While one lasts, no other can be sung.

## How it works

```
Idle / Run ──duma pressed──► can sing? ──no──► Events.spirit_short (spirit bar flashes)
                                  │ yes
                                  ▼
                            Duma state: planted, aura rises
                                  │ cast_point
                                  ▼
            PlayerDumas.begin(): spend cost(), ItemEffects.use(item)
                                  │ recovery
                                  ▼
                              Idle / Run
     lasting effects run for duration + DUMA_DURATION ──► running (HUD line shrinks)
```

1. A duma is an `Item` with `kind = DUMA` (`actors/player/items/dumas/<id>.tres`). It has a `spirit_cost` and effects with the `ON_USE` trigger. There is one duma slot; wearing another duma replaces the worn one. See [Inventory](/systems/inventory#kinds-and-slots).
2. In Idle or Run, a press of `duma` asks `PlayerDumas.wants()` (`actors/player/abilities/dumas.gd`). It can sing when a duma is worn, none is running, the player has at least `cost()` spirit (the duma's `spirit_cost` plus the `duma_cost` [stat](/systems/stats)) and every `ON_USE` effect of the duma can start now (`ItemEffect.can_start()`, asked through `PlayerItemEffects.can_use()`). Otherwise it emits `Events.spirit_short` and the spirit bar flashes red. A press while a duma is running does nothing.
3. The **Duma** state (`actors/player/states/duma.gd`) plants the player on the ground with no control. The `DumaAura` placeholder fades in over `cast_point`.
4. At the cast point it calls `PlayerDumas.begin()`. The spirit is spent, and `PlayerItemEffects.use(item, extra)` starts every `ON_USE` effect of the duma. Effects with a `duration` run for that long plus the `duma_duration` stat, then stop on their own.
5. The aura flashes and fades during `recovery`, then the player is back in Idle or Run. A hit before the cast point interrupts the cast and nothing is spent. Walking off a ledge drops into Fall.
6. While the longest lasting effect runs, the duma is **running** (`PlayerDumas.is_running()`). Each frame `Events.duma_time_changed(fraction_left)` reports the time left, and the [HUD](/systems/hud#spirit-bar-and-death-marks) draws it as a line under the spirit bar. A duma with only instant effects never runs.
7. **Death and resting** end a running duma at once (`PlayerDumas.end()`, on `Health.died` and `Events.rested`): its effects stop, the sabre ring closes, the HUD line clears, and a duma can be sung again. Pillars and shots still waiting to go off are dropped (`PlayerDumas.generation`).
8. **Entering a room** (an exit, travel or a respawn) doesn't end it: the duma keeps running and its time keeps counting. The `SabreRing` lives under the `World`, not the room, so it goes along, jumping to the player when they are more than `snap_distance` away. `World._load_room()` calls `PlayerDumas.drop_pending()`, so pillars and shots still waiting don't go off in the new room, and blasts and projectiles already out are freed on `Events.room_change_requested`.
9. **Swapping while one runs:** the running duma is the one sung, not the one worn. Wearing another duma, or taking every duma off, doesn't stop it: its effects (a sabre ring, heavy strikes) keep going until their time runs out, and `duma` still does nothing until then. The newly worn duma can be sung once it ends. `PlayerItemEffects` stops `ON_USE` effects by their timer whatever is worn.

### Duma effects

Dumas are built from [item effects](/systems/inventory#effects) with the `ON_USE` trigger. Five effect types exist for them; attacks they spawn are scaled by `PlayerDumas.strength()`, the `duma_strength` stat, on top of the player's `damage` stat.

- **`BlastRowEffect`**: a row of `PlayerBlast`s along the ground from the player's feet, one after another. The first goes off `offset` px in front, the next ones `spacing` further each, spread evenly over `spread_time`; `both_sides` sends a second row behind. A wall ends the row (a ray at `WALL_CHECK_HEIGHT` above the feet). `count` 1 with `offset` 0 is a single blast on the player.
- **`VolleyEffect`**: `shots` `PlayerProjectile`s forward from the chest (`muzzle`), `interval` apart, each after the first up to `spread` px higher or lower at random.
- **`SummonEffect`**: puts a scene next to the player for the effect's `duration`, calling its `follow(player)` before adding it under the `World` and its `dismiss()` when the effect stops. Used for the `SabreRing` and the [companions](#companions). It works with lasting triggers too: the wandering candle, a relic, summons its light while worn. A relic worn when the game loads starts before the `World` is ready, so the node is added once it is.
- **`HeavyStrikesEffect`**: every swing hitbox under `Visual/Attacks` deals HEAVY hits while it runs (longer stagger, more knockback, double spirit); their own reaction comes back when it stops.

- **`ReturnEffect`**: sends `Events.return_requested`. `World` fades out and puts the player back at the last [rest point](/systems/rest-points) they used, loading its room. Health, flasks and spirit stay as they are: it is a way home, not a rest, and the respawn point doesn't change. Before any rest, it puts the player where they entered the current room. Its `can_start()` is false during a [boss fight](/systems/bosses) (`BossArena.FIGHT_GROUP`), so the duma isn't sung there and the spirit bar flashes.

The existing `StatEffect` and `RestoreEffect` work with `ON_USE` too: the Iron Hand pairs `HeavyStrikesEffect` with a `StatEffect` for damage.

**Sabre ring** (`actors/player/attacks/sabre_ring.gd`): its `Hitbox` children circle the player's chest, opening from nothing to `radius` over `open_time`. Each sabre hits enemies it passes, and is switched off for one frame every `rehit_time` so an enemy that stays inside is hit again. Enemy shots (`EnemyProjectile`) that touch a sabre are destroyed. On `dismiss()` the ring closes over `close_time`, then frees itself. It goes into the next room with the player, jumping to them when they are farther than `snap_distance`.

### Companions

Helpers summoned by `SummonEffect`, in `actors/player/companions/`. The ones that float beside the player extend **`Companion`** (`companion.gd`): `follow()` remembers the player, `dismiss()` fades out over `fade_time` and frees the node, and `glide_to()` eases towards a target but jumps there when it is more than `snap_distance` away, so a companion arrives with the player in a new room. Dying or resting ends the duma, which dismisses them.

- **Wagon Fort** (`WagonFort`, `wagon_fort.gd`): a warding circle set down where the duma is sung. It doesn't follow the player around the room. While the player's chest (`chest_height` above the feet) is within `radius` of its centre, their hurtbox is warded (`Hurtbox.set_ward()`, see [Blocking](/systems/combat#blocking)): every hit is blocked and enemy shots stop on the player. Parries still work, and pits and spikes still kill. Drawn as a dome (the upper half of the circle). It goes along with the player: after a room exit (`Events.player_arrived`, sent by the `World` behind the black screen once the player is placed) it closes and opens again at the player's feet in the new room, for the rest of the duma's time.
- **Sworn Brother** (`SwornBrother`, `sworn_brother.gd`): a ghost floating at `offset` behind the player's shoulder. It listens to the player's `StateMachine.state_changed`. A swing (`STRIKE_STATES`: side, up and crouch attacks, the combo swings, the charged slash and the riposte) sends him lunging `strike_distance` past the player with his `Sabre`, a HEAVY hit. Raising the parry guard sends him `guard_distance` in front of the player with his `Shield` up, warding the player for `guard_time`. Either one starts `cooldown`, and nothing new starts while he is busy. His sabre and his shield destroy enemy shots they touch.
- **Falcons** (`FalconFlock`, `falcons/falcon_flock.gd`, with three `Falcon`s, `falcons/falcon.gd`): the falcons hover in an arc over the player's head. Every `check_interval` the flock picks the nearest enemy within `attack_range` of the player that it can see (no solid terrain between the flock and the enemy's hurtbox) and sends one falcon at it. The falcon leaves the flock, flies at the centre of the enemy's hurtbox shape and is gone after its first hit, on reaching the spot, after `lifetime` or on a room change. Dying enemies, turned-off ones (a dormant boss) and enemies on their knees (an [execution](/systems/combat#executions) waits for the player) are skipped. Sending the last falcon ends the duma (`PlayerDumas.end()`); if the time runs out first, the falcons left fade away.
- **Wandering light** (`WanderingLight`, `wandering_light.gd`): summoned by the wandering candle relic while it is worn, not by a duma. It floats behind the player's shoulder. After `notice_delay` in a room it looks for a captive cage that isn't broken (a `Breakable` in the `captives` group; `captive_cage.tscn` joins it) and drifts over to hover `hover_height` above the nearest one at `seek_speed`, until the cage breaks or the room changes. Then it comes back.

**Stunning hits:** the Calm Sea's `StunBurst` has `Hitbox.stuns` on. An enemy that flinches is stunned by it as if parried (`EnemyDamage.stun_from()`), see [Enemies](/systems/enemies#stun). Bosses don't flinch, so they only take the damage.

### Dumas

| Duma | Cost | Price | Effect |
|---|---|---|---|
| Duma of the Burning Steppe | 15 | 600 | 8 `FirePillar`s march forward (24 px apart, from 24 px, over 0.6 s), 30 FIRE damage each |
| Duma of the Black Sea Storm | 15 | 600 | 4 `FirePillar`s on each side at once (28 px apart, from 20 px, over 0.4 s) |
| Duma of the Thunderbolt | 20 | 700 | A `ThunderBeam` (28 × 200 px) on the player: 70 damage, HEAVY |
| Duma of the Three Brothers | 10 | 450 | 3 `DumaShot`s forward, 0.15 s apart, 30 damage each |
| Duma of the Calm Sea | 15 | 550 | A `StunBurst` (144 × 56 px) around the player: 10 damage, stuns |
| Duma of the Sabre Ring | 20 | 800 | 3 sabres circle the player for 15 s, 15 damage per hit, destroy enemy shots |
| Duma of the Iron Hand | 20 | 800 | For 20 s every swing is HEAVY and damage is +25% |
| Duma of the Road Home | 30 | 500 | Back to the last rest point used, without healing. Not during a boss fight |
| Duma of the Wagon Fort | 25 | 700 | A warding circle (40 px) where it is sung: no hit lands on the player inside it for 10 s |
| Duma of the Sworn Brother | 25 | 900 | A ghost fights beside the player for 30 s: a 40-damage HEAVY cut when they swing, a shield that wards them when they parry |
| Duma of the Falcons | 20 | 800 | 3 falcons for 20 s, each strikes the nearest visible enemy once for 40 damage; the duma ends when the last one flies |

The first seven lie in the test room, past the pit east of the training dummy. The Wagon Fort, the Sworn Brother and the Falcons lie on the floor past the next step, near the musketeer (x 968 to 1016). The Road Home lies at the west end of the [test crypt](/systems/environment#test-crypt-layout). The wandering candle (a relic) lies in the test barracks (x 300), the room with a captive cage.

## Files

| File | Role |
|---|---|
| `actors/player/abilities/dumas.gd` | `PlayerDumas`: the button, cost, `begin()`, running time, `end()` |
| `actors/player/states/duma.gd` | Duma: the planted cast with the aura |
| `actors/player/items/dumas/` | One `.tres` per duma |
| `actors/player/items/effects/blast_row_effect.gd` | `BlastRowEffect`: a row of blasts along the ground |
| `actors/player/items/effects/volley_effect.gd` | `VolleyEffect`: a few shots forward |
| `actors/player/items/effects/summon_effect.gd` | `SummonEffect`: a scene beside the player while it runs |
| `actors/player/items/effects/heavy_strikes_effect.gd` | `HeavyStrikesEffect`: HEAVY swings while it runs |
| `actors/player/items/effects/return_effect.gd` | `ReturnEffect`: back to the last rest point (`Events.return_requested`) |
| `actors/player/attacks/sabre_ring.gd` / `.tscn` | `SabreRing`: the circling sabres |
| `actors/player/companions/companion.gd` | `Companion`: base for helpers that float beside the player |
| `actors/player/companions/wagon_fort.gd` / `.tscn` | `WagonFort`: the warding circle |
| `actors/player/companions/sworn_brother.gd` / `.tscn` | `SwornBrother`: the ghost that strikes and guards with the player |
| `actors/player/companions/falcons/` | `FalconFlock` and `Falcon`: falcons that strike the nearest enemy |
| `actors/player/companions/wandering_light.gd` / `.tscn` | `WanderingLight`: the wandering candle's light, leads to captives |
| `actors/player/attacks/fire_pillar.tscn`, `thunder_beam.tscn`, `stun_burst.tscn` | `PlayerBlast` scenes for dumas |
| `actors/player/attacks/duma_shot.tscn` | `PlayerProjectile` for the Three Brothers |

## Tuning

Duma state (`StateMachine/Duma`):

| Value | Default | Effect |
|---|---|---|
| `cast_point` | 0.4 | Seconds from the press to the cast point, where spirit is spent |
| `recovery` | 0.35 | Seconds held after the cast point |

Stats (`PlayerStats`, see [Stats](/systems/stats)):

| Value | Default | Effect |
|---|---|---|
| `duma_cost` | 0 | Spirit added to every duma's cost (below 0 makes them cheaper, never below 0) |
| `duma_duration` | 0 | Seconds added to every lasting duma effect |
| `duma_strength` | 1.0 | Multiplier for the damage of duma attacks |

`BlastRowEffect`:

| Value | Default | Effect |
|---|---|---|
| `count` | 8 | Blasts in a row |
| `offset` | 24 | Distance from the player to the first blast (px) |
| `spacing` | 24 | Distance between blasts (px) |
| `spread_time` | 0.6 | Seconds from the first blast to the last |
| `both_sides` | false | Also a row behind |
| `shake` | 0.3 | Camera shake when the row starts |

`VolleyEffect`:

| Value | Default | Effect |
|---|---|---|
| `shots` | 3 | Shots fired |
| `interval` | 0.15 | Seconds between shots |
| `spread` | 6 | Random height change of later shots (px) |
| `muzzle` | (12, -18) | Where shots start, facing right (px) |

`SabreRing`:

| Value | Default | Effect |
|---|---|---|
| `radius` | 28 | Ring radius when open (px) |
| `open_time` / `close_time` | 0.5 / 0.4 | Seconds to open and close |
| `turns_per_second` | 0.8 | Spin speed |
| `rehit_time` | 0.5 | Seconds before a sabre can hit the same enemy again |
| `height` | 16 | Centre above the feet (px) |
| `follow_speed` | 12 | How tightly it follows the player |
| `snap_distance` | 64 | Farther than this from the player (px), the ring jumps to them (a room change) |

`WagonFort`:

| Value | Default | Effect |
|---|---|---|
| `radius` | 40 | Radius of the circle when open (px) |
| `open_time` | 0.3 | Seconds to open |
| `chest_height` | 16 | Height above the feet measured against the circle (px) |
| `fill` / `rim` | pale gold | Placeholder colours |

`Companion` (shared):

| Value | Default | Effect |
|---|---|---|
| `snap_distance` | 160 | Farther than this from its target (px), it jumps there |
| `fade_time` | 0.3 | Seconds to fade out when dismissed |

`SwornBrother`:

| Value | Default | Effect |
|---|---|---|
| `offset` | (-18, -6) | Where he floats from the player's feet, facing right (px) |
| `follow_speed` | 8 | How tightly he follows |
| `bob_height` / `bob_speed` | 2 / 3 | Floating bob |
| `strike_distance` | 36 | How far past the player the lunge ends (px) |
| `strike_time` / `strike_hold` | 0.18 / 0.08 | Seconds of the lunge, then with the cut still out |
| `guard_distance` | 14 | How far in front of the player he guards (px) |
| `guard_time` | 0.5 | Seconds the shield is up and the player warded |
| `cooldown` | 0.6 | Seconds after a strike or a guard before the next |

`FalconFlock`:

| Value | Default | Effect |
|---|---|---|
| `attack_range` | 160 | Enemies farther from the player than this are ignored (px) |
| `check_interval` | 0.6 | Seconds between looks for a target |
| `height` | 34 | Flock centre above the player's feet (px) |
| `follow_speed` | 7 | How tightly it follows |
| `spread` | 14 | Distance of each falcon from the centre (px) |
| `bob_height` / `bob_speed` | 2 / 4 | Hovering bob |

`Falcon`:

| Value | Default | Effect |
|---|---|---|
| `start_speed` / `max_speed` | 120 / 340 | Flight speed (px/s) |
| `acceleration` | 900 | Speed gained per second |
| `lifetime` | 1.5 | Seconds in flight before it gives up |
| `reach_distance` | 4 | How close to the target point counts as reaching it (px) |
| `fade_time` | 0.15 | Seconds to fade after striking |

`WanderingLight`:

| Value | Default | Effect |
|---|---|---|
| `offset` | (-14, -30) | Where it floats from the player's feet, facing right (px) |
| `follow_speed` | 5 | How tightly it follows the player |
| `seek_speed` | 120 | Speed drifting to a captive (px/s) |
| `hover_height` | 40 | Height above a captive's feet (px) |
| `notice_delay` | 2 | Seconds in a room before it looks for captives |
| `search_interval` | 0.5 | Seconds between looks while there is none |
| `wobble` / `wobble_speed` | (4, 2) / (1.3, 2.6) | Drifting wobble |

Attack scenes:

| Scene | Damage | Size (px) | Notes |
|---|---|---|---|
| `FirePillar` | 30 | 16 × 56 | FIRE, knocks up, on for 0.25 s |
| `ThunderBeam` | 70 | 28 × 200 | HEAVY, knocks up, shake 0.9, on for 0.3 s |
| `StunBurst` | 10 | 144 × 56 | LIGHT, `stuns`, shake 0.5, on for 0.2 s |
| `DumaShot` | 30 | 12 × 4 | 360 to 420 px/s, 0.6 s |
| `SabreRing` sabre | 15 | 10 × 10 | Three of them |
| `SwornBrother` sabre | 40 | 28 × 22 | HEAVY, knockback 160, destroys enemy shots |
| `Falcon` talons | 40 | 10 × 8 | One hit per falcon |

## Extending

- **A new duma:** create an `Item` `.tres` in `actors/player/items/dumas/` with `kind = DUMA`, a `spirit_cost`, a description that names the cost, a lore, and effects with `trigger = ON_USE`. Add it to `Inventory.all` on the player scene. A lasting duma needs a `duration` on its effects.
- **A new kind of effect:** extend `ItemEffect`, override `start()` (and `stop()` if it lasts). Override `can_start()` if the duma must not be sung in some situations. Scale any damage by `player.dumas.strength()`. Spawn attacks under `player.get_parent()`, as the other effects do.
- **A new companion:** a scene whose root has `follow(player)` and `dismiss()`; extend `Companion` for one that floats beside the player. Summon it with a `SummonEffect`. Put it on the `player_attacks` layer for hits, scale damage by `player.dumas.strength()`, and use `Hurtbox.set_ward()` with its own source name to protect the player (clear it in `_on_dismiss()` and `_exit_tree()`). It can end its duma early with `player.dumas.end()`.
- **A charm that changes dumas:** a `StatEffect` on `duma_cost`, `duma_duration` or `duma_strength`.

## Known limitations

- Placeholder rectangles for the Sworn Brother, the falcons and the wandering light, and a flat dome for the Wagon Fort. No animations or sounds.
- The Sworn Brother doesn't strike with the dive, the lunge or the ranged bolt; only the swings in `STRIKE_STATES`.
- Falcons fly straight at their target and pass through terrain once launched; only the launch checks the line of sight.
- Placeholder rectangles for the aura, pillars, beam, burst, shots and sabres. No singing sound.
- Hits from duma attacks don't fill spirit and don't set off `ON_HIT` item effects (they are spawned after the player is ready).
- Only Idle and Run can start a duma; a press during a swing or in the air is ignored without a flash.
- A duma that can't be sung right now (the Road Home in a boss fight) flashes the spirit bar like a lack of spirit; there is no message saying why.
