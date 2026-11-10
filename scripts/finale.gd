extends Node
## El Hierro y el final de MAGEC.
##
## lp_done -> (hablas con Bentor, el farero) -> eh_calm -> de noche, en el Mar de las
## Calmas, lees la bitácora de Aridane -> San Borondón surge del mar -> eh_island ->
## hablas con Aridane -> llega Baltasar -> final según lo que hayas hecho.

var main
var quest

const READ_SPOT := Vector2(-30, 118)
const SB_CENTER := Vector2(-30, 178)
const SB_R := 32.0
const SHORE := Vector2(-30, 134)

var sb: Node3D
var eye_slit: MeshInstance3D
var eye_mat: StandardMaterial3D
var risen := false
var rise_t := -1.0
var baltasar_ship: Node3D
var ship_t := -1.0
var ending := ""

const BENTOR := [
	["Bentor", "Llevo cuarenta años en el faro de Orchilla, donde se acaba el mundo conocido. Y nunca había visto el mar tan quieto."],
	["Bentor", "El Mar de las Calmas, lo llaman. Ahora mismo no se mueve ni una ola. Como si algo debajo contuviera la respiración."],
	["Acorán", "Traigo la bitácora de mi abuelo. Dice que hay que leer la última página en el Mar de las Calmas, de noche."],
	["Bentor", "Entonces ve, muchacho. Al sur del puerto, mar adentro. Y que Magec te alumbre."],
]
const BENTOR_WAIT := [["Bentor", "De noche, al sur, en el Mar de las Calmas. Lee la bitácora en voz alta."]]
const READ := [
	["Acorán", "«Yo, Aridane, pescador de Güímar, he visto la isla que no está en los mapas.»"],
	["Acorán", "«Quien lea esto en el Mar de las Calmas, que encienda su farol y llame a la isla por su nombre.»"],
	["Acorán", "…San Borondón."],
]
const ARIDANE := [
	["Aridane", "¿Acorán? … Tienes la cara de tu padre. Y los ojos de tu abuela."],
	["Acorán", "Abuelo… Treinta años. Te dimos por muerto."],
	["Aridane", "Casi lo estoy, mi niño. Esta isla no te deja envejecer, pero tampoco te deja vivir."],
	["Aridane", "Lo que duerme aquí debajo es más viejo que las islas. Magec lo durmió con siete piedras. Guayota y los perros negros solo guardan la puerta."],
	["Aridane", "Cuando las piedras se apagan, se revuelve en sueños. Por eso salen los peces raros: son sus sueños, que se escapan al mar."],
	["Aridane", "Yo guardo la séptima piedra. Si alguien la enciende con la luz de las otras seis, dormirá otros mil años."],
	["Acorán", "Las seis están en mi farol, abuelo."],
	["Aridane", "Entonces solo falta…", "baltasar"],
	["Don Baltasar", "Qué escena tan conmovedora. Abuelo y nieto, juntos al fin."],
	["Don Baltasar", "Treinta años, Aridane. Treinta años comprando los sueños de la bestia, pez a pez, para que despertara."],
	["Aridane", "¿Y para qué la quieres despierta, Baltasar?"],
	["Don Baltasar", "Porque quien la despierta, la gobierna. Y con ella, el mar entero."],
]
const BAD := [
	["Don Baltasar", "Y tú me has ayudado muchísimo, muchacho. Cada pez especial que me vendiste era un trozo de su sueño."],
	["Don Baltasar", "Ya tengo suficiente."],
	["Aridane", "Acorán… ¿qué has hecho?", "wake"],
	["Don Baltasar", "Despierta."],
]
const BEFORE_CHOICE := [
	["Don Baltasar", "Pero no me has traído suficientes. No importa. La despertaré por las malas."],
	["Aridane", "No mientras quede luz de Magec. Acorán, la piedra. Ahora."],
]
const GOOD := [
	["Acorán", "La enciendo, abuelo.", "light"],
	["Aridane", "Mira cómo se duerme… como un niño. Mil años de calma."],
	["Don Baltasar", "¡No! ¡Treinta años!", "swallow"],
	["Aridane", "Vete a casa, mi niño. Paga el barco. Y cuando haya calma chicha, ven a saludarme."],
]
const RELEVO := [
	["Acorán", "La enciendo yo. Y me quedo yo, abuelo.", "light"],
	["Aridane", "¿Qué dices, insensato?"],
	["Acorán", "Llevas treinta años aquí. Vuelve tú a Güímar. Chaxiraxi te espera. Pancho te espera."],
	["Don Baltasar", "¡No! ¡Treinta años!", "swallow"],
	["Aridane", "… Eres más terco que yo. Igualito."],
]

