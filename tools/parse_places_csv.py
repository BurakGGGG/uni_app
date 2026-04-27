#!/usr/bin/env python3
"""
Sprint 4 — Place CSV Parser
Mekanları CSV klasör yapısından kanonik JSON'a dönüştürür.

Kullanım:
  python3 tools/parse_places_csv.py \
    --input data/raw/unisec_üniversiteler \
    --output assets/data/places_seed.json
"""
import os, csv, json, re, argparse

# Üniversite adı → ID mapping (Gün 1'de finalize edilen)
UNI_NAME_TO_ID = {
    'BOĞAZİÇİ ÜNİVERSİTESİ': 'bogazici',
    'İSTANBUL TEKNİK ÜNİVERSİTESİ (İTÜ)': 'itu',
    'İSTANBUL ÜNİVERSİTESİ': 'istanbul_uni',
    'YILDIZ TEKNİK ÜNİVERSİTESİ': 'yildiz_teknik',
    'MARMARA ÜNİVERSİTESİ': 'marmara',
    'KOÇ ÜNİVERSİTESİ': 'koc',
    'SABANCI ÜNİVERSİTESİ': 'sabanci',
    'İSTANBUL BİLGİ ÜNİVERSİTESİ': 'bilgi',
    'İSTANBUL AYDIN ÜNİVERSİTESİ': 'aydin',
    'GELİŞİM ÜNİVERSİTESİ': 'gelisim',
    'MEDİPOL ÜNİVERSİTESİ': 'medipol',
    'ODTÜ': 'odtu',
    'HACETTEPE ÜNİVERSİTESİ': 'hacettepe',
    'ANKARA ÜNİVERSİTESİ': 'ankara_uni',
    'GAZİ ÜNİVERSİTESİ': 'gazi',
    'İHSAN DOĞRAMACI BİLKENT ÜNİVERSİTESİ': 'bilkent',
    'ANKARA HACI BAYRAM VELİ ÜNİVERSİTESİ': 'hacibayram',
    'EGE ÜNİVERSİTESİ': 'ege',
    'DOKUZ EYLÜL ÜNİVERSİTESİ': 'dokuz_eylul',
    'İZMİR YÜKSEK TEKNOLOJİ ENSTİTÜSÜ': 'iyte',
    'YAŞAR ÜNİVERSİTESİ': 'yasar',
    'İZMİR DEMOKRASİ ÜNİVERSİTESİ': 'izmir_demokrasi',
    'İZMİR KATİP ÇELEBİ ÜNİVERSİTESİ': 'izmir_katipcelebi',
    'AKDENİZ ÜNİVERSİTESİ': 'akdeniz',
    'ALANYA ALAADDİN KEYKUBAT ÜNİVERSİTESİ': 'alanya',
    'ANADOLU ÜNİVERSİTESİ': 'anadolu',
    'ESKİŞEHİR OSMANGAZİ ÜNİVERSİTESİ': 'ogu',
    'ESKİŞEHİR TEKNİK ÜNİVERSİTESİ': 'estu',
    'BURSA ULUDAĞ ÜNİVERSİTESİ': 'uludag',
    'BURSA TEKNİK ÜNİVERSİTESİ': 'btu',
    'ON SEKİZ MART ÜNİVERSİTESİ': 'comu',
    'SİVAS CUMHURİYET ÜNİVERSİTESİ': 'cumhuriyet',
    'SİVAS BİLİM VE TEKNOLOJİ ÜNİVERSİTESİ': 'sivas_btu',
    'KARADENİZ TEKNİK ÜNİVERSİTESİ': 'ktu',
    'TRABZON ÜNİVERSİTESİ': 'trabzon_uni',
    'MERSİN ÜNİVERSİTESİ': 'mersin_uni',
    'TARSUS ÜNİVERSİTESİ': 'tarsus',
    'HİTİT ÜNİVERSİTESİ': 'hitit',
}

LAYOUT_MAP = {
    'KAMPÜSLÜ': 'campus',
    'BLOK YERLEŞKE': 'block',
    'DAĞINIK KAMPÜS': 'distributed',
    'DAĞINIK KAMPÜSLÜ': 'distributed',
}

