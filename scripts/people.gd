extends RefCounted
## Personajes de MAGEC: figuras articuladas hechas por código (cabeza, torso,
## brazos y piernas), con ropa, pelo, barba y sombrero propios. Respiran, miran
## al barco cuando se acerca y gesticulan cuando hablan.

const Props = preload("res://scripts/props.gd")

# Aspecto de cada personaje
const LOOKS := {
	"Acorán": {"skin": "c49270", "shirt": "2d5d8a", "pants": "2f3540", "hair": "2a1d14", "hat": "cap", "hat_c": "2b2b2b"},
	"Chaxiraxi": {"skin": "a97a5c", "shirt": "2b2a33", "pants": "2b2a33", "hair": "d8d4cc", "hat": "kerchief", "hat_c": "1e1c24", "skirt": true, "shawl": "6a3a3a", "lantern": true, "old": true},
	"Pancho": {"skin": "c49270", "shirt": "6a6a5e", "pants": "3a3a40", "hair": "d8d4cc", "hat": "cap", "hat_c": "d9cfb4", "beard": "dcd6c8", "old": true, "sit": true, "pipe": true},
	"Nieves": {"skin": "b98a6a", "shirt": "b8322a", "pants": "3a2a2a", "hair": "2a1d14", "hat": "kerchief", "hat_c": "2e6fa6", "skirt": true, "apron": "f0ece4"},
	"Don Baltasar": {"skin": "d0a184", "shirt": "141418", "pants": "141418", "hair": "1a1a1a", "hat": "top", "hat_c": "0e0e10", "coat": "141418", "tie": "8a1c1c", "cane": true, "moustache": "1a1a1a"},
	"Yaiza": {"skin": "c49270", "shirt": "33475b", "pants": "2a2f3a", "hair": "4a2e1c", "hat": "cap", "hat_c": "1d2a38", "coat": "33475b", "long_hair": true},
	"Isidro": {"skin": "a97a5c", "shirt": "e8e0c8", "pants": "5a4a3a", "hair": "d8d4cc", "hat": "straw", "hat_c": "d9c08a", "beard": "dcd6c8", "old": true, "cane": true},
	"Marcial": {"skin": "b98a6a", "shirt": "3a5a7a", "pants": "2f3540", "hair": "6a6a6a", "hat": "cap", "hat_c": "1d2a38", "beard": "7a7a7a", "old": true},
	"Saro": {"skin": "a87850", "shirt": "c9a26a", "pants": "4a3a2a", "hair": "1a1a1a", "hat": "straw", "hat_c": "d9c08a"},
	"Elena": {"skin": "d0a184", "shirt": "d9662a", "pants": "2f3540", "hair": "4a2e1c", "hat": "helmet", "hat_c": "f2c230", "coat": "d9662a", "long_hair": true},
	"Bentor": {"skin": "b98a6a", "shirt": "1d2a38", "pants": "1d2a38", "hair": "e8e4dc", "hat": "cap", "hat_c": "1d2a38", "beard": "e8e4dc", "old": true, "coat": "1d2a38"},
	"Aridane": {"skin": "c4a080", "shirt": "6a6a50", "pants": "4a4a3a", "hair": "eeeae2", "hat": "none", "hat_c": "000000", "beard": "eeeae2", "long_beard": true, "old": true, "lantern": true, "long_hair": true},
	"Tomasín": {"skin": "c49270", "shirt": "b8322a", "pants": "2f3540", "hair": "2a1d14", "hat": "cap", "hat_c": "b8322a"},
}


static func m(hexs: String, rough := 0.85) -> StandardMaterial3D:
	var mt := StandardMaterial3D.new()
	mt.albedo_color = Color(hexs)
	mt.roughness = rough
	return mt


static func _cap(r: float, h: float) -> CapsuleMesh:
	var c := CapsuleMesh.new()
	c.radius = r
	c.height = h
	c.radial_segments = 10
	c.rings = 4
	return c


static func _sph(r: float, sy := 1.0) -> SphereMesh:
	var s := SphereMesh.new()
	s.radius = r
	s.height = r * 2.0 * sy
	s.radial_segments = 12
	s.rings = 6
	return s


