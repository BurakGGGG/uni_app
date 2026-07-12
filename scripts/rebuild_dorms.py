#!/usr/bin/env python3
"""
KYK Yurt Verisi Yeniden Oluşturma
===================================
1. places_seed.json'dan TÜM dorm kayıtlarını siler
2. Scraped verileri doğru formatta ekler
3. Her şehirdeki yurtları, o şehirdeki TÜM üniversitelere atar
"""

import json
import re
import os

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
SEED_PATH = os.path.join(SCRIPT_DIR, "..", "assets", "data", "places_seed.json")
SCRAPED_PATH = os.path.join(SCRIPT_DIR, "..", "assets", "data", "kyk_dorms_scraped.json")

# Üni→şehir eşlemesi seed JSON'lardan türetilir
from v2_city_maps import UNI_CITY


def slugify(text):
    """Türkçe metni slug'a çevir."""
    tr_map = str.maketrans("çğıöşüÇĞİÖŞÜ", "cgiosuCGIOSU")
    s = text.translate(tr_map).lower()
    s = re.sub(r'[^a-z0-9\s]', '', s)
    s = re.sub(r'\s+', '_', s).strip('_')
    return s


def generate_dorm_id(uni_id, dorm_name):
    """Yurt için benzersiz ID üret."""
    slug = slugify(dorm_name)
    # Çok uzunsa kısalt
    if len(slug) > 50:
        slug = slug[:50]
    return f"{uni_id}_dorm_{slug}"


def detect_gender(name):
    """Yurt adından cinsiyet belirle."""
    n = name.lower()
    if "kız" in n or "kiz" in n:
        return "Kız"
    elif "erkek" in n:
        return "Erkek"
    elif "karma" in n or "kız ve erkek" in n or "kiz ve erkek" in n:
        return "Karma"
    else:
        return "Karma"


def scraped_to_place(dorm, uni_id):
    """Scraped yurt verisini PlaceModel formatına çevir."""
    name = dorm["name"]
    gender = detect_gender(name)
    
    # Amenities
    amenities = ["KYK"]
    if gender == "Kız":
        amenities.append("Kız Yurdu")
    elif gender == "Erkek":
        amenities.append("Erkek Yurdu")
    else:
        amenities.append("Karma Yurt")
    
    # MapUrl
    map_url = None
    if dorm.get("latitude") and dorm.get("longitude"):
        map_url = f"https://www.google.com/maps?q={dorm['latitude']},{dorm['longitude']}"
    
    # Image URLs
    image_urls = []
    if dorm.get("image_url"):
        image_urls = [dorm["image_url"]]
    
    # Adres
    address = dorm.get("address", "")
    if not address:
        # Şehir bilgisini kullan
        address = dorm.get("city", "")
    
    # Açıklama oluştur
    district = dorm.get("district", "")
    city = dorm.get("city", "")
    desc_parts = []
    if district:
        desc_parts.append(f"{district}/{city}")
    elif city:
        desc_parts.append(city)
    desc_parts.append(f"KYK {gender} Yurdu")
    description = " - ".join(desc_parts)
    
    place = {
        "id": generate_dorm_id(uni_id, name),
        "universityId": uni_id,
        "name": name,
        "type": "dorm",
        "description": description,
        "address": address,
        "priceRange": None,
        "externalRating": None,
        "externalRatingSource": None,
        "imageUrls": image_urls,
        "amenities": amenities,
        "openHours": "7/24",
        "mapUrl": map_url,
        "dormType": "KYK",
        "dormGenderType": gender,
        "avgRating": 0.0,
        "reviewCount": 0,
        "categoryRatings": {},
        "isPromoted": False,
        "promotionPriority": 0,
    }
    
    # Telefon
    if dorm.get("phone"):
        place["phone"] = dorm["phone"]
    
    return place


