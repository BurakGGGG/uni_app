#!/usr/bin/env python3
"""v3 — üniversiteler için Google Place ID çözümleme (tek seferlik backfill).

Places API (New) Text Search ile her üniversitenin place_id'sini bulur.
Place ID saklamak Places politikasına göre serbesttir (yorum/puan saklamak
yasaktır — onlar runtime'da canlı çekilir, bkz. getGoogleReviews CF).

Kullanım:
  GOOGLE_MAPS_API_KEY=... python3 lib/scripts/osym/v3_resolve_place_ids.py

Not: alan maskesi displayName/formattedAddress içerdiği için çağrılar
Text Search Pro SKU'suna girer (5.000/ay ücretsiz) — 105 tek seferlik
çağrı ücretsiz kotanın çok altında.

Çıktılar:
  assets/data/universities_seed.json      — üni başına "googlePlaceId" alanı
  lib/scripts/osym/v3_place_ids.json      — {appId: placeId} (Node uploader girdisi)
  lib/scripts/osym/v3_place_id_report.md  — eşleşme raporu; düşük güvenliler
                                            "ELLE KONTROL" işaretli

googlePlaceId'si zaten dolu olan üniler atlanır (yeniden çözmek için seed'deki
alanı sil).
"""

import difflib
import json
import os
import sys
import time
import unicodedata
from pathlib import Path

import requests

ROOT = Path(__file__).resolve().parents[3]
SEED = ROOT / 'assets' / 'data' / 'universities_seed.json'
CITIES = ROOT / 'assets' / 'data' / 'cities_seed.json'
OUT_IDS = Path(__file__).resolve().parent / 'v3_place_ids.json'
OUT_REPORT = Path(__file__).resolve().parent / 'v3_place_id_report.md'

SEARCH_URL = 'https://places.googleapis.com/v1/places:searchText'
FIELD_MASK = 'places.id,places.displayName,places.formattedAddress,places.types'


def norm(s: str) -> str:
    """v2_select_universities.py ile aynı ad normalizasyonu."""
    s = s.strip().upper()
    s = s.replace('Â', 'A').replace('Î', 'İ').replace('Û', 'U')
    s = unicodedata.normalize('NFC', s)
    return ' '.join(s.split())


def similarity(a: str, b: str) -> float:
    return difflib.SequenceMatcher(None, norm(a), norm(b)).ratio()


def search_places(api_key: str, query: str) -> list[dict]:
    # Geçici DNS/ağ hatalarına karşı 3 deneme (sandbox ortamında DNS oynak).
    last_err: Exception | None = None
    for attempt in range(3):
        try:
            r = requests.post(
                SEARCH_URL,
                headers={
                    'X-Goog-Api-Key': api_key,
                    'X-Goog-FieldMask': FIELD_MASK,
                    'Content-Type': 'application/json',
                },
                json={'textQuery': query, 'languageCode': 'tr', 'regionCode': 'TR'},
                timeout=30,
            )
            r.raise_for_status()
            return r.json().get('places', [])
        except requests.RequestException as e:
            last_err = e
            time.sleep(1.5 * (attempt + 1))
    raise last_err  # type: ignore[misc]


def pick_candidate(uni: dict, city_name: str, places: list[dict]) -> tuple[dict | None, float, bool]:
    """En iyi adayı (place, ad benzerliği, şehir tutuyor mu) olarak döndür."""
    best, best_sim, best_city_ok = None, 0.0, False
    names = [uni['name']] + uni.get('aliases', [])
    for place in places[:5]:
        display = place.get('displayName', {}).get('text', '')
        addr = place.get('formattedAddress', '')
        sim = max(similarity(n, display) for n in names)
        city_ok = norm(city_name) in norm(addr)
        # Şehri tutan adayı, tutmayan biraz daha benzer adaya tercih et
        score = sim + (0.15 if city_ok else 0.0)
        if score > best_sim + (0.15 if best_city_ok else 0.0):
            best, best_sim, best_city_ok = place, sim, city_ok
    return best, best_sim, best_city_ok


def confidence(sim: float, city_ok: bool, is_university_type: bool) -> str:
    if sim >= 0.85 and city_ok:
        return 'YÜKSEK'
    if sim >= 0.70 and (city_ok or is_university_type):
        return 'ORTA'
    return 'DÜŞÜK'


