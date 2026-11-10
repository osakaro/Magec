extends CanvasLayer
## Interfaz de MAGEC con estilo de barca canaria: madera, latón y papel.
## El reloj es un arco de sol (Magec) y luna; el miedo es un ojo que se abre.

const Data = preload("res://scripts/data.gd")
const FishArt = preload("res://scripts/fishart.gd")

const F_TITLE = preload("res://fonts/AlegreyaSC-Bold.ttf")
const F_TITLE_R = preload("res://fonts/AlegreyaSC-Regular.ttf")
const F_UI = preload("res://fonts/BarlowSemiCondensed-Medium.ttf")
const F_UI_B = preload("res://fonts/BarlowSemiCondensed-SemiBold.ttf")
const F_HAND = preload("res://fonts/Caveat-Variable.ttf")

const WOOD_D := Color("1b120c")
const WOOD := Color("33221a")
const WOOD_L := Color("5b3d27")
const BRASS := Color("c9a14a")
const BRASS_D := Color("7a5a24")
const PAPER := Color("e9dec3")
const INK := Color("2a211b")
const FOAM := Color("f1e9d8")
const SALT := Color("b4a68b")
const SUN := Color("f2b33d")
const BLOOD := Color("c43b2f")
const SEA := Color("2f6f73")

const DAYS := ["Lunes", "Martes", "Miércoles", "Jueves", "Viernes", "Sábado", "Domingo"]

var main

var dial: SunDial
var money_lbl: Label
var debt_lbl: Label
var hull_lbl: Label
var shake_amt := 0.0
var root_ctl: Control
var place_lbl: Label
var note: PaperNote
var hint_box: PanelContainer
var hint_key: KeyCap
var hint_lbl: Label
var toast_box: PanelContainer
var toast_lbl: Label
var toast_time := 0.0
var vignette: ColorRect

var fish_panel: WoodPanel
var fish_title: Label
var fish_sub: Label
var catch_new: Label
var journal_panel: WoodPanel
var journal_book: JournalBook
var journal_count: Label
var fish_bar: FishBar
var catch_panel: WoodPanel
var catch_icon: FishIcon
var catch_name: Label
var catch_desc: Label
var catch_price: Label
var keep_btn: Button
var hold_panel: WoodPanel
var hold_grid: HoldGrid
var hold_stats: Label
var hold_info: Label
var drop_btn: Button
var port_panel: WoodPanel
var port_list: VBoxContainer
var dlg_panel: WoodPanel
var dlg_portrait: Portrait
var dlg_name: Label
var dlg_text: Label

var intro: Control
var tut_box: PanelContainer
var tut_key: KeyCap
var tut_lbl: Label
var choice_panel: WoodPanel
var choice_label: Label
var choice_box: VBoxContainer
var choice_cb: Callable
var ending_layer: ColorRect
var ending_title: Label
var ending_text: Label
var ending_stats: Label
var journal_pg: Label
var silbo_panel: WoodPanel
var silbo_bar: SilboBar
var silbo_msg: Label
var compass: Compass
var map_panel: WoodPanel
var map_chart: ChartMap
var hud_nodes: Array = []
var menu_layer: Control
var menu_buttons: VBoxContainer
var menu_confirm: HBoxContainer
var pause_panel: WoodPanel
var options_panel: WoodPanel
var opt := {"master": 0.8, "music": 0.8, "sfx": 0.9, "fullscreen": false, "quality": 2, "tutorial": true, "difficulty": 1}
const OPT_PATH := "user://opciones.cfg"
var cine_black: ColorRect
var cine_card: Label
var cine_sub: Label
var cine_title: Label


# =====================================================================
# Piezas dibujadas a mano
# =====================================================================

static func draw_fish(ci: CanvasItem, rect: Rect2, color: Color, mut: bool, vertical: bool) -> void:
	var w := rect.size.x
	var h := rect.size.y
	var o := rect.position
	if vertical:
		ci.draw_set_transform(o + Vector2(w, 0), PI / 2, Vector2.ONE)
		var tmp := w
		w = h
		h = tmp
		o = Vector2.ZERO
	var cx := o.x + w * 0.46
	var cy := o.y + h / 2.0
	var rx := w * 0.34
	var ry: float = min(h * 0.3, w * 0.2)
	var col := color
	if mut:
		col = color.lerp(Color("4a5f3a"), 0.45)
	ci.draw_colored_polygon(PackedVector2Array([Vector2(cx + rx * 0.85, cy), Vector2(o.x + w * 0.96, cy - ry * 1.1), Vector2(o.x + w * 0.96, cy + ry * 1.1)]), col.darkened(0.1))
	var pts := PackedVector2Array()
	for i in 28:
		var a := TAU * i / 28.0
		pts.append(Vector2(cx + cos(a) * rx, cy + sin(a) * ry))
	ci.draw_colored_polygon(pts, col)
	var belly := PackedVector2Array()
	for i in 16:
		var a := TAU * i / 16.0
		belly.append(Vector2(cx + cos(a) * rx * 0.8, cy + ry * 0.35 + sin(a) * ry * 0.35))
	ci.draw_colored_polygon(belly, Color(1, 1, 1, 0.16))
	var outline := pts.duplicate()
	outline.append(pts[0])
	ci.draw_polyline(outline, col.darkened(0.45), 1.5, true)
	ci.draw_colored_polygon(PackedVector2Array([Vector2(cx - rx * 0.3, cy - ry * 0.9), Vector2(cx + rx * 0.1, cy - ry * 1.45), Vector2(cx + rx * 0.4, cy - ry * 0.85)]), col.darkened(0.2))
	if mut:
		var dark := col.darkened(0.5)
		for i in 7:
			var px := cx - rx * 0.6 + i * rx * 0.2
			ci.draw_colored_polygon(PackedVector2Array([Vector2(px - 3, cy - ry * 0.9), Vector2(px, cy - ry * 1.6), Vector2(px + 3, cy - ry * 0.9)]), dark)
		for i in 6:
			var ex := cx - rx * 0.5 + float((i * 37) % 10) / 10.0 * rx * 1.1
			var ey := cy + (float((i * 53) % 10) / 10.0 - 0.5) * ry * 1.1
			var er: float = max(2.0, ry * 0.14)
			ci.draw_circle(Vector2(ex, ey), er, Color("f6e9c9"))
			ci.draw_circle(Vector2(ex, ey), er * 0.5, Color("b3140c"))
	var eye := Vector2(cx - rx * 0.62, cy - ry * 0.2)
	ci.draw_circle(eye, max(2.0, ry * 0.17), Color("f8f8f0"))
	ci.draw_circle(eye, max(1.0, ry * 0.09), Color("b3140c") if mut else Color("111111"))
	ci.draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)


static func wood_style(alpha := 0.96) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(WOOD, alpha)
	sb.border_color = WOOD_D
	sb.set_border_width_all(5)
	sb.set_corner_radius_all(4)
	sb.shadow_color = Color(0, 0, 0, 0.45)
	sb.shadow_size = 14
	sb.shadow_offset = Vector2(0, 5)
	sb.set_content_margin_all(22)
	return sb


## Panel de madera con vetas, filo de latón y remaches.
class WoodPanel extends PanelContainer:
	var seed_v := 0.0
	func _init() -> void:
		add_theme_stylebox_override("panel", load("res://scripts/ui.gd").wood_style())
		seed_v = randf() * 100.0
	func _draw() -> void:
		var r := Rect2(Vector2.ZERO, size)
		var y := 9.0
		var i := 0
		while y < size.y - 8.0:
			var a: float = 0.05 + 0.04 * sin(i * 1.7 + seed_v)
			var pts := PackedVector2Array()
			for k in 9:
				var x := 8.0 + (size.x - 16.0) * k / 8.0
				pts.append(Vector2(x, y + sin(k * 0.9 + i + seed_v) * 1.6))
			draw_polyline(pts, Color(0, 0, 0, a), 1.0, true)
			y += 7.0 + fmod(i * 3.7 + seed_v, 6.0)
			i += 1
		draw_rect(r.grow(-8), Color(BRASS, 0.55), false, 1.5)
		for c in [Vector2(14, 14), Vector2(size.x - 14, 14), Vector2(14, size.y - 14), Vector2(size.x - 14, size.y - 14)]:
			draw_circle(c, 3.2, BRASS_D)
			draw_circle(c - Vector2(0.8, 0.8), 1.6, BRASS)


## Placa de latón para títulos.
class Plaque extends Control:
	var text := ""
	var size_px := 20
	func _init(t := "", s := 20) -> void:
		text = t
		size_px = s
		custom_minimum_size = Vector2(0, s + 18)
	func _draw() -> void:
		var tw := F_TITLE.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size_px).x
		var w := tw + 44.0
		var h := size.y
		var pts := PackedVector2Array([Vector2(10, 0), Vector2(w - 10, 0), Vector2(w, h / 2), Vector2(w - 10, h), Vector2(10, h), Vector2(0, h / 2)])
		draw_colored_polygon(pts, BRASS_D)
		var inner := PackedVector2Array()
		for p in pts:
			inner.append(p.lerp(Vector2(w / 2, h / 2), 0.08))
		draw_colored_polygon(inner, BRASS)
		draw_string(F_TITLE, Vector2(22, h / 2 + size_px * 0.36), text, HORIZONTAL_ALIGNMENT_LEFT, -1, size_px, INK)


