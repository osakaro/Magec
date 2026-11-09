extends Node
## Cinemática de inicio de MAGEC.
## Prólogo: Aridane y San Borondón, treinta años después, Acorán, el temblor
## y el farol de Chaxiraxi. Se puede saltar con Esc, Espacio o Intro.

var main  # main.gd

# Cada plano: [nombre, duración en segundos]
const SHOTS := [
	["card_past", 7.0],
	["aridane", 14.0],
	["borondon", 13.0],
	["card_now", 5.0],
	["dawn", 14.0],
	["quake", 10.0],
	["chaxiraxi", 11.0],
	["title", 6.5],
]

# Subtítulos por plano: [inicio, fin, texto]
const SUBS := {
	"aridane": [
		[0.8, 6.6, "Mi abuelo Aridane salía a pescar cada noche, cuando nadie más se atrevía."],
		[7.0, 13.6, "Una noche volvió al puerto diciendo que había visto una isla que no sale en ningún mapa."],
	],
	"borondon": [
		[1.5, 5.2, "San Borondón."],
		[5.6, 12.6, "Al día siguiente salió a buscarla. Nunca volvió. Su barca apareció vacía frente a El Hierro."],
	],
	"dawn": [
		[1.0, 6.6, "Me llamo Acorán. Pesco en la misma caleta de Güímar que mi abuelo."],
		[7.0, 13.6, "Todavía debo quinientos euros del barco. Así que salgo a la mar, pase lo que pase."],
	],
	"quake": [
		[0.6, 4.6, "Hasta la madrugada del temblor."],
		[5.0, 9.8, "Desde ese día, lo que sale del mar de noche ya no es normal."],
	],
}

const CARDS := {
	"card_past": "Güímar, Tenerife.\nHace treinta años.",
	"card_now": "Treinta años después.",
	"chaxiraxi": "«Toma, mi niño. Este farol guarda la luz de Magec.\nDe noche, no lo apagues nunca.»\n\n— Chaxiraxi, junto a las Pirámides de Güímar",
}

var time := 0.0
var done := false
var rumbled := false
var aridane: Dictionary
var island: MeshInstance3D
var island_mat: StandardMaterial3D


func _ready() -> void:
	# La barca de Aridane: madera vieja, franjas verde y amarilla.
	aridane = main.make_boat(Color("d9c9a3"), Color("2e6b4f"), Color("c9a227"))
	aridane["light"].light_energy = 2.4
	aridane["lamp_mat"].emission_energy_multiplier = 4.0

	# San Borondón: silueta que brilla a través de la niebla.
	var sm := SphereMesh.new()
	sm.radius = 1.0
	sm.height = 2.0
	sm.radial_segments = 12
	sm.rings = 6
	island_mat = StandardMaterial3D.new()
	island_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	island_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	island_mat.albedo_color = Color(0.32, 0.5, 0.42, 0.0)
	island_mat.set("disable_fog", true)
	island = MeshInstance3D.new()
	island.mesh = sm
	island.material_override = island_mat
	island.scale = Vector3(120, 30, 45)
	island.position = Vector3(0, -40, 300)
	main.add_child(island)

	# Acorán amarrado junto al muelle.
	main.bx = 4.5
	main.bz = -62.0
	main.ba = PI * 0.5


func _unhandled_input(event: InputEvent) -> void:
	if done:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode in [KEY_ESCAPE, KEY_SPACE, KEY_ENTER]:
			finish()
			get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	if done:
		return
	time += delta
	var t0 := 0.0
	for s in SHOTS:
		if time < t0 + s[1]:
			_shot(s[0], time - t0, s[1])
			return
		t0 += s[1]
	finish()


static func fade(lt: float, dur: float, edge := 1.0) -> float:
	# 0 → 1 → 0 con rampas de `edge` segundos.
	return clamp(min(lt / edge, (dur - lt) / edge), 0.0, 1.0)


func _sub(name: String, lt: float) -> Array:
	if SUBS.has(name):
		for s in SUBS[name]:
			if lt >= s[0] and lt <= s[1]:
				return [s[2], fade(lt - s[0], s[1] - s[0], 0.4)]
	return ["", 0.0]


func _cam(pos: Vector3, look: Vector3, shake := 0.0) -> void:
	var cam: Camera3D = main.camera
	cam.position = pos + Vector3(randf_range(-1, 1), randf_range(-1, 1), randf_range(-1, 1)) * shake
	cam.look_at(look)


func _place_aridane(z: float) -> Vector3:
	var x := 0.0
	var y: float = main.wave(x, z, main.t)
	var n: Node3D = aridane["node"]
	n.position = Vector3(x, y + 0.1, z)
	n.basis = Basis.from_euler(Vector3((main.wave(x, z + 1.0, main.t) - y) * 0.8, PI, 0))
	return n.position


