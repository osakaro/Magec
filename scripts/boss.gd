extends Node
## Guayota, el demonio del Teide. Primer jefe de MAGEC.
##
## De noche, frente al Teide, sale del mar entre lava y agua hirviendo.
## Para vencerlo hay que prender los tres fuegos de Magec (con el farol encendido)
## mientras esquivas las rocas ardientes que escupe.

var main
var quest

const ARENA := Vector2(-150, 60)
const FIRE_R := 24.0

var phase := "idle"   # idle, rise, fight, defeat, retreat
var ptimer := 0.0
var fires: Array = []   # {pos, lit, light, flame}
var bombs: Array = []
var bomb_timer := 2.0
var boils: Array = []
var boil_cd := 0.0
var lines_said := 0

var body: Node3D
var body_light: OmniLight3D
var lava_mat: StandardMaterial3D
var bomb_mesh: SphereMesh
var bomb_mat: StandardMaterial3D
var mark_mat: StandardMaterial3D

const TAUNTS := [
	"GUAYOTA: «Pescador… hueles a la piedra.»",
	"GUAYOTA: «Tu abuelo también navegaba de noche.»",
	"GUAYOTA: «La luz de Magec se apaga. Siempre se apaga.»",
]

const DEFEAT := [
	["Guayota", "Magec… Otra vez tu luz. Maldita sea tu luz."],
	["Guayota", "Disfruta de tu fuego, pescador. Yo solo soy el perro que guarda la puerta."],
	["Guayota", "Pregúntale a tu abuelo qué duerme bajo San Borondón. Él lo sabe. Lleva treinta años oyéndolo respirar."],
	["Acorán", "¿Mi abuelo? ¿Qué sabes de mi abuelo?"],
	["Guayota", "…"],
]


func _ready() -> void:
	_build_fires()
	_build_body()
	bomb_mesh = SphereMesh.new()
	bomb_mesh.radius = 0.9
	bomb_mesh.height = 1.8
	bomb_mat = StandardMaterial3D.new()
	bomb_mat.albedo_color = Color("2a1a12")
	bomb_mat.emission_enabled = true
	bomb_mat.emission = Color("ff5a1a")
	bomb_mat.emission_energy_multiplier = 3.0
	mark_mat = StandardMaterial3D.new()
	mark_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mark_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mark_mat.albedo_color = Color(1.0, 0.25, 0.1, 0.7)
	mark_mat.set("disable_fog", true)
	# zonas de agua hirviendo
	var bm := StandardMaterial3D.new()
	bm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	bm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	bm.albedo_color = Color(1.0, 0.45, 0.1, 0.0)
	for a in [0.6, 2.3, 4.1]:
		var p := ARENA + Vector2(cos(a), sin(a)) * 13.0
		var c := CylinderMesh.new()
		c.top_radius = 4.0
		c.bottom_radius = 4.0
		c.height = 0.1
		var mi := MeshInstance3D.new()
		mi.mesh = c
		mi.material_override = bm
		mi.position = Vector3(p.x, 0, p.y)
		main.add_child(mi)
		boils.append({"pos": p, "node": mi})
	boils[0]["mat"] = bm


