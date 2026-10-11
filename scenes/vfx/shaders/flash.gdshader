// Camera-facing glow for muzzle flashes, impacts and explosions: a hot core, a soft halo
// and a few rays. Driven by the `progress` instance uniform (VfxBurst), 0 -> 1.
shader_type spatial;
render_mode blend_add, unshaded, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;

uniform vec4 color : source_color = vec4(1.0, 0.75, 0.35, 1.0);
uniform vec4 core_color : source_color = vec4(1.0, 0.97, 0.85, 1.0);
uniform float energy : hint_range(0.0, 10.0) = 2.5;
// Part of the lifetime spent expanding; the rest fades out.
uniform float grow_time : hint_range(0.01, 1.0) = 0.15;
// Fully faded at this point of the lifetime (lets lights or smoke outlast the flash).
uniform float fade_end : hint_range(0.05, 1.0) = 1.0;
uniform float start_scale : hint_range(0.0, 1.0) = 0.35;
uniform float core_size : hint_range(0.0, 1.0) = 0.3;
uniform float halo_softness : hint_range(0.5, 8.0) = 2.2;
uniform float ray_count : hint_range(0.0, 16.0, 1.0) = 6.0;
uniform float ray_strength : hint_range(0.0, 2.0) = 0.6;
uniform float ray_sharpness : hint_range(1.0, 64.0) = 12.0;

instance uniform float progress = 0.0;
instance uniform float seed = 0.0;

void vertex() {
	// Billboard that keeps the node's scale.
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(
			INV_VIEW_MATRIX[0] * length(MODEL_MATRIX[0].xyz),
			INV_VIEW_MATRIX[1] * length(MODEL_MATRIX[1].xyz),
			INV_VIEW_MATRIX[2] * length(MODEL_MATRIX[2].xyz),
			MODEL_MATRIX[3]);
}

void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float grow = smoothstep(0.0, grow_time, progress);
	float d = length(p) / mix(start_scale, 1.0, grow);
	float falloff = clamp(1.0 - d, 0.0, 1.0);
	float halo = pow(falloff, halo_softness);
	float angle = atan(p.y, p.x) + seed;
	float rays = pow(abs(cos(angle * ray_count * 0.5)), ray_sharpness) * ray_strength * falloff;
	float core = smoothstep(core_size, 0.0, d);
	float fade = 1.0 - smoothstep(grow_time, max(fade_end, grow_time + 0.01), progress);
	ALBEDO = (color.rgb * (halo + rays) + core_color.rgb * core) * energy * fade;
}
