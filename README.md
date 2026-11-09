# MAGEC

Juego de pesca y terror marino en las Islas Canarias. Acorán, pescador de Güímar,
sale al mar de día a pescar... y de noche lo que sale del agua ya no es normal.

## Cómo jugar

1. Descarga **Godot 4.3** (o más nuevo) desde https://godotengine.org/download
2. Abre Godot → **Importar** → elige el archivo `project.godot` de esta carpeta.
3. Pulsa **Play** (F5).

## Controles

| Tecla | Acción |
|---|---|
| WASD / flechas | Navegar |
| E | Pescar (junto a las burbujas) / entrar al puerto |
| Espacio | Golpe en el minijuego de pesca |
| F | Farol de Magec |
| I | Bodega |
| C | Cuaderno de especies |
| N | Echar nasa |
| R | Echar / recoger la red |
| Esc | Pausa / recoger sedal |

## Qué hay en esta versión

- 15 especies de Tenerife con su mutante. Cuatro minijuegos: normal, rápido (4 aciertos), zigzag y tirón (el agua dorada se mueve). De noche el agua dorada parpadea.
- Cuaderno de especies (C). Nasas (N) que se llenan con las horas y red de arrastre (R) que pesca mientras navegas.
- Menú principal (Continuar / Nueva partida / Opciones / Salir), pausa con Esc y opciones de volumen y pantalla completa.
- Guardado automático al dormir, al zarpar del puerto y al avanzar la misión; también se puede guardar desde la pausa.
- Cinemática de inicio (se salta con Esc o Espacio): Aridane y San Borondón, treinta años después, el temblor y el farol de Chaxiraxi.
- Sonido sintetizado: mar, viento, motor, timple de día, música inquietante de noche, latido con el miedo, golpes y efectos (`tools/gen_audio.py` los regenera).
- Misión 1 «La primera Piedra»: Chaxiraxi junto a las Pirámides de Güímar, diálogos, la Piedra de Magec de noche en el fondo y mejora del farol.
- Costa de Güímar con el Teide al fondo, muelle y casas.
- Mar con olas (shader), ciclo de día y noche; el tiempo pasa al navegar o pescar.
- 12 puntos de pesca en 3 zonas (orilla, aguas medias, fondo).
- 7 peces de Tenerife, cada uno con su versión mutante nocturna.
- Bodega tipo Tetris: cada pez ocupa una forma.
- Miedo de noche, ojos de Tibicena y golpes en el casco. El farol lo frena.
- Puerto: vender, pagar la deuda del barco, mejorar motor y bodega, dormir.

## Estructura

- `scenes/main.tscn` – escena principal.
- `scripts/main.gd` – mundo, barco y lógica del juego.
- `scripts/ui.gd` – interfaz (HUD, pesca, bodega, puerto).
- `scripts/data.gd` – peces y zonas.
- `shaders/ocean.gdshader` – el mar.