PRICE_NORM = {
    'çok ekonomik': '₺',
    'ekonomik': '₺',
    'orta': '₺₺',
    'orta-üst': '₺₺',
    'üst': '₺₺₺',
    'orta / öğrenci dostu': '₺',
}

FILENAME_TYPE_MAP = {
    'kafeler': 'cafe', 'cafeler': 'cafe',
    'yurtlar': 'dorm',
    'kütüphaneler': 'library', 'kütüphane': 'library',
}

def slugify(text):
    if not text: return ''
    tr_map = str.maketrans('çğıöşüÇĞİÖŞÜ', 'cgiosuCGIOSU')
    text = text.translate(tr_map)
    text = re.sub(r'[^a-zA-Z0-9\s]', '', text)
    text = re.sub(r'\s+', '_', text.strip()).lower()
    return text[:60]

def normalize_price(price):
    if not price: return None
    return PRICE_NORM.get(price.strip().lower(), '₺₺')

def parse_kafeler(rows, uni_id):
    places = []
    for row in rows:
        name = row.get('Kafe Adı', '').strip()
        if not name: continue
        location = row.get('Konum', row.get('Konum / Yakınlık', '')).strip()
        why = row.get('Neden Seçmelisin?', row.get('Öne Çıkan Özellikler', '')).strip()
        price = row.get('Fiyat', row.get('Fiyat Seviyesi', '')).strip()
        google_rating = row.get('Google Puanı', '').strip()
        try: gr = float(google_rating) if google_rating else None
        except: gr = None
        slug = slugify(name)
        places.append({
            'id': f"{uni_id}_cafe_{slug}",
            'universityId': uni_id,
            'name': name,
            'type': 'cafe',
            'description': why,
            'address': location,
            'priceRange': normalize_price(price),
            'externalRating': gr,
            'externalRatingSource': 'google' if gr else None,
            'imageUrls': [],
            'amenities': [],
            'openHours': None,
            'mapUrl': None,
            'avgRating': 0.0,
            'reviewCount': 0,
            'categoryRatings': {},
            'isPromoted': False,
            'promotionPriority': 0,
        })
    return places

def parse_yurtlar(rows, uni_id):
    places = []
    for row in rows:
        name = row.get('Yurt Adı', '').strip()
        if not name: continue
        tur = row.get('Tür', '').strip()
        kontenjan = row.get('Kontenjan Tipi', row.get('Kontenjan', '')).strip()
        yakinlik = (row.get('Kampüse Yakınlık / Ulaşım') or
                    row.get('Üniversiteye Mesafe / Ulaşım') or
                    row.get('Kampüse Yakınlık') or '').strip()
        amenities = []
        if 'KYK' in tur.upper(): amenities.append('KYK')
        if 'ÖZEL' in tur.upper() or 'Özel' in tur: amenities.append('Özel Yurt')
        if 'kız' in kontenjan.lower(): amenities.append('Kız Yurdu')
        if 'erkek' in kontenjan.lower(): amenities.append('Erkek Yurdu')
        if 'karma' in kontenjan.lower(): amenities.append('Karma')
        slug = slugify(name)
        places.append({
            'id': f"{uni_id}_dorm_{slug}",
            'universityId': uni_id,
            'name': name,
            'type': 'dorm',
            'description': yakinlik,
            'address': '',
            'priceRange': None,
            'externalRating': None,
            'externalRatingSource': None,
            'imageUrls': [],
            'amenities': amenities,
            'openHours': '7/24',
            'mapUrl': None,
            'dormType': tur,
            'dormGenderType': kontenjan,
            'avgRating': 0.0,
            'reviewCount': 0,
            'categoryRatings': {},
            'isPromoted': False,
            'promotionPriority': 0,
        })
    return places

