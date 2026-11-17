"""Controleert Docs/LEVELS.md.

    python Docs/check_levels.py            # alleen controleren
    python Docs/check_levels.py --schrijf  # controleren + profielregel onder elk level bijwerken

Controleert:
  * elke bouwsteen: bestaat, alle parameters ingevuld, waarden binnen de grenzen van hoofdstuk 2
  * variatie-regels van hoofdstuk 3 (herhaling, vorm/begin/eind, minstens 3 soorten obstakels)
  * finales (10, 20, ... 100) eindigen hoger dan de start
Berekent per level: lengte in tiles, hoogste en laagste punt, eindhoogte.
"""
import re
import sys

sys.stdout.reconfigure(encoding='utf-8')
PAD = 'Docs/LEVELS.md'
tekst = open(PAD, encoding='utf-8').read()

SNEL_ZAAG = {'normaal', 'snel', 'razend'}
SNEL_2 = {'normaal', 'snel'}
MAAT = {'klein', 'normaal', 'groot'}
TOREN_WOORD = {'spikes', 'zaag', 'zaag-snel', 'leeg', 'vzaag'}


class Fout(Exception):
    pass


def getal(x, lo=None, hi=None, naam='waarde'):
    try:
        v = float(x)
    except ValueError:
        raise Fout(f'{naam} "{x}" is geen getal')
    if (lo is not None and v < lo) or (hi is not None and v > hi):
        raise Fout(f'{naam} {x} buiten {lo}..{hi}')
    return int(v) if v == int(v) else v


def keuze(x, opties, naam):
    if x not in opties:
        raise Fout(f'{naam} "{x}" moet een van {sorted(opties)} zijn')
    return x


def aantal(args, n, naam):
    if len(args) != n:
        raise Fout(f'{naam} heeft {len(args)} parameters, verwacht {n}')


