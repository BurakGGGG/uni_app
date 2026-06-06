#!/usr/bin/env python3
"""
KYK Yurt Verisi Merge Scripti
==============================
Scraped verileri mevcut places_seed.json'a entegre eder:
1. Mevcut KYK yurtlarının adres/telefon/koordinat bilgilerini günceller
2. Eşleşmeyen mevcut yurtları fuzzy matching ile eşleştirmeye çalışır
3. Sonuçları raporlar
"""

import json
import re
import os
from difflib import SequenceMatcher

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
SEED_PATH = os.path.join(SCRIPT_DIR, "..", "assets", "data", "places_seed.json")
SCRAPED_PATH = os.path.join(SCRIPT_DIR, "..", "assets", "data", "kyk_dorms_scraped.json")
OUTPUT_PATH = os.path.join(SCRIPT_DIR, "..", "assets", "data", "places_seed.json")

# Üniversite -> Şehir mapping
UNI_CITY = {
    "uludag": "bursa", "btu": "bursa",
    "estu": "eskisehir", "anadolu": "eskisehir", "ogu": "eskisehir",
    "ktu": "trabzon", "trabzon_uni": "trabzon",
    "hitit": "corum",
    "itu": "istanbul", "yildiz_teknik": "istanbul", "marmara": "istanbul",
    "istanbul_uni": "istanbul", "aydin": "istanbul", "medipol": "istanbul", "gelisim": "istanbul",
    "mersin_uni": "mersin", "tarsus": "mersin",
    "akdeniz": "antalya", "alanya": "antalya",
    "comu": "canakkale",
    "cumhuriyet": "sivas", "sivas_btu": "sivas",
    "odtu": "ankara", "ankara_uni": "ankara", "hacettepe": "ankara", "hacibayram": "ankara", "gazi": "ankara",
    "izmir_katipcelebi": "izmir", "dokuz_eylul": "izmir", "ege": "izmir", "izmir_demokrasi": "izmir",
    "erciyes": "kayseri", "inonu": "malatya", "omu": "samsun", "selcuk": "konya",
    "dpu": "kutahya", "kocaeli": "kocaeli", "sakarya": "sakarya", "ibu": "bolu",
    "beun": "zonguldak", "yyu": "van", "atauni": "erzurum", "gantep": "gaziantep",
    "cu": "adana", "pau": "denizli", "ksu": "kahramanmaras", "cbu": "manisa",
    "sdu": "isparta", "karabuk": "karabuk", "gop": "tokat",
}


def normalize(name):
    """Yurt adını normalleştir (karşılaştırma için)."""
    n = name.lower().strip()
    # Yaygın varyasyonları standartlaştır
    n = n.replace("ö", "o").replace("ü", "u").replace("ş", "s").replace("ç", "c").replace("ğ", "g").replace("ı", "i")
    n = re.sub(r'\bkyk\b', '', n)
    n = re.sub(r'\bögrenci\b', '', n)
    n = re.sub(r'\byurdu\b', '', n)
    n = re.sub(r'\bkiz\b', '', n)
    n = re.sub(r'\berkek\b', '', n)
    n = re.sub(r'\bozel\b', '', n)
    n = re.sub(r'\s+', ' ', n).strip()
    return n


def similarity(a, b):
    """İki string arasındaki benzerlik oranı."""
    return SequenceMatcher(None, normalize(a), normalize(b)).ratio()


def find_best_match(existing_name, scraped_dorms, threshold=0.55):
    """Mevcut yurt adı için scraped veriden en iyi eşleşmeyi bul."""
    best_score = 0
    best_match = None
    
    for sd in scraped_dorms:
        score = similarity(existing_name, sd["name"])
        if score > best_score:
            best_score = score
            best_match = sd
    
    if best_score >= threshold:
        return best_match, best_score
    return None, 0


def main():
    # Verileri yükle
    with open(SEED_PATH, "r", encoding="utf-8") as f:
        seed_data = json.load(f)
    
    with open(SCRAPED_PATH, "r", encoding="utf-8") as f:
        scraped_data = json.load(f)
    
    print(f"📦 Mevcut places: {len(seed_data['places'])}")
    print(f"📦 Scraped yurt: {scraped_data['meta']['total_dorms']}")
    
    # Şehir bazlı scraped veri index'i oluştur
    scraped_by_city = {}
    for city_slug, city_info in scraped_data["cities"].items():
        scraped_by_city[city_slug] = city_info["dorms"]
    
    # İstatistikler
    updated = 0
    not_found = 0
    already_has_addr = 0
    matched_names = []
    unmatched = []
    
    # Mevcut KYK yurtlarını güncelle
    for place in seed_data["places"]:
        if place.get("type") != "dorm" or place.get("dormType") != "KYK":
            continue
        
        uid = place.get("universityId", "")
        city_slug = UNI_CITY.get(uid)
        if not city_slug or city_slug not in scraped_by_city:
            continue
        
        city_dorms = scraped_by_city[city_slug]
        match, score = find_best_match(place["name"], city_dorms)
        
        if match:
            # Güncelle
            changed = False
            
            if match.get("address") and not place.get("address"):
                place["address"] = match["address"]
                changed = True
            
            if match.get("phone"):
                place["phone"] = match["phone"]
                changed = True
            
            if match.get("latitude") and match.get("longitude"):
                place["mapUrl"] = f"https://www.google.com/maps?q={match['latitude']},{match['longitude']}"
                changed = True
            
            if match.get("image_url") and not place.get("imageUrls"):
                place["imageUrls"] = [match["image_url"]]
                changed = True
            elif match.get("image_url") and place.get("imageUrls") == []:
                place["imageUrls"] = [match["image_url"]]
                changed = True
            
            if changed:
                updated += 1
                matched_names.append(f"  ✅ {place['name']}  →  {match['name']} ({score:.0%})")
            else:
                already_has_addr += 1
        else:
            not_found += 1
            unmatched.append(f"  ❌ [{uid}] {place['name']}")
    
    # Sonuçları yazdır
    print(f"\n{'='*60}")
    print(f"📊 MERGE SONUÇLARI")
    print(f"{'='*60}")
    print(f"  ✅ Güncellenen:     {updated}")
    print(f"  ⏭️  Zaten güncel:    {already_has_addr}")
    print(f"  ❌ Eşleşmeyen:     {not_found}")
    
    if matched_names:
        print(f"\n📋 Eşleşen Yurtlar:")
        for m in sorted(matched_names):
            print(m)
    
    if unmatched:
        print(f"\n⚠️  Eşleşmeyen Yurtlar:")
        for u in sorted(unmatched):
            print(u)
    
    # Kaydet
    with open(OUTPUT_PATH, "w", encoding="utf-8") as f:
        json.dump(seed_data, f, ensure_ascii=False, indent=2)
    
    print(f"\n💾 Güncellenmiş veri kaydedildi: {OUTPUT_PATH}")
    print(f"   Toplam place: {len(seed_data['places'])}")


if __name__ == "__main__":
    main()
