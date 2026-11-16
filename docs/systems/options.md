# Options

Player options for video, audio, accessibility and controls. Each group is owned by its own autoload, which applies changes at once and saves them in its own section of `user://settings.cfg`. The pages in `ui/menus/options/` only read and call those autoloads.

## How it works

1. On start, each settings autoload reads its section through `SettingsFile.load_section()` and applies it. Missing or invalid values fall back to the defaults below.
2. A menu row calls a setter such as `DisplaySettings.set_brightness(120)`. The setter applies the change, writes its section with `SettingsFile.save_section()`, and sends its `changed` signal.
3. Pages that can go out of step listen to `changed`. The video page refreshes when F11 toggles fullscreen.

There is no "apply" or "cancel" step. Every change is visible straight away, which is easier to judge, and nothing is lost if the game closes.

`settings.cfg` is kept apart from the save slots, so **New game** and the debug save reset (F8) never touch options.

## Video

`autoload/display_settings.gd` (`DisplaySettings`). See [Rendering](/systems/rendering) for how the 640×360 picture is scaled.

| Option | Values | Default | Effect |
|---|---|---|---|
| Fullscreen | On / Off | On | Fullscreen at the desktop resolution. F11 and Alt+Enter toggle it too |
| Resolution | Sizes that fit the screen | 1280×720 | Window size in windowed mode. Hidden in fullscreen |
| Scaling | Pixel perfect / Fill screen | Pixel perfect | Only shown when the picture is not a whole multiple of 640×360, because otherwise both look the same |
| VSync | On / Off | On | `DisplayServer.window_set_vsync_mode()` |
| Textures | Sharp / Smooth | Sharp | The root viewport's default texture filter (nearest or linear). Smooth softens scaled or rotated sprites |
| Brightness | 50% to 150% in steps of 10 | 100% | Gamma: above 100% lifts dark areas more than bright ones |
| CRT filter | Off and 10 presets | Off | See below |

**Resolution list.** Godot can't list a monitor's display modes, so `ResolutionList` (`components/display/resolution_list.gd`) offers the common 16:9 and 16:10 sizes from 640×360 up to the screen size, plus the screen's own size. The window is centred on the screen's usable area when it changes. Fullscreen always uses the desktop resolution: Godot fullscreen doesn't change the monitor's mode.

Window rows are skipped on phones (always fullscreen) and in the editor's embedded Game view, where the editor owns the window.

### Screen effects (brightness and CRT)

`ui/screen_effects/screen_effects.gd` (`ScreenEffects`) is a `CanvasLayer` on layer 128, above everything including menus. `DisplaySettings` owns it. It draws a full-screen rect with `screen_effects.gdshader`, which reads the finished frame and draws it back:

1. If a CRT preset is on: curve the picture like tube glass, split red and blue apart, blur and smear colour sideways, grade it (contrast, brightness, saturation, then map dark and light levels to two colours), darken every other column and/or row, add noise and a rolling wobble, then a vignette.
2. Always: apply the brightness gamma.

When brightness is 100% and the filter is off, the layer hides, so the default costs nothing.

Each preset is a `CrtPreset` resource (`ui/screen_effects/crt_preset.gd`) in `ui/screen_effects/crt_presets/`:

| Preset | Look |
|---|---|
| Soft CRT | Gentle curve, light grille, a little colour bleed |
| Living room TV | Flatter and cleaner than Soft CRT |
| Small CRT | Strong curve, heavy grille and vignette |
| Colour TV | Warm and saturated, strong vignette |
| Old TV | Heavy blur and bleed, dark grain, rolling wobble |
| Sharp monitor | Flat, light grille, almost no softness |
| Arcade | Flat with strong scanlines |
| Broken black & white | No colour, heavy noise and wobble |
| Green terminal | Green phosphor with scanlines |
| Amber terminal | Amber phosphor with scanlines |

The filter runs at the 640×360 base resolution, so grille and scanlines are one game pixel wide.

## Audio