const ENDINGS := {
	"good": ["FINAL · LA LUZ DE MAGEC", "Acorán encendió la última piedra. La criatura suspiró y volvió a dormirse, y San Borondón se hundió en la niebla con Aridane, que siguió guardándola como había hecho siempre.\n\nEl galeón de Baltasar nunca volvió a puerto.\n\nEn Güímar, las noches volvieron a ser solo noches. Acorán pagó el barco, y cada año, cuando hay calma chicha, sale al oeste a saludar a su abuelo."],
	"relevo": ["FINAL · EL GUARDIÁN", "Acorán ocupó el lugar de su abuelo. Aridane volvió a Güímar treinta años después, con la misma cara de no haber dormido, y Chaxiraxi lloró al verlo.\n\nEl galeón de Baltasar nunca volvió a puerto.\n\nDicen que, en las noches de calma, desde la caleta se oye un silbo que viene del oeste, de una isla que no está en ningún mapa."],
	"bad": ["FINAL · EL DESPERTAR", "La isla se movió. Abrió un ojo del tamaño de un barranco y miró a Acorán.\n\nEsa noche, en todas las costas de Canarias, el mar se retiró cien metros y volvió como un muro. Nadie volvió a pescar de noche.\n\nDesde el Teide, dicen, todavía se ve algo enorme nadando hacia el oeste. Y en su lomo, un hombre de negro."],
}


func _ready() -> void:
	_build_island()


func _build_island() -> void:
	sb = Node3D.new()
	sb.position = Vector3(SB_CENTER.x, -60, SB_CENTER.y)
	sb.visible = false
	main.add_child(sb)
	# relieve verde de la isla
	var keep = main.terrain_mat
	var gm := ShaderMaterial.new()
	gm.shader = load("res://shaders/terrain.gdshader")
	gm.set_shader_parameter("detail", keep.get_shader_parameter("detail"))
	gm.set_shader_parameter("snow_line", 9999.0)
	gm.set_shader_parameter("green", 1.0)
	gm.set_shader_parameter("scrub", Color(0.2, 0.4, 0.18))
	gm.set_shader_parameter("earth", Color(0.25, 0.3, 0.2))
	gm.set_shader_parameter("glow", 0.55)
	main.terrain_mat = gm
	var before: int = main.get_child_count()
	main._mountain(Vector3(0, -6, 0), SB_R + 8.0, 34.0, 99)
	main.terrain_mat = keep
	var mtn: Node = main.get_child(before)
	main.remove_child(mtn)
	sb.add_child(mtn)
	# lomo de la criatura: crestas de roca
	var rock := StandardMaterial3D.new()
	rock.albedo_color = Color("2b2a26")
	for i in 9:
		var c := CylinderMesh.new()
		c.top_radius = 0.0
		c.bottom_radius = 3.5 - abs(i - 4) * 0.4
		c.height = 9.0 - abs(i - 4) * 0.8
		c.radial_segments = 5
		var mi := MeshInstance3D.new()
		mi.mesh = c
		mi.material_override = rock
		mi.position = Vector3(-24 + i * 6.0, 26.0 - abs(i - 4) * 3.0, 6.0)
		mi.rotation.z = (i - 4) * 0.08
		sb.add_child(mi)
	# árboles
	var laurel: ArrayMesh = main._laurel_mesh()
	var tf: Array = []
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for i in 40:
		var a := rng.randf() * TAU
		var r := rng.randf_range(6.0, SB_R - 6.0)
		var x := cos(a) * r
		var z := sin(a) * r
		var y := 34.0 * pow(1.0 - r / (SB_R + 8.0), 1.35) - 6.5
		tf.append(Transform3D(Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3.ONE * rng.randf_range(0.8, 1.3)), Vector3(x, y, z)))
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = laurel
	mm.instance_count = tf.size()
	for i in tf.size():
		mm.set_instance_transform(i, tf[i])
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	var lm := StandardMaterial3D.new()
	lm.albedo_color = Color("2f5a2a")
	lm.emission_enabled = true
	lm.emission = Color("2f7a3a")
	lm.emission_energy_multiplier = 0.5
	mmi.material_override = lm
	sb.add_child(mmi)
	# el ojo dormido, en el acantilado que mira al barco
	var lid := SphereMesh.new()
	lid.radius = 1.0
	lid.height = 2.0
	var lid_m := StandardMaterial3D.new()
	lid_m.albedo_color = Color("1a1714")
	var li := MeshInstance3D.new()
	li.mesh = lid
	li.material_override = lid_m
	li.scale = Vector3(7.0, 3.2, 1.5)
	li.position = Vector3(0, 6.0, -SB_R - 1.0)
	sb.add_child(li)
	eye_mat = StandardMaterial3D.new()
	eye_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	eye_mat.albedo_color = Color(0.6, 1.0, 0.5)
	eye_mat.set("disable_fog", true)
	eye_slit = MeshInstance3D.new()
	eye_slit.mesh = Props_box(Vector3(9.0, 0.25, 0.3))
	eye_slit.material_override = eye_mat
	eye_slit.position = Vector3(0, 6.0, -SB_R - 2.4)
	sb.add_child(eye_slit)
	# Aridane en la orilla, con su barca varada y un farol
	var aridane_pos := Vector3(0, 0.6, -SB_R + 3.0)
	_person(sb, aridane_pos, Color("3a4a3a"), Color("c4a080"), Color("dcd6c8"))
	var lamp := OmniLight3D.new()
	lamp.light_color = Color("ffd27a")
	lamp.light_energy = 2.5
	lamp.omni_range = 20
	lamp.position = aridane_pos + Vector3(0.8, 1.6, 0)
	sb.add_child(lamp)
	var glow := OmniLight3D.new()
	glow.light_color = Color(0.5, 1.0, 0.6)
	glow.light_energy = 7.0
	glow.omni_range = 150
	glow.position = Vector3(0, 30, -20)
	# bruma verde que envuelve la isla
	var mist_m := StandardMaterial3D.new()
	mist_m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mist_m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mist_m.albedo_color = Color(0.6, 1.0, 0.7, 0.18)
	mist_m.set("disable_fog", true)
	mist_m.cull_mode = BaseMaterial3D.CULL_DISABLED
	var mist := TorusMesh.new()
	mist.inner_radius = SB_R - 4.0
	mist.outer_radius = SB_R + 6.0
	var mi2 := MeshInstance3D.new()
	mi2.mesh = mist
	mi2.material_override = mist_m
	mi2.scale.y = 0.35
	mi2.position.y = 1.5
	sb.add_child(mi2)
	sb.add_child(glow)


