# 🎯 Sprint 4.5 — Ara Sprint
## Bölüm Puanları, Tercih Listeleri & AI Tercih Robotu

> **Süre**: 17 iş günü (~2.5 hafta) — esnek, gerekirse 3 haftaya uzayabilir
> **Takım**: 2 kişi (Kişi A & Kişi B) paralel çalışma
> **Hedef**: Sprint 5 (yayın) öncesi uygulamanın "asıl ihtiyacı" olan ÖSYM puan verisini sisteme entegre etmek + tercih liste sistemi + AI tercih robotu eklemek + tüm uygulamayı optimize etmek
> **Tarih aralığı (öneri)**: Mayıs ortası → Haziran başı

---

## 📋 İçindekiler

1. [Sprint Hedefleri ve Başarı Kriterleri](#1-sprint-hedefleri)
2. [Mimari Genel Bakış](#2-mimari-genel-bakış)
3. [Görev Paylaşımı (Kişi A / Kişi B)](#3-görev-paylaşımı)
4. [Conflict Yönetimi Protokolü](#4-conflict-yönetimi)
5. [D1 — ÖSYM Puan Çekme Sistemi (Kişi A)](#5-d1--ösym-puan-çekme-sistemi)
6. [D2 — Bölüm Kartı UI Yenileme (Kişi A)](#6-d2--bölüm-kartı-ui-yenileme)
7. [D3 — Tercih Listeleri Sistemi (Kişi B)](#7-d3--tercih-listeleri-sistemi)
8. [D4 — AI Tercih Robotu (Kişi B)](#8-d4--ai-tercih-robotu)
9. [D5 — Genel Optimizasyon (Ortak)](#9-d5--genel-optimizasyon)
10. [Gün Gün Takvim](#10-gün-gün-takvim)
11. [Test Stratejisi](#11-test-stratejisi)
12. [Sprint Sonu Definition of Done](#12-sprint-sonu-definition-of-done)
13. [Riskler ve Çözümler](#13-riskler-ve-çözümler)

---

## 1. Sprint Hedefleri

### 🎯 Ana Hedefler

| # | Hedef | Sahibi | Başarı Kriteri |
|---|-------|--------|----------------|
| D1 | Gerçek ÖSYM/YÖK Atlas verisini sisteme entegre etmek | Kişi A | 30 üni × 10 bölüm = 300 bölümde 2024 taban puanı, sıralama, kontenjan + 2 yıllık trend |
| D2 | Bölüm kartı UI'sını puan + sıralama + trend gösterimine adapte etmek | Kişi A | Bölüm listesi, detay ve karşılaştırma ekranlarında yeni veriler görünür ve şık |
| D3 | Kullanıcı tercih listeleri (oluştur/düzenle/paylaş) | Kişi B | Kullanıcı en az 1 liste oluşturabilir, public link ile paylaşabilir |
| D4 | AI Tercih Robotu — anasayfa hero banner'a bağlı | Kişi B | 5–8 soruluk akış sonunda en az 3 öneri (üni / şehir / bölüm) |
| D5 | Genel performans optimizasyonu | Ortak | İlk açılış < 2.5 sn, tab geçişi < 200ms, Firestore okuma -%30 |

### 🚦 Olmazsa Olmazlar (P0)

- ✅ 2024 yılı taban puanı, sıralama, kontenjan, yerleşen sayısı (en az 300 kayıt)
- ✅ Tercih listesi CRUD + paylaşım URL'si
- ✅ AI Robot demo akışı (en az 5 soru, kural tabanlı)
- ✅ Mevcut özelliklerden hiçbiri bozulmamış olmalı (regression testleri geçer)

### 🎁 Olursa İyi Olur (P1)

- 🔵 2022, 2023 yılları trend grafiği (3 yıllık çizgi grafik)
- 🔵 Tercih listesi içinde öneriler (AI Robot tetiklenebilir)
- 🔵 AI Robot için Claude API entegrasyonu (kural tabanlı yerine)
- 🔵 Tercih listesinde sürükle-bırak sıralama

### ❌ Bu Sprintte YOK

- ❌ Mezun verileri / iş istihdam verileri
- ❌ Yıllar arası dinamik karşılaştırma (eklenebilir ama Sprint 5'e bırakılabilir)
- ❌ Kayıtlı tercih listelerine yorum yazma sistemi

---

## 2. Mimari Genel Bakış

### 2.1 Yeni Klasör Yapısı

Mevcut `lib/features/` altında **2 yeni feature** ve **1 yeni script** eklenecek:

```
lib/
├── features/
│   ├── ... (mevcut)
│   ├── preference_lists/         ← YENİ (Kişi B)
│   │   ├── data/
│   │   │   └── preference_list_repository.dart
│   │   ├── domain/
│   │   │   └── models/
│   │   │       └── preference_list_model.dart
│   │   └── presentation/
│   │       ├── providers/
│   │       │   └── preference_list_providers.dart
│   │       ├── screens/
│   │       │   ├── my_lists_screen.dart
│   │       │   ├── list_detail_screen.dart
│   │       │   ├── list_edit_screen.dart
│   │       │   └── shared_list_screen.dart
│   │       └── widgets/
│   │           ├── list_card.dart
│   │           ├── list_item_tile.dart
│   │           └── share_list_sheet.dart
│   │
│   ├── recommendation/            ← YENİ (Kişi B)
│   │   ├── data/
│   │   │   └── recommendation_engine.dart
│   │   ├── domain/
│   │   │   ├── models/
│   │   │   │   ├── recommendation_question.dart
│   │   │   │   ├── recommendation_answer.dart
│   │   │   │   └── recommendation_result.dart
│   │   │   └── question_bank.dart
│   │   └── presentation/
│   │       ├── providers/
│   │       │   └── recommendation_providers.dart
│   │       ├── screens/
│   │       │   ├── recommendation_intro_screen.dart
│   │       │   ├── recommendation_chat_screen.dart
│   │       │   └── recommendation_result_screen.dart
│   │       └── widgets/
│   │           ├── chat_bubble.dart
│   │           ├── option_chip.dart
│   │           └── result_card.dart
│   │
│   └── university/
│       ├── data/
│       │   └── university_repository.dart  ← güncellenecek (Kişi A)
│       ├── domain/models/
│       │   └── department_model.dart       ← genişletilecek (Kişi A)
│       └── presentation/
│           ├── screens/
│           │   ├── department_detail_screen.dart  ← yenilenecek (Kişi A)
│           │   └── uni_departments_screen.dart    ← yenilenecek (Kişi A)
│           └── widgets/
│               ├── department_card.dart            ← YENİ (Kişi A)
│               ├── score_trend_chart.dart          ← YENİ (Kişi A)
│               └── score_badge.dart                ← YENİ (Kişi A)
│
├── scripts/
│   ├── ... (mevcut)
│   ├── department_scores_migration.dart   ← YENİ (Kişi A)
│   └── osym/                                ← YENİ (Kişi A)
│       ├── scrape_yokatlas.py              ← Python scraper
│       ├── department_scores.json          ← Çıktı
│       └── README.md                        ← Kullanım kılavuzu
│
└── assets/
    └── data/
        └── department_scores.json          ← Kopya (migration için)
```

### 2.2 Yeni Firestore Koleksiyonları

```
firestore/
├── ... (mevcut)
├── departments/{deptId}                    ← Mevcut, ALANLAR genişletilecek
│   ├── ... (mevcut alanlar)
│   ├── scoreData: {                         ← YENİ
│   │     baseScore: number,
│   │     ranking: number,
│   │     quota: number,
│   │     placedCount: number,
│   │     scoreType: string,
│   │     year: number,
│   │     previousYears: { 2023: {...}, 2022: {...} }
│   │   }
│   └── lastScoreUpdate: timestamp
│
├── preferenceLists/{listId}                 ← YENİ
│   ├── userId: string
│   ├── userName: string
│   ├── title: string
│   ├── description: string
│   ├── isPublic: boolean
│   ├── shareSlug: string                    (5 karakterli kısa kod)
│   ├── viewCount: number
│   ├── items: [{                            (max 24 öğe — ÖSYM kuralı)
│   │     deptId: string,
│   │     uniId: string,
│   │     order: number,
│   │     note: string?
│   │   }]
│   ├── createdAt: timestamp
│   └── updatedAt: timestamp
│
└── userPreferenceListsCount/{userId}        ← YENİ
    └── count: number  (max 10 list/user — limit)
```

### 2.3 Yeni Route'lar

```dart
// lib/router/app_router.dart içine eklenecek route'lar

// Kişi B — Preference Lists
'/my-lists'                            // Kendi listelerim
'/my-lists/new'                        // Yeni liste oluştur
'/my-lists/:listId'                    // Liste detayı (kendi)
'/my-lists/:listId/edit'               // Liste düzenle
'/list/:shareSlug'                     // Public paylaşım sayfası
                                       // (route param olarak slug kullanır)

// Kişi B — Recommendation
'/recommend'                           // AI Robot intro
'/recommend/chat'                      // Soru-cevap akışı
'/recommend/result'                    // Sonuç ekranı
```

### 2.4 Bottom Navigation Değişikliği

```
ÖNCESİ:                          SONRASI:
[Ana Sayfa]                      [Ana Sayfa]
[Keşfet]                         [Keşfet]
[Karşılaştır]                    [Karşılaştır]
[Favoriler]      ─────────►      [Tercih Listelerim]   ← favoriler buraya taşındı
[Profil]                         [Profil]
                                  └─ Favoriler artık profil > "Favorilerim" linkinden
```

> **NOT**: `/favorites` route'u kalmaya devam edecek, sadece bottom nav'dan kaldırılacak ve profil ekranından erişilecek. Favoriler özelliği silinmeyecek.

### 2.5 Ana Sayfa Hero Banner Değişikliği

`HomeScreen` içindeki `_HeroBanner` widget'ı tıklanabilir olacak ve `/recommend`'e gidecek. Mevcut "Keşfet →" yazısı kalacak ama artık AI Robot'a yönlendirecek.

---

## 3. Görev Paylaşımı

Conflict riskini minimize etmek için **dosya bazlı net ayrım** yapıyoruz. Her kişi farklı feature klasörlerinde çalışıyor; paylaşılan dosyalar için ise **merge protokolü** var (Bölüm 4).

### 👤 Kişi A — "Veri & UI"
**Sahip olduğu klasörler:**
- `lib/scripts/osym/` (yeni)
- `lib/scripts/department_scores_migration.dart` (yeni)
- `lib/features/university/domain/models/department_model.dart` (genişletme)
- `lib/features/university/data/university_repository.dart` (genişletme)
- `lib/features/university/presentation/widgets/department_card.dart` (yeni)
- `lib/features/university/presentation/widgets/score_trend_chart.dart` (yeni)
- `lib/features/university/presentation/widgets/score_badge.dart` (yeni)
- `lib/features/university/presentation/screens/department_detail_screen.dart` (yenileme)
- `lib/features/university/presentation/screens/uni_departments_screen.dart` (yenileme)
- `lib/features/comparison/` içinde **sadece** bölüm karşılaştırma istatistikleri (Sprint 4'tekiler kalır, üstüne ekleme)
- `assets/data/department_scores.json` (yeni)
- `pubspec.yaml` — `fl_chart` zaten var, başka paket eklenmez

**Görev özeti:**
1. YÖK Atlas Python scraper yaz → JSON üret
2. JSON'u Firestore'a yükleyen Dart migration script yaz
3. `DepartmentModel`'i genişlet (scoreData alanı)
4. `DepartmentCard` widget'ı oluştur
5. `ScoreTrendChart` widget'ı oluştur (3 yıllık çizgi grafik)
6. `ScoreBadge` widget'ı oluştur (puan + sıralama rozeti)
7. `department_detail_screen` ve `uni_departments_screen`'leri yeni UI'a uyarla

### 👤 Kişi B — "Tercih Listeleri & AI Robot"
**Sahip olduğu klasörler:**
- `lib/features/preference_lists/` (yeni — tüm klasör)
- `lib/features/recommendation/` (yeni — tüm klasör)
- `firestore.rules` içinde sadece preferenceLists kuralları
- `firestore.indexes.json` içinde sadece preferenceLists indeksleri

**Görev özeti:**
1. `PreferenceListModel` + `PreferenceListRepository` yaz
2. `MyListsScreen`, `ListDetailScreen`, `ListEditScreen` ekranları
3. Public paylaşım: slug üretme + `SharedListScreen` (auth gerekmez)
4. AI Robot için soru bankası (kural tabanlı, 8 soru)
5. `RecommendationEngine` (puanlama algoritması)
6. Soru-cevap UI (chat tarzı), sonuç ekranı

### 🤝 Ortak Sorumluluk

Aşağıdaki dosyalar **iki kişi de dokunacak** — merge protokolü uygulanır (Bölüm 4):

| Dosya | Kişi A'nın değişikliği | Kişi B'nin değişikliği |
|-------|------------------------|------------------------|
| `lib/router/app_router.dart` | Yok | 6 yeni route ekleme |
| `lib/router/app_shell.dart` | Yok | Bottom nav: Favoriler → Tercih Listeleri |
| `lib/features/profile/presentation/screens/profile_screen.dart` | Yok | "Favorilerim" linki ekleme |
| `lib/features/home/presentation/screens/home_screen.dart` | Yok | Hero banner tıklanabilir |
| `firestore.indexes.json` | departments için index yok (mevcut yeterli) | preferenceLists için 2 index |
| `firestore.rules` | departments için rules zaten var | preferenceLists rules ekleme |
| `pubspec.yaml` | Yok | `share_plus` zaten var, ek paket gerekmiyor |

---

## 4. Conflict Yönetimi Protokolü

### 4.1 Branch Stratejisi

```
main
├── dev (entegrasyon branch'i — her iki kişi de buraya merge eder)
│   ├── feature/A-osym-data-import         (Kişi A)
│   ├── feature/A-department-card-ui       (Kişi A)
│   ├── feature/B-preference-lists         (Kişi B)
│   └── feature/B-recommendation-bot       (Kişi B)
└── release/sprint-4.5 (sprint sonu, dev'den oluşturulur)
```

### 4.2 Paylaşılan Dosya Düzenleme Kuralları

#### Kural 1: "Önce iletişim, sonra commit"
Paylaşılan bir dosyaya dokunmadan önce **diğer kişiye mesaj at** (Discord/Slack):
> "router'a 3 route ekleyeceğim, 10 dakika bekle, ben push ettikten sonra pull al"

#### Kural 2: Paylaşılan dosyalar için "saat dilimleri"
Çakışmayı sıfıra indirmek için:
- **Sabah (09:00–13:00)** — Kişi A paylaşılan dosyalara dokunabilir
- **Öğleden sonra (13:00–18:00)** — Kişi B paylaşılan dosyalara dokunabilir
- Acil durumda diğer kişiye haber verilir

#### Kural 3: Router'da "yer rezervasyonu" yorumları

`app_router.dart` içinde aşağıdaki yorum bloklarını kullanacağız. Her kişi sadece kendi bloğuna route ekler:

```dart
// ─── KİŞİ A ROUTE'LARI (Bölüm Sayfaları) ─────────────────
// Bu blok içine sadece Kişi A ekleme yapar.
// Bölüm detay, taban puan trend modal vs.
// (mevcut bölüm route'ları zaten var, üstüne ekleme yapılır)

// ─── KİŞİ B — PREFERENCE LISTS ROUTE'LARI ─────────────────
// /my-lists, /my-lists/new, /my-lists/:id, /list/:shareSlug
// (Bu blok aşağıda)
GoRoute(path: '/my-lists', builder: ...),
GoRoute(path: '/my-lists/new', builder: ...),
GoRoute(path: '/my-lists/:listId', builder: ...),
GoRoute(path: '/list/:shareSlug', builder: ...),

// ─── KİŞİ B — RECOMMENDATION ROUTE'LARI ───────────────────
GoRoute(path: '/recommend', builder: ...),
GoRoute(path: '/recommend/chat', builder: ...),
GoRoute(path: '/recommend/result', builder: ...),
```

#### Kural 4: `firestore.indexes.json` ve `firestore.rules`

Bu iki dosya `JSON` ve metin tabanlı. Kişi B sprint sonuna doğru tek seferde günceller (kuralları yazar, indeksleri ekler) ve PR açar. Kişi A inceleme yapar.

#### Kural 5: Çakışma çıkarsa
1. Önce git pull yap (rebase ile, merge değil): `git pull --rebase origin dev`
2. Çakışma metni dikkatlice oku — paylaşılan dosyada ise diğer kişiyle birlikte çöz
3. Asla `git checkout --ours` veya `--theirs` ile otomatik çözüm yapma
4. Çözümden sonra: `flutter analyze` ve `flutter test` mutlaka çalıştırılır

### 4.3 Daily Sync (15 dakikalık günlük toplantı)

Her sabah 09:30:
- Dün ne yaptın?
- Bugün ne yapacaksın?
- Bugün hangi paylaşılan dosyaya dokunacaksın? (rezervasyon)
- Engelin var mı?

### 4.4 PR (Pull Request) Süreci
- Her görev kendi branch'inde gelişir
- Görev bitince `dev`'e PR açılır
- Diğer kişi review yapar (15 dakika max)
- CI yeşil olduktan sonra merge

---

## 5. D1 — ÖSYM Puan Çekme Sistemi

> **Sahibi**: Kişi A
> **Süre**: 4 gün (Gün 1–4)
> **Risk**: ⚠️ YÜKSEK — YÖK Atlas yapısı değişebilir, scraping yasal hassas konu

### 5.1 Veri Kaynağı Seçimi

#### Karşılaştırma

| Yaklaşım | Kalite | Hız | Yasal Risk | Yedek Plan |
|----------|--------|-----|------------|------------|
| **A) YÖK Atlas scraping** | ⭐⭐⭐⭐⭐ | Yıllık 1 kez ~10 dk | Düşük (public veri) | — |
| **B) Manuel CSV doldurma** | ⭐⭐⭐⭐ | 1 gün insan emeği | Yok | A başarısız olursa |
| **C) ÖSYM PDF parse** | ⭐⭐⭐ | Karmaşık | Yok | — |

**Karar**: **A → B fallback**. Önce scraping deneriz, çalışmazsa manuel doldururuz.

> ⚠️ **HUKUKİ NOT**: YÖK Atlas verileri kamuya açık ve resmi kaynak. Scraping fiilen yasal ama "robots.txt" kontrol edilmeli; rate limit'e (saniyede 1 istek) uyulmalı; ticari kullanım için YÖK'e haber verilmeli (uygulama yayına çıkmadan önce).

### 5.2 Python Scraper

`lib/scripts/osym/scrape_yokatlas.py`

```python
"""
YÖK Atlas'tan bölüm taban puanlarını çeker.
Kullanım: python3 scrape_yokatlas.py --year 2024 --output department_scores.json
Ön koşul: pip install requests beautifulsoup4 tqdm
"""

import argparse
import json
import time
from pathlib import Path
from typing import Optional

import requests
from bs4 import BeautifulSoup
from tqdm import tqdm

# 30 üniversite × 10 bölüm için YÖK Atlas program ID eşleşmesi
# Bu eşleşme manuel olarak hazırlanmalı (1 sefer)
# Format: { "deptId": "yokatlas_program_id" }
DEPARTMENT_MAPPING = {
    # Örnek (gerçekleri YÖK Atlas URL'lerinden alınır):
    # https://yokatlas.yok.gov.tr/lisans.php?y=104111719  → 104111719
    "odtu_bilgisayar_muhendisligi": "104111719",
    "odtu_elektrik_elektronik_muhendisligi": "104110281",
    "itu_bilgisayar_muhendisligi": "105210277",
    # ... (manuel olarak doldurulacak — 300 satır)
}

YOKATLAS_BASE = "https://yokatlas.yok.gov.tr"
USER_AGENT = "Mozilla/5.0 (UniSec/1.0; +https://unisec.app)"
DELAY_SEC = 1.0  # Saniyede 1 istek

def fetch_program(program_id: str, year: int) -> Optional[dict]:
    """Tek bir program için detay sayfasını çeker."""
    url = f"{YOKATLAS_BASE}/{'lisans' if not program_id.startswith('1') else 'lisans'}.php?y={program_id}"
    if year != 2024:
        # Önceki yıllar için farklı URL: lisans-onlisans.php?y=...&yil=2023
        url += f"&yil={year}"

    try:
        resp = requests.get(url, headers={"User-Agent": USER_AGENT}, timeout=15)
        resp.raise_for_status()
    except requests.RequestException as e:
        print(f"  ❌ Hata ({program_id}): {e}")
        return None

    soup = BeautifulSoup(resp.text, "html.parser")
    try:
        # YÖK Atlas'ın HTML yapısı sürekli değişebilir; CSS selector'ları
        # gerçek tarama anında doğrulanmalı.
        base_score = _safe_float(soup.select_one("td.taban-puan").text)
        ranking = _safe_int(soup.select_one("td.basari-sirasi").text)
        quota = _safe_int(soup.select_one("td.kontenjan").text)
        placed = _safe_int(soup.select_one("td.yerlesen").text)
        score_type = soup.select_one("td.puan-turu").text.strip()

        return {
            "year": year,
            "baseScore": base_score,
            "ranking": ranking,
            "quota": quota,
            "placedCount": placed,
            "scoreType": score_type,
        }
    except (AttributeError, ValueError) as e:
        print(f"  ⚠️ Parse hatası ({program_id}): {e}")
        return None


def _safe_float(s: str) -> float:
    return float(s.strip().replace(",", ".").replace(" ", ""))


def _safe_int(s: str) -> int:
    return int(s.strip().replace(".", "").replace(",", ""))


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--years", nargs="+", type=int, default=[2024, 2023, 2022])
    parser.add_argument("--output", default="department_scores.json")
    parser.add_argument("--mapping", default="dept_mapping.json",
                        help="deptId -> yokatlas_program_id eşleşmesi")
    args = parser.parse_args()

    # Eşleşmeyi oku
    mapping_path = Path(args.mapping)
    if mapping_path.exists():
        DEPARTMENT_MAPPING.update(json.loads(mapping_path.read_text(encoding="utf-8")))
    print(f"📋 {len(DEPARTMENT_MAPPING)} bölüm eşleşmesi var")

    results = []
    for dept_id, program_id in tqdm(DEPARTMENT_MAPPING.items(), desc="Bölümler"):
        item = {"deptId": dept_id, "previousYears": {}}
        for year in args.years:
            data = fetch_program(program_id, year)
            time.sleep(DELAY_SEC)
            if not data:
                continue
            if year == max(args.years):
                # En güncel yıl ana veri
                item.update({k: v for k, v in data.items() if k != "year"})
                item["year"] = year
            else:
                item["previousYears"][str(year)] = {
                    "baseScore": data["baseScore"],
                    "ranking": data["ranking"],
                }
        if item.get("baseScore"):
            results.append(item)

    # Kaydet
    output = {
        "version": f"{max(args.years)}-1",
        "lastUpdated": time.strftime("%Y-%m-%d"),
        "scores": results,
    }
    Path(args.output).write_text(
        json.dumps(output, ensure_ascii=False, indent=2), encoding="utf-8"
    )
    print(f"✅ {len(results)} kayıt {args.output} dosyasına yazıldı")


if __name__ == "__main__":
    main()
```

### 5.3 Eşleşme Tablosu — `dept_mapping.json`

YÖK Atlas'ın URL'lerinden program ID'leri **manuel olarak** çıkarılmalı. Örneğin ODTÜ Bilgisayar Mühendisliği için:

1. https://yokatlas.yok.gov.tr/tercih-sihirbazi.php
2. ODTÜ → Bilgisayar Mühendisliği → URL'den `y=104111719` parametresi
3. Bu ID'yi `dept_mapping.json`'a ekle

```json
{
  "odtu_bilgisayar_muhendisligi": "104111719",
  "odtu_elektrik_elektronik_muhendisligi": "104110281",
  "itu_bilgisayar_muhendisligi": "105210277",
  "...": "..."
}
```

> 💡 **Pratik tavsiye**: Bu eşleşmeyi tek seferde, 1 saatlik focused work ile çıkarın. 300 ID için Excel'de tablo tutun, sonra JSON'a dönüştürün.

### 5.4 Çıktı Formatı — `department_scores.json`

```json
{
  "version": "2024-1",
  "lastUpdated": "2025-08-15",
  "scores": [
    {
      "deptId": "odtu_bilgisayar_muhendisligi",
      "year": 2024,
      "scoreType": "SAY",
      "baseScore": 547.32,
      "ranking": 856,
      "quota": 120,
      "placedCount": 120,
      "previousYears": {
        "2023": { "baseScore": 540.18, "ranking": 1200 },
        "2022": { "baseScore": 535.45, "ranking": 1450 }
      }
    }
  ]
}
```

### 5.5 `DepartmentModel` Genişletmesi

`lib/features/university/domain/models/department_model.dart` dosyasına yeni alanlar:

```dart
class DepartmentModel {
  // ... mevcut alanlar

  // ── YENİ: Sprint 4.5 ──────────────────────────────────
  final DepartmentScoreData? scoreData;
  final DateTime? lastScoreUpdate;

  DepartmentModel({
    // ... mevcut
    this.scoreData,
    this.lastScoreUpdate,
  });

  factory DepartmentModel.fromMap(Map<String, dynamic> map, String id) {
    return DepartmentModel(
      // ... mevcut
      scoreData: map['scoreData'] != null
          ? DepartmentScoreData.fromMap(map['scoreData'])
          : null,
      lastScoreUpdate: (map['lastScoreUpdate'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
    // ... mevcut
    if (scoreData != null) 'scoreData': scoreData!.toMap(),
    if (lastScoreUpdate != null)
      'lastScoreUpdate': Timestamp.fromDate(lastScoreUpdate!),
  };
}

// ── YENİ Model ────────────────────────────────────────────
class DepartmentScoreData {
  final int year;
  final String scoreType;       // SAY, EA, SÖZ, DİL, TYT
  final double baseScore;
  final int ranking;
  final int quota;
  final int placedCount;
  final Map<int, YearlyScore> previousYears;

  const DepartmentScoreData({
    required this.year,
    required this.scoreType,
    required this.baseScore,
    required this.ranking,
    required this.quota,
    required this.placedCount,
    this.previousYears = const {},
  });

  /// Doluluk oranı (yerleşen / kontenjan)
  double get fillRate => quota == 0 ? 0 : placedCount / quota;

  /// Tüm yıllar (mevcut + geçmiş) — küçükten büyüğe
  List<MapEntry<int, YearlyScore>> get allYearsAscending {
    final all = <int, YearlyScore>{
      year: YearlyScore(baseScore: baseScore, ranking: ranking),
      ...previousYears,
    };
    final sorted = all.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
    return sorted;
  }

  /// Geçen yıla göre puan farkı (negatif = düşmüş, pozitif = yükselmiş)
  double? get yearOverYearDelta {
    final prev = previousYears[year - 1];
    if (prev == null) return null;
    return baseScore - prev.baseScore;
  }

  factory DepartmentScoreData.fromMap(Map<String, dynamic> map) {
    final prev = (map['previousYears'] as Map?)?.cast<String, dynamic>() ?? {};
    return DepartmentScoreData(
      year: map['year'] ?? 0,
      scoreType: map['scoreType'] ?? '',
      baseScore: (map['baseScore'] as num?)?.toDouble() ?? 0,
      ranking: (map['ranking'] as num?)?.toInt() ?? 0,
      quota: (map['quota'] as num?)?.toInt() ?? 0,
      placedCount: (map['placedCount'] as num?)?.toInt() ?? 0,
      previousYears: {
        for (final entry in prev.entries)
          int.parse(entry.key): YearlyScore.fromMap(entry.value as Map<String, dynamic>)
      },
    );
  }

  Map<String, dynamic> toMap() => {
    'year': year,
    'scoreType': scoreType,
    'baseScore': baseScore,
    'ranking': ranking,
    'quota': quota,
    'placedCount': placedCount,
    'previousYears': {
      for (final e in previousYears.entries) e.key.toString(): e.value.toMap()
    },
  };
}

class YearlyScore {
  final double baseScore;
  final int ranking;
  const YearlyScore({required this.baseScore, required this.ranking});

  factory YearlyScore.fromMap(Map<String, dynamic> m) => YearlyScore(
        baseScore: (m['baseScore'] as num).toDouble(),
        ranking: (m['ranking'] as num).toInt(),
      );

  Map<String, dynamic> toMap() => {
        'baseScore': baseScore,
        'ranking': ranking,
      };
}
```

### 5.6 Migration Script — Firestore'a Yükleme

`lib/scripts/department_scores_migration.dart`

```dart
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// JSON'daki puanları Firestore'daki bölüm kayıtlarına merge eder.
///
/// Kullanım: Profil > Debug > "Bölüm Puanlarını Yükle (Debug)"
class DepartmentScoresMigration {
  final _db = FirebaseFirestore.instance;

  Future<MigrationReport> run() async {
    // 1. Admin kontrolü
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('Yetkisiz erişim: Lütfen giriş yapın.');
    }
    final token = await user.getIdTokenResult();
    if (token.claims?['admin'] != true) {
      throw Exception('Yetkisiz erişim: Sadece adminler veriyi yükleyebilir.');
    }

    // 2. JSON'u oku
    final jsonStr = await rootBundle.loadString('assets/data/department_scores.json');
    final data = json.decode(jsonStr) as Map<String, dynamic>;
    final scores = (data['scores'] as List).cast<Map<String, dynamic>>();
    debugPrint('📥 ${scores.length} bölüm için puan import edilecek');

    // 3. Batch ile Firestore'a yaz (max 490 yazma/batch)
    var batch = _db.batch();
    var batchCount = 0;
    var ok = 0;
    var skipped = 0;
    final missingDepts = <String>[];

    for (final score in scores) {
      final deptId = score['deptId'] as String;
      final ref = _db.collection('departments').doc(deptId);

      // Önceden var mı kontrol et (yoksa skip)
      final existing = await ref.get();
      if (!existing.exists) {
        skipped++;
        missingDepts.add(deptId);
        continue;
      }

      final scoreData = {
        'year': score['year'],
        'scoreType': score['scoreType'],
        'baseScore': score['baseScore'],
        'ranking': score['ranking'],
        'quota': score['quota'],
        'placedCount': score['placedCount'],
        'previousYears': score['previousYears'] ?? {},
      };

      batch.update(ref, {
        'scoreData': scoreData,
        'lastScoreUpdate': FieldValue.serverTimestamp(),
        // Backward compat: eski alanları da güncelle
        'baseScore': score['baseScore'],
        'ranking': score['ranking'],
        'quota': score['quota'],
        'scoreType': score['scoreType'],
      });
      batchCount++;
      ok++;

      if (batchCount >= 490) {
        await batch.commit();
        batch = _db.batch();
        batchCount = 0;
      }
    }
    if (batchCount > 0) await batch.commit();

    final report = MigrationReport(
      total: scores.length,
      successful: ok,
      skipped: skipped,
      missingDeptIds: missingDepts,
    );
    debugPrint('✅ Migration tamamlandı: $report');
    return report;
  }
}

class MigrationReport {
  final int total;
  final int successful;
  final int skipped;
  final List<String> missingDeptIds;
  const MigrationReport({
    required this.total,
    required this.successful,
    required this.skipped,
    required this.missingDeptIds,
  });

  @override
  String toString() =>
      '$successful/$total güncellendi, $skipped atlandı'
      '${missingDeptIds.isNotEmpty ? " | Eksik: ${missingDeptIds.take(3).join(", ")}..." : ""}';
}
```

### 5.7 Profil Ekranına Debug Butonu

`profile_screen.dart` içine yeni satır (mevcut diğer debug butonlarının yanına):

```dart
if (kDebugMode)
  _SettingsItem(
    icon: Icons.calculate_rounded,
    title: 'Bölüm Puanlarını Yükle (Debug)',
    subtitle: 'YÖK Atlas verilerini Firestore\'a yazar',
    onTap: () async {
      final messenger = ScaffoldMessenger.of(context);
      try {
        final report = await DepartmentScoresMigration().run();
        messenger.showSnackBar(SnackBar(content: Text(report.toString())));
        ref.invalidate(departmentsByUniversityProvider);
      } catch (e) {
        messenger.showSnackBar(SnackBar(
          content: Text('Hata: $e'),
          backgroundColor: AppColors.error,
        ));
      }
    },
  ),
```

### 5.8 Güncellik Stratejisi

ÖSYM her yıl Ağustos sonunda yeni puanları açıklar. Sprint sonrası:

1. **Otomatik güncelleme yok** — yıllık manuel job
2. Her yıl Ağustos sonunda:
   - Python scraper çalıştırılır
   - Yeni JSON oluşturulur
   - Profil > Debug > "Puanları Yükle"
   - Eski yıllar `previousYears`'a otomatik kayar

> 💡 **Sprint 5+** için: Cloud Functions ile otomatik güncelleme job'u eklenebilir.

---

## 6. D2 — Bölüm Kartı UI Yenileme

> **Sahibi**: Kişi A
> **Süre**: 3 gün (Gün 5–7)
> **Bağımlılık**: D1'in Firestore'a veri yazmış olması gerekir (ama mock veri ile paralel başlanabilir)

### 6.1 Hedef Görseli

Yeni `DepartmentCard` şu bilgileri gösterecek:

```
┌─────────────────────────────────────────────────────────┐
│ ┌────┐  Bilgisayar Mühendisliği                          │
│ │SAY │  Mühendislik Fakültesi · 4 Yıl · İngilizce         │
│ └────┘  ─────────────────────────────────────────────    │
│         📊 Taban: 547.32  🏆 Sıralama: 856  📋 120/120   │
│                                       ↗ +7.14 puan       │
└─────────────────────────────────────────────────────────┘
```

### 6.2 `ScoreBadge` Widget

`lib/features/university/presentation/widgets/score_badge.dart`

```dart
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

enum ScoreBadgeVariant {
  scoreType,    // SAY/EA/SÖZ/DİL/TYT
  baseScore,    // 547.32
  ranking,      // 856
  quota,        // 120/120
  delta,        // ↗ +7.14
}

class ScoreBadge extends StatelessWidget {
  final ScoreBadgeVariant variant;
  final String value;
  final IconData? icon;
  final Color? customColor;
  final bool small;

  const ScoreBadge({
    super.key,
    required this.variant,
    required this.value,
    this.icon,
    this.customColor,
    this.small = false,
  });

  factory ScoreBadge.scoreType(String type, {bool small = false}) {
    return ScoreBadge(
      variant: ScoreBadgeVariant.scoreType,
      value: type,
      customColor: _scoreTypeColor(type),
      small: small,
    );
  }

  factory ScoreBadge.baseScore(double score, {bool small = false}) {
    return ScoreBadge(
      variant: ScoreBadgeVariant.baseScore,
      value: score.toStringAsFixed(2),
      icon: Icons.trending_up_rounded,
      customColor: AppColors.primary,
      small: small,
    );
  }

  factory ScoreBadge.ranking(int rank, {bool small = false}) {
    final formatted = rank > 999 ? '${(rank / 1000).toStringAsFixed(1)}B' : rank.toString();
    return ScoreBadge(
      variant: ScoreBadgeVariant.ranking,
      value: formatted,
      icon: Icons.emoji_events_rounded,
      customColor: AppColors.warning,
      small: small,
    );
  }

  factory ScoreBadge.quota(int placed, int quota, {bool small = false}) {
    return ScoreBadge(
      variant: ScoreBadgeVariant.quota,
      value: '$placed/$quota',
      icon: Icons.people_rounded,
      customColor: placed == quota ? AppColors.success : AppColors.info,
      small: small,
    );
  }

  factory ScoreBadge.delta(double delta, {bool small = false}) {
    final isUp = delta > 0;
    final color = isUp ? AppColors.success : AppColors.error;
    return ScoreBadge(
      variant: ScoreBadgeVariant.delta,
      value: '${isUp ? "+" : ""}${delta.toStringAsFixed(2)}',
      icon: isUp ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
      customColor: color,
      small: small,
    );
  }

  static Color _scoreTypeColor(String type) {
    switch (type) {
      case 'SAY': return const Color(0xFF3B82F6);
      case 'EA':  return const Color(0xFF8B5CF6);
      case 'SÖZ': return const Color(0xFFEC4899);
      case 'DİL': return const Color(0xFF10B981);
      case 'TYT': return const Color(0xFFF59E0B);
      default:    return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = customColor ?? AppColors.primary;
    final padH = small ? 6.0 : 8.0;
    final padV = small ? 3.0 : 4.0;
    final iconSize = small ? 12.0 : 14.0;
    final fontSize = small ? 10.0 : 11.0;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: padH, vertical: padV),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(small ? 6 : 8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: iconSize, color: color),
            SizedBox(width: small ? 3 : 4),
          ],
          Text(
            value,
            style: AppTextStyles.labelSmall.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: fontSize,
            ),
          ),
        ],
      ),
    );
  }
}
```

### 6.3 `DepartmentCard` Widget

`lib/features/university/presentation/widgets/department_card.dart`

```dart
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/constants/app_constants.dart';
import '../../domain/models/department_model.dart';
import 'score_badge.dart';

class DepartmentCard extends StatelessWidget {
  final DepartmentModel department;
  final VoidCallback onTap;
  final bool compact;
  final EdgeInsets? margin;

  const DepartmentCard({
    super.key,
    required this.department,
    required this.onTap,
    this.compact = false,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final hasScoreData = department.scoreData != null;

    return Container(
      margin: margin ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.radiusLg),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: AppColors.softShadow,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppConstants.radiusLg),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppConstants.radiusLg),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Üst satır: tip ikonu + ad + chevron
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: (department.type == 'Lisans'
                                ? AppColors.primary
                                : AppColors.accent)
                            .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        department.type == 'Lisans'
                            ? Icons.school_rounded
                            : Icons.auto_stories_rounded,
                        color: department.type == 'Lisans'
                            ? AppColors.primary
                            : AppColors.accent,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            department.name,
                            style: AppTextStyles.titleSmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${department.faculty} · ${department.duration} Yıl · ${department.language}',
                            style: AppTextStyles.labelSmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    if (hasScoreData)
                      ScoreBadge.scoreType(department.scoreData!.scoreType, small: true),
                  ],
                ),

                // Alt satır: puan rozetleri (sadece veri varsa)
                if (hasScoreData) ...[
                  const SizedBox(height: 12),
                  Container(
                    height: 1,
                    color: AppColors.borderLight,
                  ),
                  const SizedBox(height: 10),
                  _ScoreRow(scoreData: department.scoreData!),
                ] else if (department.baseScore != null) ...[
                  // Fallback: eski veri
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      ScoreBadge.baseScore(department.baseScore!, small: true),
                      if (department.ranking != null) ...[
                        const SizedBox(width: 6),
                        ScoreBadge.ranking(department.ranking!, small: true),
                      ],
                    ],
                  ),
                ] else ...[
                  // Henüz veri yok
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.textTertiary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Puan verisi yakında',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.textTertiary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ScoreRow extends StatelessWidget {
  final DepartmentScoreData scoreData;
  const _ScoreRow({required this.scoreData});

  @override
  Widget build(BuildContext context) {
    final delta = scoreData.yearOverYearDelta;
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        ScoreBadge.baseScore(scoreData.baseScore, small: true),
        ScoreBadge.ranking(scoreData.ranking, small: true),
        ScoreBadge.quota(scoreData.placedCount, scoreData.quota, small: true),
        if (delta != null && delta.abs() > 0.01)
          ScoreBadge.delta(delta, small: true),
      ],
    );
  }
}
```

### 6.4 `ScoreTrendChart` Widget — 3 Yıllık Trend

`lib/features/university/presentation/widgets/score_trend_chart.dart`

```dart
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/models/department_model.dart';

class ScoreTrendChart extends StatelessWidget {
  final DepartmentScoreData scoreData;
  const ScoreTrendChart({super.key, required this.scoreData});

  @override
  Widget build(BuildContext context) {
    final years = scoreData.allYearsAscending;
    if (years.length < 2) {
      return _buildEmptyState();
    }

    final spots = <FlSpot>[];
    for (var i = 0; i < years.length; i++) {
      spots.add(FlSpot(i.toDouble(), years[i].value.baseScore));
    }

    final minScore = years.map((e) => e.value.baseScore).reduce((a, b) => a < b ? a : b);
    final maxScore = years.map((e) => e.value.baseScore).reduce((a, b) => a > b ? a : b);
    final padding = (maxScore - minScore) * 0.15 + 2;

    return Container(
      height: 220,
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.show_chart_rounded, size: 18, color: AppColors.primary),
              const SizedBox(width: 6),
              Text('Taban Puan Trendi',
                  style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: LineChart(
              LineChartData(
                minY: minScore - padding,
                maxY: maxScore + padding,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: (maxScore - minScore) / 3,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: AppColors.borderLight,
                    strokeWidth: 1,
                    dashArray: [4, 4],
                  ),
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (value, _) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= years.length) return const SizedBox();
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(years[idx].key.toString(),
                              style: AppTextStyles.labelSmall),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, _) => Text(
                        value.toStringAsFixed(0),
                        style: AppTextStyles.labelSmall,
                      ),
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    curveSmoothness: 0.35,
                    color: AppColors.primary,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, _, __, ___) => FlDotCirclePainter(
                        radius: 5,
                        color: AppColors.surface,
                        strokeWidth: 2.5,
                        strokeColor: AppColors.primary,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary.withValues(alpha: 0.2),
                          AppColors.primary.withValues(alpha: 0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => AppColors.textPrimary,
                    getTooltipItems: (spots) => spots.map((s) {
                      final idx = s.x.toInt();
                      final entry = years[idx];
                      return LineTooltipItem(
                        '${entry.key}\n${entry.value.baseScore.toStringAsFixed(2)}',
                        AppTextStyles.labelSmall.copyWith(color: Colors.white),
                      );
                    }).toList(),
                  ),
                ),
              ),
              duration: const Duration(milliseconds: 600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.show_chart_rounded, size: 32, color: AppColors.textTertiary),
            const SizedBox(height: 8),
            Text('Trend verisi henüz yok',
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.textTertiary)),
          ],
        ),
      ),
    );
  }
}
```

### 6.5 `DepartmentDetailScreen` Yenileme

Mevcut ekrana `ScoreTrendChart` ve genişletilmiş bilgi kartları eklenir:

```dart
// department_detail_screen.dart içinde
// Mevcut "taban puan kartı"nın altına ekle:

if (dept.scoreData != null) ...[
  const SizedBox(height: 16),
  ScoreTrendChart(scoreData: dept.scoreData!),

  const SizedBox(height: 16),

  // Detay grid'i — 4 kart (yıl, sıralama, kontenjan, doluluk)
  GridView.count(
    crossAxisCount: 2,
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    childAspectRatio: 2.0,
    mainAxisSpacing: 8,
    crossAxisSpacing: 8,
    children: [
      _ScoreInfoTile(
        label: 'Taban Puan',
        value: dept.scoreData!.baseScore.toStringAsFixed(2),
        subtitle: '${dept.scoreData!.year} yılı',
        icon: Icons.trending_up_rounded,
        color: AppColors.primary,
      ),
      _ScoreInfoTile(
        label: 'Başarı Sırası',
        value: dept.scoreData!.ranking.toString(),
        icon: Icons.emoji_events_rounded,
        color: AppColors.warning,
      ),
      _ScoreInfoTile(
        label: 'Kontenjan',
        value: dept.scoreData!.quota.toString(),
        subtitle: '${dept.scoreData!.placedCount} yerleşti',
        icon: Icons.people_rounded,
        color: AppColors.info,
      ),
      _ScoreInfoTile(
        label: 'Doluluk',
        value: '${(dept.scoreData!.fillRate * 100).toStringAsFixed(0)}%',
        icon: Icons.pie_chart_rounded,
        color: AppColors.success,
      ),
    ],
  ),
],
```

### 6.6 Karşılaştırma Ekranında Kullanım

`comparison_stats_table.dart` zaten `avgBaseScoreA` ve `avgBaseScoreB` gösteriyor. Yeni veri ile bu hesaplama daha doğru olacak — değişiklik gerekmiyor, sadece veri akacak.

### 6.7 Filtre Eklenmesi (Opsiyonel — P1)

`uni_departments_screen.dart`'a "Puan Aralığı" filtresi:
- Slider: 200–600 arası
- "Skor Tipi" çoklu seçim (SAY, EA, SÖZ, DİL, TYT)

Bu opsiyonel görev, zaman kalırsa Gün 7 sonunda yapılır.

---

## 7. D3 — Tercih Listeleri Sistemi

> **Sahibi**: Kişi B
> **Süre**: 5 gün (Gün 1–5)
> **Risk**: 🟡 ORTA — Paylaşım URL'leri için slug sistemi dikkat ister

### 7.1 Veri Modeli

`lib/features/preference_lists/domain/models/preference_list_model.dart`

```dart
import 'package:cloud_firestore/cloud_firestore.dart';

class PreferenceListModel {
  final String id;
  final String userId;
  final String userName;          // denormalize (paylaşım için)
  final String? userPhotoUrl;     // denormalize
  final String title;
  final String description;
  final bool isPublic;
  final String shareSlug;         // 5 karakter, tüm sistemde unique
  final int viewCount;
  final List<PreferenceItem> items;
  final DateTime createdAt;
  final DateTime updatedAt;

  PreferenceListModel({
    required this.id,
    required this.userId,
    required this.userName,
    this.userPhotoUrl,
    required this.title,
    this.description = '',
    this.isPublic = false,
    required this.shareSlug,
    this.viewCount = 0,
    this.items = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  static const int maxItems = 24;     // ÖSYM tercih limiti
  static const int maxLists = 10;     // Bir kullanıcı max 10 liste

  String get publicUrl => 'https://unisec.app/list/$shareSlug';

  factory PreferenceListModel.fromMap(Map<String, dynamic> m, String id) {
    final items = (m['items'] as List?) ?? [];
    return PreferenceListModel(
      id: id,
      userId: m['userId'] ?? '',
      userName: m['userName'] ?? 'Kullanıcı',
      userPhotoUrl: m['userPhotoUrl'],
      title: m['title'] ?? 'Adsız Liste',
      description: m['description'] ?? '',
      isPublic: m['isPublic'] ?? false,
      shareSlug: m['shareSlug'] ?? '',
      viewCount: m['viewCount'] ?? 0,
      items: items.map((e) => PreferenceItem.fromMap(e as Map<String, dynamic>))
                  .toList(),
      createdAt: (m['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (m['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
    'userId': userId,
    'userName': userName,
    'userPhotoUrl': userPhotoUrl,
    'title': title,
    'description': description,
    'isPublic': isPublic,
    'shareSlug': shareSlug,
    'viewCount': viewCount,
    'items': items.map((e) => e.toMap()).toList(),
    'createdAt': Timestamp.fromDate(createdAt),
    'updatedAt': Timestamp.fromDate(updatedAt),
  };

  PreferenceListModel copyWith({
    String? title,
    String? description,
    bool? isPublic,
    List<PreferenceItem>? items,
    int? viewCount,
  }) {
    return PreferenceListModel(
      id: id,
      userId: userId,
      userName: userName,
      userPhotoUrl: userPhotoUrl,
      title: title ?? this.title,
      description: description ?? this.description,
      isPublic: isPublic ?? this.isPublic,
      shareSlug: shareSlug,
      viewCount: viewCount ?? this.viewCount,
      items: items ?? this.items,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}

class PreferenceItem {
  final String deptId;
  final String uniId;
  final int order;          // 1-24 arası tercih sırası
  final String? note;       // Kullanıcı notu

  // Denormalize alanlar (paylaşım sırasında kart için)
  final String deptName;
  final String uniName;
  final String? uniLogoUrl;

  const PreferenceItem({
    required this.deptId,
    required this.uniId,
    required this.order,
    this.note,
    required this.deptName,
    required this.uniName,
    this.uniLogoUrl,
  });

  factory PreferenceItem.fromMap(Map<String, dynamic> m) => PreferenceItem(
    deptId: m['deptId'] ?? '',
    uniId: m['uniId'] ?? '',
    order: (m['order'] as num?)?.toInt() ?? 0,
    note: m['note'],
    deptName: m['deptName'] ?? '',
    uniName: m['uniName'] ?? '',
    uniLogoUrl: m['uniLogoUrl'],
  );

  Map<String, dynamic> toMap() => {
    'deptId': deptId,
    'uniId': uniId,
    'order': order,
    if (note != null) 'note': note,
    'deptName': deptName,
    'uniName': uniName,
    if (uniLogoUrl != null) 'uniLogoUrl': uniLogoUrl,
  };

  PreferenceItem copyWith({int? order, String? note}) => PreferenceItem(
    deptId: deptId,
    uniId: uniId,
    order: order ?? this.order,
    note: note ?? this.note,
    deptName: deptName,
    uniName: uniName,
    uniLogoUrl: uniLogoUrl,
  );
}
```

### 7.2 Repository

`lib/features/preference_lists/data/preference_list_repository.dart`

```dart
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../domain/models/preference_list_model.dart';

class PreferenceListRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  PreferenceListRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> get _listsRef =>
      _firestore.collection('preferenceLists');

  /// Slug üretimi: 5 karakterli alfanumerik (1/52^5 = 1/380M unique uzayı)
  static String _generateSlug() {
    const chars = 'abcdefghjkmnpqrstuvwxyz23456789'; // confusing chars çıkarıldı
    final rng = Random.secure();
    return List.generate(5, (_) => chars[rng.nextInt(chars.length)]).join();
  }

  /// Unique slug bul (collision varsa tekrar üret)
  Future<String> _findUniqueSlug({int maxAttempts = 5}) async {
    for (var i = 0; i < maxAttempts; i++) {
      final slug = _generateSlug();
      final exists = await _listsRef.where('shareSlug', isEqualTo: slug)
                                     .limit(1).get();
      if (exists.docs.isEmpty) return slug;
    }
    // Fallback: 6 karakter
    return _generateSlug() + Random.secure().nextInt(36).toRadixString(36);
  }

  /// Yeni liste oluştur
  Future<PreferenceListModel> createList({
    required String title,
    String description = '',
    bool isPublic = false,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Giriş yapmalısınız');

    // Limit kontrolü
    final myLists = await _listsRef.where('userId', isEqualTo: user.uid)
                                     .count().get();
    final count = myLists.count ?? 0;
    if (count >= PreferenceListModel.maxLists) {
      throw Exception('En fazla ${PreferenceListModel.maxLists} liste oluşturabilirsiniz.');
    }

    final slug = await _findUniqueSlug();
    final now = DateTime.now();
    final docRef = _listsRef.doc();

    final list = PreferenceListModel(
      id: docRef.id,
      userId: user.uid,
      userName: user.displayName ?? 'Öğrenci',
      userPhotoUrl: user.photoURL,
      title: title,
      description: description,
      isPublic: isPublic,
      shareSlug: slug,
      createdAt: now,
      updatedAt: now,
    );

    await docRef.set(list.toMap());
    return list;
  }

  /// Liste güncelle
  Future<void> updateList(PreferenceListModel list) async {
    final user = _auth.currentUser;
    if (user == null || user.uid != list.userId) {
      throw Exception('Bu listeyi düzenleme yetkiniz yok');
    }
    if (list.items.length > PreferenceListModel.maxItems) {
      throw Exception('Bir listede en fazla ${PreferenceListModel.maxItems} tercih olabilir');
    }
    await _listsRef.doc(list.id).update(list.toMap());
  }

  /// Liste sil
  Future<void> deleteList(String listId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Giriş yapmalısınız');
    final doc = await _listsRef.doc(listId).get();
    if (!doc.exists || doc.data()?['userId'] != user.uid) {
      throw Exception('Bu listeyi silme yetkiniz yok');
    }
    await _listsRef.doc(listId).delete();
  }

  /// Kullanıcının listelerini stream olarak izle
  Stream<List<PreferenceListModel>> watchMyLists() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    return _listsRef
        .where('userId', isEqualTo: user.uid)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => PreferenceListModel.fromMap(d.data(), d.id))
            .toList());
  }

  /// Tek liste izle (kendi)
  Stream<PreferenceListModel?> watchList(String listId) {
    return _listsRef.doc(listId).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return PreferenceListModel.fromMap(doc.data()!, doc.id);
    });
  }

  /// Slug ile public liste getir + view count artır
  Future<PreferenceListModel?> getPublicListBySlug(String slug) async {
    final query = await _listsRef
        .where('shareSlug', isEqualTo: slug)
        .where('isPublic', isEqualTo: true)
        .limit(1)
        .get();
    if (query.docs.isEmpty) return null;
    final doc = query.docs.first;
    
    // View count artır (best effort, hata olursa sessizce devam et)
    _listsRef.doc(doc.id).update({
      'viewCount': FieldValue.increment(1),
    }).catchError((_) {});

    return PreferenceListModel.fromMap(doc.data(), doc.id);
  }

  /// Liste'ye öğe ekle
  Future<void> addItem(String listId, PreferenceItem item) async {
    final list = await _listsRef.doc(listId).get();
    if (!list.exists) throw Exception('Liste bulunamadı');
    final model = PreferenceListModel.fromMap(list.data()!, listId);

    if (model.items.length >= PreferenceListModel.maxItems) {
      throw Exception('Listede en fazla ${PreferenceListModel.maxItems} tercih olabilir');
    }
    if (model.items.any((i) => i.deptId == item.deptId)) {
      throw Exception('Bu bölüm zaten listede');
    }

    final newItems = [...model.items, item.copyWith(order: model.items.length + 1)];
    await _listsRef.doc(listId).update({
      'items': newItems.map((e) => e.toMap()).toList(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Sırayı yeniden düzenle
  Future<void> reorderItems(String listId, List<PreferenceItem> orderedItems) async {
    final reordered = <Map<String, dynamic>>[];
    for (var i = 0; i < orderedItems.length; i++) {
      reordered.add(orderedItems[i].copyWith(order: i + 1).toMap());
    }
    await _listsRef.doc(listId).update({
      'items': reordered,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
```

### 7.3 Firestore Rules

`firestore.rules` dosyasına ekle:

```
// ─── Tercih Listeleri ────────────────────────────────────────
match /preferenceLists/{listId} {
  // Public listeler herkes okuyabilir, private sadece sahibi
  allow read: if resource.data.isPublic == true ||
                 (request.auth != null && request.auth.uid == resource.data.userId);

  // Sadece giriş yapmış kullanıcılar oluşturabilir,
  // kendisini userId olarak set etmeli
  allow create: if request.auth != null
                && request.resource.data.userId == request.auth.uid
                && request.resource.data.items.size() <= 24;

  // Sahibi güncelleyebilir, viewCount herkes increment edebilir
  allow update: if (request.auth != null && request.auth.uid == resource.data.userId)
                || (request.resource.data.diff(resource.data).affectedKeys().hasOnly(['viewCount']));

  allow delete: if request.auth != null && request.auth.uid == resource.data.userId;
}
```

### 7.4 Firestore Indexes

`firestore.indexes.json` dosyasına ekle:

```json
{
  "collectionGroup": "preferenceLists",
  "queryScope": "COLLECTION",
  "fields": [
    { "fieldPath": "userId", "order": "ASCENDING" },
    { "fieldPath": "updatedAt", "order": "DESCENDING" }
  ]
},
{
  "collectionGroup": "preferenceLists",
  "queryScope": "COLLECTION",
  "fields": [
    { "fieldPath": "shareSlug", "order": "ASCENDING" },
    { "fieldPath": "isPublic", "order": "ASCENDING" }
  ]
}
```

### 7.5 Providers

`lib/features/preference_lists/presentation/providers/preference_list_providers.dart`

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/preference_list_repository.dart';
import '../../domain/models/preference_list_model.dart';

final preferenceListRepositoryProvider = Provider<PreferenceListRepository>((ref) {
  return PreferenceListRepository();
});

/// Kullanıcının tüm listeleri
final myPreferenceListsProvider = StreamProvider<List<PreferenceListModel>>((ref) {
  ref.keepAlive();
  return ref.watch(preferenceListRepositoryProvider).watchMyLists();
});

/// Tek liste detay
final preferenceListProvider = StreamProvider.family<PreferenceListModel?, String>((ref, listId) {
  return ref.watch(preferenceListRepositoryProvider).watchList(listId);
});

/// Public liste (paylaşım slug ile)
final publicListBySlugProvider = FutureProvider.family<PreferenceListModel?, String>((ref, slug) {
  return ref.watch(preferenceListRepositoryProvider).getPublicListBySlug(slug);
});

/// Aksiyonlar için controller
class PreferenceListController extends StateNotifier<AsyncValue<void>> {
  PreferenceListController(this._repo) : super(const AsyncValue.data(null));
  final PreferenceListRepository _repo;

  Future<PreferenceListModel?> create({
    required String title,
    String description = '',
    bool isPublic = false,
  }) async {
    state = const AsyncValue.loading();
    try {
      final list = await _repo.createList(
        title: title,
        description: description,
        isPublic: isPublic,
      );
      state = const AsyncValue.data(null);
      return list;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> update(PreferenceListModel list) async {
    state = const AsyncValue.loading();
    try {
      await _repo.updateList(list);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> delete(String listId) async {
    state = const AsyncValue.loading();
    try {
      await _repo.deleteList(listId);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

final preferenceListControllerProvider =
    StateNotifierProvider<PreferenceListController, AsyncValue<void>>(
  (ref) => PreferenceListController(ref.read(preferenceListRepositoryProvider)),
);
```

### 7.6 Ekranlar — Genel Yapı

#### 7.6.1 `MyListsScreen` (Bottom Nav'da Tercih Listelerim tab'ı)

```dart
class MyListsScreen extends ConsumerWidget {
  const MyListsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).value;
    if (user == null) return const _UnauthenticatedView();

    final listsAsync = ref.watch(myPreferenceListsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tercih Listelerim'),
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite_outline_rounded),
            tooltip: 'Favorilerim',
            onPressed: () => context.push('/favorites'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateDialog(context, ref),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Yeni Liste'),
      ),
      body: listsAsync.when(
        loading: () => const ShimmerList(itemCount: 3),
        error: (e, _) => ErrorStateWidget(message: '$e'),
        data: (lists) {
          if (lists.isEmpty) return const _EmptyState();
          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: lists.length,
            itemBuilder: (_, i) => ListCard(
              list: lists[i],
              onTap: () => context.push('/my-lists/${lists[i].id}'),
              onShare: () => ShareListSheet.show(context, lists[i]),
              onDelete: () => _confirmDelete(context, ref, lists[i]),
            ),
          );
        },
      ),
    );
  }
  // ... yardımcı methodlar
}
```

#### 7.6.2 `ListEditScreen` — Düzenleme + Sürükle-Bırak

```dart
class ListEditScreen extends ConsumerStatefulWidget {
  final String listId;
  // ...
}

class _ListEditScreenState extends ConsumerState<ListEditScreen> {
  late TextEditingController _titleCtrl;
  late TextEditingController _descCtrl;
  late List<PreferenceItem> _items;
  bool _isPublic = false;

  // ReorderableListView ile sürükle-bırak
  Widget _buildItemsList() {
    return ReorderableListView.builder(
      shrinkWrap: true,
      itemCount: _items.length,
      onReorder: (oldIdx, newIdx) {
        if (newIdx > oldIdx) newIdx--;
        setState(() {
          final item = _items.removeAt(oldIdx);
          _items.insert(newIdx, item);
        });
      },
      itemBuilder: (_, i) => ListItemTile(
        key: ValueKey(_items[i].deptId),
        item: _items[i],
        order: i + 1,
        onRemove: () => setState(() => _items.removeAt(i)),
      ),
    );
  }

  // "+ Bölüm Ekle" butonu → bottom sheet'te üni > bölüm seçim
  Future<void> _addItem() async {
    final selected = await DepartmentPicker.show(context);
    if (selected != null) {
      setState(() => _items.add(PreferenceItem(
        deptId: selected.id,
        uniId: selected.universityId,
        order: _items.length + 1,
        deptName: selected.name,
        uniName: selected.uniName,
        uniLogoUrl: selected.uniLogoUrl,
      )));
    }
  }
}
```

#### 7.6.3 `SharedListScreen` — Public Görüntüleme

```dart
class SharedListScreen extends ConsumerWidget {
  final String shareSlug;
  const SharedListScreen({super.key, required this.shareSlug});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listAsync = ref.watch(publicListBySlugProvider(shareSlug));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Paylaşılan Liste'),
        actions: [
          // Login'siz erişim — login butonu göster
          if (ref.watch(authStateProvider).value == null)
            TextButton(
              onPressed: () => context.push('/login'),
              child: const Text('Giriş Yap'),
            ),
        ],
      ),
      body: listAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorStateWidget(message: '$e'),
        data: (list) {
          if (list == null) {
            return const EmptyStateWidget(
              icon: Icons.link_off_rounded,
              title: 'Liste bulunamadı',
              description: 'Bu liste silinmiş veya gizli olarak işaretlenmiş olabilir.',
            );
          }
          return _buildListView(context, list);
        },
      ),
    );
  }
  // ...
}
```

### 7.7 `ShareListSheet` — Paylaşım Modal'ı

```dart
class ShareListSheet {
  static Future<void> show(BuildContext context, PreferenceListModel list) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _Content(list: list),
    );
  }
}

class _Content extends ConsumerWidget {
  final PreferenceListModel list;
  const _Content({required this.list});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(width: 40, height: 4, /* ... */),
          const SizedBox(height: 16),
          Text('Listeyi Paylaş', style: AppTextStyles.headlineSmall),
          const SizedBox(height: 16),

          // Public/Private toggle
          SwitchListTile(
            title: const Text('Herkese açık'),
            subtitle: const Text('Linke sahip herkes görebilir'),
            value: list.isPublic,
            onChanged: (v) async {
              await ref.read(preferenceListControllerProvider.notifier)
                       .update(list.copyWith(isPublic: v));
            },
          ),

          if (list.isPublic) ...[
            const SizedBox(height: 16),
            // Link kart
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(list.publicUrl,
                        style: AppTextStyles.bodySmall.copyWith(color: AppColors.primary)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy_rounded),
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: list.publicUrl));
                      // snackbar
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Paylaşım butonları
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => Share.share(
                      '"${list.title}" tercih listemi paylaştım — ${list.publicUrl}',
                    ),
                    icon: const Icon(Icons.share_rounded),
                    label: const Text('Paylaş'),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: () => _shareViaWhatsapp(list),
                  icon: const Icon(Icons.message_rounded),
                ),
              ],
            ),

            const SizedBox(height: 12),
            Text(
              '${list.viewCount} görüntülenme',
              style: AppTextStyles.labelSmall,
            ),
          ],
        ],
      ),
    );
  }
}
```

### 7.8 Bottom Navigation Güncellemesi

`lib/router/app_shell.dart` içinde 4. tab değişiyor:

```dart
// ÖNCESİ:
const NavigationDestination(
  icon: Icon(Icons.favorite_outline_rounded),
  selectedIcon: Icon(Icons.favorite_rounded, color: AppColors.primary),
  label: 'Favoriler',
),