def main() -> int:
    api_key = os.environ.get('GOOGLE_MAPS_API_KEY', '').strip()
    if not api_key:
        print('HATA: GOOGLE_MAPS_API_KEY ortam değişkeni gerekli.', file=sys.stderr)
        return 1

    seed = json.loads(SEED.read_text(encoding='utf-8'))
    unis = seed['universities']
    cities = json.loads(CITIES.read_text(encoding='utf-8'))['cities']
    city_names = {c['id']: c['name'] for c in cities}

    place_ids: dict[str, str] = {}
    rows: list[dict] = []
    for uni in unis:
        if uni.get('googlePlaceId'):
            place_ids[uni['id']] = uni['googlePlaceId']
            continue

        city_name = city_names.get(uni['cityId'], '')
        query = f"{uni['name']} {city_name}"
        try:
            places = search_places(api_key, query)
        except requests.RequestException as e:
            print(f"  !! {uni['id']}: istek hatası: {e}", file=sys.stderr)
            rows.append({'uni': uni, 'place': None, 'sim': 0.0,
                         'city_ok': False, 'conf': 'HATA'})
            continue

        place, sim, city_ok = pick_candidate(uni, city_name, places)
        if place is None:
            print(f"  -- {uni['id']}: sonuç yok ({query})")
            rows.append({'uni': uni, 'place': None, 'sim': 0.0,
                         'city_ok': False, 'conf': 'BULUNAMADI'})
            continue

        is_uni_type = 'university' in place.get('types', [])
        conf = confidence(sim, city_ok, is_uni_type)
        uni['googlePlaceId'] = place['id']
        place_ids[uni['id']] = place['id']
        rows.append({'uni': uni, 'place': place, 'sim': sim,
                     'city_ok': city_ok, 'conf': conf})
        print(f"  {conf:9s} {uni['id']:24s} -> "
              f"{place.get('displayName', {}).get('text', '')} (benzerlik {sim:.2f})")
        time.sleep(0.2)

    SEED.write_text(
        json.dumps(seed, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    OUT_IDS.write_text(
        json.dumps(place_ids, ensure_ascii=False, indent=2, sort_keys=True) + '\n',
        encoding='utf-8')

    manual = [r for r in rows if r['conf'] not in ('YÜKSEK',)]
    lines = [
        '# v3 Place ID eşleşme raporu',
        '',
        f'Toplam: {len(rows)} çözümlendi, {len(manual)} elle kontrol gerektiriyor '
        f'(DÜŞÜK/ORTA/BULUNAMADI/HATA).',
        '',
        '| Güven | App ID | Üniversite | Google eşleşmesi | Adres | Benzerlik | Doğrula |',
        '|---|---|---|---|---|---|---|',
    ]
    for r in sorted(rows, key=lambda r: ({'DÜŞÜK': 0, 'BULUNAMADI': 0, 'HATA': 0,
                                          'ORTA': 1, 'YÜKSEK': 2}[r['conf']], r['uni']['id'])):
        uni, place = r['uni'], r['place']
        flag = 'ELLE KONTROL — ' if r['conf'] != 'YÜKSEK' else ''
        if place is None:
            lines.append(f"| {flag}{r['conf']} | {uni['id']} | {uni['name']} | — | — | — | — |")
            continue
        display = place.get('displayName', {}).get('text', '').replace('|', '/')
        addr = place.get('formattedAddress', '').replace('|', '/')
        link = f"https://www.google.com/maps/place/?q=place_id:{place['id']}"
        lines.append(
            f"| {flag}{r['conf']} | {uni['id']} | {uni['name']} | {display} | {addr} "
            f"| {r['sim']:.2f} | [Haritada aç]({link}) |")
    OUT_REPORT.write_text('\n'.join(lines) + '\n', encoding='utf-8')

    print(f"\nSeed güncellendi: {SEED}")
    print(f"ID haritası: {OUT_IDS}")
    print(f"Rapor: {OUT_REPORT}  (elle kontrol: {len(manual)})")
    return 0


if __name__ == '__main__':
    sys.exit(main())
