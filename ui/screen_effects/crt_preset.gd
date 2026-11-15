class_name CrtPreset
extends Resource
## One look for the CRT filter (see `ScreenEffects`). Presets live in
## `ui/screen_effects/crt_presets/` and are listed in the video options
## in the order of `ScreenEffects.CRT_PRESETS`.
##
## Distances are in game pixels: the filter runs at the 640×360 base
## resolution, before the picture is scaled up to the screen.

@export var display_name := "CRT"

@export_group("Softness")
## Horizontal blur distance (px).
@export_range(0.0, 2.0) var blur_size := 0.7
## How much of the blurred picture is mixed in.
@export_range(0.0, 1.0) var blur_strength := 0.6
## How far colour smears to the right (px), like a weak video signal.
@export_range(0.0, 2.0) var bleeding_size := 0.75
@export_range(0.0, 1.0) var bleeding_strength := 0.5
## Red and blue split apart by this much (px).
@export_range(0.0, 3.0) var aberration := 1.25

@export_group("Lines")
## Darkens every other column, like the gaps of an aperture grille.
@export_range(0.0, 1.0) var mask_strength := 0.35
## Darkens every other row.
@export_range(0.0, 1.0) var scanline_strength := 0.0
## Rolling horizontal wobble.
@export_range(0.0, 0.1) var interference := 0.0

@export_group("Noise")
## Random colour speckle added every frame.
@export_range(0.0, 1.0) var color_noise := 0.15
## Grain: positive lightens, negative darkens.
@export_range(-1.0, 1.0) var white_noise := 0.25

@export_group("Tube")
## Bulge of the glass, 0 is flat.
@export_range(0.0, 1.0) var curvature := 0.6
@export_range(0.0, 1.0) var vignette_size := 0.35
@export_range(0.0, 1.0) var vignette_strength := 0.1

@export_group("Colour")
@export_range(-1.0, 1.0) var brightness := 0.2
@export_range(-1.0, 1.0) var contrast := 0.1
## -1 is black and white.
@export_range(-1.0, 1.0) var saturation := -0.05
## Input levels: values at or below `darkest_level` become `darkest_color`,
## values at or above `brightest_level` become `brightest_color`.
@export_range(0.0, 1.0) var darkest_level := 0.0
@export_range(0.0, 1.0) var brightest_level := 0.92
@export var darkest_color := Color(0.08, 0.08, 0.08)
@export var brightest_color := Color.WHITE


## Pushes every value into the screen effects shader.
func apply_to(material: ShaderMaterial) -> void:
	for property: String in [
		"blur_size",
		"blur_strength",
		"bleeding_size",
		"bleeding_strength",
		"aberration",
		"mask_strength",
		"scanline_strength",
		"interference",
		"color_noise",
		"white_noise",
		"curvature",
		"vignette_size",
		"vignette_strength",
		"brightness",
		"contrast",
		"saturation",
		"darkest_level",
		"brightest_level",
	]:
		material.set_shader_parameter(property, get(property))
	material.set_shader_parameter(
		"darkest_color", Vector3(darkest_color.r, darkest_color.g, darkest_color.b)
	)
	material.set_shader_parameter(
		"brightest_color", Vector3(brightest_color.r, brightest_color.g, brightest_color.b)
	)
