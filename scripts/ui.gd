extends CanvasLayer
## Interfaz de MAGEC: HUD, intro, minijuego de pesca, captura, bodega y puerto.

const Data = preload("res://scripts/data.gd")

const C_ABYSS := Color("071219")
const C_DEEP := Color("0f2430")
const C_FOAM := Color("e7efe9")
const C_SALT := Color("9fb3b4")
const C_SUN := Color("f2b33d")
const C_BLOOD := Color("d2453a")
const C_KELP := Color("6fae7d")

var main  # referencia a main.gd

var clock_lbl: Label
var day_lbl: Label
var money_lbl: Label
var debt_lbl: Label
var panic_bar: ProgressBar
var panic_lbl: Label
var hint_lbl: RichTextLabel
var toast_lbl: Label
var toast_time := 0.0
var vignette: ColorRect

var intro: Control
var fish_panel: PanelContainer
var fish_title: Label
var fish_bar: FishBar
var catch_panel: PanelContainer
var catch_icon: FishIcon
var catch_name: Label
var catch_desc: Label
var keep_btn: Button
var hold_panel: PanelContainer
var hold_grid: HoldGrid
var hold_info: Label
var drop_btn: Button
var port_panel: PanelContainer
var port_list: VBoxContainer


# ================= Controles dibujados a mano =================

static func draw_fish(ci: CanvasItem, rect: Rect2, color: Color, mut: bool, vertical: bool) -> void:
	var w := rect.size.x
	var h := rect.size.y
	var o := rect.position
	if vertical:
		# Dibuja en horizontal dentro de un rectángulo girado.
		ci.draw_set_transform(o + Vector2(w, 0), PI / 2, Vector2.ONE)
		var tmp := w
		w = h
		h = tmp
		o = Vector2.ZERO
	var cx := o.x + w * 0.46
	var cy := o.y + h / 2.0
	var rx := w * 0.34
	var ry := h * 0.3
	var col := color
	if mut:
		col = color.lerp(Color("4a5f3a"), 0.45)
	ci.draw_colored_polygon(PackedVector2Array([Vector2(cx + rx * 0.85, cy), Vector2(o.x + w * 0.96, cy - ry * 1.1), Vector2(o.x + w * 0.96, cy + ry * 1.1)]), col)
	var pts := PackedVector2Array()
	for i in 24:
		var a := TAU * i / 24.0
		pts.append(Vector2(cx + cos(a) * rx, cy + sin(a) * ry))
	ci.draw_colored_polygon(pts, col)
	var belly := PackedVector2Array()
	for i in 16:
		var a := TAU * i / 16.0
		belly.append(Vector2(cx + cos(a) * rx * 0.8, cy + ry * 0.35 + sin(a) * ry * 0.35))
	ci.draw_colored_polygon(belly, Color(1, 1, 1, 0.18))
	if mut:
		var dark := col.darkened(0.4)
		for i in 7:
			var px := cx - rx * 0.6 + i * rx * 0.2
			ci.draw_colored_polygon(PackedVector2Array([Vector2(px - 4, cy - ry * 0.9), Vector2(px, cy - ry * 1.5), Vector2(px + 4, cy - ry * 0.9)]), dark)
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


class FishIcon extends Control:
	var key := ""
	var mut := false
	func _draw() -> void:
		if key == "":
			return
		draw_rect(Rect2(Vector2.ZERO, size), Color("0c1d27"))
		var r := Rect2(size.x * 0.25, 0, size.x * 0.5, size.y)
		owner_ui().draw_fish(self, r, Data.FISH[key]["c"], mut, false)
	func owner_ui():
		return load("res://scripts/ui.gd")


