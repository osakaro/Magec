extends Node3D
## MAGEC - escena principal. Construye la costa de Güímar, el mar y el barco,
## y lleva la lógica de pesca, tiempo, miedo, bodega y puerto.

const Data = preload("res://scripts/data.gd")
const UI = preload("res://scripts/ui.gd")
const OCEAN_SHADER = preload("res://shaders/ocean.gdshader")
const Cinematic = preload("res://scripts/cinematic.gd")
const Audio = preload("res://scripts/audio.gd")
const Quest = preload("res://scripts/quest.gd")
const Gear = preload("res://scripts/gear.gd")
const Hazards = preload("res://scripts/hazards.gd")
const Weather = preload("res://scripts/weather.gd")
const Life = preload("res://scripts/life.gd")

# Altura de las olas (la cinemática la sube durante el temblor)
static var amp := 1.0

# Qué hacer al cargar la escena: "" (menú), "new" o "continue"
static var start_action := ""

const SAVE_PATH := "user://partida.json"

const SHORE := -70.0
const PORT := Vector3(0, 0, -58)
const OCEAN_SIZE := 400.0
const OCEAN_SUBDIV := 180

# ---------- Estado ----------
var mode := "cinematic"   # cinematic, sail, fish, catch, port
var game_time := 7.0 * 60.0   # minutos desde el inicio
var day := 1
var money := 0
var debt := 500
var panic := 0.0
var lamp_on := false
var lamp_mult := 1.0   # mejora del farol (misión 1)
var speed_lvl := 0
var rows := 3
var cols := 6
var items: Array = []
var t := 0.0

# Barco
var bx := 0.0
var bz := -40.0
var ba := 0.0
var bv := 0.0

# Pesca
var fishing: Dictionary = {}
var pending: Dictionary = {}

# ---------- Nodos ----------
var env: Environment
var sky_mat: ProceduralSkyMaterial
var sun: DirectionalLight3D
var moon: DirectionalLight3D
var ocean: MeshInstance3D
var ocean_mat: ShaderMaterial
var boat: Node3D
var lamp_light: OmniLight3D
var lamp_mat: StandardMaterial3D
var port_light: OmniLight3D
var camera: Camera3D
var spots: Array = []
var eyes: Array = []
var eye_mat: StandardMaterial3D
var ui
var cine
var audio
var quest
var gear
var hazards
var weather
var life
var hull := 3
var hull_max := 3
var journal := {}   # especie -> {"n": vista normal, "m": vista mutante, "count": nº}


func _ready() -> void:
	randomize()
	_build_environment()
	_build_ocean()
	_build_land()
	_build_port()
	_build_boat()
	_build_spots()
	_build_eyes()
	camera = Camera3D.new()
	camera.fov = 55
	camera.far = 1500
	add_child(camera)
	camera.position = Vector3(bx, 13, bz + 20)
	ui = UI.new()
	ui.main = self
	add_child(ui)
	audio = Audio.new()
	audio.main = self
	add_child(audio)
	quest = Quest.new()
	quest.main = self
	add_child(quest)
	gear = Gear.new()
	gear.main = self
	add_child(gear)
	hazards = Hazards.new()
	hazards.main = self
	add_child(hazards)
	weather = Weather.new()
	weather.main = self
	add_child(weather)
	life = Life.new()
	life.main = self
	add_child(life)
	match start_action:
		"new":
			cine = Cinematic.new()
			cine.main = self
			add_child(cine)
		"continue":
			load_game()
			mode = "sail"
			ui.end_cinematic()
			ui.toast("Partida cargada. Día %d." % day)
		_:
			# Menú principal: el barco amarrado en Güímar al atardecer
			mode = "menu"
			game_time = 19.4 * 60.0
			bx = 4.5
			bz = -62.0
			ba = PI * 0.5
			ui.open_menu(has_save())
	start_action = ""
	_apply_light()


# ---------- Funciones del mundo ----------
static func wave(x: float, z: float, tt: float) -> float:
	return amp * (0.45 * sin(0.12 * x + tt * 0.8) + 0.30 * sin(0.17 * z - tt * 1.1) + 0.15 * sin(0.45 * (x + z) + tt * 1.7))


static func nz(x: float, z: float) -> float:
	return sin(x * 0.07) * cos(z * 0.09) + 0.5 * sin(x * 0.19 + z * 0.13) + 0.3 * cos(x * 0.31 - z * 0.27)


static func land_h(x: float, z: float) -> float:
	var inland := (SHORE - z) + nz(x * 0.6, z) * 8.0 + sin(x * 0.04) * 10.0
	return -4.0 + inland * 0.38 + nz(x, z) * 2.2


func hour() -> float:
	return fmod(game_time, 1440.0) / 60.0


