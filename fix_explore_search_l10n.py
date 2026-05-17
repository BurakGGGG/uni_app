import json

tr_file = '/home/burak/uni_app/lib/l10n/app_tr.arb'
en_file = '/home/burak/uni_app/lib/l10n/app_en.arb'

tr_data = json.load(open(tr_file))
en_data = json.load(open(en_file))

keys = {
    'exploreTitle': ('Keşfet', 'Explore'),
    'exploreSubtitle': ('Üniversiteleri keşfet, filtrele ve karşılaştır', 'Explore, filter and compare universities'),
    'exploreSearchHint': ('Üniversite ara...', 'Search universities...'),
    'exploreTypeState': ('Devlet', 'State'),
    'exploreTypeFoundation': ('Vakıf', 'Foundation'),
    'exploreFilters': ('Filtreler', 'Filters'),
    'exploreClear': ('Temizle', 'Clear'),
    'exploreUniType': ('Üniversite Türü', 'University Type'),
    'exploreCities': ('Şehirler', 'Cities'),
    'exploreCitiesError': ('Şehirler yüklenemedi', 'Failed to load cities'),
    'exploreNoResults': ('Sonuç bulunamadı', 'No results found'),
    'exploreNoResultsSub': ('Filtrelerinizi değiştirerek tekrar deneyin.', 'Try changing your filters.'),
    
    'searchError': ('Arama yapılırken bir hata oluştu.', 'An error occurred while searching.'),
    'searchNoResults': ('Sonuç bulunamadı', 'No results found'),
    'searchNoResultsSub': ('"{query}" aramasına uygun üniversite yok.', 'No university matching "{query}".'),
    'searchCampus': ('Kampüslü', 'Has Campus'),
    'searchEst': ('Kuruluş: {year}', 'Established: {year}'),
}

for k, (tr, en) in keys.items():
    tr_data[k] = tr
    en_data[k] = en

with open(tr_file, 'w', encoding='utf-8') as f:
    json.dump(tr_data, f, ensure_ascii=False, indent=2)

with open(en_file, 'w', encoding='utf-8') as f:
    json.dump(en_data, f, ensure_ascii=False, indent=2)

# explore_screen.dart
explore_file = '/home/burak/uni_app/lib/features/home/presentation/screens/explore_screen.dart'
with open(explore_file, 'r', encoding='utf-8') as f:
    content = f.read()

if "import '../../../../l10n/generated/app_localizations.dart';" not in content:
    content = content.replace(
        "import 'package:flutter/material.dart';",
        "import 'package:flutter/material.dart';\nimport '../../../../l10n/generated/app_localizations.dart';"
    )

if "final loc = AppLocalizations.of(context)!;" not in content:
    content = content.replace(
        "final filters = ref.watch(exploreFilterProvider);",
        "final filters = ref.watch(exploreFilterProvider);\n    final loc = AppLocalizations.of(context)!;"
    )

replacements_explore = [
    ("'Keşfet'", 'loc.exploreTitle'),
    ("'Üniversiteleri keşfet, filtrele ve karşılaştır'", 'loc.exploreSubtitle'),
    ("'Devlet'", 'loc.exploreTypeState'),
    ("'Vakıf'", 'loc.exploreTypeFoundation'),
    ("'Filtreler'", 'loc.exploreFilters'),
    ("'Temizle'", 'loc.exploreClear'),
    ("'Üniversite Türü'", 'loc.exploreUniType'),
    ("'Şehirler'", 'loc.exploreCities'),
    ("'Şehirler yüklenemedi'", 'loc.exploreCitiesError'),
    ("'Sonuç bulunamadı'", 'loc.exploreNoResults'),
    ("'Filtrelerinizi değiştirerek tekrar deneyin.'", 'loc.exploreNoResultsSub'),
]

for old, new in replacements_explore:
    content = content.replace(old, new)

with open(explore_file, 'w', encoding='utf-8') as f:
    f.write(content)

# search_screen.dart
search_file = '/home/burak/uni_app/lib/features/home/presentation/screens/search_screen.dart'
with open(search_file, 'r', encoding='utf-8') as f:
    content = f.read()

if "import '../../../../l10n/generated/app_localizations.dart';" not in content:
    content = content.replace(
        "import 'package:flutter/material.dart';",
        "import 'package:flutter/material.dart';\nimport '../../../../l10n/generated/app_localizations.dart';"
    )

if "final loc = AppLocalizations.of(context)!;" not in content:
    content = content.replace(
        "final query = ref.watch(searchQueryProvider);",
        "final query = ref.watch(searchQueryProvider);\n    final loc = AppLocalizations.of(context)!;"
    )

replacements_search = [
    ("'Üniversite ara...'", 'loc.exploreSearchHint'),
    ("'Arama yapılırken bir hata oluştu.'", 'loc.searchError'),
    ("'Sonuç bulunamadı'", 'loc.searchNoResults'),
    ("'\"$query\" aramasına uygun üniversite yok.'", "loc.searchNoResultsSub.replaceAll('{query}', query)"),
    ("'Kampüslü'", 'loc.searchCampus'),
    ("'${uni.type} • Kuruluş: ${uni.establishedYear}'", "'${uni.type == \\'Devlet\\' ? loc.exploreTypeState : loc.exploreTypeFoundation} • ' + loc.searchEst.replaceAll('{year}', uni.establishedYear.toString())"),
    ("uni.type == 'Devlet' ? AppColors.stateUni : AppColors.foundationUni", "uni.type == 'Devlet' ? AppColors.stateUni : AppColors.foundationUni"),
    ("uni.type,", "uni.type == 'Devlet' ? loc.exploreTypeState : loc.exploreTypeFoundation,"),
]

for old, new in replacements_search:
    content = content.replace(old, new)

with open(search_file, 'w', encoding='utf-8') as f:
    f.write(content)

print("Done")