class FishBar extends Control:
	var game
	func _draw() -> void:
		draw_rect(Rect2(Vector2.ZERO, size), Color("0c1d27"))
		if game == null or game.fishing.is_empty():
			return
		var f: Dictionary = game.fishing
		draw_rect(Rect2(f["zs"] * size.x, 0, f["w"] * size.x, size.y), Color(0.43, 0.68, 0.49, 0.6))
		var x: float = f["p"] * size.x
		draw_rect(Rect2(x - 2, -4, 4, size.y + 8), Color("f2b33d"))
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.62, 0.7, 0.7, 0.4), false, 1.0)
	func _gui_input(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed:
			game.strike()


class HoldGrid extends Control:
	const CELL := 44.0
	const GAP := 3.0
	var game
	var sel := -1
	var on_select: Callable
	func refresh() -> void:
		custom_minimum_size = Vector2(game.cols * (CELL + GAP) + GAP, game.rows * (CELL + GAP) + GAP)
		if sel >= game.items.size():
			sel = -1
		queue_redraw()
	func _draw() -> void:
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.62, 0.7, 0.7, 0.15))
		for r in game.rows:
			for c in game.cols:
				draw_rect(Rect2(GAP + c * (CELL + GAP), GAP + r * (CELL + GAP), CELL, CELL), Color("0c1d27"))
		var i := 0
		for it in game.items:
			var sh: Array = it["shape"]
			var rect := Rect2(GAP + it["c"] * (CELL + GAP), GAP + it["r"] * (CELL + GAP), sh[0].size() * (CELL + GAP) - GAP, sh.size() * (CELL + GAP) - GAP)
			draw_rect(rect, Color(0.82, 0.27, 0.23, 0.22) if it["mut"] else Color(0.43, 0.68, 0.49, 0.18))
			load("res://scripts/ui.gd").draw_fish(self, rect.grow(-3), Data.FISH[it["key"]]["c"], it["mut"], sh.size() > sh[0].size())
			if i == sel:
				draw_rect(rect, Color("f2b33d"), false, 2.0)
			i += 1
	func _gui_input(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			var c := int((event.position.x - GAP) / (CELL + GAP))
			var r := int((event.position.y - GAP) / (CELL + GAP))
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


# ================= Construcción =================

func _ready() -> void:
	var theme := Theme.new()
	theme.default_font_size = 18
	var panel_sb := StyleBoxFlat.new()
	panel_sb.bg_color = Color(C_ABYSS, 0.94)
	panel_sb.border_color = Color(C_SALT, 0.3)
	panel_sb.set_border_width_all(1)
	panel_sb.set_corner_radius_all(10)
	panel_sb.set_content_margin_all(18)
	theme.set_stylebox("panel", "PanelContainer", panel_sb)
	var btn := StyleBoxFlat.new()
	btn.bg_color = C_DEEP
	btn.border_color = Color(C_SALT, 0.35)
	btn.set_border_width_all(1)
	btn.set_corner_radius_all(6)
	btn.set_content_margin_all(10)
	var btn_h := btn.duplicate()
	btn_h.bg_color = C_DEEP.lightened(0.15)
	var btn_d := btn.duplicate()
	btn_d.bg_color = Color(C_DEEP, 0.4)
	theme.set_stylebox("normal", "Button", btn)
	theme.set_stylebox("hover", "Button", btn_h)
	theme.set_stylebox("pressed", "Button", btn_h)
	theme.set_stylebox("disabled", "Button", btn_d)
	theme.set_stylebox("focus", "Button", StyleBoxEmpty.new())
	theme.set_color("font_color", "Button", C_FOAM)
	theme.set_color("font_color", "Label", C_FOAM)
	var bar_bg := StyleBoxFlat.new()
	bar_bg.bg_color = Color(1, 1, 1, 0.08)
	bar_bg.set_corner_radius_all(4)
	var bar_fg := StyleBoxFlat.new()
	bar_fg.bg_color = C_BLOOD
	bar_fg.set_corner_radius_all(4)
	theme.set_stylebox("background", "ProgressBar", bar_bg)
	theme.set_stylebox("fill", "ProgressBar", bar_fg)

	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.theme = theme
	add_child(root)

	vignette = ColorRect.new()
	vignette.set_anchors_preset(Control.PRESET_FULL_RECT)
	vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var vs := Shader.new()
	vs.code = "shader_type canvas_item; uniform float amount = 0.0; void fragment(){ float d = distance(UV, vec2(0.5)); COLOR = vec4(0.5, 0.03, 0.03, smoothstep(0.35, 0.75, d) * amount); }"
	var vm := ShaderMaterial.new()
	vm.shader = vs
	vignette.material = vm
	root.add_child(vignette)

	_build_hud(root)
	_build_fishing(root)
	_build_catch(root)
	_build_hold(root)
	_build_port(root)
	_build_intro(root)


func _chip(parent: Control) -> VBoxContainer:
	var pc := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(C_ABYSS, 0.72)
	sb.border_color = Color(C_SALT, 0.25)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(6)
	sb.set_content_margin_all(10)
	pc.add_theme_stylebox_override("panel", sb)
	pc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(pc)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 2)
	pc.add_child(vb)
	return vb


