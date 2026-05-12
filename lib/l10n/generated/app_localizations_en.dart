// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get comparisonHubTitle => 'Compare';

  @override
  String get comparisonUniversity => 'Compare Universities';

  @override
  String get comparisonUniversityDesc =>
      'Compare two universities side by side';

  @override
  String get comparisonDepartment => 'Compare Departments';

  @override
  String get comparisonDepartmentDesc =>
      'Compare the same department across universities';

  @override
  String get comparisonCity => 'Compare Cities';

  @override
  String get comparisonCityDesc => 'Compare two cities\' university ecosystems';

  @override
  String get selectUniversityA => 'University A';

  @override
  String get selectUniversityB => 'University B';

  @override
  String get selectDepartmentA => 'Department A';

  @override
  String get selectDepartmentB => 'Department B';

  @override
  String get selectCityA => 'City A';

  @override
  String get selectCityB => 'City B';

  @override
  String get swap => 'Swap';

  @override
  String get share => 'Share';

  @override
  String get reset => 'Reset';

  @override
  String get retry => 'Retry';

  @override
  String get tabGeneral => 'General';

  @override
  String get tabCategories => 'Categories';

  @override
  String get tabChart => 'Chart';

  @override
  String get tabStats => 'Stats';

  @override
  String emptyStateTitle(String entityType) {
    return 'Select two $entityType';
  }

  @override
  String get loadingComparison => 'Loading comparison…';

  @override
  String get errorComparison => 'Failed to load comparison';

  @override
  String get aiSummaryTitle => 'AI Analysis';

  @override
  String get aiSummaryProRequired =>
      'AI Analysis is a Pro feature. Upgrade to unlock detailed summaries.';

  @override
  String aiSummaryLimitReached(int limit) {
    return 'You\'ve used your daily $limit AI summaries. Try again tomorrow.';
  }

  @override
  String get aiSummaryActive => 'Pro analysis active';

  @override
  String get aiSummaryRegenerate => 'Regenerate';

  @override
  String get watchAdToContinue => 'Watch Ad to Continue';

  @override
  String get upgradePlus => 'Upgrade to Plus — Unlimited';

  @override
  String get cancelForNow => 'Cancel for Now';

  @override
  String get dailyLimitReached => 'Daily comparison limit reached';

  @override
  String get comparisonStarted => 'Comparison started';

  @override
  String get scoreType => 'Score Type';

  @override
  String get baseScore => 'Base Score';

  @override
  String get ranking => 'Ranking';

  @override
  String get quota => 'Quota';

  @override
  String get fillRate => 'Fill Rate';

  @override
  String get duration => 'Duration';

  @override
  String get language => 'Language';

  @override
  String get type => 'Type';

  @override
  String get categoryRating => 'Category Rating';

  @override
  String get reviewCount => 'Review Count';

  @override
  String get averageRating => 'Average Rating';

  @override
  String get establishedYear => 'Established';

  @override
  String get stateUniversity => 'State';

  @override
  String get foundationUniversity => 'Foundation';

  @override
  String get winner => 'Winner';

  @override
  String get tie => 'Tie';

  @override
  String get noEnoughReviews => 'Not enough reviews';

  @override
  String get trendInsufficient => 'Not enough reviews for trend analysis';

  @override
  String get offline => 'No internet connection';

  @override
  String get offlineDescription =>
      'Connect to the internet to make comparisons.';

  @override
  String shareSubject(String uniA, String uniB) {
    return '$uniA vs $uniB — Comparison';
  }
}