## Tecla dibujada.
class KeyCap extends Control:
	var key := ""
	func _init(k := "") -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		set_key(k)
	func set_key(k: String) -> void:
		key = k
		var w: float = max(30.0, F_UI_B.get_string_size(k, HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x + 16.0)
		custom_minimum_size = Vector2(w, 30)
		queue_redraw()
	func _draw() -> void:
		draw_rect(Rect2(0, 3, size.x, size.y - 3), BRASS_D)
		draw_rect(Rect2(0, 0, size.x, size.y - 4), Color("e7d3a0"))
		draw_rect(Rect2(0, 0, size.x, size.y - 4), BRASS_D, false, 1.0)
		var tw := F_UI_B.get_string_size(key, HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x
		draw_string(F_UI_B, Vector2((size.x - tw) / 2, 20), key, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, INK)


## Reloj de Magec: el sol (o la luna) recorre un arco; el ojo del miedo se abre dentro.
class SunDial extends Control:
	var game
	func _init() -> void:
		custom_minimum_size = Vector2(380, 178)
		mouse_filter = Control.MOUSE_FILTER_IGNORE
	func _draw() -> void:
		if game == null:
			return
		var c := Vector2(size.x / 2, 112)
		var R := 96.0
		var l: float = game.daylight()
		var h: float = game.hour()
		var night: bool = game.is_night()
		var sky := Color("0b1622").lerp(Color("6aa6c4"), l)
		var pts := PackedVector2Array([c])
		for i in 33:
			var a := PI + PI * i / 32.0
			pts.append(c + Vector2(cos(a), sin(a)) * R)
		draw_colored_polygon(pts, Color(sky, 0.88))
		draw_rect(Rect2(c.x - R, c.y - 6, R * 2, 6), Color(SEA.darkened(0.3 + (1.0 - l) * 0.5), 0.95))
		if l < 0.5:
			for i in 14:
				var a := PI + PI * (0.08 + 0.84 * fmod(i * 0.618, 1.0))
				var rr := R * (0.35 + 0.55 * fmod(i * 0.377, 1.0))
				draw_circle(c + Vector2(cos(a), sin(a)) * rr, 1.1, Color(1, 1, 1, (0.5 - l) * 1.6))
		draw_arc(c, R, PI, TAU, 48, BRASS_D, 9.0, true)
		draw_arc(c, R, PI, TAU, 48, BRASS, 4.0, true)
		for hh in range(6, 21, 2):
			var a := PI + PI * (hh - 6) / 14.0
			var d := Vector2(cos(a), sin(a))
			draw_line(c + d * (R - 9), c + d * (R + 9), INK, 2.0)
			if hh % 6 == 0:
				var s := str(hh)
				var tw := F_UI_B.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x
				var at := c + d * (R + 20) + Vector2(-tw / 2, 5)
				draw_string_outline(F_UI_B, at, s, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, 4, Color(0, 0, 0, 0.7))
				draw_string(F_UI_B, at, s, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, FOAM)
		if not night:
			var a: float = PI + PI * clamp((h - 6.0) / 14.0, 0.0, 1.0)
			var p := c + Vector2(cos(a), sin(a)) * (R - 26)
			for i in 12:
				var ra: float = TAU * i / 12.0 + game.t * 0.2
				var rl := 21.0 if i % 2 == 0 else 18.0
				draw_line(p + Vector2(cos(ra), sin(ra)) * 15, p + Vector2(cos(ra), sin(ra)) * rl, SUN, 2.0, true)
			draw_circle(p, 12, SUN)
			draw_circle(p, 8, Color("ffd77a"))
		else:
			var nh: float = h - 20.0 if h >= 20.0 else h + 4.0
			var a: float = PI + PI * clamp(nh / 10.0, 0.0, 1.0)
			var p := c + Vector2(cos(a), sin(a)) * (R - 26)
			draw_circle(p, 11, Color("e9e3cf"))
			draw_circle(p + Vector2(5, -3), 9.5, Color(sky, 1.0))
		# ojo del miedo
		var panic: float = game.panic
		var open: float = clamp(panic / 100.0, 0.06, 1.0)
		var e := c + Vector2(0, -30)
		var ew := 34.0
		var eh := 15.0 * open
		var eye := PackedVector2Array()
		for i in 21:
			var x := -ew + 2.0 * ew * i / 20.0
			eye.append(e + Vector2(x, -eh * (1.0 - pow(x / ew, 2))))
		for i in range(19, 0, -1):
			var x := -ew + 2.0 * ew * i / 20.0
			eye.append(e + Vector2(x, eh * (1.0 - pow(x / ew, 2))))
		var pulse := 0.0
		if panic > 60.0:
			pulse = 0.5 + 0.5 * sin(game.t * (4.0 + panic / 15.0))
		draw_colored_polygon(eye, Color("efe2c8").lerp(Color("f2c2a8"), panic / 100.0))
		var ir: float = min(eh, 11.0)
		if ir > 1.0:
			draw_circle(e, ir, BLOOD.lerp(Color("ff3b2a"), pulse))
			draw_circle(e, ir * 0.45, Color("120807"))
		var outline := eye.duplicate()
		outline.append(eye[0])
		draw_polyline(outline, INK, 2.0, true)
		if panic < 6.0:
			for i in 5:
				var x := -ew * 0.6 + ew * 0.3 * i
				draw_line(e + Vector2(x, 0), e + Vector2(x * 1.15, 6), INK, 1.5, true)
		# placa de la hora
		var pr := Rect2(c.x - 92, c.y + 4, 184, 58)
		draw_rect(pr.grow(3), WOOD_D)
		draw_rect(pr, WOOD)
		draw_rect(pr.grow(-4), Color(BRASS, 0.6), false, 1.2)
		var mins := int(fmod(game.game_time, 60.0))
		var tstr := "%02d:%02d" % [int(h), mins]
		var tw := F_TITLE.get_string_size(tstr, HORIZONTAL_ALIGNMENT_LEFT, -1, 30).x
		draw_string(F_TITLE, Vector2(c.x - tw / 2, pr.position.y + 31), tstr, HORIZONTAL_ALIGNMENT_LEFT, -1, 30, FOAM)
		var dstr: String = ("%s · Día %d" % [DAYS[(game.day - 1) % 7], game.day]).to_upper()
		var dw := F_UI.get_string_size(dstr, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x
		draw_string(F_UI, Vector2(c.x - dw / 2, pr.position.y + 50), dstr, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, SALT)


## Nota de papel clavada con una chincheta (el encargo actual).
class PaperNote extends Control:
	var title := "ENCARGO"
	var text := ""
	func _init() -> void:
		custom_minimum_size = Vector2(330, 120)
		size = custom_minimum_size
		rotation = deg_to_rad(-1.8)
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		visible = false
	func set_text(t: String) -> void:
		if t == text:
			return
		text = t
		visible = t != ""
		var lines := F_HAND.get_multiline_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, 290, 25).y
		custom_minimum_size.y = 62 + lines
		size = custom_minimum_size
		queue_redraw()
	func _draw() -> void:
		draw_rect(Rect2(Vector2(4, 5), size), Color(0, 0, 0, 0.35))
		var pts := PackedVector2Array([Vector2(0, 2), Vector2(size.x * 0.4, 0), Vector2(size.x, 3), Vector2(size.x - 2, size.y), Vector2(size.x * 0.6, size.y - 3), Vector2(1, size.y - 1)])
		draw_colored_polygon(pts, PAPER)
		for i in 4:
			draw_line(Vector2(18, 50 + i * 26), Vector2(size.x - 18, 50 + i * 26), Color(0.4, 0.5, 0.6, 0.12), 1.0)
		draw_circle(Vector2(size.x / 2, 8), 7, BLOOD.darkened(0.2))
		draw_circle(Vector2(size.x / 2 - 2, 6), 2.5, Color(1, 1, 1, 0.5))
		draw_string(F_TITLE, Vector2(20, 36), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color(INK, 0.7))
		draw_multiline_string(F_HAND, Vector2(20, 62), text, HORIZONTAL_ALIGNMENT_LEFT, 290, 25, -1, INK)


## Retrato redondo para los diálogos.
class Portrait extends Control:
	var who := ""
	func _init() -> void:
		custom_minimum_size = Vector2(96, 96)
	func _draw() -> void:
		var c := size / 2
		draw_circle(c, 46, BRASS_D)
		draw_circle(c, 42, BRASS)
		var looks := {
			"Acorán": [Color("2a3440"), Color("1d4f7a"), Color("c49270")],
			"Chaxiraxi": [Color("3a2a22"), Color("1e1c24"), Color("a97a5c")],
			"Pancho": [Color("3a3a34"), Color("5c5a52"), Color("c49270")],
			"Nieves": [Color("3a2a2a"), Color("b8322a"), Color("b98a6a")],
			"Don Baltasar": [Color("1c1c22"), Color("15151a"), Color("d0a184")],
			"Yaiza": [Color("22303c"), Color("33475b"), Color("c49270")],
			"Guayota": [Color("2a0806"), Color("1a1412"), Color("1a1412")],
		}
		var lk: Array = looks.get(who, looks["Acorán"])
		draw_circle(c, 38, lk[0])
		if who == "Guayota":
			draw_colored_polygon(PackedVector2Array([c + Vector2(-26, 34), c + Vector2(-8, -24), c + Vector2(8, -24), c + Vector2(26, 34)]), lk[1])
			draw_circle(c + Vector2(-7, -4), 4, Color("fff07a"))
			draw_circle(c + Vector2(7, -4), 4, Color("fff07a"))
			draw_rect(Rect2(c.x - 10, c.y + 8, 20, 4), Color("ff6a1a"))
			return
		draw_colored_polygon(_semi(c + Vector2(0, 38), 26, 24), lk[1])
		draw_circle(c + Vector2(0, -4), 14, lk[2])
		if who == "Pancho":
			draw_colored_polygon(_semi(c + Vector2(0, 8), 13, -9), Color("dcd6c8"))
			draw_rect(Rect2(c.x - 15, c.y - 20, 30, 6), Color("d9cfb4"))
			return
		if who == "Nieves":
			draw_colored_polygon(_semi(c + Vector2(0, -8), 17, 14), Color("2e6fa6"))
			return
		if who == "Don Baltasar":
			draw_rect(Rect2(c.x - 16, c.y - 20, 32, 4), Color("0e0e10"))
			draw_rect(Rect2(c.x - 10, c.y - 32, 20, 13), Color("0e0e10"))
			draw_rect(Rect2(c.x - 2, c.y + 14, 4, 18), Color("8a1c1c"))
			return
		if who == "Yaiza":
			draw_rect(Rect2(c.x - 15, c.y - 20, 30, 7), Color("1d2a38"))
			draw_rect(Rect2(c.x - 15, c.y - 14, 34, 3), Color("1d2a38"))
			return
		if who == "Chaxiraxi":
			draw_colored_polygon(_semi(c + Vector2(0, -6), 17, 16), lk[1])
			draw_circle(c + Vector2(22, 16), 6, Color("ffb45a"))
		else:
			draw_rect(Rect2(c.x - 14, c.y - 20, 28, 8), Color("2b2b2b"))
			draw_rect(Rect2(c.x - 2, c.y - 14, 20, 3), Color("2b2b2b"))
	func _semi(center: Vector2, rx: float, ry: float) -> PackedVector2Array:
		var p := PackedVector2Array()
		for i in 17:
			var a := PI + PI * i / 16.0
			p.append(center + Vector2(cos(a) * rx, sin(a) * ry))
		return p


## Ficha de captura en papel, como un cuaderno de especies.
class FishIcon extends Control:
	var key := ""
	var mut := false
	func _process(_d: float) -> void:
		if is_visible_in_tree():
			queue_redraw()
	func _draw() -> void:
		if key == "":
			return
		var r := Rect2(Vector2.ZERO, size)
		draw_rect(r, PAPER)
		for i in 6:
			draw_line(Vector2(0, 20 + i * 22), Vector2(size.x, 20 + i * 22), Color(0.4, 0.5, 0.6, 0.1), 1.0)
		if mut:
			draw_rect(r.grow(-6), Color(BLOOD, 0.5), false, 2.0)
		FishArt.draw(self, Rect2(size.x * 0.18, 8, size.x * 0.64, size.y - 22), key, mut, false, false, Time.get_ticks_msec() / 1000.0)
		draw_string(F_HAND, Vector2(14, size.y - 12), "Ejemplar · Güímar", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color(INK, 0.55))


## Minijuego: el corcho se mueve por el sedal; hay que pararlo sobre el agua dorada.
class FishBar extends Control:
	var game
	func _init() -> void:
		custom_minimum_size = Vector2(0, 112)
	func _draw() -> void:
		var bar := Rect2(0, 18, size.x, 46)
		draw_rect(bar.grow(3), WOOD_D)
		var steps := 12
		for i in steps:
			var k := float(i) / steps
			draw_rect(Rect2(bar.position.x, bar.position.y + bar.size.y * k, bar.size.x, bar.size.y / steps + 1), SEA.darkened(0.2 + k * 0.5))
		if game == null or game.fishing.is_empty():
			return
		var f: Dictionary = game.fishing
		var tt: float = game.t
		var zr := Rect2(bar.position.x + f["zs"] * bar.size.x, bar.position.y, f["w"] * bar.size.x, bar.size.y)
		var vis: float = f.get("vis", 1.0)
		draw_rect(zr, Color(SUN, (0.28 + 0.1 * sin(tt * 6.0)) * vis))
		draw_rect(zr, Color(SUN, 0.9 * vis), false, 2.0)
		for i in 4:
			var bx: float = zr.position.x + zr.size.x * fmod(i * 0.29 + tt * 0.3, 1.0)
			draw_circle(Vector2(bx, zr.end.y - fmod(tt * 20.0 + i * 11.0, bar.size.y)), 2.0, Color(1, 1, 1, 0.5))
		draw_line(Vector2(0, bar.position.y + 8), Vector2(size.x, bar.position.y + 8), Color(1, 1, 1, 0.35), 1.0)
		var x: float = bar.position.x + f["p"] * bar.size.x
		var y := bar.position.y + 8 + sin(tt * 9.0) * 2.0
		draw_line(Vector2(x, y - 14), Vector2(x, y + 22), INK, 2.0)
		draw_circle(Vector2(x, y + 4), 9, FOAM)
		draw_circle(Vector2(x, y - 1), 9, BLOOD)
		draw_rect(Rect2(x - 9, y + 1, 18, 3), FOAM)
		var base := Vector2(0, 80)
		for i in int(f.get("need", 3)):
			var r := Rect2(base.x + i * 62, base.y, 54, 26)
			draw_rect(r, Color(0, 0, 0, 0.3))
			if i < f["hits"]:
				load("res://scripts/ui.gd").draw_fish(self, r.grow(-2), SUN, false, false)
			else:
				draw_rect(r, Color(BRASS, 0.4), false, 1.0)
		for i in 3:
			var cx: float = size.x - 20 - i * 34
			var col := BLOOD if i < f["miss"] else Color(BRASS, 0.35)
			draw_line(Vector2(cx - 9, base.y + 4), Vector2(cx + 9, base.y + 22), col, 3.0)
			draw_line(Vector2(cx + 9, base.y + 4), Vector2(cx - 9, base.y + 22), col, 3.0)
	func _gui_input(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed:
			game.strike()


## Bodega en cuadrícula con marco de latón.
class HoldGrid extends Control:
	const CELL := 46.0
	const GAP := 4.0
	var game
	var sel := -1
	var on_select: Callable
	func refresh() -> void:
		custom_minimum_size = Vector2(game.cols * (CELL + GAP) + GAP + 12, game.rows * (CELL + GAP) + GAP + 12)
		if sel >= game.items.size():
			sel = -1
		queue_redraw()
	func _draw() -> void:
		var frame := Rect2(Vector2.ZERO, size)
		draw_rect(frame, BRASS_D)
		draw_rect(frame.grow(-3), BRASS)
		draw_rect(frame.grow(-6), WOOD_D)
		var o := Vector2(6, 6)
		for r in game.rows:
			for c in game.cols:
				var cr := Rect2(o + Vector2(GAP + c * (CELL + GAP), GAP + r * (CELL + GAP)), Vector2(CELL, CELL))
				draw_rect(cr, Color("140d09"))
				draw_rect(cr, Color(BRASS, 0.12), false, 1.0)
		var i := 0
		var tt: float = game.t
		for it in game.items:
			var sh: Array = it["shape"]
			var rect := Rect2(o + Vector2(GAP + it["c"] * (CELL + GAP), GAP + it["r"] * (CELL + GAP)), Vector2(sh[0].size() * (CELL + GAP) - GAP, sh.size() * (CELL + GAP) - GAP))
			if it["mut"]:
				draw_rect(rect, Color(BLOOD, 0.22 + 0.06 * sin(tt * 3.0 + i)))
				draw_rect(rect, Color(BLOOD, 0.7), false, 1.5)
			else:
				draw_rect(rect, Color(SEA, 0.35))
			FishArt.draw(self, rect.grow(-3), it["key"], it["mut"], sh.size() > sh[0].size())
			if i == sel:
				draw_rect(rect.grow(2), SUN, false, 2.5)
			i += 1
	func _process(_d: float) -> void:
		if is_visible_in_tree():
			queue_redraw()
	func _gui_input(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			var c := int((event.position.x - 6 - GAP) / (CELL + GAP))
			var r := int((event.position.y - 6 - GAP) / (CELL + GAP))
			sel = -1
			var i := 0
			for it in game.items:
				var sh: Array = it["shape"]
				var lr: int = r - it["r"]
				var lc: int = c - it["c"]
				if lr >= 0 and lc >= 0 and lr < sh.size() and lc < sh[0].size() and sh[lr][lc]:
					sel = i
				i += 1
			queue_redraw()
			if on_select.is_valid():
				on_select.call(sel)


# =====================================================================
# Construcción
# =====================================================================

func _ready() -> void:
	var theme := Theme.new()
	theme.default_font = F_UI
	theme.default_font_size = 18
	var btn := StyleBoxFlat.new()
	btn.bg_color = WOOD_D
	btn.border_color = BRASS_D
	btn.set_border_width_all(2)
	btn.set_corner_radius_all(3)
	btn.content_margin_left = 16
	btn.content_margin_right = 16
	btn.content_margin_top = 8
	btn.content_margin_bottom = 8
	var btn_h := btn.duplicate()
	btn_h.border_color = BRASS
	btn_h.bg_color = WOOD_L
	var btn_d := btn.duplicate()
	btn_d.bg_color = Color(WOOD_D, 0.5)
	btn_d.border_color = Color(BRASS_D, 0.4)
	theme.set_stylebox("normal", "Button", btn)
	theme.set_stylebox("hover", "Button", btn_h)
	theme.set_stylebox("pressed", "Button", btn_h)
	theme.set_stylebox("disabled", "Button", btn_d)
	theme.set_stylebox("focus", "Button", StyleBoxEmpty.new())
	theme.set_color("font_color", "Button", FOAM)
	theme.set_color("font_hover_color", "Button", SUN)
	theme.set_color("font_disabled_color", "Button", Color(SALT, 0.5))
	theme.set_font("font", "Button", F_UI_B)
	theme.set_color("font_color", "Label", FOAM)

	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.theme = theme
	add_child(root)

	vignette = ColorRect.new()
	vignette.set_anchors_preset(Control.PRESET_FULL_RECT)
	vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var vs := Shader.new()
	vs.code = "shader_type canvas_item; uniform float amount = 0.0; uniform float t = 0.0; void fragment(){ float d = distance(UV, vec2(0.5)); float vein = 0.5 + 0.5 * sin(UV.x * 40.0 + t) * sin(UV.y * 30.0 - t * 0.7); COLOR = vec4(0.35, 0.02, 0.02, smoothstep(0.32, 0.78, d + vein * 0.05) * amount); }"
	var vm := ShaderMaterial.new()
	vm.shader = vs
	vignette.material = vm
	root.add_child(vignette)

	_build_hud(root)
	_build_fishing(root)
	_build_catch(root)
	_build_hold(root)
	_build_port(root)
	_build_dialogue(root)
	_build_journal(root)
	_build_map(root)
	_build_silbo(root)
	_build_choice(root)
	_build_ending(root)
	_build_intro(root)
	_build_menu(root)
	_build_pause(root)
	_build_options(root)
	process_mode = Node.PROCESS_MODE_ALWAYS
	_load_options()


func _label(text: String, size := 18, color := FOAM, font: Font = null) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	if font:
		l.add_theme_font_override("font", font)
	return l


func _shadowed(l: Label) -> Label:
	l.add_theme_constant_override("outline_size", 7)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.75))
	return l


func _button(text: String, cb: Callable, primary := false) -> Button:
	var b := Button.new()
	b.text = text
	b.pressed.connect(cb)
	if primary:
		var sb := StyleBoxFlat.new()
		sb.bg_color = BRASS
		sb.border_color = BRASS_D
		sb.set_border_width_all(2)
		sb.set_corner_radius_all(3)
		sb.content_margin_left = 18
		sb.content_margin_right = 18
		sb.content_margin_top = 9
		sb.content_margin_bottom = 9
		var sbh := sb.duplicate()
		sbh.bg_color = SUN
		b.add_theme_stylebox_override("normal", sb)
		b.add_theme_stylebox_override("hover", sbh)
		b.add_theme_stylebox_override("pressed", sbh)
		for k in ["font_color", "font_hover_color", "font_pressed_color"]:
			b.add_theme_color_override(k, INK)
	return b


func _center_panel(root: Control, width := 520) -> WoodPanel:
	var p := WoodPanel.new()
	p.set_anchors_preset(Control.PRESET_CENTER)
	p.custom_minimum_size = Vector2(width, 0)
	p.grow_horizontal = Control.GROW_DIRECTION_BOTH
	p.grow_vertical = Control.GROW_DIRECTION_BOTH
	p.visible = false
	root.add_child(p)
	return p


func _build_hud(root: Control) -> void:
	dial = SunDial.new()
	dial.game = main
	dial.set_anchors_preset(Control.PRESET_CENTER_TOP)
	dial.grow_horizontal = Control.GROW_DIRECTION_BOTH
	dial.offset_left = -190
	dial.offset_right = 190
	dial.offset_top = 18
	dial.offset_bottom = 196
	root.add_child(dial)

	place_lbl = _shadowed(_label("", 16, PAPER, F_TITLE_R))
	place_lbl.set_anchors_preset(Control.PRESET_CENTER_TOP)
	place_lbl.grow_horizontal = Control.GROW_DIRECTION_BOTH
	place_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	place_lbl.offset_top = 198
	root.add_child(place_lbl)

	var mp := PanelContainer.new()
	var msb := wood_style(0.92)
	msb.set_content_margin_all(14)
	msb.content_margin_left = 20
	msb.content_margin_right = 20
	mp.add_theme_stylebox_override("panel", msb)
	mp.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	mp.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	mp.offset_right = -20
	mp.offset_top = 18
	mp.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(mp)
	hud_nodes.append(mp)
	var mvb := VBoxContainer.new()
	mvb.add_theme_constant_override("separation", 0)
	mp.add_child(mvb)
	money_lbl = _label("0 €", 34, SUN, F_TITLE)
	money_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	mvb.add_child(money_lbl)
	debt_lbl = _label("", 14, SALT)
	debt_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	mvb.add_child(debt_lbl)
	hull_lbl = _label("", 15, PAPER, F_UI_B)
	hull_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	mvb.add_child(hull_lbl)

	note = PaperNote.new()
	note.position = Vector2(26, 24)
	root.add_child(note)

	hint_box = PanelContainer.new()
	var hsb := StyleBoxFlat.new()
	hsb.bg_color = Color(WOOD_D, 0.85)
	hsb.border_color = Color(BRASS, 0.5)
	hsb.set_border_width_all(1)
	hsb.set_corner_radius_all(20)
	hsb.content_margin_left = 10
	hsb.content_margin_right = 18
	hsb.content_margin_top = 6
	hsb.content_margin_bottom = 6
	hint_box.add_theme_stylebox_override("panel", hsb)
	hint_box.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	hint_box.grow_horizontal = Control.GROW_DIRECTION_BOTH
	hint_box.grow_vertical = Control.GROW_DIRECTION_BEGIN
	hint_box.offset_bottom = -78
	hint_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hint_box.visible = false
	root.add_child(hint_box)
	var hrow := HBoxContainer.new()
	hrow.add_theme_constant_override("separation", 10)
	hint_box.add_child(hrow)
	hint_key = KeyCap.new("E")
	hrow.add_child(hint_key)
	hint_lbl = _label("", 19, FOAM, F_UI_B)
	hrow.add_child(hint_lbl)

	# Cartel del tutorial: papel con una tecla, bajo el encargo
	tut_box = PanelContainer.new()
	var tsb2 := StyleBoxFlat.new()
	tsb2.bg_color = Color(PAPER, 0.96)
	tsb2.border_color = Color(SUN, 0.9)
	tsb2.set_border_width_all(2)
	tsb2.set_corner_radius_all(4)
	tsb2.set_content_margin_all(12)
	tsb2.shadow_color = Color(0, 0, 0, 0.35)
	tsb2.shadow_size = 8
	tut_box.add_theme_stylebox_override("panel", tsb2)
	tut_box.position = Vector2(26, 190)
	tut_box.custom_minimum_size = Vector2(360, 0)
	tut_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tut_box.visible = false
	root.add_child(tut_box)
	var trow := HBoxContainer.new()
	trow.add_theme_constant_override("separation", 12)
	tut_box.add_child(trow)
	tut_key = KeyCap.new("E")
	tut_key.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	trow.add_child(tut_key)
	var tvb := VBoxContainer.new()
	tvb.add_theme_constant_override("separation", 0)
	trow.add_child(tvb)
	tvb.add_child(_label("CONSEJO", 12, Color(INK, 0.6), F_TITLE))
	tut_lbl = _label("", 18, INK)
	tut_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tut_lbl.custom_minimum_size = Vector2(290, 0)
	tvb.add_child(tut_lbl)

	toast_box = PanelContainer.new()
	var tsb := wood_style(0.92)
	tsb.set_content_margin_all(12)
	tsb.content_margin_left = 22
	tsb.content_margin_right = 22
	toast_box.add_theme_stylebox_override("panel", tsb)
	toast_box.set_anchors_preset(Control.PRESET_CENTER_TOP)
	toast_box.grow_horizontal = Control.GROW_DIRECTION_BOTH
	toast_box.offset_top = 234
	toast_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(toast_box)
	toast_lbl = _label("", 18, PAPER, F_TITLE_R)
	toast_box.add_child(toast_lbl)

	var keys := HBoxContainer.new()
	keys.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	keys.grow_horizontal = Control.GROW_DIRECTION_BOTH
	keys.grow_vertical = Control.GROW_DIRECTION_BEGIN
	keys.offset_bottom = -18
	keys.add_theme_constant_override("separation", 8)
	keys.modulate.a = 0.8
	keys.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(keys)
	hud_nodes.append(keys)
	for k in [["WASD", "Navegar"], ["E", "Acción"], ["F", "Farol"], ["G", "Silbar"], ["I", "Bodega"], ["C", "Cuaderno"], ["M", "Mapa"]]:
		keys.add_child(KeyCap.new(k[0]))
		keys.add_child(_shadowed(_label(k[1] + "   ", 15, PAPER)))


func _build_fishing(root: Control) -> void:
	fish_panel = _center_panel(root, 560)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 10)
	fish_panel.add_child(vb)
	vb.add_child(Plaque.new("SEDAL EN EL AGUA", 18))
	fish_title = _label("Pescando…", 28, FOAM, F_TITLE)
	vb.add_child(fish_title)
	fish_sub = _label("", 16, SALT)
	fish_sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vb.add_child(fish_sub)
	vb.add_child(_label("Espacio o clic cuando el corcho esté sobre el agua dorada.", 14, Color(SALT, 0.7)))
	fish_bar = FishBar.new()
	fish_bar.game = main
	vb.add_child(fish_bar)
	var row := HBoxContainer.new()
	vb.add_child(row)
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(sp)
	row.add_child(_button("Recoger sedal", func(): main.end_fishing(false, true)))


func _build_catch(root: Control) -> void:
	catch_panel = _center_panel(root, 500)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 10)
	catch_panel.add_child(vb)
	var head := HBoxContainer.new()
	vb.add_child(head)
	var pl := Plaque.new("CAPTURA", 18)
	pl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(pl)
	catch_new = _label("¡Nueva en el cuaderno!", 26, BLOOD.lightened(0.25), F_HAND)
	head.add_child(catch_new)
	catch_icon = FishIcon.new()
	catch_icon.custom_minimum_size = Vector2(0, 150)
	vb.add_child(catch_icon)
	var nrow := HBoxContainer.new()
	vb.add_child(nrow)
	catch_name = _label("", 32, FOAM, F_TITLE)
	catch_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nrow.add_child(catch_name)
	catch_price = _label("", 28, SUN, F_TITLE)
	nrow.add_child(catch_price)
	catch_desc = _label("", 17, SALT)
	catch_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vb.add_child(catch_desc)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	vb.add_child(row)
	keep_btn = _button("Guardar en bodega", func():
		catch_panel.visible = false
		main.keep_catch(), true)
	row.add_child(keep_btn)
	row.add_child(_button("Soltar", func():
		catch_panel.visible = false
		main.release_catch()))