func _label(text: String, size := 18, color := C_FOAM) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l


func _button(text: String, cb: Callable, primary := false) -> Button:
	var b := Button.new()
	b.text = text
	b.pressed.connect(cb)
	if primary:
		var sb := StyleBoxFlat.new()
		sb.bg_color = C_SUN
		sb.set_corner_radius_all(6)
		sb.set_content_margin_all(12)
		b.add_theme_stylebox_override("normal", sb)
		b.add_theme_stylebox_override("hover", sb)
		b.add_theme_stylebox_override("pressed", sb)
		b.add_theme_color_override("font_color", C_ABYSS)
		b.add_theme_color_override("font_hover_color", C_ABYSS)
		b.add_theme_color_override("font_pressed_color", C_ABYSS)
	return b


func _center_panel(root: Control, width := 480) -> PanelContainer:
	var p := PanelContainer.new()
	p.set_anchors_preset(Control.PRESET_CENTER)
	p.custom_minimum_size = Vector2(width, 0)
	p.grow_horizontal = Control.GROW_DIRECTION_BOTH
	p.grow_vertical = Control.GROW_DIRECTION_BOTH
	p.visible = false
	root.add_child(p)
	return p


func _build_hud(root: Control) -> void:
	var top := HBoxContainer.new()
	top.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top.offset_left = 16
	top.offset_right = -16
	top.offset_top = 14
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(top)

	var c1 := _chip(top)
	clock_lbl = _label("07:00", 30)
	day_lbl = _label("Día 1", 13, C_SALT)
	c1.add_child(clock_lbl)
	c1.add_child(day_lbl)

	var sp1 := Control.new()
	sp1.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sp1.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.add_child(sp1)

	var c2 := _chip(top)
	var row := HBoxContainer.new()
	row.add_child(_label("MIEDO", 13, C_SALT))
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(sp)
	panic_lbl = _label("0%", 13, C_SALT)
	row.add_child(panic_lbl)
	c2.add_child(row)
	panic_bar = ProgressBar.new()
	panic_bar.custom_minimum_size = Vector2(200, 10)
	panic_bar.show_percentage = false
	c2.add_child(panic_bar)

	var sp2 := Control.new()
	sp2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sp2.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.add_child(sp2)

	var c3 := _chip(top)
	money_lbl = _label("0 €", 24, C_SUN)
	debt_lbl = _label("Deuda del barco: 500 €", 13, C_SALT)
	c3.add_child(money_lbl)
	c3.add_child(debt_lbl)

	hint_lbl = RichTextLabel.new()
	hint_lbl.bbcode_enabled = true
	hint_lbl.fit_content = true
	hint_lbl.scroll_active = false
	hint_lbl.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	hint_lbl.custom_minimum_size = Vector2(700, 0)
	hint_lbl.grow_horizontal = Control.GROW_DIRECTION_BOTH
	hint_lbl.grow_vertical = Control.GROW_DIRECTION_BEGIN
	hint_lbl.offset_bottom = -110
	hint_lbl.add_theme_font_size_override("normal_font_size", 20)
	hint_lbl.add_theme_constant_override("outline_size", 6)
	hint_lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	hint_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(hint_lbl)

	toast_lbl = _label("", 18)
	toast_lbl.set_anchors_preset(Control.PRESET_CENTER_TOP)
	toast_lbl.grow_horizontal = Control.GROW_DIRECTION_BOTH
	toast_lbl.offset_top = 110
	toast_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast_lbl.add_theme_constant_override("outline_size", 6)
	toast_lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	root.add_child(toast_lbl)

	var keys := _label("WASD / flechas: navegar   ·   E: acción   ·   F: farol   ·   I: bodega", 14, C_SALT)
	keys.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	keys.grow_horizontal = Control.GROW_DIRECTION_BOTH
	keys.grow_vertical = Control.GROW_DIRECTION_BEGIN
	keys.offset_bottom = -16
	keys.add_theme_constant_override("outline_size", 4)
	keys.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	root.add_child(keys)


