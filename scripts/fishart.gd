extends RefCounted
## Ilustraciones de los peces de MAGEC, dibujadas por código.
## Cada especie tiene su forma, colores y dibujo reales (simplificados),
## y cada mutante su deformidad propia.

# h: altura del cuerpo respecto a la longitud; hump: frente alta; tail: fork/round/lunate
# pattern: none, vbars, hstripes, spots, scales, line, band, blotch
const STYLE := {
	"vieja": {"top": "b4362a", "belly": "e7a443", "h": 0.42, "pattern": "scales", "pc": "8c2a20", "fin": "d0603a", "tail": "round", "eye": 1.0},
	"sargo": {"top": "9aa3a3", "belly": "eceeea", "h": 0.46, "pattern": "vbars", "pc": "2a2c2e", "fin": "6f7676", "tail": "fork", "eye": 1.1, "tailspot": true},
	"salema": {"top": "8d9a96", "belly": "e6e4d6", "h": 0.38, "pattern": "hstripes", "pc": "d9b440", "fin": "c9a640", "tail": "fork", "eye": 1.1},
	"chicharro": {"top": "3f6f7c", "belly": "dfe6e6", "h": 0.3, "pattern": "line", "pc": "26343a", "fin": "8aa0a6", "tail": "fork", "eye": 1.3},
	"sardina": {"top": "2f5f86", "belly": "e8eef0", "h": 0.26, "pattern": "spots", "pc": "1e3346", "fin": "9fb2c0", "tail": "fork", "eye": 1.2},
	"boga": {"top": "6f8a6a", "belly": "e2e6da", "h": 0.27, "pattern": "line", "pc": "c9b65a", "fin": "a0ae96", "tail": "fork", "eye": 1.4},
	"medregal": {"top": "6f7e78", "belly": "dcdcd0", "h": 0.27, "pattern": "band", "pc": "e3c33c", "fin": "c9b04a", "tail": "lunate", "eye": 0.9},
	"sama": {"top": "c8604a", "belly": "efc0a8", "h": 0.42, "hump": 0.25, "pattern": "spots", "pc": "9a3e30", "fin": "d97a5c", "tail": "fork", "eye": 1.0},
	"abade": {"top": "6c6450", "belly": "b8ae8e", "h": 0.38, "pattern": "blotch", "pc": "c9c2a8", "fin": "5a5240", "tail": "round", "eye": 0.9, "bigmouth": true},
	"cherne": {"top": "4c4540", "belly": "8d857a", "h": 0.4, "pattern": "blotch", "pc": "77706a", "fin": "3c3632", "tail": "round", "eye": 0.9, "bigmouth": true},
	"mero": {"top": "6b4c33", "belly": "b39272", "h": 0.42, "pattern": "blotch", "pc": "d8c2a0", "fin": "5a3e2a", "tail": "round", "eye": 0.8, "bigmouth": true},
	"alfonsino": {"top": "c8231c", "belly": "f07a5c", "h": 0.42, "pattern": "none", "pc": "000000", "fin": "e04a34", "tail": "fork", "eye": 2.0},
	"pargo": {"top": "d27c62", "belly": "f3c9b4", "h": 0.44, "hump": 0.3, "pattern": "spots", "pc": "6fa7d8", "fin": "e0957a", "tail": "fork", "eye": 1.0},
	"bocinegro": {"top": "c9705c", "belly": "f0c2ae", "h": 0.43, "hump": 0.2, "pattern": "vbars", "pc": "a95646", "fin": "d98a74", "tail": "fork", "eye": 1.0, "darkmouth": true},
	"dorada": {"top": "8e9a9e", "belly": "eef0ec", "h": 0.44, "pattern": "line", "pc": "556066", "fin": "7d878a", "tail": "fork", "eye": 1.0, "brow": true},
	"morena": {"kind": "eel", "top": "5d4a22", "belly": "a48a4a", "pattern": "spots", "pc": "d9c27a"},
	"pulpo": {"kind": "octopus", "top": "a6584d", "belly": "d9938a"},
	"calamar": {"kind": "squid", "top": "d9a3a0", "belly": "f3d8d2"},
}

const MUT_TINT := Color("4a5f3a")


