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
  String get homeTabExplore => 'Explore';

  @override
  String get homeTabCompare => 'Compare';

  @override
  String get homeTabFavorites => 'Favorites';

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
  String get favoritesEmpty => 'No favorites';

  @override
  String get favoritesEmptyHint => 'Track universities you like here.';
}
