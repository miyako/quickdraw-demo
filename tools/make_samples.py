#!/usr/bin/env python3
"""Generate original sample artwork for the quickdraw 4D demo.

Everything here is authored from scratch with plain geometric primitives
(MIT licensed, see the repository LICENSE). No historical or third-party
PICT/font data is copied. The script is deterministic, uses only the Python
standard library and performs no network access.

Usage:
    python3 tools/make_samples.py
"""

from __future__ import annotations

import json
import struct
from pathlib import Path

SAMPLES = Path(__file__).resolve().parent.parent / "Resources" / "Samples"

# PICT opcodes used by the generator (QuickDraw opcode table).
OP_FONT = 0x0003  # txFont (u16 font ID)
OP_PENSIZE = 0x0007  # pnSize (point)
OP_FILLPAT = 0x000A  # fill pattern (8x8 bytes)
OP_SIZE = 0x000D  # txSize (u16 size)
OP_FGCOLOR = 0x001A  # RGBColor (3 x u16)
OP_BGCOLOR = 0x001B
OP_LINE = 0x0020  # start point + end point
OP_TEXT = 0x0028  # point + u8 count + MacRoman bytes
OP_FRAME_RECT = 0x0030
OP_PAINT_RECT = 0x0031
OP_ERASE_RECT = 0x0032
OP_INVERT_RECT = 0x0033
OP_FILL_RECT = 0x0034
OP_PAINT_ROUND = 0x0041
OP_PAINT_OVAL = 0x0051
OP_PAINT_ARC = 0x0061
OP_PAINT_POLY = 0x0071
OP_END = 0x00FF

# Classic QuickDraw 8x8 patterns.
PAT_50 = bytes([0xAA, 0x55] * 4)
PAT_DIAG = bytes([0x81, 0x42, 0x24, 0x18, 0x18, 0x24, 0x42, 0x81])
PAT_DOTS = bytes([0x88, 0x00, 0x22, 0x00, 0x88, 0x00, 0x22, 0x00])


def u16(value: int) -> bytes:
    return struct.pack(">H", value & 0xFFFF)


def i16(value: int) -> bytes:
    return struct.pack(">h", value)


def rect(top: int, left: int, bottom: int, right: int) -> bytes:
    return i16(top) + i16(left) + i16(bottom) + i16(right)


def rgb(r: int, g: int, b: int) -> bytes:
    """8-bit components scaled to the 16-bit RGBColor components."""
    return u16(r * 257) + u16(g * 257) + u16(b * 257)


class Pict:
    """Minimal PICT version 2 writer with word alignment and HeaderOp."""

    def __init__(self, width: int, height: int) -> None:
        self.width = width
        self.height = height
        self.ops = bytearray()

    def op(self, opcode: int, operand: bytes = b"") -> "Pict":
        # V2 pads each opcode to an even offset relative to the picture start:
        # 2 size + 8 frame + 4 version + 2 HeaderOp + 24 header payload = 40.
        if (40 + len(self.ops)) % 2 == 1:
            self.ops.append(0)
        self.ops += u16(opcode)
        self.ops += operand
        return self

    def color(self, opcode: int, r: int, g: int, b: int) -> "Pict":
        return self.op(opcode, rgb(r, g, b))

    def render(self) -> bytes:
        frame = rect(0, 0, self.height, self.width)
        header = b"\x00\x00" + frame + b"\x00\x11\x02\xff"
        header_op = b"\x0c\x00" + b"\xff\xff\xff\xff" + bytes(20)
        # EndPic must also begin on an even offset.
        if (40 + len(self.ops)) % 2 == 1:
            self.ops.append(0)
        body = header_op + bytes(self.ops) + u16(OP_END)
        total = len(header) + len(body)
        # The v2 declared size is ignored by readers; keep it meaningful anyway.
        return u16(min(total, 0xFFFF)) + header[2:] + body


