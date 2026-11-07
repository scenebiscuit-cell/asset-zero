"""Writes XF-0 airframe shapes: weight-class bases (data/shapes/) and refit overlays
(data/shapes/overlays/), then points the weapon and refit .tres files at their overlays.

This is the source of truth for data/shapes: edit the point lists here and rerun, never the .tres
files by hand. Idempotent. Run from anywhere:

    cd C:/Projects/asset-zero
    python tools/gen_shapes.py

Then check every class x refit x form still draws (tools/check_shapes.gd):

    Godot --headless --script tools/check_shapes.gd --path .
"""
import os, re
root = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), '..')) + '/'
os.chdir(root)
NL = '\r\n'

def fmt(v):
    v = round(v, 3)
    return ('%d' % v) if v == int(v) else ('%g' % v)

def pva(points):
    return 'PackedVector2Array(%s)' % ', '.join('%s, %s' % (fmt(x), fmt(y)) for x, y in points)

def mirror(points):
    return [(-x, y) for x, y in reversed(points)]

def scale(points, s):
    return [(x * s, y * s) for x, y in points]

def shift(points, dx, dy):
    return [(x + dx, y + dy) for x, y in points]

def write(path, text):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    open(path, 'w', encoding='utf-8', newline='').write(text.strip('\n').replace('\n', NL) + NL)

def shape_tres(parts, extra=''):
    body = ',\n'.join('"%s": %s' % (k, pva(v)) for k, v in parts.items())
    text = '[gd_resource type="Resource" script_class="AirframeShape" format=3]\n\n'
    text += '[ext_resource type="Script" path="res://resources/airframe_shape.gd" id="1_shape"]\n\n'
    text += '[resource]\nscript = ExtResource("1_shape")\n'
    text += 'parts = Dictionary[String, PackedVector2Array]({\n%s\n})\n' % body
    return text + extra

def pair(right):
    """Right-side part -> (left, right) mirrored pair."""
    return mirror(right), right

# ---------------- Light base (as before) ----------------
G = {
    'Barrel': [(-1.5, -35), (1.5, -35), (1.5, -20), (-1.5, -20)],
    'Hull': [(0, -30), (5, -16), (7, -4), (22, 6), (24, 12), (8, 10), (9, 20), (4, 22), (0, 18), (-4, 22), (-9, 20), (-8, 10), (-24, 12), (-22, 6), (-7, -4), (-5, -16)],
    'Highlight': [(0, -26), (2.5, -14), (2, 6), (0, 12), (-2, 6), (-2.5, -14)],
    'Sensor': [(0, -21), (1.5, -15), (0, -11), (-1.5, -15)],
    'WingLightL': [(-24, 12), (-22, 6), (-20, 7), (-21, 11.7)],
    'WingLightR': [(24, 12), (22, 6), (20, 7), (21, 11.7)],
    'EngineGlow': [(-5.5, 16), (5.5, 16), (5, 27), (3, 27), (2.5, 17), (-2.5, 17), (-3, 27), (-5, 27)],
}
L = {
    'Barrel': [(0, -47), (0.9, -40), (0.9, -30), (-0.9, -30), (-0.9, -40)],
    'Hull': [(0, -40), (3, -22), (4.5, -6), (12, 14), (13, 21), (7, 17), (7, 25), (3, 27), (0, 23), (-3, 27), (-7, 25), (-7, 17), (-13, 21), (-12, 14), (-4.5, -6), (-3, -22)],
    'Highlight': [(0, -36), (2, -18), (1.5, 8), (0, 15), (-1.5, 8), (-2, -18)],
    'Sensor': [(0, -30), (1.5, -24), (0, -20), (-1.5, -24)],
    'WingLightL': [(-13, 21), (-12, 14), (-10, 15), (-11, 20.5)],
    'WingLightR': [(13, 21), (12, 14), (10, 15), (11, 20.5)],
    'EngineGlow': [(-2.6, 22), (2.6, 22), (1.2, 34), (0, 37), (-1.2, 34)],
}
G_OFFSETS = {'muzzle': (0, -35), 'pylon': (14, 6), 'mount': (0, 10)}
L_OFFSETS = {'muzzle': (0, -46), 'pylon': (8, 13), 'mount': (0, 8)}
G_HITBOX = 'hitbox_radius = 12.0\nhitbox_height = 36.0\nhitbox_offset = Vector2(0, 0)\ngraze_radius = 28.0\n'
# The Thresher is the same metal reshaped, so it keeps most of the Gunship's area (DESIGN.md §5.3): the
# wings' mass goes into a longer, thicker needle. Everything in Thresher space (hull, detail, overlays,
# hardpoints) is scaled by this together, so Razor Wing blades still sit on the edge.
LX, LY = 1.28, 1.08
def lscale(points):
    return [(x * LX, y * LY) for x, y in points]
L_HITBOX = 'hitbox_radius = 7.0\nhitbox_height = 44.0\nhitbox_offset = Vector2(0, -4)\ngraze_radius = 36.0\n'