func daylight() -> float:
	return clamp(sin(PI * (hour() - 5.5) / 14.5) * 1.6, 0.0, 1.0)


func is_night() -> bool:
	return daylight() < 0.3


func zone_name(z: float) -> String:
	if z < -25:
		return "Orilla"
	if z < 55:
		return "Aguas medias"
	return "Fondo profundo"


# ---------- Construcción ----------
func _mat(c: Color, rough := 0.9) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	return m


func _mesh(mesh: Mesh, mat: Material, pos: Vector3, parent: Node = self) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	parent.add_child(mi)
	return mi


func _build_environment() -> void:
	env = Environment.new()
	env.background_mode = Environment.BG_SKY
	sky_mat = ProceduralSkyMaterial.new()
	var sky := Sky.new()
	sky.sky_material = sky_mat
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.fog_enabled = true
	env.fog_sky_affect = 0.6
	env.glow_enabled = true
	env.glow_intensity = 0.9
	env.glow_bloom = 0.1
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)

	sun = DirectionalLight3D.new()
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 200
	add_child(sun)
	moon = DirectionalLight3D.new()
	moon.light_color = Color(0.55, 0.65, 0.9)
	moon.rotation_degrees = Vector3(-40, 140, 0)
	add_child(moon)


func _build_ocean() -> void:
	var pm := PlaneMesh.new()
	pm.size = Vector2(OCEAN_SIZE, OCEAN_SIZE)
	pm.subdivide_width = OCEAN_SUBDIV
	pm.subdivide_depth = OCEAN_SUBDIV
	ocean_mat = ShaderMaterial.new()
	ocean_mat.shader = OCEAN_SHADER
	ocean = _mesh(pm, ocean_mat, Vector3.ZERO)
	ocean.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


func _build_land() -> void:
	# Costa volcánica: rejilla de triángulos con sombreado plano (estilo low-poly).
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var x0 := -350.0
	var z0 := -330.0
	var nx := 140
	var nzc := 58
	var dx := 700.0 / nx
	var dz := 290.0 / nzc
	for i in nx:
		for j in nzc:
			var a := Vector2(x0 + i * dx, z0 + j * dz)
			var quad := [a, a + Vector2(dx, 0), a + Vector2(dx, dz), a + Vector2(0, dz)]
			var pts: Array = []
			for q in quad:
				var h: float = min(land_h(q.x, q.y), 30.0 + nz(q.x * 2.0, q.y) * 4.0)
				pts.append(Vector3(q.x, h, q.y))
			var cy: float = (pts[0].y + pts[1].y + pts[2].y + pts[3].y) / 4.0
			var col := Color("2a2522")
			if cy >= 0.6 and cy < 8.0:
				col = Color("3b3330").lerp(Color("5a6b3a"), clamp(nz(a.x * 1.7, a.y * 1.3), 0.0, 1.0) * 0.6)
			elif cy >= 8.0:
				col = Color("4a3d36")
			for idx in [0, 1, 2, 0, 2, 3]:
				st.set_color(col)
				st.add_vertex(pts[idx])
	st.generate_normals()
	var m := StandardMaterial3D.new()
	m.vertex_color_use_as_albedo = true
	m.roughness = 1.0
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	mi.material_override = m
	add_child(mi)

	# El Teide al fondo
	var cone := CylinderMesh.new()
	cone.top_radius = 0.0
	cone.bottom_radius = 150
	cone.height = 170
	cone.radial_segments = 9
	cone.rings = 4
	_mesh(cone, _mat(Color("5b4a40"), 1.0), Vector3(-90, 60, -330))
	var snow := CylinderMesh.new()
	snow.top_radius = 0.0
	snow.bottom_radius = 42
	snow.height = 48
	snow.radial_segments = 9
	_mesh(snow, _mat(Color("e9eef0"), 0.8), Vector3(-90, 121, -330))


