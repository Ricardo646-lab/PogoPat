# PogoPat – Levelontwerp (100 levels)

Dit document beschrijft alle 100 levels zo precies dat ze één voor één gebouwd kunnen worden.
Elk level is met de hand ontworpen (geen willekeurige generator meer) en bestaat uit een rij
**bouwstenen** van links naar rechts. De bouwstenen zijn hieronder exact gedefinieerd (maten in tiles).

---

## 1. Vaste maten en regels

| Wat | Waarde |
|---|---|
| Tile | 70 × 70 px |
| Speler – botsing | 1 tile breed, 2 tiles hoog (142 px) |
| Speler – zichtbaar (met stick) | ~3 tiles hoog (222 px) → **onder een plafond altijd minstens 5 rijen lucht** |
| Max sprong (natuurkunde) | ~7 omhoog, ~13,8 ver op gelijke hoogte, ~10 ver bij 5 omhoog |
| Ontwerpregel sprong, level 1–49 | max **5 omhoog**, max **6 breed** gat |
| Ontwerpregel sprong, level 50–100 | max **6 omhoog**, max **8 breed** gat |
| Kleinste spike-kuil | **3 breed** (1–2 breed is saai) |
| Zwevende blokken | alleen boven veilige grond, **nooit recht boven spikes** |
| Bewegend platform | kuil eronder ≥ **17 breed** (anders spring je eroverheen) |
| Lift | klif ≥ **9 hoog** (anders spring je erop) |
| Decoratie | **geen** (afleidend). Alleen groene pijlborden in torens/schachten |
| Begin en eind | hoge muur (20 rijen boven het hoogste punt), niet uit het level te springen |
| Grond | loopt altijd door tot ver onder beeld, geen gaten zonder bodem |

**Obstakels (vaste maten)**

| Obstakel | Maat | Snelheden |
|---|---|---|
| Zaag | radius 100 (≈3 tiles doorsnee), op de grond half ingegraven | normaal 150, snel 320, razend 400 px/s |
| Verticale zaag | bovenste stand: midden 5 rijen boven de vloer, zakt 4 rijen (onderste stand blokkeert) | normaal 150, snel 250 |
| Sloopkogel | radius 80, ophangpunt 8 rijen boven de vloer, ketting 6,5 tiles, zwaait ±50°, bereik ±6 tiles | swing 1,6 (snel: 2,2) |
| Bewegend platform | 3 breed, 32 px dik | normaal 170, snel 230 |
| Lift | 3 breed | 170 |

**Kleine uitbreidingen die nodig zijn** (eenmalig bouwen):
1. `fase` voor sloopkogel (start-hoek, zodat kogels in tegenfase kunnen zwaaien).
2. `vertraging` voor zagen/platforms (start-offset in de baan, voor "golven").
3. Per obstakel een eigen snelheid (zaag, platform, kogel).
4. Een level-bestand: `LEVELS = { 1: [...bouwstenen...], 2: [...] }` dat de builder van links naar rechts afloopt.

---

## 2. Bouwstenen

### 2.1 Hoe je een level leest

Een level is een rij bouwstenen van links naar rechts, gescheiden door ` · `:
```
START(kort) · KUIL(5,1)+HANGZAAG(2,3,normaal,normaal) · OP(3,4) · FINISH(piek)
```
- `NAAM(a,b,c)` – een bouwsteen met zijn parameters. **Alle parameters zijn verplicht** (geen standaardwaarden).
- `A+B` – obstakel `B` hoort bij bouwsteen `A` (staat erop, erin of erboven, zie per bouwsteen).
- `A+B@plek` – zelfde, maar op een bepaalde plek binnen `A` (bv. `@richel 2`, `@trede 1,3`, `@kuil 2`, `@2`).
- **Vloer** = de grondhoogte waar je op dat moment staat. Hoogtes zijn in tiles; `+` = omhoog.
- Na elke bouwsteen ga je verder op de vloerhoogte waarop die bouwsteen eindigt (kolom "Hoogte" hieronder).
- In de ASCII-voorbeelden: `#` grond, `^` spikes, `.` lucht, `S` zaag, `W` ophangpunt kogel, `=` platformbaan.

**Waarden die vaker terugkomen**

| Parameter | Mogelijke waarden |
|---|---|
| snelheid zaag / hangzaag | `normaal` 150 · `snel` 320 · `razend` 400 (px/s) |
| snelheid verticale zaag | `normaal` 150 · `snel` 250 |
| snelheid kogel | `normaal` (swing 1,6) · `snel` (swing 2,2) |
| snelheid platform | `normaal` 170 · `snel` 230 |
| maat zaag | `klein` (radius 70) · `normaal` (radius 100) · `groot` (radius 130) |
| vertraging | 0 – 1 = waar in zijn heen-en-weer-beweging het obstakel begint (0,5 = precies andersom dan 0) |
| fase kogel | 0 – 359 graden; 0 = begint in het midden naar rechts, 180 = in het midden naar links |

### 2.2 Begin en eind

| Bouwsteen | Breedte | Hoogte | Beschrijving |
|---|---|---|---|
| `START(vlak)` | 8 | 0 | Hoge muur links, 8 vlak, speler op kolom 5. |
| `START(kort)` | 3 | 0 | Hoge muur links, 3 vlak, meteen actie. |
| `START(klif)` | 5 | 0 | Je start op een plateau van 5; het terrein links ervan is een hoge muur. De eerstvolgende bouwsteen gaat meestal omlaag. |
| `START(dal)` | 5 | 0 | Je start in een dal: links hoge muur, de eerste bouwsteen gaat omhoog. |
| `FINISH(plateau)` | 6 | 0 | 6 vlak, vlag op kolom 2, hoge muur rechts. |
| `FINISH(piek)` | 3+4 | +2 | Smalle top: `OP(2,3)` met de vlag erop, daarna 4 lager terug naar de muur (je kunt eraf vallen, dan gewoon weer op). |
| `FINISH(dal)` | 6 | −2 | `AF(2,6)` met de vlag beneden. |
| `FINISH(pilaar)` | 6 | +3 | Spike-kuil 3 breed, dan een pilaar van 3 breed en 3 hoog met de vlag erop, daarna muur. |
| `FINISH(dak)` | 4 | 0 | Vlag direct naast de uitgang van de vorige bouwsteen (toren, schacht, lift). |

Alle muren aan begin en eind zijn 12 rijen hoger dan het hoogste punt van het level.

**Finishgebied**: de grond onder de vlag (plateau 6 breed, piek 3, dal 6, pilaar 3, dak 4) krijgt een geel-zwarte streep (tiles 14,8 / 15,8). Overal op die gestreepte grond telt de finish (botsing over de hele breedte, tot 3 tiles hoog). De vlag staat in het midden.

### 2.3 Terrein

| Bouwsteen | Parameters | Breedte | Hoogte | Beschrijving |
|---|---|---|---|---|
| `VLAK(w)` | w ≥ 3 | w | 0 | Vlak stuk. **Alleen gebruiken met een obstakel erop** (`VLAK(7)+ZAAG(…)`); rust = `HEUVEL`. |
| `OP(h,w)` | h 1–5 (vanaf level 50: 1–6), w ≥ 1 | w | +h | Muur h omhoog, daarna w breed plateau. `+X` staat midden op het plateau. |
| `AF(h,w)` | h ≥ 1, w ≥ 1 | w | −h | Muur h omlaag, daarna w breed. |
| `HEUVEL(a,b,…)` | elk stapje −2 … +2 | 3 per stapje | som | Elk getal is één stapje van 3 breed (`0` = vlak stuk van 3). Voor rust en een levendig hoogteprofiel. |
| `TRAP(n,h,w)` | n ≥ 2, h 1–5, w ≥ 2 | n·w | +n·h | n treden omhoog. `+X@trede i,j` = obstakel midden op die treden (trede 1 = de onderste). |
| `TRAP-AF(n,h,w)` | zelfde | n·w | −n·h | n treden omlaag. |

