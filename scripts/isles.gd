extends Node
## Historia de Lanzarote (La Graciosa), Fuerteventura y La Palma.
##
## Cada isla: hablas con alguien en el puerto, superas una prueba propia, sacas la
## Piedra de Magec y vuelves para encenderla.
##  - Lanzarote: la piedra está en la cueva del Jameo; la morena abisal muerde si tardas.
##  - Fuerteventura: de noche sale un galeón fantasma; síguelo sin perderlo.
##  - La Palma: el pez remo gigante sube de noche; acompáñalo con el farol encendido.

var main
var quest

const CAVE := Vector2(-90, -61)
const GHOST_PATH := [Vector2(60, 40), Vector2(110, 90), Vector2(40, 140), Vector2(-50, 150)]
const REMO_PATH := [Vector2(-60, 80), Vector2(-120, 120), Vector2(-60, 160), Vector2(20, 130), Vector2(-10, 90)]

const ISLES := {
	"lanzarote": {
		"npc": "Marcial", "desc": "Pescador de La Graciosa. Fue amigo de Aridane.",
		"start": "lg_done", "task": "lz_stone", "stone": "lz_stone", "ret": "lz_return", "done": "lz_done", "n": 4, "lamp": 0.2,
		"intro": [
			["Marcial", "¿Acorán? ¡El nieto de Aridane en mi caleta! Ven aquí, que te vea la cara."],
			["Marcial", "Tu abuelo pasó por La Graciosa antes de irse. Me dejó su cuaderno de bitácora y me dijo: «Si un día viene mi nieto, dáselo»."],
			["Acorán", "¿Lo tiene usted?"],
			["Marcial", "Lo tengo. Pero primero haz lo que viniste a hacer. La piedra de Lanzarote está en la cueva del Jameo, al oeste de la caleta."],
			["Marcial", "La guarda una morena tan grande como tu barco. Cuando eches el sedal en la boca de la cueva, date prisa: cada vez que tardas, muerde."],
		],
		"wait": [["Marcial", "La cueva, al oeste de la caleta. Pesca rápido, que la morena no espera."]],
		"ret_lines": [
			["Marcial", "¡La has sacado de la boca de la morena! Tu abuelo estaría orgulloso."],
			["Marcial", "Déjala al sol un momento… mira. Se enciende sola, como si respirara.", "light"],
			["Marcial", "Y aquí tienes lo prometido. El cuaderno de Aridane."],
			["Acorán", "«Mar de las Calmas, El Hierro. Noche de calma chicha. Lee en voz alta la última página y la isla aparecerá.»"],
			["Marcial", "Siempre pensé que eran desvaríos de viejo. Ahora ya no estoy tan seguro."],
			["Marcial", "Te quedan Fuerteventura y La Palma. Y luego, El Hierro. Ve con Dios, muchacho."],
		],
		"later": [["Marcial", "La Graciosa siempre tiene sitio para el nieto de Aridane."]],
	},
	"fuerteventura": {
		"npc": "Saro", "desc": "Pescador majorero de Corralejo.",
		"start": "lz_done", "task": "fv_ghost", "stone": "fv_stone", "ret": "fv_return", "done": "fv_done", "n": 5, "lamp": 0.15,
		"intro": [
			["Saro", "Así que tú eres el de las piedras. Por aquí ya se habla de ti, chacho."],
			["Saro", "En Fuerteventura, de noche, salen los barcos de los naufragios. Galeones viejos, de cuando los piratas."],
			["Saro", "Uno de ellos siempre navega hacia el mismo sitio. Los viejos dicen que busca una luz bajo el agua."],
			["Saro", "Sal de noche, al sur del puerto. Cuando lo veas, síguelo de cerca. Si lo pierdes de vista, se desvanece hasta la noche siguiente."],
		],
		"wait": [["Saro", "De noche, al sur del puerto. Sigue al galeón sin perderlo de vista."]],
		"wait_stone": [["Saro", "Donde se paró el galeón, ahí brilla la piedra. Ve de noche."]],
		"ret_lines": [
			["Saro", "¡La quinta! Ni mi abuelo se lo creería."],
			["Saro", "Mira cómo le da la luz de la calima. Ya está, encendida.", "light"],
			["Saro", "Los del galeón eran marineros que buscaban lo mismo que tú. Ninguno volvió a casa."],
			["Saro", "A ti te queda La Palma. Y luego, la última, que no está en ninguna isla que yo conozca."],
		],
		"later": [["Saro", "Si ves el galeón otra vez, no lo sigas. Ya ha hecho su trabajo."]],
	},
	"la_palma": {
		"npc": "Elena", "desc": "Vulcanóloga. Vigila el volcán nuevo.",
		"start": "fv_done", "task": "lp_remo", "stone": "lp_stone", "ret": "lp_return", "done": "lp_done", "n": 6, "lamp": 0.1,
		"intro": [
			["Elena", "Tú debes de ser Acorán. Chaxiraxi me llamó. Dice que no estás loco, aunque lo parezca."],
			["Elena", "Desde la erupción, los sismógrafos registran algo que no es el volcán. Un latido lento, muy profundo."],
			["Elena", "Y de noche sube un pez remo gigante. La leyenda dice que suben antes de los terremotos. Este no para de subir."],
			["Elena", "Si lo acompañas de cerca con el farol encendido, no se asustará. Cuando baje, te dejará donde está la piedra. Eso creo."],
		],
		"wait": [["Elena", "De noche, mar adentro. Acompaña al pez remo de cerca y con el farol encendido."]],
		"wait_stone": [["Elena", "Donde bajó el pez remo. Ve de noche, que de día no se ve el brillo."]],
		"ret_lines": [
			["Elena", "La sexta piedra… Y el sismógrafo se ha quedado quieto. El latido ha parado."],
			["Elena", "Mírala. Ya brilla.", "light"],
			["Elena", "Acorán, lo que late no está en La Palma. Las ondas vienen del sur. De debajo del mar de El Hierro."],
			["Elena", "Si de verdad quieres terminar esto, tienes que ir allí. Pero ten cuidado: lo que respira no quiere despertar. O sí quiere."],
		],
		"later": [["Elena", "El volcán sigue humeando, pero el latido no ha vuelto. Por ahora."]],
	},
}