func _build_hold(root: Control) -> void:
	hold_panel = WoodPanel.new()
	hold_panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	hold_panel.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	hold_panel.offset_right = -20
	hold_panel.offset_top = 120
	hold_panel.visible = false
	root.add_child(hold_panel)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 10)
	hold_panel.add_child(vb)
	vb.add_child(Plaque.new("BODEGA", 20))
	hold_stats = _label("", 14, SALT)
	vb.add_child(hold_stats)
	hold_grid = HoldGrid.new()
	hold_grid.game = main
	hold_grid.on_select = _on_hold_select
	vb.add_child(hold_grid)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	vb.add_child(row)
	drop_btn = _button("Tirar al mar", func():
		main.drop_item(hold_grid.sel)
		hold_grid.sel = -1
		_on_hold_select(-1))
	drop_btn.disabled = true
	row.add_child(drop_btn)
	hold_info = _label("", 15, PAPER)
	row.add_child(hold_info)
	hold_grid.refresh()


## Cuaderno de especies: páginas de papel con una ficha por pez.
class JournalBook extends Control:
	const COLS := 6
	const CW := 162.0
	const CH := 136.0
	const PER_PAGE := 18
	var game
	var page := 0
	func pages() -> int:
		return int(ceil(float(Data.JOURNAL.size()) / PER_PAGE))
	func _init() -> void:
		custom_minimum_size = Vector2(COLS * CW + 40, 3 * CH + 30)
	func _draw() -> void:
		var r := Rect2(Vector2.ZERO, size)
		draw_rect(r, PAPER)
		for idx in range(page * PER_PAGE, min((page + 1) * PER_PAGE, Data.JOURNAL.size())):
			var i := idx - page * PER_PAGE
			var key: String = Data.JOURNAL[idx][0]
			var where: String = Data.JOURNAL[idx][1]
			var e: Dictionary = game.journal.get(key, {})
			var seen_n: bool = e.get("n", false)
			var seen_m: bool = e.get("m", false)
			var cell := Rect2(20 + (i % COLS) * CW, 15 + (i / COLS) * CH, CW - 10, CH - 10)
			draw_rect(cell, Color(INK, 0.05))
			draw_rect(cell, Color(INK, 0.25), false, 1.0)
			var fr := Rect2(cell.position + Vector2(18, 8), Vector2(cell.size.x - 36, 48))
			var f: Dictionary = Data.FISH[key]
			if seen_n or seen_m:
				FishArt.draw(self, fr, key, seen_m and not seen_n)
				draw_string(F_TITLE, cell.position + Vector2(10, 76), f["n"], HORIZONTAL_ALIGNMENT_LEFT, cell.size.x - 20, 18, INK)
				draw_string(F_UI, cell.position + Vector2(10, 93), "%s · %d €" % [where, f["v"]], HORIZONTAL_ALIGNMENT_LEFT, cell.size.x - 20, 12, Color(INK, 0.6))
			else:
				FishArt.draw(self, fr, key, false, false, true)
				draw_string(F_TITLE, cell.position + Vector2(10, 76), "???", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(INK, 0.45))
				draw_string(F_UI, cell.position + Vector2(10, 93), where, HORIZONTAL_ALIGNMENT_LEFT, cell.size.x - 20, 12, Color(INK, 0.45))
			var mt: String = f["m"] if seen_m else "Mutante: ???"
			draw_string(F_HAND, cell.position + Vector2(10, 114), mt, HORIZONTAL_ALIGNMENT_LEFT, cell.size.x - 16, 17, BLOOD if seen_m else Color(INK, 0.35))


