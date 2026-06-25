# ÜniSeç — Kapsamlı Gizlilik ve Güvenlik Politikası

Bu belge, **ÜniSeç — Üniversite Yaşam Rehberi** uygulamasının kullanıcı verilerini nasıl topladığını, işlediğini, sakladığını ve en üst düzey güvenlik standartlarıyla nasıl koruduğunu detaylandıran şeffaf bir manifestodur. 

Uygulamanın kaynak kodları, veritabanı kuralları ve mimarisi temel alınarak "Privacy by Design" (Tasarım Aşamasında Gizlilik) ve "Security by Default" (Varsayılan Olarak Güvenlik) prensipleriyle oluşturulmuştur.

---

## BÖLÜM 1: GİZLİLİK POLİTİKASI (Kişisel Verilerin İşlenmesi)

Uygulamamız, veri minimizasyonu ilkesini benimseyerek sadece hizmetin kalitesini artırmak için zorunlu olan verileri toplar. Toplanan veriler ve işlenme amaçları sistem mimarisine göre aşağıda sınıflandırılmıştır:

### 1.1. Toplanan Kullanıcı Profil Verileri
Firebase Authentication ve Cloud Firestore altyapısı üzerinden aşağıdaki profil verileriniz toplanır:
- **Kimlik ve Profil Verileri:** Tam ad (`displayName`), E-posta adresi (`email`), Profil fotoğrafı URL'si (`photoUrl`), Biyografi (`bio`).
- **Akademik Veriler:** Onaylı öğrenci durumu (`isVerifiedStudent`), Üniversite adı ve ID'si (`university`, `universityId`), Bölüm (`department`), Sınıf (`grade`).
- **Kullanım Verileri:** Son giriş tarihi (`lastLoginAt`), Hesap oluşturma tarihi (`createdAt`), Bildirim tercihleri (`notificationPrefs`).

### 1.2. Kullanıcı Tarafından Üretilen İçerikler (UGC)
- **Yorumlar ve Değerlendirmeler:** Üniversiteler, bölümler ve mekanlar hakkında yapılan yorumlar, puanlamalar, avantajlar (`pros`), dezavantajlar (`cons`) ve yüklenen görseller (`imageUrls`). *Not: Kullanıcılar yorumlarını `isAnonymous: true` bayrağı ile tamamen anonim ("Anonim Öğrenci") olarak yapma hakkına sahiptir.*
- **Tercih Listeleri (`preferenceLists`):** Kullanıcıların oluşturduğu tercih listeleri (halka açık veya gizli), liste görüntülenme sayıları ve paylaşılan özel linkler (`shareSlug`).
- **Karşılaştırma Geçmişi ve Notları:** **Plus ve Pro** abonelerimizin yaptığı yapay zeka destekli karşılaştırma kayıtları (`comparisonHistory`) ve bu karşılaştırmalara ekledikleri özel notlar (`comparisonNotes`). Bu veriler *yalnızca kullanıcının kendisine* açıktır.
- **Mekan Önerileri ve Geri Bildirimler:** Sisteme eklenmesi için önerilen mekanlar, mekan fotoğrafları ve uygulama içi geri bildirim raporları.

### 1.3. Cihaz, Konum ve Analitik Verileri
- **Cihaz ve Platform Verileri:** Firebase Analytics ve Crashlytics aracılığıyla cihaz modeli, işletim sistemi versiyonu, hata logları (crash logs) ve uygulama içi davranış metrikleri.
- **Push Bildirim Cihaz Token'ları (`fcmTokens`):** Kullanıcılara özel bildirim gönderebilmek adına Firebase Cloud Messaging (FCM) platform tokenları şifreli şekilde saklanır.
- **Konum Verileri:** Harita ve mekan özellikleri (`flutter_map` ve `latlong2`) kullanılırken cihazın anlık konumu (sadece izin verildiğinde ve uygulama açıkken) işlenir, sunucularda kalıcı olarak tutulmaz.

### 1.4. Üçüncü Taraf Entegrasyonları ve Veri Paylaşımı
- **Satın Alımlar (RevenueCat):** Uygulama içi satın alımlar (Plus/Pro abonelikleri) `purchases_flutter` (RevenueCat) üzerinden anonim ID'ler ile yönetilir. Ödeme bilgileri, kredi kartı verileri **kesinlikle** sunucularımızda saklanmaz, doğrudan Apple App Store veya Google Play Store tarafından işlenir.
- **Reklam Sağlayıcıları:** Ücretsiz sürüm kullanıcıları için `google_mobile_ads` entegrasyonu mevcuttur. Google AdMob, kişiselleştirilmiş reklamlar sunmak amacıyla reklam kimliklerini (IDFA/AAID) kullanabilir.
- **Yapay Zeka (AI Summary):** Yapay zeka ile özetleme ve karşılaştırma özellikleri (`aiSummaryLogs`, `aiSummaryCache`) kullanılırken, kullanıcıların kişisel kimlik verileri (PII) yapay zeka modelleriyle **paylaşılmaz**. Tüm süreç anonimleştirilmiş sorgular üzerinden çalışır.

---

## BÖLÜM 2: GÜVENLİK POLİTİKASI (Sistem Mimarisi ve Koruma)