static func _c(hexs: String, mut: bool, k := 0.4) -> Color:
	var c := Color(hexs)
	return c.lerp(MUT_TINT, k) if mut else c


static func draw(ci: CanvasItem, rect: Rect2, key: String, mut: bool, vertical := false, silhouette := false) -> void:
	var st: Dictionary = STYLE.get(key, STYLE["vieja"])
	var o := rect.position
	var w := rect.size.x
	var h := rect.size.y
	if vertical:
		ci.draw_set_transform(o + Vector2(w, 0), PI / 2, Vector2.ONE)
		var tmp := w
		w = h
		h = tmp
		o = Vector2.ZERO
	var kind: String = st.get("kind", "fish")
	match kind:
		"eel":
			_eel(ci, o, w, h, st, key, mut, silhouette)
		"octopus":
			_octopus(ci, o, w, h, st, mut, silhouette)
		"squid":
			_squid(ci, o, w, h, st, mut, silhouette)
		_:
			_fish(ci, o, w, h, st, key, mut, silhouette)
	ci.draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)


# ---------------------------------------------------------------------
static func _fish(ci: CanvasItem, o: Vector2, w: float, h: float, st: Dictionary, key: String, mut: bool, sil: bool) -> void:
	var L := w * 0.74
	var x0 := o.x + w * 0.04
	var cy := o.y + h * 0.52
	var H: float = min(L * float(st["h"]), h * 0.8)
	if mut and key == "abade":
		H *= 1.25
	var hump: float = st.get("hump", 0.0)
	var top := _c(st["top"], mut)
	var belly := _c(st["belly"], mut)
	var finc := _c(st.get("fin", st["top"]), mut)
	if sil:
		top = Color(0.18, 0.15, 0.13, 0.55)
		belly = top
		finc = top
	# contorno del cuerpo (cabeza a la izquierda)
	var upper := PackedVector2Array()
	var lower := PackedVector2Array()
	var n := 24
	for i in n + 1:
		var u := float(i) / n
		var prof: float = pow(sin(PI * clamp(u * 0.92 + 0.04, 0.0, 1.0)), 0.75)
		var taper: float = 1.0 - pow(max(u - 0.72, 0.0) / 0.28, 1.4) * 0.72
		var ht: float = H * 0.5 * prof * taper * (1.0 + hump * (1.0 - u) * 1.4 * float(u < 0.5))
		var hb: float = H * 0.5 * prof * taper * 0.92
		upper.append(Vector2(x0 + u * L, cy - ht))
		lower.append(Vector2(x0 + u * L, cy + hb))
	var tail_x := x0 + L
	var tail_h := H * 0.62
	# aleta caudal
	var tail := PackedVector2Array()
	match st.get("tail", "fork"):
		"round":
			tail = PackedVector2Array([Vector2(tail_x - 2, cy - H * 0.1), Vector2(tail_x + w * 0.12, cy - tail_h * 0.55), Vector2(tail_x + w * 0.17, cy), Vector2(tail_x + w * 0.12, cy + tail_h * 0.55), Vector2(tail_x - 2, cy + H * 0.1)])
		"lunate":
			tail = PackedVector2Array([Vector2(tail_x - 2, cy - H * 0.07), Vector2(tail_x + w * 0.2, cy - tail_h * 0.75), Vector2(tail_x + w * 0.1, cy), Vector2(tail_x + w * 0.2, cy + tail_h * 0.75), Vector2(tail_x - 2, cy + H * 0.07)])
		_:
			tail = PackedVector2Array([Vector2(tail_x - 2, cy - H * 0.09), Vector2(tail_x + w * 0.18, cy - tail_h * 0.62), Vector2(tail_x + w * 0.1, cy), Vector2(tail_x + w * 0.18, cy + tail_h * 0.62), Vector2(tail_x - 2, cy + H * 0.09)])
	ci.draw_colored_polygon(tail, finc)
	# aletas dorsal, anal y pectoral
	var dors := PackedVector2Array([upper[6], upper[9] + Vector2(0, -H * 0.38), upper[13] + Vector2(0, -H * 0.32), upper[17] + Vector2(0, -H * 0.12), upper[17]])
	ci.draw_colored_polygon(dors, finc.darkened(0.08))
	var anal := PackedVector2Array([lower[13], lower[15] + Vector2(0, H * 0.22), lower[18] + Vector2(0, H * 0.1), lower[18]])
	ci.draw_colored_polygon(anal, finc.darkened(0.08))
	# cuerpo: lomo y vientre
	var body := upper.duplicate()
	for i in range(lower.size() - 1, -1, -1):
		body.append(lower[i])
	ci.draw_colored_polygon(body, top)
	if not sil:
		var bel := PackedVector2Array()
		for i in lower.size():
			bel.append(lower[i].lerp(upper[i], 0.42))
		for i in range(lower.size() - 1, -1, -1):
			bel.append(lower[i])
		ci.draw_colored_polygon(bel, belly)
		_pattern(ci, st, upper, lower, cy, H, L, x0, mut)
		var pec := PackedVector2Array([Vector2(x0 + L * 0.26, cy + H * 0.05), Vector2(x0 + L * 0.42, cy + H * 0.02), Vector2(x0 + L * 0.36, cy + H * 0.2)])
		ci.draw_colored_polygon(pec, finc.lightened(0.1))
		# opérculo
		ci.draw_arc(Vector2(x0 + L * 0.2, cy), H * 0.3, -1.1, 1.1, 10, top.darkened(0.3), 1.2, true)
	var out := body.duplicate()
	out.append(body[0])
	ci.draw_polyline(out, (top if sil else top.darkened(0.5)), 1.4, true)
	if sil:
		return
	# boca
	var mouth := Vector2(x0 + 1, cy + H * 0.06)
	var mw := L * (0.1 if st.get("bigmouth", false) else 0.05)
	var mc := Color("1a1010") if st.get("darkmouth", false) else top.darkened(0.55)
	ci.draw_line(mouth, mouth + Vector2(mw, H * 0.04), mc, 2.0 if st.get("darkmouth", false) else 1.4, true)
	# ojo
	var ep := Vector2(x0 + L * 0.11, cy - H * 0.12)
	var er: float = max(2.0, H * 0.09 * float(st.get("eye", 1.0)))
	var faceless := mut and key == "cherne"
	if not faceless:
		ci.draw_circle(ep, er, Color("f6f0dc"))
		var blind := mut and key == "alfonsino"
		if not blind:
			ci.draw_circle(ep + Vector2(-er * 0.15, 0), er * 0.55, Color("b3140c") if mut else Color("121212"))
			ci.draw_circle(ep + Vector2(-er * 0.35, -er * 0.3), er * 0.18, Color(1, 1, 1, 0.8))
	if st.get("brow", false):
		ci.draw_line(ep + Vector2(-er * 1.4, -er * 1.4), ep + Vector2(er * 2.2, -er * 1.1), _c("d8b440", mut, 0.1), 3.0, true)
		ci.draw_circle(Vector2(x0 + L * 0.22, cy - H * 0.05), er * 0.7, Color(0.1, 0.1, 0.12, 0.6))
	if st.get("tailspot", false):
		ci.draw_circle(Vector2(tail_x - L * 0.04, cy), H * 0.1, Color(0.1, 0.1, 0.1, 0.9))
	if mut:
		_mutation(ci, key, upper, lower, cy, H, L, x0, ep, er, top)


