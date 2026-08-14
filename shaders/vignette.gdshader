shader_type canvas_item;
// 全屏暗角 + 低血量红色渐显。hp_frac: 1=满血 0=濒死。

uniform float hp_frac : hint_range(0.0, 1.0) = 1.0;
uniform float base_strength : hint_range(0.0, 1.0) = 0.35;

void fragment() {
	vec2 uv = UV - vec2(0.5);
	float d = length(uv) * 1.414;      // 0 中心 ~1 角落
	float vig = smoothstep(0.4, 1.0, d);
	// 基础暗角(黑)
	float dark = vig * base_strength;
	// 低血量:血越少红色暗角越强
	float low = clamp(1.0 - hp_frac, 0.0, 1.0);
	float red = vig * low * 0.9;
	vec3 col = mix(vec3(0.0), vec3(0.55, 0.02, 0.03), red > 0.001 ? 1.0 : 0.0);
	float a = max(dark, red);
	COLOR = vec4(col, a);
}
