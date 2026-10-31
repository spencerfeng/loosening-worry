"""Lesson illustrations: 342x200 flat SVGs, one per lesson card. ART["dayN.slot"] = (panel tint, svg body).

The panel behind each drawing is the card's `tint` in lessons.json, drawn by the app, so the art itself has no background.
No words inside the art: it can't be translated. Run generate.py after changing anything here.
"""
import math
V, VT, VL = '#6A4FD8', '#EEE9FC', '#D9CFF8'
A, AT = '#F0A33A', '#FDF0DC'
G, GT, GD = '#4CB782', '#E3F4EA', '#2E8A5C'
B, BT, BL, BS = '#2E6AE6', '#E4EDFD', '#C9D9FA', '#5B8DF0'
R, W, INK = '#D9574B', '#FFFFFF', '#262624'

def spark(x, y, c, k=1):
    return (f'<path d="M{x} {y-9*k}l{2.4*k} {6.6*k} {6.6*k} {2.4*k} {-6.6*k} {2.4*k} {-2.4*k} {6.6*k} '
            f'{-2.4*k} {-6.6*k} {-6.6*k} {-2.4*k} {6.6*k} {-2.4*k}z" fill="{c}"/>')

def dots3(cx, cy, c=W, gap=10, r=3.5):
    return ''.join(f'<circle cx="{cx+(i-1)*gap}" cy="{cy}" r="{r}" fill="{c}"/>' for i in range(3))

def star(cx, cy, r, c):
    pts = []
    for i in range(10):
        a = -math.pi/2 + i*math.pi/5
        rr = r if i % 2 == 0 else r*0.45
        pts.append(f'{cx+rr*math.cos(a):.1f},{cy+rr*math.sin(a):.1f}')
    return f'<polygon points="{" ".join(pts)}" fill="{c}"/>'

def bolt(cx, cy, c=W, k=1):
    return f'<path d="M{cx+3*k} {cy-13*k}l{-11*k} {15*k}h{9*k}l{-4*k} {12*k} {12*k} {-16*k}h{-9*k}z" fill="{c}"/>'

def clock(cx, cy, r, rim=V, face=W, h=(0, -0.55), m=(0.4, 0.25)):
    return (f'<circle cx="{cx}" cy="{cy}" r="{r}" fill="{face}" stroke="{rim}" stroke-width="{r*0.16:.1f}"/>'
            f'<path d="M{cx} {cy}l{h[0]*r:.1f} {h[1]*r:.1f}M{cx} {cy}l{m[0]*r:.1f} {m[1]*r:.1f}" stroke="{rim}" '
            f'stroke-width="{r*0.14:.1f}" stroke-linecap="round"/>')

def moon(cx, cy, r, c, bg):
    return f'<circle cx="{cx}" cy="{cy}" r="{r}" fill="{c}"/><circle cx="{cx+r*0.45:.1f}" cy="{cy-r*0.3:.1f}" r="{r*0.82:.1f}" fill="{bg}"/>'

def cloud(cx, cy, s, c):
    return (f'<circle cx="{cx-18*s}" cy="{cy+4*s}" r="{14*s}" fill="{c}"/><circle cx="{cx}" cy="{cy-6*s}" r="{20*s}" fill="{c}"/>'
            f'<circle cx="{cx+18*s}" cy="{cy+4*s}" r="{14*s}" fill="{c}"/><rect x="{cx-18*s}" y="{cy+2*s}" width="{36*s}" height="{16*s}" fill="{c}"/>')

def pin(cx, cy, s, c):
    return (f'<path d="M{cx} {cy+26*s}C{cx-6*s} {cy+14*s} {cx-15*s} {cy+8*s} {cx-15*s} {cy-2*s}a{15*s} {15*s} 0 0 1 {30*s} 0'
            f'c0 {10*s} {-9*s} {16*s} {-15*s} {28*s}z" fill="{c}"/><circle cx="{cx}" cy="{cy-2*s}" r="{5.5*s}" fill="{W}"/>')

def person(cx, cy, s, c):
    return (f'<circle cx="{cx}" cy="{cy-14*s}" r="{9*s}" fill="{c}"/>'
            f'<path d="M{cx-16*s} {cy+16*s}Q{cx-16*s} {cy-2*s} {cx} {cy-2*s}Q{cx+16*s} {cy-2*s} {cx+16*s} {cy+16*s}z" fill="{c}"/>')

def phone(x, y, w, h, c=V, screen=W):
    return f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="{w*0.2:.0f}" fill="{c}"/><rect x="{x+6}" y="{y+12}" width="{w-12}" height="{h-24}" rx="{w*0.12:.0f}" fill="{screen}"/>'

def envelope(x, y, w, h, c=W, flap=BL):
    return (f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="8" fill="{c}"/>'
            f'<path d="M{x+6} {y+8}L{x+w/2} {y+h*0.55}L{x+w-6} {y+8}" fill="none" stroke="{flap}" stroke-width="5" stroke-linecap="round" stroke-linejoin="round"/>')

def bell(cx, cy, s, c):
    return (f'<path d="M{cx-18*s} {cy+12*s}Q{cx-16*s} {cy-22*s} {cx} {cy-22*s}Q{cx+16*s} {cy-22*s} {cx+18*s} {cy+12*s}z" fill="{c}"/>'
            f'<rect x="{cx-24*s}" y="{cy+10*s}" width="{48*s}" height="{8*s}" rx="{4*s}" fill="{c}"/><circle cx="{cx}" cy="{cy+24*s}" r="{6*s}" fill="{c}"/>')

def gear(cx, cy, r, c, hole):
    return (f'<circle cx="{cx}" cy="{cy}" r="{r}" fill="none" stroke="{c}" stroke-width="{r*0.45:.1f}" stroke-dasharray="{r*0.42:.1f} {r*0.36:.1f}"/>'
            f'<circle cx="{cx}" cy="{cy}" r="{r*0.82:.1f}" fill="{c}"/><circle cx="{cx}" cy="{cy}" r="{r*0.32:.1f}" fill="{hole}"/>')

def check(cx, cy, r, c=G):
    return (f'<circle cx="{cx}" cy="{cy}" r="{r}" fill="{c}"/><path d="M{cx-r*0.45:.1f} {cy+r*0.02:.1f}l{r*0.3:.1f} {r*0.3:.1f} {r*0.55:.1f} {-r*0.6:.1f}" '
            f'fill="none" stroke="{W}" stroke-width="{r*0.2:.1f}" stroke-linecap="round" stroke-linejoin="round"/>')

def lines(x, y, ws, c=BL, gap=22, h=8):
    return ''.join(f'<rect x="{x}" y="{y+i*gap}" width="{w}" height="{h}" rx="{h/2}" fill="{c}"/>' for i, w in enumerate(ws))

def notebook(x=118, y=28, extra=''):
    return (f'<rect x="{x}" y="{y}" width="104" height="146" rx="14" fill="{W}"/>'
            f'<circle cx="{x+20}" cy="{y+32}" r="6" fill="{A}"/><circle cx="{x+20}" cy="{y+58}" r="6" fill="{V}"/><circle cx="{x+20}" cy="{y+84}" r="6" fill="{G}"/>'
            + lines(x+34, y+28, [52, 44, 48], gap=26) + lines(x+14, y+110, [40]) + extra)

def pencil(cx, cy, rot=35):
    return (f'<g transform="translate({cx} {cy}) rotate({rot})"><rect x="-9" y="-44" width="18" height="66" rx="3" fill="{A}"/>'
            f'<rect x="-9" y="-52" width="18" height="12" rx="4" fill="{R}"/><path d="M-9 22 L0 40 L9 22z" fill="#F5D7A8"/><path d="M-3.5 33 L0 40 L3.5 33z" fill="#6E4A1E"/></g>')

def arrowhead(x, y, rot, c, k=1):
    return f'<path d="M{-8*k} {-7*k} L{8*k} 0 L{-8*k} {7*k}z" transform="translate({x} {y}) rotate({rot})" fill="{c}"/>'

def ring3(cx=171, cy=100, r=62, trig=None, beh=None, res=None, ringc='#A9C3F8', arr=BS):
    pts = [(cx, cy-r), (cx+r*math.cos(math.radians(30)), cy+r*0.5), (cx-r*math.cos(math.radians(30)), cy+r*0.5)]
    out = f'<circle cx="{cx}" cy="{cy}" r="{r}" fill="none" stroke="{ringc}" stroke-width="10"/>'
    for ang, rot in [(-30, 60), (90, 180), (210, -60)]:
        out += arrowhead(round(cx+r*math.cos(math.radians(ang)), 1), round(cy+r*math.sin(math.radians(ang)), 1), rot, arr)
    (tx, ty), (bx, by), (rx, ry) = pts
    out += (trig if trig is not None else f'<circle cx="{tx}" cy="{ty}" r="26" fill="{A}"/>' + bolt(tx, ty))
    out += (beh if beh is not None else f'<circle cx="{bx:.1f}" cy="{by}" r="26" fill="{V}"/>' + dots3(bx, by))
    out += (res if res is not None else f'<circle cx="{rx:.1f}" cy="{ry}" r="26" fill="{G}"/>' + star(rx, ry, 13, W))
    return out

TAN, VM, BM = '#C9A982', '#B3A2F5', '#A9C3F8'


def mag(cx, cy, r, c=GD, fill=W):
    return (f'<path d="M{cx+r*0.7:.1f} {cy+r*0.7:.1f}l{r*0.8:.1f} {r*0.8:.1f}" stroke="{c}" stroke-width="{r*0.36:.1f}" stroke-linecap="round"/>'
            f'<circle cx="{cx}" cy="{cy}" r="{r}" fill="{fill}" fill-opacity="0.8" stroke="{c}" stroke-width="{r*0.24:.1f}"/>')


def heart(cx, cy, s, c=R):
    return (f'<path d="M{cx} {cy+18*s}C{cx-26*s} {cy+2*s} {cx-22*s} {cy-18*s} {cx-10*s} {cy-18*s}C{cx-4*s} {cy-18*s} {cx} {cy-13*s} '
            f'{cx} {cy-9*s}C{cx} {cy-13*s} {cx+4*s} {cy-18*s} {cx+10*s} {cy-18*s}C{cx+22*s} {cy-18*s} {cx+26*s} {cy+2*s} {cx} {cy+18*s}z" fill="{c}"/>')


def calendar(x, y, w, h, head=R, marks=()):
    cells = ''.join(f'<circle cx="{x+w*(0.2+0.2*(i%4)):.1f}" cy="{y+h*(0.45+0.2*(i//4)):.1f}" r="{min(w, h)*0.055:.1f}" '
                    f'fill="{marks[i] if i < len(marks) and marks[i] else BL}"/>' for i in range(12))
    return (f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="12" fill="{W}"/>'
            f'<path d="M{x} {y+12}a12 12 0 0 1 12 -12h{w-24}a12 12 0 0 1 12 12v{h*0.14:.1f}h{-w}z" fill="{head}"/>' + cells)


def bars(x, base, heights, colors, w=22, gap=12):
    return ''.join(f'<rect x="{x+i*(w+gap)}" y="{base-h}" width="{w}" height="{h}" rx="6" fill="{c}"/>'
                   for i, (h, c) in enumerate(zip(heights, colors)))


def wave(x, y, w, amp, c, sw=7, n=2):
    seg = w / (n * 2)
    d = f'M{x} {y}' + ''.join(f' q{seg/2:.1f} {-amp if i % 2 == 0 else amp} {seg:.1f} 0' for i in range(n * 2))
    return f'<path d="{d}" fill="none" stroke="{c}" stroke-width="{sw}" stroke-linecap="round"/>'


def eye(cx, cy, s, iris=V):
    return (f'<path d="M{cx-52*s} {cy}Q{cx} {cy-52*s} {cx+52*s} {cy}Q{cx} {cy+52*s} {cx-52*s} {cy}z" fill="{W}"/>'
            f'<circle cx="{cx}" cy="{cy}" r="{22*s}" fill="{iris}"/><circle cx="{cx}" cy="{cy}" r="{9*s}" fill="{INK}"/>'
            f'<circle cx="{cx+6*s}" cy="{cy-6*s}" r="{4*s}" fill="{W}"/>')


def bubble(x, y, w, h, c=W, tail='left'):
    tx = x + 24 if tail == 'left' else x + w - 24
    d = f'M{tx-6} {y+h-2}l{-8 if tail == "left" else 8} 16 {20 if tail == "left" else -20} -14z'
    return f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="{min(h/2, 22)}" fill="{c}"/><path d="{d}" fill="{c}"/>'


def chip(x, y, w, c, line=W):
    return f'<rect x="{x}" y="{y}" width="{w}" height="34" rx="17" fill="{c}"/><rect x="{x+14}" y="{y+13}" width="{w-28}" height="8" rx="4" fill="{line}" fill-opacity="0.85"/>'


def refresh(cx, cy, r, c, sw=8):
    # A clockwise arc from the top round to 10 o'clock. The arrowhead's base sits on the arc's end and its tip on the
    # circle a little further round, so the head follows the curve.
    end = math.radians(200)
    ex, ey = cx + r * math.cos(end), cy + r * math.sin(end)
    half = sw * 1.05
    tip = end + 2.1 * sw / r
    tx, ty = cx + r * math.cos(tip), cy + r * math.sin(tip)
    dx, dy = tx - ex, ty - ey
    n = math.hypot(dx, dy)
    px, py = -dy / n * half, dx / n * half
    return (f'<path d="M{cx} {cy-r}A{r} {r} 0 1 1 {ex:.1f} {ey:.1f}" fill="none" stroke="{c}" stroke-width="{sw}" stroke-linecap="round"/>'
            + f'<path d="M{ex+px:.1f} {ey+py:.1f} L{tx:.1f} {ty:.1f} L{ex-px:.1f} {ey-py:.1f}z" fill="{c}" stroke="{c}" stroke-width="{sw*0.3:.1f}" stroke-linejoin="round"/>')