```
OP(3,4):        AF(2,3):        HEUVEL(+1,+1,-2):        TRAP(3,2,3):
   ####         ###                ...###...               ......###
   ####         ###...             ###.....###             ...######
#######         ######          ###...........###          #########
                                ##################   (laatste stapje −2)
```

### 2.4 Kuilen en pilaren

| Bouwsteen | Parameters | Breedte | Hoogte | Beschrijving |
|---|---|---|---|---|
| `KUIL(w,d)` | w 3–6 (vanaf 50: 3–8), d 1–3 | w+2 | 0 | Spike-kuil w breed, d diep, spikes op de bodem, 2 vlak erna. `+HANGZAAG` hangt boven het midden van de kuil. |
| `KUIL-OP(w,h)` | w 3–6 (vanaf 50: 3–8), h −5…+5 (vanaf 50: +6) | w+2 | +h | Kuil (1 diep), de overkant ligt h hoger (negatief = lager). Landing 2 breed. |
| `DAL(w,d,s)` | w ≥ 6, d 2–5, s 0–(w−2) | w+2 | 0 | Dal met steile wanden, s spikes midden op de bodem. Eruit = d omhoog. |
| `PILAREN(h1/h2/…,b,g1/g2/…)` | hoogte per pilaar 1–5 (vanaf 50: 6), breedte b 1–3, gaten g 3–6 (vanaf 50: 8); er is 1 gat meer dan pilaren | som(g) + n·b + 2 | 0 | Pilaren boven spike-kuilen (1 diep). Gat 1 = vóór de eerste pilaar, het laatste gat = na de laatste pilaar. |
| `TREDEPILAREN(n,s,g)` | n ≥ 2, stijging s per pilaar (−2…+2), gat g | (n+1)·g + 2n + 2 | 2 + (n−1)·s | Pilaren van 2 breed; de eerste is 2 hoog, elke volgende s hoger. Na de laatste pilaar landt je op een plateau op de hoogte van de laatste pilaar. `+X@kuil i` = boven gat i. |

```
KUIL(4,2):     KUIL-OP(5,+2):    PILAREN(3/2,2,4/3/4):
###....###              ###      ......##.............
###....###     ###.....####      ......##...##........
###^^^^###     ###^^^^^####      ##....##...##....##
##########     ############      ##^^^^##^^^##^^^^##
```

### 2.5 Zagen

| Bouwsteen | Parameters | Breedte | Beschrijving |
|---|---|---|---|
| `ZAAG(t,snelheid,v,maat)` | baan t 1–10 tiles | t+4 | Zaag op de grond, half ingegraven (midden op de vloerlijn). Rijdt t tiles naar rechts en terug. Als `+ZAAG` op een plateau: midden op het plateau. |
| `HANGZAAG(y,t,snelheid,maat)` | y = hoogte van het midden boven de vloer (2–7), baan t | (geen, altijd met `+`) | Zwevende zaag, rijdt horizontaal. Boven een kuil: baan gecentreerd boven de kuil. In een lift (`LIFT+HANGZAAG`): y = hoogte boven de liftbodem, baan kruist de liftschacht. In een schacht (`@richel i`): y boven die richel, baan over de hele schachtbreedte. |
| `VZAAG(t,snelheid,v)` | slag t 3–5 | 4 | Verticale zaag. Bovenste stand: midden 5 rijen boven de vloer (je kunt eronder door). Hij zakt t rijen: slag 3 = midden 2 boven de vloer, slag 5 = midden op de vloer. In alle gevallen blokkeert de onderste stand. |

**Rijtjes zagen** worden altijd los uitgeschreven (`VZAAG(3,snel,0) · VZAAG(4,snel,0.17) · …`) zodat elke zaag zijn eigen slag en vertraging heeft. Een golf = elke volgende zaag een iets grotere vertraging.

```
ZAAG(2,…):            VZAAG(4,…) bovenste en onderste stand:
....S-->..                 S            .
###(S)#####                .            .
                           .            .
                           .            .
                           .            S
                        ######       ######
```

### 2.6 Sloopkogel

| Bouwsteen | Parameters | Breedte | Beschrijving |
|---|---|---|---|
| `KOGEL(k,f,snelheid)` | ketting k 5–7, fase f | 2k+1 | Ophangpunt k+2 rijen boven de vloer, midden van de bouwsteen. Radius 80. Bereik ±(k·0,77+1,1) tiles. |
| `KOGEL(k,f,snelheid,muur h)` | + muur h 3–6 | 2k+4 | Na het bereik van de kogel een muur van h hoog met een plateau van 3: geraakt = splat. Daarna sta je op de muur (**hoogte +h**). |
| `KOGEL(k,f,snelheid,rand)` | | 4 | Ophangpunt 2 tiles na de rand van het vorige plateau (bv. bovenaan een lift): je moet eraf stappen als de kogel weg zwaait. |
| `KOGEL-KUIL(w,k,f,snelheid)` | kuil w | max(w+2, 2k+1) | Kogel boven het midden van een spike-kuil (1 diep). |
| `KOGEL-KUIL(w,k,f,snelheid,muur h)` | + muur | idem + 3 | Na de kuil een muur van h hoog met een plateau van 3 (**hoogte +h**). |

Doorgerekend voor elke k: op het laagste punt blokkeert de kogel (25 px ruimte), aan het uiteinde van de zwaai kun je eronderdoor (k5: 162 px, k6: 187 px, k7: 212 px; speler 142 px).
`+KOGEL` bij een platform/trede: ophangpunt k+2 boven dat platform/die trede.

### 2.7 Platforms en liften

| Bouwsteen | Parameters | Breedte | Hoogte | Beschrijving |
|---|---|---|---|---|
| `PLATFORM(w,snelheid,v)` | kuil w 17–22 | w+3 | 0 | Spike-kuil w breed (2 diep), platform (3 breed) rijdt van de linker- naar de rechterrand. Te breed om over te springen. `+X` hangt boven het midden van de baan. |
| `PLATFORMS(n,snelheid,v)` | n 2–3 | 9n+3 | 0 | n platforms naast elkaar, elk een baan van 9; ze rijden gelijk op, gat ertussen 6. `+X@i` = boven baan i. |
| `LIFT(h)` | h ≥ 9 | 9 | +h | 3 aanloop, liftschacht 3 breed, klif van h hoog erachter; boven stap je naar rechts. `+HANGZAAG(y,…)` kruist de schacht op hoogte y. |
| `LIFT-OVER(h,w)` | h ≥ 9, w 4–6 (vanaf 50: 8) | 6+w+3 | +h | Lift omhoog, boven spring je w breed naar de overkant (geen klif naast de lift, onder je spikes). |
| `LIFT-AF(h)` | h ≥ 9 | 12 | −h | 3 vlak bovenop, liftschacht van 3 (de lift pendelt tussen beneden en boven), 3 spikes beneden, 3 vlak beneden. Stap op de lift als hij boven is en spring beneden over de spikes. |

### 2.8 Torens en schachten

| Bouwsteen | Parameters | Breedte | Hoogte | Beschrijving |
|---|---|---|---|---|
| `TOREN(n,richting,inhoud)` | n = 3 of 5, richting `op`/`omlaag`, inhoud = n woorden met `/` (verdieping 1 eerst) | 22 | op: +6(n−1), omlaag: −6(n−1) | Zie ASCII. Woorden: `spikes` (3 spikes midden), `zaag` (ZAAG(4,normaal,0,normaal) over de vloer), `zaag-snel` (ZAAG(4,snel,0,normaal)), `leeg`, `vzaag` (alleen de bovenste verdieping, open lucht). |
| `SCHACHT(h,richting,r)` | h 12–24, richting `op`/`omlaag`, richel-afstand r 3 of 4 | 9 | op: +h, omlaag: −h | Klimwand van 9 breed. Aan de uitgangskant een muur van h hoog (staat op de grond, uitgang bovenop). Aan de ingangskant **geen muur** (die zou zweven): de richels daar zijn losse opstapjes van 2 breed boven het veilige stuk grond. Richels om en om, elke r rijen (richel 1 = onderste, aan de muurkant). Bodem: spikes behalve 3 tiles bij de ingang. `+HANGZAAG(…)@richel i,j` = zaag y boven die richel, baan midden over de schacht. `omlaag` = gespiegeld. |

