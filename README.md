# AI trenér

Webová aplikace, která vede trénink v posilovně. **Bez instalace, bez účtu,
bez serveru** — je to jedna stránka, která funguje i offline.

Nepočítá za tebe, nic nevymýšlí a nikam neposílá data. Přečte si plán ze
souborů, provede tě tréninkem a zapíše, co jsi odcvičil.

## Co umí

- **Trénink podle plánu** — jednotky mají datum, aplikace najde tu dnešní.
- **Trénink podle nálady** — vybereš partie, aplikace složí bloky ze šablon.
  Další partii jde přidat i uprostřed tréninku.
- **U každého bloku 3–4 rovnocenné cviky.** Když je stroj obsazený, ťukneš na
  náhradu a jedeš dál. Tohle je celý důvod, proč aplikace vznikla.
- **Zápis sérií na dvě ťuknutí**, s odpočtem pauzy. Výchozí váha se bere
  z historie, ne od nuly.
- **U cviku je popsané provedení**, časté chyby a dech.
- Historie zůstává v prohlížeči, dá se vyexportovat jako JSON.

## V repu nejsou žádná data

Aplikace je **prázdná slupka**. Neobsahuje jediný cvik ani plán — všechno si
načte z tvojí složky, kterou vybereš při prvním spuštění. Data zůstávají u tebe,
nikam se neposílají a nic se nikam nepřihlašuje.

Je to schválně: tréninkový plán je věc, která má odpovídat konkrétnímu člověku,
jeho zdraví a cílům. Sdílený „univerzální" plán by byl v lepším případě
k ničemu, v horším škodlivý.

## Co potřebuje ve složce

Tři soubory:

| Soubor | Co v něm je |
|---|---|
| `data/cviky.json` | cviky, jejich provedení a sloty (partie) |
| `data/sablony.json` | jednotky A/B a šablony pro trénink podle nálady |
| `plany/aktualni.json` | vygenerovaný plán s datumy — podle nich se řídí |

### `cviky.json`

```json
{
  "schema": 1,
  "sloty": [ { "id": "kvadricepsy", "nazev": "Kvadricepsy", "partie": "nohy" } ],
  "cviky": [
    {
      "id": "leg-press",
      "nazev": "Leg press",
      "sloty": ["kvadricepsy"],
      "typ": "stroj",
      "provedeni": ["Záda opřená o opěrku.", "Kolena nepropínat."],
      "chyby": ["odlepení kříže od opěrky"],
      "dech": "výdech při tlaku"
    }
  ]
}
```

### `plany/aktualni.json`

Blok neurčuje cvik, ale **slot** a k němu 3–4 rovnocenné volby. Proto obsazený
stroj nezdrží — ťukneš na náhradu a jedeš dál.

```json
{
  "schema": 1,
  "jednotky": [
    {
      "datum": "2026-09-05",
      "typ": "A",
      "nazev": "Full body A",
      "bloky": [
        { "poradi": 1, "slot": "kvadricepsy", "serie": 3, "opakovani": "10-12",
          "rezerva": "3", "pauza_s": 165,
          "volby": ["leg-press", "hack-drep", "predkopavani"] }
      ]
    }
  ]
}
```

`sablony.json` má stejné bloky bez datumů — z nich se skládá trénink podle
nálady a generuje plán.

### Skripty

Nepovinné. Když si soubory píšeš ručně, nepotřebuješ je.

```bash
./generuj-plan.sh mesic      # plán na 28 dní ze šablon, drží 48 h mezi tréninky
./kontrola-plan.sh           # ověří, že plán sedí na databázi cviků
./obrazky.sh                 # zapojí obrázky ze složky obrazky/
./build-app.sh               # aplikace i s tvými daty v jednom souboru
```

Obrázky jsou nepovinné: ulož je do `obrazky/` pod názvem cviku
(`leg-press.jpg`) a spusť `./obrazky.sh`.

## Jak je to postavené

Aplikace je **jen rozhraní**. Neobsahuje žádná data natvrdo — všechno si tahá
ze souborů. Přidání cviku nebo nový plán proto není nová verze aplikace.

Jeden soubor, žádné závislosti, žádný build krok pro běh. Historie
v `localStorage`, na Macu v Chrome umí zapisovat rovnou do zvolené složky
(File System Access API); v Safari a na iOS se složka načte a historie
exportuje ručně.

## Upozornění

Tohle není zdravotnická aplikace ani náhrada za trenéra. Vznikla jako osobní
nástroj a je zveřejněná, protože se může hodit i někomu dalšímu. Za to, co
zvedneš, si odpovídáš sám.

## Licence

MIT, viz `LICENSE`.
