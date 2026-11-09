extends Node
## Misión 1: "La primera Piedra".
## Chaxiraxi (junto a las Pirámides de Güímar) cuenta la leyenda de Guayota y
## Magec. Acorán debe buscar de noche la Piedra de Magec de Tenerife en el fondo
## y llevársela.

var main

const CHAX_SPOT := Vector2(-62, -62)      # donde se para el barco para hablar
const STONE_SPOT := Vector2(20, 150)      # la Piedra, mar adentro (solo de noche)

var state := "talk1"   # talk1 -> stone -> return -> done
var lines: Array = []
var line_i := 0
var after_dialogue := Callable()
var stones := 0

var beacon: MeshInstance3D
var beacon_mat: StandardMaterial3D
var stone_spot: Node3D
var stone_bubbles: Array = []
var chax_light: OmniLight3D

const TALK1 := [
	["Chaxiraxi", "Ay, Acorán. Te pareces tanto a tu abuelo… Él también venía a verme cuando el mar hacía cosas raras."],
	["Acorán", "Chaxiraxi, ¿qué fue ese temblor? Anoche saqué una vieja con ojos por todo el cuerpo."],
	["Chaxiraxi", "No fue el volcán, mi niño. Fue Guayota, revolviéndose allá abajo, bajo el Teide."],
	["Chaxiraxi", "Hace muchos siglos, Magec, el sol, lo encerró. Y guardó su luz en siete piedras, en el fondo del mar. Una por cada isla."],
	["Chaxiraxi", "Se están apagando. Por eso el mar se pudre de noche."],
	["Acorán", "Eso son cuentos de los viejos…"],
	["Chaxiraxi", "¿Y el farol que te di? ¿También es un cuento? Mira cómo se apartan las sombras cuando lo enciendes."],
	["Chaxiraxi", "La piedra de Tenerife está mar adentro, en lo hondo. Solo se deja ver de noche, donde el agua brilla dorada."],
	["Chaxiraxi", "Tu abuelo la buscó antes que tú. Tráemela, Acorán. Y no apagues el farol."],
]

const TALK_WAIT := [
	["Chaxiraxi", "La piedra solo se deja ver de noche, mar adentro, en el fondo profundo. Busca el agua dorada."],
]

const TALK2 := [
	["Chaxiraxi", "La has encontrado… Está fría. Apagada, como me temía."],
	["Chaxiraxi", "Pero mira. Ahí está. La luz de Magec todavía vive dentro.", "light"],
	["Acorán", "Cuando la saqué del agua me pareció oír algo bajo el barco. Como si alguien respirara."],
	["Chaxiraxi", "Guayota ya sabe quién eres. Y no es lo único que espera ahí abajo."],
	["Chaxiraxi", "He puesto un poco de la luz de la piedra dentro de tu farol. Ahora te protegerá mejor."],
	["Chaxiraxi", "Quedan seis. En Gran Canaria hay un hombre que compra todo lo raro que sale de las redes… Ten cuidado con él."],
]

const TALK_DONE := [
	["Chaxiraxi", "Ve con cuidado, mi niño. Y vuelve a dormir a casa, que la noche no es para nadie."],
]


func _ready() -> void:
	_build_pyramids_and_chaxiraxi()
	_build_stone_spot()
	beacon_mat = StandardMaterial3D.new()
	beacon_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	beacon_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	beacon_mat.albedo_color = Color(1.0, 0.78, 0.3, 0.22)
	beacon_mat.set("disable_fog", true)
	beacon_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.3
	cyl.bottom_radius = 1.2
	cyl.height = 70
	beacon = MeshInstance3D.new()
	beacon.mesh = cyl
	beacon.material_override = beacon_mat
	beacon.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	main.add_child(beacon)


func _build_pyramids_and_chaxiraxi() -> void:
	# Pirámides de Güímar: plataformas escalonadas de piedra volcánica.
	var stone := StandardMaterial3D.new()
	stone.albedo_color = Color("4a4038")
	stone.roughness = 1.0
	for p in [[-82.0, -96.0, 12.0], [-66.0, -102.0, 9.0], [-96.0, -108.0, 10.0]]:
		var base_y: float = max(main.land_h(p[0], p[1]), 0.5)
		var w: float = p[2]
		for step in 4:
			var bm := BoxMesh.new()
			bm.size = Vector3(w - step * 2.2, 1.2, w - step * 2.2)
			var mi := MeshInstance3D.new()
			mi.mesh = bm
			mi.material_override = stone
			mi.position = Vector3(p[0], base_y + 0.4 + step * 1.2, p[1])
			main.add_child(mi)
	# Chaxiraxi en la orilla, con su candil.
	var cx := -62.0
	var cz := -74.0
	var y: float = max(main.land_h(cx, cz), 0.4)
	var dress := StandardMaterial3D.new()
	dress.albedo_color = Color("2b2a33")
	var body := CapsuleMesh.new()
	body.radius = 0.45
	body.height = 1.7
	var bmi := MeshInstance3D.new()
	bmi.mesh = body
	bmi.material_override = dress
	bmi.position = Vector3(cx, y + 0.85, cz)
	main.add_child(bmi)
	var head := SphereMesh.new()
	head.radius = 0.25
	head.height = 0.5
	var skin := StandardMaterial3D.new()
	skin.albedo_color = Color("b98a6a")
	var hmi := MeshInstance3D.new()
	hmi.mesh = head
	hmi.material_override = skin
	hmi.position = Vector3(cx, y + 1.95, cz)
	main.add_child(hmi)
	var scarf := SphereMesh.new()
	scarf.radius = 0.29
	scarf.height = 0.4
	var smi := MeshInstance3D.new()
	smi.mesh = scarf
	smi.material_override = dress
	smi.position = Vector3(cx, y + 2.05, cz - 0.04)
	main.add_child(smi)
	chax_light = OmniLight3D.new()
	chax_light.light_color = Color("ffb45a")
	chax_light.omni_range = 14
	chax_light.position = Vector3(cx + 0.6, y + 1.6, cz + 0.3)
	main.add_child(chax_light)


