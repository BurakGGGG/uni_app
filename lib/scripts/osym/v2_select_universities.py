#!/usr/bin/env python3
"""v2 üniversite seçimi — karma strateji.

Hedef: min 100 üniversite, min 50 şehir.
Strateji (kullanıcı onaylı):
  0. Bilinirliği yüksek üniler (Boğaziçi, Koç, Bilkent vb.) her koşulda dahil —
     toplam tercih metriği program sayısıyla korele olduğundan az-programlı
     elit üniler veriyle yakalanamıyor, küratörlü liste şart.
  1. Şehir hedefini garantile: uygulamada olmayan illerden, öğrenci talebine
     (YÖK-Atlas tercih sayıları) göre en güçlü illeri seç; her yeni ilden
     en köklü/büyük üniyi al.
  2. Kalan kotayı ildeki mevcudiyete bakmadan en popüler ünilerle doldur.

Popülerlik metriği: tum_bolumler.csv içindeki tercihtoplam2023'ün üniversite
bazında toplamı (2023'te kaç tercih listesinde yer aldı). Yedek: yerlesen2024.

Çıktılar (bu klasöre):
  v2_selection.json — seçilen ünilerin tam listesi (mevcut + yeni, alanlarla)
  v2_selection.md   — insan gözden geçirmesi için özet tablo
"""

import csv
import json
import sys
import unicodedata
from collections import defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
UNIS_CSV = ROOT / 'taban_puanları' / 'yokatlas-dataset-2025' / 'universiteler.csv'
BOLUMLER_CSV = ROOT / 'taban_puanları' / 'yokatlas-dataset-2025' / 'tum_bolumler.csv'
OUT_DIR = Path(__file__).resolve().parent

# Hedefler (min değerlerin üstünde tampon bırakıyoruz)
TARGET_TOTAL_UNIS = 105
TARGET_TOTAL_CITIES = 52

# ── Mevcut uygulama durumu ─────────────────────────────────────────────
# csv_to_json_parser.py UNI_MAPPING ile birebir aynı (ÖSYM adı → app id)
CURRENT_UNIS = {
    'İSTANBUL TEKNİK ÜNİVERSİTESİ': 'itu',
    'İSTANBUL ÜNİVERSİTESİ': 'istanbul_uni',
    'YILDIZ TEKNİK ÜNİVERSİTESİ': 'yildiz_teknik',
    'ORTA DOĞU TEKNİK ÜNİVERSİTESİ': 'odtu',
    'HACETTEPE ÜNİVERSİTESİ': 'hacettepe',
    'ANKARA ÜNİVERSİTESİ': 'ankara_uni',
    'GAZİ ÜNİVERSİTESİ': 'gazi',
    'EGE ÜNİVERSİTESİ': 'ege',
    'DOKUZ EYLÜL ÜNİVERSİTESİ': 'dokuz_eylul',
    'AKDENİZ ÜNİVERSİTESİ': 'akdeniz',
    'ALANYA ALAADDİN KEYKUBAT ÜNİVERSİTESİ': 'alanya',
    'ANADOLU ÜNİVERSİTESİ': 'anadolu',
    'ESKİŞEHİR OSMANGAZİ ÜNİVERSİTESİ': 'ogu',
    'ESKİŞEHİR TEKNİK ÜNİVERSİTESİ': 'estu',
    'BURSA ULUDAĞ ÜNİVERSİTESİ': 'uludag',
    'BURSA TEKNİK ÜNİVERSİTESİ': 'btu',
    'ÇANAKKALE ONSEKİZ MART ÜNİVERSİTESİ': 'comu',
    'SİVAS CUMHURİYET ÜNİVERSİTESİ': 'cumhuriyet',
    'SİVAS BİLİM VE TEKNOLOJİ ÜNİVERSİTESİ': 'sivas_btu',
    'KARADENİZ TEKNİK ÜNİVERSİTESİ': 'ktu',
    'TRABZON ÜNİVERSİTESİ': 'trabzon_uni',
    'MERSİN ÜNİVERSİTESİ': 'mersin_uni',
    'TARSUS ÜNİVERSİTESİ': 'tarsus',
    'MARMARA ÜNİVERSİTESİ': 'marmara',
    'ANKARA HACI BAYRAM VELİ ÜNİVERSİTESİ': 'hacibayram',
    'İZMİR DEMOKRASİ ÜNİVERSİTESİ': 'izmir_demokrasi',
    'İZMİR KATİP ÇELEBİ ÜNİVERSİTESİ': 'izmir_katipcelebi',
    'İSTANBUL AYDIN ÜNİVERSİTESİ': 'aydin',
    'İSTANBUL GELİŞİM ÜNİVERSİTESİ': 'gelisim',
    'İSTANBUL MEDİPOL ÜNİVERSİTESİ': 'medipol',
    'HİTİT ÜNİVERSİTESİ': 'hitit',
    'ERCİYES ÜNİVERSİTESİ': 'erciyes',
    'İNÖNÜ ÜNİVERSİTESİ': 'inonu',
    'ONDOKUZ MAYIS ÜNİVERSİTESİ': 'omu',
    'SELÇUK ÜNİVERSİTESİ': 'selcuk',
    'KÜTAHYA DUMLUPINAR ÜNİVERSİTESİ': 'dpu',
    'KOCAELİ ÜNİVERSİTESİ': 'kocaeli',
    'SAKARYA ÜNİVERSİTESİ': 'sakarya',
    'BOLU ABANT İZZET BAYSAL ÜNİVERSİTESİ': 'ibu',
    'ZONGULDAK BÜLENT ECEVİT ÜNİVERSİTESİ': 'beun',
    'VAN YÜZÜNCÜ YIL ÜNİVERSİTESİ': 'yyu',
    'ATATÜRK ÜNİVERSİTESİ': 'atauni',
    'GAZİANTEP ÜNİVERSİTESİ': 'gantep',
    'ÇUKUROVA ÜNİVERSİTESİ': 'cu',
    'PAMUKKALE ÜNİVERSİTESİ': 'pau',
    'KAHRAMANMARAŞ SÜTÇÜ İMAM ÜNİVERSİTESİ': 'ksu',
    'MANİSA CELÂL BAYAR ÜNİVERSİTESİ': 'cbu',
    'SÜLEYMAN DEMİREL ÜNİVERSİTESİ': 'sdu',
    'KARABÜK ÜNİVERSİTESİ': 'karabuk',
    'TOKAT GAZİOSMANPAŞA ÜNİVERSİTESİ': 'gop',
}

