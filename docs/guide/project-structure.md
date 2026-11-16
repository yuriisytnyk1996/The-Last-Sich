# Project structure

```
The-Last-Sich/
├── project.godot                 Engine settings, input map, autoloads, physics layers, version
├── CLAUDE.md                     Rules for AI-assisted work (docs, commits)
├── CHANGELOG.md                  Generated on release from commit messages
├── package.json                  Tooling: docs site, commit linting, releases (pnpm)
├── commitlint.config.ts          Commit message rules
├── lefthook.yml                  Git hooks
├── eslint.config.ts              Lint rules for the JS/TS tooling
├── mise.toml                     Pinned tool versions (Node, pnpm, gdtoolkit)
├── pnpm-workspace.yaml           pnpm settings (allowed install scripts)
├── .versionrc.json               Release and changelog settings
├── default_bus_layout.tres       Audio buses: Master, Music, Effects, Voice
├── autoload/
│   ├── events.gd                 Global signal bus (autoload "Events")
│   ├── display_settings.gd       Video options: window, scaling, VSync, textures, brightness, CRT (autoload "DisplaySettings")
│   ├── audio_settings.gd         Bus volumes (autoload "AudioSettings")
│   ├── accessibility_settings.gd Screen shake and rumble toggles (autoload "AccessibilitySettings")
│   ├── input_settings.gd         Key and button rebinding (autoload "InputSettings")
│   ├── rumble.gd                 Gamepad vibration (autoload "Rumble")
│   ├── hit_stop.gd               Short game freeze on hits (autoload "HitStop")
│   └── save_manager.gd           Save snapshot, load and save, room state (autoload "SaveManager")
├── components/
│   ├── state_machine/
│   │   ├── state_machine.gd      Generic finite state machine
│   │   └── state.gd              Base class for one state
│   ├── camera/
│   │   └── camera_shake.gd       Trauma-based shake for a Camera2D
│   ├── interaction/
│   │   └── interaction_area.gd   Touch or interact area, base for exits and doors
│   ├── save/
│   │   ├── save_file.gd          JSON save slot with safe writes and a backup
│   │   └── settings_file.gd      One section of user://settings.cfg per settings autoload
│   ├── display/
│   │   └── resolution_list.gd    Window sizes that fit the screen
│   ├── stats/
│   │   ├── stats.gd              Named stats with modifiers by source
│   │   └── stat_modifier.gd      One flat or percent change to a stat (resource)
│   └── combat/
│       ├── hitbox.gd             Deals damage while active
│       ├── hurtbox.gd            Detects hitboxes, reports hits, invincibility
│       ├── health.gd             Hit points, damaged and died signals
│       ├── invincibility_blink.gd   Blinks a visual while a hurtbox is invincible
│       └── hurt_feedback.gd      Flash, hit-stop and shake on every hit
├── actors/
│   ├── player/
│   │   ├── player.tscn           Player scene
│   │   ├── player.gd             Tuning values and shared helpers
│   │   ├── player_damage.gd      Hit reactions, hurt and death tuning
│   │   ├── player_stats.gd       Player stats: health, flasks, damage, resistances, spirit, timing
│   │   ├── abilities/            Movement, healing, spirit and currency pieces with their own tuning
│   │   │   ├── drop_through.gd   Down + jump through one-way platforms
│   │   │   ├── ladder_climb.gd   Finds ladders to grab, climbing tuning
│   │   │   ├── ledge_grab.gd     Finds ledges to grab, hang and climb tuning
│   │   │   ├── flasks.gd         Healing flask charges (count and heal from stats)
│   │   │   ├── wallet.gd         Currency the player carries, spent on skills, saved
│   │   │   ├── skills.gd         Learned skills and the rules for learning them, saved
│   │   │   ├── safe_ground.gd    Remembers the last safe spot, where death marks are left
│   │   │   ├── spirit.gd         Spirit, filled by landing hits
│   │   │   ├── area_effects.gd   Combines the wind and mud zones the player is in
│   │   │   └── parry.gd          Parry and riposte tuning (windows from stats)
│   │   ├── skills/               Upgrades learned at skill shrines
│   │   │   ├── player_skill.gd   Skill resource: id, text, tier, cost, parent
│   │   │   ├── combo/            combo_1/2/3.tres: the combo finishers
│   │   │   ├── charged/          charged_1/2/3.tres, charged_attack.gd
│   │   │   ├── lunge/            lunge_1/2/3.tres, lunge_attack.gd
│   │   │   ├── dive/             dive_1/2/3.tres, dive_attack.gd
│   │   │   └── ranged/           ranged_1/2/3.tres, ranged_attack.gd
│   │   ├── attacks/              Projectiles and blasts
│   │   │   ├── player_projectile.gd   Flying hitbox: bolt and wave
│   │   │   ├── player_blast.gd   One-off hitbox: burst and shockwave
│   │   │   └── *.tscn            ranged_bolt, charged_wave, bolt_burst, dive_shockwave
│   │   └── states/               One script per player state
│   │       ├── player_state.gd   Base class for player states
│   │       ├── idle.gd
│   │       ├── run.gd
│   │       ├── jump.gd
│   │       ├── fall.gd
│   │       ├── dash.gd
│   │       ├── climb.gd          On a ladder
│   │       ├── ledge_hang.gd     Hanging from a ledge
│   │       ├── ledge_climb.gd    Pulling up onto a ledge
│   │       ├── hard_landing.gd   Stuck in place after a long fall
│   │       ├── heal.gd           Drinking a healing flask
│   │       ├── parry.gd          Guard up, deflects parryable hits
│   │       ├── hurt.gd           Knockback after a hit
│   │       ├── dead.gd           Health ran out, waits, then asks for a respawn
│   │       ├── attacks/          One script per attack
│   │       │   ├── player_attack_state.gd   Shared swing timing, combo and charge hooks
│   │       │   ├── side_attack.gd   Also chains the ground combo
│   │       │   ├── up_attack.gd
│   │       │   ├── crouch_attack.gd
│   │       │   ├── riposte.gd    Counter-attack after a parry
│   │       │   ├── combo_strike.gd   Heavy combo swing with its own timing
│   │       │   └── combo_heavy.gd    End of the ground combo, picks the finisher
│   │       └── skills/           States of the skill attacks
│   │           ├── charge.gd     Charging the charged slash
│   │           ├── charged_slash.gd
│   │           ├── lunge.gd      Thrust out of a dash
│   │           ├── dive.gd       Hang, plunge, land
│   │           └── ranged.gd     Throwing the spirit bolt
│   ├── enemies/
│   │   ├── enemy.gd              Shared enemy base: tuning, movement and sensing helpers
│   │   ├── enemy_damage.gd       Enemy hit reactions, hurt and death tuning
│   │   ├── enemy_stats.gd        Enemy stats: health, damage multiplier, resistances
│   │   ├── enemy_state.gd        Base class for enemy states
│   │   ├── attacks/
│   │   │   └── enemy_projectile.gd   Shared flying shot: straight line, ends on a hit or a wall
│   │   ├── states/               States shared by every enemy
│   │   │   ├── patrol.gd
│   │   │   ├── chase.gd
│   │   │   ├── hurt.gd
│   │   │   ├── stunned.gd        Helpless after a parried attack
│   │   │   ├── dead.gd
│   │   │   └── enemy_attack_state.gd   Shared telegraphed attack timing
│   │   ├── raider/
│   │   │   ├── raider.tscn       Melee grunt
│   │   │   └── states/
│   │   │       └── saber_slash.gd   Lunging forward cut
│   │   └── musketeer/
│   │       ├── musketeer.tscn    Ranged enemy that stands and shoots
│   │       ├── musket_ball.tscn  The shot
│   │       └── states/
│   │           ├── hold_range.gd      Its Chase: close in, stand and fire
│   │           └── musket_shot.gd     Aim, fire, reload
│   └── training_dummy/
│       ├── training_dummy.tscn   Stationary target for testing attacks
│       └── training_dummy.gd     Hit reaction, break and rebuild
├── levels/
│   ├── world.tscn                Gameplay scene: player, HUD, world map, screen fade, pause menu and the current room
│   ├── world.gd                  Loads rooms, runs room transitions, respawns at rest points, loads the save
│   ├── room.gd                   Base room logic: camera bounds, pits, respawning in the room
│   ├── killed_enemies.gd         Keeps killed enemies dead across rooms until the player rests or dies
│   ├── death_penalty.gd          Death marks: leaves them on death, applies the penalty, recovers them, saved
│   ├── death_mark_list.gd        The marks and their links, as plain data
│   ├── map/
│   │   ├── world_map.gd          World map data: scans rooms, reveals cells as the player walks, saved
│   │   └── map_room.gd           One room on the map: cells, doors, marks
│   ├── objects/                  Things placed in rooms
│   │   ├── room_exit.gd          Edge exit or door to another room
│   │   ├── door.tscn             Door entered by pressing interact
│   │   ├── rest_point.gd         Checkpoint: heal, reset enemies, set the respawn
│   │   ├── rest_point.tscn       Rest point scene
│   │   ├── death_mark.gd         A death mark, recovered with interact
│   │   ├── death_mark.tscn       Its scene
│   │   ├── skill_shrine.gd       Opens the skill menu with interact
│   │   ├── skill_shrine.tscn     Skill shrine scene
│   │   ├── tier_relic.gd         Raises the skill tier once when touched
│   │   ├── tier_relic.tscn       Its scene
│   │   ├── spikes.gd             Instant death when stepped in
│   │   ├── ladder.gd             Climbable ladder
│   │   ├── breakables/           Breakable crate and cracked wall (breakable.gd, crate.tscn, breakable_wall.tscn)
│   │   ├── platforms/            Moving platform, elevator and its call lever
│   │   ├── traps/                Timed spike and fire traps, turret and its bolt
│   │   └── zones/                Wind, mud and poison zones on the AreaEffect base
│   ├── rooms/
│   │   ├── test_room.tscn        Test level (start room): a Room with Deco, Layout and Logic
│   │   ├── test_room/            Its parts: deco.tscn, layout.tscn, logic.tscn
│   │   ├── test_cave.tscn        Second test room, east of the test room
│   │   ├── test_cave/            Its parts
│   │   ├── test_house.tscn       Small room behind the test room's door
│   │   ├── test_house/           Its parts
│   │   ├── test_shaft.tscn       Tall room under the test cave, reached through a hole
│   │   ├── test_shaft/           Its parts
│   │   ├── test_works.tscn       Two-floor room east of the test cave with every environment piece
│   │   └── test_works/           Its parts
│   ├── terrain/
│   │   ├── terrain.tres          Shared tileset: solid and one-way tiles on the world layer
│   │   └── terrain_tiles.png     Placeholder tile texture (16×16 tiles)
├── ui/
│   ├── version_label.gd          On-screen game version
│   ├── screen_fade.gd            Black fade for room transitions
│   ├── screen_effects/
│   │   ├── screen_effects.gd     Full-screen brightness and CRT pass (owned by DisplaySettings)
│   │   ├── screen_effects.gdshader
│   │   ├── crt_preset.gd         One CRT look
│   │   └── crt_presets/          The 10 CRT presets (.tres)
│   ├── menus/
│   │   ├── menu.gd               Stack of menu screens, back, focus recovery
│   │   ├── menu_screen.gd        Base page with row helpers
│   │   ├── option_row.gd         Left/right value row
│   │   ├── confirm_screen.gd     Yes/no question
│   │   ├── pausing_menu.gd       Menu that pauses the game while open
│   │   ├── menu_theme.tres       Menu fonts, colours, focus marker
│   │   ├── main_menu/
│   │   │   ├── main_menu.tscn    Main scene: the title screen
│   │   │   ├── main_menu.gd
│   │   │   └── title_screen.gd   Continue, New game, Options, Quit
│   │   ├── pause/
│   │   │   ├── pause_menu.gd     The pause menu, a pausing menu
│   │   │   └── pause_screen.gd   Resume, Map, Options, Quit to main menu
│   │   ├── map/
│   │   │   ├── map_screen.gd     Map page: zone name, map view, legend
│   │   │   ├── map_view.gd       Draws the map, pans and zooms
│   │   │   └── map_cell_painter.gd One cell's fill, walls and door gaps
│   │   ├── skills/
│   │   │   └── skills_screen.gd  Skill shrine page: list, description, learn
│   │   └── options/
│   │       ├── options_screen.gd Options hub
│   │       ├── video_options.gd
│   │       ├── audio_options.gd
│   │       ├── accessibility_options.gd
│   │       ├── controls_options.gd   Rebinding page
│   │       └── binding_button.gd     One key or button binding
│   ├── hud/
│   │   ├── hud.tscn              Gameplay HUD layer, instanced in the world scene
│   │   ├── health_bar.gd         Player health bar
│   │   ├── flask_counter.gd      Player healing flask pips
│   │   ├── currency_counter.gd   Currency the player carries
│   │   ├── spirit_bar.gd         Spirit, with the part locked by death marks
│   │   └── death_mark_counter.gd One pip per death mark
│   └── debug/
│       └── debug_label.gd        On-screen state readout
├── tools/
│   ├── check_file_sizes.sh       Enforces file size limits
│   └── release/
│       └── godot-version-updater.ts   Bumps the version in project.godot
└── docs/                         This site (VitePress)
```

See [Code organization](/guide/code-organization) for the rules behind this layout and the planned folders.

## Folder rules

| Folder | What goes in it |
|---|---|
| `autoload/` | Global singletons registered in **Project Settings → Globals → Autoload**. Keep them few and small. |
| `components/` | Reusable building blocks with no knowledge of specific actors (state machine, hitboxes, hurtboxes, health, stats). |
| `actors/` | Anything that moves and acts: the player, enemies, bosses, NPCs. One folder per actor, with its scene, script and states. |
| `levels/` | Rooms and level-specific scripts. |
| `ui/` | Menus, HUD and debug overlays. |
| `tools/` | Developer scripts that are not part of the game. |
| `docs/` | Documentation only. Ignored by Godot. |

Planned folders as the game grows: `assets/` (sprites, audio, fonts), `resources/` (data `.tres` files such as enemy stats), `actors/bosses/`.
