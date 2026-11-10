extends RefCounted
## Modelos 3D generados por código: barquillo canario, palmera canaria, cardón,
## tabaiba, casas canarias, iglesia, escollera, bolardos.

static var _tex_cache := {}


static func tex(name: String, map: String) -> Texture2D:
	var key := name + "/" + map
	if not _tex_cache.has(key):
		var path := "res://assets/textures/%s/%s.jpg" % [name, map]
		_tex_cache[key] = load(path) if ResourceLoader.exists(path) else null
	return _tex_cache[key]


static func tex_mat(name: String, tint: Color, scale := 0.25, rough := 0.9) -> StandardMaterial3D:
	## Material con textura fotográfica proyectada en el mundo (sin coordenadas UV).
	var m := StandardMaterial3D.new()
	m.albedo_color = tint
	m.roughness = rough
	var a := tex(name, "albedo")
	if a:
		m.albedo_texture = a
		m.uv1_triplanar = true
		m.uv1_world_triplanar = true
		m.uv1_scale = Vector3.ONE * scale
		var n := tex(name, "normal")
		if n:
			m.normal_enabled = true
			m.normal_texture = n
			m.normal_scale = 1.0
	return m


static var _model_cache := {}


static func model(name: String) -> Node3D:
	## Instancia un modelo de Poly Haven (o null si no está descargado).
	var path := "res://assets/models/%s/%s.gltf" % [name, name]
	if not _model_cache.has(path):
		_model_cache[path] = load(path) if ResourceLoader.exists(path) else null
	var sc: PackedScene = _model_cache[path]
	return sc.instantiate() if sc else null


static func place(parent: Node, name: String, pos: Vector3, scl := 1.0, rot_y := 0.0, tint := Color(1, 1, 1, 1)) -> Node3D:
	var m := model(name)
	if m == null:
		return null
	parent.add_child(m)
	m.position = pos
	m.rotation.y = rot_y
	m.scale = Vector3.ONE * scl
	if tint != Color(1, 1, 1, 1):
		tint_model(m, tint)
	return m


static func tint_model(root: Node, tint: Color, emission := Color(0, 0, 0, 0), alpha := 1.0) -> void:
	## Copia los materiales del modelo multiplicando su color (p. ej. roca más oscura).
	var stack: Array = [root]
	while stack.size() > 0:
		var n = stack.pop_back()
		for c in n.get_children():
			stack.append(c)
		if n is MeshInstance3D and n.mesh:
			for si in n.mesh.get_surface_count():
				var base: Material = n.get_active_material(si)
				var m: StandardMaterial3D = (base.duplicate() if base is StandardMaterial3D else StandardMaterial3D.new())
				m.albedo_color = m.albedo_color * tint
				if alpha < 1.0:
					m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
					m.albedo_color.a = alpha
					m.cull_mode = BaseMaterial3D.CULL_DISABLED
				if emission.a > 0.0:
					m.emission_enabled = true
					m.emission = Color(emission.r, emission.g, emission.b)
					m.emission_energy_multiplier = emission.a
					m.set("disable_fog", true)
				n.set_surface_override_material(si, m)


static func model_mesh(name: String) -> ArrayMesh:
	## Junta todas las mallas de un modelo en una sola (para repartirla con MultiMesh).
	var root := model(name)
	if root == null:
		return null
	var out := ArrayMesh.new()
	var stack: Array = [[root, Transform3D()]]
	while stack.size() > 0:
		var it: Array = stack.pop_back()
		var n: Node = it[0]
		var xf: Transform3D = it[1]
		if n is Node3D and n != root:
			xf = xf * (n as Node3D).transform
		for c in n.get_children():
			stack.append([c, xf])
		if n is MeshInstance3D and n.mesh:
			for si in n.mesh.get_surface_count():
				var arr: Array = n.mesh.surface_get_arrays(si)
				var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
				for i in v.size():
					v[i] = xf * v[i]
				arr[Mesh.ARRAY_VERTEX] = v
				if arr[Mesh.ARRAY_NORMAL]:
					var nr: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]
					for i in nr.size():
						nr[i] = (xf.basis * nr[i]).normalized()
					arr[Mesh.ARRAY_NORMAL] = nr
				arr[Mesh.ARRAY_TANGENT] = null
				out.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
				out.surface_set_material(out.get_surface_count() - 1, n.get_active_material(si))
	root.free()
	return out


