#!/bin/bash
# Zapojí obrázky ze složky do databáze cviků.
#
#   ./obrazky.sh                 zpracuje data/obrazky/
#   ./obrazky.sh data/lidi/karel jiná složka dat
#
# Postup: ulož obrázek pod názvem cviku (např. `leg-press.jpg`) do
# <slozka>/obrazky/ a spusť tohle. Skript ho zmenší na 800 px, převede na JPEG
# a zapíše cestu ke cviku v cviky.json. Vypíše, které cviky obrázek ještě nemají.
#
# Obrázky stažené z wger jsou vedené v obrazky/zdroje.json a nesou autora
# a licenci. Co v tom seznamu není, bere se jako vlastní — bez licenční
# poznámky. Když vlastní obrázek přepíše wger, autor se odstraní.

cd "$(dirname "$0")" || exit 1
DATA="${1:-data}"
[ -d "$DATA/obrazky" ] || { echo "CHYBA: $DATA/obrazky neexistuje."; exit 1; }

python3 - "$DATA" <<'PY'
import json, os, sys, io, hashlib
from PIL import Image

dd = sys.argv[1]
slozka = f"{dd}/obrazky"
d = json.load(open(f"{dd}/cviky.json"))
try:
    wger = json.load(open(f"{slozka}/zdroje.json"))["wger"]
except Exception:
    wger = {}

znama = {c["id"] for c in d["cviky"]}
nalezene, cizi, prevedene = {}, [], []

for f in sorted(os.listdir(slozka)):
    zaklad, pripona = os.path.splitext(f)
    if pripona.lower() not in (".jpg", ".jpeg", ".png", ".webp"):
        continue
    if zaklad not in znama:
        cizi.append(f)
        continue
    cesta = os.path.join(slozka, f)
    cil = os.path.join(slozka, zaklad + ".jpg")
    im = Image.open(cesta)
    puvodni = im.size
    if im.mode != "RGB":
        pozadi = Image.new("RGB", im.size, (255, 255, 255))
        im = im.convert("RGBA")
        pozadi.paste(im, mask=im.split()[-1])
        im = pozadi
    if im.width > 800:
        im = im.resize((800, round(im.height * 800 / im.width)), Image.LANCZOS)
    if im.size != puvodni or pripona.lower() != ".jpg":
        im.save(cil, "JPEG", quality=78, optimize=True)
        if cesta != cil:
            os.remove(cesta)
        prevedene.append(f)
    nalezene[zaklad] = f"obrazky/{zaklad}.jpg"

odebrane = []
for c in d["cviky"]:
    cesta = nalezene.get(c["id"])
    if not cesta:
        # Soubor zmizel (smazaný, přejmenovaný) — odkaz musí zmizet taky,
        # jinak by aplikace ukazovala prázdné místo po obrázku.
        if c.pop("obrazek", None):
            c.pop("obrazek_zdroj", None)
            c.pop("obrazek_poznamka", None)
            odebrane.append(c["nazev"])
        continue
    c["obrazek"] = cesta
    # Licence se připojí, jen když soubor opravdu je ten stažený z wger.
    # Jakmile ho přepíšeš vlastním, otisk nesedí a cizí autor zmizí — jinak
    # by se vlastní obrázek tvářil pod cizí licencí.
    zapsany = wger.get(c["id"])
    otisk = hashlib.sha256(open(os.path.join(slozka, c["id"] + ".jpg"), "rb").read()).hexdigest()[:16]
    if zapsany and zapsany.get("otisk") == otisk:
        c["obrazek_zdroj"] = {k: v for k, v in zapsany.items() if k != "otisk"}
    else:
        c.pop("obrazek_zdroj", None)
        c.pop("obrazek_poznamka", None)   # poznámka patřila k tomu cizímu obrázku

io.open(f"{dd}/cviky.json", "w", encoding="utf-8").write(
    json.dumps(d, ensure_ascii=False, indent=2) + "\n")

chybi = [c["nazev"] for c in d["cviky"] if not c.get("obrazek")]
vlastni = sum(1 for c in d["cviky"] if c.get("obrazek") and not c.get("obrazek_zdroj"))
print(f"Obrázků v databázi: {len(nalezene)} z {len(d['cviky'])} cviků "
      f"({vlastni} vlastních, {len(nalezene)-vlastni} z wger)")
if prevedene:
    print("Zmenšeno / převedeno na JPEG: " + ", ".join(prevedene))
if odebrane:
    print("Obrázek zmizel ze složky, odkaz odebrán: " + ", ".join(odebrane))
if cizi:
    print("Nepatří k žádnému cviku (přejmenuj podle id): " + ", ".join(cizi))
if chybi:
    print(f"\nBez obrázku ({len(chybi)}):")
    for n in chybi:
        print("  " + n)
print("\nPotom: ./build-app.sh")
PY