func _build_fires() -> void:
	var iron := StandardMaterial3D.new()
	iron.albedo_color = Color("2a2522")
	var buoy := StandardMaterial3D.new()
	buoy.albedo_color = Color("4a3a2a")
	for i in 3:
		var a := PI * 0.5 + i * TAU / 3.0
		var p := ARENA + Vector2(cos(a), sin(a)) * FIRE_R
		var g := Node3D.new()
		g.position = Vector3(p.x, 0, p.y)
		main.add_child(g)
		var base := CylinderMesh.new()
		base.top_radius = 0.9
		base.bottom_radius = 1.2
		base.height = 1.0
		var b := MeshInstance3D.new()
		b.mesh = base
		b.material_override = buoy
		g.add_child(b)
		var bowl := CylinderMesh.new()
		bowl.top_radius = 0.9
		bowl.bottom_radius = 0.4
		bowl.height = 0.6
		var w := MeshInstance3D.new()
		w.mesh = bowl
		w.material_override = iron
		w.position.y = 1.6
		g.add_child(w)
		var pole := CylinderMesh.new()
		pole.top_radius = 0.1
		pole.bottom_radius = 0.1
		pole.height = 1.2
		var pl := MeshInstance3D.new()
		pl.mesh = pole
		pl.material_override = iron
		pl.position.y = 1.0
		g.add_child(pl)
		var fm := StandardMaterial3D.new()
		fm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		fm.albedo_color = Color("ffcf5a")
		fm.set("disable_fog", true)
		var flame := SphereMesh.new()
		flame.radius = 0.6
		flame.height = 1.6
		var f := MeshInstance3D.new()
		f.mesh = flame
		f.material_override = fm
		f.position.y = 2.3
		f.visible = false
		g.add_child(f)
		var l := OmniLight3D.new()
		l.light_color = Color("ffb040")
		l.omni_range = 22
		l.light_energy = 0.0
		l.position.y = 2.6
		g.add_child(l)
		fires.append({"pos": p, "lit": false, "light": l, "flame": f, "node": g})


func _build_body() -> void:
	body = Node3D.new()
	body.visible = false
	main.add_child(body)
	var basalt := StandardMaterial3D.new()
	basalt.albedo_color = Color("2a1c16")
	basalt.roughness = 0.9
	basalt.emission_enabled = true
	basalt.emission = Color("5a1a0a")
	basalt.emission_energy_multiplier = 0.6
	basalt.set("disable_fog", true)
	var cone := CylinderMesh.new()
	cone.top_radius = 2.5
	cone.bottom_radius = 9.0
	cone.height = 18.0
	cone.radial_segments = 9
	cone.rings = 3
	var c := MeshInstance3D.new()
	c.mesh = cone
	c.material_override = basalt
	body.add_child(c)
	lava_mat = StandardMaterial3D.new()
	lava_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	lava_mat.albedo_color = Color("ff6a1a")
	lava_mat.set("disable_fog", true)
	var crown := TorusMesh.new()
	crown.inner_radius = 2.2
	crown.outer_radius = 3.0
	var cr := MeshInstance3D.new()
	cr.mesh = crown
	cr.material_override = lava_mat
	cr.position.y = 9.0
	body.add_child(cr)
	# grietas de lava por los lados
	for i in 6:
		var crack := BoxMesh.new()
		crack.size = Vector3(0.35, 9.0, 0.35)
		var k := MeshInstance3D.new()
		k.mesh = crack
		k.material_override = lava_mat
		var a := i * TAU / 6.0
		k.position = Vector3(cos(a) * 5.4, -1.0, sin(a) * 5.4)
		k.rotation = Vector3(sin(a) * 0.35, 0, -cos(a) * 0.35)
		body.add_child(k)
	var eye_m := StandardMaterial3D.new()
	eye_m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	eye_m.albedo_color = Color("fff07a")
	eye_m.set("disable_fog", true)
	var eye := SphereMesh.new()
	eye.radius = 0.8
	eye.height = 1.0
	for side in [-1.5, 1.5]:
		var e := MeshInstance3D.new()
		e.mesh = eye
		e.material_override = eye_m
		e.position = Vector3(side, 5.0, 4.6)
		body.add_child(e)
	var mouth := BoxMesh.new()
	mouth.size = Vector3(3.6, 0.7, 0.5)
	var mo := MeshInstance3D.new()
	mo.mesh = mouth
	mo.material_override = lava_mat
	mo.position = Vector3(0, 2.5, 5.2)
	body.add_child(mo)
	body_light = OmniLight3D.new()
	body_light.light_color = Color("ff6a1a")
	body_light.light_energy = 0.0
	body_light.omni_range = 90
	body_light.position.y = 10
	body.add_child(body_light)


