import csv
import json
import time
from pathlib import Path
import re

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
    'HİTİT ÜNİVERSİTESİ': 'hitit'
}

def slugify(text: str) -> str:
    text = text.lower()
    replacements = {
        'ç': 'c', 'ş': 's', 'ı': 'i', 'ğ': 'g', 'ü': 'u', 'ö': 'o',
        '(': '', ')': '', ' ': '_'
    }
    for k, v in replacements.items():
        text = text.replace(k, v)
    text = re.sub(r'[^a-z0-9_]', '', text)
    return text

def safe_float(val):
    try:
        return float(val) if val.strip() else 0.0
    except:
        return 0.0

def safe_int(val):
    try:
        return int(float(val)) if val.strip() else 0
    except:
        return 0

def main():
    print(f"Parsing {CSV_PATH}...")
    results = []
    
    with open(CSV_PATH, encoding='utf-8') as f:
        reader = csv.reader(f)
        row_count = 0
        matched_count = 0
        
        for row in reader:
            if len(row) < 159:
                continue
            
            row_count += 1
            if row_count == 1 and row[0] == 'id':
                continue # Skip header
                
            uni_name = row[2].strip()
            dept_name = row[1].strip()
            
            # 1. Match University
            uni_id = None
            for key, val in UNI_MAPPING.items():
                if key in uni_name:
                    uni_id = val
                    break
            
            if not uni_id:
                continue
                
            # 2. Match Department slug (to match DB structure)
            dept_slug = slugify(dept_name)
            # Remove "ve_" or "programi" if it disrupts matching but for now simple slug
            # e.g., 'Tip' -> 'tip'
            if 'ingilizce' in dept_slug:
                continue # Skip english variants unless they are the main one, to avoid duplicates for our simple app
            
            dept_db_id = f"{uni_id}_{dept_slug}"
            
            # The indices based on our examination:
            # 105: maxpuan2022
            # 106: puan2022
            # 107: sira2022
            # 108: yerlesme2022
            # 129: kontenjan2023
            # 148: sira2023
            # 149: puan2023
            # 134: yerlesen2023
            # 150: kontenjan2024
            # 155: puan2024
            # 156: sira2024
            # 158: yerlesen2024
            # scoreType -> row[4]
            
            score_type = row[4].strip()
            
            # 2024 Data
            base_score = safe_float(row[155])
            ranking = safe_int(row[156])
            quota = safe_int(row[150])
            placed = safe_int(row[158])
            
            # Skip if no score
            if base_score == 0:
                continue
                
            # Previous Years (2023, 2022)
            prev = {}
            
            puan2023 = safe_float(row[149])
            sira2023 = safe_int(row[148])
            if puan2023 > 0:
                prev["2023"] = {"baseScore": puan2023, "ranking": sira2023}
                
            puan2022 = safe_float(row[106])
            sira2022 = safe_int(row[107])
            if puan2022 > 0:
                prev["2022"] = {"baseScore": puan2022, "ranking": sira2022}
            
            item = {
                "deptId": dept_db_id,
                "year": 2024,
                "scoreType": score_type,
                "baseScore": base_score,
                "ranking": ranking,
                "quota": quota,
                "placedCount": placed,
                "previousYears": prev
            }
            results.append(item)
            matched_count += 1
            
    # Output to JSON
    output_dir = Path(OUTPUT_PATH).parent
    output_dir.mkdir(parents=True, exist_ok=True)
    
    output = {
        "version": "2024-1",
        "lastUpdated": time.strftime("%Y-%m-%d"),
        "scores": results,
    }
    
    Path(OUTPUT_PATH).write_text(
        json.dumps(output, ensure_ascii=False, indent=2), encoding="utf-8"
    )
    
    print(f"✅ Extracted {matched_count} departments.")
    print(f"✅ Data written to {OUTPUT_PATH}")

if __name__ == "__main__":
    main()