```
TOREN(3,op,spikes/leeg/spikes):
.##...................
.##....R..^^^.........   verdieping 3 (uitgang rechts)
.##....###############
.##..................#
.####................#   opstapje
.####...........L....#   verdieping 2
.################....#
...................###   opstapje
...........^^^.....###   verdieping 1
######################

SCHACHT(12,op,4):
........#   <- uitgang bovenop de muur (+12)
........#
........#
........#
.##.....#   richel 2 (los opstapje, boven veilige grond)
........#
........#
........#
......###   richel 1 (vast aan de muur)
........#
........#
...^^^^^#   spikes, links 3 veilig
#########
```
Toren: vloeren 6 rijen uit elkaar (5 rijen lucht), gat naar boven 4 breed, opstapje 2×2 tegen de muur (van opstapje naar volgende vloer = 4 omhoog). `omlaag` = gespiegeld, je valt door de gaten.

### 2.9 Vormen

Elk level heeft één vorm: `KLIM` · `AFDALING` · `VALLEI` (omlaag, dan omhoog) · `BERG` (omhoog, dan omlaag) · `GOLF` (steeds op en neer) · `PLATEAU` (hoog en druk) · `TRAPPEN` · `ZIGZAG` (toren/schacht) · `KLOOF` (grote sprongen) · `RACE` (snel en lang).

---

## 3. Opbouw

**Level 1–16 = introductie.** Elk level laat iets nieuws zien. Na level 16 heb je **alle** obstakels gezien:

| Level | Nieuw | | Level | Nieuw |
|---|---|---|---|---|
| 1 | hoppen, kleine stapjes | | 9 | dal + pilaren |
| 2 | volle sprong | | 10 | toren |
| 3 | spike-kuilen | | 11 | hangzaag |
| 4 | zaag | | 12 | kogel met splat-muur + kogel boven kuil |
| 5 | verticale zaag | | 13 | schacht |
| 6 | sloopkogel | | 14 | snelle zaag + golf (tegenfase) |
| 7 | bewegend platform | | 15 | lift naar beneden + meerdere platforms |
| 8 | lift | | 16 | toren en schacht naar beneden |

**Variatie-regels** (worden met een script gecontroleerd):
1. Vanaf level 17 minstens **3 verschillende soorten obstakels** per level.
2. Een bouwsteen met **precies dezelfde parameters** komt niet terug binnen 5 levels.
3. Een **paar** opeenvolgende bouwstenen (A gevolgd door B, met parameters) komt niet terug binnen 10 levels.
4. Twee opeenvolgende levels hebben nooit dezelfde **vorm**, hetzelfde **begin** of hetzelfde **eind**.
5. Geen `VLAK` als opvulling: rust = `HEUVEL` of een breed plateau (`OP(h,w)` met grote w). `VLAK` alleen met een obstakel erop.
6. Alle parameters ingevuld en binnen de grenzen van hoofdstuk 2 (het script controleert dit).

| Wereld | Levels | Hoogtepunt | Lengte (tiles) |
|---|---|---|---|
| 1 De Bouwplaats | 1–10 | introductie | 23–59 |
| 2 De Steengroeve | 11–20 | introductie, dan omhoog | 34–104 |
| 3 De Zagerij | 21–30 | grote zaag-momenten | 37–79 |
| 4 De Sloopwijk | 31–40 | kogel-momenten | 36–94 |
| 5 De Hoogbouw | 41–50 | torens en schachten | 32–82 |
| 6 De Kloof | 51–60 | grote sprongen (6 hoog / 8 ver) | 44–115 |
| 7 De Fabriek | 61–70 | timing-combinaties | 38–96 |
| 8 De Mijn | 71–80 | diep naar beneden | 37–79 |
| 9 De Storm | 81–90 | snelheid, strakke sterren | 43–127 |
| 10 De Top | 91–100 | de finale, steeds hoger | 42–165 |

Elk 10e level is een **finale** en eindigt hoger dan de start. Sterren: ⭐⭐⭐ = eerste tijd, ⭐⭐ = tweede tijd.

---

## 4. Alle levels

### Wereld 1 – De Bouwplaats (introductie)

**1. Eerste Hop** – KLIM · *onboarding, vlag op de berg al in beeld*
`START(vlak) · OP(1,3) · OP(1,3) · OP(2,4) · FINISH(piek)`
Profiel: ~25 tiles · hoogste +6 · laagste +0 · eind +6
Tutorial-borden. ⭐ 9 / 18

**2. Opladen** – BERG · *nieuw: volle sprong*
`START(kort) · OP(3,4) · OP(5,3) · AF(3,4) · AF(2,3) · FINISH(dal)`
Profiel: ~23 tiles · hoogste +8 · laagste +0 · eind +1
⭐ 9 / 18

**3. Au!** – GOLF · *nieuw: spike-kuilen*
`START(vlak) · KUIL(3,1) · HEUVEL(+1,-1) · KUIL(4,2) · OP(2,3) · KUIL-OP(5,-2) · FINISH(plateau)`
Profiel: ~41 tiles · hoogste +2 · laagste -2 · eind +0
⭐ 12 / 24

**4. Zaagje** – PLATEAU · *nieuw: zaag*
`START(kort) · ZAAG(3,normaal,0,klein) · OP(2,6) · KUIL(3,2) · ZAAG(2,normaal,0,normaal) · HEUVEL(+1) · FINISH(piek)`
Profiel: ~37 tiles · hoogste +5 · laagste +0 · eind +5
⭐ 13 / 26

**5. Valbijl** – VALLEI · *nieuw: verticale zaag*
`START(klif) · AF(3,4) · VZAAG(4,normaal,0) · KUIL(4,1) · VZAAG(3,snel,0) · OP(3,3) · OP(2,3) · FINISH(plateau)`
Profiel: ~35 tiles · hoogste +2 · laagste -4 · eind +2
⭐ 12 / 24

**6. Sloopkogel** – TRAPPEN · *nieuw: kogel*
`START(vlak) · TRAP(2,1,3) · KOGEL(6,0,normaal) · TRAP(2,1,2) · ZAAG(2,normaal,0,klein) · KUIL(5,1) · FINISH(dal)`
Profiel: ~50 tiles · hoogste +4 · laagste +0 · eind +2
⭐ 15 / 30

**7. Glijbaan** – KLOOF · *nieuw: bewegend platform*
`START(kort) · KUIL(3,3) · PLATFORM(17,normaal,0) · OP(3,4) · VZAAG(4,normaal,0.5) · FINISH(piek)`
Profiel: ~43 tiles · hoogste +5 · laagste -3 · eind +5
⭐ 15 / 30

**8. De Lift** – KLIM · *nieuw: lift*
`START(dal) · KUIL(5,2) · LIFT(9) · KOGEL(5,0,normaal) · AF(3,3) · FINISH(plateau)`
Profiel: ~41 tiles · hoogste +9 · laagste -2 · eind +6
⭐ 15 / 30

**9. Pilaren en Dal** – VALLEI · *nieuw: dal + pilaren*
`START(vlak) · DAL(8,4,3) · PILAREN(3/2/3,2,4/3/4/4) · ZAAG(2,normaal,0.5,normaal) · FINISH(pilaar)`
Profiel: ~53 tiles · hoogste +3 · laagste -4 · eind +3
⭐ 15 / 30

**10. Drie Hoog** – ZIGZAG · *nieuw: toren · finale*
`START(kort) · ZAAG(2,normaal,0,groot) · TOREN(3,op,spikes/leeg/spikes) · KOGEL(7,0,normaal,muur 3) · KUIL-OP(4,+2) · FINISH(dak)`
Profiel: ~59 tiles · hoogste +17 · laagste +0 · eind +17
⭐ 19 / 38

