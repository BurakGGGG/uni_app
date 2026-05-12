import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_tr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('tr'),
  ];

  /// Karşılaştırma hub ekranı başlığı
  ///
  /// In tr, this message translates to:
  /// **'Karşılaştır'**
  String get comparisonHubTitle;

  /// No description provided for @comparisonUniversity.
  ///
  /// In tr, this message translates to:
  /// **'Üniversite Karşılaştır'**
  String get comparisonUniversity;

  /// No description provided for @comparisonUniversityDesc.
  ///
  /// In tr, this message translates to:
  /// **'İki üniversiteyi yan yana kıyasla'**
  String get comparisonUniversityDesc;

  /// No description provided for @comparisonDepartment.
  ///
  /// In tr, this message translates to:
  /// **'Bölüm Karşılaştır'**
  String get comparisonDepartment;

  /// No description provided for @comparisonDepartmentDesc.
  ///
  /// In tr, this message translates to:
  /// **'Aynı bölümü farklı üniversitelerde kıyasla'**
  String get comparisonDepartmentDesc;

  /// No description provided for @comparisonCity.
  ///
  /// In tr, this message translates to:
  /// **'Şehir Karşılaştır'**
  String get comparisonCity;

  /// No description provided for @comparisonCityDesc.
  ///
  /// In tr, this message translates to:
  /// **'İki şehrin üniversite ekosistemini kıyasla'**
  String get comparisonCityDesc;

  /// No description provided for @selectUniversityA.
  ///
  /// In tr, this message translates to:
  /// **'Üniversite A'**
  String get selectUniversityA;

  /// No description provided for @selectUniversityB.
  ///
  /// In tr, this message translates to:
  /// **'Üniversite B'**
  String get selectUniversityB;

  /// No description provided for @selectDepartmentA.
  ///
  /// In tr, this message translates to:
  /// **'Bölüm A'**
  String get selectDepartmentA;

  /// No description provided for @selectDepartmentB.
  ///
  /// In tr, this message translates to:
  /// **'Bölüm B'**
  String get selectDepartmentB;

  /// No description provided for @selectCityA.
  ///
  /// In tr, this message translates to:
  /// **'Şehir A'**
  String get selectCityA;

  /// No description provided for @selectCityB.
  ///
  /// In tr, this message translates to:
  /// **'Şehir B'**
  String get selectCityB;

  /// No description provided for @swap.
  ///
  /// In tr, this message translates to:
  /// **'Yer Değiştir'**
  String get swap;

  /// No description provided for @share.
  ///
  /// In tr, this message translates to:
  /// **'Paylaş'**
  String get share;

  /// No description provided for @reset.
  ///
  /// In tr, this message translates to:
  /// **'Sıfırla'**
  String get reset;

  /// No description provided for @retry.
  ///
  /// In tr, this message translates to:
  /// **'Tekrar Dene'**
  String get retry;

  /// No description provided for @tabGeneral.
  ///
  /// In tr, this message translates to:
  /// **'Genel'**
  String get tabGeneral;

  /// No description provided for @tabCategories.
  ///
  /// In tr, this message translates to:
  /// **'Kategoriler'**
  String get tabCategories;

  /// No description provided for @tabChart.
  ///
  /// In tr, this message translates to:
  /// **'Grafik'**
  String get tabChart;

  /// No description provided for @tabStats.
  ///
  /// In tr, this message translates to:
  /// **'İstatistik'**
  String get tabStats;

  /// No description provided for @emptyStateTitle.
  ///
  /// In tr, this message translates to:
  /// **'İki {entityType} seç'**
  String emptyStateTitle(String entityType);

  /// No description provided for @loadingComparison.
  ///
  /// In tr, this message translates to:
  /// **'Karşılaştırma yükleniyor…'**
  String get loadingComparison;

  /// No description provided for @errorComparison.
  ///
  /// In tr, this message translates to:
  /// **'Karşılaştırma yüklenirken bir hata oluştu'**
  String get errorComparison;

  /// No description provided for @aiSummaryTitle.
  ///
  /// In tr, this message translates to:
  /// **'AI Analizi'**
  String get aiSummaryTitle;

  /// No description provided for @aiSummaryProRequired.
  ///
  /// In tr, this message translates to:
  /// **'AI Analizi Pro pakette aktif. Pro\'ya geçerek detaylı özeti açabilirsin.'**
  String get aiSummaryProRequired;

  /// No description provided for @aiSummaryLimitReached.
  ///
  /// In tr, this message translates to:
  /// **'Günlük {limit} AI özet hakkın doldu, yarın tekrar dene.'**
  String aiSummaryLimitReached(int limit);

  /// No description provided for @aiSummaryActive.
  ///
  /// In tr, this message translates to:
  /// **'Pro analizi aktif'**
  String get aiSummaryActive;

  /// No description provided for @aiSummaryRegenerate.
  ///
  /// In tr, this message translates to:
  /// **'Yeniden Üret'**
  String get aiSummaryRegenerate;

  /// No description provided for @watchAdToContinue.
  ///
  /// In tr, this message translates to:
  /// **'Reklamı İzle ve Devam Et'**
  String get watchAdToContinue;

  /// No description provided for @upgradePlus.
  ///
  /// In tr, this message translates to:
  /// **'Plus\'a Geç — Sınırsız'**
  String get upgradePlus;

  /// No description provided for @cancelForNow.
  ///
  /// In tr, this message translates to:
  /// **'Şimdilik Vazgeç'**
  String get cancelForNow;

  /// No description provided for @dailyLimitReached.
  ///
  /// In tr, this message translates to:
  /// **'Günlük karşılaştırma hakkın doldu'**
  String get dailyLimitReached;

  /// No description provided for @comparisonStarted.
  ///
  /// In tr, this message translates to:
  /// **'Karşılaştırma başladı'**
  String get comparisonStarted;

  /// No description provided for @scoreType.
  ///
  /// In tr, this message translates to:
  /// **'Puan Türü'**
  String get scoreType;

  /// No description provided for @baseScore.
  ///
  /// In tr, this message translates to:
  /// **'Taban Puan'**
  String get baseScore;

  /// No description provided for @ranking.
  ///
  /// In tr, this message translates to:
  /// **'Sıralama'**
  String get ranking;

  /// No description provided for @quota.
  ///
  /// In tr, this message translates to:
  /// **'Kontenjan'**
  String get quota;

  /// No description provided for @fillRate.
  ///
  /// In tr, this message translates to:
  /// **'Doluluk Oranı'**
  String get fillRate;

  /// No description provided for @duration.
  ///
  /// In tr, this message translates to:
  /// **'Süre'**
  String get duration;

  /// No description provided for @language.
  ///
  /// In tr, this message translates to:
  /// **'Dil'**
  String get language;

  /// No description provided for @type.
  ///
  /// In tr, this message translates to:
  /// **'Tür'**
  String get type;

  /// No description provided for @categoryRating.
  ///
  /// In tr, this message translates to:
  /// **'Kategori Puanı'**
  String get categoryRating;

  /// No description provided for @reviewCount.
  ///
  /// In tr, this message translates to:
  /// **'Yorum Sayısı'**
  String get reviewCount;

  /// No description provided for @averageRating.
  ///
  /// In tr, this message translates to:
  /// **'Ortalama Puan'**
  String get averageRating;

  /// No description provided for @establishedYear.
  ///
  /// In tr, this message translates to:
  /// **'Kuruluş Yılı'**
  String get establishedYear;

  /// No description provided for @stateUniversity.
  ///
  /// In tr, this message translates to:
  /// **'Devlet'**
  String get stateUniversity;

  /// No description provided for @foundationUniversity.
  ///
  /// In tr, this message translates to:
  /// **'Vakıf'**
  String get foundationUniversity;

  /// No description provided for @winner.
  ///
  /// In tr, this message translates to:
  /// **'Kazanan'**
  String get winner;

  /// No description provided for @tie.
  ///
  /// In tr, this message translates to:
  /// **'Berabere'**
  String get tie;

  /// No description provided for @noEnoughReviews.
  ///
  /// In tr, this message translates to:
  /// **'Yeterli yorum yok'**
  String get noEnoughReviews;

  /// No description provided for @trendInsufficient.
  ///
  /// In tr, this message translates to:
  /// **'Trend için yeterli yorum yok'**
  String get trendInsufficient;

  /// No description provided for @offline.
  ///
  /// In tr, this message translates to:
  /// **'İnternet bağlantısı yok'**
  String get offline;

  /// No description provided for @offlineDescription.
  ///
  /// In tr, this message translates to:
  /// **'Karşılaştırma yapmak için internete bağlan.'**
  String get offlineDescription;

  /// No description provided for @shareSubject.
  ///
  /// In tr, this message translates to:
  /// **'{uniA} vs {uniB} — Karşılaştırma'**
  String shareSubject(String uniA, String uniB);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'tr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'tr':
      return AppLocalizationsTr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