def stopwatch(cx, cy, r, rim=V, face=W, frac=0.25):
    a = math.radians(-90 + 360 * frac)
    return (f'<rect x="{cx-6}" y="{cy-r-14}" width="12" height="10" rx="3" fill="{rim}"/>'
            f'<circle cx="{cx}" cy="{cy}" r="{r}" fill="{face}" stroke="{rim}" stroke-width="{r*0.16:.1f}"/>'
            f'<path d="M{cx} {cy-r*0.7:.1f}A{r*0.7:.1f} {r*0.7:.1f} 0 0 1 {cx+r*0.7*math.cos(a):.1f} {cy+r*0.7*math.sin(a):.1f}L{cx} {cy}z" fill="{rim}" fill-opacity="0.35"/>'
            f'<path d="M{cx} {cy}L{cx+r*0.6*math.cos(a):.1f} {cy+r*0.6*math.sin(a):.1f}" stroke="{rim}" stroke-width="{r*0.13:.1f}" stroke-linecap="round"/>')


def tile(x, y, s, bg, inner):
    return f'<rect x="{x}" y="{y}" width="{s}" height="{s}" rx="{s*0.28:.0f}" fill="{bg}"/>' + inner


def tool_tile(index, x, y, s):
    """One of the four tools' tiles, in Home's order: Get curious, Breathe, Note it, Be kind."""
    c, k = s / 2, s / 56
    inner = [
        (BL, mag(x + c - 4 * k, y + c - 4 * k, s * 0.2, B)),
        ('#CDEBD9', wave(x + 10 * k, y + c, s - 20 * k, 8 * k, GD, 5 * k, 1)),
        ('#F7DDB5', lines(x + 12 * k, y + 16 * k, [s * 0.57, s * 0.43, s * 0.29], c='#B86E12', gap=10 * k, h=5 * k)),
        ('#F6CFCB', heart(x + c, y + c + 1, 0.62 * k, R)),
    ][index]
    return tile(x, y, s, inner[0], inner[1])


def tool_tiles(x, y, s=56, gap=14):
    return ''.join(tool_tile(i, x + i * (s + gap), y, s) for i in range(4))


def person_scan(cx, cy, s, c=BS):
    return person(cx, cy, s, c)


def plant(cx, base, h, c=G):
    return (f'<path d="M{cx} {base}V{base-h}" stroke="{GD}" stroke-width="5" stroke-linecap="round"/>'
            f'<path d="M{cx} {base-h*0.5}C{cx-h*0.5} {base-h*0.55} {cx-h*0.55} {base-h*0.85} {cx-h*0.45} {base-h*0.95}C{cx-h*0.15} {base-h*0.9} {cx} {base-h*0.75} {cx} {base-h*0.5}z" fill="{c}"/>'
            f'<path d="M{cx} {base-h*0.7}C{cx+h*0.45} {base-h*0.75} {cx+h*0.5} {base-h*1.05} {cx+h*0.42} {base-h*1.12}C{cx+h*0.12} {base-h*1.08} {cx} {base-h*0.92} {cx} {base-h*0.7}z" fill="{c}"/>')


def breath(cx, cy, r, c=G):
    return (f'<circle cx="{cx}" cy="{cy}" r="{r*1.45:.1f}" fill="{c}" fill-opacity="0.18"/><circle cx="{cx}" cy="{cy}" r="{r*1.2:.1f}" fill="{c}" fill-opacity="0.25"/>'
            f'<circle cx="{cx}" cy="{cy}" r="{r}" fill="{c}"/>')


def rings(cx, cy, r):
    return (f'<circle cx="{cx}" cy="{cy}" r="{r}" fill="{VT}"/><circle cx="{cx}" cy="{cy}" r="{r*0.72:.1f}" fill="#D9CFF8"/>'
            f'<circle cx="{cx}" cy="{cy}" r="{r*0.44:.1f}" fill="{V}"/><circle cx="{cx+r*0.78:.1f}" cy="{cy-r*0.6:.1f}" r="{r*0.15:.1f}" fill="{A}"/>'
            f'<circle cx="{cx-r*0.74:.1f}" cy="{cy+r*0.62:.1f}" r="{r*0.11:.1f}" fill="{G}"/>')


def cookie(cx, cy, r):
    return (f'<circle cx="{cx}" cy="{cy}" r="{r}" fill="#D9A766"/>' + ''.join(
        f'<circle cx="{cx+dx*r:.1f}" cy="{cy+dy*r:.1f}" r="{r*0.12:.1f}" fill="#6E4A1E"/>' for dx, dy in [(-0.4, -0.3), (0.3, -0.45), (0.1, 0.1), (-0.3, 0.4), (0.45, 0.3)]))


def flag(x, base, h, c=G):
    return f'<path d="M{x} {base}V{base-h}" stroke="{TAN}" stroke-width="5" stroke-linecap="round"/><path d="M{x} {base-h}h{h*0.6:.1f}l{-h*0.12:.1f} {h*0.18:.1f} {h*0.12:.1f} {h*0.18:.1f}h{-h*0.6:.1f}z" fill="{c}"/>'


ART = {}

# Day 1 · Welcome
ART['day1.hook'] = (VT, '<rect x="96" y="128" width="150" height="40" rx="20" fill="#FFFFFF"/><rect x="96" y="150" width="150" height="22" rx="8" fill="#D9CFF8"/>'
    + refresh(171, 76, 30, V, 9)
    + moon(262, 52, 22, A, VT) + clock(82, 62, 24, V, W, (0, -0.55), (-0.45, -0.2)) + spark(282, 132, G, 0.7) + spark(60, 140, A, 0.7))
ART['day1.idea1'] = (BT, phone(196, 34, 66, 132, V)
    + f'<rect x="210" y="58" width="38" height="20" rx="5" fill="{BS}"/><rect x="210" y="84" width="38" height="20" rx="5" fill="{A}"/><rect x="210" y="110" width="38" height="20" rx="5" fill="{G}"/>'
    + '<path d="M70 150 Q90 60 180 92" fill="none" stroke="#A9C3F8" stroke-width="8" stroke-linecap="round" stroke-dasharray="1 16"/>'
    + arrowhead(184, 94, 18, BS) + f'<circle cx="66" cy="156" r="20" fill="{V}"/>' + spark(290, 50, A, 0.8) + spark(110, 40, G, 0.6))
ART['day1.idea2'] = (BT, ring3(beh='') + gear(171, 100, 22, B, BT))
ART['day1.idea3'] = (GT, '<circle cx="150" cy="104" r="58" fill="none" stroke="#A9C3F8" stroke-width="10" stroke-dasharray="26 18" stroke-linecap="round"/>'
    + f'<path d="M232 170 V96" stroke="{GD}" stroke-width="7" stroke-linecap="round"/>'
    + f'<path d="M232 120 C206 118 198 96 202 84 C222 86 232 102 232 120z" fill="{G}"/><path d="M232 104 C254 100 264 78 260 66 C240 70 230 86 232 104z" fill="{G}"/>'
    + f'<rect x="206" y="166" width="52" height="14" rx="7" fill="#C9A982"/>' + spark(286, 120, A, 0.8) + spark(84, 44, V, 0.7))
ART['day1.example'] = (VT, '<rect x="70" y="40" width="150" height="104" rx="14" fill="#FFFFFF"/>' + envelope(104, 66, 82, 54)
    + f'<circle cx="214" cy="48" r="14" fill="{R}"/>' + moon(276, 52, 22, A, VT)
    + f'<path d="M234 122 l12 -14 12 14 12 -14 12 14" fill="none" stroke="{A}" stroke-width="7" stroke-linecap="round" stroke-linejoin="round"/>'
    + spark(282, 160, V, 0.7))
ART['day1.try'] = (AT, pin(130, 86, 1.9, V) + clock(222, 92, 38, A) + spark(80, 50, G, 0.8) + spark(282, 156, V, 0.7) + spark(176, 40, A, 0.6))
ART['day1.task'] = (BT, f'<path d="M180 128L214 162" stroke="{B}" stroke-width="16" stroke-linecap="round"/>'
    + f'<circle cx="146" cy="94" r="50" fill="{W}" stroke="{B}" stroke-width="10"/><circle cx="146" cy="94" r="30" fill="{A}"/>' + bolt(146, 94, W, 1.25)
    + f'<rect x="216" y="34" width="78" height="46" rx="20" fill="{W}"/><path d="M226 74 l-10 18 22-12z" fill="{W}"/>' + dots3(255, 57, V, 14, 5)
    + spark(70, 50, V, 0.8) + spark(270, 150, G, 0.8) + spark(66, 150, A, 0.6))

# Day 2 · Your brain loves loops
ART['day2.hook'] = (VT, phone(131, 22, 80, 156, V)
    + f'<rect x="143" y="42" width="56" height="28" rx="6" fill="{A}"/><rect x="143" y="76" width="56" height="28" rx="6" fill="{BS}"/><rect x="143" y="110" width="56" height="28" rx="6" fill="{G}"/><rect x="143" y="144" width="56" height="16" rx="6" fill="{VL}"/>'
    + clock(246, 56, 18, V) + f'<text x="90" y="80" font-size="40" font-weight="800" fill="{V}" font-family="Figtree, sans-serif">?</text>'
    + '<path d="M104 104v40m-8-8l8 8 8-8" fill="none" stroke="#B3A2F5" stroke-width="4" stroke-linecap="round" stroke-linejoin="round"/>'
    + spark(262, 142, A) + spark(282, 112, G, 0.7) + spark(80, 150, BS, 0.7))
ART['day2.idea1'] = (BT, ring3() + spark(272, 46, A) + spark(66, 70, G, 0.7))
ART['day2.idea2'] = (AT, refresh(150, 108, 50, A, 12)
    + f'<circle cx="150" cy="108" r="22" fill="{V}"/>' + dots3(150, 108, gap=9) + star(252, 70, 28, G)
    + f'<path d="M236 104 Q228 134 206 128" fill="none" stroke="{G}" stroke-width="4" stroke-linecap="round" stroke-dasharray="2 9"/>'
    + spark(292, 52, A, 0.8) + spark(282, 118, BS, 0.7) + spark(84, 46, G, 0.7))
ART['day2.idea3'] = (GT, f'<path d="M159.7 44.8 A56 56 0 0 1 202.6 119.2" fill="none" stroke="{A}" stroke-width="14" stroke-linecap="round"/>'
    + f'<path d="M192.9 136 A56 56 0 0 1 107.1 136" fill="none" stroke="{V}" stroke-width="14" stroke-linecap="round"/>'
    + f'<path d="M97.4 119.2 A56 56 0 0 1 140.3 44.8" fill="none" stroke="{BS}" stroke-width="14" stroke-linecap="round"/>'
    + f'<path d="M262 108l28 28" stroke="{GD}" stroke-width="13" stroke-linecap="round"/><circle cx="240" cy="84" r="34" fill="{W}" fill-opacity="0.75" stroke="{GD}" stroke-width="8"/>'
    + spark(290, 46, A, 0.8) + spark(70, 52, V, 0.7) + spark(80, 160, G))
ART['day2.example'] = (VT, f'<rect x="56" y="36" width="206" height="58" rx="20" fill="{W}"/><path d="M76 90 l-6 14 18-10z" fill="{W}"/><circle cx="84" cy="65" r="15" fill="{BS}"/>'
    + lines(110, 54, [120, 80], c=BL, gap=16)
    + f'<circle cx="206" cy="116" r="6" fill="{A}"/><circle cx="222" cy="128" r="9" fill="{A}"/><circle cx="256" cy="150" r="30" fill="{A}"/>'
    + f'<text x="256" y="161" text-anchor="middle" font-size="30" font-weight="800" fill="{W}" font-family="Figtree, sans-serif">?!</text>'
    + spark(290, 44, G, 0.8) + spark(92, 146, V) + spark(124, 170, A, 0.6))
ART['day2.try'] = (AT, ''.join(
    f'<rect x="{x}" y="{y}" width="150" height="40" rx="18" fill="{c}"/><circle cx="{x+22}" cy="{y+20}" r="11" fill="{W}"/>'
    f'<text x="{x+22}" y="{y+25.5}" text-anchor="middle" font-size="14" font-weight="800" fill="{c}" font-family="Figtree, sans-serif">{n}</text>'
    f'<rect x="{x+42}" y="{y+16}" width="88" height="8" rx="4" fill="{W}" fill-opacity="0.85"/>'
    for x, y, c, n in [(66, 24, A, 1), (126, 80, V, 2), (66, 136, G, 3)])
    + spark(258, 44, BS, 0.8) + spark(80, 108, V, 0.7) + spark(270, 160, A, 0.7))
ART['day2.task'] = (BT, notebook() + pencil(238, 120) + check(222, 40, 20) + spark(88, 60, A, 0.8) + spark(282, 150, V, 0.7) + spark(76, 150, G, 0.6))

# Day 3 · Worry as a behavior
ART['day3.hook'] = (BT, envelope(70, 52, 130, 90) + f'<circle cx="196" cy="56" r="20" fill="{R}"/>'
    + f'<text x="196" y="63" text-anchor="middle" font-size="19" font-weight="800" fill="{W}" font-family="Figtree, sans-serif">5</text>'
    + f'<path d="M262 128l26 26" stroke="{V}" stroke-width="12" stroke-linecap="round"/><circle cx="242" cy="106" r="30" fill="{W}" fill-opacity="0.8" stroke="{V}" stroke-width="8"/>'
    + lines(226, 98, [32, 22], c=BL, gap=14) + spark(290, 46, A, 0.8) + spark(60, 166, G, 0.6))
ART['day3.idea1'] = (AT, f'<circle cx="104" cy="100" r="54" fill="{W}"/>'
    + f'<path d="M72 100 q8 -16 16 0 t16 0 t16 0 t16 0" fill="none" stroke="{A}" stroke-width="7" stroke-linecap="round"/>'
    + f'<path d="M162 100h28" stroke="#C9A982" stroke-width="6" stroke-linecap="round"/>' + arrowhead(196, 100, 0, '#C9A982')
    + f'<circle cx="252" cy="100" r="54" fill="{V}"/>'
    + refresh(252, 100, 26, W, 7) + spark(296, 40, G, 0.7) + spark(56, 40, V, 0.6))
