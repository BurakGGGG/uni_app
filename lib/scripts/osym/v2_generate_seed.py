#!/usr/bin/env python3
"""v2 seed üretici.

Girdi:
  v2_selection.json            — v2_select_universities.py çıktısı (yeni üniler)
  seed_data_service.dart       — mevcut 50 üni + 30 şehir (birebir korunur)
  universiteler.csv            — il başına toplam üni sayısı için

Çıktı:
  assets/data/cities_seed.json        — 60 şehir (mevcut + yeni, alanlar birleşik)
  assets/data/universities_seed.json  — 105 üni
  lib/scripts/osym/v2_uni_mapping_additions.json — ÖSYM adı → yeni app id
  lib/scripts/osym/v2_missing_report.md          — elle doldurulacak alanlar

Seçim listesi değişirse önce v2_select_universities.py, sonra bu script
yeniden çalıştırılır; çıktılar deterministiktir.
"""

import csv
import json
import re
import sys
import unicodedata
from collections import Counter
from pathlib import Path

from v2_select_universities import PLATE_DISPLAY, PROVINCE_PLATES, norm

ROOT = Path(__file__).resolve().parents[3]
SELECTION = Path(__file__).resolve().parent / 'v2_selection.json'
SEED_DART = ROOT / 'lib' / 'scripts' / 'seed_data_service.dart'
ABBR_DART = ROOT / 'lib' / 'core' / 'utils' / 'university_abbreviations.dart'
UNIS_CSV = ROOT / 'taban_puanları' / 'yokatlas-dataset-2025' / 'universiteler.csv'
OUT_CITIES = ROOT / 'assets' / 'data' / 'cities_seed.json'
OUT_UNIS = ROOT / 'assets' / 'data' / 'universities_seed.json'
OUT_MAPPING = Path(__file__).resolve().parent / 'v2_uni_mapping_additions.json'
OUT_REPORT = Path(__file__).resolve().parent / 'v2_missing_report.md'
BRAND_COLORS = Path(__file__).resolve().parent / 'v2_brand_colors.json'
LOGO_DIR = ROOT / 'assets' / 'logos'

# Bilinen üniler için okunaklı app id (kural yetersiz kaldığında)
ID_OVERRIDES = {
    'BOĞAZİÇİ ÜNİVERSİTESİ': 'bogazici',
    'İSTANBUL ÜNİVERSİTESİ-CERRAHPAŞA': 'iuc',
    'SAĞLIK BİLİMLERİ ÜNİVERSİTESİ': 'sbu',
    'MİMAR SİNAN GÜZEL SANATLAR ÜNİVERSİTESİ': 'msgsu',
    'İZMİR YÜKSEK TEKNOLOJİ ENSTİTÜSÜ': 'iyte',
    'TÜRK-ALMAN ÜNİVERSİTESİ': 'turk_alman',
    'İHSAN DOĞRAMACI BİLKENT ÜNİVERSİTESİ': 'bilkent',
    'TOBB EKONOMİ VE TEKNOLOJİ ÜNİVERSİTESİ': 'tobb_etu',
    'KADİR HAS ÜNİVERSİTESİ': 'kadir_has',
    'İSTANBUL BİLGİ ÜNİVERSİTESİ': 'bilgi',
    'İZMİR EKONOMİ ÜNİVERSİTESİ': 'izmir_ekonomi',
    'AYDIN ADNAN MENDERES ÜNİVERSİTESİ': 'adu',
    'MUĞLA SITKI KOÇMAN ÜNİVERSİTESİ': 'msku',
    'HATAY MUSTAFA KEMAL ÜNİVERSİTESİ': 'mku',
    'MARDİN ARTUKLU ÜNİVERSİTESİ': 'artuklu',
    'NECMETTİN ERBAKAN ÜNİVERSİTESİ': 'erbakan',
    'NİĞDE ÖMER HALİSDEMİR ÜNİVERSİTESİ': 'ohu',
    'ISPARTA UYGULAMALI BİLİMLER ÜNİVERSİTESİ': 'isubu',
    'SAKARYA UYGULAMALI BİLİMLER ÜNİVERSİTESİ': 'subu',
    'ERZİNCAN BİNALİ YILDIRIM ÜNİVERSİTESİ': 'ebyu',
    'TEKİRDAĞ NAMIK KEMAL ÜNİVERSİTESİ': 'nku',
    'YOZGAT BOZOK ÜNİVERSİTESİ': 'yobu',
    'NEVŞEHİR HACI BEKTAŞ VELİ ÜNİVERSİTESİ': 'nevu',
    'BURDUR MEHMET AKİF ERSOY ÜNİVERSİTESİ': 'maku',
    'AFYON KOCATEPE ÜNİVERSİTESİ': 'aku',
    'KIRŞEHİR AHİ EVRAN ÜNİVERSİTESİ': 'kaeu',
    'BİTLİS EREN ÜNİVERSİTESİ': 'bitlis_eren',
    'ARTVİN ÇORUH ÜNİVERSİTESİ': 'acu',
    'KIRIKKALE ÜNİVERSİTESİ': 'kku',
    'KIRKLARELİ ÜNİVERSİTESİ': 'klu',
    'ANKARA YILDIRIM BEYAZIT ÜNİVERSİTESİ': 'aybu',
    'ANKARA SOSYAL BİLİMLER ÜNİVERSİTESİ': 'asbu',
}

