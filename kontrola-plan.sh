#!/bin/bash
# Kontrola vygenerovaného plánu proti databázi cviků.
# Tichá chyba v plánu se jinak projeví až v posilovně.
#
#   ./kontrola-plan.sh                              zkontroluje data/plany/aktualni.json
#   ./kontrola-plan.sh data/plany/plan-X.json       jiný soubor
#   ./kontrola-plan.sh data/lidi/karel/plany/aktualni.json   plán jiného člověka
#
# Databáze cviků se hledá vedle plánu (o dvě složky výš), protože každý člověk
# má svou vlastní — nic se mezi lidmi nesdílí.

cd "$(dirname "$0")" || exit 1
SOUBOR="${1:-data/plany/aktualni.json}"
[ -f "$SOUBOR" ] || { echo "CHYBÍ: $SOUBOR"; exit 1; }

python3 - "$SOUBOR" <<'PY'
import json, sys, datetime

soubor = sys.argv[1]
chyby = []
plan = json.load(open(soubor))
# plány leží v <slozka_dat>/plany/, databáze cviků tedy v <slozka_dat>/cviky.json
import os
dd = os.path.dirname(os.path.dirname(soubor)) or "data"
cviky = json.load(open(os.path.join(dd, "cviky.json")))
znama_id = {c["id"] for c in cviky["cviky"]}
znamé_sloty = {s["id"] for s in cviky["sloty"]}

if plan.get("schema") != 1:
    chyby.append(f"neznámá verze schématu: {plan.get('schema')}")

predchozi = None
for j in plan.get("jednotky", []):
    kde = f"jednotka {j.get('datum','?')}"
    try:
        d = datetime.date.fromisoformat(j["datum"])
    except Exception:
        chyby.append(f"{kde}: špatné datum"); continue
    if predchozi and (d - predchozi).days < 2:
        chyby.append(f"{kde}: jen {(d - predchozi).days} den od předchozího tréninku, plan.md žádá 48 h")
    predchozi = d

    if not j.get("bloky"):
        chyby.append(f"{kde}: žádné bloky")
    for b in j.get("bloky", []):
        kdeb = f"{kde}, blok {b.get('poradi','?')}"
        if b.get("slot") not in znamé_sloty:
            chyby.append(f"{kdeb}: neznámý slot '{b.get('slot')}'")
        for pole in ("serie", "opakovani", "rezerva"):
            if not b.get(pole):
                chyby.append(f"{kdeb}: chybí {pole}")
        volby = b.get("volby") or []
        if len(volby) < 2:
            chyby.append(f"{kdeb}: jen {len(volby)} volba — smysl je mít 3–4, ať se nečeká na stroj")
        for v in volby:
            if v not in znama_id:
                chyby.append(f"{kdeb}: cvik '{v}' není v {dd}/cviky.json")

print(f"--- {soubor}: {len(plan.get('jednotky', []))} jednotek")
if chyby:
    for c in chyby:
        print("  " + c)
    print(f"\nNALEZENO PROBLÉMŮ: {len(chyby)}")
    sys.exit(1)
print("\nOK — plán sedí na databázi cviků.")
PY