### Wereld 2 – De Steengroeve

**11. Hangzaag** – KLOOF · *nieuw: zaag boven een kuil*
`START(vlak) · KUIL(5,1)+HANGZAAG(2,3,normaal,normaal) · HEUVEL(+2,-1) · KUIL-OP(5,+1)+HANGZAAG(3,2,snel,normaal) · VZAAG(5,normaal,0) · FINISH(plateau)`
Profiel: ~38 tiles · hoogste +2 · laagste -1 · eind +2
⭐ 13 / 26

**12. Splat!** – BERG · *nieuw: splat-muur + kogel boven kuil*
`START(kort) · OP(2,3) · KOGEL(6,0,normaal,muur 4) · KUIL(3,2) · KOGEL-KUIL(5,5,0,normaal) · AF(3,3) · ZAAG(2,normaal,0,klein) · FINISH(dal)`
Profiel: ~53 tiles · hoogste +6 · laagste +0 · eind +1
⭐ 17 / 34

**13. Gevelklimmer** – ZIGZAG · *nieuw: schacht*
`START(vlak) · SCHACHT(12,op,4) · KUIL(4,2) · VZAAG(3,normaal,0) · FINISH(piek)`
Profiel: ~34 tiles · hoogste +14 · laagste +0 · eind +14
⭐ 13 / 26

**14. De Golf** – GOLF · *nieuw: snelle zaag + tegenfase*
`START(klif) · ZAAG(4,snel,0,normaal) · HEUVEL(+1,+1) · VZAAG(4,normaal,0) · VZAAG(4,normaal,0.5) · HEUVEL(-2) · KOGEL(6,0,normaal) · KOGEL(6,180,normaal) · FINISH(plateau)`
Profiel: ~62 tiles · hoogste +2 · laagste +0 · eind +0
⭐ 19 / 38

**15. Mijnlift** – VALLEI · *nieuw: lift omlaag + meerdere platforms*
`START(vlak) · OP(5,3) · OP(4,2) · LIFT-AF(10) · PLATFORMS(2,normaal,0) · OP(2,3) · FINISH(dal)`
Profiel: ~55 tiles · hoogste +9 · laagste -3 · eind -1
⭐ 20 / 40

**16. Ondergronds** – AFDALING · *nieuw: toren en schacht omlaag*
`START(klif) · TOREN(3,omlaag,leeg/zaag/spikes) · ZAAG(3,normaal,0,normaal) · OP(4,3) · SCHACHT(12,omlaag,3) · KOGEL-KUIL(5,6,0,normaal) · FINISH(plateau)`
Profiel: ~65 tiles · hoogste +0 · laagste -21 · eind -20
Vanaf hier ken je alles. ⭐ 19 / 38

**17. Bergbeklimmer** – KLIM
`START(vlak) · OP(3,3) · KUIL(3,1) · VZAAG(4,snel,0) · OP(4,4) · KOGEL(5,90,normaal) · OP(5,3) · ZAAG(2,normaal,0,groot) · OP(2,5) · FINISH(piek)`
Profiel: ~56 tiles · hoogste +16 · laagste +0 · eind +16
⭐ 19 / 38

**18. Tweede Verdieping** – ZIGZAG
`START(kort) · TOREN(3,op,zaag/spikes/leeg) · KUIL(4,2)+HANGZAAG(2,2,normaal,normaal) · PLATFORM(18,normaal,0.5) · FINISH(plateau)`
Profiel: ~58 tiles · hoogste +12 · laagste +0 · eind +12
⭐ 20 / 40

**19. Liftschacht** – KLOOF
`START(dal) · LIFT-OVER(10,5) · KUIL(5,2)+HANGZAAG(3,3,normaal,normaal) · KOGEL(7,0,normaal,muur 3) · LIFT(9) · FINISH(piek)`
Profiel: ~60 tiles · hoogste +24 · laagste -1 · eind +24
⭐ 24 / 48

**20. Steengroeve-finale** – KLIM
`START(vlak) · PILAREN(2/4,3,4/5/4) · LIFT(10)+HANGZAAG(5,3,normaal,normaal) · TREDEPILAREN(3,+1,4) · KOGEL(6,0,normaal,muur 3) · TOREN(3,op,spikes/zaag/vzaag) · FINISH(dak)`
Profiel: ~104 tiles · hoogste +29 · laagste -1 · eind +29
⭐ 34 / 68

### Wereld 3 – De Zagerij

**21. Snelle Zagen** – RACE
`START(kort) · ZAAG(4,snel,0,normaal) · KUIL(4,2) · KOGEL(5,45,normaal) · ZAAG(5,snel,0.5,klein) · OP(3,4) · FINISH(plateau)`
Profiel: ~47 tiles · hoogste +3 · laagste -2 · eind +3
⭐ 15 / 30

**22. Zaagtrap** – TRAPPEN · *hoogtepunt: verticale zaag op elke trede*
`START(vlak) · OP(2,5)+VZAAG(3,normaal,0) · OP(2,5)+VZAAG(4,normaal,0.3) · OP(2,5)+VZAAG(5,snel,0) · KOGEL-KUIL(5,6,0,normaal) · FINISH(piek)`
Profiel: ~43 tiles · hoogste +8 · laagste +0 · eind +8
⭐ 16 / 32

**23. Zaagkloof** – KLOOF · *hoogtepunt: hangzagen boven kuil en platform*
`START(klif) · KUIL(5,1)+HANGZAAG(2,3,normaal,normaal) · PLATFORM(19,normaal,0)+HANGZAAG(4,4,normaal,normaal) · KUIL-OP(5,+1)+HANGZAAG(2,3,snel,groot) · FINISH(plateau)`
Profiel: ~47 tiles · hoogste +1 · laagste -2 · eind +1
⭐ 17 / 34

**24. Tegenfase** – VALLEI
`START(vlak) · AF(3,2) · VZAAG(4,normaal,0) · VZAAG(4,normaal,0.5) · LIFT(9) · KOGEL(6,270,normaal) · VZAAG(3,snel,0) · FINISH(piek)`
Profiel: ~51 tiles · hoogste +8 · laagste -3 · eind +8
⭐ 20 / 40

**25. Zaagplateau** – PLATEAU
`START(kort) · KUIL(4,1) · VLAK(7)+ZAAG(3,snel,0,normaal) · KUIL(6,2) · SCHACHT(12,op,3) · FINISH(dak)`
Profiel: ~37 tiles · hoogste +12 · laagste -2 · eind +12
Je landt op het plateau terwijl de zaag erover rijdt. ⭐ 14 / 28

**26. Zaagbrug** – KLOOF
`START(vlak) · PLATFORM(17,normaal,0)+VZAAG(4,normaal,0) · PILAREN(3/3/4,1,3/4/4/3) · ZAAG(2,snel,0,klein) · FINISH(dal)`
Profiel: ~59 tiles · hoogste +4 · laagste -2 · eind -2
⭐ 19 / 38

**27. Zagenregen** – ZIGZAG · *hoogtepunt: golf van drie verticale zagen*
`START(kort) · VZAAG(5,normaal,0) · VZAAG(5,normaal,0.3) · VZAAG(5,normaal,0.6) · TOREN(3,op,leeg/spikes/zaag) · KUIL(5,1) · FINISH(plateau)`
Profiel: ~50 tiles · hoogste +12 · laagste +0 · eind +12
⭐ 18 / 36

**28. Razend** – GOLF
`START(klif) · AF(3,1) · ZAAG(5,razend,0,normaal) · OP(4,3) · KOGEL(7,0,normaal,muur 3) · KUIL(5,2) · FINISH(dal)`
Profiel: ~49 tiles · hoogste +4 · laagste -3 · eind +2
⭐ 15 / 30