func _build_journal(root: Control) -> void:
	journal_panel = _center_panel(root, 0)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 10)
	journal_panel.add_child(vb)
	var head := HBoxContainer.new()
	vb.add_child(head)
	var pl := Plaque.new("CUADERNO DE ESPECIES", 20)
	pl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(pl)
	journal_count = _label("", 16, PAPER)
	head.add_child(journal_count)
	journal_book = JournalBook.new()
	journal_book.game = main
	vb.add_child(journal_book)
	var foot := HBoxContainer.new()
	foot.add_theme_constant_override("separation", 10)
	foot.add_child(_button("◀ Anterior", func(): journal_page(-1)))
	journal_pg = _label("", 15, PAPER)
	foot.add_child(journal_pg)
	foot.add_child(_button("Siguiente ▶", func(): journal_page(1)))
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	foot.add_child(sp)
	foot.add_child(KeyCap.new("C"))
	foot.add_child(_label("  cerrar", 14, SALT))
	vb.add_child(foot)


func _build_map(root: Control) -> void:
	compass = Compass.new()
	compass.game = main
	compass.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	compass.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	compass.grow_vertical = Control.GROW_DIRECTION_BEGIN
	compass.offset_right = -20
	compass.offset_bottom = -14
	root.add_child(compass)
	hud_nodes.append(compass)
	map_panel = _center_panel(root, 1180)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 10)
	map_panel.add_child(vb)
	vb.add_child(Plaque.new("CARTA DE NAVEGACIÓN", 20))
	map_chart = ChartMap.new()
	map_chart.full = true
	map_chart.custom_minimum_size = Vector2(1130, 560)
	map_chart.mouse_filter = Control.MOUSE_FILTER_IGNORE
	map_chart.clip_contents = true
	vb.add_child(map_chart)
	var foot := HBoxContainer.new()
	vb.add_child(foot)
	var tip := _label("Para cruzar a otra isla, entra en el puerto y elige el viaje. La flecha dorada de la brújula señala tu objetivo.", 15, SALT)
	tip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	foot.add_child(tip)
	foot.add_child(KeyCap.new("M"))
	foot.add_child(_label("  cerrar", 14, SALT))


func toggle_map() -> void:
	map_panel.visible = not map_panel.visible
	hold_panel.visible = false
	journal_panel.visible = false
	if map_panel.visible:
		var ports := {"tenerife": Vector2(-16.37, 28.29), "gran_canaria": Vector2(-15.42, 28.14), "la_gomera": Vector2(-17.11, 28.09),
			"lanzarote": Vector2(-13.5, 29.23), "fuerteventura": Vector2(-13.87, 28.73), "la_palma": Vector2(-17.94, 28.64), "el_hierro": Vector2(-17.98, 27.65)}
		map_chart.here = ports.get(main.region, Vector2.ZERO)
		var gk: String = main.quest.goal_island_key()
		map_chart.goal = ports.get(gk, Vector2.ZERO) if gk != main.region else Vector2.ZERO
		map_chart.goal_name = Data.REGIONS[gk]["name"] if Data.REGIONS.has(gk) else ""


func _build_silbo(root: Control) -> void:
	silbo_panel = _center_panel(root, 560)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 12)
	silbo_panel.add_child(vb)
	vb.add_child(Plaque.new("SILBO GOMERO", 20))
	silbo_msg = _label("", 22, FOAM, F_TITLE_R)
	silbo_msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(silbo_msg)
	silbo_bar = SilboBar.new()
	vb.add_child(silbo_bar)
	var keys := HBoxContainer.new()
	keys.alignment = BoxContainer.ALIGNMENT_CENTER
	keys.add_theme_constant_override("separation", 8)
	keys.add_child(KeyCap.new("W"))
	keys.add_child(_label("silbo agudo      ", 15, SALT))
	keys.add_child(KeyCap.new("S"))
	keys.add_child(_label("silbo grave", 15, SALT))
	vb.add_child(keys)


func open_silbo() -> void:
	hold_panel.visible = false
	silbo_panel.visible = true


func close_silbo() -> void:
	silbo_panel.visible = false


func update_silbo(sb: Dictionary) -> void:
	if sb.is_empty():
		return
	var seq: Array = main.quest.SILBO_ROUNDS[sb["round"]]
	silbo_bar.seq = seq
	silbo_bar.shown = sb["i"]
	silbo_bar.input = sb["input"]
	silbo_bar.phase = sb["phase"]
	silbo_bar.queue_redraw()
	var r := "Ronda %d de %d · " % [sb["round"] + 1, main.quest.SILBO_ROUNDS.size()]
	match sb["phase"]:
		"listen":
			silbo_msg.text = r + "Escucha a Isidro…"
		"repeat":
			silbo_msg.text = r + "Ahora tú: repite el silbo."
		"ok":
			silbo_msg.text = "¡Bien silbado!"
		"fail":
			silbo_msg.text = "Ese no era. Isidro vuelve a silbar."


func journal_page(d: int) -> void:
	journal_book.page = posmod(journal_book.page + d, journal_book.pages())
	journal_pg.text = "Página %d de %d" % [journal_book.page + 1, journal_book.pages()]
	journal_book.queue_redraw()


func _build_choice(root: Control) -> void:
	choice_panel = WoodPanel.new()
	choice_panel.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	choice_panel.custom_minimum_size = Vector2(900, 0)
	choice_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	choice_panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	choice_panel.offset_bottom = -64
	choice_panel.visible = false
	root.add_child(choice_panel)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 12)
	choice_panel.add_child(vb)
	choice_label = _label("", 24, SUN, F_TITLE)
	vb.add_child(choice_label)
	choice_box = VBoxContainer.new()
	choice_box.add_theme_constant_override("separation", 8)
	vb.add_child(choice_box)


func show_choice(prompt: String, options: Array, cb: Callable) -> void:
	choice_label.text = prompt
	choice_cb = cb
	for c in choice_box.get_children():
		c.queue_free()
	for i in options.size():
		var idx := i
		var b := _button("%d · %s" % [i + 1, options[i]], func(): pick_choice(idx), i == 0)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		choice_box.add_child(b)
	main.mode = "choice"
	choice_panel.visible = true


