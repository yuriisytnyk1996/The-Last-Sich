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
| Window size (desktop) | 1280×720 | Comfortable default window |
| Stretch mode | `viewport` | Renders at 640×360 and scales the result up, so every pixel stays a square |
| Scale mode | `integer` | Only whole-number scaling, no uneven pixels |
| Aspect | `expand` | Wider screens (phones, ultrawide) show more of the level instead of black bars |
| Orientation (mobile) | Sensor landscape | Landscape, follows how the device is held |

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