static func _pattern(ci: CanvasItem, st: Dictionary, upper: PackedVector2Array, lower: PackedVector2Array, cy: float, H: float, L: float, x0: float, mut: bool) -> void:
	var pc := _c(st["pc"], mut, 0.3)
	match st["pattern"]:
		"vbars":
			for k in 5:
				var i := 5 + k * 3
				ci.draw_line(upper[i], upper[i].lerp(lower[i], 0.82), Color(pc, 0.75), H * 0.08, true)
		"hstripes":
			for k in 4:
				var f := 0.2 + k * 0.17
				var pts := PackedVector2Array()
				for i in range(3, upper.size() - 2):
					pts.append(upper[i].lerp(lower[i], f))
				ci.draw_polyline(pts, Color(pc, 0.85), max(1.2, H * 0.04), true)
		"line":
			var pts := PackedVector2Array()
			for i in range(3, upper.size() - 1):
				pts.append(upper[i].lerp(lower[i], 0.38 + 0.06 * sin(i * 0.4)))
			ci.draw_polyline(pts, Color(pc, 0.8), max(1.2, H * 0.035), true)
		"band":
			var pts := PackedVector2Array()
			for i in range(2, upper.size() - 1):
				pts.append(upper[i].lerp(lower[i], 0.45))
			ci.draw_polyline(pts, Color(pc, 0.95), max(2.0, H * 0.13), true)
		"spots":
			for i in range(4, upper.size() - 3, 2):
				for f in [0.3, 0.55]:
					if (i + int(f * 10)) % 3 == 0:
						continue
					ci.draw_circle(upper[i].lerp(lower[i], f), max(1.0, H * 0.045), Color(pc, 0.85))
		"blotch":
			for k in 7:
				var i := 5 + (k * 5) % 15
				var f := 0.25 + 0.5 * fmod(k * 0.37, 1.0)
				ci.draw_circle(upper[i].lerp(lower[i], f), H * 0.1, Color(pc, 0.45))
		"scales":
			for i in range(5, upper.size() - 4, 2):
				for f in [0.25, 0.45, 0.65]:
					var p := upper[i].lerp(lower[i], f)
					ci.draw_arc(p, H * 0.07, -PI * 0.5, PI * 0.5, 6, Color(pc, 0.7), 1.2, true)


