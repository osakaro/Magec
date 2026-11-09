extends RefCounted
## Datos del juego: peces y zonas de pesca de la costa de Güímar (Tenerife).

# shape: celdas que ocupa en la bodega (1 = ocupada).
# v: precio normal, mv: precio de la versión mutante (de noche).
const FISH := {
	"vieja": {
		"n": "Vieja", "m": "Vieja de mil ojos", "shape": [[1, 1]], "v": 12, "mv": 40,
		"c": Color("c8553d"),
		"d": "Pez loro canario, el más apreciado de la costa.",
		"md": "Tiene ojos abiertos por toda la piel. Todos te miran.",
	},
	"chicharro": {
		"n": "Chicharro", "m": "Chicharro hueco", "shape": [[1]], "v": 6, "mv": 22,
		"c": Color("8fa7b8"),
		"d": "Pequeño y plateado. Sale en bancos cerca de la orilla.",
		"md": "Ligero como una cáscara. Por dentro no hay nada.",
	},
	"medregal": {
		"n": "Medregal", "m": "Medregal de hueso", "shape": [[1, 1, 1, 1]], "v": 30, "mv": 85,
		"c": Color("c9b26b"),
		"d": "Largo y rápido, de aguas abiertas.",
		"md": "Le asoma la espina por el lomo. Sigue nadando.",
	},
	"abade": {
		"n": "Abade", "m": "Abade ahogado", "shape": [[1, 1], [1, 1]], "v": 28, "mv": 80,
		"c": Color("6d6f5a"),
		"d": "Pariente del mero, de fondos rocosos.",
		"md": "Hinchado y pálido, como si hubiera pasado años bajo el agua.",
	},
	"calamar": {
		"n": "Calamar", "m": "Calamar dentado", "shape": [[1], [1], [1]], "v": 22, "mv": 70,
		"c": Color("d9a3a0"),
		"d": "Sube de noche hacia la luz.",
		"md": "Cada ventosa tiene una hilera de dientes.",
	},
	"cherne": {
		"n": "Cherne", "m": "Cherne sin rostro", "shape": [[1, 1, 1], [1, 1, 0]], "v": 45, "mv": 130,
		"c": Color("5b5148"),
		"d": "El rey de los fondos de Tenerife.",
		"md": "Donde debería estar la cara, solo hay piel lisa.",
	},
	"mero": {
		"n": "Mero", "m": "Mero de dos bocas", "shape": [[1, 1, 1], [1, 1, 1]], "v": 60, "mv": 170,
		"c": Color("7a5a3c"),
		"d": "Enorme y viejo. Cuesta sacarlo.",
		"md": "Una boca respira. La otra susurra.",
	},
}

const ZONES := {
	"orilla": {"name": "Orilla", "fish": ["vieja", "chicharro", "vieja", "chicharro", "calamar"]},
	"media": {"name": "Aguas medias", "fish": ["medregal", "abade", "calamar", "chicharro"]},
	"fondo": {"name": "Fondo profundo", "fish": ["cherne", "mero", "abade", "medregal"]},
}

# Puntos de pesca: [x, z, zona]
const SPOTS := [
	[-40, -48, "orilla"], [30, -50, "orilla"], [70, -40, "orilla"], [-80, -44, "orilla"],
	[-60, 0, "media"], [20, 10, "media"], [90, 20, "media"], [-110, 30, "media"],
	[-30, 90, "fondo"], [60, 110, "fondo"], [130, 80, "fondo"], [-120, 120, "fondo"],
]


static func fish_name(key: String, mut: bool) -> String:
	return FISH[key]["m"] if mut else FISH[key]["n"]


static func fish_value(key: String, mut: bool) -> int:
	return FISH[key]["mv"] if mut else FISH[key]["v"]
