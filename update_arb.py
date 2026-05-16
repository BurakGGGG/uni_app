import json

tr_file = '/home/burak/uni_app/lib/l10n/app_tr.arb'
en_file = '/home/burak/uni_app/lib/l10n/app_en.arb'

tr_data = json.load(open(tr_file))
en_data = json.load(open(en_file))

tr_data['profileTheme'] = 'Tema'
tr_data['themeSystem'] = 'Sistem'
tr_data['themeLight'] = 'Açık'
tr_data['themeDark'] = 'Koyu'
tr_data['themeSelection'] = 'Tema Seçimi'
tr_data['languageSelection'] = 'Dil Seçimi'
tr_data['turkish'] = 'Türkçe'
tr_data['english'] = 'English'

en_data['profileTheme'] = 'Theme'
en_data['themeSystem'] = 'System'
en_data['themeLight'] = 'Light'
en_data['themeDark'] = 'Dark'
en_data['themeSelection'] = 'Theme Selection'
en_data['languageSelection'] = 'Language Selection'
en_data['turkish'] = 'Türkçe'
en_data['english'] = 'English'

with open(tr_file, 'w', encoding='utf-8') as f:
    json.dump(tr_data, f, ensure_ascii=False, indent=2)

with open(en_file, 'w', encoding='utf-8') as f:
    json.dump(en_data, f, ensure_ascii=False, indent=2)

print("Done")