**29. Zaagtoren** – KLIM
`START(vlak) · TOREN(3,op,zaag/zaag/vzaag) · KOGEL-KUIL(5,5,0,normaal) · LIFT(9) · ZAAG(3,snel,0,groot) · FINISH(piek)`
Profiel: ~64 tiles · hoogste +23 · laagste +0 · eind +23
⭐ 23 / 46

**30. Zagerij-finale** – RACE
`START(kort) · ZAAG(3,snel,0,normaal) · KUIL(5,1)+HANGZAAG(2,3,normaal,normaal) · VZAAG(3,normaal,0.2) · VZAAG(5,normaal,0.5) · PLATFORM(18,normaal,0)+VZAAG(3,snel,0) · KOGEL(6,0,normaal) · OP(3,2) · ZAAG(4,razend,0,groot) · OP(3,4) · FINISH(pilaar)`
Profiel: ~79 tiles · hoogste +9 · laagste -2 · eind +9
⭐ 27 / 54

### Wereld 4 – De Sloopwijk

**31. Over de Kuil** – PLATEAU
`START(vlak) · KOGEL-KUIL(5,6,0,normaal) · ZAAG(3,snel,0,klein) · PILAREN(2/3,2,4/4/3) · OP(2,4) · FINISH(plateau)`
Profiel: ~55 tiles · hoogste +3 · laagste -1 · eind +2
⭐ 16 / 32

**32. Dubbel** – GOLF · *hoogtepunt: twee kogels in tegenfase*
`START(kort) · HEUVEL(+1,-1) · KOGEL(5,0,normaal) · KOGEL(7,180,normaal) · VZAAG(4,normaal,0.2) · OP(3,3) · KUIL(4,3) · FINISH(dal)`
Profiel: ~54 tiles · hoogste +3 · laagste +0 · eind +1
⭐ 16 / 32

**33. Steegje** – VALLEI
`START(klif) · AF(3,2) · KOGEL(6,0,normaal,muur 3) · PLATFORM(17,normaal,0.6) · KUIL(4,1) · FINISH(plateau)`
Profiel: ~55 tiles · hoogste +0 · laagste -3 · eind +0
Links de wand, rechts de muur: geraakt = altijd splat. ⭐ 17 / 34

**34. Kogel en Zaag** – KLIM
`START(vlak) · KOGEL(6,300,normaal) · VZAAG(5,normaal,0) · KUIL(5,1)+HANGZAAG(2,2,normaal,klein) · OP(3,3) · OP(2,2) · FINISH(piek)`
Profiel: ~44 tiles · hoogste +7 · laagste -1 · eind +7
⭐ 15 / 30

**35. Bouwkraan** – BERG · *hoogtepunt: kogel aan de rand bij de lift*
`START(dal) · LIFT(9) · KOGEL(5,0,normaal,rand) · ZAAG(3,normaal,0,normaal) · AF(4,3) · KUIL(5,2) · FINISH(dal)`
Profiel: ~41 tiles · hoogste +9 · laagste +0 · eind +3
Stap van de lift af als de kogel weg zwaait. ⭐ 16 / 32

**36. Kogeltrap** – TRAPPEN
`START(vlak) · TRAP(3,2,3)+KOGEL(6,0,normaal)@trede 2 · SCHACHT(12,op,4) · ZAAG(2,normaal,0,groot) · FINISH(dak)`
Profiel: ~36 tiles · hoogste +18 · laagste +0 · eind +18
⭐ 15 / 30

**37. Sloopkuil** – AFDALING
`START(klif) · KOGEL-KUIL(6,6,0,normaal,muur 4) · ZAAG(2,snel,0,normaal) · TOREN(3,omlaag,spikes/zaag/leeg) · FINISH(dal)`
Profiel: ~55 tiles · hoogste +4 · laagste -10 · eind -10
⭐ 17 / 34

**38. Drie Kogels** – RACE · *hoogtepunt: golf van kogels*
`START(kort) · KOGEL(5,0,normaal) · KOGEL(6,60,normaal) · KOGEL(7,120,normaal) · VZAAG(4,normaal,0) · VZAAG(3,snel,0.5) · KUIL(6,1) · OP(3,5) · FINISH(plateau)`
Profiel: ~69 tiles · hoogste +3 · laagste -1 · eind +3
⭐ 21 / 42

**39. Sloopput** – VALLEI
`START(vlak) · AF(6,2) · KOGEL(5,0,snel) · OP(3,2) · OP(3,3) · PLATFORMS(2,normaal,0.3) · KUIL(4,2) · FINISH(piek)`
Profiel: ~60 tiles · hoogste +2 · laagste -6 · eind +2
⭐ 19 / 38

**40. Sloopwijk-finale** – BERG
`START(klif) · KOGEL-KUIL(5,7,0,normaal) · OP(2,3) · KOGEL(6,0,normaal,muur 3) · KOGEL(5,30,normaal) · KOGEL(5,210,normaal) · LIFT(10) · KOGEL(6,0,normaal,rand) · VZAAG(4,snel,0) · AF(4,3) · ZAAG(3,snel,0.5,normaal) · FINISH(plateau)`
Profiel: ~94 tiles · hoogste +15 · laagste -1 · eind +11
Eindigt 6 hoger dan de start. ⭐ 31 / 62

### Wereld 5 – De Hoogbouw

**41. Wolkenkrabber** – ZIGZAG · *hoogtepunt: toren van 5*
`START(vlak) · TOREN(5,op,spikes/leeg/zaag/spikes/leeg) · KOGEL(6,120,normaal) · KUIL(5,2) · FINISH(dak)`
Profiel: ~54 tiles · hoogste +24 · laagste +0 · eind +24
⭐ 19 / 38

**42. Lift en Toren** – KLIM
`START(kort) · LIFT(9) · TOREN(3,op,zaag/leeg/spikes) · KUIL(5,1)+HANGZAAG(2,3,snel,normaal) · FINISH(piek)`
Profiel: ~48 tiles · hoogste +23 · laagste +0 · eind +23
⭐ 19 / 38

**43. Zigzag** – BERG · *toren op, toren af*
`START(vlak) · TOREN(3,op,spikes/zaag/leeg) · VZAAG(5,snel,0.4) · TOREN(3,omlaag,leeg/spikes/zaag) · ZAAG(4,snel,0,klein) · FINISH(dal)`
Profiel: ~70 tiles · hoogste +12 · laagste -2 · eind -2
⭐ 22 / 44

**44. Penthouse** – PLATEAU
`START(kort) · TOREN(3,op,leeg/spikes/vzaag) · KOGEL-KUIL(5,5,0,normaal) · ZAAG(2,normaal,0.3,groot) · FINISH(plateau)`
Profiel: ~48 tiles · hoogste +12 · laagste +0 · eind +12
⭐ 16 / 32

**45. Hijskraan** – KLOOF
`START(vlak) · TOREN(3,op,zaag/spikes/leeg) · KOGEL(7,0,normaal,muur 3) · PLATFORM(20,normaal,0.4) · FINISH(piek)`
Profiel: ~78 tiles · hoogste +17 · laagste +0 · eind +17
⭐ 25 / 50

**46. Trappenhuis** – TRAPPEN
`START(klif) · AF(2,3) · TRAP(5,3,7)+KUIL(3,1)@trede 2,4 · VZAAG(4,normaal,0) · VZAAG(5,normaal,0.5) · KOGEL(6,90,normaal) · FINISH(pilaar)`
Profiel: ~70 tiles · hoogste +16 · laagste -2 · eind +16
⭐ 22 / 44

**47. Gevelklimmer II** – ZIGZAG · *hoogtepunt: hoge schacht met hangzagen*
`START(kort) · SCHACHT(16,op,4)+HANGZAAG(2,3,normaal,klein)@richel 1,3 · ZAAG(3,snel,0,normaal) · KUIL(5,2) · FINISH(plateau)`
Profiel: ~32 tiles · hoogste +16 · laagste +0 · eind +16
⭐ 14 / 28

