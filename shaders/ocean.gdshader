shader_type spatial;

uniform float time_s = 0.0;
uniform float daylight = 1.0;
uniform float amp = 1.0;
uniform vec3 deep_color : source_color = vec3(0.02, 0.13, 0.19);
uniform vec3 shallow_color : source_color = vec3(0.06, 0.30, 0.37);

varying float h;

// Must match Main.wave() in main.gd
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
}

void fragment() {
	float crest = clamp(h * 0.55 + 0.5, 0.0, 1.0);
	vec3 col = mix(deep_color, shallow_color, crest) * (0.25 + 0.75 * daylight);
	float foam = smoothstep(0.62, 0.85, h);
	col = mix(col, vec3(0.85, 0.92, 0.92) * (0.2 + 0.8 * daylight), foam * 0.55);
	ALBEDO = col;
	ROUGHNESS = 0.12;
	SPECULAR = 0.45;
}