# ---------------- Weight classes ----------------
CLASSES = ['light', 'medium', 'heavy', 'assault']
SCALES = [1.0, 1.1, 1.22, 1.36]
def sym(right):
    """Right half, nose (x=0) to tail (x=0) -> whole outline."""
    return right + [(-x, y) for x, y in reversed(right[1:-1])]
# Own silhouette per class, at Light size, in one stealth language: faceted nose, straight edges, and
# wing leading and trailing edges at matching angles. Every class shares one leading-edge line
# (Gunship through (7,-4), slope 0.667; Thresher through (4.5,-6), slope 2.667) so Razor Wing blades fit.
HULLS_G = [
    # Light: slim diamond wing, small sawtooth tail.
    sym([(0, -30), (3, -24), (5, -15), (7, -4), (24, 7.3), (24, 10.5), (10, 18), (12, 23), (7, 24), (4, 21), (0, 18)]),
    # Medium: canards parallel to the wing, cropped tips, tailplanes.
    sym([(0, -30), (3.5, -22), (5, -15), (11, -11), (11, -8.5), (6, -10), (7, -4), (25, 8), (25, 11.5), (10, 19), (15, 23), (15, 26), (9, 24), (4, 22), (0, 18)]),
    # Heavy: thick blended body, broad trapezoid wings, twin tail booms.
    sym([(0, -30), (4, -23), (8, -12), (10, -2), (28, 10), (28, 14), (16, 20), (16, 27), (12, 29), (8, 22), (4, 22), (0, 18)]),
    # Assault: faceted shoulders at the nose, huge double delta, long twin tails.
    sym([(0, -30), (3.5, -23), (10, -18), (12, -12), (9, -8), (10, -2), (22, 6), (31, 12), (34, 18), (27, 17), (24, 21), (15, 18), (18, 28), (12, 30), (8, 23), (4, 22), (0, 18)]),
]
HULLS_L = [
    sym([(0, -40), (2.5, -28), (3.5, -18), (4.5, -6), (13, 16.7), (13, 20), (6, 25), (7, 29), (4, 29), (3, 27), (0, 23)]),
    sym([(0, -40), (2.5, -29), (3.3, -23), (6.5, -18), (6.5, -16), (3.7, -16), (4.5, -6), (14, 19.3), (14, 22), (6.5, 25), (9.5, 29), (9.5, 31), (5.5, 29), (3, 27), (0, 23)]),
    sym([(0, -40), (3, -30), (5, -14), (6, -2), (16, 24.7), (16, 27.5), (10, 27), (10, 33), (7, 34), (5.5, 28), (3, 27), (0, 23)]),
    sym([(0, -40), (3, -31), (7, -27), (8, -20), (5.5, -16), (6, -2), (13, 16.7), (18, 24), (19.5, 30), (14, 28), (12, 30), (9, 28), (11, 36), (7, 37), (5.5, 28), (3, 27), (0, 23)]),
]
TIPS_G = [[(24, 10.5), (24, 7.3), (22.2, 6.1), (22.2, 11.5)], [(25, 11.5), (25, 8), (23.2, 6.8), (23.2, 12.4)], [(28, 14), (28, 10), (25.8, 8.5), (25.8, 15.1)], [(34, 18), (31, 12), (28.8, 10.5), (31.5, 17.6)]]
TIPS_L = [[(13, 20), (13, 16.7), (11.6, 13), (11.6, 21)], [(14, 22), (14, 19.3), (12.7, 15.8), (12.7, 22.5)], [(16, 27.5), (16, 24.7), (14.4, 20.4), (14.4, 27.4)], [(19.5, 30), (18, 24), (16.2, 21.6), (17.3, 29.2)]]
# Surface detail per class, at Light size.
def outline_of(poly, d=1.0):
    """The outline pushed outward by d, for the dark edge under the hull. Spikes are capped."""
    n = len(poly)
    area = sum(poly[i][0] * poly[(i + 1) % n][1] - poly[(i + 1) % n][0] * poly[i][1] for i in range(n))
    sign = 1.0 if area > 0 else -1.0
    out = []
    for i in range(n):
        ax, ay = poly[i - 1]; bx, by = poly[i]; cx, cy = poly[(i + 1) % n]
        def normal(x, y):
            length = (x * x + y * y) ** 0.5
            return (sign * y / length, -sign * x / length)
        n1 = normal(bx - ax, by - ay); n2 = normal(cx - bx, cy - by)
        mx, my = n1[0] + n2[0], n1[1] + n2[1]
        length = (mx * mx + my * my) ** 0.5 or 1.0
        mx, my = mx / length, my / length
        k = min(d / max(mx * n1[0] + my * n1[1], 0.01), d * 1.8)
        out.append((bx + mx * k, by + my * k))
    return out
def right_half(hull):
    # sym() lists the right side first, from nose to tail.
    tail = next(i for i, pt in enumerate(hull) if i > 0 and pt[0] == 0)
    return hull[:tail + 1]