func _build_stone_spot() -> void:
	stone_spot = Node3D.new()
	stone_spot.position = Vector3(STONE_SPOT.x, 0, STONE_SPOT.y)
	main.add_child(stone_spot)
	var gold := StandardMaterial3D.new()
	gold.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	gold.albedo_color = Color(1.0, 0.82, 0.35, 0.9)
	gold.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	gold.set("disable_fog", true)
	for i in 12:
		var sm := SphereMesh.new()
		sm.radius = 0.3
		sm.height = 0.6
		var mi := MeshInstance3D.new()
		mi.mesh = sm
		mi.material_override = gold
		stone_spot.add_child(mi)
		stone_bubbles.append({"m": mi, "o": randf() * 6.0, "r": 0.5 + randf() * 2.5})
	var glow := OmniLight3D.new()
	glow.light_color = Color("ffcc66")
	glow.light_energy = 3.0
	glow.omni_range = 18
	glow.position.y = 1.0
	stone_spot.add_child(glow)


# ---------- Estado de la misión ----------
func objective() -> String:
	match state:
		"talk1":
			return "Habla con Chaxiraxi, en la playa junto a las Pirámides de Güímar."
		"stone":
			return "Busca la Piedra de Magec: de noche, mar adentro, donde el agua brilla dorada."
		"return":
			return "Lleva la Piedra de Magec a Chaxiraxi."
	return "Piedras de Magec: %d/7 · Próximo destino: Gran Canaria (próximamente)" % stones


func target():
	match state:
		"talk1", "return":
			return CHAX_SPOT
		"stone":
			return STONE_SPOT if main.is_night() else null
	return null


func near(p: Vector2, r: float) -> bool:
	return Vector2(main.bx, main.bz).distance_to(p) < r


func hint() -> String:
	if near(CHAX_SPOT, 10.0):
		return "[center][color=#f2b33d]E[/color] · Hablar con Chaxiraxi[/center]"
	if state == "stone" and main.is_night() and near(STONE_SPOT, 7.0):
		return "[center][color=#f2b33d]E[/color] · Echar el sedal en el agua dorada[/center]"
	return ""


func try_interact() -> bool:
	if near(CHAX_SPOT, 10.0):
		match state:
			"talk1":
				start_dialogue(TALK1, func(): state = "stone")
			"stone":
				start_dialogue(TALK_WAIT)
			"return":
				start_dialogue(TALK2, _reward)
			_:
				start_dialogue(TALK_DONE)
		return true
	if state == "stone" and main.is_night() and near(STONE_SPOT, 7.0):
		main.start_special_fishing()
		return true
	return false


func got_stone() -> void:
	state = "return"
	main.panic = min(100.0, main.panic + 20.0)
	main.audio.sfx("stone", -4.0, 0.7)
	main.ui.toast("Has sacado la Piedra de Magec. Está fría como el fondo del mar.")
	main.save_game()


func _reward() -> void:
	state = "done"
	stones = 1
	main.lamp_mult = 0.5
	main.audio.sfx("stone")
	main.ui.toast("Farol mejorado: con él encendido, el miedo sube la mitad de rápido.")


# ---------- Diálogos ----------
func start_dialogue(l: Array, then := Callable()) -> void:
	lines = l
	line_i = 0
	after_dialogue = then
	main.mode = "talk"
	main.bv = 0.0
	_show()


func next_line() -> void:
	line_i += 1
	if line_i >= lines.size():
		main.ui.close_dialogue()
		main.mode = "sail"
		if after_dialogue.is_valid():
			after_dialogue.call()
		main.save_game()
		return
	_show()


func _show() -> void:
	var l: Array = lines[line_i]
	if l.size() > 2 and l[2] == "light":
		main.audio.sfx("stone")
		chax_light.light_energy = 5.0
	main.ui.show_dialogue(l[0], l[1], line_i, lines.size())


# ---------- Cada frame ----------
func _process(_dt: float) -> void:
	var tt: float = main.t
	var night: bool = main.is_night()
	stone_spot.visible = state == "stone" and night
	if stone_spot.visible:
		stone_spot.position.y = main.wave(STONE_SPOT.x, STONE_SPOT.y, tt) + 0.1
		var i := 0
		for b in stone_bubbles:
			var k := fmod(tt * 0.7 + b["o"], 2.0)
			b["m"].position = Vector3(cos(i * 0.7 + tt * 0.4) * b["r"], k * 0.8, sin(i * 1.1 + tt * 0.2) * b["r"])
			i += 1
	chax_light.light_energy = move_toward(chax_light.light_energy, 1.5 + (1.0 - main.daylight()) * 1.5, _dt)
	var tg = target()
	beacon.visible = tg != null and main.mode != "cinematic" and main.mode != "menu"
	if beacon.visible:
		beacon.position = Vector3(tg.x, 35, tg.y)
		beacon_mat.albedo_color.a = 0.14 + 0.08 * sin(tt * 2.0)
