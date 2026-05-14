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
}