static func _mutation(ci: CanvasItem, key: String, upper: PackedVector2Array, lower: PackedVector2Array, cy: float, H: float, L: float, x0: float, ep: Vector2, er: float, top: Color) -> void:
	var red := Color("b3140c")
	var bone := Color("efe6cf")
	match key:
		"vieja":
			for k in 9:
				var i := 6 + (k * 7) % 14
				var p := upper[i].lerp(lower[i], 0.2 + 0.6 * fmod(k * 0.41, 1.0))
				var r: float = max(2.0, H * 0.07)
				ci.draw_circle(p, r, bone)
				ci.draw_circle(p, r * 0.5, red)
		"sargo", "bocinegro":
			var m := Vector2(x0 + 2, cy + H * 0.06)
			if key == "sargo":
				for k in 5:
					ci.draw_rect(Rect2(m + Vector2(k * H * 0.06, -H * 0.03), Vector2(H * 0.05, H * 0.08)), bone)
			else:
				for k in 4:
					var a := m + Vector2(k * H * 0.05, -H * 0.05)
					ci.draw_line(a, a + Vector2(0, H * 0.12), Color("2a3a20"), 1.5)
		"medregal", "boga":
			var spine := PackedVector2Array()
			for i in range(4, upper.size() - 2):
				spine.append(upper[i].lerp(lower[i], 0.45))
			ci.draw_polyline(spine, bone, 2.0, true)
			for i in range(5, upper.size() - 3, 2):
				var p := upper[i].lerp(lower[i], 0.45)
				ci.draw_line(p + Vector2(-2, -H * 0.18), p + Vector2(2, H * 0.18), Color(bone, 0.8), 1.2)
		"chicharro":
			var hole := PackedVector2Array()
			for i in range(5, upper.size() - 5):
				hole.append(upper[i].lerp(lower[i], 0.3))
			for i in range(upper.size() - 6, 4, -1):
				hole.append(upper[i].lerp(lower[i], 0.7))
			ci.draw_colored_polygon(hole, Color("140e0c"))
		"mero":
			var m2 := Vector2(x0 + L * 0.2, cy + H * 0.26)
			ci.draw_line(m2, m2 + Vector2(L * 0.1, 0), red.darkened(0.3), 3.0)
			ci.draw_line(m2 + Vector2(0, -2), m2 + Vector2(L * 0.1, -2), bone, 1.0)
		"pargo":
			ci.draw_line(Vector2(x0, cy + H * 0.06), Vector2(x0 - L * 0.12, cy + H * 0.25), Color("101010"), 3.0, true)
		"dorada":
			for i in range(4, upper.size() - 3, 2):
				for f in [0.35, 0.6]:
					ci.draw_circle(upper[i].lerp(lower[i], f), H * 0.05, Color("e3b83c"))
		"sardina":
			for i in range(4, upper.size() - 3, 2):
				ci.draw_circle(upper[i].lerp(lower[i], 0.3), H * 0.06, Color("101010"))
		"sama":
			ci.draw_colored_polygon(PackedVector2Array([upper[8], upper[16], lower[16], lower[8]]), Color(1.0, 0.3, 0.1, 0.25))
		"salema":
			ci.draw_string(ThemeDB.fallback_font, Vector2(x0 - 6, cy - H * 0.6), "♪", HORIZONTAL_ALIGNMENT_LEFT, -1, int(max(10.0, H * 0.4)), Color("2a211b"))
		"abade", "cherne", "alfonsino":
			pass
	# todos los mutantes: púas sobre el lomo
	for i in range(7, 17, 2):
		var b := upper[i]
		ci.draw_colored_polygon(PackedVector2Array([b + Vector2(-2, 0), b + Vector2(0, -H * 0.22), b + Vector2(2, 0)]), top.darkened(0.5))


