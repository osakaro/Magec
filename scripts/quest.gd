extends Node
## Historia de MAGEC.
##
## Tenerife:
##   talk1 -> stone -> return -> guayota (jefe, de noche) -> guayota_back -> go_gc
## Gran Canaria:
##   gc_armador -> gc_yaiza -> gc_stone -> gc_return -> gc_done
##
## Secundarias en Güímar: Pancho el Viejo (le llevas una vieja) y Nieves (pescadera).
## Don Baltasar, el armador de Las Palmas, compra los mutantes; cuántos le vendes
## cuenta para el final.

const Boss = preload("res://scripts/boss.gd")
const Data = preload("res://scripts/data.gd")
const People = preload("res://scripts/people.gd")
const Isles = preload("res://scripts/isles.gd")
const Finale = preload("res://scripts/finale.gd")

var main

const CHAX_SPOT := Vector2(-62, -62)       # Chaxiraxi, junto a las Pirámides (Tenerife)
const YAIZA_SPOT := Vector2(-70, -60)      # Yaiza, en el faro de La Isleta (Gran Canaria)
const STONE_TF := Vector2(20, 150)
const STONE_GC := Vector2(-40, 140)
const STONE_LG := Vector2(120, 125)
const LOST_POS := Vector2(-135, 105)       # Tomasín, perdido en la niebla (La Gomera)

# Orden de la historia (para saber qué islas están abiertas)
const ORDER := ["talk1", "stone", "return", "guayota", "guayota_back", "go_gc", "gc_armador", "gc_yaiza",
	"gc_stone", "gc_return", "gc_done", "lg_silbo", "lg_lost", "lg_stone", "lg_return", "lg_done",
	"lz_stone", "lz_return", "lz_done", "fv_ghost", "fv_stone", "fv_return", "fv_done",
	"lp_remo", "lp_stone", "lp_return", "lp_done", "eh_calm", "eh_island", "end"]

const PORT_NPC := {"lanzarote": "Marcial", "fuerteventura": "Saro", "la_palma": "Elena", "el_hierro": "Bentor el farero"}

var state := "talk1"
var stones := 0
var pancho := "intro"     # intro -> wait -> done
var met_nieves := false
var mutants_sold := 0
var silbo_learned := false
var bitacora := false
var isles
var finale
var echo_time := 0.0          # cuánto dura la marca del eco en la brújula
var echo_bearing := 0.0
var whistle_cd := 0.0
var tomasin: Dictionary = {}
var silbo: Dictionary = {}    # estado del minijuego del silbo

var lines: Array = []
var line_i := 0
var after_dialogue := Callable()

var beacon: MeshInstance3D
var beacon_mat: StandardMaterial3D
var stone_spot: Node3D
var stone_bubbles: Array = []
var npc_light: OmniLight3D
var boss


# =====================================================================
# Diálogos
# =====================================================================

const TALK1 := [
	["Chaxiraxi", "Ay, Acorán. Te pareces tanto a tu abuelo… Él también venía a verme cuando el mar hacía cosas raras."],
	["Acorán", "Chaxiraxi, ¿qué fue ese temblor? Anoche saqué una vieja con ojos por todo el cuerpo."],
	["Chaxiraxi", "No fue el volcán, mi niño. Fue Guayota, revolviéndose allá abajo, bajo el Teide."],
	["Chaxiraxi", "Hace muchos siglos, Magec, el sol, lo encerró. Y guardó su luz en siete piedras, en el fondo del mar. Una por cada isla."],
	["Chaxiraxi", "Se están apagando. Por eso el mar se pudre de noche."],
	["Acorán", "Eso son cuentos de los viejos…"],
	["Chaxiraxi", "¿Y el farol que te di? ¿También es un cuento? Mira cómo se apartan las sombras cuando lo enciendes."],
	["Chaxiraxi", "La piedra de Tenerife está mar adentro, en lo hondo. Solo se deja ver de noche, donde el agua brilla dorada."],
	["Chaxiraxi", "Tu abuelo la buscó antes que tú. Tráemela, Acorán. Y no apagues el farol."],
]
const TALK_WAIT := [
	["Chaxiraxi", "La piedra solo se deja ver de noche, mar adentro, en el fondo profundo. Busca el agua dorada."],
]
const TALK2 := [
	["Chaxiraxi", "La has encontrado… Está fría. Apagada, como me temía."],
	["Chaxiraxi", "Pero mira. Ahí está. La luz de Magec todavía vive dentro.", "light"],
	["Acorán", "Cuando la saqué del agua me pareció oír algo bajo el barco. Como si alguien respirara."],
	["Chaxiraxi", "Guayota ya sabe quién eres. Ha olido la piedra, y esta noche vendrá a buscarla."],
	["Chaxiraxi", "He puesto un poco de su luz dentro de tu farol. Ahora te protegerá mejor."],
	["Chaxiraxi", "Escúchame bien. Frente al Teide, mar afuera, hay tres braseros viejos sobre boyas. Los pusieron los antiguos."],
	["Chaxiraxi", "Esta noche, ve allí con el farol encendido y prende los tres fuegos de Magec. Es lo único que lo obliga a volver abajo."],
	["Acorán", "¿Y si no lo consigo?"],
	["Chaxiraxi", "Entonces vuelves a casa, reparas el barco y lo intentas la noche siguiente. Pero no dejes que te hunda, mi niño."],
]
const TALK_BOSS_WAIT := [
	["Chaxiraxi", "De noche, frente al Teide. Tres fuegos. Esquiva el fuego que escupe y no apagues tu farol."],
]
const TALK_AFTER_BOSS := [
	["Chaxiraxi", "Lo he visto desde aquí. El mar se puso rojo y luego… silencio. Lo has conseguido."],
	["Acorán", "Me habló, Chaxiraxi. Dijo que él no era a quien debía temer. Que le preguntara a mi abuelo qué duerme bajo San Borondón."],
	["Chaxiraxi", "…"],
	["Chaxiraxi", "Guayota miente como respira. Pero esa vez, me temo que no mentía."],
	["Chaxiraxi", "La segunda piedra está en Gran Canaria. Allí, en el Puerto de La Luz, hay un armador muy rico, Don Baltasar."],
	["Chaxiraxi", "Compra todo lo raro que sale del mar. Nadie sabe para qué. Ve, pesca, gánate la vida… y no le vendas tu alma."],
	["Chaxiraxi", "Desde el puerto de Güímar puedes cruzar. Son unas horas de travesía."],
]
const TALK_CHAX_LATER := [
	["Chaxiraxi", "Ve con cuidado, mi niño. Y vuelve a dormir a casa, que la noche no es para nadie."],
]