**48. Valschacht** – AFDALING
`START(klif) · SCHACHT(16,omlaag,3) · LIFT-AF(10) · KOGEL(6,45,normaal) · FINISH(dal)`
Profiel: ~45 tiles · hoogste +0 · laagste -28 · eind -28
⭐ 15 / 30

**49. Torenrace** – RACE
`START(kort) · TOREN(5,op,zaag/zaag/spikes/zaag/vzaag) · KOGEL(5,0,snel) · PLATFORMS(2,snel,0) · FINISH(plateau)`
Profiel: ~63 tiles · hoogste +24 · laagste +0 · eind +24
⭐ 23 / 46

**50. De Grote Stap** – KLIM · *finale, vanaf nu 6 hoog / 8 ver*
`START(vlak) · SCHACHT(12,op,3) · OP(6,3) · KUIL(8,2) · OP(6,4) · TOREN(3,op,spikes/zaag/leeg) · KOGEL(7,0,normaal) · VZAAG(5,snel,0) · FINISH(piek)`
Profiel: ~82 tiles · hoogste +38 · laagste +0 · eind +38
Uitlegbord bij de eerste OP(6): "volle kracht!". ⭐ 28 / 56

### Wereld 6 – De Kloof

**51. Lange Sprong** – KLOOF
`START(kort) · KUIL(7,1) · ZAAG(3,normaal,0,klein) · KUIL(8,3) · VZAAG(4,normaal,0) · KUIL-OP(7,+2) · FINISH(plateau)`
Profiel: ~48 tiles · hoogste +2 · laagste -3 · eind +2
⭐ 14 / 28

**52. Kloofbrug** – VALLEI
`START(klif) · AF(4,2) · PLATFORMS(2,normaal,0) · KOGEL-KUIL(7,6,0,normaal) · KUIL-OP(6,+4) · FINISH(piek)`
Profiel: ~56 tiles · hoogste +2 · laagste -6 · eind +2
⭐ 18 / 36

**53. Overkant** – KLIM · *ver én hoger*
`START(vlak) · KUIL-OP(6,+3) · KUIL-OP(6,+3)+HANGZAAG(3,3,normaal,normaal) · KUIL-OP(5,-4) · LIFT(9) · FINISH(dak)`
Profiel: ~44 tiles · hoogste +11 · laagste -1 · eind +11
⭐ 17 / 34

**54. Hoog en Ver** – BERG
`START(kort) · OP(6,3) · KUIL(8,1) · VZAAG(5,normaal,0) · OP(6,2) · KOGEL(7,0,normaal,muur 4) · AF(5,3) · FINISH(dal)`
Profiel: ~49 tiles · hoogste +16 · laagste +0 · eind +9
⭐ 17 / 34

**55. Kloofpilaren** – GOLF · *hoogtepunt: hoge pilaren, grote gaten*
`START(vlak) · PILAREN(4/5/3,2,6/5/6/4) · TREDEPILAREN(3,+2,5)+HANGZAAG(3,2,normaal,klein)@kuil 3 · KOGEL(5,150,normaal) · ZAAG(3,snel,0,groot) · FINISH(pilaar)`
Profiel: ~89 tiles · hoogste +9 · laagste -1 · eind +9
⭐ 26 / 52

**56. Kloofkogel** – ZIGZAG
`START(kort) · KOGEL-KUIL(8,7,0,normaal) · TOREN(3,op,spikes/spikes/zaag) · KOGEL-KUIL(7,6,0,normaal,muur 4) · FINISH(plateau)`
Profiel: ~62 tiles · hoogste +16 · laagste -1 · eind +16
⭐ 20 / 40

**57. Snelle Brug** – KLOOF
`START(vlak) · PLATFORM(20,snel,0)+VZAAG(4,snel,0) · OP(3,2) · KUIL(8,2) · SCHACHT(12,op,4) · FINISH(dak)`
Profiel: ~56 tiles · hoogste +15 · laagste -2 · eind +15
⭐ 20 / 40

**58. Diepe Kloof** – VALLEI
`START(klif) · SCHACHT(16,omlaag,4) · ZAAG(4,razend,0,normaal) · SCHACHT(16,op,3) · KOGEL(5,0,normaal) · FINISH(piek)`
Profiel: ~49 tiles · hoogste +2 · laagste -16 · eind +2
⭐ 18 / 36

**59. Sprongenreeks** – RACE · *hoogtepunt: vier krachtsprongen op rij*
`START(kort) · KUIL-OP(8,0) · KUIL-OP(7,+2) · KUIL-OP(8,-3) · KUIL-OP(6,+4) · KOGEL(6,200,normaal) · VZAAG(3,snel,0) · FINISH(plateau)`
Profiel: ~63 tiles · hoogste +3 · laagste -2 · eind +3
Landingen van 2 breed, geen rust. ⭐ 18 / 36

**60. Kloof-finale** – KLIM
`START(vlak) · PLATFORMS(3,normaal,0) · KUIL-OP(8,+2) · PILAREN(5/5,3,6/6/5) · KOGEL-KUIL(8,5,0,normaal) · LIFT-OVER(12,7) · ZAAG(4,razend,0,klein) · FINISH(piek)`
Profiel: ~115 tiles · hoogste +16 · laagste -2 · eind +16
⭐ 34 / 68

### Wereld 7 – De Fabriek

**61. Lopende Band** – PLATEAU · *hoogtepunt: drie platforms met een zaag erboven*
`START(kort) · PLATFORMS(3,normaal,0)+HANGZAAG(4,2,normaal,normaal)@2 · VZAAG(5,normaal,0.4) · OP(3,4) · FINISH(plateau)`
Profiel: ~47 tiles · hoogste +3 · laagste -2 · eind +3
⭐ 16 / 32

**62. Pers** – RACE · *vier snelle verticale zagen als persen*
`START(vlak) · VZAAG(4,snel,0) · VZAAG(4,snel,0.25) · VZAAG(4,snel,0.5) · VZAAG(4,snel,0.75) · KOGEL(5,30,normaal) · KUIL(6,3) · FINISH(dal)`
Profiel: ~49 tiles · hoogste +0 · laagste -3 · eind -2
⭐ 16 / 32

**63. Zaagbaan** – GOLF
`START(kort) · ZAAG(10,snel,0,normaal) · OP(3,2) · KOGEL-KUIL(6,6,0,normaal) · AF(2,1) · ZAAG(10,razend,0,klein) · FINISH(plateau)`
Profiel: ~53 tiles · hoogste +3 · laagste +0 · eind +1
Rijd de zaag voor of spring eroverheen. ⭐ 16 / 32

**64. Fabriekshal** – ZIGZAG
`START(vlak) · TOREN(3,op,zaag/zaag/leeg) · KOGEL(6,150,normaal) · LIFT(9) · KUIL(6,1) · FINISH(piek)`
Profiel: ~67 tiles · hoogste +23 · laagste +0 · eind +23
⭐ 23 / 46

**65. Kogel & Zaag** – VALLEI
`START(klif) · AF(4,2) · KOGEL(5,0,normaal) · VZAAG(3,normaal,0) · KOGEL(7,90,normaal) · VZAAG(5,normaal,0.5) · OP(5,3) · KUIL(6,2) · FINISH(plateau)`
Profiel: ~58 tiles · hoogste +1 · laagste -4 · eind +1
⭐ 18 / 36

**66. Liftzaag** – KLIM · *zaag kruist de lift*
`START(dal) · LIFT(12)+HANGZAAG(6,3,normaal,normaal) · KUIL(5,3) · KOGEL(6,240,normaal) · FINISH(dak)`
Profiel: ~38 tiles · hoogste +12 · laagste +0 · eind +12
⭐ 16 / 32

**67. Productielijn** – KLOOF
`START(vlak) · PLATFORM(20,normaal,0)+KOGEL(6,0,normaal) · OP(2,3) · VZAAG(4,normaal,0.3) · VZAAG(4,normaal,0.8) · FINISH(plateau)`
Profiel: ~48 tiles · hoogste +2 · laagste -2 · eind +2
⭐ 17 / 34