DETAIL_G = [{
    'Sensor': [(0, -23), (1.8, -18), (1.5, -13), (0, -10), (-1.5, -13), (-1.8, -18)],
    'WingPanel': [(11.5, 0.5), (20, 6.2), (20.5, 9.5), (11.5, 14.5)],
    'Intake': [(2.8, -10), (4.8, -9), (6, -2), (3.4, -4)],
    'Edge': [(7.4, -3.2), (23.2, 7.3), (22.8, 8.3), (7.4, -2)],
    'Stripe': [(13, 3), (16, 5), (16, 6.2), (13, 4.2)],
}, {
    'Sensor': [(0, -24), (2.2, -18), (1.8, -12), (0, -9), (-1.8, -12), (-2.2, -18)],
    'WingPanel': [(11.5, 0.5), (21, 7), (21.5, 10.5), (11.5, 16)],
    'Intake': [(3.2, -11), (5.6, -9), (6.2, -1), (3.6, -3)],
    'Edge': [(7.4, -3.2), (24.2, 8), (23.8, 9), (7.4, -2)],
    'Stripe': [(13, 3), (16, 5), (16, 6.2), (13, 4.2)],
}, {
    'Sensor': [(0, -25), (2.6, -19), (2.2, -12), (0, -9), (-2.2, -12), (-2.6, -19)],
    'WingPanel': [(14, 2), (25, 9.5), (25, 13.5), (16.5, 17.5), (14, 16)],
    'Intake': [(4, -13), (7, -11), (8.6, -1), (4.4, -3)],
    'Edge': [(10.4, -1.1), (27.8, 10.5), (27.4, 11.5), (10.4, 0)],
    'Stripe': [(17, 5), (21, 7.7), (21, 9), (17, 6.3)],
}, {
    'Sensor': [(0, -26), (2.8, -20), (2.4, -13), (0, -10), (-2.4, -13), (-2.8, -20)],
    'WingPanel': [(14.5, 1.5), (28, 10.5), (31, 15.5), (27, 15.5), (23.5, 19), (16.5, 16)],
    'Intake': [(4.5, -17), (9.5, -15.5), (10.5, -11.5), (8, -8.5), (8.6, -2), (4.5, -4)],
    'Edge': [(10.4, -1.4), (22, 6.5), (31, 12.6), (30.6, 13.6), (22, 7.6), (10.4, -0.2)],
    'Stripe': [(18, 5), (22, 7.7), (22, 9), (18, 6.3)],
}]
DETAIL_L = [{
    'Sensor': [(0, -32), (1.4, -27), (1.2, -22), (0, -20), (-1.2, -22), (-1.4, -27)],
    'WingPanel': [(6.2, 3), (10.8, 15), (11, 19.5), (6.5, 22.5)],
    'Intake': [(1.7, -12), (3, -11), (3.9, -3), (2, -5)],
    'Edge': [(4.9, -5), (12.8, 16.2), (12.2, 16.5), (4.6, -3.8)],
    'Stripe': [(7.5, 5), (9, 9), (9, 10.3), (7.5, 6.3)],
}, {
    'Sensor': [(0, -33), (1.7, -27), (1.4, -22), (0, -19), (-1.4, -22), (-1.7, -27)],
    'WingPanel': [(6.2, 3), (11.5, 16.5), (11.8, 20.5), (6.5, 22.5)],
    'Intake': [(1.9, -13), (3.4, -12), (4.1, -3), (2.2, -5)],
    'Edge': [(4.9, -5), (13.8, 18.6), (13.2, 18.9), (4.6, -3.8)],
    'Stripe': [(8, 6), (9.5, 10), (9.5, 11.3), (8, 7.3)],
}, {
    'Sensor': [(0, -34), (2, -28), (1.7, -22), (0, -19), (-1.7, -22), (-2, -28)],
    'WingPanel': [(7.8, 6), (14, 22.5), (14, 26), (8.5, 26)],
    'Intake': [(2.2, -16), (4.2, -14), (5.4, -2), (2.6, -4)],
    'Edge': [(6.2, -1.6), (15.8, 24.2), (15.2, 24.5), (5.7, -0.9)],
    'Stripe': [(9.5, 8), (11, 12), (11, 13.3), (9.5, 9.3)],
}, {
    'Sensor': [(0, -35), (2.1, -29.5), (1.8, -24), (0, -21), (-1.8, -24), (-2.1, -29.5)],
    'WingPanel': [(7.8, 6), (12.5, 18), (17.5, 25), (18.3, 28.5), (14, 26.8), (12, 28.5), (8.5, 27)],
    'Intake': [(3.2, -27), (6.4, -25.5), (7.1, -20.5), (4.9, -17), (5.2, -2), (2.9, -4)],
    'Edge': [(6.4, -1.9), (13.3, 16.4), (18.3, 23.8), (17.8, 24.4), (12.8, 17), (6.1, -0.7)],
    'Stripe': [(8.6, 7), (10, 11), (10, 12.3), (8.6, 8.3)],
}]
def curve(*segments, per=3):
    """Smooth Catmull-Rom curve through each segment's points; segments join at sharp corners."""
    out = []
    for seg in segments:
        pts = [seg[0]] + list(seg) + [seg[-1]]
        for i in range(1, len(pts) - 2):
            p0, p1, p2, p3 = pts[i - 1], pts[i], pts[i + 1], pts[i + 2]
            for k in range(per):
                t = k / per
                out.append(tuple(0.5 * (2 * p1[a] + (p2[a] - p0[a]) * t + (2 * p0[a] - 5 * p1[a] + 4 * p2[a] - p3[a]) * t * t + (3 * p1[a] - p0[a] - 3 * p2[a] + p3[a]) * t * t * t) for a in (0, 1)))
    out.append(segments[-1][-1])
    return out
