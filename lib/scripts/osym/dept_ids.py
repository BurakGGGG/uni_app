"""Bölüm doc id üretimi — tek doğruluk kaynağı.

Prod Firestore'daki doc id'ler (yorum bağları nedeniyle) birebir korunmak
zorunda; HEAD verisi iki nesil slugify karışımı olduğundan mevcut id'ler
legacy_dept_ids.json haritasıyla aynen korunur, yalnızca YENİ dokümanlar
buradaki slugify ile üretilir. (bkz. v2_extract_allowlist.py)
"""

import json
import re
from pathlib import Path

LEGACY_DEPT_IDS = json.loads(
    (Path(__file__).resolve().parent / 'legacy_dept_ids.json').read_text(encoding='utf-8'))

# id → 'name|tür' (çakışma guard'ı için ters harita)
_LEGACY_ID_OWNERS = {v: k.split('|', 1)[1] for k, v in LEGACY_DEPT_IDS.items()}

# CSV ismi → seed slug override (DB'de seed-side slug ile eşleşsin diye)
SEED_SLUG_OVERRIDE_LISANS = {
    'Veteriner': 'veterinerlik',
}
SEED_SLUG_OVERRIDE_ONLISANS = {
    'İlk ve Acil Yardım': 'ilk_ve_acil_yardim_paramedik',
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


def make_dept_id(uni_id: str, name: str, is_onlisans: bool, suffix_names) -> str:
    """Doc id: önce prod'daki mevcut id, yoksa deterministik yeni id."""
    dtype = 'Önlisans' if is_onlisans else 'Lisans'
    legacy = LEGACY_DEPT_IDS.get(f'{uni_id}|{name}|{dtype}')
    if legacy:
        return legacy

    override_map = SEED_SLUG_OVERRIDE_ONLISANS if is_onlisans else SEED_SLUG_OVERRIDE_LISANS
    slug = override_map.get(name) or slugify(name)
    if is_onlisans and name in suffix_names:
        slug += '_onl'
    dept_id = f'{uni_id}_{slug}'

    # Yeni id, farklı bir (ad|tür)'e ait legacy id'ye çarpıyorsa ayrıştır
    # (örn. legacy önlisans 'x_pazarlama' varken yeni lisans Pazarlama gelirse)
    owner = _LEGACY_ID_OWNERS.get(dept_id)
    if owner and owner != f'{name}|{dtype}':
        dept_id += '_onl' if is_onlisans else '_ls'
    return dept_id