**68. Stempel** – TRAPPEN
`START(kort) · OP(2,5)+VZAAG(3,normaal,0) · OP(2,5)+VZAAG(4,normaal,0.25) · OP(2,5)+VZAAG(5,normaal,0.5) · OP(2,5)+VZAAG(4,normaal,0.75) · KOGEL-KUIL(6,5,0,normaal) · FINISH(piek)`
Profiel: ~41 tiles · hoogste +10 · laagste +0 · eind +10
⭐ 16 / 32

**69. Overuren** – RACE
`START(vlak) · ZAAG(4,snel,0,groot) · KUIL-OP(7,+2) · VZAAG(4,normaal,0.1) · KOGEL(6,0,normaal,muur 3) · PLATFORM(17,normaal,0.7) · ZAAG(3,razend,0,normaal) · SCHACHT(12,op,3) · FINISH(dak)`
Profiel: ~85 tiles · hoogste +17 · laagste -1 · eind +17
⭐ 28 / 56

**70. Fabriek-finale** – ZIGZAG
`START(kort) · PLATFORMS(2,normaal,0.5) · TOREN(3,op,zaag/spikes/zaag) · VZAAG(5,normaal,0) · VZAAG(5,normaal,0.5) · KOGEL(6,0,normaal) · KOGEL(6,180,normaal) · LIFT(12)+HANGZAAG(7,3,snel,normaal) · FINISH(piek)`
Profiel: ~96 tiles · hoogste +26 · laagste -2 · eind +26
⭐ 34 / 68

### Wereld 8 – De Mijn

**71. Mijnschacht** – AFDALING · *hoogtepunt: diepe schacht omlaag*
`START(klif) · OP(6,2) · SCHACHT(20,omlaag,4)+HANGZAAG(2,3,snel,normaal)@richel 2,4 · KOGEL(7,0,normaal) · FINISH(dal)`
Profiel: ~37 tiles · hoogste +6 · laagste -16 · eind -16
⭐ 13 / 26

**72. Afdaling** – TRAPPEN
`START(vlak) · OP(6,3) · TRAP-AF(4,4,8)+KUIL(4,1)@trede 1,2,3 · VZAAG(4,snel,0.2) · ZAAG(3,snel,0,klein) · FINISH(plateau)`
Profiel: ~60 tiles · hoogste +6 · laagste -10 · eind -10
⭐ 17 / 34

**73. Mijnlift** – VALLEI
`START(kort) · OP(6,3) · OP(5,2) · LIFT-AF(11) · KOGEL-KUIL(6,6,0,normaal) · OP(3,3) · ZAAG(2,normaal,0,groot) · FINISH(piek)`
Profiel: ~49 tiles · hoogste +11 · laagste -1 · eind +5
⭐ 19 / 38

**74. Toren Omlaag** – ZIGZAG
`START(klif) · TOREN(5,omlaag,zaag/spikes/zaag/leeg/spikes) · PLATFORM(17,snel,0) · FINISH(dal)`
Profiel: ~53 tiles · hoogste +0 · laagste -26 · eind -26
⭐ 16 / 32

**75. Kogelmijn** – AFDALING
`START(vlak) · AF(4,2) · KOGEL-KUIL(7,6,0,normaal,muur 4) · AF(4,3) · KOGEL(5,120,normaal) · VZAAG(4,normaal,0.6) · FINISH(plateau)`
Profiel: ~50 tiles · hoogste +0 · laagste -5 · eind -4
⭐ 16 / 32

**76. Diepe Val** – KLOOF
`START(klif) · OP(6,2) · SCHACHT(20,omlaag,3)+HANGZAAG(2,3,normaal,groot)@richel 3 · PLATFORM(19,normaal,0.2) · KOGEL(7,60,normaal) · FINISH(piek)`
Profiel: ~60 tiles · hoogste +6 · laagste -16 · eind -12
⭐ 20 / 40

**77. Mijnkarretjes** – GOLF · *platforms trapsgewijs omlaag*
`START(kort) · PLATFORM(17,normaal,0) · AF(3,2) · PLATFORM(18,snel,0)+KOGEL(6,0,normaal) · AF(3,2) · PLATFORM(20,normaal,0.5)+VZAAG(4,normaal,0) · FINISH(dal)`
Profiel: ~77 tiles · hoogste +0 · laagste -8 · eind -8
⭐ 26 / 52

**78. Kristalgrot** – BERG
`START(vlak) · OP(6,2) · OP(6,2) · TREDEPILAREN(5,-2,6)+HANGZAAG(3,3,normaal,normaal)@kuil 3 · KOGEL(5,0,normaal) · FINISH(pilaar)`
Profiel: ~77 tiles · hoogste +14 · laagste +0 · eind +9
⭐ 23 / 46

**79. De Bodem** – KLIM
`START(dal) · KUIL(6,2) · LIFT(14) · KOGEL(6,0,normaal,rand) · ZAAG(3,snel,0,normaal) · OP(5,2) · FINISH(piek)`
Profiel: ~42 tiles · hoogste +21 · laagste -2 · eind +21
⭐ 18 / 36

**80. Mijn-finale** – VALLEI
`START(klif) · TOREN(3,omlaag,spikes/zaag/leeg) · LIFT-AF(11) · KOGEL-KUIL(8,7,0,normaal,muur 5) · LIFT(14)+HANGZAAG(7,3,normaal,normaal) · SCHACHT(16,op,4) · FINISH(dak)`
Profiel: ~79 tiles · hoogste +12 · laagste -24 · eind +12
Eindigt hoger dan de start. ⭐ 31 / 62

### Wereld 9 – De Storm

Sterrentijden zijn strak: ⭐⭐⭐ vraagt om doorspringen zonder te wachten.

**81. Sprint** – RACE
`START(kort) · ZAAG(4,snel,0,normaal) · ZAAG(4,snel,0.5,klein) · KUIL(6,1) · ZAAG(5,razend,0,normaal) · KOGEL(5,0,snel) · FINISH(plateau)`
Profiel: ~53 tiles · hoogste +0 · laagste -1 · eind +0
⭐ 16 / 32

**82. Windvlaag** – KLOOF
`START(vlak) · PLATFORMS(3,snel,0) · KUIL-OP(8,+3) · VZAAG(4,snel,0) · PLATFORM(21,snel,0.5) · FINISH(piek)`
Profiel: ~83 tiles · hoogste +5 · laagste -2 · eind +5
⭐ 25 / 50

**83. Hagel** – GOLF · *hoogtepunt: zes verticale zagen*
`START(kort) · VZAAG(3,snel,0) · VZAAG(4,snel,0.17) · HEUVEL(+1) · VZAAG(5,snel,0.33) · VZAAG(5,snel,0.5) · HEUVEL(+1) · VZAAG(4,snel,0.67) · VZAAG(3,snel,0.83) · PLATFORM(17,normaal,0.1) · KOGEL(6,0,snel) · FINISH(dal)`
Profiel: ~72 tiles · hoogste +2 · laagste +0 · eind +0
⭐ 25 / 50

**84. Bliksem** – KLOOF
`START(klif) · KUIL(6,2)+HANGZAAG(2,4,razend,normaal) · KUIL-OP(7,+2)+HANGZAAG(2,4,razend,klein) · KOGEL(7,0,snel,muur 4) · FINISH(plateau)`
Profiel: ~46 tiles · hoogste +6 · laagste -2 · eind +6
⭐ 15 / 30

**85. Orkaan** – VALLEI · *drie snelle kogels*
`START(vlak) · AF(3,2) · KUIL(7,2) · KOGEL(5,40,snel) · KOGEL(6,120,snel) · KOGEL(7,240,snel,muur 4) · ZAAG(4,snel,0,groot) · FINISH(piek)`
Profiel: ~76 tiles · hoogste +3 · laagste -5 · eind +3
⭐ 22 / 44