func _shot(name: String, lt: float, dur: float) -> void:
	var p := lt / dur
	var sub := _sub(name, lt)
	match name:
		"card_past", "card_now":
			main.game_time = 23.5 * 60.0
			main.ui.cine_set(1.0, CARDS[name], fade(lt, dur, 1.2), "", 0.0, 0.0)

		"aridane":
			main.game_time = 23.5 * 60.0
			main.panic = 40.0  # más niebla
			var bp := _place_aridane(lerp(30.0, 70.0, p))
			_cam(bp + Vector3(lerp(16.0, 9.0, p), lerp(6.0, 3.5, p), lerp(-10.0, 4.0, p)), bp + Vector3(0, 1.5, 0))
			main.ui.cine_set(1.0 - clamp(lt / 1.5, 0.0, 1.0), "", 0.0, sub[0], sub[1], 0.0)

		"borondon":
			main.game_time = 23.6 * 60.0
			var bp := _place_aridane(lerp(70.0, 95.0, p))
			var rise: float = clamp(p / 0.45, 0.0, 1.0)
			var sink: float = clamp((p - 0.75) / 0.25, 0.0, 1.0)
			island.position.y = lerp(-40.0, -6.0, rise) - sink * 30.0
			island_mat.albedo_color.a = 0.75 * rise * (1.0 - sink)
			# El farol de Aridane se apaga al final
			aridane["light"].light_energy = 2.4 * (1.0 - sink)
			aridane["lamp_mat"].emission_energy_multiplier = 4.0 * (1.0 - sink)
			_cam(bp + Vector3(-3.0, 4.0, -14.0 + p * 4.0), Vector3(0, 6, 300))
			var black: float = clamp((p - 0.88) / 0.12, 0.0, 1.0)
			main.ui.cine_set(black, "", 0.0, sub[0], sub[1], 0.0)

		"dawn":
			aridane["node"].visible = false
			island.visible = false
			main.panic = 0.0
			main.game_time = lerp(6.0 * 60.0 + 5.0, 6.0 * 60.0 + 50.0, p)
			var e := p * p * (3.0 - 2.0 * p)
			var from := Vector3(-70, 70, 40)
			var to := Vector3(16, 6, -40)
			var look := Vector3(-40, 20, -120).lerp(Vector3(4.5, 1.5, -62), e)
			_cam(from.lerp(to, e), look)
			main.ui.cine_set(1.0 - clamp(lt / 1.5, 0.0, 1.0), "", 0.0, sub[0], sub[1], 0.0)

		"quake":
			if not rumbled:
				rumbled = true
				main.audio.sfx("rumble", 2.0)
			main.game_time = 6.0 * 60.0 + 50.0
			var k: float = sin(PI * clamp(p / 0.6, 0.0, 1.0))
			main.amp = 1.0 + k * 2.6
			_cam(Vector3(16, 6, -40), Vector3(4.5, 1.5, -62), k * 0.6)
			main.ui.cine_set(0.0, "", 0.0, sub[0], sub[1], 0.0)

		"chaxiraxi":
			main.amp = 1.0
			main.game_time = 6.0 * 60.0 + 52.0
			# El farol de Magec se enciende en el barco de Acorán
			var on: float = clamp((lt - 2.0) / 1.5, 0.0, 1.0)
			main.lamp_light.light_energy = 2.8 * on
			main.lamp_mat.emission_energy_multiplier = 4.0 * on
			var a: float = lerp(0.4, 1.2, p)
			var c := Vector3(4.5, 1.5, -62)
			_cam(c + Vector3(cos(a) * 14.0, 5.0, sin(a) * 14.0), c)
			main.ui.cine_set(0.72, CARDS[name], fade(lt, dur, 1.0), "", 0.0, 0.0)

		"title":
			main.game_time = 7.0 * 60.0
			var c := Vector3(4.5, 1.5, -62)
			_cam(c + Vector3(cos(1.2) * 14.0, 5.0 + p * 8.0, sin(1.2) * 14.0), c + Vector3(0, p * 6.0, 0))
			main.ui.cine_set(0.0, "", 0.0, "", 0.0, fade(lt, dur, 1.5))


func finish() -> void:
	if done:
		return
	done = true
	main.amp = 1.0
	main.panic = 0.0
	main.game_time = 7.0 * 60.0
	main.bx = 0.0
	main.bz = -46.0
	main.ba = PI
	main.bv = 0.0
	main.lamp_on = false
	main.camera.position = Vector3(0, 13, -66)
	if is_instance_valid(aridane["node"]):
		aridane["node"].queue_free()
	island.queue_free()
	main.mode = "sail"
	main.ui.end_cinematic()
	queue_free()
