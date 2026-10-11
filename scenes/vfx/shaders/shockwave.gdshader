// Expanding ring on the ground (use on a PlaneMesh) for explosions and frost bursts.
// Driven by the `progress` instance uniform (VfxBurst), 0 -> 1.
shader_type spatial;
render_mode blend_add, unshaded, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;

uniform vec4 color : source_color = vec4(1.0, 0.6, 0.25, 1.0);
uniform float energy : hint_range(0.0, 10.0) = 1.5;
uniform float thickness : hint_range(0.01, 0.5) = 0.12;
uniform float start_radius : hint_range(0.0, 1.0) = 0.1;
// Higher = ring races out early and slows down.
uniform float ease_out : hint_range(1.0, 8.0) = 3.0;
// Fill inside the ring (scorch glow), fraction of the ring brightness.
uniform float inner_glow : hint_range(0.0, 1.0) = 0.25;
uniform sampler2D noise : hint_default_white, repeat_enable;
uniform float noise_strength : hint_range(0.0, 1.0) = 0.4;

instance uniform float progress = 0.0;
instance uniform float seed = 0.0;

void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float r = length(p);
	float t = 1.0 - pow(1.0 - progress, ease_out);
	float radius = mix(start_radius, 1.0 - thickness, t);
	float ring = 1.0 - smoothstep(0.0, thickness, abs(r - radius));
	float inside = (1.0 - smoothstep(radius - thickness, radius, r)) * inner_glow * (1.0 - t);
	float angle = atan(p.y, p.x) / TAU + 0.5;
	float breakup = mix(1.0, texture(noise, vec2(angle * 3.0 + seed, r * 0.5 + progress)).r, noise_strength);
	float fade = (1.0 - progress) * (1.0 - progress);
	ALBEDO = color.rgb * energy * (ring + inside) * breakup * fade;
}