func pick_choice(i: int) -> void:
	if not choice_panel.visible:
		return
	choice_panel.visible = false
	main.mode = "sail"
	if choice_cb.is_valid():
		choice_cb.call(i)


func _build_ending(root: Control) -> void:
	ending_layer = ColorRect.new()
	ending_layer.color = Color(0.03, 0.02, 0.02, 0.97)
	ending_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	ending_layer.visible = false
	root.add_child(ending_layer)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	ending_layer.add_child(center)
	var vb := VBoxContainer.new()
	vb.custom_minimum_size = Vector2(820, 0)
	vb.add_theme_constant_override("separation", 20)
	center.add_child(vb)
	ending_title = _label("", 44, SUN, F_TITLE)
	ending_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(ending_title)
	ending_text = _label("", 21, PAPER, F_TITLE_R)
	ending_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ending_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(ending_text)
	ending_stats = _label("", 16, SALT)
	ending_stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(ending_stats)
	vb.add_child(_label("Gracias por jugar MAGEC", 28, SUN, F_HAND))
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 14)
	row.add_child(_button("Seguir pescando", func():
		ending_layer.visible = false
		main.mode = "sail", true))
	row.add_child(_button("Volver al menú", func(): main.to_main_menu()))
	vb.add_child(row)


func show_ending(title: String, text: String) -> void:
	var n := 0
	for e in main.journal.values():
		n += 1 if e.get("n", false) else 0
	ending_title.text = title
	ending_text.text = text
	ending_stats.text = "Días en el mar: %d   ·   Especies descubiertas: %d/%d   ·   Mutantes vendidos a Baltasar: %d" % [main.day, n, Data.JOURNAL.size(), main.quest.mutants_sold]
	ending_layer.visible = true
	main.mode = "menu"


func toggle_journal() -> void:
	journal_panel.visible = not journal_panel.visible
	hold_panel.visible = false
	if journal_panel.visible:
		var n := 0
		var m := 0
		for e in main.journal.values():
			n += 1 if e.get("n", false) else 0
			m += 1 if e.get("m", false) else 0
		journal_count.text = "Especies: %d/%d   ·   Mutantes: %d/%d" % [n, Data.JOURNAL.size(), m, Data.JOURNAL.size()]
		journal_page(0)


func toast_new_species(key: String, mut: bool) -> void:
	toast("¡Nueva en el cuaderno! " + Data.fish_name(key, mut))


func _build_port(root: Control) -> void:
	port_panel = _center_panel(root, 620)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 10)
	port_panel.add_child(vb)
	vb.add_child(Plaque.new(Data.REGIONS[main.region]["port"].to_upper(), 20))
	vb.add_child(_label("Aquí estás a salvo. La luz del puerto calma el miedo.", 16, SALT))
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 470)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vb.add_child(scroll)
	port_list = VBoxContainer.new()
	port_list.add_theme_constant_override("separation", 8)
	port_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(port_list)
	var b := _button("Zarpar", func():
		port_panel.visible = false
		main.leave_port(), true)
	b.size_flags_horizontal = Control.SIZE_SHRINK_END
	vb.add_child(b)


func _build_dialogue(root: Control) -> void:
	dlg_panel = WoodPanel.new()
	dlg_panel.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	dlg_panel.custom_minimum_size = Vector2(900, 0)
	dlg_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	dlg_panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	dlg_panel.offset_bottom = -64
	dlg_panel.visible = false
	root.add_child(dlg_panel)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 18)
	dlg_panel.add_child(row)
	dlg_portrait = Portrait.new()
	row.add_child(dlg_portrait)
	var vb := VBoxContainer.new()
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.add_theme_constant_override("separation", 6)
	row.add_child(vb)
	dlg_name = _label("", 24, SUN, F_TITLE)
	vb.add_child(dlg_name)
	dlg_text = _label("", 22, FOAM)
	dlg_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vb.add_child(dlg_text)
	var cont := HBoxContainer.new()
	cont.alignment = BoxContainer.ALIGNMENT_END
	cont.add_child(KeyCap.new("E"))
	cont.add_child(_label(" continuar", 14, SALT))
	vb.add_child(cont)
	dlg_panel.gui_input.connect(func(e):
		if e is InputEventMouseButton and e.pressed:
			main.quest.next_line())


func _build_intro(root: Control) -> void:
	# Capa de la cinemática: bandas de cine, rótulos, subtítulos y título.
	intro = Control.new()
	intro.set_anchors_preset(Control.PRESET_FULL_RECT)
	intro.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(intro)
	for top in [true, false]:
		var band := ColorRect.new()
		band.color = Color.BLACK
		band.set_anchors_preset(Control.PRESET_TOP_WIDE if top else Control.PRESET_BOTTOM_WIDE)
		if top:
			band.offset_bottom = 96
		else:
			band.offset_top = -96
		band.mouse_filter = Control.MOUSE_FILTER_IGNORE
		intro.add_child(band)
	cine_black = ColorRect.new()
	cine_black.color = Color.BLACK
	cine_black.set_anchors_preset(Control.PRESET_FULL_RECT)
	cine_black.mouse_filter = Control.MOUSE_FILTER_IGNORE
	intro.add_child(cine_black)
	cine_card = _label("", 34, PAPER, F_TITLE_R)
	cine_card.set_anchors_preset(Control.PRESET_FULL_RECT)
	cine_card.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cine_card.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	cine_card.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	cine_card.offset_left = 200
	cine_card.offset_right = -200
	intro.add_child(cine_card)
	cine_sub = _shadowed(_label("", 26, FOAM))
	cine_sub.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	cine_sub.offset_top = -180
	cine_sub.offset_bottom = -104
	cine_sub.offset_left = 160
	cine_sub.offset_right = -160
	cine_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cine_sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	intro.add_child(cine_sub)
	cine_title = _label("MAGEC", 170, SUN, F_TITLE)
	cine_title.set_anchors_preset(Control.PRESET_FULL_RECT)
	cine_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cine_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	cine_title.add_theme_constant_override("outline_size", 16)
	cine_title.add_theme_color_override("font_outline_color", Color(0.25, 0.12, 0.0, 0.7))
	cine_title.modulate.a = 0.0
	intro.add_child(cine_title)
	var skip := HBoxContainer.new()
	skip.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	skip.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	skip.offset_right = -28
	skip.offset_top = 34
	skip.add_child(KeyCap.new("Esc"))
	skip.add_child(_label("  Saltar", 15, SALT))
	intro.add_child(skip)


# =====================================================================
# API usada por main.gd, quest.gd y cinematic.gd
# =====================================================================

func cine_set(black: float, card: String, card_a: float, sub: String, sub_a: float, title_a: float) -> void:
	cine_black.color.a = black
	cine_card.text = card
	cine_card.modulate.a = card_a
	cine_sub.text = sub
	cine_sub.modulate.a = sub_a
	cine_title.modulate.a = title_a


func end_cinematic() -> void:
	intro.visible = false
	toast("Busca las burbujas en el agua para pescar.")


func shake(amount: float) -> void:
	shake_amt = max(shake_amt, amount)


func toast(text: String) -> void:
	toast_lbl.text = text
	toast_time = 2.8


func _set_hint(bb: String) -> void:
	# Las pistas vienen como "[color=#f2b33d]E[/color] · texto"
	var key := ""
	var text := bb
	var re := RegEx.new()
	re.compile("\\[color=#f2b33d\\](\\w+)\\[/color\\]\\s*·?\\s*")
	var m := re.search(bb)
	if m:
		key = m.get_string(1)
		text = text.replace(m.get_string(0), "")
	var strip := RegEx.new()
	strip.compile("\\[[^\\]]*\\]")
	text = strip.sub(text, "", true).strip_edges()
	hint_box.visible = text != ""
	hint_key.visible = key != ""
	if key != "" and key != hint_key.key:
		hint_key.set_key(key)
	hint_lbl.text = text


func update_hud() -> void:
	var cine: bool = main.mode == "cinematic" or main.mode == "menu"
	for n in hud_nodes:
		n.visible = not cine
	dial.visible = not cine
	dial.queue_redraw()
	money_lbl.text = "%d €" % main.money
	debt_lbl.text = ("Deuda del barco: %d €" % main.debt) if main.debt > 0 else "Barco pagado"
	place_lbl.text = "" if cine else "%s  ·  %s  ·  %s" % [Data.REGIONS[main.region]["place"], main.zone_name(main.bz), main.weather.name_now()]
	var hull_txt := "Casco  "
	for i in main.hull_max:
		hull_txt += "■ " if i < main.hull else "□ "
	hull_lbl.text = hull_txt
	hull_lbl.add_theme_color_override("font_color", PAPER if main.hull > 1 else Color("e2675b"))
	if shake_amt > 0.0:
		shake_amt = max(0.0, shake_amt - get_process_delta_time())
		main.camera.h_offset = randf_range(-1, 1) * shake_amt * 0.6
		main.camera.v_offset = randf_range(-1, 1) * shake_amt * 0.6
	else:
		main.camera.h_offset = 0.0
		main.camera.v_offset = 0.0
	note.set_text("" if cine else main.quest.objective())
	var tip: Array = main.tutorial.current() if (main.tutorial and not cine) else []
	tut_box.visible = not tip.is_empty() and main.mode in ["sail", "fish", "catch"]
	if tut_box.visible:
		if tut_key.key != tip[0]:
			tut_key.set_key(tip[0])
		tut_lbl.text = tip[1]
		tut_box.position.y = note.position.y + note.size.y + 16.0
	vignette.material.set_shader_parameter("amount", clamp((main.panic - 60.0) / 40.0, 0.0, 1.0))
	vignette.material.set_shader_parameter("t", main.t)

	toast_time -= get_process_delta_time()
	toast_box.modulate.a = clamp(toast_time / 0.4, 0.0, 1.0)
	toast_box.visible = toast_time > 0.0

	var hint := ""
	var qh: String = main.quest.hint() if main.mode == "sail" else ""
	if qh == "" and main.mode == "sail":
		qh = main.gear.hint()
	if qh != "":
		hint = qh
	elif main.mode == "sail":
		if main.near_port():
			hint = "[color=#f2b33d]E[/color] · Entrar al puerto de Güímar"
		else:
			var s = main.near_spot()
			if s != null:
				hint = "[color=#f2b33d]E[/color] · Pescar (%s)%s" % [Data.ZONES[s["zone"]]["name"], " · de noche salen mutantes" if main.is_night() else ""]
			elif main.is_night() and not main.lamp_on:
				hint = "[color=#f2b33d]F[/color] · Está oscuro. Enciende el farol"
	_set_hint(hint)

	if fish_panel.visible:
		fish_bar.queue_redraw()


func open_fishing(title: String, sub := "") -> void:
	hold_panel.visible = false
	journal_panel.visible = false
	fish_title.text = title
	fish_sub.text = sub
	fish_panel.visible = true


func close_fishing() -> void:
	fish_panel.visible = false


func open_catch(key: String, mut: bool, fits: bool, is_new := false) -> void:
	catch_new.visible = is_new
	catch_icon.key = key
	catch_icon.mut = mut
	catch_icon.queue_redraw()
	catch_name.text = Data.fish_name(key, mut)
	catch_name.add_theme_color_override("font_color", Color("e2675b") if mut else FOAM)
	catch_price.text = "%d €" % Data.fish_value(key, mut)
	catch_desc.text = Data.FISH[key]["md"] if mut else Data.FISH[key]["d"]
	var who: String = main.side.wanted(key, mut)
	if who != "":
		catch_desc.text += "\n★ Lo busca: %s." % who
	keep_btn.disabled = not fits
	keep_btn.text = "Guardar en bodega" if fits else "No cabe en la bodega"
	catch_panel.visible = true


func toggle_hold() -> void:
	hold_panel.visible = not hold_panel.visible
	refresh_hold()