# ---------- Interacción ----------
func _near_fire() -> Variant:
	for f in fires:
		if not f["lit"] and Vector2(main.bx, main.bz).distance_to(f["pos"]) < 6.0:
			return f
	return null


func hint() -> String:
	if quest.state != "guayota":
		return ""
	var f = _near_fire()
	if f == null:
		return ""
	if not main.lamp_on:
		return "[color=#f2b33d]F[/color] · Enciende el farol para prender el fuego de Magec"
	return "[color=#f2b33d]E[/color] · Prender el fuego de Magec"


func try_interact() -> bool:
	if quest.state != "guayota":
		return false
	var f = _near_fire()
	if f == null:
		return false
	if not main.lamp_on:
		main.ui.toast("El brasero no prende. Necesitas la luz del farol de Magec.")
		return true
	f["lit"] = true
	f["flame"].visible = true
	f["light"].light_energy = 3.0
	main.audio.sfx("stone", -2.0, 1.2)
	var lit := 0
	for x in fires:
		lit += 1 if x["lit"] else 0
	if lit < 3:
		main.ui.toast("Fuego de Magec encendido (%d/3)." % lit)
		if phase == "fight":
			bomb_timer = 0.3
	else:
		main.ui.toast("¡Los tres fuegos arden!")
		if phase == "fight" or phase == "rise":
			_defeat()
		else:
			# encendidos sin que él saliera: sale igual, y cae enseguida
			_start()
			_defeat()
	return true


# ---------- Fases ----------
func _start() -> void:
	phase = "rise"
	ptimer = 0.0
	lines_said = 0
	body.visible = true
	body.position = Vector3(ARENA.x, -22, ARENA.y)
	main.audio.sfx("rumble", 4.0)
	main.audio.sfx("growl", 2.0, 0.5)
	main.ui.shake(1.2)
	main.ui.toast("El mar hierve frente al Teide. ¡GUAYOTA!")


func _defeat() -> void:
	phase = "defeat"
	ptimer = 0.0
	main.audio.sfx("growl", 4.0, 0.4)
	main.audio.sfx("rumble", 2.0, 0.8)
	main.ui.shake(1.0)
	_clear_bombs()


func _retreat(msg: String) -> void:
	phase = "retreat"
	ptimer = 0.0
	_clear_bombs()
	for f in fires:
		f["lit"] = false
		f["flame"].visible = false
		f["light"].light_energy = 0.0
	main.ui.toast(msg)


func _clear_bombs() -> void:
	for b in bombs:
		b["node"].queue_free()
		b["mark"].queue_free()
	bombs.clear()


func _spawn_bomb() -> void:
	var lead: Vector2 = Vector2(-sin(main.ba), -cos(main.ba)) * main.bv * 1.3
	var tgt: Vector2 = Vector2(main.bx, main.bz) + lead + Vector2(randf_range(-3, 3), randf_range(-3, 3))
	var n := MeshInstance3D.new()
	n.mesh = bomb_mesh
	n.material_override = bomb_mat
	main.add_child(n)
	var tm := TorusMesh.new()
	tm.inner_radius = 3.6
	tm.outer_radius = 4.4
	var mk := MeshInstance3D.new()
	mk.mesh = tm
	mk.material_override = mark_mat
	mk.scale.y = 0.1
	mk.position = Vector3(tgt.x, main.wave(tgt.x, tgt.y, main.t) + 0.2, tgt.y)
	main.add_child(mk)
	bombs.append({"from": body.position + Vector3(0, 9, 0), "to": tgt, "t": 0.0, "dur": 1.9, "node": n, "mark": mk})


