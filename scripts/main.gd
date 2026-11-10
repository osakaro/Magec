extends Node3D
## MAGEC - escena principal. Construye la costa de Güímar, el mar y el barco,
## y lleva la lógica de pesca, tiempo, miedo, bodega y puerto.

const Data = preload("res://scripts/data.gd")
const UI = preload("res://scripts/ui.gd")
const OCEAN_SHADER = preload("res://shaders/ocean.gdshader")
const SKY_SHADER = preload("res://shaders/sky.gdshader")
const TERRAIN_SHADER = preload("res://shaders/terrain.gdshader")
const Props = preload("res://scripts/props.gd")
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

# Relieve de la isla actual (cada isla desplaza el ruido del terreno)
static var land_seed := 0.0
static var land_steep := 0.38   # La Gomera tiene costas más empinadas

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
var bturn := 0.0   # velocidad de giro (con inercia)
var wake_pts: Array = []   # estela: [x, z, edad, velocidad]
var wake_timer := 0.0
var spray: GPUParticles3D

# Pesca
var fishing: Dictionary = {}
var pending: Dictionary = {}

# ---------- Nodos ----------
var env: Environment
var sky_mat: ShaderMaterial
var terrain_mat: ShaderMaterial
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
var region := "tenerife"
var journal := {}   # especie -> {"n": vista normal, "m": vista mutante, "count": nº}


func _ready() -> void:
	randomize()
	if start_action == "continue":
		region = peek_region()
	land_seed = Data.REGIONS[region]["seed"]
	var steep := {"la_gomera": 0.62, "lanzarote": 0.42, "fuerteventura": 0.22, "la_palma": 0.7, "el_hierro": 0.55}
	land_steep = steep.get(region, 0.38)
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
	var sx := x + land_seed
	var inland := (SHORE - z) + nz(sx * 0.6, z) * 8.0 + sin(sx * 0.04) * 10.0
	return -4.0 + inland * land_steep + nz(sx, z) * 2.2


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


func _noise_tex(freq: float, size: int, normal_map: bool, seed_v: int, octaves := 4) -> NoiseTexture2D:
	var n := FastNoiseLite.new()
	n.seed = seed_v
	n.frequency = freq
	n.fractal_octaves = octaves
	var tx := NoiseTexture2D.new()
	tx.width = size
	tx.height = size
	tx.seamless = true
	tx.as_normal_map = normal_map
	if normal_map:
		tx.bump_strength = 4.0
	tx.generate_mipmaps = true
	tx.noise = n
	return tx


func _build_environment() -> void:
	env = Environment.new()
	env.background_mode = Environment.BG_SKY
	sky_mat = ShaderMaterial.new()
	sky_mat.shader = SKY_SHADER
	sky_mat.set_shader_parameter("cloud_noise", _noise_tex(0.008, 512, false, 3, 5))
	var sky := Sky.new()
	sky.sky_material = sky_mat
	sky.radiance_size = Sky.RADIANCE_SIZE_128
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.tonemap_exposure = 1.0
	env.tonemap_white = 6.0
	env.ssao_enabled = true
	env.ssao_radius = 1.4
	env.ssao_intensity = 1.6
	env.fog_enabled = true
	env.fog_sky_affect = 0.35
	env.fog_aerial_perspective = 0.55
	env.glow_enabled = true
	env.glow_intensity = 0.7
	env.glow_bloom = 0.06
	env.glow_hdr_threshold = 1.1
	env.ssil_enabled = true
	env.ssil_intensity = 0.8
	env.volumetric_fog_enabled = true
	env.volumetric_fog_density = 0.004
	env.volumetric_fog_anisotropy = 0.55
	env.volumetric_fog_length = 120.0
	env.volumetric_fog_sky_affect = 0.0
	env.adjustment_enabled = true
	env.adjustment_contrast = 1.08
	env.adjustment_saturation = 1.08
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)

	sun = DirectionalLight3D.new()
	sun.shadow_enabled = true
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
	sun.directional_shadow_max_distance = 220
	sun.shadow_blur = 1.5
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
	ocean_mat.set_shader_parameter("normal_a", _noise_tex(0.02, 512, true, 7))
	ocean_mat.set_shader_parameter("normal_b", _noise_tex(0.035, 512, true, 13))
	ocean_mat.set_shader_parameter("foam_noise", _noise_tex(0.03, 256, false, 21, 3))
	ocean = _mesh(pm, ocean_mat, Vector3.ZERO)
	ocean.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


func apply_terrain_tex(m: ShaderMaterial) -> void:
	## Texturas fotográficas del terreno (Poly Haven, CC0).
	var sets := {"rock": "rock_face", "lava": "aerial_rocks_04", "sand": "coast_sand_01", "ground": "dry_ground_01"}
	for k in sets:
		var a: Texture2D = Props.tex(sets[k], "albedo")
		var n: Texture2D = Props.tex(sets[k], "normal")
		if a == null:
			m.set_shader_parameter("use_textures", false)
			return
		m.set_shader_parameter(k + "_alb", a)
		m.set_shader_parameter(k + "_nrm", n)