# Kural yetmediğinde alias'lar (ÖSYM adı → alias listesi)
ALIAS_OVERRIDES = {
    'İSTANBUL ÜNİVERSİTESİ-CERRAHPAŞA': ['İÜC', 'Cerrahpaşa'],
    'İHSAN DOĞRAMACI BİLKENT ÜNİVERSİTESİ': ['Bilkent'],
    'TOBB EKONOMİ VE TEKNOLOJİ ÜNİVERSİTESİ': ['TOBB ETÜ', 'TOBB'],
    'SAKARYA UYGULAMALI BİLİMLER ÜNİVERSİTESİ': ['SUBÜ'],
    'İZMİR EKONOMİ ÜNİVERSİTESİ': ['İEÜ', 'İzmir Ekonomi'],
    'KADİR HAS ÜNİVERSİTESİ': ['KHAS', 'Kadir Has'],
    'BAHÇEŞEHİR ÜNİVERSİTESİ': ['BAU', 'Bahçeşehir'],
    'ÖZYEĞİN ÜNİVERSİTESİ': ['ÖzÜ', 'Özyeğin'],
}

# Görünen adda büyük kalması gereken akronimler
UPPER_WORDS = {'TOBB'}

# Yeni şehirlerin yaklaşık nüfusları (TÜİK 2023/24 ölçeğinde; mevcut
# city_population_migration.dart'ın standardıyla uyumlu: tam doğruluk şart
# değil, gözden geçirme raporunda işaretlenir)
PLATE_POPULATION = {
    '02': 604_000,    # Adıyaman
    '03': 751_000,    # Afyonkarahisar
    '05': 339_000,    # Amasya
    '08': 169_000,    # Artvin
    '09': 1_161_000,  # Aydın
    '10': 1_276_000,  # Balıkesir
    '12': 285_000,    # Bingöl
    '13': 353_000,    # Bitlis
    '15': 274_000,    # Burdur
    '21': 1_818_000,  # Diyarbakır
    '22': 421_000,    # Edirne
    '23': 604_000,    # Elazığ
    '24': 243_000,    # Erzincan
    '28': 461_000,    # Giresun
    '29': 148_000,    # Gümüşhane
    '31': 1_544_000,  # Hatay
    '36': 274_000,    # Kars
    '37': 388_000,    # Kastamonu
    '39': 377_000,    # Kırklareli
    '40': 244_000,    # Kırşehir
    '47': 888_000,    # Mardin
    '48': 1_066_000,  # Muğla
    '50': 315_000,    # Nevşehir
    '51': 377_000,    # Niğde
    '59': 1_167_000,  # Tekirdağ
    '63': 2_213_000,  # Şanlıurfa
    '66': 420_000,    # Yozgat
    '68': 438_000,    # Aksaray
    '71': 277_000,    # Kırıkkale
    '81': 409_000,    # Düzce
}

TR_LOWER = str.maketrans({'I': 'ı', 'İ': 'i'})
TR_FOLD = str.maketrans({
    'ç': 'c', 'ğ': 'g', 'ı': 'i', 'ö': 'o', 'ş': 's', 'ü': 'u',
    'Ç': 'c', 'Ğ': 'g', 'İ': 'i', 'I': 'i', 'Ö': 'o', 'Ş': 's', 'Ü': 'u',
})
LOWERCASE_WORDS = {'ve', 'ile'}


def tr_lower(s: str) -> str:
    return s.translate(TR_LOWER).lower()


