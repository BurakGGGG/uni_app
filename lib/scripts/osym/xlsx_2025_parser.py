"""
2025 ÖSYM Taban Puanları CSV → assets/data/department_scores.json

CSV dosyaları (xlsx'ten dönüştürülmüş) okur, mevcut JSON'daki 2024 verilerini
previousYears'a kaydırır ve 2025 verilerini ana yıl olarak yazar.

Kurallar:
- Sadece LISANS_ALLOWLIST + ONLISANS_ALLOWLIST'teki bölümler işlenir
- Üniversite eşlemesi startswith ile yapılır (2025'te şehir suffix'i var)
- Ranking verisi 2025'te YOK → ranking = 0 olarak yazılır
- Program isminden açıklama ayrıştırılır (parantez içi)
- aciklama_tier mantığı: ana > İngilizce > diğer
- Her (uni, dept_name) için TEK doküman: en uygun varyant seçilir
"""
import csv
import json
import re
import time
from pathlib import Path
from collections import OrderedDict, defaultdict, Counter

LISANS_CSV = "/home/burak/uni_app/taban_puanları/2025_puanları_dataset/lisans.csv"
ONLISANS_CSV = "/home/burak/uni_app/taban_puanları/2025_puanları_dataset/onlisans.csv"
EXISTING_JSON = "/home/burak/uni_app/assets/data/department_scores.json"
OUTPUT_PATH = "/home/burak/uni_app/assets/data/department_scores.json"