// SONRASI:
const NavigationDestination(
  icon: Icon(Icons.list_alt_outlined),
  selectedIcon: Icon(Icons.list_alt_rounded, color: AppColors.primary),
  label: 'Listelerim',
),
```

Ve `app_router.dart`'da branch güncellemesi:
```dart
// ÖNCESİ: /favorites branch
StatefulShellBranch(routes: [
  GoRoute(path: AppRoutes.favorites, ...),
]),

// SONRASI: /my-lists branch (favorites ana route'a kalır, profilden açılır)
StatefulShellBranch(routes: [
  GoRoute(path: '/my-lists',
    pageBuilder: (c, s) => const NoTransitionPage(child: MyListsScreen()),
  ),
]),
```

### 7.9 Profil Ekranı'na "Favorilerim" Linki

`profile_screen.dart` içinde "Hesap" bölümüne ekle:

```dart
_SettingsItem(
  icon: Icons.favorite_outline_rounded,
  title: 'Favorilerim',
  subtitle: '${favoritesCount} üniversite',
  onTap: () => context.push('/favorites'),
),
```

---

## 8. D4 — AI Tercih Robotu

> **Sahibi**: Kişi B
> **Süre**: 4 gün (Gün 6–9)
> **Strateji**: Kural tabanlı (rule-based) puanlama. Sprint 5+ için Claude API entegrasyonu.

### 8.1 Mimari

```
Kullanıcı tıklar → "Hayalindeki üniversiteyi bulalım"
       │
       ▼