def main():
    # Verileri yükle
    with open(SEED_PATH, "r", encoding="utf-8") as f:
        seed_data = json.load(f)
    with open(SCRAPED_PATH, "r", encoding="utf-8") as f:
        scraped_data = json.load(f)
    
    # 1. Eski tüm dorm kayıtlarını sil
    old_count = sum(1 for p in seed_data["places"] if p["type"] == "dorm")
    non_dorm_places = [p for p in seed_data["places"] if p["type"] != "dorm"]
    print(f"🗑️  {old_count} eski yurt kaydı silindi")
    print(f"📦 {len(non_dorm_places)} dorm-dışı kayıt korundu")
    
    # 2. Şehir → üniversiteler eşlemesi oluştur
    city_to_unis = {}
    for uni_id, city_slug in UNI_CITY.items():
        if city_slug not in city_to_unis:
            city_to_unis[city_slug] = []
        city_to_unis[city_slug].append(uni_id)
    
    # 3. Scraped verileri PlaceModel formatına çevir
    new_dorms = []
    seen_ids = set()
    
    for city_slug, city_info in scraped_data["cities"].items():
        uni_ids = city_to_unis.get(city_slug, [])
        if not uni_ids:
            continue
        
        dorms = city_info["dorms"]
        print(f"\n📍 {city_info['city_name']} ({city_slug}): {len(dorms)} yurt → {len(uni_ids)} üniversite")
        
        for dorm in dorms:
            for uni_id in uni_ids:
                place = scraped_to_place(dorm, uni_id)
                
                # ID çakışmasını önle
                if place["id"] in seen_ids:
                    place["id"] += f"_{uni_id[-3:]}"
                seen_ids.add(place["id"])
                
                new_dorms.append(place)
        
        for uid in uni_ids:
            count = sum(1 for d in new_dorms if d["universityId"] == uid)
            # sadece son eklenenler
    
    # 4. Birleştir
    all_places = non_dorm_places + new_dorms
    
    # 5. Meta güncelle
    dorm_count = sum(1 for p in all_places if p["type"] == "dorm")
    cafe_count = sum(1 for p in all_places if p["type"] == "cafe")
    library_count = sum(1 for p in all_places if p["type"] == "library")
    
    seed_data["meta"]["totalPlaces"] = len(all_places)
    seed_data["meta"]["dormCount"] = dorm_count
    seed_data["meta"]["cafeCount"] = cafe_count
    seed_data["meta"]["libraryCount"] = library_count
    seed_data["places"] = all_places
    
    # 6. Kaydet
    with open(SEED_PATH, "w", encoding="utf-8") as f:
        json.dump(seed_data, f, ensure_ascii=False, indent=2)
    
    # Özet
    print(f"\n{'='*60}")
    print(f"🎉 YENİDEN OLUŞTURMA TAMAMLANDI!")
    print(f"{'='*60}")
    print(f"  Eski yurt sayısı:      {old_count}")
    print(f"  Yeni yurt sayısı:      {dorm_count}")
    print(f"  Toplam place sayısı:   {len(all_places)}")
    print(f"  Kafe sayısı:           {cafe_count}")
    print(f"  Kütüphane sayısı:      {library_count}")
    
    # Üniversite bazlı dağılım
    from collections import Counter
    uni_counts = Counter(p["universityId"] for p in all_places if p["type"] == "dorm")
    print(f"\n📊 Üniversite Bazlı Yurt Dağılımı:")
    print(f"{'Üniversite':<22}{'Yurt':>6}")
    print(f"{'-'*28}")
    for uid in sorted(uni_counts.keys()):
        print(f"  {uid:<20}{uni_counts[uid]:>6}")
    
    # Veri kalitesi
    phones = sum(1 for p in all_places if p["type"] == "dorm" and p.get("phone"))
    addrs = sum(1 for p in all_places if p["type"] == "dorm" and p.get("address") and p["address"].strip())
    maps = sum(1 for p in all_places if p["type"] == "dorm" and p.get("mapUrl"))
    imgs = sum(1 for p in all_places if p["type"] == "dorm" and p.get("imageUrls"))
    
    print(f"\n📊 Veri Kalitesi:")
    print(f"  Telefon:    {phones}/{dorm_count} ({100*phones//dorm_count}%)")
    print(f"  Adres:      {addrs}/{dorm_count} ({100*addrs//dorm_count}%)")
    print(f"  Harita:     {maps}/{dorm_count} ({100*maps//dorm_count}%)")
    print(f"  Fotoğraf:   {imgs}/{dorm_count} ({100*imgs//dorm_count}%)")


if __name__ == "__main__":
    main()
