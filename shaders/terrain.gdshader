shader_type spatial;
render_mode diffuse_burley;

// Terreno volcánico canario con texturas fotográficas (Poly Haven, CC0):
// arena en la orilla, roca en las pendientes (proyección triplanar), tierra,
// malpaís y matorral en lo llano, nieve en las cumbres. Cada isla tiñe las
// texturas con sus colores.

uniform sampler2D detail : filter_linear_mipmap, repeat_enable;
uniform float snow_line = 115.0;
uniform float green = 0.0;   // 0 = isla seca, 1 = isla verde (La Gomera)
uniform float glow = 0.0;    // brillo propio (San Borondón)
uniform vec3 sand : source_color = vec3(0.10, 0.09, 0.085);
uniform vec3 basalt : source_color = vec3(0.16, 0.13, 0.115);
uniform vec3 earth : source_color = vec3(0.36, 0.24, 0.16);
uniform vec3 scrub : source_color = vec3(0.30, 0.36, 0.17);
uniform vec3 snow : source_color = vec3(0.93, 0.94, 0.96);

uniform sampler2D rock_alb : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D rock_nrm : hint_normal, filter_linear_mipmap, repeat_enable;
uniform sampler2D lava_alb : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D lava_nrm : hint_normal, filter_linear_mipmap, repeat_enable;
uniform sampler2D sand_alb : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D sand_nrm : hint_normal, filter_linear_mipmap, repeat_enable;
uniform sampler2D ground_alb : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D ground_nrm : hint_normal, filter_linear_mipmap, repeat_enable;
uniform bool use_textures = true;

varying vec3 wpos;
varying vec3 wnorm;

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	wnorm = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

// La textura vale 0.5 de media: la multiplicamos por 2 para que el tinte mande.
vec3 tinted(vec3 tex, vec3 tint) {
	return tex * tint * 2.1;
}

void fragment() {
	float slope = 1.0 - clamp(wnorm.y, 0.0, 1.0);
	float n = texture(detail, wpos.xz * 0.012).r;
	float n2 = texture(detail, wpos.xz * 0.09).r;
	float n3 = texture(detail, wpos.xz * 0.4).r;

	vec3 t_ground = vec3(0.5);
	vec3 t_lava = vec3(0.5);
	vec3 t_sand = vec3(0.5);
	vec3 t_rock = vec3(0.5);
	vec3 nm_ground = vec3(0.5, 0.5, 1.0);
	vec3 nm_lava = nm_ground;
	vec3 nm_sand = nm_ground;
	vec3 nm_rock = nm_ground;
	if (use_textures) {
		vec2 uvg = wpos.xz * 0.075;
		t_ground = texture(ground_alb, uvg).rgb;
		nm_ground = texture(ground_nrm, uvg).rgb;
		t_lava = texture(lava_alb, wpos.xz * 0.05).rgb;
		nm_lava = texture(lava_nrm, wpos.xz * 0.05).rgb;
		t_sand = texture(sand_alb, wpos.xz * 0.11).rgb;
		nm_sand = texture(sand_nrm, wpos.xz * 0.11).rgb;
		// roca en las pendientes: proyección triplanar para que no se estire
		vec3 bw = pow(abs(wnorm), vec3(4.0));
		bw /= (bw.x + bw.y + bw.z);
		float rs = 0.06;
		t_rock = texture(rock_alb, wpos.zy * rs).rgb * bw.x + texture(rock_alb, wpos.xz * rs).rgb * bw.y + texture(rock_alb, wpos.xy * rs).rgb * bw.z;
		nm_rock = texture(rock_nrm, wpos.zy * rs).rgb * bw.x + texture(rock_nrm, wpos.xz * rs).rgb * bw.y + texture(rock_nrm, wpos.xy * rs).rgb * bw.z;
	}

	vec3 c_earth = tinted(t_ground, earth);
	vec3 c_scrub = tinted(t_ground, scrub) * (0.85 + 0.3 * n3);
	vec3 c_lava = tinted(t_lava, basalt * 1.15);
	vec3 c_rock = tinted(t_rock, basalt * 1.3);
	vec3 c_sand = tinted(t_sand, sand * 1.4);

	float w_scrub = smoothstep(0.48 - green * 0.32, 0.62 - green * 0.25, n) * (1.0 - smoothstep(0.15 + green * 0.25, 0.4 + green * 0.3, slope));
	vec3 c = mix(c_earth, c_scrub, w_scrub);
	vec3 nm = mix(nm_ground, nm_ground, w_scrub);
	c = mix(c, c_earth * 0.8, smoothstep(0.55, 0.7, n2) * 0.4);
	// coladas de lava (malpaís)
	float w_lava = smoothstep(0.58, 0.66, n) * 0.9;
	c = mix(c, c_lava, w_lava);
	nm = mix(nm, nm_lava, w_lava);
	// roca en las pendientes
	float w_rock = smoothstep(0.28, 0.55, slope + (n2 - 0.5) * 0.3);
	c = mix(c, c_rock, w_rock);
	nm = mix(nm, nm_rock, w_rock);
	// arena y roca mojada junto al agua
	float beach = 1.0 - smoothstep(0.4, 2.6 + n * 1.5, wpos.y);
	c = mix(c, c_sand, beach * (1.0 - w_rock * 0.6));
	nm = mix(nm, nm_sand, beach);
	float wet = 1.0 - smoothstep(-0.6, 0.5, wpos.y);
	c *= mix(1.0, 0.55, wet);
	// nieve en las cumbres (el Teide)
	float w_snow = smoothstep(snow_line - 8.0, snow_line + 6.0, wpos.y + (n2 - 0.5) * 18.0) * (1.0 - smoothstep(0.55, 0.85, slope));
	c = mix(c, snow, w_snow);
	c *= 0.88 + 0.24 * n3;

	ALBEDO = c;
	NORMAL_MAP = mix(nm, vec3(0.5, 0.5, 1.0), w_snow);
	NORMAL_MAP_DEPTH = 1.2;
	ROUGHNESS = mix(0.95, 0.35, wet * beach);
	EMISSION = c * glow + vec3(0.1, 0.35, 0.18) * glow * 0.6;
}