[Soru 1: Bölüm grubu?]
   ├─ Mühendislik
   ├─ Sağlık
   ├─ Sosyal
   ├─ Sanat
   └─ Henüz emin değilim
       │
       ▼
[Soru 2: Tahmini puan aralığın?]
   ├─ 200-300
   ├─ 300-400
   ├─ 400-500
   ├─ 500+
   └─ Bilmiyorum
       │
       ▼
[Soru 3: Hangi şehirleri düşünüyorsun?]  (multi-select)
       │
       ▼
[Soru 4: Devlet mi vakıf mı?]
       │
       ▼
[Soru 5: Kampüs hayatı önemli mi?]
       │
       ▼
[Soru 6: Sosyal hayat / akademik odak?]
       │
       ▼
[Soru 7 (opsiyonel): İngilizce eğitim?]
       │
       ▼
[Soru 8: Yurt durumu?]
       │
       ▼
[Sonuç: 3 üni öneri + en uygun 5 bölüm]
```

### 8.2 Soru Bankası

`lib/features/recommendation/domain/question_bank.dart`

```dart
import 'package:flutter/material.dart';
import 'models/recommendation_question.dart';

class QuestionBank {
  static const List<RecommendationQuestion> questions = [
    RecommendationQuestion(
      id: 'department_group',
      question: 'Hangi alanda okumak istiyorsun?',
      type: QuestionType.singleSelect,
      options: [
        QuestionOption(id: 'engineering', label: 'Mühendislik & Teknik',
            icon: Icons.engineering_rounded, scoreType: 'SAY'),
        QuestionOption(id: 'health', label: 'Sağlık & Tıp',
            icon: Icons.medical_services_rounded, scoreType: 'SAY'),
        QuestionOption(id: 'social', label: 'Sosyal Bilimler',
            icon: Icons.people_alt_rounded, scoreType: 'EA'),
        QuestionOption(id: 'verbal', label: 'Hukuk & Tarih & Edebiyat',
            icon: Icons.menu_book_rounded, scoreType: 'SÖZ'),
        QuestionOption(id: 'arts', label: 'Sanat & Tasarım',
            icon: Icons.palette_rounded),
        QuestionOption(id: 'undecided', label: 'Henüz emin değilim',
            icon: Icons.help_outline_rounded),
      ],
    ),
    RecommendationQuestion(
      id: 'estimated_score',
      question: 'Tahmini YKS puanın hangi aralıkta?',
      hint: 'Net çözdüğün soru sayısına göre kabaca tahmin edebilirsin',
      type: QuestionType.singleSelect,
      options: [
        QuestionOption(id: '200_300', label: '200 - 300', scoreMin: 200, scoreMax: 300),
        QuestionOption(id: '300_400', label: '300 - 400', scoreMin: 300, scoreMax: 400),
        QuestionOption(id: '400_500', label: '400 - 500', scoreMin: 400, scoreMax: 500),
        QuestionOption(id: '500_plus', label: '500+', scoreMin: 500, scoreMax: 600),
        QuestionOption(id: 'unknown', label: 'Henüz bilmiyorum'),
      ],
    ),
    RecommendationQuestion(
      id: 'cities',
      question: 'Hangi şehirleri düşünüyorsun?',
      hint: 'Birden fazla seçebilirsin',
      type: QuestionType.multiSelect,
      options: [
        QuestionOption(id: 'istanbul', label: 'İstanbul', cityIds: ['34']),
        QuestionOption(id: 'ankara', label: 'Ankara', cityIds: ['06']),
        QuestionOption(id: 'izmir', label: 'İzmir', cityIds: ['35']),
        QuestionOption(id: 'bursa', label: 'Bursa', cityIds: ['16']),
        QuestionOption(id: 'eskisehir', label: 'Eskişehir', cityIds: ['26']),
        QuestionOption(id: 'antalya', label: 'Antalya', cityIds: ['07']),
        QuestionOption(id: 'aegean', label: 'Ege bölgesi geneli',
            cityIds: ['35', '07']),
        QuestionOption(id: 'anywhere', label: 'Fark etmez', cityIds: []),
      ],
    ),
    RecommendationQuestion(
      id: 'university_type',
      question: 'Devlet mi yoksa vakıf mı?',
      hint: 'Vakıf üniversiteleri burs imkanları sunabilir',
      type: QuestionType.singleSelect,
      options: [
        QuestionOption(id: 'state', label: 'Devlet', uniType: 'Devlet'),
        QuestionOption(id: 'foundation', label: 'Vakıf', uniType: 'Vakıf'),
        QuestionOption(id: 'both', label: 'İkisi de olabilir'),
      ],
    ),
    RecommendationQuestion(
      id: 'campus_life',
      question: 'Kampüs hayatı senin için ne kadar önemli?',
      hint: 'Kampüslü üniversiteler genellikle yeşil alan, sosyal etkinlik açısından zengin',
      type: QuestionType.singleSelect,
      options: [
        QuestionOption(id: 'campus_critical', label: 'Çok önemli, kampüs şart',
            preferCampus: true),
        QuestionOption(id: 'campus_nice', label: 'Olsa iyi olur',
            preferCampus: true, weight: 0.5),
        QuestionOption(id: 'no_pref', label: 'Fark etmez'),
      ],
    ),
    RecommendationQuestion(
      id: 'focus',
      question: 'Üniversite hayatında neye öncelik verirsin?',
      type: QuestionType.singleSelect,
      options: [
        QuestionOption(id: 'academic', label: 'Akademik kalite',
            categoryWeights: {'Eğitim Kalitesi': 2.0}),
        QuestionOption(id: 'social', label: 'Sosyal hayat',
            categoryWeights: {'Sosyal Hayat': 2.0}),
        QuestionOption(id: 'job', label: 'İş imkanları',
            categoryWeights: {'İş İmkanı': 2.0}),
        QuestionOption(id: 'balance', label: 'Hepsinden dengeli'),
      ],
    ),
    RecommendationQuestion(
      id: 'language',
      question: 'İngilizce eğitim ister misin?',
      type: QuestionType.singleSelect,
      isOptional: true,
      options: [
        QuestionOption(id: 'en_required', label: 'Evet, kesinlikle', preferLanguage: 'İngilizce'),
        QuestionOption(id: 'en_optional', label: 'Olabilir ama şart değil'),
        QuestionOption(id: 'tr_required', label: 'Türkçe tercih ederim', preferLanguage: 'Türkçe'),
      ],
    ),
    RecommendationQuestion(
      id: 'dorm',
      question: 'Yurt durumu önemli mi?',
      type: QuestionType.singleSelect,
      options: [
        QuestionOption(id: 'dorm_important', label: 'Yurt şart',
            categoryWeights: {'Yurt': 2.0}),
        QuestionOption(id: 'dorm_local', label: 'Şehirde aileyle kalacağım'),
        QuestionOption(id: 'dorm_alone', label: 'Kendi başıma kiralayacağım'),
      ],
    ),
  ];
}
```

### 8.3 Modeller

`lib/features/recommendation/domain/models/recommendation_question.dart`

```dart
import 'package:flutter/material.dart';

