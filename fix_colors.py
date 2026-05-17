import re

files = [
    '/home/burak/uni_app/lib/scripts/seed_data_service.dart',
    '/home/burak/uni_app/lib/scripts/city_brand_colors_migration.dart'
]

changes = {
    'anadolu': ('#212121', '#424242'),
    'hacibayram': ('#212121', '#D32F2F'),
    'ankara_uni': ('#0D47A1', '#FFB300'),
    'uludag': ('#00ACC1', '#0D47A1'),
    'comu': ('#D32F2F', '#212121'),
    'ogu': ('#00ACC1', '#0D47A1'),
    'estu': ('#800000', '#500000'),
    'gazi': ('#0D47A1', '#4DD0E1'),
    'hacettepe': ('#D32F2F', '#EF5350'),
    'hitit': ('#FF8F00', '#1A237E'),
    'aydin': ('#0D47A1', '#1565C0'),
    'gelisim': ('#1A237E', '#283593'),
    'medipol': ('#1A237E', '#757575'),
    'istanbul_uni': ('#1B5E20', '#2E7D32'),
    'izmir_demokrasi': ('#795548', '#C62828'),
    'izmir_katipcelebi': ('#B71C1C', '#880E4F'),
    'odtu': ('#D32F2F', '#EF5350'),
    'cumhuriyet': ('#D32F2F', '#B71C1C'),
    'yildiz_teknik': ('#FFB300', '#0D47A1'),
    'beun': ('#D32F2F', '#B71C1C')
}

for file_path in files:
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()

    for uid, (primary, secondary) in changes.items():
        if 'seed_data_service' in file_path:
            # {'id': 'itu', ..., 'brandPrimaryHex': '#1A237E', 'brandSecondaryHex': '#283593'}
            pattern1 = r"(\{'id':\s*'" + uid + r"'.*?'brandPrimaryHex':\s*')[^']+('.*?'brandSecondaryHex':\s*')[^']+(\})"
            content = re.sub(pattern1, rf"\g<1>{primary}\g<2>{secondary}\g<3>", content)
        else:
            # 'itu': {'p': '#1A237E', 's': '#283593', 'o': false},
            pattern2 = r"('" + uid + r"':\s*\{'p':\s*')[^']+('.*?'s':\s*')[^']+(\})"
            content = re.sub(pattern2, rf"\g<1>{primary}\g<2>{secondary}\g<3>", content)

    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(content)

print("Done")
