"""Descarga las texturas y modelos de Poly Haven (licencia CC0) que usa MAGEC.

Uso:  python3 tools/fetch_assets.py
Guarda en assets/textures/<nombre>/ y assets/models/<nombre>/.
Todo lo de Poly Haven es CC0: se puede usar libremente, también en juegos comerciales.
"""
import json
import os
import sys
import urllib.request

ROOT = os.path.join(os.path.dirname(__file__), "..", "assets")
API = "https://api.polyhaven.com/files/"
RES = "1k"

TEXTURES = [
    "rock_face",            # roca de acantilado
    "aerial_rocks_04",      # malpaís / lava
    "coast_sand_01",        # arena de playa
    "dry_ground_01",        # tierra seca
    "white_plaster_rough_01",  # paredes encaladas
    "weathered_planks",     # madera de puertas y muelle
    "brown_planks_05",      # cubierta del barco
    "white_planks_clean",   # casco pintado del barquillo
]
MODELS = [
    "boulder_01", "namaqualand_boulder_03", "namaqualand_boulder_05",
    "dutch_ship_medium",
    "ocean_buoy", "lifebuoy",
    "wooden_barrels_01", "wooden_crate_01", "Barrel_01",
    "wooden_lantern_01", "street_lamp_01", "fishermans_hat",
    "modular_wooden_pier",
    "shrub_02", "shrub_04", "wild_rooibos_bush",
]
MAPS = {"Diffuse": "albedo", "nor_gl": "normal", "Rough": "rough", "AO": "ao"}


def get(url, path):
    if os.path.exists(path) and os.path.getsize(path) > 0:
        return
    os.makedirs(os.path.dirname(path), exist_ok=True)
    req = urllib.request.Request(url, headers={"User-Agent": "magec-asset-fetcher"})
    with urllib.request.urlopen(req, timeout=120) as r, open(path, "wb") as f:
        f.write(r.read())
    print("  ", os.path.relpath(path, ROOT))


def files(asset):
    req = urllib.request.Request(API + asset, headers={"User-Agent": "magec-asset-fetcher"})
    with urllib.request.urlopen(req, timeout=60) as r:
        return json.load(r)


def fetch_texture(name):
    print("textura", name)
    f = files(name)
    for key, short in MAPS.items():
        if key in f and RES in f[key]:
            info = f[key][RES].get("jpg") or f[key][RES].get("png")
            ext = "jpg" if "jpg" in f[key][RES] else "png"
            get(info["url"], os.path.join(ROOT, "textures", name, "%s.%s" % (short, ext)))


def fetch_model(name):
    print("modelo", name)
    f = files(name)
    g = f["gltf"][RES]["gltf"]
    base = os.path.join(ROOT, "models", name)
    get(g["url"], os.path.join(base, name + ".gltf"))
    for rel, inc in g.get("include", {}).items():
        get(inc["url"], os.path.join(base, rel))


def normalize(name, target, keep_color):
    """Ajusta el brillo medio de una textura (y opcionalmente la pasa a gris) para
    que funcione como base que luego se tiñe en el juego."""
    from PIL import Image, ImageOps, ImageStat
    path = os.path.join(ROOT, "textures", name, "albedo.jpg")
    flag = path + ".normalizada"
    if not os.path.exists(path) or os.path.exists(flag):
        return
    im = Image.open(path).convert("RGB")
    if not keep_color:
        im = ImageOps.grayscale(im).convert("RGB")
    mean = sum(ImageStat.Stat(im).mean) / 3.0
    k = target / max(mean, 1.0)
    im = im.point(lambda v: min(255, int(v * k)))
    im.save(path, quality=92)
    open(flag, "w").close()
    print("   normalizada", name)


if __name__ == "__main__":
    for t in TEXTURES:
        fetch_texture(t)
    for m in MODELS:
        try:
            fetch_model(m)
        except Exception as e:  # algún modelo puede no tener gltf
            print("   (saltado)", m, e, file=sys.stderr)
    normalize("white_plaster_rough_01", 215, False)   # enlucido: gris claro neutro
    normalize("weathered_planks", 140, True)          # madera: más clara
    normalize("white_planks_clean", 205, False)       # casco: gris claro, lo tiñe la pintura
    with open(os.path.join(ROOT, "LICENCIA.txt"), "w") as f:
        f.write("Texturas y modelos de Poly Haven (https://polyhaven.com), licencia CC0.\n"
                "Dominio público: se pueden usar, modificar y distribuir sin restricciones.\n")