enum QuestionType { singleSelect, multiSelect, slider, freeText }

class RecommendationQuestion {
  final String id;
  final String question;
  final String? hint;
  final QuestionType type;
  final List<QuestionOption> options;
  final bool isOptional;

  const RecommendationQuestion({
    required this.id,
    required this.question,
    this.hint,
    required this.type,
    required this.options,
    this.isOptional = false,
  });
}

class QuestionOption {
  final String id;
  final String label;
  final IconData? icon;

  // Skorlama parametreleri (algoritmaya feed edilir)
  final String? scoreType;
  final double? scoreMin;
  final double? scoreMax;
  final List<String>? cityIds;
  final String? uniType;
  final bool preferCampus;
  final String? preferLanguage;
  final Map<String, double> categoryWeights;
  final double weight;

  const QuestionOption({
    required this.id,
    required this.label,
    this.icon,
    this.scoreType,
    this.scoreMin,
    this.scoreMax,
    this.cityIds,
    this.uniType,
    this.preferCampus = false,
    this.preferLanguage,
    this.categoryWeights = const {},
    this.weight = 1.0,
  });
}
```

`recommendation_answer.dart`

```dart
class RecommendationAnswer {
  final String questionId;
  final List<String> selectedOptionIds;
  final DateTime answeredAt;