func _build_port() -> void:
	var wood := _mat(Color("6b4a2f"), 1.0)
	var dock := BoxMesh.new()
	dock.size = Vector3(4, 0.6, 24)
	_mesh(dock, wood, Vector3(0, 0.9, -66))
	var post := CylinderMesh.new()
	post.top_radius = 0.25
	post.bottom_radius = 0.25
	post.height = 4
	for i in 5:
		_mesh(post, wood, Vector3(1.9 if i % 2 else -1.9, -0.8, -56 - i * 4))
	# Casas blancas de la caleta
	var house_cols := [Color("f3efe6"), Color("f0e6c8"), Color("e8eef0"), Color("f3d9b1"), Color.WHITE]
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for i in 14:
		var w := 3.0 + rng.randf() * 3.0
		var h := 2.5 + rng.randf() * 2.0
		var x := -26.0 + i * 4.0 + rng.randf() * 2.0
		var z := -84.0 - rng.randf() * 14.0
		var bm := BoxMesh.new()
		bm.size = Vector3(w, h + 3.0, w)
		_mesh(bm, _mat(house_cols[i % 5], 0.8), Vector3(x, max(land_h(x, z), 0.5) + h / 2.0 - 1.8, z))
	# Farola del muelle
	var pole := CylinderMesh.new()
	pole.top_radius = 0.12
	pole.bottom_radius = 0.12
	pole.height = 6
	_mesh(pole, _mat(Color("222222")), Vector3(1.6, 3.5, -72))
	var bulb := SphereMesh.new()
	bulb.radius = 0.45
	bulb.height = 0.9
	var bm2 := _mat(Color("ffc070"))
	bm2.emission_enabled = true
	bm2.emission = Color("ffb45a")
	bm2.emission_energy_multiplier = 3.0
	_mesh(bulb, bm2, Vector3(1.6, 6.6, -72))
	port_light = OmniLight3D.new()
	port_light.light_color = Color("ffb45a")
	port_light.omni_range = 40
	port_light.position = Vector3(1.6, 6.2, -72)
	add_child(port_light)


func _build_boat() -> void:
	# Barquillo canario de Acorán: blanco con franja azul y roja.
	var b := make_boat(Color("f2f2ec"), Color("1d5aa6"), Color("c0392b"))
	boat = b["node"]
	lamp_light = b["light"]
	lamp_mat = b["lamp_mat"]


func make_boat(hull_col: Color, stripe1: Color, stripe2: Color) -> Dictionary:
	var node := Node3D.new()
	add_child(node)
	var white := _mat(hull_col, 0.6)
	var hull := BoxMesh.new()
	hull.size = Vector3(2.4, 1.1, 5)
	_mesh(hull, white, Vector3(0, 0.2, 0), node)
	var bow := PrismMesh.new()
	bow.size = Vector3(2.4, 2.2, 1.1)
	var bow_mi := _mesh(bow, white, Vector3(0, 0.2, -3.6), node)
	bow_mi.rotation_degrees.x = -90
	var s1 := BoxMesh.new()
	s1.size = Vector3(2.46, 0.22, 5.02)
	_mesh(s1, _mat(stripe1, 0.5), Vector3(0, 0.55, 0), node)
	var s2 := BoxMesh.new()
	s2.size = Vector3(2.46, 0.12, 5.02)
	_mesh(s2, _mat(stripe2, 0.5), Vector3(0, 0.3, 0), node)
	var cabin := BoxMesh.new()
	cabin.size = Vector3(1.6, 1.2, 1.6)
	_mesh(cabin, _mat(hull_col.darkened(0.08), 0.7), Vector3(0, 1.3, 0.9), node)
	var mast := CylinderMesh.new()
	mast.top_radius = 0.07
	mast.bottom_radius = 0.07
	mast.height = 3
	_mesh(mast, _mat(Color("6b4a2f")), Vector3(0, 2.6, -0.6), node)
	var bulb := SphereMesh.new()
	bulb.radius = 0.22
	bulb.height = 0.44
	var lm := _mat(Color("553311"))
	lm.emission_enabled = true
	lm.emission = Color("ffe7a0")
	lm.emission_energy_multiplier = 0.0
	_mesh(bulb, lm, Vector3(0, 4.1, -0.6), node)
	var light := OmniLight3D.new()
	light.light_color = Color("ffd27a")
	light.omni_range = 38
	light.shadow_enabled = true
	light.light_energy = 0.0
	light.position = Vector3(0, 4.2, -0.6)
	node.add_child(light)
	return {"node": node, "light": light, "lamp_mat": lm}


func _build_spots() -> void:
	var bub_mat := StandardMaterial3D.new()
	bub_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	bub_mat.albedo_color = Color(0.92, 0.98, 1.0, 0.85)
	bub_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	var ring_mat := bub_mat.duplicate()
	ring_mat.albedo_color = Color(0.92, 0.98, 1.0, 0.35)
	for s in Data.SPOTS:
		var g := Node3D.new()
		g.position = Vector3(s[0], 0, s[1])
		add_child(g)
		var bubs: Array = []
		for i in 7:
			var sm := SphereMesh.new()
			sm.radius = 0.22
			sm.height = 0.44
			var mi := _mesh(sm, bub_mat, Vector3.ZERO, g)
			bubs.append({"m": mi, "o": randf() * 6.0, "r": 0.6 + randf() * 1.4})
		var tm := TorusMesh.new()
		tm.inner_radius = 2.2
		tm.outer_radius = 2.5
		var ring := _mesh(tm, ring_mat, Vector3.ZERO, g)
		spots.append({"g": g, "bub": bubs, "ring": ring, "zone": s[2], "x": float(s[0]), "z": float(s[1]), "left": 1, "back": 0.0})