def tr_title(s: str) -> str:
    """ÖSYM büyük harf adını görünen ada çevir: 'BOĞAZİÇİ ÜNİVERSİTESİ' → 'Boğaziçi Üniversitesi'."""
    def cap(word: str) -> str:
        if not word:
            return word
        if word.upper() in UPPER_WORDS:
            return word.upper()
        if tr_lower(word) in LOWERCASE_WORDS:
            return tr_lower(word)
        head, tail = word[0], tr_lower(word[1:])
        head = 'İ' if head == 'i' else ('I' if head == 'ı' else head.upper())
        return head + tail

    def cap_compound(token: str) -> str:
        return '-'.join(cap(p) for p in token.split('-'))

    return ' '.join(cap_compound(tr_lower(w)) for w in s.split())


def slugify(s: str) -> str:
    s = tr_lower(s).translate(TR_FOLD)
    s = re.sub(r'[^a-z0-9]+', '_', s).strip('_')
    return s


def clean_website(url: str) -> str:
    """'http://www.agu.edu.tr/x' → 'agu.edu.tr' (mevcut seed stiliyle uyumlu)."""
    host = re.sub(r'^https?://', '', url.strip())
    host = host.split('/')[0].split('?')[0]
    return host.removeprefix('www.').lower()


def load_abbreviations() -> dict:
    """university_abbreviations.dart içindeki _map'i (tam ad → kısaltma) çek."""
    text = ABBR_DART.read_text(encoding='utf-8')
    pairs = re.findall(r"'([^']+)':\s*'([^']+)',", text)
    return {norm(k): v for k, v in pairs}


def dart_line_to_json(line: str):
    """seed_data_service.dart'taki tek satırlık Dart map literalini JSON'a çevir."""
    line = line.strip().rstrip(',')
    line = line.replace('<String, double>{}', '{}')
    out, i, n = [], 0, len(line)
    while i < n:
        ch = line[i]
        if ch == "'":  # Dart string başlangıcı
            i += 1
            buf = []
            while i < n:
                c = line[i]
                if c == '\\' and i + 1 < n:
                    nxt = line[i + 1]
                    buf.append(nxt if nxt == "'" else '\\' + nxt)
                    i += 2
                    continue
                if c == "'":
                    break
                buf.append('\\"' if c == '"' else c)
                i += 1
            out.append('"' + ''.join(buf) + '"')
        else:
            out.append(ch)
        i += 1
    return json.loads(''.join(out))


def extract_dart_list(marker: str) -> list:
    """`final <marker> = [` bloğundaki map literallerini parse et."""
    entries = []
    in_block = False
    for line in SEED_DART.read_text(encoding='utf-8').splitlines():
        stripped = line.strip()
        if stripped.startswith(f'final {marker} = ['):
            in_block = True
            continue
        if in_block:
            if stripped.startswith('];'):
                break
            if stripped.startswith('{'):
                entries.append(dart_line_to_json(line))
    return entries


def province_totals() -> Counter:
    """İl başına gerçek üni sayısı (Devlet+Vakıf, MYO hariç)."""
    totals = Counter()
    with UNIS_CSV.open(encoding='utf-8') as f:
        for row in csv.DictReader(f):
            plate = PROVINCE_PLATES.get(norm(row['il']))
            if plate and row['tur'].strip().upper() in ('DEVLET', 'VAKIF'):
                totals[plate] += 1
    return totals


def make_id(osym_name: str, province: str, existing: set) -> str:
    if osym_name in ID_OVERRIDES:
        return ID_OVERRIDES[osym_name]
    words = osym_name.replace('ÜNİVERSİTESİ', '').strip().split()
    if len(words) == 1:
        base = slugify(words[0])
        # İl adıyla aynıysa mevcut stile uy: trabzon_uni, istanbul_uni...
        if norm(words[0]) == province:
            base += '_uni'
    else:
        base = slugify(' '.join(words))
    uid = base
    n = 2
    while uid in existing:
        uid = f'{base}_{n}'
        n += 1
    return uid