  RecommendationAnswer({
    required this.questionId,
    required this.selectedOptionIds,
    DateTime? answeredAt,
  }) : answeredAt = answeredAt ?? DateTime.now();
}
```

`recommendation_result.dart`

```dart
import '../../../university/domain/models/university_model.dart';
import '../../../university/domain/models/department_model.dart';

class RecommendationResult {
  final List<UniversityRecommendation> universities;
  final List<DepartmentRecommendation> departments;
  final String summary;     // "X şehrindeki Y bölümü senin için ideal"
  final DateTime generatedAt;

  RecommendationResult({
    required this.universities,
    required this.departments,
    required this.summary,
    DateTime? generatedAt,
  }) : generatedAt = generatedAt ?? DateTime.now();
}

class UniversityRecommendation {
  final UniversityModel university;
  final double score;        // 0-100 arası eşleşme skoru
  final List<String> reasons; // "Akademik kalitede önde", "İstediğin şehirde"
  UniversityRecommendation({
    required this.university,
    required this.score,
    required this.reasons,
  });
}

class DepartmentRecommendation {
  final DepartmentModel department;
  final UniversityModel university;
  final double score;
  final List<String> reasons;
  DepartmentRecommendation({
    required this.department,
    required this.university,
    required this.score,
    required this.reasons,
  });
}
```

### 8.4 RecommendationEngine — Skorlama Algoritması

`lib/features/recommendation/data/recommendation_engine.dart`

```dart
import '../../university/domain/models/university_model.dart';
import '../../university/domain/models/department_model.dart';
import '../domain/models/recommendation_answer.dart';
import '../domain/models/recommendation_result.dart';
import '../domain/question_bank.dart';