func refresh_hold() -> void:
	if hold_grid == null:
		return
	hold_grid.refresh()
	var lamp := "Farol de Magec" + (" (bendecido)" if main.lamp_mult < 1.0 else "")
	var g = main.gear
	var gear_txt := "   ·   Nasas: %d/%d [N]" % [g.nasas_free(), g.nasas_owned] if g.nasas_owned > 0 else ""
	if g.net_owned:
		gear_txt += "   ·   Red [R]: %s" % ("echada" if g.net_out else "a bordo")
	hold_stats.text = "Motor: nivel %d   ·   %s%s" % [main.speed_lvl + 1, lamp, gear_txt]
	_on_hold_select(hold_grid.sel)


func _on_hold_select(sel: int) -> void:
	drop_btn.disabled = sel < 0
	if sel >= 0 and sel < main.items.size():
		var it: Dictionary = main.items[sel]
		hold_info.text = "%s · %d €" % [Data.fish_name(it["key"], it["mut"]), Data.fish_value(it["key"], it["mut"])]
	else:
		hold_info.text = "%d peces · %d €" % [main.items.size(), main.hold_value()]


func open_port() -> void:
	hold_panel.visible = false
	_render_port()
	port_panel.visible = true


func show_dialogue(who: String, text: String, _i: int, _n: int) -> void:
	hold_panel.visible = false
	dlg_portrait.who = who
	dlg_portrait.queue_redraw()
	dlg_name.text = who
	var name_cols := {"Acorán": Color("9cc8d8"), "Guayota": Color("ff6a3a"), "Don Baltasar": Color("d9b98a")}
	dlg_name.add_theme_color_override("font_color", name_cols.get(who, SUN))
	dlg_text.text = text
	dlg_panel.visible = true


func close_dialogue() -> void:
	dlg_panel.visible = false


func _port_line(title: String, sub: String, btn_text: String, disabled: bool, cb: Callable) -> void:
	var pc := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(WOOD_D, 0.8)
	sb.border_color = Color(BRASS, 0.2)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(3)
	sb.set_content_margin_all(10)
	sb.content_margin_left = 14
	pc.add_theme_stylebox_override("panel", sb)
	port_list.add_child(pc)
	var row := HBoxContainer.new()
	pc.add_child(row)
	var vb := VBoxContainer.new()
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.add_theme_constant_override("separation", 0)
	vb.add_child(_label(title, 20, FOAM, F_TITLE_R))
	vb.add_child(_label(sub, 14, SALT))
	row.add_child(vb)
	var b := _button(btn_text, func():
		cb.call()
		_render_port())
	b.disabled = disabled
	row.add_child(b)


func _section(title: String) -> void:
	var l := _label(title, 15, SUN, F_TITLE)
	l.add_theme_constant_override("outline_size", 0)
	port_list.add_child(l)


func _render_port() -> void:
	for c in port_list.get_children():
		c.queue_free()
	# ---- Lonja
	_section("LONJA")
	var total: int = main.hold_value()
	_port_line("Vender la pesca", "%d peces en la bodega%s" % [main.items.size(), "  ·  nevera +20 %" if main.has_fridge else ""], "+%d €" % total, total == 0, main.sell_all)
	_port_line("Pagar deuda del barco", ("Quedan %d €" % main.debt) if main.debt > 0 else "Pagada", "Pagar", main.money <= 0 or main.debt <= 0, main.pay_debt)
	if main.quest.baltasar_open():
		var mt := 0
		for it in main.items:
			if it["mut"]:
				mt += int(Data.fish_value(it["key"], true) * 1.5)
		_port_line("Vender mutantes a Don Baltasar", "Paga una vez y media. Nadie sabe para qué los quiere.", "+%d €" % mt, mt == 0, func(): main.quest.sell_mutants_to_baltasar())
	# ---- Encargos
	_section("ENCARGOS DEL DÍA")
	for e in main.side.current():
		var ent: Dictionary = e
		if ent["done"]:
			_port_line(ent["who"], "Entregado. ¡Gracias!", "✓", true, func(): pass)
		else:
			var have: int = main.side.have(ent)
			_port_line(ent["who"], "Pide %s  ·  tienes %d/%d" % [ent["text"], min(have, int(ent["count"])), int(ent["count"])], "Entregar · %d €" % int(ent["reward"]), have < int(ent["count"]), func(): main.side.deliver(ent))
	# ---- Astillero
	_section("ASTILLERO")
	if main.hull < main.hull_max:
		var rc: int = 40 * (main.hull_max - main.hull)
		_port_line("Reparar el casco", "Casco %d/%d." % [main.hull, main.hull_max], "%d €" % rc, main.money < rc, func():
			main.money -= rc
			main.hull = main.hull_max
			toast("Casco reparado."))
	if main.speed_lvl < 3:
		_port_line("Motor %s" % ["nuevo", "II", "III"][main.speed_lvl], "Navegas más rápido.", "%d €" % main.engine_price(), main.money < main.engine_price(), main.buy_engine)
	if main.rows < 5:
		_port_line("Ampliar bodega", "Una fila más de espacio.", "%d €" % main.hold_price(), main.money < main.hold_price(), main.buy_hold)
	if main.hull_lvl < 2:
		_port_line("Casco reforzado %s" % ["I", "II"][main.hull_lvl], "Aguanta un golpe más contra rocas, lava y dientes.", "%d €" % main.hull_price(), main.money < main.hull_price(), main.buy_hull)
	var ups := [
		["rod", "Caña buena", "El agua dorada del minijuego es un 25 % más ancha.", 180, main.has_rod],
		["sonar", "Sonar", "La brújula marca los bancos de peces cercanos.", 250, main.has_sonar],
		["foco", "Foco de proa", "Más luz de noche; el Tibicena se queda más lejos.", 200, main.has_foco],
		["fridge", "Nevera", "El pescado se vende un 20 % más caro.", 300, main.has_fridge],
	]
	for u in ups:
		if not u[4]:
			var what: String = u[0]
			var price: int = u[3]
			_port_line(u[1], u[2], "%d €" % price, main.money < price, func(): main.buy_upgrade(what, price))
	var g = main.gear
	if g.nasas_owned < g.MAX_NASAS:
		_port_line("Nasa para pulpos y morenas", "Échala con N y vuelve a por ella horas después. Tienes %d." % g.nasas_owned, "%d €" % g.NASA_PRICE, main.money < g.NASA_PRICE, func():
			main.money -= g.NASA_PRICE
			g.nasas_owned += 1
			toast("Nasa comprada. Pulsa N en el mar para echarla."))
	if not g.net_owned:
		_port_line("Red de arrastre", "Pesca peces pequeños mientras navegas (R), pero frena el barco.", "%d €" % g.NET_PRICE, main.money < g.NET_PRICE, func():
			main.money -= g.NET_PRICE
			g.net_owned = true
			toast("Red comprada. Pulsa R en el mar para echarla o recogerla."))
	# ---- Gente y viajes
	_section("GENTE Y VIAJES")
	for p in main.quest.port_people():
		var cb: Callable = p[2]
		_port_line(p[0], p[1], "Ir" if p[0].begins_with("Viajar") or p[0].begins_with("Volver") else "Hablar", false, func():
			port_panel.visible = false
			cb.call())
	if main.is_night():
		_port_line("Dormir hasta el amanecer", "Pasa la noche en casa.", "Dormir", false, main.sleep)
	refresh_hold()


# =====================================================================
# Menú principal, pausa y opciones
# =====================================================================