# ---------------------------------------------------------------------
static func _eel(ci: CanvasItem, o: Vector2, w: float, h: float, st: Dictionary, key: String, mut: bool, sil: bool) -> void:
	var top := _c(st["top"], mut)
	var belly := _c(st["belly"], mut)
	if sil:
		top = Color(0.18, 0.15, 0.13, 0.55)
		belly = top
	var cy := o.y + h * 0.5
	var pts_u := PackedVector2Array()
	var pts_l := PackedVector2Array()
	var n := 30
	var th: float = min(h * 0.28, w * 0.09)
	for i in n + 1:
		var u := float(i) / n
		var x := o.x + w * (0.04 + u * 0.92)
		var y := cy + sin(u * 6.0) * h * 0.14
		var t: float = th * (1.0 - u * 0.75) * (0.7 + 0.3 * sin(min(u * 8.0, PI * 0.5)))
		pts_u.append(Vector2(x, y - t))
		pts_l.append(Vector2(x, y + t))
	# aleta continua
	var fin := PackedVector2Array()
	for i in range(3, n + 1):
		fin.append(pts_u[i] + Vector2(0, -th * 0.45))
	for i in range(n, 2, -1):
		fin.append(pts_u[i])
	ci.draw_colored_polygon(fin, top.darkened(0.2))
	var body := pts_u.duplicate()
	for i in range(n, -1, -1):
		body.append(pts_l[i])
	ci.draw_colored_polygon(body, top)
	if sil:
		return
	for i in range(3, n - 2, 2):
		ci.draw_circle(pts_u[i].lerp(pts_l[i], 0.45), th * 0.18, Color(_c(st["pc"], mut, 0.2), 0.7))
	var out := body.duplicate()
	out.append(body[0])
	ci.draw_polyline(out, top.darkened(0.5), 1.4, true)
	# boca abierta con dientes
	var m := pts_u[0].lerp(pts_l[0], 0.55)
	ci.draw_colored_polygon(PackedVector2Array([m, m + Vector2(th * 1.1, -th * 0.25), m + Vector2(th * 1.1, th * 0.3)]), Color("2a0c0a"))
	for k in 3:
		ci.draw_line(m + Vector2(th * (0.3 + k * 0.25), -th * 0.15), m + Vector2(th * (0.3 + k * 0.25), th * 0.05), Color("efe6cf"), 1.2)
	var ep := pts_u[1].lerp(pts_l[1], 0.3) + Vector2(th * 0.6, 0)
	ci.draw_circle(ep, max(1.5, th * 0.2), Color("e8d36a") if not mut else Color("b3140c"))
	if mut:
		var m2 := m + Vector2(th * 0.4, th * 0.1)
		ci.draw_colored_polygon(PackedVector2Array([m2, m2 + Vector2(th * 0.7, -th * 0.15), m2 + Vector2(th * 0.7, th * 0.2)]), Color("4a0c0a"))