func _build_fishing(root: Control) -> void:
	fish_panel = _center_panel(root)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 12)
	fish_panel.add_child(vb)
	fish_title = _label("Pescando…", 26)
	vb.add_child(fish_title)
	vb.add_child(_label("Pulsa Espacio (o haz clic) cuando la aguja esté en la zona verde.", 15, C_SALT))
	fish_bar = FishBar.new()
	fish_bar.game = main
	fish_bar.custom_minimum_size = Vector2(0, 36)
	vb.add_child(fish_bar)
	var row := HBoxContainer.new()
	vb.add_child(row)
	var dots := _label("", 16, C_SALT)
	dots.name = "Dots"
	dots.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(dots)
	row.add_child(_button("Recoger sedal", func(): main.end_fishing(false, true)))


func _build_catch(root: Control) -> void:
	catch_panel = _center_panel(root)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 10)
	catch_panel.add_child(vb)
	catch_icon = FishIcon.new()
	catch_icon.custom_minimum_size = Vector2(0, 130)
	vb.add_child(catch_icon)
	catch_name = _label("", 28)
	vb.add_child(catch_name)
	catch_desc = _label("", 16, C_SALT)
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
	hold_panel = PanelContainer.new()
	hold_panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	hold_panel.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	hold_panel.offset_right = -16
	hold_panel.offset_top = 110
	hold_panel.visible = false
	root.add_child(hold_panel)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 10)
	hold_panel.add_child(vb)
	vb.add_child(_label("Bodega", 26))
	vb.add_child(_label("Haz clic en un pez para seleccionarlo.", 14, C_SALT))
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
	hold_info = _label("", 15, C_SALT)
	row.add_child(hold_info)
	hold_grid.refresh()


func _build_port(root: Control) -> void:
	port_panel = _center_panel(root, 520)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 10)
	port_panel.add_child(vb)
	vb.add_child(_label("Puerto de Güímar", 28))
	vb.add_child(_label("Aquí estás a salvo. La luz del puerto calma el miedo.", 15, C_SALT))
	port_list = VBoxContainer.new()
	port_list.add_theme_constant_override("separation", 8)
	vb.add_child(port_list)
	vb.add_child(_button("Zarpar", func():
		port_panel.visible = false
		main.leave_port()))


func _build_intro(root: Control) -> void:
	intro = ColorRect.new()
	intro.color = Color(C_ABYSS, 0.92)
	intro.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(intro)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	intro.add_child(center)
	var vb := VBoxContainer.new()
	vb.custom_minimum_size = Vector2(620, 0)
	vb.add_theme_constant_override("separation", 14)
	center.add_child(vb)
	var title := _label("MAGEC", 110, C_SUN)
	vb.add_child(title)
	vb.add_child(_label("PROTOTIPO  ·  COSTA DE GÜÍMAR, TENERIFE", 14, C_SALT))
	for txt in [
		"Acorán es pescador en la caleta de Güímar, como su abuelo Aridane, que desapareció hace treinta años buscando San Borondón.",
		"Desde el temblor bajo el mar, lo que sale en las redes de noche ya no es normal. Chaxiraxi le ha dado un farol que, dice, guarda la luz de Magec.",
		"Debes 500 € del barco. Pesca de día. Si sales de noche, enciende el farol… y no te alejes demasiado del puerto.",
	]:
		var l := _label(txt, 18, Color("cdd9d4"))
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		vb.add_child(l)
	var ctr := _label("WASD o flechas para navegar · E junto a las burbujas para pescar · E en el muelle para vender · F farol · I bodega. El tiempo solo pasa cuando navegas o pescas.", 15, C_SALT)
	ctr.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vb.add_child(ctr)
	var b := _button("Zarpar", func():
		intro.visible = false
		main.mode = "sail"
		toast("Busca las burbujas en el agua para pescar."), true)
	b.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	b.custom_minimum_size = Vector2(160, 0)
	vb.add_child(b)


# ================= API usada por main.gd =================

func toast(text: String) -> void:
	toast_lbl.text = text
	toast_time = 2.8