def make_poster() -> bytes:
    p = Pict(360, 240)

    # Backdrop.
    p.color(OP_BGCOLOR, 22, 28, 44)
    p.color(OP_FGCOLOR, 34, 46, 72)
    p.op(OP_PAINT_RECT, rect(0, 0, 240, 360))

    # Vertical color bands.
    p.color(OP_FGCOLOR, 240, 112, 64)
    p.op(OP_PAINT_RECT, rect(0, 0, 70, 360))

    p.color(OP_BGCOLOR, 248, 232, 200)
    p.color(OP_FGCOLOR, 26, 30, 46)
    p.op(OP_FILLPAT, PAT_50)
    p.op(OP_FILL_RECT, rect(70, 0, 120, 360))

    p.color(OP_FGCOLOR, 252, 208, 92)
    p.op(OP_PAINT_RECT, rect(120, 0, 170, 360))

    p.color(OP_FGCOLOR, 56, 190, 184)
    p.op(OP_PAINT_RECT, rect(170, 0, 240, 360))

    # Inner keyline.
    p.color(OP_FGCOLOR, 250, 250, 245)
    p.op(OP_FRAME_RECT, rect(8, 8, 232, 352))

    # Oval sun with a diagonal hatch fill.
    p.color(OP_BGCOLOR, 250, 250, 245)
    p.color(OP_FGCOLOR, 226, 64, 112)
    p.op(OP_FILLPAT, PAT_DIAG)
    p.op(OP_PAINT_OVAL, rect(38, 52, 148, 246))

    # Arc sweeping over the sun.
    p.color(OP_FGCOLOR, 255, 242, 132)
    p.op(OP_PAINT_ARC, rect(96, 30, 214, 240) + i16(0) + i16(180))

    # Polygon hill silhouette.
    p.color(OP_FGCOLOR, 26, 30, 46)
    points = [(212, 228), (168, 246), (190, 302), (226, 322), (212, 340)]
    poly_bounds = rect(160, 220, 232, 344)
    p.op(OP_PAINT_POLY, u16(10 + 4 * len(points)) + poly_bounds + b"".join(
        i16(y) + i16(x) for y, x in points
    ))

    # Highlight badge.
    p.color(OP_FGCOLOR, 255, 255, 255)
    p.op(OP_PAINT_ROUND, rect(186, 18, 226, 100))

    # A long diagonal accent line.
    p.op(OP_PENSIZE, i16(3) + i16(3))
    p.color(OP_FGCOLOR, 250, 250, 245)
    p.op(OP_LINE, i16(236) + i16(18) + i16(16) + i16(236))

    # Outer frame.
    p.color(OP_FGCOLOR, 22, 28, 44)
    p.op(OP_FRAME_RECT, rect(0, 0, 240, 360))
    return p.render()


def make_flags() -> bytes:
    p = Pict(240, 160)

    # Strict-safe field: rectangles, RGB colors and 8x8 patterns only.
    p.color(OP_BGCOLOR, 255, 255, 255)
    p.color(OP_FGCOLOR, 18, 26, 44)
    p.op(OP_PAINT_RECT, rect(0, 0, 160, 240))

    bands = [
        (0, 42, (208, 58, 60)),
        (42, 82, (246, 160, 56)),
        (82, 128, (70, 168, 94)),
        (128, 160, (54, 104, 196)),
    ]
    for top, bottom, color in bands:
        p.color(OP_FGCOLOR, *color)
        p.op(OP_PAINT_RECT, rect(top, 0, bottom, 240))

    # Textured stripe.
    p.color(OP_BGCOLOR, 255, 255, 255)
    p.color(OP_FGCOLOR, 18, 26, 44)
    p.op(OP_FILLPAT, PAT_DOTS)
    p.op(OP_FILL_RECT, rect(56, 0, 76, 240))

    # Erased and inverted swatches.
    p.color(OP_BGCOLOR, 255, 255, 255)
    p.op(OP_ERASE_RECT, rect(24, 16, 52, 72))
    p.op(OP_INVERT_RECT, rect(96, 160, 140, 216))

    # Frame keyline.
    p.color(OP_FGCOLOR, 255, 255, 255)
    p.op(OP_FRAME_RECT, rect(4, 4, 156, 236))
    return p.render()


def make_text() -> bytes:
    p = Pict(160, 48)
    p.color(OP_BGCOLOR, 255, 255, 255)
    p.color(OP_FGCOLOR, 0, 0, 0)
    p.op(OP_FONT, u16(7))
    p.op(OP_SIZE, u16(3))
    # The demo NFNT only provides glyphs for 'A' and 'B', so draw those.
    p.op(OP_TEXT, i16(20) + i16(4) + bytes([2]) + b"AB")
    return p.render()


def make_badge() -> bytes:
    """Small 120x90 picture used for the PICT resource 129 sample."""
    p = Pict(120, 90)
    p.color(OP_BGCOLOR, 250, 244, 228)
    p.color(OP_FGCOLOR, 40, 92, 168)
    p.op(OP_PAINT_RECT, rect(0, 0, 90, 120))

    p.color(OP_FGCOLOR, 252, 214, 92)
    p.op(OP_PAINT_RECT, rect(0, 0, 26, 120))

    p.color(OP_FGCOLOR, 244, 246, 250)
    p.op(OP_PAINT_OVAL, rect(30, 44, 82, 104))

    p.color(OP_FGCOLOR, 220, 70, 96)
    p.op(OP_PAINT_RECT, rect(58, 54, 68, 94))

    p.color(OP_FGCOLOR, 250, 250, 245)
    p.op(OP_FRAME_RECT, rect(4, 4, 86, 116))
    return p.render()