static func make(parent: Node, who: String, pos: Vector3, facing := 0.0, main = null) -> Node3D:
	var lk: Dictionary = LOOKS.get(who, LOOKS["Acorán"])
	var p := Person.new()
	p.who = who
	p.main = main
	p.position = pos
	p.rotation.y = facing
	parent.add_child(p)
	var skin := m(lk["skin"], 0.7)
	var shirt := m(lk["shirt"])
	var pants := m(lk["pants"])
	var hair := m(lk["hair"], 0.9)
	var sit: bool = lk.get("sit", false)
	var old: bool = lk.get("old", false)
	var hip_y := 0.5 if sit else 0.92
	# piernas (o falda)
	if lk.get("skirt", false):
		var sk := Props.cyl(0.17, 0.3, 0.8, 12)
		Props.add_mesh(p, sk, pants, Vector3(0, hip_y - 0.4, 0))
	else:
		for sx in [-0.1, 0.1]:
			var leg := Node3D.new()
			leg.position = Vector3(sx, hip_y, 0)
			p.add_child(leg)
			var lm := Props.add_mesh(leg, _cap(0.075, 0.9), pants, Vector3(0, -0.45, 0))
			if sit:
				leg.rotation.x = PI / 2
			var shoe := Props.add_mesh(leg, Props.box(Vector3(0.11, 0.07, 0.24)), m("2a2420"), Vector3(0, -0.88, -0.05))
	# torso
	var body := Node3D.new()
	body.position = Vector3(0, hip_y, 0)
	p.add_child(body)
	p.body = body
	var torso := Props.add_mesh(body, _cap(0.19, 0.7), shirt, Vector3(0, 0.32, 0), Vector3.ZERO, Vector3(1.0, 1.0, 0.72))
	if old:
		body.rotation.x = 0.12
	if lk.has("coat"):
		Props.add_mesh(body, Props.box(Vector3(0.42, 0.75, 0.3)), m(lk["coat"]), Vector3(0, 0.2, 0))
	if lk.has("apron"):
		Props.add_mesh(body, Props.box(Vector3(0.32, 0.6, 0.02)), m(lk["apron"]), Vector3(0, 0.05, -0.15))
	if lk.has("shawl"):
		Props.add_mesh(body, _cap(0.22, 0.5), m(lk["shawl"]), Vector3(0, 0.52, 0), Vector3(0, 0, PI / 2), Vector3(1.05, 1.0, 0.75))
	if lk.has("tie"):
		Props.add_mesh(body, Props.box(Vector3(0.05, 0.3, 0.02)), m(lk["tie"]), Vector3(0, 0.38, -0.15))
	# brazos: hombro -> codo, con mano
	for side in [-1.0, 1.0]:
		var sh := Node3D.new()
		sh.position = Vector3(0.24 * side, 0.6, 0)
		body.add_child(sh)
		Props.add_mesh(sh, _cap(0.06, 0.36), m(lk.get("coat", lk["shirt"])), Vector3(0, -0.16, 0))
		var el := Node3D.new()
		el.position = Vector3(0, -0.32, 0)
		sh.add_child(el)
		Props.add_mesh(el, _cap(0.055, 0.32), m(lk.get("coat", lk["shirt"])), Vector3(0, -0.14, 0))
		Props.add_mesh(el, _sph(0.05), skin, Vector3(0, -0.32, 0))
		sh.rotation.z = 0.08 * side
		if side > 0:
			p.arm_r = sh
		else:
			p.arm_l = sh
	# objetos en las manos
	if lk.get("cane", false):
		Props.add_mesh(p.arm_r.get_child(1), Props.cyl(0.02, 0.02, 0.95, 6), m("3a2a1c"), Vector3(0, -0.6, -0.05))
	if lk.get("lantern", false):
		var ln := Props.place(p.arm_l.get_child(1), "wooden_lantern_01", Vector3(0, -0.6, 0), 0.9)
		var lt := OmniLight3D.new()
		lt.light_color = Color("ffb45a")
		lt.light_energy = 1.4
		lt.omni_range = 9
		lt.position = Vector3(0, -0.45, 0)
		p.arm_l.get_child(1).add_child(lt)
		p.arm_l.rotation.x = -0.5
	# cabeza
	var head := Node3D.new()
	head.position = Vector3(0, 0.82, 0)
	body.add_child(head)
	p.head = head
	Props.add_mesh(head, _cap(0.05, 0.12), skin, Vector3(0, -0.08, 0))   # cuello
	Props.add_mesh(head, _sph(0.12, 1.1), skin, Vector3(0, 0.06, 0))
	Props.add_mesh(head, _sph(0.025), skin, Vector3(0, 0.05, -0.12))   # nariz
	for ex in [-0.045, 0.045]:
		Props.add_mesh(head, _sph(0.014), m("1a1410", 0.3), Vector3(ex, 0.09, -0.105))
	# pelo
	Props.add_mesh(head, _sph(0.125, 0.75), hair, Vector3(0, 0.12, 0.015))
	if lk.get("long_hair", false):
		Props.add_mesh(head, Props.box(Vector3(0.22, 0.26, 0.08)), hair, Vector3(0, -0.02, 0.09))
	if lk.has("beard"):
		var bh: float = 0.22 if lk.get("long_beard", false) else 0.1
		Props.add_mesh(head, _sph(0.1, 0.9 + bh * 3.0), m(lk["beard"], 0.95), Vector3(0, -0.04 - bh * 0.5, -0.05), Vector3.ZERO, Vector3(1.0, 1.0, 0.8))
	if lk.has("moustache"):
		Props.add_mesh(head, Props.box(Vector3(0.09, 0.02, 0.02)), m(lk["moustache"]), Vector3(0, 0.0, -0.115))
	if lk.get("pipe", false):
		Props.add_mesh(head, Props.cyl(0.012, 0.012, 0.12, 5), m("4a2e1c"), Vector3(0.03, -0.01, -0.16), Vector3(PI / 2, 0, 0))
	# sombrero
	var hc := m(lk["hat_c"])
	match lk["hat"]:
		"cap":
			Props.add_mesh(head, _sph(0.13, 0.55), hc, Vector3(0, 0.16, 0))
			Props.add_mesh(head, Props.box(Vector3(0.17, 0.015, 0.1)), hc, Vector3(0, 0.15, -0.12))
		"straw":
			Props.add_mesh(head, Props.cyl(0.3, 0.3, 0.02, 16), hc, Vector3(0, 0.16, 0))
			Props.add_mesh(head, Props.cyl(0.11, 0.13, 0.12, 12), hc, Vector3(0, 0.22, 0))
		"top":
			Props.add_mesh(head, Props.cyl(0.2, 0.2, 0.015, 16), hc, Vector3(0, 0.16, 0))
			Props.add_mesh(head, Props.cyl(0.11, 0.11, 0.24, 12), hc, Vector3(0, 0.28, 0))
		"kerchief":
			Props.add_mesh(head, _sph(0.132, 0.85), hc, Vector3(0, 0.11, 0.01))
		"helmet":
			Props.add_mesh(head, _sph(0.14, 0.7), hc, Vector3(0, 0.15, 0))
	return p