func update_hud() -> void:
	var h: float = main.hour()
	clock_lbl.text = "%02d:%02d" % [int(h), int(fmod(main.game_time, 60.0))]
	day_lbl.text = "DÍA %d  ·  %s  ·  %s" % [main.day, "NOCHE" if main.is_night() else "DÍA", main.zone_name(main.bz).to_upper()]
	money_lbl.text = "%d €" % main.money
	debt_lbl.text = "Deuda del barco: %s" % ("%d €" % main.debt if main.debt > 0 else "pagada")
	panic_bar.value = main.panic
	panic_lbl.text = "%d%%" % int(main.panic)
	vignette.material.set_shader_parameter("amount", clamp((main.panic - 60.0) / 40.0, 0.0, 1.0))

	toast_time -= get_process_delta_time()
	toast_lbl.modulate.a = clamp(toast_time / 0.4, 0.0, 1.0)

	var hint := ""
	if main.mode == "sail":
		if main.near_port():
			hint = "[center][color=#f2b33d]E[/color] · Entrar al puerto de Güímar[/center]"
		else:
			var s = main.near_spot()
			if s != null:
				hint = "[center][color=#f2b33d]E[/color] · Pescar (%s)%s[/center]" % [Data.ZONES[s["zone"]]["name"], " — [color=#d2453a]de noche salen mutantes[/color]" if main.is_night() else ""]
			elif main.is_night() and not main.lamp_on:
				hint = "[center]Está oscuro. Pulsa [color=#f2b33d]F[/color] para encender el farol.[/center]"
	if hint_lbl.text != hint:
		hint_lbl.text = hint

	if fish_panel.visible:
		fish_bar.queue_redraw()
		var f: Dictionary = main.fishing
		if not f.is_empty():
			var dots: Label = fish_panel.find_child("Dots", true, false)
			dots.text = "Aciertos: %s   Fallos: %s" % ["●".repeat(f["hits"]) + "○".repeat(3 - f["hits"]), "✕".repeat(f["miss"]) + "·".repeat(3 - f["miss"])]


func open_fishing(title: String) -> void:
	hold_panel.visible = false
	fish_title.text = title
	fish_panel.visible = true


func close_fishing() -> void:
	fish_panel.visible = false


func open_catch(key: String, mut: bool, fits: bool) -> void:
	catch_icon.key = key
	catch_icon.mut = mut
	catch_icon.queue_redraw()
	catch_name.text = Data.fish_name(key, mut)
	catch_name.add_theme_color_override("font_color", C_BLOOD if mut else C_FOAM)
	catch_desc.text = "%s  ·  Valor: %d €" % [Data.FISH[key]["md"] if mut else Data.FISH[key]["d"], Data.fish_value(key, mut)]
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


func _port_line(title: String, sub: String, btn_text: String, disabled: bool, cb: Callable) -> void:
	var pc := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("0c1d27")
	sb.set_corner_radius_all(6)
	sb.set_content_margin_all(10)
	pc.add_theme_stylebox_override("panel", sb)
	port_list.add_child(pc)
	var row := HBoxContainer.new()
	pc.add_child(row)
	var vb := VBoxContainer.new()
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.add_child(_label(title, 18))
	vb.add_child(_label(sub, 14, C_SALT))
	row.add_child(vb)
	var b := _button(btn_text, func():
		cb.call()
		_render_port())
	b.disabled = disabled
	row.add_child(b)


func _render_port() -> void:
	for c in port_list.get_children():
		c.queue_free()
	var total: int = main.hold_value()
	_port_line("Vender la pesca", "%d peces en la bodega" % main.items.size(), "+%d €" % total, total == 0, main.sell_all)
	_port_line("Pagar deuda del barco", "Quedan %d €" % main.debt if main.debt > 0 else "Pagada", "Pagar", main.money <= 0 or main.debt <= 0, main.pay_debt)
	if main.speed_lvl < 2:
		_port_line("Motor nuevo", "Navegas más rápido", "%d €" % main.engine_price(), main.money < main.engine_price(), main.buy_engine)
	if main.rows < 5:
		_port_line("Ampliar bodega", "Una fila más de espacio", "%d €" % main.hold_price(), main.money < main.hold_price(), main.buy_hold)
	if main.is_night():
		_port_line("Dormir hasta el amanecer", "Pasa la noche en casa", "Dormir", false, main.sleep)
	refresh_hold()