ART['day3.idea2'] = (VT, ring3(beh=cloud(224.7, 131, 0.95, V) + '<path d="M216 132 a8 8 0 1 1 9 8" fill="none" stroke="#FFFFFF" stroke-width="3.5" stroke-linecap="round"/>', ringc=VL, arr=V)
    + spark(276, 50, A, 0.8) + spark(66, 160, G, 0.6))
ART['day3.idea3'] = (GT, '<path d="M120 26 L60 176 L180 176z" fill="#FFF4C8" fill-opacity="0.9"/>' + f'<circle cx="120" cy="138" r="30" fill="{V}"/>' + dots3(120, 138)
    + f'<path d="M180 138 H222 M222 138 L258 102 M222 138 L258 174" fill="none" stroke="{G}" stroke-width="7" stroke-linecap="round" stroke-linejoin="round"/>'
    + arrowhead(262, 98, -45, G) + arrowhead(262, 178, 45, G) + f'<circle cx="120" cy="26" r="12" fill="{A}"/>' + spark(296, 52, A, 0.7))
ART['day3.example'] = (BT, phone(128, 18, 86, 166, V)
    + f'<rect x="142" y="42" width="48" height="20" rx="10" fill="{BL}"/><rect x="152" y="70" width="48" height="20" rx="10" fill="{BS}"/><rect x="142" y="98" width="40" height="20" rx="10" fill="{BL}"/><rect x="142" y="126" width="52" height="20" rx="10" fill="{BL}"/>'
    + '<path d="M246 140 V60" stroke="#A9C3F8" stroke-width="7" stroke-linecap="round"/>' + arrowhead(246, 56, -90, BS)
    + f'<circle cx="92" cy="70" r="22" fill="{A}"/><text x="92" y="79" text-anchor="middle" font-size="26" font-weight="800" fill="{W}" font-family="Figtree, sans-serif">?</text>'
    + spark(290, 150, G, 0.7))
ART['day3.try'] = (AT, ''.join(f'<rect x="{x}" y="78" width="80" height="44" rx="22" fill="{c}"/>' for x, c in [(44, V), (131, A), (218, G)])
    + '<path d="M96 92 A10 10 0 1 0 98 108" fill="none" stroke="#FFFFFF" stroke-width="4" stroke-linecap="round"/>' + arrowhead(95, 90, -150, W, 0.55)
    + lines(156, 90, [30, 22], c=W, gap=12, h=5)
    + f'<path d="M244 100l7 7 13-14" fill="none" stroke="{W}" stroke-width="5" stroke-linecap="round" stroke-linejoin="round"/>'
    + f'<text x="171" y="58" text-anchor="middle" font-size="34" font-weight="800" fill="#C9A982" font-family="Figtree, sans-serif">?</text>'
    + spark(64, 50, B, 0.7) + spark(282, 156, V, 0.7))
ART['day3.task'] = (BT, notebook() + cloud(244, 52, 0.9, V) + pencil(240, 130) + spark(84, 60, A, 0.8) + spark(84, 150, G, 0.6))

# Day 4 · Finding your triggers
ART['day4.hook'] = (AT, f'<rect x="64" y="40" width="112" height="116" rx="14" fill="{W}"/><rect x="64" y="40" width="112" height="28" rx="14" fill="{R}"/><rect x="64" y="56" width="112" height="12" fill="{R}"/>'
    + ''.join(f'<circle cx="{84+(i%4)*24}" cy="{88+(i//4)*24}" r="6" fill="{BL if i != 6 else V}"/>' for i in range(12))
    + f'<path d="M206 150 A50 50 0 0 1 306 150z" fill="{A}"/><rect x="196" y="150" width="120" height="8" rx="4" fill="#C9A982"/>'
    + f'<path d="M256 60 V96" stroke="{V}" stroke-width="7" stroke-linecap="round"/>' + arrowhead(256, 100, 90, V) + spark(300, 54, V, 0.6))
ART['day4.idea1'] = (BT, pin(70, 70, 1.1, V) + clock(170, 56, 22, A) + bell(272, 64, 0.95, G)
    + person(88, 150, 1.2, BS) + cloud(176, 146, 0.9, V) + f'<path d="M262 164 C236 148 240 128 252 128 C258 128 262 133 262 137 C262 133 266 128 272 128 C284 128 288 148 262 164z" fill="{R}"/>' + spark(122, 104, A, 0.6) + spark(226, 104, G, 0.6))
ART['day4.idea2'] = (GT, f'<path d="M210 124l42 42" stroke="{GD}" stroke-width="14" stroke-linecap="round"/><circle cx="170" cy="86" r="58" fill="{W}" fill-opacity="0.85" stroke="{GD}" stroke-width="10"/>'
    + bolt(170, 86, A, 1.6) + f'<circle cx="80" cy="156" r="5" fill="{A}"/><circle cx="276" cy="52" r="4" fill="{V}"/><circle cx="64" cy="64" r="3.5" fill="{BS}"/>'
    + spark(292, 150, A, 0.6))
ART['day4.idea3'] = (VT, f'<path d="M110 100 Q171 36 232 100 Q171 164 110 100z" fill="{W}"/><circle cx="171" cy="100" r="26" fill="{V}"/><circle cx="171" cy="100" r="11" fill="#262624"/><circle cx="178" cy="93" r="5" fill="{W}"/>'
    + f'<path d="M40 100 H84" stroke="{A}" stroke-width="7" stroke-linecap="round" stroke-dasharray="2 12"/>' + bolt(40, 100, A, 1.2)
    + spark(272, 52, G, 0.8) + spark(282, 150, A, 0.6))
ART['day4.example'] = (VT, '<path d="M70 150 C110 60 170 170 200 96 S270 40 284 70" fill="none" stroke="#B3A2F5" stroke-width="6" stroke-linecap="round" stroke-dasharray="2 13"/>'
    + pin(70, 118, 1.1, A) + f'<rect x="56" y="150" width="28" height="18" rx="4" fill="{W}"/><rect x="56" y="155" width="28" height="4" fill="{A}"/>'
    + pin(200, 64, 1.1, BS) + f'<rect x="186" y="98" width="28" height="34" rx="3" fill="{W}"/>' + lines(192, 104, [6, 6, 6], c=BL, gap=9, h=5)
    + pin(284, 38, 1.1, V) + moon(300, 130, 16, A, VT) + f'<rect x="258" y="150" width="52" height="16" rx="8" fill="{W}"/>')
ART['day4.try'] = (AT, ''.join(f'<rect x="{x}" y="46" width="66" height="108" rx="16" fill="{W}"/>' for x in (36, 112, 188, 264))
    + pin(69, 92, 1, V) + clock(145, 100, 20, A) + person(221, 104, 1, BS) + cloud(297, 98, 0.62, G)
    + spark(171, 30, R, 0.6))
ART['day4.task'] = (BT, notebook(150, 28) + ''.join(f'<circle cx="92" cy="{y}" r="18" fill="{A}"/>' + bolt(92, y, W, 0.75) for y in (54, 100, 146))
    + check(122, 54, 8) + check(122, 100, 8) + f'<circle cx="122" cy="146" r="8" fill="none" stroke="{BL}" stroke-width="3"/>' + spark(290, 60, V, 0.7))

# Day 5 · Why worry feels useful
ART['day5.hook'] = (VT, f'<g transform="translate(104 86) rotate(-20)"><rect x="-56" y="-9" width="112" height="18" rx="9" fill="{BS}"/>'
    + f'<path d="M-6 -6 L-26 -40 H-12 L14 -6z M-6 6 L-26 40 H-12 L14 6z M-50 -4 L-58 -22 H-48 L-38 -4z" fill="{B}"/></g>'
    + f'<rect x="196" y="50" width="92" height="118" rx="12" fill="{W}"/>' + ''.join(check(214, 76+i*26, 8, A if i < 3 else BL) for i in range(4))
    + lines(230, 72, [42, 36, 46, 30], c=VL, gap=26) + moon(74, 156, 18, A, VT) + spark(160, 150, G, 0.7))
ART['day5.idea1'] = (VT, f'<rect x="112" y="80" width="118" height="88" rx="10" fill="{V}"/><rect x="104" y="60" width="134" height="30" rx="8" fill="#8A73EE"/>'
    + f'<rect x="162" y="60" width="18" height="108" fill="{A}"/>'
    + f'<path d="M171 60 C150 30 128 40 140 58z M171 60 C192 30 214 40 202 58z" fill="{A}"/>'
    + f'<text x="171" y="138" text-anchor="middle" font-size="40" font-weight="800" fill="{W}" font-family="Figtree, sans-serif">?</text>'
    + spark(272, 60, A, 0.9) + spark(80, 70, G, 0.7) + spark(270, 150, BS, 0.6))
ART['day5.idea2'] = (AT, f'<path d="M238 136 L252 70" stroke="#C9A982" stroke-width="9" stroke-linecap="round"/><rect x="226" y="52" width="58" height="24" rx="8" fill="#C9A982"/><rect x="236" y="59" width="26" height="10" rx="3" fill="{W}"/>'
    + f'<rect x="70" y="132" width="190" height="26" rx="13" fill="{V}"/>' + ''.join(f'<rect x="{x}" y="138" width="6" height="14" rx="3" fill="#8A73EE"/>' for x in range(94, 246, 20))
    + f'<circle cx="83" cy="145" r="7" fill="{W}"/><circle cx="247" cy="145" r="7" fill="{W}"/><rect x="74" y="158" width="18" height="16" rx="4" fill="#C9A982"/><rect x="238" y="158" width="18" height="16" rx="4" fill="#C9A982"/>'
    + refresh(165, 84, 30, A, 9)
    + f'<path d="M40 120 H64 M30 140 H58 M44 160 H64" stroke="{A}" stroke-width="5" stroke-linecap="round"/>' + spark(290, 40, G, 0.7) + spark(292, 150, V, 0.6))
ART['day5.idea3'] = (BT, ''.join(f'<g transform="translate({x} {y}) rotate({r})"><path d="M-44 -26 H30 L48 0 L30 26 H-44z" fill="{c}"/><circle cx="30" cy="0" r="5" fill="{BT}"/></g>'
    for x, y, r, c in [(96, 64, -8, V), (226, 64, 8, A), (160, 144, 0, G)])
    + f'<path d="M78 50 h18 v12 q0 12 -9 16 q-9 -4 -9 -16z" fill="{W}"/>'
    + f'<path d="M208 62l6 6 12-12" fill="none" stroke="{W}" stroke-width="5" stroke-linecap="round" stroke-linejoin="round"/>'
    + f'<path d="M126 146 a16 14 0 0 1 32 0z M142 146 v12 q0 5 5 5" fill="{W}" stroke="{W}" stroke-width="3" stroke-linecap="round"/>' + spark(296, 140, V, 0.6))
ART['day5.example'] = (VT, f'<rect x="56" y="32" width="92" height="120" rx="12" fill="{W}"/>' + lines(70, 54, [62, 50, 58, 40], c=VL, gap=20) + check(140, 140, 20)
    + ''.join(moon(186+i*24, 96, 9, '#B3A2F5', VT) for i in range(6)) + f'<rect x="174" y="118" width="144" height="6" rx="3" fill="{VL}"/>'
    + spark(290, 48, A, 0.7))
ART['day5.try'] = (AT, f'<rect x="44" y="60" width="150" height="70" rx="26" fill="{W}"/><path d="M76 126 l-8 20 24-16z" fill="{W}"/>' + dots3(119, 95, '#C9A982', 18, 6)
    + f'<path d="M206 95 H232" stroke="{V}" stroke-width="6" stroke-linecap="round"/>' + arrowhead(238, 95, 0, V)
    + f'<rect x="250" y="66" width="58" height="58" rx="12" fill="{V}"/><text x="279" y="108" text-anchor="middle" font-size="34" font-weight="800" fill="{W}" font-family="Figtree, sans-serif">?</text>'
    + spark(290, 154, G, 0.7) + spark(70, 40, V, 0.6))
ART['day5.task'] = (BT, notebook() + f'<g transform="translate(244 58) rotate(15)"><path d="M-30 -16 H18 L32 0 L18 16 H-30z" fill="{V}"/><circle cx="18" cy="0" r="4" fill="{BT}"/></g>'
    + pencil(240, 132) + spark(84, 60, A, 0.8) + spark(84, 150, G, 0.6))

def svg(name):
    bg, body = ART[name]
    return bg, f'<svg width="342" height="200" viewBox="0 0 342 200" aria-hidden="true">{body}</svg>'

# Asset catalogs don't render SVG <text>, so the few symbols in the art are drawn as strokes, font-size units.
GLYPHS = {
    '?': ('M-0.2 -0.53A0.2 0.2 0 1 1 0.1 -0.35L0.02 -0.29L0.02 -0.2', [(0.02, -0.03)]),
    '!': ('M0 -0.7L0 -0.24', [(0, -0.03)]),
    '1': ('M-0.12 -0.58L0.04 -0.7L0.04 0', []),
    '2': ('M-0.2 -0.52A0.2 0.2 0 1 1 0.14 -0.36L-0.2 0L0.22 0', []),
    '3': ('M-0.2 -0.7L0.18 -0.7L-0.02 -0.44A0.22 0.22 0 1 1 -0.21 -0.1', []),
    '5': ('M0.18 -0.7L-0.14 -0.7L-0.18 -0.4A0.24 0.22 0 1 1 -0.2 -0.08', []),
}
import re as _re
_TEXT = _re.compile(r'<text x="([\d.]+)" y="([\d.]+)"( text-anchor="middle")? font-size="(\d+)" font-weight="800" fill="([^"]+)"[^>]*>([^<]+)</text>')

def _glyphs(m):
    x, y, middle, size, color, chars = float(m[1]), float(m[2]), m[3], float(m[4]), m[5], m[6]
    adv = 0.5 * size
    width = adv * len(chars)
    left = x - width / 2 if middle else x
    out = ''
    for i, ch in enumerate(chars):
        path, dots = GLYPHS[ch]
        cx = left + adv * (i + 0.5)
        out += (f'<path d="{path}" transform="translate({cx:.1f} {y}) scale({size})" fill="none" stroke="{color}" '
                f'stroke-width="0.13" stroke-linecap="round" stroke-linejoin="round"/>')
        out += ''.join(f'<circle cx="{cx + dx*size:.1f}" cy="{y + dy*size:.1f}" r="{0.085*size:.1f}" fill="{color}"/>' for dx, dy in dots)
    return out

