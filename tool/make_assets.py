"""يرسم الشخصيات الجاهزة وأيقونة البرنامج.
الإحداثيات لازم تفضل متطابقة مع builtInPersonas() في lib/models.dart:
  البق عند (0.5, 0.578) وعرضه 0.13، العينين عند (0.425/0.575, 0.44) ونص القطر 0.03.
"""
import math
import os
from PIL import Image, ImageDraw, ImageFilter

S = 2  # رسم بدقة مضاعفة ثم تصغير لنعومة الحواف
W, H = 600, 800
OUT = os.path.join(os.path.dirname(__file__), '..', 'assets')


def s(v):
    return int(round(v * S))


def box(cx, cy, rx, ry):
    return [s(cx - rx), s(cy - ry), s(cx + rx), s(cy + ry)]


def gradient(top, bottom):
    img = Image.new('RGB', (W * S, H * S))
    d = ImageDraw.Draw(img)
    for y in range(H * S):
        t = y / (H * S)
        c = tuple(int(top[i] + (bottom[i] - top[i]) * t) for i in range(3))
        d.line([(0, y), (W * S, y)], fill=c)
    return img.convert('RGBA')


def shade(c, k):
    return tuple(max(0, min(255, int(v * k))) for v in c[:3])


def soft_layer(draw_fn, blur):
    layer = Image.new('RGBA', (W * S, H * S), (0, 0, 0, 0))
    draw_fn(ImageDraw.Draw(layer))
    return layer.filter(ImageFilter.GaussianBlur(s(blur)))