# ---- Pancho el Viejo (Güímar)
const PANCHO_INTRO := [
	["Pancho", "¿Tú eres el nieto de Aridane? Coño, si eres igualito. Esa misma cara de no haber dormido."],
	["Pancho", "Tu abuelo y yo salíamos juntos a la mar. Hasta la noche aquella."],
	["Acorán", "¿Usted estaba allí cuando desapareció?"],
	["Pancho", "Estaba. Y lo que vi no se lo he contado a nadie. Pero con la boca seca no me sale la historia."],
	["Pancho", "Tráeme una vieja, de las buenas, de las normales. Hace años que no como una vieja sancochada como Dios manda."],
]
const PANCHO_WAIT := [
	["Pancho", "Una vieja, mi niño. Normal. Que las que salen de noche tienen más ojos que yo años."],
]
const PANCHO_DONE := [
	["Pancho", "¡Mírala! Roja como un atardecer. Gracias, mi niño. Siéntate, que te cuento.", "take_vieja"],
	["Pancho", "Aquella noche había calma chicha. Ni una ola. Y de repente el agua se iluminó, como si el fondo tuviera luz propia."],
	["Pancho", "Al oeste, donde no hay nada, apareció una isla. Verde. Con árboles. Y se oía cantar, como una salve de mujeres."],
	["Pancho", "Tu abuelo se quedó mirándola sin decir nada. Al día siguiente salió solo. Yo no tuve valor de acompañarlo."],
	["Pancho", "Toma, coge esto por la vieja. Y Acorán… si algún día ves esa isla, no le hagas caso al canto.", "pay"],
]
const PANCHO_LATER := [
	["Pancho", "La mar da y la mar quita, mi niño. Tú no dejes que te quite más de la cuenta."],
]

# ---- Nieves, la pescadera de Güímar
const NIEVES_FIRST := [
	["Nieves", "¡Acorán! Yo te compro todo lo que traigas, pero lo raro me lo dejas en el cubo de atrás, que me espanta la clientela."],
	["Nieves", "Un consejo: las nasas, échalas cerca de las rocas. Los pulpos y las morenas se esconden ahí."],
	["Nieves", "Y si se te rompe el casco, aquí en el muelle te lo arreglan. Caro, eso sí."],
]
const NIEVES_LATER := [
	["Nieves", "Hoy la gente no quiere pescado de noche. Dicen que tiene sabor a hierro."],
	["Nieves", "Mi primo dice que en Las Palmas un señor paga el triple por los peces raros. Qué gente más rara hay en el mundo."],
	["Nieves", "¿Has visto a los delfines? Mi abuela decía que si te acompañan es que la mar te quiere."],
]

# ---- Gran Canaria
const BALTASAR_FIRST := [
	["Don Baltasar", "Vaya, vaya. El nieto de Aridane. Las noticias corren rápido entre los muelles, muchacho."],
	["Don Baltasar", "Me llamo Baltasar Ojeda. Armador. Tengo media flota del puerto y un interés… científico, por lo que sale raro del mar."],
	["Acorán", "¿Usted es el que compra los peces mutantes?"],
	["Don Baltasar", "Mutantes. Qué palabra tan fea. Yo prefiero decir «especiales». Y por los especiales pago bien. Muy bien."],
	["Don Baltasar", "Una vez y media lo que te da cualquier pescadera. Piénsalo. Tu deuda desaparecería en dos noches."],
	["Don Baltasar", "Ah, y si buscas historias de piedras brillantes, la farera de La Isleta, Yaiza, no habla de otra cosa. Pobre mujer."],
]
const BALTASAR_LATER := [
	["Don Baltasar", "¿Me traes algo especial hoy? Mi oferta sigue en pie, muchacho."],
	["Don Baltasar", "Tu abuelo también vino a verme, ¿sabes? Él tampoco quiso vender. Mira cómo acabó."],
]
const YAIZA_TALK := [
	["Yaiza", "¿Te manda Baltasar? Ese hombre no da un paso sin saber a dónde lleva."],
	["Acorán", "Me manda Chaxiraxi, de Güímar. Busco la piedra de Magec de Gran Canaria."],
	["Yaiza", "Chaxiraxi… hace años que no oía ese nombre. Entonces es verdad. Están volviendo a apagarse."],
	["Yaiza", "Desde el faro la veo algunas noches. Al norte, mar adentro, en la bahía: un brillo dorado bajo el agua."],
	["Yaiza", "Pero no está sola. Cada vez que el brillo aparece, algo negro nada alrededor. Algo con ojos rojos."],
	["Yaiza", "Si la sacas, llévala con el farol encendido. Y ven directo aquí, que el faro también tiene luz de la buena."],
]
const YAIZA_WAIT := [
	["Yaiza", "De noche, al norte, mar adentro. Busca el brillo dorado. Y no apagues el farol."],
]
const YAIZA_RETURN := [
	["Yaiza", "¡La tienes! Ponla aquí, bajo la lámpara del faro."],
	["Yaiza", "Mira cómo bebe la luz… Ya está. Encendida.", "light"],
	["Yaiza", "Toma, frota tu farol con ella. Verás que ahora alumbra más lejos."],
	["Acorán", "Baltasar dijo que mi abuelo vino a verlo. Que no quiso venderle nada."],
	["Yaiza", "Baltasar no compra peces, Acorán. Compra lo que llevan dentro. Y cuanto más le das, más cerca está de despertarlo."],
	["Acorán", "¿Despertar qué?"],
	["Yaiza", "Lo que duerme bajo San Borondón. Lo que tu abuelo vigila desde hace treinta años."],
	["Yaiza", "La próxima piedra está en La Gomera, entre la niebla. Pero eso… es otra travesía."],
]
const YAIZA_LATER := [
	["Yaiza", "Desde el faro te veo pasar, Acorán. Mientras la luz siga encendida, no estás solo."],
]


