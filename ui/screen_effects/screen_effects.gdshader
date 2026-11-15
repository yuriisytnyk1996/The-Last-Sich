// Full-screen pass drawn over everything (see screen_effects.gd):
// an optional CRT filter, then the player's brightness setting.
// Runs at the 640x360 base resolution.
shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, filter_linear;

// Brightness option. Gamma, so dark areas lift more than bright ones.
uniform float gamma = 1.0;

uniform bool crt = false;
uniform float blur_size = 0.7;
uniform float blur_strength = 0.6;
uniform float bleeding_size = 0.75;
uniform float bleeding_strength = 0.5;
uniform float aberration = 1.25;
uniform float mask_strength = 0.35;
uniform float scanline_strength = 0.0;
uniform float interference = 0.0;
uniform float color_noise = 0.15;
uniform float white_noise = 0.25;
uniform float curvature = 0.6;
uniform float vignette_size = 0.35;
uniform float vignette_strength = 0.1;
uniform float brightness = 0.2;
uniform float contrast = 0.1;
uniform float saturation = -0.05;
uniform float darkest_level = 0.0;
uniform float brightest_level = 0.92;
uniform vec3 darkest_color = vec3(0.16);
uniform vec3 brightest_color = vec3(1.0);

float random(vec2 point) {
	return fract(sin(dot(point, vec2(12.9898, 78.233))) * 43758.5453);
}

// Bends the picture like the glass of a tube.
vec2 warp(vec2 uv) {
	vec2 centered = uv * 2.0 - 1.0;
	centered *= 1.0 + centered.yx * centered.yx * curvature * 0.12;
	return centered * 0.5 + 0.5;
}

vec3 sample_soft(vec2 uv, vec2 pixel) {
	vec2 split = vec2(aberration * pixel.x, 0.0);
	vec3 color = vec3(
		texture(screen_texture, uv + split).r,
		texture(screen_texture, uv).g,
		texture(screen_texture, uv - split).b
	);
	vec2 step = vec2(blur_size * pixel.x, 0.0);
	vec3 blurred = (texture(screen_texture, uv + step).rgb + texture(screen_texture, uv - step).rgb) * 0.5;
	color = mix(color, blurred, blur_strength * 0.5);
	vec3 smear = texture(screen_texture, uv - vec2(bleeding_size * pixel.x * 2.0, 0.0)).rgb;
	return mix(color, max(color, smear), bleeding_strength * 0.5);
}

vec3 grade(vec3 color) {
	color = (color - 0.5) * (1.0 + contrast) + 0.5 + brightness * 0.1;
	float luma = dot(color, vec3(0.299, 0.587, 0.114));
	color = mix(vec3(luma), color, 1.0 + saturation);
	vec3 level = clamp((color - darkest_level) / max(brightest_level - darkest_level, 0.001), 0.0, 1.0);
	return mix(darkest_color, brightest_color, level);
}

vec3 crt_color(vec2 screen_uv, vec2 pixel, vec2 frag) {
	vec2 uv = warp(screen_uv);
	if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0) {
		return vec3(0.0);
	}
	uv.x += sin(uv.y * 25.0 - TIME * 3.0) * interference * 0.1;
	vec3 color = grade(sample_soft(uv, pixel));
	vec2 cell = floor(frag);
	color *= 1.0 - mask_strength * 0.5 * mod(cell.x, 2.0);
	color *= 1.0 - scanline_strength * 0.5 * mod(cell.y, 2.0);
	float seed = fract(TIME * 7.13);
	color += (vec3(random(cell + seed), random(cell + seed + 1.7), random(cell + seed + 3.1)) - 0.5) * color_noise * 0.3;
	color += (random(cell * 1.3 + seed) - 0.5) * white_noise * 0.2;
	float edge = length(screen_uv - 0.5) * 1.414;
	color *= 1.0 - vignette_strength * smoothstep(1.0 - vignette_size, 1.0, edge);
	return color;
}

void fragment() {
	vec3 color;
	if (crt) {
		color = crt_color(SCREEN_UV, SCREEN_PIXEL_SIZE, FRAGCOORD.xy);
	} else {
		color = texture(screen_texture, SCREEN_UV).rgb;
	}
	COLOR = vec4(pow(max(color, vec3(0.0)), vec3(1.0 / gamma)), 1.0);
}