def avatar(name, bg, skin, hair, shirt, iris, lip, hair_style, extras=()):
    img = gradient(*bg)
    # بقعة نور ورا الراس
    img.alpha_composite(soft_layer(lambda d: d.ellipse(box(300, 360, 230, 230), fill=(255, 255, 255, 40)), 40))
    d = ImageDraw.Draw(img)
    hx, hy, hrx, hry = 300, 392, 116, 146

    # شعر ورا (للشعر الطويل)
    if hair_style in ('long', 'curly'):
        if hair_style == 'long':
            d.rounded_rectangle([s(170), s(270), s(430), s(690)], radius=s(110), fill=hair)
        else:
            for (cx, cy, r) in [(190, 330, 70), (410, 330, 70), (180, 430, 72), (420, 430, 72),
                                (195, 530, 66), (405, 530, 66), (300, 250, 110)]:
                d.ellipse(box(cx, cy, r, r), fill=hair)

    # الجسم والرقبة
    d.rounded_rectangle([s(255), s(500), s(345), s(690)], radius=s(30), fill=shade(skin, 0.86))
    d.rounded_rectangle([s(70), s(640), s(530), s(900)], radius=s(150), fill=shirt)
    if 'suit' not in extras:
        d.pieslice(box(300, 640, 52, 34), 0, 180, fill=shade(skin, 0.86))
    if 'suit' in extras:
        d.polygon([(s(300), s(660)), (s(225), s(640)), (s(270), s(800))], fill=(240, 240, 245))
        d.polygon([(s(300), s(660)), (s(375), s(640)), (s(330), s(800))], fill=(240, 240, 245))
        d.polygon([(s(290), s(668)), (s(310), s(668)), (s(318), s(800)), (s(282), s(800))], fill=(150, 30, 45))
        d.polygon([(s(225), s(640)), (s(160), s(660)), (s(255), s(800))], fill=shade(shirt, 0.75))
        d.polygon([(s(375), s(640)), (s(440), s(660)), (s(345), s(800))], fill=shade(shirt, 0.75))

    # الودان
    for ex in (hx - hrx + 6, hx + hrx - 6):
        d.ellipse(box(ex, 410, 20, 32), fill=shade(skin, 0.94))

    # الوش
    d.ellipse(box(hx, hy, hrx, hry), fill=skin)
    # ظل خفيف تحت الدقن
    img.alpha_composite(soft_layer(lambda dd: dd.ellipse(box(300, 540, 70, 18), fill=(0, 0, 0, 50)), 8))
    d = ImageDraw.Draw(img)
    # خدود
    img.alpha_composite(soft_layer(lambda dd: [dd.ellipse(box(230, 470, 30, 18), fill=(255, 120, 120, 55)),
                                               dd.ellipse(box(370, 470, 30, 18), fill=(255, 120, 120, 55))], 10))
    d = ImageDraw.Draw(img)

    # ذقن خفيفة
    if 'stubble' in extras or 'beard' in extras:
        alpha = 70 if 'stubble' in extras else 150
        def beard(dd):
            dd.pieslice(box(hx, hy, hrx - 4, hry - 4), 15, 165, fill=hair + (alpha,))
            dd.ellipse(box(300, 455, 50, 16), fill=hair + (alpha,))
        img.alpha_composite(soft_layer(beard, 3))
        d = ImageDraw.Draw(img)
        # نرجّع منطقة البق والشفايف
        d.ellipse(box(300, 470, 44, 22), fill=skin)

    # شعر قدام
    if hair_style == 'short':
        d.chord(box(hx, 296, hrx + 8, 62), 180, 360, fill=hair)
        d.pieslice(box(hx - 30, 296, 95, 38), 0, 120, fill=hair)
        d.rectangle([s(hx - hrx - 4), s(296), s(hx - hrx + 14), s(385)], fill=hair)
        d.rectangle([s(hx + hrx - 14), s(296), s(hx + hrx + 4), s(385)], fill=hair)
    elif hair_style == 'neat':
        d.chord(box(hx, 292, hrx + 6, 58), 180, 360, fill=hair)
        d.chord(box(hx, 292, hrx - 6, 14), 0, 180, fill=hair)
        d.rectangle([s(hx - hrx - 2), s(292), s(hx - hrx + 12), s(380)], fill=hair)
        d.rectangle([s(hx + hrx - 12), s(292), s(hx + hrx + 2), s(380)], fill=hair)
    elif hair_style == 'long':
        d.chord(box(hx, 296, hrx + 12, 66), 180, 360, fill=hair)
        d.chord(box(hx + 20, 296, 100, 26), 0, 180, fill=hair)
        d.polygon([(s(186), s(296)), (s(214), s(296)), (s(196), s(420)), (s(178), s(420))], fill=hair)
        d.polygon([(s(386), s(296)), (s(414), s(296)), (s(422), s(420)), (s(404), s(420))], fill=hair)
    elif hair_style == 'curly':
        for (cx, cy, r) in [(210, 300, 48), (250, 268, 50), (300, 255, 52), (350, 268, 50), (390, 300, 48),
                            (196, 350, 36), (404, 350, 36)]:
            d.ellipse(box(cx, cy, r, r), fill=hair)

    # الحواجب
    brow = shade(hair, 0.8)
    for side in (-1, 1):
        x0 = 300 + side * 45
        x1 = 300 + side * 100
        d.line([(s(x0), s(318)), (s((x0 + x1) / 2), s(310)), (s(x1), s(318))], fill=brow, width=s(8), joint='curve')

    # العينين (المراكز: 255 و 345، y=352)
    for cx in (255, 345):
        d.ellipse(box(cx, 352, 22, 14), fill=(250, 250, 252))
        d.ellipse(box(cx, 353, 11, 11), fill=iris)
        d.ellipse(box(cx, 353, 5.5, 5.5), fill=(20, 16, 24))
        d.ellipse(box(cx + 4, 349, 3, 3), fill=(255, 255, 255))
        d.arc(box(cx, 352, 23, 15), 190, 350, fill=shade(skin, 0.45), width=s(3.5))
        if 'lashes' in extras:
            d.line([(s(cx + 20), s(345)), (s(cx + 28), s(339))], fill=(30, 20, 20), width=s(3))
            d.line([(s(cx - 20), s(345)), (s(cx - 28), s(339))], fill=(30, 20, 20), width=s(3))

    if 'glasses' in extras:
        for cx in (255, 345):
            d.rounded_rectangle(box(cx, 354, 36, 26), radius=s(12), outline=(35, 35, 45), width=s(5))
        d.line([(s(291), s(350)), (s(309), s(350))], fill=(35, 35, 45), width=s(5))
        d.line([(s(219), s(348)), (s(186), s(340))], fill=(35, 35, 45), width=s(5))
        d.line([(s(381), s(348)), (s(414), s(340))], fill=(35, 35, 45), width=s(5))

    # المناخير
    d.arc(box(300, 405, 18, 22), 20, 160, fill=shade(skin, 0.72), width=s(4))
    d.line([(s(296), s(360)), (s(292), s(400))], fill=shade(skin, 0.88), width=s(3))

    # الشفايف — خط البق عند y=462
    up = [(s(262), s(462)), (s(278), s(452)), (s(292), s(449)), (s(300), s(453)),
          (s(308), s(449)), (s(322), s(452)), (s(338), s(462))]
    d.polygon(up, fill=shade(lip, 0.88))
    low = [(s(262), s(462)), (s(338), s(462)), (s(325), s(474)), (s(300), s(480)), (s(275), s(474))]
    d.polygon(low, fill=lip)
    d.line([(s(262), s(462)), (s(338), s(462))], fill=shade(lip, 0.55), width=s(2.5))
    d.ellipse(box(300, 470, 10, 3), fill=shade(lip, 1.15))

    img = img.resize((W, H), Image.LANCZOS).convert('RGB')
    img.save(os.path.join(OUT, 'avatars', f'{name}.png'), optimize=True)


