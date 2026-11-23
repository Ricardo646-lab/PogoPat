"""Zet de levels uit Docs/LEVELS.md om naar Scripts/level_data.gd.

    python Docs/export_levels.py

Draai dit na elke wijziging in LEVELS.md (en eerst python Docs/check_levels.py --schrijf).
"""
import re

tekst = open('Docs/LEVELS.md', encoding='utf-8').read()
blokken = re.findall(r'^\*\*(\d+)\. ([^–\n]*?) – [^\n]*\n`([^`]*)`\n(.*?)(?=^\*\*\d+\. |^### |^---|\Z)', tekst, re.M | re.S)

namen, levels, sterren = [''] * 101, [''] * 101, [[0, 0]] * 101
for n, naam, regel, rest in blokken:
    n = int(n)
    namen[n] = naam.strip().rstrip('*').strip()
    levels[n] = regel.strip()
    m = re.search(r'⭐ (\d+) / (\d+)', rest)
    sterren[n] = [int(m.group(1)), int(m.group(2))]

ontbreekt = [i for i in range(1, 101) if not levels[i]]
assert not ontbreekt, f'levels ontbreken: {ontbreekt}'

def gd(s):
    return '"' + s.replace('\\', '\\\\').replace('"', '\\"') + '"'

uit = ['# AUTOMATISCH GEMAAKT door Docs/export_levels.py uit Docs/LEVELS.md - niet met de hand aanpassen.',
       'extends RefCounted', '',
       'const STARS = [' + ', '.join(f'[{a}, {b}]' for a, b in sterren) + ']', '',
       'const LEVELS = [']
uit += ['\t' + gd(x) + ',' for x in levels]
uit += [']', '']
open('Scripts/level_data.gd', 'w', encoding='utf-8', newline='\n').write('\n'.join(uit))
print('100 levels geschreven naar Scripts/level_data.gd')