func _build_eyes() -> void:
	# Ojos de Tibicena: aparecen en la oscuridad cuando el miedo sube.
	eye_mat = StandardMaterial3D.new()
	eye_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	eye_mat.albedo_color = Color(1, 0.16, 0.1, 0)
	eye_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	eye_mat.set("disable_fog", true)
	var sm := SphereMesh.new()
	sm.radius = 0.28
	sm.height = 0.56
	for i in 5:
		var g := Node3D.new()
		add_child(g)
		_mesh(sm, eye_mat, Vector3(-0.5, 0, 0), g)
		_mesh(sm, eye_mat, Vector3(0.5, 0, 0), g)
		eyes.append({"g": g, "ang": randf() * TAU, "dist": 45.0})


# ---------- Tiempo y luz ----------
func advance(minutes: float) -> void:
	var before := int(game_time / 1440.0)
	game_time += minutes
	var after := int(game_time / 1440.0)
	if after > before:
		day = after + 1
		for s in spots:
			s["left"] = 1
		ui.toast("Amanece el día %d. Los cardúmenes han vuelto." % day)


func _apply_light() -> void:
	var l := daylight()
	var h := hour()
	var day_top := Color("4f8fbf")
	var day_hor := Color("a9cbd8")
	var night_top := Color("02060c")
	var night_hor := Color("0a1520")
	var dusk := Color("d98a5f")
	var dusk_amt := 0.0
	if (h > 17.0 and h < 20.5) or (h > 5.0 and h < 7.5):
		dusk_amt = max(0.0, 1.0 - abs(l - 0.45) * 2.2)
	var hor := night_hor.lerp(day_hor, l).lerp(dusk, dusk_amt * 0.6)
	sky_mat.sky_top_color = night_top.lerp(day_top, l)
	sky_mat.sky_horizon_color = hor
	sky_mat.ground_horizon_color = hor
	sky_mat.ground_bottom_color = night_top.lerp(Color("1b2a2f"), l)
	sky_mat.sun_angle_max = 30
	var wb: Dictionary = weather.blend if weather else {"fog": 0.0, "tint": Color(0, 0, 0, 0), "sun": 1.0}
	var tint: Color = wb["tint"]
	hor = hor.lerp(Color(tint.r, tint.g, tint.b) * (0.25 + 0.75 * l), tint.a)
	sky_mat.sky_horizon_color = hor
	sky_mat.ground_horizon_color = hor
	sky_mat.sky_top_color = sky_mat.sky_top_color.lerp(hor, tint.a * 0.6)
	env.fog_light_color = hor
	env.fog_density = lerp(0.03, 0.004, l) + panic * 0.00015 + float(wb["fog"])
	env.ambient_light_energy = 0.2 + l * 0.5
	# Sol: sube y baja con la hora
	var sun_elev := sin(PI * (h - 6.0) / 12.0) * 70.0
	sun.rotation_degrees = Vector3(-max(sun_elev, -5.0), -30.0 + (h - 12.0) * 10.0, 0)
	sun.light_energy = (0.05 + l * 0.95) * float(wb["sun"])
	sun.light_color = Color(1.0, 0.9, 0.75).lerp(Color("ffb070"), dusk_amt)
	moon.light_energy = (1.0 - l) * 0.25
	port_light.light_energy = (1.0 - l * 2.0) * 2.5 if l < 0.5 else 0.0
	if mode != "cinematic":
		lamp_light.light_energy = (1.6 + (1.0 - l) * 1.4) if lamp_on else 0.0
		lamp_mat.emission_energy_multiplier = 4.0 if lamp_on else 0.0
	ocean_mat.set_shader_parameter("daylight", l)


# ---------- Acciones ----------
func near_spot():
	var best = null
	var bd := 6.5
	for s in spots:
		var d := Vector2(s["x"] - bx, s["z"] - bz).length()
		if d < bd and s["left"] > 0:
			bd = d
			best = s
	return best


func near_port() -> bool:
	return Vector2(bx - PORT.x, bz - PORT.z).length() < 9.0


func act() -> void:
	if mode != "sail":
		return
	if quest.try_interact():
		return
	if gear.try_interact():
		return
	if near_port():
		mode = "port"
		bv = 0.0
		ui.open_port()
		return
	var s = near_spot()
	if s != null:
		start_fishing(s)
		return
	ui.toast("No hay nada aquí. Busca las burbujas en el agua.")


func toggle_lamp() -> void:
	lamp_on = not lamp_on
	audio.sfx("lamp", -6.0, 1.0 if lamp_on else 0.8)
	ui.toast("Farol de Magec encendido." if lamp_on else "Farol apagado.")


