extends RefCounted
## Datos del juego: peces y zonas de pesca de la costa de Güímar (Tenerife).

# shape: celdas que ocupa en la bodega (1 = ocupada).
# v: precio normal, mv: precio de la versión mutante (de noche).
const FISH := {
	"vieja": {
		"game": "normal", "n": "Vieja", "m": "Vieja de mil ojos", "shape": [[1, 1]], "v": 12, "mv": 40,
		"c": Color("c8553d"),
		"d": "Pez loro canario, el más apreciado de la costa.",
		"md": "Tiene ojos abiertos por toda la piel. Todos te miran.",
	},
	"chicharro": {
		"game": "normal", "n": "Chicharro", "m": "Chicharro hueco", "shape": [[1]], "v": 6, "mv": 22,
		"c": Color("8fa7b8"),
		"d": "Pequeño y plateado. Sale en bancos cerca de la orilla.",
		"md": "Ligero como una cáscara. Por dentro no hay nada.",
	},
	"medregal": {
		"game": "rapido", "n": "Medregal", "m": "Medregal de hueso", "shape": [[1, 1, 1, 1]], "v": 30, "mv": 85,
		"c": Color("c9b26b"),
		"d": "Largo y rápido, de aguas abiertas.",
		"md": "Le asoma la espina por el lomo. Sigue nadando.",
	},
	"abade": {
		"game": "tiron", "n": "Abade", "m": "Abade ahogado", "shape": [[1, 1], [1, 1]], "v": 28, "mv": 80,
		"c": Color("6d6f5a"),
		"d": "Pariente del mero, de fondos rocosos.",
		"md": "Hinchado y pálido, como si hubiera pasado años bajo el agua.",
	},
	"calamar": {
		"game": "zigzag", "n": "Calamar", "m": "Calamar dentado", "shape": [[1], [1], [1]], "v": 22, "mv": 70,
		"c": Color("d9a3a0"),
		"d": "Sube de noche hacia la luz.",
		"md": "Cada ventosa tiene una hilera de dientes.",
	},
	"cherne": {
		"game": "tiron", "n": "Cherne", "m": "Cherne sin rostro", "shape": [[1, 1, 1], [1, 1, 0]], "v": 45, "mv": 130,
		"c": Color("5b5148"),
		"d": "El rey de los fondos de Tenerife.",
		"md": "Donde debería estar la cara, solo hay piel lisa.",
	},
	"mero": {
		"game": "tiron", "n": "Mero", "m": "Mero de dos bocas", "shape": [[1, 1, 1], [1, 1, 1]], "v": 60, "mv": 170,
		"c": Color("7a5a3c"),
		"d": "Enorme y viejo. Cuesta sacarlo.",
		"md": "Una boca respira. La otra susurra.",
	},
	"sargo": {
		"game": "normal", "n": "Sargo", "m": "Sargo de dientes humanos", "shape": [[1, 1]], "v": 10, "mv": 34,
		"c": Color("b9bcb4"),
		"d": "Plateado con rayas negras. Le gusta la espuma de las rocas.",
		"md": "Sonríe. Tiene la dentadura de una persona.",
	},
	"salema": {
		"game": "normal", "n": "Salema", "m": "Salema que canta", "shape": [[1, 1]], "v": 8, "mv": 28,
		"c": Color("c9b24e"),
		"d": "Rayas doradas. Va en bancos cerca de la orilla.",
		"md": "Fuera del agua sigue haciendo un sonido agudo, como un silbido.",
	},
	"sama": {
		"game": "rapido", "n": "Sama", "m": "Sama roja de fiebre", "shape": [[1, 1, 1]], "v": 26, "mv": 75,
		"c": Color("d0704f"),
		"d": "Rosada y fuerte. Muy apreciada en las cocinas de Canarias.",
		"md": "Quema al tocarla. El agua del cubo empieza a hervir.",
	},
	"pulpo": {
		"game": "zigzag", "n": "Pulpo", "m": "Pulpo dentado", "shape": [[0, 1, 0], [1, 1, 1]], "v": 24, "mv": 72,
		"c": Color("a6584d"),
		"d": "Listo y escurridizo. Se mete en las nasas buscando refugio.",
		"md": "Cada ventosa tiene una boquita con dientes. Muerde la nasa desde dentro.",
	},
	"morena": {
		"game": "tiron", "n": "Morena", "m": "Morena de dos mandíbulas", "shape": [[1, 1, 1, 1, 1]], "v": 32, "mv": 95,
		"c": Color("6b5a2e"),
		"d": "Vive en las grietas de las rocas. Muerde fuerte.",
		"md": "Dentro de su boca hay otra boca. Y dentro de esa, otra.",
	},
	"alfonsino": {
		"game": "tiron", "n": "Alfonsiño", "m": "Alfonsiño de ojos ciegos", "shape": [[1, 1], [1, 1]], "v": 40, "mv": 115,
		"c": Color("d2392f"),
		"d": "Rojo intenso y ojos enormes. Vive muy hondo.",
		"md": "Sus ojos enormes están en blanco. Aun así, te sigue con la mirada.",
	},
	"boga": {
		"game": "normal", "n": "Boga", "m": "Boga transparente", "shape": [[1]], "v": 4, "mv": 16,
		"c": Color("9fb2a6"),
		"d": "Pequeña y abundante. Se pesca con red.",
		"md": "Se le ven las tripas a través de la piel. Late algo dentro.",
	},
	"sardina": {
		"game": "normal", "n": "Sardina", "m": "Sardina de escamas negras", "shape": [[1]], "v": 3, "mv": 14,
		"c": Color("8aa0b6"),
		"d": "Plateada y azul. Va en grandes bancos.",
		"md": "Las escamas se le caen como ceniza.",
	},

}