# Thresher form (DESIGN.md §5.3): the metal unlocked and hunting. A dark ribbed crescent with a forked
# tail, hooked tines along the trailing edges, ember cores glowing between the ribs and a dark eye.
# All classes share one leading-edge curve so Razor Wing blades fit; bigger classes run it further back.
LEAD = [(4.6, -2), (7.5, 7), (11, 16), (13, 22)]
# trail: which hull segment is the trailing edge the tines hang from, and the part of it they cover.
THRESHER = [
    {'tip': (13, 22), 'lead': LEAD, 'trail': 1, 'range': (0.0, 0.62), 'claws': 3, 'claw_len': 5.5,
     'ribs': (-21, 5.0, 7), 'slits': 3, 'hull': [
        [(0, -40), (1.6, -30), (2.6, -18), (3, -10), (4.6, -2), (7.5, 7), (11, 16), (13, 22)],
        [(13, 22), (10, 19.5), (7, 20), (5.5, 24)],
        [(5.5, 24), (5, 31)],
        [(5, 31), (3, 27), (0, 24)]]},
    # Medium: small swept fins near the nose, four tines.
    {'tip': (14.5, 25), 'lead': LEAD + [(14.5, 25)], 'trail': 4, 'range': (0.0, 0.66), 'claws': 4, 'claw_len': 6.0,
     'ribs': (-21, 5.2, 7), 'slits': 3, 'hull': [
        [(0, -40), (1.6, -30), (2.6, -20)],
        [(2.6, -20), (5.5, -16), (8, -9)],
        [(8, -9), (5, -11), (3.1, -9.5)],
        [(3.1, -9.5), (4.6, -2), (7.5, 7), (11, 16), (13, 22), (14.5, 25)],
        [(14.5, 25), (11, 21.5), (7.5, 21.5), (5.6, 25)],
        [(5.6, 25), (5.2, 33)],
        [(5.2, 33), (3, 29), (0, 25)]]},
    # Heavy: thicker core, long crescents, five tines, a second pair of prongs at the tail.
    {'tip': (17, 31), 'lead': LEAD + [(15, 27), (17, 31)], 'trail': 1, 'range': (0.0, 0.46), 'claws': 5, 'claw_len': 7.0,
     'ribs': (-22, 5.4, 8), 'slits': 4, 'hull': [
        [(0, -40), (2.2, -30), (3.8, -18), (4.4, -9), (4.6, -2), (7.5, 7), (11, 16), (13, 22), (15, 27), (17, 31)],
        [(17, 31), (12.5, 25.5), (9, 24.5), (8.5, 28), (7.5, 33)],
        [(7.5, 33), (6, 28), (4.6, 27)],
        [(4.6, 27), (3, 31), (0, 28)]]},
    # Assault: forward mandibles at the nose, huge crescents, six tines, long tail prongs.
    {'tip': (20, 34), 'lead': LEAD + [(16, 28), (20, 34)], 'trail': 3, 'range': (0.0, 0.41), 'claws': 6, 'claw_len': 8.0,
     'ribs': (-22, 5.6, 8), 'slits': 4, 'hull': [
        [(0, -40), (2, -31), (2.6, -26)],
        [(2.6, -26), (4.6, -28), (6.5, -32)],
        [(6.5, -32), (7, -24), (5.4, -14), (4.6, -2), (7.5, 7), (11, 16), (13, 22), (16, 28), (20, 34)],
        [(20, 34), (14.5, 27.5), (10.5, 26), (10.5, 32), (9.5, 38)],
        [(9.5, 38), (7.5, 31), (5, 29)],
        [(5, 29), (3.2, 34), (0, 30)]]},
]
# Dark iron, with the ribs and tines in mid grey and ember orange for everything that glows (DESIGN.md §11).
THRESHER_COLORS = {'Hull': '0.22, 0.24, 0.28, 1', 'HullShade': '0.16, 0.18, 0.21, 1', 'Outline': '0.03, 0.03, 0.04, 1',
    'Highlight': '0.07, 0.09, 0.13, 1', 'Sensor': '1, 0.58, 0.14, 1', 'WingPanelL': '1, 0.45, 0.1, 1', 'WingPanelR': '1, 0.45, 0.1, 1',
    'EdgeL': '0.44, 0.47, 0.52, 1', 'EdgeR': '0.44, 0.47, 0.52, 1', 'Spine': '0.46, 0.49, 0.54, 1',
    'WingLightL': '1, 0.62, 0.2, 1', 'WingLightR': '1, 0.62, 0.2, 1', 'EngineGlow': '1, 0.5, 0.14, 0.85', 'Barrel': '0.3, 0.32, 0.36, 1'}
