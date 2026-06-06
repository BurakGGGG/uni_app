#!/usr/bin/env python3
"""
Manuel KYK Yurt Eşleştirme
===========================
Fuzzy matching'in yakalayamadığı yurtları manuel eşleştirir.
Scraped verideki yurt adlarını listeleyerek doğru eşleşmeyi bulmaya çalışır.
"""

import json
import re
import os

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
SEED_PATH = os.path.join(SCRIPT_DIR, "..", "assets", "data", "places_seed.json")
SCRAPED_PATH = os.path.join(SCRIPT_DIR, "..", "assets", "data", "kyk_dorms_scraped.json")

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
}

# Manuel eşleştirme tablosu
# format: "mevcut_yurt_adı": "scraped_yurt_adındaki_anahtar_kelime"
MANUAL_MATCHES = {
    # Bursa
    "Orhangazi KYK Erkek Yurdu": "Orhangazi",
    "Muradiye KYK Erkek Yurdu": "Muradiye",
    # Eskişehir - "Yunus Emre" birden fazla şehirde var, Eskişehir'deki spesifik olanı
    "Muttalip KYK Kız Yurdu": "Muttalip",
    "Ertuğrul Gazi KYK Erkek Yurdu": "Ertuğrul Gazi",
    # Trabzon
    "Trabzon KYK Erkek Yurdu": "Trabzon",
    "Hasan Ali Yücel KYK Erkek Yurdu": "Hasan Ali Yücel",
    # Çorum
    "Akşemseddin KYK": "İskilip",  # İskilip'teki tek yurt
    # İstanbul
    "Sarıyer Bahçeköy KYK Yurdu": "Bahçeköy",
    "Ortaköy KYK Erkek Yurdu": "Cihannüma",  # Ortaköy = Cihannüma bölgesi
    "Ümraniye Çakmak KYK Yurdu": "Çakmak",
    # Mersin
    "Kırkkaşık KYK Kız Yurdu": "Kırkkaşık",
    "Münevver Ayaşlı KYK Kız Yurdu": "Münevver Ayaşlı",
    "İbni Sina KYK Erkek Yurdu": "İbni Sina",
    # Tarsus
    "Tarsus KYK Kız Yurdu (A/B Blok)": "Tarsus Kyk Kız",
    "Beydeğirmeni KYK Kız Yurdu (C Blok)": "Beydeğirmeni",
    "Tozkoparan KYK Erkek Yurdu (C Blok)": "Tozkoparan",
    # Antalya
    "Akdeniz Kız KYK Yurdu": "Akdeniz",
    # Sivas
    "Binali Yıldırım Kampüsü KYK": "Binali Yıldırım",
    "Kadı Burhaneddin KYK Yurdu": "Kadı Burhaneddin",
    "Taha Akgül KYK Yurdu": "Taha Akgül",
    "Binali Yıldırım KYK Kampüsü": "Binali Yıldırım",
    "Kadı Burhaneddin KYK": "Kadı Burhaneddin",
    # Ankara
    "Ankara (Beşevler) KYK": "Beşevler",
    "Ankara (Beşevler) KYK Yurdu": "Beşevler",
    "Sabahat Akşiray KYK": "Sabahat Akşiray",
    "Şenol Yücesoy KYK Yurdu": "Şenol Yücesoy",
    "Başkent KYK Erkek Yurdu": "Başkent",
    "Halide Edip Adıvar KYK Yurdu": "Halide Edip",
    # İzmir
    "Menemen KYK Kız Yurdu": "Menemen",
    "Menemen KYK Erkek Yurdu": "Menemen",
    "Binali Yıldırım KYK Yurdu": "Binali Yıldırım",
    "Buca Erkek KYK Yurdu": "Buca",
    "Ege KYK Kız Yurdu": "Ege",
    "Dokuz Eylül KYK Kız Yurdu": "Dokuz Eylül",
    "Çaka Bey KYK Erkek Yurdu": "Çaka Bey",
    "Balçova KYK Erkek Yurdu": "Balçova",
}


def find_by_keyword(keyword, dorms, gender_hint=None):
    """Scraped veriden anahtar kelimeyle yurt bul."""
    keyword_lower = keyword.lower()
    candidates = []
    
    for d in dorms:
        name_lower = d["name"].lower()
        if keyword_lower in name_lower:
            candidates.append(d)
    
    if len(candidates) == 1:
        return candidates[0]
    
    # Birden fazla sonuç varsa, cinsiyet ile filtrele
    if gender_hint and len(candidates) > 1:
        for c in candidates:
            if gender_hint.lower() in c["name"].lower():
                return c
    
    # İlk sonucu döndür
    if candidates:
        return candidates[0]
    
    return None


def main():
    with open(SEED_PATH, "r", encoding="utf-8") as f:
        seed_data = json.load(f)
    with open(SCRAPED_PATH, "r", encoding="utf-8") as f:
        scraped_data = json.load(f)
    
    scraped_by_city = {}
    for city_slug, city_info in scraped_data["cities"].items():
        scraped_by_city[city_slug] = city_info["dorms"]
    
    updated = 0
    still_unmatched = 0
    
    for place in seed_data["places"]:
        if place.get("type") != "dorm" or place.get("dormType") != "KYK":
            continue
        if place.get("phone"):
            continue  # Zaten eşleşmiş
        
        uid = place.get("universityId", "")
        city_slug = UNI_CITY.get(uid)
        if not city_slug or city_slug not in scraped_by_city:
            still_unmatched += 1
            continue
        
        city_dorms = scraped_by_city[city_slug]
        name = place["name"]
        keyword = MANUAL_MATCHES.get(name)
        
        if not keyword:
            still_unmatched += 1
            print(f"  ❌ Eşleşme tablosunda yok: [{uid}] {name}")
            continue
        
        # Cinsiyet ipucu
        gender_hint = None
        name_lower = name.lower()
        if "kız" in name_lower:
            gender_hint = "kız"
        elif "erkek" in name_lower:
            gender_hint = "erkek"
        
        match = find_by_keyword(keyword, city_dorms, gender_hint)
        
        if match:
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
            if match.get("image_url") and (not place.get("imageUrls") or place["imageUrls"] == []):
                place["imageUrls"] = [match["image_url"]]
                changed = True
            
            if changed:
                updated += 1
                print(f"  ✅ {name} → {match['name']}")
        else:
            still_unmatched += 1
            # Yardımcı: bu şehirde mevcut yurtları listele
            print(f"  ❌ Eşleşme bulunamadı: [{uid}] {name}")
            print(f"     '{keyword}' araması {city_slug}'da sonuç vermedi")
            print(f"     Mevcut yurtlar:")
            for d in city_dorms[:5]:
                print(f"       - {d['name']}")
    
    # Kaydet
    with open(SEED_PATH, "w", encoding="utf-8") as f:
        json.dump(seed_data, f, ensure_ascii=False, indent=2)
    
    print(f"\n{'='*50}")
    print(f"✅ Manuel eşleştirme: {updated} yurt güncellendi")
    print(f"❌ Hâlâ eşleşmeyen: {still_unmatched}")


if __name__ == "__main__":
    main()