const ZONES := {
	"orilla": {"name": "Orilla", "fish": ["vieja", "chicharro", "sargo", "salema", "vieja", "calamar"]},
	"media": {"name": "Aguas medias", "fish": ["medregal", "abade", "calamar", "sama", "chicharro", "sama"]},
	"fondo": {"name": "Fondo profundo", "fish": ["cherne", "mero", "abade", "alfonsino", "alfonsino"]},
}

# Lo que cae en las nasas y en la red
const NASA_POOL := ["pulpo", "pulpo", "morena", "vieja", "pulpo", "morena"]
const NET_POOL := ["chicharro", "sardina", "boga", "sardina", "boga", "salema"]

# Orden del cuaderno de especies y dónde se pescan
const JOURNAL := [
	["vieja", "Orilla"], ["sargo", "Orilla"], ["salema", "Orilla · red"], ["chicharro", "Orilla · red"],
	["sardina", "Red"], ["boga", "Red"], ["pulpo", "Nasa"], ["morena", "Nasa"],
	["calamar", "Orilla · aguas medias"], ["medregal", "Aguas medias"], ["sama", "Aguas medias"],
	["abade", "Aguas medias · fondo"], ["cherne", "Fondo profundo"], ["mero", "Fondo profundo"], ["alfonsino", "Fondo profundo"],
]

# Cómo se comporta cada tipo de pez en el minijuego
const GAMES := {
	"normal": {"hits": 3, "speed": 1.0, "w": 1.0, "title": "Pica algo.", "sub": "Para el corcho sobre el agua dorada."},
	"rapido": {"hits": 4, "speed": 1.35, "w": 1.25, "title": "¡Es rápido!", "sub": "Necesitas cuatro aciertos."},
	"zigzag": {"hits": 3, "speed": 1.0, "w": 1.0, "title": "Se mueve a tirones, sin rumbo.", "sub": "El corcho cambia de dirección sin avisar."},
	"tiron": {"hits": 3, "speed": 0.85, "w": 1.0, "title": "¡Tira fuerte!", "sub": "El agua dorada se mueve: síguela."},
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
