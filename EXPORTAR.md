# Cómo crear el ejecutable de MAGEC (Windows)

El proyecto ya trae la configuración de exportación (`export_presets.cfg`) y el icono.
Solo hace falta hacerlo una vez en tu PC:

1. Abre el proyecto en **Godot 4.3** (o más nuevo).
2. Menú **Editor → Administrar plantillas de exportación… → Descargar e instalar**.
   (Son unos 1 GB; solo se descargan la primera vez.)
3. Menú **Proyecto → Exportar…**
4. Elige el preset **Windows** y pulsa **Exportar proyecto**.
   - Desmarca **"Exportar con depuración"** para la versión final.
   - Guarda el archivo como `Magec.exe` donde quieras (por ejemplo en el escritorio).
5. Listo: `Magec.exe` es un solo archivo (lleva todo dentro) y funciona en cualquier
   Windows de 64 bits sin instalar nada. Puedes pasárselo a quien quieras.

## Subirlo a itch.io (opcional, gratis)
1. Crea una cuenta en https://itch.io y pulsa **Upload new project**.
2. Tipo: **Downloadable**. Sube un ZIP con `Magec.exe` y marca **Windows**.
3. Pon capturas, una descripción y publícalo (puede ser privado con enlace).

## Requisitos para jugar
- Windows 10/11 de 64 bits.
- Tarjeta gráfica compatible con Vulkan (cualquiera de los últimos 8-10 años).
- En portátiles u ordenadores de oficina, pon **Calidad gráfica: Baja** en Opciones
  (el juego lo detecta solo la primera vez si la gráfica es integrada).