static func Props_box(size: Vector3) -> BoxMesh:
	var b := BoxMesh.new()
	b.size = size
	return b


func _person(parent: Node3D, pos: Vector3, body_col: Color, skin: Color, hat: Color) -> void:
	var m := StandardMaterial3D.new()
	m.albedo_color = body_col
	var body := CapsuleMesh.new()
	body.radius = 0.4
	body.height = 1.7
	var b := MeshInstance3D.new()
	b.mesh = body
	b.material_override = m
	b.position = pos + Vector3(0, 0.85, 0)
	parent.add_child(b)
	var sm := StandardMaterial3D.new()
	sm.albedo_color = skin
	var head := SphereMesh.new()
	head.radius = 0.24
	head.height = 0.48
	var h := MeshInstance3D.new()
	h.mesh = head
	h.material_override = sm
	h.position = pos + Vector3(0, 1.95, 0)
	parent.add_child(h)
	var hm := StandardMaterial3D.new()
	hm.albedo_color = hat
	var beard := SphereMesh.new()
	beard.radius = 0.2
	beard.height = 0.3
	var bd := MeshInstance3D.new()
	bd.mesh = beard
	bd.material_override = hm
	bd.position = pos + Vector3(0, 1.8, -0.12)
	parent.add_child(bd)


# ---------- Historia ----------
func handles() -> bool:
	return main.region == "el_hierro"


func objective() -> String:
	match quest.state:
		"lp_done":
			return "Busca a Bentor, el farero de Orchilla, en el puerto de La Restinga."
		"eh_calm":
			return "De noche, al sur, en el Mar de las Calmas: lee la bitácora de Aridane."
		"eh_island":
			return "Desembarca en San Borondón. Alguien te espera en la orilla."
	return ""


func target() -> Variant:
	match quest.state:
		"lp_done":
			return Vector2(0, -58)
		"eh_calm":
			return READ_SPOT if main.is_night() else null
		"eh_island":
			return SHORE
	return null


func hint() -> String:
	if quest.state == "eh_calm" and main.is_night() and quest.near(READ_SPOT, 14.0):
		return "[color=#f2b33d]E[/color] · Leer la última página de la bitácora"
	if quest.state == "eh_island" and quest.near(SHORE, 13.0):
		return "[color=#f2b33d]E[/color] · Hablar con el hombre de la orilla"
	return ""