**86. Stormtoren** – ZIGZAG
`START(kort) · TOREN(5,op,zaag-snel/zaag-snel/spikes/zaag-snel/vzaag) · KOGEL(7,90,snel) · KUIL(8,3) · FINISH(plateau)`
Profiel: ~56 tiles · hoogste +24 · laagste +0 · eind +24
⭐ 19 / 38

**87. Golfslag** – GOLF
`START(vlak) · PILAREN(4/3/5/4,2,6/5/6/6/5)+HANGZAAG(2,2,snel,klein)@kuil 1,2,3,4,5 · VZAAG(4,snel,0) · VZAAG(4,snel,0.5) · FINISH(pilaar)`
Profiel: ~60 tiles · hoogste +5 · laagste -1 · eind +3
⭐ 18 / 36

**88. Donder** – KLIM
`START(dal) · LIFT(14)+HANGZAAG(7,3,snel,normaal) · KOGEL(5,0,normaal,rand) · KUIL(8,1) · ZAAG(4,razend,0,normaal) · FINISH(piek)`
Profiel: ~43 tiles · hoogste +16 · laagste +0 · eind +16
⭐ 18 / 36

**89. Oog van de Storm** – PLATEAU · *rustig begin, chaos aan het eind*
`START(vlak) · HEUVEL(+1,+1,0,0) · ZAAG(4,razend,0,groot) · VZAAG(5,snel,0) · KOGEL(6,0,snel,muur 4) · PLATFORM(20,snel,0)+VZAAG(3,snel,0) · FINISH(plateau)`
Profiel: ~77 tiles · hoogste +6 · laagste +0 · eind +6
⭐ 24 / 48

**90. Storm-finale** – RACE
`START(kort) · ZAAG(5,razend,0.3,groot) · PLATFORMS(3,snel,0) · TOREN(3,op,zaag/spikes/vzaag) · KOGEL(5,300,snel) · KOGEL(7,180,snel) · SCHACHT(16,op,3) · VZAAG(5,snel,0.05) · VZAAG(4,snel,0.17) · VZAAG(3,snel,0.33) · VZAAG(3,snel,0.5) · VZAAG(4,snel,0.67) · VZAAG(5,snel,0.83) · FINISH(dak)`
Profiel: ~127 tiles · hoogste +28 · laagste -2 · eind +28
⭐ 42 / 84

### Wereld 10 – De Top

Elk level eindigt hoger dan de start; de finale (100) heeft het hoogste punt van het spel.

**91. Basiskamp** – KLIM
`START(vlak) · TRAP(4,3,4) · KUIL-OP(7,+2) · ZAAG(3,snel,0.3,normaal) · LIFT(12) · PILAREN(4/5/4,2,6/6/5/6) · KOGEL(6,0,normaal) · OP(6,3) · FINISH(piek)`
Profiel: ~103 tiles · hoogste +34 · laagste +0 · eind +34
⭐ 33 / 66

**92. Gletsjer** – KLOOF
`START(kort) · PLATFORMS(3,normaal,0.2) · PLATFORM(20,snel,0)+HANGZAAG(4,3,normaal,normaal) · PLATFORMS(2,snel,0)+KOGEL(7,0,normaal)@1 · OP(5,3) · FINISH(dak)`
Profiel: ~84 tiles · hoogste +5 · laagste -2 · eind +5
⭐ 28 / 56

**93. IJswand** – ZIGZAG · *twee schachten boven elkaar*
`START(vlak) · SCHACHT(16,op,4)+HANGZAAG(2,3,normaal,normaal)@richel 2 · KOGEL(5,330,normaal) · SCHACHT(18,op,3) · FINISH(piek)`
Profiel: ~44 tiles · hoogste +36 · laagste +0 · eind +36
⭐ 20 / 40

**94. Lawine** – AFDALING · *alles naar beneden*
`START(klif) · OP(6,2) · SCHACHT(20,omlaag,3)+HANGZAAG(2,3,snel,klein)@richel 2,4 · TOREN(5,omlaag,zaag/zaag/spikes/zaag/leeg) · LIFT(14) · FINISH(dak)`
Profiel: ~51 tiles · hoogste +6 · laagste -38 · eind -24
⭐ 20 / 40

**95. Bergkam** – BERG
`START(vlak) · TREDEPILAREN(6,+2,7) · KOGEL-KUIL(8,7,0,normaal) · TREDEPILAREN(4,-2,7)+HANGZAAG(3,3,normaal,groot)@kuil 2 · VZAAG(5,snel,0.3) · FINISH(dal)`
Profiel: ~141 tiles · hoogste +14 · laagste -1 · eind +6
⭐ 36 / 72

**96. Hangbrug** – KLOOF
`START(kort) · PLATFORM(20,normaal,0)+KOGEL(6,0,normaal) · PLATFORM(22,snel,0)+KOGEL(6,180,normaal) · VZAAG(4,snel,0.5) · OP(6,3) · FINISH(piek)`
Profiel: ~65 tiles · hoogste +8 · laagste -2 · eind +8
⭐ 23 / 46

**97. Stormklim** – ZIGZAG
`START(vlak) · TOREN(5,op,zaag/spikes/zaag/spikes/vzaag) · LIFT(13) · SCHACHT(16,op,4) · KOGEL(7,0,snel) · FINISH(dak)`
Profiel: ~67 tiles · hoogste +53 · laagste +0 · eind +53
⭐ 28 / 56

**98. Laatste Fabriek** – RACE
`START(kort) · ZAAG(6,razend,0,normaal) · VZAAG(3,snel,0) · VZAAG(4,snel,0.25) · VZAAG(5,snel,0.5) · VZAAG(4,snel,0.75) · KUIL(8,2)+HANGZAAG(3,4,razend,normaal) · PLATFORM(20,normaal,0)+VZAAG(4,snel,0) · TOREN(3,op,zaag/zaag/zaag) · KOGEL(6,0,snel) · FINISH(plateau)`
Profiel: ~103 tiles · hoogste +12 · laagste -2 · eind +12
⭐ 34 / 68

**99. De Muur** – ZIGZAG · *één gigantische wand*
`START(vlak) · SCHACHT(24,op,4)+HANGZAAG(2,3,snel,normaal)@richel 2,4,5 · KOGEL(7,0,snel,muur 6) · OP(6,3) · FINISH(dak)`
Profiel: ~42 tiles · hoogste +36 · laagste +0 · eind +36
⭐ 19 / 38

**100. De Top** – KLIM · *de grote finale*
`START(kort) · PLATFORMS(3,snel,0) · TOREN(5,op,spikes/zaag/spikes/zaag/vzaag) · KOGEL(6,60,snel) · KOGEL(7,180,snel) · LIFT(14)+HANGZAAG(7,3,snel,normaal) · SCHACHT(24,op,3) · PILAREN(5/6/5,2,7/6/7/7) · KOGEL-KUIL(8,7,0,normaal,muur 6) · OP(6,4) · FINISH(piek)`
Profiel: ~165 tiles · hoogste +76 · laagste -2 · eind +76
De hoogste vlag van het spel; bij de camera-preview vanaf de start zie je alleen lucht. ⭐ 56 / 112

---

## 5. Checklist bij het bouwen van een level

1. Bouwstenen van links naar rechts plaatsen; vloerhoogte bijhouden.
2. Controle: geen gat > regel, geen OP > regel (behalve LIFT/SCHACHT/TOREN, die hebben eigen hulp).
3. Controle: overal waar een plafond is, minstens 5 rijen lucht.
4. Controle: geen zwevend blok recht boven spikes; spike-stroken ≥ 3.
5. Muren aan begin en eind ≥ 20 rijen boven het hoogste punt.
6. Vanaf level 17: minstens 3 verschillende soorten obstakels.
7. Variatie-regels uit hoofdstuk 3 (script: geen herhaalde bouwsteen binnen 5 levels, geen herhaald paar binnen 10, vorm/begin/eind nooit 2x achter elkaar).
8. Screenshot op echte zoom (0,5) bekijken, één keer zelf spelen, sterrentijden bijstellen.