def polyline_at(pts, f):
    """Point at fraction f of a polyline's length, plus the direction there."""
    lens = [((b[0] - a[0]) ** 2 + (b[1] - a[1]) ** 2) ** 0.5 for a, b in zip(pts, pts[1:])]
    target = f * sum(lens)
    for i, l in enumerate(lens):
        if target <= l or i == len(lens) - 1:
            t = min(max(target / l if l else 0.0, 0.0), 1.0)
            a, b = pts[i], pts[i + 1]
            return (a[0] + (b[0] - a[0]) * t, a[1] + (b[1] - a[1]) * t), ((b[0] - a[0]) / (l or 1), (b[1] - a[1]) / (l or 1))
        target -= l
def claws(edge, count, length, lo, hi, lean=0.35):
    """A comb of tines hanging back off a trailing edge (edge runs wingtip -> body). All tines are
    parallel (back and a little outward), so neighbours never cross however the edge bends, and each
    is a plain triangle, so the live ripple can't twist one."""
    bases = [polyline_at(edge, lo + (hi - lo) * k / count)[0] for k in range(count + 1)]
    norm = (lean * lean + 1.0) ** 0.5
    dx, dy = lean / norm, 1.0 / norm
    out, inner = [], []
    for i in range(count):
        a, b = bases[i], bases[i + 1]
        mid = ((a[0] + b[0]) / 2, (a[1] + b[1]) / 2)
        out += [a, (mid[0] + dx * length, mid[1] + dy * length)]
        inner.append((a[0] - dx * 1.4, a[1] - dy * 1.4))
    last = bases[-1]
    out.append(last)
    inner.append((last[0] - dx * 1.4, last[1] - dy * 1.4))
    return out + list(reversed(inner))
def ribs(y0, h, count, narrow=0.9, wide=3.0):
    """Stacked chevron plates down the spine, one polygon."""
    right = [(0, y0 - 1.5)]
    for k in range(count):
        right += [(narrow, y0 + k * h), (wide, y0 + k * h + h * 0.55)]
    right += [(narrow, y0 + count * h), (0, y0 + count * h + 1.5)]
    return sym(right)
def chain(centres, d, L, W, neck=0.45):
    """Diamonds joined by thin necks along direction d: glow slits as one polygon."""
    dx, dy = d
    nx, ny = -dy, dx
    fwd, back = [], []
    for cx, cy in centres:
        fwd += [(cx - dx * L + nx * neck, cy - dy * L + ny * neck), (cx + nx * W, cy + ny * W), (cx + dx * L + nx * neck, cy + dy * L + ny * neck)]
        back += [(cx - dx * L - nx * neck, cy - dy * L - ny * neck), (cx - nx * W, cy - ny * W), (cx + dx * L - nx * neck, cy + dy * L - ny * neck)]
    return fwd + list(reversed(back))
def ellipse(cx, cy, rx, ry, n=10):
    return [(cx + rx * math.cos(2 * math.pi * k / n), cy + ry * math.sin(2 * math.pi * k / n)) for k in range(n)]
import math
def thresher_shape(i):
    spec = THRESHER[i]; s = SCALES[i]
    hull = sym(curve(*spec['hull']))
    tx, ty = spec['tip']
    lo, hi = spec['range']
    claw = claws(curve(spec['hull'][spec['trail']]), spec['claws'], spec['claw_len'], lo, hi)
    y0, h, count = spec['ribs']
    rib = ribs(y0, h, count)
    cores = chain([(0, y0 + k * h) for k in range(1, count)], (0, 1), 1.5, 2.6)
    lead = spec['lead']
    slit_centres, slit_dir = [], (0.33, 0.94)
    for k in range(spec['slits']):
        (px, py), (dx, dy) = polyline_at(lead, 0.3 + 0.55 * k / max(spec['slits'] - 1, 1))
        slit_centres.append((px - dy * 2.6, py + dx * 2.6))
        slit_dir = (dx, dy)
    slits = chain(slit_centres, slit_dir, 1.7, 0.75)
    eye = ellipse(0, -25, 2.0, 3.6)
    tip = [(tx, ty), (tx - 1.5, ty - 4.2), (tx - 2.6, ty - 2)]
    flip = lambda pts: [(-x, y) for x, y in pts]
    parts = {'Barrel': L['Barrel'], 'Outline': outline_of(hull, 0.8), 'Hull': hull, 'HullShade': right_half(hull),
             'EdgeR': claw, 'EdgeL': flip(claw), 'WingPanelR': slits, 'WingPanelL': flip(slits), 'Spine': rib,
             'Sensor': cores, 'Highlight': eye, 'WingLightR': tip, 'WingLightL': flip(tip), 'EngineGlow': L['EngineGlow']}
    parts = {k: scale(lscale(v), s) for k, v in parts.items()}
    extra = ''
    for key, name in [('muzzle', 'muzzle_offset'), ('pylon', 'pylon_offset'), ('mount', 'mount_offset')]:
        x, y = L_OFFSETS[key]
        extra += '%s = Vector2(%s, %s)\n' % (name, fmt(x * LX * s), fmt(y * LY * s))
    extra += 'overlay_scale = %s\n' % fmt(s)
    extra += 'part_colors = Dictionary[String, Color]({\n%s\n})\n' % ',\n'.join('"%s": Color(%s)' % kv for kv in THRESHER_COLORS.items())
    return shape_tres(parts, extra + L_HITBOX)