`autoload/audio_settings.gd` (`AudioSettings`). Buses are defined in `default_bus_layout.tres`:

| Bus | Feeds | Default | Used for |
|---|---|---|---|
| Master | output | 100% | Everything |
| Music | Master | 100% | Music |
| Effects | Master | 100% | Sound effects |
| Voice | Master | 100% | Spoken lines |

Volumes go from 0% to 100% in steps of 10 and are set with `AudioServer.set_bus_volume_linear()`. 0% mutes the bus. A sound picks its bus with `AudioStreamPlayer.bus`.

## Accessibility

`autoload/accessibility_settings.gd` (`AccessibilitySettings`).

| Option | Default | Effect |
|---|---|---|
| Screen shake | On | Off: `CameraShake.add_trauma()` ignores every request |
| Rumble | On | Off: `Rumble.play()` does nothing. Turning it on gives a short buzz |

`autoload/rumble.gd` (`Rumble`) vibrates every connected gamepad. `HurtFeedback` asks for rumble on every accepted hit, see [Game feel](/systems/game-feel#rumble).

## Controls

`autoload/input_settings.gd` (`InputSettings`). The page has one row per gameplay action, with a **Keyboard** column and a **Gamepad** column.

1. Press a binding, then press the new key or gamepad button.
2. Escape, Start, a mouse click or a press on the other device cancels.
3. If another action already uses that key or button, the two actions **swap**, so no action is ever left unbound by accident.
4. **Reset to defaults** (after a confirmation) reloads the bindings from `project.godot` and removes the `[controls]` section.

Only the key and button events change. Stick directions on the move actions stay fixed. Reserved, and never bound to an action: Escape (back and pause), F11 (fullscreen), F8 (debug save reset), F9 (debug unlock all skills) and Start (pause).

Keys are stored as **physical** keycodes, like the defaults. The page shows each key as it is labelled on the player's layout.

## Files

| File | Role |
|---|---|
| `components/save/settings_file.gd` | `SettingsFile`: read, write and erase one section of `user://settings.cfg` |
| `components/display/resolution_list.gd` | `ResolutionList`: window sizes that fit the screen, whether scaling mode matters |
| `autoload/display_settings.gd` | `DisplaySettings`: window, scaling, VSync, textures, brightness, CRT |
| `autoload/audio_settings.gd` | `AudioSettings`: bus volumes |
| `autoload/accessibility_settings.gd` | `AccessibilitySettings`: screen shake, rumble |
| `autoload/rumble.gd` | `Rumble`: gamepad vibration |
| `autoload/input_settings.gd` | `InputSettings`: key and button bindings |
| `default_bus_layout.tres` | Master, Music, Effects and Voice buses |
| `ui/screen_effects/` | `ScreenEffects`, its shader, `CrtPreset` and the presets |
| `ui/menus/options/` | The options pages, `BindingButton` |

## Extending

**A new option:**

1. Add the value, a setter and save/load lines to the autoload that owns that area (or a new `*_settings.gd` autoload with its own section).
2. Make the setter apply the value, save, and emit `changed`.
3. Add a row in the matching page with `add_option()`.
4. Add it to the tables above.

**A new CRT preset:** duplicate a `.tres` in `ui/screen_effects/crt_presets/`, tune it in the Inspector, and add it to `ScreenEffects.CRT_PRESETS`. Saved settings store the preset's index, so add new presets at the end.

**A new rebindable action:** add it to `InputSettings.ACTIONS` and give it a label in `ControlsOptions.LABELS`. It needs exactly one key and one gamepad button in `project.godot`.

## Known limitations

- No text or audio language options yet: the game has no translations or voice lines.
- The CRT filter works at game resolution, not screen resolution, so it can't draw sub-pixel scanlines or a fine RGB mask.
- The window can't go above the screen's usable area, so the largest windowed size may be a little smaller than the screen.
- Gamepad buttons are named by their Xbox layout (A, B, X, Y, LB, RB).