# ---- La Gomera
const ISIDRO_1 := [
	["Isidro", "¿Tú eres el muchacho de las piedras con luz? Yaiza me mandó recado por el silbo. Aquí todo se sabe."],
	["Acorán", "¿Por el silbo?"],
	["Isidro", "En La Gomera hablamos silbando, de barranco a barranco. La voz se pierde; el silbo cruza montes y niebla."],
	["Isidro", "Y con esta niebla, mi niño, los ojos no te van a servir de nada. Tienes que aprender a escuchar."],
	["Isidro", "Te enseño. Yo silbo y tú repites: el silbo agudo con la W, el grave con la S. Atento."],
]
const ISIDRO_2 := [
	["Isidro", "¡Eso es! Tienes buen oído, como los de aquí."],
	["Isidro", "Ahora te voy a pedir un favor. Mi sobrino Tomasín salió ayer a la mar y la niebla se lo tragó."],
	["Isidro", "Sal a buscarlo. Pulsa la G para silbar: si te oye, te contestará, y sabrás de dónde viene su silbo."],
	["Isidro", "Tráemelo de vuelta y te diré dónde brilla la piedra. Él la ha visto."],
	["Isidro", "Ah, y otra cosa: los perros negros del mar odian el silbo. Si uno te persigue, sílbale fuerte."],
]
const ISIDRO_WAIT := [
	["Isidro", "Silba con la G y escucha de dónde te contesta. La brújula te marcará el eco."],
]
const TOMASIN := [
	["Tomasín", "¡Bendito silbo! Llevo un día dando vueltas en esta leche. No veía ni las manos."],
	["Acorán", "Tu tío me manda a buscarte. Dice que viste una luz en el mar."],
	["Tomasín", "La vi, sí. Anoche, al este, mar adentro: un brillo dorado bajo el agua."],
	["Tomasín", "Pero alrededor nadaba algo negro. Grande como un perro de presa. Con los ojos como brasas."],
	["Tomasín", "Yo me vuelvo a puerto siguiendo tu estela. Ve de noche y lleva el farol encendido."],
]
const ISIDRO_STONE_WAIT := [
	["Isidro", "De noche, al este, mar adentro. Y si el perro negro se acerca, silba."],
]
const ISIDRO_RETURN := [
	["Isidro", "Tomasín llegó sano y salvo. Y tú traes… ¡mírala! La tercera piedra."],
	["Isidro", "Déjame silbarle. Los viejos decían que la luz de Magec despierta con el silbo.", "light"],
	["Isidro", "Ahí está. Encendida. Tu farol también lo nota: ahora alumbra más que nunca."],
	["Acorán", "Isidro, ¿usted conoció a mi abuelo, a Aridane?"],
	["Isidro", "Lo conocí. Pasó por aquí hace treinta años, con la misma cara que tú. Buscaba la isla que canta."],
	["Isidro", "Me dijo que en San Borondón no cantan mujeres. Que lo que se oye es algo enorme respirando bajo la tierra."],
	["Isidro", "La próxima piedra está en Lanzarote, entre volcanes. Pero eso ya es otra travesía, mi niño."],
]
const ISIDRO_LATER := [
	["Isidro", "Si la niebla te pierde, silba. La Gomera siempre contesta."],
]


func _ready() -> void:
	beacon_mat = StandardMaterial3D.new()
	beacon_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	beacon_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	beacon_mat.albedo_color = Color(1.0, 0.78, 0.3, 0.22)
	beacon_mat.set("disable_fog", true)
	beacon_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.3
	cyl.bottom_radius = 1.2
	cyl.height = 70
	beacon = MeshInstance3D.new()
	beacon.mesh = cyl
	beacon.material_override = beacon_mat
	beacon.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	main.add_child(beacon)
	if main.region == "tenerife":
		_build_pyramids_and_chaxiraxi()
		_build_dock_people()
		boss = Boss.new()
		boss.main = self.main
		boss.quest = self
		main.add_child(boss)
	elif main.region == "gran_canaria":
		_build_lighthouse()
		_build_baltasar()
	elif main.region == "la_gomera":
		People.make(main, "Isidro", Vector3(-1.4, 1.12, -60.0), PI, main)
		_build_tomasin()
	else:
		var npc_by_isle := {"lanzarote": "Marcial", "fuerteventura": "Saro", "la_palma": "Elena", "el_hierro": "Bentor"}
		People.make(main, npc_by_isle.get(main.region, "Marcial"), Vector3(-1.4, 1.12, -60.0), PI, main)
	isles = Isles.new()
	isles.main = main
	isles.quest = self
	main.add_child(isles)
	if main.region == "el_hierro":
		finale = Finale.new()
		finale.main = main
		finale.quest = self
		main.add_child(finale)
	_build_stone_spot()