# Extras at Light size; the whole class shape is then scaled.
# Plate = canted tail fins, growing with the class; Spine = raised centre armour.
EXTRAS_G = [
    {'Plate': [(6, 9), (9, 11), (10, 17), (7, 15.5)]},
    {'Plate': [(6, 7), (10, 10), (11.5, 18), (7.5, 15)]},
    {'Plate': [(8, 6), (13, 10), (14.5, 20), (9.5, 16)],
     'Spine': [(0, -14), (2.6, -8), (2.6, 10), (0, 14), (-2.6, 10), (-2.6, -8)]},
    {'Plate': [(8, 6), (14, 10), (16, 21), (10, 17)],
     'Spine': [(0, -18), (3.5, -10), (3.5, 12), (0, 16), (-3.5, 12), (-3.5, -10)]},
]
EXTRAS_L = [
    {'Plate': [(3, 12), (5, 15), (5.6, 23), (3.6, 20)]},
    {'Plate': [(3.2, 10), (5.6, 14), (6.2, 24), (3.8, 20)]},
    {'Plate': [(3.6, 9), (6.6, 14), (7.4, 26), (4.2, 21)],
     'Spine': [(0, -20), (1.8, -12), (1.8, 12), (0, 16), (-1.8, 12), (-1.8, -12)]},
    {'Plate': [(3.6, 8), (7, 13), (8, 28), (4.4, 22)],
     'Spine': [(0, -24), (2.4, -14), (2.4, 13), (0, 18), (-2.4, 13), (-2.4, -14)]},
]

def class_shape(base, extras, offsets, hitbox, s, hull, tip, detail=None):
    base = dict(base)
    if hull:
        base['Hull'] = hull
        base['WingLightR'] = tip
        base['WingLightL'] = [(-x, y) for x, y in tip]
    parts = {}
    order = ['Barrel', 'Hull']
    for k in order:
        parts[k] = scale(base[k], s)
    if 'Plate' in extras:
        left, right = pair(extras['Plate'])
        parts['PlateL'] = scale(left, s)
        parts['PlateR'] = scale(right, s)
    if 'Spine' in extras:
        parts['Spine'] = scale(extras['Spine'], s)
    for k in ['Highlight', 'Sensor', 'WingLightL', 'WingLightR', 'EngineGlow']:
        parts[k] = scale(base[k], s)
    if detail:
        parts['Outline'] = scale(outline_of(base['Hull']), s)
        parts['HullShade'] = scale(right_half(base['Hull']), s)
        parts['Sensor'] = scale(detail['Sensor'], s)
        for k in ['WingPanel', 'Intake', 'Edge', 'Stripe']:
            parts[k + 'R'] = scale(detail[k], s)
            parts[k + 'L'] = scale([(-x, y) for x, y in detail[k]], s)
    extra = ''
    for key, name in [('muzzle', 'muzzle_offset'), ('pylon', 'pylon_offset'), ('mount', 'mount_offset')]:
        x, y = offsets[key]
        extra += '%s = Vector2(%s, %s)\n' % (name, fmt(x * s), fmt(y * s))
    extra += 'overlay_scale = %s\n' % fmt(s)
    # Same hitbox in every class (DESIGN.md §5.2), so a bigger ship isn't unfair.
    return shape_tres(parts, extra + hitbox)

for i, c in enumerate(CLASSES):
    write('data/shapes/xf0_%s_gunship.tres' % c, class_shape(G, EXTRAS_G[i], G_OFFSETS, G_HITBOX, SCALES[i], HULLS_G[i], TIPS_G[i], DETAIL_G[i]))
    write('data/shapes/xf0_%s_thresher.tres' % c, thresher_shape(i))

set_text = '[gd_resource type="Resource" script_class="AirframeSet" load_steps=10 format=3]\n\n'
set_text += '[ext_resource type="Script" path="res://resources/airframe_set.gd" id="1_set"]\n'
for c in CLASSES:
    set_text += '[ext_resource type="Resource" path="res://data/shapes/xf0_%s_gunship.tres" id="g_%s"]\n' % (c, c)
    set_text += '[ext_resource type="Resource" path="res://data/shapes/xf0_%s_thresher.tres" id="l_%s"]\n' % (c, c)