def make_aliases(osym_name: str, uni_type: str, abbr: dict) -> list:
    if osym_name in ALIAS_OVERRIDES:
        return list(ALIAS_OVERRIDES[osym_name])
    aliases = []
    key = norm(osym_name)
    ab = abbr.get(key)
    if ab is None:  # boşluk farklarını tolere et (ODTÜ örneği)
        squished = {k.replace(' ', ''): v for k, v in abbr.items()}
        ab = squished.get(key.replace(' ', ''))
    if ab:
        aliases.append(ab)
    # Ayırt edici kelime: 'KOÇ ÜNİVERSİTESİ' → 'Koç'
    words = osym_name.replace('ÜNİVERSİTESİ', '').strip()
    if words and len(words.split()) <= 2:
        pretty = tr_title(words)
        if pretty not in aliases:
            aliases.append(pretty)
    return aliases


VOWELS = 'aeıioöuü'
BACK, ROUNDED = 'aıou', 'oöuü'
HARD_CONS = 'çfhkpsşt'


def _last_vowel(word: str) -> str:
    for ch in reversed(tr_lower(word)):
        if ch in VOWELS:
            return ch
    return 'e'


def tr_genitive(word: str) -> str:
    """İstanbul → İstanbul'un, Ankara → Ankara'nın."""
    v = _last_vowel(word)
    suffix = ('ı' if v in 'aı' else 'u' if v in 'ou' else 'ü' if v in 'öü' else 'i') + 'n'
    buffer = 'n' if tr_lower(word)[-1] in VOWELS else ''
    return f"{word}'{buffer}{suffix}"


def tr_locative(word: str) -> str:
    """Tekirdağ → Tekirdağ'da, Bitlis → Bitlis'te, Kırklareli → Kırklareli'nde."""
    low = tr_lower(word)
    if low.endswith('eli'):  # Kocaeli, Kırklareli: iyelik bileşiği, kaynaştırma alır
        return f"{word}'nde"
    cons = 'd' if low[-1] not in HARD_CONS else 't'
    vowel = 'a' if _last_vowel(word) in BACK else 'e'
    return f"{word}'{cons}{vowel}"


def make_description(display_name: str, city: str, uni_type: str, established) -> str:
    kind = 'devlet' if uni_type == 'Devlet' else 'vakıf'
    if established and established <= 1990:
        return f"{tr_genitive(city)} köklü {kind} üniversitelerinden."
    return f"{tr_locative(city)} eğitim veren {kind} üniversitesi."