def outline(body):
    return _TEXT.sub(_glyphs, body)

# Day 6 · Avoidance loops
ART['day6.hook'] = (AT, f'<rect x="40" y="150" width="262" height="10" rx="5" fill="{TAN}"/>' + envelope(96, 92, 110, 58)
    + f'<circle cx="202" cy="94" r="16" fill="{R}"/>' + outline(f'<text x="202" y="102" text-anchor="middle" font-size="22" font-weight="800" fill="{W}">!</text>')
    + calendar(226, 40, 76, 72, R, [BL, BL, BL]) + ''.join(f'<path d="M{238+i*15} {72}l8 8m0 -8l-8 8" stroke="{R}" stroke-width="3" stroke-linecap="round"/>' for i in range(3))
    + spark(70, 60, V, 0.7))
ART['day6.idea1'] = (VT, ring3(beh=f'<circle cx="224.7" cy="131" r="26" fill="{V}"/><path d="M234 131 H214" stroke="{W}" stroke-width="5" stroke-linecap="round"/>' + arrowhead(213, 131, 180, W, 0.7)
    + f'<path d="M234 120 v22" stroke="{W}" stroke-width="5" stroke-linecap="round"/>', ringc=VL, arr=V) + spark(276, 48, A, 0.8))
ART['day6.idea2'] = (BT, f'<path d="M50 168 H292" stroke="{BM}" stroke-width="4" stroke-linecap="round"/>' + bars(70, 164, [34, 56, 84, 116], [G, A, A, R], w=36, gap=24)
    + arrowhead(296, 168, 0, BM) + spark(90, 110, G, 0.8) + spark(280, 46, A, 0.7))
ART['day6.idea3'] = (GT, f'<path d="M48 100 H294" stroke="{GD}" stroke-width="5" stroke-linecap="round" stroke-dasharray="2 12"/>'
    + f'<circle cx="70" cy="100" r="16" fill="{G}"/><circle cx="170" cy="100" r="16" fill="{A}"/><circle cx="262" cy="100" r="16" fill="{R}"/>'
    + clock(70, 50, 14, GD) + clock(170, 50, 14, '#B86E12') + mag(262, 100, 34) + spark(120, 156, A, 0.7))
ART['day6.example'] = (VT, f'<rect x="72" y="40" width="130" height="120" rx="14" fill="{W}"/>'
    + ''.join(f'<path d="M{x} {y} l0 22" stroke="{VM}" stroke-width="2"/><circle cx="{x}" cy="{y}" r="12" fill="{c}"/>' for x, y, c in [(110, 74, A), (137, 64, BS), (164, 76, G)])
    + lines(96, 116, [82, 60], c=VL, gap=16) + f'<circle cx="200" cy="44" r="14" fill="{R}"/>'
    + ''.join(f'<circle cx="{238+i*26}" cy="{120-i*14}" r="{6+i*4}" fill="{A}" fill-opacity="{0.5+i*0.2:.1f}"/>' for i in range(3))
    + spark(282, 46, V, 0.7))
ART['day6.try'] = (AT, clock(100, 96, 40, G) + f'<path d="M154 96 H192" stroke="{TAN}" stroke-width="6" stroke-linecap="round" stroke-dasharray="2 10"/>' + arrowhead(198, 96, 0, TAN)
    + clock(246, 96, 40, R, W, (0.5, -0.3), (0, 0.6)) + spark(170, 40, V, 0.7) + spark(170, 160, G, 0.6))
ART['day6.task'] = (BT, notebook() + f'<circle cx="244" cy="56" r="24" fill="{A}"/><rect x="235" y="44" width="6" height="24" rx="3" fill="{W}"/><rect x="247" y="44" width="6" height="24" rx="3" fill="{W}"/>'
    + pencil(240, 134) + spark(84, 60, V, 0.8) + spark(84, 150, G, 0.6))

# Day 7 · Your loop map
ART['day7.hook'] = (GT, '<path d="M60 150 C100 90 130 160 170 110 S240 60 282 80" fill="none" stroke="#7FD4A6" stroke-width="5" stroke-dasharray="2 12" stroke-linecap="round"/>'
    + ''.join(f'<circle cx="{x}" cy="{y}" r="9" fill="{c}"/>' for x, y, c in [(60, 150, A), (104, 120, V), (140, 138, BS), (170, 110, A), (214, 84, V), (250, 74, A)])
    + pin(282, 52, 1.1, GD) + spark(86, 56, V, 0.8))
ART['day7.idea1'] = (BT, ''.join(f'<circle cx="{70+(i%9)*25}" cy="{48+(i//9)*26}" r="7" fill="{[A, V, G, BS][i % 4] if i in (3, 8, 12, 17, 22, 30) else BL}"/>' for i in range(45))
    + spark(296, 160, A, 0.6))
ART['day7.idea2'] = (VT, f'<path d="M60 170 H290" stroke="{VM}" stroke-width="4" stroke-linecap="round"/>' + bars(74, 166, [40, 120, 52, 30, 64], [VL, V, VL, VL, VL], w=30, gap=16)
    + star(121, 30, 13, A) + spark(280, 50, G, 0.7))
ART['day7.idea3'] = (AT, ''.join(f'<circle cx="{x}" cy="{y}" r="8" fill="{c}"/>' for x, y, c in [(80, 60, V), (110, 130, G), (150, 90, BS), (210, 150, V), (270, 60, G)])
    + mag(176, 92, 40, '#B86E12') + heart(176, 94, 0.7, R) + spark(286, 140, V, 0.7))
ART['day7.example'] = (VT, f'<circle cx="150" cy="100" r="66" fill="{W}"/><path d="M150 100 L{150+58*math.cos(math.radians(-90+270)):.1f} {100+58*math.sin(math.radians(-90+270)):.1f} A58 58 0 0 1 {150+58*math.cos(math.radians(-90+330)):.1f} {100+58*math.sin(math.radians(-90+330)):.1f}z" fill="{V}"/>'
    + f'<circle cx="150" cy="100" r="66" fill="none" stroke="{VM}" stroke-width="6"/><circle cx="150" cy="100" r="6" fill="{INK}"/>'
    + moon(266, 64, 26, A, VT) + spark(266, 150, G, 0.8))
ART['day7.try'] = (AT, cloud(150, 92, 1.7, W) + outline(f'<text x="150" y="112" text-anchor="middle" font-size="48" font-weight="800" fill="{V}">?</text>')
    + pin(262, 92, 1.2, V) + spark(70, 50, G, 0.7) + spark(290, 160, A, 0.6))
ART['day7.task'] = (BT, phone(126, 18, 90, 166, V) + bars(146, 150, [40, 70, 100], [BL, BS, B], w=14, gap=8)
    + spark(260, 52, A, 0.8) + spark(84, 140, G, 0.7))

# Day 8 · Habits beyond worry
ART['day8.hook'] = (AT, f'<rect x="100" y="26" width="96" height="154" rx="14" fill="{W}"/><path d="M100 84 H196" stroke="{BL}" stroke-width="4"/><rect x="180" y="44" width="6" height="26" rx="3" fill="{TAN}"/><rect x="180" y="100" width="6" height="40" rx="3" fill="{TAN}"/>'
    + clock(250, 62, 26, V, W, (0.35, 0.35), (0, -0.6)) + envelope(226, 112, 56, 38) + spark(70, 60, G, 0.7))
ART['day8.idea1'] = (VT, tile(56, 62, 72, W, phone(76, 72, 32, 52, BS)) + tile(135, 62, 72, W, cookie(171, 98, 22))
    + tile(214, 62, 72, W, lines(228, 80, [44, 34, 40], c=A, gap=14, h=7)) + spark(171, 34, A, 0.7) + spark(171, 168, G, 0.6))
ART['day8.idea2'] = (BT, ring3(beh=f'<circle cx="224.7" cy="131" r="26" fill="{W}"/>' + cookie(224.7, 131, 18)) + spark(276, 48, A, 0.8))
ART['day8.idea3'] = (GT, cookie(130, 100, 44) + mag(222, 92, 40) + f'<path d="M210 92 h24 M222 80 v24" stroke="{GD}" stroke-width="0"/>'
    + spark(286, 156, A, 0.7) + spark(70, 50, V, 0.6))
ART['day8.example'] = (AT, envelope(48, 72, 100, 66) + f'<circle cx="146" cy="74" r="15" fill="{R}"/>'
    + f'<path d="M164 112 Q192 84 212 100" fill="none" stroke="{TAN}" stroke-width="6" stroke-dasharray="2 12" stroke-linecap="round"/>' + arrowhead(214, 102, 30, TAN)
    + f'<circle cx="260" cy="104" r="44" fill="{W}"/>' + cookie(260, 104, 34)
    + ''.join(f'<circle cx="{x}" cy="{y}" r="4" fill="#D9A766"/>' for x, y in [(222, 160), (238, 168), (290, 164)])
    + spark(90, 40, V, 0.8) + spark(300, 40, G, 0.6))
ART['day8.try'] = (AT, cloud(92, 96, 1.1, VM) + f'<path d="M128 116 Q170 160 214 112" fill="none" stroke="{TAN}" stroke-width="6" stroke-dasharray="2 12" stroke-linecap="round"/>' + arrowhead(218, 108, -40, TAN)
    + phone(226, 46, 64, 116, V) + spark(176, 50, A, 0.7))
ART['day8.task'] = (BT, notebook() + f'<circle cx="244" cy="56" r="26" fill="{W}"/>' + cookie(244, 56, 20) + pencil(240, 134) + spark(84, 60, A, 0.8))

# Day 9 · Catch it sooner
ART['day9.hook'] = (VT, f'<circle cx="150" cy="100" r="62" fill="{W}"/><path d="M150 100 L150 46 A54 54 0 0 1 204 100z" fill="{V}" fill-opacity="0.85"/>'
    + f'<circle cx="150" cy="100" r="62" fill="none" stroke="{V}" stroke-width="8"/><circle cx="150" cy="100" r="6" fill="{INK}"/>'
    + outline(f'<text x="262" y="118" text-anchor="middle" font-size="56" font-weight="800" fill="{V}">?</text>') + spark(70, 50, A, 0.7))
ART['day9.idea1'] = (GT, f'<path d="M40 150 C110 150 120 70 200 80 S270 120 296 60" fill="none" stroke="#7FD4A6" stroke-width="8" stroke-linecap="round"/>'
    + bolt(60, 150, A, 1.1) + flag(262, 102, 56, G) + check(286, 52, 14) + spark(130, 40, V, 0.7))
ART['day9.idea2'] = (BT, f'<path d="M40 110 H300" stroke="{BM}" stroke-width="6" stroke-linecap="round"/>'
    + f'<circle cx="76" cy="110" r="24" fill="{A}"/>' + bolt(76, 110) + f'<rect x="112" y="84" width="110" height="52" rx="14" fill="{W}" fill-opacity="0.9"/>'
    + f'<path d="M124 110 h86" stroke="{G}" stroke-width="5" stroke-dasharray="2 10" stroke-linecap="round"/>'
    + f'<circle cx="262" cy="110" r="24" fill="{V}"/>' + dots3(262, 110) + spark(167, 52, G, 0.8))
ART['day9.idea3'] = (AT, f'<rect x="96" y="30" width="86" height="150" rx="8" fill="{W}"/><rect x="104" y="40" width="70" height="132" rx="4" fill="#F7DDB5"/><circle cx="162" cy="108" r="6" fill="{TAN}"/>'
    + f'<path d="M206 76 q14 24 0 48 M224 64 q22 36 0 72 M242 52 q30 48 0 96" fill="none" stroke="{V}" stroke-width="6" stroke-linecap="round"/>' + spark(70, 50, G, 0.7))
ART['day9.example'] = (AT, f'<path d="M84 96 h80 v44 a28 28 0 0 1 -28 28 h-24 a28 28 0 0 1 -28 -28z" fill="{W}"/><path d="M164 108 a16 16 0 1 1 0 28" fill="none" stroke="{W}" stroke-width="8"/>'
    + f'<path d="M104 84 q-8 -14 0 -26 M124 84 q-8 -14 0 -26 M144 84 q-8 -14 0 -26" fill="none" stroke="{TAN}" stroke-width="4" stroke-linecap="round"/>'
    + bubble(206, 46, 92, 56, V, 'left') + outline(f'<text x="252" y="88" text-anchor="middle" font-size="34" font-weight="800" fill="{W}">?</text>') + spark(276, 150, G, 0.7))
ART['day9.try'] = (VT, f'<circle cx="86" cy="100" r="40" fill="{V}"/>' + cloud(86, 96, 0.8, W)
    + f'<circle cx="171" cy="100" r="34" fill="{W}"/>' + wave(147, 100, 48, 10, A, 5, 1)
    + f'<circle cx="256" cy="100" r="34" fill="{W}"/>' + phone(242, 76, 28, 48, BS) + spark(86, 36, A, 0.8))
ART['day9.task'] = (BT, notebook() + f'<circle cx="244" cy="56" r="24" fill="{A}"/>' + bolt(244, 56, W, 0.9) + pencil(240, 134) + spark(84, 60, V, 0.8))

# Day 10 · Stage 1 check-in
ART['day10.hook'] = (VT, ring3(ringc=VL, arr=V) + check(206, 26, 11) + check(262, 148, 11) + check(80, 148, 11))
ART['day10.idea1'] = (AT, f'<path d="M150 120 L132 176 L150 166 L168 176z M192 120 L210 176 L192 166 L174 176z" fill="{R}"/>'
    + f'<circle cx="171" cy="90" r="50" fill="{A}"/><circle cx="171" cy="90" r="38" fill="#F7DDB5"/>' + star(171, 90, 24, A) + spark(260, 50, V, 0.8) + spark(80, 140, G, 0.7))
