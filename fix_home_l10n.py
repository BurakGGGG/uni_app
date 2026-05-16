import json
import re

tr_file = '/home/burak/uni_app/lib/l10n/app_tr.arb'
en_file = '/home/burak/uni_app/lib/l10n/app_en.arb'

tr_data = json.load(open(tr_file))
en_data = json.load(open(en_file))

keys = {
    'homeGreeting': ('Merhaba! 👋', 'Hello! 👋'),
    'homePopularUniversities': ('Popüler Üniversiteler', 'Popular Universities'),
    'homeSeeAll': ('Tümünü Gör', 'See All'),
    'homeCities': ('Şehirler', 'Cities'),
    'homeCitiesLoadError': ('Şehirler yüklenemedi', 'Failed to load cities'),
    'homeRecentReviews': ('Son Yorumlar', 'Recent Reviews'),
    'homeNoReviews': ('Henüz yorum yok', 'No reviews yet'),
    'homeFirstReview': ('İlk yorumu yazan siz olun!', 'Be the first to write a review!'),
    'homeAssistantTitle': ('Tercih Asistanı', 'Preference Assistant'),
    'homeAssistantSubtitle': ('Hayalindeki üniversiteyi\nbirlikte bulalım!', 'Let\'s find your dream\nuniversity together!'),
    'homeStart': ('Başla', 'Start'),
}

for k, (tr, en) in keys.items():
    tr_data[k] = tr
    en_data[k] = en

with open(tr_file, 'w', encoding='utf-8') as f:
    json.dump(tr_data, f, ensure_ascii=False, indent=2)

with open(en_file, 'w', encoding='utf-8') as f:
    json.dump(en_data, f, ensure_ascii=False, indent=2)

home_file = '/home/burak/uni_app/lib/features/home/presentation/screens/home_screen.dart'
with open(home_file, 'r', encoding='utf-8') as f:
    home_content = f.read()

# Add import if missing
if "import '../../../../l10n/generated/app_localizations.dart';" not in home_content:
    home_content = home_content.replace(
        "import 'package:flutter/material.dart';",
        "import 'package:flutter/material.dart';\nimport '../../../../l10n/generated/app_localizations.dart';"
    )

# Add loc variable
if "final loc = AppLocalizations.of(context)!;" not in home_content:
    home_content = home_content.replace(
        "final citiesAsync = ref.watch(citiesProvider);",
        "final loc = AppLocalizations.of(context)!;\n    final citiesAsync = ref.watch(citiesProvider);"
    )

# Replace strings
replacements = [
    ("'Merhaba! 👋'", 'loc.homeGreeting'),
    ("'Popüler Üniversiteler'", 'loc.homePopularUniversities'),
    ("'Tümünü Gör'", 'loc.homeSeeAll'),
    ("'Şehirler'", 'loc.homeCities'),
    ("'Şehirler yüklenemedi'", 'loc.homeCitiesLoadError'),
    ("'Son Yorumlar'", 'loc.homeRecentReviews'),
    ("'Henüz yorum yok'", 'loc.homeNoReviews'),
    ("'İlk yorumu yazan siz olun!'", 'loc.homeFirstReview'),
    ("'Tercih Asistanı'", 'loc.homeAssistantTitle'),
    ("'Hayalindeki üniversiteyi\\nbirlikte bulalım!'", 'loc.homeAssistantSubtitle'),
    ("'Başla'", 'loc.homeStart'),
]

for old, new in replacements:
    home_content = home_content.replace(old, new)

with open(home_file, 'w', encoding='utf-8') as f:
    f.write(home_content)

print("Done")
