#!/usr/bin/env python3
"""v2 yeni üniversiteler için logo indirme + marka rengi çıkarımı.

Kaynak zinciri (üni başına):
  1. TR Wikipedia makalesindeki dosyalardan adı logo/amblem/arma/seal/emblem
     içeren ilk dosya (512px PNG thumb)
  2. EN Wikipedia, aynı filtre
  3. TR Wikipedia pageimage (fotoğraf olabilir → elle kontrol işaretlenir)

Çıktılar:
  assets/logos/{id}.png
  lib/scripts/osym/v2_brand_colors.json   — {id: [primaryHex, secondaryHex]}
  lib/scripts/osym/v2_logo_report.md      — kaynak + elle kontrol bayrakları

Var olan logo dosyaları atlanır (yeniden indirmek için dosyayı sil).
"""

import colorsys
import io
import json
import re
import time
from pathlib import Path

import requests
from PIL import Image

ROOT = Path(__file__).resolve().parents[3]
SEED = ROOT / 'assets' / 'data' / 'universities_seed.json'
LOGO_DIR = ROOT / 'assets' / 'logos'
OUT_COLORS = Path(__file__).resolve().parent / 'v2_brand_colors.json'
OUT_REPORT = Path(__file__).resolve().parent / 'v2_logo_report.md'

UA = {'User-Agent': 'UniSecApp-v2-data-prep/1.0 (gurgilburak@gmail.com)'}
LOGO_WORDS = re.compile(r'logo|amblem|arma|seal|emblem', re.I)
SKIP_FILES = re.compile(
    r'commons-logo|wiki|icon_|edit-|openstreetmap|maplink|\bmap\b|flag|bayrak', re.I)
# Dernek/eski logolar üniversitenin kendisi değildir — ancak başka aday yoksa
BAD_WORDS = re.compile(r'mezunlar|dernek|alumni|eski|old\b', re.I)

# Wikipedia makale adı üni adından farklıysa
TITLE_OVERRIDES = {
    'iuc': 'İstanbul Üniversitesi-Cerrahpaşa',
    'tobb_etu': 'TOBB Ekonomi ve Teknoloji Üniversitesi',
}


def api(lang: str, **params):
    params.update({'format': 'json', 'action': 'query'})
    r = requests.get(f'https://{lang}.wikipedia.org/w/api.php',
                     params=params, headers=UA, timeout=20)
    r.raise_for_status()
    return r.json()


def find_logo_file(lang: str, title: str) -> tuple[str | None, bool]:
    """Makaledeki dosyalardan logo adayı döndür: (File adı, dernek/eski mi)."""
    data = api(lang, titles=title, prop='images', imlimit=100, redirects=1)
    pages = data['query']['pages']
    page = next(iter(pages.values()))
    candidates = [img['title'] for img in page.get('images', [])
                  if LOGO_WORDS.search(img['title']) and not SKIP_FILES.search(img['title'])]
    if not candidates:
        return None, False
    # Dernek/eski logoları en sona at, sıra korunarak en iyi aday seçilir
    candidates.sort(key=lambda n: bool(BAD_WORDS.search(n)))
    best = candidates[0]
    return best, bool(BAD_WORDS.search(best))


def file_thumb_url(lang: str, file_title: str) -> str | None:
    data = api(lang, titles=file_title, prop='imageinfo',
               iiprop='url', iiurlwidth=512)
    page = next(iter(data['query']['pages'].values()))
    info = page.get('imageinfo')
    if not info:
        return None
    return info[0].get('thumburl') or info[0].get('url')


def page_image_url(lang: str, title: str) -> str | None:
    data = api(lang, titles=title, prop='pageimages', pithumbsize=512, redirects=1)
    page = next(iter(data['query']['pages'].values()))
    thumb = page.get('thumbnail')
    return thumb['source'] if thumb else None


def download_png(url: str, dest: Path) -> Image.Image:
    r = requests.get(url, headers=UA, timeout=30)
    r.raise_for_status()
    im = Image.open(io.BytesIO(r.content))
    im = im.convert('RGBA')
    im.thumbnail((512, 512), Image.LANCZOS)
    im.save(dest, 'PNG')
    return im


