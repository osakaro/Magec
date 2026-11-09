shader_type sky;

// Cielo de MAGEC: degradado, sol, luna, estrellas y nubes que se mueven.

uniform vec3 top_color : source_color = vec3(0.26, 0.5, 0.75);
uniform vec3 horizon_color : source_color = vec3(0.68, 0.8, 0.86);
uniform vec3 ground_color : source_color = vec3(0.1, 0.16, 0.2);
uniform vec3 sun_tint : source_color = vec3(1.0, 0.92, 0.78);
uniform float daylight = 1.0;
uniform float time_s = 0.0;
uniform float cloud_cover = 0.45;
uniform vec3 cloud_tint : source_color = vec3(1.0);
uniform sampler2D cloud_noise : filter_linear_mipmap, repeat_enable;

float hash(vec3 p) {
	p = fract(p * 0.3183099 + 0.1);
	p *= 17.0;
	return fract(p.x * p.y * p.z * (p.x + p.y + p.z));
}

void sky() {
	vec3 d = EYEDIR;
	float hgt = d.y;
	vec3 col = mix(horizon_color, top_color, pow(clamp(hgt, 0.0, 1.0), 0.55));
	col = mix(col, ground_color, smoothstep(0.0, -0.25, hgt));

	// estrellas
	if (daylight < 0.6 && hgt > 0.0) {
		vec3 g = floor(d * 280.0);
		float s = hash(g);
		float star = step(0.9975, s) * (0.5 + 0.5 * sin(time_s * 2.0 + s * 50.0));
		col += vec3(star) * (0.6 - daylight) * 1.6 * smoothstep(0.0, 0.2, hgt);
	}

	// sol (luz 0) y luna (luz 1)
	if (LIGHT0_ENABLED) {
		float s = dot(d, LIGHT0_DIRECTION);
		col += sun_tint * (smoothstep(0.9994, 0.9997, s) * 8.0 + pow(max(s, 0.0), 200.0) * 0.8 + pow(max(s, 0.0), 8.0) * 0.18) * LIGHT0_ENERGY;
	}
	if (LIGHT1_ENABLED) {
		float m = dot(d, LIGHT1_DIRECTION);
		col += vec3(0.9, 0.92, 1.0) * (smoothstep(0.9990, 0.9993, m) * 1.4 + pow(max(m, 0.0), 120.0) * 0.15) * (1.0 - daylight);
	}

	// nubes en una bóveda plana
	if (hgt > 0.0) {
		vec2 uv = d.xz / (hgt + 0.12) * 0.22 + vec2(time_s * 0.004, time_s * 0.0015);
		float n = texture(cloud_noise, uv).r * 0.65 + texture(cloud_noise, uv * 2.7 + 0.3).r * 0.35;
		float c = smoothstep(1.0 - cloud_cover, 1.0 - cloud_cover + 0.28, n) * smoothstep(0.0, 0.18, hgt);
		vec3 lit = mix(horizon_color * 0.9, vec3(1.0), 0.55 + 0.45 * daylight) * cloud_tint;
		vec3 cloud = mix(lit * (0.25 + 0.75 * daylight), horizon_color * 0.6, smoothstep(0.6, 1.0, n) * 0.4);
		col = mix(col, cloud, c * 0.92);
	}
	COLOR = col;
}