def parse_kutuphaneler(rows, uni_id):
    places = []
    for row in rows:
        name = row.get('Kütüphane Adı', '').strip()
        if not name: continue
        kutup_tur = row.get('Tür', '').strip()
        konum = row.get('Konum', '').strip()
        saat = row.get('Çalışma Saatleri', row.get('Saat', '')).strip()
        why = row.get('Ders Çalışmaya Uygunluk', '').strip()
        konfor = row.get('Konfor', '').strip()
        sessizlik = row.get('Sessizlik', '').strip()
        zorluk = row.get('Yer Bulma Zorluğu', '').strip()
        desc_parts = []
        if why: desc_parts.append(why)
        elif konfor or sessizlik:
            meta = []
            if konfor: meta.append(f"Konfor: {konfor}")
            if sessizlik: meta.append(f"Sessizlik: {sessizlik}")
            if zorluk: meta.append(f"Yer Bulma: {zorluk}")
            desc_parts.append(' • '.join(meta))
        amenities = []
        if kutup_tur: amenities.append(f"{kutup_tur} Kütüphanesi")
        if 'sessiz' in (sessizlik + zorluk + why).lower(): amenities.append('Sessiz')
        if '7/24' in saat or '24' in saat: amenities.append('7/24 Açık')
        slug = slugify(name)
        places.append({
            'id': f"{uni_id}_lib_{slug}",
            'universityId': uni_id,
            'name': name,
            'type': 'library',
            'description': ' '.join(desc_parts),
            'address': konum,
            'priceRange': None,
            'externalRating': None,
            'externalRatingSource': None,
            'imageUrls': [],
            'amenities': amenities,
            'openHours': saat or None,
            'mapUrl': None,
            'avgRating': 0.0,
            'reviewCount': 0,
            'categoryRatings': {},
            'isPromoted': False,
            'promotionPriority': 0,
        })
    return places

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--input', required=True)
    parser.add_argument('--output', required=True)
    args = parser.parse_args()
    
    all_places = []
    layouts = {}
    unmapped = set()
    
    for city in os.listdir(args.input):
        cp = os.path.join(args.input, city)
        if not os.path.isdir(cp): continue
        for tur in os.listdir(cp):
            tp = os.path.join(cp, tur)
            if not os.path.isdir(tp): continue
            for layout in os.listdir(tp):
                lp = os.path.join(tp, layout)
                if not os.path.isdir(lp): continue
                for uni in os.listdir(lp):
                    up = os.path.join(lp, uni)
                    if not os.path.isdir(up): continue
                    
                    uname = uni.upper().strip()
                    uid = UNI_NAME_TO_ID.get(uname) or UNI_NAME_TO_ID.get(re.sub(r'\s*\([^)]*\)', '', uname).strip())
                    if not uid:
                        unmapped.add(uname)
                        continue
                    
                    layouts[uid] = LAYOUT_MAP.get(layout.upper(), 'campus')
                    
                    for fname in os.listdir(up):
                        fp = os.path.join(up, fname)
                        if not os.path.isfile(fp): continue
                        ptype = FILENAME_TYPE_MAP.get(fname.lower())
                        if not ptype: continue
                        with open(fp, encoding='utf-8') as f:
                            rows = list(csv.DictReader(f))
                        if ptype == 'cafe': places = parse_kafeler(rows, uid)
                        elif ptype == 'dorm': places = parse_yurtlar(rows, uid)
                        elif ptype == 'library': places = parse_kutuphaneler(rows, uid)
                        else: continue
                        all_places.extend(places)
    
    out = {
        'meta': {
            'totalPlaces': len(all_places),
            'totalUniversities': len(layouts),
            'cafeCount': sum(1 for p in all_places if p['type'] == 'cafe'),
            'dormCount': sum(1 for p in all_places if p['type'] == 'dorm'),
            'libraryCount': sum(1 for p in all_places if p['type'] == 'library'),
            'unmappedUniversities': sorted(list(unmapped)),
        },
        'campusLayouts': layouts,
        'places': all_places,
    }
    os.makedirs(os.path.dirname(args.output), exist_ok=True)
    with open(args.output, 'w', encoding='utf-8') as f:
        json.dump(out, f, ensure_ascii=False, indent=2)
    
    print(f"✅ {len(all_places)} mekan parse edildi")
    print(f"  Kafe: {out['meta']['cafeCount']}")
    print(f"  Yurt: {out['meta']['dormCount']}")
    print(f"  Kütüphane: {out['meta']['libraryCount']}")
    print(f"  Üniversite: {len(layouts)}")
    if unmapped:
        print(f"⚠️  Mapped olmayan üniler: {sorted(unmapped)}")
    print(f"📁 Çıktı: {args.output}")

if __name__ == '__main__':
    main()