func _menu_button(text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = "   " + text
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.flat = true
	b.add_theme_font_override("font", F_TITLE)
	b.add_theme_font_size_override("font_size", 34)
	b.add_theme_color_override("font_color", PAPER)
	b.add_theme_color_override("font_hover_color", SUN)
	b.add_theme_color_override("font_focus_color", SUN)
	b.add_theme_color_override("font_pressed_color", SUN)
	b.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	b.add_theme_stylebox_override("hover", StyleBoxEmpty.new())
	b.add_theme_stylebox_override("pressed", StyleBoxEmpty.new())
	b.mouse_entered.connect(func(): b.text = "◆ " + text)
	b.mouse_exited.connect(func(): b.text = "   " + text)
	b.pressed.connect(cb)
	return b



## Notas del silbo: círculos dorados (agudo) y azules (grave).
class SilboBar extends Control:
	var seq: Array = []
	var shown := 0
	var input: Array = []
	var phase := ""
	func _init() -> void:
		custom_minimum_size = Vector2(0, 90)
	func _draw() -> void:
		var n := seq.size()
		if n == 0:
			return
		var gap := 70.0
		var x0 := size.x / 2 - (n - 1) * gap / 2
		for i in n:
			var c := Vector2(x0 + i * gap, 30)
			draw_circle(c, 24, Color(0, 0, 0, 0.3))
			var val = null
			if phase == "listen" and i < shown:
				val = seq[i]
			elif phase != "listen" and i < input.size():
				val = input[i]
			if val == null:
				draw_arc(c, 22, 0, TAU, 24, Color(BRASS, 0.5), 2.0, true)
				continue
			var col := SUN if val == 1 else Color("5aa8d8")
			if phase == "fail" and i == input.size() - 1:
				col = BLOOD
			draw_circle(c, 22, col)
			var up: bool = val == 1
			var tip := c + Vector2(0, -11 if up else 11)
			draw_colored_polygon(PackedVector2Array([tip, c + Vector2(-9, 5 if up else -5), c + Vector2(9, 5 if up else -5)]), INK)
			draw_string(F_UI_B, c + Vector2(-14, 46), "agudo" if up else "grave", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, PAPER)


## Brújula del barco: la rosa gira con el rumbo y la flecha dorada señala el objetivo.
class Compass extends Control:
	var game
	func _init() -> void:
		custom_minimum_size = Vector2(190, 214)
		mouse_filter = Control.MOUSE_FILTER_IGNORE
	func _process(_d: float) -> void:
		if is_visible_in_tree():
			queue_redraw()
	func _pos(c: Vector2, ang: float, r: float) -> Vector2:
		return c + Vector2(sin(ang), -cos(ang)) * r
	func _draw() -> void:
		if game == null:
			return
		var c := Vector2(95, 95)
		var R := 80.0
		var heading: float = -game.ba
		draw_circle(c + Vector2(3, 5), R + 6, Color(0, 0, 0, 0.35))
		draw_circle(c, R + 6, BRASS_D)
		draw_circle(c, R + 3, BRASS)
		draw_circle(c, R, Color("1d2a30"))
		draw_circle(c, R - 18, Color("24343b"))
		# marcas cada 15°
		for i in 24:
			var a := deg_to_rad(i * 15.0) - heading
			var l := 10.0 if i % 6 == 0 else 5.0
			draw_line(_pos(c, a, R - 2), _pos(c, a, R - 2 - l), Color(PAPER, 0.7), 1.5, true)
		var letters := [["N", 0.0], ["E", 90.0], ["S", 180.0], ["O", 270.0]]
		for lt in letters:
			var a := deg_to_rad(lt[1]) - heading
			var p := _pos(c, a, R - 25)
			var col := BLOOD.lightened(0.2) if lt[0] == "N" else PAPER
			var tw := F_TITLE.get_string_size(lt[0], HORIZONTAL_ALIGNMENT_LEFT, -1, 18).x
			draw_string(F_TITLE, p + Vector2(-tw / 2, 7), lt[0], HORIZONTAL_ALIGNMENT_LEFT, -1, 18, col)
		# rosa central pequeña
		for i in 8:
			var a := i * TAU / 8.0 - heading
			var r := 22.0 if i % 2 == 0 else 13.0
			var tip := _pos(c, a, r)
			draw_colored_polygon(PackedVector2Array([c, _pos(c, a - 0.4, 6), tip]), Color(PAPER, 0.5) if i % 2 else Color(BRASS, 0.8))
			draw_colored_polygon(PackedVector2Array([c, tip, _pos(c, a + 0.4, 6)]), Color(INK, 0.6))
		# objetivo
		var tg = game.quest.target()
		var info := "Sin rumbo fijo"
		if tg != null:
			var v: Vector2 = tg - Vector2(game.bx, game.bz)
			var dist := v.length()
			var bearing := atan2(v.x, -v.y)
			var a := bearing - heading
			var tip := _pos(c, a, R - 6)
			var base := _pos(c, a, R - 40)
			var side := Vector2(cos(a), sin(a)) * 9.0
			draw_colored_polygon(PackedVector2Array([tip, base + side, base - side]), SUN)
			draw_line(c, base, Color(SUN, 0.6), 2.0, true)
			info = "Objetivo · %d m" % int(dist) if dist > 12.0 else "Has llegado"
		var gi: String = game.quest.goal_island()
		if gi != "":
			info = "Ve al puerto y cruza a " + gi
		# sonar: puntos verdes para los bancos de peces cercanos
		if game.has_sonar:
			for sp in game.spots:
				if sp["left"] <= 0:
					continue
				var sv: Vector2 = Vector2(sp["x"], sp["z"]) - Vector2(game.bx, game.bz)
				var sd := sv.length()
				if sd < 140.0:
					var sa := atan2(sv.x, -sv.y) - heading
					var sr: float = lerp(18.0, R - 18.0, sd / 140.0)
					draw_circle(_pos(c, sa, sr), 3.5, Color(0.45, 1.0, 0.6, 0.9))
		# eco del silbo: marca azul que se desvanece
		var et: float = game.quest.echo_time
		if et > 0.0:
			var ea: float = game.quest.echo_bearing - heading
			var al: float = clamp(et / 6.0, 0.0, 1.0)
			draw_arc(c, R - 9, ea - 0.35 - PI / 2, ea + 0.35 - PI / 2, 12, Color(0.4, 0.8, 1.0, al), 6.0, true)
			draw_line(c, _pos(c, ea, R - 14), Color(0.4, 0.8, 1.0, al * 0.8), 2.0, true)
			info = "Eco del silbo"
		# línea de proa fija
		draw_colored_polygon(PackedVector2Array([c + Vector2(0, -R - 8), c + Vector2(-7, -R + 6), c + Vector2(7, -R + 6)]), BLOOD)
		draw_circle(c, 4, BRASS)
		var tw := F_UI_B.get_string_size(info, HORIZONTAL_ALIGNMENT_LEFT, -1, 15).x
		var tp := Vector2(c.x - tw / 2, c.y + R + 34)
		draw_string_outline(F_UI_B, tp, info, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, 6, Color(0, 0, 0, 0.75))
		draw_string(F_UI_B, tp, info, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, PAPER)


## Carta náutica de Canarias para la portada (pergamino, islas, rosa de los vientos).
class ChartMap extends Control:
	const LON0 := -19.0
	const LAT1 := 29.55
	const ISLANDS := {
		"La Graciosa": [[-13.53, 29.29], [-13.47, 29.27], [-13.48, 29.22], [-13.54, 29.24]],
		"Lanzarote": [[-13.47, 29.23], [-13.42, 29.18], [-13.45, 29.05], [-13.55, 28.98], [-13.62, 28.91], [-13.78, 28.84], [-13.87, 28.86], [-13.86, 28.97], [-13.76, 29.05], [-13.62, 29.13], [-13.53, 29.21]],
		"Fuerteventura": [[-13.87, 28.75], [-13.82, 28.6], [-13.84, 28.42], [-13.9, 28.3], [-14.02, 28.21], [-14.2, 28.13], [-14.38, 28.05], [-14.5, 28.07], [-14.47, 28.11], [-14.3, 28.16], [-14.2, 28.24], [-14.08, 28.38], [-14.03, 28.55], [-13.98, 28.7], [-13.92, 28.76]],
		"Gran Canaria": [[-15.68, 28.16], [-15.52, 28.18], [-15.42, 28.1], [-15.37, 27.95], [-15.42, 27.83], [-15.57, 27.74], [-15.7, 27.77], [-15.81, 27.86], [-15.83, 28.0], [-15.76, 28.1]],
		"Tenerife": [[-16.92, 28.37], [-16.74, 28.38], [-16.55, 28.42], [-16.4, 28.49], [-16.22, 28.56], [-16.13, 28.57], [-16.2, 28.5], [-16.35, 28.37], [-16.45, 28.24], [-16.55, 28.1], [-16.66, 28.01], [-16.75, 28.05], [-16.83, 28.18], [-16.92, 28.3]],
		"La Gomera": [[-17.33, 28.2], [-17.2, 28.21], [-17.1, 28.12], [-17.12, 28.05], [-17.22, 28.01], [-17.32, 28.06], [-17.35, 28.13]],
		"La Palma": [[-17.9, 28.84], [-17.77, 28.85], [-17.73, 28.74], [-17.76, 28.6], [-17.8, 28.5], [-17.85, 28.46], [-17.88, 28.55], [-17.93, 28.68], [-17.98, 28.78]],
		"El Hierro": [[-18.16, 27.72], [-18.05, 27.76], [-17.95, 27.84], [-17.88, 27.81], [-17.92, 27.72], [-17.99, 27.65], [-18.05, 27.7]],
	}
	const BORONDON := [[-18.78, 28.88], [-18.62, 28.9], [-18.55, 28.8], [-18.6, 28.68], [-18.72, 28.66], [-18.82, 28.76]]
	var t := 0.0
	var here := Vector2.ZERO      # lon, lat de tu barco (0 = no se muestra)
	var goal := Vector2.ZERO      # lon, lat del próximo destino
	var goal_name := ""
	var full := false             # true: ocupa todo el ancho (mapa del juego)
	var k := 200.0
	var ox := 520.0
	var oy := 240.0

	func _process(dt: float) -> void:
		t += dt
		queue_redraw()

	func P(lon: float, lat: float) -> Vector2:
		return Vector2(ox + (lon - LON0) * 0.879 * k, oy + (LAT1 - lat) * k)

	func _poly(pts: Array) -> PackedVector2Array:
		var out := PackedVector2Array()
		for q in pts:
			out.append(P(q[0], q[1]))
		return out

	func _draw() -> void:
		var W := size.x
		var H := size.y
		# encaja la carta en la parte derecha de la pantalla
		var mw: float = W * (0.9 if full else 0.64)
		k = min(mw / (5.85 * 0.879), H * 0.82 / 2.1)
		mw = k * 5.85 * 0.879
		ox = (W - mw) / 2.0 if full else W - mw - W * 0.03
		oy = (H - 2.1 * k) / 2.0
		# pergamino
		draw_rect(Rect2(Vector2.ZERO, size), Color("d6c49b"))
		for i in 18:
			var a: float = 0.05 + 0.03 * sin(i * 1.3)
			draw_rect(Rect2(0, H * i / 18.0, W, H / 18.0 + 1), Color(0.45, 0.32, 0.18, a))
		# olas dibujadas a pluma
		var ink := Color("3b2c20")
		for j in 22:
			for i in 30:
				var x: float = fmod(i * 61.0 + j * 37.0 + t * 6.0, W + 60.0) - 30.0
				var y: float = j * H / 22.0 + 14.0 + sin(i * 2.1 + j) * 6.0
				draw_arc(Vector2(x, y), 6.0, PI * 1.15, PI * 1.85, 6, Color(ink, 0.12), 1.2, true)
		# meridianos y paralelos
		for lon in range(-19, -12):
			var a := P(lon, 29.55)
			var b := P(lon, 27.45)
			draw_dashed_line(a, b, Color(ink, 0.18), 1.0, 6.0)
			draw_string(F_UI, b + Vector2(4, -6), "%d°O" % -lon, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(ink, 0.45))
		for lat in [28.0, 29.0]:
			var a := P(-19.0, lat)
			var b := P(-13.15, lat)
			draw_dashed_line(a, b, Color(ink, 0.18), 1.0, 6.0)
			draw_string(F_UI, b + Vector2(-34, -6), "%d°N" % int(lat), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(ink, 0.45))
		# ruta de Güímar a Las Palmas
		var gu := P(-16.37, 28.29)
		var lp := P(-15.42, 28.14)
		draw_dashed_line(gu, lp, Color(BLOOD, 0.7), 2.0, 8.0)
		# islas
		var land := Color("b9a274")
		for name in ISLANDS:
			var poly := _poly(ISLANDS[name])
			var shadow := PackedVector2Array()
			for q in poly:
				shadow.append(q + Vector2(3, 4))
			draw_colored_polygon(shadow, Color(ink, 0.25))
			draw_colored_polygon(poly, land)
			var outline := poly.duplicate()
			outline.append(poly[0])
			draw_polyline(outline, ink, 2.0, true)
			# segunda línea de costa, como en las cartas antiguas
			var c := Vector2.ZERO
			for q in poly:
				c += q
			c /= poly.size()
			var inner := PackedVector2Array()
			for q in outline:
				inner.append(q.lerp(c, 0.12))
			draw_polyline(inner, Color(ink, 0.35), 1.0, true)
			var fs := 18 if name != "La Graciosa" else 13
			var tw := F_TITLE.get_string_size(name, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
			var minp := poly[0]
			var maxp := poly[0]
			for q in poly:
				minp = Vector2(min(minp.x, q.x), min(minp.y, q.y))
				maxp = Vector2(max(maxp.x, q.x), max(maxp.y, q.y))
			var lab := Vector2(c.x - tw / 2, minp.y - 10)   # encima de la isla
			if name in ["Fuerteventura", "Lanzarote", "La Graciosa"]:
				lab = Vector2(maxp.x + 10, c.y + 6)            # a la derecha
			elif name in ["Gran Canaria", "El Hierro", "La Gomera"]:
				lab = Vector2(c.x - tw / 2, maxp.y + 22)       # debajo
			var off := lab - c
			draw_string(F_TITLE, c + off, name, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, ink)
		# el Teide
		var te := P(-16.64, 28.27)
		draw_colored_polygon(PackedVector2Array([te + Vector2(-16, 10), te + Vector2(0, -18), te + Vector2(16, 10)]), Color("6b5040"))
		draw_colored_polygon(PackedVector2Array([te + Vector2(-5, -10), te + Vector2(0, -18), te + Vector2(5, -10)]), Color("f1ece0"))
		draw_string(F_HAND, te + Vector2(-16, 28), "Teide", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, ink)
		# puertos
		for pt in [[gu, "Güímar"], [lp, "Las Palmas"]]:
			draw_circle(pt[0], 5, BLOOD)
			draw_circle(pt[0], 2, PAPER)
			draw_string(F_HAND, pt[0] + Vector2(8, 18), pt[1], HORIZONTAL_ALIGNMENT_LEFT, -1, 20, BLOOD.darkened(0.3))
		# barquito sobre la ruta
		var bk: float = 0.5 + 0.5 * sin(t * 0.25)
		var bp := gu.lerp(lp, bk)
		draw_colored_polygon(PackedVector2Array([bp + Vector2(-9, 0), bp + Vector2(9, 0), bp + Vector2(6, 5), bp + Vector2(-6, 5)]), ink)
		draw_line(bp, bp + Vector2(0, -12), ink, 1.5)
		draw_colored_polygon(PackedVector2Array([bp + Vector2(1, -12), bp + Vector2(8, -3), bp + Vector2(1, -3)]), PAPER)
		# San Borondón, la isla que aparece y desaparece
		var ga: float = 0.25 + 0.25 * sin(t * 0.7)
		var sb := _poly(BORONDON)
		draw_colored_polygon(sb, Color(Color("6f8f7a"), ga * 0.6))
		var so := sb.duplicate()
		so.append(sb[0])
		for i in so.size() - 1:
			draw_dashed_line(so[i], so[i + 1], Color(ink, ga + 0.2), 1.5, 5.0)
		var sc := P(-18.68, 28.78)
		draw_string(F_HAND, sc + Vector2(-58, 52), "¿San Borondón?", HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color(ink, ga + 0.35))
		# marcas del mapa del juego
		if goal != Vector2.ZERO:
			var gp := P(goal.x, goal.y)
			for i in 10:
				var a := i * TAU / 10.0 - PI / 2
				var r := 14.0 if i % 2 == 0 else 6.0
				var a2 := (i + 1) * TAU / 10.0 - PI / 2
				var r2 := 14.0 if (i + 1) % 2 == 0 else 6.0
				draw_colored_polygon(PackedVector2Array([gp, gp + Vector2(cos(a), sin(a)) * r, gp + Vector2(cos(a2), sin(a2)) * r2]), SUN.darkened(0.15))
			draw_string(F_HAND, gp + Vector2(16, -10), goal_name, HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color("8a5a10"))
		if here != Vector2.ZERO:
			var hp := P(here.x, here.y)
			var pulse := 0.5 + 0.5 * sin(t * 4.0)
			draw_arc(hp, 10 + pulse * 8, 0, TAU, 24, Color(BLOOD, 1.0 - pulse * 0.7), 2.5, true)
			draw_circle(hp, 6, BLOOD)
			draw_string(F_HAND, hp + Vector2(14, 40), "Estás aquí", HORIZONTAL_ALIGNMENT_LEFT, -1, 24, BLOOD.darkened(0.25))
		# rosa de los vientos
		var rc := Vector2(W - 120, H - 130)
		for i in 8:
			var a := i * TAU / 8.0 - PI / 2
			var r := 62.0 if i % 2 == 0 else 38.0
			var tip := rc + Vector2(cos(a), sin(a)) * r
			var l := rc + Vector2(cos(a - 0.35), sin(a - 0.35)) * 12.0
			var rr := rc + Vector2(cos(a + 0.35), sin(a + 0.35)) * 12.0
			draw_colored_polygon(PackedVector2Array([rc, l, tip]), ink if i % 2 == 0 else Color(ink, 0.6))
			draw_colored_polygon(PackedVector2Array([rc, tip, rr]), BRASS if i % 2 == 0 else PAPER)
		draw_arc(rc, 48, 0, TAU, 40, Color(ink, 0.6), 1.5, true)
		draw_string(F_TITLE, rc + Vector2(-7, -70), "N", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, ink)
		# cartela
		draw_string(F_TITLE_R, Vector2(ox + 10, oy + 2.1 * k + 30), "CARTA DE LAS YSLAS AFORTUNADAS · MAR DE MAGEC", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(ink, 0.7))
		# viñeta
		for i in 10:
			draw_rect(Rect2(Vector2.ZERO, size).grow(-i * 6), Color(0.2, 0.12, 0.05, 0.06), false, 12.0)

func _build_menu(root: Control) -> void:
	menu_layer = Control.new()
	menu_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	menu_layer.visible = false
	root.add_child(menu_layer)
	var chart := ChartMap.new()
	chart.set_anchors_preset(Control.PRESET_FULL_RECT)
	chart.mouse_filter = Control.MOUSE_FILTER_IGNORE
	menu_layer.add_child(chart)
	# degradado oscuro a la izquierda para leer el título
	var grad := Gradient.new()
	grad.set_color(0, Color(0.09, 0.05, 0.03, 0.95))
	grad.set_color(1, Color(0.09, 0.05, 0.03, 0.0))
	var gt := GradientTexture2D.new()
	gt.gradient = grad
	gt.fill_from = Vector2(0, 0)
	gt.fill_to = Vector2(1, 0)
	var shade := TextureRect.new()
	shade.texture = gt
	shade.stretch_mode = TextureRect.STRETCH_SCALE
	shade.set_anchors_preset(Control.PRESET_LEFT_WIDE)
	shade.offset_right = 640
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	menu_layer.add_child(shade)

	var vb := VBoxContainer.new()
	vb.position = Vector2(110, 150)
	vb.add_theme_constant_override("separation", 6)
	menu_layer.add_child(vb)
	var title := _label("MAGEC", 150, SUN, F_TITLE)
	title.add_theme_constant_override("outline_size", 14)
	title.add_theme_color_override("font_outline_color", Color(0.25, 0.12, 0.0, 0.7))
	vb.add_child(title)
	vb.add_child(_label("Pesca y terror en las Islas Canarias", 24, PAPER, F_TITLE_R))
	var sp := Control.new()
	sp.custom_minimum_size = Vector2(0, 50)
	vb.add_child(sp)
	menu_buttons = VBoxContainer.new()
	menu_buttons.add_theme_constant_override("separation", 4)
	vb.add_child(menu_buttons)
	menu_confirm = HBoxContainer.new()
	menu_confirm.add_theme_constant_override("separation", 12)
	menu_confirm.visible = false
	vb.add_child(menu_confirm)
	menu_confirm.add_child(_label("Esto borrará tu partida guardada.", 18, SALT))
	menu_confirm.add_child(_button("Empezar de nuevo", func(): main.new_game(), true))
	menu_confirm.add_child(_button("Cancelar", func(): menu_confirm.visible = false))

	var foot := _label("Güímar, Tenerife  ·  versión de desarrollo", 14, SALT)
	foot.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	foot.grow_vertical = Control.GROW_DIRECTION_BEGIN
	foot.offset_left = 110
	foot.offset_bottom = -40
	menu_layer.add_child(foot)


func open_menu(has_save: bool) -> void:
	intro.visible = false
	for c in menu_buttons.get_children():
		c.queue_free()
	if has_save:
		menu_buttons.add_child(_menu_button("Continuar", func(): main.continue_game()))
	menu_buttons.add_child(_menu_button("Nueva partida", func():
		if has_save:
			menu_confirm.visible = true
		else:
			main.new_game()))
	menu_buttons.add_child(_menu_button("Opciones", open_options))
	menu_buttons.add_child(_menu_button("Salir", func(): get_tree().quit()))
	menu_layer.visible = true


func _build_pause(root: Control) -> void:
	pause_panel = _center_panel(root, 380)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 10)
	pause_panel.add_child(vb)
	vb.add_child(Plaque.new("PAUSA", 22))
	for b in [
		_button("Continuar", close_pause, true),
		_button("Guardar partida", func():
			main.save_game()
			toast("Partida guardada.")),
		_button("Opciones", open_options),
		_button("Guardar y volver al menú", func():
			main.save_game()
			main.to_main_menu()),
		_button("Guardar y salir", func():
			main.save_game()
			get_tree().quit()),
	]:
		b.custom_minimum_size = Vector2(0, 44)
		vb.add_child(b)


func open_pause() -> void:
	hold_panel.visible = false
	get_tree().paused = true
	pause_panel.visible = true


func close_pause() -> void:
	pause_panel.visible = false
	options_panel.visible = false
	get_tree().paused = false


func _slider_row(vb: VBoxContainer, title: String, key: String) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	vb.add_child(row)
	var l := _label(title, 18, FOAM, F_TITLE_R)
	l.custom_minimum_size = Vector2(170, 0)
	row.add_child(l)
	var s := HSlider.new()
	s.min_value = 0.0
	s.max_value = 1.0
	s.step = 0.05
	s.value = opt[key]
	s.custom_minimum_size = Vector2(240, 24)
	s.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	s.value_changed.connect(func(v):
		opt[key] = v
		_apply_options()
		_save_options())
	row.add_child(s)


func _build_options(root: Control) -> void:
	options_panel = _center_panel(root, 480)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 14)
	options_panel.add_child(vb)
	vb.add_child(Plaque.new("OPCIONES", 22))
	_slider_row(vb, "Volumen general", "master")
	_slider_row(vb, "Música", "music")
	_slider_row(vb, "Efectos y mar", "sfx")
	var qrow := HBoxContainer.new()
	qrow.add_theme_constant_override("separation", 14)
	var ql := _label("Calidad gráfica", 18, FOAM, F_TITLE_R)
	ql.custom_minimum_size = Vector2(170, 0)
	qrow.add_child(ql)
	var qo := OptionButton.new()
	for q in ["Baja (ordenadores modestos)", "Media", "Alta"]:
		qo.add_item(q)
	qo.selected = int(opt["quality"])
	qo.item_selected.connect(func(i):
		opt["quality"] = i
		_apply_options()
		_save_options())
	qrow.add_child(qo)
	vb.add_child(qrow)
	var drow := HBoxContainer.new()
	drow.add_theme_constant_override("separation", 14)
	var dl := _label("Dificultad", 18, FOAM, F_TITLE_R)
	dl.custom_minimum_size = Vector2(170, 0)
	drow.add_child(dl)
	var dopt := OptionButton.new()
	for q in ["Relajada", "Normal", "Difícil"]:
		dopt.add_item(q)
	dopt.selected = int(opt["difficulty"])
	dopt.item_selected.connect(func(i):
		opt["difficulty"] = i
		_save_options())
	drow.add_child(dopt)
	vb.add_child(drow)
	var tu := CheckButton.new()
	tu.text = "Consejos del tutorial"
	tu.add_theme_font_override("font", F_TITLE_R)
	tu.add_theme_font_size_override("font_size", 18)
	tu.button_pressed = opt["tutorial"]
	tu.toggled.connect(func(on):
		opt["tutorial"] = on
		_save_options())
	vb.add_child(tu)
	var fs := CheckButton.new()
	fs.text = "Pantalla completa"
	fs.add_theme_font_override("font", F_TITLE_R)
	fs.add_theme_font_size_override("font_size", 18)
	fs.button_pressed = opt["fullscreen"]
	fs.toggled.connect(func(on):
		opt["fullscreen"] = on
		_apply_options()
		_save_options())
	vb.add_child(fs)
	var b := _button("Volver", func(): options_panel.visible = false, true)
	b.size_flags_horizontal = Control.SIZE_SHRINK_END
	vb.add_child(b)