Uygulamamızın veritabanı (Firestore) ve depolama (Cloud Storage) katmanları, "Sıfır Güven" (Zero Trust) felsefesiyle inşa edilmiş güvenlik kurallarıyla korunmaktadır.

### 2.1. Cloud Firestore Güvenlik Kuralları Katmanı (RBAC)
- **Kullanıcı İzolasyonu (`isOwner` pattern):** Kullanıcıların özel verileri (hesap ayarları, karşılaştırma geçmişi, özel notlar, favoriler, bildirimler), `request.auth.uid == userId` kuralı ile **sadece ve sadece** verinin sahibinin okuma ve yazma yetkisine açık olacak şekilde kilitlenmiştir.
- **Rol Tabanlı Erişim Kontrolü (RBAC):** Admin yetkileri (`request.auth.token.admin == true`), şehirler, üniversiteler, bölümler, mekanlar, şüpheli aktivite logları ve admin paneline sıkı sıkıya bağlıdır. Yetkisiz erişimler veritabanı seviyesinde reddedilir.
- **Sıkı Veri Validasyonu (Schema Enforcement):** 
  - Veritabanına yazılacak tüm veriler karakter, tip ve boyut limitlerine tabidir. Örneğin bir yorum (review) yazıldığında; puanın 1-5 arasında olması (`rating >= 1 && rating <= 5`), yorum metninin en az 20, en fazla 500 karakter olması, fotoğraf sayısının maksimum 3 ile sınırlı olması (`imageUrls.size() <= 3`) kurallarla (Firestore Rules) zorunlu kılınmıştır.
  - Sadece izin verilen alanların (`affectedKeys().hasOnly([...])`) güncellenmesine izin verilir. Bu durum, "Kullanıcı kendini Admin yapabilir mi?" gibi veri sızdırma (Payload Injection) ataklarını teknik olarak imkansız kılar.
- **Rate Limiting ve Kotalar:** Kullanım istatistikleri (`usageStats`) her güncelendiğinde matematiksel olarak doğrulanır (Ör: `dailyComparisons == resource.data.dailyComparisons + 1`). Hileli kullanım veya AI endpoint'lerini suistimal etme (DDoS) denemeleri engellenmiştir.

### 2.2. Cloud Storage (Dosya Depolama) Güvenlik Katmanı
Uygulamaya yüklenen tüm medya dosyaları için Firebase Storage rules uygulanmaktadır:
- **Dosya Tipi Kontrolü (MIME Type Validation):** Kullanıcıların profil fotoğrafları veya yorum fotoğrafları yükleyebilmesi için dosyanın **kesinlikle** bir resim (örn: `image/jpeg`, `image/png`, `image/webp`) olması gerekmektedir. Zararlı yazılım (script, apk, exe vb.) yükleme girişimleri doğrudan engellenir.
- **Dosya Boyutu Sınırları:** Profil fotoğrafları maksimum **5 MB**, yorum görselleri ve mekan öneri görselleri maksimum **10 MB** ile sınırlandırılmıştır (`request.resource.size < 5 * 1024 * 1024`).
- **Dosya Adı Doğrulama:** Depolama alanındaki dizin kirliliğini ve LFI ataklarını önlemek için, dosya isimleri zorunlu Regular Expression (Regex) kurallarına tabidir (Ör: `^[A-Za-z0-9_-]+\\.jpg$`).

### 2.3. Platform Seviyesinde Güvenlik Önlemleri
- **Firebase App Check:** Uygulama, tersine mühendisliği ve sahte cihaz/sunucu isteklerini (Botnet, API Abuse) engellemek için `firebase_app_check` modülünü kullanır. Uygulama dışından sunucularımıza yapılan hiçbir API isteği kabul edilmez.
- **Sunucu Taraflı (Server-side) İşlemler:** Kullanıcı kayıtları sonrası istatistiklerin artırılması, webhook eventlerinin yönetimi ve riskli işlemler yalnızca Google Cloud Functions üzerinden "Admin" yetkisiyle izole bir ortamda işlenir. Kullanıcıların (Client) bu webhook alanlarına okuma/yazma erişimi **yoktur** (`allow read, write: if false;`).
- **Statik Analiz ve Kalite:** Uygulama mimarisi `flutter_lints`, `custom_lint` ve `riverpod_lint` gibi statik kod analiz araçlarıyla sürekli taranarak bellek sızıntıları ve potansiyel zafiyetlere karşı güvence altına alınmıştır.

---

### 2.4. Kullanıcı Hakları ve Veri Silme Politikası
- **Hesap Silme Hakkı:** Kullanıcılar, uygulama içi ayarlar üzerinden hesaplarını sildiklerinde, Firestore üzerindeki onlara ait profil verileri, favoriler ve token'lar veritabanından kalıcı olarak silinir veya anonimleştirilir.
- **Anonimlik Hakkı:** Yorum yaparken "Anonim" seçeneğini işaretleyen kullanıcıların gerçek adları veya fotoğrafları **veritabanına yazılmaz** ve diğer kullanıcılarla paylaşılmaz. Güvenlik kuralı gereği anonim yorumlarda zorunlu olarak ad "Anonim Öğrenci" olmak zorundadır.

ÜniSeç, kullanıcı verilerinin mahremiyetine ve güvenliğine en az eğitim ve kariyer yolculuğunuz kadar önem vermektedir. Tüm mimari bu vizyonla tasarlanmıştır.
