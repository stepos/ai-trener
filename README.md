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

## Vyzkoušet

Otevři `index.html`, nebo si stáhni `dist/ai-trener.html` — to je celá
aplikace i s daty v jednom souboru, který jde poslat mailem a otevřít offline.

## Vlastní data

V repu je ukázková sada: 44 cviků ve 12 slotech, full body A/B třikrát týdně.
**Vem ji jako příklad, ne jako doporučení** — série, opakování a výběr cviků
si nastav podle sebe, ideálně s někým, kdo tvoje tělo zná.

Tři soubory:

| Soubor | Co v něm je |
|---|---|
| `data/cviky.json` | cviky, jejich provedení a sloty (partie) |
| `data/sablony.json` | jednotky A/B a šablony pro trénink podle nálady |
| `data/plany/aktualni.json` | vygenerovaný plán s datumy — čte ho aplikace |

Plán se generuje ze šablon, cviky do něj nepatří — každý blok nese jen slot
a k němu seznam rovnocenných voleb:

```bash
./generuj-plan.sh mesic      # 28 dní, střídá A a B, drží 48 h mezi tréninky
./kontrola-plan.sh           # ověří, že plán sedí na databázi cviků
./build-app.sh               # dist/ai-trener.html — jeden soubor i s daty
```

Obrázky ke cvikům jsou nepovinné: ulož obrázek do `data/obrazky/` pod
názvem cviku (`leg-press.jpg`) a spusť `./obrazky.sh`.

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
