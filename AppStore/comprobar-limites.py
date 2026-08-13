#!/usr/bin/env python3
"""Comprueba que cada campo de la ficha cabe en su límite de App Store Connect.

Los campos se leen de los bloques ``` de ficha.md, así que el documento y esta
comprobación no se pueden desincronizar.

    python3 AppStore/comprobar-limites.py
"""
import re
import sys
from pathlib import Path

LIMITES = {
    "Nombre": 30,
    "Subtítulo": 30,
    "Texto promocional": 170,
    "Palabras clave": 100,
    "Descripción": 4000,
}

ficha = (Path(__file__).parent / "ficha.md").read_text(encoding="utf-8")

# Cada sección "## Campo · límite N" seguida de uno o más bloques ```
secciones = re.split(r"^## ", ficha, flags=re.MULTILINE)[1:]

fallos = 0
for seccion in secciones:
    titulo = seccion.splitlines()[0].split("·")[0].strip()
    if titulo not in LIMITES:
        continue
    limite = LIMITES[titulo]
    for n, bloque in enumerate(re.findall(r"```\n(.*?)\n```", seccion, re.DOTALL), 1):
        texto = bloque.strip()
        largo = len(texto)
        etiqueta = titulo if n == 1 else f"{titulo} (alternativa {n - 1})"
        ok = largo <= limite
        fallos += not ok
        print(f"{'ok ' if ok else 'MAL'}  {etiqueta:<34} {largo:>4} / {limite}")
        if not ok:
            print(f"      sobran {largo - limite} caracteres")

if fallos:
    print(f"\n{fallos} campo(s) se pasan del límite.")
    sys.exit(1)
print("\nTodos los campos caben.")