# NFNT payload from the documented quickdraw-cli test helper layout.
NFNT_WORDS_1 = [0x1000, 65, 66, 4, 0, 0, 3, 3, 12, 3, 0, 0, 1]
NFNT_BYTES = bytes([0x5C, 0x00, 0xB4, 0x00, 0xFC, 0x00])
NFNT_WORDS_2 = [0, 3, 5, 6]
NFNT_WORDS_3 = [4, 0x0103, 2, -1]


def make_nfnt() -> bytes:
    return (
        b"".join(i16(w) for w in NFNT_WORDS_1)
        + NFNT_BYTES
        + b"".join(i16(w) for w in NFNT_WORDS_2)
        + b"".join(i16(w) for w in NFNT_WORDS_3)
    )


def make_fonts_json() -> bytes:
    payload = {
        "schema": 1,
        "fonts": [{"id": 7, "size": 3, "face": 0, "path": "font.nfnt"}],
    }
    return (json.dumps(payload, separators=(",", ":")) + "\n").encode("ascii")


def make_resource_fork(resources: list[tuple[bytes, int, bytes]]) -> bytes:
    """Build a classic Macintosh resource fork for several resource types.

    ``resources`` is a list of (type, id, payload). Reference lists are grouped
    by type, and type entries are ordered lexicographically.
    """
    resources = sorted(resources, key=lambda item: (item[0], item[1]))

    data = bytearray()
    offsets: list[int] = []
    for _, _, payload in resources:
        offsets.append(len(data))
        data += struct.pack(">I", len(payload))
        data += payload
    data_len = len(data)

    types: list[bytes] = []
    for kind, _, _ in resources:
        if kind not in types:
            types.append(kind)
    types.sort()

    type_list_offset = 28
    refs_start = type_list_offset + 2 + 8 * len(types)
    name_list_offset = refs_start + 12 * len(resources)

    # Name list format: u16 offset to first name plus length-prefixed names.
    # Reference entries use -1 so the list only carries its two-byte header.
    names = u16(2)

    map_len = name_list_offset + len(names)
    map_offset = 256 + data_len
    header = (
        struct.pack(">I", 256)
        + struct.pack(">I", map_offset)
        + struct.pack(">I", data_len)
        + struct.pack(">I", map_len)
    )

    rmap = bytearray(header)
    rmap += bytes(4)  # next resource map handle
    rmap += u16(0)  # file reference number
    rmap += u16(0)  # resource fork attributes
    rmap += u16(type_list_offset)
    rmap += u16(name_list_offset)

    rmap += u16(len(types) - 1)
    # Resource type entries come first, each pointing at its reference list.
    ref_cursor = refs_start
    type_refs: list[list[int]] = []
    for kind in types:
        members = [i for i, item in enumerate(resources) if item[0] == kind]
        rmap += kind
        rmap += u16(len(members) - 1)
        rmap += u16(ref_cursor - type_list_offset)  # relative to type list
        type_refs.append(members)
        ref_cursor += 12 * len(members)

    # Then the 12-byte reference list entries for every type.
    for members in type_refs:
        for index in members:
            rmap += i16(resources[index][1])
            rmap += i16(-1)  # no resource name
            rmap += b"\x00"  # attributes
            rmap += offsets[index].to_bytes(3, "big")  # relative to data start
            rmap += bytes(4)  # reserved handle

    rmap += names
    assert len(rmap) == map_len

    return header + bytes(256 - 16) + bytes(data) + bytes(rmap)


def build() -> dict[str, bytes]:
    poster = make_poster()
    flags = make_flags()
    text = make_text()
    font = make_nfnt()
    badge = make_badge()
    return {
        "poster.pict": poster,
        "flags.pict": flags,
        "text.pict": text,
        "font.nfnt": font,
        "fonts.json": make_fonts_json(),
        "drawing.rsrc": make_resource_fork(
            [
                (b"PICT", 128, poster),
                (b"PICT", 129, badge),
                (b"NFNT", 7, font),
            ]
        ),
        "broken.pict": b"\0",
    }


def main() -> None:
    SAMPLES.mkdir(parents=True, exist_ok=True)
    for name, payload in build().items():
        (SAMPLES / name).write_bytes(payload)
        print(f"wrote {name} ({len(payload)} bytes)")


if __name__ == "__main__":
    main()