CURRENT_CITY_PLATES = {
    '34', '06', '35', '07', '26', '16', '17', '58', '61', '33',
    '19', '38', '44', '55', '42', '43', '41', '54', '14', '67',
    '65', '25', '27', '01', '20', '46', '45', '32', '78', '60',
}

# Bilinirliği yüksek, her koşulda dahil edilecek üniler (ÖSYM/YÖK-Atlas adıyla)
MUST_INCLUDE = [
    'BOĞAZİÇİ ÜNİVERSİTESİ',
    'GALATASARAY ÜNİVERSİTESİ',
    'İZMİR YÜKSEK TEKNOLOJİ ENSTİTÜSÜ',
    'MİMAR SİNAN GÜZEL SANATLAR ÜNİVERSİTESİ',
    'İSTANBUL ÜNİVERSİTESİ-CERRAHPAŞA',
    'SAĞLIK BİLİMLERİ ÜNİVERSİTESİ',
    'ANKARA YILDIRIM BEYAZIT ÜNİVERSİTESİ',
    'ANKARA SOSYAL BİLİMLER ÜNİVERSİTESİ',
    'TÜRK-ALMAN ÜNİVERSİTESİ',
    'KOÇ ÜNİVERSİTESİ',
    'SABANCI ÜNİVERSİTESİ',
    'İHSAN DOĞRAMACI BİLKENT ÜNİVERSİTESİ',
    'BAHÇEŞEHİR ÜNİVERSİTESİ',
    'YEDİTEPE ÜNİVERSİTESİ',
    'İSTANBUL BİLGİ ÜNİVERSİTESİ',
    'ÖZYEĞİN ÜNİVERSİTESİ',
    'KADİR HAS ÜNİVERSİTESİ',
    'TOBB EKONOMİ VE TEKNOLOJİ ÜNİVERSİTESİ',
    'BAŞKENT ÜNİVERSİTESİ',
    'ATILIM ÜNİVERSİTESİ',
    'YAŞAR ÜNİVERSİTESİ',
    'İZMİR EKONOMİ ÜNİVERSİTESİ',
]

