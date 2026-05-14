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
  String get authSignIn => 'Giriş Yap';

  @override
  String get authSignUp => 'Kayıt Ol';

  @override
  String get authEmailLabel => 'E-posta adresi';

  @override
  String get authEmailHint => 'ornek@universite.edu.tr';

  @override
  String get authPasswordLabel => 'Şifre';

  @override
  String get authPasswordHint => 'En az 6 karakter';

  @override
  String get authForgotPassword => 'Şifremi Unuttum';

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
  String get authEmailInvalid => 'Geçerli bir e-posta adresi girin';

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
  String get profileEditProfile => 'Profili Düzenle';

  @override
  String get profileEditSubtitle => 'Fotoğraf, isim, üniversite';

  @override
  String get profileAccount => 'Hesap';

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
}
