#!/usr/bin/env python3
"""
KYK Yurt Veri Çekme Scripti (Optimized)
========================================
kykyurtlar.com'dan KYK yurt verilerini çeker.
Sadece ana şehir sayfası + gerçek ilçe sayfaları taranır (üniversite, apart, pansiyon vb. atlanır).

Kaynak: https://www.kykyurtlar.com/
Veriler GSB KYK web sitesinin kamuya açık bilgilerinden derlenmiştir.
"""

import json
import re
import time
import sys
import os

import requests
from bs4 import BeautifulSoup

# ─── Üniversitelerimiz ve bulundukları şehirler ───────────────────────
UNIVERSITY_CITY_MAP = {
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

CITY_NAMES = {
    "adana": "Adana", "ankara": "Ankara", "antalya": "Antalya", "bolu": "Bolu",
    "bursa": "Bursa", "canakkale": "Çanakkale", "corum": "Çorum", "denizli": "Denizli",
    "erzurum": "Erzurum", "eskisehir": "Eskişehir", "gaziantep": "Gaziantep",
    "isparta": "Isparta", "istanbul": "İstanbul", "izmir": "İzmir",
    "kahramanmaras": "Kahramanmaraş", "karabuk": "Karabük", "kayseri": "Kayseri",
    "kocaeli": "Kocaeli", "konya": "Konya", "kutahya": "Kütahya",
    "malatya": "Malatya", "manisa": "Manisa", "mersin": "Mersin",
    "sakarya": "Sakarya", "samsun": "Samsun", "sivas": "Sivas",
    "tokat": "Tokat", "trabzon": "Trabzon", "van": "Van", "zonguldak": "Zonguldak",
}

BASE_URL = "https://www.kykyurtlar.com"

SESSION = requests.Session()
SESSION.headers.update({
    "User-Agent": "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 "
                  "(KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
    "Accept-Language": "tr-TR,tr;q=0.9",
})


def fetch_page(url, retries=3):
    for attempt in range(retries):
        try:
            resp = SESSION.get(url, timeout=15, allow_redirects=True)
            resp.raise_for_status()
            return resp.text
        except Exception as e:
            print(f"  ⚠ Attempt {attempt+1}/{retries}: {e}")
            if attempt < retries - 1:
                time.sleep(3)
    return None


def parse_dorm_cards(html):
    """article.box kartlarından yurt bilgilerini çıkar."""
    soup = BeautifulSoup(html, "html.parser")
    dorms = []

    for article in soup.select("article.box"):
        dorm = {}

        # İsim: span[itemprop=name]
        name_el = article.select_one("span[itemprop='name']")
        if name_el:
            dorm["name"] = name_el.get_text(strip=True)
        else:
            a = article.select_one("h6.box-title a, h5.box-title a")
            if a:
                dorm["name"] = a.get_text(strip=True)
        if not dorm.get("name"):
            continue

        # Adres: .descp ilk satırı
        descp = article.select_one(".descp")
        if descp:
            raw = descp.get_text(separator="\n", strip=True)
            lines = [l.strip() for l in raw.split("\n") if l.strip()]
            if lines:
                dorm["address"] = lines[0]

        # Telefon: .pc_box .special_note span
        phone_el = article.select_one(".pc_box .special_note a span")
        if phone_el:
            phone = re.sub(r'[^\d\(\)\s\-\+]', '', phone_el.get_text(strip=True)).strip()
            if phone:
                dorm["phone"] = phone
        if not dorm.get("phone"):
            tel = article.select_one("a[href^='tel:']")
            if tel:
                dorm["phone"] = tel["href"].replace("tel:", "").replace("+90", "0")

        # Koordinat: a[href*=google.com/maps] → daddr=lat,lng
        maps_a = article.select_one("a[href*='google.com/maps']")
        if maps_a:
            m = re.search(r'daddr=([\d.\-]+),([\d.\-]+)', maps_a.get("href", ""))
            if m:
                dorm["latitude"] = float(m.group(1))
                dorm["longitude"] = float(m.group(2))

        # Fotoğraf
        img = article.select_one("figure img")
        if img:
            dorm["image_url"] = img.get("data-src") or img.get("src", "")

        # Cinsiyet
        n = dorm["name"].lower()
        if "kız" in n or "kiz" in n:
            dorm["gender"] = "Kız"
        elif "erkek" in n:
            dorm["gender"] = "Erkek"
        else:
            dorm["gender"] = "Karma"

        dorms.append(dorm)

    return dorms


def is_real_district_url(url, city_slug):
    """
    Sadece gerçek ilçe sayfalarını al.
    Format: /{city}-{ilce}-kyk-yurtlari/
    Filtrele: üniversite, apart, pansiyon, rezidans, özel yurt sayfalarını atla.
    """
    path = url.rstrip("/").split("/")[-1]
    
    # Üniversite, apart, pansiyon vb. sayfaları atla
    skip_patterns = [
        "-universitesi-", "-uni-", "-meslek-yuksekokulu-",
        "-apart-", "-pansiyon-", "-rezidans-", "-evleri-",
        "-ozel-yurt-", "-ozel-kiz-", "-ozel-erkek-",
        f"{city_slug}-da-", f"{city_slug}-de-", f"{city_slug}-te-",
        "-meb-", "-academic-house-",
    ]
    for p in skip_patterns:
        if p in path:
            return False
    
    # Format: {city}-{district}-kyk-yurtlari
    if re.match(rf'^{city_slug}-[\w\-]+-kyk-yurtlari$', path):
        return True
    
    return False


def get_district_urls(html, city_slug):
    """Şehir sayfasından gerçek ilçe linklerini çıkar."""
    soup = BeautifulSoup(html, "html.parser")
    urls = set()
    main_url = f"{BASE_URL}/{city_slug}-kyk-yurtlari/"

    for a in soup.select("a[href]"):
        href = a.get("href", "").strip()
        if "-kyk-yurtlari" not in href:
            continue
        if href.startswith("/"):
            full = BASE_URL + href
        elif href.startswith(".."):
            full = BASE_URL + "/" + href.lstrip("./")
        elif href.startswith("http"):
            full = href
        else:
            full = BASE_URL + "/" + href
        full = full.rstrip("/") + "/"

        if full != main_url and city_slug in full and is_real_district_url(full, city_slug):
            urls.add(full)

    return sorted(urls)


def scrape_city(city_slug, city_name):
    print(f"\n{'='*60}")
    print(f"📍 {city_name} ({city_slug})")
    print(f"{'='*60}")

    all_dorms = []
    seen = set()

    main_url = f"{BASE_URL}/{city_slug}-kyk-yurtlari/"
    html = fetch_page(main_url)
    if not html:
        print(f"  ❌ Ana sayfa yüklenemedi!")
        return all_dorms

    # Ana sayfadaki yurtları al
    for d in parse_dorm_cards(html):
        if d["name"] not in seen:
            seen.add(d["name"])
            d["city"] = city_name
            all_dorms.append(d)
    print(f"  Ana sayfa: {len(all_dorms)} yurt")

    # İlçe sayfalarını tara
    district_urls = get_district_urls(html, city_slug)
    if district_urls:
        print(f"  {len(district_urls)} ilçe sayfası")
        for url in district_urls:
            time.sleep(1)
            page = fetch_page(url)
            if not page:
                continue
            new = 0
            for d in parse_dorm_cards(page):
                if d["name"] not in seen:
                    seen.add(d["name"])
                    d["city"] = city_name
                    # İlçe adını URL'den çıkar
                    slug_part = url.rstrip("/").split("/")[-1].replace("-kyk-yurtlari", "")
                    parts = slug_part.split("-")
                    if len(parts) > 1:
                        d["district"] = " ".join(parts[1:]).title()
                    all_dorms.append(d)
                    new += 1
            if new:
                print(f"    +{new} yurt ({url.split('/')[-2]})")

    print(f"  ✅ Toplam: {len(all_dorms)} yurt")
    return all_dorms


def main():
    unique_cities = sorted(set(UNIVERSITY_CITY_MAP.values()))

    print(f"🏠 KYK Yurt Veri Çekme (Optimized)")
    print(f"   {len(unique_cities)} şehir, {len(UNIVERSITY_CITY_MAP)} üniversite\n")

    # Tek şehir testi
    if len(sys.argv) > 1:
        test = sys.argv[1]
        if test in CITY_NAMES:
            dorms = scrape_city(test, CITY_NAMES[test])
            print(f"\n📋 Toplam {len(dorms)} yurt:")
            for d in dorms:
                print(f"  • {d['name']}")
                print(f"    📍 {d.get('address', '-')}")
                print(f"    📞 {d.get('phone', '-')}")
                print(f"    👤 {d.get('gender', '-')}")
                if d.get('latitude'):
                    print(f"    🗺️  {d['latitude']}, {d['longitude']}")
                print()
            return

    all_data = {}
    total = 0

    for city_slug in unique_cities:
        city_name = CITY_NAMES[city_slug]
        dorms = scrape_city(city_slug, city_name)
        all_data[city_slug] = {
            "city_name": city_name,
            "dorm_count": len(dorms),
            "dorms": dorms,
        }
        total += len(dorms)
        time.sleep(1.5)

    # Kaydet
    out = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "assets", "data", "kyk_dorms_scraped.json")
    out = os.path.abspath(out)

    with open(out, "w", encoding="utf-8") as f:
        json.dump({
            "meta": {
                "source": "https://www.kykyurtlar.com/",
                "scraped_at": time.strftime("%Y-%m-%d %H:%M:%S"),
                "total_cities": len(all_data),
                "total_dorms": total,
                "note": "Veriler GSB KYK web sitesinin kamuya açık bilgilerinden derlenmiştir.",
            },
            "cities": all_data,
        }, f, ensure_ascii=False, indent=2)

    print(f"\n{'='*60}")
    print(f"🎉 TAMAMLANDI! {total} yurt, {len(all_data)} şehir")
    print(f"   → {out}")
    print(f"{'='*60}\n")

    print(f"{'Şehir':<22}{'Yurt':>6}")
    print(f"{'-'*28}")
    for s in sorted(all_data.keys()):
        d = all_data[s]
        print(f"{d['city_name']:<22}{d['dorm_count']:>6}")


if __name__ == "__main__":
    main()