func _build_tomasin() -> void:
	var b: Dictionary = main.make_boat(Color("eae4d2"), Color("b8322a"), Color("1d5aa6"), "San Telmo")
	b["light"].light_energy = 1.6
	b["lamp_mat"].emission_energy_multiplier = 3.0
	People.make(b["node"], "Tomasín", Vector3(0.3, 0.45, 2.0), 0.0, main)
	tomasin = b


# =====================================================================
# Escenario y personajes
# =====================================================================

func _person(pos: Vector3, body_col: Color, skin: Color, hat: Color = Color(0, 0, 0, 0), sitting := false) -> void:
	var m := StandardMaterial3D.new()
	m.albedo_color = body_col
	var body := CapsuleMesh.new()
	body.radius = 0.4
	body.height = 1.2 if sitting else 1.7
	var b := MeshInstance3D.new()
	b.mesh = body
	b.material_override = m
	b.position = pos + Vector3(0, body.height / 2.0, 0)
	main.add_child(b)
	var sm := StandardMaterial3D.new()
	sm.albedo_color = skin
	var head := SphereMesh.new()
	head.radius = 0.24
	head.height = 0.48
	var h := MeshInstance3D.new()
	h.mesh = head
	h.material_override = sm
	h.position = pos + Vector3(0, body.height + 0.25, 0)
	main.add_child(h)
	if hat.a > 0.0:
		var hm := StandardMaterial3D.new()
		hm.albedo_color = hat
		var c := CylinderMesh.new()
		c.top_radius = 0.2
		c.bottom_radius = 0.34
		c.height = 0.22
		var hi := MeshInstance3D.new()
		hi.mesh = c
		hi.material_override = hm
		hi.position = pos + Vector3(0, body.height + 0.5, 0)
		main.add_child(hi)


func shore(x: float, z: float) -> Vector3:
	## Punto de tierra seca más cercano yendo tierra adentro (para que nadie quede en el agua).
	var zz := z
	for i in 60:
		if main.land_h(x, zz) > 0.7:
			break
		zz -= 0.5
	return Vector3(x, main.land_h(x, zz), zz)


func _build_pyramids_and_chaxiraxi() -> void:
	var stone := StandardMaterial3D.new()
	stone.albedo_color = Color("4a4038")
	stone.roughness = 1.0
	for p in [[-82.0, -96.0, 12.0], [-66.0, -102.0, 9.0], [-96.0, -108.0, 10.0]]:
		var base_y: float = max(main.land_h(p[0], p[1]), 0.5)
		var w: float = p[2]
		for step in 4:
			var bm := BoxMesh.new()
			bm.size = Vector3(w - step * 2.2, 1.2, w - step * 2.2)
			var mi := MeshInstance3D.new()
			mi.mesh = bm
			mi.material_override = stone
			mi.position = Vector3(p[0], base_y + 0.4 + step * 1.2, p[1])
			main.add_child(mi)
	var cx := -62.0
	var cz := -74.0
	var y: float = max(main.land_h(cx, cz), 0.4)
	var cp := shore(cx, cz)
	People.make(main, "Chaxiraxi", cp, PI, main)
	y = cp.y
	cz = cp.z
	npc_light = OmniLight3D.new()
	npc_light.light_color = Color("ffb45a")
	npc_light.omni_range = 14
	npc_light.position = Vector3(cx + 0.6, y + 1.6, cz + 0.3)
	main.add_child(npc_light)


func _build_dock_people() -> void:
	# Pancho sentado en una caja al final del muelle; Nieves en su puesto de pescado.
	var crate := BoxMesh.new()
	crate.size = Vector3(0.9, 0.6, 0.9)
	var wood := StandardMaterial3D.new()
	wood.albedo_color = Color("7a5636")
	var c := MeshInstance3D.new()
	c.mesh = crate
	c.material_override = wood
	c.position = Vector3(-1.2, 1.5, -57.5)
	main.add_child(c)
	People.make(main, "Pancho", Vector3(-1.2, 1.32, -57.75), PI, main)
	var stall := BoxMesh.new()
	stall.size = Vector3(2.4, 1.0, 1.2)
	var s := MeshInstance3D.new()
	s.mesh = stall
	s.material_override = wood
	s.position = Vector3(3.6, 1.0, -74.5)
	main.add_child(s)
	var awning := BoxMesh.new()
	awning.size = Vector3(2.8, 0.1, 1.8)
	var am := StandardMaterial3D.new()
	am.albedo_color = Color("2e6fa6")
	var a := MeshInstance3D.new()
	a.mesh = awning
	a.material_override = am
	a.position = Vector3(3.6, 3.2, -74.5)
	main.add_child(a)
	People.make(main, "Nieves", shore(3.6, -76.0), PI, main)


func _build_lighthouse() -> void:
	var white := StandardMaterial3D.new()
	white.albedo_color = Color("eeeae0")
	var red := StandardMaterial3D.new()
	red.albedo_color = Color("b8322a")
	var x := YAIZA_SPOT.x
	var z := YAIZA_SPOT.y - 14.0
	var y: float = max(main.land_h(x, z), 0.5)
	for i in 4:
		var c := CylinderMesh.new()
		c.top_radius = 1.6 - i * 0.2
		c.bottom_radius = 1.8 - i * 0.2
		c.height = 4.0
		var mi := MeshInstance3D.new()
		mi.mesh = c
		mi.material_override = white if i % 2 == 0 else red
		mi.position = Vector3(x, y + 2.0 + i * 4.0, z)
		main.add_child(mi)
	npc_light = OmniLight3D.new()
	npc_light.light_color = Color("fff1c0")
	npc_light.omni_range = 40
	npc_light.position = Vector3(x, y + 17.0, z)
	main.add_child(npc_light)
	var lamp := SphereMesh.new()
	lamp.radius = 1.0
	lamp.height = 2.0
	var lm := StandardMaterial3D.new()
	lm.albedo_color = Color("fff1c0")
	lm.emission_enabled = true
	lm.emission = Color("fff1c0")
	lm.emission_energy_multiplier = 4.0
	var l := MeshInstance3D.new()
	l.mesh = lamp
	l.material_override = lm
	l.position = Vector3(x, y + 17.0, z)
	main.add_child(l)
	People.make(main, "Yaiza", shore(x + 2.5, z + 6.0), PI, main)