func _build_land() -> void:
	# Costa volcánica con sombreado suave; el color lo pone el shader del terreno.
	terrain_mat = ShaderMaterial.new()
	terrain_mat.shader = TERRAIN_SHADER
	terrain_mat.set_shader_parameter("detail", _noise_tex(0.02, 512, false, 31, 5))
	apply_terrain_tex(terrain_mat)
	if region != "tenerife":
		terrain_mat.set_shader_parameter("snow_line", 9999.0)
	var looks := {
		"lanzarote": {"earth": Color(0.12, 0.1, 0.09), "scrub": Color(0.3, 0.16, 0.1), "basalt": Color(0.07, 0.06, 0.06), "green": 0.0},
		"fuerteventura": {"earth": Color(0.7, 0.58, 0.42), "scrub": Color(0.5, 0.46, 0.3), "basalt": Color(0.38, 0.3, 0.24), "sand": Color(0.86, 0.8, 0.66), "green": 0.0},
		"la_palma": {"earth": Color(0.28, 0.21, 0.15), "scrub": Color(0.18, 0.32, 0.13), "green": 0.8},
		"el_hierro": {"earth": Color(0.24, 0.18, 0.14), "scrub": Color(0.24, 0.32, 0.15), "green": 0.45},
	}
	if looks.has(region):
		for k in looks[region]:
			terrain_mat.set_shader_parameter(k, looks[region][k])
	if region == "la_gomera":
		terrain_mat.set_shader_parameter("green", 1.0)
		terrain_mat.set_shader_parameter("scrub", Color(0.17, 0.3, 0.12))
		terrain_mat.set_shader_parameter("earth", Color(0.3, 0.22, 0.15))
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var x0 := -350.0
	var z0 := -330.0
	var nx := 280
	var nzc := 116
	var dx := 700.0 / nx
	var dz := 290.0 / nzc
	for j in nzc + 1:
		for i in nx + 1:
			var x := x0 + i * dx
			var z := z0 + j * dz
			var h: float = min(land_h(x, z), 30.0 + nz(x * 2.0, z) * 4.0)
			st.add_vertex(Vector3(x, h, z))
	for j in nzc:
		for i in nx:
			var a := j * (nx + 1) + i
			var b := a + nx + 1
			st.add_index(a)
			st.add_index(a + 1)
			st.add_index(b)
			st.add_index(a + 1)
			st.add_index(b + 1)
			st.add_index(b)
	st.generate_normals()
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	mi.material_override = terrain_mat
	add_child(mi)
	_build_vegetation()

	if region == "gran_canaria":
		_build_gc_mountains()
		return
	if region == "la_gomera":
		_build_lg_mountains()
		return
	match region:
		"lanzarote":
			_mountain(Vector3(-60, -10, -300), 200.0, 105.0, 11)   # Famara
			_volcano(Vector3(-150, -6, -190), 55.0, 45.0, Color(0.42, 0.17, 0.11))
			_volcano(Vector3(80, -6, -210), 48.0, 38.0, Color(0.32, 0.14, 0.1))
			_volcano(Vector3(190, -6, -170), 40.0, 30.0, Color(0.45, 0.2, 0.12))
		"fuerteventura":
			_mountain(Vector3(-80, -10, -320), 180.0, 70.0, 12)
			_mountain(Vector3(110, -10, -300), 160.0, 60.0, 13)
			for i in 6:
				_mountain(Vector3(-150 + i * 60, -2.0, -110 - (i % 2) * 18), 26.0, 9.0, 40 + i)   # dunas
		"la_palma":
			_mountain(Vector3(-60, -10, -330), 200.0, 170.0, 14)   # Caldera de Taburiente
			_mountain(Vector3(120, -10, -320), 170.0, 140.0, 15)
			_volcano(Vector3(-150, -6, -170), 50.0, 55.0, Color(0.08, 0.07, 0.07), true)   # Tajogaite
		"el_hierro":
			_mountain(Vector3(-40, -10, -320), 190.0, 130.0, 16)
			_mountain(Vector3(150, -10, -300), 150.0, 100.0, 17)
	# El Teide al fondo, con nieve en la cumbre
	_mountain(Vector3(-90, -10, -330), 175.0, 190.0, 1)
	_mountain(Vector3(60, -10, -360), 150.0, 120.0, 2)
	_mountain(Vector3(-260, -10, -300), 140.0, 100.0, 3)


func _mountain(center: Vector3, radius: float, height: float, seed_v: int) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rings := 18
	var segs := 36
	st.add_vertex(center + Vector3(0, height, 0))
	for r in range(1, rings + 1):
		var k := float(r) / rings
		for sgm in segs:
			var a := TAU * sgm / segs
			var rr := radius * k * (0.85 + 0.15 * sin(a * 3.0 + seed_v))
			var x := center.x + cos(a) * rr
			var z := center.z + sin(a) * rr
			var y := center.y + height * pow(1.0 - k, 1.35) + nz(x * 0.8 + seed_v * 20.0, z * 0.8) * 7.0 * k
			st.add_vertex(Vector3(x, y, z))
	for sgm in segs:
		st.add_index(0)
		st.add_index(1 + (sgm + 1) % segs)
		st.add_index(1 + sgm)
	for r in range(0, rings - 1):
		for sgm in segs:
			var a := 1 + r * segs + sgm
			var b := 1 + r * segs + (sgm + 1) % segs
			var c := a + segs
			var d := b + segs
			st.add_index(a)
			st.add_index(b)
			st.add_index(c)
			st.add_index(b)
			st.add_index(d)
			st.add_index(c)
	st.generate_normals()
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	mi.material_override = terrain_mat
	add_child(mi)


func _build_lg_mountains() -> void:
	# Garajonay y los barrancos de La Gomera; al este, el Teide al otro lado del mar
	_mountain(Vector3(-40, -10, -300), 170.0, 110.0, 7)
	_mountain(Vector3(90, -10, -320), 150.0, 95.0, 8)
	_mountain(Vector3(-200, -10, -290), 160.0, 100.0, 9)
	var far_mat := ShaderMaterial.new()
	far_mat.shader = TERRAIN_SHADER
	far_mat.set_shader_parameter("detail", terrain_mat.get_shader_parameter("detail"))
	far_mat.set_shader_parameter("snow_line", 190.0)
	apply_terrain_tex(far_mat)
	var keep := terrain_mat
	terrain_mat = far_mat
	_mountain(Vector3(760, -30, 120), 360.0, 300.0, 1)
	terrain_mat = keep


