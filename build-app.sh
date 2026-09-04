#!/bin/bash
# Slepí aplikaci a data do jednoho HTML souboru, který funguje bez serveru.
#
#   ./build-app.sh                          appka nad data/
#   ./build-app.sh artefakt                 verze pro publikaci jako Artifact
#   ./build-app.sh web data/lidi/karel      appka nad daty jiného člověka
#
# Každý člověk má vlastní složku dat — vlastní cviky, postupy i plán.
# Aplikace je jen slupka; co v ní bude, určuje složka.
#
# Vstup:  app/index.html (žádná data v kódu) + data/cviky.json, sablony.json,
#         plany/aktualni.json
# Výstup: app/dist/ai-trener.html — jde poslat, otevřít z Files, hostovat kdekoliv.
#
# Zdrojová aplikace zůstává bez dat; ta se vkládají až sem, do buildu.
# Viz DECISIONS.md 2026-09-04 — v kódu aplikace nesmí být cviky natvrdo.

cd "$(dirname "$0")" || exit 1
mkdir -p dist

DATA="${2:-data}"
[ -d "$DATA" ] || { echo "CHYBA: složka $DATA neexistuje."; exit 1; }

if [ -f "$DATA/plany/aktualni.json" ]; then
  ./kontrola-plan.sh "$DATA/plany/aktualni.json" >/dev/null ||
    { echo "CHYBA: plán neprošel kontrolou, build zastaven."; exit 1; }
fi

# Varianta pro Artifact: publikuje se jen obsah stránky, kostru dodá platforma.
python3 - "${1:-web}" "$DATA" <<'PY'
import json, io

import sys, os
rezim = sys.argv[1] if len(sys.argv) > 1 else "web"
dd = sys.argv[2] if len(sys.argv) > 2 else "data"

cviky = json.load(open(f"{dd}/cviky.json"))
sablony = json.load(open(f"{dd}/sablony.json"))
try:
    plan = json.load(open(f"{dd}/plany/aktualni.json"))
except FileNotFoundError:
    plan = None

# Obrázky: v datech je cesta (např. "obrazky/leg-press.jpg"), do buildu se
# vkládá obsah jako data URI — jinak by se v jednom souboru nenačetly.
import base64, mimetypes
chybi = []
for c in cviky["cviky"]:
    o = c.get("obrazek")
    if not o or o.startswith("data:"):
        continue
    cesta = os.path.join(dd, o)
    if not os.path.exists(cesta):
        chybi.append(o); c.pop("obrazek"); continue
    typ = mimetypes.guess_type(cesta)[0] or "image/jpeg"
    c["obrazek"] = f"data:{typ};base64," + base64.b64encode(open(cesta, "rb").read()).decode()
if chybi:
    print("POZOR: chybějící obrázky vynechány — " + ", ".join(chybi))

data = {"cviky": cviky["cviky"], "sloty": cviky["sloty"], "sablony": sablony, "plan": plan}
html = io.open("index.html", encoding="utf-8").read()

vlozka = ('<script>window.AI_TRENER_DATA = '
          + json.dumps(data, ensure_ascii=False).replace("</", "<\\/")
          + ';</script>\n')

znacka = "<script>\n\"use strict\";"
assert html.count(znacka) == 1, "nenašel jsem hlavní <script> — změnila se struktura index.html?"
html = html.replace(znacka, vlozka + znacka, 1)

# Jméno výstupu podle složky, ať se lidem soubory nepřepisují navzájem.
osoba = os.path.basename(dd.rstrip("/"))
pripona = "" if osoba == "data" else "-" + osoba

if rezim == "artefakt":
    # Artifact obalí soubor vlastním <!doctype>/<head>/<body>, takže se posílá
    # jen obsah — od <title> po </script>.
    zac = html.index("<title>")
    kon = html.rindex("</script>") + len("</script>")
    html = html[zac:kon] + "\n"
    cesta = f"dist/ai-trener{pripona}-artefakt.html"
else:
    cesta = f"dist/ai-trener{pripona}.html"

io.open(cesta, "w", encoding="utf-8").write(html)
s_obr = sum(1 for c in data["cviky"] if c.get("obrazek"))
print(f"{cesta} — {len(html):,} B, {len(data['cviky'])} cviků, {s_obr} s obrázkem"
      + (f", plán {plan['plati_od']} – {plan['plati_do']}" if plan else ", bez plánu"))
PY