ART['day10.idea2'] = (GT, '<path d="M150 46 A54 54 0 1 1 96 100" fill="none" stroke="#2E8A5C" stroke-width="10" stroke-linecap="round" stroke-dasharray="40 14 20 14 8 14"/>'
    + f'<circle cx="150" cy="100" r="22" fill="{V}"/>' + dots3(150, 100, gap=9) + plant(262, 168, 70) + spark(286, 46, A, 0.7))
ART['day10.idea3'] = (BT, ''.join(f'<rect x="{60+i*72}" y="{140-i*36}" width="76" height="{40+i*36}" rx="6" fill="{c}"/>' for i, c in enumerate([BL, BS, B]))
    + check(98, 120, 13) + flag(250, 70, 50, A) + spark(80, 50, V, 0.7))
ART['day10.example'] = (VT, ''.join(f'<circle cx="{86+(i%7)*28}" cy="{70+(i//7)*48}" r="11" fill="{G if i in (4, 10) else [A, V, BS][i % 3]}"/>' for i in range(14))
    + check(198, 58, 8) + check(170, 106, 8) + spark(290, 150, A, 0.7))
ART['day10.try'] = (AT, f'<circle cx="171" cy="84" r="44" fill="{A}"/><rect x="153" y="124" width="36" height="22" rx="6" fill="{TAN}"/><rect x="157" y="150" width="28" height="10" rx="5" fill="{TAN}"/>'
    + f'<path d="M171 62 v26 m-12 -10 l12 12 12 -12" fill="none" stroke="{W}" stroke-width="0"/><path d="M160 92 q11 -16 22 0" fill="none" stroke="{W}" stroke-width="5" stroke-linecap="round"/>'
    + ''.join(f'<path d="M{171+70*math.cos(math.radians(a)):.1f} {84+70*math.sin(math.radians(a)):.1f} L{171+84*math.cos(math.radians(a)):.1f} {84+84*math.sin(math.radians(a)):.1f}" stroke="{A}" stroke-width="5" stroke-linecap="round"/>' for a in (-150, -120, -90, -60, -30))
    + spark(70, 150, V, 0.7))
ART['day10.task'] = (BT, phone(126, 18, 90, 166, V) + bars(142, 150, [30, 54, 46, 84], [BL, BS, BS, B], w=11, gap=6) + spark(262, 52, A, 0.8) + spark(84, 140, G, 0.7))

# Day 11 · What did you get?
ART['day11.hook'] = (BT, f'<rect x="60" y="138" width="160" height="12" rx="6" fill="{BM}"/><rect x="86" y="118" width="110" height="22" rx="8" fill="{V}"/>'
    + f'<circle cx="244" cy="80" r="34" fill="{W}"/>' + outline(f'<text x="244" y="98" text-anchor="middle" font-size="44" font-weight="800" fill="{V}">?</text>')
    + spark(110, 60, A, 0.8) + spark(290, 150, G, 0.6))
ART['day11.idea1'] = (VT, f'<rect x="70" y="50" width="150" height="100" rx="16" fill="{W}"/>'
    + ''.join(f'<path d="M{94+i*14} 76 v50" stroke="{V}" stroke-width="6" stroke-linecap="round"/>' for i in range(4)) + f'<path d="M86 116 L160 86" stroke="{V}" stroke-width="6" stroke-linecap="round"/>'
    + f'<path d="M176 76 v50" stroke="{VM}" stroke-width="6" stroke-linecap="round"/>' + star(262, 82, 28, A) + spark(276, 150, G, 0.7))
ART['day11.idea2'] = (AT, f'<g transform="translate(130 100) rotate(-8)"><rect x="-56" y="-62" width="112" height="124" rx="10" fill="{W}"/></g>'
    + lines(88, 60, [70, 56, 76], c='#E8D9C2', gap=18) + star(130, 128, 20, '#E8D9C2')
    + calendar(214, 54, 80, 80, TAN) + spark(80, 170, V, 0.6))
ART['day11.idea3'] = (GT, eye(130, 100, 0.95, G) + refresh(240, 100, 30, GD) + star(240, 100, 14, A) + spark(80, 40, V, 0.7) + spark(296, 160, A, 0.6))
ART['day11.example'] = (VT, phone(70, 20, 92, 168, V)
    + ''.join(f'<rect x="84" y="{y}" width="64" height="30" rx="6" fill="{VL}"/><rect x="90" y="{y+6}" width="18" height="18" rx="4" fill="{c}"/>'
              + f'<rect x="112" y="{y+8}" width="30" height="5" rx="2.5" fill="{V}"/><rect x="112" y="{y+17}" width="22" height="5" rx="2.5" fill="{V}" fill-opacity="0.45"/>'
              for y, c in [(40, R), (78, A), (116, R)])
    + f'<path d="M188 160 q10 -6 20 0 q10 6 20 -12 q10 -18 20 -4 q12 14 24 -40 q8 -34 22 -52" fill="none" stroke="{A}" stroke-width="7" stroke-linecap="round" stroke-linejoin="round"/>'
    + arrowhead(294, 52, -62, R, 1.2)
    + spark(198, 54, V, 0.8) + spark(48, 160, G, 0.6))
ART['day11.try'] = (AT, heart(140, 100, 2.2, R) + wave(220, 76, 70, 10, '#B86E12', 5, 1) + wave(220, 104, 70, 10, '#B86E12', 5, 1) + wave(220, 132, 70, 10, '#B86E12', 5, 1)
    + spark(84, 50, V, 0.7))
ART['day11.task'] = (BT, notebook() + f'<circle cx="244" cy="56" r="26" fill="{W}"/><path d="M226 50 h36 M244 40 v34 M232 50 l-6 12 h12z M256 50 l-6 12 h12z" fill="{A}" stroke="{A}" stroke-width="3" stroke-linejoin="round"/>'
    + pencil(240, 134) + spark(84, 60, V, 0.8))

# Day 12 · Worry is a habit, not a fact
ART['day12.hook'] = (VT, f'<rect x="70" y="40" width="80" height="140" rx="8" fill="{W}"/><rect x="78" y="50" width="64" height="122" rx="4" fill="#D9CFF8"/><circle cx="130" cy="114" r="5" fill="{V}"/>'
    + cloud(236, 76, 1.6, '#8A73EE') + f'<path d="M240 92 l-14 22 h14 l-8 20 22 -28 h-14 l8 -14z" fill="{A}"/>' + clock(196, 150, 18, V) + spark(296, 150, G, 0.6))
ART['day12.idea1'] = (AT, f'<path d="M90 82 L190 46 V154 L90 118z" fill="{V}"/><rect x="66" y="80" width="30" height="40" rx="8" fill="#8A73EE"/>'
    + outline(f'<text x="246" y="124" text-anchor="middle" font-size="60" font-weight="800" fill="{R}">!</text>') + spark(290, 46, G, 0.7))
ART['day12.idea2'] = (BT, f'<rect x="96" y="28" width="150" height="148" rx="14" fill="{W}"/>'
    + ''.join((check(122, 54+i*30, 10) if i == 2 else f'<circle cx="122" cy="{54+i*30}" r="10" fill="{BL}"/><path d="M117 {49+i*30}l10 10m0 -10l-10 10" stroke="{W}" stroke-width="3" stroke-linecap="round"/>')
              + f'<rect x="142" y="{50+i*30}" width="{84-i*6}" height="8" rx="4" fill="{BL}"/>' for i in range(5)) + spark(286, 50, A, 0.7))
ART['day12.idea3'] = (GT, cloud(150, 86, 1.9, W) + f'<path d="M196 116 L230 140" stroke="{TAN}" stroke-width="3"/>'
    + f'<g transform="translate(250 150) rotate(20)"><path d="M-30 -16 H18 L32 0 L18 16 H-30z" fill="{G}"/><circle cx="18" cy="0" r="4" fill="{GT}"/></g>' + spark(70, 160, A, 0.7))
ART['day12.example'] = (VT, f'<rect x="96" y="26" width="120" height="152" rx="12" fill="{W}"/>' + lines(114, 50, [84, 70, 84, 60, 80, 52], c=VL, gap=18)
    + f'<path d="M110 82 h40" stroke="{R}" stroke-width="3"/><path d="M180 118 q8 -10 16 0" fill="none" stroke="{R}" stroke-width="3"/>'
    + check(238, 140, 22) + spark(276, 50, A, 0.8))
ART['day12.try'] = (AT, f'<rect x="50" y="50" width="100" height="100" rx="18" fill="{W}"/>' + cloud(100, 96, 0.85, '#8A73EE') + f'<path d="M100 108 l-8 14 h8 l-4 12 14 -18 h-8 l4 -8z" fill="{A}"/>'
    + f'<path d="M162 100 H182" stroke="{TAN}" stroke-width="6" stroke-linecap="round"/>' + arrowhead(188, 100, 0, TAN)
    + f'<rect x="196" y="50" width="100" height="100" rx="18" fill="{W}"/><circle cx="246" cy="100" r="22" fill="{A}"/>'
    + ''.join(f'<path d="M{246+30*math.cos(math.radians(a)):.1f} {100+30*math.sin(math.radians(a)):.1f}L{246+38*math.cos(math.radians(a)):.1f} {100+38*math.sin(math.radians(a)):.1f}" stroke="{A}" stroke-width="4" stroke-linecap="round"/>' for a in range(0, 360, 45)))
ART['day12.task'] = (BT, notebook() + f'<circle cx="244" cy="56" r="16" fill="{A}"/>'
    + ''.join(f'<path d="M{244+21*math.cos(math.radians(a)):.1f} {56+21*math.sin(math.radians(a)):.1f}L{244+28*math.cos(math.radians(a)):.1f} {56+28*math.sin(math.radians(a)):.1f}" stroke="{A}" stroke-width="4" stroke-linecap="round"/>' for a in range(0, 360, 45))
    + pencil(240, 134) + spark(84, 60, V, 0.8))

# Day 13 · Feel it in your body
ART['day13.hook'] = (AT, person(171, 120, 3.2, V) + f'<path d="M110 92 l-14 -10 M100 104 l-18 -4 M232 92 l14 -10 M242 104 l18 -4" stroke="{R}" stroke-width="5" stroke-linecap="round"/>'
    + spark(70, 46, G, 0.7) + spark(280, 40, BS, 0.6))
ART['day13.idea1'] = (VT, f'<path d="M110 24 H232 V176 l-12 -8 -12 8 -12 -8 -12 8 -12 -8 -12 8 -12 -8 -12 8 -12 -8 -12 8z" fill="{W}"/>'
    + ''.join(f'<circle cx="132" cy="{52+i*26}" r="7" fill="{c}"/><rect x="148" y="{48+i*26}" width="{60-i*6}" height="8" rx="4" fill="{VL}"/>' for i, c in enumerate([R, A, V, G]))
    + spark(272, 60, A, 0.8))
ART['day13.idea2'] = (BT, heart(130, 104, 2.4, R) + f'<path d="M178 100 h22 l10 -26 l14 52 l12 -38 l8 12 h34" fill="none" stroke="{B}" stroke-width="6" stroke-linecap="round" stroke-linejoin="round"/>'
    + spark(290, 50, A, 0.7))
ART['day13.idea3'] = (GT, person(171, 128, 3.2, '#7FD4A6') + f'<rect x="96" y="92" width="150" height="8" rx="4" fill="{GD}"/>'
    + arrowhead(171, 112, 90, GD) + spark(70, 50, A, 0.7) + spark(280, 160, V, 0.6))
ART['day13.example'] = (VT, ''.join(phone(60+i*14, 40+i*8, 56, 104, c) for i, c in enumerate([VL, VM, V]))
    + heart(234, 104, 2.0, R) + f'<rect x="188" y="96" width="92" height="12" rx="6" fill="{V}"/>' + spark(290, 40, A, 0.7))
ART['day13.try'] = (AT, person(171, 128, 3.2, '#F7DDB5') + ''.join(f'<circle cx="171" cy="{y}" r="7" fill="{c}"/>' for y, c in [(64, V), (88, V), (118, A), (142, R), (166, G)])
    + spark(80, 50, V, 0.7) + spark(270, 160, G, 0.6))
ART['day13.task'] = (BT, notebook() + f'<circle cx="244" cy="56" r="26" fill="{W}"/>' + person(244, 62, 0.95, BS) + pin(258, 34, 0.55, R) + pencil(240, 134) + spark(84, 60, A, 0.8))

# Day 14 · Willpower isn't the answer
ART['day14.hook'] = (BT, phone(82, 22, 80, 156, V) + refresh(122, 100, 22, BS, 6) + cloud(244, 90, 1.3, VM)
    + f'<path d="M232 100 q12 -10 24 0" fill="none" stroke="{W}" stroke-width="4" stroke-linecap="round"/>' + spark(290, 160, A, 0.6))
ART['day14.idea1'] = (AT, f'<rect x="90" y="66" width="150" height="70" rx="14" fill="{W}"/><rect x="240" y="86" width="14" height="30" rx="4" fill="{W}"/>'
    + f'<rect x="102" y="78" width="30" height="46" rx="6" fill="{R}"/>' + refresh(66, 52, 18, R, 5) + spark(286, 46, V, 0.7))
ART['day14.idea2'] = (GT, wave(56, 110, 150, 26, A, 8, 2) + mag(240, 92, 40) + spark(80, 50, V, 0.7) + spark(296, 160, A, 0.6))
ART['day14.idea3'] = (VT, eye(130, 100, 0.95) + f'<circle cx="250" cy="100" r="36" fill="{V}"/><path d="M240 82 v36 l30 -18z" fill="{W}"/>' + spark(296, 46, A, 0.7))
ART['day14.example'] = (BT, f'<rect x="50" y="48" width="200" height="44" rx="22" fill="{W}"/>' + mag(76, 68, 10, BS) + lines(98, 66, [120], c=BL)
    + heart(110, 138, 1.1, R) + f'<path d="M150 136 h14 l6 -14 l8 28 l6 -20 l4 6 h20" fill="none" stroke="{B}" stroke-width="4" stroke-linecap="round" stroke-linejoin="round"/>'
    + f'<path d="M270 60 q16 20 0 40 M282 52 q24 28 0 56" fill="none" stroke="{V}" stroke-width="5" stroke-linecap="round"/>')