func _volcano(center: Vector3, radius: float, height: float, col: Color, smoking := false) -> void:
	## Cono volcánico con cráter (picón rojo o negro).
	var keep := terrain_mat
	var vm := ShaderMaterial.new()
	vm.shader = TERRAIN_SHADER
	vm.set_shader_parameter("detail", terrain_mat.get_shader_parameter("detail"))
	vm.set_shader_parameter("snow_line", 9999.0)
	apply_terrain_tex(vm)
	vm.set_shader_parameter("earth", col)
	vm.set_shader_parameter("scrub", col.darkened(0.2))
	vm.set_shader_parameter("basalt", col.darkened(0.35))
	terrain_mat = vm
	_mountain(center, radius, height, int(center.x))
	terrain_mat = keep
	# cráter: anillo oscuro hundido en la cima
	var crater := Props.cyl(radius * 0.18, radius * 0.12, 4.0, 14)
	_mesh(crater, _mat(col.darkened(0.6), 1.0), center + Vector3(0, height - 1.0, 0))
	if smoking:
		var smoke := GPUParticles3D.new()
		smoke.amount = 60
		smoke.lifetime = 9.0
		var pm := ParticleProcessMaterial.new()
		pm.direction = Vector3(0.3, 1, 0)
		pm.spread = 12.0
		pm.initial_velocity_min = 3.0
		pm.initial_velocity_max = 5.0
		pm.gravity = Vector3(0.6, 0.4, 0)
		pm.scale_min = 6.0
		pm.scale_max = 14.0
		smoke.process_material = pm
		var puff := SphereMesh.new()
		puff.radius = 1.0
		puff.height = 2.0
		var sm := StandardMaterial3D.new()
		sm.albedo_color = Color(0.35, 0.33, 0.32, 0.35)
		sm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		sm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		puff.material = sm
		smoke.draw_pass_1 = puff
		smoke.position = center + Vector3(0, height, 0)
		smoke.visibility_aabb = AABB(Vector3(-80, -10, -80), Vector3(160, 200, 160))
		add_child(smoke)
		var glow := OmniLight3D.new()
		glow.light_color = Color(1.0, 0.4, 0.1)
		glow.light_energy = 3.0
		glow.omni_range = 60
		glow.position = center + Vector3(0, height + 4, 0)
		add_child(glow)


func _build_village(seed_v: int, wall_c := Color(0, 0, 0, 0), wood_c := Color(0, 0, 0, 0), avoid := Vector2(9999, 9999)) -> void:
	## Muelle de madera y un pueblo de casas canarias frente al mar.
	var stone := Props.tex_mat("rock_face", Color("8a827a"), 0.4)
	_mesh(Props.box(Vector3(4.6, 2.4, 25)), stone, Vector3(0, -0.2, -66.5))
	var plank := Props.tex_mat("weathered_planks", Color(1.0, 0.92, 0.82), 0.5)
	for i in 25:
		_mesh(Props.box(Vector3(4.4, 0.12, 0.95)), plank, Vector3(0, 1.06, -54.5 - i))
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_v
	for row in 2:
		for i in 15:
			var w := 4.5 + rng.randf() * 2.5
			var h := 3.4 + rng.randf() * (3.0 + row * 1.5)
			var x := -40.0 + i * 5.4 + rng.randf()
			var z := -85.0 - row * 9.0 - rng.randf() * 3.0
			if Vector2(x, z).distance_to(avoid) < 12.0:
				continue
			Props.house(self, Vector3(x, max(land_h(x, z), 0.5), z), w, 6.0, h, rng, 0.0, wall_c, wood_c)
	port_light = OmniLight3D.new()
	port_light.light_color = Color("ffb45a")
	port_light.omni_range = 40
	port_light.position = Vector3(1.6, 6.2, -72)
	add_child(port_light)
	var lamp_m := _mat(Color("ffdba0"))
	lamp_m.emission_enabled = true
	lamp_m.emission = Color("ffb45a")
	lamp_m.emission_energy_multiplier = 3.0
	_mesh(Props.cyl(0.08, 0.1, 6.0, 6), _mat(Color("222222")), Vector3(1.6, 3.5, -72))
	var gl := SphereMesh.new()
	gl.radius = 0.4
	gl.height = 0.8
	_mesh(gl, lamp_m, Vector3(1.6, 6.6, -72))
	_dock_props()


func _dock_props() -> void:
	## Barriles, cajas, farol y salvavidas sobre el muelle (modelos de Poly Haven).
	Props.place(self, "wooden_barrels_01", Vector3(1.4, 1.12, -59.5), 1.2, 0.4)
	Props.place(self, "Barrel_01", Vector3(1.5, 1.12, -61.0), 1.1, 1.2)
	Props.place(self, "wooden_crate_01", Vector3(-1.5, 1.12, -63.5), 1.4, 0.2)
	Props.place(self, "wooden_crate_01", Vector3(-1.4, 1.6, -63.4), 1.3, -0.3)
	Props.place(self, "wooden_lantern_01", Vector3(-1.4, 2.08, -63.3), 1.4)
	Props.place(self, "lifebuoy", Vector3(2.25, 1.6, -67.0), 1.2, PI / 2)
	Props.place(self, "wooden_crate_01", Vector3(1.6, 1.12, -71.0), 1.3, 1.0)