var ghost: Node3D
var ghost_t := 0.0
var ghost_seg := 0
var ghost_far := 0.0
var ghost_on := false
var remo: Node3D
var remo_segs: Array = []
var remo_on := false
var remo_seg := 0
var remo_t := 0.0
var remo_progress := 0.0
var remo_dive := Vector2(-10, 90)
var morena: Node3D
var morena_t := 0.0


func _ready() -> void:
	match main.region:
		"fuerteventura":
			ghost = load("res://scripts/props.gd").ghost_ship(main)
			ghost.visible = false
		"la_palma":
			_build_remo()
		"lanzarote":
			_build_morena()


func cfg() -> Dictionary:
	return ISLES.get(main.region, {})


func handles() -> bool:
	return ISLES.has(main.region)


# ---------- Datos de la historia ----------
func objective() -> String:
	var c := cfg()
	var st: String = quest.state
	match main.region:
		"lanzarote":
			match st:
				"lg_done":
					return "Busca a Marcial en el muelle de Caleta de Sebo."
				"lz_stone":
					return "Saca la piedra de la cueva del Jameo, al oeste. Pesca rápido: la morena muerde."
				"lz_return":
					return "Lleva la piedra a Marcial."
		"fuerteventura":
			match st:
				"lz_done":
					return "Busca a Saro en el puerto de Corralejo."
				"fv_ghost":
					return "De noche, al sur del puerto, sigue al galeón fantasma sin perderlo de vista."
				"fv_stone":
					return "De noche, pesca la piedra donde se paró el galeón."
				"fv_return":
					return "Lleva la piedra a Saro."
		"la_palma":
			match st:
				"fv_done":
					return "Busca a Elena, la vulcanóloga, en el puerto de Tazacorte."
				"lp_remo":
					return "De noche, mar adentro: acompaña al pez remo gigante con el farol encendido (%d%%)." % int(remo_progress / 25.0 * 100.0)
				"lp_stone":
					return "De noche, pesca la piedra donde bajó el pez remo."
				"lp_return":
					return "Lleva la piedra a Elena."
	return ""


func target() -> Variant:
	var st: String = quest.state
	var night: bool = main.is_night()
	match main.region:
		"lanzarote":
			if st == "lz_stone":
				return CAVE
		"fuerteventura":
			if st == "fv_ghost":
				if ghost_on:
					return Vector2(ghost.position.x, ghost.position.z)
				return GHOST_PATH[0] if night else null
			if st == "fv_stone":
				return GHOST_PATH[GHOST_PATH.size() - 1] if night else null
		"la_palma":
			if st == "lp_remo":
				if remo_on:
					return Vector2(remo.position.x, remo.position.z)
				return REMO_PATH[0] if night else null
			if st == "lp_stone":
				return remo_dive if night else null
	var c := cfg()
	if not c.is_empty() and (st == c["start"] or st == c["ret"]):
		return Vector2(0, -58)
	return null


func stone_pos() -> Vector2:
	match main.region:
		"lanzarote":
			return CAVE
		"fuerteventura":
			return GHOST_PATH[GHOST_PATH.size() - 1]
		"la_palma":
			return remo_dive
	return Vector2.ZERO


