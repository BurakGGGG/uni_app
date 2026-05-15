"""
YÖK Atlas tum_bolumler.csv → assets/data/department_scores.json

Allowlist tabanlı, minimum doküman üretir (Firebase okuma/yazma kotası için).

Kurallar:
- Sadece LISANS_ALLOWLIST + ONLISANS_ALLOWLIST'teki bölümler işlenir.
- Allowlist eşleşmesi (name, scoreType) çiftiyle yapılır → "Sağlık Yönetimi" gibi
  iki puan türünde de geçen programlar için doğru tür alınır.
- Her (uni, dept_name) için TEK doküman yazılır:
    1) aciklama=='' (ana sürüm) > aciklama=='(İngilizce)' tek başına > diğer varyantlar
    2) Aynı tier içinde yüksek puanlıyı tut.
  Böylece devlet üniversitesinde Türkçe versiyonu, vakıfta ise Burslu vb.
  yüksek puanlı varyant seçilir.
- Veteriner → seed slug'ı "veterinerlik" kullanılır.
- Önlisans "İlk ve Acil Yardım" → seed slug'ı "ilk_ve_acil_yardim_paramedik" kullanılır.
- Lisans/Önlisans aynı isim çakışması (Çocuk Gelişimi) önlisansta "_onl" suffix'i ile
  ayrı doküman olur.
- name/faculty/type/language/duration/description JSON'a yazılır → migration metadata olarak set'ler.
"""
import csv
import json
import re
import time
from pathlib import Path
from collections import OrderedDict, defaultdict

CSV_PATH = "/home/burak/uni_app/taban_puanları/yokatlas-dataset-2025/tum_bolumler.csv"
OUTPUT_PATH = "/home/burak/uni_app/assets/data/department_scores.json"

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

# Lisans allowlist: CSV'deki tam isim → izinli puan türleri set'i
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
    'Veteriner': {'SAY'},                # CSV ismi (Veterinerlik DEĞİL)
    'Ebelik': {'SAY'},
    'Gastronomi ve Mutfak Sanatları': {'SÖZ'},
    'Türkçe Öğretmenliği': {'SÖZ'},
    'Çocuk Gelişimi': {'EA'},            # Lisans EA — önlisansla çakışır, _onl ile ayrılır
    'İç Mimarlık ve Çevre Tasarımı': {'EA'},
    'İngilizce Öğretmenliği': {'DİL'},
    'İlköğretim Matematik Öğretmenliği': {'SAY'},
    'Havacılık Yönetimi': {'SAY'},
    'Sağlık Yönetimi': {'SAY', 'EA'},   # Hem SAY hem EA versiyonları var
    'Acil Yardım ve Afet Yönetimi': {'SAY'},
    'İngiliz Dili ve Edebiyatı': {'DİL'},
    'İngilizce Mütercim ve Tercümanlık': {'DİL'},  # CSV "Mütercim-Tercümanlık" yerine
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

# Önlisans allowlist (rövaçtaki 10 program)
ONLISANS_ALLOWLIST = {
    'Bilgisayar Programcılığı': {'TYT'},
    'İlk ve Acil Yardım': {'TYT'},        # Seed slug "ilk_ve_acil_yardim_paramedik"a yazılır
    'Adalet': {'TYT'},
    'Aşçılık': {'TYT'},
    'Lojistik': {'TYT'},
    'Anestezi': {'TYT'},
    'Tıbbi Görüntüleme Teknikleri': {'TYT'},
    'Tıbbi Dokümantasyon ve Sekreterlik': {'TYT'},
    'Dış Ticaret': {'TYT'},
    'Çocuk Gelişimi': {'TYT'},            # önlisans varyantı, _onl suffix ile
}

# CSV ismi → seed slug override (DB'de seed-side slug ile eşleşsin diye)
SEED_SLUG_OVERRIDE_LISANS = {
    'Veteriner': 'veterinerlik',
}
SEED_SLUG_OVERRIDE_ONLISANS = {
    'İlk ve Acil Yardım': 'ilk_ve_acil_yardim_paramedik',
}

# Lisans/Önlisans çakışan isimler (önlisans dokümanına _onl eki gerekir)
ONLISANS_SUFFIX_FOR = {'Çocuk Gelişimi'}

# Skipped: kuruma adına / mesleki kontenjanlar (her zaman atılır)
SKIP_TAGS = {
    'M.T.O.K.',
    'Milli Savunma Bakanlığı Adına',
    'İçişleri Bakanlığı Adına',
}


def slugify(text: str) -> str:
    """Dart toLowerCase mantığıyla uyumlu slug. Türkçe İ/ı ele alınır."""
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
    try:
        return float(val) if val and val.strip() else 0.0
    except Exception:
        return 0.0


def safe_int(val):
    try:
        return int(float(val)) if val and val.strip() else 0
    except Exception:
        return 0