func _lighthouse(x: float, z: float, h := 16.0) -> void:
	var y: float = max(land_h(x, z), 0.5)
	for i in 4:
		_mesh(Props.cyl(1.6 - i * 0.2, 1.8 - i * 0.2, h / 4.0, 12), _mat(Color("eeeae0") if i % 2 == 0 else Color("b8322a"), 0.8), Vector3(x, y + h / 8.0 + i * h / 4.0, z))
	var lm := _mat(Color("fff1c0"))
	lm.emission_enabled = true
	lm.emission = Color("fff1c0")
	lm.emission_energy_multiplier = 4.0
	var bulb := SphereMesh.new()
	bulb.radius = 1.0
	bulb.height = 2.0
	_mesh(bulb, lm, Vector3(x, y + h + 1.0, z))


func _build_lg_port() -> void:
	# San Sebastián de La Gomera: muelle, Torre del Conde, iglesia y casas
	var stone := _mat(Color("6d665e"), 1.0)
	var dock := BoxMesh.new()
	dock.size = Vector3(5, 2.4, 26)
	_mesh(dock, stone, Vector3(0, -0.2, -67))
	var plank := _mat(Color("7a5636"), 0.9)
	for i in 26:
		var pb := BoxMesh.new()
		pb.size = Vector3(4.8, 0.12, 0.95)
		_mesh(pb, plank, Vector3(0, 1.06, -54.5 - i))
	var rng := RandomNumberGenerator.new()
	rng.seed = 23
	for i in 18:
		var w := 4.5 + rng.randf() * 2.5
		var h := 3.6 + rng.randf() * 4.5
		var x := -40.0 + i * 5.0 + rng.randf()
		var z := -86.0 - rng.randf() * 6.0
		if x > 14.0 and x < 26.0:
			continue
		Props.house(self, Vector3(x, max(land_h(x, z), 0.5), z), w, 6.0, h, rng)
	# Torre del Conde: torre de piedra con almenas
	var tx := 20.0
	var tz := -92.0
	var ty: float = max(land_h(tx, tz), 0.5)
	var tower := _mat(Color("8a7a68"), 1.0)
	_mesh(Props.box(Vector3(7, 16, 7)), tower, Vector3(tx, ty + 6.0, tz))
	for cx in [-1, 1]:
		for cz in [-1, 1]:
			_mesh(Props.box(Vector3(1.0, 16.2, 1.0)), _mat(Color("6a5a4a"), 1.0), Vector3(tx + cx * 3.2, ty + 6.0, tz + cz * 3.2))
	for i in 8:
		var a := i * TAU / 8.0
		_mesh(Props.box(Vector3(1.2, 1.2, 1.2)), tower, Vector3(tx + cos(a) * 3.0, ty + 14.6, tz + sin(a) * 3.0))
	_mesh(Props.box(Vector3(1.2, 2.2, 0.2)), _mat(Color("2a1a10")), Vector3(tx, ty + 0.9, tz + 3.55))
	Props.church(self, Vector3(-22, max(land_h(-22, -100), 0.5), -100))
	port_light = OmniLight3D.new()
	port_light.light_color = Color("ffb45a")
	port_light.omni_range = 40
	port_light.position = Vector3(1.6, 6.2, -72)
	add_child(port_light)
	var lamp_m := _mat(Color("ffdba0"))
	lamp_m.emission_enabled = true
	lamp_m.emission = Color("ffb45a")
	lamp_m.emission_energy_multiplier = 3.0
	_mesh(Props.cyl(0.08, 0.1, 6.0, 6), _mat(Color("222222")), Vector3(1.6, 3.5, -72))
	var gl := SphereMesh.new()
	gl.radius = 0.4
	gl.height = 0.8
	_mesh(gl, lamp_m, Vector3(1.6, 6.6, -72))


func _laurel_mesh() -> ArrayMesh:
	## Árbol de laurisilva: tronco y copa densa de verdes oscuros.
	var st := SurfaceTool.new()
	var trunk := Props.cyl(0.18, 0.28, 3.0, 6)
	st.append_from(trunk, 0, Transform3D(Basis(), Vector3(0, 1.5, 0)))
	var leaf := SphereMesh.new()
	leaf.radial_segments = 8
	leaf.rings = 5
	for i in 6:
		var r := 1.3 + 0.25 * (i % 3)
		leaf.radius = r
		leaf.height = r * 1.6
		var off := Vector3(cos(i * 1.7) * 0.9, 3.4 + (i % 2) * 0.9, sin(i * 1.7) * 0.9)
		st.append_from(leaf, 0, Transform3D(Basis(), off))
	return st.commit()