set_text += '[ext_resource type="Script" path="res://resources/airframe_shape.gd" id="2_shape"]\n'
set_text = set_text.replace('load_steps=10', 'load_steps=11')
set_text += '\n[resource]\nscript = ExtResource("1_set")\n'
set_text += 'gunship_shapes = Array[ExtResource("2_shape")]([%s])\n' % ', '.join('ExtResource("g_%s")' % c for c in CLASSES)
set_text += 'thresher_shapes = Array[ExtResource("2_shape")]([%s])\n' % ', '.join('ExtResource("l_%s")' % c for c in CLASSES)
write('data/shapes/xf0_airframes.tres', set_text)

# ---------------- Overlays (Light size) ----------------
OV = {}
def overlay(name, g, l):
    OV[name] = (g, l)

# Propulsion
glow_g = [(-6, 16), (6, 16), (5.5, 32), (2.7, 32), (2.3, 17), (-2.3, 17), (-2.7, 32), (-5.5, 32)]
glow_l = [(-3, 22), (3, 22), (1.5, 44), (0, 48), (-1.5, 44)]
def lr(name, right):
    left, r = pair(right)
    return {name + 'L': left, name + 'R': r}
swept_parts_g = {'EngineGlow': glow_g}
swept_parts_l = {'EngineGlow': glow_l}
SWEEP_G = 'wing_sweep = 0.35\nsweep_pivot = 7.0\n'
SWEEP_L = 'wing_sweep = 0.4\nsweep_pivot = %s\n' % fmt(4.5 * LX)
SWEPT = ['propulsion_2', 'propulsion_3a', 'propulsion_3b']
overlay('propulsion_1', {'EngineGlow': glow_g}, {'EngineGlow': glow_l})
overlay('propulsion_2', swept_parts_g, swept_parts_l)
overlay('propulsion_3a', {**swept_parts_g, **lr('Blade', [(7, -5), (8.5, -8.5), (23.5, 9.5), (22, 11.2)])},
        {**swept_parts_l, **lr('Blade', curve([(4.6, -2), (5.6, -6)], [(5.6, -6), (8.9, 7), (12.3, 17.5), (13.8, 25.5)], [(13.8, 25.5), (13, 25.4), (11, 18.6), (7.5, 8.2), (4.6, -2)])[:-1])})
overlay('propulsion_3b', {**swept_parts_g, **lr('Nozzle', [(8.5, 17), (13, 17.5), (13, 22), (8.8, 22.5)])},
        {**swept_parts_l, **lr('Nozzle', [(6.5, 24), (10, 24.5), (10, 29), (6.5, 29.5)])})

# Nose weapons
overlay('m20d', {'Barrel': [(-3.5, -35), (-1, -35), (-1, -19), (1, -19), (1, -35), (3.5, -35), (3.5, -17), (-3.5, -17)]},
        {'Barrel': [(-2.5, -46), (-0.7, -46), (-0.7, -28), (0.7, -28), (0.7, -46), (2.5, -46), (2.5, -26), (-2.5, -26)]})
overlay('m40', {'Barrel': [(-6, -32), (-4, -32), (-2.5, -23), (-1, -23), (-1, -34), (1, -34), (1, -23), (2.5, -23), (4, -32), (6, -32), (4.5, -17), (-4.5, -17)]},
        {'Barrel': [(-3, -44), (-1.8, -44), (-1.2, -30), (-0.5, -30), (-0.5, -47), (0.5, -47), (0.5, -30), (1.2, -30), (1.8, -44), (3, -44), (2.2, -26), (-2.2, -26)]})
overlay('rg9', {'Barrel': [], 'Rail': [(-2.6, -46), (-1.2, -46), (-1.2, 6), (1.2, 6), (1.2, -46), (2.6, -46), (2.6, 9), (-2.6, 9)]},
        {'Barrel': [], 'Rail': [(-2, -58), (-0.9, -58), (-0.9, 4), (0.9, 4), (0.9, -58), (2, -58), (2, 7), (-2, 7)]})
import math
def hexagon(cx, cy, r):
    return [(cx + r * math.cos(math.pi / 6 + k * math.pi / 3), cy + r * math.sin(math.pi / 6 + k * math.pi / 3)) for k in range(6)]
overlay('hel1', {'Barrel': [], 'Lens': [(0, -34), (2, -30.5), (0, -27), (-2, -30.5)]},
        {'Barrel': [], 'Lens': [(0, -44), (1.7, -40.5), (0, -37), (-1.7, -40.5)]})