func stone_active() -> bool:
	var st: String = quest.state
	match main.region:
		"lanzarote":
			return st == "lz_stone"
		"fuerteventura":
			return st == "fv_stone" and main.is_night()
		"la_palma":
			return st == "lp_stone" and main.is_night()
	return false


func got_stone() -> void:
	quest.state = cfg()["ret"]
	if main.region != "lanzarote":
		main.hazards.cooldown = 0.0
		main.hazards.start_hunt()


func talk() -> void:
	var c := cfg()
	var st: String = quest.state
	if st == c["start"]:
		quest.start_dialogue(c["intro"], func(): quest.state = c["task"])
	elif st == c["ret"]:
		quest.start_dialogue(c["ret_lines"], func():
			quest.state = c["done"]
			quest.stones = c["n"]
			main.lamp_mult = c["lamp"]
			if main.region == "lanzarote":
				quest.bitacora = true
			main.ui.toast("Farol mejorado. Piedras de Magec: %d/7." % c["n"]))
	elif st == c["task"]:
		quest.start_dialogue(c["wait"])
	elif st == c["stone"]:
		quest.start_dialogue(c.get("wait_stone", c["wait"]))
	else:
		quest.start_dialogue(c["later"])


# ---------- Morena abisal (Lanzarote) ----------
func _build_morena() -> void:
	morena = Node3D.new()
	morena.visible = false
	main.add_child(morena)
	var m := StandardMaterial3D.new()
	m.albedo_color = Color("3b3020")
	m.roughness = 0.4
	for i in 10:
		var c := CapsuleMesh.new()
		c.radius = 0.9 - i * 0.05
		c.height = 2.6
		var mi := MeshInstance3D.new()
		mi.mesh = c
		mi.material_override = m
		mi.rotation_degrees.x = 90
		mi.position = Vector3(0, 0, i * 1.9)
		morena.add_child(mi)
	var eye := StandardMaterial3D.new()
	eye.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	eye.albedo_color = Color("e8d36a")
	var e := SphereMesh.new()
	e.radius = 0.22
	e.height = 0.44
	for sx in [-0.55, 0.55]:
		var ei := MeshInstance3D.new()
		ei.mesh = e
		ei.material_override = eye
		ei.position = Vector3(sx, 0.5, -0.6)
		morena.add_child(ei)


func fishing_tick(dt: float) -> void:
	## Mientras pescas la piedra en la cueva, la morena asoma y muerde cada pocos segundos.
	if main.region != "lanzarote" or not main.fishing.get("special", false):
		return
	morena.visible = true
	morena_t += dt
	var lunge: float = clamp(sin(morena_t / 3.6 * TAU) * 2.0, 0.0, 1.0)
	morena.position = Vector3(CAVE.x, -0.6 + lunge * 1.6, CAVE.y - 9.0 + lunge * 6.0)
	morena.rotation = Vector3(-0.2 - lunge * 0.4, PI, 0)
	if fmod(morena_t, 3.6) < dt:
		main.audio.sfx("growl", 0.0, 1.3)
		main.audio.sfx("crack")
		main.hazards.damage("¡La morena abisal muerde el casco!")


func fishing_end() -> void:
	if morena:
		morena.visible = false
		morena_t = 0.0


# ---------- Pez remo (La Palma) ----------
func _build_remo() -> void:
	remo = Node3D.new()
	remo.visible = false
	main.add_child(remo)
	var silver := StandardMaterial3D.new()
	silver.albedo_color = Color("d4dadf")
	silver.metallic = 0.6
	silver.roughness = 0.25
	silver.emission_enabled = true
	silver.emission = Color(0.6, 0.72, 0.85)
	silver.emission_energy_multiplier = 1.1
	var red := StandardMaterial3D.new()
	red.albedo_color = Color("d9332a")
	red.emission_enabled = true
	red.emission = Color("ff3a1a")
	red.emission_energy_multiplier = 1.2
	for i in 18:
		var b := BoxMesh.new()
		b.size = Vector3(0.9 - i * 0.03, 1.3 - i * 0.04, 2.2)
		var mi := MeshInstance3D.new()
		mi.mesh = b
		mi.material_override = silver
		mi.position.y = 0.9
		remo.add_child(mi)
		var crest := BoxMesh.new()
		crest.size = Vector3(0.08, 1.6 if i < 2 else 0.5, 2.0)
		var ci := MeshInstance3D.new()
		ci.mesh = crest
		ci.material_override = red
		ci.position.y = 0.9 if i < 2 else 0.75
		mi.add_child(ci)
		remo_segs.append(mi)
	var l := OmniLight3D.new()
	l.light_color = Color(0.7, 0.85, 1.0)
	l.light_energy = 1.5
	l.omni_range = 18
	remo.add_child(l)


