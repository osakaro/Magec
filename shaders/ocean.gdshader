shader_type spatial;
render_mode cull_back, diffuse_burley, specular_schlick_ggx;

// Mar de MAGEC: olas (iguales que Main.wave), pequeñas olas en la superficie,
// transparencia en la orilla, espuma donde el agua toca algo y reflejo del cielo.

uniform float time_s = 0.0;
uniform float amp = 1.0;
uniform float daylight = 1.0;
uniform vec3 deep_color : source_color = vec3(0.01, 0.10, 0.16);
uniform vec3 mid_color : source_color = vec3(0.03, 0.26, 0.33);
uniform vec3 shallow_color : source_color = vec3(0.12, 0.52, 0.52);
uniform vec3 sky_color : source_color = vec3(0.6, 0.75, 0.85);
uniform sampler2D normal_a : hint_normal, filter_linear_mipmap, repeat_enable;
uniform sampler2D normal_b : hint_normal, filter_linear_mipmap, repeat_enable;
uniform sampler2D foam_noise : filter_linear_mipmap, repeat_enable;
uniform sampler2D depth_tex : hint_depth_texture, filter_linear;
uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap;

varying float h;
varying vec3 wpos;

// Debe coincidir con Main.wave() en main.gd
float wave(vec2 p, float t) {
	return amp * (0.45 * sin(0.12 * p.x + t * 0.8)
		+ 0.30 * sin(0.17 * p.y - t * 1.1)
		+ 0.15 * sin(0.45 * (p.x + p.y) + t * 1.7));
}

void vertex() {
	vec3 wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float hh = wave(wp.xz, time_s);
	float e = 0.6;
	float hx = wave(wp.xz + vec2(e, 0.0), time_s);
	float hz = wave(wp.xz + vec2(0.0, e), time_s);
	VERTEX.y += hh;
	NORMAL = normalize(vec3(-(hx - hh) / e, 1.0, -(hz - hh) / e));
	h = hh;
	wpos = wp + vec3(0.0, hh, 0.0);
}

void fragment() {
	// pequeñas olas: dos capas de ruido que se cruzan
	vec2 uv1 = wpos.xz * 0.045 + vec2(time_s * 0.012, time_s * 0.007);
	vec2 uv2 = wpos.xz * 0.11 - vec2(time_s * 0.009, time_s * 0.016);
	vec3 n1 = texture(normal_a, uv1).rgb;
	vec3 n2 = texture(normal_b, uv2).rgb;
	NORMAL_MAP = mix(n1, n2, 0.5);
	NORMAL_MAP_DEPTH = 0.55;

	// profundidad del fondo bajo el agua (para espuma y transparencia)
	float depth = texture(depth_tex, SCREEN_UV).r;
	// Forward+ (Godot 4.3+): profundidad en NDC directamente
	vec3 ndc = vec3(SCREEN_UV * 2.0 - 1.0, depth);
	vec4 view = INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
	view.xyz /= view.w;
	float diff = clamp(-view.z - (-VERTEX.z), 0.0, 60.0);

	float crest = clamp(h * 0.5 + 0.5, 0.0, 1.0);
	vec3 water = mix(shallow_color, mid_color, smoothstep(0.0, 4.0, diff));
	water = mix(water, deep_color, smoothstep(4.0, 22.0, diff));
	water = mix(water, mid_color * 1.25, crest * 0.25);

	// transparencia y refracción en lo poco profundo
	vec2 refr = NORMAL_MAP.xy * 0.02 - 0.01;
	vec3 under = textureLod(screen_tex, SCREEN_UV + refr, 1.0).rgb;
	float clarity = 1.0 - smoothstep(0.0, 5.0, diff);
	vec3 col = mix(water, under * shallow_color * 1.6, clarity * 0.65);

	// espuma: donde el agua toca rocas, costa y muelle, y en las crestas
	float fn = texture(foam_noise, wpos.xz * 0.12 + vec2(time_s * 0.02, 0.0)).r;
	float fn2 = texture(foam_noise, wpos.xz * 0.35 - vec2(0.0, time_s * 0.03)).r;
	float shore = 1.0 - smoothstep(0.0, 1.6 + fn * 1.2, diff);
	float edge_line = smoothstep(0.45, 0.6, fract(diff * 0.6 - time_s * 0.35 + fn)) * (1.0 - smoothstep(0.0, 3.5, diff));
	float crest_foam = smoothstep(0.7, 0.95, crest + fn2 * 0.25) * smoothstep(1.3, 2.1, amp);
	float foam = clamp(shore * (0.55 + fn2 * 0.6) + edge_line * 0.5 + crest_foam * 0.6, 0.0, 1.0);
	foam *= step(0.4, fn2 + shore * 0.6);
	vec3 foam_col = vec3(0.92, 0.95, 0.95) * (0.15 + 0.85 * daylight);

	// reflejo del cielo según el ángulo
	float fres = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 4.0);
	col = mix(col, sky_color, fres * 0.55);
	col = mix(col, foam_col, foam);

	ALBEDO = col * (0.5 + 0.5 * daylight);
	ROUGHNESS = mix(0.06, 0.6, foam);
	SPECULAR = 0.55;
	METALLIC = 0.0;
}
