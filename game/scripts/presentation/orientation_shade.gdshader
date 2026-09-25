shader_type spatial;
render_mode unshaded, blend_mix, cull_disabled, shadows_disabled, depth_draw_never;

uniform float strength = 0.0;

void fragment() {
	vec2 from_center = UV * 2.0 - vec2(1.0);
	float distance_from_center = length(from_center);
	float falloff = smoothstep(1.05, 0.08, distance_from_center);
	ALBEDO = vec3(0.03, 0.035, 0.03);
	ALPHA = strength * falloff;
}
