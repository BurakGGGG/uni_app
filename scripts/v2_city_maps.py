#!/usr/bin/env python3
"""Üni→şehir ve şehir slug haritaları — seed JSON'lardan türetilir.

scrape_kyk.py / merge_kyk_data.py / rebuild_dorms.py içindeki el yazması
UNI_CITY / CITY_NAMES sözlüklerinin yerini alır; üni-şehir listesi artık
assets/data/universities_seed.json + cities_seed.json'dan gelir (v2: 105 üni,
60 şehir). Seed değişince scriptler otomatik güncel kalır.
"""

import json
import os

_DATA = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "assets", "data")


def _fold(name: str) -> str:
    """Şehir adı → kykyurtlar.com slug'ı: 'Şanlıurfa' → 'sanliurfa'."""
    tr = str.maketrans("çğıöşüÇĞİÖŞÜâî", "cgiosuCGIOSUai")
    s = name.translate(tr).lower()
    return "".join(ch for ch in s if ch.isalnum())


def load_maps():
    """(UNI_CITY, CITY_NAMES) döndürür: uni_id→slug, slug→görünen ad."""
    with open(os.path.join(_DATA, "cities_seed.json"), encoding="utf-8") as f:
        cities = json.load(f)["cities"]
    with open(os.path.join(_DATA, "universities_seed.json"), encoding="utf-8") as f:
        unis = json.load(f)["universities"]

    plate_to_slug = {c["id"]: _fold(c["name"]) for c in cities}
    city_names = {_fold(c["name"]): c["name"] for c in cities}
    uni_city = {u["id"]: plate_to_slug[u["cityId"]] for u in unis}
    return uni_city, city_names


UNI_CITY, CITY_NAMES = load_maps()
UNIVERSITY_CITY_MAP = UNI_CITY  # scrape_kyk.py'deki adla uyum

if __name__ == "__main__":
    print(f"{len(UNI_CITY)} üni, {len(CITY_NAMES)} şehir")
    for slug, name in sorted(CITY_NAMES.items()):
        n = sum(1 for v in UNI_CITY.values() if v == slug)
        print(f"  {slug:16} {name:16} {n} üni")