class RecommendationEngine {
  /// Algoritma:
  /// 1. Tüm üniversite + bölümleri al
  /// 2. Cevaplara göre filtre uygula (hard constraints)
  /// 3. Kalan adaylara puanlama uygula (soft preferences)
  /// 4. Top 3 üni + Top 5 bölüm döndür
  RecommendationResult generateRecommendations({
    required List<UniversityModel> universities,
    required List<DepartmentModel> departments,
    required Map<String, RecommendationAnswer> answers,
  }) {
    // ─── 1. Cevapları parse et ───────────────────────────────
    final criteria = _parseAnswers(answers);

    // ─── 2. Üniversiteleri filtrele + skorla ─────────────────
    var uniCandidates = universities;

    // Hard filter: Şehir
    if (criteria.cityIds.isNotEmpty) {
      uniCandidates = uniCandidates
          .where((u) => criteria.cityIds.contains(u.cityId))
          .toList();
    }

    // Hard filter: Tür
    if (criteria.uniType != null) {
      uniCandidates =
          uniCandidates.where((u) => u.type == criteria.uniType).toList();
    }

    // Hard filter: Kampüs (preferCampus weight 1.0 ise zorunlu)
    if (criteria.requireCampus) {
      uniCandidates = uniCandidates.where((u) => u.hasCampus).toList();
    }

    // Üni skorlama
    final scoredUnis = uniCandidates.map((uni) {
      var score = 50.0;
      final reasons = <String>[];

      // Kampüs tercih
      if (criteria.preferCampus && uni.hasCampus) {
        score += 10 * criteria.campusWeight;
        reasons.add('Kampüslü');
      }

      // Kategori puanları
      criteria.categoryWeights.forEach((cat, weight) {
        final rating = uni.categoryRatings[cat] ?? 0;
        if (rating >= 4.0) {
          score += rating * weight * 3;
          reasons.add('$cat\'da öne çıkıyor');
        }
      });

      // Genel puan
      if (uni.avgRating >= 4.5) {
        score += 10;
        reasons.add('Yüksek genel puan');
      } else if (uni.avgRating >= 4.0) {
        score += 5;
      }

      // Aktif yorum
      if (uni.reviewCount >= 10) score += 5;

      return UniversityRecommendation(
        university: uni,
        score: score.clamp(0, 100),
        reasons: reasons,
      );
    }).toList()
      ..sort((a, b) => b.score.compareTo(a.score));

    final topUnis = scoredUnis.take(3).toList();

    // ─── 3. Bölümleri filtrele + skorla ──────────────────────
    final topUniIds = topUnis.map((u) => u.university.id).toSet();
    var deptCandidates = departments
        .where((d) => topUniIds.contains(d.universityId))
        .toList();

    // Hard filter: Skor tipi
    if (criteria.scoreType != null) {
      deptCandidates = deptCandidates
          .where((d) =>
              d.scoreData?.scoreType == criteria.scoreType ||
              d.scoreType == criteria.scoreType)
          .toList();
    }

    // Hard filter: Dil
    if (criteria.preferLanguage != null) {
      deptCandidates = deptCandidates
          .where((d) => d.language == criteria.preferLanguage)
          .toList();
    }

    // Hard filter: Puan aralığı (±50 puan tolerans)
    if (criteria.scoreMin != null && criteria.scoreMax != null) {
      deptCandidates = deptCandidates.where((d) {
        final base = d.scoreData?.baseScore ?? d.baseScore;
        if (base == null) return true; // Veri yoksa geç
        return base >= criteria.scoreMin! - 50 &&
               base <= criteria.scoreMax! + 30;
      }).toList();
    }

    // Bölüm skorlama
    final scoredDepts = deptCandidates.map((dept) {
      final uni = topUnis.firstWhere(
        (u) => u.university.id == dept.universityId,
        orElse: () => topUnis.first,
      );
      var score = 50.0 + uni.score * 0.3; // üni skorunun %30'u taban
      final reasons = <String>[];

      // Puana yakınlık
      final base = dept.scoreData?.baseScore ?? dept.baseScore ?? 0;
      if (criteria.scoreMin != null && criteria.scoreMax != null) {
        final mid = (criteria.scoreMin! + criteria.scoreMax!) / 2;
        final delta = (base - mid).abs();
        if (delta < 30) {
          score += 15;
          reasons.add('Puan aralığına uygun');
        } else if (delta < 60) {
          score += 8;
        }
      }

      // Bölüm puanı
      if (dept.avgRating >= 4.0) {
        score += 8;
        reasons.add('Yüksek puanlı bölüm');
      }

      // Doluluk oranı (ÖSYM)
      if (dept.scoreData?.fillRate == 1.0) {
        score += 5;
        reasons.add('Tüm kontenjan dolmuş');
      }

      return DepartmentRecommendation(
        department: dept,
        university: uni.university,
        score: score.clamp(0, 100),
        reasons: reasons,
      );
    }).toList()
      ..sort((a, b) => b.score.compareTo(a.score));

    final topDepts = scoredDepts.take(5).toList();

    // ─── 4. Özet metni oluştur ────────────────────────────────
    final summary = _generateSummary(topUnis, topDepts, criteria);

    return RecommendationResult(
      universities: topUnis,
      departments: topDepts,
      summary: summary,
    );
  }

  _Criteria _parseAnswers(Map<String, RecommendationAnswer> answers) {
    final criteria = _Criteria();

    for (final question in QuestionBank.questions) {
      final answer = answers[question.id];
      if (answer == null) continue;

      for (final optionId in answer.selectedOptionIds) {
        final option =
            question.options.firstWhere((o) => o.id == optionId, orElse: () => question.options.first);

        // Skor tipi
        if (option.scoreType != null) criteria.scoreType = option.scoreType;
        // Puan aralığı
        if (option.scoreMin != null) criteria.scoreMin = option.scoreMin;
        if (option.scoreMax != null) criteria.scoreMax = option.scoreMax;
        // Şehirler (multi-select için cumulative)
        if (option.cityIds != null && option.cityIds!.isNotEmpty) {
          criteria.cityIds.addAll(option.cityIds!);
        }
        // Üni türü
        if (option.uniType != null) criteria.uniType = option.uniType;
        // Kampüs
        if (option.preferCampus) {
          criteria.preferCampus = true;
          criteria.campusWeight = option.weight;
          if (option.weight >= 1.0 && option.id == 'campus_critical') {
            criteria.requireCampus = true;
          }
        }
        // Dil
        if (option.preferLanguage != null) {
          criteria.preferLanguage = option.preferLanguage;
        }
        // Kategori ağırlıkları
        option.categoryWeights.forEach((k, v) {
          criteria.categoryWeights[k] = (criteria.categoryWeights[k] ?? 1.0) + v;
        });
      }
    }
    return criteria;
  }

  String _generateSummary(
    List<UniversityRecommendation> unis,
    List<DepartmentRecommendation> depts,
    _Criteria criteria,
  ) {
    if (unis.isEmpty) {
      return 'Verdiğin cevaplara uygun üniversite bulamadık. Filtreleri gevşeterek tekrar dene.';
    }

    final topUni = unis.first.university;
    final topDept = depts.isNotEmpty ? depts.first : null;

    if (topDept != null) {
      return '${topUni.name} bünyesindeki ${topDept.department.name} bölümü, '
             'tercihlerinle %${unis.first.score.toInt()} oranında uyumlu.';
    }
    return '${topUni.name}, tercihlerinle en uyumlu üniversite olarak öne çıktı.';
  }
}

class _Criteria {
  String? scoreType;
  double? scoreMin;
  double? scoreMax;
  Set<String> cityIds = {};
  String? uniType;
  bool preferCampus = false;
  bool requireCampus = false;
  double campusWeight = 1.0;
  String? preferLanguage;
  Map<String, double> categoryWeights = {};
}
```

### 8.5 Providers

`lib/features/recommendation/presentation/providers/recommendation_providers.dart`

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../university/presentation/providers/university_providers.dart';
import '../../data/recommendation_engine.dart';
import '../../domain/models/recommendation_answer.dart';
import '../../domain/models/recommendation_result.dart';
import '../../domain/question_bank.dart';

/// Mevcut soru indeksi
final currentQuestionIndexProvider = StateProvider<int>((_) => 0);

/// Cevaplar — questionId → answer
final recommendationAnswersProvider =
    StateProvider<Map<String, RecommendationAnswer>>((_) => {});

/// Mevcut soru
final currentQuestionProvider = Provider((ref) {
  final idx = ref.watch(currentQuestionIndexProvider);
  if (idx >= QuestionBank.questions.length) return null;
  return QuestionBank.questions[idx];
});

/// İlerleme yüzdesi
final recommendationProgressProvider = Provider<double>((ref) {
  final idx = ref.watch(currentQuestionIndexProvider);
  return idx / QuestionBank.questions.length;
});

/// Sonuç hesaplama
final recommendationResultProvider = FutureProvider<RecommendationResult>((ref) async {
  final answers = ref.watch(recommendationAnswersProvider);
  final unis = await ref.read(allUniversitiesProvider.future);

  // Tüm bölümleri al (paralel)
  final deptsFutures = unis.map((u) =>
    ref.read(departmentsByUniversityProvider(u.id).future));
  final deptsList = await Future.wait(deptsFutures);
  final allDepts = deptsList.expand((e) => e).toList();

  return RecommendationEngine().generateRecommendations(
    universities: unis,
    departments: allDepts,
    answers: answers,
  );
});
```

