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
  String get viewProPlans => 'View Pro Plans';

  @override
  String get proChartLockedSubtitle => 'This chart is part of the Pro plan.';

  @override
  String get watchAdUnlockOneHour => 'Watch a Video & Unlock Free for 1 Hour';

  @override
  String get adLoading => 'Loading ad, please wait…';

  @override
  String get proChartsUnlockedOneHour =>
      'Pro charts and features unlocked for 1 hour!';

  @override
  String get adFailedRetry =>
      'The ad couldn\'t load or wasn\'t completed. Please try again.';

  @override
  String get chartHeatmapTitle => 'Category Comparison';

  @override
  String get chartTrendTitle => '6-Month Rating Trend';

  @override
  String get chartScatterTitle => 'Base Score × Ranking';

  @override
  String get chartScatterXAxis => 'Base score';

  @override
  String get chartScatterYAxis => 'Ranking';

  @override
  String get chartScaleLow => 'Low';

  @override
  String get chartScaleHigh => 'High';

  @override
  String get chartNoData => 'No data';

  @override
  String get chartDepartmentLabel => 'Department';

  @override
  String tempProBadge(int minutes) {
    return 'Pro active · $minutes min';
  }

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

  @override
  String get authSignIn => 'Sign in';

  @override
  String get authSignUp => 'Sign up';

  @override
  String get authEmailLabel => 'Email';

  @override
  String get authEmailHint => 'example@university.edu';

  @override
  String get authPasswordLabel => 'Password';

  @override
  String get authPasswordHint => 'At least 6 characters';

  @override
  String get authForgotPassword => 'Forgot password';

  @override
  String get authGoogleContinue => 'Sign In with Google';

  @override
  String get authNoAccount => 'Don\'t have an account? ';

  @override
  String get authHaveAccount => 'Already have an account? ';

  @override
  String get authShowPassword => 'Show password';

  @override
  String get authHidePassword => 'Hide password';

  @override
  String get authPasswordRequired => 'Password is required';

  @override
  String get authEmailRequired => 'Email address is required';

  @override
  String get authEmailInvalid => 'Enter a valid email';

  @override
  String get authContinueWithAccount => 'Sign in to your account to continue';

  @override
  String get authOrDivider => 'or';

  @override
  String get authGuestContinue => 'Continue as guest';

  @override
  String get authLoggingIn => 'Signing in...';

  @override
  String get authPleaseWait => 'Please wait';

  @override
  String get authResetPasswordTitle => 'Reset Password';

  @override
  String get authResetPasswordDesc =>
      'Enter your email address to receive a password reset link.';

  @override
  String get authResetPasswordSend => 'Send Reset Link';

  @override
  String get authResetPasswordSent => 'Password reset link sent!';

  @override
  String get authRegisterTitle => 'Create a new account and start exploring';

  @override
  String get authFullName => 'Full Name';

  @override
  String get authFullNameRequired => 'Full name is required';

  @override
  String get authFullNameTooShort => 'Full name must be at least 2 characters';

  @override
  String get authPasswordConfirm => 'Confirm Password';

  @override
  String get authPasswordConfirmRequired => 'Password confirmation is required';

  @override
  String get authPasswordMismatch => 'Passwords don\'t match';

  @override
  String get authPasswordMin8 => 'Password must be at least 8 characters';

  @override
  String get authPasswordUppercase =>
      'Password must contain at least one uppercase letter';

  @override
  String get authPasswordDigit => 'Password must contain at least one digit';

  @override
  String get authCreatingAccount => 'Creating account...';

  @override
  String get authEduDetected =>
      'edu.tr account detected! You can write reviews after verification.';

  @override
  String get authEduVerifyTitle => 'edu.tr Verification';

  @override
  String get authEduVerifyLinkSent =>
      'A verification link has been sent to your email:';

  @override
  String get authEduVerifyAfter =>
      'You can write reviews after verifying your email.';

  @override
  String get authOk => 'OK';

  @override
  String get authGoBack => 'Go back';

  @override
  String get authVerifyEmailTitle => 'Verify your email';

  @override
  String authVerifyEmailBody(String email) {
    return 'We sent a verification link to $email.';
  }

  @override
  String get profileTitle => 'Account';

  @override
  String get profileEditProfile => 'Edit profile';

  @override
  String get profileEditSubtitle => 'Photo, name, university';

  @override
  String get profileAccount => 'Account';

  @override
  String get profileSettings => 'Settings';

  @override
  String get profileNotifications => 'Notifications';

  @override
  String get profileNotificationsSubtitle => 'Review, favorite notifications';

  @override
  String get profileSecurity => 'Security';

  @override
  String get profileSecuritySubtitle => 'Change password';

  @override
  String get profilePasswordChanged => 'Password changed successfully';

  @override
  String get profileApp => 'App';

  @override
  String get profileAbout => 'About';

  @override
  String get profileRateApp => 'Rate the App';

  @override
  String get profileRateAppSubtitle => 'Rate on Google Play';

  @override
  String get profileShareApp => 'Recommend to a Friend';

  @override
  String get profileShareAppSubtitle => 'Share link';

  @override
  String get profileShareText =>
      'ÜniSeç - Discover your dream university! 🎓\nhttps://play.google.com/store/apps/details?id=com.unisec.app';

  @override
  String get profilePrivacyPolicy => 'Privacy Policy';

  @override
  String get privacyPolicyComingSoon => 'Privacy policy coming soon';

  @override
  String get profileSignOut => 'Sign Out';

  @override
  String get profileSignOutConfirm => 'Are you sure you want to sign out?';

  @override
  String get profileCancel => 'Cancel';

  @override
  String get profileMembershipPlan => 'Membership Plan';

  @override
  String profileMembershipUsing(String plan) {
    return 'You are using the $plan plan';
  }

  @override
  String get profilePlanDetails => 'Plan Details';

  @override
  String get profileViewPlans => 'View Plans & Upgrade';

  @override
  String get profileGuestWelcome => 'Welcome!';

  @override
  String get profileGuestSubtitle =>
      'You need to sign in to\nwrite reviews and add favorites.';

  @override
  String get profileVerifiedStudent => 'Verified Student';

  @override
  String get profileVerificationPending => 'Verification Pending';

  @override
  String get profileVerified => 'Your account has been verified!';

  @override
  String get profileNotVerified =>
      'Not verified yet. Please click the link in your email.';

  @override
  String get profileRefresh => 'Refresh';

  @override
  String get profileStatReview => 'Reviews';

  @override
  String get profileStatFavorite => 'Favorites';

  @override
  String get profileStatMembership => 'Member';

  @override
  String profileStatDays(int days) {
    return '$days days';
  }

  @override
  String get profileAboutDescription =>
      'ÜniSeç is a mobile app that helps you discover, compare, and share your experiences about universities in Turkey.';

  @override
  String get profileAboutCopyright => '© 2026 ÜniSeç Team';

  @override
  String get profileUser => 'User';

  @override
  String get editProfileTitle => 'Edit Profile';

  @override
  String get editProfileCamera => 'Camera';

  @override
  String get editProfileGallery => 'Gallery';

  @override
  String get editProfileFullName => 'Full Name';

  @override
  String get editProfileFullNameRequired => 'Full name is required';

  @override
  String get editProfileUniversity => 'University';

  @override
  String editProfileUniversityError(String error) {
    return 'Failed to load universities: $error';
  }

  @override
  String get editProfileDepartment => 'Department';

  @override
  String get editProfileDepartmentHint => 'e.g. Computer Engineering';

  @override
  String get editProfileBio => 'About Me (Optional)';

  @override
  String get editProfileBioHint => 'Tell us a bit about yourself...';

  @override
  String get editProfileBioProfanity => 'Inappropriate content detected';

  @override
  String get editProfileGrade => 'Grade';

  @override
  String get editProfileSave => 'Save';

  @override
  String get editProfileSaving => 'Saving...';

  @override
  String get editProfileSuccess => 'Profile updated successfully';

  @override
  String get editProfileError => 'An error occurred while updating profile';

  @override
  String errorGeneral(String error) {
    return 'Error: $error';
  }

  @override
  String get universityNotFound => 'University not found';

  @override
  String get errorDepartmentsLoad =>
      'An error occurred while loading departments.';

  @override
  String get noDepartmentsFound => 'No departments found.';

  @override
  String get errorPlacesLoad => 'An error occurred while loading places.';

  @override
  String get noPlacesFound => 'No places found.';

  @override
  String get errorReviewsLoad => 'An error occurred while loading reviews.';

  @override
  String get reviewLoginRequired =>
      'You must log in to your account first to write a review.';

  @override
  String get reviewEduRequiredTitle => 'Verification Required';

  @override
  String get reviewEduRequiredDesc =>
      'Only verified university students can write reviews (.edu.tr).';

  @override
  String get reviewAnonymousStudent => 'Anonymous Student';

  @override
  String get reviewLoading => 'Loading...';

  @override
  String get reviewUniversityFallback => 'University';

  @override
  String get reviewDepartmentFallback => 'Department';

  @override
  String get reviewPlaceFallback => 'Place';

  @override
  String get reviewUniversityReview => 'University Review';

  @override
  String get reviewDepartmentReview => 'Department Review';

  @override
  String get reviewPlaceReview => 'Place Review';

  @override
  String get reviewPendingTitle => 'Not Published';

  @override
  String get reviewPendingDesc =>
      'Your review is under moderation. If inappropriate content was detected, you can edit and resubmit.';

  @override
  String get reviewShowLess => 'Show less';

  @override
  String get reviewReadMore => 'Read more';

  @override
  String get recommendIntroTitle => 'Preference Assistant';

  @override
  String get recommendIntroSubtitle =>
      'I\'ll ask you a few short questions,\nlet\'s find your dream university together.';

  @override
  String get recommendIntroDuration => '~4 minutes';

  @override
  String get recommendIntroMedals => 'Gold / Silver / Bronze';

  @override
  String get recommendIntroSuggestions => '8 suggestions';

  @override
  String get recommendIntroBetaTitle => 'Beta — Development Phase';

  @override
  String get recommendIntroBetaDesc =>
      'This assistant is still under development. Suggestions are for guidance only, not final decisions. Always do your own research for final preferences.';

  @override
  String get recommendIntroStart => 'Let\'s Start';

  @override
  String get recommendIntroDurationNote => 'Takes approximately 4 minutes';

  @override
  String get aiSummaryLimitReachedSimple =>
      'You\'ve used your daily AI summary quota. Try again tomorrow.';

  @override
  String get commonRetry => 'Try again';

  @override
  String get commonError => 'Something went wrong';

  @override
  String get paywallPerMonthSuffix => '/mo';

  @override
  String get paywallPerYearSuffix => '/yr';

  @override
  String paywallSaveBadge(int percent) {
    return 'SAVE $percent%';
  }

  @override
  String paywallYearlySavingsSub(int percent) {
    return 'Save $percent% vs monthly';
  }

  @override
  String paywallFreeTrialNote(String duration) {
    return 'First $duration free, then auto-renews';
  }

  @override
  String get paywallUnitDay => 'days';

  @override
  String get paywallUnitWeek => 'weeks';

  @override
  String get paywallUnitMonth => 'months';

  @override
  String get paywallUnitYear => 'years';

  @override
  String get commonLoading => 'Loading...';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonSave => 'Save';

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonClose => 'Close';

  @override
  String get commonShare => 'Share';

  @override
  String get commonEdit => 'Edit';

  @override
  String get commonContinue => 'Continue';

  @override
  String get authSignOut => 'Sign out';

  @override
  String get authPasswordTooShort => 'Password must be at least 6 characters';

  @override
  String get homeTabHome => 'Home';

  @override
  String get homeTabExplore => 'Explore';

  @override
  String get homeTabCompare => 'Compare';

  @override
  String get homeTabFavorites => 'My Lists';

  @override
  String get homeTabProfile => 'Profile';

  @override
  String get comparisonTitleUni => 'Compare universities';

  @override
  String get comparisonTitleDept => 'Compare departments';

  @override
  String get comparisonTitleCity => 'Compare cities';

  @override
  String get comparisonNoteAdd => 'Add note';

  @override
  String get comparisonNoteEmpty => 'No notes yet';

  @override
  String get comparisonNoteMaxLength => 'Maximum 500 characters';

  @override
  String get comparisonNotesLoadError => 'Failed to load notes.';

  @override
  String get comparisonNoteSaved => 'Note saved ✍️';

  @override
  String get comparisonNoteUpdated => 'Note updated ✅';

  @override
  String get comparisonNoteDeleteTitle => 'Delete Note';

  @override
  String get comparisonNoteDeleteConfirm =>
      'This note will be permanently deleted. Continue?';

  @override
  String get comparisonNoteDeleted => 'Note deleted';

  @override
  String get comparisonNoteEmptyTitle => 'No notes yet';

  @override
  String get comparisonNoteEmptyDesc =>
      'Save your thoughts about this comparison';

  @override
  String get comparisonProUpsell => 'Upgrade to Pro to add a 3rd university';

  @override
  String get paywallContinueFree => 'Continue for free';

  @override
  String paywallSavePercent(int percent) {
    return 'SAVE $percent%';
  }

  @override
  String get paywallMonthly => 'Monthly';

  @override
  String get paywallYearly => 'Yearly';

  @override
  String get paywallRestore => 'Restore purchases';

  @override
  String get paywallPackageInfoError =>
      'Couldn\'t get package info. Please try again.';

  @override
  String get paywallPurchaseSuccess =>
      'Purchase successful. Your plan is being updated.';

  @override
  String get paywallPurchaseIncomplete => 'Purchase was not completed.';

  @override
  String paywallRestoreResult(String tier) {
    return 'Restore result: $tier';
  }

  @override
  String get paywallOfferingsLoadError =>
      'Something went wrong while loading plans. Please try again.';

  @override
  String get paywallSecurityNote => 'Secure payment • Cancel anytime';

  @override
  String get paywallPurchaseSuccessTitle => 'Purchase successful!';

  @override
  String get paywallPurchaseSuccessDesc =>
      'Your plan is now active. Enjoy all the features.';

  @override
  String get paywallGreat => 'Great';

  @override
  String get reviewWrite => 'Write a review';

  @override
  String get reviewAnonymous => 'Anonymous';

  @override
  String get reviewRatingRequired => 'Cannot submit without a rating';

  @override
  String get profilePremium => 'Premium membership';

  @override
  String get profileLanguage => 'Language';

  @override
  String get profileDeleteAccount => 'Delete account';

  @override
  String get deleteAccountTitle => 'Permanently delete account';

  @override
  String get deleteAccountDescription =>
      'Your profile, favorites, preference lists, reviews, suggestions, and personal data associated with your account will be deleted.';

  @override
  String get deleteAccountWarning =>
      'This action cannot be undone. If you have an active store subscription, you must also cancel it through Google Play.';

  @override
  String get deleteAccountPasswordNote =>
      'Verify your identity with your current password to continue.';

  @override
  String get deleteAccountGoogleNote =>
      'You will be asked to verify your identity with Google when you continue.';

  @override
  String get deleteAccountPasswordLabel => 'Current password';

  @override
  String get deleteAccountPasswordRequired => 'Enter your current password';

  @override
  String get deleteAccountConfirmationWord => 'DELETE';

  @override
  String deleteAccountConfirmationLabel(String word) {
    return 'Type $word to confirm';
  }

  @override
  String deleteAccountConfirmationMismatch(String word) {
    return 'Type $word to continue';
  }

  @override
  String get deleteAccountConfirmButton => 'Delete account';

  @override
  String get deleteAccountProgress => 'Deleting your account and data...';

  @override
  String get deleteAccountSuccess =>
      'Your account and associated data were deleted.';

  @override
  String get favoritesEmpty => 'No favorites';

  @override
  String get favoritesEmptyHint => 'Track universities you like here.';

  @override
  String get profileTheme => 'Theme';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get themeSelection => 'Theme Selection';

  @override
  String get languageSelection => 'Language Selection';

  @override
  String get turkish => 'Türkçe';

  @override
  String get english => 'English';

  @override
  String get homeGreeting => 'Hello! 👋';

  @override
  String get homePopularUniversities => 'Popular Universities';

  @override
  String get homeSeeAll => 'See All';

  @override
  String get homeCities => 'Cities';

  @override
  String get homeCitiesLoadError => 'Failed to load cities';

  @override
  String get homeRecentReviews => 'Recent Reviews';

  @override
  String get homeTopReviews => 'Featured Reviews';

  @override
  String get homeNoReviews => 'No reviews yet';

  @override
  String get homeFirstReview => 'Be the first to write a review!';

  @override
  String get homeAssistantTitle => 'Preference Assistant';

  @override
  String get homeAssistantSubtitle =>
      'Let\'s find your dream\nuniversity together!';

  @override
  String get homeStart => 'Start';

  @override
  String get exploreTitle => 'Explore';

  @override
  String get exploreSubtitle => 'Explore, filter and compare universities';

  @override
  String get exploreSearchHint => 'Search universities...';

  @override
  String get exploreTypeState => 'State';

  @override
  String get exploreTypeFoundation => 'Foundation';

  @override
  String get exploreFilters => 'Filters';

  @override
  String get exploreClear => 'Clear';

  @override
  String get exploreUniType => 'University Type';

  @override
  String get exploreCities => 'Cities';

  @override
  String get exploreCitiesError => 'Failed to load cities';

  @override
  String get exploreNoResults => 'No results found';

  @override
  String get exploreNoResultsSub => 'Try changing your filters.';

  @override
  String get searchGlobalHint => 'Search university, department or city...';

  @override
  String get showcaseSearchTitle => 'Quick Search';

  @override
  String get showcaseSearchDescription =>
      'Search university, department or city — find what you need instantly.';

  @override
  String get searchError => 'An error occurred while searching.';

  @override
  String get searchNoResults => 'No results found';

  @override
  String get searchRecentTitle => 'Recent Searches';

  @override
  String get searchRecentClear => 'Clear';

  @override
  String searchNoResultsSub(Object query) {
    return 'No university matching \"$query\".';
  }

  @override
  String get searchDidYouMean => 'Did you mean?';

  @override
  String get searchCampus => 'Has Campus';

  @override
  String searchEst(Object year) {
    return 'Established: $year';
  }

  @override
  String get homeHeroBannerTitle => 'Calculate Your Score,\nSet Your Goal!';

  @override
  String get reviewSortLabel => 'Sort:';

  @override
  String get reviewSortNewest => 'Newest';

  @override
  String get reviewSortMostLiked => 'Most Liked';

  @override
  String get uniDetailDepartments => 'Departments';

  @override
  String uniDetailDepartmentsSubtitle(int count) {
    return '$count departments — Top 3 most searched';
  }

  @override
  String get uniDetailSeeAllDepartments => 'See all departments';

  @override
  String get uniDetailReviews => 'Reviews';

  @override
  String uniDetailReviewsSubtitle(int count) {
    return '$count reviews — Top 3 most liked';
  }

  @override
  String get uniDetailNoReviews => 'No reviews yet';

  @override
  String get uniDetailSeeAllReviews => 'See all reviews';

  @override
  String get uniDetailWriteFirstReview => 'Write the first review';

  @override
  String get googleReviewsTitle => 'Google Reviews';

  @override
  String get googleReviewsTileSubtitle => 'Ratings from Google Maps users';

  @override
  String googleReviewsCount(int count) {
    return '$count ratings';
  }

  @override
  String get googleReviewsAttribution => 'Reviews are provided by Google';

  @override
  String get reviewBadgeOwnUniversity => 'Student at this university';

  @override
  String get reviewBadgeOtherUniversity => 'Student at another university';

  @override
  String get reviewPromptTitleOwn => 'Rate your university';

  @override
  String get reviewPromptTitleOther => 'Rate this university';

  @override
  String reviewPromptBodyOwn(String uniName) {
    return 'Share your $uniName experience and guide the students coming after you.';
  }

  @override
  String reviewPromptBodyOther(String uniName) {
    return 'If you know $uniName, sharing your experience helps students making their choice.';
  }

  @override
  String get reviewPromptCta => 'Write a review';

  @override
  String get reviewPromptLater => 'Maybe later';

  @override
  String get reviewPromptNever => 'Don\'t show again';

  @override
  String get badgeFirstReview => 'First Review';

  @override
  String get badgeFirstReviewDesc => 'Write your first approved review';

  @override
  String get badgeDetailedReviewer => 'Detailed Reviewer';

  @override
  String get badgeDetailedReviewerDesc => 'Write 3 approved reviews';

  @override
  String get badgeHelpful => 'Helpful';

  @override
  String get badgeHelpfulDesc => 'Get 10 total likes on your reviews';

  @override
  String get badgeProlificReviewer => 'Master Reviewer';

  @override
  String get badgeProlificReviewerDesc => 'Write 10 approved reviews';

  @override
  String get badgeReviewLegend => 'Review Legend';

  @override
  String get badgeReviewLegendDesc => 'Write 25 approved reviews';

  @override
  String get badgeCommunityHero => 'Community Hero';

  @override
  String get badgeCommunityHeroDesc => 'Get 50 total likes on your reviews';

  @override
  String get badgeLikeMagnet => 'Like Magnet';

  @override
  String get badgeLikeMagnetDesc => 'Get 150 total likes on your reviews';

  @override
  String get badgeCollector => 'Collector';

  @override
  String get badgeCollectorDesc => 'Add 5 universities to your favorites';

  @override
  String get badgeMasterCollector => 'Treasure Hunter';

  @override
  String get badgeMasterCollectorDesc =>
      'Add 15 universities to your favorites';

  @override
  String get badgeExplorer => 'Explorer';

  @override
  String get badgeExplorerDesc => 'View 10 different universities';

  @override
  String get badgeWanderer => 'Wanderer';

  @override
  String get badgeWandererDesc => 'View 30 different universities';

  @override
  String get badgeCartographer => 'Cartographer';

  @override
  String get badgeCartographerDesc => 'View 60 different universities';

  @override
  String get badgeCityTraveler => 'City Traveler';

  @override
  String get badgeCityTravelerDesc => 'Explore 5 different cities';

  @override
  String get badgeAnalyst => 'Analyst';

  @override
  String get badgeAnalystDesc => 'Make 5 comparisons';

  @override
  String get badgeStrategist => 'Strategist';

  @override
  String get badgeStrategistDesc => 'Make 20 comparisons';

  @override
  String get badgeAmbassador => 'Ambassador';

  @override
  String get badgeAmbassadorDesc => 'Share 3 times';

  @override
  String get badgeSuperAmbassador => 'Brand Ambassador';

  @override
  String get badgeSuperAmbassadorDesc => 'Share 10 times';

  @override
  String get badgeStreakStarter => 'Spark';

  @override
  String get badgeStreakStarterDesc => 'Open the app 3 days in a row';

  @override
  String get badgeStreakKeeper => 'Flame Keeper';

  @override
  String get badgeStreakKeeperDesc => 'Open the app 7 days in a row';

  @override
  String get badgeStreakMaster => 'Eternal Flame';

  @override
  String get badgeStreakMasterDesc => 'Open the app 30 days in a row';

  @override
  String get badgeLoyalMember => 'Loyal Member';

  @override
  String get badgeLoyalMemberDesc => 'Be a member for 30 days';

  @override
  String get badgeVeteran => 'Veteran';

  @override
  String get badgeVeteranDesc => 'Be a member for a year';

  @override
  String get badgeProfileComplete => 'Showcase';

  @override
  String get badgeProfileCompleteDesc =>
      'Complete your profile: photo, bio, department and grade';

  @override
  String get badgeVerifiedScholar => 'Verified Student';

  @override
  String get badgeVerifiedScholarDesc =>
      'Verify your student status with your edu.tr email';

  @override
  String get badgeEarlyAdopter => 'First Generation';

  @override
  String get badgeEarlyAdopterDesc => 'You were among the app\'s first users';

  @override
  String get badgesScreenTitle => 'My Badges';

  @override
  String badgesEarnedCount(int earned, int total) {
    return '$earned/$total';
  }

  @override
  String get badgesSeeAll => 'See All';

  @override
  String badgeProgressLabel(int current, int target) {
    return '$current/$target';
  }

  @override
  String badgeEarnedOn(String date) {
    return 'Earned on $date';
  }

  @override
  String get badgeLockedLabel => 'Locked';

  @override
  String get badgeCelebrationTitle => 'You Earned a New Badge!';

  @override
  String get badgeCelebrationAction => 'Awesome!';

  @override
  String get badgeCelebrationSecondary => 'My Badges';

  @override
  String get badgeCategoryReviewer => 'Reviewer';

  @override
  String get badgeCategoryHero => 'Hero';

  @override
  String get badgeCategoryCollection => 'Collection';

  @override
  String get badgeCategoryExplorer => 'Exploration';

  @override
  String get badgeCategoryAnalyst => 'Analysis';

  @override
  String get badgeCategoryAmbassador => 'Sharing';

  @override
  String get badgeCategoryStreak => 'Streak';

  @override
  String get badgeCategoryMembership => 'Membership';

  @override
  String get badgeCategorySpecial => 'Special';

  @override
  String get uniDetailPlaces => 'Places';

  @override
  String uniDetailPlacesSubtitle(int count) {
    return '$count places';
  }

  @override
  String get uniDetailPlacesComingSoon => 'Coming soon with your suggestions!';

  @override
  String get uniDetailSeeAllPlaces => 'See all places';

  @override
  String get uniDetailPlacesLoading => 'Loading...';

  @override
  String get uniDetailPlacesLoadError => 'Failed to load';

  @override
  String get uniDetailOpenMap => 'Open Map';

  @override
  String get uniDetailGallery => 'Gallery';

  @override
  String get uniDetailCategoryRatings => 'Category Ratings';

  @override
  String get uniDetailRateUniversity => 'Rate University';

  @override
  String get uniDetailPlacesEmptyTitle => 'Cafes Coming Soon!';

  @override
  String get uniDetailPlacesEmptyDesc =>
      'Cafes and places will be added to this section soon.\nWe\'ll build this list with your suggestions! 🎉';

  @override
  String exploreFoundCount(int count) {
    return '$count universities found';
  }

  @override
  String get exploreShowResults => 'Show Results';

  @override
  String get commonActions => 'Actions';

  @override
  String get commonPrivate => 'Private';

  @override
  String get commonPublic => 'Public';

  @override
  String get commonPublicLong => 'Public';

  @override
  String get commonSelect => 'Select';

  @override
  String get commonNoData => 'No data';

  @override
  String get commonNoDataLower => 'no data';

  @override
  String get semanticUniversityLogo => 'University logo';

  @override
  String get universityTypeState => 'State';

  @override
  String get universityTypeFoundation => 'Foundation';

  @override
  String get campusLayoutCampus => 'Campus';

  @override
  String get campusLayoutBlock => 'Block campus';

  @override
  String get campusLayoutDistributed => 'Distributed campus';

  @override
  String get departmentTypeUndergraduate => 'Undergraduate';

  @override
  String get departmentTypeAssociate => 'Associate degree';

  @override
  String get departmentLanguageTurkish => 'Turkish';

  @override
  String get departmentLanguageEnglish => 'English';

  @override
  String yearsCount(int years) {
    return '$years years';
  }

  @override
  String get prefListsTitle => 'My Preference Lists';

  @override
  String get prefListsNewList => 'New List';

  @override
  String get prefListsLoginTitle => 'Sign in required';

  @override
  String get prefListsLoginDesc =>
      'Sign in first to view your lists and add new preferences.';

  @override
  String get prefListDeleteTitle => 'Delete List';

  @override
  String prefListDeleteConfirm(String title) {
    return 'Are you sure you want to delete \"$title\"? This action cannot be undone.';
  }

  @override
  String prefListItemLimit(int max) {
    return '/ $max choices';
  }

  @override
  String prefListItemCount(int count) {
    return '$count choices';
  }

  @override
  String get prefListActionsShare => 'Share List';

  @override
  String get prefListActionsShareDesc => 'Manage the share link and visibility';

  @override
  String get prefListActionsDeleteDesc => 'This action cannot be undone';

  @override
  String get prefListCreateTitle => 'New preference list';

  @override
  String get prefListCreateSubtitle =>
      'You name it — I\'ll help you fill it in.';

  @override
  String get prefListTitleLabel => 'List name';

  @override
  String get prefListTitleRequired => 'List name is required';

  @override
  String get prefListTitleHint => 'E.g. My 2025 STEM Preferences';

  @override
  String get prefListNameIdeasLabel => 'Quick names';

  @override
  String prefListNameIdeaTyped(String type) {
    return 'My $type Plan';
  }

  @override
  String get prefListNameIdeaMain => 'My Main Plan';

  @override
  String get prefListNameIdeaBackup => 'Backup Plan';

  @override
  String get prefListNameIdeaDream => 'My Dreams';

  @override
  String get prefListDescriptionLabel => 'Description (optional)';

  @override
  String get prefListDescriptionHint => 'A short note about this list…';

  @override
  String get prefListPublicTitle => 'Public';

  @override
  String get prefListPublicCreateSubtitle =>
      'Anyone with the link can view the list';

  @override
  String get prefListPublicShareSubtitle =>
      'Anyone with the link can view your list';

  @override
  String get prefListCreateButton => 'Create List';

  @override
  String get prefListShareTitle => 'Share List';

  @override
  String get prefListLinkCopied => 'Link copied';

  @override
  String get prefListShareLinkButton => 'Share Link';

  @override
  String prefListViewCount(int count) {
    return '$count views';
  }

  @override
  String get prefListPrivateNotice =>
      'Your list is private right now. Turn on the switch above to share it.';

  @override
  String prefListShareTextHeader(String title) {
    return 'I shared my \"$title\" preference list 🎓';
  }

  @override
  String prefListShareTextExtra(int count) {
    return '…and $count more departments';
  }

  @override
  String get prefListDuplicateDepartment =>
      'This department is already in the list';

  @override
  String prefListMaxItems(int max) {
    return 'A list can contain at most $max choices';
  }

  @override
  String prefListSaveError(String error) {
    return 'Save error: $error';
  }

  @override
  String get prefListDeleted => 'Preference list deleted';

  @override
  String prefListDeleteError(String error) {
    return 'Delete error: $error';
  }

  @override
  String get prefListNotFound => 'List not found.';

  @override
  String prefListFullLimit(int max) {
    return 'Limit reached ($max)';
  }

  @override
  String get prefListAddDepartment => 'Add Department';

  @override
  String get prefListUndo => 'Undo';

  @override
  String prefListsSummary(int lists, int items) {
    return '$lists lists · $items picks';
  }

  @override
  String get prefListEmptyItemsTitle => 'This list is still empty';

  @override
  String prefListEmptyItemsDesc(int max) {
    return 'You get $max choices in the placement. Shall we add the first one?';
  }

  @override
  String get prefDeptSelectUniversity => 'Select University';

  @override
  String get prefDeptSelectDepartment => 'Select Department';

  @override
  String get prefDeptSearchUniversity => 'Search university…';

  @override
  String get prefDeptSearchDepartment => 'Search department…';

  @override
  String get prefNoSearchResults => 'No results found';

  @override
  String get prefNoSearchResultsDesc => 'Try a different search.';

  @override
  String get prefNoDepartmentsTitle => 'No departments found';

  @override
  String get prefNoDepartmentsDesc =>
      'There are no registered departments for this university.';

  @override
  String prefDeptUniversitiesWithDepartment(String department) {
    return 'Universities with $department';
  }

  @override
  String get prefDeptNoUniversityForDepartment =>
      'No university found with this department';

  @override
  String prefDeptNoOtherUniversityForDepartment(String department) {
    return 'There is no other university with \"$department\".';
  }

  @override
  String get prefBaseScoreShort => 'Base';

  @override
  String get prefSharedListLoadError => 'Failed to load list';

  @override
  String get prefSharedListBadge => 'Shared List';

  @override
  String get prefSharedListOwner => 'List owner';

  @override
  String get prefSharedListEmptyDesc =>
      'There are no preferences in this list yet.';

  @override
  String get prefSharedListHiddenOrDeleted =>
      'This list may have been deleted or marked private.';

  @override
  String get prefSharedListBackHome => 'Back to Home';

  @override
  String get prefSharedReadOnlyNotice =>
      'You are viewing this list in read-only mode.';

  @override
  String get prefSharedCopyButton => 'Copy to My Lists & Edit';

  @override
  String get prefSharedCopySuccess =>
      'List copied to your account! You can now edit it.';

  @override
  String get prefSharedCopyOwnList => 'This list already belongs to you.';

  @override
  String get prefSharedEditOwnList => 'Edit Your List';

  @override
  String get prefSharedCopyPaywallTitle => 'Copying is a Plus Feature';

  @override
  String get prefSharedCopyPaywallDesc =>
      'You can view this list. Copying it to your account and editing requires a Plus or Pro membership. Copying never changes the owner\'s list — you get your own independent copy.';

  @override
  String get prefSharedCopyPaywallButton => 'See Plans';

  @override
  String get comparisonHubSubtitle =>
      'What type of comparison do you want to make?';

  @override
  String get comparisonHistoryTitle => 'Comparison History';

  @override
  String get comparisonHistoryTooltip => 'Comparison history';

  @override
  String get comparisonEntityUniversity => 'University';

  @override
  String get comparisonEntityDepartment => 'Department';

  @override
  String get comparisonEntityCity => 'City';

  @override
  String get comparisonSubscriptionLabel => 'Your plan';

  @override
  String get subscriptionFree => 'Free';

  @override
  String get comparisonUpgradePlus => 'Upgrade to Plus';

  @override
  String get comparisonResetTitle => 'Reset Comparison';

  @override
  String get comparisonResetConfirm =>
      'Reset the current comparison? You can choose new universities.';

  @override
  String get comparisonAddThirdTooltip => 'Add 3rd university (Pro)';

  @override
  String get comparisonRemoveThirdTooltip => 'Remove 3rd university';

  @override
  String get comparisonEmptyUniversityTitle => 'Select two universities';

  @override
  String get comparisonEmptyUniversityDesc =>
      'Once you choose two universities above, comparison results will appear here.';

  @override
  String get comparisonNotesTab => 'My Notes';

  @override
  String get comparisonNotesTabShort => 'Notes';

  @override
  String get comparisonTabGeneralShort => 'Gen';

  @override
  String get comparisonTabCategoriesShort => 'Cat';

  @override
  String get comparisonTabChartShort => 'Chart';

  @override
  String get comparisonTabStatsShort => 'Stats';

  @override
  String get comparisonSummaryTitle => 'Comparison Summary';

  @override
  String comparisonWinnerCategories(String winnerName, int wins, int total) {
    return '🏆 $winnerName leads in $wins/$total categories';
  }

  @override
  String get comparisonQuickDepartments => 'Departments';

  @override
  String get comparisonQuickPlaces => 'Places';

  @override
  String get comparisonQuickReviews => 'Reviews';

  @override
  String reviewCountShort(int count) {
    return '$count reviews';
  }

  @override
  String get comparisonCategoriesEmptyTitle => 'Not enough ratings';

  @override
  String get comparisonCategoriesEmptyDesc =>
      'There are not enough reviews to calculate category scores for these two universities yet.';

  @override
  String get comparisonChartEmptyTitle =>
      'Reviews are required to generate charts';

  @override
  String get comparisonChartEmptyDesc =>
      'Charts appear empty because there are not enough ratings yet.';

  @override
  String get comparisonChartHintTitle => 'New: Pro comparison charts';

  @override
  String get comparisonChartHintBody =>
      'Discover radar, heat map and trend charts in the Chart tab.';

  @override
  String get comparisonChartHintCta => 'Show me';

  @override
  String get comparisonUniversityPickerTitle => 'Compare Universities';

  @override
  String get comparisonUniversityPickerSubtitle =>
      'Select two universities to compare. Scores, categories, and statistics will appear side by side.';

  @override
  String get comparisonTripleHint =>
      'With Pro, you can add a 3rd university for a three-way comparison.';

  @override
  String get comparisonSelectUniversityForA => 'Select university for A';

  @override
  String get comparisonSelectUniversityForB => 'Select university for B';

  @override
  String get comparisonDepartmentHeaderTitle => 'Compare Departments';

  @override
  String get comparisonDepartmentHeaderSubtitle =>
      'Compare the same department at two different universities. Base score, ranking, and quota appear side by side.';

  @override
  String get comparisonDepartmentHint =>
      'Once you select one department on each side, comparison results will appear here.';

  @override
  String get comparisonCityHeaderTitle => 'Compare Cities';

  @override
  String get comparisonCityHeaderSubtitle =>
      'Compare the university ecosystem of two cities. State/foundation distribution, university count, and more.';

  @override
  String get comparisonCityHint =>
      'Once you select two cities, comparison results will appear here.';

  @override
  String get comparisonSelectCity => 'Select City';

  @override
  String get comparisonSearchCity => 'Search city…';

  @override
  String comparisonCityTileMeta(String plate, int count) {
    return 'Plate: $plate • Univ: $count';
  }

  @override
  String get comparisonResultNotFound => 'Result not found.';

  @override
  String get comparisonScoreTypeMismatch =>
      'The score types appear to be different. The comparison may be misleading.';

  @override
  String get comparisonBaseScore2025 => 'Base Score (2025)';

  @override
  String get comparisonDetailedInfo => 'Detailed Information';

  @override
  String get comparisonFaculty => 'Faculty';

  @override
  String get comparisonRankingTitle => 'Ranking';

  @override
  String get comparisonNoDataLower => 'no data';

  @override
  String get comparisonUniversityCount => 'University Count';

  @override
  String get comparisonStateFoundationDistribution =>
      'State / Foundation Distribution';

  @override
  String get comparisonPopulation => 'Population';

  @override
  String get comparisonCityFeatures => 'City Details';

  @override
  String get comparisonPlate => 'Plate';

  @override
  String get comparisonTotalUniversities => 'Total Univ.';

  @override
  String get comparisonInUniSec => 'In ÜniSeç';

  @override
  String get comparisonProNotesTitle => 'Comparison Notes';

  @override
  String get comparisonProNotesSubtitleLoggedIn =>
      'A premium experience for Pro members is waiting for you!';

  @override
  String get comparisonProNotesSubtitleGuest =>
      'Sign in and become a Pro member to unlock this feature!';

  @override
  String get comparisonProNotesFeaturePersonal =>
      'Add personal notes to every comparison';

  @override
  String get comparisonProNotesFeatureProsCons =>
      'Analyze in detail with pros and cons';

  @override
  String get comparisonProNotesFeatureRating =>
      'Sort with a 1-5 star preference score';

  @override
  String get comparisonProNotesFeatureCloud =>
      'Your notes are safe in the cloud — never lost';

  @override
  String get comparisonProNotesUpgrade => 'Upgrade to Pro';

  @override
  String get comparisonProNotesLoginAndPro => 'Sign In and Go Pro';

  @override
  String get comparisonSkipForNow => 'Skip for now';

  @override
  String get comparisonHistoryClearTooltip => 'Clear history';

  @override
  String get comparisonHistoryClearTitle => 'Clear History';

  @override
  String get comparisonHistoryClearConfirm => 'Delete all comparison history?';

  @override
  String get comparisonHistoryClearButton => 'Clear';

  @override
  String comparisonHistoryLoadError(String error) {
    return 'Failed to load history: $error';
  }

  @override
  String get comparisonHistoryEmptyTitle => 'No comparisons yet';

  @override
  String get comparisonHistoryEmptyDesc =>
      'Your first comparison will appear here.';

  @override
  String get comparisonHistoryPaywallTitle =>
      'Comparison History is in Plus / Pro';

  @override
  String get comparisonHistoryPaywallDesc =>
      'Save your comparisons automatically and reopen them whenever you want.';

  @override
  String get comparisonHistoryPaywallButton => 'Upgrade to Plus / Pro';

  @override
  String get comparisonHistoryFeatureRecent =>
      'The last 20 comparisons are saved automatically';

  @override
  String get comparisonHistoryFeatureReturn =>
      'Return to the same comparison with one tap';

  @override
  String get comparisonHistoryFeatureSync => 'Sync across devices';

  @override
  String get comparisonTripleCategoryTitle => 'Category Comparison';

  @override
  String get comparisonLeader => 'LEADER';

  @override
  String get noteEditTitle => 'Edit Note';

  @override
  String get noteAddTitle => 'Add Note';

  @override
  String get noteSubtitle => 'Save your thoughts about this comparison';

  @override
  String get notePreferenceRating => 'Your Preference Rating';

  @override
  String get noteLabel => 'Note';

  @override
  String get noteHint => 'E.g. ITU is closer to me, the campus is beautiful...';

  @override
  String get noteEmptyError => 'Note cannot be empty';

  @override
  String get noteProsLabel => 'Pros';

  @override
  String get noteConsLabel => 'Cons';

  @override
  String get noteAddProHint => 'Add a new pro...';

  @override
  String get noteAddConHint => 'Add a new con...';

  @override
  String get noteUpdate => 'Update';

  @override
  String get noteMyNotes => 'My Notes';

  @override
  String get noteLoadError => 'Failed to load notes.';

  @override
  String get noteSavedSnack => 'Note saved ✍️';

  @override
  String get noteUpdatedSnack => 'Note updated ✅';

  @override
  String get noteDeletedSnack => 'Note deleted';

  @override
  String get noteDeleteTitle => 'Delete Note';

  @override
  String get noteDeleteConfirm =>
      'This note will be permanently deleted. Continue?';

  @override
  String get noteEmptyState => 'No notes yet';

  @override
  String get noteEmptyStateDesc => 'Save your thoughts about this comparison';

  @override
  String get noteTimeJustNow => 'Just now';

  @override
  String noteTimeMinutesAgo(int minutes) {
    return '$minutes min ago';
  }

  @override
  String noteTimeHoursAgo(int hours) {
    return '$hours hours ago';
  }

  @override
  String noteTimeDaysAgo(int days) {
    return '$days days ago';
  }

  @override
  String noteTimeWeeksAgo(int weeks) {
    return '$weeks weeks ago';
  }

  @override
  String get plusLockSubtitle => 'Unlock with Plus or Pro';

  @override
  String get plusLockButton => 'Upgrade to Plus';

  @override
  String get comparisonNoData => 'No data';

  @override
  String get trendNoData => 'No trend data';

  @override
  String get shareInstagramStory => 'Instagram Story (9:16)';

  @override
  String get shareInstagramPost => 'Instagram Post (1:1)';

  @override
  String get shareTwitterWhatsApp => 'Twitter / WhatsApp';

  @override
  String get yearlyTableYear => 'Year';

  @override
  String loadFailed(String error) {
    return 'Failed to load: $error';
  }

  @override
  String get favoriteLoginRequired => 'Sign in to add favorites.';

  @override
  String get yearlyComparisonTitle => 'Year-by-Year Comparison';

  @override
  String get yearlyDifference => 'Diff';

  @override
  String rankFormat(String rank) {
    return '${rank}th place';
  }

  @override
  String get rankNotAnnounced => 'Rank: Not announced';

  @override
  String get shareStatAvgBase => 'Avg. Base';

  @override
  String get shareStatDepartment => 'Dept.';

  @override
  String get shareStatPlace => 'Place';

  @override
  String get shareFormat => 'Share Format';

  @override
  String get comparisonSubtitle => 'Compare universities side by side';

  @override
  String get comparisonSwapTooltip => 'Swap';

  @override
  String comparisonError(String error) {
    return 'Error: $error';
  }

  @override
  String get adGateTitleGuest => 'Compare with Ad';

  @override
  String get adGateTitleUser => 'Free quota used up';

  @override
  String get adGateDescGuest =>
      'You need to watch a short ad to compare. Sign in or upgrade to Plus for unlimited comparisons.';

  @override
  String get adGateDescUser =>
      'You\'ve used your 1 free daily comparison. Watch a short ad to continue or upgrade to Plus for unlimited comparisons.';

  @override
  String get adGateWatchBusy => 'Loading ad…';

  @override
  String get adGateWatchCta => 'Watch Ad & Continue';

  @override
  String get adGatePlusCta => 'Upgrade to Plus — Unlimited';

  @override
  String get adGateDismiss => 'Not now';

  @override
  String get adGateOverlayTitleGuest => 'Watch an ad to continue';

  @override
  String get adGateOverlayTitleUser => 'Unlock to continue';

  @override
  String get adGateOverlayDescGuest =>
      'You need to watch a short ad to compare.';

  @override
  String get adGateOverlayDescUser => 'Your daily comparison quota is used up.';

  @override
  String get adGateOverlayBusy => 'Loading…';

  @override
  String get adGateOverlayCta => 'Watch Ad / Upgrade to Plus';

  @override
  String get favoritesAddTitle => 'Add to favorites';

  @override
  String get actionBarShare => 'Share';

  @override
  String get actionBarFavorite => 'Favorite';

  @override
  String get actionBarRecompare => 'Redo';

  @override
  String get emptyStateSelectTwo => 'Select two universities';

  @override
  String get emptyStateSelectTwoDesc =>
      'Select two universities above to see comparison results here.';

  @override
  String get triplePickerTitle => 'Select 3rd university';

  @override
  String get triplePickerSearchHint => 'Search university…';

  @override
  String get triplePickerNoResult => 'No results found';

  @override
  String get sectionCategoryScores => 'Category Scores';

  @override
  String get sectionOverview => 'Overview';

  @override
  String get sectionStats => 'General Statistics';

  @override
  String get noReviewsTitle => 'Not enough reviews';

  @override
  String get noReviewsDesc =>
      'There are not enough reviews yet to generate category scores for these two universities.';

  @override
  String get commonReset => 'Reset';

  @override
  String get prefListsOthersHeading => 'YOUR OTHER LISTS';

  @override
  String get prefListsMainBadge => 'MAIN LIST';

  @override
  String get prefListsOpen => 'Open list';

  @override
  String prefListsSlotsFree(int count) {
    return '$count slots free';
  }

  @override
  String get prefListsEmptyHeroTitle => 'Let\'s build your list together';

  @override
  String get prefListsEmptyHeroDesc =>
      'I\'ll draft a balanced set from the programs within your reach; you drop the ones you don\'t want.';

  @override
  String get prefListsEmptyDraftCta => 'Let Üni draft it';

  @override
  String get prefListsEmptyBlankCta => 'Create an empty list';

  @override
  String get prefListOptions => 'Options';

  @override
  String get prefListSaving => 'Saving';

  @override
  String get prefListUndoAction => 'UNDO';

  @override
  String get prefListOrderUpdated => 'Order updated';

  @override
  String prefListItemRemoved(String name) {
    return '$name removed from the list';
  }

  @override
  String get prefListSortedByRisk => 'Sorted from reach to safe';

  @override
  String get prefListSortWithUni => 'Let Üni order it';

  @override
  String get prefListPinAction => 'Make it my main list';

  @override
  String get prefListPinDesc => 'Always on top, the first thing you see';

  @override
  String get prefListUnpinAction => 'Unpin';

  @override
  String get prefListUnpinDesc => 'It will no longer be kept on top';

  @override
  String get prefListShareLink => 'Share link';

  @override
  String get prefListShareImage => 'Create image';

  @override
  String get prefListShareImageDesc => 'A shareable summary card';

  @override
  String get prefListRenameAction => 'Rename';

  @override
  String get prefListRenameDesc => 'Edit the name and description';

  @override
  String get prefListRenameTitle => 'Rename list';

  @override
  String get prefListUpdated => 'List updated';

  @override
  String get prefListDuplicateAction => 'Duplicate';

  @override
  String get prefListDuplicateDesc => 'A second copy with the same choices';

  @override
  String get prefListDuplicated => 'List duplicated';

  @override
  String get prefListCopySuffix => 'copy';

  @override
  String get prefListDeleteUndoDesc => 'You get a few seconds to undo';

  @override
  String prefListDeletedNamed(String title) {
    return '“$title” deleted';
  }

  @override
  String get prefListRestoreFailed => 'The list could not be restored';

  @override
  String get prefListBandSafe => 'safe';

  @override
  String get prefListBandTarget => 'match';

  @override
  String get prefListBandReach => 'reach';

  @override
  String prefListUnrated(int count) {
    return '+$count not rated';
  }

  @override
  String get prefListBalanceInvite =>
      'Calculate your score and I\'ll rate your list';

  @override
  String get prefListShareCardHeading => 'MY PREFERENCE LIST';

  @override
  String prefListShareCardCount(int filled, int max) {
    return '$filled/$max choices';
  }

  @override
  String prefListShareCardBandSafe(int count) {
    return '$count safe';
  }

  @override
  String prefListShareCardBandReach(int count) {
    return '$count reach';
  }

  @override
  String prefListShareCardMore(int count) {
    return 'and $count more…';
  }

  @override
  String prefListShareCardText(String title, int filled, int max) {
    return '$title — $filled/$max choices | ÜniSeç';
  }

  @override
  String get cmpGroupNumbers => 'By the numbers';

  @override
  String get cmpGroupReviews => 'Student ratings';

  @override
  String get cmpGroupPlacement => 'Placement data';

  @override
  String get cmpRowDepartments => 'Departments';

  @override
  String get cmpRowUndergrad => 'Bachelor\'s programs';

  @override
  String get cmpRowAssociate => 'Associate programs';

  @override
  String get cmpRowAvgBase => 'Average base score';

  @override
  String get cmpRowQuota => 'Places';

  @override
  String get cmpRowFillRate => 'Fill rate';

  @override
  String get cmpRowPlaces => 'Venues nearby';

  @override
  String get cmpRowType => 'Type';

  @override
  String get cmpRowFounded => 'Founded';

  @override
  String get cmpRowRating => 'Student rating';

  @override
  String get cmpRowReviews => 'Reviews';

  @override
  String get cmpRowBaseScore => 'Base score';

  @override
  String get cmpRowRanking => 'Success rank';

  @override
  String get cmpRowScoreType => 'Score type';

  @override
  String get cmpRowDuration => 'Duration';

  @override
  String get cmpRowUniCount => 'Universities';

  @override
  String get cmpRowStateUni => 'State universities';

  @override
  String get cmpRowFoundationUni => 'Foundation universities';

  @override
  String get cmpRowDensity => 'University density';

  @override
  String get cmpRowPopulation => 'Population';

  @override
  String get cmpRowAvgReviews => 'Reviews per university';

  @override
  String get cmpHintLastYear => '2025 data';

  @override
  String get cmpHintPerMillion => 'per million people';

  @override
  String get cmpReviewsEmpty =>
      'No student ratings for these two yet. This fills in as reviews arrive.';

  @override
  String get cmpNoRows => 'No shared data to compare.';

  @override
  String cmpVerdictAhead(String name, String count) {
    return '$name leads on $count';
  }

  @override
  String cmpVerdictTiedOnly(String count) {
    return 'Level on $count measures';
  }

  @override
  String cmpVerdictTiedSuffix(String count) {
    return '$count level';
  }

  @override
  String get cmpChangeSide => 'Change';

  @override
  String get cmpSwap => 'Swap sides';

  @override
  String get cmpChartsTitle => 'Charts';

  @override
  String get cmpHighlightsTitle => 'Biggest differences';

  @override
  String get cmpMoreTitle => 'More';

  @override
  String get cmpChartsDesc => 'Radar, heat map, trend and scatter';

  @override
  String get cmpChartsOpen => 'View charts';

  @override
  String get cmpPersonalTitle => 'For you';

  @override
  String cmpPersonalBody(String a, String countA, String b, String countB) {
    return '$countA departments at $a and $countB at $b match your score.';
  }

  @override
  String cmpPersonalTop(String name, String dept) {
    return 'Highest at $name: $dept';
  }

  @override
  String get cmpPersonalNoProfile =>
      'Calculate your score and I\'ll tell you how many departments match at each.';

  @override
  String get cmpPersonalNone =>
      'I couldn\'t find a department matching your score at either one.';

  @override
  String get cmpPersonalCta => 'Calculate your score';

  @override
  String get cmpAddToList => 'Add the matching ones to my list';

  @override
  String get cmpAddSheetTitle => 'Going into your list';

  @override
  String get cmpAddSheetDesc =>
      'I picked the programs that match your score. Drop the ones you don\'t want and I\'ll add the rest in one go.';

  @override
  String cmpAddSelectedCta(String count) {
    return 'Add $count choices';
  }

  @override
  String get cmpAddNoList => 'Create a preference list first.';

  @override
  String cmpAddedToList(String count, String title) {
    return '$count choices added to $title';
  }

  @override
  String get cmpHubRecentTitle => 'YOUR RECENT COMPARISONS';

  @override
  String get cmpHubRecentEmpty => 'Your first comparison will show up here.';

  @override
  String get cmpHubSeeAll => 'All';

  @override
  String cmpYears(String count) {
    return '$count years';
  }

  @override
  String cmpCityPlate(String plate) {
    return 'Plate $plate';
  }

  @override
  String get citiesTitle => 'Explore Cities';

  @override
  String citiesHeroSubtitle(String cities, String universities) {
    return '$cities cities · $universities universities';
  }

  @override
  String get citiesSearchHint => 'Search city or plate code…';

  @override
  String get citiesSearchClear => 'Clear search';

  @override
  String get citiesFilterAll => 'All';

  @override
  String get citiesRegionMarmara => 'Marmara';

  @override
  String get citiesRegionAegean => 'Aegean';

  @override
  String get citiesRegionMediterranean => 'Mediterranean';

  @override
  String get citiesRegionCentral => 'Central Anatolia';

  @override
  String get citiesRegionBlackSea => 'Black Sea';

  @override
  String get citiesRegionEastern => 'Eastern Anatolia';

  @override
  String get citiesRegionSoutheastern => 'Southeastern Anatolia';

  @override
  String get citiesSortTitle => 'Sort';

  @override
  String get citiesSortUniversities => 'University count';

  @override
  String get citiesSortAlphabetical => 'A to Z';

  @override
  String get citiesSortPopulation => 'Population';

  @override
  String citiesUniShort(String count) {
    return '$count uni';
  }

  @override
  String citiesPopulationLabel(String value) {
    return '$value people';
  }

  @override
  String get citiesEmptyTitle => 'No cities found';

  @override
  String get citiesClearFilters => 'Clear filters';

  @override
  String get cmpPickTapToSelect => 'Tap to select';

  @override
  String get cmpPickStart => 'Pick one to get started';

  @override
  String cmpPickNext(String label) {
    return 'Next: $label';
  }

  @override
  String get cmpPickSuggestUniversity => 'POPULAR UNIVERSITIES';

  @override
  String get cmpPickSuggestCity => 'CITIES WITH THE MOST UNIVERSITIES';

  @override
  String get cmpPickSuggestDepartment => 'WIDELY OFFERED PROGRAMS';

  @override
  String get cmpPickSuggestHint => 'Tap one and it fills the empty side.';

  @override
  String cmpPickUniCount(String count) {
    return '$count uni';
  }
}
