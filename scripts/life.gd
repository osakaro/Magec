extends Node
## Vida en el mar: gaviotas, delfines y barcas de otros pescadores de Güímar.
## De noche no sale nadie: las barcas vuelven al puerto.

var main

var gulls: Array = []
var dolphins: Array = []
var pod_timer := 25.0
var pod_active := false
var boats: Array = []
var gull_call := 6.0

const ROUTES := [
	[Vector2(-30, -30), Vector2(-90, 10), Vector2(-60, 60), Vector2(10, 30), Vector2(20, -25)],
	[Vector2(40, -30), Vector2(110, 0), Vector2(120, 70), Vector2(50, 60), Vector2(30, -10)],
]
const PARKING := [Vector2(-7, -60), Vector2(7, -66)]


func _ready() -> void:
	_build_gulls()
	_build_dolphins()
	_build_boats()


func _mat(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.6
	return m


func _build_gulls() -> void:
	var white := _mat(Color("f4f2ec"))
	var grey := _mat(Color("8d949a"))
	var centers := [Vector2(0, -62), Vector2(-40, -48), Vector2(30, -50), Vector2(20, 10), Vector2(-60, 0)]
	for i in 8:
		var g := Node3D.new()
		main.add_child(g)
		var body := CapsuleMesh.new()
		body.radius = 0.16
		body.height = 0.8
		var b := MeshInstance3D.new()
		b.mesh = body
		b.material_override = white
		b.rotation_degrees.x = 90
		g.add_child(b)
		var wings: Array = []
		for side in [-1, 1]:
			var pivot := Node3D.new()
			g.add_child(pivot)
			var w := BoxMesh.new()
			w.size = Vector3(0.9, 0.03, 0.3)
			var wm := MeshInstance3D.new()
			wm.mesh = w
			wm.material_override = grey
			wm.position.x = 0.45 * side
			pivot.add_child(wm)
			wings.append({"p": pivot, "s": side})
		var c: Vector2 = centers[i % centers.size()]
		gulls.append({"n": g, "w": wings, "c": c, "r": randf_range(6, 14), "h": randf_range(8, 14), "a": randf() * TAU, "sp": randf_range(0.35, 0.6) * (1 if i % 2 else -1)})


func _build_dolphins() -> void:
	var grey := _mat(Color("5d6f7a"))
	for i in 3:
		var g := Node3D.new()
		g.visible = false
		main.add_child(g)
		var body := CapsuleMesh.new()
		body.radius = 0.35
		body.height = 2.2
		var b := MeshInstance3D.new()
		b.mesh = body
		b.material_override = grey
		b.rotation_degrees.x = 90
		g.add_child(b)
		var fin := PrismMesh.new()
		fin.size = Vector3(0.1, 0.5, 0.5)
		var f := MeshInstance3D.new()
		f.mesh = fin
		f.material_override = grey
		f.position = Vector3(0, 0.45, 0.1)
		f.rotation_degrees.y = 90
		g.add_child(f)
		var tail := BoxMesh.new()
		tail.size = Vector3(0.8, 0.06, 0.3)
		var tl := MeshInstance3D.new()
		tl.mesh = tail
		tl.material_override = grey
		tl.position = Vector3(0, 0, 1.15)
		g.add_child(tl)
		dolphins.append({"n": g, "t": -1.0, "from": Vector3.ZERO, "dir": Vector3.ZERO, "delay": 0.0})


func _build_boats() -> void:
	var colors := [[Color("f1e6c8"), Color("2e7d4f"), Color("e0b23a")], [Color("eef0ee"), Color("b8322a"), Color("1d5aa6")]]
	for i in 2:
		var b: Dictionary = main.make_boat(colors[i][0], colors[i][1], colors[i][2])
		var start: Vector2 = ROUTES[i][0]
		boats.append({"node": b["node"], "light": b["light"], "lamp": b["lamp_mat"], "pos": start, "wp": 1, "route": i, "a": 0.0})


func _process(dt: float) -> void:
	if main == null:
		return
	var tt: float = main.t
	var day: float = main.daylight()
	var quiet: bool = main.mode == "cinematic"
	# ---- gaviotas: de día dan vueltas sobre el puerto y los cardúmenes
	gull_call -= dt
	for g in gulls:
		var n: Node3D = g["n"]
		n.visible = day > 0.35 and not quiet
		if not n.visible:
			continue
		g["a"] += g["sp"] * dt
		var p: Vector2 = g["c"] + Vector2(cos(g["a"]), sin(g["a"])) * g["r"]
		n.position = Vector3(p.x, g["h"] + sin(tt + g["r"]) * 0.6, p.y)
		var tangent: Vector3 = Vector3(-sin(g["a"]), 0, cos(g["a"])) * signf(g["sp"])
		n.look_at(n.position + tangent, Vector3.UP)
		var flap := sin(tt * 9.0 + g["r"]) * 0.6
		for w in g["w"]:
			w["p"].rotation.z = flap * w["s"]
	if gull_call <= 0.0:
		gull_call = randf_range(5.0, 12.0)
		if day > 0.5 and not quiet and Vector2(main.bx, main.bz).distance_to(Vector2(0, -55)) < 70.0:
			main.audio.sfx("gull", -14.0, randf_range(0.9, 1.15))

	# ---- delfines: de día, en aguas abiertas, saltan junto al barco
	pod_timer -= dt
	if not pod_active and pod_timer <= 0.0:
		pod_timer = randf_range(30.0, 60.0)
		if day > 0.5 and main.bz > -20.0 and main.mode == "sail" and main.weather.current != "picada":
			_spawn_pod()
	if pod_active:
		var any := false
		for d in dolphins:
			if d["t"] < 0.0:
				continue
			any = true
			d["t"] += dt
			var k: float = (d["t"] - d["delay"]) / 1.3
			var n: Node3D = d["n"]
			if k < 0.0:
				n.visible = false
				continue
			if k > 1.0:
				n.visible = false
				if d["t"] - d["delay"] > 1.3 + 0.8:
					d["t"] = -1.0
				continue
			n.visible = true
			var pos: Vector3 = d["from"] + d["dir"] * k * 9.0
			pos.y = main.wave(pos.x, pos.z, tt) + sin(PI * k) * 2.6 - 0.4
			n.position = pos
			n.look_at(pos + d["dir"] + Vector3(0, cos(PI * k) * 1.4, 0), Vector3.UP)
			if k > 0.0 and k < 0.05:
				main.audio.sfx("splash", -14.0, 1.3)
		pod_active = any

	# ---- barcas de otros pescadores
	for b in boats:
		var target: Vector2
		var night: bool = main.is_night()
		if night:
			target = PARKING[b["route"]]
		else:
			var route: Array = ROUTES[b["route"]]
			target = route[b["wp"]]
			if b["pos"].distance_to(target) < 4.0:
				b["wp"] = (b["wp"] + 1) % route.size()
		var to: Vector2 = target - b["pos"]
		var speed := 4.5 if to.length() > 3.0 else 0.0
		if speed > 0.0:
			var want := atan2(-to.x, -to.y)
			b["a"] = lerp_angle(b["a"], want, dt * 0.8)
			b["pos"] += Vector2(-sin(b["a"]), -cos(b["a"])) * speed * dt
		var y: float = main.wave(b["pos"].x, b["pos"].y, tt)
		var n: Node3D = b["node"]
		n.position = Vector3(b["pos"].x, y + 0.1, b["pos"].y)
		n.rotation = Vector3(sin(tt * 1.3 + b["route"]) * 0.05, b["a"], cos(tt * 1.1) * 0.05)
		b["light"].light_energy = 1.4 if (day < 0.5) else 0.0
		b["lamp"].emission_energy_multiplier = 3.0 if day < 0.5 else 0.0


func _spawn_pod() -> void:
	pod_active = true
	main.audio.sfx("dolphin", -8.0)
	var fwd := Vector3(-sin(main.ba), 0, -cos(main.ba))
	var right := Vector3(cos(main.ba), 0, -sin(main.ba))
	var i := 0
	for d in dolphins:
		d["t"] = 0.0
		d["delay"] = i * 0.45 + randf() * 0.2
		d["from"] = Vector3(main.bx, 0, main.bz) + right * (7.0 + i * 1.5) + fwd * (6.0 - i * 3.0)
		d["dir"] = fwd
		i += 1
