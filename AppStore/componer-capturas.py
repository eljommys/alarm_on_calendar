#!/usr/bin/env python3
"""Compone las capturas promocionales de la App Store.

Toma las capturas crudas del simulador y las monta sobre un lienzo de
1242x2688 con un titular encima. El lienzo se dibuja a tamaño final, así que
la captura del dispositivo se coloca a escala natural, sin reescalar hacia
arriba.

    python3 AppStore/componer-capturas.py <dir-capturas> <dir-salida>
"""
import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

LIENZO = (1242, 2688)
FONDO = (10, 10, 12)
ACENTO = (249, 121, 46)
FUENTE = "/System/Library/Fonts/HelveticaNeue.ttc"

# (archivo, titular, apoyo)
GUIONES = {
    "es": [
        ("es_1_proximos.png",
         "Una alarma de verdad\nantes de cada evento",
         "Suena aunque lleves el móvil en silencio"),
        ("es_2_calendarios.png",
         "Una antelación distinta\npara cada calendario",
         "15 minutos para Trabajo, 5 para Personal"),
        ("es_3_ajustes.png",
         "Solo los confirmados,\no todos. Tú eliges",
         "Y el interruptor de cada evento manda sobre todo"),
        ("es_4_guia.png",
         "Google y Microsoft,\nsin iniciar sesión",
         "Usa las cuentas que ya tienes en tu iPhone"),
    ],
    "en": [
        ("en_1_upcoming.png",
         "A real alarm\nbefore every event",
         "It rings even when your phone is on silent"),
        ("en_2_calendars.png",
         "A different lead time\nfor every calendar",
         "15 minutes for Work, 5 for Personal"),
        ("en_3_settings.png",
         "Only accepted events,\nor every one of them",
         "And each event's own switch overrides the rest"),
        ("en_4_guide.png",
         "Google and Microsoft,\nwith no sign-in",
         "It uses the accounts already on your iPhone"),
    ],
}


def esquinas_redondeadas(imagen: Image.Image, radio: int) -> Image.Image:
    mascara = Image.new("L", imagen.size, 0)
    ImageDraw.Draw(mascara).rounded_rectangle(
        [(0, 0), (imagen.size[0] - 1, imagen.size[1] - 1)], radio, fill=255
    )
    salida = imagen.convert("RGBA")
    salida.putalpha(mascara)
    return salida


def resplandor(lienzo: Image.Image) -> None:
    """Halo naranja tenue detrás del titular, para que el fondo no sea plano."""
    ancho, alto = lienzo.size
    capa = Image.new("RGBA", lienzo.size, (0, 0, 0, 0))
    dibujo = ImageDraw.Draw(capa)
    cx, cy = ancho // 2, round(alto * 0.150)
    for f, alfa in [(0.576, 8), (0.424, 10), (0.288, 12), (0.167, 14)]:
        radio = round(ancho * f)
        dibujo.ellipse([cx - radio, cy - radio // 2, cx + radio, cy + radio // 2],
                       fill=(*ACENTO, alfa))
    lienzo.alpha_composite(capa)


def centrar(dibujo, texto, fuente, y, color, interlineado, ancho_lienzo):
    for linea in texto.split("\n"):
        ancho = dibujo.textbbox((0, 0), linea, font=fuente)[2]
        dibujo.text(((ancho_lienzo - ancho) // 2, y), linea, font=fuente, fill=color)
        y += interlineado
    return y


def componer(captura: Path, titular: str, apoyo: str, destino: Path, lienzo_px) -> None:
    W, H = lienzo_px
    lienzo = Image.new("RGBA", lienzo_px, (*FONDO, 255))
    resplandor(lienzo)
    dibujo = ImageDraw.Draw(lienzo)

    # Medidas proporcionales al ancho, no fijas, por si cambia el lienzo.
    titulo = ImageFont.truetype(FUENTE, round(W * 0.0652), index=1)   # Bold
    sub = ImageFont.truetype(FUENTE, round(W * 0.0333), index=0)      # Regular

    y = centrar(dibujo, titular, titulo, round(H * 0.0732),
                (255, 255, 255), round(W * 0.0788), W)
    centrar(dibujo, apoyo, sub, y + round(W * 0.020),
            (168, 168, 176), round(W * 0.0424), W)

    # La captura se reduce, nunca se amplía: así no se ve borrosa.
    foto = Image.open(captura).convert("RGB")
    ancho = round(W * 0.7879)
    alto = round(foto.size[1] * ancho / foto.size[0])
    radio = round(W * 0.0439)
    foto = foto.resize((ancho, alto), Image.LANCZOS)
    foto = esquinas_redondeadas(foto, radio)

    x = (W - ancho) // 2
    y = round(H * 0.2232)
    marco = Image.new("RGBA", (ancho + 6, alto + 6), (0, 0, 0, 0))
    ImageDraw.Draw(marco).rounded_rectangle(
        [(0, 0), (ancho + 5, alto + 5)], radio + 3, outline=(255, 255, 255, 38), width=3
    )
    lienzo.alpha_composite(marco, (x - 3, y - 3))
    lienzo.alpha_composite(foto, (x, y))

    lienzo.convert("RGB").save(destino, "PNG")


def main() -> int:
    if len(sys.argv) != 3:
        print(__doc__)
        return 2
    origen, salida = Path(sys.argv[1]), Path(sys.argv[2])

    for idioma, guiones in GUIONES.items():
        carpeta = salida / idioma
        carpeta.mkdir(parents=True, exist_ok=True)
        for n, (archivo, titular, apoyo) in enumerate(guiones, 1):
            captura = origen / archivo
            if not captura.exists():
                print(f"  falta {captura}")
                continue
            destino = carpeta / f"{n}.png"
            componer(captura, titular, apoyo, destino, LIENZO)
            print(f"{idioma}/{destino.name}  {Image.open(destino).size}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