def main() -> None:
    selection = json.loads(SELECTION.read_text(encoding='utf-8'))
    abbr = load_abbreviations()
    totals = province_totals()
    brand = json.loads(BRAND_COLORS.read_text(encoding='utf-8')) if BRAND_COLORS.exists() else {}

    cities = extract_dart_list('cities')
    unis = extract_dart_list('universities')
    if not cities or not unis:
        # seed_data_service.dart JSON tabanlı sisteme geçince listeler silindi;
        # v1 kayıtları dondurulmuş snapshot'tan gelir.
        snap = json.loads(
            (Path(__file__).resolve().parent / 'v1_seed_snapshot.json')
            .read_text(encoding='utf-8'))
        cities, unis = snap['cities'], snap['universities']
        print(f'Mevcut seed: {len(unis)} üni, {len(cities)} şehir (v1 snapshot)')
    else:
        print(f'Mevcut seed: {len(unis)} üni, {len(cities)} şehir (Dart\'tan çekildi)')

    existing_ids = {u['id'] for u in unis}
    existing_plates = {c['id'] for c in cities}
    mapping_additions = {}

    for sel in selection['newUniversities']:
        uid = make_id(sel['osymName'], norm(sel['province']), existing_ids)
        existing_ids.add(uid)
        display = tr_title(sel['osymName'])
        city_name = PLATE_DISPLAY[sel['plate']]
        mapping_additions[sel['osymName']] = uid
        unis.append({
            'id': uid,
            'cityId': sel['plate'],
            'name': display,
            'type': sel['type'],
            'hasCampus': True,
            'logoUrl': '',
            'photoUrl': '',
            'description': make_description(display, city_name, sel['type'], sel['established']),
            'establishedYear': sel['established'] or 0,
            'website': clean_website(sel['website']),
            'avgRating': 0.0,
            'reviewCount': 0,
            'categoryRatings': {},
            'campusLayout': 'campus',
            'aliases': make_aliases(sel['osymName'], sel['type'], abbr),
            'brandPrimaryHex': brand.get(uid, [None, None])[0],
            'brandSecondaryHex': brand.get(uid, [None, None])[1],
            '_v2New': True,  # rapor için işaret; yüklemeden önce düşülür
        })

    # Yeni şehirler — foto ve renkler mevcut havuzdan sırayla atanır
    # (mevcut seed'de de şehirler arası foto tekrarı var; kürasyon sonradan).
    photo_pool = sorted({c['photoUrl'] for c in cities if c.get('photoUrl')})
    color_pool = sorted({(c['brandPrimaryHex'], c['brandSecondaryHex'])
                         for c in cities
                         if c.get('brandPrimaryHex') and c.get('brandSecondaryHex')})
    new_plates = [p for p in selection['newCityPlates'] if p not in existing_plates]
    for i, plate in enumerate(sorted(new_plates)):
        colors = color_pool[i % len(color_pool)]
        cities.append({
            'id': plate,
            'name': PLATE_DISPLAY[plate],
            'plateCode': plate,
            'photoUrl': photo_pool[i % len(photo_pool)],
            'totalUniversityCount': 0,
            'appUniversityCount': 0,
            'population': PLATE_POPULATION.get(plate),
            'brandPrimaryHex': colors[0],
            'brandSecondaryHex': colors[1],
            'brandUseDarkOverlay': False,
            '_v2New': True,
        })

    # Şehir sayaçlarını yeniden hesapla (mevcutlar dahil)
    app_counts = Counter(u['cityId'] for u in unis)
    for c in cities:
        c['appUniversityCount'] = app_counts.get(c['id'], 0)
        c['totalUniversityCount'] = totals.get(c['id'], c.get('totalUniversityCount', 0))

    OUT_CITIES.write_text(
        json.dumps({'cities': cities}, ensure_ascii=False, indent=2), encoding='utf-8')
    OUT_UNIS.write_text(
        json.dumps({'universities': unis}, ensure_ascii=False, indent=2), encoding='utf-8')
    OUT_MAPPING.write_text(
        json.dumps(mapping_additions, ensure_ascii=False, indent=2), encoding='utf-8')

    # ── Eksikler raporu ─────────────────────────────────────────────
    new_unis = [u for u in unis if u.get('_v2New')]
    new_cities = [c for c in cities if c.get('_v2New')]
    no_alias = [u for u in new_unis if not u['aliases']]
    lines = [
        '# v2 Eksikler / Gözden Geçirme Raporu',
        '',
        'Otomatik üretilen ama elle gözden geçirilmesi önerilen alanlar.',
        '',
        f'## Yeni şehirler ({len(new_cities)})',
        '- photoUrl ve marka renkleri mevcut havuzdan atandı (placeholder) — kürasyon önerilir',
        '- population yaklaşık TÜİK değerleriyle dolduruldu — hassasiyet gerekirse doğrulanmalı',
        '',
        '| Plaka | Şehir | Üni | photoUrl | renkler |',
        '|---|---|---|---|---|',
    ]
    for c in new_cities:
        lines.append(f"| {c['id']} | {c['name']} | {c['appUniversityCount']} "
                     f"| placeholder | {c['brandPrimaryHex']} |")
    lines += [
        '',
        f'## Yeni üniversiteler ({len(new_unis)})',
        '- campusLayout hepsi `campus` varsayıldı — blok/dağınık yerleşkeliler elle işaretlenmeli',
        '- description şablondan üretildi',
        '- renkler logodan otomatik çıkarıldı (v2_logo_report.md ile birlikte gözden geçir)',
        '',
        '| id | Ad | Alias | Logo | Renkler |',
        '|---|---|---|---|---|',
    ]
    for u in new_unis:
        has_logo = '✓' if (LOGO_DIR / f"{u['id']}.png").exists() else '❌'
        colors = (f"{u['brandPrimaryHex']} {u['brandSecondaryHex']}"
                  if u['brandPrimaryHex'] else '❌')
        lines.append(
            f"| `{u['id']}` | {u['name']} | {', '.join(u['aliases']) or '❌ YOK'} "
            f"| {has_logo} | {colors} |")
    if no_alias:
        lines += ['', f'⚠ Alias üretilemeyen üniler: '
                  + ', '.join(u['name'] for u in no_alias)]
    OUT_REPORT.write_text('\n'.join(lines) + '\n', encoding='utf-8')

    print(f'✔ {len(unis)} üni → {OUT_UNIS}')
    print(f'✔ {len(cities)} şehir → {OUT_CITIES}')
    print(f'✔ {len(mapping_additions)} UNI_MAPPING eki → {OUT_MAPPING}')
    print(f'✔ Eksikler raporu → {OUT_REPORT}')


if __name__ == '__main__':
    sys.exit(main())