ART['day14.try'] = (AT, wave(60, 120, 140, 30, A, 9, 2) + bubble(214, 40, 84, 56, V, 'left') + outline(f'<text x="256" y="82" text-anchor="middle" font-size="32" font-weight="800" fill="{W}">?</text>')
    + spark(80, 50, G, 0.7))
ART['day14.task'] = (BT, notebook() + f'<circle cx="244" cy="56" r="26" fill="{W}"/>' + wave(226, 56, 36, 8, A, 5, 1) + pencil(240, 134) + spark(84, 60, V, 0.8))

# Day 15 · Seeing clearly
ART['day15.hook'] = (BT, f'<rect x="56" y="40" width="130" height="120" rx="10" fill="{W}"/><rect x="68" y="54" width="106" height="16" rx="4" fill="{BS}"/>' + lines(68, 82, [106, 80, 96, 70], c=BL, gap=18)
    + ''.join(f'<path d="M{216+i*12} 70 v46" stroke="{V}" stroke-width="5" stroke-linecap="round"/>' for i in range(4)) + f'<path d="M210 104 L262 80" stroke="{V}" stroke-width="5" stroke-linecap="round"/>'
    + ''.join(f'<path d="M{272+i*12} 70 v46" stroke="{V}" stroke-width="5" stroke-linecap="round"/>' for i in range(2)) + spark(250, 156, A, 0.7))
ART['day15.idea1'] = (VT, ''.join(star(70+i*66, 96, 30-i*6, A) for i in range(4)) + f'<path d="M56 154 H290" stroke="{VM}" stroke-width="5" stroke-linecap="round" stroke-dasharray="2 12"/>' + spark(296, 46, G, 0.6))
ART['day15.idea2'] = (AT, f'<path d="M60 170 H290" stroke="{TAN}" stroke-width="4" stroke-linecap="round"/>' + bars(78, 166, [50, 128, 70, 40], ['#F7DDB5', A, '#F7DDB5', '#F7DDB5'], w=34, gap=22)
    + pin(151, 18, 0.8, V) + spark(286, 60, G, 0.7))
ART['day15.idea3'] = (GT, f'<rect x="40" y="166" width="262" height="10" rx="5" fill="{TAN}"/>' + plant(90, 166, 30) + plant(171, 166, 62) + plant(252, 166, 104) + spark(80, 50, A, 0.7))
ART['day15.example'] = (BT, f'<rect x="60" y="36" width="150" height="128" rx="12" fill="{W}"/>'
    + ''.join(f'<path d="M60 {68+i*24} H210" stroke="{BL}" stroke-width="3"/>' for i in range(4)) + ''.join(f'<path d="M{110+i*50} 36 V164" stroke="{BL}" stroke-width="3"/>' for i in range(2))
    + f'<circle cx="252" cy="76" r="26" fill="{A}"/><circle cx="252" cy="76" r="17" fill="none" stroke="#F7DDB5" stroke-width="4"/>'
    + f'<path d="M232 126 l20 20 20 -26" fill="none" stroke="{G}" stroke-width="7" stroke-linecap="round" stroke-linejoin="round"/>')
ART['day15.try'] = (AT, ring3(ringc='#F7DDB5', arr=A) + star(171, 100, 18, A) + spark(276, 50, V, 0.7))
ART['day15.task'] = (GT, notebook() + f'<circle cx="244" cy="56" r="28" fill="{W}"/>' + eye(244, 56, 0.4, G) + pencil(240, 134) + spark(84, 60, A, 0.8))

# Day 16 · The "just one more" trap
ART['day16.hook'] = (BT, f'<rect x="70" y="30" width="90" height="150" rx="8" fill="{W}"/><rect x="78" y="40" width="74" height="132" rx="4" fill="{BL}"/>'
    + f'<rect x="126" y="98" width="20" height="26" rx="4" fill="{A}"/><path d="M130 98 v-8 a6 6 0 0 1 12 0 v8" fill="none" stroke="{A}" stroke-width="4"/>'
    + refresh(240, 100, 34, V) + spark(290, 160, A, 0.6))
ART['day16.idea1'] = (VT, f'<rect x="92" y="54" width="92" height="92" rx="20" fill="{W}"/><path d="M114 100 l18 18 32 -36" fill="none" stroke="{G}" stroke-width="10" stroke-linecap="round" stroke-linejoin="round"/>'
    + f'<path d="M242 52 l40 14 v30 c0 26 -20 40 -40 48 c-20 -8 -40 -22 -40 -48 v-30z" fill="{V}"/>' + spark(80, 160, A, 0.7))
ART['day16.idea2'] = (AT, ''.join(f'<path d="M{60+i*76} 100 l14 14 26 -28" fill="none" stroke="{G}" stroke-opacity="{1-i*0.3:.1f}" stroke-width="10" stroke-linecap="round" stroke-linejoin="round"/>' for i in range(3))
    + clock(286, 100, 22, '#B86E12') + f'<path d="M50 150 H300" stroke="{TAN}" stroke-width="4" stroke-dasharray="2 10" stroke-linecap="round"/>')
ART['day16.idea3'] = (GT, stopwatch(120, 104, 46, GD, W, 0.15) + f'<rect x="196" y="90" width="100" height="24" rx="12" fill="{W}"/><rect x="196" y="90" width="34" height="24" rx="12" fill="{G}"/>'
    + spark(290, 50, A, 0.7))
ART['day16.example'] = (BT, envelope(60, 64, 130, 86) + refresh(244, 104, 30, BS) + stopwatch(276, 44, 16, V, W, 0.1) + spark(90, 40, A, 0.7))
ART['day16.try'] = (AT, stopwatch(171, 106, 56, '#B86E12', W, 0.08) + spark(80, 60, V, 0.8) + spark(270, 150, G, 0.7))
ART['day16.task'] = (VT, notebook() + f'<circle cx="244" cy="56" r="26" fill="{W}"/>' + refresh(244, 56, 14, V, 5) + pencil(240, 134) + spark(84, 60, A, 0.8))

# Day 17 · Self-judgment loops
ART['day17.hook'] = (VT, bubble(50, 40, 130, 50, W, 'left') + lines(70, 61, [90], c=VL)
    + f'<path d="M150 110 l14 -10 14 8 14 -12 14 10 14 -8 14 12 14 -8 8 16 v40 h-110 v-40z" fill="{R}"/>'
    + outline(f'<text x="214" y="150" text-anchor="middle" font-size="34" font-weight="800" fill="{W}">!</text>') + spark(290, 46, A, 0.7))
ART['day17.idea1'] = (BT, f'<circle cx="138" cy="100" r="48" fill="none" stroke="{BS}" stroke-width="12"/><circle cx="204" cy="100" r="48" fill="none" stroke="{R}" stroke-width="12"/>'
    + arrowhead(138, 52, 0, BS) + arrowhead(204, 148, 180, R) + spark(286, 46, A, 0.7))
ART['day17.idea2'] = (AT, person(100, 128, 1.6, V) + f'<path d="M150 80 L270 44 V140 L150 104z" fill="{R}"/>'
    + outline(f'<text x="226" y="108" text-anchor="middle" font-size="40" font-weight="800" fill="{W}">!</text>') + spark(70, 50, G, 0.6))
ART['day17.idea3'] = (GT, ring3(beh=f'<circle cx="224.7" cy="131" r="26" fill="{R}"/>' + outline(f'<text x="224.7" y="144" text-anchor="middle" font-size="30" font-weight="800" fill="{W}">!</text>'), ringc='#A8DCC0', arr=GD)
    + spark(276, 48, A, 0.8))
ART['day17.example'] = (VT, f'<path d="M110 100 h70 l16 70 h-102z" fill="{V}"/><path d="M124 100 a21 21 0 0 1 42 0" fill="none" stroke="{V}" stroke-width="10"/>'
    + moon(260, 64, 26, A, VT) + spark(80, 50, A, 0.6) + spark(270, 156, G, 0.6))
ART['day17.try'] = (AT, f'<path d="M60 60 l16 -10 16 10 16 -10 16 10 16 -10 16 10 16 -10 16 10 v60 l-16 10 -16 -10 -16 10 -16 -10 -16 10 -16 -10 -16 10 -16 -10z" fill="{W}"/>'
    + f'<path d="M190 100 h12 l6 -18 l10 36 l8 -26 l6 8 h20" fill="none" stroke="{R}" stroke-width="5" stroke-linecap="round" stroke-linejoin="round"/>'
    + person(276, 120, 1.0, V) + spark(280, 46, G, 0.6))
ART['day17.task'] = (BT, notebook() + f'<circle cx="244" cy="56" r="24" fill="{R}"/>' + outline(f'<text x="244" y="68" text-anchor="middle" font-size="28" font-weight="800" fill="{W}">!</text>')
    + pencil(240, 134) + spark(84, 60, V, 0.8))

# Day 18 · Small wins count
ART['day18.hook'] = (GT, envelope(70, 66, 120, 80) + moon(236, 66, 24, A, GT) + check(238, 136, 22) + spark(290, 40, V, 0.6))
ART['day18.idea1'] = (VT, ''.join(f'<ellipse cx="{70+i*44}" cy="{150-(i%2)*14}" rx="9" ry="13" fill="{VM}"/>' for i in range(4)) + plant(262, 168, 66) + spark(282, 50, A, 0.7))
ART['day18.idea2'] = (BT, ''.join(f'<rect x="{80-i*8}" y="{40+i*8}" width="110" height="130" rx="12" fill="{c}"/>' for i, c in enumerate([BL, '#DCE7FB', W]))
    + f'<path d="M84 140 L110 120 L134 128 L170 90" fill="none" stroke="{B}" stroke-width="6" stroke-linecap="round" stroke-linejoin="round"/>'
    + arrowhead(174, 86, -45, B) + spark(270, 60, A, 0.8) + spark(260, 150, G, 0.6))
ART['day18.idea3'] = (AT, eye(130, 100, 0.95) + ''.join(f'<path d="M{x-12} {y} h24 M{x} {y-12} v24" stroke="{c}" stroke-width="7" stroke-linecap="round"/>' for x, y, c in [(240, 70, G), (276, 110, A), (232, 142, V)]))
ART['day18.example'] = (VT, f'<circle cx="150" cy="100" r="56" fill="none" stroke="{VL}" stroke-width="16"/>'
    + f'<path d="M150 44 A56 56 0 1 1 {150+56*math.cos(math.radians(-90+300)):.1f} {100+56*math.sin(math.radians(-90+300)):.1f}" fill="none" stroke="{G}" stroke-width="16" stroke-linecap="round"/>'
    + cloud(150, 98, 0.75, V) + spark(266, 60, A, 0.8) + spark(266, 150, G, 0.6))
ART['day18.try'] = (GT, star(171, 100, 46, A) + spark(240, 60, V, 1.0) + spark(100, 140, G, 0.8) + spark(250, 150, A, 0.6))
ART['day18.task'] = (BT, phone(126, 18, 90, 166, V) + f'<circle cx="171" cy="100" r="26" fill="none" stroke="{BL}" stroke-width="9"/>'
    + f'<path d="M171 74 A26 26 0 1 1 {171+26*math.cos(math.radians(-90+290)):.1f} {100+26*math.sin(math.radians(-90+290)):.1f}" fill="none" stroke="{G}" stroke-width="9" stroke-linecap="round"/>'
    + spark(262, 52, A, 0.8) + spark(84, 140, V, 0.6))

# Day 19 · When it really helps
ART['day19.hook'] = (AT, f'<rect x="70" y="30" width="116" height="146" rx="12" fill="{W}"/>' + lines(86, 54, [84, 70, 84, 56], c='#E8D9C2', gap=20)
    + check(170, 150, 20) + calendar(214, 52, 84, 84, R, [None, None, None, None, None, R]) + spark(286, 160, V, 0.6))
ART['day19.idea1'] = (GT, f'<circle cx="70" cy="100" r="22" fill="{A}"/>' + bolt(70, 100)
    + f'<path d="M94 100 H150 M150 100 L210 56 M150 100 L210 144" fill="none" stroke="{GD}" stroke-width="7" stroke-linecap="round" stroke-linejoin="round"/>'
    + flag(236, 74, 44, G) + check(262, 40, 11) + refresh(246, 146, 20, R, 6))
ART['day19.idea2'] = (BT, f'<path d="M60 64 H220" stroke="{G}" stroke-width="9" stroke-linecap="round"/>' + check(250, 64, 22)
    + f'<path d="M60 140 H140" stroke="{A}" stroke-width="9" stroke-linecap="round"/>' + refresh(186, 140, 26, A) + spark(286, 140, V, 0.6))
ART['day19.idea3'] = (VT, f'<path d="M171 40 V160 M120 160 h102" stroke="{TAN}" stroke-width="8" stroke-linecap="round"/><path d="M90 70 H252" stroke="{V}" stroke-width="7" stroke-linecap="round"/>'
    + f'<path d="M90 70 l-22 50 h44z M252 70 l-22 50 h44z" fill="{VM}"/>' + check(90, 106, 13) + refresh(252, 108, 12, A, 5) + spark(290, 40, G, 0.6))
ART['day19.example'] = (GT, f'<rect x="60" y="40" width="110" height="120" rx="12" fill="{W}"/>' + ''.join(f'<circle cx="80" cy="{70+i*36}" r="7" fill="{G}"/><rect x="94" y="{66+i*36}" width="60" height="8" rx="4" fill="#C8E8D5"/>' for i in range(2))
    + f'<rect x="204" y="56" width="70" height="90" rx="20" fill="{V}"/><circle cx="239" cy="86" r="14" fill="{W}"/><rect x="222" y="108" width="34" height="8" rx="4" fill="{W}"/>' + check(272, 50, 14))
ART['day19.try'] = (AT, f'<rect x="60" y="40" width="80" height="120" rx="8" fill="{W}"/><circle cx="124" cy="104" r="5" fill="{TAN}"/>' + check(100, 70, 16)
    + refresh(240, 100, 38, '#B86E12') + spark(176, 40, V, 0.7))
