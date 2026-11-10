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

	"pargo": {
		"game": "tiron", "n": "Pargo", "m": "Pargo de lengua negra", "shape": [[1, 1, 1], [0, 1, 0]], "v": 34, "mv": 100,
		"c": Color("d98b6a"),
		"d": "Rosado y de frente alta. Típico de los fondos de Gran Canaria.",
		"md": "Tiene una lengua negra y larga que se mueve sola.",
	},
	"bocinegro": {
		"game": "rapido", "n": "Bocinegro", "m": "Bocinegro de boca cosida", "shape": [[1, 1, 1]], "v": 30, "mv": 90,
		"c": Color("c9876e"),
		"d": "Pariente del pargo, con la boca oscura. Muy rápido.",
		"md": "Tiene la boca cerrada con un hilo de algas, como si alguien la hubiera cosido.",
	},
	"dorada": {
		"game": "zigzag", "n": "Dorada", "m": "Dorada de escamas de oro", "shape": [[1, 1]], "v": 18, "mv": 60,
		"c": Color("b8b48a"),
		"d": "Plateada con una ceja dorada. Desconfiada y lista.",
		"md": "Las escamas son de oro de verdad. Pesan como monedas.",
	},
	"seifia": {
		"game": "normal", "n": "Seifía", "m": "Seifía de dos colas", "shape": [[1, 1]], "v": 12, "mv": 38,
		"c": Color("a9afab"),
		"d": "Plateada con dos manchas negras, en la nuca y en la cola. Muy de La Gomera.",
		"md": "Tiene una segunda cola donde debería estar la cabeza. No se sabe hacia dónde nada.",
	},
	"chopa": {
		"game": "zigzag", "n": "Chopa", "m": "Chopa ahumada", "shape": [[1, 1], [1, 0]], "v": 16, "mv": 50,
		"c": Color("8d9490"),
		"d": "Gris con líneas doradas. Se esconde entre las piedras de los roques.",
		"md": "Huele a hoguera. Por dentro la carne está negra y caliente.",
	},
	"fula": {
		"game": "rapido", "n": "Fula negra", "m": "Fula de ojos azules", "shape": [[1]], "v": 7, "mv": 26,
		"c": Color("2e2a24"),
		"d": "Pequeña, oscura y peleona. Defiende su roca como un perro.",
		"md": "Los ojos le brillan de un azul eléctrico, aunque la saques del agua.",
	},
	"pejeperro": {
		"game": "tiron", "n": "Pejeperro", "m": "Pejeperro que ladra", "shape": [[1, 1, 1], [1, 1, 0]], "v": 38, "mv": 110,
		"c": Color("c9452e"),
		"d": "Rojo y amarillo, con el hocico puntiagudo. Escaso y muy buscado.",
		"md": "Al sacarlo del agua hace un ruido seco. Como un ladrido lejano.",
	},
	"cabrilla": {
		"game": "normal", "n": "Cabrilla", "m": "Cabrilla con cuernos", "shape": [[1, 1]], "v": 10, "mv": 32,
		"c": Color("9a6a44"),
		"d": "Parda con barras oscuras y rayas naranjas. Muerde cualquier cebo.",
		"md": "Le han salido dos cuernos pequeños en la frente.",
	},
	"bicuda": {
		"game": "rapido", "n": "Bicuda", "m": "Bicuda de niebla", "shape": [[1, 1, 1, 1, 1]], "v": 28, "mv": 85,
		"c": Color("98a6ac"),
		"d": "Una barracuda canaria: larga, plateada y con dientes de aguja.",
		"md": "Es casi transparente. Al tocarla se te queda la mano fría y húmeda.",
	},
	"murion": {
		"game": "tiron", "n": "Murión", "m": "Murión de cien dientes", "shape": [[1, 1, 1, 1]], "v": 26, "mv": 80,
		"c": Color("3a3226"),
		"d": "Pariente de la morena, oscuro y moteado. Vive en los tubos volcánicos.",
		"md": "Abre la boca y no termina nunca de abrirla. Está llena de dientes hasta la garganta.",
	},
	"catalufa": {
		"game": "rapido", "n": "Catalufa", "m": "Catalufa de ojo vacío", "shape": [[1, 1]], "v": 14, "mv": 44,
		"c": Color("c9312a"),
		"d": "Roja como un tomate y con ojos enormes. Sale de noche de las cuevas.",
		"md": "Uno de sus ojos es un agujero negro por el que no se ve el fondo.",
	},
	"gallo": {
		"game": "zigzag", "n": "Gallo", "m": "Gallo de piel de piedra", "shape": [[1, 1], [1, 1]], "v": 18, "mv": 55,
		"c": Color("6f7e86"),
		"d": "El pez ballesta de Canarias. Duro como una piedra y con mala leche.",
		"md": "La piel se le ha vuelto lava fría. Pesa el doble de lo que parece.",
	},
	"choco": {
		"game": "zigzag", "n": "Choco", "m": "Choco que escribe", "shape": [[1, 1], [1, 0]], "v": 20, "mv": 62,
		"c": Color("a88a6a"),
		"d": "La sepia. Cambia de color y suelta tinta.",
		"md": "Su tinta forma letras en el agua. Siempre la misma palabra: Aridane.",
	},
	"chucho": {
		"game": "tiron", "n": "Chucho", "m": "Chucho de cola doble", "shape": [[1, 1, 1], [1, 1, 1]], "v": 22, "mv": 66,
		"c": Color("7a6a52"),
		"d": "Raya de arena con un aguijón en la cola. Cuidado al cogerlo.",
		"md": "Tiene dos aguijones y los dos se mueven solos.",
	},
	"mantelina": {
		"game": "normal", "n": "Mantelina", "m": "Mantelina de alas negras", "shape": [[1, 1, 1], [0, 1, 0]], "v": 16, "mv": 50,
		"c": Color("8a7a5a"),
		"d": "Raya mariposa, ancha y plana, que se entierra en la arena.",
		"md": "Sus alas son negras como el carbón y se mueven sin agua.",
	},
	"angelote": {
		"game": "tiron", "n": "Angelote", "m": "Angelote de dos caras", "shape": [[1, 1, 1, 1], [1, 1, 1, 1]], "v": 30, "mv": 90,
		"c": Color("9a8a6a"),
		"d": "Tiburón ángel, aplastado como una raya. En Canarias aún quedan.",
		"md": "Tiene una cara arriba y otra debajo. Las dos te miran.",
	},
	"salmonete": {
		"game": "normal", "n": "Salmonete", "m": "Salmonete de barbas largas", "shape": [[1, 1]], "v": 14, "mv": 44,
		"c": Color("d65a46"),
		"d": "Rojo con barbillas para buscar en la arena. Muy sabroso.",
		"md": "Las barbas le llegan a la cola y se enroscan como raíces.",
	},
	"corvina": {
		"game": "tiron", "n": "Corvina", "m": "Corvina que ronca", "shape": [[1, 1, 1, 1]], "v": 34, "mv": 98,
		"c": Color("8d8a78"),
		"d": "Grande y plateada. Hace ruido con la vejiga natatoria.",
		"md": "Ronca como un hombre dormido, incluso fuera del agua.",
	},
	"pez_luna": {
		"game": "tiron", "n": "Pez luna", "m": "Pez luna eclipsado", "shape": [[1, 1, 1], [1, 1, 1], [1, 1, 1]], "v": 50, "mv": 140,
		"c": Color("a9b1b4"),
		"d": "Enorme y redondo, sin cola. Toma el sol tumbado en la superficie.",
		"md": "La mitad de su cuerpo es negra, como una luna a medio eclipsar.",
	},
	"conejo": {
		"game": "rapido", "n": "Conejo", "m": "Conejo de las cenizas", "shape": [[1, 1, 1, 1]], "v": 30, "mv": 88,
		"c": Color("3b3a3e"),
		"d": "Pez de profundidad, negro y alargado, con dientes finos.",
		"md": "Está cubierto de ceniza volcánica que no se quita al lavarlo.",
	},
	"rascacio": {
		"game": "normal", "n": "Rascacio", "m": "Rascacio de espinas rojas", "shape": [[1, 1]], "v": 18, "mv": 56,
		"c": Color("b8553a"),
		"d": "Escorpión de roca, lleno de espinas venenosas. Camuflado entre la lava.",
		"md": "Sus espinas brillan al rojo como brasas.",
	},
	"pota": {
		"game": "zigzag", "n": "Pota", "m": "Pota de ojos de vidrio", "shape": [[1], [1], [1]], "v": 20, "mv": 60,
		"c": Color("d98a7a"),
		"d": "Calamar grande de las aguas hondas de La Palma.",
		"md": "Sus ojos son de vidrio volcánico: obsidiana pulida.",
	},
	"burro": {
		"game": "normal", "n": "Burro", "m": "Burro que suspira", "shape": [[1, 1]], "v": 12, "mv": 38,
		"c": Color("9a9a90"),
		"d": "Roncador gris con rayas finas. Gruñe cuando lo sacas.",
		"md": "Suspira como un viejo cansado cada vez que respira.",
	},
	"pez_remo": {
		"game": "tiron", "n": "Pez remo", "m": "Pez remo de corona roja", "shape": [[1, 1, 1, 1, 1, 1]], "v": 80, "mv": 220,
		"c": Color("c9ced2"),
		"d": "El rey de los arenques: larguísimo y plateado, con una cresta roja. Rarísimo.",
		"md": "La cresta le arde como una corona de fuego. Dicen que anuncia terremotos.",
	},
	"rabil": {
		"game": "rapido", "n": "Rabil", "m": "Rabil de aletas de hueso", "shape": [[1, 1, 1, 1], [1, 1, 1, 0]], "v": 60, "mv": 170,
		"c": Color("2d4a6e"),
		"d": "Atún de aletas amarillas. Rápido como una bala.",
		"md": "Las aletas amarillas son hueso desnudo.",
	},
	"patudo": {
		"game": "tiron", "n": "Patudo", "m": "Patudo sin pupilas", "shape": [[1, 1, 1, 1], [1, 1, 1, 1]], "v": 70, "mv": 190,
		"c": Color("263e5e"),
		"d": "Atún de ojos grandes que vive hondo.",
		"md": "Sus ojos enormes son blancos y lisos, como perlas.",
	},
	"peto": {
		"game": "rapido", "n": "Peto", "m": "Peto de rayas vivas", "shape": [[1, 1, 1, 1, 1]], "v": 40, "mv": 115,
		"c": Color("3d6a82"),
		"d": "Largo, plateado y con rayas azules. El más rápido del mar canario.",
		"md": "Sus rayas se mueven por el cuerpo como serpientes.",
	},
	"picudo": {
		"game": "tiron", "n": "Picudo", "m": "Picudo de espada negra", "shape": [[1, 1, 1, 1, 1, 1], [0, 1, 1, 1, 0, 0]], "v": 90, "mv": 250,
		"c": Color("1e3f66"),
		"d": "Marlín azul, con su espada y su vela. El trofeo de El Hierro.",
		"md": "Su espada es de piedra negra y está afilada como un cuchillo.",
	},
	"dorado": {
		"game": "rapido", "n": "Dorado", "m": "Dorado que se apaga", "shape": [[1, 1, 1]], "v": 32, "mv": 95,
		"c": Color("4aa86a"),
		"d": "Verde y dorado, de frente cuadrada. Cambia de color al morir.",
		"md": "Sus colores se apagan y se encienden como una bombilla vieja.",
	},
	"abadejo": {
		"game": "normal", "n": "Abadejo", "m": "Abadejo de piel de lagarto", "shape": [[1, 1, 1]], "v": 34, "mv": 96,
		"c": Color("7a6a4a"),
		"d": "Pariente del mero, pardo y moteado. Vive en los veriles de La Restinga.",
		"md": "Tiene la piel de un lagarto gigante de El Hierro.",
	},
}