func _build_baltasar() -> void:
	People.make(main, "Don Baltasar", Vector3(-1.5, 1.12, -60.0), PI, main)


func _build_stone_spot() -> void:
	stone_spot = Node3D.new()
	var sp: Vector2 = stone_pos()
	stone_spot.position = Vector3(sp.x, 0, sp.y)
	main.add_child(stone_spot)
	var gold := StandardMaterial3D.new()
	gold.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	gold.albedo_color = Color(1.0, 0.82, 0.35, 0.9)
	gold.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	gold.set("disable_fog", true)
	for i in 12:
		var sm := SphereMesh.new()
		sm.radius = 0.3
		sm.height = 0.6
		var mi := MeshInstance3D.new()
		mi.mesh = sm
		mi.material_override = gold
		stone_spot.add_child(mi)
		stone_bubbles.append({"m": mi, "o": randf() * 6.0, "r": 0.5 + randf() * 2.5})
	var glow := OmniLight3D.new()
	glow.light_color = Color("ffcc66")
	glow.light_energy = 3.0
	glow.omni_range = 18
	glow.position.y = 1.0
	stone_spot.add_child(glow)


func stone_pos() -> Vector2:
	if isles and isles.handles():
		return isles.stone_pos()
	match main.region:
		"tenerife":
			return STONE_TF
		"la_gomera":
			return STONE_LG
	return STONE_GC


func prog(st: String = "") -> int:
	return ORDER.find(st if st != "" else state)


# =====================================================================
# Estado
# =====================================================================

func _in_tf() -> bool:
	return main.region == "tenerife"


func _gc_state() -> bool:
	return state.begins_with("gc_")


func objective() -> String:
	var gk := goal_island_key()
	if state == "end":
		return "Fin de la historia. Puedes seguir pescando por las islas."
	if gk != main.region and Data.REGIONS.has(gk):
		return "Viaja a %s desde el puerto." % Data.REGIONS[gk]["name"]
	if isles and isles.handles() and isles.objective() != "":
		return isles.objective()
	if finale and finale.objective() != "":
		return finale.objective()
	match main.region:
		"tenerife":
			match state:
				"talk1":
					return "Habla con Chaxiraxi, en la playa junto a las Pirámides de Güímar."
				"stone":
					return "Busca la Piedra de Magec: de noche, mar adentro, donde el agua brilla dorada."
				"return":
					return "Lleva la Piedra de Magec a Chaxiraxi."
				"guayota":
					return "De noche, frente al Teide, prende los tres fuegos de Magec. Lleva el farol encendido."
				"guayota_back":
					return "Guayota ha vuelto al fondo. Cuéntaselo a Chaxiraxi."
		"gran_canaria":
			match state:
				"go_gc", "gc_armador":
					return "Habla con el armador, Don Baltasar, en el Puerto de La Luz."
				"gc_yaiza":
					return "Busca a Yaiza en el faro de La Isleta."
				"gc_stone":
					return "De noche, al norte, mar adentro: busca el brillo dorado. Algo lo vigila."
				"gc_return":
					return "Lleva la piedra al faro de Yaiza."
		"la_gomera":
			match state:
				"gc_done", "lg_silbo":
					return "Busca a Isidro el silbador en el muelle de San Sebastián."
				"lg_lost":
					return "Encuentra a Tomasín en la niebla: silba con la G y sigue el eco en la brújula."
				"lg_stone":
					return "De noche, al este, mar adentro: la piedra brilla bajo el agua. Silba si el perro negro te persigue."
				"lg_return":
					return "Lleva la piedra a Isidro, en el muelle."
	if pancho == "wait" and _in_tf():
		return "Pancho el Viejo quiere una vieja normal. Tiene una historia de tu abuelo."
	var nxt: String = Data.REGIONS.get(gk, {"name": "San Borondón"})["name"]
	return "Piedras de Magec: %d/7 · Próximo destino: %s" % [stones, nxt]


func target() -> Variant:
	var night: bool = main.is_night()
	var gk := goal_island_key()
	if state == "end":
		return null
	if gk != main.region and Data.REGIONS.has(gk):
		return Vector2(0, -58)
	if isles and isles.handles():
		return isles.target()
	if finale:
		return finale.target()
	match main.region:
		"tenerife":
			match state:
				"talk1", "return", "guayota_back":
					return CHAX_SPOT
				"stone":
					return STONE_TF if night else null
				"guayota":
					return boss.ARENA if boss else null
		"gran_canaria":
			match state:
				"go_gc", "gc_armador":
					return Vector2(0, -58)
				"gc_yaiza", "gc_return":
					return YAIZA_SPOT
				"gc_stone":
					return STONE_GC if night else null
		"la_gomera":
			match state:
				"gc_done", "lg_silbo", "lg_return":
					return Vector2(0, -58)
				"lg_stone":
					return STONE_LG if night else null
	return null


