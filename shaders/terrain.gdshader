shader_type spatial;
render_mode diffuse_burley;

// Terreno volcánico canario: arena negra en la orilla, basalto en las pendientes,
// tierra ocre, matorral (tabaibas) en las zonas llanas y nieve en las cumbres.

uniform sampler2D detail : filter_linear_mipmap, repeat_enable;
uniform float snow_line = 115.0;
uniform float green = 0.0;
uniform float glow = 0.0;    // brillo propio (San Borondón)   // 0 = isla seca, 1 = isla verde (La Gomera)
uniform vec3 sand : source_color = vec3(0.10, 0.09, 0.085);
uniform vec3 basalt : source_color = vec3(0.16, 0.13, 0.115);
uniform vec3 earth : source_color = vec3(0.36, 0.24, 0.16);
uniform vec3 scrub : source_color = vec3(0.30, 0.36, 0.17);
uniform vec3 snow : source_color = vec3(0.93, 0.94, 0.96);

varying vec3 wpos;
varying vec3 wnorm;

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	wnorm = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	float slope = 1.0 - clamp(wnorm.y, 0.0, 1.0);
	float n = texture(detail, wpos.xz * 0.012).r;
	float n2 = texture(detail, wpos.xz * 0.09).r;
	float n3 = texture(detail, wpos.xz * 0.4).r;
	vec3 c = mix(earth, scrub, smoothstep(0.48 - green * 0.32, 0.62 - green * 0.25, n) * (1.0 - smoothstep(0.15 + green * 0.25, 0.4 + green * 0.3, slope)));
	c = mix(c, earth * 0.75, smoothstep(0.55, 0.7, n2) * 0.5);
	c = mix(c, basalt, smoothstep(0.28, 0.55, slope + (n2 - 0.5) * 0.3));
	// coladas de lava (malpaís) oscuras
	c = mix(c, basalt * 0.8, smoothstep(0.58, 0.66, n) * 0.85);
	// arena negra y roca mojada junto al agua
	float beach = 1.0 - smoothstep(0.4, 2.6 + n * 1.5, wpos.y);
	c = mix(c, sand, beach);
	c *= mix(1.0, 0.55, 1.0 - smoothstep(-0.6, 0.5, wpos.y));
	// nieve en las cumbres (el Teide)
	c = mix(c, snow, smoothstep(snow_line - 8.0, snow_line + 6.0, wpos.y + (n2 - 0.5) * 18.0) * (1.0 - smoothstep(0.55, 0.85, slope)));
	c *= 0.82 + 0.36 * n3;
	ALBEDO = c;
	EMISSION = c * glow + vec3(0.1, 0.35, 0.18) * glow * 0.6;
	ROUGHNESS = mix(0.95, 0.55, beach * (1.0 - smoothstep(-0.2, 0.6, wpos.y)));
}
