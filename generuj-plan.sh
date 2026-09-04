#!/bin/bash
# Vygeneruje datovaný plán tréninků do data/plany/.
#
#   ./generuj-plan.sh              trénink na dnešek (1 jednotka)
#   ./generuj-plan.sh tyden        7 dní
#   ./generuj-plan.sh mesic        28 dní
#   ./generuj-plan.sh 14 2026-09-08    vlastní počet dní a začátek
#   ./generuj-plan.sh tyden "" data/lidi/karel   plán nad cizí složkou dat
#
# Třetí argument je složka s daty (výchozí `data`). Každý člověk má svou —
# vlastní cviky, vlastní šablony, vlastní plán. Nic se mezi lidmi nesdílí.
#
# Skládá jednotky A a B ze šablon v data/sablony.json, střídá je a drží
# 3 tréninky týdně s odstupem 48 h (dny 0, 2, 4 v každém týdnu) — viz plan.md.
# Cviky nevybírá: každý blok nese slot a k němu 3–4 rovnocenné volby
# z data/cviky.json. Volbu dělá cvičící v posilovně podle toho, co je volné.

cd "$(dirname "$0")" || exit 1

case "$1" in
  ""|dnes|dnesek) DNI=1 ;;
  tyden)          DNI=7 ;;
  mesic)          DNI=28 ;;
  *[!0-9]*)       echo "CHYBA: první argument je počet dní, 'tyden' nebo 'mesic'."; exit 1 ;;
  *)              DNI="$1" ;;
esac
OD="${2:-$(date +%Y-%m-%d)}"
[ -n "$OD" ] || OD=$(date +%Y-%m-%d)
DATA="${3:-data}"
[ -d "$DATA" ] || { echo "CHYBA: složka $DATA neexistuje."; exit 1; }

case "$OD" in
  [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]) ;;
  *) echo "CHYBA: datum musí být RRRR-MM-DD."; exit 1 ;;
esac

python3 - "$DNI" "$OD" "$DATA" <<'PY'
import json, sys, datetime, os

dni = int(sys.argv[1]); od = datetime.date.fromisoformat(sys.argv[2])
dd = sys.argv[3]
sab = json.load(open(f"{dd}/sablony.json"))
cviky = json.load(open(f"{dd}/cviky.json"))

volby = {}
for c in cviky["cviky"]:
    for s in c["sloty"]:
        volby.setdefault(s, []).append(c["id"])

# Tréninkové dny: v každém týdnu offsety 0, 2, 4 → 3× týdně, vždy aspoň 48 h.
dny = [d for t in range(0, dni, 7) for o in (0, 2, 4) if (d := t + o) < dni]

jednotky = []
for i, offset in enumerate(dny):
    typ = "A" if i % 2 == 0 else "B"
    sablona = sab["jednotky"][typ]
    bloky = []
    for poradi, b in enumerate(sablona["bloky"], 1):
        blok = {"poradi": poradi, "slot": b["slot"], "serie": b["serie"],
                "opakovani": b["opakovani"], "rezerva": b["rezerva"],
                "pauza_s": b["pauza_s"], "volby": volby.get(b["slot"], [])}
        if b.get("volitelne"):
            blok["volitelne"] = True
        bloky.append(blok)
    jednotky.append({"datum": (od + datetime.timedelta(days=offset)).isoformat(),
                     "typ": typ, "nazev": sablona["nazev"], "bloky": bloky})

plan = {"schema": 1,
        "vygenerovano": datetime.date.today().isoformat(),
        "plati_od": od.isoformat(),
        "plati_do": (od + datetime.timedelta(days=dni - 1)).isoformat(),
        "zdroj": f"{dd}/sablony.json + {dd}/cviky.json",
        "jednotky": jednotky}

os.makedirs(f"{dd}/plany", exist_ok=True)
cesta = f"{dd}/plany/plan-{od.isoformat()}.json"
with open(cesta, "w", encoding="utf-8") as f:
    json.dump(plan, f, ensure_ascii=False, indent=2)
    f.write("\n")
# Aplikace čte vždy stejné jméno, ať nemusí vědět, který plán je nejnovější.
with open(f"{dd}/plany/aktualni.json", "w", encoding="utf-8") as f:
    json.dump(plan, f, ensure_ascii=False, indent=2)
    f.write("\n")
print(f"Vygenerováno: {cesta} — {len(jednotky)} jednotek, {od} až {plan['plati_do']}")
print(f"Zkopírováno do: {dd}/plany/aktualni.json (odtud čte aplikace)")
PY
