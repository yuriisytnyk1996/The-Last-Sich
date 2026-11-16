# Menus

The main menu, the pause menu and every options page are built from the same small set of pieces: a `Menu` that holds a stack of `MenuScreen` pages, and rows that work the same with keyboard, gamepad and mouse.

## How it works

### Flow

```
main_menu.tscn (main scene)
└── Menu ── TitleScreen ── Continue / New game ──► world.tscn
                        └─ Options ──► OptionsScreen ──► Video / Audio / Accessibility / Controls

world.tscn
└── PauseMenu (Escape / Start) ── PauseScreen ── Resume
                                            ├─ Options ──► (same OptionsScreen)
                                            └─ Quit to main menu ──► main_menu.tscn
└── SkillShrine (interact) ── PausingMenu ── SkillsScreen ── learn a skill (see Skills)
```

1. The game starts in `ui/menus/main_menu/main_menu.tscn`. **Continue** only shows when a save exists. **New game** asks first when there is a save, then deletes it. Both switch to `levels/world.tscn`, which loads the save as before (see [Save system](/systems/save-system)).
2. In the world, the `pause` action opens the `PauseMenu`. `World._unhandled_input()` opens it, and the world doesn't run while the tree is paused, so the menu can't open during a room transition or on top of itself.
3. The pause menu pauses the tree (it is a `PausingMenu`, like the skill shrine's menu). Closing it (Resume, back on the first page, or `pause` again from any page) unpauses one frame later, so the press that closed it isn't also read as a jump or an attack.
4. **Quit to main menu** asks first, because the game only saves at rest points: the next Continue starts from the last rest point.

### Menu and screens

- `Menu` (`ui/menus/menu.gd`) is a `CanvasLayer` with a tinted background and a stack of screens. `push()` opens a page, `pop()` goes back, `close()` pops everything and sends `closed`. It runs with `PROCESS_MODE_ALWAYS`, so it works while the game is paused.
- Back (`ui_cancel`: Escape / B) calls the top screen's `go_back()`. The title screen overrides it to do nothing. The pause screen keeps the default, so back on its first page resumes.
- Each page remembers which row had focus when another page opened over it, and gets it back on return. If the mouse clicks empty space and focus is lost, the next arrow press focuses the first row again.
- `MenuScreen` (`ui/menus/menu_screen.gd`) is a column. Subclasses add rows in `_build()` with `add_title`, `add_text`, `add_button`, `add_option` and `add_gap`.
- `OptionRow` (`ui/menus/option_row.gd`) is a button with a name on the left and `< value >` on the right. Left and right step through the values, and accept steps forward. Clicking the left half of the value (the `<` arrow) steps back, clicking anywhere else steps forward. Mouse presses are handled in `_gui_input()` rather than through `pressed`, which can't tell where the click landed and drops fast repeat clicks. On/off and lists wrap around. Ranges such as volume stop at the ends.
- `ConfirmScreen` (`ui/menus/confirm_screen.gd`) asks a yes/no question. **No** is focused first.

### Look

`ui/menus/menu_theme.tres` sets the font size (10 px at the 640×360 base resolution), the colours, and the focus marker: a gold bar on the left with a faint highlight. `TitleLabel` and `HeaderLabel` are type variations for page titles and column headers.

## Files

| File | Role |
|---|---|
| `ui/menus/menu.gd` | `Menu`: screen stack, back, focus recovery |
| `ui/menus/menu_screen.gd` | `MenuScreen`: base page with row helpers |
| `ui/menus/option_row.gd` | `OptionRow`: left/right value row |
| `ui/menus/confirm_screen.gd` | `ConfirmScreen`: yes/no question |
| `ui/menus/menu_theme.tres` | Menu theme |
| `ui/menus/main_menu/main_menu.tscn`, `main_menu.gd` | Main scene: background, version label, the title screen |
| `ui/menus/main_menu/title_screen.gd` | `TitleScreen`: Continue, New game, Options, Quit |
| `ui/menus/pausing_menu.gd` | `PausingMenu`: a menu that pauses the tree while open and unpauses a frame after closing; can free itself on close |
| `ui/menus/pause/pause_menu.gd` | `PauseMenu`: a `PausingMenu` that opens the pause screen and closes on `pause` |
| `ui/menus/skills/skills_screen.gd` | `SkillsScreen`: the skill shrine's page, see [Skills](/systems/skills) |
| `ui/menus/pause/pause_screen.gd` | `PauseScreen`: Resume, Options, Quit to main menu |
| `ui/menus/options/` | The options pages, see [Options](/systems/options) |

## Tuning

| Value | Default | Effect |
|---|---|---|
| `Menu.background` | (0.03, 0.02, 0.05, 0.8) | Tint behind the pages. The pause menu lets the game show through |
| `MainMenu.background` | (0.06, 0.05, 0.08, 1) | Solid colour behind the title screen |

## Extending

**A new page:**

```gdscript
class_name ExtrasScreen
extends MenuScreen


func _build() -> void:
	add_title("Extras")
	add_option("Speedrun timer", ON_OFF, 0, func(i: int) -> void: print(i == 1))
	add_gap()
	add_button("Back", go_back)
```

Open it from another page with `menu.push(ExtrasScreen.new())`.

**Another menu** (a shop, a map screen): instance a `Menu` and `push()` its first page. For an in-game menu that pauses the game, instance a `PausingMenu` and call `open_screen()`; set `free_on_close` when it is made on the spot, as `SkillShrine` does.

## Known limitations

- The default engine font stands in for a pixel font, and there is no menu art, sound or animation yet.
- There is no single save slot picker. The game has one slot (`SaveManager.slot`).
- No touch controls yet. On phones the menus work with taps, since every row is a button.
