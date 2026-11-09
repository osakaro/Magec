extends Node
## Aparejos: nasas (se dejan en el mar y se llenan con el tiempo) y red de
## arrastre (pesca peces pequeños mientras navegas, pero frena el barco).

const Data = preload("res://scripts/data.gd")

const NASA_PRICE := 80
const NET_PRICE := 150
const MAX_NASAS := 2
const HOURS_PER_CATCH := 4.0
const NET_DISTANCE := 70.0

var main

var nasas_owned := 0
var nasas: Array = []    # {x, z, placed, node}
var net_owned := false
var net_out := false
var net_dist := 0.0
var net_floats: Array = []


func _ready() -> void:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color("e8692c")
	var sm := SphereMesh.new()
	sm.radius = 0.25
	sm.height = 0.5
	for i in 7:
		var mi := MeshInstance3D.new()
		mi.mesh = sm
		mi.material_override = m
		mi.visible = false
		main.add_child(mi)
		net_floats.append(mi)


func _make_buoy(x: float, z: float) -> Node3D:
	var g := Node3D.new()
	g.position = Vector3(x, 0, z)
	main.add_child(g)
	var red := StandardMaterial3D.new()
	red.albedo_color = Color("c43b2f")
	var white := StandardMaterial3D.new()
	white.albedo_color = Color("f1e9d8")
	var c1 := CylinderMesh.new()
	c1.top_radius = 0.35
	c1.bottom_radius = 0.45
	c1.height = 0.7
	var a := MeshInstance3D.new()
	a.mesh = c1
	a.material_override = red
	a.position.y = 0.2
	g.add_child(a)
	var c2 := CylinderMesh.new()
	c2.top_radius = 0.05
	c2.bottom_radius = 0.05
	c2.height = 1.6
	var b := MeshInstance3D.new()
	b.mesh = c2
	b.material_override = white
	b.position.y = 1.2
	g.add_child(b)
	var flag := BoxMesh.new()
	flag.size = Vector3(0.6, 0.35, 0.03)
	var f := MeshInstance3D.new()
	f.mesh = flag
	f.material_override = red
	f.position = Vector3(0.32, 1.8, 0)
	g.add_child(f)
	var l := OmniLight3D.new()
	l.light_color = Color("ff6a3a")
	l.light_energy = 0.8
	l.omni_range = 6
	l.position.y = 2.0
	g.add_child(l)
	return g


# ---------- Nasas ----------
func nasas_free() -> int:
	return nasas_owned - nasas.size()


func drop_nasa() -> void:
	if nasas_free() <= 0:
		main.ui.toast("No te quedan nasas a bordo. Cómpralas en el puerto." if nasas_owned == 0 else "Ya tienes todas tus nasas en el agua.")
		return
	if main.near_port():
		main.ui.toast("Aquí no: estás en el puerto.")
		return
	var n := {"x": main.bx, "z": main.bz, "placed": main.game_time, "node": _make_buoy(main.bx, main.bz)}
	nasas.append(n)
	main.audio.sfx("splash", -2.0, 0.8)
	main.ui.toast("Nasa echada al agua. Vuelve en unas horas.")
	main.save_game()


func _nasa_count(n: Dictionary) -> int:
	return clamp(int((main.game_time - n["placed"]) / 60.0 / HOURS_PER_CATCH), 0, 3)


func _near_nasa() -> Variant:
	for n in nasas:
		if Vector2(main.bx, main.bz).distance_to(Vector2(n["x"], n["z"])) < 7.0:
			return n
	return null


func hint() -> String:
	var n = _near_nasa()
	if n != null:
		var c := _nasa_count(n)
		return "[color=#f2b33d]E[/color] · Recoger nasa (%s)" % ("vacía todavía" if c == 0 else "%d dentro" % c)
	return ""


func try_interact() -> bool:
	var n = _near_nasa()
	if n == null:
		return false
	var count := _nasa_count(n)
	var mut: bool = main.is_night()
	var got: Array = []
	var lost := 0
	for i in count:
		var key: String = Data.NASA_POOL[randi() % Data.NASA_POOL.size()]
		var m: bool = mut and randf() < 0.7
		if main.add_catch(key, m):
			got.append(Data.fish_name(key, m))
		else:
			lost += 1
	n["node"].queue_free()
	nasas.erase(n)
	main.audio.sfx("catch" if not mut else "mutant", -3.0)
	if count == 0:
		main.ui.toast("La nasa estaba vacía. Hay que dejarla más tiempo.")
	elif got.is_empty():
		main.ui.toast("La nasa venía llena, pero no te cabe nada en la bodega.")
	else:
		main.ui.toast("Nasa: " + ", ".join(got) + (" (%d no cabían)" % lost if lost > 0 else ""))
	return true


# ---------- Red ----------
func toggle_net() -> void:
	if not net_owned:
		main.ui.toast("No tienes red. Se vende en el puerto.")
		return
	net_out = not net_out
	net_dist = 0.0
	main.audio.sfx("splash", -4.0, 0.6)
	main.ui.toast("Red echada: el barco irá más lento." if net_out else "Red recogida.")


func speed_mult() -> float:
	return 0.65 if net_out else 1.0


func _process(dt: float) -> void:
	if main == null:
		return
	var tt: float = main.t
	for n in nasas:
		n["node"].position.y = main.wave(n["x"], n["z"], tt) - 0.1
		n["node"].rotation.z = sin(tt * 1.3 + n["x"]) * 0.12
	# boyas de la red detrás del barco
	for i in net_floats.size():
		var f: MeshInstance3D = net_floats[i]
		f.visible = net_out
		if net_out:
			var d := 6.0 + i * 1.6
			var side := (i - 3) * 0.9
			var x: float = main.bx + sin(main.ba) * d + cos(main.ba) * side
			var z: float = main.bz + cos(main.ba) * d - sin(main.ba) * side
			f.position = Vector3(x, main.wave(x, z, tt), z)
	if net_out and main.mode == "sail":
		net_dist += abs(main.bv) * dt
		if net_dist >= NET_DISTANCE:
			net_dist = 0.0
			var key: String = Data.NET_POOL[randi() % Data.NET_POOL.size()]
			var m: bool = main.is_night() and randf() < 0.7
			if main.add_catch(key, m):
				main.ui.toast("La red ha sacado: " + Data.fish_name(key, m))
				main.audio.sfx("catch", -8.0, 1.2)
			else:
				main.ui.toast("La red trae peces, pero la bodega está llena.")


# ---------- Guardar ----------
func to_dict() -> Dictionary:
	var ns: Array = []
	for n in nasas:
		ns.append({"x": n["x"], "z": n["z"], "placed": n["placed"]})
	return {"nasas_owned": nasas_owned, "nasas": ns, "net_owned": net_owned}


func from_dict(d: Dictionary) -> void:
	nasas_owned = int(d.get("nasas_owned", 0))
	net_owned = bool(d.get("net_owned", false))
	for n in d.get("nasas", []):
		var x := float(n["x"])
		var z := float(n["z"])
		nasas.append({"x": x, "z": z, "placed": float(n["placed"]), "node": _make_buoy(x, z)})
