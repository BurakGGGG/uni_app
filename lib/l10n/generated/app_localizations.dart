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

  /// No description provided for @viewProPlans.
  ///
  /// In tr, this message translates to:
  /// **'Pro Paketleri İncele'**
  String get viewProPlans;

  /// No description provided for @proChartLockedSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Bu grafik Pro paketinde.'**
  String get proChartLockedSubtitle;

  /// No description provided for @watchAdUnlockOneHour.
  ///
  /// In tr, this message translates to:
  /// **'Video İzle ve 1 Saat Ücretsiz Aç'**
  String get watchAdUnlockOneHour;

  /// No description provided for @adLoading.
  ///
  /// In tr, this message translates to:
  /// **'Reklam yükleniyor, lütfen bekleyin…'**
  String get adLoading;

  /// No description provided for @proChartsUnlockedOneHour.
  ///
  /// In tr, this message translates to:
  /// **'Pro grafikler ve özellikler 1 saatliğine başarıyla açıldı!'**
  String get proChartsUnlockedOneHour;

  /// No description provided for @adFailedRetry.
  ///
  /// In tr, this message translates to:
  /// **'Reklam yüklenemedi veya tamamlanmadı. Lütfen tekrar deneyin.'**
  String get adFailedRetry;

  /// No description provided for @chartHeatmapTitle.
  ///
  /// In tr, this message translates to:
  /// **'Kategori Karşılaştırması'**
  String get chartHeatmapTitle;

  /// No description provided for @chartTrendTitle.
  ///
  /// In tr, this message translates to:
  /// **'6 Aylık Puan Trendi'**
  String get chartTrendTitle;

  /// No description provided for @chartScatterTitle.
  ///
  /// In tr, this message translates to:
  /// **'Taban Puanı × Sıralama'**
  String get chartScatterTitle;

  /// No description provided for @chartScatterXAxis.
  ///
  /// In tr, this message translates to:
  /// **'Taban puanı'**
  String get chartScatterXAxis;

  /// No description provided for @chartScatterYAxis.
  ///
  /// In tr, this message translates to:
  /// **'Sıralama'**
  String get chartScatterYAxis;

  /// No description provided for @chartScaleLow.
  ///
  /// In tr, this message translates to:
  /// **'Düşük'**
  String get chartScaleLow;

  /// No description provided for @chartScaleHigh.
  ///
  /// In tr, this message translates to:
  /// **'Yüksek'**
  String get chartScaleHigh;

  /// No description provided for @chartNoData.
  ///
  /// In tr, this message translates to:
  /// **'Veri yok'**
  String get chartNoData;

  /// No description provided for @chartDepartmentLabel.
  ///
  /// In tr, this message translates to:
  /// **'Bölüm'**
  String get chartDepartmentLabel;

  /// No description provided for @tempProBadge.
  ///
  /// In tr, this message translates to:
  /// **'Pro aktif · {minutes} dk'**
  String tempProBadge(int minutes);

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

  /// No description provided for @authSignIn.
  ///
  /// In tr, this message translates to:
  /// **'Giriş yap'**
  String get authSignIn;

  /// No description provided for @authSignUp.
  ///
  /// In tr, this message translates to:
  /// **'Kayıt ol'**
  String get authSignUp;

  /// No description provided for @authEmailLabel.
  ///
  /// In tr, this message translates to:
  /// **'E-posta'**
  String get authEmailLabel;

  /// No description provided for @authEmailHint.
  ///
  /// In tr, this message translates to:
  /// **'ornek@universite.edu.tr'**
  String get authEmailHint;

  /// No description provided for @authPasswordLabel.
  ///
  /// In tr, this message translates to:
  /// **'Şifre'**
  String get authPasswordLabel;

  /// No description provided for @authPasswordHint.
  ///
  /// In tr, this message translates to:
  /// **'En az 6 karakter'**
  String get authPasswordHint;

  /// No description provided for @authForgotPassword.
  ///
  /// In tr, this message translates to:
  /// **'Şifremi unuttum'**
  String get authForgotPassword;

  /// No description provided for @authGoogleContinue.
  ///
  /// In tr, this message translates to:
  /// **'Google ile Giriş Yap'**
  String get authGoogleContinue;

  /// No description provided for @authNoAccount.
  ///
  /// In tr, this message translates to:
  /// **'Hesabın yok mu? '**
  String get authNoAccount;

  /// No description provided for @authHaveAccount.
  ///
  /// In tr, this message translates to:
  /// **'Zaten hesabın var mı? '**
  String get authHaveAccount;

  /// No description provided for @authShowPassword.
  ///
  /// In tr, this message translates to:
  /// **'Şifreyi göster'**
  String get authShowPassword;

  /// No description provided for @authHidePassword.
  ///
  /// In tr, this message translates to:
  /// **'Şifreyi gizle'**
  String get authHidePassword;

  /// No description provided for @authPasswordRequired.
  ///
  /// In tr, this message translates to:
  /// **'Şifre gerekli'**
  String get authPasswordRequired;

  /// No description provided for @authEmailRequired.
  ///
  /// In tr, this message translates to:
  /// **'E-posta adresi gerekli'**
  String get authEmailRequired;

  /// No description provided for @authEmailInvalid.
  ///
  /// In tr, this message translates to:
  /// **'Geçerli bir e-posta gir'**
  String get authEmailInvalid;

  /// No description provided for @authContinueWithAccount.
  ///
  /// In tr, this message translates to:
  /// **'Hesabına giriş yaparak devam et'**
  String get authContinueWithAccount;

  /// No description provided for @authOrDivider.
  ///
  /// In tr, this message translates to:
  /// **'veya'**
  String get authOrDivider;

  /// No description provided for @authGuestContinue.
  ///
  /// In tr, this message translates to:
  /// **'Misafir olarak devam et'**
  String get authGuestContinue;

  /// No description provided for @authLoggingIn.
  ///
  /// In tr, this message translates to:
  /// **'Giriş yapılıyor...'**
  String get authLoggingIn;

  /// No description provided for @authPleaseWait.
  ///
  /// In tr, this message translates to:
  /// **'Lütfen bekleyin'**
  String get authPleaseWait;

  /// No description provided for @authResetPasswordTitle.
  ///
  /// In tr, this message translates to:
  /// **'Şifre Sıfırlama'**
  String get authResetPasswordTitle;

  /// No description provided for @authResetPasswordDesc.
  ///
  /// In tr, this message translates to:
  /// **'E-posta adresini gir, şifre sıfırlama linki gönderelim.'**
  String get authResetPasswordDesc;

  /// No description provided for @authResetPasswordSend.
  ///
  /// In tr, this message translates to:
  /// **'Sıfırlama Linki Gönder'**
  String get authResetPasswordSend;

  /// No description provided for @authResetPasswordSent.
  ///
  /// In tr, this message translates to:
  /// **'Şifre sıfırlama linki gönderildi!'**
  String get authResetPasswordSent;

  /// No description provided for @authRegisterTitle.
  ///
  /// In tr, this message translates to:
  /// **'Yeni hesap oluştur ve keşfetmeye başla'**
  String get authRegisterTitle;

  /// No description provided for @authFullName.
  ///
  /// In tr, this message translates to:
  /// **'Ad Soyad'**
  String get authFullName;

  /// No description provided for @authFullNameRequired.
  ///
  /// In tr, this message translates to:
  /// **'Ad Soyad gerekli'**
  String get authFullNameRequired;

  /// No description provided for @authFullNameTooShort.
  ///
  /// In tr, this message translates to:
  /// **'Ad Soyad en az 2 karakter olmalı'**
  String get authFullNameTooShort;

  /// No description provided for @authPasswordConfirm.
  ///
  /// In tr, this message translates to:
  /// **'Şifre Tekrar'**
  String get authPasswordConfirm;

  /// No description provided for @authPasswordConfirmRequired.
  ///
  /// In tr, this message translates to:
  /// **'Şifre tekrarı gerekli'**
  String get authPasswordConfirmRequired;

  /// No description provided for @authPasswordMismatch.
  ///
  /// In tr, this message translates to:
  /// **'Şifreler eşleşmiyor'**
  String get authPasswordMismatch;

  /// No description provided for @authPasswordMin8.
  ///
  /// In tr, this message translates to:
  /// **'Şifre en az 8 karakter olmalı'**
  String get authPasswordMin8;

  /// No description provided for @authPasswordUppercase.
  ///
  /// In tr, this message translates to:
  /// **'Şifre en az bir büyük harf içermeli'**
  String get authPasswordUppercase;

  /// No description provided for @authPasswordDigit.
  ///
  /// In tr, this message translates to:
  /// **'Şifre en az bir rakam içermeli'**
  String get authPasswordDigit;

  /// No description provided for @authCreatingAccount.
  ///
  /// In tr, this message translates to:
  /// **'Hesap oluşturuluyor...'**
  String get authCreatingAccount;

  /// No description provided for @authEduDetected.
  ///
  /// In tr, this message translates to:
  /// **'edu.tr hesabı algılandı! Doğrulama sonrası yorum yazabileceksin.'**
  String get authEduDetected;

  /// No description provided for @authEduVerifyTitle.
  ///
  /// In tr, this message translates to:
  /// **'edu.tr Doğrulama'**
  String get authEduVerifyTitle;

  /// No description provided for @authEduVerifyLinkSent.
  ///
  /// In tr, this message translates to:
  /// **'Doğrulama linki e-posta adresine gönderildi:'**
  String get authEduVerifyLinkSent;

  /// No description provided for @authEduVerifyAfter.
  ///
  /// In tr, this message translates to:
  /// **'E-postanı doğruladıktan sonra yorum yazabileceksin.'**
  String get authEduVerifyAfter;

  /// No description provided for @authOk.
  ///
  /// In tr, this message translates to:
  /// **'Tamam'**
  String get authOk;

  /// No description provided for @authGoBack.
  ///
  /// In tr, this message translates to:
  /// **'Geri dön'**
  String get authGoBack;

  /// No description provided for @authVerifyEmailTitle.
  ///
  /// In tr, this message translates to:
  /// **'E-postanı doğrula'**
  String get authVerifyEmailTitle;

  /// No description provided for @authVerifyEmailBody.
  ///
  /// In tr, this message translates to:
  /// **'{email} adresine doğrulama linki gönderdik.'**
  String authVerifyEmailBody(String email);

  /// No description provided for @profileTitle.
  ///
  /// In tr, this message translates to:
  /// **'Hesabım'**
  String get profileTitle;

  /// No description provided for @profileEditProfile.
  ///
  /// In tr, this message translates to:
  /// **'Profili düzenle'**
  String get profileEditProfile;

  /// No description provided for @profileEditSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Fotoğraf, isim, üniversite'**
  String get profileEditSubtitle;

  /// No description provided for @profileAccount.
  ///
  /// In tr, this message translates to:
  /// **'Hesap'**
  String get profileAccount;

  /// No description provided for @profileSettings.
  ///
  /// In tr, this message translates to:
  /// **'Ayarlar'**
  String get profileSettings;

  /// No description provided for @profileNotifications.
  ///
  /// In tr, this message translates to:
  /// **'Bildirimler'**
  String get profileNotifications;

  /// No description provided for @profileNotificationsSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Yorum, favori bildirimleri'**
  String get profileNotificationsSubtitle;

  /// No description provided for @profileSecurity.
  ///
  /// In tr, this message translates to:
  /// **'Güvenlik'**
  String get profileSecurity;

  /// No description provided for @profileSecuritySubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Şifre değiştir'**
  String get profileSecuritySubtitle;

  /// No description provided for @profilePasswordChanged.
  ///
  /// In tr, this message translates to:
  /// **'Şifre başarıyla değiştirildi'**
  String get profilePasswordChanged;

  /// No description provided for @profileApp.
  ///
  /// In tr, this message translates to:
  /// **'Uygulama'**
  String get profileApp;

  /// No description provided for @profileAbout.
  ///
  /// In tr, this message translates to:
  /// **'Hakkında'**
  String get profileAbout;

  /// No description provided for @profileRateApp.
  ///
  /// In tr, this message translates to:
  /// **'Uygulamayı Puanla'**
  String get profileRateApp;

  /// No description provided for @profileRateAppSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Google Play\'de değerlendir'**
  String get profileRateAppSubtitle;

  /// No description provided for @profileShareApp.
  ///
  /// In tr, this message translates to:
  /// **'Arkadaşına Öner'**
  String get profileShareApp;

  /// No description provided for @profileShareAppSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Linki paylaş'**
  String get profileShareAppSubtitle;

  /// No description provided for @profileShareText.
  ///
  /// In tr, this message translates to:
  /// **'ÜniSeç - Hayalindeki üniversiteyi keşfet! 🎓\nhttps://play.google.com/store/apps/details?id=com.unisec.app'**
  String get profileShareText;

  /// No description provided for @profilePrivacyPolicy.
  ///
  /// In tr, this message translates to:
  /// **'Gizlilik Politikası'**
  String get profilePrivacyPolicy;

  /// No description provided for @privacyPolicyComingSoon.
  ///
  /// In tr, this message translates to:
  /// **'Gizlilik politikası yakında yayınlanacak'**
  String get privacyPolicyComingSoon;

  /// No description provided for @profileSignOut.
  ///
  /// In tr, this message translates to:
  /// **'Çıkış Yap'**
  String get profileSignOut;

  /// No description provided for @profileSignOutConfirm.
  ///
  /// In tr, this message translates to:
  /// **'Hesabınızdan çıkış yapmak istediğinize emin misiniz?'**
  String get profileSignOutConfirm;

  /// No description provided for @profileCancel.
  ///
  /// In tr, this message translates to:
  /// **'İptal'**
  String get profileCancel;

  /// No description provided for @profileMembershipPlan.
  ///
  /// In tr, this message translates to:
  /// **'Üyelik Planı'**
  String get profileMembershipPlan;

  /// No description provided for @profileMembershipUsing.
  ///
  /// In tr, this message translates to:
  /// **'{plan} planını kullanıyorsun'**
  String profileMembershipUsing(String plan);

  /// No description provided for @profilePlanDetails.
  ///
  /// In tr, this message translates to:
  /// **'Plan Detayları'**
  String get profilePlanDetails;

  /// No description provided for @profileViewPlans.
  ///
  /// In tr, this message translates to:
  /// **'Planları Gör ve Yükselt'**
  String get profileViewPlans;

  /// No description provided for @profileGuestWelcome.
  ///
  /// In tr, this message translates to:
  /// **'Hoş Geldin!'**
  String get profileGuestWelcome;

  /// No description provided for @profileGuestSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Yorum yapmak ve favori eklemek için\ngiriş yapman gerekiyor.'**
  String get profileGuestSubtitle;

  /// No description provided for @profileVerifiedStudent.
  ///
  /// In tr, this message translates to:
  /// **'Doğrulanmış Öğrenci'**
  String get profileVerifiedStudent;

  /// No description provided for @profileVerificationPending.
  ///
  /// In tr, this message translates to:
  /// **'Doğrulama Bekleniyor'**
  String get profileVerificationPending;

  /// No description provided for @profileVerified.
  ///
  /// In tr, this message translates to:
  /// **'Hesabınız doğrulandı!'**
  String get profileVerified;

  /// No description provided for @profileNotVerified.
  ///
  /// In tr, this message translates to:
  /// **'Henüz doğrulanmamış. Lütfen mailinize gelen linke tıklayın.'**
  String get profileNotVerified;

  /// No description provided for @profileRefresh.
  ///
  /// In tr, this message translates to:
  /// **'Yenile'**
  String get profileRefresh;

  /// No description provided for @profileStatReview.
  ///
  /// In tr, this message translates to:
  /// **'Yorum'**
  String get profileStatReview;

  /// No description provided for @profileStatFavorite.
  ///
  /// In tr, this message translates to:
  /// **'Favori'**
  String get profileStatFavorite;

  /// No description provided for @profileStatMembership.
  ///
  /// In tr, this message translates to:
  /// **'Üyelik'**
  String get profileStatMembership;

  /// No description provided for @profileStatDays.
  ///
  /// In tr, this message translates to:
  /// **'{days} gün'**
  String profileStatDays(int days);

  /// No description provided for @profileAboutDescription.
  ///
  /// In tr, this message translates to:
  /// **'ÜniSeç, Türkiye\'deki üniversiteleri keşfetmeni, karşılaştırmanı ve deneyimlerini paylaşmanı sağlayan bir mobil uygulamadır.'**
  String get profileAboutDescription;

  /// No description provided for @profileAboutCopyright.
  ///
  /// In tr, this message translates to:
  /// **'© 2026 ÜniSeç Ekibi'**
  String get profileAboutCopyright;

  /// No description provided for @profileUser.
  ///
  /// In tr, this message translates to:
  /// **'Kullanıcı'**
  String get profileUser;

  /// No description provided for @editProfileTitle.
  ///
  /// In tr, this message translates to:
  /// **'Profili Düzenle'**
  String get editProfileTitle;

  /// No description provided for @editProfileCamera.
  ///
  /// In tr, this message translates to:
  /// **'Kamera'**
  String get editProfileCamera;

  /// No description provided for @editProfileGallery.
  ///
  /// In tr, this message translates to:
  /// **'Galeri'**
  String get editProfileGallery;

  /// No description provided for @editProfileFullName.
  ///
  /// In tr, this message translates to:
  /// **'Ad Soyad'**
  String get editProfileFullName;

  /// No description provided for @editProfileFullNameRequired.
  ///
  /// In tr, this message translates to:
  /// **'Ad Soyad gerekli'**
  String get editProfileFullNameRequired;

  /// No description provided for @editProfileUniversity.
  ///
  /// In tr, this message translates to:
  /// **'Üniversite'**
  String get editProfileUniversity;

  /// No description provided for @editProfileUniversityError.
  ///
  /// In tr, this message translates to:
  /// **'Üniversiteler yüklenemedi: {error}'**
  String editProfileUniversityError(String error);

  /// No description provided for @editProfileDepartment.
  ///
  /// In tr, this message translates to:
  /// **'Bölüm'**
  String get editProfileDepartment;

  /// No description provided for @editProfileDepartmentHint.
  ///
  /// In tr, this message translates to:
  /// **'Örn: Bilgisayar Mühendisliği'**
  String get editProfileDepartmentHint;

  /// No description provided for @editProfileBio.
  ///
  /// In tr, this message translates to:
  /// **'Hakkımda (Opsiyonel)'**
  String get editProfileBio;

  /// No description provided for @editProfileBioHint.
  ///
  /// In tr, this message translates to:
  /// **'Kendinden kısaca bahset...'**
  String get editProfileBioHint;

  /// No description provided for @editProfileBioProfanity.
  ///
  /// In tr, this message translates to:
  /// **'Uygunsuz içerik tespit edildi'**
  String get editProfileBioProfanity;

  /// No description provided for @editProfileGrade.
  ///
  /// In tr, this message translates to:
  /// **'Sınıf'**
  String get editProfileGrade;

  /// No description provided for @editProfileSave.
  ///
  /// In tr, this message translates to:
  /// **'Kaydet'**
  String get editProfileSave;

  /// No description provided for @editProfileSaving.
  ///
  /// In tr, this message translates to:
  /// **'Kaydediliyor...'**
  String get editProfileSaving;

  /// No description provided for @editProfileSuccess.
  ///
  /// In tr, this message translates to:
  /// **'Profil başarıyla güncellendi'**
  String get editProfileSuccess;

  /// No description provided for @editProfileError.
  ///
  /// In tr, this message translates to:
  /// **'Profil güncellenirken hata oluştu'**
  String get editProfileError;

  /// No description provided for @errorGeneral.
  ///
  /// In tr, this message translates to:
  /// **'Hata: {error}'**
  String errorGeneral(String error);

  /// No description provided for @universityNotFound.
  ///
  /// In tr, this message translates to:
  /// **'Üniversite bulunamadı'**
  String get universityNotFound;

  /// No description provided for @errorDepartmentsLoad.
  ///
  /// In tr, this message translates to:
  /// **'Bölümler yüklenirken hata oluştu.'**
  String get errorDepartmentsLoad;

  /// No description provided for @noDepartmentsFound.
  ///
  /// In tr, this message translates to:
  /// **'Bölüm bulunamadı.'**
  String get noDepartmentsFound;

  /// No description provided for @errorPlacesLoad.
  ///
  /// In tr, this message translates to:
  /// **'Mekanlar yüklenirken hata oluştu.'**
  String get errorPlacesLoad;

  /// No description provided for @noPlacesFound.
  ///
  /// In tr, this message translates to:
  /// **'Mekan bulunamadı.'**
  String get noPlacesFound;

  /// No description provided for @errorReviewsLoad.
  ///
  /// In tr, this message translates to:
  /// **'Yorumlar yüklenirken hata oluştu.'**
  String get errorReviewsLoad;

  /// No description provided for @reviewLoginRequired.
  ///
  /// In tr, this message translates to:
  /// **'Yorum yazabilmek için önce hesabınıza giriş yapmanız gerekiyor.'**
  String get reviewLoginRequired;

  /// No description provided for @reviewEduRequiredTitle.
  ///
  /// In tr, this message translates to:
  /// **'Doğrulama Gerekli'**
  String get reviewEduRequiredTitle;

  /// No description provided for @reviewEduRequiredDesc.
  ///
  /// In tr, this message translates to:
  /// **'Sadece onaylı üniversite öğrencileri değerlendirme yapabilir (.edu.tr).'**
  String get reviewEduRequiredDesc;

  /// No description provided for @reviewAnonymousStudent.
  ///
  /// In tr, this message translates to:
  /// **'Anonim Öğrenci'**
  String get reviewAnonymousStudent;

  /// No description provided for @reviewLoading.
  ///
  /// In tr, this message translates to:
  /// **'Yükleniyor...'**
  String get reviewLoading;

  /// No description provided for @reviewUniversityFallback.
  ///
  /// In tr, this message translates to:
  /// **'Üniversite'**
  String get reviewUniversityFallback;

  /// No description provided for @reviewDepartmentFallback.
  ///
  /// In tr, this message translates to:
  /// **'Bölüm'**
  String get reviewDepartmentFallback;

  /// No description provided for @reviewPlaceFallback.
  ///
  /// In tr, this message translates to:
  /// **'Mekan'**
  String get reviewPlaceFallback;

  /// No description provided for @reviewUniversityReview.
  ///
  /// In tr, this message translates to:
  /// **'Üniversite Yorumu'**
  String get reviewUniversityReview;

  /// No description provided for @reviewDepartmentReview.
  ///
  /// In tr, this message translates to:
  /// **'Bölüm Yorumu'**
  String get reviewDepartmentReview;

  /// No description provided for @reviewPlaceReview.
  ///
  /// In tr, this message translates to:
  /// **'Mekan Yorumu'**
  String get reviewPlaceReview;

  /// No description provided for @reviewPendingTitle.
  ///
  /// In tr, this message translates to:
  /// **'Yayınlanmadı'**
  String get reviewPendingTitle;

  /// No description provided for @reviewPendingDesc.
  ///
  /// In tr, this message translates to:
  /// **'Yorumun moderasyon aşamasında. Uygunsuz içerik tespit edildiyse düzenleyerek tekrar gönderebilirsin.'**
  String get reviewPendingDesc;

  /// No description provided for @reviewShowLess.
  ///
  /// In tr, this message translates to:
  /// **'Daha az göster'**
  String get reviewShowLess;

  /// No description provided for @reviewReadMore.
  ///
  /// In tr, this message translates to:
  /// **'Devamını oku'**
  String get reviewReadMore;

  /// No description provided for @recommendIntroTitle.
  ///
  /// In tr, this message translates to:
  /// **'Tercih Asistanı'**
  String get recommendIntroTitle;

  /// No description provided for @recommendIntroSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Sana birkaç kısa soru soracağım,\nhayalindeki üniversiteyi birlikte bulalım.'**
  String get recommendIntroSubtitle;

  /// No description provided for @recommendIntroDuration.
  ///
  /// In tr, this message translates to:
  /// **'~4 dakika'**
  String get recommendIntroDuration;

  /// No description provided for @recommendIntroMedals.
  ///
  /// In tr, this message translates to:
  /// **'Altın / Gümüş / Bronz'**
  String get recommendIntroMedals;

  /// No description provided for @recommendIntroSuggestions.
  ///
  /// In tr, this message translates to:
  /// **'8 öneri'**
  String get recommendIntroSuggestions;

  /// No description provided for @recommendIntroBetaTitle.
  ///
  /// In tr, this message translates to:
  /// **'Beta — Geliştirme Aşaması'**
  String get recommendIntroBetaTitle;

  /// No description provided for @recommendIntroBetaDesc.
  ///
  /// In tr, this message translates to:
  /// **'Bu asistan henüz geliştirilme aşamasında. Öneriler kesin tercih kararı için değil, yönlendirme amaçlıdır. Final tercihinde mutlaka kendi araştırmanı yap.'**
  String get recommendIntroBetaDesc;

  /// No description provided for @recommendIntroStart.
  ///
  /// In tr, this message translates to:
  /// **'Başlayalım'**
  String get recommendIntroStart;

  /// No description provided for @recommendIntroDurationNote.
  ///
  /// In tr, this message translates to:
  /// **'Yaklaşık 4 dakika sürer'**
  String get recommendIntroDurationNote;

  /// No description provided for @aiSummaryLimitReachedSimple.
  ///
  /// In tr, this message translates to:
  /// **'Günlük AI özet hakkın doldu, yarın tekrar dene.'**
  String get aiSummaryLimitReachedSimple;

  /// No description provided for @commonRetry.
  ///
  /// In tr, this message translates to:
  /// **'Tekrar dene'**
  String get commonRetry;

  /// No description provided for @commonError.
  ///
  /// In tr, this message translates to:
  /// **'Bir hata oluştu'**
  String get commonError;

  /// No description provided for @paywallPerMonthSuffix.
  ///
  /// In tr, this message translates to:
  /// **'/ay'**
  String get paywallPerMonthSuffix;

  /// No description provided for @paywallPerYearSuffix.
  ///
  /// In tr, this message translates to:
  /// **'/yıl'**
  String get paywallPerYearSuffix;

  /// No description provided for @paywallSaveBadge.
  ///
  /// In tr, this message translates to:
  /// **'%{percent} TASARRUF'**
  String paywallSaveBadge(int percent);

  /// No description provided for @paywallYearlySavingsSub.
  ///
  /// In tr, this message translates to:
  /// **'Aylığa göre %{percent} tasarruf'**
  String paywallYearlySavingsSub(int percent);

  /// No description provided for @paywallFreeTrialNote.
  ///
  /// In tr, this message translates to:
  /// **'İlk {duration} ücretsiz, sonra otomatik yenilenir'**
  String paywallFreeTrialNote(String duration);

  /// No description provided for @paywallUnitDay.
  ///
  /// In tr, this message translates to:
  /// **'gün'**
  String get paywallUnitDay;

  /// No description provided for @paywallUnitWeek.
  ///
  /// In tr, this message translates to:
  /// **'hafta'**
  String get paywallUnitWeek;

  /// No description provided for @paywallUnitMonth.
  ///
  /// In tr, this message translates to:
  /// **'ay'**
  String get paywallUnitMonth;

  /// No description provided for @paywallUnitYear.
  ///
  /// In tr, this message translates to:
  /// **'yıl'**
  String get paywallUnitYear;

  /// No description provided for @commonLoading.
  ///
  /// In tr, this message translates to:
  /// **'Yükleniyor...'**
  String get commonLoading;

  /// No description provided for @commonCancel.
  ///
  /// In tr, this message translates to:
  /// **'İptal'**
  String get commonCancel;

  /// No description provided for @commonSave.
  ///
  /// In tr, this message translates to:
  /// **'Kaydet'**
  String get commonSave;

  /// No description provided for @commonDelete.
  ///
  /// In tr, this message translates to:
  /// **'Sil'**
  String get commonDelete;

  /// No description provided for @commonClose.
  ///
  /// In tr, this message translates to:
  /// **'Kapat'**
  String get commonClose;

  /// No description provided for @commonShare.
  ///
  /// In tr, this message translates to:
  /// **'Paylaş'**
  String get commonShare;

  /// No description provided for @commonEdit.
  ///
  /// In tr, this message translates to:
  /// **'Düzenle'**
  String get commonEdit;

  /// No description provided for @commonContinue.
  ///
  /// In tr, this message translates to:
  /// **'Devam et'**
  String get commonContinue;

  /// No description provided for @authSignOut.
  ///
  /// In tr, this message translates to:
  /// **'Çıkış yap'**
  String get authSignOut;

  /// No description provided for @authPasswordTooShort.
  ///
  /// In tr, this message translates to:
  /// **'Şifre en az 6 karakter olmalı'**
  String get authPasswordTooShort;

  /// No description provided for @homeTabHome.
  ///
  /// In tr, this message translates to:
  /// **'Ana Sayfa'**
  String get homeTabHome;

  /// No description provided for @homeTabExplore.
  ///
  /// In tr, this message translates to:
  /// **'Keşfet'**
  String get homeTabExplore;

  /// No description provided for @homeTabCompare.
  ///
  /// In tr, this message translates to:
  /// **'Karşılaştır'**
  String get homeTabCompare;

  /// No description provided for @homeTabFavorites.
  ///
  /// In tr, this message translates to:
  /// **'Listelerim'**
  String get homeTabFavorites;

  /// No description provided for @homeTabProfile.
  ///
  /// In tr, this message translates to:
  /// **'Profil'**
  String get homeTabProfile;

  /// No description provided for @comparisonTitleUni.
  ///
  /// In tr, this message translates to:
  /// **'Üniversite karşılaştır'**
  String get comparisonTitleUni;

  /// No description provided for @comparisonTitleDept.
  ///
  /// In tr, this message translates to:
  /// **'Bölüm karşılaştır'**
  String get comparisonTitleDept;

  /// No description provided for @comparisonTitleCity.
  ///
  /// In tr, this message translates to:
  /// **'Şehir karşılaştır'**
  String get comparisonTitleCity;

  /// No description provided for @comparisonNoteAdd.
  ///
  /// In tr, this message translates to:
  /// **'Not ekle'**
  String get comparisonNoteAdd;

  /// No description provided for @comparisonNoteEmpty.
  ///
  /// In tr, this message translates to:
  /// **'Henüz notun yok'**
  String get comparisonNoteEmpty;

  /// No description provided for @comparisonNoteMaxLength.
  ///
  /// In tr, this message translates to:
  /// **'En fazla 500 karakter'**
  String get comparisonNoteMaxLength;

  /// No description provided for @comparisonNotesLoadError.
  ///
  /// In tr, this message translates to:
  /// **'Notlar yüklenemedi.'**
  String get comparisonNotesLoadError;

  /// No description provided for @comparisonNoteSaved.
  ///
  /// In tr, this message translates to:
  /// **'Not kaydedildi ✍️'**
  String get comparisonNoteSaved;

  /// No description provided for @comparisonNoteUpdated.
  ///
  /// In tr, this message translates to:
  /// **'Not güncellendi ✅'**
  String get comparisonNoteUpdated;

  /// No description provided for @comparisonNoteDeleteTitle.
  ///
  /// In tr, this message translates to:
  /// **'Notu Sil'**
  String get comparisonNoteDeleteTitle;

  /// No description provided for @comparisonNoteDeleteConfirm.
  ///
  /// In tr, this message translates to:
  /// **'Bu not kalıcı olarak silinecek. Devam edilsin mi?'**
  String get comparisonNoteDeleteConfirm;

  /// No description provided for @comparisonNoteDeleted.
  ///
  /// In tr, this message translates to:
  /// **'Not silindi'**
  String get comparisonNoteDeleted;

  /// No description provided for @comparisonNoteEmptyTitle.
  ///
  /// In tr, this message translates to:
  /// **'Henüz not yok'**
  String get comparisonNoteEmptyTitle;

  /// No description provided for @comparisonNoteEmptyDesc.
  ///
  /// In tr, this message translates to:
  /// **'Bu karşılaştırma hakkındaki düşüncelerini kaydet'**
  String get comparisonNoteEmptyDesc;

  /// No description provided for @comparisonProUpsell.
  ///
  /// In tr, this message translates to:
  /// **'3. üniversite eklemek için Pro\'ya yükselt'**
  String get comparisonProUpsell;

  /// No description provided for @paywallContinueFree.
  ///
  /// In tr, this message translates to:
  /// **'Ücretsiz devam et'**
  String get paywallContinueFree;

  /// No description provided for @paywallSavePercent.
  ///
  /// In tr, this message translates to:
  /// **'TASARRUF {percent}%'**
  String paywallSavePercent(int percent);

  /// No description provided for @paywallMonthly.
  ///
  /// In tr, this message translates to:
  /// **'Aylık'**
  String get paywallMonthly;

  /// No description provided for @paywallYearly.
  ///
  /// In tr, this message translates to:
  /// **'Yıllık'**
  String get paywallYearly;

  /// No description provided for @paywallRestore.
  ///
  /// In tr, this message translates to:
  /// **'Satın alımları geri yükle'**
  String get paywallRestore;

  /// No description provided for @paywallPackageInfoError.
  ///
  /// In tr, this message translates to:
  /// **'Paket bilgisi alınamadı. Tekrar dene.'**
  String get paywallPackageInfoError;

  /// No description provided for @paywallPurchaseSuccess.
  ///
  /// In tr, this message translates to:
  /// **'Satın alma başarılı. Planın güncelleniyor.'**
  String get paywallPurchaseSuccess;

  /// No description provided for @paywallPurchaseIncomplete.
  ///
  /// In tr, this message translates to:
  /// **'Satın alma tamamlanmadı.'**
  String get paywallPurchaseIncomplete;

  /// No description provided for @paywallRestoreResult.
  ///
  /// In tr, this message translates to:
  /// **'Geri yükleme sonucu: {tier}'**
  String paywallRestoreResult(String tier);

  /// No description provided for @paywallOfferingsLoadError.
  ///
  /// In tr, this message translates to:
  /// **'Paketler yüklenirken bir sorun oluştu. Lütfen tekrar dene.'**
  String get paywallOfferingsLoadError;

  /// No description provided for @paywallSecurityNote.
  ///
  /// In tr, this message translates to:
  /// **'Güvenli ödeme • İstediğinde iptal'**
  String get paywallSecurityNote;

  /// No description provided for @paywallPurchaseSuccessTitle.
  ///
  /// In tr, this message translates to:
  /// **'Satın alma başarılı!'**
  String get paywallPurchaseSuccessTitle;

  /// No description provided for @paywallPurchaseSuccessDesc.
  ///
  /// In tr, this message translates to:
  /// **'Planın aktif edildi. Tüm özelliklerin keyfini çıkar.'**
  String get paywallPurchaseSuccessDesc;

  /// No description provided for @paywallGreat.
  ///
  /// In tr, this message translates to:
  /// **'Harika'**
  String get paywallGreat;

  /// No description provided for @reviewWrite.
  ///
  /// In tr, this message translates to:
  /// **'Yorum yaz'**
  String get reviewWrite;

  /// No description provided for @reviewAnonymous.
  ///
  /// In tr, this message translates to:
  /// **'Anonim'**
  String get reviewAnonymous;

  /// No description provided for @reviewRatingRequired.
  ///
  /// In tr, this message translates to:
  /// **'Puan vermeden yorum gönderilemez'**
  String get reviewRatingRequired;

  /// No description provided for @profilePremium.
  ///
  /// In tr, this message translates to:
  /// **'Premium üyelik'**
  String get profilePremium;

  /// No description provided for @profileLanguage.
  ///
  /// In tr, this message translates to:
  /// **'Dil'**
  String get profileLanguage;

  /// No description provided for @profileDeleteAccount.
  ///
  /// In tr, this message translates to:
  /// **'Hesabımı sil'**
  String get profileDeleteAccount;

  /// No description provided for @deleteAccountTitle.
  ///
  /// In tr, this message translates to:
  /// **'Hesabı kalıcı olarak sil'**
  String get deleteAccountTitle;

  /// No description provided for @deleteAccountDescription.
  ///
  /// In tr, this message translates to:
  /// **'Profiliniz, favorileriniz, tercih listeleriniz, yorumlarınız, önerileriniz ve hesabınızla ilişkili kişisel veriler silinecektir.'**
  String get deleteAccountDescription;

  /// No description provided for @deleteAccountWarning.
  ///
  /// In tr, this message translates to:
  /// **'Bu işlem geri alınamaz. Aktif mağaza aboneliğiniz varsa aboneliği ayrıca Google Play üzerinden iptal etmeniz gerekir.'**
  String get deleteAccountWarning;

  /// No description provided for @deleteAccountPasswordNote.
  ///
  /// In tr, this message translates to:
  /// **'Devam etmek için mevcut şifrenizle kimliğinizi doğrulayın.'**
  String get deleteAccountPasswordNote;

  /// No description provided for @deleteAccountGoogleNote.
  ///
  /// In tr, this message translates to:
  /// **'Devam ettiğinizde Google hesabınızla yeniden doğrulama istenecektir.'**
  String get deleteAccountGoogleNote;

  /// No description provided for @deleteAccountPasswordLabel.
  ///
  /// In tr, this message translates to:
  /// **'Mevcut şifre'**
  String get deleteAccountPasswordLabel;

  /// No description provided for @deleteAccountPasswordRequired.
  ///
  /// In tr, this message translates to:
  /// **'Mevcut şifrenizi girin'**
  String get deleteAccountPasswordRequired;

  /// No description provided for @deleteAccountConfirmationWord.
  ///
  /// In tr, this message translates to:
  /// **'SİL'**
  String get deleteAccountConfirmationWord;

  /// No description provided for @deleteAccountConfirmationLabel.
  ///
  /// In tr, this message translates to:
  /// **'Onaylamak için {word} yazın'**
  String deleteAccountConfirmationLabel(String word);

  /// No description provided for @deleteAccountConfirmationMismatch.
  ///
  /// In tr, this message translates to:
  /// **'Devam etmek için {word} yazın'**
  String deleteAccountConfirmationMismatch(String word);

  /// No description provided for @deleteAccountConfirmButton.
  ///
  /// In tr, this message translates to:
  /// **'Hesabı sil'**
  String get deleteAccountConfirmButton;

  /// No description provided for @deleteAccountProgress.
  ///
  /// In tr, this message translates to:
  /// **'Hesabınız ve verileriniz siliniyor...'**
  String get deleteAccountProgress;

  /// No description provided for @deleteAccountSuccess.
  ///
  /// In tr, this message translates to:
  /// **'Hesabınız ve ilişkili verileriniz silindi.'**
  String get deleteAccountSuccess;

  /// No description provided for @favoritesEmpty.
  ///
  /// In tr, this message translates to:
  /// **'Favori yok'**
  String get favoritesEmpty;

  /// No description provided for @favoritesEmptyHint.
  ///
  /// In tr, this message translates to:
  /// **'Beğendiğin üniversiteleri buradan takip et.'**
  String get favoritesEmptyHint;

  /// No description provided for @profileTheme.
  ///
  /// In tr, this message translates to:
  /// **'Tema'**
  String get profileTheme;

  /// No description provided for @themeSystem.
  ///
  /// In tr, this message translates to:
  /// **'Sistem'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In tr, this message translates to:
  /// **'Açık'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In tr, this message translates to:
  /// **'Koyu'**
  String get themeDark;

  /// No description provided for @themeSelection.
  ///
  /// In tr, this message translates to:
  /// **'Tema Seçimi'**
  String get themeSelection;

  /// No description provided for @languageSelection.
  ///
  /// In tr, this message translates to:
  /// **'Dil Seçimi'**
  String get languageSelection;

  /// No description provided for @turkish.
  ///
  /// In tr, this message translates to:
  /// **'Türkçe'**
  String get turkish;

  /// No description provided for @english.
  ///
  /// In tr, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @homeGreeting.
  ///
  /// In tr, this message translates to:
  /// **'Merhaba! 👋'**
  String get homeGreeting;

  /// No description provided for @homePopularUniversities.
  ///
  /// In tr, this message translates to:
  /// **'Popüler Üniversiteler'**
  String get homePopularUniversities;

  /// No description provided for @homeSeeAll.
  ///
  /// In tr, this message translates to:
  /// **'Tümünü Gör'**
  String get homeSeeAll;

  /// No description provided for @homeCities.
  ///
  /// In tr, this message translates to:
  /// **'Şehirler'**
  String get homeCities;

  /// No description provided for @homeCitiesLoadError.
  ///
  /// In tr, this message translates to:
  /// **'Şehirler yüklenemedi'**
  String get homeCitiesLoadError;

  /// No description provided for @homeRecentReviews.
  ///
  /// In tr, this message translates to:
  /// **'Son Yorumlar'**
  String get homeRecentReviews;

  /// No description provided for @homeTopReviews.
  ///
  /// In tr, this message translates to:
  /// **'Öne Çıkan Yorumlar'**
  String get homeTopReviews;

  /// No description provided for @homeNoReviews.
  ///
  /// In tr, this message translates to:
  /// **'Henüz yorum yok'**
  String get homeNoReviews;

  /// No description provided for @homeFirstReview.
  ///
  /// In tr, this message translates to:
  /// **'İlk yorumu yazan siz olun!'**
  String get homeFirstReview;

  /// No description provided for @homeAssistantTitle.
  ///
  /// In tr, this message translates to:
  /// **'Tercih Asistanı'**
  String get homeAssistantTitle;

  /// No description provided for @homeAssistantSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Hayalindeki üniversiteyi\nbirlikte bulalım!'**
  String get homeAssistantSubtitle;

  /// No description provided for @homeStart.
  ///
  /// In tr, this message translates to:
  /// **'Başla'**
  String get homeStart;

  /// No description provided for @exploreTitle.
  ///
  /// In tr, this message translates to:
  /// **'Keşfet'**
  String get exploreTitle;

  /// No description provided for @exploreSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Üniversiteleri keşfet, filtrele ve karşılaştır'**
  String get exploreSubtitle;

  /// No description provided for @exploreSearchHint.
  ///
  /// In tr, this message translates to:
  /// **'Üniversite ara...'**
  String get exploreSearchHint;

  /// No description provided for @exploreTypeState.
  ///
  /// In tr, this message translates to:
  /// **'Devlet'**
  String get exploreTypeState;

  /// No description provided for @exploreTypeFoundation.
  ///
  /// In tr, this message translates to:
  /// **'Vakıf'**
  String get exploreTypeFoundation;

  /// No description provided for @exploreFilters.
  ///
  /// In tr, this message translates to:
  /// **'Filtreler'**
  String get exploreFilters;

  /// No description provided for @exploreClear.
  ///
  /// In tr, this message translates to:
  /// **'Temizle'**
  String get exploreClear;

  /// No description provided for @exploreUniType.
  ///
  /// In tr, this message translates to:
  /// **'Üniversite Türü'**
  String get exploreUniType;

  /// No description provided for @exploreCities.
  ///
  /// In tr, this message translates to:
  /// **'Şehirler'**
  String get exploreCities;

  /// No description provided for @exploreCitiesError.
  ///
  /// In tr, this message translates to:
  /// **'Şehirler yüklenemedi'**
  String get exploreCitiesError;

  /// No description provided for @exploreNoResults.
  ///
  /// In tr, this message translates to:
  /// **'Sonuç bulunamadı'**
  String get exploreNoResults;

  /// No description provided for @exploreNoResultsSub.
  ///
  /// In tr, this message translates to:
  /// **'Filtrelerinizi değiştirerek tekrar deneyin.'**
  String get exploreNoResultsSub;

  /// No description provided for @searchGlobalHint.
  ///
  /// In tr, this message translates to:
  /// **'Üniversite, bölüm veya şehir ara...'**
  String get searchGlobalHint;

  /// No description provided for @showcaseSearchTitle.
  ///
  /// In tr, this message translates to:
  /// **'Hızlı Arama'**
  String get showcaseSearchTitle;

  /// No description provided for @showcaseSearchDescription.
  ///
  /// In tr, this message translates to:
  /// **'Üniversite, bölüm veya şehir ara — istediğin her şeyi anında bul.'**
  String get showcaseSearchDescription;

  /// No description provided for @searchError.
  ///
  /// In tr, this message translates to:
  /// **'Arama yapılırken bir hata oluştu.'**
  String get searchError;

  /// No description provided for @searchNoResults.
  ///
  /// In tr, this message translates to:
  /// **'Sonuç bulunamadı'**
  String get searchNoResults;

  /// No description provided for @searchRecentTitle.
  ///
  /// In tr, this message translates to:
  /// **'Son Aramalar'**
  String get searchRecentTitle;

  /// No description provided for @searchRecentClear.
  ///
  /// In tr, this message translates to:
  /// **'Temizle'**
  String get searchRecentClear;

  /// No description provided for @searchNoResultsSub.
  ///
  /// In tr, this message translates to:
  /// **'\"{query}\" aramasına uygun üniversite yok.'**
  String searchNoResultsSub(Object query);

  /// No description provided for @searchDidYouMean.
  ///
  /// In tr, this message translates to:
  /// **'Bunu mu demek istedin?'**
  String get searchDidYouMean;

  /// No description provided for @searchCampus.
  ///
  /// In tr, this message translates to:
  /// **'Kampüslü'**
  String get searchCampus;

  /// No description provided for @searchEst.
  ///
  /// In tr, this message translates to:
  /// **'Kuruluş: {year}'**
  String searchEst(Object year);

  /// No description provided for @homeHeroBannerTitle.
  ///
  /// In tr, this message translates to:
  /// **'Puanını Hesapla,\nHedefini Belirle!'**
  String get homeHeroBannerTitle;

  /// No description provided for @reviewSortLabel.
  ///
  /// In tr, this message translates to:
  /// **'Sırala:'**
  String get reviewSortLabel;

  /// No description provided for @reviewSortNewest.
  ///
  /// In tr, this message translates to:
  /// **'En Yeni'**
  String get reviewSortNewest;

  /// No description provided for @reviewSortMostLiked.
  ///
  /// In tr, this message translates to:
  /// **'En Beğenilen'**
  String get reviewSortMostLiked;

  /// No description provided for @uniDetailDepartments.
  ///
  /// In tr, this message translates to:
  /// **'Bölümler'**
  String get uniDetailDepartments;

  /// No description provided for @uniDetailDepartmentsSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'{count} bölüm — En çok aranan 3 tanesi'**
  String uniDetailDepartmentsSubtitle(int count);

  /// No description provided for @uniDetailSeeAllDepartments.
  ///
  /// In tr, this message translates to:
  /// **'Tüm bölümleri gör'**
  String get uniDetailSeeAllDepartments;

  /// No description provided for @uniDetailReviews.
  ///
  /// In tr, this message translates to:
  /// **'Yorumlar'**
  String get uniDetailReviews;

  /// No description provided for @uniDetailReviewsSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'{count} yorum — En çok beğenilen 3 tanesi'**
  String uniDetailReviewsSubtitle(int count);

  /// No description provided for @uniDetailNoReviews.
  ///
  /// In tr, this message translates to:
  /// **'Henüz yorum yok'**
  String get uniDetailNoReviews;

  /// No description provided for @uniDetailSeeAllReviews.
  ///
  /// In tr, this message translates to:
  /// **'Tüm yorumları gör'**
  String get uniDetailSeeAllReviews;

  /// No description provided for @uniDetailWriteFirstReview.
  ///
  /// In tr, this message translates to:
  /// **'İlk yorumu sen yaz'**
  String get uniDetailWriteFirstReview;

  /// No description provided for @googleReviewsTitle.
  ///
  /// In tr, this message translates to:
  /// **'Google Yorumları'**
  String get googleReviewsTitle;

  /// No description provided for @googleReviewsTileSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Google Haritalar kullanıcılarının değerlendirmeleri'**
  String get googleReviewsTileSubtitle;

  /// No description provided for @googleReviewsCount.
  ///
  /// In tr, this message translates to:
  /// **'{count} değerlendirme'**
  String googleReviewsCount(int count);

  /// No description provided for @googleReviewsAttribution.
  ///
  /// In tr, this message translates to:
  /// **'Yorumlar Google tarafından sağlanmaktadır'**
  String get googleReviewsAttribution;

  /// No description provided for @reviewBadgeOwnUniversity.
  ///
  /// In tr, this message translates to:
  /// **'Bu üniversitenin öğrencisi'**
  String get reviewBadgeOwnUniversity;

  /// No description provided for @reviewBadgeOtherUniversity.
  ///
  /// In tr, this message translates to:
  /// **'Başka üniversiteden öğrenci'**
  String get reviewBadgeOtherUniversity;

  /// No description provided for @reviewPromptTitleOwn.
  ///
  /// In tr, this message translates to:
  /// **'Üniversiteni değerlendir'**
  String get reviewPromptTitleOwn;

  /// No description provided for @reviewPromptTitleOther.
  ///
  /// In tr, this message translates to:
  /// **'Bu üniversiteyi değerlendir'**
  String get reviewPromptTitleOther;

  /// No description provided for @reviewPromptBodyOwn.
  ///
  /// In tr, this message translates to:
  /// **'{uniName} deneyimini paylaş, senden sonraki öğrencilere yol göster.'**
  String reviewPromptBodyOwn(String uniName);

  /// No description provided for @reviewPromptBodyOther.
  ///
  /// In tr, this message translates to:
  /// **'{uniName} hakkında bilgin varsa deneyimini paylaşarak tercih yapacak öğrencilere yardımcı olabilirsin.'**
  String reviewPromptBodyOther(String uniName);

  /// No description provided for @reviewPromptCta.
  ///
  /// In tr, this message translates to:
  /// **'Yorum yaz'**
  String get reviewPromptCta;

  /// No description provided for @reviewPromptLater.
  ///
  /// In tr, this message translates to:
  /// **'Daha sonra'**
  String get reviewPromptLater;

  /// No description provided for @reviewPromptNever.
  ///
  /// In tr, this message translates to:
  /// **'Bir daha gösterme'**
  String get reviewPromptNever;

  /// No description provided for @badgeFirstReview.
  ///
  /// In tr, this message translates to:
  /// **'İlk Yorum'**
  String get badgeFirstReview;

  /// No description provided for @badgeFirstReviewDesc.
  ///
  /// In tr, this message translates to:
  /// **'İlk onaylı yorumunu yaz'**
  String get badgeFirstReviewDesc;

  /// No description provided for @badgeDetailedReviewer.
  ///
  /// In tr, this message translates to:
  /// **'Detaylı Yorumcu'**
  String get badgeDetailedReviewer;

  /// No description provided for @badgeDetailedReviewerDesc.
  ///
  /// In tr, this message translates to:
  /// **'3 onaylı yorum yaz'**
  String get badgeDetailedReviewerDesc;

  /// No description provided for @badgeHelpful.
  ///
  /// In tr, this message translates to:
  /// **'Faydalı'**
  String get badgeHelpful;

  /// No description provided for @badgeHelpfulDesc.
  ///
  /// In tr, this message translates to:
  /// **'Yorumların toplam 10 beğeni alsın'**
  String get badgeHelpfulDesc;

  /// No description provided for @badgeProlificReviewer.
  ///
  /// In tr, this message translates to:
  /// **'Usta Yorumcu'**
  String get badgeProlificReviewer;

  /// No description provided for @badgeProlificReviewerDesc.
  ///
  /// In tr, this message translates to:
  /// **'10 onaylı yorum yaz'**
  String get badgeProlificReviewerDesc;

  /// No description provided for @badgeReviewLegend.
  ///
  /// In tr, this message translates to:
  /// **'Efsane Yorumcu'**
  String get badgeReviewLegend;

  /// No description provided for @badgeReviewLegendDesc.
  ///
  /// In tr, this message translates to:
  /// **'25 onaylı yorum yaz'**
  String get badgeReviewLegendDesc;

  /// No description provided for @badgeCommunityHero.
  ///
  /// In tr, this message translates to:
  /// **'Topluluk Kahramanı'**
  String get badgeCommunityHero;

  /// No description provided for @badgeCommunityHeroDesc.
  ///
  /// In tr, this message translates to:
  /// **'Yorumların toplam 50 beğeni alsın'**
  String get badgeCommunityHeroDesc;

  /// No description provided for @badgeLikeMagnet.
  ///
  /// In tr, this message translates to:
  /// **'Beğeni Mıknatısı'**
  String get badgeLikeMagnet;

  /// No description provided for @badgeLikeMagnetDesc.
  ///
  /// In tr, this message translates to:
  /// **'Yorumların toplam 150 beğeni alsın'**
  String get badgeLikeMagnetDesc;

  /// No description provided for @badgeCollector.
  ///
  /// In tr, this message translates to:
  /// **'Koleksiyoncu'**
  String get badgeCollector;

  /// No description provided for @badgeCollectorDesc.
  ///
  /// In tr, this message translates to:
  /// **'5 üniversiteyi favorilerine ekle'**
  String get badgeCollectorDesc;

  /// No description provided for @badgeMasterCollector.
  ///
  /// In tr, this message translates to:
  /// **'Hazine Avcısı'**
  String get badgeMasterCollector;

  /// No description provided for @badgeMasterCollectorDesc.
  ///
  /// In tr, this message translates to:
  /// **'15 üniversiteyi favorilerine ekle'**
  String get badgeMasterCollectorDesc;

  /// No description provided for @badgeExplorer.
  ///
  /// In tr, this message translates to:
  /// **'Kaşif'**
  String get badgeExplorer;

  /// No description provided for @badgeExplorerDesc.
  ///
  /// In tr, this message translates to:
  /// **'10 farklı üniversiteyi incele'**
  String get badgeExplorerDesc;

  /// No description provided for @badgeWanderer.
  ///
  /// In tr, this message translates to:
  /// **'Gezgin'**
  String get badgeWanderer;

  /// No description provided for @badgeWandererDesc.
  ///
  /// In tr, this message translates to:
  /// **'30 farklı üniversiteyi incele'**
  String get badgeWandererDesc;

  /// No description provided for @badgeCartographer.
  ///
  /// In tr, this message translates to:
  /// **'Harita Ustası'**
  String get badgeCartographer;

  /// No description provided for @badgeCartographerDesc.
  ///
  /// In tr, this message translates to:
  /// **'60 farklı üniversiteyi incele'**
  String get badgeCartographerDesc;

  /// No description provided for @badgeCityTraveler.
  ///
  /// In tr, this message translates to:
  /// **'Şehir Gezgini'**
  String get badgeCityTraveler;

  /// No description provided for @badgeCityTravelerDesc.
  ///
  /// In tr, this message translates to:
  /// **'5 farklı şehri keşfet'**
  String get badgeCityTravelerDesc;

  /// No description provided for @badgeAnalyst.
  ///
  /// In tr, this message translates to:
  /// **'Analist'**
  String get badgeAnalyst;

  /// No description provided for @badgeAnalystDesc.
  ///
  /// In tr, this message translates to:
  /// **'5 karşılaştırma yap'**
  String get badgeAnalystDesc;

  /// No description provided for @badgeStrategist.
  ///
  /// In tr, this message translates to:
  /// **'Stratejist'**
  String get badgeStrategist;

  /// No description provided for @badgeStrategistDesc.
  ///
  /// In tr, this message translates to:
  /// **'20 karşılaştırma yap'**
  String get badgeStrategistDesc;

  /// No description provided for @badgeAmbassador.
  ///
  /// In tr, this message translates to:
  /// **'Elçi'**
  String get badgeAmbassador;

  /// No description provided for @badgeAmbassadorDesc.
  ///
  /// In tr, this message translates to:
  /// **'3 kez paylaşım yap'**
  String get badgeAmbassadorDesc;

  /// No description provided for @badgeSuperAmbassador.
  ///
  /// In tr, this message translates to:
  /// **'Marka Elçisi'**
  String get badgeSuperAmbassador;

  /// No description provided for @badgeSuperAmbassadorDesc.
  ///
  /// In tr, this message translates to:
  /// **'10 kez paylaşım yap'**
  String get badgeSuperAmbassadorDesc;

  /// No description provided for @badgeStreakStarter.
  ///
  /// In tr, this message translates to:
  /// **'Kıvılcım'**
  String get badgeStreakStarter;

  /// No description provided for @badgeStreakStarterDesc.
  ///
  /// In tr, this message translates to:
  /// **'3 gün üst üste uygulamaya gir'**
  String get badgeStreakStarterDesc;

  /// No description provided for @badgeStreakKeeper.
  ///
  /// In tr, this message translates to:
  /// **'Alev Ustası'**
  String get badgeStreakKeeper;

  /// No description provided for @badgeStreakKeeperDesc.
  ///
  /// In tr, this message translates to:
  /// **'7 gün üst üste uygulamaya gir'**
  String get badgeStreakKeeperDesc;

  /// No description provided for @badgeStreakMaster.
  ///
  /// In tr, this message translates to:
  /// **'Sönmeyen Alev'**
  String get badgeStreakMaster;

  /// No description provided for @badgeStreakMasterDesc.
  ///
  /// In tr, this message translates to:
  /// **'30 gün üst üste uygulamaya gir'**
  String get badgeStreakMasterDesc;

  /// No description provided for @badgeLoyalMember.
  ///
  /// In tr, this message translates to:
  /// **'Sadık Üye'**
  String get badgeLoyalMember;

  /// No description provided for @badgeLoyalMemberDesc.
  ///
  /// In tr, this message translates to:
  /// **'30 gündür aramızda ol'**
  String get badgeLoyalMemberDesc;

  /// No description provided for @badgeVeteran.
  ///
  /// In tr, this message translates to:
  /// **'Emektar'**
  String get badgeVeteran;

  /// No description provided for @badgeVeteranDesc.
  ///
  /// In tr, this message translates to:
  /// **'1 yıldır aramızda ol'**
  String get badgeVeteranDesc;

  /// No description provided for @badgeProfileComplete.
  ///
  /// In tr, this message translates to:
  /// **'Vitrin'**
  String get badgeProfileComplete;

  /// No description provided for @badgeProfileCompleteDesc.
  ///
  /// In tr, this message translates to:
  /// **'Profilini tamamla: fotoğraf, tanıtım, bölüm ve sınıf'**
  String get badgeProfileCompleteDesc;

  /// No description provided for @badgeVerifiedScholar.
  ///
  /// In tr, this message translates to:
  /// **'Onaylı Öğrenci'**
  String get badgeVerifiedScholar;

  /// No description provided for @badgeVerifiedScholarDesc.
  ///
  /// In tr, this message translates to:
  /// **'edu.tr e-postanla öğrenciliğini doğrula'**
  String get badgeVerifiedScholarDesc;

  /// No description provided for @badgeEarlyAdopter.
  ///
  /// In tr, this message translates to:
  /// **'İlk Nesil'**
  String get badgeEarlyAdopter;

  /// No description provided for @badgeEarlyAdopterDesc.
  ///
  /// In tr, this message translates to:
  /// **'Uygulamanın ilk kullanıcılarından oldun'**
  String get badgeEarlyAdopterDesc;

  /// No description provided for @badgesScreenTitle.
  ///
  /// In tr, this message translates to:
  /// **'Rozetlerim'**
  String get badgesScreenTitle;

  /// No description provided for @badgesEarnedCount.
  ///
  /// In tr, this message translates to:
  /// **'{earned}/{total}'**
  String badgesEarnedCount(int earned, int total);

  /// No description provided for @badgesSeeAll.
  ///
  /// In tr, this message translates to:
  /// **'Tümünü Gör'**
  String get badgesSeeAll;

  /// No description provided for @badgeProgressLabel.
  ///
  /// In tr, this message translates to:
  /// **'{current}/{target}'**
  String badgeProgressLabel(int current, int target);

  /// No description provided for @badgeEarnedOn.
  ///
  /// In tr, this message translates to:
  /// **'{date} tarihinde kazanıldı'**
  String badgeEarnedOn(String date);

  /// No description provided for @badgeLockedLabel.
  ///
  /// In tr, this message translates to:
  /// **'Kilitli'**
  String get badgeLockedLabel;

  /// No description provided for @badgeCelebrationTitle.
  ///
  /// In tr, this message translates to:
  /// **'Yeni Rozet Kazandın!'**
  String get badgeCelebrationTitle;

  /// No description provided for @badgeCelebrationAction.
  ///
  /// In tr, this message translates to:
  /// **'Harika!'**
  String get badgeCelebrationAction;

  /// No description provided for @badgeCelebrationSecondary.
  ///
  /// In tr, this message translates to:
  /// **'Rozetlerim'**
  String get badgeCelebrationSecondary;

  /// No description provided for @badgeCategoryReviewer.
  ///
  /// In tr, this message translates to:
  /// **'Yorumcu'**
  String get badgeCategoryReviewer;

  /// No description provided for @badgeCategoryHero.
  ///
  /// In tr, this message translates to:
  /// **'Kahraman'**
  String get badgeCategoryHero;

  /// No description provided for @badgeCategoryCollection.
  ///
  /// In tr, this message translates to:
  /// **'Koleksiyon'**
  String get badgeCategoryCollection;

  /// No description provided for @badgeCategoryExplorer.
  ///
  /// In tr, this message translates to:
  /// **'Keşif'**
  String get badgeCategoryExplorer;

  /// No description provided for @badgeCategoryAnalyst.
  ///
  /// In tr, this message translates to:
  /// **'Analiz'**
  String get badgeCategoryAnalyst;

  /// No description provided for @badgeCategoryAmbassador.
  ///
  /// In tr, this message translates to:
  /// **'Paylaşım'**
  String get badgeCategoryAmbassador;

  /// No description provided for @badgeCategoryStreak.
  ///
  /// In tr, this message translates to:
  /// **'Seri'**
  String get badgeCategoryStreak;

  /// No description provided for @badgeCategoryMembership.
  ///
  /// In tr, this message translates to:
  /// **'Üyelik'**
  String get badgeCategoryMembership;

  /// No description provided for @badgeCategorySpecial.
  ///
  /// In tr, this message translates to:
  /// **'Özel'**
  String get badgeCategorySpecial;

  /// No description provided for @uniDetailPlaces.
  ///
  /// In tr, this message translates to:
  /// **'Mekanlar'**
  String get uniDetailPlaces;

  /// No description provided for @uniDetailPlacesSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'{count} mekan'**
  String uniDetailPlacesSubtitle(int count);

  /// No description provided for @uniDetailPlacesComingSoon.
  ///
  /// In tr, this message translates to:
  /// **'Yakında sizlerin önerileriyle!'**
  String get uniDetailPlacesComingSoon;

  /// No description provided for @uniDetailSeeAllPlaces.
  ///
  /// In tr, this message translates to:
  /// **'Tüm mekanları gör'**
  String get uniDetailSeeAllPlaces;

  /// No description provided for @uniDetailPlacesLoading.
  ///
  /// In tr, this message translates to:
  /// **'Yükleniyor...'**
  String get uniDetailPlacesLoading;

  /// No description provided for @uniDetailPlacesLoadError.
  ///
  /// In tr, this message translates to:
  /// **'Yüklenemedi'**
  String get uniDetailPlacesLoadError;

  /// No description provided for @uniDetailOpenMap.
  ///
  /// In tr, this message translates to:
  /// **'Haritada Aç'**
  String get uniDetailOpenMap;

  /// No description provided for @uniDetailGallery.
  ///
  /// In tr, this message translates to:
  /// **'Galeri'**
  String get uniDetailGallery;

  /// No description provided for @uniDetailCategoryRatings.
  ///
  /// In tr, this message translates to:
  /// **'Kategori Puanları'**
  String get uniDetailCategoryRatings;

  /// No description provided for @uniDetailRateUniversity.
  ///
  /// In tr, this message translates to:
  /// **'Üniversiteyi Değerlendir'**
  String get uniDetailRateUniversity;

  /// No description provided for @uniDetailPlacesEmptyTitle.
  ///
  /// In tr, this message translates to:
  /// **'Kafeler Yakında!'**
  String get uniDetailPlacesEmptyTitle;

  /// No description provided for @uniDetailPlacesEmptyDesc.
  ///
  /// In tr, this message translates to:
  /// **'Bu bölüme yakında kafeler ve mekanlar eklenecek.\nSizlerin önerileriyle bu listeyi oluşturacağız! 🎉'**
  String get uniDetailPlacesEmptyDesc;

  /// No description provided for @exploreFoundCount.
  ///
  /// In tr, this message translates to:
  /// **'{count} üniversite bulundu'**
  String exploreFoundCount(int count);

  /// No description provided for @exploreShowResults.
  ///
  /// In tr, this message translates to:
  /// **'Sonuçları Göster'**
  String get exploreShowResults;

  /// No description provided for @commonActions.
  ///
  /// In tr, this message translates to:
  /// **'İşlemler'**
  String get commonActions;

  /// No description provided for @commonPrivate.
  ///
  /// In tr, this message translates to:
  /// **'Gizli'**
  String get commonPrivate;

  /// No description provided for @commonPublic.
  ///
  /// In tr, this message translates to:
  /// **'Açık'**
  String get commonPublic;

  /// No description provided for @commonPublicLong.
  ///
  /// In tr, this message translates to:
  /// **'Herkese Açık'**
  String get commonPublicLong;

  /// No description provided for @commonSelect.
  ///
  /// In tr, this message translates to:
  /// **'Seç'**
  String get commonSelect;

  /// No description provided for @commonNoData.
  ///
  /// In tr, this message translates to:
  /// **'Veri yok'**
  String get commonNoData;

  /// No description provided for @commonNoDataLower.
  ///
  /// In tr, this message translates to:
  /// **'veri yok'**
  String get commonNoDataLower;

  /// No description provided for @semanticUniversityLogo.
  ///
  /// In tr, this message translates to:
  /// **'Üniversite logosu'**
  String get semanticUniversityLogo;

  /// No description provided for @universityTypeState.
  ///
  /// In tr, this message translates to:
  /// **'Devlet'**
  String get universityTypeState;

  /// No description provided for @universityTypeFoundation.
  ///
  /// In tr, this message translates to:
  /// **'Vakıf'**
  String get universityTypeFoundation;

  /// No description provided for @campusLayoutCampus.
  ///
  /// In tr, this message translates to:
  /// **'Kampüslü'**
  String get campusLayoutCampus;

  /// No description provided for @campusLayoutBlock.
  ///
  /// In tr, this message translates to:
  /// **'Blok Yerleşke'**
  String get campusLayoutBlock;

  /// No description provided for @campusLayoutDistributed.
  ///
  /// In tr, this message translates to:
  /// **'Dağınık Kampüs'**
  String get campusLayoutDistributed;

  /// No description provided for @departmentTypeUndergraduate.
  ///
  /// In tr, this message translates to:
  /// **'Lisans'**
  String get departmentTypeUndergraduate;

  /// No description provided for @departmentTypeAssociate.
  ///
  /// In tr, this message translates to:
  /// **'Önlisans'**
  String get departmentTypeAssociate;

  /// No description provided for @departmentLanguageTurkish.
  ///
  /// In tr, this message translates to:
  /// **'Türkçe'**
  String get departmentLanguageTurkish;

  /// No description provided for @departmentLanguageEnglish.
  ///
  /// In tr, this message translates to:
  /// **'İngilizce'**
  String get departmentLanguageEnglish;

  /// No description provided for @yearsCount.
  ///
  /// In tr, this message translates to:
  /// **'{years} yıl'**
  String yearsCount(int years);

  /// No description provided for @prefListsTitle.
  ///
  /// In tr, this message translates to:
  /// **'Tercih Listelerim'**
  String get prefListsTitle;

  /// No description provided for @prefListsNewList.
  ///
  /// In tr, this message translates to:
  /// **'Yeni Liste'**
  String get prefListsNewList;

  /// No description provided for @prefListsLoginTitle.
  ///
  /// In tr, this message translates to:
  /// **'Giriş Yapmalısın'**
  String get prefListsLoginTitle;

  /// No description provided for @prefListsLoginDesc.
  ///
  /// In tr, this message translates to:
  /// **'Listelerini görmek ve yeni tercihler eklemek için önce giriş yapmalısın.'**
  String get prefListsLoginDesc;

  /// No description provided for @prefListDeleteTitle.
  ///
  /// In tr, this message translates to:
  /// **'Listeyi Sil'**
  String get prefListDeleteTitle;

  /// No description provided for @prefListDeleteConfirm.
  ///
  /// In tr, this message translates to:
  /// **'\"{title}\" listesini silmek istediğine emin misin? Bu işlem geri alınamaz.'**
  String prefListDeleteConfirm(String title);

  /// No description provided for @prefListItemLimit.
  ///
  /// In tr, this message translates to:
  /// **'/ {max} tercih'**
  String prefListItemLimit(int max);

  /// No description provided for @prefListItemCount.
  ///
  /// In tr, this message translates to:
  /// **'{count} tercih'**
  String prefListItemCount(int count);

  /// No description provided for @prefListActionsShare.
  ///
  /// In tr, this message translates to:
  /// **'Listeyi Paylaş'**
  String get prefListActionsShare;

  /// No description provided for @prefListActionsShareDesc.
  ///
  /// In tr, this message translates to:
  /// **'Paylaşım bağlantısını ve görünürlüğü yönet'**
  String get prefListActionsShareDesc;

  /// No description provided for @prefListActionsDeleteDesc.
  ///
  /// In tr, this message translates to:
  /// **'Bu işlem geri alınamaz'**
  String get prefListActionsDeleteDesc;

  /// No description provided for @prefListCreateTitle.
  ///
  /// In tr, this message translates to:
  /// **'Yeni tercih listesi'**
  String get prefListCreateTitle;

  /// No description provided for @prefListCreateSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Adını sen koy, doldurmasına ben yardım edeyim.'**
  String get prefListCreateSubtitle;

  /// No description provided for @prefListTitleLabel.
  ///
  /// In tr, this message translates to:
  /// **'Liste adı'**
  String get prefListTitleLabel;

  /// No description provided for @prefListTitleRequired.
  ///
  /// In tr, this message translates to:
  /// **'Liste adı gerekli'**
  String get prefListTitleRequired;

  /// No description provided for @prefListTitleHint.
  ///
  /// In tr, this message translates to:
  /// **'Örn. 2025 Sayısal Tercihlerim'**
  String get prefListTitleHint;

  /// No description provided for @prefListNameIdeasLabel.
  ///
  /// In tr, this message translates to:
  /// **'Hazır adlar'**
  String get prefListNameIdeasLabel;

  /// No description provided for @prefListNameIdeaTyped.
  ///
  /// In tr, this message translates to:
  /// **'{type} Planım'**
  String prefListNameIdeaTyped(String type);

  /// No description provided for @prefListNameIdeaMain.
  ///
  /// In tr, this message translates to:
  /// **'Ana Planım'**
  String get prefListNameIdeaMain;

  /// No description provided for @prefListNameIdeaBackup.
  ///
  /// In tr, this message translates to:
  /// **'Yedek Plan'**
  String get prefListNameIdeaBackup;

  /// No description provided for @prefListNameIdeaDream.
  ///
  /// In tr, this message translates to:
  /// **'Hayallerim'**
  String get prefListNameIdeaDream;

  /// No description provided for @prefListDescriptionLabel.
  ///
  /// In tr, this message translates to:
  /// **'Açıklama (opsiyonel)'**
  String get prefListDescriptionLabel;

  /// No description provided for @prefListDescriptionHint.
  ///
  /// In tr, this message translates to:
  /// **'Bu liste hakkında kısa not…'**
  String get prefListDescriptionHint;

  /// No description provided for @prefListPublicTitle.
  ///
  /// In tr, this message translates to:
  /// **'Herkese açık'**
  String get prefListPublicTitle;

  /// No description provided for @prefListPublicCreateSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Bağlantıyı paylaştığın herkes listeyi görebilir'**
  String get prefListPublicCreateSubtitle;

  /// No description provided for @prefListPublicShareSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Linke sahip herkes listeni görebilir'**
  String get prefListPublicShareSubtitle;

  /// No description provided for @prefListCreateButton.
  ///
  /// In tr, this message translates to:
  /// **'Listeyi Oluştur'**
  String get prefListCreateButton;

  /// No description provided for @prefListShareTitle.
  ///
  /// In tr, this message translates to:
  /// **'Listeyi Paylaş'**
  String get prefListShareTitle;

  /// No description provided for @prefListLinkCopied.
  ///
  /// In tr, this message translates to:
  /// **'Bağlantı kopyalandı'**
  String get prefListLinkCopied;

  /// No description provided for @prefListShareLinkButton.
  ///
  /// In tr, this message translates to:
  /// **'Bağlantıyı Paylaş'**
  String get prefListShareLinkButton;

  /// No description provided for @prefListViewCount.
  ///
  /// In tr, this message translates to:
  /// **'{count} görüntülenme'**
  String prefListViewCount(int count);

  /// No description provided for @prefListPrivateNotice.
  ///
  /// In tr, this message translates to:
  /// **'Listen şu an gizli. Paylaşmak için yukarıdaki anahtarı aç.'**
  String get prefListPrivateNotice;

  /// No description provided for @prefListShareTextHeader.
  ///
  /// In tr, this message translates to:
  /// **'\"{title}\" tercih listemi paylaştım 🎓'**
  String prefListShareTextHeader(String title);

  /// No description provided for @prefListShareTextExtra.
  ///
  /// In tr, this message translates to:
  /// **'…ve {count} bölüm daha'**
  String prefListShareTextExtra(int count);

  /// No description provided for @prefListDuplicateDepartment.
  ///
  /// In tr, this message translates to:
  /// **'Bu bölüm zaten listede'**
  String get prefListDuplicateDepartment;

  /// No description provided for @prefListMaxItems.
  ///
  /// In tr, this message translates to:
  /// **'Listede en fazla {max} tercih olabilir'**
  String prefListMaxItems(int max);

  /// No description provided for @prefListSaveError.
  ///
  /// In tr, this message translates to:
  /// **'Kaydetme hatası: {error}'**
  String prefListSaveError(String error);

  /// No description provided for @prefListDeleted.
  ///
  /// In tr, this message translates to:
  /// **'Tercih listesi silindi'**
  String get prefListDeleted;

  /// No description provided for @prefListDeleteError.
  ///
  /// In tr, this message translates to:
  /// **'Silme hatası: {error}'**
  String prefListDeleteError(String error);

  /// No description provided for @prefListNotFound.
  ///
  /// In tr, this message translates to:
  /// **'Liste bulunamadı.'**
  String get prefListNotFound;

  /// No description provided for @prefListFullLimit.
  ///
  /// In tr, this message translates to:
  /// **'Limit dolu ({max})'**
  String prefListFullLimit(int max);

  /// No description provided for @prefListAddDepartment.
  ///
  /// In tr, this message translates to:
  /// **'Bölüm Ekle'**
  String get prefListAddDepartment;

  /// No description provided for @prefListUndo.
  ///
  /// In tr, this message translates to:
  /// **'Geri Al'**
  String get prefListUndo;

  /// No description provided for @prefListsSummary.
  ///
  /// In tr, this message translates to:
  /// **'{lists} liste · {items} tercih'**
  String prefListsSummary(int lists, int items);

  /// No description provided for @prefListEmptyItemsTitle.
  ///
  /// In tr, this message translates to:
  /// **'Bu liste henüz boş'**
  String get prefListEmptyItemsTitle;

  /// No description provided for @prefListEmptyItemsDesc.
  ///
  /// In tr, this message translates to:
  /// **'ÖSYM’de {max} tercih hakkın var. İlkini ekleyelim mi?'**
  String prefListEmptyItemsDesc(int max);

  /// No description provided for @prefDeptSelectUniversity.
  ///
  /// In tr, this message translates to:
  /// **'Üniversite Seç'**
  String get prefDeptSelectUniversity;

  /// No description provided for @prefDeptSelectDepartment.
  ///
  /// In tr, this message translates to:
  /// **'Bölüm Seç'**
  String get prefDeptSelectDepartment;

  /// No description provided for @prefDeptSearchUniversity.
  ///
  /// In tr, this message translates to:
  /// **'Üniversite ara…'**
  String get prefDeptSearchUniversity;

  /// No description provided for @prefDeptSearchDepartment.
  ///
  /// In tr, this message translates to:
  /// **'Bölüm ara…'**
  String get prefDeptSearchDepartment;

  /// No description provided for @prefNoSearchResults.
  ///
  /// In tr, this message translates to:
  /// **'Sonuç bulunamadı'**
  String get prefNoSearchResults;

  /// No description provided for @prefNoSearchResultsDesc.
  ///
  /// In tr, this message translates to:
  /// **'Farklı bir arama deneyebilirsin.'**
  String get prefNoSearchResultsDesc;

  /// No description provided for @prefNoDepartmentsTitle.
  ///
  /// In tr, this message translates to:
  /// **'Bölüm bulunamadı'**
  String get prefNoDepartmentsTitle;

  /// No description provided for @prefNoDepartmentsDesc.
  ///
  /// In tr, this message translates to:
  /// **'Bu üniversite için kayıtlı bölüm yok.'**
  String get prefNoDepartmentsDesc;

  /// No description provided for @prefDeptUniversitiesWithDepartment.
  ///
  /// In tr, this message translates to:
  /// **'{department} bölümü olan üniversiteler'**
  String prefDeptUniversitiesWithDepartment(String department);

  /// No description provided for @prefDeptNoUniversityForDepartment.
  ///
  /// In tr, this message translates to:
  /// **'Bu bölüme sahip üniversite bulunamadı'**
  String get prefDeptNoUniversityForDepartment;

  /// No description provided for @prefDeptNoOtherUniversityForDepartment.
  ///
  /// In tr, this message translates to:
  /// **'\"{department}\" bölümü olan başka üniversite yok.'**
  String prefDeptNoOtherUniversityForDepartment(String department);

  /// No description provided for @prefBaseScoreShort.
  ///
  /// In tr, this message translates to:
  /// **'Taban'**
  String get prefBaseScoreShort;

  /// No description provided for @prefSharedListLoadError.
  ///
  /// In tr, this message translates to:
  /// **'Liste yüklenemedi'**
  String get prefSharedListLoadError;

  /// No description provided for @prefSharedListBadge.
  ///
  /// In tr, this message translates to:
  /// **'Paylaşılan Liste'**
  String get prefSharedListBadge;

  /// No description provided for @prefSharedListOwner.
  ///
  /// In tr, this message translates to:
  /// **'Liste sahibi'**
  String get prefSharedListOwner;

  /// No description provided for @prefSharedListEmptyDesc.
  ///
  /// In tr, this message translates to:
  /// **'Bu listede henüz tercih yok.'**
  String get prefSharedListEmptyDesc;

  /// No description provided for @prefSharedListHiddenOrDeleted.
  ///
  /// In tr, this message translates to:
  /// **'Bu liste silinmiş veya gizli olarak işaretlenmiş olabilir.'**
  String get prefSharedListHiddenOrDeleted;

  /// No description provided for @prefSharedListBackHome.
  ///
  /// In tr, this message translates to:
  /// **'Ana Sayfaya Dön'**
  String get prefSharedListBackHome;

  /// No description provided for @prefSharedReadOnlyNotice.
  ///
  /// In tr, this message translates to:
  /// **'Bu listeyi salt görüntüleme modunda inceliyorsun.'**
  String get prefSharedReadOnlyNotice;

  /// No description provided for @prefSharedCopyButton.
  ///
  /// In tr, this message translates to:
  /// **'Kendime Kopyala ve Düzenle'**
  String get prefSharedCopyButton;

  /// No description provided for @prefSharedCopySuccess.
  ///
  /// In tr, this message translates to:
  /// **'Liste sana kopyalandı! Artık düzenleyebilirsin.'**
  String get prefSharedCopySuccess;

  /// No description provided for @prefSharedCopyOwnList.
  ///
  /// In tr, this message translates to:
  /// **'Bu liste zaten sana ait.'**
  String get prefSharedCopyOwnList;

  /// No description provided for @prefSharedEditOwnList.
  ///
  /// In tr, this message translates to:
  /// **'Listeni Düzenle'**
  String get prefSharedEditOwnList;

  /// No description provided for @prefSharedCopyPaywallTitle.
  ///
  /// In tr, this message translates to:
  /// **'Kopyalamak Plus\'a Özel'**
  String get prefSharedCopyPaywallTitle;

  /// No description provided for @prefSharedCopyPaywallDesc.
  ///
  /// In tr, this message translates to:
  /// **'Bu listeyi görüntüleyebilirsin. Kendine kopyalayıp düzenlemek Plus ve Pro üyelere özeldir. Kopyaladığında liste sahibinin listesi değişmez — tamamen sana ait yeni bir kopya oluşur.'**
  String get prefSharedCopyPaywallDesc;

  /// No description provided for @prefSharedCopyPaywallButton.
  ///
  /// In tr, this message translates to:
  /// **'Planları Gör'**
  String get prefSharedCopyPaywallButton;

  /// No description provided for @comparisonHubSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Hangi tür karşılaştırma yapmak istiyorsun?'**
  String get comparisonHubSubtitle;

  /// No description provided for @comparisonHistoryTitle.
  ///
  /// In tr, this message translates to:
  /// **'Karşılaştırma Geçmişi'**
  String get comparisonHistoryTitle;

  /// No description provided for @comparisonHistoryTooltip.
  ///
  /// In tr, this message translates to:
  /// **'Karşılaştırma geçmişi'**
  String get comparisonHistoryTooltip;

  /// No description provided for @comparisonEntityUniversity.
  ///
  /// In tr, this message translates to:
  /// **'Üniversite'**
  String get comparisonEntityUniversity;

  /// No description provided for @comparisonEntityDepartment.
  ///
  /// In tr, this message translates to:
  /// **'Bölüm'**
  String get comparisonEntityDepartment;

  /// No description provided for @comparisonEntityCity.
  ///
  /// In tr, this message translates to:
  /// **'Şehir'**
  String get comparisonEntityCity;

  /// No description provided for @comparisonSubscriptionLabel.
  ///
  /// In tr, this message translates to:
  /// **'Aboneliğin'**
  String get comparisonSubscriptionLabel;

  /// No description provided for @subscriptionFree.
  ///
  /// In tr, this message translates to:
  /// **'Ücretsiz'**
  String get subscriptionFree;

  /// No description provided for @comparisonUpgradePlus.
  ///
  /// In tr, this message translates to:
  /// **'Plus\'a Geç'**
  String get comparisonUpgradePlus;

  /// No description provided for @comparisonResetTitle.
  ///
  /// In tr, this message translates to:
  /// **'Karşılaştırmayı Sıfırla'**
  String get comparisonResetTitle;

  /// No description provided for @comparisonResetConfirm.
  ///
  /// In tr, this message translates to:
  /// **'Mevcut karşılaştırma sıfırlansın mı? Yeni üniversiteler seçebilirsiniz.'**
  String get comparisonResetConfirm;

  /// No description provided for @comparisonAddThirdTooltip.
  ///
  /// In tr, this message translates to:
  /// **'3. üniversite ekle (Pro)'**
  String get comparisonAddThirdTooltip;

  /// No description provided for @comparisonRemoveThirdTooltip.
  ///
  /// In tr, this message translates to:
  /// **'3. üniversiteyi kaldır'**
  String get comparisonRemoveThirdTooltip;

  /// No description provided for @comparisonEmptyUniversityTitle.
  ///
  /// In tr, this message translates to:
  /// **'İki üniversite seç'**
  String get comparisonEmptyUniversityTitle;

  /// No description provided for @comparisonEmptyUniversityDesc.
  ///
  /// In tr, this message translates to:
  /// **'Yukarıdan iki üniversite seçince karşılaştırma sonuçları burada gözükür.'**
  String get comparisonEmptyUniversityDesc;

  /// No description provided for @comparisonNotesTab.
  ///
  /// In tr, this message translates to:
  /// **'Notlarım'**
  String get comparisonNotesTab;

  /// No description provided for @comparisonNotesTabShort.
  ///
  /// In tr, this message translates to:
  /// **'Not'**
  String get comparisonNotesTabShort;

  /// No description provided for @comparisonTabGeneralShort.
  ///
  /// In tr, this message translates to:
  /// **'Gn'**
  String get comparisonTabGeneralShort;

  /// No description provided for @comparisonTabCategoriesShort.
  ///
  /// In tr, this message translates to:
  /// **'Kat'**
  String get comparisonTabCategoriesShort;

  /// No description provided for @comparisonTabChartShort.
  ///
  /// In tr, this message translates to:
  /// **'Grf'**
  String get comparisonTabChartShort;

  /// No description provided for @comparisonTabStatsShort.
  ///
  /// In tr, this message translates to:
  /// **'İst'**
  String get comparisonTabStatsShort;

  /// No description provided for @comparisonSummaryTitle.
  ///
  /// In tr, this message translates to:
  /// **'Karşılaştırma Özeti'**
  String get comparisonSummaryTitle;

  /// No description provided for @comparisonWinnerCategories.
  ///
  /// In tr, this message translates to:
  /// **'🏆 {winnerName} {wins}/{total} kategoride önde'**
  String comparisonWinnerCategories(String winnerName, int wins, int total);

  /// No description provided for @comparisonQuickDepartments.
  ///
  /// In tr, this message translates to:
  /// **'Bölüm'**
  String get comparisonQuickDepartments;

  /// No description provided for @comparisonQuickPlaces.
  ///
  /// In tr, this message translates to:
  /// **'Mekan'**
  String get comparisonQuickPlaces;

  /// No description provided for @comparisonQuickReviews.
  ///
  /// In tr, this message translates to:
  /// **'Yorum'**
  String get comparisonQuickReviews;

  /// No description provided for @reviewCountShort.
  ///
  /// In tr, this message translates to:
  /// **'{count} yorum'**
  String reviewCountShort(int count);

  /// No description provided for @comparisonCategoriesEmptyTitle.
  ///
  /// In tr, this message translates to:
  /// **'Yeterli değerlendirme yok'**
  String get comparisonCategoriesEmptyTitle;

  /// No description provided for @comparisonCategoriesEmptyDesc.
  ///
  /// In tr, this message translates to:
  /// **'Bu iki üniversite için henüz kategori puanı oluşturacak yorum bulunmuyor.'**
  String get comparisonCategoriesEmptyDesc;

  /// No description provided for @comparisonChartEmptyTitle.
  ///
  /// In tr, this message translates to:
  /// **'Grafik üretmek için yorum gerekiyor'**
  String get comparisonChartEmptyTitle;

  /// No description provided for @comparisonChartEmptyDesc.
  ///
  /// In tr, this message translates to:
  /// **'Henüz yeterli değerlendirme olmadığı için grafikler boş görünüyor.'**
  String get comparisonChartEmptyDesc;

  /// No description provided for @comparisonChartHintTitle.
  ///
  /// In tr, this message translates to:
  /// **'Yeni: Pro karşılaştırma grafikleri'**
  String get comparisonChartHintTitle;

  /// No description provided for @comparisonChartHintBody.
  ///
  /// In tr, this message translates to:
  /// **'Radar, ısı haritası ve trend grafiklerini Grafik sekmesinde keşfet.'**
  String get comparisonChartHintBody;

  /// No description provided for @comparisonChartHintCta.
  ///
  /// In tr, this message translates to:
  /// **'Göster'**
  String get comparisonChartHintCta;

  /// No description provided for @comparisonUniversityPickerTitle.
  ///
  /// In tr, this message translates to:
  /// **'Üniversite Karşılaştır'**
  String get comparisonUniversityPickerTitle;

  /// No description provided for @comparisonUniversityPickerSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Karşılaştırmak istediğin iki üniversiteyi seç. Puanlar, kategoriler ve istatistikler yan yana gelsin.'**
  String get comparisonUniversityPickerSubtitle;

  /// No description provided for @comparisonTripleHint.
  ///
  /// In tr, this message translates to:
  /// **'Pro ile 3. üniversiteyi ekleyip üçlü karşılaştırma yapabilirsin.'**
  String get comparisonTripleHint;

  /// No description provided for @comparisonSelectUniversityForA.
  ///
  /// In tr, this message translates to:
  /// **'A için üniversite seç'**
  String get comparisonSelectUniversityForA;

  /// No description provided for @comparisonSelectUniversityForB.
  ///
  /// In tr, this message translates to:
  /// **'B için üniversite seç'**
  String get comparisonSelectUniversityForB;

  /// No description provided for @comparisonDepartmentHeaderTitle.
  ///
  /// In tr, this message translates to:
  /// **'Bölüm Karşılaştır'**
  String get comparisonDepartmentHeaderTitle;

  /// No description provided for @comparisonDepartmentHeaderSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Aynı bölümü iki farklı üniversitede karşılaştır. Taban puan, sıralama ve kontenjan yan yana gelsin.'**
  String get comparisonDepartmentHeaderSubtitle;

  /// No description provided for @comparisonDepartmentHint.
  ///
  /// In tr, this message translates to:
  /// **'İki taraftan da birer bölüm seçince karşılaştırma sonuçları burada gözükecek.'**
  String get comparisonDepartmentHint;

  /// No description provided for @comparisonCityHeaderTitle.
  ///
  /// In tr, this message translates to:
  /// **'Şehir Karşılaştır'**
  String get comparisonCityHeaderTitle;

  /// No description provided for @comparisonCityHeaderSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'İki şehrin üniversite ekosistemini karşılaştır. Devlet/vakıf dağılımı, üniversite sayısı ve daha fazlası.'**
  String get comparisonCityHeaderSubtitle;

  /// No description provided for @comparisonCityHint.
  ///
  /// In tr, this message translates to:
  /// **'İki şehir seçince karşılaştırma sonuçları burada gözükecek.'**
  String get comparisonCityHint;

  /// No description provided for @comparisonSelectCity.
  ///
  /// In tr, this message translates to:
  /// **'Şehir Seç'**
  String get comparisonSelectCity;

  /// No description provided for @comparisonSearchCity.
  ///
  /// In tr, this message translates to:
  /// **'Şehir ara…'**
  String get comparisonSearchCity;

  /// No description provided for @comparisonCityTileMeta.
  ///
  /// In tr, this message translates to:
  /// **'Plaka: {plate} • Üni: {count}'**
  String comparisonCityTileMeta(String plate, int count);

  /// No description provided for @comparisonResultNotFound.
  ///
  /// In tr, this message translates to:
  /// **'Sonuç bulunamadı.'**
  String get comparisonResultNotFound;

  /// No description provided for @comparisonScoreTypeMismatch.
  ///
  /// In tr, this message translates to:
  /// **'Puan türleri farklı görünüyor. Karşılaştırma yanıltıcı olabilir.'**
  String get comparisonScoreTypeMismatch;

  /// No description provided for @comparisonBaseScore2025.
  ///
  /// In tr, this message translates to:
  /// **'Taban Puan (2025)'**
  String get comparisonBaseScore2025;

  /// No description provided for @comparisonDetailedInfo.
  ///
  /// In tr, this message translates to:
  /// **'Detaylı Bilgiler'**
  String get comparisonDetailedInfo;

  /// No description provided for @comparisonFaculty.
  ///
  /// In tr, this message translates to:
  /// **'Fakülte'**
  String get comparisonFaculty;

  /// No description provided for @comparisonRankingTitle.
  ///
  /// In tr, this message translates to:
  /// **'Sıralama'**
  String get comparisonRankingTitle;

  /// No description provided for @comparisonNoDataLower.
  ///
  /// In tr, this message translates to:
  /// **'veri yok'**
  String get comparisonNoDataLower;

  /// No description provided for @comparisonUniversityCount.
  ///
  /// In tr, this message translates to:
  /// **'Üniversite Sayısı'**
  String get comparisonUniversityCount;

  /// No description provided for @comparisonStateFoundationDistribution.
  ///
  /// In tr, this message translates to:
  /// **'Devlet / Vakıf Dağılımı'**
  String get comparisonStateFoundationDistribution;

  /// No description provided for @comparisonPopulation.
  ///
  /// In tr, this message translates to:
  /// **'Nüfus'**
  String get comparisonPopulation;

  /// No description provided for @comparisonCityFeatures.
  ///
  /// In tr, this message translates to:
  /// **'Şehir Özellikleri'**
  String get comparisonCityFeatures;

  /// No description provided for @comparisonPlate.
  ///
  /// In tr, this message translates to:
  /// **'Plaka'**
  String get comparisonPlate;

  /// No description provided for @comparisonTotalUniversities.
  ///
  /// In tr, this message translates to:
  /// **'Toplam Üni'**
  String get comparisonTotalUniversities;

  /// No description provided for @comparisonInUniSec.
  ///
  /// In tr, this message translates to:
  /// **'ÜniSeç\'te'**
  String get comparisonInUniSec;

  /// No description provided for @comparisonProNotesTitle.
  ///
  /// In tr, this message translates to:
  /// **'Karşılaştırma Notları'**
  String get comparisonProNotesTitle;

  /// No description provided for @comparisonProNotesSubtitleLoggedIn.
  ///
  /// In tr, this message translates to:
  /// **'Pro üyelere özel premium bir deneyim seni bekliyor!'**
  String get comparisonProNotesSubtitleLoggedIn;

  /// No description provided for @comparisonProNotesSubtitleGuest.
  ///
  /// In tr, this message translates to:
  /// **'Giriş yap ve Pro üye olarak bu özelliğin kilidini aç!'**
  String get comparisonProNotesSubtitleGuest;

  /// No description provided for @comparisonProNotesFeaturePersonal.
  ///
  /// In tr, this message translates to:
  /// **'Her karşılaştırmaya kişisel not ekle'**
  String get comparisonProNotesFeaturePersonal;

  /// No description provided for @comparisonProNotesFeatureProsCons.
  ///
  /// In tr, this message translates to:
  /// **'Artılar ve eksiler ile detaylı analiz yap'**
  String get comparisonProNotesFeatureProsCons;

  /// No description provided for @comparisonProNotesFeatureRating.
  ///
  /// In tr, this message translates to:
  /// **'1-5 yıldız tercih puanı ile sırala'**
  String get comparisonProNotesFeatureRating;

  /// No description provided for @comparisonProNotesFeatureCloud.
  ///
  /// In tr, this message translates to:
  /// **'Notların bulutta güvende — asla kaybolmaz'**
  String get comparisonProNotesFeatureCloud;

  /// No description provided for @comparisonProNotesUpgrade.
  ///
  /// In tr, this message translates to:
  /// **'Pro Plana Yükselt'**
  String get comparisonProNotesUpgrade;

  /// No description provided for @comparisonProNotesLoginAndPro.
  ///
  /// In tr, this message translates to:
  /// **'Giriş Yap ve Pro Ol'**
  String get comparisonProNotesLoginAndPro;

  /// No description provided for @comparisonSkipForNow.
  ///
  /// In tr, this message translates to:
  /// **'Şimdilik geç'**
  String get comparisonSkipForNow;

  /// No description provided for @comparisonHistoryClearTooltip.
  ///
  /// In tr, this message translates to:
  /// **'Geçmişi temizle'**
  String get comparisonHistoryClearTooltip;

  /// No description provided for @comparisonHistoryClearTitle.
  ///
  /// In tr, this message translates to:
  /// **'Geçmişi Temizle'**
  String get comparisonHistoryClearTitle;

  /// No description provided for @comparisonHistoryClearConfirm.
  ///
  /// In tr, this message translates to:
  /// **'Tüm karşılaştırma geçmişin silinsin mi?'**
  String get comparisonHistoryClearConfirm;

  /// No description provided for @comparisonHistoryClearButton.
  ///
  /// In tr, this message translates to:
  /// **'Temizle'**
  String get comparisonHistoryClearButton;

  /// No description provided for @comparisonHistoryLoadError.
  ///
  /// In tr, this message translates to:
  /// **'Geçmiş yüklenemedi: {error}'**
  String comparisonHistoryLoadError(String error);

  /// No description provided for @comparisonHistoryEmptyTitle.
  ///
  /// In tr, this message translates to:
  /// **'Henüz karşılaştırma yapmadın'**
  String get comparisonHistoryEmptyTitle;

  /// No description provided for @comparisonHistoryEmptyDesc.
  ///
  /// In tr, this message translates to:
  /// **'İlk karşılaştırmanı yaptığında burada görünecek.'**
  String get comparisonHistoryEmptyDesc;

  /// No description provided for @comparisonHistoryPaywallTitle.
  ///
  /// In tr, this message translates to:
  /// **'Karşılaştırma Geçmişi Plus / Pro\'da'**
  String get comparisonHistoryPaywallTitle;

  /// No description provided for @comparisonHistoryPaywallDesc.
  ///
  /// In tr, this message translates to:
  /// **'Yaptığın karşılaştırmalar otomatik kaydedilsin, istediğin zaman tekrar açıp incele.'**
  String get comparisonHistoryPaywallDesc;

  /// No description provided for @comparisonHistoryPaywallButton.
  ///
  /// In tr, this message translates to:
  /// **'Plus / Pro\'ya Geç'**
  String get comparisonHistoryPaywallButton;

  /// No description provided for @comparisonHistoryFeatureRecent.
  ///
  /// In tr, this message translates to:
  /// **'Son 20 karşılaştırma otomatik kaydedilir'**
  String get comparisonHistoryFeatureRecent;

  /// No description provided for @comparisonHistoryFeatureReturn.
  ///
  /// In tr, this message translates to:
  /// **'Tek dokunuşla aynı karşılaştırmaya geri dön'**
  String get comparisonHistoryFeatureReturn;

  /// No description provided for @comparisonHistoryFeatureSync.
  ///
  /// In tr, this message translates to:
  /// **'Cihazlar arası senkronize'**
  String get comparisonHistoryFeatureSync;

  /// No description provided for @comparisonTripleCategoryTitle.
  ///
  /// In tr, this message translates to:
  /// **'Kategori Karşılaştırması'**
  String get comparisonTripleCategoryTitle;

  /// No description provided for @comparisonLeader.
  ///
  /// In tr, this message translates to:
  /// **'LİDER'**
  String get comparisonLeader;

  /// No description provided for @noteEditTitle.
  ///
  /// In tr, this message translates to:
  /// **'Notu Düzenle'**
  String get noteEditTitle;

  /// No description provided for @noteAddTitle.
  ///
  /// In tr, this message translates to:
  /// **'Not Ekle'**
  String get noteAddTitle;

  /// No description provided for @noteSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Karşılaştırma hakkındaki düşüncelerini kaydet'**
  String get noteSubtitle;

  /// No description provided for @notePreferenceRating.
  ///
  /// In tr, this message translates to:
  /// **'Tercih Puanın'**
  String get notePreferenceRating;

  /// No description provided for @noteLabel.
  ///
  /// In tr, this message translates to:
  /// **'Not'**
  String get noteLabel;

  /// No description provided for @noteHint.
  ///
  /// In tr, this message translates to:
  /// **'Örn: İTÜ bana daha yakın, kampüsü çok güzel...'**
  String get noteHint;

  /// No description provided for @noteEmptyError.
  ///
  /// In tr, this message translates to:
  /// **'Not boş bırakılamaz'**
  String get noteEmptyError;

  /// No description provided for @noteProsLabel.
  ///
  /// In tr, this message translates to:
  /// **'Artılar'**
  String get noteProsLabel;

  /// No description provided for @noteConsLabel.
  ///
  /// In tr, this message translates to:
  /// **'Eksiler'**
  String get noteConsLabel;

  /// No description provided for @noteAddProHint.
  ///
  /// In tr, this message translates to:
  /// **'Yeni artı ekle...'**
  String get noteAddProHint;

  /// No description provided for @noteAddConHint.
  ///
  /// In tr, this message translates to:
  /// **'Yeni eksi ekle...'**
  String get noteAddConHint;

  /// No description provided for @noteUpdate.
  ///
  /// In tr, this message translates to:
  /// **'Güncelle'**
  String get noteUpdate;

  /// No description provided for @noteMyNotes.
  ///
  /// In tr, this message translates to:
  /// **'Notlarım'**
  String get noteMyNotes;

  /// No description provided for @noteLoadError.
  ///
  /// In tr, this message translates to:
  /// **'Notlar yüklenemedi.'**
  String get noteLoadError;

  /// No description provided for @noteSavedSnack.
  ///
  /// In tr, this message translates to:
  /// **'Not kaydedildi ✍️'**
  String get noteSavedSnack;

  /// No description provided for @noteUpdatedSnack.
  ///
  /// In tr, this message translates to:
  /// **'Not güncellendi ✅'**
  String get noteUpdatedSnack;

  /// No description provided for @noteDeletedSnack.
  ///
  /// In tr, this message translates to:
  /// **'Not silindi'**
  String get noteDeletedSnack;

  /// No description provided for @noteDeleteTitle.
  ///
  /// In tr, this message translates to:
  /// **'Notu Sil'**
  String get noteDeleteTitle;

  /// No description provided for @noteDeleteConfirm.
  ///
  /// In tr, this message translates to:
  /// **'Bu not kalıcı olarak silinecek. Devam edilsin mi?'**
  String get noteDeleteConfirm;

  /// No description provided for @noteEmptyState.
  ///
  /// In tr, this message translates to:
  /// **'Henüz not yok'**
  String get noteEmptyState;

  /// No description provided for @noteEmptyStateDesc.
  ///
  /// In tr, this message translates to:
  /// **'Bu karşılaştırma hakkındaki düşüncelerini kaydet'**
  String get noteEmptyStateDesc;

  /// No description provided for @noteTimeJustNow.
  ///
  /// In tr, this message translates to:
  /// **'Az önce'**
  String get noteTimeJustNow;

  /// No description provided for @noteTimeMinutesAgo.
  ///
  /// In tr, this message translates to:
  /// **'{minutes} dk önce'**
  String noteTimeMinutesAgo(int minutes);

  /// No description provided for @noteTimeHoursAgo.
  ///
  /// In tr, this message translates to:
  /// **'{hours} saat önce'**
  String noteTimeHoursAgo(int hours);

  /// No description provided for @noteTimeDaysAgo.
  ///
  /// In tr, this message translates to:
  /// **'{days} gün önce'**
  String noteTimeDaysAgo(int days);

  /// No description provided for @noteTimeWeeksAgo.
  ///
  /// In tr, this message translates to:
  /// **'{weeks} hafta önce'**
  String noteTimeWeeksAgo(int weeks);

  /// No description provided for @plusLockSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Plus veya Pro ile açılır'**
  String get plusLockSubtitle;

  /// No description provided for @plusLockButton.
  ///
  /// In tr, this message translates to:
  /// **'Plus\'a Geç'**
  String get plusLockButton;

  /// No description provided for @comparisonNoData.
  ///
  /// In tr, this message translates to:
  /// **'Veri yok'**
  String get comparisonNoData;

  /// No description provided for @trendNoData.
  ///
  /// In tr, this message translates to:
  /// **'Trend verisi yok'**
  String get trendNoData;

  /// No description provided for @shareInstagramStory.
  ///
  /// In tr, this message translates to:
  /// **'Instagram Hikaye (9:16)'**
  String get shareInstagramStory;

  /// No description provided for @shareInstagramPost.
  ///
  /// In tr, this message translates to:
  /// **'Instagram Gönderi (1:1)'**
  String get shareInstagramPost;

  /// No description provided for @shareTwitterWhatsApp.
  ///
  /// In tr, this message translates to:
  /// **'Twitter / WhatsApp'**
  String get shareTwitterWhatsApp;

  /// No description provided for @yearlyTableYear.
  ///
  /// In tr, this message translates to:
  /// **'Yıl'**
  String get yearlyTableYear;

  /// No description provided for @loadFailed.
  ///
  /// In tr, this message translates to:
  /// **'Yüklenemedi: {error}'**
  String loadFailed(String error);

  /// No description provided for @favoriteLoginRequired.
  ///
  /// In tr, this message translates to:
  /// **'Favori için giriş yapmalısın.'**
  String get favoriteLoginRequired;

  /// No description provided for @yearlyComparisonTitle.
  ///
  /// In tr, this message translates to:
  /// **'Yıl Bazlı Karşılaştırma'**
  String get yearlyComparisonTitle;

  /// No description provided for @yearlyDifference.
  ///
  /// In tr, this message translates to:
  /// **'Fark'**
  String get yearlyDifference;

  /// No description provided for @rankFormat.
  ///
  /// In tr, this message translates to:
  /// **'{rank}. sıra'**
  String rankFormat(String rank);

  /// No description provided for @rankNotAnnounced.
  ///
  /// In tr, this message translates to:
  /// **'Sıra: Açıklanmadı'**
  String get rankNotAnnounced;

  /// No description provided for @shareStatAvgBase.
  ///
  /// In tr, this message translates to:
  /// **'Ort. Taban'**
  String get shareStatAvgBase;

  /// No description provided for @shareStatDepartment.
  ///
  /// In tr, this message translates to:
  /// **'Bölüm'**
  String get shareStatDepartment;

  /// No description provided for @shareStatPlace.
  ///
  /// In tr, this message translates to:
  /// **'Mekan'**
  String get shareStatPlace;

  /// No description provided for @shareFormat.
  ///
  /// In tr, this message translates to:
  /// **'Paylaşım Formatı'**
  String get shareFormat;

  /// No description provided for @comparisonSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Üniversiteleri yan yana kıyasla'**
  String get comparisonSubtitle;

  /// No description provided for @comparisonSwapTooltip.
  ///
  /// In tr, this message translates to:
  /// **'Yer Değiştir'**
  String get comparisonSwapTooltip;

  /// No description provided for @comparisonError.
  ///
  /// In tr, this message translates to:
  /// **'Hata: {error}'**
  String comparisonError(String error);

  /// No description provided for @adGateTitleGuest.
  ///
  /// In tr, this message translates to:
  /// **'Reklam ile Karşılaştır'**
  String get adGateTitleGuest;

  /// No description provided for @adGateTitleUser.
  ///
  /// In tr, this message translates to:
  /// **'Ücretsiz hakkın bitti'**
  String get adGateTitleUser;

  /// No description provided for @adGateDescGuest.
  ///
  /// In tr, this message translates to:
  /// **'Karşılaştırma yapmak için kısa bir reklam izlemen gerekiyor. Giriş yap veya Plus\'a geçerek sınırsız karşılaştırma yapabilirsin.'**
  String get adGateDescGuest;

  /// No description provided for @adGateDescUser.
  ///
  /// In tr, this message translates to:
  /// **'Günlük 1 ücretsiz karşılaştırma hakkını kullandın. Devam etmek için kısa bir reklam izleyebilir veya Plus\'a geçerek sınırsız karşılaştırma yapabilirsin.'**
  String get adGateDescUser;

  /// No description provided for @adGateWatchBusy.
  ///
  /// In tr, this message translates to:
  /// **'Reklam hazırlanıyor…'**
  String get adGateWatchBusy;

  /// No description provided for @adGateWatchCta.
  ///
  /// In tr, this message translates to:
  /// **'Reklamı İzle ve Devam Et'**
  String get adGateWatchCta;

  /// No description provided for @adGatePlusCta.
  ///
  /// In tr, this message translates to:
  /// **'Plus\'a Geç — Sınırsız'**
  String get adGatePlusCta;

  /// No description provided for @adGateDismiss.
  ///
  /// In tr, this message translates to:
  /// **'Şimdilik Vazgeç'**
  String get adGateDismiss;

  /// No description provided for @adGateOverlayTitleGuest.
  ///
  /// In tr, this message translates to:
  /// **'Reklam izleyerek devam et'**
  String get adGateOverlayTitleGuest;

  /// No description provided for @adGateOverlayTitleUser.
  ///
  /// In tr, this message translates to:
  /// **'Devam etmek için kilidi aç'**
  String get adGateOverlayTitleUser;

  /// No description provided for @adGateOverlayDescGuest.
  ///
  /// In tr, this message translates to:
  /// **'Karşılaştırma için kısa bir reklam izlemen gerekiyor.'**
  String get adGateOverlayDescGuest;

  /// No description provided for @adGateOverlayDescUser.
  ///
  /// In tr, this message translates to:
  /// **'Günlük karşılaştırma hakkın doldu.'**
  String get adGateOverlayDescUser;

  /// No description provided for @adGateOverlayBusy.
  ///
  /// In tr, this message translates to:
  /// **'Yükleniyor…'**
  String get adGateOverlayBusy;

  /// No description provided for @adGateOverlayCta.
  ///
  /// In tr, this message translates to:
  /// **'Reklamı İzle / Plus\'a Geç'**
  String get adGateOverlayCta;

  /// No description provided for @favoritesAddTitle.
  ///
  /// In tr, this message translates to:
  /// **'Favorilere ekle'**
  String get favoritesAddTitle;

  /// No description provided for @actionBarShare.
  ///
  /// In tr, this message translates to:
  /// **'Paylaş'**
  String get actionBarShare;

  /// No description provided for @actionBarFavorite.
  ///
  /// In tr, this message translates to:
  /// **'Favorile'**
  String get actionBarFavorite;

  /// No description provided for @actionBarRecompare.
  ///
  /// In tr, this message translates to:
  /// **'Yeniden'**
  String get actionBarRecompare;

  /// No description provided for @emptyStateSelectTwo.
  ///
  /// In tr, this message translates to:
  /// **'İki üniversite seç'**
  String get emptyStateSelectTwo;

  /// No description provided for @emptyStateSelectTwoDesc.
  ///
  /// In tr, this message translates to:
  /// **'Yukarıdan iki üniversite seçince karşılaştırma sonuçları burada gözükür.'**
  String get emptyStateSelectTwoDesc;

  /// No description provided for @triplePickerTitle.
  ///
  /// In tr, this message translates to:
  /// **'3. üniversiteyi seç'**
  String get triplePickerTitle;

  /// No description provided for @triplePickerSearchHint.
  ///
  /// In tr, this message translates to:
  /// **'Üniversite ara…'**
  String get triplePickerSearchHint;

  /// No description provided for @triplePickerNoResult.
  ///
  /// In tr, this message translates to:
  /// **'Sonuç bulunamadı'**
  String get triplePickerNoResult;

  /// No description provided for @sectionCategoryScores.
  ///
  /// In tr, this message translates to:
  /// **'Kategori Puanları'**
  String get sectionCategoryScores;

  /// No description provided for @sectionOverview.
  ///
  /// In tr, this message translates to:
  /// **'Genel Görünüm'**
  String get sectionOverview;

  /// No description provided for @sectionStats.
  ///
  /// In tr, this message translates to:
  /// **'Genel İstatistikler'**
  String get sectionStats;

  /// No description provided for @noReviewsTitle.
  ///
  /// In tr, this message translates to:
  /// **'Yeterli değerlendirme yok'**
  String get noReviewsTitle;

  /// No description provided for @noReviewsDesc.
  ///
  /// In tr, this message translates to:
  /// **'Bu iki üniversite için henüz kategori puanı oluşturacak yorum bulunmuyor.'**
  String get noReviewsDesc;

  /// No description provided for @commonReset.
  ///
  /// In tr, this message translates to:
  /// **'Sıfırla'**
  String get commonReset;

  /// No description provided for @prefListsOthersHeading.
  ///
  /// In tr, this message translates to:
  /// **'DİĞER LİSTELERİN'**
  String get prefListsOthersHeading;

  /// No description provided for @prefListsMainBadge.
  ///
  /// In tr, this message translates to:
  /// **'ANA LİSTEN'**
  String get prefListsMainBadge;

  /// No description provided for @prefListsOpen.
  ///
  /// In tr, this message translates to:
  /// **'Listeyi aç'**
  String get prefListsOpen;

  /// No description provided for @prefListsSlotsFree.
  ///
  /// In tr, this message translates to:
  /// **'{count} hak boş'**
  String prefListsSlotsFree(int count);

  /// No description provided for @prefListsEmptyHeroTitle.
  ///
  /// In tr, this message translates to:
  /// **'Listeni birlikte kuralım'**
  String get prefListsEmptyHeroTitle;

  /// No description provided for @prefListsEmptyHeroDesc.
  ///
  /// In tr, this message translates to:
  /// **'Puanına uyan programlardan dengeli bir taslak hazırlayayım; beğenmediğini çıkarırsın.'**
  String get prefListsEmptyHeroDesc;

  /// No description provided for @prefListsEmptyDraftCta.
  ///
  /// In tr, this message translates to:
  /// **'Üni taslağı hazırlasın'**
  String get prefListsEmptyDraftCta;

  /// No description provided for @prefListsEmptyBlankCta.
  ///
  /// In tr, this message translates to:
  /// **'Boş liste oluştur'**
  String get prefListsEmptyBlankCta;

  /// No description provided for @prefListOptions.
  ///
  /// In tr, this message translates to:
  /// **'Seçenekler'**
  String get prefListOptions;

  /// No description provided for @prefListSaving.
  ///
  /// In tr, this message translates to:
  /// **'Kaydediliyor'**
  String get prefListSaving;

  /// No description provided for @prefListUndoAction.
  ///
  /// In tr, this message translates to:
  /// **'GERİ AL'**
  String get prefListUndoAction;

  /// No description provided for @prefListOrderUpdated.
  ///
  /// In tr, this message translates to:
  /// **'Sıralama güncellendi'**
  String get prefListOrderUpdated;

  /// No description provided for @prefListItemRemoved.
  ///
  /// In tr, this message translates to:
  /// **'{name} listeden çıkarıldı'**
  String prefListItemRemoved(String name);

  /// No description provided for @prefListSortedByRisk.
  ///
  /// In tr, this message translates to:
  /// **'Zorlayıcıdan güvenliye sıralandı'**
  String get prefListSortedByRisk;

  /// No description provided for @prefListSortWithUni.
  ///
  /// In tr, this message translates to:
  /// **'Üni sıraya dizsin'**
  String get prefListSortWithUni;

  /// No description provided for @prefListPinAction.
  ///
  /// In tr, this message translates to:
  /// **'Ana listem yap'**
  String get prefListPinAction;

  /// No description provided for @prefListPinDesc.
  ///
  /// In tr, this message translates to:
  /// **'Hep en üstte, açılışta ilk bu görünür'**
  String get prefListPinDesc;

  /// No description provided for @prefListUnpinAction.
  ///
  /// In tr, this message translates to:
  /// **'Sabitlemeyi kaldır'**
  String get prefListUnpinAction;

  /// No description provided for @prefListUnpinDesc.
  ///
  /// In tr, this message translates to:
  /// **'En üstte tutulması sona erer'**
  String get prefListUnpinDesc;

  /// No description provided for @prefListShareLink.
  ///
  /// In tr, this message translates to:
  /// **'Bağlantı paylaş'**
  String get prefListShareLink;

  /// No description provided for @prefListShareImage.
  ///
  /// In tr, this message translates to:
  /// **'Görsel oluştur'**
  String get prefListShareImage;

  /// No description provided for @prefListShareImageDesc.
  ///
  /// In tr, this message translates to:
  /// **'Paylaşılabilir özet kartı'**
  String get prefListShareImageDesc;

  /// No description provided for @prefListRenameAction.
  ///
  /// In tr, this message translates to:
  /// **'Yeniden adlandır'**
  String get prefListRenameAction;

  /// No description provided for @prefListRenameDesc.
  ///
  /// In tr, this message translates to:
  /// **'Ad ve açıklamayı düzenle'**
  String get prefListRenameDesc;

  /// No description provided for @prefListRenameTitle.
  ///
  /// In tr, this message translates to:
  /// **'Listeyi yeniden adlandır'**
  String get prefListRenameTitle;

  /// No description provided for @prefListUpdated.
  ///
  /// In tr, this message translates to:
  /// **'Liste güncellendi'**
  String get prefListUpdated;

  /// No description provided for @prefListDuplicateAction.
  ///
  /// In tr, this message translates to:
  /// **'Çoğalt'**
  String get prefListDuplicateAction;

  /// No description provided for @prefListDuplicateDesc.
  ///
  /// In tr, this message translates to:
  /// **'Aynı tercihlerle ikinci bir kopya'**
  String get prefListDuplicateDesc;

  /// No description provided for @prefListDuplicated.
  ///
  /// In tr, this message translates to:
  /// **'Liste çoğaltıldı'**
  String get prefListDuplicated;

  /// No description provided for @prefListCopySuffix.
  ///
  /// In tr, this message translates to:
  /// **'kopya'**
  String get prefListCopySuffix;

  /// No description provided for @prefListDeleteUndoDesc.
  ///
  /// In tr, this message translates to:
  /// **'Geri almak için birkaç saniyen olur'**
  String get prefListDeleteUndoDesc;

  /// No description provided for @prefListDeletedNamed.
  ///
  /// In tr, this message translates to:
  /// **'“{title}” silindi'**
  String prefListDeletedNamed(String title);

  /// No description provided for @prefListRestoreFailed.
  ///
  /// In tr, this message translates to:
  /// **'Liste geri getirilemedi'**
  String get prefListRestoreFailed;

  /// No description provided for @prefListBandSafe.
  ///
  /// In tr, this message translates to:
  /// **'güvenli'**
  String get prefListBandSafe;

  /// No description provided for @prefListBandTarget.
  ///
  /// In tr, this message translates to:
  /// **'hedef'**
  String get prefListBandTarget;

  /// No description provided for @prefListBandReach.
  ///
  /// In tr, this message translates to:
  /// **'zorlayıcı'**
  String get prefListBandReach;

  /// No description provided for @prefListUnrated.
  ///
  /// In tr, this message translates to:
  /// **'+{count} değerlendirilmedi'**
  String prefListUnrated(int count);

  /// No description provided for @prefListBalanceInvite.
  ///
  /// In tr, this message translates to:
  /// **'Puanını hesapla, listeni değerlendireyim'**
  String get prefListBalanceInvite;

  /// No description provided for @prefListShareCardHeading.
  ///
  /// In tr, this message translates to:
  /// **'TERCİH LİSTEM'**
  String get prefListShareCardHeading;

  /// No description provided for @prefListShareCardCount.
  ///
  /// In tr, this message translates to:
  /// **'{filled}/{max} tercih'**
  String prefListShareCardCount(int filled, int max);

  /// No description provided for @prefListShareCardBandSafe.
  ///
  /// In tr, this message translates to:
  /// **'{count} güvenli'**
  String prefListShareCardBandSafe(int count);

  /// No description provided for @prefListShareCardBandReach.
  ///
  /// In tr, this message translates to:
  /// **'{count} zorlayıcı'**
  String prefListShareCardBandReach(int count);

  /// No description provided for @prefListShareCardMore.
  ///
  /// In tr, this message translates to:
  /// **'ve {count} tercih daha…'**
  String prefListShareCardMore(int count);

  /// No description provided for @prefListShareCardText.
  ///
  /// In tr, this message translates to:
  /// **'{title} — {filled}/{max} tercih | ÜniSeç'**
  String prefListShareCardText(String title, int filled, int max);

  /// No description provided for @cmpGroupNumbers.
  ///
  /// In tr, this message translates to:
  /// **'Sayılarla'**
  String get cmpGroupNumbers;

  /// No description provided for @cmpGroupReviews.
  ///
  /// In tr, this message translates to:
  /// **'Öğrenci puanları'**
  String get cmpGroupReviews;

  /// No description provided for @cmpGroupPlacement.
  ///
  /// In tr, this message translates to:
  /// **'Yerleştirme verisi'**
  String get cmpGroupPlacement;

  /// No description provided for @cmpRowDepartments.
  ///
  /// In tr, this message translates to:
  /// **'Bölüm sayısı'**
  String get cmpRowDepartments;

  /// No description provided for @cmpRowUndergrad.
  ///
  /// In tr, this message translates to:
  /// **'Lisans programı'**
  String get cmpRowUndergrad;

  /// No description provided for @cmpRowAssociate.
  ///
  /// In tr, this message translates to:
  /// **'Önlisans programı'**
  String get cmpRowAssociate;

  /// No description provided for @cmpRowAvgBase.
  ///
  /// In tr, this message translates to:
  /// **'Ortalama taban puanı'**
  String get cmpRowAvgBase;

  /// No description provided for @cmpRowQuota.
  ///
  /// In tr, this message translates to:
  /// **'Kontenjan'**
  String get cmpRowQuota;

  /// No description provided for @cmpRowFillRate.
  ///
  /// In tr, this message translates to:
  /// **'Doluluk'**
  String get cmpRowFillRate;

  /// No description provided for @cmpRowPlaces.
  ///
  /// In tr, this message translates to:
  /// **'Çevresindeki mekân'**
  String get cmpRowPlaces;

  /// No description provided for @cmpRowType.
  ///
  /// In tr, this message translates to:
  /// **'Tür'**
  String get cmpRowType;

  /// No description provided for @cmpRowFounded.
  ///
  /// In tr, this message translates to:
  /// **'Kuruluş yılı'**
  String get cmpRowFounded;

  /// No description provided for @cmpRowRating.
  ///
  /// In tr, this message translates to:
  /// **'Öğrenci puanı'**
  String get cmpRowRating;

  /// No description provided for @cmpRowReviews.
  ///
  /// In tr, this message translates to:
  /// **'Yorum sayısı'**
  String get cmpRowReviews;

  /// No description provided for @cmpRowBaseScore.
  ///
  /// In tr, this message translates to:
  /// **'Taban puanı'**
  String get cmpRowBaseScore;

  /// No description provided for @cmpRowRanking.
  ///
  /// In tr, this message translates to:
  /// **'Başarı sırası'**
  String get cmpRowRanking;

  /// No description provided for @cmpRowScoreType.
  ///
  /// In tr, this message translates to:
  /// **'Puan türü'**
  String get cmpRowScoreType;

  /// No description provided for @cmpRowDuration.
  ///
  /// In tr, this message translates to:
  /// **'Süre'**
  String get cmpRowDuration;

  /// No description provided for @cmpRowUniCount.
  ///
  /// In tr, this message translates to:
  /// **'Üniversite sayısı'**
  String get cmpRowUniCount;

  /// No description provided for @cmpRowStateUni.
  ///
  /// In tr, this message translates to:
  /// **'Devlet üniversitesi'**
  String get cmpRowStateUni;

  /// No description provided for @cmpRowFoundationUni.
  ///
  /// In tr, this message translates to:
  /// **'Vakıf üniversitesi'**
  String get cmpRowFoundationUni;

  /// No description provided for @cmpRowDensity.
  ///
  /// In tr, this message translates to:
  /// **'Üniversite yoğunluğu'**
  String get cmpRowDensity;

  /// No description provided for @cmpRowPopulation.
  ///
  /// In tr, this message translates to:
  /// **'Nüfus'**
  String get cmpRowPopulation;

  /// No description provided for @cmpRowAvgReviews.
  ///
  /// In tr, this message translates to:
  /// **'Üni başına yorum'**
  String get cmpRowAvgReviews;

  /// No description provided for @cmpHintLastYear.
  ///
  /// In tr, this message translates to:
  /// **'2025 verisi'**
  String get cmpHintLastYear;

  /// No description provided for @cmpHintPerMillion.
  ///
  /// In tr, this message translates to:
  /// **'milyon kişi başına'**
  String get cmpHintPerMillion;

  /// No description provided for @cmpReviewsEmpty.
  ///
  /// In tr, this message translates to:
  /// **'Bu ikisi için henüz öğrenci puanı yok. Yorum geldikçe burası dolacak.'**
  String get cmpReviewsEmpty;

  /// No description provided for @cmpNoRows.
  ///
  /// In tr, this message translates to:
  /// **'Karşılaştırılacak ortak veri bulunamadı.'**
  String get cmpNoRows;

  /// No description provided for @cmpVerdictAhead.
  ///
  /// In tr, this message translates to:
  /// **'{name} {count} ölçütte önde'**
  String cmpVerdictAhead(String name, String count);

  /// No description provided for @cmpVerdictTiedOnly.
  ///
  /// In tr, this message translates to:
  /// **'{count} ölçütte başa baş'**
  String cmpVerdictTiedOnly(String count);

  /// No description provided for @cmpVerdictTiedSuffix.
  ///
  /// In tr, this message translates to:
  /// **'{count} başa baş'**
  String cmpVerdictTiedSuffix(String count);

  /// No description provided for @cmpChangeSide.
  ///
  /// In tr, this message translates to:
  /// **'Değiştir'**
  String get cmpChangeSide;

  /// No description provided for @cmpSwap.
  ///
  /// In tr, this message translates to:
  /// **'Yer değiştir'**
  String get cmpSwap;

  /// No description provided for @cmpChartsTitle.
  ///
  /// In tr, this message translates to:
  /// **'Grafikler'**
  String get cmpChartsTitle;

  /// No description provided for @cmpHighlightsTitle.
  ///
  /// In tr, this message translates to:
  /// **'En büyük farklar'**
  String get cmpHighlightsTitle;

  /// No description provided for @cmpMoreTitle.
  ///
  /// In tr, this message translates to:
  /// **'Daha fazlası'**
  String get cmpMoreTitle;

  /// No description provided for @cmpChartsDesc.
  ///
  /// In tr, this message translates to:
  /// **'Radar, ısı haritası, trend ve saçılım'**
  String get cmpChartsDesc;

  /// No description provided for @cmpChartsOpen.
  ///
  /// In tr, this message translates to:
  /// **'Grafikleri gör'**
  String get cmpChartsOpen;

  /// No description provided for @cmpPersonalTitle.
  ///
  /// In tr, this message translates to:
  /// **'Senin için'**
  String get cmpPersonalTitle;

  /// No description provided for @cmpPersonalBody.
  ///
  /// In tr, this message translates to:
  /// **'{a} içinde {countA}, {b} içinde {countB} bölüm senin puanına uyuyor.'**
  String cmpPersonalBody(String a, String countA, String b, String countB);

  /// No description provided for @cmpPersonalTop.
  ///
  /// In tr, this message translates to:
  /// **'{name} içinde en yükseği: {dept}'**
  String cmpPersonalTop(String name, String dept);

  /// No description provided for @cmpPersonalNoProfile.
  ///
  /// In tr, this message translates to:
  /// **'Puanını hesapla, hangisinde kaç bölümün sana uyduğunu söyleyeyim.'**
  String get cmpPersonalNoProfile;

  /// No description provided for @cmpPersonalNone.
  ///
  /// In tr, this message translates to:
  /// **'Bu iki üniversitede puanına uyan bölüm bulamadım.'**
  String get cmpPersonalNone;

  /// No description provided for @cmpPersonalCta.
  ///
  /// In tr, this message translates to:
  /// **'Puanını hesapla'**
  String get cmpPersonalCta;

  /// No description provided for @cmpAddToList.
  ///
  /// In tr, this message translates to:
  /// **'Puanına uyanları listeme ekle'**
  String get cmpAddToList;

  /// No description provided for @cmpAddSheetTitle.
  ///
  /// In tr, this message translates to:
  /// **'Listene eklenecekler'**
  String get cmpAddSheetTitle;

  /// No description provided for @cmpAddSheetDesc.
  ///
  /// In tr, this message translates to:
  /// **'Puanına uyan programları seçtim. İstemediğini çıkar, gerisini bir kerede ekleyeyim.'**
  String get cmpAddSheetDesc;

  /// No description provided for @cmpAddSelectedCta.
  ///
  /// In tr, this message translates to:
  /// **'{count} tercihi ekle'**
  String cmpAddSelectedCta(String count);

  /// No description provided for @cmpAddNoList.
  ///
  /// In tr, this message translates to:
  /// **'Önce bir tercih listesi oluştur.'**
  String get cmpAddNoList;

  /// No description provided for @cmpAddedToList.
  ///
  /// In tr, this message translates to:
  /// **'{count} tercih {title} listesine eklendi'**
  String cmpAddedToList(String count, String title);

  /// No description provided for @cmpHubRecentTitle.
  ///
  /// In tr, this message translates to:
  /// **'SON KARŞILAŞTIRMALARIN'**
  String get cmpHubRecentTitle;

  /// No description provided for @cmpHubRecentEmpty.
  ///
  /// In tr, this message translates to:
  /// **'İlk karşılaştırmanı yaptığında burada duracak.'**
  String get cmpHubRecentEmpty;

  /// No description provided for @cmpHubSeeAll.
  ///
  /// In tr, this message translates to:
  /// **'Tümü'**
  String get cmpHubSeeAll;

  /// No description provided for @cmpYears.
  ///
  /// In tr, this message translates to:
  /// **'{count} yıl'**
  String cmpYears(String count);

  /// No description provided for @cmpCityPlate.
  ///
  /// In tr, this message translates to:
  /// **'{plate} plaka'**
  String cmpCityPlate(String plate);
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