const ZONES := {
	"orilla": {"name": "Orilla", "fish": ["vieja", "chicharro", "sargo", "salema", "vieja", "calamar"]},
	"media": {"name": "Aguas medias", "fish": ["medregal", "abade", "calamar", "sama", "chicharro", "sama"]},
	"fondo": {"name": "Fondo profundo", "fish": ["cherne", "mero", "abade", "alfonsino", "alfonsino"]},
}

# Islas: nombre, costa, puerto, semilla del relieve y peces por zona
const REGIONS := {
	"tenerife": {
		"name": "Tenerife", "place": "Costa de Güímar", "port": "Puerto de Güímar", "seed": 0.0,
		"zones": {
			"orilla": ["vieja", "chicharro", "sargo", "salema", "vieja", "calamar"],
			"media": ["medregal", "abade", "calamar", "sama", "chicharro", "sama"],
			"fondo": ["cherne", "mero", "abade", "alfonsino", "alfonsino"],
		},
	},
	"la_gomera": {
		"name": "La Gomera", "place": "Costa de San Sebastián", "port": "Puerto de San Sebastián", "seed": 91.0,
		"zones": {
			"orilla": ["seifia", "fula", "cabrilla", "seifia", "chopa", "vieja"],
			"media": ["chopa", "bicuda", "cabrilla", "sama", "bicuda"],
			"fondo": ["pejeperro", "bicuda", "abade", "pejeperro", "cherne"],
		},
	},
	"lanzarote": {
		"name": "Lanzarote", "place": "Costa de La Graciosa", "port": "Caleta de Sebo", "seed": 137.0,
		"zones": {
			"orilla": ["vieja", "catalufa", "gallo", "choco", "vieja"],
			"media": ["catalufa", "gallo", "morena", "murion", "choco"],
			"fondo": ["morena", "murion", "abade", "murion"],
		},
	},
	"fuerteventura": {
		"name": "Fuerteventura", "place": "Costa de Corralejo", "port": "Puerto de Corralejo", "seed": 173.0,
		"zones": {
			"orilla": ["salmonete", "chucho", "mantelina", "corvina", "salmonete"],
			"media": ["angelote", "corvina", "salmonete", "sama", "mantelina"],
			"fondo": ["pez_luna", "angelote", "corvina", "chucho"],
		},
	},
	"la_palma": {
		"name": "La Palma", "place": "Costa de Tazacorte", "port": "Puerto de Tazacorte", "seed": 211.0,
		"zones": {
			"orilla": ["rascacio", "burro", "vieja", "burro"],
			"media": ["pota", "burro", "conejo", "rascacio"],
			"fondo": ["alfonsino", "conejo", "pota", "conejo", "pez_remo"],
		},
	},
	"el_hierro": {
		"name": "El Hierro", "place": "Costa de La Restinga", "port": "Puerto de La Restinga", "seed": 251.0,
		"zones": {
			"orilla": ["abadejo", "dorado", "vieja", "abadejo"],
			"media": ["peto", "dorado", "rabil", "peto"],
			"fondo": ["patudo", "picudo", "rabil", "patudo"],
		},
	},
	"gran_canaria": {
		"name": "Gran Canaria", "place": "Costa de Las Palmas", "port": "Puerto de La Luz", "seed": 53.0,
		"zones": {
			"orilla": ["salema", "sargo", "dorada", "vieja", "dorada", "boga"],
			"media": ["sama", "pargo", "bocinegro", "sama", "dorada"],
			"fondo": ["pargo", "bocinegro", "abade", "cherne", "pargo"],
		},
	},
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
	["dorada", "Gran Canaria · orilla"], ["bocinegro", "Gran Canaria · medias"], ["pargo", "Gran Canaria · fondo"],
	["seifia", "La Gomera · orilla"], ["fula", "La Gomera · orilla"], ["cabrilla", "La Gomera · orilla"],
	["chopa", "La Gomera · medias"], ["bicuda", "La Gomera · medias"], ["pejeperro", "La Gomera · fondo"],
	["catalufa", "Lanzarote · orilla"], ["gallo", "Lanzarote · orilla"], ["choco", "Lanzarote · orilla"],
	["murion", "Lanzarote · fondo"], ["salmonete", "Fuerteventura · orilla"], ["chucho", "Fuerteventura · orilla"],
	["mantelina", "Fuerteventura · orilla"], ["corvina", "Fuerteventura · medias"], ["angelote", "Fuerteventura · medias"],
	["pez_luna", "Fuerteventura · fondo"], ["rascacio", "La Palma · orilla"], ["burro", "La Palma · orilla"],
	["pota", "La Palma · medias"], ["conejo", "La Palma · fondo"], ["pez_remo", "La Palma · fondo (raro)"],
	["abadejo", "El Hierro · orilla"], ["dorado", "El Hierro · orilla"], ["peto", "El Hierro · medias"],
	["rabil", "El Hierro · medias"], ["patudo", "El Hierro · fondo"], ["picudo", "El Hierro · fondo"],
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