func _build_vegetation() -> void:
	# Palmeras canarias, cardones y tabaibas repartidos por la costa.
	var rng := RandomNumberGenerator.new()
	rng.seed = 99 + int(land_seed)
	var palms: Array = []
	var cardones: Array = []
	var shrubs: Array = []
	var tries := 0
	while tries < 9000:
		tries += 1
		var x := rng.randf_range(-320, 320)
		var z := rng.randf_range(-300, -66)
		var h := land_h(x, z)
		if h < 0.8 or h > 30.0:
			continue
		var slope: float = abs(land_h(x + 2.0, z) - h) + abs(land_h(x, z + 2.0) - h)
		var in_town: bool = abs(x) < 34.0 and z > -112.0
		var near_pyr: bool = Vector2(x, z).distance_to(Vector2(-82, -100)) < 26.0
		if in_town or near_pyr:
			continue
		var basis := Basis(Vector3.UP, rng.randf() * TAU)
		var veg := {"lanzarote": [0.25, 0.0, 0.15], "fuerteventura": [0.3, 0.1, 0.3], "la_palma": [0.6, 0.3, 1.0], "el_hierro": [0.4, 0.5, 0.8]}
		var vk: Array = veg.get(region, [1.0, 1.0, 1.0])
		if rng.randf() > max(vk[0], max(vk[1], vk[2])):
			continue
		if h < 7.0 and slope < 1.6 and palms.size() < int(70 * vk[0]) and rng.randf() < 0.18:
			palms.append(Transform3D(basis.scaled(Vector3.ONE * rng.randf_range(0.8, 1.25)), Vector3(x, h - 0.2, z)))
		elif slope > 0.8 and cardones.size() < int(160 * vk[1]) and rng.randf() < 0.3:
			cardones.append(Transform3D(basis.scaled(Vector3.ONE * rng.randf_range(0.7, 1.5)), Vector3(x, h - 0.1, z)))
		elif shrubs.size() < int(700 * vk[2]):
			shrubs.append(Transform3D(basis.scaled(Vector3(1, rng.randf_range(0.7, 1.1), 1) * rng.randf_range(0.6, 1.4)), Vector3(x, h - 0.1, z)))
	# palmeras del paseo del pueblo
	for i in 9:
		var x := -32.0 + i * 8.0
		var z := -77.5
		palms.append(Transform3D(Basis(Vector3.UP, i * 1.3).scaled(Vector3.ONE * (0.95 + 0.1 * (i % 3))), Vector3(x, max(land_h(x, z), 0.6) - 0.2, z)))
	Props.scatter(self, Props.palm_mesh(), Props.vc_mat(0.85), palms)
	var cm := Props.mat(Color("5d7a4a"), 0.8)
	Props.scatter(self, Props.cardon_mesh(), cm, cardones)
	var shrub_model := Props.model_mesh("wild_rooibos_bush")
	if shrub_model:
		# tabaibas y matorral: modelo fotogramétrico, agrandado
		var big: Array = []
		for t in shrubs:
			big.append(Transform3D(t.basis.scaled(Vector3(2.2, 2.0, 2.2)), t.origin))
		Props.scatter(self, shrub_model, null, big)
	else:
		var sm := Props.mat(Color("6f7f3a"), 0.95)
		Props.scatter(self, Props.shrub_mesh(), sm, shrubs)
	if region in ["la_palma", "el_hierro"]:
		# pinar canario en las alturas; sabinas en El Hierro; plataneras en La Palma
		var trees: Array = []
		var low: Array = []
		var r3 := RandomNumberGenerator.new()
		r3.seed = 55
		for i in 7000:
			var x := r3.randf_range(-330, 330)
			var z := r3.randf_range(-310, -72)
			var h := land_h(x, z)
			if h < 1.0 or h > 45.0 or (abs(x) < 45.0 and z > -105.0):
				continue
			var basis := Basis(Vector3.UP, r3.randf() * TAU)
			if h > 16.0 and trees.size() < 380:
				trees.append(Transform3D(basis.scaled(Vector3.ONE * r3.randf_range(0.8, 1.4)), Vector3(x, h - 0.3, z)))
			elif h < 10.0 and low.size() < 260:
				low.append(Transform3D(basis.scaled(Vector3.ONE * r3.randf_range(0.8, 1.2)), Vector3(x, h - 0.2, z)))
		Props.scatter(self, Props.pine_mesh(), Props.mat(Color("2f4a26"), 0.9), trees)
		if region == "la_palma":
			Props.scatter(self, Props.banana_mesh(), Props.mat(Color("5a8a32"), 0.8), low)
		else:
			Props.scatter(self, Props.sabina_mesh(), Props.mat(Color("3d5230"), 0.9), low)
	if region == "la_gomera":
		# laurisilva en lo alto y palmerales en los barrancos
		var laurels: Array = []
		var more_palms: Array = []
		var r2 := RandomNumberGenerator.new()
		r2.seed = 77
		for i in 6000:
			var x := r2.randf_range(-330, 330)
			var z := r2.randf_range(-310, -70)
			var h := land_h(x, z)
			if h < 1.0 or h > 40.0:
				continue
			if abs(x) < 45.0 and z > -110.0:
				continue
			var basis := Basis(Vector3.UP, r2.randf() * TAU)
			if h > 14.0 and laurels.size() < 420:
				laurels.append(Transform3D(basis.scaled(Vector3.ONE * r2.randf_range(0.8, 1.6)), Vector3(x, h - 0.3, z)))
			elif h < 9.0 and more_palms.size() < 90 and r2.randf() < 0.25:
				more_palms.append(Transform3D(basis.scaled(Vector3.ONE * r2.randf_range(0.8, 1.2)), Vector3(x, h - 0.2, z)))
		Props.scatter(self, _laurel_mesh(), Props.mat(Color("2c4a22"), 0.9), laurels)
		Props.scatter(self, Props.palm_mesh(), Props.vc_mat(0.85), more_palms)


func _build_gc_mountains() -> void:
	# Cumbres de Gran Canaria con el Roque Nublo
	_mountain(Vector3(-60, -10, -310), 150.0, 120.0, 4)
	_mountain(Vector3(70, -10, -330), 160.0, 105.0, 5)
	_mountain(Vector3(0, -10, -370), 180.0, 135.0, 6)
	var roque := CylinderMesh.new()
	roque.top_radius = 4
	roque.bottom_radius = 7
	roque.height = 34
	roque.radial_segments = 7
	_mesh(roque, _mat(Color("5a4a3e"), 1.0), Vector3(0, 138, -370))


