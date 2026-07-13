// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get comparisonHubTitle => 'Karşılaştır';

  @override
  String get comparisonUniversity => 'Üniversite Karşılaştır';

  @override
  String get comparisonUniversityDesc => 'İki üniversiteyi yan yana kıyasla';

  @override
  String get comparisonDepartment => 'Bölüm Karşılaştır';

  @override
  String get comparisonDepartmentDesc =>
      'Aynı bölümü farklı üniversitelerde kıyasla';

  @override
  String get comparisonCity => 'Şehir Karşılaştır';

  @override
  String get comparisonCityDesc => 'İki şehrin üniversite ekosistemini kıyasla';

  @override
  String get selectUniversityA => 'Üniversite A';

  @override
  String get selectUniversityB => 'Üniversite B';

  @override
  String get selectDepartmentA => 'Bölüm A';

  @override
  String get selectDepartmentB => 'Bölüm B';

  @override
  String get selectCityA => 'Şehir A';

  @override
  String get selectCityB => 'Şehir B';

  @override
  String get swap => 'Yer Değiştir';

  @override
  String get share => 'Paylaş';

  @override
  String get reset => 'Sıfırla';

  @override
  String get retry => 'Tekrar Dene';

  @override
  String get tabGeneral => 'Genel';

  @override
  String get tabCategories => 'Kategoriler';

  @override
  String get tabChart => 'Grafik';

  @override
  String get tabStats => 'İstatistik';

  @override
  String emptyStateTitle(String entityType) {
    return 'İki $entityType seç';
  }

  @override
  String get loadingComparison => 'Karşılaştırma yükleniyor…';

  @override
  String get errorComparison => 'Karşılaştırma yüklenirken bir hata oluştu';

  @override
  String get aiSummaryTitle => 'AI Analizi';

  @override
  String get aiSummaryProRequired =>
      'AI Analizi Pro pakette aktif. Pro\'ya geçerek detaylı özeti açabilirsin.';

  @override
  String aiSummaryLimitReached(int limit) {
    return 'Günlük $limit AI özet hakkın doldu, yarın tekrar dene.';
  }

  @override
  String get aiSummaryActive => 'Pro analizi aktif';

  @override
  String get aiSummaryRegenerate => 'Yeniden Üret';

  @override
  String get viewProPlans => 'Pro Paketleri İncele';

  @override
  String get proChartLockedSubtitle => 'Bu grafik Pro paketinde.';

  @override
  String get watchAdUnlockOneHour => 'Video İzle ve 1 Saat Ücretsiz Aç';

  @override
  String get adLoading => 'Reklam yükleniyor, lütfen bekleyin…';

  @override
  String get proChartsUnlockedOneHour =>
      'Pro grafikler ve özellikler 1 saatliğine başarıyla açıldı!';

  @override
  String get adFailedRetry =>
      'Reklam yüklenemedi veya tamamlanmadı. Lütfen tekrar deneyin.';

  @override
  String get chartHeatmapTitle => 'Kategori Karşılaştırması';

  @override
  String get chartTrendTitle => '6 Aylık Puan Trendi';

  @override
  String get chartScatterTitle => 'Taban Puanı × Sıralama';

  @override
  String get chartScatterXAxis => 'Taban puanı';

  @override
  String get chartScatterYAxis => 'Sıralama';

  @override
  String get chartScaleLow => 'Düşük';

  @override
  String get chartScaleHigh => 'Yüksek';

  @override
  String get chartNoData => 'Veri yok';

  @override
  String get chartDepartmentLabel => 'Bölüm';

  @override
  String tempProBadge(int minutes) {
    return 'Pro aktif · $minutes dk';
  }

  @override
  String get watchAdToContinue => 'Reklamı İzle ve Devam Et';

  @override
  String get upgradePlus => 'Plus\'a Geç — Sınırsız';

  @override
  String get cancelForNow => 'Şimdilik Vazgeç';

  @override
  String get dailyLimitReached => 'Günlük karşılaştırma hakkın doldu';

  @override
  String get comparisonStarted => 'Karşılaştırma başladı';

  @override
  String get scoreType => 'Puan Türü';

  @override
  String get baseScore => 'Taban Puan';

  @override
  String get ranking => 'Sıralama';

  @override
  String get quota => 'Kontenjan';

  @override
  String get fillRate => 'Doluluk Oranı';

  @override
  String get duration => 'Süre';

  @override
  String get language => 'Dil';

  @override
  String get type => 'Tür';

  @override
  String get categoryRating => 'Kategori Puanı';

  @override
  String get reviewCount => 'Yorum Sayısı';

  @override
  String get averageRating => 'Ortalama Puan';

  @override
  String get establishedYear => 'Kuruluş Yılı';

  @override
  String get stateUniversity => 'Devlet';

  @override
  String get foundationUniversity => 'Vakıf';

  @override
  String get winner => 'Kazanan';

  @override
  String get tie => 'Berabere';

  @override
  String get noEnoughReviews => 'Yeterli yorum yok';

  @override
  String get trendInsufficient => 'Trend için yeterli yorum yok';

  @override
  String get offline => 'İnternet bağlantısı yok';

  @override
  String get offlineDescription =>
      'Karşılaştırma yapmak için internete bağlan.';

  @override
  String shareSubject(String uniA, String uniB) {
    return '$uniA vs $uniB — Karşılaştırma';
  }

  @override
  String get authSignIn => 'Giriş yap';

  @override
  String get authSignUp => 'Kayıt ol';

  @override
  String get authEmailLabel => 'E-posta';

  @override
  String get authEmailHint => 'ornek@universite.edu.tr';

  @override
  String get authPasswordLabel => 'Şifre';

  @override
  String get authPasswordHint => 'En az 6 karakter';

  @override
  String get authForgotPassword => 'Şifremi unuttum';

  @override
  String get authGoogleContinue => 'Google ile Giriş Yap';

  @override
  String get authNoAccount => 'Hesabın yok mu? ';

  @override
  String get authHaveAccount => 'Zaten hesabın var mı? ';

  @override
  String get authShowPassword => 'Şifreyi göster';

  @override
  String get authHidePassword => 'Şifreyi gizle';

  @override
  String get authPasswordRequired => 'Şifre gerekli';

  @override
  String get authEmailRequired => 'E-posta adresi gerekli';

  @override
  String get authEmailInvalid => 'Geçerli bir e-posta gir';

  @override
  String get authContinueWithAccount => 'Hesabına giriş yaparak devam et';

  @override
  String get authOrDivider => 'veya';

  @override
  String get authGuestContinue => 'Misafir olarak devam et';

  @override
  String get authLoggingIn => 'Giriş yapılıyor...';

  @override
  String get authPleaseWait => 'Lütfen bekleyin';

  @override
  String get authResetPasswordTitle => 'Şifre Sıfırlama';

  @override
  String get authResetPasswordDesc =>
      'E-posta adresini gir, şifre sıfırlama linki gönderelim.';

  @override
  String get authResetPasswordSend => 'Sıfırlama Linki Gönder';

  @override
  String get authResetPasswordSent => 'Şifre sıfırlama linki gönderildi!';

  @override
  String get authRegisterTitle => 'Yeni hesap oluştur ve keşfetmeye başla';

  @override
  String get authFullName => 'Ad Soyad';

  @override
  String get authFullNameRequired => 'Ad Soyad gerekli';

  @override
  String get authFullNameTooShort => 'Ad Soyad en az 2 karakter olmalı';

  @override
  String get authPasswordConfirm => 'Şifre Tekrar';

  @override
  String get authPasswordConfirmRequired => 'Şifre tekrarı gerekli';

  @override
  String get authPasswordMismatch => 'Şifreler eşleşmiyor';

  @override
  String get authPasswordMin8 => 'Şifre en az 8 karakter olmalı';

  @override
  String get authPasswordUppercase => 'Şifre en az bir büyük harf içermeli';

  @override
  String get authPasswordDigit => 'Şifre en az bir rakam içermeli';

  @override
  String get authCreatingAccount => 'Hesap oluşturuluyor...';

  @override
  String get authEduDetected =>
      'edu.tr hesabı algılandı! Doğrulama sonrası yorum yazabileceksin.';

  @override
  String get authEduVerifyTitle => 'edu.tr Doğrulama';

  @override
  String get authEduVerifyLinkSent =>
      'Doğrulama linki e-posta adresine gönderildi:';

  @override
  String get authEduVerifyAfter =>
      'E-postanı doğruladıktan sonra yorum yazabileceksin.';

  @override
  String get authOk => 'Tamam';

  @override
  String get authGoBack => 'Geri dön';

  @override
  String get authVerifyEmailTitle => 'E-postanı doğrula';

  @override
  String authVerifyEmailBody(String email) {
    return '$email adresine doğrulama linki gönderdik.';
  }

  @override
  String get profileTitle => 'Hesabım';

  @override
  String get profileEditProfile => 'Profili düzenle';

  @override
  String get profileEditSubtitle => 'Fotoğraf, isim, üniversite';

  @override
  String get profileAccount => 'Hesap';

  @override
  String get profileSettings => 'Ayarlar';

  @override
  String get profileNotifications => 'Bildirimler';

  @override
  String get profileNotificationsSubtitle => 'Yorum, favori bildirimleri';

  @override
  String get profileSecurity => 'Güvenlik';

  @override
  String get profileSecuritySubtitle => 'Şifre değiştir';

  @override
  String get profilePasswordChanged => 'Şifre başarıyla değiştirildi';

  @override
  String get profileApp => 'Uygulama';

  @override
  String get profileAbout => 'Hakkında';

  @override
  String get profileRateApp => 'Uygulamayı Puanla';

  @override
  String get profileRateAppSubtitle => 'Google Play\'de değerlendir';

  @override
  String get profileShareApp => 'Arkadaşına Öner';

  @override
  String get profileShareAppSubtitle => 'Linki paylaş';

  @override
  String get profileShareText =>
      'ÜniSeç - Hayalindeki üniversiteyi keşfet! 🎓\nhttps://play.google.com/store/apps/details?id=com.unisec.app';

  @override
  String get profilePrivacyPolicy => 'Gizlilik Politikası';

  @override
  String get privacyPolicyComingSoon =>
      'Gizlilik politikası yakında yayınlanacak';

  @override
  String get profileSignOut => 'Çıkış Yap';

  @override
  String get profileSignOutConfirm =>
      'Hesabınızdan çıkış yapmak istediğinize emin misiniz?';

  @override
  String get profileCancel => 'İptal';

  @override
  String get profileMembershipPlan => 'Üyelik Planı';

  @override
  String profileMembershipUsing(String plan) {
    return '$plan planını kullanıyorsun';
  }

  @override
  String get profilePlanDetails => 'Plan Detayları';

  @override
  String get profileViewPlans => 'Planları Gör ve Yükselt';

  @override
  String get profileGuestWelcome => 'Hoş Geldin!';

  @override
  String get profileGuestSubtitle =>
      'Yorum yapmak ve favori eklemek için\ngiriş yapman gerekiyor.';

  @override
  String get profileVerifiedStudent => 'Doğrulanmış Öğrenci';

  @override
  String get profileVerificationPending => 'Doğrulama Bekleniyor';

  @override
  String get profileVerified => 'Hesabınız doğrulandı!';

  @override
  String get profileNotVerified =>
      'Henüz doğrulanmamış. Lütfen mailinize gelen linke tıklayın.';

  @override
  String get profileRefresh => 'Yenile';

  @override
  String get profileStatReview => 'Yorum';

  @override
  String get profileStatFavorite => 'Favori';

  @override
  String get profileStatMembership => 'Üyelik';

  @override
  String profileStatDays(int days) {
    return '$days gün';
  }

  @override
  String get profileAboutDescription =>
      'ÜniSeç, Türkiye\'deki üniversiteleri keşfetmeni, karşılaştırmanı ve deneyimlerini paylaşmanı sağlayan bir mobil uygulamadır.';

  @override
  String get profileAboutCopyright => '© 2026 ÜniSeç Ekibi';

  @override
  String get profileUser => 'Kullanıcı';

  @override
  String get editProfileTitle => 'Profili Düzenle';

  @override
  String get editProfileCamera => 'Kamera';

  @override
  String get editProfileGallery => 'Galeri';

  @override
  String get editProfileFullName => 'Ad Soyad';

  @override
  String get editProfileFullNameRequired => 'Ad Soyad gerekli';

  @override
  String get editProfileUniversity => 'Üniversite';

  @override
  String editProfileUniversityError(String error) {
    return 'Üniversiteler yüklenemedi: $error';
  }

  @override
  String get editProfileDepartment => 'Bölüm';

  @override
  String get editProfileDepartmentHint => 'Örn: Bilgisayar Mühendisliği';

  @override
  String get editProfileBio => 'Hakkımda (Opsiyonel)';

  @override
  String get editProfileBioHint => 'Kendinden kısaca bahset...';

  @override
  String get editProfileBioProfanity => 'Uygunsuz içerik tespit edildi';

  @override
  String get editProfileGrade => 'Sınıf';

  @override
  String get editProfileSave => 'Kaydet';

  @override
  String get editProfileSaving => 'Kaydediliyor...';

  @override
  String get editProfileSuccess => 'Profil başarıyla güncellendi';

  @override
  String get editProfileError => 'Profil güncellenirken hata oluştu';

  @override
  String errorGeneral(String error) {
    return 'Hata: $error';
  }

  @override
  String get universityNotFound => 'Üniversite bulunamadı';

  @override
  String get errorDepartmentsLoad => 'Bölümler yüklenirken hata oluştu.';

  @override
  String get noDepartmentsFound => 'Bölüm bulunamadı.';

  @override
  String get errorPlacesLoad => 'Mekanlar yüklenirken hata oluştu.';

  @override
  String get noPlacesFound => 'Mekan bulunamadı.';

  @override
  String get errorReviewsLoad => 'Yorumlar yüklenirken hata oluştu.';

  @override
  String get reviewLoginRequired =>
      'Yorum yazabilmek için önce hesabınıza giriş yapmanız gerekiyor.';

  @override
  String get reviewEduRequiredTitle => 'Doğrulama Gerekli';

  @override
  String get reviewEduRequiredDesc =>
      'Sadece onaylı üniversite öğrencileri değerlendirme yapabilir (.edu.tr).';

  @override
  String get reviewAnonymousStudent => 'Anonim Öğrenci';

  @override
  String get reviewLoading => 'Yükleniyor...';

  @override
  String get reviewUniversityFallback => 'Üniversite';

  @override
  String get reviewDepartmentFallback => 'Bölüm';

  @override
  String get reviewPlaceFallback => 'Mekan';

  @override
  String get reviewUniversityReview => 'Üniversite Yorumu';

  @override
  String get reviewDepartmentReview => 'Bölüm Yorumu';

  @override
  String get reviewPlaceReview => 'Mekan Yorumu';

  @override
  String get reviewPendingTitle => 'Yayınlanmadı';

  @override
  String get reviewPendingDesc =>
      'Yorumun moderasyon aşamasında. Uygunsuz içerik tespit edildiyse düzenleyerek tekrar gönderebilirsin.';

  @override
  String get reviewShowLess => 'Daha az göster';

  @override
  String get reviewReadMore => 'Devamını oku';

  @override
  String get recommendIntroTitle => 'Tercih Asistanı';

  @override
  String get recommendIntroSubtitle =>
      'Sana birkaç kısa soru soracağım,\nhayalindeki üniversiteyi birlikte bulalım.';

  @override
  String get recommendIntroDuration => '~4 dakika';

  @override
  String get recommendIntroMedals => 'Altın / Gümüş / Bronz';

  @override
  String get recommendIntroSuggestions => '8 öneri';

  @override
  String get recommendIntroBetaTitle => 'Beta — Geliştirme Aşaması';

  @override
  String get recommendIntroBetaDesc =>
      'Bu asistan henüz geliştirilme aşamasında. Öneriler kesin tercih kararı için değil, yönlendirme amaçlıdır. Final tercihinde mutlaka kendi araştırmanı yap.';

  @override
  String get recommendIntroStart => 'Başlayalım';

  @override
  String get recommendIntroDurationNote => 'Yaklaşık 4 dakika sürer';

  @override
  String get aiSummaryLimitReachedSimple =>
      'Günlük AI özet hakkın doldu, yarın tekrar dene.';

  @override
  String get commonRetry => 'Tekrar dene';

  @override
  String get commonError => 'Bir hata oluştu';

  @override
  String get paywallPerMonthSuffix => '/ay';

  @override
  String get paywallPerYearSuffix => '/yıl';

  @override
  String paywallSaveBadge(int percent) {
    return '%$percent TASARRUF';
  }

  @override
  String paywallYearlySavingsSub(int percent) {
    return 'Aylığa göre %$percent tasarruf';
  }

  @override
  String paywallFreeTrialNote(String duration) {
    return 'İlk $duration ücretsiz, sonra otomatik yenilenir';
  }

  @override
  String get paywallUnitDay => 'gün';

  @override
  String get paywallUnitWeek => 'hafta';

  @override
  String get paywallUnitMonth => 'ay';

  @override
  String get paywallUnitYear => 'yıl';

  @override
  String get commonLoading => 'Yükleniyor...';

  @override
  String get commonCancel => 'İptal';

  @override
  String get commonSave => 'Kaydet';

  @override
  String get commonDelete => 'Sil';

  @override
  String get commonClose => 'Kapat';

  @override
  String get commonShare => 'Paylaş';

  @override
  String get commonEdit => 'Düzenle';

  @override
  String get commonContinue => 'Devam et';

  @override
  String get authSignOut => 'Çıkış yap';

  @override
  String get authPasswordTooShort => 'Şifre en az 6 karakter olmalı';

  @override
  String get homeTabHome => 'Ana Sayfa';

  @override
  String get homeTabExplore => 'Keşfet';

  @override
  String get homeTabCompare => 'Karşılaştır';

  @override
  String get homeTabFavorites => 'Listelerim';

  @override
  String get homeTabProfile => 'Profil';

  @override
  String get comparisonTitleUni => 'Üniversite karşılaştır';

  @override
  String get comparisonTitleDept => 'Bölüm karşılaştır';

  @override
  String get comparisonTitleCity => 'Şehir karşılaştır';

  @override
  String get comparisonNoteAdd => 'Not ekle';

  @override
  String get comparisonNoteEmpty => 'Henüz notun yok';

  @override
  String get comparisonNoteMaxLength => 'En fazla 500 karakter';

  @override
  String get comparisonNotesLoadError => 'Notlar yüklenemedi.';

  @override
  String get comparisonNoteSaved => 'Not kaydedildi ✍️';

  @override
  String get comparisonNoteUpdated => 'Not güncellendi ✅';

  @override
  String get comparisonNoteDeleteTitle => 'Notu Sil';

  @override
  String get comparisonNoteDeleteConfirm =>
      'Bu not kalıcı olarak silinecek. Devam edilsin mi?';

  @override
  String get comparisonNoteDeleted => 'Not silindi';

  @override
  String get comparisonNoteEmptyTitle => 'Henüz not yok';

  @override
  String get comparisonNoteEmptyDesc =>
      'Bu karşılaştırma hakkındaki düşüncelerini kaydet';

  @override
  String get comparisonProUpsell =>
      '3. üniversite eklemek için Pro\'ya yükselt';

  @override
  String get paywallContinueFree => 'Ücretsiz devam et';

  @override
  String paywallSavePercent(int percent) {
    return 'TASARRUF $percent%';
  }

  @override
  String get paywallMonthly => 'Aylık';

  @override
  String get paywallYearly => 'Yıllık';

  @override
  String get paywallRestore => 'Satın alımları geri yükle';

  @override
  String get paywallPackageInfoError => 'Paket bilgisi alınamadı. Tekrar dene.';

  @override
  String get paywallPurchaseSuccess =>
      'Satın alma başarılı. Planın güncelleniyor.';

  @override
  String get paywallPurchaseIncomplete => 'Satın alma tamamlanmadı.';

  @override
  String paywallRestoreResult(String tier) {
    return 'Geri yükleme sonucu: $tier';
  }

  @override
  String get paywallOfferingsLoadError =>
      'Paketler yüklenirken bir sorun oluştu. Lütfen tekrar dene.';

  @override
  String get paywallSecurityNote => 'Güvenli ödeme • İstediğinde iptal';

  @override
  String get paywallPurchaseSuccessTitle => 'Satın alma başarılı!';

  @override
  String get paywallPurchaseSuccessDesc =>
      'Planın aktif edildi. Tüm özelliklerin keyfini çıkar.';

  @override
  String get paywallGreat => 'Harika';

  @override
  String get reviewWrite => 'Yorum yaz';

  @override
  String get reviewAnonymous => 'Anonim';

  @override
  String get reviewRatingRequired => 'Puan vermeden yorum gönderilemez';

  @override
  String get profilePremium => 'Premium üyelik';

  @override
  String get profileLanguage => 'Dil';

  @override
  String get profileDeleteAccount => 'Hesabımı sil';

  @override
  String get deleteAccountTitle => 'Hesabı kalıcı olarak sil';

  @override
  String get deleteAccountDescription =>
      'Profiliniz, favorileriniz, tercih listeleriniz, yorumlarınız, önerileriniz ve hesabınızla ilişkili kişisel veriler silinecektir.';

  @override
  String get deleteAccountWarning =>
      'Bu işlem geri alınamaz. Aktif mağaza aboneliğiniz varsa aboneliği ayrıca Google Play üzerinden iptal etmeniz gerekir.';

  @override
  String get deleteAccountPasswordNote =>
      'Devam etmek için mevcut şifrenizle kimliğinizi doğrulayın.';

  @override
  String get deleteAccountGoogleNote =>
      'Devam ettiğinizde Google hesabınızla yeniden doğrulama istenecektir.';

  @override
  String get deleteAccountPasswordLabel => 'Mevcut şifre';

  @override
  String get deleteAccountPasswordRequired => 'Mevcut şifrenizi girin';

  @override
  String get deleteAccountConfirmationWord => 'SİL';

  @override
  String deleteAccountConfirmationLabel(String word) {
    return 'Onaylamak için $word yazın';
  }

  @override
  String deleteAccountConfirmationMismatch(String word) {
    return 'Devam etmek için $word yazın';
  }

  @override
  String get deleteAccountConfirmButton => 'Hesabı sil';

  @override
  String get deleteAccountProgress => 'Hesabınız ve verileriniz siliniyor...';

  @override
  String get deleteAccountSuccess =>
      'Hesabınız ve ilişkili verileriniz silindi.';

  @override
  String get favoritesEmpty => 'Favori yok';

  @override
  String get favoritesEmptyHint =>
      'Beğendiğin üniversiteleri buradan takip et.';

  @override
  String get profileTheme => 'Tema';

  @override
  String get themeSystem => 'Sistem';

  @override
  String get themeLight => 'Açık';

  @override
  String get themeDark => 'Koyu';

  @override
  String get themeSelection => 'Tema Seçimi';

  @override
  String get languageSelection => 'Dil Seçimi';

  @override
  String get turkish => 'Türkçe';

  @override
  String get english => 'English';

  @override
  String get homeGreeting => 'Merhaba! 👋';

  @override
  String get homePopularUniversities => 'Popüler Üniversiteler';

  @override
  String get homeSeeAll => 'Tümünü Gör';

  @override
  String get homeCities => 'Şehirler';

  @override
  String get homeCitiesLoadError => 'Şehirler yüklenemedi';

  @override
  String get homeRecentReviews => 'Son Yorumlar';

  @override
  String get homeNoReviews => 'Henüz yorum yok';

  @override
  String get homeFirstReview => 'İlk yorumu yazan siz olun!';

  @override
  String get homeAssistantTitle => 'Tercih Asistanı';

  @override
  String get homeAssistantSubtitle =>
      'Hayalindeki üniversiteyi\nbirlikte bulalım!';

  @override
  String get homeStart => 'Başla';

  @override
  String get exploreTitle => 'Keşfet';

  @override
  String get exploreSubtitle =>
      'Üniversiteleri keşfet, filtrele ve karşılaştır';

  @override
  String get exploreSearchHint => 'Üniversite ara...';

  @override
  String get exploreTypeState => 'Devlet';

  @override
  String get exploreTypeFoundation => 'Vakıf';

  @override
  String get exploreFilters => 'Filtreler';

  @override
  String get exploreClear => 'Temizle';

  @override
  String get exploreUniType => 'Üniversite Türü';

  @override
  String get exploreCities => 'Şehirler';

  @override
  String get exploreCitiesError => 'Şehirler yüklenemedi';

  @override
  String get exploreNoResults => 'Sonuç bulunamadı';

  @override
  String get exploreNoResultsSub =>
      'Filtrelerinizi değiştirerek tekrar deneyin.';

  @override
  String get searchGlobalHint => 'Üniversite, bölüm veya şehir ara...';

  @override
  String get showcaseSearchTitle => 'Hızlı Arama';

  @override
  String get showcaseSearchDescription =>
      'Üniversite, bölüm veya şehir ara — istediğin her şeyi anında bul.';

  @override
  String get searchError => 'Arama yapılırken bir hata oluştu.';

  @override
  String get searchNoResults => 'Sonuç bulunamadı';

  @override
  String get searchRecentTitle => 'Son Aramalar';

  @override
  String get searchRecentClear => 'Temizle';

  @override
  String searchNoResultsSub(Object query) {
    return '\"$query\" aramasına uygun üniversite yok.';
  }

  @override
  String get searchDidYouMean => 'Bunu mu demek istedin?';

  @override
  String get searchCampus => 'Kampüslü';

  @override
  String searchEst(Object year) {
    return 'Kuruluş: $year';
  }

  @override
  String get homeHeroBannerTitle => 'Puanını Hesapla,\nHedefini Belirle!';

  @override
  String get reviewSortLabel => 'Sırala:';

  @override
  String get reviewSortNewest => 'En Yeni';

  @override
  String get reviewSortMostLiked => 'En Beğenilen';

  @override
  String get uniDetailDepartments => 'Bölümler';

  @override
  String uniDetailDepartmentsSubtitle(int count) {
    return '$count bölüm — En çok aranan 3 tanesi';
  }

  @override
  String get uniDetailSeeAllDepartments => 'Tüm bölümleri gör';

  @override
  String get uniDetailReviews => 'Yorumlar';

  @override
  String uniDetailReviewsSubtitle(int count) {
    return '$count yorum — En çok beğenilen 3 tanesi';
  }

  @override
  String get uniDetailNoReviews => 'Henüz yorum yok';

  @override
  String get uniDetailSeeAllReviews => 'Tüm yorumları gör';

  @override
  String get googleReviewsTitle => 'Google Yorumları';

  @override
  String get googleReviewsTileSubtitle =>
      'Google Haritalar kullanıcılarının değerlendirmeleri';

  @override
  String googleReviewsCount(int count) {
    return '$count değerlendirme';
  }

  @override
  String get googleReviewsAttribution =>
      'Yorumlar Google tarafından sağlanmaktadır';

  @override
  String get reviewBadgeOwnUniversity => 'Bu üniversitenin öğrencisi';

  @override
  String get reviewBadgeOtherUniversity => 'Başka üniversiteden öğrenci';

  @override
  String get reviewPromptTitleOwn => 'Üniversiteni değerlendir';

  @override
  String get reviewPromptTitleOther => 'Bu üniversiteyi değerlendir';

  @override
  String reviewPromptBodyOwn(String uniName) {
    return '$uniName deneyimini paylaş, senden sonraki öğrencilere yol göster.';
  }

  @override
  String reviewPromptBodyOther(String uniName) {
    return '$uniName hakkında bilgin varsa deneyimini paylaşarak tercih yapacak öğrencilere yardımcı olabilirsin.';
  }

  @override
  String get reviewPromptCta => 'Yorum yaz';

  @override
  String get reviewPromptLater => 'Daha sonra';

  @override
  String get reviewPromptNever => 'Bir daha gösterme';

  @override
  String get badgeFirstReview => 'İlk Yorum';

  @override
  String get badgeFirstReviewDesc => 'İlk yorumunu yayınladın';

  @override
  String get badgeDetailedReviewer => 'Detaylı Yorumcu';

  @override
  String get badgeDetailedReviewerDesc => '3 veya daha fazla yorum yayınladın';

  @override
  String get badgeHelpful => 'Faydalı';

  @override
  String get badgeHelpfulDesc => 'Yorumların toplam 10 beğeni aldı';

  @override
  String get uniDetailPlaces => 'Mekanlar';

  @override
  String uniDetailPlacesSubtitle(int count) {
    return '$count mekan';
  }

  @override
  String get uniDetailPlacesComingSoon => 'Yakında sizlerin önerileriyle!';

  @override
  String get uniDetailSeeAllPlaces => 'Tüm mekanları gör';

  @override
  String get uniDetailPlacesLoading => 'Yükleniyor...';

  @override
  String get uniDetailPlacesLoadError => 'Yüklenemedi';

  @override
  String get uniDetailOpenMap => 'Haritada Aç';

  @override
  String get uniDetailGallery => 'Galeri';

  @override
  String get uniDetailCategoryRatings => 'Kategori Puanları';

  @override
  String get uniDetailRateUniversity => 'Üniversiteyi Değerlendir';

  @override
  String get uniDetailPlacesEmptyTitle => 'Kafeler Yakında!';

  @override
  String get uniDetailPlacesEmptyDesc =>
      'Bu bölüme yakında kafeler ve mekanlar eklenecek.\nSizlerin önerileriyle bu listeyi oluşturacağız! 🎉';

  @override
  String exploreFoundCount(int count) {
    return '$count üniversite bulundu';
  }

  @override
  String get exploreShowResults => 'Sonuçları Göster';

  @override
  String get commonActions => 'İşlemler';

  @override
  String get commonPrivate => 'Gizli';

  @override
  String get commonPublic => 'Açık';

  @override
  String get commonPublicLong => 'Herkese Açık';

  @override
  String get commonSelect => 'Seç';

  @override
  String get commonNoData => 'Veri yok';

  @override
  String get commonNoDataLower => 'veri yok';

  @override
  String get semanticUniversityLogo => 'Üniversite logosu';

  @override
  String get universityTypeState => 'Devlet';

  @override
  String get universityTypeFoundation => 'Vakıf';

  @override
  String get campusLayoutCampus => 'Kampüslü';

  @override
  String get campusLayoutBlock => 'Blok Yerleşke';

  @override
  String get campusLayoutDistributed => 'Dağınık Kampüs';

  @override
  String get departmentTypeUndergraduate => 'Lisans';

  @override
  String get departmentTypeAssociate => 'Önlisans';

  @override
  String get departmentLanguageTurkish => 'Türkçe';

  @override
  String get departmentLanguageEnglish => 'İngilizce';

  @override
  String yearsCount(int years) {
    return '$years yıl';
  }

  @override
  String get prefListsTitle => 'Tercih Listelerim';

  @override
  String get prefListsNewList => 'Yeni Liste';

  @override
  String get prefListsEmptyTitle => 'Henüz listen yok';

  @override
  String get prefListsEmptyDesc =>
      'Sağ alttaki \"Yeni Liste\" butonuna tıklayarak ilk tercih listeni oluşturmaya başla.';

  @override
  String get prefListsLoginTitle => 'Giriş Yapmalısın';

  @override
  String get prefListsLoginDesc =>
      'Listelerini görmek ve yeni tercihler eklemek için önce giriş yapmalısın.';

  @override
  String get prefListDeleteTitle => 'Listeyi Sil';

  @override
  String prefListDeleteConfirm(String title) {
    return '\"$title\" listesini silmek istediğine emin misin? Bu işlem geri alınamaz.';
  }

  @override
  String prefListItemLimit(int max) {
    return '/ $max tercih';
  }

  @override
  String prefListItemCount(int count) {
    return '$count tercih';
  }

  @override
  String get prefListActionsShare => 'Listeyi Paylaş';

  @override
  String get prefListActionsShareDesc =>
      'Paylaşım bağlantısını ve görünürlüğü yönet';

  @override
  String get prefListActionsDeleteDesc => 'Bu işlem geri alınamaz';

  @override
  String get prefListCreateTitle => 'Yeni Tercih Listesi';

  @override
  String get prefListCreateSubtitle => 'Liste adını ve açıklamasını gir';

  @override
  String get prefListTitleLabel => 'Liste adı';

  @override
  String get prefListTitleRequired => 'Liste adı gerekli';

  @override
  String get prefListTitleHint => 'Örn. 2025 Sayısal Tercihlerim';

  @override
  String get prefListDescriptionLabel => 'Açıklama (opsiyonel)';

  @override
  String get prefListDescriptionHint => 'Bu liste hakkında kısa not…';

  @override
  String get prefListPublicTitle => 'Herkese açık';

  @override
  String get prefListPublicCreateSubtitle =>
      'Bağlantıyı paylaştığın herkes listeyi görebilir';

  @override
  String get prefListPublicShareSubtitle =>
      'Linke sahip herkes listeni görebilir';

  @override
  String get prefListCreateButton => 'Listeyi Oluştur';

  @override
  String get prefListShareTitle => 'Listeyi Paylaş';

  @override
  String get prefListLinkCopied => 'Bağlantı kopyalandı';

  @override
  String get prefListShareLinkButton => 'Bağlantıyı Paylaş';

  @override
  String prefListViewCount(int count) {
    return '$count görüntülenme';
  }

  @override
  String get prefListPrivateNotice =>
      'Listen şu an gizli. Paylaşmak için yukarıdaki anahtarı aç.';

  @override
  String prefListShareTextHeader(String title) {
    return '\"$title\" tercih listemi paylaştım 🎓';
  }

  @override
  String prefListShareTextExtra(int count) {
    return '…ve $count bölüm daha';
  }

  @override
  String get prefListDuplicateDepartment => 'Bu bölüm zaten listede';

  @override
  String prefListMaxItems(int max) {
    return 'Listede en fazla $max tercih olabilir';
  }

  @override
  String get prefListSaved => 'Tercih listesi kaydedildi';

  @override
  String prefListSaveError(String error) {
    return 'Kaydetme hatası: $error';
  }

  @override
  String get prefListDeleted => 'Tercih listesi silindi';

  @override
  String prefListDeleteError(String error) {
    return 'Silme hatası: $error';
  }

  @override
  String get prefListNotFound => 'Liste bulunamadı.';

  @override
  String prefListFullLimit(int max) {
    return 'Limit dolu ($max)';
  }

  @override
  String get prefListAddDepartment => 'Bölüm Ekle';

  @override
  String get prefListSortByScore => 'Puana Göre Sırala';

  @override
  String get prefListUndo => 'Geri Al';

  @override
  String prefListsSummary(int lists, int items) {
    return '$lists liste · $items tercih';
  }

  @override
  String get prefListSavedState => 'Kaydedildi';

  @override
  String get prefListEmptyItemsTitle => 'Liste boş';

  @override
  String get prefListEmptyItemsDesc =>
      '\"Bölüm Ekle\" butonuna tıklayarak üniversite ve bölüm seç. Tercihlerini sürükleyerek veya sıralamaya göre düzenleyebilirsin.';

  @override
  String get prefDeptSelectUniversity => 'Üniversite Seç';

  @override
  String get prefDeptSelectDepartment => 'Bölüm Seç';

  @override
  String get prefDeptSearchUniversity => 'Üniversite ara…';

  @override
  String get prefDeptSearchDepartment => 'Bölüm ara…';

  @override
  String get prefNoSearchResults => 'Sonuç bulunamadı';

  @override
  String get prefNoSearchResultsDesc => 'Farklı bir arama deneyebilirsin.';

  @override
  String get prefNoDepartmentsTitle => 'Bölüm bulunamadı';

  @override
  String get prefNoDepartmentsDesc => 'Bu üniversite için kayıtlı bölüm yok.';

  @override
  String prefDeptUniversitiesWithDepartment(String department) {
    return '$department bölümü olan üniversiteler';
  }

  @override
  String get prefDeptNoUniversityForDepartment =>
      'Bu bölüme sahip üniversite bulunamadı';

  @override
  String prefDeptNoOtherUniversityForDepartment(String department) {
    return '\"$department\" bölümü olan başka üniversite yok.';
  }

  @override
  String get prefBaseScoreShort => 'Taban';

  @override
  String get prefSharedListLoadError => 'Liste yüklenemedi';

  @override
  String get prefSharedListBadge => 'Paylaşılan Liste';

  @override
  String get prefSharedListOwner => 'Liste sahibi';

  @override
  String get prefSharedListEmptyDesc => 'Bu listede henüz tercih yok.';

  @override
  String get prefSharedListHiddenOrDeleted =>
      'Bu liste silinmiş veya gizli olarak işaretlenmiş olabilir.';

  @override
  String get prefSharedListBackHome => 'Ana Sayfaya Dön';

  @override
  String get prefSharedReadOnlyNotice =>
      'Bu listeyi salt görüntüleme modunda inceliyorsun.';

  @override
  String get prefSharedCopyButton => 'Kendime Kopyala ve Düzenle';

  @override
  String get prefSharedCopySuccess =>
      'Liste sana kopyalandı! Artık düzenleyebilirsin.';

  @override
  String get prefSharedCopyOwnList => 'Bu liste zaten sana ait.';

  @override
  String get prefSharedEditOwnList => 'Listeni Düzenle';

  @override
  String get prefSharedCopyPaywallTitle => 'Kopyalamak Plus\'a Özel';

  @override
  String get prefSharedCopyPaywallDesc =>
      'Bu listeyi görüntüleyebilirsin. Kendine kopyalayıp düzenlemek Plus ve Pro üyelere özeldir. Kopyaladığında liste sahibinin listesi değişmez — tamamen sana ait yeni bir kopya oluşur.';

  @override
  String get prefSharedCopyPaywallButton => 'Planları Gör';

  @override
  String get comparisonHubSubtitle =>
      'Hangi tür karşılaştırma yapmak istiyorsun?';

  @override
  String get comparisonHistoryTitle => 'Karşılaştırma Geçmişi';

  @override
  String get comparisonHistoryTooltip => 'Karşılaştırma geçmişi';

  @override
  String get comparisonEntityUniversity => 'Üniversite';

  @override
  String get comparisonEntityDepartment => 'Bölüm';

  @override
  String get comparisonEntityCity => 'Şehir';

  @override
  String get comparisonSubscriptionLabel => 'Aboneliğin';

  @override
  String get subscriptionFree => 'Ücretsiz';

  @override
  String get comparisonUpgradePlus => 'Plus\'a Geç';

  @override
  String get comparisonResetTitle => 'Karşılaştırmayı Sıfırla';

  @override
  String get comparisonResetConfirm =>
      'Mevcut karşılaştırma sıfırlansın mı? Yeni üniversiteler seçebilirsiniz.';

  @override
  String get comparisonAddThirdTooltip => '3. üniversite ekle (Pro)';

  @override
  String get comparisonRemoveThirdTooltip => '3. üniversiteyi kaldır';

  @override
  String get comparisonEmptyUniversityTitle => 'İki üniversite seç';

  @override
  String get comparisonEmptyUniversityDesc =>
      'Yukarıdan iki üniversite seçince karşılaştırma sonuçları burada gözükür.';

  @override
  String get comparisonNotesTab => 'Notlarım';

  @override
  String get comparisonNotesTabShort => 'Not';

  @override
  String get comparisonTabGeneralShort => 'Gn';

  @override
  String get comparisonTabCategoriesShort => 'Kat';

  @override
  String get comparisonTabChartShort => 'Grf';

  @override
  String get comparisonTabStatsShort => 'İst';

  @override
  String get comparisonSummaryTitle => 'Karşılaştırma Özeti';

  @override
  String comparisonWinnerCategories(String winnerName, int wins, int total) {
    return '🏆 $winnerName $wins/$total kategoride önde';
  }

  @override
  String get comparisonQuickDepartments => 'Bölüm';

  @override
  String get comparisonQuickPlaces => 'Mekan';

  @override
  String get comparisonQuickReviews => 'Yorum';

  @override
  String reviewCountShort(int count) {
    return '$count yorum';
  }

  @override
  String get comparisonCategoriesEmptyTitle => 'Yeterli değerlendirme yok';

  @override
  String get comparisonCategoriesEmptyDesc =>
      'Bu iki üniversite için henüz kategori puanı oluşturacak yorum bulunmuyor.';

  @override
  String get comparisonChartEmptyTitle => 'Grafik üretmek için yorum gerekiyor';

  @override
  String get comparisonChartEmptyDesc =>
      'Henüz yeterli değerlendirme olmadığı için grafikler boş görünüyor.';

  @override
  String get comparisonChartHintTitle => 'Yeni: Pro karşılaştırma grafikleri';

  @override
  String get comparisonChartHintBody =>
      'Radar, ısı haritası ve trend grafiklerini Grafik sekmesinde keşfet.';

  @override
  String get comparisonChartHintCta => 'Göster';

  @override
  String get comparisonUniversityPickerTitle => 'Üniversite Karşılaştır';

  @override
  String get comparisonUniversityPickerSubtitle =>
      'Karşılaştırmak istediğin iki üniversiteyi seç. Puanlar, kategoriler ve istatistikler yan yana gelsin.';

  @override
  String get comparisonTripleHint =>
      'Pro ile 3. üniversiteyi ekleyip üçlü karşılaştırma yapabilirsin.';

  @override
  String get comparisonSelectUniversityForA => 'A için üniversite seç';

  @override
  String get comparisonSelectUniversityForB => 'B için üniversite seç';

  @override
  String get comparisonDepartmentHeaderTitle => 'Bölüm Karşılaştır';

  @override
  String get comparisonDepartmentHeaderSubtitle =>
      'Aynı bölümü iki farklı üniversitede karşılaştır. Taban puan, sıralama ve kontenjan yan yana gelsin.';

  @override
  String get comparisonDepartmentHint =>
      'İki taraftan da birer bölüm seçince karşılaştırma sonuçları burada gözükecek.';

  @override
  String get comparisonCityHeaderTitle => 'Şehir Karşılaştır';

  @override
  String get comparisonCityHeaderSubtitle =>
      'İki şehrin üniversite ekosistemini karşılaştır. Devlet/vakıf dağılımı, üniversite sayısı ve daha fazlası.';

  @override
  String get comparisonCityHint =>
      'İki şehir seçince karşılaştırma sonuçları burada gözükecek.';

  @override
  String get comparisonSelectCity => 'Şehir Seç';

  @override
  String get comparisonSearchCity => 'Şehir ara…';

  @override
  String comparisonCityTileMeta(String plate, int count) {
    return 'Plaka: $plate • Üni: $count';
  }

  @override
  String get comparisonResultNotFound => 'Sonuç bulunamadı.';

  @override
  String get comparisonScoreTypeMismatch =>
      'Puan türleri farklı görünüyor. Karşılaştırma yanıltıcı olabilir.';

  @override
  String get comparisonBaseScore2025 => 'Taban Puan (2025)';

  @override
  String get comparisonDetailedInfo => 'Detaylı Bilgiler';

  @override
  String get comparisonFaculty => 'Fakülte';

  @override
  String get comparisonRankingTitle => 'Sıralama';

  @override
  String get comparisonNoDataLower => 'veri yok';

  @override
  String get comparisonUniversityCount => 'Üniversite Sayısı';

  @override
  String get comparisonStateFoundationDistribution => 'Devlet / Vakıf Dağılımı';

  @override
  String get comparisonPopulation => 'Nüfus';

  @override
  String get comparisonCityFeatures => 'Şehir Özellikleri';

  @override
  String get comparisonPlate => 'Plaka';

  @override
  String get comparisonTotalUniversities => 'Toplam Üni';

  @override
  String get comparisonInUniSec => 'ÜniSeç\'te';

  @override
  String get comparisonProNotesTitle => 'Karşılaştırma Notları';

  @override
  String get comparisonProNotesSubtitleLoggedIn =>
      'Pro üyelere özel premium bir deneyim seni bekliyor!';

  @override
  String get comparisonProNotesSubtitleGuest =>
      'Giriş yap ve Pro üye olarak bu özelliğin kilidini aç!';

  @override
  String get comparisonProNotesFeaturePersonal =>
      'Her karşılaştırmaya kişisel not ekle';

  @override
  String get comparisonProNotesFeatureProsCons =>
      'Artılar ve eksiler ile detaylı analiz yap';

  @override
  String get comparisonProNotesFeatureRating =>
      '1-5 yıldız tercih puanı ile sırala';

  @override
  String get comparisonProNotesFeatureCloud =>
      'Notların bulutta güvende — asla kaybolmaz';

  @override
  String get comparisonProNotesUpgrade => 'Pro Plana Yükselt';

  @override
  String get comparisonProNotesLoginAndPro => 'Giriş Yap ve Pro Ol';

  @override
  String get comparisonSkipForNow => 'Şimdilik geç';

  @override
  String get comparisonHistoryClearTooltip => 'Geçmişi temizle';

  @override
  String get comparisonHistoryClearTitle => 'Geçmişi Temizle';

  @override
  String get comparisonHistoryClearConfirm =>
      'Tüm karşılaştırma geçmişin silinsin mi?';

  @override
  String get comparisonHistoryClearButton => 'Temizle';

  @override
  String comparisonHistoryLoadError(String error) {
    return 'Geçmiş yüklenemedi: $error';
  }

  @override
  String get comparisonHistoryEmptyTitle => 'Henüz karşılaştırma yapmadın';

  @override
  String get comparisonHistoryEmptyDesc =>
      'İlk karşılaştırmanı yaptığında burada görünecek.';

  @override
  String get comparisonHistoryPaywallTitle =>
      'Karşılaştırma Geçmişi Plus / Pro\'da';

  @override
  String get comparisonHistoryPaywallDesc =>
      'Yaptığın karşılaştırmalar otomatik kaydedilsin, istediğin zaman tekrar açıp incele.';

  @override
  String get comparisonHistoryPaywallButton => 'Plus / Pro\'ya Geç';

  @override
  String get comparisonHistoryFeatureRecent =>
      'Son 20 karşılaştırma otomatik kaydedilir';

  @override
  String get comparisonHistoryFeatureReturn =>
      'Tek dokunuşla aynı karşılaştırmaya geri dön';

  @override
  String get comparisonHistoryFeatureSync => 'Cihazlar arası senkronize';

  @override
  String get comparisonTripleCategoryTitle => 'Kategori Karşılaştırması';

  @override
  String get comparisonLeader => 'LİDER';

  @override
  String get noteEditTitle => 'Notu Düzenle';

  @override
  String get noteAddTitle => 'Not Ekle';

  @override
  String get noteSubtitle => 'Karşılaştırma hakkındaki düşüncelerini kaydet';

  @override
  String get notePreferenceRating => 'Tercih Puanın';

  @override
  String get noteLabel => 'Not';

  @override
  String get noteHint => 'Örn: İTÜ bana daha yakın, kampüsü çok güzel...';

  @override
  String get noteEmptyError => 'Not boş bırakılamaz';

  @override
  String get noteProsLabel => 'Artılar';

  @override
  String get noteConsLabel => 'Eksiler';

  @override
  String get noteAddProHint => 'Yeni artı ekle...';

  @override
  String get noteAddConHint => 'Yeni eksi ekle...';

  @override
  String get noteUpdate => 'Güncelle';

  @override
  String get noteMyNotes => 'Notlarım';

  @override
  String get noteLoadError => 'Notlar yüklenemedi.';

  @override
  String get noteSavedSnack => 'Not kaydedildi ✍️';

  @override
  String get noteUpdatedSnack => 'Not güncellendi ✅';

  @override
  String get noteDeletedSnack => 'Not silindi';

  @override
  String get noteDeleteTitle => 'Notu Sil';

  @override
  String get noteDeleteConfirm =>
      'Bu not kalıcı olarak silinecek. Devam edilsin mi?';

  @override
  String get noteEmptyState => 'Henüz not yok';

  @override
  String get noteEmptyStateDesc =>
      'Bu karşılaştırma hakkındaki düşüncelerini kaydet';

  @override
  String get noteTimeJustNow => 'Az önce';

  @override
  String noteTimeMinutesAgo(int minutes) {
    return '$minutes dk önce';
  }

  @override
  String noteTimeHoursAgo(int hours) {
    return '$hours saat önce';
  }

  @override
  String noteTimeDaysAgo(int days) {
    return '$days gün önce';
  }

  @override
  String noteTimeWeeksAgo(int weeks) {
    return '$weeks hafta önce';
  }

  @override
  String get plusLockSubtitle => 'Plus veya Pro ile açılır';

  @override
  String get plusLockButton => 'Plus\'a Geç';

  @override
  String get comparisonNoData => 'Veri yok';

  @override
  String get trendNoData => 'Trend verisi yok';

  @override
  String get shareInstagramStory => 'Instagram Hikaye (9:16)';

  @override
  String get shareInstagramPost => 'Instagram Gönderi (1:1)';

  @override
  String get shareTwitterWhatsApp => 'Twitter / WhatsApp';

  @override
  String get yearlyTableYear => 'Yıl';

  @override
  String loadFailed(String error) {
    return 'Yüklenemedi: $error';
  }

  @override
  String get favoriteLoginRequired => 'Favori için giriş yapmalısın.';

  @override
  String get yearlyComparisonTitle => 'Yıl Bazlı Karşılaştırma';

  @override
  String get yearlyDifference => 'Fark';

  @override
  String rankFormat(String rank) {
    return '$rank. sıra';
  }

  @override
  String get rankNotAnnounced => 'Sıra: Açıklanmadı';

  @override
  String get shareStatAvgBase => 'Ort. Taban';

  @override
  String get shareStatDepartment => 'Bölüm';

  @override
  String get shareStatPlace => 'Mekan';

  @override
  String get shareFormat => 'Paylaşım Formatı';

  @override
  String get comparisonSubtitle => 'Üniversiteleri yan yana kıyasla';

  @override
  String get comparisonSwapTooltip => 'Yer Değiştir';

  @override
  String comparisonError(String error) {
    return 'Hata: $error';
  }

  @override
  String get adGateTitleGuest => 'Reklam ile Karşılaştır';

  @override
  String get adGateTitleUser => 'Ücretsiz hakkın bitti';

  @override
  String get adGateDescGuest =>
      'Karşılaştırma yapmak için kısa bir reklam izlemen gerekiyor. Giriş yap veya Plus\'a geçerek sınırsız karşılaştırma yapabilirsin.';

  @override
  String get adGateDescUser =>
      'Günlük 1 ücretsiz karşılaştırma hakkını kullandın. Devam etmek için kısa bir reklam izleyebilir veya Plus\'a geçerek sınırsız karşılaştırma yapabilirsin.';

  @override
  String get adGateWatchBusy => 'Reklam hazırlanıyor…';

  @override
  String get adGateWatchCta => 'Reklamı İzle ve Devam Et';

  @override
  String get adGatePlusCta => 'Plus\'a Geç — Sınırsız';

  @override
  String get adGateDismiss => 'Şimdilik Vazgeç';

  @override
  String get adGateOverlayTitleGuest => 'Reklam izleyerek devam et';

  @override
  String get adGateOverlayTitleUser => 'Devam etmek için kilidi aç';

  @override
  String get adGateOverlayDescGuest =>
      'Karşılaştırma için kısa bir reklam izlemen gerekiyor.';

  @override
  String get adGateOverlayDescUser => 'Günlük karşılaştırma hakkın doldu.';

  @override
  String get adGateOverlayBusy => 'Yükleniyor…';

  @override
  String get adGateOverlayCta => 'Reklamı İzle / Plus\'a Geç';

  @override
  String get favoritesAddTitle => 'Favorilere ekle';

  @override
  String get actionBarShare => 'Paylaş';

  @override
  String get actionBarFavorite => 'Favorile';

  @override
  String get actionBarRecompare => 'Yeniden';

  @override
  String get emptyStateSelectTwo => 'İki üniversite seç';

  @override
  String get emptyStateSelectTwoDesc =>
      'Yukarıdan iki üniversite seçince karşılaştırma sonuçları burada gözükür.';

  @override
  String get triplePickerTitle => '3. üniversiteyi seç';

  @override
  String get triplePickerSearchHint => 'Üniversite ara…';

  @override
  String get triplePickerNoResult => 'Sonuç bulunamadı';

  @override
  String get sectionCategoryScores => 'Kategori Puanları';

  @override
  String get sectionOverview => 'Genel Görünüm';

  @override
  String get sectionStats => 'Genel İstatistikler';

  @override
  String get noReviewsTitle => 'Yeterli değerlendirme yok';

  @override
  String get noReviewsDesc =>
      'Bu iki üniversite için henüz kategori puanı oluşturacak yorum bulunmuyor.';

  @override
  String get commonReset => 'Sıfırla';
}