def bouwsteen(naam, args, lvl):
    """Geeft (breedte, hoogteverandering, laagste, hoogste, soorten, extra) relatief aan de vloer."""
    hoog = 6 if lvl >= 50 else 5
    gat = 8 if lvl >= 50 else 6
    a = args
    if naam == 'START':
        aantal(a, 1, naam); keuze(a[0], {'vlak', 'kort', 'klif', 'dal'}, 'begin')
        return {'vlak': 8, 'kort': 3}.get(a[0], 5), 0, 0, 0, set(), {}
    if naam == 'FINISH':
        aantal(a, 1, naam)
        t = keuze(a[0], {'plateau', 'piek', 'dal', 'pilaar', 'dak'}, 'eind')
        return {'plateau': (6, 0), 'piek': (7, 2), 'dal': (6, -2), 'pilaar': (6, 3), 'dak': (4, 0)}[t] + (min(0, {'dal': -2}.get(t, 0)), max(0, {'piek': 2, 'pilaar': 3}.get(t, 0)), set(), {})
    if naam == 'VLAK':
        aantal(a, 1, naam); w = getal(a[0], 3, 30, 'breedte')
        return w, 0, 0, 0, set(), {}
    if naam in ('OP', 'AF'):
        aantal(a, 2, naam)
        h = getal(a[0], 1, hoog if naam == 'OP' else 30, 'hoogte'); w = getal(a[1], 1, 30, 'breedte')
        d = h if naam == 'OP' else -h
        return w, d, min(0, d), max(0, d), set(), {}
    if naam == 'HEUVEL':
        stappen = [getal(x, -2, 2, 'stapje') for x in a]
        h = cur = lo = hi = 0
        for x in stappen:
            cur += x; lo = min(lo, cur); hi = max(hi, cur)
        return 3 * len(stappen), cur, lo, hi, set(), {}
    if naam in ('TRAP', 'TRAP-AF'):
        aantal(a, 3, naam)
        n = getal(a[0], 2, 10, 'treden'); h = getal(a[1], 1, hoog, 'trede-hoogte'); w = getal(a[2], 2, 12, 'trede-breedte')
        d = n * h if naam == 'TRAP' else -n * h
        return n * w, d, min(0, d), max(0, d), set(), {'trede': n}
    if naam == 'KUIL':
        aantal(a, 2, naam); w = getal(a[0], 3, gat, 'breedte'); d = getal(a[1], 1, 3, 'diepte')
        return w + 2, 0, -d, 0, {'spikes'}, {'kuil': 1}
    if naam == 'KUIL-OP':
        aantal(a, 2, naam); w = getal(a[0], 3, gat, 'breedte'); h = getal(a[1], -hoog, hoog, 'hoogteverschil')
        return w + 2, h, min(-1, h), max(0, h), {'spikes'}, {'kuil': 1}
    if naam == 'DAL':
        aantal(a, 3, naam); w = getal(a[0], 6, 20, 'breedte'); d = getal(a[1], 2, hoog, 'diepte'); s = getal(a[2], 0, w - 2, 'spikes')
        return w + 2, 0, -d, 0, ({'spikes'} if s else set()), {}
    if naam == 'PILAREN':
        aantal(a, 3, naam)
        hs = [getal(x, 1, hoog, 'pilaarhoogte') for x in a[0].split('/')]
        b = getal(a[1], 1, 3, 'pilaarbreedte')
        gs = [getal(x, 3, gat, 'gat') for x in a[2].split('/')]
        if len(gs) != len(hs) + 1:
            raise Fout(f'PILAREN: {len(hs)} pilaren vraagt {len(hs) + 1} gaten, er zijn er {len(gs)}')
        return sum(gs) + len(hs) * b + 2, 0, -1, max(hs), {'pilaren', 'spikes'}, {'kuil': len(gs)}
    if naam == 'TREDEPILAREN':
        aantal(a, 3, naam)
        n = getal(a[0], 2, 8, 'aantal'); st = getal(a[1], -2, 2, 'stijging'); g = getal(a[2], 3, gat, 'gat')
        tops = [2 + i * st for i in range(n)]
        return (n + 1) * g + 2 * n + 2, tops[-1], min(-1, min(tops)), max(tops), {'pilaren', 'spikes'}, {'kuil': n + 1}
    if naam == 'ZAAG':
        aantal(a, 4, naam)
        t = getal(a[0], 1, 10, 'baan'); keuze(a[1], SNEL_ZAAG, 'snelheid'); getal(a[2], 0, 1, 'vertraging'); keuze(a[3], MAAT, 'maat')
        return t + 4, 0, 0, 0, {'zaag'}, {}
    if naam == 'HANGZAAG':
        aantal(a, 4, naam)
        getal(a[0], 2, 7, 'hoogte'); getal(a[1], 1, 8, 'baan'); keuze(a[2], SNEL_ZAAG, 'snelheid'); keuze(a[3], MAAT, 'maat')
        return 0, 0, 0, 0, {'zaag'}, {}
    if naam == 'VZAAG':
        aantal(a, 3, naam); getal(a[0], 3, 5, 'slag'); keuze(a[1], SNEL_2, 'snelheid'); getal(a[2], 0, 1, 'vertraging')
        return 4, 0, 0, 0, {'vzaag'}, {}
    if naam == 'KOGEL':
        if len(a) not in (3, 4):
            raise Fout(f'KOGEL heeft {len(a)} parameters, verwacht 3 of 4')
        k = getal(a[0], 5, 7, 'ketting'); getal(a[1], 0, 359, 'fase'); keuze(a[2], SNEL_2, 'snelheid')
        d = 0
        breedte = 2 * k + 1
        if len(a) == 4:
            if a[3] == 'rand':
                breedte = 4
            elif a[3].startswith('muur '):
                d = getal(a[3][5:], 3, 6, 'muur')
                breedte += 3
            else:
                raise Fout(f'KOGEL: 4e parameter "{a[3]}" moet "muur h" of "rand" zijn')
        return breedte, d, 0, d, {'kogel'}, {}
    if naam == 'KOGEL-KUIL':
        if len(a) not in (4, 5):
            raise Fout(f'KOGEL-KUIL heeft {len(a)} parameters, verwacht 4 of 5')
        w = getal(a[0], 3, gat, 'breedte'); k = getal(a[1], 5, 7, 'ketting'); getal(a[2], 0, 359, 'fase'); keuze(a[3], SNEL_2, 'snelheid')
        d = 0
        if len(a) == 5:
            if not a[4].startswith('muur '):
                raise Fout('KOGEL-KUIL: 5e parameter moet "muur h" zijn')
            d = getal(a[4][5:], 3, 6, 'muur')
        return max(w + 2, 2 * k + 1) + (3 if d else 0), d, -1, d, {'kogel', 'spikes'}, {'kuil': 1}
    if naam == 'PLATFORM':
        aantal(a, 3, naam); w = getal(a[0], 17, 22, 'kuil'); keuze(a[1], SNEL_2, 'snelheid'); getal(a[2], 0, 1, 'vertraging')
        return w + 3, 0, -2, 0, {'platform', 'spikes'}, {}
    if naam == 'PLATFORMS':
        aantal(a, 3, naam); n = getal(a[0], 2, 3, 'aantal'); keuze(a[1], SNEL_2, 'snelheid'); getal(a[2], 0, 1, 'vertraging')
        return 9 * n + 3, 0, -2, 0, {'platform', 'spikes'}, {'platform': n}
    if naam == 'LIFT':
        aantal(a, 1, naam); h = getal(a[0], 9, 20, 'hoogte')
        return 9, h, 0, h, {'lift'}, {}
    if naam == 'LIFT-OVER':
        aantal(a, 2, naam); h = getal(a[0], 9, 20, 'hoogte'); w = getal(a[1], 4, gat, 'sprong')
        return 6 + w + 3, h, -1, h, {'lift', 'spikes'}, {}
    if naam == 'LIFT-AF':
        aantal(a, 1, naam); h = getal(a[0], 9, 20, 'hoogte')
        return 12, -h, -h, 0, {'lift', 'spikes'}, {}
    if naam == 'TOREN':
        aantal(a, 3, naam)
        n = int(keuze(a[0], {'3', '5'}, 'verdiepingen')); r = keuze(a[1], {'op', 'omlaag'}, 'richting')
        w = a[2].split('/')
        if len(w) != n:
            raise Fout(f'TOREN({n}) heeft {len(w)} verdiepingen in de inhoud')
        for i, x in enumerate(w):
            keuze(x, TOREN_WOORD, 'verdieping')
            if x == 'vzaag' and i != n - 1:
                raise Fout('vzaag mag alleen op de bovenste verdieping')
        soort = {'toren'}
        if any(x.startswith('zaag') for x in w): soort.add('zaag')
        if 'vzaag' in w: soort.add('vzaag')
        if 'spikes' in w: soort.add('spikes')
        d = 6 * (n - 1) * (1 if r == 'op' else -1)
        return 22, d, min(0, d), max(0, d), soort, {}
    if naam == 'SCHACHT':
        aantal(a, 3, naam)
        h = getal(a[0], 12, 24, 'hoogte'); r = keuze(a[1], {'op', 'omlaag'}, 'richting'); rr = int(keuze(a[2], {'3', '4'}, 'richel-afstand'))
        d = h if r == 'op' else -h
        return 9, d, min(0, d), max(0, d), {'schacht', 'spikes'}, {'richel': h // rr}
    raise Fout(f'onbekende bouwsteen "{naam}"')


BIJLAGE_OK = {
    'HANGZAAG': {'KUIL', 'KUIL-OP', 'PLATFORM', 'PLATFORMS', 'LIFT', 'SCHACHT', 'TREDEPILAREN', 'PILAREN'},
    'VZAAG': {'OP', 'PLATFORM', 'PLATFORMS', 'VLAK'},
    'ZAAG': {'OP', 'VLAK'},
    'KOGEL': {'TRAP', 'PLATFORM', 'PLATFORMS', 'OP'},
    'KUIL': {'TRAP', 'TRAP-AF'},
}


def splits(seg):
    """'A(..)+B(..)@plek' -> [(naam, args, plek)]"""
    delen = re.findall(r'([A-Z][A-Z-]*)\(([^)]*)\)(@[^+]*)?', seg)
    rest = re.sub(r'([A-Z][A-Z-]*)\(([^)]*)\)(@[^+]*)?', '', seg).replace('+', '').strip()
    if rest:
        raise Fout(f'onbegrepen tekst "{rest}" in "{seg}"')
    return [(n, [x.strip() for x in a.split(',')] if a.strip() else [], (p[1:].strip() if p else None)) for n, a, p in delen]


levels = list(re.finditer(r'^\*\*(\d+)\. ([^–\n]*)– (\w+)[^\n]*\n`([^`]*)`\n(Profiel:[^\n]*\n)?', tekst, re.M))
data, fouten, profielen, sterren, lengtes = {}, [], {}, {}, {}

for m in levels:
    n = int(m.group(1)); vorm = m.group(3)
    delen = [x.strip() for x in m.group(4).split('·')]
    h = lo = hi = breedte = klim = wachten = obstakels = 0
    soorten = set()
    for seg in delen:
        try:
            stukken = splits(seg)
            if not stukken:
                raise Fout(f'lege bouwsteen in "{seg}"')
            hoofd, args, _ = stukken[0]
            w, d, mn, mx, srt, extra = bouwsteen(hoofd, args, n)
            for bn, ba, plek in stukken[1:]:
                if hoofd not in BIJLAGE_OK.get(bn, set()):
                    raise Fout(f'{bn} kan niet bij {hoofd}')
                _, _, _, _, s2, _ = bouwsteen(bn, ba, n)
                srt |= s2
                if plek:
                    soort_plek, _, nums = plek.partition(' ')
                    if soort_plek.isdigit():
                        soort_plek, nums = 'platform', soort_plek
                    grens = extra.get(soort_plek)
                    if grens is None:
                        raise Fout(f'@{plek} past niet bij {hoofd}')
                    for x in nums.split(','):
                        if not (1 <= int(x) <= grens):
                            raise Fout(f'@{plek}: {x} bestaat niet (1..{grens})')
            lo = min(lo, h + mn); hi = max(hi, h + mx)
            h += d; breedte += w
            klim += max(0, d)
            soorten |= srt
            for bn, _, _ in stukken:
                if bn.startswith(('LIFT', 'PLATFORM')):
                    wachten += 1
                elif bn in ('ZAAG', 'HANGZAAG', 'VZAAG', 'KOGEL', 'KOGEL-KUIL', 'TOREN', 'SCHACHT', 'PILAREN', 'TREDEPILAREN'):
                    obstakels += 1
        except Fout as e:
            fouten.append(f'{n}: {e}')
    data[n] = (vorm, delen[0], delen[-1], delen[1:-1], soorten)
    profielen[n] = f'Profiel: ~{breedte} tiles · hoogste {hi:+d} · laagste {lo:+d} · eind {h:+d}\n'
    # Sterren: 3 s + 0,2 s/tile + 0,15 s per rij omhoog + 2 s per lift/platform + 0,7 s per ander obstakel
    drie = round(3 + 0.2 * breedte + 0.15 * klim + 2 * wachten + 0.7 * obstakels)
    sterren[n] = f'⭐ {drie} / {2 * drie}'
    lengtes[n] = breedte
    if n % 10 == 0 and h <= 0:
        fouten.append(f'{n}: finale eindigt niet hoger dan de start (eind {h:+d})')

for n in sorted(data):
    vorm, st, fi, segs, soorten = data[n]
    if n - 1 in data:
        pv, ps, pf, _, _ = data[n - 1]
        if pv == vorm: fouten.append(f'{n}: zelfde vorm als {n-1} ({vorm})')
        if ps == st: fouten.append(f'{n}: zelfde begin als {n-1} ({st})')
        if pf == fi: fouten.append(f'{n}: zelfde eind als {n-1} ({fi})')
    for seg in segs:
        if seg.startswith(('OP(', 'AF(', 'HEUVEL(')):
            continue
        for m2 in range(max(1, n - 4), n):
            if m2 in data and seg in data[m2][3]:
                fouten.append(f'{n}: "{seg}" ook in {m2}')
    for a_, b_ in zip(segs, segs[1:]):
        for m2 in range(max(1, n - 9), n):
            if m2 in data and any(x == a_ and y == b_ for x, y in zip(data[m2][3], data[m2][3][1:])):
                fouten.append(f'{n}: paar "{a_} -> {b_}" ook in {m2}')
    obst = soorten - {'pilaren'}
    if n >= 17 and len(obst) < 3:
        fouten.append(f'{n}: maar {len(obst)} soorten obstakels {sorted(obst)}')

print(f'{len(data)} levels, {len(fouten)} problemen')
print('\n'.join(fouten))

if '--schrijf' in sys.argv:
    def zet(m):
        n = int(m.group(1))
        return m.group(0)[:len(m.group(0)) - len(m.group(5) or '')] + profielen[n]
    tekst = re.sub(r'^\*\*(\d+)\. ([^–\n]*)– (\w+)[^\n]*\n`([^`]*)`\n(Profiel:[^\n]*\n)?', zet, tekst, flags=re.M)

    # sterrentijden: de eerste '⭐ a / b' na elk level vervangen
    def ster(m):
        n = int(m.group(1))
        blok = re.sub(r'⭐ \d+ / \d+', sterren[n], m.group(0), count=1)
        return blok
    tekst = re.sub(r'^\*\*(\d+)\. .*?(?=^\*\*\d+\. |^### |^---|\Z)', ster, tekst, flags=re.M | re.S)

    # lengtes per wereld in de wereldtabel
    for w in range(10):
        ls = [lengtes[n] for n in range(w * 10 + 1, w * 10 + 11) if n in lengtes]
        if ls:
            tekst = re.sub(r'(\| %d De [^|]*\| [^|]*\| [^|]*\| )[^|]*(\|)' % (w + 1), r'\g<1>%d–%d \g<2>' % (min(ls), max(ls)), tekst, count=1)
    open(PAD, 'w', encoding='utf-8', newline='\n').write(tekst)
    print('profielen, sterren en lengtes bijgewerkt')