func _process(dt: float) -> void:
	if main.mode == "menu" or main.mode == "cinematic":
		return
	var tt: float = main.t
	var dist: float = Vector2(main.bx, main.bz).distance_to(ARENA)
	for f in fires:
		var g: Node3D = f["node"]
		g.position.y = main.wave(f["pos"].x, f["pos"].y, tt) - 0.3
		if f["lit"]:
			f["flame"].scale = Vector3.ONE * (1.0 + 0.15 * sin(tt * 12.0 + f["pos"].x))
	var bm: StandardMaterial3D = boils[0]["mat"]
	var boiling := phase == "fight" or phase == "rise"
	bm.albedo_color.a = move_toward(bm.albedo_color.a, (0.45 + 0.15 * sin(tt * 6.0)) if boiling else 0.0, dt)
	for b in boils:
		b["node"].position.y = main.wave(b["pos"].x, b["pos"].y, tt) + 0.05

	match phase:
		"idle":
			if quest.state == "guayota" and main.is_night() and dist < 60.0 and main.mode == "sail":
				_start()
		"rise":
			ptimer += dt
			body.position.y = lerp(-22.0, -1.0, clamp(ptimer / 4.0, 0.0, 1.0))
			body_light.light_energy = min(ptimer, 4.0)
			if ptimer > 4.0:
				phase = "fight"
				bomb_timer = 1.0
				main.ui.toast("Prende los tres fuegos de Magec. ¡Esquiva la lava!")
		"fight":
			ptimer += dt
			body.position.y = -1.0 + sin(tt * 0.8) * 0.6
			body.rotation.y = atan2(main.bx - ARENA.x, main.bz - ARENA.y)
			bomb_timer -= dt
			if bomb_timer <= 0.0:
				var lit := 0
				for x in fires:
					lit += 1 if x["lit"] else 0
				bomb_timer = (1.6 - lit * 0.3) / main.diff("bomb")
				_spawn_bomb()
			if int(ptimer / 9.0) > lines_said and lines_said < TAUNTS.size():
				main.ui.toast(TAUNTS[lines_said])
				lines_said += 1
			# agua hirviendo
			boil_cd = max(0.0, boil_cd - dt)
			for b in boils:
				if boil_cd <= 0.0 and Vector2(main.bx, main.bz).distance_to(b["pos"]) < 4.0:
					boil_cd = 2.5
					main.hazards.damage("¡El agua hierve bajo el casco!")
			if not main.is_night():
				_retreat("Amanece. Guayota se hunde en el mar… volverá la próxima noche.")
			elif dist > 110.0:
				_retreat("Te alejas. Guayota vuelve al fondo y apaga los fuegos.")
			elif main.hull <= 1 and main.mode == "sail" and dist > 200.0:
				_retreat("Guayota se retira.")
		"defeat":
			ptimer += dt
			body.position.y = lerp(-1.0, -24.0, clamp(ptimer / 4.0, 0.0, 1.0))
			body_light.light_energy = max(0.0, 4.0 - ptimer)
			if ptimer > 4.0:
				phase = "done"
				body.visible = false
				quest.start_dialogue(DEFEAT, func():
					quest.boss_defeated()
					main.ui.toast("Guayota ha vuelto al fondo. Ve a contárselo a Chaxiraxi."))
		"retreat":
			ptimer += dt
			body.position.y -= dt * 6.0
			body_light.light_energy = max(0.0, body_light.light_energy - dt)
			if ptimer > 3.0:
				body.visible = false
				phase = "idle"

	# rocas de lava en vuelo
	for b in bombs.duplicate():
		b["t"] += dt
		var k: float = b["t"] / b["dur"]
		var to3 := Vector3(b["to"].x, 0, b["to"].y)
		var p: Vector3 = b["from"].lerp(to3, k)
		p.y += sin(PI * k) * 22.0
		b["node"].position = p
		b["mark"].scale = Vector3(1.0 - k * 0.5, 0.1, 1.0 - k * 0.5)
		if k >= 1.0:
			main.audio.sfx("splash", 2.0, 0.6)
			if Vector2(main.bx, main.bz).distance_to(b["to"]) < 4.5:
				main.audio.sfx("crack")
				main.hazards.damage("¡Una roca ardiente te alcanza!")
			b["node"].queue_free()
			b["mark"].queue_free()
			bombs.erase(b)