# ---------- Cada frame ----------
func _process(dt: float) -> void:
	if main == null or main.mode == "menu" or main.mode == "cinematic":
		return
	var tt: float = main.t
	var boat := Vector2(main.bx, main.bz)
	# Galeón fantasma (Fuerteventura)
	if ghost:
		if quest.state == "fv_ghost" and main.is_night():
			if not ghost_on and boat.distance_to(GHOST_PATH[0]) < 90.0:
				ghost_on = true
				ghost_seg = 0
				ghost_t = 0.0
				ghost_far = 0.0
				ghost.visible = true
				main.audio.sfx("whistle_answer", -4.0, 0.5)
				main.ui.toast("Un galeón viejo aparece entre la calima. Síguelo.")
			if ghost_on:
				var a: Vector2 = GHOST_PATH[ghost_seg]
				var b: Vector2 = GHOST_PATH[min(ghost_seg + 1, GHOST_PATH.size() - 1)]
				var seg_len := a.distance_to(b)
				ghost_t += dt * 5.5 / max(seg_len, 1.0)
				if ghost_t >= 1.0:
					ghost_t = 0.0
					ghost_seg += 1
				var p := a.lerp(b, ghost_t)
				ghost.position = Vector3(p.x, main.wave(p.x, p.y, tt) + 0.3, p.y)
				ghost.rotation = Vector3(sin(tt) * 0.04, atan2(-(b.x - a.x), -(b.y - a.y)), cos(tt * 0.8) * 0.04)
				var d := boat.distance_to(p)
				ghost_far = ghost_far + dt if d > 60.0 else 0.0
				if ghost_far > 6.0:
					ghost_on = false
					ghost.visible = false
					main.ui.toast("El galeón se desvanece en la calima. Volverá otra noche.")
				elif ghost_seg >= GHOST_PATH.size() - 1:
					ghost_on = false
					quest.state = "fv_stone"
					main.ui.toast("El galeón se detiene… y se hunde sin hacer ruido. Bajo él, algo brilla.")
					main.save_game()
					get_tree().create_timer(3.0).timeout.connect(func(): ghost.visible = false)
		elif ghost_on and not main.is_night():
			ghost_on = false
			ghost.visible = false
	# Pez remo (La Palma)
	if remo:
		if quest.state == "lp_remo" and main.is_night():
			if not remo_on and boat.distance_to(REMO_PATH[0]) < 80.0:
				remo_on = true
				remo_seg = 0
				remo_t = 0.0
				remo.visible = true
				main.ui.toast("Una cinta de plata enorme sube a la superficie. El pez remo.")
			if remo_on:
				var a: Vector2 = REMO_PATH[remo_seg % REMO_PATH.size()]
				var b: Vector2 = REMO_PATH[(remo_seg + 1) % REMO_PATH.size()]
				remo_t += dt * 4.5 / max(a.distance_to(b), 1.0)
				if remo_t >= 1.0:
					remo_t = 0.0
					remo_seg += 1
				var p := a.lerp(b, remo_t)
				var dir := (b - a).normalized()
				remo.position = Vector3(p.x, main.wave(p.x, p.y, tt) - 0.2, p.y)
				remo.rotation.y = atan2(-dir.x, -dir.y)
				for i in remo_segs.size():
					var s: MeshInstance3D = remo_segs[i]
					s.position = Vector3(sin(tt * 3.0 - i * 0.5) * (0.3 + i * 0.08), 0.9 + sin(tt * 2.0 - i * 0.4) * 0.25, i * 2.1)
					s.rotation.y = cos(tt * 3.0 - i * 0.5) * 0.3
				var d := boat.distance_to(p)
				if d < 25.0 and main.lamp_on:
					remo_progress += dt
				if remo_progress >= 25.0:
					remo_on = false
					remo_dive = p
					quest.state = "lp_stone"
					main.ui.toast("El pez remo se sumerge despacio. Donde bajó, el agua empieza a brillar.")
					main.save_game()
					var tw := create_tween()
					tw.tween_property(remo, "position:y", -20.0, 4.0)
					tw.tween_callback(func(): remo.visible = false)
		elif remo_on and not main.is_night():
			remo_on = false
			remo.visible = false


func to_dict() -> Dictionary:
	return {"remo_progress": remo_progress, "remo_dive": [remo_dive.x, remo_dive.y]}


func from_dict(d: Dictionary) -> void:
	remo_progress = float(d.get("remo_progress", 0.0))
	var rd: Array = d.get("remo_dive", [-10, 90])
	remo_dive = Vector2(float(rd[0]), float(rd[1]))