func start_fishing(s: Dictionary) -> void:
	var night := is_night()
	var pool: Array = Data.ZONES[s["zone"]]["fish"]
	var key: String = pool[randi() % pool.size()]
	var g: String = Data.FISH[key]["game"]
	var gi: Dictionary = Data.GAMES[g]
	var base: float = ((1.25 if night else 0.85) + (0.25 if s["zone"] == "fondo" else 0.0)) * gi["speed"]
	fishing = {
		"spot": s, "key": key, "mut": night, "p": 0.0, "dir": 1.0, "game": g, "need": gi["hits"],
		"speed": base, "base": base, "w": (0.1 if night else 0.15) * gi["w"], "zs": 0.0, "zdir": 1.0,
		"timer": 0.6, "vis": 1.0, "hits": 0, "miss": 0,
	}
	_new_zone()
	mode = "fish"
	bv = 0.0
	audio.sfx("splash")
	advance(15)
	var title: String = "Algo muerde en la oscuridad…" if night else gi["title"]
	ui.open_fishing(title, gi["sub"] + ("  De noche, el agua dorada parpadea." if night else ""))


func start_special_fishing() -> void:
	fishing = {
		"spot": null, "key": "", "mut": true, "special": true, "p": 0.0, "dir": 1.0,
		"speed": 1.2, "base": 1.2, "w": 0.1, "zs": 0.0, "zdir": 1.0, "game": "tiron", "need": 3,
		"timer": 0.6, "vis": 1.0, "hits": 0, "miss": 0,
	}
	_new_zone()
	mode = "fish"
	bv = 0.0
	audio.sfx("splash", 0.0, 0.7)
	advance(15)
	ui.open_fishing("¡Algo muy pesado tira del sedal!")


func _update_minigame(dt: float) -> void:
	var f := fishing
	f["timer"] -= dt
	match f.get("game", "normal"):
		"zigzag":
			# cambia de rumbo y de velocidad sin avisar
			if f["timer"] <= 0.0:
				f["timer"] = randf_range(0.35, 0.9)
				if randf() < 0.55:
					f["dir"] = -f["dir"]
				f["speed"] = f["base"] * randf_range(0.6, 1.7)
		"tiron":
			# el agua dorada se desplaza, y de vez en cuando pega un tirón
			f["zs"] += f["zdir"] * 0.22 * dt
			if f["zs"] < 0.04 or f["zs"] > 0.96 - f["w"]:
				f["zdir"] = -f["zdir"]
				f["zs"] = clamp(f["zs"], 0.04, 0.96 - f["w"])
			if f["timer"] <= 0.0:
				f["timer"] = randf_range(1.0, 2.2)
				f["speed"] = f["base"] * 2.2
				audio.sfx("miss", -16.0, 0.6)
			else:
				f["speed"] = move_toward(f["speed"], f["base"], dt * 1.5)
	# los mutantes hacen parpadear el agua dorada
	if f["mut"]:
		f["vis"] = 0.25 if sin(t * 5.3) * sin(t * 2.1) > 0.35 else 1.0


func register_catch(key: String, mut: bool) -> bool:
	var e: Dictionary = journal.get(key, {"n": false, "m": false, "count": 0})
	var is_new: bool = not e["m" if mut else "n"]
	e["m" if mut else "n"] = true
	e["count"] = int(e["count"]) + 1
	journal[key] = e
	return is_new


func add_catch(key: String, mut: bool) -> bool:
	## Mete un pez directamente en la bodega (nasas y red).
	var slot = find_slot(Data.FISH[key]["shape"])
	if slot == null:
		return false
	items.append({"key": key, "mut": mut, "shape": slot["shape"], "r": slot["r"], "c": slot["c"]})
	if register_catch(key, mut):
		ui.toast_new_species(key, mut)
	ui.refresh_hold()
	return true


func _new_zone() -> void:
	fishing["zs"] = 0.08 + randf() * (0.84 - fishing["w"])


func strike() -> void:
	if mode != "fish":
		return
	var p: float = fishing["p"]
	if p >= fishing["zs"] and p <= fishing["zs"] + fishing["w"]:
		fishing["hits"] += 1
		fishing["speed"] *= 1.12
		audio.sfx("hit", -4.0, 1.0 + fishing["hits"] * 0.12)
		_new_zone()
	else:
		fishing["miss"] += 1
		audio.sfx("miss", -4.0)
	if fishing["hits"] >= fishing.get("need", 3):
		end_fishing(true)
	elif fishing["miss"] >= 3:
		end_fishing(false)