func _build_gc_port() -> void:
	# Puerto de La Luz: muelles largos, grúas y la ciudad detrás
	var concrete := _mat(Color("8d8a83"), 1.0)
	var pier := BoxMesh.new()
	pier.size = Vector3(5, 1.2, 26)
	_mesh(pier, concrete, Vector3(0, 0.6, -67))
	var pier2 := BoxMesh.new()
	pier2.size = Vector3(40, 1.2, 5)
	_mesh(pier2, concrete, Vector3(20, 0.6, -78))
	var yellow := _mat(Color("d9a22b"), 0.7)
	for x in [14.0, 30.0]:
		var leg := BoxMesh.new()
		leg.size = Vector3(1.2, 18, 1.2)
		_mesh(leg, yellow, Vector3(x, 9.0, -80))
		var arm := BoxMesh.new()
		arm.size = Vector3(1.0, 1.0, 20)
		_mesh(arm, yellow, Vector3(x, 18.0, -72))
	var cont_cols := [Color("b8322a"), Color("1d5aa6"), Color("2e7d4f"), Color("d98b2b")]
	for i in 8:
		var bm := BoxMesh.new()
		bm.size = Vector3(6, 2.6, 2.6)
		_mesh(bm, _mat(cont_cols[i % 4], 0.8), Vector3(8.0 + (i % 4) * 7.0, 2.5 + (i / 4) * 2.6, -84))
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	for row in 2:
		for i in 16:
			var w := 6.0 + rng.randf() * 4.0
			var h := 6.0 + rng.randf() * 10.0 + row * 5.0
			var x := -70.0 + i * 8.5 + rng.randf() * 1.5
			var z := -96.0 - row * 12.0 - rng.randf() * 3.0
			Props.house(self, Vector3(x, max(land_h(x, z), 0.5), z), w, 7.0, h, rng)
	port_light = OmniLight3D.new()
	port_light.light_color = Color("ffc27a")
	port_light.omni_range = 50
	port_light.position = Vector3(2, 8, -70)
	add_child(port_light)


func _build_port() -> void:
	if region == "gran_canaria":
		_build_gc_port()
		return
	if region == "la_gomera":
		_build_lg_port()
		return
	match region:
		"lanzarote":
			# Caleta de Sebo: casas blancas con carpintería verde, calles de arena
			_build_village(31, Color("f6f4ee"), Color("2e6b4f"))
			# cueva marina (Jameo) al oeste, con su arco de lava
			var basalt := _mat(Color("1c1917"), 0.95)
			for sx in [-1, 1]:
				var r := MeshInstance3D.new()
				r.mesh = Props.rock_mesh(sx + 5)
				r.material_override = basalt
				r.scale = Vector3(4.0, 7.0, 4.5)
				r.position = Vector3(-90 + sx * 7.0, 2.0, -70)
				add_child(r)
			var lintel := MeshInstance3D.new()
			lintel.mesh = Props.rock_mesh(9)
			lintel.material_override = basalt
			lintel.scale = Vector3(10.0, 3.0, 5.0)
			lintel.position = Vector3(-90, 8.5, -70)
			add_child(lintel)
			_mesh(Props.box(Vector3(9.0, 8.0, 4.0)), _mat(Color("050404"), 1.0), Vector3(-90, 2.0, -73))
		"fuerteventura":
			_build_village(37, Color("f6f4ee"), Color("1d5aa6"))
			_lighthouse(70.0, -80.0)
		"la_palma":
			_build_village(41)
		"el_hierro":
			_build_village(43, Color(0, 0, 0, 0), Color(0, 0, 0, 0))
			_lighthouse(-120.0, -82.0, 14.0)
	# Muelle: base de piedra, tablones de madera y bolardos
	var stone := Props.tex_mat("rock_face", Color("8a827a"), 0.4)
	var dock := BoxMesh.new()
	dock.size = Vector3(4.4, 2.4, 24)
	_mesh(dock, stone, Vector3(0, -0.2, -66))
	var plank_a := Props.tex_mat("weathered_planks", Color(1.0, 0.92, 0.82), 0.5)
	var plank_b := Props.tex_mat("weathered_planks", Color(0.9, 0.82, 0.72), 0.5)
	for i in 24:
		var pb := BoxMesh.new()
		pb.size = Vector3(4.2, 0.12, 0.95)
		_mesh(pb, plank_a if i % 2 == 0 else plank_b, Vector3(0, 1.06, -54.5 - i))
	var iron := _mat(Color("2b2b2e"), 0.5)
	for i in 4:
		for sx in [-1.9, 1.9]:
			var bol := Props.cyl(0.18, 0.24, 0.6, 10)
			_mesh(bol, iron, Vector3(sx, 1.4, -56.0 - i * 6.0))
	# Escollera de roca volcánica protegiendo la caleta
	var basalt := _mat(Color("2a2522"), 0.95)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for i in 26:
		var x := -48.0 + i * 1.7 + rng.randf_range(-0.5, 0.5)
		var z := -71.0 + rng.randf_range(-1.0, 1.0)
		if abs(x) < 6.0:
			continue
		var rk := MeshInstance3D.new()
		rk.mesh = Props.rock_mesh(i)
		rk.material_override = basalt
		var sc := rng.randf_range(0.9, 1.7)
		rk.scale = Vector3(sc, sc * 0.7, sc)
		rk.position = Vector3(x, -0.3, z)
		rk.rotation.y = rng.randf() * TAU
		add_child(rk)
	# Pueblo: casas canarias y la iglesia
	for i in 16:
		var w := 4.5 + rng.randf() * 2.5
		var h := 3.6 + rng.randf() * 4.0
		var x := -34.0 + i * 4.6 + rng.randf() * 0.8
		var z := -84.0 - rng.randf() * 3.0
		Props.house(self, Vector3(x, max(land_h(x, z), 0.5), z), w, 6.0, h, rng)
	for i in 12:
		var w := 5.0 + rng.randf() * 2.0
		var h := 3.4 + rng.randf() * 3.0
		var x := -30.0 + i * 5.2 + rng.randf() * 1.0
		var z := -95.0 - rng.randf() * 4.0
		if x > -22.0 and x < -6.0:
			continue
		Props.house(self, Vector3(x, max(land_h(x, z), 0.5), z), w, 6.0, h, rng)
	Props.church(self, Vector3(-14, max(land_h(-14, -100), 0.5), -100))
	_dock_props()
	# Farolas del paseo
	var lamp_m := _mat(Color("ffdba0"))
	lamp_m.emission_enabled = true
	lamp_m.emission = Color("ffb45a")
	lamp_m.emission_energy_multiplier = 2.0
	for i in 5:
		var x := -28.0 + i * 14.0
		var y: float = max(land_h(x, -79.0), 0.6)
		if Props.place(self, "street_lamp_01", Vector3(x, y, -79.0), 1.3, PI) == null:
			_mesh(Props.cyl(0.07, 0.09, 4.0, 6), iron, Vector3(x, y + 2.0, -79.0))
		var gl := SphereMesh.new()
		gl.radius = 0.18
		gl.height = 0.36
		_mesh(gl, lamp_m, Vector3(x, y + 4.75, -79.0))
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
	lamp_light.light_volumetric_fog_energy = 2.5
	# salpicaduras en la proa
	spray = GPUParticles3D.new()
	spray.amount = 70
	spray.lifetime = 0.8
	spray.local_coords = false
	spray.emitting = false
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = Vector3(1.0, 0.1, 0.3)
	pm.direction = Vector3(0, 1, -0.4)
	pm.spread = 35.0
	pm.initial_velocity_min = 2.5
	pm.initial_velocity_max = 5.0
	pm.gravity = Vector3(0, -9.8, 0)
	pm.scale_min = 0.6
	pm.scale_max = 1.4
	var ramp := Gradient.new()
	ramp.set_color(0, Color(1, 1, 1, 0.9))
	ramp.set_color(1, Color(1, 1, 1, 0.0))
	var gt := GradientTexture1D.new()
	gt.gradient = ramp
	pm.color_ramp = gt
	spray.process_material = pm
	var drop := SphereMesh.new()
	drop.radius = 0.09
	drop.height = 0.18
	drop.radial_segments = 6
	drop.rings = 3
	var dm := StandardMaterial3D.new()
	dm.albedo_color = Color(0.92, 0.97, 1.0, 0.85)
	dm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	dm.vertex_color_use_as_albedo = true
	dm.roughness = 0.1
	drop.material = dm
	spray.draw_pass_1 = drop
	spray.position = Vector3(0, 0.3, -3.2)
	boat.add_child(spray)


