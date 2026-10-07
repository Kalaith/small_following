"""The game's procedural characters, redrawn with Pillow for plates and postcards.

Shapes, proportions and colours are ported from the game's own _draw()
functions (scripts/gathering.gd Listener, scripts/player.gd, scripts/helper.gd)
so plates share the game's shape language. Coordinates are the game's local
units with the origin at the feet; `s` scales them. Extra props (pie, captain's
hat, mortarboard, wimple, top hat) are new and drawn in the same style.
"""
from __future__ import annotations

import math
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

FONTS = Path("C:/Windows/Fonts")
CREAM = "#fff0d8"
LILAC = "#d4b4fa"
PARCHMENT = "#efe0c2"
INK = "#3b2a45"
COATS = ["#be8066", "#b89c58", "#679391", "#7c88aa", "#caaf77", "#9c695a"]  # gathering.gd


def font(size: int, serif: bool = False, bold: bool = False, italic: bool = False):
    name = ("georgiaz" if bold and italic else "georgiab" if bold else "georgiai" if italic else "georgia") \
        if serif else ("trebucbi" if bold and italic else "trebucbd" if bold else "trebucit" if italic else "trebuc")
    return ImageFont.truetype(str(FONTS / f"{name}.ttf"), size)


class Pen:
    """Draws game-local shapes at (ox, oy) with scale s on a supersampled image."""

    def __init__(self, image: Image.Image, ss: int = 2):
        self.image, self.ss = image, ss
        self.draw = ImageDraw.Draw(image, "RGBA")

    def at(self, ox: float, oy: float, s: float) -> "Pen":
        self.ox, self.oy, self.s = ox, oy, s
        return self

    def _p(self, x: float, y: float) -> tuple[float, float]:
        return ((self.ox + x * self.s) * self.ss, (self.oy + y * self.s) * self.ss)

    def poly(self, points, fill) -> None:
        self.draw.polygon([self._p(x, y) for x, y in points], fill=fill)

    def circle(self, c, r, fill, squash: float = 1.0) -> None:
        x, y = self._p(*c)
        rx, ry = r * self.s * self.ss, r * self.s * self.ss * squash
        self.draw.ellipse((x - rx, y - ry, x + rx, y + ry), fill=fill)

    def ring(self, c, r, color, width, squash: float = 1.0) -> None:
        x, y = self._p(*c)
        rx, ry = r * self.s * self.ss, r * self.s * self.ss * squash
        self.draw.ellipse((x - rx, y - ry, x + rx, y + ry), outline=color,
                          width=max(1, round(width * self.s * self.ss)))

    def line(self, a, b, color, width) -> None:
        self.draw.line([self._p(*a), self._p(*b)], fill=color, width=max(1, round(width * self.s * self.ss)))

    def arc(self, c, r, start, end, color, width) -> None:
        x, y = self._p(*c)
        rr = r * self.s * self.ss
        self.draw.arc((x - rr, y - rr, x + rr, y + rr), math.degrees(start), math.degrees(end),
                      fill=color, width=max(1, round(width * self.s * self.ss)))

    def rect(self, x, y, w, h, fill) -> None:
        self.draw.rectangle([self._p(x, y), self._p(x + w, y + h)], fill=fill)

    def text(self, xy, value, size, fill, serif=True, bold=False, anchor="mm") -> None:
        self.draw.text(self._p(*xy), value, font=font(round(size * self.s * self.ss), serif, bold),
                       fill=fill, anchor=anchor)


# --- characters ----------------------------------------------------------------

def listener(pen: Pen, x: float, y: float, s: float, coat: str = COATS[0], prop: str = "",
             following: bool = False) -> None:
    """gathering.gd Listener: legs, coat, head, hair arc, dot eyes, optional prop."""
    pen.at(x, y, s)
    pen.circle((0, 0), 12, (56, 69, 51, 50), squash=.4)
    pen.line((-4, -9), (-5, 0), "#625648", 4)
    pen.line((4, -9), (5, 0), "#625648", 4)
    pen.poly([(-9, -23), (8, -23), (12, -6), (-11, -6)], "#9780a7" if following else coat)
    pen.circle((0, -29), 9, "#eac49a")
    pen.arc((0, -31), 9, math.pi, math.tau, "#75604a", 4)
    pen.circle((-3, -29), 1.1, "#4e4944")
    pen.circle((3, -29), 1.1, "#4e4944")
    PROPS.get(prop, lambda p: None)(pen)


def _merchant(p: Pen) -> None:
    p.rect(-12, -40, 24, 5, "#75562d")
    p.rect(-7, -48, 14, 10, "#b38c3c")
    p.circle((12, -12), 6, "#e2b953")
    p.line((12, -16), (12, -8), "#765923", 2)


def _guild(p: Pen) -> None:
    p.rect(-10, -41, 20, 6, "#466d75")
    p.rect(-5, -23, 10, 15, "#d2c39b")
    p.line((-9, -13), (10, -13), "#6a5136", 3)


def _patron(p: Pen) -> None:
    p.rect(-14, -40, 28, 4, "#85628f")
    p.rect(-8, -46, 16, 8, "#a07aae")
    p.line((6, -44), (13, -53), "#f1dfb1", 3)
    p.poly([(11, -11), (6, -23), (19, -23)], "#e3c587")


