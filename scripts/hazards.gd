extends Node
## Peligros del mar: rocas y bajíos que dañan el casco, y el Tibicena,
## el perro-demonio que sale del agua de noche y persigue al barco.

var main

var rocks: Array = []   # {x, z, r, sunk}
var hit_cooldown := 0.0

# Tibicena
var beast: Node3D
var beast_eyes: StandardMaterial3D
var hunting := false
var bpos := Vector3.ZERO
var bstate := ""   # rise, chase, circle, dive
var btimer := 0.0
var cooldown := 30.0


func _ready() -> void:
	_build_rocks()
	_build_beast()


# =================== Rocas ===================
func _ok_place(x: float, z: float) -> bool:
	if main.land_h(x, z) > -3.0:
		return false
	if Vector2(x, z - 20).length() > 185.0:
		return false
	var avoid := [Vector2(0, -46), Vector2(0, -58), Vector2(-62, -62), Vector2(20, 150)]
	for s in main.spots:
		avoid.append(Vector2(s["x"], s["z"]))
	for a in avoid:
		if a.distance_to(Vector2(x, z)) < 16.0:
			return false
	for r in rocks:
		if Vector2(r["x"], r["z"]).distance_to(Vector2(x, z)) < 12.0:
			return false
	return true


func _build_rocks() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 2024
	var basalt := StandardMaterial3D.new()
	basalt.albedo_color = Color("2b2622")
	basalt.roughness = 0.95
	var foam := StandardMaterial3D.new()
	foam.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	foam.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	foam.albedo_color = Color(0.95, 0.97, 0.97, 0.55)
	var tries := 0
	while rocks.size() < 30 and tries < 2000:
		tries += 1
		var x := rng.randf_range(-170, 170)
		var z := rng.randf_range(-60, 200)
		if not _ok_place(x, z):
			continue
		var r := rng.randf_range(1.8, 4.5)
		var sunk := rng.randf() < 0.3
		var g := Node3D.new()
		g.position = Vector3(x, 0, z)
		main.add_child(g)
		if not sunk:
			for k in rng.randi_range(1, 3):
				var sm := SphereMesh.new()
				sm.radius = 1.0
				sm.height = 2.0
				sm.radial_segments = 6
				sm.rings = 3
				var mi := MeshInstance3D.new()
				mi.mesh = sm
				mi.material_override = basalt
				var rr := r * rng.randf_range(0.5, 1.0)
				mi.scale = Vector3(rr, rr * rng.randf_range(0.6, 1.3), rr * rng.randf_range(0.7, 1.1))
				mi.position = Vector3(rng.randf_range(-1, 1) * r * 0.4, rng.randf_range(-0.5, 0.6), rng.randf_range(-1, 1) * r * 0.4)
				mi.rotation.y = rng.randf() * TAU
				g.add_child(mi)
		var tm := TorusMesh.new()
		tm.inner_radius = r * (0.6 if sunk else 0.95)
		tm.outer_radius = r * (1.0 if sunk else 1.25)
		tm.rings = 16
		tm.ring_segments = 6
		var ring := MeshInstance3D.new()
		ring.mesh = tm
		ring.material_override = foam
		ring.scale.y = 0.08
		g.add_child(ring)
		rocks.append({"x": x, "z": z, "r": r, "sunk": sunk, "ring": ring})


func rock_at(x: float, z: float):
	for r in rocks:
		if Vector2(x, z).distance_to(Vector2(r["x"], r["z"])) < r["r"] + 1.4:
			return r
	return null


func hit_rock(speed: float) -> void:
	if hit_cooldown > 0.0:
		return
	hit_cooldown = 1.2
	if abs(speed) < 2.5:
		main.ui.toast("Rozas una roca. Cuidado.")
		return
	main.audio.sfx("crack")
	damage("Has chocado contra una roca. El casco se resiente.")


func damage(msg: String) -> void:
	main.hull -= 1
	main.ui.shake(0.5)
	if main.hull <= 0:
		_wreck()
	else:
		main.ui.toast(msg + " (Casco %d/%d)" % [main.hull, main.hull_max])


func _wreck() -> void:
	# Naufragio: pierdes la carga y te remolcan hasta Güímar.
	main.items.clear()
	main.hull = 1
	main.panic = 0.0
	main.bv = 0.0
	main.bx = 0.0
	main.bz = -46.0
	main.ba = PI
	var cost: int = min(main.money, 60)
	main.money -= cost
	main.advance(6 * 60)
	end_hunt(true)
	main.ui.toast("El barco se hunde. Te remolcan hasta Güímar (%d €). Has perdido la carga." % cost)
	main.ui.refresh_hold()
	main.save_game()