ART['day19.task'] = (BT, f'<rect x="58" y="96" width="100" height="70" rx="12" fill="{W}"/><rect x="184" y="96" width="100" height="70" rx="12" fill="{W}"/>' + check(108, 130, 18) + refresh(234, 132, 18, A, 6)
    + f'<g transform="translate(171 52) rotate(-8)"><rect x="-36" y="-22" width="72" height="44" rx="8" fill="{V}"/>' + lines(-24, -8, [48, 34], c=W, gap=14, h=6) + '</g>')

# Day 20 · Stage 2 check-in
ART['day20.hook'] = (VT, star(171, 100, 56, VM) + spark(256, 56, VL, 0.9) + spark(88, 140, VL, 0.7))
ART['day20.idea1'] = (AT, ''.join(f'<g opacity="{1-i*0.28:.2f}"><ellipse cx="{84+i*80}" cy="132" rx="16" ry="12" fill="{V}"/><path d="M{98+i*80} 132 V64 l26 -8 v16 l-26 8" fill="none" stroke="{V}" stroke-width="6" stroke-linejoin="round"/></g>' for i in range(3)))
ART['day20.idea2'] = (GT, f'<rect x="40" y="166" width="262" height="10" rx="5" fill="{TAN}"/>' + plant(84, 166, 98) + plant(171, 166, 54) + plant(258, 166, 76) + spark(286, 40, A, 0.7))
ART['day20.idea3'] = (BT, tool_tiles(43, 72) + spark(171, 40, A, 0.8) + spark(171, 160, V, 0.6))
ART['day20.example'] = (VT, f'<rect x="50" y="48" width="200" height="44" rx="22" fill="{W}"/>' + mag(76, 68, 10, V) + lines(98, 66, [120], c=VL)
    + f'<path d="M150 116 V156" stroke="{A}" stroke-width="7" stroke-linecap="round"/>' + arrowhead(150, 160, 90, A) + star(264, 132, 20, VM) + spark(286, 50, G, 0.6))
ART['day20.try'] = (AT, star(120, 100, 44, A) + f'<path d="M184 100 H214" stroke="{TAN}" stroke-width="6" stroke-linecap="round"/>' + arrowhead(220, 100, 0, TAN) + star(258, 100, 22, '#E8D9C2'))
ART['day20.task'] = (BT, notebook() + f'<circle cx="244" cy="56" r="26" fill="{W}"/>' + star(244, 56, 16, VM) + pencil(240, 134) + spark(84, 60, A, 0.8))

# Day 21 · Curiosity beats worry
ART['day21.hook'] = (BT, f'<path d="M80 60 h40 a14 14 0 1 1 24 0 h40 v40 a14 14 0 1 0 0 24 v40 h-104z" fill="{A}"/>' + mag(236, 96, 36, B) + spark(286, 160, V, 0.7))
ART['day21.idea1'] = (AT, f'<rect x="60" y="112" width="64" height="52" rx="8" fill="#E8D9C2"/><rect x="54" y="100" width="76" height="18" rx="6" fill="#E8D9C2"/>'
    + f'<rect x="168" y="82" width="120" height="96" rx="12" fill="{V}"/><rect x="160" y="62" width="136" height="30" rx="10" fill="#8A73EE"/><rect x="218" y="62" width="20" height="116" fill="{A}"/>'
    + star(228, 132, 0, A) + spark(228, 40, A, 1.0) + spark(296, 60, G, 0.7))
ART['day21.idea2'] = (VT, f'<circle cx="104" cy="100" r="30" fill="{A}"/>' + ''.join(f'<path d="M{104+40*math.cos(math.radians(a)):.1f} {100+40*math.sin(math.radians(a)):.1f}L{104+56*math.cos(math.radians(a)):.1f} {100+56*math.sin(math.radians(a)):.1f}" stroke="{A}" stroke-width="5" stroke-linecap="round"/>' for a in range(0, 360, 45))
    + f'<path d="M206 100 c0 -48 80 -48 80 0 s-64 48 -64 0 s48 -32 48 0 s-32 22 -32 0" fill="none" stroke="{V}" stroke-width="9" stroke-linecap="round"/>')
ART['day21.idea3'] = (GT, person(130, 124, 2.8, '#7FD4A6') + f'<circle cx="130" cy="122" r="12" fill="{A}"/>' + mag(232, 92, 34) + spark(290, 160, V, 0.6))
ART['day21.example'] = (VT, f'<rect x="40" y="132" width="262" height="12" rx="6" fill="{TAN}"/>' + person(130, 112, 2.0, V)
    + f'<path d="M122 108 c0 -8 16 -8 16 0 s-12 8 -12 0" fill="none" stroke="{A}" stroke-width="4" stroke-linecap="round"/>'
    + bubble(190, 36, 110, 54, W, 'left') + dots3(245, 63, V, 16, 5) + spark(280, 160, G, 0.6))
ART['day21.try'] = (AT, bubble(56, 48, 150, 70, W, 'left') + dots3(131, 83, '#C9A982', 22, 7) + mag(246, 104, 32, '#B86E12') + spark(286, 40, V, 0.6))
ART['day21.task'] = (BT, rings(171, 100, 70) + spark(286, 50, A, 0.8) + spark(66, 150, G, 0.6))

# Day 22 · Noticing the details
ART['day22.hook'] = (BT, f'<circle cx="112" cy="80" r="30" fill="{A}"/>' + cloud(180, 108, 1.6, W) + f'<path d="M230 60 h50 M240 76 h44 M226 92 h40" stroke="{BM}" stroke-width="6" stroke-linecap="round"/>' + spark(80, 156, V, 0.6))
ART['day22.idea1'] = (VT, ''.join(f'<path d="M171 100 L{171+66*math.cos(math.radians(a)):.1f} {100+66*math.sin(math.radians(a)):.1f} A66 66 0 0 1 {171+66*math.cos(math.radians(a+60)):.1f} {100+66*math.sin(math.radians(a+60)):.1f}z" fill="{c}" transform="translate({8*math.cos(math.radians(a+30)):.1f} {8*math.sin(math.radians(a+30)):.1f})"/>'
    for a, c in zip(range(-90, 270, 60), [V, A, G, BS, R, VM])))
ART['day22.idea2'] = (AT, f'<path d="M40 100 q20 -60 40 0 t40 0 q15 -30 30 0 t30 0 q10 -12 20 0 t20 0 q6 -4 12 0 t12 0" fill="none" stroke="{A}" stroke-width="8" stroke-linecap="round"/>' + spark(290, 50, V, 0.7))
ART['day22.idea3'] = (GT, pin(171, 72, 1.8, G) + person(171, 166, 1.2, GD) + spark(80, 60, A, 0.7) + spark(270, 150, V, 0.6))
ART['day22.example'] = (BT, person(110, 124, 2.8, '#C9D9FA') + ''.join(f'<circle cx="{x}" cy="{y}" r="9" fill="{c}"/>' for x, y, c in [(110, 92, V), (110, 132, A), (74, 160, R), (146, 160, R)])
    + f'<g transform="translate(250 70) rotate(-20) scale(0.7)"><rect x="-56" y="-9" width="112" height="18" rx="9" fill="{BS}"/><path d="M-6 -6 L-26 -40 H-12 L14 -6z M-6 6 L-26 40 H-12 L14 6z M-50 -4 L-58 -22 H-48 L-38 -4z" fill="{B}"/></g>')
ART['day22.try'] = (AT, ''.join(f'<circle cx="171" cy="100" r="{r}" fill="none" stroke="{A}" stroke-opacity="{o}" stroke-width="5"/>' for r, o in [(24, 1), (44, 0.6), (64, 0.3)]) + f'<circle cx="171" cy="100" r="10" fill="{V}"/>')
ART['day22.task'] = (VT, rings(171, 100, 70) + spark(286, 150, A, 0.8))

# Day 23 · Name it to step back
ART['day23.hook'] = (VT, cloud(136, 86, 1.8, W) + f'<path d="M182 112 L214 136" stroke="{TAN}" stroke-width="3"/>'
    + f'<g transform="translate(236 148) rotate(20)"><path d="M-30 -16 H18 L32 0 L18 16 H-30z" fill="{V}"/><circle cx="18" cy="0" r="4" fill="{VT}"/>' + lines(-22, -3, [30], c=W, h=6) + '</g>')
ART['day23.idea1'] = (BT, cloud(240, 86, 1.6, VM) + person(84, 140, 1.6, BS) + f'<path d="M120 112 H186" stroke="{BM}" stroke-width="5" stroke-linecap="round" stroke-dasharray="2 10"/>'
    + arrowhead(124, 112, 180, BM) + arrowhead(184, 112, 0, BM))
ART['day23.idea2'] = (AT, chip(70, 56, 92, V) + chip(176, 56, 96, A) + chip(116, 108, 110, G) + spark(290, 160, V, 0.6))
ART['day23.idea3'] = (GT, ''.join(f'<g transform="translate({90+i*54} {130-i*22}) rotate({-6+i*4})"><path d="M-30 -16 H18 L32 0 L18 16 H-30z" fill="{c}"/><circle cx="18" cy="0" r="4" fill="{GT}"/></g>' for i, c in enumerate([G, A, V, BS])))
ART['day23.example'] = (VT, f'<rect x="60" y="138" width="150" height="34" rx="14" fill="{W}"/>' + moon(270, 52, 22, A, VT)
    + chip(70, 60, 80, V) + chip(140, 96, 86, A) + chip(176, 44, 72, G) + spark(290, 150, A, 0.6))
ART['day23.try'] = (AT, ''.join(chip(x, y, w, c) for x, y, w, c in [(60, 120, 90, V), (116, 70, 80, A), (200, 34, 86, G)])
    + ''.join(f'<circle cx="{x}" cy="{y}" r="4" fill="{TAN}"/>' for x, y in [(170, 128), (180, 118), (250, 86)]))
ART['day23.task'] = (BT, f'<circle cx="171" cy="70" r="40" fill="{W}" stroke="#F7DDB5" stroke-width="5"/>' + lines(151, 64, [40, 24], c='#E8D9C2', gap=12, h=6)
    + chip(76, 128, 76, W, BL) + chip(160, 128, 64, W, BL) + chip(232, 128, 40, W, BL) + spark(270, 46, A, 0.7))

# Day 24 · Breath as an anchor
ART['day24.hook'] = (BT, phone(70, 26, 76, 148, V) + f'<circle cx="108" cy="100" r="20" fill="{G}"/><path d="M99 92 c2 10 8 16 18 18 l4 -6 -7 -4 -3 3 c-3 -2 -5 -4 -6 -7 l3 -3 -4 -7z" fill="{W}"/>'
    + f'<path d="M160 70 q12 30 0 60 M176 58 q20 42 0 84" fill="none" stroke="{BS}" stroke-width="5" stroke-linecap="round"/>'
    + ''.join(f'<path d="M{206+i*4} {70+i*22} q20 -8 40 0 t40 0" fill="none" stroke="{BM}" stroke-width="5" stroke-linecap="round"/>' for i in range(3)))
ART['day24.idea1'] = (GT, breath(171, 100, 40) + f'<path d="M70 100 H106 M236 100 H266" stroke="{GD}" stroke-width="6" stroke-linecap="round"/>'
    + arrowhead(110, 100, 0, GD) + arrowhead(272, 100, 0, GD))
ART['day24.idea2'] = (VT, f'<path d="M171 40 V160 M140 64 H202 M110 120 Q114 162 171 162 Q228 162 232 120" fill="none" stroke="{V}" stroke-width="12" stroke-linecap="round"/>'
    + f'<circle cx="171" cy="40" r="12" fill="none" stroke="{V}" stroke-width="8"/>' + arrowhead(110, 120, -90, V) + arrowhead(232, 120, -90, V) + spark(270, 50, A, 0.7))
ART['day24.idea3'] = (AT, breath(110, 100, 34) + f'<path d="M168 100 H196" stroke="{TAN}" stroke-width="6" stroke-linecap="round"/>' + arrowhead(202, 100, 0, TAN)
    + f'<rect x="216" y="44" width="80" height="120" rx="8" fill="{W}"/><circle cx="280" cy="108" r="5" fill="{TAN}"/>')
ART['day24.example'] = (BT, f'<rect x="56" y="40" width="150" height="96" rx="10" fill="{W}"/>' + bars(78, 120, [30, 50, 70], [BL, BS, B], w=20, gap=14)
    + f'<path d="M131 136 V166 M108 166 h46" stroke="{TAN}" stroke-width="6" stroke-linecap="round"/>' + clock(262, 64, 26, V, W, (-0.5, -0.1), (0, -0.6)) + breath(262, 142, 18))
ART['day24.try'] = (GT, breath(171, 100, 34) + ''.join(f'<circle cx="{171+70*math.cos(math.radians(a)):.1f}" cy="{100+70*math.sin(math.radians(a)):.1f}" r="7" fill="{A}"/>' for a in range(-150, -30, 30))
    + ''.join(f'<circle cx="{171+70*math.cos(math.radians(a)):.1f}" cy="{100+70*math.sin(math.radians(a)):.1f}" r="7" fill="{BS}"/>' for a in range(0, 180, 30)))
ART['day24.task'] = (GT, breath(171, 100, 44) + spark(270, 50, A, 0.8) + spark(76, 150, V, 0.6))

# Day 25 · Kindness feels good
ART['day25.hook'] = (VT, bubble(50, 40, 120, 60, W, 'left') + heart(110, 72, 0.8, R)
    + f'<path d="M180 106 l14 -10 14 8 14 -12 14 10 14 -8 14 12 14 -8 v52 h-112z" fill="{VM}"/>' + spark(80, 156, A, 0.6))
ART['day25.idea1'] = (AT, ring3(beh=f'<circle cx="224.7" cy="131" r="26" fill="{R}"/>' + outline(f'<text x="224.7" y="144" text-anchor="middle" font-size="30" font-weight="800" fill="{W}">!</text>'), ringc='#F7DDB5', arr='#B86E12'))
ART['day25.idea2'] = (GT, heart(171, 100, 3.2, R) + spark(260, 50, A, 1.0) + spark(80, 70, V, 0.8) + spark(250, 156, G, 0.7))
ART['day25.idea3'] = (BT, heart(171, 100, 2.6, R) + f'<path d="M100 70 q-10 30 0 60 M84 80 q-8 20 0 40 M242 70 q10 30 0 60 M258 80 q8 20 0 40" fill="none" stroke="{BS}" stroke-width="5" stroke-linecap="round"/>'
    + f'<path d="M226 56 q8 12 0 18 q-8 -6 0 -18z" fill="{BS}"/>')