func open_options() -> void:
	options_panel.visible = true


func _load_options() -> void:
	var cf := ConfigFile.new()
	if cf.load(OPT_PATH) == OK:
		for k in opt.keys():
			opt[k] = cf.get_value("opciones", k, opt[k])
	else:
		# primera vez: en gráficas integradas (portátiles, oficina) empieza en calidad baja
		var gpu := RenderingServer.get_video_adapter_name().to_lower()
		for weak in ["intel", "uhd", "iris", "llvmpipe", "vega 8", "radeon(tm) graphics", "microsoft basic"]:
			if gpu.contains(weak):
				opt["quality"] = 0
	_apply_options()
	# refrescar controles con los valores cargados
	options_panel.queue_free()
	_build_options(options_panel.get_parent())


func _save_options() -> void:
	var cf := ConfigFile.new()
	for k in opt.keys():
		cf.set_value("opciones", k, opt[k])
	cf.save(OPT_PATH)


func _apply_options() -> void:
	AudioServer.set_bus_volume_db(0, linear_to_db(max(opt["master"], 0.0001)))
	for pair in [["Musica", "music"], ["Efectos", "sfx"]]:
		var i := AudioServer.get_bus_index(pair[0])
		if i != -1:
			AudioServer.set_bus_volume_db(i, linear_to_db(max(opt[pair[1]], 0.0001)))
	apply_quality(int(opt["quality"]))
	var want := DisplayServer.WINDOW_MODE_FULLSCREEN if opt["fullscreen"] else DisplayServer.WINDOW_MODE_WINDOWED
	if DisplayServer.window_get_mode() != want and DisplayServer.get_name() != "headless":
		DisplayServer.window_set_mode(want)


func apply_quality(q: int) -> void:
	## 0 = baja, 1 = media, 2 = alta. Cambia los efectos más caros.
	if main == null or main.env == null:
		return
	var env: Environment = main.env
	env.volumetric_fog_enabled = q >= 2
	env.ssil_enabled = q >= 2
	env.ssao_enabled = q >= 1
	env.glow_enabled = q >= 1
	var vp := get_viewport()
	vp.scaling_3d_scale = 0.7 if q == 0 else 1.0
	vp.msaa_3d = Viewport.MSAA_DISABLED if q == 0 else (Viewport.MSAA_2X if q == 1 else Viewport.MSAA_4X)
	if q == 0:
		vp.screen_space_aa = Viewport.SCREEN_SPACE_AA_FXAA
	else:
		vp.screen_space_aa = Viewport.SCREEN_SPACE_AA_DISABLED
	main.sun.directional_shadow_max_distance = 70.0 if q == 0 else (140.0 if q == 1 else 220.0)
	main.sun.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL if q == 0 else DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
	if main.lamp_light:
		main.lamp_light.shadow_enabled = q >= 1


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_ESCAPE:
		if options_panel.visible:
			options_panel.visible = false
			get_viewport().set_input_as_handled()
		elif pause_panel.visible:
			close_pause()
			get_viewport().set_input_as_handled()