def aciklama_tier(aciklama: str) -> int:
    """Hangi varyant tercihli? Düşük tier = daha tercihli.
    0 = ana versiyon (aciklama yok)
    1 = sadece (İngilizce)
    2 = diğer her şey (Burslu, Ücretli, UOLP, vb.)
    """
    if not aciklama:
        return 0
    if aciklama.strip() == '(İngilizce)':
        return 1
    return 2


def parse_aciklama_language(aciklama: str) -> str:
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


def main():
    print(f"Reading: {CSV_PATH}")

    # candidates[(uni_id, dept_id)] = list of CSV row dicts
    candidates = defaultdict(list)
    csv_total = 0

    with open(CSV_PATH, encoding='utf-8') as f:
        reader = csv.reader(f)
        next(reader)
        for row in reader:
            if len(row) < 159:
                continue
            csv_total += 1

            uni_id = UNI_MAPPING.get(row[2].strip())
            if not uni_id:
                continue

            dept_name = row[1].strip()
            aciklama = row[8].strip()

            if is_skipped(aciklama):
                continue

            base_score = safe_float(row[155])
            if base_score == 0:
                continue

            raw_st = row[4].strip()
            score_type = SCORE_TYPE_MAP.get(raw_st, raw_st)

            is_onlisans = row[11].strip() == '1'

            # Allowlist eşlemesi
            if is_onlisans:
                allowlist = ONLISANS_ALLOWLIST
                slug_override_map = SEED_SLUG_OVERRIDE_ONLISANS
            else:
                allowlist = LISANS_ALLOWLIST
                slug_override_map = SEED_SLUG_OVERRIDE_LISANS

            allowed_types = allowlist.get(dept_name)
            if not allowed_types or score_type not in allowed_types:
                continue

            # DB doc id belirleme
            override_slug = slug_override_map.get(dept_name)
            base_slug = override_slug if override_slug else slugify(dept_name)
            if is_onlisans and dept_name in ONLISANS_SUFFIX_FOR:
                base_slug = base_slug + '_onl'
            dept_id = f'{uni_id}_{base_slug}'

            ranking = safe_int(row[156])
            quota = safe_int(row[150])
            placed = safe_int(row[158])
            faculty = row[7].strip()
            duration = safe_int(row[3]) or (2 if is_onlisans else 4)

            prev = {}
            puan_2023 = safe_float(row[149])
            sira_2023 = safe_int(row[148])
            if puan_2023 > 0:
                prev['2023'] = {'baseScore': puan_2023, 'ranking': sira_2023}
            puan_2022 = safe_float(row[106])
            sira_2022 = safe_int(row[107])
            if puan_2022 > 0:
                prev['2022'] = {'baseScore': puan_2022, 'ranking': sira_2022}

            candidates[(uni_id, dept_id)].append({
                'tier': aciklama_tier(aciklama),
                'baseScore': base_score,
                'language': parse_aciklama_language(aciklama),
                'aciklama': aciklama,
                'name': dept_name,
                'faculty': faculty,
                'type': 'Önlisans' if is_onlisans else 'Lisans',
                'duration': duration,
                'scoreType': score_type,
                'ranking': ranking,
                'quota': quota,
                'placedCount': placed,
                'previousYears': prev,
            })

    # Her (uni, dept_id) için en uygun varyantı seç:
    #   1) En düşük tier (ana > İngilizce > diğerleri)
    #   2) Aynı tier içinde en yüksek baseScore
    out = OrderedDict()
    for (uni_id, dept_id), rows in candidates.items():
        rows.sort(key=lambda r: (r['tier'], -r['baseScore']))
        best = rows[0]

        # Lisans Çocuk Gelişimi vs Önlisans Çocuk Gelişimi: aynı dept_id'ye düşmesin
        # (önlisans için _onl ekledik zaten, çakışma yok)

        out[dept_id] = {
            'deptId': dept_id,
            'universityId': uni_id,
            'name': best['name'],
            'faculty': best['faculty'],
            'type': best['type'],
            'language': best['language'],
            'duration': best['duration'],
            'description': best['aciklama'],
            'year': 2024,
            'scoreType': best['scoreType'],
            'baseScore': best['baseScore'],
            'ranking': best['ranking'],
            'quota': best['quota'],
            'placedCount': best['placedCount'],
            'previousYears': best['previousYears'],
        }

    results = list(out.values())

    output = {
        'version': '2024-3-allowlist',
        'lastUpdated': time.strftime('%Y-%m-%d'),
        'scores': results,
    }

    Path(OUTPUT_PATH).parent.mkdir(parents=True, exist_ok=True)
    Path(OUTPUT_PATH).write_text(
        json.dumps(output, ensure_ascii=False, indent=2), encoding='utf-8'
    )

    print(f"CSV satırı: {csv_total}")
    print(f"Aday (uni, dept) çifti: {len(candidates)}")
    print(f"Yazılan kayıt (her uni-dept tek doküman): {len(results)}")
    print(f"Çıktı: {OUTPUT_PATH}")


if __name__ == '__main__':
    main()