def _baker(p: Pen) -> None:
    p.rect(-6, -22, 12, 15, "#efdeb0")
    p.circle((0, -41), 7, "#efdeb0")


def _pie(p: Pen) -> None:  # Gerald's pie, held out in front
    p.circle((13, -14), 8, "#b9783f", squash=.55)
    p.circle((13, -16), 7, "#e0b36a", squash=.45)
    for dx in (-3, 0, 3):
        p.line((13 + dx, -18), (13 + dx + 1, -15), "#9b5f2c", 1)


def _captain(p: Pen) -> None:
    p.rect(-11, -39, 22, 4, "#24324f")
    p.rect(-8, -45, 16, 7, "#2e4166")
    p.rect(-3, -44, 6, 3, "#e7c46a")
    p.rect(-5, -23, 10, 4, "#d6c79a")


def _mortarboard(p: Pen) -> None:
    p.rect(-6, -42, 12, 5, "#2f2a3a")
    p.poly([(-14, -42), (0, -48), (14, -42), (0, -37)], "#3a3348")
    p.line((10, -42), (13, -33), "#e2b953", 1.5)


def _wimple(p: Pen) -> None:
    p.poly([(-11, -38), (11, -38), (12, -18), (-12, -18)], "#f4efe4")
    p.circle((0, -29), 8, "#eac49a")
    p.circle((-3, -29), 1.1, "#4e4944")
    p.circle((3, -29), 1.1, "#4e4944")
    p.rect(-11, -42, 22, 5, "#3c3448")


def _top_hat(p: Pen) -> None:
    p.rect(-12, -39, 24, 3, "#2b2131")
    p.rect(-7, -54, 14, 15, "#2b2131")
    p.rect(-7, -44, 14, 3, "#b8423f")
    p.poly([(-9, -23), (8, -23), (12, -6), (-11, -6)], "#b8423f")


def _scholar(p: Pen) -> None:
    p.rect(5, -22, 9, 12, "#7c5b3a")
    p.line((5, -16), (14, -16), "#e8d6a4", 1)


def _fan(p: Pen) -> None:
    p.poly([(11, -11), (6, -23), (19, -23)], "#e3c587")


PROPS = {"merchant": _merchant, "guild": _guild, "patron": _patron, "baker": _baker, "pie": _pie,
         "captain": _captain, "mortarboard": _mortarboard, "wimple": _wimple, "top_hat": _top_hat,
         "scholar": _scholar, "fan": _fan}


def cultist(pen: Pen, x: float, y: float, s: float, cloth: float = 0.0) -> None:
    """player.gd: shadow, robe cloth, boots, robe, oversized hood, glowing eyes, clasp."""
    pen.at(x, y, s)
    pen.circle((0, 1), 23, (43, 33, 54, 56), squash=.32)
    tip = (cloth * 18, 6)
    pen.poly([(-10, -9), (tip[0] - 8, tip[1]), (tip[0], tip[1] + 7), (tip[0] + 8, tip[1]), (10, -9)], "#6f4593")
    pen.circle((-7, -1), 5, "#372b43")
    pen.circle((7, -1), 5, "#372b43")
    pen.poly([(-12, -38), (12, -38), (21, -5), (11, 0), (0, -3), (-11, 0), (-21, -5)], "#51365f")
    pen.poly([(-10, -37), (10, -37), (17, -7), (8, -4), (0, -7), (-9, -4), (-17, -7)], "#9670ad")
    pen.line((-3, -28), (-7, -8), "#b38dc6", 2)
    pen.line((7, -28), (11, -8), "#79578e", 2)
    pen.circle((0, -43), 20, "#51365f")
    pen.circle((-1, -45), 18, "#9670ad")
    pen.arc((-1, -45), 15, math.pi * 1.10, math.pi * 1.80, "#b998cf", 2)
    pen.circle((0, -42), 12, "#322c40")
    pen.poly([(-11, -42), (11, -42), (8, -31), (-8, -31)], "#322c40")
    for ex in (-4.5, 4.5):
        pen.circle((ex, -41), 3.5, (252, 214, 133, 31))
        pen.circle((ex, -41), 1.8, "#ffe4a1")
    pen.circle((0, -27), 3, "#e5c889")


def helper(pen: Pen, x: float, y: float, s: float) -> None:
    """helper.gd: the teal-hooded helper with a lilac sash."""
    pen.at(x, y, s)
    pen.circle((0, 0), 12, (56, 69, 51, 56), squash=.4)
    pen.poly([(-7, -24), (7, -24), (12, -2), (-12, -2)], "#528c83")
    pen.line((-7, -21), (7, -5), "#dac5ee", 3)
    pen.circle((0, -29), 11, "#69a699")
    pen.circle((0, -28), 7, "#314c4e")
    pen.circle((-2, -28), 1, "#fff1d0")
    pen.circle((3, -28), 1, "#fff1d0")


def finish(image: Image.Image, ss: int = 2) -> Image.Image:
    """Downsample a supersampled drawing for smooth edges."""
    return image.resize((image.width // ss, image.height // ss), Image.LANCZOS)
