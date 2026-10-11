// Flame tongue for GPUParticles3D draw passes (QuadMesh). Colour and alpha come from the
// particle colour ramp (COLOR); scrolling noise eats the edges so each flame flickers.
shader_type spatial;
render_mode blend_add, unshaded, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;

uniform sampler2D noise : hint_default_white, repeat_enable, filter_linear_mipmap;
uniform float energy : hint_range(0.0, 10.0) = 2.0;
uniform float scroll_speed : hint_range(0.0, 5.0) = 1.6;
uniform float noise_scale : hint_range(0.1, 4.0) = 0.9;
// Sideways wobble, stronger at the tip.
uniform float distortion : hint_range(0.0, 1.0) = 0.35;
// How much narrower the tip is than the base.
uniform float taper : hint_range(0.0, 1.0) = 0.6;
uniform float edge_softness : hint_range(0.01, 1.0) = 0.3;

varying float v_seed;

void vertex() {
	// Particle billboard that keeps the particle's scale.
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(
			INV_VIEW_MATRIX[0] * length(MODEL_MATRIX[0].xyz),
			INV_VIEW_MATRIX[1] * length(MODEL_MATRIX[1].xyz),
			INV_VIEW_MATRIX[2] * length(MODEL_MATRIX[2].xyz),
			MODEL_MATRIX[3]);
	v_seed = fract(float(INSTANCE_ID) * 0.6180339);
}

void fragment() {
	// UV.y = 0 at the top of the quad.
	float height = 1.0 - UV.y;
	vec2 nuv = vec2(UV.x + v_seed * 7.0, UV.y + TIME * scroll_speed + v_seed * 3.0) * noise_scale;
	float n = texture(noise, nuv).r;
	vec2 p = UV * 2.0 - 1.0;
	p.x += (n - 0.5) * distortion * height * 2.0;
	p.x /= mix(1.0, 1.0 - taper, height);
	p.y = p.y * 0.85 + 0.15;
	float body = 1.0 - length(p);
	float mask = smoothstep(0.0, edge_softness, body * (0.6 + n * 0.8));
	ALBEDO = COLOR.rgb * energy * mask * COLOR.a;
}