func goal_island_key() -> String:
	## Isla a la que apunta la historia ahora mismo.
	var p := prog()
	if p >= prog("go_gc") and p < prog("gc_done"):
		return "gran_canaria"
	if p >= prog("gc_done") and p < prog("lg_done"):
		return "la_gomera"
	if p >= prog("lg_done") and p < prog("lz_done"):
		return "lanzarote"
	if p >= prog("lz_done") and p < prog("fv_done"):
		return "fuerteventura"
	if p >= prog("fv_done") and p < prog("lp_done"):
		return "la_palma"
	if p >= prog("lp_done") and p < prog("end"):
		return "el_hierro"
	if p >= prog("end"):
		return main.region
	return "tenerife"


func goal_island() -> String:
	## Nombre de la isla a la que hay que viajar, si no es la actual.
	var k := goal_island_key()
	if k == main.region or not Data.REGIONS.has(k):
		return ""
	return Data.REGIONS[k]["name"]


func near(p: Vector2, r: float) -> bool:
	return Vector2(main.bx, main.bz).distance_to(p) < r


func hint() -> String:
	if boss and boss.hint() != "":
		return boss.hint()
	if finale and finale.hint() != "":
		return finale.hint()
	if main.region == "la_gomera" and state == "lg_lost" and near(_tomasin_pos(), 12.0):
		return "[color=#f2b33d]E[/color] · Hablar con Tomasín"
	if _in_tf() and near(CHAX_SPOT, 10.0):
		return "[color=#f2b33d]E[/color] · Hablar con Chaxiraxi"
	if main.region == "gran_canaria" and near(YAIZA_SPOT, 10.0):
		return "[color=#f2b33d]E[/color] · Hablar con Yaiza, la farera"
	if _stone_active() and near(stone_pos(), 7.0):
		return "[color=#f2b33d]E[/color] · Echar el sedal en el agua dorada"
	return ""


func _stone_active() -> bool:
	if isles and isles.handles():
		return isles.stone_active()
	if not main.is_night():
		return false
	match main.region:
		"tenerife":
			return state == "stone"
		"gran_canaria":
			return state == "gc_stone"
		"la_gomera":
			return state == "lg_stone"
	return false


func try_interact() -> bool:
	if boss and boss.try_interact():
		return true
	if finale and finale.try_interact():
		return true
	if _in_tf() and near(CHAX_SPOT, 10.0):
		match state:
			"talk1":
				start_dialogue(TALK1, func(): state = "stone")
			"stone":
				start_dialogue(TALK_WAIT)
			"return":
				start_dialogue(TALK2, func():
					state = "guayota"
					stones = 1
					main.lamp_mult = 0.5
					main.ui.toast("Farol mejorado: con él encendido, el miedo sube la mitad de rápido."))
			"guayota":
				start_dialogue(TALK_BOSS_WAIT)
			"guayota_back":
				start_dialogue(TALK_AFTER_BOSS, func():
					state = "go_gc"
					main.ui.toast("Ya puedes viajar a Gran Canaria desde el puerto."))
			_:
				start_dialogue(TALK_CHAX_LATER)
		return true
	if main.region == "la_gomera" and state == "lg_lost" and near(_tomasin_pos(), 12.0):
		start_dialogue(TOMASIN, func():
			state = "lg_stone"
			main.ui.toast("Tomasín vuelve a puerto. La piedra brilla de noche, al este."))
		return true
	if main.region == "gran_canaria" and near(YAIZA_SPOT, 10.0):
		match state:
			"gc_yaiza":
				start_dialogue(YAIZA_TALK, func(): state = "gc_stone")
			"gc_stone":
				start_dialogue(YAIZA_WAIT)
			"gc_return":
				start_dialogue(YAIZA_RETURN, func():
					state = "gc_done"
					stones = 2
					main.lamp_mult = 0.35
					main.ui.toast("Farol mejorado otra vez. Piedras de Magec: 2/7."))
			"go_gc", "gc_armador":
				start_dialogue([["Yaiza", "¿Quién eres? Habla primero con Baltasar, en el puerto. Luego, si quieres, vuelve."]])
			_:
				start_dialogue(YAIZA_LATER)
		return true
	if _stone_active() and near(stone_pos(), 7.0):
		main.start_special_fishing()
		return true
	return false


func got_stone() -> void:
	match main.region:
		"tenerife":
			state = "return"
		"gran_canaria":
			state = "gc_return"
		"la_gomera":
			state = "lg_return"
		_:
			isles.got_stone()
	main.panic = min(100.0, main.panic + 20.0)
	main.audio.sfx("stone", -4.0, 0.7)
	main.ui.toast("Has sacado la Piedra de Magec. Está fría como el fondo del mar.")
	if main.region in ["gran_canaria", "la_gomera"]:
		# El guardián de la piedra sale a por ti
		main.hazards.cooldown = 0.0
		main.hazards.start_hunt()
	main.save_game()


func boss_defeated() -> void:
	state = "guayota_back"
	main.save_game()


# ---------- Gente del puerto (se abre desde el panel del puerto) ----------
func port_people() -> Array:
	var out: Array = []
	match main.region:
		"tenerife":
			out.append(["Pancho el Viejo", "Pescador jubilado. Salía a la mar con tu abuelo.", _talk_pancho])
			out.append(["Nieves", "La pescadera del muelle.", _talk_nieves])
		"gran_canaria":
			out.append(["Don Baltasar", "Armador del Puerto de La Luz.", _talk_baltasar])
		"la_gomera":
			out.append(["Isidro el silbador", "Un viejo de Hermigua que habla silbando.", _talk_isidro])
		"el_hierro":
			out.append(["Bentor el farero", "Cuida el faro de Orchilla, donde se acaba el mundo conocido.", func(): finale.talk_port()])
		_:
			if isles.handles():
				out.append([isles.cfg()["npc"], isles.cfg()["desc"], func(): isles.talk()])
	# viajes a las islas ya abiertas
	var open := {"tenerife": true, "gran_canaria": prog() >= prog("go_gc"), "la_gomera": prog() >= prog("gc_done"),
		"lanzarote": prog() >= prog("lg_done"), "fuerteventura": prog() >= prog("lz_done"),
		"la_palma": prog() >= prog("fv_done"), "el_hierro": prog() >= prog("lp_done")}
	for k in ["tenerife", "gran_canaria", "la_gomera", "lanzarote", "fuerteventura", "la_palma", "el_hierro"]:
		if open[k] and k != main.region:
			var dest: String = k
			out.append(["Viajar a " + Data.REGIONS[k]["name"], "Unas 5 horas de travesía hasta " + Data.REGIONS[k]["port"] + ".", func(): main.travel(dest)])
	return out