# 81 il → plaka (YÖK-Atlas büyük harf yazımıyla)
PROVINCE_PLATES = {
    'ADANA': '01', 'ADIYAMAN': '02', 'AFYONKARAHİSAR': '03', 'AĞRI': '04',
    'AMASYA': '05', 'ANKARA': '06', 'ANTALYA': '07', 'ARTVİN': '08',
    'AYDIN': '09', 'BALIKESİR': '10', 'BİLECİK': '11', 'BİNGÖL': '12',
    'BİTLİS': '13', 'BOLU': '14', 'BURDUR': '15', 'BURSA': '16',
    'ÇANAKKALE': '17', 'ÇANKIRI': '18', 'ÇORUM': '19', 'DENİZLİ': '20',
    'DİYARBAKIR': '21', 'EDİRNE': '22', 'ELAZIĞ': '23', 'ERZİNCAN': '24',
    'ERZURUM': '25', 'ESKİŞEHİR': '26', 'GAZİANTEP': '27', 'GİRESUN': '28',
    'GÜMÜŞHANE': '29', 'HAKKARİ': '30', 'HATAY': '31', 'ISPARTA': '32',
    'MERSİN': '33', 'İSTANBUL': '34', 'İZMİR': '35', 'KARS': '36',
    'KASTAMONU': '37', 'KAYSERİ': '38', 'KIRKLARELİ': '39', 'KIRŞEHİR': '40',
    'KOCAELİ': '41', 'KONYA': '42', 'KÜTAHYA': '43', 'MALATYA': '44',
    'MANİSA': '45', 'KAHRAMANMARAŞ': '46', 'MARDİN': '47', 'MUĞLA': '48',
    'MUŞ': '49', 'NEVŞEHİR': '50', 'NİĞDE': '51', 'ORDU': '52',
    'RİZE': '53', 'SAKARYA': '54', 'SAMSUN': '55', 'SİİRT': '56',
    'SİNOP': '57', 'SİVAS': '58', 'TEKİRDAĞ': '59', 'TOKAT': '60',
    'TRABZON': '61', 'TUNCELİ': '62', 'ŞANLIURFA': '63', 'UŞAK': '64',
    'VAN': '65', 'YOZGAT': '66', 'ZONGULDAK': '67', 'AKSARAY': '68',
    'BAYBURT': '69', 'KARAMAN': '70', 'KIRIKKALE': '71', 'BATMAN': '72',
    'ŞIRNAK': '73', 'BARTIN': '74', 'ARDAHAN': '75', 'IĞDIR': '76',
    'YALOVA': '77', 'KARABÜK': '78', 'KİLİS': '79', 'OSMANİYE': '80',
    'DÜZCE': '81',
    # YÖK-Atlas'ta görülebilen alternatif yazımlar
    'AFYON': '03', 'İÇEL': '33', 'K.MARAŞ': '46', 'HAKKARI': '30',
}

# Plaka → il görünen adı (uygulamadaki şehir kayıtlarında kullanılacak yazım)
PLATE_DISPLAY = {
    '01': 'Adana', '02': 'Adıyaman', '03': 'Afyonkarahisar', '04': 'Ağrı',
    '05': 'Amasya', '06': 'Ankara', '07': 'Antalya', '08': 'Artvin',
    '09': 'Aydın', '10': 'Balıkesir', '11': 'Bilecik', '12': 'Bingöl',
    '13': 'Bitlis', '14': 'Bolu', '15': 'Burdur', '16': 'Bursa',
    '17': 'Çanakkale', '18': 'Çankırı', '19': 'Çorum', '20': 'Denizli',
    '21': 'Diyarbakır', '22': 'Edirne', '23': 'Elazığ', '24': 'Erzincan',
    '25': 'Erzurum', '26': 'Eskişehir', '27': 'Gaziantep', '28': 'Giresun',
    '29': 'Gümüşhane', '30': 'Hakkari', '31': 'Hatay', '32': 'Isparta',
    '33': 'Mersin', '34': 'İstanbul', '35': 'İzmir', '36': 'Kars',
    '37': 'Kastamonu', '38': 'Kayseri', '39': 'Kırklareli', '40': 'Kırşehir',
    '41': 'Kocaeli', '42': 'Konya', '43': 'Kütahya', '44': 'Malatya',
    '45': 'Manisa', '46': 'Kahramanmaraş', '47': 'Mardin', '48': 'Muğla',
    '49': 'Muş', '50': 'Nevşehir', '51': 'Niğde', '52': 'Ordu',
    '53': 'Rize', '54': 'Sakarya', '55': 'Samsun', '56': 'Siirt',
    '57': 'Sinop', '58': 'Sivas', '59': 'Tekirdağ', '60': 'Tokat',
    '61': 'Trabzon', '62': 'Tunceli', '63': 'Şanlıurfa', '64': 'Uşak',
    '65': 'Van', '66': 'Yozgat', '67': 'Zonguldak', '68': 'Aksaray',
    '69': 'Bayburt', '70': 'Karaman', '71': 'Kırıkkale', '72': 'Batman',
    '73': 'Şırnak', '74': 'Bartın', '75': 'Ardahan', '76': 'Iğdır',
    '77': 'Yalova', '78': 'Karabük', '79': 'Kilis', '80': 'Osmaniye',
    '81': 'Düzce',
}