## Animación sencilla: respira, mira al barco y gesticula al hablar.
class Person extends Node3D:
	var who := ""
	var main
	var body: Node3D
	var head: Node3D
	var arm_r: Node3D
	var arm_l: Node3D
	var t := randf() * 10.0

	func _process(dt: float) -> void:
		t += dt
		if body:
			body.scale.y = 1.0 + sin(t * 1.6) * 0.012
		var talking := false
		if main and main.ui and main.ui.dlg_panel and main.ui.dlg_panel.visible:
			talking = main.ui.dlg_name.text == who
		if head:
			var yaw := sin(t * 0.4) * 0.25
			if main and is_inside_tree():
				var to := Vector3(main.bx, global_position.y, main.bz) - global_position
				if to.length() < 30.0 and to.length() > 0.5:
					var local := global_basis.inverse() * to
					yaw = clamp(atan2(-local.x, -local.z), -1.1, 1.1)
			head.rotation.y = lerp_angle(head.rotation.y, yaw, dt * 3.0)
			head.rotation.x = sin(t * 2.2) * 0.06 if talking else 0.0
		if arm_r:
			var target := -0.9 + sin(t * 3.0) * 0.35 if talking else sin(t * 1.1) * 0.05
			arm_r.rotation.x = lerp(arm_r.rotation.x, target, dt * 4.0)