func _talk_isidro() -> void:
	match state:
		"gc_done", "lg_silbo":
			state = "lg_silbo"
			start_dialogue(ISIDRO_1, func(): start_silbo())
		"lg_lost":
			start_dialogue(ISIDRO_WAIT)
		"lg_stone":
			start_dialogue(ISIDRO_STONE_WAIT)
		"lg_return":
			start_dialogue(ISIDRO_RETURN, func():
				state = "lg_done"
				stones = 3
				main.lamp_mult = 0.25
				main.ui.toast("Farol mejorado. Piedras de Magec: 3/7."))
		_:
			start_dialogue(ISIDRO_LATER)


# ---------- Minijuego del silbo ----------
const SILBO_ROUNDS := [[1, 0, 1], [0, 1, 1, 0], [1, 1, 0, 1, 0]]   # 1 = agudo, 0 = grave


func start_silbo() -> void:
	silbo = {"round": 0, "phase": "listen", "t": -0.8, "i": 0, "input": []}
	main.mode = "silbo"
	main.bv = 0.0
	main.ui.open_silbo()


func silbo_key(k: int) -> void:
	if silbo.is_empty() or silbo["phase"] != "repeat":
		return
	var v := -1
	if k in [KEY_W, KEY_UP]:
		v = 1
	elif k in [KEY_S, KEY_DOWN]:
		v = 0
	if v < 0:
		return
	main.audio.sfx("whistle_hi" if v == 1 else "whistle_lo", -4.0)
	var seq: Array = SILBO_ROUNDS[silbo["round"]]
	silbo["input"].append(v)
	var n: int = silbo["input"].size()
	if seq[n - 1] != v:
		silbo["phase"] = "fail"
		silbo["t"] = 0.0
	elif n == seq.size():
		silbo["phase"] = "ok"
		silbo["t"] = 0.0


func _update_silbo(dt: float) -> void:
	if silbo.is_empty():
		return
	silbo["t"] += dt
	var seq: Array = SILBO_ROUNDS[silbo["round"]]
	match silbo["phase"]:
		"listen":
			if silbo["t"] >= 0.0 and silbo["i"] < seq.size() and silbo["t"] >= silbo["i"] * 0.75:
				main.audio.sfx("whistle_hi" if seq[silbo["i"]] == 1 else "whistle_lo", -2.0)
				silbo["i"] += 1
			if silbo["i"] >= seq.size() and silbo["t"] > seq.size() * 0.75 + 0.4:
				silbo["phase"] = "repeat"
				silbo["input"] = []
		"ok":
			if silbo["t"] > 1.0:
				silbo["round"] += 1
				if silbo["round"] >= SILBO_ROUNDS.size():
					silbo = {}
					silbo_learned = true
					main.ui.close_silbo()
					main.mode = "sail"
					start_dialogue(ISIDRO_2, func():
						state = "lg_lost"
						main.weather.from_dict({"current": "niebla", "next_change": main.game_time + 8 * 60})
						main.ui.toast("Has aprendido el silbo gomero. Pulsa G para silbar."))
					return
				silbo["phase"] = "listen"
				silbo["t"] = -0.6
				silbo["i"] = 0
				silbo["input"] = []
		"fail":
			if silbo["t"] > 1.2:
				silbo["phase"] = "listen"
				silbo["t"] = -0.4
				silbo["i"] = 0
				silbo["input"] = []
	main.ui.update_silbo(silbo)


# ---------- Silbar (G) ----------
func whistle() -> void:
	if not silbo_learned or whistle_cd > 0.0:
		return
	whistle_cd = 3.5
	main.audio.sfx("whistle_call", -2.0)
	if main.hazards.hunting:
		main.hazards.scare()
	if main.region == "la_gomera" and state == "lg_lost":
		var v: Vector2 = _tomasin_pos() - Vector2(main.bx, main.bz)
		echo_bearing = atan2(v.x, -v.y)
		get_tree().create_timer(1.6).timeout.connect(func():
			main.audio.sfx("whistle_answer", lerp(0.0, -14.0, clamp(v.length() / 260.0, 0.0, 1.0)))
			echo_time = 6.0
			var dirs := ["norte", "noreste", "este", "sureste", "sur", "suroeste", "oeste", "noroeste"]
			var idx := int(round(fposmod(echo_bearing, TAU) / (TAU / 8.0))) % 8
			main.ui.toast("Tomasín contesta desde el %s." % dirs[idx]))


func _tomasin_pos() -> Vector2:
	return LOST_POS


func _talk_pancho() -> void:
	match pancho:
		"intro":
			start_dialogue(PANCHO_INTRO, func(): pancho = "wait")
		"wait":
			if _has_vieja():
				start_dialogue(PANCHO_DONE, func(): pancho = "done")
			else:
				start_dialogue(PANCHO_WAIT)
		_:
			start_dialogue(PANCHO_LATER)


func _has_vieja() -> bool:
	for it in main.items:
		if it["key"] == "vieja" and not it["mut"]:
			return true
	return false