overlay('hel2', {'Barrel': [], 'Lens': hexagon(0, -30, 3.4)}, {'Barrel': [], 'Lens': hexagon(0, -40, 2.8)})
overlay('hel3t', {'Barrel': [], 'Lens': hexagon(0, -30, 3.4), **lr('HeatSink', [(6, -13), (10, -10), (10, -3), (7, -1)])},
        {'Barrel': [], 'Lens': hexagon(0, -40, 2.8), **lr('HeatSink', [(3.8, -16), (6.5, -13), (6.5, -7), (4.3, -5)])})
overlay('hel3s', {'Barrel': [], 'Lens': [(-6.5, -27), (-5, -31), (-3.5, -27), (-1.5, -27), (0, -33), (1.5, -27), (3.5, -27), (5, -31), (6.5, -27), (6, -24), (-6, -24)]},
        {'Barrel': [], 'Lens': [(-3.6, -37), (-2.6, -40), (-1.6, -37), (-0.9, -37), (0, -43), (0.9, -37), (1.6, -37), (2.6, -40), (3.6, -37), (3.2, -34), (-3.2, -34)]})

# Wing pylon pods, drawn around the pylon point.
PODS = {
    'r1': [(-2, -5), (2, -5), (2, 5), (-2, 5)],
    'mk1': [(0, -7), (1.6, -4), (1.6, 5), (-1.6, 5), (-1.6, -4)],
    'mk2': [(-3, -6), (-0.5, -6), (-0.5, -3), (0.5, -3), (0.5, -6), (3, -6), (3, 6), (-3, 6)],
    'mk3': [(-3, -4), (0, -8), (3, -4), (3, 7), (-3, 7)],
    'gbu': [(-1.5, -8), (1.5, -8), (3.5, -4), (3.5, 4), (1.5, 8), (-1.5, 8), (-3.5, 4), (-3.5, -4)],
}
for key, pod in PODS.items():
    g = shift(pod, *G_OFFSETS['pylon'])
    l = shift(scale(pod, 0.75), *L_OFFSETS['pylon'])
    overlay(key, lr('Pod', g), lr('Pod', l))

for name, (g, l) in OV.items():
    swept = name in SWEPT
    write('data/shapes/overlays/%s_gunship.tres' % name, shape_tres(g, SWEEP_G if swept else ''))
    write('data/shapes/overlays/%s_thresher.tres' % name, shape_tres({k: lscale(v) for k, v in l.items()}, SWEEP_L if swept else ''))

# ---------------- Point weapons and refits at their overlays ----------------
TARGETS = {
    'data/weapons/m20d_twin_autocannon.tres': 'm20d', 'data/weapons/m40_flak_battery.tres': 'm40',
    'data/weapons/rg9_railgun.tres': 'rg9', 'data/weapons/hel1_beam_laser.tres': 'hel1',
    'data/weapons/hel2_focused_beam.tres': 'hel2', 'data/weapons/hel3t_thermal_lance.tres': 'hel3t',
    'data/weapons/hel3s_split_array.tres': 'hel3s', 'data/weapons/r1_rocket_pod.tres': 'r1',
    'data/weapons/mk1_seeker.tres': 'mk1', 'data/weapons/mk2_seeker_pod.tres': 'mk2',
    'data/weapons/mk3_cluster_missile.tres': 'mk3', 'data/weapons/gbu_bunker_buster.tres': 'gbu',
    'data/refits/propulsion_1.tres': 'propulsion_1', 'data/refits/propulsion_2.tres': 'propulsion_2',
    'data/refits/propulsion_3a.tres': 'propulsion_3a', 'data/refits/propulsion_3b.tres': 'propulsion_3b',
}
for path, name in TARGETS.items():
    raw = open(path, encoding='utf-8', newline='').read()
    crlf = '\r\n' in raw
    s = raw.replace('\r\n', '\n')
    # Idempotent: drop anything a previous run added.
    s = re.sub(r'\[ext_resource [^\n]*id="air_[gl]"\]\n', '', s)
    s = re.sub(r'airframe_(gunship|thresher) = ExtResource\("air_[gl]"\)\n', '', s)
    s = re.sub(r'\n\n\n+', '\n\n', s)
    # External references go right after the last existing one (before any sub-resources).
    last = list(re.finditer(r'^\[ext_resource [^\n]*\]\n', s, re.M))[-1]
    refs = '[ext_resource type="Resource" path="res://data/shapes/overlays/%s_gunship.tres" id="air_g"]\n' % name
    refs += '[ext_resource type="Resource" path="res://data/shapes/overlays/%s_thresher.tres" id="air_l"]\n' % name
    s = s[:last.end()] + refs + s[last.end():]
    s = s.rstrip('\n') + '\nairframe_gunship = ExtResource("air_g")\nairframe_thresher = ExtResource("air_l")\n'
    count = len(re.findall(r'^\[(ext|sub)_resource', s, re.M)) + 1
    s = re.sub(r'load_steps=\d+', 'load_steps=%d' % count, s, count=1)
    if crlf:
        s = s.replace('\n', '\r\n')
    open(path, 'w', encoding='utf-8', newline='').write(s)
print('shapes ok', len(OV), 'overlays')
