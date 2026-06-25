import '../../l10n/generated/app_localizations.dart';

String localizedUniversityType(AppLocalizations loc, String value) {
  final normalized = value.trim().toLowerCase();
  switch (normalized) {
    case 'devlet':
    case 'state':
      return loc.universityTypeState;
    case 'vakıf':
    case 'vakif':
    case 'foundation':
      return loc.universityTypeFoundation;
    default:
      return value;
  }
}

String localizedCampusLayout(AppLocalizations loc, String value) {
  final normalized = value.trim().toLowerCase();
  switch (normalized) {
    case 'campus':
    case 'kampüslü':
    case 'kampuslu':
      return loc.campusLayoutCampus;
    case 'block':
    case 'blok yerleşke':
    case 'blok yerleske':
      return loc.campusLayoutBlock;
    case 'distributed':
    case 'dağınık kampüs':
    case 'daginik kampus':
      return loc.campusLayoutDistributed;
    default:
      return value;
  }
}

String localizedDepartmentType(AppLocalizations loc, String value) {
  final normalized = value.trim().toLowerCase();
  switch (normalized) {
    case 'lisans':
    case 'undergraduate':
      return loc.departmentTypeUndergraduate;
    case 'önlisans':
    case 'onlisans':
    case 'associate':
    case 'associate degree':
      return loc.departmentTypeAssociate;
    default:
      return value;
  }
}

String localizedDepartmentLanguage(AppLocalizations loc, String value) {
  final normalized = value.trim().toLowerCase();
  switch (normalized) {
    case 'türkçe':
    case 'turkce':
    case 'turkish':
      return loc.departmentLanguageTurkish;
    case 'ingilizce':
    case 'i̇ngilizce':
    case 'english':
      return loc.departmentLanguageEnglish;
    default:
      return value;
  }
}