func _talk_nieves() -> void:
	if not met_nieves:
		met_nieves = true
		start_dialogue(NIEVES_FIRST)
	else:
		start_dialogue([NIEVES_LATER[randi() % NIEVES_LATER.size()]])


func _talk_baltasar() -> void:
	if state == "go_gc" or state == "gc_armador":
		start_dialogue(BALTASAR_FIRST, func():
			state = "gc_yaiza"
			main.ui.toast("Ahora puedes vender peces mutantes a Don Baltasar en este puerto."))
	else:
		start_dialogue([BALTASAR_LATER[randi() % BALTASAR_LATER.size()]])


func baltasar_open() -> bool:
	return main.region == "gran_canaria" and not (state == "go_gc" or state == "gc_armador")


func sell_mutants_to_baltasar() -> int:
	var total := 0
	var keep: Array = []
	var n := 0
	for it in main.items:
		if it["mut"]:
			total += int(Data.fish_value(it["key"], true) * 1.5)
			n += 1
		else:
			keep.append(it)
	main.items = keep
	main.money += total
	mutants_sold += n
	if n > 0:
		var lines_b := [
			"Excelente. Mis… clientes estarán encantados.",
			"Cada uno de estos vale su peso en oro. Literalmente, muchacho.",
			"Sigue así y pronto no necesitarás pescar nunca más.",
		]
		main.ui.toast("Don Baltasar: «%s»" % lines_b[randi() % lines_b.size()])
	return total


# =====================================================================
# Diálogos
# =====================================================================

func start_dialogue(l: Array, then := Callable()) -> void:
	lines = l
	line_i = 0
	after_dialogue = then
	main.mode = "talk"
	main.bv = 0.0
	main.ui.port_panel.visible = false
	_show()


func next_line() -> void:
	line_i += 1
	if line_i >= lines.size():
		main.ui.close_dialogue()
		main.mode = "sail"
		if after_dialogue.is_valid():
			after_dialogue.call()
		main.save_game()
		return
	_show()


func _show() -> void:
	var l: Array = lines[line_i]
	if l.size() > 2:
		match l[2]:
			"light":
				main.audio.sfx("stone")
				if npc_light:
					npc_light.light_energy = 6.0
			"take_vieja":
				for i in main.items.size():
					var it: Dictionary = main.items[i]
					if it["key"] == "vieja" and not it["mut"]:
						main.items.remove_at(i)
						break
				main.ui.refresh_hold()
			"pay":
				main.money += 60
				main.ui.toast("Pancho te da 60 €.")
			_:
				if finale:
					finale.on_event(l[2])
	main.ui.show_dialogue(l[0], l[1], line_i, lines.size())


# =====================================================================
# Cada frame
# =====================================================================

func _process(dt: float) -> void:
	var tt: float = main.t
	whistle_cd = max(0.0, whistle_cd - dt)
	echo_time = max(0.0, echo_time - dt)
	if main.mode == "silbo":
		_update_silbo(dt)
	if not tomasin.is_empty():
		var n: Node3D = tomasin["node"]
		n.visible = state == "lg_lost"
		var y: float = main.wave(LOST_POS.x, LOST_POS.y, tt)
		n.position = Vector3(LOST_POS.x, y + 0.1, LOST_POS.y)
		n.rotation = Vector3(sin(tt * 1.2) * 0.05, 0.8, cos(tt) * 0.05)
	stone_spot.visible = _stone_active()
	if stone_spot.visible:
		var sp: Vector2 = stone_pos()
		stone_spot.position.y = main.wave(sp.x, sp.y, tt) + 0.1
		var i := 0
		for b in stone_bubbles:
			var k := fmod(tt * 0.7 + b["o"], 2.0)
			b["m"].position = Vector3(cos(i * 0.7 + tt * 0.4) * b["r"], k * 0.8, sin(i * 1.1 + tt * 0.2) * b["r"])
			i += 1
	if npc_light:
		var base: float = 1.5 + (1.0 - main.daylight()) * 1.5
		if not _in_tf():
			base = 0.5 + (1.0 - main.daylight()) * 4.0
		npc_light.light_energy = move_toward(npc_light.light_energy, base, dt)
	var tg = target()
	beacon.visible = tg != null and main.mode != "cinematic" and main.mode != "menu"
	if beacon.visible:
		beacon.position = Vector3(tg.x, 35, tg.y)
		# se desvanece al acercarte, para no tapar la pantalla
		var d: float = Vector2(main.bx, main.bz).distance_to(tg)
		var fade: float = clamp((d - 12.0) / 30.0, 0.0, 1.0)
		beacon_mat.albedo_color.a = (0.14 + 0.08 * sin(tt * 2.0)) * fade
		beacon.visible = fade > 0.01


# =====================================================================
# Guardar
# =====================================================================

func to_dict() -> Dictionary:
	var d := {"pancho": pancho, "met_nieves": met_nieves, "mutants_sold": mutants_sold, "silbo": silbo_learned, "bitacora": bitacora}
	if isles:
		d["isles"] = isles.to_dict()
	if finale:
		d["finale"] = finale.to_dict()
	return d


func from_dict(d: Dictionary) -> void:
	pancho = str(d.get("pancho", "intro"))
	met_nieves = bool(d.get("met_nieves", false))
	mutants_sold = int(d.get("mutants_sold", 0))
	silbo_learned = bool(d.get("silbo", false))
	bitacora = bool(d.get("bitacora", false))
	if isles:
		isles.from_dict(d.get("isles", {}))
	if finale:
		finale.from_dict(d.get("finale", {}))
	# Partidas antiguas: "done" pasaba directamente al final de la misión 1
	if state == "done":
		state = "guayota"