func try_interact() -> bool:
	if quest.state == "eh_calm" and main.is_night() and quest.near(READ_SPOT, 14.0):
		quest.start_dialogue(READ, _rise)
		return true
	if quest.state == "eh_island" and quest.near(SHORE, 13.0):
		quest.start_dialogue(ARIDANE, _after_aridane)
		return true
	return false


func talk_port() -> void:
	match quest.state:
		"lp_done":
			quest.start_dialogue(BENTOR, func(): quest.state = "eh_calm")
		"eh_calm":
			quest.start_dialogue(BENTOR_WAIT)
		_:
			quest.start_dialogue([["Bentor", "El mar sigue en calma. Mientras dure, todo irá bien."]])


func on_event(ev: String) -> bool:
	## Eventos que lanzan algunas líneas de diálogo.
	match ev:
		"baltasar":
			_spawn_baltasar()
			return true
		"wake":
			eye_mat.albedo_color = Color(1.0, 0.25, 0.1)
			var tw := create_tween()
			tw.tween_property(eye_slit, "scale", Vector3(1.0, 18.0, 1.0), 2.0)
			main.audio.sfx("rumble", 6.0, 0.6)
			main.audio.sfx("growl", 6.0, 0.35)
			main.ui.shake(2.5)
			return true
		"swallow":
			if baltasar_ship:
				var tw := create_tween()
				tw.tween_property(baltasar_ship, "position:y", -30.0, 5.0)
			main.audio.sfx("rumble", 2.0, 0.9)
			return true
	return false


func _rise() -> void:
	rise_t = 0.0
	sb.visible = true
	main.mode = "scene"
	main.audio.sfx("rumble", 6.0, 0.7)
	main.audio.sfx("whistle_answer", 2.0, 0.6)
	main.ui.shake(1.5)
	main.ui.toast("El mar se abre. Algo enorme sube desde el fondo…")


func _spawn_baltasar() -> void:
	baltasar_ship = load("res://scripts/props.gd").ghost_ship(main, true)
	baltasar_ship.position = Vector3(SHORE.x + 40.0, 0.3, SHORE.y - 30.0)
	baltasar_ship.rotation.y = -0.9
	ship_t = 0.0
	main.audio.sfx("growl", -6.0, 0.6)


func _after_aridane() -> void:
	if quest.mutants_sold >= 10:
		quest.start_dialogue(BAD, func(): _end("bad"))
	else:
		quest.start_dialogue(BEFORE_CHOICE, func():
			main.ui.show_choice("¿Qué haces con la séptima Piedra de Magec?", [
				"Encenderla y dejar que el abuelo siga guardando la isla",
				"Encenderla y quedarte tú como guardián para que él vuelva a casa",
			], func(i: int):
				if i == 0:
					quest.start_dialogue(GOOD, func(): _end("good"))
				else:
					quest.start_dialogue(RELEVO, func(): _end("relevo"))))


func _end(kind: String) -> void:
	ending = kind
	quest.state = "end"
	quest.stones = 7 if kind != "bad" else 6
	main.save_game()
	var e: Array = ENDINGS[kind]
	main.ui.show_ending(e[0], e[1])


func solid(x: float, z: float) -> bool:
	## La isla es tierra firme cuando ha subido.
	return risen and Vector2(x, z).distance_to(SB_CENTER) < SB_R - 1.0


func _process(dt: float) -> void:
	if main == null:
		return
	var tt: float = main.t
	if rise_t >= 0.0:
		rise_t += dt
		sb.position.y = lerp(-60.0, 0.0, clamp(rise_t / 9.0, 0.0, 1.0))
		if rise_t > 9.0:
			rise_t = -1.0
			risen = true
			quest.state = "eh_island"
			main.mode = "sail"
			main.ui.toast("San Borondón. Verde, con árboles… y respira.")
			main.save_game()
	if risen or rise_t >= 0.0:
		# la isla respira
		sb.scale = Vector3(1.0, 1.0 + sin(tt * 0.45) * 0.015, 1.0)
		eye_mat.albedo_color.a = 1.0
	if baltasar_ship and ship_t >= 0.0:
		ship_t += dt
		var p := baltasar_ship.position
		baltasar_ship.position = Vector3(p.x - dt * 3.0 * float(ship_t < 6.0), p.y if p.y < 0.0 else main.wave(p.x, p.z, tt) + 0.3, p.z + dt * 2.0 * float(ship_t < 6.0))


func to_dict() -> Dictionary:
	return {"risen": risen, "ending": ending}


func from_dict(d: Dictionary) -> void:
	risen = bool(d.get("risen", false))
	ending = str(d.get("ending", ""))
	if risen:
		sb.visible = true
		sb.position.y = 0.0
