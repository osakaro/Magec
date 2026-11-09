extends Node
## Sonido de MAGEC: ambiente (mar, viento, motor, música de día y de noche,
## latido con el miedo) y efectos sueltos.

var main

const LOOPS := ["ocean", "wind", "engine", "heartbeat", "day_music", "night_drone"]
var loops := {}
var level := {}   # volumen lineal actual de cada bucle


func _ready() -> void:
	for bus in ["Musica", "Efectos"]:
		if AudioServer.get_bus_index(bus) == -1:
			AudioServer.add_bus()
			var i := AudioServer.bus_count - 1
			AudioServer.set_bus_name(i, bus)
			AudioServer.set_bus_send(i, "Master")
	for n in LOOPS:
		var p := AudioStreamPlayer.new()
		p.bus = "Musica" if n in ["day_music", "night_drone"] else "Efectos"
		p.stream = load("res://audio/%s.wav" % n)
		p.volume_db = -80.0
		add_child(p)
		p.finished.connect(p.play)
		p.play()
		loops[n] = p
		level[n] = 0.0
	if main and main.ui:
		main.ui._apply_options()


func sfx(name: String, vol_db := 0.0, pitch := 1.0) -> void:
	var p := AudioStreamPlayer.new()
	p.stream = load("res://audio/%s.wav" % name)
	p.volume_db = vol_db
	p.pitch_scale = pitch
	p.bus = "Efectos"
	add_child(p)
	p.finished.connect(p.queue_free)
	p.play()


func _vol(name: String, target: float, dt: float, speed := 1.5) -> void:
	level[name] = move_toward(level[name], target, dt * speed)
	loops[name].volume_db = linear_to_db(max(level[name], 0.0001))


func _process(dt: float) -> void:
	if main == null:
		return
	var l: float = main.daylight()
	var cine: bool = main.mode == "cinematic" or main.mode == "menu"
	var vmax: float = 9.0 + main.speed_lvl * 3.5
	var spd: float = clamp(abs(main.bv) / vmax, 0.0, 1.0)

	_vol("ocean", 0.55, dt)
	_vol("wind", 0.18 + (1.0 - l) * 0.25 + main.panic / 100.0 * 0.2, dt)
	_vol("engine", 0.0 if cine else 0.06 + spd * 0.4, dt, 2.0)
	loops["engine"].pitch_scale = 0.8 + spd * 0.5
	_vol("day_music", 0.0 if cine or main.panic > 30.0 else clamp((l - 0.4) * 2.0, 0.0, 1.0) * 0.35, dt, 0.3)
	_vol("night_drone", clamp((0.5 - l) * 2.0, 0.0, 1.0) * (0.25 if cine else 0.4), dt, 0.3)
	_vol("heartbeat", clamp((main.panic - 45.0) / 50.0, 0.0, 1.0) * 0.9, dt)
	loops["heartbeat"].pitch_scale = 0.9 + main.panic / 160.0