def make_icon():
    size = 1024
    S2 = 1

    def bubble(img, fg_only):
        d = ImageDraw.Draw(img)
        if not fg_only:
            for y in range(size):
                t = y / size
                c = (int(43 + (27 - 43) * t), int(26 + (19 - 26) * t), int(98 + (64 - 98) * t))
                d.line([(0, y), (size, y)], fill=c)
        # فقاعة كلام كهرماني
        bx0, by0, bx1, by1 = 250, 270, 774, 690
        grad = Image.new('RGBA', (size, size), (0, 0, 0, 0))
        gd = ImageDraw.Draw(grad)
        for y in range(by0, by1 + 110):
            t = (y - by0) / (by1 + 110 - by0)
            gd.line([(0, y), (size, y)], fill=(255, int(197 - 60 * t), int(107 - 15 * t), 255))
        mask = Image.new('L', (size, size), 0)
        md = ImageDraw.Draw(mask)
        md.rounded_rectangle([bx0, by0, bx1, by1], radius=150, fill=255)
        md.polygon([(380, 650), (330, 790), (500, 680)], fill=255)
        img.paste(grad, (0, 0), mask)
        d = ImageDraw.Draw(img)
        # موجة صوت (3 عواميد) + نقطتين = كلام
        dark = (42, 26, 0)
        for i, hgt in enumerate([90, 170, 240, 170, 90]):
            x = 362 + i * 75
            d.rounded_rectangle([x - 22, 480 - hgt / 2, x + 22, 480 + hgt / 2], radius=22, fill=dark)
        return img

    full = bubble(Image.new('RGBA', (size, size), (0, 0, 0, 0)), False)
    full.convert('RGB').save(os.path.join(OUT, 'icon', 'icon.png'))
    # أيقونة متكيفة: المقدمة لازم تبقى في النص الآمن (66%)
    fg = bubble(Image.new('RGBA', (size, size), (0, 0, 0, 0)), True)
    fg = fg.resize((int(size * 0.72), int(size * 0.72)), Image.LANCZOS)
    canvas = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    canvas.paste(fg, ((size - fg.width) // 2, (size - fg.height) // 2), fg)
    canvas.save(os.path.join(OUT, 'icon', 'icon_fg.png'))


if __name__ == '__main__':
    avatar('emma', ((255, 214, 186), (233, 150, 160)), (247, 214, 190), (222, 180, 110),
           (70, 110, 200), (70, 120, 170), (210, 100, 110), 'long', ('lashes',))
    avatar('james', ((176, 214, 240), (90, 130, 190)), (238, 200, 170), (110, 70, 40),
           (60, 70, 85), (90, 130, 90), (190, 115, 105), 'short', ('stubble',))
    avatar('sara', ((200, 240, 220), (110, 190, 170)), (200, 150, 115), (40, 25, 20),
           (240, 120, 90), (85, 55, 30), (185, 90, 90), 'curly', ('lashes',))
    avatar('david', ((225, 225, 235), (150, 150, 175)), (180, 130, 95), (30, 28, 30),
           (40, 50, 80), (70, 45, 25), (160, 90, 80), 'neat', ('suit', 'glasses', 'beard'))
    make_icon()
    print('done')
