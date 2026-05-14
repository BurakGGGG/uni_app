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

  /// No description provided for @authSignIn.
  ///
  /// In tr, this message translates to:
  /// **'Giriş Yap'**
  String get authSignIn;

  /// No description provided for @authSignUp.
  ///
  /// In tr, this message translates to:
  /// **'Kayıt Ol'**
  String get authSignUp;

  /// No description provided for @authEmailLabel.
  ///
  /// In tr, this message translates to:
  /// **'E-posta adresi'**
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
  /// **'Şifremi Unuttum'**
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
  /// **'Geçerli bir e-posta adresi girin'**
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
  /// **'Profili Düzenle'**
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