### 8.6 Ekranlar

#### 8.6.1 `RecommendationIntroScreen` — Karşılama

```dart
class RecommendationIntroScreen extends ConsumerWidget {
  const RecommendationIntroScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.auto_awesome_rounded,
                  size: 80, color: AppColors.primary),
              const SizedBox(height: 24),
              Text('Tercih Asistanı', style: AppTextStyles.displaySmall),
              const SizedBox(height: 8),
              Text(
                'Sana 8 kısa soru soracağım, hayalindeki üniversiteyi birlikte bulalım.',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 40),
              GradientButton(
                text: 'Başla',
                icon: Icons.rocket_launch_rounded,
                onPressed: () {
                  // Reset state
                  ref.read(currentQuestionIndexProvider.notifier).state = 0;
                  ref.read(recommendationAnswersProvider.notifier).state = {};
                  context.push('/recommend/chat');
                },
              ),
              const SizedBox(height: 12),
              Text('Yaklaşık 2 dakika sürer',
                  style: AppTextStyles.labelSmall),
            ],
          ),
        ),
      ),
    );
  }
}
```

#### 8.6.2 `RecommendationChatScreen` — Soru-Cevap

```dart
class RecommendationChatScreen extends ConsumerStatefulWidget {
  const RecommendationChatScreen({super.key});
  // ...
}

class _RecommendationChatScreenState extends ConsumerState<RecommendationChatScreen> {
  final List<String> _selectedIds = [];

  @override
  Widget build(BuildContext context) {
    final question = ref.watch(currentQuestionProvider);
    final progress = ref.watch(recommendationProgressProvider);

    if (question == null) {
      // Tüm sorular tamamlandı → result'a yönlendir
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.pushReplacement('/recommend/result');
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Soru ${ref.watch(currentQuestionIndexProvider) + 1} / 8'),
      ),
      body: Column(
        children: [
          LinearProgressIndicator(
            value: progress,
            backgroundColor: AppColors.borderLight,
            valueColor: const AlwaysStoppedAnimation(AppColors.primary),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Robot avatarı + soru baloncuğu
                  ChatBubble(
                    message: question.question,
                    hint: question.hint,
                  ),
                  const SizedBox(height: 24),

                  // Seçenekler (chip ya da büyük buton)
                  ...question.options.map((opt) => _OptionTile(
                    option: opt,
                    isSelected: _selectedIds.contains(opt.id),
                    isMulti: question.type == QuestionType.multiSelect,
                    onTap: () {
                      setState(() {
                        if (question.type == QuestionType.singleSelect) {
                          _selectedIds
                            ..clear()
                            ..add(opt.id);
                        } else {
                          if (_selectedIds.contains(opt.id)) {
                            _selectedIds.remove(opt.id);
                          } else {
                            _selectedIds.add(opt.id);
                          }
                        }
                      });
                    },
                  )),
                ],
              ),
            ),
          ),
          // Devam et butonu
          Padding(
            padding: const EdgeInsets.all(16),
            child: SafeArea(
              top: false,
              child: GradientButton(
                text: ref.watch(currentQuestionIndexProvider) ==
                       QuestionBank.questions.length - 1
                    ? 'Tamamla'
                    : 'Devam Et',
                icon: Icons.arrow_forward_rounded,
                onPressed: _selectedIds.isEmpty && !question.isOptional
                    ? null
                    : _onNext,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onNext() {
    final question = ref.read(currentQuestionProvider)!;
    final answers = {...ref.read(recommendationAnswersProvider)};
    answers[question.id] = RecommendationAnswer(
      questionId: question.id,
      selectedOptionIds: List.from(_selectedIds),
    );
    ref.read(recommendationAnswersProvider.notifier).state = answers;
    ref.read(currentQuestionIndexProvider.notifier).state++;
    setState(() => _selectedIds.clear());
  }
}
```

#### 8.6.3 `RecommendationResultScreen`

```dart
class RecommendationResultScreen extends ConsumerWidget {
  const RecommendationResultScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resultAsync = ref.watch(recommendationResultProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Önerilerim'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Yeniden başlat',
            onPressed: () => context.go('/recommend'),
          ),
        ],
      ),
      body: resultAsync.when(
        loading: () => _LoadingView(),  // Animasyonlu "Düşünüyorum..."
        error: (e, _) => ErrorStateWidget(message: '$e'),
        data: (result) {
          if (result.universities.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.search_off_rounded,
              title: 'Önerimiz yok',
              description: 'Verdiğin cevaplara uygun üniversite bulamadık. '
                          'Filtreleri gevşeterek tekrar dene.',
              actionText: 'Yeniden başla',
              onAction: () => context.go('/recommend'),
            );
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Özet kartı
              _SummaryCard(summary: result.summary),
              const SizedBox(height: 24),

              // Üniversite önerileri
              const _SectionTitle('Önerilen Üniversiteler'),
              ...result.universities.map((rec) => _UniRecommendationCard(rec: rec)),

              const SizedBox(height: 24),

              // Bölüm önerileri
              const _SectionTitle('Sana Uygun Bölümler'),
              ...result.departments.map((rec) => _DeptRecommendationCard(rec: rec)),

              const SizedBox(height: 24),

              // CTA: Liste oluştur
              if (result.departments.isNotEmpty)
                OutlinedButton.icon(
                  onPressed: () => _createListFromRecommendations(context, ref, result),
                  icon: const Icon(Icons.list_alt_rounded),
                  label: const Text('Bu önerilerden tercih listesi oluştur'),
                ),
            ],
          );
        },
      ),
    );
  }
}
```

### 8.7 Ana Sayfa Hero Banner Bağlantısı

`home_screen.dart` içindeki `_HeroBanner` widget'ını GestureDetector ile sarmala:

```dart
// _HeroBanner widget'ında
return GestureDetector(
  onTap: () => context.push('/recommend'),
  child: Container(
    /* ... mevcut içerik ... */
    child: Stack(
      children: [
        /* mevcut ... */
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  const Icon(Icons.auto_awesome_rounded,
                      color: Colors.white, size: 14),
                  const SizedBox(width: 6),
                  Text('Tercih Asistanı',
                    style: AppTextStyles.labelMedium.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Hayalindeki üniversiteyi\nbirlikte bulalım!',
                style: AppTextStyles.headlineMedium.copyWith(
                  color: Colors.white,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Başla',
                      style: AppTextStyles.labelLarge.copyWith(color: Colors.white)),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_forward_rounded,
                        color: Colors.white, size: 16),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  ),
);
```

### 8.8 Sprint 5+ İçin: Claude API Entegrasyonu

Bu sprint kural tabanlı kalır. Sprint 5'te Cloud Functions üzerinde Claude API'yi çağıran bir endpoint açılabilir:

```
[Kullanıcı cevapları] → Cloud Function → Claude API
                                          ↓
                                        Daha kişiselleştirilmiş öneri
```

> **NOT**: Claude API çağrıları için API key client'ta tutulamaz. Mutlaka Cloud Functions/backend üzerinden proxy gerekir. Sprint 5+ planına eklenmeli.

---

## 9. D5 — Genel Optimizasyon

> **Sahibi**: Ortak (Kişi A & B son 2 günde paralel çalışır)
> **Süre**: 2 gün (Gün 16–17)

### 9.1 Performans Hedefleri

| Metrik | Mevcut Durum (tahmin) | Hedef | Ölçüm Yöntemi |
|--------|------------------------|-------|---------------|
| Cold start (splash → home) | ~3 sn | < 2.5 sn | Stopwatch in `_navigateToNext` |
| Tab geçiş süresi | ~150ms | < 200ms (kabul) | Manuel görsel test |
| Üni listesi scroll | Çoğu zaman 60fps | Stabil 60fps | Flutter DevTools Performance |
| Firestore okuma sayısı (ana sayfa) | ~12 read | < 8 read | `cloud_firestore` debug log |
| Cache hit oranı | ~%50 | > %75 | UniversityRepository._isCacheValid loglama |
| APK boyutu | Bilinmiyor | < 30 MB (Android arm64) | `flutter build apk` çıktısı |

### 9.2 Optimizasyon Görev Listesi

#### Kişi A görevleri (Bölüm Sayfaları & Veri)