func end_fishing(ok: bool, cancel := false) -> void:
	ui.close_fishing()
	if ok and fishing.get("special", false):
		fishing = {}
		mode = "sail"
		quest.got_stone()
		return
	if ok:
		# El banco se agota y vuelve a aparecer unas horas después
		fishing["spot"]["left"] = 0
		fishing["spot"]["back"] = game_time + randf_range(5.0, 9.0) * 60.0
		pending = {"key": fishing["key"], "mut": fishing["mut"]}
		mode = "catch"
		if pending["mut"]:
			panic = min(100.0, panic + 10.0)
		audio.sfx("mutant" if pending["mut"] else "catch", -2.0)
		var is_new := register_catch(pending["key"], pending["mut"])
		ui.open_catch(pending["key"], pending["mut"], find_slot(Data.FISH[pending["key"]]["shape"]) != null, is_new)
	else:
		mode = "sail"
		ui.toast("Recoges el sedal." if cancel else "Se ha escapado.")
		if fishing.get("mut", false) and not cancel:
			panic = min(100.0, panic + 6.0)
	fishing = {} if not ok else fishing


func keep_catch() -> void:
	var slot = find_slot(Data.FISH[pending["key"]]["shape"])
	if slot != null:
		items.append({"key": pending["key"], "mut": pending["mut"], "shape": slot["shape"], "r": slot["r"], "c": slot["c"]})
		ui.toast("Guardado: " + Data.fish_name(pending["key"], pending["mut"]))
	mode = "sail"
	ui.refresh_hold()


func release_catch() -> void:
	mode = "sail"
	ui.toast("Lo devuelves al mar.")


# ---------- Bodega tipo Tetris ----------
static func rot(sh: Array) -> Array:
	var r := sh.size()
	var c: int = sh[0].size()
	var o: Array = []
	for j in c:
		var row: Array = []
		for i in range(r - 1, -1, -1):
			row.append(sh[i][j])
		o.append(row)
	return o


func occupancy() -> Array:
	var g: Array = []
	for r in rows:
		var row: Array = []
		row.resize(cols)
		row.fill(false)
		g.append(row)
	for it in items:
		var sh: Array = it["shape"]
		for i in sh.size():
			for j in sh[i].size():
				if sh[i][j]:
					g[it["r"] + i][it["c"] + j] = true
	return g


func find_slot(shape: Array):
	var g := occupancy()
	for sh in [shape, rot(shape)]:
		for r in range(0, rows - sh.size() + 1):
			for c in range(0, cols - sh[0].size() + 1):
				var ok := true
				for i in sh.size():
					for j in sh[0].size():
						if sh[i][j] and g[r + i][c + j]:
							ok = false
				if ok:
					return {"r": r, "c": c, "shape": sh}
	return null


func drop_item(idx: int) -> void:
	if idx >= 0 and idx < items.size():
		items.remove_at(idx)
		ui.refresh_hold()


# ---------- Puerto ----------
func hold_value() -> int:
	var total := 0
	for it in items:
		total += Data.fish_value(it["key"], it["mut"])
	return total


func sell_all() -> void:
	var total := hold_value()
	var muts := 0
	for it in items:
		if it["mut"]:
			muts += 1
	money += total
	items.clear()
	ui.toast("El comprador no hace preguntas sobre los peces raros." if muts > 0 else "Vendido por %d €." % total)


func pay_debt() -> void:
	var p: int = min(money, debt)
	money -= p
	debt -= p
	if debt == 0:
		ui.toast("El barco es tuyo. Aridane estaría orgulloso.")


func engine_price() -> int:
	return 220 if speed_lvl == 1 else 120


func hold_price() -> int:
	return 260 if rows == 4 else 150


func buy_engine() -> void:
	if speed_lvl < 2 and money >= engine_price():
		money -= engine_price()
		speed_lvl += 1
		ui.toast("Motor mejorado.")


func buy_hold() -> void:
	if rows < 5 and money >= hold_price():
		money -= hold_price()
		rows += 1
		ui.toast("Bodega ampliada.")


func sleep() -> void:
	var d := int(game_time / 1440.0) + (1 if hour() >= 6.0 else 0)
	game_time = d * 1440.0 + 360.0
	day = d + 1
	panic = 0.0
	for s in spots:
		s["left"] = 1
	ui.toast("Duermes en casa. Amanece el día %d. Partida guardada." % day)
	save_game()


func leave_port() -> void:
	mode = "sail"
	save_game()


# ---------- Guardar y cargar ----------
static func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func save_game() -> void:
	var its: Array = []
	for it in items:
		its.append({"key": it["key"], "mut": it["mut"], "shape": it["shape"], "r": it["r"], "c": it["c"]})
	var left: Array = []
	for s in spots:
		left.append([s["left"], s["back"]])
	var data := {
		"version": 1,
		"game_time": game_time, "day": day, "money": money, "debt": debt,
		"lamp_mult": lamp_mult, "speed_lvl": speed_lvl, "rows": rows,
		"items": its, "spots": left,
		"bx": bx, "bz": bz, "ba": ba,
		"quest_state": quest.state, "stones": quest.stones,
		"journal": journal, "gear": gear.to_dict(),
		"hull": hull, "weather": weather.to_dict(),
	}
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(data, "\t"))
		f.close()