ART['day25.example'] = (VT, person(171, 128, 3.2, '#D9CFF8') + f'<circle cx="171" cy="120" r="30" fill="{R}" fill-opacity="0.25"/>' + heart(171, 122, 0.9, R) + spark(260, 50, A, 0.8))
ART['day25.try'] = (AT, person(90, 130, 1.8, V) + person(252, 130, 1.8, BS) + bubble(120, 30, 100, 56, W, 'left') + heart(170, 58, 0.7, R))
ART['day25.task'] = (VT, ''.join(f'<circle cx="171" cy="100" r="{r}" fill="{R}" fill-opacity="{o}"/>' for r, o in [(72, 0.12), (54, 0.2)]) + heart(171, 102, 1.7, R) + spark(270, 46, A, 0.7))

# Day 26 · Riding the urge
ART['day26.hook'] = (BT, phone(70, 26, 76, 148, V) + lines(84, 56, [48, 36, 44], c=BL, gap=18) + f'<circle cx="138" cy="34" r="12" fill="{R}"/>' + f'<path d="M176 150 C210 150 220 50 250 50 C276 50 280 110 300 110" fill="none" stroke="{A}" stroke-width="8" stroke-linecap="round"/>'
    + arrowhead(252, 46, -10, A) + spark(200, 60, V, 0.7))
ART['day26.idea1'] = (BT, f'<path d="M40 160 C110 160 130 40 171 40 C212 40 232 160 302 160" fill="none" stroke="{BS}" stroke-width="10" stroke-linecap="round"/>'
    + f'<circle cx="171" cy="40" r="10" fill="{A}"/>' + spark(80, 70, V, 0.7) + spark(270, 70, G, 0.6))
ART['day26.idea2'] = (GT, f'<path d="M40 150 C90 150 110 70 160 70 C200 70 210 130 250 130 S290 110 302 110" fill="none" stroke="{G}" stroke-width="10" stroke-linecap="round"/>'
    + f'<g transform="translate(160 56) rotate(-8)"><ellipse cx="0" cy="0" rx="40" ry="9" fill="{A}"/><path d="M-30 0 H30" stroke="#F7DDB5" stroke-width="2"/></g>' + spark(270, 50, V, 0.7))
ART['day26.idea3'] = (AT, wave(40, 70, 110, 24, A, 7, 1) + wave(150, 110, 90, 16, A, 6, 1) + wave(240, 140, 62, 9, A, 5, 1) + spark(286, 50, V, 0.7))
ART['day26.example'] = (VT, stopwatch(92, 104, 42, V, W, 0.4) + f'<path d="M160 160 C190 160 200 70 222 70 C244 70 256 160 300 160" fill="none" stroke="{VM}" stroke-width="8" stroke-linecap="round"/>'
    + f'<circle cx="222" cy="70" r="9" fill="{A}"/>' + spark(290, 50, G, 0.6))
ART['day26.try'] = (AT, f'<path d="M40 150 C100 150 120 60 171 60 C222 60 242 150 302 150" fill="none" stroke="{A}" stroke-width="9" stroke-linecap="round"/>' + breath(171, 140, 18) + spark(270, 50, V, 0.7))
ART['day26.task'] = (GT, breath(171, 92, 38) + wave(96, 164, 150, 8, GD, 5, 3) + spark(270, 46, A, 0.7))

# Day 27 · Your go-to tool
ART['day27.hook'] = (VT, tool_tiles(43, 92) + bubble(124, 18, 94, 56, V, 'left') + outline(f'<text x="171" y="58" text-anchor="middle" font-size="30" font-weight="800" fill="{W}">?</text>'))
ART['day27.idea1'] = (BT, tool_tiles(43, 112) + ''.join(f'<path d="M{71+i*70} 70 v28" stroke="{BM}" stroke-width="5" stroke-linecap="round"/>' for i in range(4))
    + f'<circle cx="71" cy="54" r="12" fill="{R}" fill-opacity="0.6"/><circle cx="141" cy="54" r="13" fill="{A}"/>' + bolt(141, 54, W, 0.6) + cloud(211, 56, 0.45, V)
    + f'<circle cx="281" cy="54" r="13" fill="{R}"/>' + outline(f'<text x="281" y="63" text-anchor="middle" font-size="20" font-weight="800" fill="{W}">!</text>'))
ART['day27.idea2'] = (AT, calendar(70, 40, 120, 120, V, [None, None, None, None, None, G]) + check(240, 100, 30) + spark(290, 40, V, 0.6))
ART['day27.idea3'] = (GT, f'<circle cx="171" cy="100" r="62" fill="{W}"/><circle cx="171" cy="100" r="62" fill="none" stroke="{GD}" stroke-width="8"/>'
    + f'<path d="M171 50 L186 100 L171 150 L156 100z" fill="{R}"/><path d="M171 100 L186 100 L171 150 L156 100z" fill="{GD}"/><circle cx="171" cy="100" r="6" fill="{W}"/>' + spark(270, 50, A, 0.7))
ART['day27.example'] = (VT, f'<rect x="60" y="140" width="150" height="30" rx="12" fill="{W}"/>' + moon(270, 50, 22, A, VT) + chip(70, 60, 80, '#F7DDB5', '#B86E12') + chip(150, 90, 90, '#F7DDB5', '#B86E12'))
ART['day27.try'] = (AT, f'<circle cx="80" cy="100" r="30" fill="{A}"/>' + bolt(80, 100, W, 1.2) + f'<path d="M124 100 H170" stroke="{TAN}" stroke-width="6" stroke-linecap="round"/>' + arrowhead(176, 100, 0, TAN)
    + tile(196, 64, 72, '#CDEBD9', wave(208, 100, 48, 10, GD, 6, 1)) + spark(290, 46, V, 0.6))
ART['day27.task'] = (BT, phone(126, 18, 90, 166, V) + ''.join(f'<rect x="140" y="{50+i*22}" width="{62-i*14}" height="12" rx="6" fill="{[A, V, G][i]}"/>' for i in range(3))
    + tile(148, 124, 46, '#CDEBD9', wave(156, 147, 30, 6, GD, 4, 1)) + spark(262, 52, A, 0.8))

# Day 28 · When it comes back
ART['day28.hook'] = (VT, f'<circle cx="96" cy="70" r="26" fill="{A}"/>' + cloud(206, 80, 1.5, '#8A73EE') + f'<path d="M190 112 l-8 20 M210 112 l-8 20 M230 112 l-8 20" stroke="{BS}" stroke-width="4" stroke-linecap="round"/>'
    + f'<path d="M40 166 C120 166 150 130 300 140" fill="none" stroke="{VM}" stroke-width="6" stroke-linecap="round"/>')
ART['day28.idea1'] = (AT, f'<path d="M171 176 C171 120 120 90 70 40" fill="none" stroke="#E8D9C2" stroke-width="26" stroke-linecap="round"/>'
    + f'<path d="M171 176 C171 120 222 90 272 40" fill="none" stroke="{G}" stroke-width="16" stroke-linecap="round" stroke-dasharray="1 0"/>' + flag(272, 52, 36, G) + spark(70, 140, V, 0.6))
ART['day28.idea2'] = (GT, f'<path d="M40 150 L100 112 L150 76 L180 106 L230 66 L300 36" fill="none" stroke="{GD}" stroke-width="8" stroke-linecap="round" stroke-linejoin="round"/>'
    + f'<circle cx="180" cy="106" r="9" fill="{A}"/>' + f'<path d="M40 170 H300" stroke="#A8DCC0" stroke-width="4" stroke-linecap="round"/>' + arrowhead(304, 34, -24, GD))
ART['day28.idea3'] = (BT, f'<path d="M110 100 a62 62 0 0 1 124 0z" fill="{V}"/><path d="M172 100 V156 a14 14 0 0 1 -28 0" fill="none" stroke="{TAN}" stroke-width="7" stroke-linecap="round"/>'
    + f'<circle cx="274" cy="54" r="22" fill="{A}"/>' + spark(80, 50, G, 0.7))
ART['day28.example'] = (VT, cloud(110, 84, 1.4, '#8A73EE') + f'<path d="M110 100 l-10 18 h10 l-6 14 16 -20 h-10 l6 -12z" fill="{A}"/>'
    + f'<rect x="196" y="56" width="104" height="80" rx="14" fill="{W}"/>' + heart(248, 84, 0.6, R) + lines(216, 108, [64], c=VL) + spark(286, 160, G, 0.6))
ART['day28.try'] = (AT, tile(48, 64, 72, W, f'<rect x="60" y="100" width="48" height="16" rx="6" fill="{VM}"/><rect x="60" y="88" width="20" height="14" rx="5" fill="{V}"/>' + moon(98, 82, 8, A, W))
    + tile(135, 64, 72, W, lines(147, 80, [48, 40, 48, 30], c=BL, gap=11, h=6)) + tile(222, 64, 72, W, bolt(258, 100, A, 1.4)))
ART['day28.task'] = (VT, f'<rect x="96" y="40" width="150" height="120" rx="14" fill="{W}"/>' + heart(171, 86, 1.1, R) + lines(126, 122, [90], c=VL)
    + f'<path d="M216 40 v40 l10 -8 10 8 v-40z" fill="{V}"/>' + spark(280, 160, A, 0.7))

# Day 29 · Look how far you've come
ART['day29.hook'] = (GT, f'<path d="M50 166 C120 166 170 110 290 60" fill="none" stroke="#7FD4A6" stroke-width="7" stroke-linecap="round" stroke-dasharray="2 12"/>'
    + flag(56, 166, 40, A) + person(210, 116, 1.1, GD) + flag(290, 70, 40, G) + spark(130, 50, V, 0.7))
ART['day29.idea1'] = (VT, f'<path d="M171 46 V160 M126 160 h90" stroke="{TAN}" stroke-width="8" stroke-linecap="round"/><path d="M100 90 L242 60" stroke="{V}" stroke-width="7" stroke-linecap="round"/>'
    + cloud(100, 106, 0.8, '#8A73EE') + f'<rect x="222" y="74" width="40" height="30" rx="6" fill="{W}"/>' + lines(229, 82, [26, 18], c=VL, gap=10, h=5))
ART['day29.idea2'] = (BT, f'<rect x="54" y="44" width="110" height="110" rx="14" fill="{W}"/><rect x="178" y="44" width="110" height="110" rx="14" fill="{W}"/>'
    + bars(70, 138, [30, 60, 40], [BL, BS, BL], w=20, gap=12) + bars(194, 138, [40, 64, 80], [BL, BS, G], w=20, gap=12))
ART['day29.idea3'] = (AT, f'<path d="M40 150 L80 118 L106 134 L150 92 L176 116 L220 70 L246 86 L300 40" fill="none" stroke="{A}" stroke-width="8" stroke-linecap="round" stroke-linejoin="round"/>' + arrowhead(304, 37, -40, A) + spark(80, 50, V, 0.6))
ART['day29.example'] = (VT, f'<rect x="54" y="36" width="110" height="128" rx="14" fill="{W}"/><rect x="178" y="36" width="110" height="128" rx="14" fill="{W}"/>'
    + ''.join(f'<circle cx="{78+(i%3)*30}" cy="{66+(i//3)*30}" r="9" fill="{[A, R, A, R, A, A, R, A, A][i]}"/>' for i in range(9))
    + ''.join(f'<circle cx="{202+(i%3)*30}" cy="{66+(i//3)*30}" r="9" fill="{[G, G, BS, G, G, A, G, G, BS][i]}"/>' for i in range(9)))
ART['day29.try'] = (AT, star(171, 96, 50, A) + f'<path d="M150 98 l14 14 26 -30" fill="none" stroke="{W}" stroke-width="7" stroke-linecap="round" stroke-linejoin="round"/>' + spark(270, 50, V, 0.7))
ART['day29.task'] = (BT, phone(126, 18, 90, 166, V) + bars(140, 150, [70, 40, 54, 92], [A, BL, BL, G], w=11, gap=6) + spark(262, 52, A, 0.8))

# Day 30 · Keep going
ART['day30.hook'] = (GT, ''.join(f'<circle cx="{66+(i%10)*20}" cy="{60+(i//10)*26}" r="7" fill="{G}"/>' for i in range(30)) + flag(282, 140, 80, A))
ART['day30.idea1'] = (VT, ring3(cx=100, cy=100, r=52, ringc=VL, arr=V).replace('r="26"', 'r="20"')
    + ''.join(tool_tile(i, 192 + (i % 2) * 58, 44 + (i // 2) * 58, 50) for i in range(4))
    + spark(290, 160, A, 0.6))
ART['day30.idea2'] = (AT, ''.join(f'<rect x="{60+i*32}" y="96" width="22" height="22" rx="7" fill="{G if i in (0, 1, 3, 4, 6) else "#F7DDB5"}"/>' for i in range(7)) + spark(171, 60, V, 0.8) + spark(171, 150, A, 0.6))
ART['day30.idea3'] = (BT, f'<path d="M86 48 h80 v116 h-80z" fill="{V}"/><path d="M166 48 h80 v116 h-80z" fill="#8A73EE"/><path d="M166 48 V164" stroke="{BT}" stroke-width="4"/>'
    + f'<path d="M210 48 v46 l10 -8 10 8 v-46z" fill="{A}"/>' + spark(280, 50, G, 0.7))
ART['day30.example'] = (GT, notebook(70, 28) + breath(236, 80, 24) + moon(250, 156, 16, A, GT))
ART['day30.try'] = (AT, f'<rect x="106" y="70" width="130" height="96" rx="14" fill="{V}"/><path d="M98 70 h146 v-14 a8 8 0 0 0 -8 -8 h-130 a8 8 0 0 0 -8 8z" fill="#8A73EE"/>'
    + heart(171, 112, 1.0, A) + spark(270, 46, G, 0.7))
ART['day30.task'] = (BT, bell(140, 96, 1.6, A) + gear(242, 120, 26, V, BT) + spark(260, 46, G, 0.7))