- [ ] **`UniversityRepository` cache TTL'ini 5dk → 15dk** çıkar (puan verisi az değişir)
- [ ] **`getDepartmentsByUniversity` için `Source.cache` fallback** ekle (offline çalışsın)
- [ ] **Department listesinde `RepaintBoundary`** ekle (her kart ayrı paint scope'ta)
- [ ] **`fl_chart` için `swapAnimationDuration`'ı azalt** (600ms → 400ms; ilk render hızlansın)
- [ ] **Ölü kod temizle**: `lib/scripts/cleanup_universities.dart` Sprint 1'de kullanıldıysa kaldır
- [ ] **`assets/data/places_seed.json`** prod build'de exclude et (sadece debug için)

#### Kişi B görevleri (Listeler & Robot)

- [ ] **`MyListsScreen`'de `ListView.builder` cache extent** = 1000 px
- [ ] **`RecommendationEngine` async işle** → `compute()` ile isolate'a taşı (300+ bölüm üzerinde sync hesap UI bloklayabilir)
- [ ] **Soru cevap state'lerini `autoDispose`** ile yönet (chat ekranından çıkınca temizlensin)
- [ ] **`PreferenceItem` ler için unused field'ları kaldır** (sadece denormalize için gerekli olanlar kalsın)
- [ ] **AI Robot result'ında `keepAlive: false`** — sonuç ekranı kapatıldığında dispose

#### Ortak (Yan Yana Pair Programming)

- [ ] **Firestore Composite Index audit**: `firestore.indexes.json` içindeki indexleri analiz et, kullanılmayanları kaldır (Firebase Console → Indexes → "Last used")
- [ ] **`flutter analyze` 0 warning** hedefi
- [ ] **`dart run flutter_launcher_icons` ile ikonları yeniden derle** (release boyut)
- [ ] **R8/ProGuard rules** Android için (`android/app/proguard-rules.pro` — Firebase için zaten ayarlı, kontrol et)
- [ ] **Image cache size** ayarla: `PaintingBinding.instance.imageCache.maximumSizeBytes = 50 * 1024 * 1024` (50 MB)
- [ ] **`pubspec.yaml`** içinde unused dependency kontrolü (`flutter pub deps`)

### 9.3 Profiling — Nereye Bakacaksın?

#### Flutter DevTools üzerinde
1. **Performance** tab → Frame chart → red frames (>16ms) yakala
2. **Memory** tab → Allocation summary → büyük objeleri tespit et
3. **Network** tab → Firestore call frequency

#### Firebase Console üzerinde
1. **Firestore → Usage** → Document reads / day → spike olduğunda hangi sayfa?
2. **Performance** → Network requests → yavaş istekleri tespit et
3. **Crashlytics** → uygulama yayında değil, test cihazından log al

### 9.4 Splash Screen Optimizasyonu

`splash_screen.dart` zaten 2.5 sn minimum split ekran ve veri prefetch yapıyor. Sprint 4.5'te:

```dart
// Eski: 4 paralel future bekler
await Future.wait([
  ref.read(citiesProvider.future),
  ref.read(popularUniversitiesProvider.future),
  ref.read(recentReviewsProvider.future),
  ref.read(currentUserProvider.future),
]);

// Yeni: minimum gerekli + arka planda diğerleri
final critical = await Future.wait([
  ref.read(citiesProvider.future),     // Home için zorunlu
  ref.read(currentUserProvider.future), // Auth için zorunlu
]).timeout(const Duration(seconds: 3), onTimeout: () => []);

// İyileştirme yok, başla
// (popular ve reviews home açıldıktan sonra Riverpod kendi yükler)
```

### 9.5 APK Boyut Küçültme

```yaml
# pubspec.yaml
flutter:
  uses-material-design: true
  assets:
    - assets/icons/
    - assets/logos/      # ÖNEMLİ: png yerine webp kullan
    - assets/city_logos/
    - assets/data/department_scores.json
    - assets/splash/

  # places_seed.json prod'da yok!
  # assets:
  #   - assets/data/places_seed.json   ← KALDIR
```

```bash
# AAB build (Play Store için optimize)
flutter build appbundle --release --obfuscate --split-debug-info=build/symbols

# Boyut analizi
flutter build apk --release --analyze-size --target-platform=android-arm64
```

### 9.6 Memory Leak Kontrolü

- [ ] Tüm `StreamSubscription`'lar `dispose`'da cancel ediliyor mu?
- [ ] `AnimationController`'lar dispose ediliyor mu?
- [ ] `TextEditingController`'lar dispose ediliyor mu?
- [ ] `Timer`'lar cancel ediliyor mu? (Search debounce vb.)

> 🔍 **Hızlı arama**: VS Code → "Search in Files" → `late ... Controller` → her birinin dispose'u var mı kontrol et.

### 9.7 Regression Test Senaryoları

Optimizasyon sonrası tüm kritik akışları manuel test et:

1. **Auth akışı**: Login → Register → Logout → Forgot password
2. **Onboarding**: İlk açılış → Atla / Devam et
3. **Ana sayfa**: Tüm bölümler render → search çalışıyor → notification bell → hero banner → recommend'e gidiyor
4. **Üni detay**: Tabs → bölümler → mekanlar → yorumlar → galeri
5. **Bölüm detay**: Yeni puan kartları → trend grafiği render
6. **Yorum yazma**: Yıldız → kategori → fotoğraf upload → submit
7. **Tercih listesi**: Oluştur → bölüm ekle → sırala → paylaş → public link kontrol
8. **AI Robot**: Tüm sorular → result ekranı → "liste oluştur" CTA
9. **Karşılaştırma**: 2 üni seç → tüm sekmeler

---

## 10. Gün Gün Takvim

### Hafta 1: Temeller

| Gün | Kişi A | Kişi B | Notlar |
|-----|--------|--------|--------|
| **1** (Pzt) | YÖK Atlas eşleşme tablosu çıkarma (manuel) + scraper script setup | `PreferenceListModel` + `PreferenceItem` modelleri yaz | İlk gün senkronizasyon: kim hangi paylaşılan dosyaya dokunacak? |
| **2** (Sal) | Python scraper test (5 üni × 10 bölüm pilot) | `PreferenceListRepository` yaz + unit test | Daily sync 09:30 |
| **3** (Çar) | Tüm 30 üni için scrape, `department_scores.json` oluştur | `MyListsScreen` UI iskelet + provider'lar | Kişi B akşam: firestore.rules güncellemesi (kişi A inceler) |
| **4** (Per) | `DepartmentModel` + `DepartmentScoreData` modeli, migration script | `ListEditScreen` + `ReorderableListView` | İlk merge to dev: temel modeller hazır |
| **5** (Cum) | Firestore'a yükleme (debug butonu), test → çalışıyor mu? | `ListDetailScreen` + `ShareListSheet` | Hafta sonu: kişi A scraping son rötuşları |

### Hafta 2: UI & AI Robot

| Gün | Kişi A | Kişi B | Notlar |
|-----|--------|--------|--------|
| **6** (Pzt) | `ScoreBadge` + `DepartmentCard` widget'ları | `SharedListScreen` + slug routing | Kişi B: app_router.dart'a list route'ları eklenir |
| **7** (Sal) | `ScoreTrendChart` + `DepartmentDetailScreen` yenileme | AI Robot soru bankası + modeller | Kişi B: app_shell.dart bottom nav değişikliği |
| **8** (Çar) | `uni_departments_screen` yeni kart + filtre (P1) | `RecommendationEngine` algoritma | Kişi A görev tamamlanma noktasına yakın |
| **9** (Per) | Gözden geçirme + bug fix + dokümantasyon | `RecommendationChatScreen` UI | İkinci merge to dev: tüm UI değişiklikleri |
| **10** (Cum) | Bölüm puan filtresi (Opsiyonel P1) | `RecommendationResultScreen` + intro | Hafta sonu: cross-review yap |

### Hafta 3: Entegrasyon & Optimizasyon

| Gün | Kişi A | Kişi B | Notlar |
|-----|--------|--------|--------|
| **11** (Pzt) | Bug fix tour (kendi feature'larında) | Hero banner bağlantısı + bug fix | Daily sync özellikle önemli |
| **12** (Sal) | Karşılaştırma ekranında bölüm puanı integrasyonu | Profil ekranı "Favorilerim" linki | Üçüncü merge to dev |
| **13** (Çar) | **OPTIMIZATION DAY 1** — kendi alanı | **OPTIMIZATION DAY 1** — kendi alanı | Daily sync uzar (30 dk) |
| **14** (Per) | **OPTIMIZATION DAY 2** — pair programming | **OPTIMIZATION DAY 2** — pair programming | Yan yana çalış: Firestore index audit, dependency cleanup |
| **15** (Cum) | Regression test (ilk yarı) | Regression test (ikinci yarı) | Manuel test, bug listesi çıkar |
| **16** (Pzt) | Bug fixes round 1 | Bug fixes round 1 | |
| **17** (Sal) | Bug fixes round 2 + sprint sonu PR'ları | Bug fixes round 2 + sprint sonu PR'ları | Sprint demo akşamı |

> 💡 **Esneklik**: Bu takvim 17 gün üzerinden. Eğer özel/banka tatili veya ek görevler çıkarsa Hafta 3'e gün eklenebilir.

---

## 11. Test Stratejisi

### 11.1 Unit Test Hedefleri

```
test/
├── features/
│   ├── recommendation/
│   │   └── data/
│   │       └── recommendation_engine_test.dart   ← Kişi B yazar
│   ├── preference_lists/
│   │   └── data/
│   │       └── preference_list_repository_test.dart ← Kişi B yazar
│   └── university/
│       └── domain/models/
│           └── department_model_test.dart        ← Kişi A yazar
```

### 11.2 Önerilen Unit Testler

#### `recommendation_engine_test.dart`
```dart
test('kullanıcı SAY tercihi ile sadece SAY bölümleri öner', () {
  final result = engine.generateRecommendations(
    universities: testUnis,
    departments: testDepts,
    answers: {
      'department_group': RecommendationAnswer(
        questionId: 'department_group',
        selectedOptionIds: ['engineering'],
      ),
    },
  );
  expect(result.departments.every((d) =>
    d.department.scoreData?.scoreType == 'SAY'), isTrue);
});

test('boş cevaplarda tüm üniversiteler skor alır', () {
  final result = engine.generateRecommendations(
    universities: testUnis,
    departments: testDepts,
    answers: {},
  );
  expect(result.universities.length, lessThanOrEqualTo(3));
  expect(result.universities, isNotEmpty);
});

test('imkansız kombinasyonda boş sonuç döner', () {
  // İstanbul'da Devlet üni + 700+ puan + 2024 → muhtemelen boş
  final result = engine.generateRecommendations(/* ... */);
  expect(result.universities, isEmpty);
  expect(result.summary, contains('uygun'));
});
```

#### `preference_list_repository_test.dart`
```dart
test('slug 5 karakterli olmalı', () async {
  final list = await repo.createList(title: 'Test');
  expect(list.shareSlug.length, equals(5));
  expect(RegExp(r'^[a-z0-9]+$').hasMatch(list.shareSlug), isTrue);
});

test('max 10 liste limiti', () async {
  for (var i = 0; i < 10; i++) {
    await repo.createList(title: 'Liste $i');
  }
  expect(() async => await repo.createList(title: 'Aşkın'),
         throwsException);
});

test('max 24 öğe limiti', () async {
  // 25 item ile update denerse throw
});
```

### 11.3 Widget Test Hedefleri (Opsiyonel — P1)

Mevcut sprintte widget test yok ama şu kritik bileşenler için yazılabilir:
- `DepartmentCard` — scoreData null/var senaryoları
- `ScoreTrendChart` — 1 yıl, 2 yıl, 3 yıl veri varyasyonları
- `ChatBubble` — ekrana sığma, multi-line

### 11.4 Manuel Test Senaryoları

#### Kişi A bitirdiğinde test edilecek

1. ✅ Profil > Debug > "Bölüm Puanlarını Yükle" → snackbar → veriler Firestore'da
2. ✅ Üni detay > Bölümler tab → yeni kart UI render
3. ✅ Bölüm detay > Trend grafik render → 3 nokta görünüyor
4. ✅ Üni detay > Bölümler > "Tümünü gör" → liste tamamı
5. ✅ Karşılaştırma > "Ortalama Taban" → sıfırdan farklı
6. ✅ Offline (uçak modu) → cache'den render

#### Kişi B bitirdiğinde test edilecek

1. ✅ Bottom nav 4. tab → "Listelerim"
2. ✅ Yeni liste oluştur → snackbar → ana ekranda görünür
3. ✅ Liste düzenle → bölüm ekle → drag-drop → sıra değişiyor
4. ✅ Liste paylaş → public toggle → URL kopyala → tarayıcıda aç → görüntüle
5. ✅ Logout → public URL'yi aç → "Giriş Yap" görünür → liste yine görünür
6. ✅ Anasayfa hero banner tıkla → AI Robot intro
7. ✅ AI Robot tüm soruları cevapla → result ekranı
8. ✅ Result > "Liste oluştur" CTA → otomatik liste oluştur

### 11.5 CI/CD (Opsiyonel)

```yaml
# .github/workflows/sprint-4-5.yml
name: Sprint 4.5 CI
on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
      - run: flutter pub get
      - run: flutter analyze
      - run: flutter test
```

---

## 12. Sprint Sonu Definition of Done

Sprint kapatılmadan önce **TÜM** maddeler tikli olmalı:

### 🟢 D1 — ÖSYM Verisi
- [ ] `assets/data/department_scores.json` repo'da, en az 250+ kayıt içeriyor
- [ ] Migration script Profil > Debug üzerinden çalışıyor, hata vermiyor
- [ ] Firestore'da bölümlerin `scoreData` alanı dolu
- [ ] Yeni `DepartmentScoreData` model toMap/fromMap testleri geçiyor

### 🟢 D2 — Bölüm UI
- [ ] `DepartmentCard` puan + sıralama + delta gösterir (scoreData varsa)
- [ ] `ScoreTrendChart` 3 yıllık trendi çizgi grafikle gösterir
- [ ] Bölüm detay sayfası 4 kartlık info grid içerir
- [ ] Eski `_DepartmentCard` (uni_departments_screen içindeki) silindi/değiştirildi

### 🟢 D3 — Tercih Listeleri
- [ ] Bottom nav'da "Listelerim" tab'ı var, eski Favoriler tab'ı kaldırıldı
- [ ] Profilde "Favorilerim" linki var (mevcut özellik korundu)
- [ ] CRUD: oluştur, düzenle, sil, içerik değiştir
- [ ] Drag-drop sıralama
- [ ] Public paylaşım: 5-karakter slug, görüntüle, view count
- [ ] Firestore rules güncellendi, indexler eklendi
- [ ] Limit'ler enforce ediliyor: max 10 liste/user, max 24 öğe/liste

### 🟢 D4 — AI Robot
- [ ] Anasayfa hero banner tıklanabilir, `/recommend`'e gidiyor
- [ ] 8 soruluk akış (sınamak için tüm sorular cevaplanır)
- [ ] Multi-select sorularda en az 1 seçim zorunlu
- [ ] Result ekranı: 3 üni + 5 bölüm öneri
- [ ] Her öneride en az 1 "neden" rozeti
- [ ] "Bu önerilerden liste oluştur" CTA çalışıyor

### 🟢 D5 — Optimizasyon
- [ ] `flutter analyze` 0 hata
- [ ] `flutter test` tüm testler yeşil
- [ ] Cold start < 2.5 sn (test cihazında)
- [ ] APK release boyutu < 30 MB (arm64)
- [ ] Tüm regression senaryoları geçiyor (Bölüm 11.4)
- [ ] Sprint sonu demo cihazda 5 dakika kullanım çökme yok

### 🟢 Genel
- [ ] `dev` branch'i `main`'e merge edildi
- [ ] Sprint Notları dokümanı yazıldı (`docs/sprint-4-5-notes.md`)
- [ ] Sprint 5 için açık kalan taskler GitHub Issue'da
- [ ] Demo videosu çekildi (1-2 dk, sprint hedefleri)

---

## 13. Riskler ve Çözümler

| # | Risk | Olasılık | Etki | Çözüm |
|---|------|----------|------|-------|
| 1 | YÖK Atlas HTML yapısı değişir, scraper bozulur | Orta | Yüksek | Manuel CSV fallback (1 günlük insan emeği). Test pilotunu mutlaka Gün 2'de yap. |
| 2 | Firestore composite index oluşumu 5+ dakika sürer | Yüksek | Düşük | Sprint başında firestore.indexes.json'ı tek seferde push et, deploy et |
| 3 | İki kişi aynı paylaşılan dosyaya aynı anda dokunur | Orta | Orta | "Saat dilimleri" + Slack rezervasyon (Bölüm 4.2) |
| 4 | AI Robot algoritması saçma sonuçlar üretir (örnek: ODTÜ tıp gibi) | Düşük | Orta | Hard filtre öncesinde + sıfırdan farklı veri varlığı kontrolü |
| 5 | Public liste URL'si ile spam paylaşımı | Düşük | Yüksek | Liste view count + Cloud Function ile rate limit (Sprint 5) |
| 6 | Slug çakışması (1/52^5 = 1/380M ama olabilir) | Çok Düşük | Düşük | `_findUniqueSlug` 5 deneme + 6 karaktere fallback |
| 7 | `fl_chart` paketinin trend grafiği prod'da render hatası | Düşük | Orta | Sprint başında basit bir test ekranında doğrula |
| 8 | Bottom nav'da 4. tab değişimi mevcut deeplinkleri bozar | Orta | Orta | `/favorites` route'u kalır, sadece bottom nav değişir; deeplinkler test et |
| 9 | Tercih listesi ekranında 24 kart (animasyonlu) ile FPS düşer | Düşük | Düşük | `RepaintBoundary` + `cacheExtent` ile mitige edilir |
| 10 | Sprint sonu çakışıp 17 günde bitmez | Orta | Orta | P1 görevleri (filtre, opsiyonel test) Sprint 5'e atılabilir |

---

## 📌 Sprint 4.5 Kapanış Kontrol Listesi

```
✅ Tüm D1-D5 görevleri DoD'yi karşılıyor
✅ Manuel regression test geçti (Bölüm 11.4)
✅ Sprint demo videosu çekildi
✅ docs/sprint-4-5-notes.md yazıldı
✅ Sprint 5 önceliklendirme toplantısı planlandı
✅ Tüm branch'ler temizlendi (merged feature branches silindi)
✅ Yeni kullanıcı testi yapıldı (1-2 lise öğrencisiyle)
```

---

## 🚀 Sprint 5'e Geçiş Notları

Sprint 4.5 bitince Sprint 5 hedeflerini yeniden değerlendirmek lazım. Sprint 5 normalde:
- ✅ UI/UX polish (artık daha fazla içerik var, daha iyi gösterilebilir)
- ✅ Beta test (gerçek liseliler ile)
- ✅ Store hazırlığı
- ✅ Bug fix marathon

Sprint 4.5'ten Sprint 5'e taşınabilecek konular:
- 🔵 Claude API entegrasyonu (kural tabanlı → gerçek LLM)
- 🔵 Bölüm puan filtresi (P1)
- 🔵 Tercih listesi yorumları
- 🔵 Cloud Function ile yıllık otomatik puan güncelleme

---

**Son hatırlatma**: Bu plan **rehber niteliğinde**, sprint içinde gerçeklik plana uymazsa **kararlı şekilde kes ve özet** — yayın tarihi (Temmuz 2026) kritik. P1 görevlerini Sprint 5'e atmak utanılacak bir şey değil; ürün kalitesi tüm görevleri yapmaktan daha önemli.

İyi sprintler! 🎓