func load_game() -> bool:
	if not has_save():
		return false
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return false
	var d = JSON.parse_string(f.get_as_text())
	f.close()
	if typeof(d) != TYPE_DICTIONARY:
		return false
	game_time = float(d.get("game_time", 420.0))
	day = int(d.get("day", 1))
	money = int(d.get("money", 0))
	debt = int(d.get("debt", 500))
	lamp_mult = float(d.get("lamp_mult", 1.0))
	speed_lvl = int(d.get("speed_lvl", 0))
	rows = int(d.get("rows", 3))
	bx = float(d.get("bx", 0.0))
	bz = float(d.get("bz", -46.0))
	ba = float(d.get("ba", PI))
	items.clear()
	for it in d.get("items", []):
		var sh: Array = []
		for row in it["shape"]:
			var r2: Array = []
			for v in row:
				r2.append(int(v))
			sh.append(r2)
		items.append({"key": str(it["key"]), "mut": bool(it["mut"]), "shape": sh, "r": int(it["r"]), "c": int(it["c"])})
	var left: Array = d.get("spots", [])
	for i in min(left.size(), spots.size()):
		if typeof(left[i]) == TYPE_ARRAY:
			spots[i]["left"] = int(left[i][0])
			spots[i]["back"] = float(left[i][1])
		else:
			spots[i]["left"] = min(int(left[i]), 1)
	quest.state = str(d.get("quest_state", "talk1"))
	quest.stones = int(d.get("stones", 0))
	journal = d.get("journal", {})
	gear.from_dict(d.get("gear", {}))
	hull = int(d.get("hull", hull_max))
	weather.from_dict(d.get("weather", {}))
	camera.position = Vector3(bx + sin(ba) * 20.0, 13.0, bz + cos(ba) * 20.0)
	return true


func new_game() -> void:
	start_action = "new"
	get_tree().paused = false
	get_tree().reload_current_scene()


func continue_game() -> void:
	start_action = "continue"
	get_tree().paused = false
	get_tree().reload_current_scene()


func to_main_menu() -> void:
	start_action = ""
	get_tree().paused = false
	get_tree().reload_current_scene()


# ---------- Entrada ----------
func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	var k: int = event.physical_keycode
	if mode == "talk":
		if k in [KEY_E, KEY_SPACE, KEY_ENTER]:
			quest.next_line()
		return
	if mode == "fish":
		if k == KEY_SPACE or k == KEY_E:
			strike()
		elif k == KEY_ESCAPE:
			end_fishing(false, true)
		return
	if mode == "sail" and k == KEY_ESCAPE:
		ui.open_pause()
		get_viewport().set_input_as_handled()
		return
	if mode != "sail":
		return
	match k:
		KEY_E:
			act()
		KEY_F:
			toggle_lamp()
		KEY_I, KEY_TAB:
			ui.toggle_hold()
		KEY_C:
			ui.toggle_journal()
		KEY_N:
			gear.drop_nasa()
		KEY_R:
			gear.toggle_net()


# ---------- Bucle ----------
func _process(delta: float) -> void:
	var dt: float = min(delta, 0.05)
	t += dt
	if mode != "cinematic" and mode != "menu":
		amp = move_toward(amp, float(weather.blend["amp"]), dt * 0.3)
	_update_boat(dt)
	_update_world(dt)
	_update_panic(dt)
	_apply_light()
	if mode == "fish":
		_update_minigame(dt)
		fishing["p"] += fishing["dir"] * fishing["speed"] * dt
		if fishing["p"] > 1.0:
			fishing["p"] = 1.0
			fishing["dir"] = -1.0
		elif fishing["p"] < 0.0:
			fishing["p"] = 0.0
			fishing["dir"] = 1.0
	ui.update_hud()