func make_boat(hull_col: Color, stripe1: Color, stripe2: Color) -> Dictionary:
	return Props.build_boat(self, hull_col, stripe1, stripe2)


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
	var night_top := Color("071426")
	var night_hor := Color("1b2c44")
	var dusk := Color("f08a4b")
	var dusk_amt := 0.0
	if (h > 17.0 and h < 20.5) or (h > 5.0 and h < 7.5):
		dusk_amt = max(0.0, 1.0 - abs(l - 0.4) * 2.0)
	var hor := night_hor.lerp(day_hor, l).lerp(dusk, dusk_amt * 0.75)
	var top_c := night_top.lerp(day_top, l)
	var wb: Dictionary = weather.blend if weather else {"fog": 0.0, "tint": Color(0, 0, 0, 0), "sun": 1.0}
	var tint: Color = wb["tint"]
	hor = hor.lerp(Color(tint.r, tint.g, tint.b) * (0.25 + 0.75 * l), tint.a)
	top_c = top_c.lerp(hor, tint.a * 0.6)
	sky_mat.set_shader_parameter("top_color", top_c)
	sky_mat.set_shader_parameter("horizon_color", hor)
	sky_mat.set_shader_parameter("ground_color", hor.darkened(0.5))
	sky_mat.set_shader_parameter("daylight", l)
	sky_mat.set_shader_parameter("time_s", t)
	sky_mat.set_shader_parameter("sun_tint", Color(1.0, 0.92, 0.78).lerp(Color("ff9a50"), dusk_amt))
	var cover := {"despejado": 0.35, "calima": 0.15, "lluvia": 0.9, "picada": 0.65, "niebla": 0.85}
	sky_mat.set_shader_parameter("cloud_cover", cover.get(weather.current if weather else "despejado", 0.35))
	sky_mat.set_shader_parameter("cloud_tint", Color(1, 1, 1).lerp(Color(1.0, 0.75, 0.55), dusk_amt * 0.8).lerp(Color(0.6, 0.62, 0.66), float(wb.get("rain", 0.0)) * 0.7))
	ocean_mat.set_shader_parameter("sky_color", hor.lerp(top_c, 0.35))
	env.fog_light_color = hor
	env.fog_density = lerp(0.016, 0.0026, l) * (1.0 - dusk_amt * 0.5) + panic * 0.00015 + float(wb["fog"])
	# niebla volumétrica: rayos de sol al atardecer y conos de luz del farol de noche
	env.volumetric_fog_density = 0.003 + float(wb["fog"]) * 0.5 + (1.0 - l) * 0.004 + dusk_amt * 0.004
	env.volumetric_fog_albedo = hor.lerp(Color.WHITE, 0.4)
	if quest and quest.boss and quest.boss.phase in ["rise", "fight", "defeat"]:
		env.fog_density *= 0.45   # el resplandor de la lava aclara la noche
	env.ambient_light_energy = 0.55 + l * 0.25
	# Sol: sube y baja con la hora
	var sun_elev := sin(PI * (h - 5.6) / 14.4) * 68.0
	sun.rotation_degrees = Vector3(-max(sun_elev, -5.0), -30.0 + (h - 12.0) * 10.0, 0)
	sun.light_energy = (0.05 + l * 0.95) * float(wb["sun"])
	sun.light_color = Color(1.0, 0.9, 0.75).lerp(Color("ffb070"), dusk_amt)
	moon.light_energy = (1.0 - l) * 0.5
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
	var pool: Array = Data.REGIONS[region]["zones"][s["zone"]]
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
	quest.isles.fishing_end()
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
static func peek_region() -> String:
	if not FileAccess.file_exists(SAVE_PATH):
		return "tenerife"
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	var d = JSON.parse_string(f.get_as_text())
	f.close()
	if typeof(d) == TYPE_DICTIONARY and Data.REGIONS.has(str(d.get("region", ""))):
		return str(d["region"])
	return "tenerife"


