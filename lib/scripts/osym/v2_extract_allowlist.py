#!/usr/bin/env python3
"""Üretimdeki geniş bölüm kataloğundan allowlist çıkarır.

c97bb6b1 ile yayına giren department_scores.json 211 bölüm adı içerir;
parser'lardaki eski 57 adlık el yazması allowlist bunun gerisinde kalmıştı.
Bu script HEAD'deki veriden (name, tür) → puan türleri haritasını üretir;
parser'lar bunu wide_allowlist.json'dan yükler. Böylece v2'de yeni üniler
eklenirken mevcut ünilerin katalog genişliği korunur.

Kullanım: python3 v2_extract_allowlist.py [ref]   (varsayılan ref: HEAD)
"""

import json
import subprocess
import sys
from collections import defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
OUT = Path(__file__).resolve().parent / 'wide_allowlist.json'
OUT_IDS = Path(__file__).resolve().parent / 'legacy_dept_ids.json'

# Sabancı fakülte-bazlı alım programları HEAD verisinde yoktur (üni yeni
# ekleniyor) — allowlist'e elle eklenir.
EXTRA_LISANS = {
    'Mühendislik ve Doğa Bilimleri Programları': ['SAY'],
    'Sanat ve Sosyal Bilimler Programları': ['EA'],
    'Yönetim Bilimleri Programları': ['EA'],
}


def main() -> None:
    ref = sys.argv[1] if len(sys.argv) > 1 else 'HEAD'
    raw = subprocess.run(
        ['git', 'show', f'{ref}:assets/data/department_scores.json'],
        capture_output=True, text=True, check=True, cwd=ROOT,
    ).stdout
    scores = json.loads(raw)['scores']

    lisans = defaultdict(set)
    onlisans = defaultdict(set)
    for s in scores:
        st = s.get('scoreType')
        if not st:
            continue
        (onlisans if s.get('type') == 'Önlisans' else lisans)[s['name']].add(st)

    for name, types in EXTRA_LISANS.items():
        lisans[name].update(types)

    out = {
        'sourceRef': ref,
        'lisans': {k: sorted(v) for k, v in sorted(lisans.items())},
        'onlisans': {k: sorted(v) for k, v in sorted(onlisans.items())},
    }
    OUT.write_text(json.dumps(out, ensure_ascii=False, indent=2), encoding='utf-8')
    print(f'✔ lisans: {len(lisans)} ad, önlisans: {len(onlisans)} ad → {OUT}')
    both = set(lisans) & set(onlisans)
    print(f'  lisans+önlisans çakışan adlar ({len(both)}): {sorted(both)}')

    # Prod Firestore'daki doc id'ler korunmak zorunda (yorum bağları vb.):
    # HEAD verisi iki nesil slugify karışımı olduğundan id'ler algoritmayla
    # değil, birebir haritayla korunur.
    legacy = {}
    for s in scores:
        key = f"{s['universityId']}|{s['name']}|{s.get('type', 'Lisans')}"
        if key in legacy and legacy[key] != s['deptId']:
            print(f"⚠ aynı anahtar iki id: {key} → {legacy[key]} / {s['deptId']}")
        legacy[key] = s['deptId']
    OUT_IDS.write_text(json.dumps(legacy, ensure_ascii=False, indent=2), encoding='utf-8')
    print(f'✔ {len(legacy)} korunan doc id → {OUT_IDS}')


if __name__ == '__main__':
    main()