func _update_boat(dt: float) -> void:
	if mode == "sail":
		var up := Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP)
		var dn := Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN)
		var lf := Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT)
		var rt := Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT)
		var vmax: float = (9.0 + speed_lvl * 3.5) * gear.speed_mult()
		if up:
			bv += 10.0 * dt
		if dn:
			bv -= 7.0 * dt
		bv = clamp(bv, -3.0, vmax)
		bv *= 1.0 - 0.6 * dt
		var turn := (1.0 if lf else 0.0) - (1.0 if rt else 0.0)
		ba += turn * dt * (0.5 + min(1.0, abs(bv) / 6.0)) * 1.1
		if abs(bv) > 0.6:
			advance(dt * abs(bv) * 1.6)
	else:
		bv *= 1.0 - 3.0 * dt

	var nx := bx - sin(ba) * bv * dt
	var nzp := bz - cos(ba) * bv * dt
	var on_dock: bool = abs(nx) < 2.6 and nzp < -53.0 and nzp > -79.0
	if hazards.rock_at(nx, nzp) != null:
		hazards.hit_rock(bv)
		bv *= -0.4
	elif land_h(nx, nzp) > -0.8 or on_dock:
		if abs(bv) > 0.5:
			ui.toast("¡Cuidado con las rocas!")
		bv *= -0.3
	elif Vector2(nx, nzp - 20.0).length() > 200.0:
		bv *= -0.3
		ui.toast("Las corrientes te empujan de vuelta.")
	else:
		bx = nx
		bz = nzp

	var wy := wave(bx, bz, t)
	var gx := wave(bx + 1.0, bz, t) - wy
	var gz := wave(bx, bz + 1.0, t) - wy
	boat.position = Vector3(bx, wy + 0.1, bz)
	boat.basis = Basis.from_euler(Vector3(gz * 0.8, ba, -gx * 0.8))

	var target := Vector3(bx + sin(ba) * 20.0, 13.0, bz + cos(ba) * 20.0)
	if mode == "menu":
		var a := t * 0.05 + 2.2
		camera.position = Vector3(4.5 + cos(a) * 30.0, 9.0, -50.0 + sin(a) * 18.0)
		camera.look_at(Vector3(-10, 6, -90))
	elif mode != "cinematic":
		camera.position = camera.position.lerp(target, 1.0 - pow(0.02, dt))
		camera.look_at(Vector3(bx, 1.5, bz))


func _update_world(dt: float) -> void:
	var cell := OCEAN_SIZE / OCEAN_SUBDIV
	ocean.position = Vector3(round(bx / cell) * cell, 0, round(bz / cell) * cell)
	ocean_mat.set_shader_parameter("time_s", t)
	ocean_mat.set_shader_parameter("amp", amp)
	for s in spots:
		if s["left"] == 0 and game_time >= s["back"]:
			s["left"] = 1
		var vis: bool = s["left"] > 0
		s["g"].visible = vis
		if not vis:
			continue
		s["g"].position.y = wave(s["x"], s["z"], t) + 0.15
		var i := 0
		for b in s["bub"]:
			var k := fmod(t * 0.9 + b["o"], 2.0)
			b["m"].position = Vector3(cos(i * 0.9 + t * 0.3) * b["r"], k * 0.6, sin(i * 1.3) * b["r"])
			b["m"].scale = Vector3.ONE * (1.0 - k * 0.4)
			i += 1
		s["ring"].scale = Vector3.ONE * (1.0 + 0.15 * sin(t * 2.0))


func _update_panic(dt: float) -> void:
	if mode == "cinematic" or mode == "menu":
		return
	var night := is_night()
	var in_port := Vector2(bx - PORT.x, bz - PORT.z).length() < 26.0
	if in_port:
		panic = max(0.0, panic - dt * 12.0)
	elif night:
		var far: float = max(0.0, bz + 40.0) / 120.0
		panic = min(100.0, panic + dt * ((0.8 * lamp_mult if lamp_on else 3.2) + far * 2.2))
	else:
		panic = max(0.0, panic - dt * 3.0)
	if night and not in_port:
		hazards.maybe_hunt(dt)
	panic = min(panic, 100.0)

	# Ojos de Tibicena
	var eye_on := night and panic > 35.0 and not in_port
	var target_a: float = clamp((panic - 35.0) / 40.0, 0.0, 1.0) if eye_on else 0.0
	var c := eye_mat.albedo_color
	c.a += (target_a - c.a) * dt * 2.0
	eye_mat.albedo_color = c
	var idx := 0
	for e in eyes:
		e["ang"] += dt * 0.05 * (1.0 if idx % 2 else -1.0)
		var target_d: float = 38.0 if lamp_on else max(14.0, 40.0 - panic * 0.3)
		e["dist"] += (target_d - e["dist"]) * dt * 0.4
		var ex: float = bx + cos(e["ang"] + idx * 1.25) * e["dist"]
		var ez: float = bz + sin(e["ang"] + idx * 1.25) * e["dist"]
		var g: Node3D = e["g"]
		g.position = Vector3(ex, wave(ex, ez, t) + 0.6, ez)
		g.look_at(Vector3(bx, g.position.y, bz))
		g.scale = Vector3(1, 0.1 if sin(t * 1.7 + idx * 3.0) > 0.97 else 1.0, 1)
		idx += 1