func travel(dest: String) -> void:
	## Cruza a otra isla: pasan horas de travesía y se carga la nueva costa.
	region = dest
	bx = 0.0
	bz = -46.0
	ba = PI
	bv = 0.0
	game_time += 5.0 * 60.0
	day = int(game_time / 1440.0) + 1
	for s in spots:
		s["left"] = 1
	gear.nasas.clear()
	save_game()
	continue_game()


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
		"region": region, "story": quest.to_dict(),
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
	quest.from_dict(d.get("story", {}))
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
	if mode == "silbo":
		quest.silbo_key(k)
		return
	if mode == "choice":
		if k in [KEY_1, KEY_KP_1]:
			ui.pick_choice(0)
		elif k in [KEY_2, KEY_KP_2]:
			ui.pick_choice(1)
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
		KEY_M:
			ui.toggle_map()
		KEY_G:
			quest.whistle()
		KEY_N:
			gear.drop_nasa()
		KEY_R:
			gear.toggle_net()


# ---------- Bucle ----------
func _process(delta: float) -> void:
	var dt: float = min(delta, 0.05)
	t += dt
	if mode != "cinematic" and mode != "menu":
		amp = move_toward(amp, float(weather.blend["amp"]) * (0.45 if region == "el_hierro" else 1.0), dt * 0.3)
	_update_boat(dt)
	_update_world(dt)
	_update_panic(dt)
	_apply_light()
	if mode == "fish":
		_update_minigame(dt)
		quest.isles.fishing_tick(dt)
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
		# El timón no gira de golpe: la velocidad de giro sube y baja poco a poco,
		# y el barco describe una curva. Gira mejor cuanto más rápido va.
		var max_turn: float = 0.95 * (0.35 + min(1.0, abs(bv) / 7.0) * 0.65)
		bturn = move_toward(bturn, turn * max_turn, dt * (1.1 if turn != 0.0 else 1.6))
		if abs(bv) > 0.6:
			advance(dt * abs(bv) * 1.6)
	else:
		bturn = move_toward(bturn, 0.0, dt * 2.0)
		bv *= 1.0 - 3.0 * dt
	ba += bturn * dt

	var nx := bx - sin(ba) * bv * dt
	var nzp := bz - cos(ba) * bv * dt
	var on_dock: bool = abs(nx) < 2.6 and nzp < -53.0 and nzp > -79.0
	if quest.finale and quest.finale.solid(nx, nzp):
		bv *= -0.3
	elif hazards.rock_at(nx, nzp) != null:
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
	# se escora hacia fuera de la curva, como un barco de verdad
	boat.basis = Basis.from_euler(Vector3(gz * 0.8, ba, -gx * 0.8 + bturn * min(abs(bv), 9.0) * 0.022))

	var target := Vector3(bx + sin(ba) * 17.0, 8.5, bz + cos(ba) * 17.0)
	if mode == "menu":
		var a := t * 0.05 + 2.2
		camera.position = Vector3(4.5 + cos(a) * 30.0, 9.0, -50.0 + sin(a) * 18.0)
		camera.look_at(Vector3(-10, 6, -90))
	elif quest and quest.boss and quest.boss.phase in ["rise", "fight", "defeat"] and mode != "cinematic":
		# Combate: la cámara se coloca detrás del barco mirando hacia Guayota
		var bp: Vector3 = quest.boss.body.position
		var to_b := Vector3(bp.x - bx, 0, bp.z - bz).normalized()
		var cam_t := Vector3(bx, 0, bz) - to_b * 26.0 + Vector3(0, 20, 0)
		camera.position = camera.position.lerp(cam_t, 1.0 - pow(0.05, dt))
		camera.look_at(Vector3(bx, 1.5, bz).lerp(Vector3(bp.x, 4.0, bp.z), 0.45))
	elif mode != "cinematic":
		camera.position = camera.position.lerp(target, 1.0 - pow(0.02, dt))
		camera.look_at(Vector3(bx - sin(ba) * 6.0, 2.0, bz - cos(ba) * 6.0))


func _update_world(dt: float) -> void:
	var cell := OCEAN_SIZE / OCEAN_SUBDIV
	ocean.position = Vector3(round(bx / cell) * cell, 0, round(bz / cell) * cell)
	ocean_mat.set_shader_parameter("time_s", t)
	# estela: un punto nuevo cada 0,25 s mientras el barco se mueve
	wake_timer -= dt
	if wake_timer <= 0.0:
		wake_timer = 0.25
		var stern := Vector2(bx + sin(ba) * 2.6, bz + cos(ba) * 2.6)
		wake_pts.push_front([stern.x, stern.y, 0.0, abs(bv)])
		if wake_pts.size() > 24:
			wake_pts.pop_back()
	var wk: Array = []
	for p in wake_pts:
		p[2] += dt
		wk.append(Vector4(p[0], p[1], p[2], p[3]))
	while wk.size() < 24:
		wk.append(Vector4(0, 0, 99, 0))
	ocean_mat.set_shader_parameter("wake", wk)
	if spray:
		spray.emitting = abs(bv) > 4.5 and mode == "sail"
		spray.amount_ratio = clamp((abs(bv) - 4.0) / 8.0, 0.1, 1.0)
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
