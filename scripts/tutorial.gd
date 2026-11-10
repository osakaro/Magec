extends Node
## Tutorial suave: carteles que enseñan lo básico la primera vez que juegas.
## Cada paso se completa haciendo lo que pide. Se puede desactivar en Opciones.

var main
var step := 0
var done := false
var start_pos := Vector2.ZERO
var saw_hold := false
var night_tip := false
var shown := ""

# [tecla, texto]
const STEPS := [
	["WASD", "Navega con W A S D. El barco tarda en girar: anticipa las curvas."],
	["E", "Las burbujas en el agua son bancos de peces. Acércate a unas y pulsa E para pescar."],
	["Espacio", "Pulsa Espacio cuando el corcho esté sobre el agua dorada. Tres aciertos y es tuyo."],
	["I", "Pulsa I para ver la bodega. Cada pez ocupa un hueco distinto, como un puzle."],
	["E", "Vuelve al muelle de Güímar y pulsa E para vender la pesca y pagar el barco."],
	["M", "La flecha dorada de la brújula señala tu encargo. Pulsa M para ver el mapa de las islas."],
]


func _ready() -> void:
	start_pos = Vector2(main.bx, main.bz)


func current() -> Array:
	if done or main.ui.opt.get("tutorial", true) == false:
		return []
	if night_tip:
		return ["F", "Ya es de noche. Enciende el farol con F: los Tibicenas odian la luz de Magec."]
	if step < STEPS.size():
		return STEPS[step]
	return []


func _advance() -> void:
	step += 1
	main.audio.sfx("hit", -10.0, 1.4)
	if step >= STEPS.size():
		done = true
		main.ui.toast("Tutorial completado. ¡Buena pesca!")
	main.save_game()


func _process(dt: float) -> void:
	if main == null or done or main.mode in ["menu", "cinematic"]:
		return
	# consejo nocturno, una sola vez
	if night_tip and (main.lamp_on or not main.is_night()):
		night_tip = false
	if main.is_night() and not main.lamp_on and not main.get_meta("night_tip_given", false):
		main.set_meta("night_tip_given", true)
		night_tip = true
	match step:
		0:
			if Vector2(main.bx, main.bz).distance_to(start_pos) > 15.0:
				_advance()
		1:
			if main.mode == "fish":
				_advance()
		2:
			if main.mode == "catch" or (main.mode == "sail" and main.items.size() > 0):
				_advance()
		3:
			if main.ui.hold_panel.visible:
				_advance()
		4:
			if main.mode == "port":
				_advance()
		5:
			if main.ui.map_panel.visible:
				_advance()


func to_dict() -> Dictionary:
	return {"step": step, "done": done}


func from_dict(d: Dictionary) -> void:
	step = int(d.get("step", 0))
	done = bool(d.get("done", false))