static func mat(c: Color, rough := 0.85, metal := 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	m.metallic = metal
	return m


static func vc_mat(rough := 0.8) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.vertex_color_use_as_albedo = true
	m.roughness = rough
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	return m


static func add_mesh(parent: Node, mesh: Mesh, m: Material, pos: Vector3, rot := Vector3.ZERO, scl := Vector3.ONE) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = m
	mi.position = pos
	mi.rotation = rot
	mi.scale = scl
	parent.add_child(mi)
	return mi


static func box(size: Vector3) -> BoxMesh:
	var b := BoxMesh.new()
	b.size = size
	return b


static func cyl(top: float, bottom: float, height: float, seg := 12) -> CylinderMesh:
	var c := CylinderMesh.new()
	c.top_radius = top
	c.bottom_radius = bottom
	c.height = height
	c.radial_segments = seg
	c.rings = 1
	return c


# =====================================================================
# Barquillo canario
# =====================================================================

static func hull_mesh(white: Color, band: Color, bottom: Color) -> ArrayMesh:
	## Casco curvo: secciones en U a lo largo del barco, con proa levantada.
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var N := 24   # secciones (popa -> proa)
	var M := 36   # puntos por sección (babor -> quilla -> estribor)
	var z_stern := 2.6
	var z_bow := -3.5
	var cap := Color("4a3424")
	for i in N + 1:
		var u := float(i) / N                    # 0 popa, 1 proa
		var z: float = lerp(z_stern, z_bow, u)
		var w: float = 1.25 * (1.0 - pow(max(u - 0.55, 0.0) / 0.45, 1.7)) * (0.86 + 0.14 * sin(PI * min(u * 1.6, 1.0)))
		w = max(w, 0.02)
		var depth: float = 0.72 * (1.0 - pow(max(u - 0.7, 0.0) / 0.3, 2.0) * 0.6)
		var top: float = 0.62 + pow(u, 3.0) * 0.55   # arrufo: la proa sube
		for j in M + 1:
			var a := PI * float(j) / M
			var x := -w * cos(a)
			var s: float = pow(sin(a), 0.75)
			var y: float = top - (top + depth) * s
			var col := white
			if y < -0.18:
				col = bottom
			elif y > top - 0.34 and y < top - 0.12:
				col = band
			elif y >= top - 0.07:
				col = cap
			st.set_color(col)
			st.add_vertex(Vector3(x, y, z))
	for i in N:
		for j in M:
			var a := i * (M + 1) + j
			var b := a + M + 1
			st.add_index(a)
			st.add_index(b)
			st.add_index(a + 1)
			st.add_index(a + 1)
			st.add_index(b)
			st.add_index(b + 1)
	st.generate_normals()
	var mesh := st.commit()
	# espejo de popa
	var st2 := SurfaceTool.new()
	st2.begin(Mesh.PRIMITIVE_TRIANGLES)
	var w0 := 1.25 * 0.86
	var pts: Array = []
	for j in M + 1:
		var a := PI * float(j) / M
		pts.append(Vector3(-w0 * cos(a), 0.62 - (0.62 + 0.72) * pow(sin(a), 0.75), z_stern))
	for j in M:
		st2.set_color(white)
		st2.add_vertex(Vector3(0, 0.4, z_stern))
		st2.add_vertex(pts[j])
		st2.add_vertex(pts[j + 1])
	st2.generate_normals()
	return st2.commit(mesh)


static func deck_mesh() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var N := 16
	var prev_l := Vector3.ZERO
	var prev_r := Vector3.ZERO
	for i in N + 1:
		var u := float(i) / N
		var z: float = lerp(2.55, -3.2, u)
		var w: float = 1.15 * (1.0 - pow(max(u - 0.55, 0.0) / 0.45, 1.7)) * (0.86 + 0.14 * sin(PI * min(u * 1.6, 1.0)))
		var y: float = 0.42 + pow(u, 3.0) * 0.45
		var l := Vector3(-w, y, z)
		var r := Vector3(w, y, z)
		if i > 0:
			var c := Color("8a6440") if i % 2 == 0 else Color("7c5838")
			for v in [prev_l, l, prev_r, prev_r, l, r]:
				st.set_color(c)
				st.add_vertex(v)
		prev_l = l
		prev_r = r
	st.generate_normals()
	return st.commit()


static func hull_section(u: float) -> Array:
	## Forma del casco en la sección u (0 = popa, 1 = proa): [z, semiancho, altura de la regala].
	var z: float = lerp(2.6, -3.5, u)
	var w: float = 1.25 * (1.0 - pow(max(u - 0.55, 0.0) / 0.45, 1.7)) * (0.86 + 0.14 * sin(PI * min(u * 1.6, 1.0)))
	var top: float = 0.62 + pow(u, 3.0) * 0.55
	return [z, max(w, 0.02), top]


static func build_boat(parent: Node, white: Color, band: Color, bottom: Color, name := "") -> Dictionary:
	## Barquillo canario: casco de tablas pintadas, regala de madera, roda, timón,
	## motor fueraborda, caseta, redes, cañas, cabos y el nombre pintado en la proa.
	var node := Node3D.new()
	parent.add_child(node)
	# casco: la textura de tablas se tiñe con los colores pintados (blanco, franja, fondo)
	var hull_m := vc_mat(0.6)
	var ht := tex("white_planks_clean", "albedo")
	if ht:
		hull_m.albedo_texture = ht
		hull_m.uv1_triplanar = true
		hull_m.uv1_scale = Vector3(0.9, 1.6, 0.9)
		hull_m.normal_enabled = true
		hull_m.normal_texture = tex("white_planks_clean", "normal")
	add_mesh(node, hull_mesh(white, band, bottom), hull_m, Vector3.ZERO)
	add_mesh(node, deck_mesh(), tex_mat("brown_planks_05", Color(1.1, 1.0, 0.9), 0.9, 0.85), Vector3.ZERO)
	var wood := tex_mat("weathered_planks", Color(1.0, 0.9, 0.8), 0.8, 0.8)
	var dark_wood := tex_mat("weathered_planks", Color(0.55, 0.45, 0.38), 0.8, 0.8)
	# regala: listón de madera por todo el borde, a ambos lados
	var prev: Array = []
	for i in 13:
		var sec := hull_section(float(i) / 12.0)
		if i > 0:
			for side in [-1.0, 1.0]:
				var a := Vector3(prev[1] * side, prev[2], prev[0])
				var b := Vector3(sec[1] * side, sec[2], sec[0])
				var seg := b - a
				var mi := add_mesh(node, box(Vector3(0.1, 0.1, seg.length() + 0.04)), wood, (a + b) / 2.0)
				mi.look_at_from_position((a + b) / 2.0, b, Vector3.UP)
		prev = sec
	# roda (proa) y quilla
	var bow := hull_section(1.0)
	var s0 := Vector3(0, -0.3, -3.45)
	var s1 := Vector3(0, bow[2] + 0.1, -3.56)
	var stem := add_mesh(node, box(Vector3(0.1, 0.1, s0.distance_to(s1))), wood, (s0 + s1) / 2.0)
	stem.look_at_from_position((s0 + s1) / 2.0, s1, Vector3.FORWARD)
	add_mesh(node, box(Vector3(0.12, 0.12, 5.6)), dark_wood, Vector3(0, -0.72, -0.4))
	# timón de popa
	add_mesh(node, box(Vector3(0.08, 0.9, 0.5)), dark_wood, Vector3(0, -0.25, 2.85))
	add_mesh(node, box(Vector3(0.06, 0.06, 0.7)), dark_wood, Vector3(0, 0.45, 2.55))
	# motor fueraborda
	var engine := mat(Color("e8e6e0"), 0.35, 0.1)
	var engine_dark := mat(Color("2a2a2c"), 0.5, 0.3)
	add_mesh(node, box(Vector3(0.42, 0.5, 0.48)), engine, Vector3(0.55, 0.85, 2.85))
	add_mesh(node, box(Vector3(0.44, 0.08, 0.5)), mat(band, 0.4), Vector3(0.55, 0.92, 2.85))
	add_mesh(node, cyl(0.06, 0.06, 1.1, 8), engine_dark, Vector3(0.55, 0.15, 2.9))
	add_mesh(node, box(Vector3(0.36, 0.06, 0.06)), engine_dark, Vector3(0.55, -0.42, 2.98))
	# caseta del timón: madera pintada, techo de color, puerta y ventanas con marco
	var cab := tex_mat("white_planks_clean", white.darkened(0.02), 1.6, 0.6)
	add_mesh(node, box(Vector3(1.4, 1.05, 1.3)), cab, Vector3(0, 1.0, 1.0))
	add_mesh(node, box(Vector3(1.62, 0.1, 1.58)), mat(band.darkened(0.15), 0.6), Vector3(0, 1.57, 1.0))
	var glass := mat(Color("1d2b33"), 0.08, 0.4)
	var frame := mat(band.darkened(0.25), 0.6)
	add_mesh(node, box(Vector3(1.08, 0.46, 0.04)), frame, Vector3(0, 1.2, 0.34))
	add_mesh(node, box(Vector3(0.96, 0.36, 0.05)), glass, Vector3(0, 1.2, 0.33))
	for sx in [-0.71, 0.71]:
		add_mesh(node, box(Vector3(0.04, 0.4, 0.66)), frame, Vector3(sx, 1.2, 1.0))
		add_mesh(node, box(Vector3(0.05, 0.32, 0.56)), glass, Vector3(sx * 1.005, 1.2, 1.0))
	add_mesh(node, box(Vector3(0.6, 0.9, 0.04)), dark_wood, Vector3(0, 0.95, 1.66))
	add_mesh(node, cyl(0.01, 0.015, 1.2, 4), engine_dark, Vector3(0.5, 2.2, 1.3))   # antena
	# neumáticos de defensa
	var tire := TorusMesh.new()
	tire.inner_radius = 0.16
	tire.outer_radius = 0.3
	tire.rings = 12
	tire.ring_segments = 6
	var rubber := mat(Color("1a1a1a"), 0.9)
	for side in [-1.0, 1.0]:
		for z in [-0.8, 1.2]:
			add_mesh(node, tire, rubber, Vector3(side * 1.24, 0.38, z), Vector3(0, 0, PI / 2))
	# redes amontonadas, cabos y cañas
	var net := mat(Color("3d6b4a"), 0.95)
	var blob := SphereMesh.new()
	blob.radius = 0.3
	blob.height = 0.32
	blob.radial_segments = 8
	blob.rings = 4
	for k in 4:
		add_mesh(node, blob, net, Vector3(-0.4 + (k % 2) * 0.35, 0.55, -1.5 - (k / 2) * 0.3), Vector3.ZERO, Vector3(1.3, 1.0, 1.0))
	var rope := TorusMesh.new()
	rope.inner_radius = 0.12
	rope.outer_radius = 0.24
	rope.rings = 12
	rope.ring_segments = 5
	add_mesh(node, rope, mat(Color("c9b48a"), 0.9), Vector3(0.5, 0.5, -0.6))
	for k in 2:
		var rod := add_mesh(node, cyl(0.015, 0.03, 3.0, 5), mat(Color("2a2a2a"), 0.4), Vector3(-0.55 + k * 1.1, 1.6, 2.2), Vector3(-0.7, 0, (k - 0.5) * 0.5))
	add_mesh(node, box(Vector3(0.6, 0.3, 0.45)), mat(Color("2e6fa6")), Vector3(0.45, 0.62, -2.0))
	add_mesh(node, box(Vector3(0.6, 0.3, 0.45)), mat(Color("c9a227")), Vector3(0.4, 0.92, -2.05))
	place(node, "lifebuoy", Vector3(0.73, 1.15, 1.0), 0.55, PI / 2)
	# nombre pintado a ambos lados de la proa
	if false and name != "":   # nombres en el casco desactivados (no quedaban integrados)
		for side in [-1.0, 1.0]:
			var lb := Label3D.new()
			lb.text = name
			lb.font = load("res://fonts/AlegreyaSC-Bold.ttf")
			lb.font_size = 48
			lb.pixel_size = 0.004
			lb.modulate = band.darkened(0.2)
			lb.outline_size = 0
			lb.double_sided = false
			lb.position = Vector3(side * 0.93, 0.62, -2.35)
			lb.rotation = Vector3(0, side * PI / 2 + (0.18 * side), 0)
			node.add_child(lb)
	# mástil, verga y farol
	var mast_wood := mat(Color("6b4a2f"))
	add_mesh(node, cyl(0.06, 0.08, 3.2, 8), mast_wood, Vector3(0, 2.0, -0.9))
	add_mesh(node, cyl(0.04, 0.04, 1.6, 6), mast_wood, Vector3(0, 2.9, -0.9), Vector3(PI / 2, 0, 0))
	var bulb := SphereMesh.new()
	bulb.radius = 0.16
	bulb.height = 0.32
	var lm := mat(Color("553311"))
	lm.emission_enabled = true
	lm.emission = Color("ffe7a0")
	lm.emission_energy_multiplier = 0.0
	add_mesh(node, bulb, lm, Vector3(0, 3.72, -0.9))
	if place(node, "wooden_lantern_01", Vector3(0, 3.5, -0.9), 1.5) == null:
		add_mesh(node, cyl(0.22, 0.18, 0.08, 8), mat(Color("2a2a2a")), Vector3(0, 3.92, -0.9))
	var light := OmniLight3D.new()
	light.light_color = Color("ffd27a")
	light.omni_range = 38
	light.shadow_enabled = true
	light.light_energy = 0.0
	light.position = Vector3(0, 3.8, -0.9)
	node.add_child(light)
	return {"node": node, "light": light, "lamp_mat": lm}


# =====================================================================
# Vegetación canaria
# =====================================================================

static func palm_mesh() -> ArrayMesh:
	## Palmera canaria (Phoenix canariensis): tronco grueso y copa redonda.
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var H := 7.5
	var segs := 10
	var sides := 8
	for i in segs:
		for k in sides:
			var a0 := TAU * k / sides
			var a1 := TAU * (k + 1) / sides
			var y0 := H * i / segs
			var y1 := H * (i + 1) / segs
			var r0: float = 0.42 - 0.12 * i / segs
			var r1: float = 0.42 - 0.12 * (i + 1) / segs
			var bend0 := sin(float(i) / segs * 1.4) * 0.6
			var bend1 := sin(float(i + 1) / segs * 1.4) * 0.6
			var c := Color("6e5a42") if i % 2 == 0 else Color("5e4c37")
			var p00 := Vector3(cos(a0) * r0 + bend0, y0, sin(a0) * r0)
			var p01 := Vector3(cos(a1) * r0 + bend0, y0, sin(a1) * r0)
			var p10 := Vector3(cos(a0) * r1 + bend1, y1, sin(a0) * r1)
			var p11 := Vector3(cos(a1) * r1 + bend1, y1, sin(a1) * r1)
			for v in [p00, p10, p01, p01, p10, p11]:
				st.set_color(c)
				st.add_vertex(v)
	var top := Vector3(sin(1.4) * 0.6, H, 0)
	var fronds := 20
	for f in fronds:
		var ang := TAU * f / fronds + (0.15 if f % 2 else 0.0)
		var dir := Vector3(cos(ang), 0, sin(ang))
		var side := Vector3(-dir.z, 0, dir.x)
		var length := 3.4 + (f % 3) * 0.4
		var rise := 0.9 if f % 2 == 0 else 1.6
		var steps := 8
		for s in steps:
			var t0 := float(s) / steps
			var t1 := float(s + 1) / steps
			var c0 := top + dir * length * t0 + Vector3(0, rise * t0 - 2.6 * t0 * t0, 0)
			var c1 := top + dir * length * t1 + Vector3(0, rise * t1 - 2.6 * t1 * t1, 0)
			var w0 := sin(PI * min(t0 + 0.08, 1.0)) * 0.55
			var w1 := sin(PI * min(t1 + 0.08, 1.0)) * 0.55
			var g0 := Color("4f7a2c").lerp(Color("8aa64a"), t0)
			var g1 := Color("4f7a2c").lerp(Color("8aa64a"), t1)
			var a := c0 - side * w0
			var b := c0 + side * w0
			var cc := c1 - side * w1
			var d := c1 + side * w1
			var mid0 := c0 + Vector3(0, 0.08, 0)
			var mid1 := c1 + Vector3(0, 0.08, 0)
			for v in [[a, g0], [mid0, g0], [cc, g1], [cc, g1], [mid0, g0], [mid1, g1], [mid0, g0], [b, g0], [mid1, g1], [mid1, g1], [b, g0], [d, g1]]:
				st.set_color(v[1])
				st.add_vertex(v[0])
	st.generate_normals()
	return st.commit()


static func cardon_mesh() -> ArrayMesh:
	## Cardón (Euphorbia canariensis): columnas verdes agrupadas, como un candelabro.
	var st := SurfaceTool.new()
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	var base := CylinderMesh.new()
	base.radial_segments = 6
	base.rings = 1
	for i in 9:
		var h := rng.randf_range(1.2, 2.6)
		var r := 0.17
		base.top_radius = r * 0.8
		base.bottom_radius = r
		base.height = h
		var ang := TAU * i / 9.0
		var off := Vector3(cos(ang), 0, sin(ang)) * rng.randf_range(0.2, 0.7)
		st.append_from(base, 0, Transform3D(Basis(), off + Vector3(0, h / 2.0, 0)))
		var cap := SphereMesh.new()
		cap.radius = r * 0.85
		cap.height = r * 1.7
		cap.radial_segments = 6
		cap.rings = 3
		st.append_from(cap, 0, Transform3D(Basis(), off + Vector3(0, h, 0)))
	return st.commit()


static func shrub_mesh() -> ArrayMesh:
	## Tabaiba: mata redondeada y baja.
	var st := SurfaceTool.new()
	var s := SphereMesh.new()
	s.radial_segments = 7
	s.rings = 4
	for i in 4:
		var r := 0.35 + 0.1 * i
		s.radius = r
		s.height = r * 1.3
		var off := Vector3(cos(i * 1.9) * 0.3, r * 0.4, sin(i * 1.9) * 0.3)
		st.append_from(s, 0, Transform3D(Basis(), off))
	return st.commit()


static func rock_mesh(seed_v: int) -> ArrayMesh:
	var s := SphereMesh.new()
	s.radius = 1.0
	s.height = 2.0
	s.radial_segments = 7
	s.rings = 4
	var arrays := s.get_mesh_arrays()
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_v
	var bumps := {}
	for i in verts.size():
		var key := Vector3i(roundi(verts[i].x * 100), roundi(verts[i].y * 100), roundi(verts[i].z * 100))
		if not bumps.has(key):
			bumps[key] = rng.randf_range(0.75, 1.2)
		verts[i] *= bumps[key]
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = null
	var am := ArrayMesh.new()
	am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var st := SurfaceTool.new()
	st.create_from(am, 0)
	st.deindex()
	st.generate_normals()
	return st.commit()


static func scatter(parent: Node, mesh: Mesh, m: Material, transforms: Array) -> MultiMeshInstance3D:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = mesh
	mm.instance_count = transforms.size()
	for i in transforms.size():
		mm.set_instance_transform(i, transforms[i])
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	mmi.material_override = m
	parent.add_child(mmi)
	return mmi


# =====================================================================
# Arquitectura canaria
# =====================================================================

const WALLS := [Color("f4f1ea"), Color("f4f1ea"), Color("f2eadb"), Color("e9c27f"), Color("f4f1ea"), Color("cfdde6"), Color("e7b08f"), Color("f4f1ea")]
const WOODS := [Color("2e6b4f"), Color("6b3f22"), Color("1d5aa6"), Color("2e6b4f"), Color("8a2b22")]


static func house(parent: Node, pos: Vector3, w: float, d: float, h: float, rng: RandomNumberGenerator, facing := 0.0, wall_c := Color(0, 0, 0, 0), wood_c := Color(0, 0, 0, 0)) -> void:
	var g := Node3D.new()
	g.position = pos
	g.rotation.y = facing
	parent.add_child(g)
	var wc: Color = wall_c if wall_c.a > 0.0 else WALLS[rng.randi() % WALLS.size()]
	var wall := tex_mat("white_plaster_rough_01", wc.lightened(0.05), 0.3)
	var wood := tex_mat("weathered_planks", (wood_c if wood_c.a > 0.0 else WOODS[rng.randi() % WOODS.size()]).lightened(0.25), 0.6, 0.8)
	var dark := mat(Color("1b1a1a"), 0.4)
	add_mesh(g, box(Vector3(w, h + 3.0, d)), wall, Vector3(0, (h - 3.0) / 2.0, 0))
	# pretil de la azotea
	var pt := 0.18
	for sx in [-1, 1]:
		add_mesh(g, box(Vector3(pt, 0.45, d)), wall, Vector3(sx * (w / 2 - pt / 2), h + 0.22, 0))
	for sz in [-1, 1]:
		add_mesh(g, box(Vector3(w, 0.45, pt)), wall, Vector3(0, h + 0.22, sz * (d / 2 - pt / 2)))
	# zócalo
	add_mesh(g, box(Vector3(w + 0.04, 0.5, d + 0.04)), mat(Color("8a8378"), 0.9), Vector3(0, 0.25, 0))
	# puerta y ventanas con marco de madera (fachada hacia el mar, +z)
	var front := d / 2 + 0.03
	add_mesh(g, box(Vector3(0.95, 2.0, 0.08)), wood, Vector3(-w * 0.18, 1.0, front))
	var floors := 1 if h < 5.0 else 2
	for fl in floors:
		var y := 1.5 + fl * 2.8
		for wx in [w * 0.22, -w * 0.38] if fl == 0 else [w * 0.22, -w * 0.18]:
			if fl == 0 and wx < 0:
				continue
			add_mesh(g, box(Vector3(0.85, 1.05, 0.06)), wood, Vector3(wx, y, front))
			add_mesh(g, box(Vector3(0.62, 0.82, 0.08)), dark, Vector3(wx, y, front + 0.01))
	# balcón de madera canario en las casas de dos plantas
	if floors == 2 and rng.randf() < 0.6:
		add_mesh(g, box(Vector3(w * 0.6, 0.12, 0.8)), wood, Vector3(0, 3.3, front + 0.4))
		add_mesh(g, box(Vector3(w * 0.6, 0.9, 0.06)), wood, Vector3(0, 3.8, front + 0.78))
		add_mesh(g, box(Vector3(w * 0.64, 0.12, 0.9)), wood, Vector3(0, 4.9, front + 0.4))


static func church(parent: Node, pos: Vector3) -> void:
	## Iglesia de muros blancos con esquinas de cantería y campanario.
	var g := Node3D.new()
	g.position = pos
	parent.add_child(g)
	var white := tex_mat("white_plaster_rough_01", Color("f6f2ea"), 0.3)
	var stone := tex_mat("rock_face", Color("6a6460"), 0.5)
	var roof := mat(Color("9c4a32"), 0.8)
	add_mesh(g, box(Vector3(8, 10, 15)), white, Vector3(0, 2.0, 0))
	var prism := PrismMesh.new()
	prism.size = Vector3(8.4, 2.4, 15.4)
	add_mesh(g, prism, roof, Vector3(0, 8.2, 0))
	add_mesh(g, box(Vector3(2.0, 3.6, 0.2)), stone, Vector3(0, 1.8, 7.55))
	add_mesh(g, box(Vector3(1.4, 2.8, 0.25)), mat(Color("4a2c18")), Vector3(0, 1.4, 7.6))
	var t := Node3D.new()
	t.position = Vector3(5.2, 0, 5.5)
	g.add_child(t)
	add_mesh(t, box(Vector3(3.4, 18, 3.4)), white, Vector3(0, 6.0, 0))
	for cx in [-1, 1]:
		for cz in [-1, 1]:
			add_mesh(t, box(Vector3(0.4, 18.1, 0.4)), stone, Vector3(cx * 1.6, 6.0, cz * 1.6))
	for side in 4:
		var rot := side * PI / 2
		var dir := Vector3(sin(rot), 0, cos(rot))
		add_mesh(t, box(Vector3(1.0, 1.8, 0.2)), mat(Color("141414")), Vector3(0, 13.0, 0) + dir * 1.62, Vector3(0, rot, 0))
	add_mesh(t, box(Vector3(3.8, 0.4, 3.8)), stone, Vector3(0, 15.2, 0))
	var cup := CylinderMesh.new()
	cup.top_radius = 0.0
	cup.bottom_radius = 1.9
	cup.height = 2.6
	cup.radial_segments = 4
	add_mesh(t, cup, roof, Vector3(0, 16.7, 0), Vector3(0, PI / 4, 0))
	add_mesh(t, cyl(0.05, 0.05, 1.4, 4), stone, Vector3(0, 18.6, 0))


static func pine_mesh() -> ArrayMesh:
	## Pino canario: tronco alto y copas verdes en pisos.
	var st := SurfaceTool.new()
	st.append_from(cyl(0.15, 0.3, 7.0, 6), 0, Transform3D(Basis(), Vector3(0, 3.5, 0)))
	var c := SphereMesh.new()
	c.radial_segments = 7
	c.rings = 4
	for i in 4:
		var r := 1.6 - i * 0.25
		c.radius = r
		c.height = r * 0.9
		st.append_from(c, 0, Transform3D(Basis(), Vector3(cos(i * 2.0) * 0.4, 4.0 + i * 1.2, sin(i * 2.0) * 0.4)))
	return st.commit()


static func sabina_mesh() -> ArrayMesh:
	## Sabina de El Hierro: tronco retorcido doblado por el viento y copa plana.
	var st := SurfaceTool.new()
	var seg := cyl(0.14, 0.2, 1.2, 6)
	var p := Vector3.ZERO
	for i in 4:
		var b := Basis(Vector3(0, 0, 1), -0.35 * (i + 1))
		st.append_from(seg, 0, Transform3D(b, p + b * Vector3(0, 0.6, 0)))
		p += b * Vector3(0, 1.2, 0)
	var c := SphereMesh.new()
	c.radial_segments = 8
	c.rings = 4
	c.radius = 1.4
	c.height = 0.9
	st.append_from(c, 0, Transform3D(Basis().scaled(Vector3(1.6, 1, 1)), p + Vector3(0.6, 0, 0)))
	return st.commit()


static func banana_mesh() -> ArrayMesh:
	## Platanera: hojas grandes en abanico.
	var st := SurfaceTool.new()
	st.append_from(cyl(0.12, 0.16, 2.0, 6), 0, Transform3D(Basis(), Vector3(0, 1.0, 0)))
	var leaf := BoxMesh.new()
	leaf.size = Vector3(0.5, 0.04, 2.0)
	for i in 6:
		var b := Basis(Vector3.UP, i * TAU / 6.0) * Basis(Vector3.RIGHT, -0.6)
		st.append_from(leaf, 0, Transform3D(b, Vector3(0, 2.0, 0) + b * Vector3(0, 0, -0.9)))
	return st.commit()


static func ghost_ship(parent: Node, dark := false) -> Node3D:
	## Barco fantasma: galeón viejo, translúcido y con faroles verdes.
	## Con dark = true es el galeón negro de Don Baltasar, con faroles rojos.
	var ship := model("dutch_ship_medium")
	if ship:
		var g0 := Node3D.new()
		parent.add_child(g0)
		g0.add_child(ship)
		ship.rotation.y = PI / 2
		ship.position.y = -1.2
		if dark:
			tint_model(ship, Color(0.22, 0.2, 0.2), Color(0.25, 0.03, 0.02, 0.4))
		else:
			tint_model(ship, Color(0.55, 1.0, 0.75), Color(0.2, 0.75, 0.5, 1.2), 0.6)
		var gl := OmniLight3D.new()
		gl.light_color = Color(1.0, 0.25, 0.15) if dark else Color(0.4, 1.0, 0.6)
		gl.light_energy = 4.0
		gl.omni_range = 45
		gl.position = Vector3(0, 8, 0)
		g0.add_child(gl)
		return g0
	var g := Node3D.new()
	parent.add_child(g)
	var wood := StandardMaterial3D.new()
	wood.albedo_color = Color(0.08, 0.07, 0.07, 1.0) if dark else Color(0.6, 0.85, 0.72, 0.7)
	wood.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED if dark else BaseMaterial3D.TRANSPARENCY_ALPHA
	wood.emission_enabled = true
	wood.emission = Color(0.25, 0.04, 0.03) if dark else Color(0.25, 0.8, 0.55)
	wood.emission_energy_multiplier = 0.5 if dark else 1.6
	wood.set("disable_fog", true)
	var sail := wood.duplicate()
	sail.albedo_color = Color(0.85, 0.95, 0.9, 0.35)
	sail.cull_mode = BaseMaterial3D.CULL_DISABLED
	add_mesh(g, box(Vector3(4.0, 2.4, 14.0)), wood, Vector3(0, 0.8, 0))
	add_mesh(g, box(Vector3(4.4, 1.8, 3.5)), wood, Vector3(0, 2.6, 5.0))
	var bow := PrismMesh.new()
	bow.size = Vector3(4.0, 3.5, 2.4)
	add_mesh(g, bow, wood, Vector3(0, 0.8, -8.5), Vector3(-PI / 2, 0, 0))
	for z in [-4.0, 1.0, 5.0]:
		add_mesh(g, cyl(0.12, 0.16, 12.0, 6), wood, Vector3(0, 7.0, z))
		var sl := BoxMesh.new()
		sl.size = Vector3(5.0, 4.0, 0.05)
		add_mesh(g, sl, sail, Vector3(0, 7.5, z), Vector3(0.1, 0, 0))
	var lm := StandardMaterial3D.new()
	lm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	lm.albedo_color = Color(1.0, 0.25, 0.15) if dark else Color(0.5, 1.0, 0.7)
	lm.set("disable_fog", true)
	var lamp := SphereMesh.new()
	lamp.radius = 0.3
	lamp.height = 0.6
	for pz in [-6.5, 6.5]:
		add_mesh(g, lamp, lm, Vector3(0, 3.2, pz))
	var l := OmniLight3D.new()
	l.light_color = Color(1.0, 0.25, 0.15) if dark else Color(0.4, 1.0, 0.6)
	l.light_energy = 4.0
	l.omni_range = 45
	l.position = Vector3(0, 5, 0)
	g.add_child(l)
	return g
