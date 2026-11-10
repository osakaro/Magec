extends Node
## Encargos del puerto: misiones secundarias que se renuevan cada día.
## Gente de cada isla pide peces concretos (o un mutante, o algo del fondo)
## y paga bien por ellos. Se entregan en el panel del puerto.

const Data = preload("res://scripts/data.gd")

var main
var by_region := {}   # isla -> [encargos]
var day_made := {}    # isla -> día en que se generaron
var completed := 0

const CLIENTS := {
	"tenerife": ["El bar El Puertito", "La cofradía de Güímar", "Nieves, para su puesto", "Las fiestas del Socorro", "Un guachinche de la carretera"],
	"gran_canaria": ["Un restaurante de Las Canteras", "El mercado de Vegueta", "La cofradía de San Cristóbal", "Un cocinero de Triana"],
	"la_gomera": ["La venta de Hermigua", "Las fiestas de Agulo", "Un bar de Valle Gran Rey", "Doña Candelaria, la de la pensión"],
	"lanzarote": ["Un restaurante de Caleta de Sebo", "La cofradía de La Graciosa", "Un cocinero de Arrieta"],
	"fuerteventura": ["El mercado de Corralejo", "Un chiringuito de las dunas", "La cofradía de El Cotillo"],
	"la_palma": ["Una tasca de Tazacorte", "Los científicos del volcán", "La cofradía de Santa Cruz de La Palma"],
	"el_hierro": ["La cofradía de La Restinga", "Un restaurante de El Golfo", "El farero Bentor"],
}

const MUSEUM := ["El museo de ciencias de Las Palmas", "Un coleccionista de Madrid", "Una profesora de biología"]


func _rng_for(region: String) -> RandomNumberGenerator:
	var r := RandomNumberGenerator.new()
	r.seed = hash(region) + main.day * 977
	return r


func ensure() -> void:
	## Genera los encargos del día para la isla actual si hace falta.
	var reg: String = main.region
	if day_made.get(reg, -1) == main.day and by_region.has(reg):
		return
	var r := _rng_for(reg)
	var list: Array = []
	var clients: Array = CLIENTS.get(reg, CLIENTS["tenerife"])
	var zones: Dictionary = Data.REGIONS[reg]["zones"]
	var pool: Array = []
	for z in zones:
		for k in zones[z]:
			if not pool.has(k):
				pool.append(k)
	var first := r.randi() % clients.size()
	for i in 3:
		var kind := r.randi() % 10
		var who: String = clients[(first + i) % clients.size()]
		var e := {}
		if kind < 7:
			var key: String = pool[r.randi() % pool.size()]
			var n := 1 + r.randi() % 3
			e = {"who": who, "key": key, "mut": false, "count": n,
				"reward": int(Data.FISH[key]["v"] * n * 1.8 + 25), "text": "%d × %s" % [n, Data.FISH[key]["n"]]}
		elif kind < 9:
			e = {"who": MUSEUM[r.randi() % MUSEUM.size()], "key": "*", "mut": true, "count": 1,
				"reward": 120 + r.randi() % 60, "text": "1 pez mutante, el que sea (para estudiarlo)"}
		else:
			var deep: Array = zones["fondo"]
			var key2: String = deep[r.randi() % deep.size()]
			e = {"who": who, "key": key2, "mut": false, "count": 1,
				"reward": int(Data.FISH[key2]["v"] * 3.0 + 40), "text": "1 × %s del fondo, bien grande" % Data.FISH[key2]["n"]}
		e["done"] = false
		list.append(e)
	by_region[reg] = list
	day_made[reg] = main.day


func current() -> Array:
	ensure()
	return by_region.get(main.region, [])


func _matches(e: Dictionary, it: Dictionary) -> bool:
	if e["key"] == "*":
		return it["mut"]
	return it["key"] == e["key"] and it["mut"] == e["mut"]


func have(e: Dictionary) -> int:
	var n := 0
	for it in main.items:
		if _matches(e, it):
			n += 1
	return n


func deliver(e: Dictionary) -> void:
	if e["done"] or have(e) < e["count"]:
		return
	var left: int = e["count"]
	var keep: Array = []
	for it in main.items:
		if left > 0 and _matches(e, it):
			left -= 1
		else:
			keep.append(it)
	main.items = keep
	main.money += e["reward"]
	e["done"] = true
	completed += 1
	main.audio.sfx("catch", -2.0, 1.2)
	main.ui.toast("Encargo entregado: %s te paga %d €." % [e["who"], e["reward"]])
	main.ui.refresh_hold()
	main.save_game()


func wanted(key: String, mut: bool) -> String:
	## Si algún encargo de esta isla pide este pez, devuelve quién lo pide.
	for e in current():
		if not e["done"] and _matches(e, {"key": key, "mut": mut}):
			return e["who"]
	return ""


func to_dict() -> Dictionary:
	return {"by_region": by_region, "day_made": day_made, "completed": completed}


func from_dict(d: Dictionary) -> void:
	by_region = d.get("by_region", {})
	day_made = d.get("day_made", {})
	for k in day_made:
		day_made[k] = int(day_made[k])
	completed = int(d.get("completed", 0))