def extract_brand_colors(im: Image.Image) -> tuple[str, str]:
    """Logodan baskın 2 doygun rengi çıkar (beyaz/gri/şeffaf hariç)."""
    small = im.convert('RGBA').resize((96, 96))
    counts = {}
    for r, g, b, a in small.getdata():
        if a < 200:
            continue
        h, s, v = colorsys.rgb_to_hsv(r / 255, g / 255, b / 255)
        # gri/siyah/beyaz atla — beyaz s ile yakalanır; v üst sınırı KOYMA,
        # #FF7100 gibi saf marka renkleri v=1.0'dır
        if s < 0.25 or v < 0.15:
            continue
        # hafif kuantalama — benzer tonları birleştir
        key = (round(h * 24), round(s * 4), round(v * 4))
        rgb, n = counts.get(key, ((r, g, b), 0))
        counts[key] = (rgb, n + 1)
    ranked = sorted(counts.values(), key=lambda x: -x[1])
    if not ranked:
        return '#455A64', '#607D8B'  # nötr fallback
    primary = ranked[0][0]

    def hexit(c):
        return '#%02X%02X%02X' % c

    def hue(c):
        return colorsys.rgb_to_hsv(c[0] / 255, c[1] / 255, c[2] / 255)[0]

    secondary = None
    for rgb, _ in ranked[1:]:
        if abs(hue(rgb) - hue(primary)) > 0.08:  # farklı ton ailesi
            secondary = rgb
            break
    if secondary is None:  # aynı ailenin koyusu
        secondary = tuple(int(c * 0.72) for c in primary)
    return hexit(primary), hexit(secondary)


def main() -> None:
    unis = json.loads(SEED.read_text(encoding='utf-8'))['universities']
    targets = [u for u in unis if u.get('_v2New')]
    colors = json.loads(OUT_COLORS.read_text(encoding='utf-8')) if OUT_COLORS.exists() else {}
    rows, missing = [], []

    for u in targets:
        uid, name = u['id'], u['name']
        dest = LOGO_DIR / f'{uid}.png'
        if dest.exists() and uid in colors:
            continue
        title = TITLE_OVERRIDES.get(uid, name)
        src, flag = None, ''
        try:
            tr_f, tr_bad = find_logo_file('tr', title)
            en_f, en_bad = (None, False)
            if not tr_f or tr_bad:
                en_f, en_bad = find_logo_file('en', title)
            # öncelik: tr-iyi → en-iyi → tr-kötü → en-kötü → sayfa görseli
            if tr_f and not tr_bad:
                lang, f = 'tr', tr_f
            elif en_f and not en_bad:
                lang, f = 'en', en_f
            elif tr_f:
                lang, f = 'tr', tr_f
                flag = '⚠ dernek/eski logo olabilir — ELLE KONTROL'
            elif en_f:
                lang, f = 'en', en_f
                flag = '⚠ dernek/eski logo olabilir — ELLE KONTROL'
            else:
                lang, f = 'tr', None
            if f:
                url = file_thumb_url(lang, f)
                src = f'{lang}:{f}'
            else:
                url = page_image_url('tr', title)
                src = 'tr:pageimage'
                flag = '⚠ logo bulunamadı, sayfa görseli indirildi — ELLE KONTROL'
            if not url:
                raise RuntimeError('görsel yok')
            im = download_png(url, dest)
            p, s = extract_brand_colors(im)
            colors[uid] = [p, s]
            rows.append((uid, name, src, p, s, flag))
            print(f'✔ {uid:14} {src}  {p}/{s} {flag}')
        except Exception as e:
            missing.append((uid, name, str(e)))
            print(f'✗ {uid:14} HATA: {e}')
        time.sleep(0.4)

    OUT_COLORS.write_text(json.dumps(colors, ensure_ascii=False, indent=2), encoding='utf-8')

    lines = ['# v2 Logo Raporu', '',
             '| id | Üniversite | Kaynak | Renkler | Not |', '|---|---|---|---|---|']
    for uid, name, src, p, s, flag in rows:
        lines.append(f'| `{uid}` | {name} | {src} | {p} {s} | {flag} |')
    if missing:
        lines += ['', '## İndirilemeyenler', '']
        for uid, name, err in missing:
            lines.append(f'- `{uid}` {name}: {err}')
    OUT_REPORT.write_text('\n'.join(lines) + '\n', encoding='utf-8')
    print(f'\n{len(rows)} indirildi, {len(missing)} eksik → {OUT_REPORT}')


if __name__ == '__main__':
    main()