def norm(s: str) -> str:
    """Üni adlarını iki dataset arasında eşleştirmek için normalize et."""
    s = s.strip().upper()
    s = s.replace('Â', 'A').replace('Î', 'İ').replace('Û', 'U')
    s = unicodedata.normalize('NFC', s)
    return ' '.join(s.split())


def parse_year(kurulus: str) -> int | None:
    kurulus = kurulus.strip()
    if not kurulus:
        return None
    part = kurulus.split('.')[-1]
    try:
        year = int(part)
    except ValueError:
        return None
    return year if 1200 <= year <= 2026 else None


def safe_float(v: str) -> float:
    try:
        return float(v)
    except (ValueError, TypeError):
        return 0.0


def load_universities() -> list[dict]:
    unis = []
    skipped = []
    with UNIS_CSV.open(encoding='utf-8') as f:
        for row in csv.DictReader(f):
            il = norm(row['il'])
            tur = row['tur'].strip().upper()
            plate = PROVINCE_PLATES.get(il)
            if plate is None or tur not in ('DEVLET', 'VAKIF'):
                skipped.append(f"{row['isim']} (il={row['il']!r}, tur={tur!r})")
                continue
            unis.append({
                'name': row['isim'].strip(),
                'norm_name': norm(row['isim']),
                'slug': row['slug'].strip(),
                'type': 'Devlet' if tur == 'DEVLET' else 'Vakıf',
                'province': il,
                'plate': plate,
                'region': row['bolge'].strip(),
                'website': row['website'].strip(),
                'established': parse_year(row['kurulus']),
                'students_total': int(safe_float(row['toplam'])),
                'students_lisans': int(safe_float(row['lisanstoplam'])),
            })
    if skipped:
        print(f"⚠ universiteler.csv'den atlanan {len(skipped)} kayıt (TR ili değil / tür dışı):")
        for s in skipped:
            print(f"   - {s}")
    return unis


def load_demand() -> tuple[dict, dict]:
    """Üni bazında tercih toplamı (2023) ve yerleşen (2024)."""
    pref = defaultdict(int)
    placed = defaultdict(int)
    with BOLUMLER_CSV.open(encoding='utf-8') as f:
        for row in csv.DictReader(f):
            key = norm(row['universite'])
            pref[key] += int(safe_float(row.get('tercihtoplam2023')))
            placed[key] += int(safe_float(row.get('yerlesen2024')))
    return pref, placed