# =================== Tibicena ===================
func _build_beast() -> void:
	beast = Node3D.new()
	beast.visible = false
	main.add_child(beast)
	var black := StandardMaterial3D.new()
	black.albedo_color = Color("0b0a0c")
	black.roughness = 0.35
	black.metallic = 0.2
	var body := CapsuleMesh.new()
	body.radius = 0.75
	body.height = 3.6
	var b := MeshInstance3D.new()
	b.mesh = body
	b.material_override = black
	b.rotation_degrees.x = 90
	beast.add_child(b)
	var head := BoxMesh.new()
	head.size = Vector3(1.0, 0.9, 1.2)
	var h := MeshInstance3D.new()
	h.mesh = head
	h.material_override = black
	h.position = Vector3(0, 0.6, -2.0)
	beast.add_child(h)
	var snout := BoxMesh.new()
	snout.size = Vector3(0.6, 0.45, 0.9)
	var sn := MeshInstance3D.new()
	sn.mesh = snout
	sn.material_override = black
	sn.position = Vector3(0, 0.4, -2.9)
	beast.add_child(sn)
	var ear := PrismMesh.new()
	ear.size = Vector3(0.35, 0.7, 0.2)
	for side in [-0.35, 0.35]:
		var e := MeshInstance3D.new()
		e.mesh = ear
		e.material_override = black
		e.position = Vector3(side, 1.35, -1.8)
		beast.add_child(e)
	beast_eyes = StandardMaterial3D.new()
	beast_eyes.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	beast_eyes.albedo_color = Color(1.0, 0.15, 0.08)
	beast_eyes.set("disable_fog", true)
	var eye := SphereMesh.new()
	eye.radius = 0.13
	eye.height = 0.26
	for side in [-0.25, 0.25]:
		var e := MeshInstance3D.new()
		e.mesh = eye
		e.material_override = beast_eyes
		e.position = Vector3(side, 0.8, -2.62)
		beast.add_child(e)
	var glow := OmniLight3D.new()
	glow.light_color = Color(1, 0.15, 0.1)
	glow.light_energy = 1.5
	glow.omni_range = 6
	glow.position = Vector3(0, 0.8, -2.8)
	beast.add_child(glow)


func start_hunt() -> void:
	if hunting:
		return
	hunting = true
	bstate = "rise"
	btimer = 0.0
	var a := randf() * TAU
	bpos = Vector3(main.bx + cos(a) * 30.0, -4.0, main.bz + sin(a) * 30.0)
	beast.visible = true
	main.audio.sfx("growl", 2.0, 0.85)
	main.ui.toast("Algo negro sale del agua. Tiene ojos de brasa.")


func end_hunt(instant := false) -> void:
	if not hunting:
		return
	if instant:
		hunting = false
		beast.visible = false
		cooldown = 45.0
	else:
		bstate = "dive"
		btimer = 0.0


func _process(dt: float) -> void:
	if main == null:
		return
	hit_cooldown = max(0.0, hit_cooldown - dt)
	var tt: float = main.t
	for r in rocks:
		r["ring"].position.y = main.wave(r["x"], r["z"], tt) * 0.5
		r["ring"].scale.x = 1.0 + 0.05 * sin(tt * 2.0 + r["x"])
		r["ring"].scale.z = r["ring"].scale.x
	if main.mode == "menu" or main.mode == "cinematic":
		return
	cooldown = max(0.0, cooldown - dt)
	if not hunting:
		return
	var boat := Vector3(main.bx, 0, main.bz)
	var to_boat := boat - Vector3(bpos.x, 0, bpos.z)
	var dist := to_boat.length()
	btimer += dt
	# Se va al amanecer o si llegas al puerto
	if bstate != "dive" and (not main.is_night() or main.near_port() or Vector2(main.bx, main.bz).distance_to(Vector2(0, -58)) < 26.0):
		end_hunt()
		main.ui.toast("El Tibicena se hunde en el agua oscura.")
	var y_target: float = main.wave(bpos.x, bpos.z, tt) + 0.2
	match bstate:
		"rise":
			bpos.y = move_toward(bpos.y, y_target, dt * 2.5)
			if btimer > 2.0:
				bstate = "chase"
		"chase", "circle":
			bpos.y = y_target + sin(tt * 6.0) * 0.15
			var lamp: bool = main.lamp_on
			var speed: float = 7.0 + (0.0 if lamp else 1.5)
			if lamp and dist < 15.0:
				# La luz de Magec lo mantiene a raya: da vueltas sin acercarse
				bstate = "circle"
				var tangent := Vector3(-to_boat.z, 0, to_boat.x).normalized()
				var push := -to_boat.normalized() * (15.0 - dist) * 0.8
				bpos += (tangent * speed * 0.8 + push) * dt
			else:
				bstate = "chase"
				bpos += to_boat.normalized() * speed * dt
			if dist < 3.2 and not lamp:
				main.audio.sfx("knock")
				main.audio.sfx("growl", 0.0, 1.1)
				main.panic = min(100.0, main.panic + 15.0)
				main.bv = -3.0
				damage("¡El Tibicena muerde el casco!")
				if hunting:
					end_hunt()
			if btimer > 35.0:
				end_hunt()
		"dive":
			bpos.y -= dt * 2.0
			if btimer > 2.0:
				hunting = false
				beast.visible = false
				cooldown = 45.0
	beast.position = bpos
	if dist > 0.5:
		beast.look_at(Vector3(main.bx, bpos.y, main.bz), Vector3.UP)


func maybe_hunt(dt: float) -> void:
	## Se llama de noche, lejos del puerto. A más miedo y sin farol, más probable.
	if hunting or cooldown > 0.0:
		return
	if main.panic >= 99.0:
		start_hunt()
		main.panic = 75.0
	elif not main.lamp_on and main.panic > 70.0 and randf() < dt * 0.02:
		start_hunt()