# ── Üniversite eşleme ──
UNI_MAPPING = {
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

SCORE_TYPE_MAP = {
    'SAYISAL': 'SAY',
    'EŞİT AĞIRLIK': 'EA',
    'SÖZEL': 'SÖZ',
    'DİL': 'DİL',
    'TYT': 'TYT',
}

LISANS_ALLOWLIST = {
    'Hukuk': {'EA'},
    'Tıp': {'SAY'},
    'Rehberlik ve Psikolojik Danışmanlık': {'EA'},
    'Mimarlık': {'SAY'},
    'İnşaat Mühendisliği': {'SAY'},
    'Diş Hekimliği': {'SAY'},
    'Sınıf Öğretmenliği': {'EA'},
    'Eczacılık': {'SAY'},
    'Psikoloji': {'EA'},
    'Hemşirelik': {'SAY'},
    'Bilgisayar Mühendisliği': {'SAY'},
    'Makine Mühendisliği': {'SAY'},
    'İşletme': {'EA'},
    'Elektrik-Elektronik Mühendisliği': {'SAY'},
    'Fizyoterapi ve Rehabilitasyon': {'SAY'},
    'Endüstri Mühendisliği': {'SAY'},
    'İktisat': {'EA'},
    'Uluslararası İlişkiler': {'EA'},
    'Türk Dili ve Edebiyatı': {'SÖZ'},
    'Özel Eğitim Öğretmenliği': {'SÖZ'},
    'İlahiyat': {'SÖZ'},
    'Okul Öncesi Öğretmenliği': {'SÖZ'},
    'Beslenme ve Diyetetik': {'SAY'},
    'Veteriner': {'SAY'},
    'Ebelik': {'SAY'},
    'Gastronomi ve Mutfak Sanatları': {'SÖZ'},
    'Türkçe Öğretmenliği': {'SÖZ'},
    'Çocuk Gelişimi': {'EA'},
    'İç Mimarlık ve Çevre Tasarımı': {'EA'},
    'İngilizce Öğretmenliği': {'DİL'},
    'İlköğretim Matematik Öğretmenliği': {'SAY'},
    'Havacılık Yönetimi': {'SAY'},
    'Sağlık Yönetimi': {'SAY', 'EA'},
    'Acil Yardım ve Afet Yönetimi': {'SAY'},
    'İngiliz Dili ve Edebiyatı': {'DİL'},
    'İngilizce Mütercim ve Tercümanlık': {'DİL'},
    'Dil ve Konuşma Terapisi': {'SAY'},
    'Mekatronik Mühendisliği': {'SAY'},
    'Fen Bilgisi Öğretmenliği': {'SAY'},
    'Gıda Mühendisliği': {'SAY'},
    'Odyoloji': {'SAY'},
    'Tarımsal Genetik Mühendisliği': {'SAY'},
    'Uçak Mühendisliği': {'SAY'},
    'Maliye': {'EA'},
    'Çalışma Ekonomisi ve Endüstri İlişkileri': {'EA'},
    'Kamu Yönetimi': {'EA'},
    'Sosyal Hizmet': {'EA'},
    'Yönetim Bilişim Sistemleri': {'EA'},
    'Gazetecilik': {'SÖZ'},
    'Radyo, Televizyon ve Sinema': {'SÖZ'},
    'Türk Dili ve Edebiyatı Öğretmenliği': {'SÖZ'},
}

ONLISANS_ALLOWLIST = {
    'Bilgisayar Programcılığı': {'TYT'},
    'İlk ve Acil Yardım': {'TYT'},
    'Adalet': {'TYT'},
    'Aşçılık': {'TYT'},
    'Lojistik': {'TYT'},
    'Anestezi': {'TYT'},
    'Tıbbi Görüntüleme Teknikleri': {'TYT'},
    'Tıbbi Dokümantasyon ve Sekreterlik': {'TYT'},
    'Dış Ticaret': {'TYT'},
    'Çocuk Gelişimi': {'TYT'},
}

SEED_SLUG_OVERRIDE_LISANS = {
    'Veteriner': 'veterinerlik',
}
SEED_SLUG_OVERRIDE_ONLISANS = {
    'İlk ve Acil Yardım': 'ilk_ve_acil_yardim_paramedik',
}

ONLISANS_SUFFIX_FOR = {'Çocuk Gelişimi'}

SKIP_TAGS = {
    'M.T.O.K.',
    'Milli Savunma Bakanlığı Adına',
    'İçişleri Bakanlığı Adına',
    'KKTC Uyruklu',
}


def slugify(text: str) -> str:
    text = text.replace('İ', 'i').replace('I', 'ı')
    text = text.lower()
    repl = {
        'ç': 'c', 'ş': 's', 'ı': 'i', 'ğ': 'g', 'ü': 'u', 'ö': 'o',
        ' ': '_',
    }
    for k, v in repl.items():
        text = text.replace(k, v)
    text = text.replace('(', '').replace(')', '')
    text = re.sub(r'[^a-z0-9_\-]', '', text)
    return text


def safe_float(val):
    if val is None:
        return 0.0
    s = str(val).strip()
    if s in ('--', '', '-', 'None'):
        return 0.0
    try:
        return float(s)
    except Exception:
        return 0.0


def safe_int(val):
    if val is None:
        return 0
    s = str(val).strip()
    if s in ('--', '', '-', 'None'):
        return 0
    try:
        return int(float(s))
    except Exception:
        return 0


def match_uni(excel_name: str) -> str | None:
    excel_name = excel_name.strip()
    if excel_name in UNI_MAPPING:
        return UNI_MAPPING[excel_name]
    for key, slug in UNI_MAPPING.items():
        if excel_name.startswith(key):
            return slug
    return None


def parse_program_name(full_name: str) -> tuple[str, str]:
    """'Bilgisayar Mühendisliği (İngilizce)' → ('Bilgisayar Mühendisliği', '(İngilizce)')"""
    full_name = full_name.strip()
    match = re.match(r'^([^(]+?)(\s*\(.+)$', full_name)
    if match:
        return match.group(1).strip(), match.group(2).strip()
    return full_name, ''


def aciklama_tier(aciklama: str) -> int:
    if not aciklama:
        return 0
    if aciklama.strip() == '(İngilizce)':
        return 1
    return 2


def parse_language(aciklama: str) -> str:
    if not aciklama:
        return 'Türkçe'
    tags = re.findall(r'\(([^)]+)\)', aciklama)
    for tag in tags:
        t = tag.strip()
        if t in {'İngilizce', 'Almanca', 'Fransızca', 'Arapça', 'İspanyolca', 'Rusça'}:
            return t
    return 'Türkçe'


def is_skipped(aciklama: str) -> bool:
    if not aciklama:
        return False
    tags = re.findall(r'\(([^)]+)\)', aciklama)
    return any(t.strip() in SKIP_TAGS for t in tags)


def read_csv(path: str, is_onlisans: bool) -> list[dict]:
    """CSV'den satırları oku. Satır 3 = header satırı, satır 4+ = veri."""
    print(f"  Reading: {path}")
    rows = []

    with open(path, encoding='utf-8') as f:
        reader = list(csv.reader(f))

    # Veri satırları index 3'ten başlar (0=title, 1=sub-header, 2=column names, 3+=data)
    for row in reader[3:]:
        if len(row) < 10:
            continue
        uni_name = (row[2] or '').strip()
        fakulte = (row[3] or '').strip()
        prog_full = (row[4] or '').strip()
        puan_turu = (row[5] or '').strip()
        kontenjan = row[6]
        yerlesen = row[7]
        en_kucuk = row[8]

        if not uni_name or not prog_full:
            continue

        rows.append({
            'uni_name': uni_name,
            'prog_full': prog_full,
            'puan_turu': puan_turu,
            'kontenjan': kontenjan,
            'yerlesen': yerlesen,
            'en_kucuk': en_kucuk,
            'fakulte': fakulte,
            'is_onlisans': is_onlisans,
        })

    print(f"  → {len(rows)} veri satırı okundu")
    return rows


def process_rows(all_rows: list[dict]) -> dict[str, dict]:
    candidates = defaultdict(list)
    skipped_uni = 0
    skipped_allow = 0
    skipped_score = 0
    skipped_tags = 0

    for row in all_rows:
        uni_id = match_uni(row['uni_name'])
        if not uni_id:
            skipped_uni += 1
            continue

        base_name, aciklama = parse_program_name(row['prog_full'])

        if is_skipped(aciklama):
            skipped_tags += 1
            continue

        raw_st = row['puan_turu']
        score_type = SCORE_TYPE_MAP.get(raw_st, raw_st)

        is_onlisans = row['is_onlisans']
        allowlist = ONLISANS_ALLOWLIST if is_onlisans else LISANS_ALLOWLIST
        slug_override_map = SEED_SLUG_OVERRIDE_ONLISANS if is_onlisans else SEED_SLUG_OVERRIDE_LISANS

        allowed_types = allowlist.get(base_name)
        if not allowed_types or score_type not in allowed_types:
            skipped_allow += 1
            continue

        base_score = safe_float(row['en_kucuk'])
        if base_score == 0:
            skipped_score += 1
            continue

        override_slug = slug_override_map.get(base_name)
        base_slug = override_slug if override_slug else slugify(base_name)
        if is_onlisans and base_name in ONLISANS_SUFFIX_FOR:
            base_slug = base_slug + '_onl'
        dept_id = f'{uni_id}_{base_slug}'

        quota = safe_int(row['kontenjan'])
        placed = safe_int(row['yerlesen'])

        candidates[dept_id].append({
            'tier': aciklama_tier(aciklama),
            'baseScore': base_score,
            'language': parse_language(aciklama),
            'aciklama': aciklama,
            'name': base_name,
            'faculty': row['fakulte'],
            'type': 'Önlisans' if is_onlisans else 'Lisans',
            'scoreType': score_type,
            'quota': quota,
            'placedCount': placed,
            'uni_id': uni_id,
            'dept_id': dept_id,
        })

    print(f"\n  Skip stats: uni={skipped_uni}, allowlist={skipped_allow}, "
          f"score=0: {skipped_score}, tags={skipped_tags}")

    best = {}
    for dept_id, rows in candidates.items():
        rows.sort(key=lambda r: (r['tier'], -r['baseScore']))
        best[dept_id] = rows[0]

    return best


def merge_with_existing(new_2025: dict[str, dict], existing_path: str) -> list[dict]:
    with open(existing_path, encoding='utf-8') as f:
        existing = json.load(f)

    existing_scores = {s['deptId']: s for s in existing['scores']}

    results = []
    matched = 0
    new_only = 0
    existing_only = 0
    existing_only_ids = []

    for dept_id, old in existing_scores.items():
        if dept_id in new_2025:
            n = new_2025[dept_id]
            matched += 1

            prev_years = {}
            if 'previousYears' in old and old['previousYears']:
                prev_years.update(old['previousYears'])
            old_year = old.get('year', 2024)
            prev_years[str(old_year)] = {
                'baseScore': old['baseScore'],
                'ranking': old.get('ranking', 0),
            }

            results.append({
                'deptId': dept_id,
                'universityId': n['uni_id'],
                'name': n['name'],
                'faculty': n['faculty'],
                'type': n['type'],
                'language': n['language'],
                'duration': old.get('duration', 2 if n['type'] == 'Önlisans' else 4),
                'description': n['aciklama'],
                'year': 2025,
                'scoreType': n['scoreType'],
                'baseScore': n['baseScore'],
                'ranking': 0,
                'quota': n['quota'],
                'placedCount': n['placedCount'],
                'previousYears': prev_years,
            })
        else:
            existing_only += 1
            existing_only_ids.append(dept_id)
            results.append(old)

    for dept_id, n in new_2025.items():
        if dept_id not in existing_scores:
            new_only += 1
            results.append({
                'deptId': dept_id,
                'universityId': n['uni_id'],
                'name': n['name'],
                'faculty': n['faculty'],
                'type': n['type'],
                'language': n['language'],
                'duration': 2 if n['type'] == 'Önlisans' else 4,
                'description': n['aciklama'],
                'year': 2025,
                'scoreType': n['scoreType'],
                'baseScore': n['baseScore'],
                'ranking': 0,
                'quota': n['quota'],
                'placedCount': n['placedCount'],
                'previousYears': {},
            })

    print(f"\n  Merge stats:")
    print(f"    Matched (2024→2025): {matched}")
    print(f"    Existing only (korunan): {existing_only}")
    if existing_only_ids and existing_only <= 30:
        for eid in existing_only_ids:
            print(f"      - {eid}")
    print(f"    New only (2025'te yeni): {new_only}")
    print(f"    Toplam: {len(results)}")

    return results


def main():
    print("=" * 60)
    print("2025 ÖSYM Taban Puanları Parser (CSV)")
    print("=" * 60)

    print("\n📂 CSV dosyaları okunuyor...")
    lisans_rows = read_csv(LISANS_CSV, is_onlisans=False)
    onlisans_rows = read_csv(ONLISANS_CSV, is_onlisans=True)
    all_rows = lisans_rows + onlisans_rows
    print(f"\n  Toplam satır: {len(all_rows)}")

    print("\n🔍 Filtreleme ve varyant seçimi...")
    best_2025 = process_rows(all_rows)
    print(f"  → {len(best_2025)} benzersiz bölüm bulundu")

    print(f"\n🔄 Mevcut JSON ile merge ediliyor...")
    results = merge_with_existing(best_2025, EXISTING_JSON)

    output = {
        'version': '2025-1-xlsx-merge',
        'lastUpdated': time.strftime('%Y-%m-%d'),
        'scores': results,
    }

    Path(OUTPUT_PATH).parent.mkdir(parents=True, exist_ok=True)
    Path(OUTPUT_PATH).write_text(
        json.dumps(output, ensure_ascii=False, indent=2), encoding='utf-8'
    )

    year_2025 = sum(1 for s in results if s.get('year') == 2025)
    year_2024 = sum(1 for s in results if s.get('year') == 2024)
    with_prev = sum(1 for s in results if s.get('previousYears'))

    print(f"\n{'=' * 60}")
    print(f"✅ TAMAMLANDI")
    print(f"  Çıktı: {OUTPUT_PATH}")
    print(f"  Toplam kayıt: {len(results)}")
    print(f"  2025 yılı: {year_2025}")
    print(f"  2024 yılı (güncellenmemiş): {year_2024}")
    print(f"  previousYears olan: {with_prev}")
    print(f"{'=' * 60}")

    uni_counts = Counter(s['universityId'] for s in results if s.get('year') == 2025)
    print(f"\n📊 2025 güncellenen - Üniversite dağılımı:")
    for uni, cnt in sorted(uni_counts.items()):
        print(f"  {uni}: {cnt}")


if __name__ == '__main__':
    main()
