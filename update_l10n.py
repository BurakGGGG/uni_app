import json

with open('lib/l10n/app_tr.arb', 'r', encoding='utf-8') as f:
    tr_data = json.load(f)

with open('lib/l10n/app_en.arb', 'r', encoding='utf-8') as f:
    en_data = json.load(f)

snippet_tr = {
  "commonRetry": "Tekrar dene",
  "commonError": "Bir hata oluştu",
  "commonLoading": "Yükleniyor...",
  "commonCancel": "İptal",
  "commonSave": "Kaydet",
  "commonDelete": "Sil",
  "commonClose": "Kapat",
  "commonShare": "Paylaş",
  "commonEdit": "Düzenle",
  "commonContinue": "Devam et",
  "authSignIn": "Giriş yap",
  "authSignUp": "Kayıt ol",
  "authSignOut": "Çıkış yap",
  "authForgotPassword": "Şifremi unuttum",
  "authEmailLabel": "E-posta",
  "authPasswordLabel": "Şifre",
  "authPasswordTooShort": "Şifre en az 6 karakter olmalı",
  "authEmailInvalid": "Geçerli bir e-posta gir",
  "homeTabExplore": "Keşfet",
  "homeTabCompare": "Karşılaştır",
  "homeTabFavorites": "Favoriler",
  "homeTabProfile": "Profil",
  "comparisonTitleUni": "Üniversite karşılaştır",
  "comparisonTitleDept": "Bölüm karşılaştır",
  "comparisonTitleCity": "Şehir karşılaştır",
  "comparisonNoteAdd": "Not ekle",
  "comparisonNoteEmpty": "Henüz notun yok",
  "comparisonNoteMaxLength": "En fazla 500 karakter",
  "comparisonProUpsell": "3. üniversite eklemek için Pro'ya yükselt",
  "paywallContinueFree": "Ücretsiz devam et",
  "paywallSavePercent": "TASARRUF {percent}%",
  "paywallMonthly": "Aylık",
  "paywallYearly": "Yıllık",
  "paywallRestore": "Satın alımları geri yükle",
  "reviewWrite": "Yorum yaz",
  "reviewAnonymous": "Anonim",
  "reviewRatingRequired": "Puan vermeden yorum gönderilemez",
  "profileTitle": "Hesabım",
  "profileEditProfile": "Profili düzenle",
  "profilePremium": "Premium üyelik",
  "profileLanguage": "Dil",
  "profileDeleteAccount": "Hesabımı sil",
  "favoritesEmpty": "Favori yok",
  "favoritesEmptyHint": "Beğendiğin üniversiteleri buradan takip et."
}

snippet_en = {
  "commonRetry": "Try again",
  "commonError": "Something went wrong",
  "commonLoading": "Loading...",
  "commonCancel": "Cancel",
  "commonSave": "Save",
  "commonDelete": "Delete",
  "commonClose": "Close",
  "commonShare": "Share",
  "commonEdit": "Edit",
  "commonContinue": "Continue",
  "authSignIn": "Sign in",
  "authSignUp": "Sign up",
  "authSignOut": "Sign out",
  "authForgotPassword": "Forgot password",
  "authEmailLabel": "Email",
  "authPasswordLabel": "Password",
  "authPasswordTooShort": "Password must be at least 6 characters",
  "authEmailInvalid": "Enter a valid email",
  "homeTabExplore": "Explore",
  "homeTabCompare": "Compare",
  "homeTabFavorites": "Favorites",
  "homeTabProfile": "Profile",
  "comparisonTitleUni": "Compare universities",
  "comparisonTitleDept": "Compare departments",
  "comparisonTitleCity": "Compare cities",
  "comparisonNoteAdd": "Add note",
  "comparisonNoteEmpty": "No notes yet",
  "comparisonNoteMaxLength": "Maximum 500 characters",
  "comparisonProUpsell": "Upgrade to Pro to add a 3rd university",
  "paywallContinueFree": "Continue for free",
  "paywallSavePercent": "SAVE {percent}%",
  "paywallMonthly": "Monthly",
  "paywallYearly": "Yearly",
  "paywallRestore": "Restore purchases",
  "reviewWrite": "Write a review",
  "reviewAnonymous": "Anonymous",
  "reviewRatingRequired": "Cannot submit without a rating",
  "profileTitle": "Account",
  "profileEditProfile": "Edit profile",
  "profilePremium": "Premium membership",
  "profileLanguage": "Language",
  "profileDeleteAccount": "Delete account",
  "favoritesEmpty": "No favorites",
  "favoritesEmptyHint": "Track universities you like here."
}

tr_data.update(snippet_tr)
en_data.update(snippet_en)

# Also ensure metadata for paywallSavePercent exists
if "@paywallSavePercent" not in tr_data:
    tr_data["@paywallSavePercent"] = {
      "placeholders": { "percent": { "type": "int" } }
    }
if "@paywallSavePercent" not in en_data:
    en_data["@paywallSavePercent"] = {
      "placeholders": { "percent": { "type": "int" } }
    }

# Find missing keys in EN
missing_in_en = set(tr_data.keys()) - set(en_data.keys())
print("Missing in EN:", missing_in_en)


missing_translations = {
    "reviewLoginRequired": "You must log in to your account first to write a review.",
    "errorPlacesLoad": "An error occurred while loading places.",
    "universityNotFound": "University not found",
    "noDepartmentsFound": "No departments found.",
    "reviewEduRequiredDesc": "Only verified university students can write reviews (.edu.tr).",
    "reviewEduRequiredTitle": "Verification Required",
    "errorDepartmentsLoad": "An error occurred while loading departments.",
    "noPlacesFound": "No places found.",
    "errorGeneral": "Error: {error}",
    "errorReviewsLoad": "An error occurred while loading reviews."
}

en_data.update(missing_translations)

# Copy missing metadata keys
for key in missing_in_en:
    if key.startswith('@'):
        en_data[key] = tr_data[key]

# Save TR back
with open('lib/l10n/app_tr.arb', 'w', encoding='utf-8') as f:
    json.dump(tr_data, f, ensure_ascii=False, indent=2)

# Save EN back
with open('lib/l10n/app_en.arb', 'w', encoding='utf-8') as f:
    json.dump(en_data, f, ensure_ascii=False, indent=2)