def main() -> None:
    unis = load_universities()
    pref, placed = load_demand()

    current_norm = {norm(k) for k in CURRENT_UNIS}
    for u in unis:
        u['pref2023'] = pref.get(u['norm_name'], 0)
        u['placed2024'] = placed.get(u['norm_name'], 0)
        u['in_app'] = u['norm_name'] in current_norm

    matched = {u['norm_name'] for u in unis}
    missing_current = current_norm - matched
    if missing_current:
        print(f"⚠ Mevcut {len(missing_current)} üni universiteler.csv ile eşleşmedi:")
        for name in sorted(missing_current):
            print(f"   - {name}")

    no_demand = [u for u in unis if not u['in_app'] and u['pref2023'] == 0 and u['placed2024'] == 0]
    if no_demand:
        print(f"ℹ tercih/yerleşen verisi bulunamayan {len(no_demand)} aday (sıralamada sona düşer)")

    candidates = [u for u in unis if not u['in_app']]

    # Aday sıralama anahtarı: tercih sayısı, eşitlikte yerleşen, sonra öğrenci sayısı
    def demand_key(u):
        return (u['pref2023'], u['placed2024'], u['students_total'])

    # ── 0. Adım: bilinirliği yüksek üniler ──────────────────────────
    selected = []
    must_norm = {norm(n) for n in MUST_INCLUDE}
    unmatched_must = must_norm - {u['norm_name'] for u in candidates}
    if unmatched_must:
        print(f"⚠ MUST_INCLUDE içinden eşleşmeyen {len(unmatched_must)} ad:")
        for name in sorted(unmatched_must):
            print(f"   - {name}")
    for u in candidates:
        if u['norm_name'] in must_norm:
            u['reason'] = 'bilinirlik'
            selected.append(u)

    # ── 1. Adım: şehir kapsama ──────────────────────────────────────
    new_city_count = TARGET_TOTAL_CITIES - len(CURRENT_CITY_PLATES)
    by_province = defaultdict(list)
    for u in candidates:
        by_province[u['plate']].append(u)

    missing_plates = set(by_province) - CURRENT_CITY_PLATES
    # İl gücü: ildeki toplam talep → en güçlü iller önce
    province_strength = {
        p: sum(u['pref2023'] for u in by_province[p]) for p in missing_plates
    }
    chosen_plates = sorted(missing_plates, key=lambda p: province_strength[p], reverse=True)[:new_city_count]

    picked_names = {u['norm_name'] for u in selected}
    for p in chosen_plates:
        # Yeni ilin amiral gemisi: Devlet öncelikli, talep sırasıyla
        pool = [u for u in by_province[p] if u['norm_name'] not in picked_names]
        if not pool:
            continue
        flagship = max(pool, key=lambda u: (u['type'] == 'Devlet', demand_key(u)))
        flagship['reason'] = 'şehir-kapsama'
        selected.append(flagship)
        picked_names.add(flagship['norm_name'])

    # ── 2. Adım: kalan kotayı popüler ünilerle doldur ───────────────
    quota = TARGET_TOTAL_UNIS - len(CURRENT_UNIS) - len(selected)
    rest = sorted(
        (u for u in candidates if u['norm_name'] not in picked_names),
        key=demand_key, reverse=True,
    )
    for u in rest[:quota]:
        u['reason'] = 'popüler'
        selected.append(u)

    # ── Özet ────────────────────────────────────────────────────────
    final_plates = CURRENT_CITY_PLATES | {u['plate'] for u in selected}
    n_total = len(CURRENT_UNIS) + len(selected)
    print(f"\n✔ Seçim: +{len(selected)} yeni üni → toplam {n_total} üni, {len(final_plates)} şehir")
    print(f"   Devlet: {sum(1 for u in selected if u['type'] == 'Devlet')}, "
          f"Vakıf: {sum(1 for u in selected if u['type'] == 'Vakıf')}")

    out = {
        'targets': {'totalUniversities': n_total, 'totalCities': len(final_plates)},
        'currentUniversities': len(CURRENT_UNIS),
        'newUniversities': [
            {
                'osymName': u['name'],
                'slug': u['slug'],
                'type': u['type'],
                'province': u['province'],
                'plate': u['plate'],
                'region': u['region'],
                'website': u['website'],
                'established': u['established'],
                'studentsTotal': u['students_total'],
                'pref2023': u['pref2023'],
                'placed2024': u['placed2024'],
                'reason': u['reason'],
                'newCity': u['plate'] not in CURRENT_CITY_PLATES,
            }
            for u in selected
        ],
        'newCityPlates': sorted({u['plate'] for u in selected} - CURRENT_CITY_PLATES),
    }
    (OUT_DIR / 'v2_selection.json').write_text(
        json.dumps(out, ensure_ascii=False, indent=2), encoding='utf-8')

    lines = [
        '# v2 Aday Listesi',
        '',
        f'Toplam: **{n_total} üni** (50 mevcut + {len(selected)} yeni), '
        f'**{len(final_plates)} şehir** ({len(CURRENT_CITY_PLATES)} mevcut + '
        f'{len(final_plates) - len(CURRENT_CITY_PLATES)} yeni)',
        '',
        '## Yeni üniversiteler',
        '',
        '| # | Üniversite | İl | Tür | Kuruluş | Tercih 2023 | Neden |',
        '|---|---|---|---|---|---|---|',
    ]
    reason_order = {'bilinirlik': 0, 'şehir-kapsama': 1, 'popüler': 2}
    for i, u in enumerate(
            sorted(selected, key=lambda x: (reason_order[x['reason']], -x['pref2023'])), 1):
        city_mark = ' 🆕' if u['plate'] not in CURRENT_CITY_PLATES else ''
        lines.append(
            f"| {i} | {u['name']} | {PLATE_DISPLAY[u['plate']]}{city_mark} | {u['type']} "
            f"| {u['established'] or '?'} | {u['pref2023']:,} | {u['reason']} |")
    lines += ['', '🆕 = uygulamaya yeni eklenen şehir', '']
    (OUT_DIR / 'v2_selection.md').write_text('\n'.join(lines), encoding='utf-8')

    print(f"→ {OUT_DIR / 'v2_selection.json'}")
    print(f"→ {OUT_DIR / 'v2_selection.md'}")


if __name__ == '__main__':
    sys.exit(main())
