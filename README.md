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
| Esc | Recoger sedal |

## Qué hay en esta versión

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
