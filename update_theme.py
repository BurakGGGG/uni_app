import re

with open('lib/core/theme/app_theme.dart', 'r') as f:
    content = f.read()

# Replace light with dark in a copied string
dark_theme_content = content[content.find('  static ThemeData get lightTheme {'):content.rfind('  }') + 3]

# Simple replacements for darkTheme
dark_theme_content = dark_theme_content.replace('get lightTheme', 'get darkTheme')
dark_theme_content = dark_theme_content.replace('Brightness.light', 'Brightness.dark')
dark_theme_content = dark_theme_content.replace('ColorScheme.light', 'ColorScheme.dark')

# Replace specific colors
replacements = {
    'AppColors.background': 'AppColors.darkBackground',
    'AppColors.surface': 'AppColors.darkSurface',
    'AppColors.surfaceVariant': 'AppColors.darkSurfaceVariant',
    'AppColors.textPrimary': 'Colors.white',
    'AppColors.textSecondary': 'Colors.grey.shade400',
    'AppColors.textTertiary': 'Colors.grey.shade600',
    'AppColors.borderLight': 'AppColors.darkSurfaceElevated',
    'AppColors.border': 'AppColors.darkSurfaceElevated',
    'AppColors.divider': 'AppColors.darkSurfaceElevated',
    'SystemUiOverlayStyle.dark': 'SystemUiOverlayStyle.light',
    'statusBarIconBrightness: Brightness.dark': 'statusBarIconBrightness: Brightness.light',
}

for k, v in replacements.items():
    dark_theme_content = dark_theme_content.replace(k, v)

# Add darkTheme before the last brace
content = content.replace('\n}\n', '\n' + dark_theme_content + '\n}\n')

with open('lib/core/theme/app_theme.dart', 'w') as f:
    f.write(content)