static func _octopus(ci: CanvasItem, o: Vector2, w: float, h: float, st: Dictionary, mut: bool, sil: bool) -> void:
	var col := _c(st["top"], mut)
	if sil:
		col = Color(0.18, 0.15, 0.13, 0.55)
	var hc := Vector2(o.x + w * 0.3, o.y + h * 0.42)
	var R: float = min(w * 0.18, h * 0.32)
	for k in 8:
		var pts := PackedVector2Array()
		var base_a := -0.9 + k * 0.26
		for i in 14:
			var u := float(i) / 13.0
			var a := base_a + sin(u * 4.0 + k) * 0.35
			pts.append(hc + Vector2(cos(a), sin(a) * 0.55) * (R * 0.6 + u * w * 0.62) + Vector2(0, u * h * 0.08))
		ci.draw_polyline(pts, col.darkened(0.08 * (k % 2)), max(2.0, R * (0.38 - 0.0)), true)
		if not sil:
			for i in range(3, 13, 3):
				ci.draw_circle(pts[i] + Vector2(0, R * 0.12), max(1.0, R * 0.07), Color("efe0d8") if not mut else Color("efe6cf"))
				if mut:
					ci.draw_circle(pts[i] + Vector2(0, R * 0.12), max(0.6, R * 0.035), Color("3a0806"))
	var head := PackedVector2Array()
	for i in 24:
		var a := TAU * i / 24.0
		head.append(hc + Vector2(cos(a) * R * 1.05, sin(a) * R * 0.8 - (R * 0.35 if sin(a) < 0 else 0.0)))
	ci.draw_colored_polygon(head, col)
	if sil:
		return
	ci.draw_circle(hc + Vector2(R * 0.55, R * 0.1), R * 0.17, Color("f2e6a0"))
	ci.draw_line(hc + Vector2(R * 0.42, R * 0.1), hc + Vector2(R * 0.68, R * 0.1), Color("101010"), 2.0)
	for i in 5:
		ci.draw_circle(hc + Vector2(-R * 0.4 + i * R * 0.2, -R * 0.45), R * 0.06, col.darkened(0.25))


static func _squid(ci: CanvasItem, o: Vector2, w: float, h: float, st: Dictionary, mut: bool, sil: bool) -> void:
	var col := _c(st["top"], mut)
	if sil:
		col = Color(0.18, 0.15, 0.13, 0.55)
	var cy := o.y + h * 0.5
	var x_tip := o.x + w * 0.95
	var x_head := o.x + w * 0.42
	var R: float = min(h * 0.26, w * 0.12)
	var mantle := PackedVector2Array([Vector2(x_head, cy - R), Vector2(x_tip - w * 0.12, cy - R * 0.7), Vector2(x_tip, cy), Vector2(x_tip - w * 0.12, cy + R * 0.7), Vector2(x_head, cy + R)])
	ci.draw_colored_polygon(PackedVector2Array([Vector2(x_tip - w * 0.2, cy), Vector2(x_tip - w * 0.06, cy - R * 1.5), Vector2(x_tip, cy), Vector2(x_tip - w * 0.06, cy + R * 1.5)]), col.darkened(0.1))
	for k in 8:
		var pts := PackedVector2Array()
		for i in 10:
			var u := float(i) / 9.0
			var long := 1.3 if k < 2 else 1.0
			pts.append(Vector2(x_head - u * w * 0.38 * long, cy + (k - 3.5) * R * 0.18 + sin(u * 5.0 + k) * R * 0.25 * u))
		ci.draw_polyline(pts, col.darkened(0.05), max(1.5, R * 0.16), true)
		if mut and not sil:
			for i in range(2, 10, 2):
				ci.draw_line(pts[i], pts[i] + Vector2(0, R * 0.12), Color("efe6cf"), 1.0)
	ci.draw_colored_polygon(mantle, col)
	if sil:
		return
	for i in 10:
		ci.draw_circle(Vector2(x_head + (i % 5 + 0.5) * w * 0.08, cy + (float(i / 5) - 0.5) * R * 0.8), R * 0.07, col.darkened(0.3))
	var ep := Vector2(x_head - R * 0.15, cy - R * 0.25)
	ci.draw_circle(ep, R * 0.3, Color("f2ecdc"))
	ci.draw_circle(ep, R * 0.17, Color("b3140c") if mut else Color("101010"))
