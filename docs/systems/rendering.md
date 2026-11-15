# Rendering & pixel art

## Target platforms and renderers

The game targets **desktop and mobile**. Godot allows a different renderer per platform:

| Platform | Renderer | Setting |
|---|---|---|
| Windows, macOS, Linux | **Forward+** | `rendering/renderer/rendering_method` |
| Android, iOS | **Mobile** | `rendering/renderer/rendering_method.mobile` |

Both support **2D HDR** (`rendering/viewport/hdr_2d = true`), which allows light values brighter than white and strong bloom, so glowing effects look the same on both. Compatibility, the third renderer, was not chosen because it lacks 2D HDR. It is needed only for web exports.

::: warning
The Mobile renderer needs Vulkan or Metal. Older Android devices may fall back to Compatibility, where HDR-dependent lighting looks flatter.
:::

## Resolution and scaling

| Setting | Value | Why |
|---|---|---|
| Base resolution | 640×360 | Scales evenly to 720p (×2), 1080p (×3), 1440p (×4) and 4K (×6) |
| Window mode (desktop) | Fullscreen on first launch | Uses the desktop resolution. Players toggle it with F11 / Alt+Enter, and the choice is saved |
| Window size (desktop, windowed) | 1280×720 | Exactly 2×, so windowed mode has no bars |
| Stretch mode | `viewport` | Renders at 640×360 and scales the result up, so every pixel stays a square |
| Scale mode | `integer` (default) | Only whole-number scaling, no uneven pixels. Players can switch it, see below |
| Aspect | `expand` | Wider screens (phones, ultrawide) show more of the level instead of black bars |
| Orientation (mobile) | Sensor landscape | Landscape, follows how the device is held |

## Display settings (player options)

`autoload/display_settings.gd` (autoload `DisplaySettings`) owns the player-facing display options: fullscreen, window resolution, scaling mode, VSync, texture filtering, brightness and the CRT filter. The player changes them in **Options → Video**. They are saved in the `[display]` section of `user://settings.cfg`. See [Options](/systems/options#video) for the full list.

### Fullscreen

- Fullscreen uses the desktop resolution. Windowed mode uses the chosen resolution (1280×720 by default).
- **F11** or **Alt+Enter** (input action `toggle_fullscreen`) switch modes in every build, because players expect these keys.
- The toggle reads the real window state, so leaving fullscreen through the OS (for example the green button on macOS) doesn't confuse it.
- Skipped on phones, which are always fullscreen, and in the editor's embedded Game view, where the editor owns the window. Press F11 there and the choice is still saved, but it only takes effect in a separate window or an exported build.

### Scaling mode

The base resolution only scales evenly when the screen is an exact multiple of 640×360. Common monitors are (1080p is 3×, 1440p is 4×, 4K is 6×), but some laptops and resized windows are not. The player picks:

| Mode | Stretch | Result |
|---|---|---|
| `PIXEL_PERFECT` (default) | `integer` | Largest whole-number scale that fits. Sharp, even pixels, black bars around the picture |
| `SCALE` | `fractional` | Fills the screen. No bars, but some pixels are one screen pixel wider than others |

The video options only show this row when the picture is not a whole multiple of 640×360, because otherwise both modes look the same.

::: tip Small picture in the editor
The editor's embedded Game view is slightly smaller than 1280×720 (for example 1278×719). In `PIXEL_PERFECT`, that drops to 1× scale. Switch to **Fill screen** in Options → Video, or run the game in its own window.
:::

### How it works

1. On start, `DisplaySettings` loads its section of `user://settings.cfg`. Missing values use the defaults.
2. It sets `get_tree().root.content_scale_stretch`, the texture filter, VSync and the [screen effects](/systems/options#screen-effects-brightness-and-crt), then the window mode and size. Godot re-fits the picture whenever the window size changes.
3. Each setter applies, saves and sends `changed`.

## Keeping pixels crisp

| Setting | Value | Why |
|---|---|---|
| Default texture filter | Nearest | No blurring when sprites are scaled |
| Snap 2D transforms to pixel | On | Sprites and camera land on whole pixels, no jitter |
| Snap 2D vertices to pixel | On | Same for polygons and lines |

## Asset guidelines

- Draw at 1× for the 640×360 base resolution. The player is about 12×30 px.
- Never scale sprites by non-integer amounts in the editor.
- Import PNGs with no mipmaps. The default filter is already Nearest.
