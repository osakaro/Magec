extends Node
## Clima canario: despejado, calima, lluvia y mar picada.
## Cambia cada pocas horas de juego y se mezcla poco a poco.

var main

const STATES := {
	"despejado": {"name": "Despejado", "fog": 0.0, "tint": Color(0, 0, 0, 0), "amp": 1.0, "rain": 0.0, "sun": 1.0, "wind": 0.0},
	"calima": {"name": "Calima", "fog": 0.018, "tint": Color(0.82, 0.58, 0.34, 0.75), "amp": 0.8, "rain": 0.0, "sun": 0.7, "wind": 0.15},
	"lluvia": {"name": "Lluvia", "fog": 0.01, "tint": Color(0.35, 0.4, 0.45, 0.6), "amp": 1.45, "rain": 1.0, "sun": 0.45, "wind": 0.3},
	"niebla": {"name": "Niebla", "fog": 0.026, "tint": Color(0.78, 0.8, 0.82, 0.85), "amp": 0.85, "rain": 0.0, "sun": 0.55, "wind": 0.1},
	"picada": {"name": "Mar picada", "fog": 0.004, "tint": Color(0.45, 0.5, 0.55, 0.35), "amp": 2.1, "rain": 0.0, "sun": 0.8, "wind": 0.45},
}
const WEIGHTS := {"despejado": 50, "calima": 16, "lluvia": 18, "picada": 16, "niebla": 0}
# En La Gomera la niebla manda
const WEIGHTS_LG := {"despejado": 25, "calima": 0, "lluvia": 10, "picada": 10, "niebla": 55}

var current := "despejado"
var next_change := 10.0 * 60.0
var blend := {}   # valores mezclados actuales
var rain_fx: GPUParticles3D


func _ready() -> void:
	for k in ["fog", "amp", "rain", "sun", "wind"]:
		blend[k] = STATES["despejado"][k]
	blend["tint"] = Color(0, 0, 0, 0)
	# Lluvia: partículas que siguen a la cámara
	rain_fx = GPUParticles3D.new()
	rain_fx.amount = 1600
	rain_fx.lifetime = 1.2
	rain_fx.visibility_aabb = AABB(Vector3(-40, -30, -40), Vector3(80, 60, 80))
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = Vector3(35, 1, 35)
	pm.direction = Vector3(0.15, -1, 0)
	pm.spread = 4.0
	pm.initial_velocity_min = 28.0
	pm.initial_velocity_max = 34.0
	pm.gravity = Vector3(0, -20, 0)
	rain_fx.process_material = pm
	var drop := BoxMesh.new()
	drop.size = Vector3(0.03, 0.9, 0.03)
	var dm := StandardMaterial3D.new()
	dm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	dm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	dm.albedo_color = Color(0.75, 0.82, 0.9, 0.35)
	drop.material = dm
	rain_fx.draw_pass_1 = drop
	rain_fx.emitting = false
	main.add_child(rain_fx)


func _pick() -> String:
	var wts: Dictionary = WEIGHTS
	if main.region == "la_gomera":
		wts = WEIGHTS_LG
	elif main.region == "fuerteventura":
		wts = {"despejado": 35, "calima": 45, "lluvia": 5, "picada": 15, "niebla": 0}
	elif main.region == "el_hierro":
		wts = {"despejado": 70, "calima": 5, "lluvia": 10, "picada": 0, "niebla": 15}
	var total := 0
	for k in wts:
		total += wts[k]
	var r := randi() % total
	for k in wts:
		r -= wts[k]
		if r < 0:
			return k
	return "despejado"


func name_now() -> String:
	return STATES[current]["name"]


func _process(dt: float) -> void:
	if main == null or main.mode == "menu" or main.mode == "cinematic":
		return
	if main.game_time >= next_change:
		var prev := current
		current = _pick()
		# la calima no empieza de noche
		if current == "calima" and main.is_night():
			current = "despejado"
		next_change = main.game_time + randf_range(3.0, 7.0) * 60.0
		if current != prev:
			var msgs := {
				"despejado": "El cielo se despeja.",
				"calima": "Llega la calima. El aire se vuelve naranja y no se ve nada a lo lejos.",
				"lluvia": "Empieza a llover sobre el mar.",
				"picada": "Se levanta el viento. La mar se pica.",
				"niebla": "Baja la niebla de los barrancos. No se ve ni la proa.",
			}
			main.ui.toast(msgs[current])
	var st: Dictionary = STATES[current]
	var k := dt * 0.15
	for key in ["fog", "amp", "rain", "sun", "wind"]:
		blend[key] = lerp(float(blend[key]), float(st[key]), k)
	blend["tint"] = (blend["tint"] as Color).lerp(st["tint"], k)
	rain_fx.emitting = blend["rain"] > 0.3
	rain_fx.amount_ratio = clamp(blend["rain"], 0.0, 1.0)
	rain_fx.global_position = main.camera.global_position + Vector3(0, 18, 0) - main.camera.global_basis.z * 15.0


func to_dict() -> Dictionary:
	return {"current": current, "next_change": next_change}


func from_dict(d: Dictionary) -> void:
	current = str(d.get("current", "despejado"))
	if not STATES.has(current):
		current = "despejado"
	next_change = float(d.get("next_change", main.game_time + 300.0))
	var st: Dictionary = STATES[current]
	for key in ["fog", "amp", "rain", "sun", "wind"]:
		blend[key] = st[key]
	blend["tint"] = st["tint"]
