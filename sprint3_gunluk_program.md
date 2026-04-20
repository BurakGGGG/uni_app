# 📅 Sprint 3 — Günlük Çalışma Programı

> **Süre:** 10 iş günü (2 hafta)
> **Ekip:** Kişi A + Kişi B (ilk kez birlikte çalışıyorlar)
> **Günlük aktif çalışma varsayımı:** ~5 saat
> **Hafta sonları:** İzin — planlama hafta içine göre yapıldı

---

## 📑 İçindekiler

1. [Başlamadan Önce: Ön Hazırlık](#-başlamadan-önce-ön-hazırlık)
2. [Günlük Ritüeller](#-günlük-ritüeller)
3. [Git Workflow Rehberi](#-git-workflow-rehberi)
4. [GÜN 1: Senkron & Kick-off](#-gün-1-senkron--kick-off)
5. [GÜN 2: İlk Paralel Çalışma](#-gün-2-ilk-paralel-çalışma)
6. [GÜN 3: Form & Visual Finalize](#-gün-3-form--visual-finalize)
7. [GÜN 4: Checkpoint 1 & Etkileşim](#-gün-4-checkpoint-1--etkileşim)
8. [GÜN 5: Department & Like Sistemi](#-gün-5-department--like-sistemi)
9. [GÜN 6: Edit & Kategori Chart](#-gün-6-edit--kategori-chart)
10. [GÜN 7: Delete & Navigation](#-gün-7-delete--navigation)
11. [GÜN 8: Checkpoint 2 & Şikayet](#-gün-8-checkpoint-2--şikayet)
12. [GÜN 9: Büyük Entegrasyon](#-gün-9-büyük-entegrasyon)
13. [GÜN 10: Polish & Release](#-gün-10-polish--release)
14. [Blocker Protokolü](#-blocker-protokolü)
15. [Sprint Sonu Retrospektifi](#-sprint-sonu-retrospektifi)

---

## 🎬 Başlamadan Önce: Ön Hazırlık

> [!IMPORTANT]
> Bu bölümü Sprint'e başlamadan bir gün önce ya da ilk günün sabahında **ikiniz birlikte** yapın. ~1 saat sürer, sonrası çok daha akıcı geçer.

### 1. İletişim Kanallarını Açın

- **Ana kanal:** WhatsApp grubu / Discord server / Slack — mesaj geçmişi kalıcı olsun
- **Kod paylaşımı:** GitHub repository'ye iki kişinin de push yetkisi olduğundan emin olun
- **Video görüşme:** Günlük kısa toplantılar için Meet / Zoom / Discord link
- **Uzaktan ekran paylaşımı:** Tuck'a girerseniz `tuple.app`, `VS Code Live Share` veya ekran paylaşımlı zoom işe yarar

### 2. Geliştirme Ortamını Senkronize Edin

Her iki tarafta çalıştığından emin olun:

```bash
# Flutter versiyonu
flutter --version  # Aynı olsun, özellikle Flutter 3.x major

# Firebase CLI
firebase --version  # En az 13.x

# Node (Cloud Functions için)
node --version  # En az 20.x

# FlutterFire CLI
dart pub global list | grep flutterfire
```

Farklı Flutter sürümleri farklı `pubspec.lock` üretir ve gereksiz conflict yaratır.

### 3. Firebase Projesine İki Kişi de Bağlansın

```bash
firebase login
firebase projects:list  # unisec-e36e1 görünmeli
firebase use unisec-e36e1
```

Cloud Functions deploy için her iki geliştirici de Firebase IAM'de **Editor** ya da **Cloud Functions Admin** rolüne sahip olmalı. Repo sahibi proje console'dan davet etsin.

### 4. Proje Çalıştığını Doğrulayın

Her iki makinede:

```bash
git pull origin main
flutter pub get
cd functions && npm install && cd ..
flutter run
```

Uygulama açılıp ana sayfa geliyorsa ✅ hazırsınız.

### 5. Rolleri Kesinleştirin

- **Kişi A:** Yazma & yönetim — form, fotoğraf, edit, delete, profile, Cloud Function moderation
- **Kişi B:** Görüntüleme & etkileşim — ReviewCard, like, sort, kategori chart, şikayet, navigation

Bunu şimdi sesli söyleyin, iki taraftan da onay alın. "Evet tamam anlaşıldı" ile sprint başlasın.

---

## 🔁 Günlük Ritüeller

Her gün tekrarlanacak 3 an:

### Sabah: Standup (10-15 dakika)

Video görüşme açın. Sırayla şu 3 soruyu cevaplayın:
1. **Dün ne bitirdim?**
2. **Bugün ne yapmayı planlıyorum?**
3. **Önüme çıkan engel var mı?**

Eğer blocker varsa, sabah standupın son 5 dakikasını bunu çözmeye harcayın. Gereksiz uzatmayın — asıl iş başlasın.

### Öğlen: Kısa Kontrol (Slack/WhatsApp mesajı)

İsteğe bağlı. Sadece ekranında blocker varsa yaz:
> "Kişi B, yazma ekranında fotoğraf Storage'a yüklenmiyor, rules'ta bir sorun olabilir. Akşam bakabilir misin?"

### Akşam: Sync & Merge (20-30 dakika)

Günün sonunda mutlaka buluşun:
1. **Her iki kişi kendi branch'ine push yapar**
2. **Bugün ne bitti göster** (ekran paylaşımı, 5dk)
3. **Yarın ne yapılacak** netleştirin
4. **Blocker'lar:** Birinin görevi diğerinin işini tıkıyor mu? Akşam konuş ki yarın takılmayın

---

## 🌿 Git Workflow Rehberi

### Branch Yapısı

```
main              ← production, kimse direkt push etmez
└── develop       ← sprint integration branch
    ├── feat/sprint3-creation    ← Kişi A
    └── feat/sprint3-viewing     ← Kişi B
```

### Günlük Ritüel

**Sabah:**
```bash
# Kendi branch'inde değilsen geç
git checkout feat/sprint3-creation  # veya viewing

# develop'tan güncellemeleri al
git fetch origin
git merge origin/develop

# Eğer conflict varsa: Partnerini ara, birlikte çöz
```

**Gün içinde:**
```bash
# Küçük commit'ler yap, mesajlar anlamlı olsun
git add <dosya>
git commit -m "feat: add category ratings section to write review form"

# Commit mesajı şablonları:
# feat: yeni özellik
# fix: bug fix
# refactor: kod temizliği
# docs: dökümantasyon
# test: test ekleme
```

**Akşam:**
```bash
# Branch'ine push
git push origin feat/sprint3-creation

# Checkpoint günleri (4, 8) veya feature tamamlandığında:
# GitHub'da Pull Request aç: feat/sprint3-creation → develop
# Partnerinden kısa review iste (3-5 dakika)
# Approve olunca merge et
```

### Conflict Olursa

```bash
git status  # hangi dosyalarda conflict var?

# Her conflict için kod editöründe:
# - <<<<<<<< HEAD (senin değişikliğin)
# - ========
# - >>>>>>>> branch (onun değişikliği)
# Partnerinle konuş, hangisi kalacak veya ikisi de mi

# Çözdükten sonra:
git add <çözülen dosya>
git commit -m "merge: resolve conflict in review_repository.dart"
```

> [!TIP]
> Asla tek başına "ezmek" için `git push --force` yapmayın. Bunu yaparsanız partnerinizin commit'lerini silebilirsiniz. Zor durumda yardım isteyin.

---

## 📆 GÜN 1: Senkron & Kick-off

> **Hedef:** İkisi de aynı sayfada, branch'ler hazır, ilk küçük PR merge edilmiş, Cloud Function moderation iskeleti deploy olmuş

### 🌅 Sabah — Birlikte (2 saat)

Bu sabah ikinizin birlikte, aynı ekranda çalışmasını istiyorum. Zoom ekran paylaşımı veya yan yana oturun.

**1. Ortak Toplantı (90dk)**

Gündem:
1. ✅ Sprint 3 planını baştan sona okuyun — [sprint3_plan.md](#)
2. ✅ Sorularınızı not alın, birlikte cevaplayın
3. ✅ Görevlerin kimde olduğunu teyit edin
4. ✅ `ReviewCard` widget API'sini yazılı olarak finalize edin:

```dart
// Bu API kontratı SABİT — değişirse ikiniz beraber karar verin
class ReviewCard extends ConsumerWidget {
  final ReviewModel review;
  final bool showActions;        // Sadece sahibine göster (edit/delete)
  final bool showReportMenu;     // Default: true (başkasınınkine raporlama)
  final VoidCallback? onTap;     // Card'a tıklanınca ne olsun
  final bool compact;            // Home'da daha kısa versiyon
  final VoidCallback? onDeleted; // Parent'a haber ver
  final VoidCallback? onEdited;  // Parent'a haber ver
  
  const ReviewCard({
    super.key,
    required this.review,
    this.showActions = false,
    this.showReportMenu = true,
    this.onTap,
    this.compact = false,
    this.onDeleted,
    this.onEdited,
  });
}
```

Bu kontratı notes.md gibi bir dosyaya yazın, iki kişi de imzalasın.

**2. Firestore Rules & Indexes Güncellemesi (30dk)**

Birlikte yapın:

`firestore.rules` dosyasına `reports` koleksiyonu için kurallar ekleyin:

```
match /reports/{reportId} {
  allow read: if false;
  allow create: if request.auth != null 
    && request.resource.data.userId == request.auth.uid;
  allow update, delete: if false;
}
```

`reviews` kuralındaki read'i güncelle ki kullanıcı kendi onaysız yorumunu görebilsin:

```
match /reviews/{reviewId} {
  allow read: if resource.data.isApproved == true 
    || (request.auth != null && request.auth.uid == resource.data.userId);
  // ... diğer kurallar aynı
}
```

`firestore.indexes.json` dosyasına yeni index ekleyin (likes'a göre sıralama için):

```json
{
  "collectionGroup": "reviews",
  "queryScope": "COLLECTION",
  "fields": [
    { "fieldPath": "targetId", "order": "ASCENDING" },
    { "fieldPath": "isApproved", "order": "ASCENDING" },
    { "fieldPath": "likes", "order": "DESCENDING" }
  ]
}
```

Deploy:
```bash
firebase deploy --only firestore:rules,firestore:indexes
```

Index build 5-10 dakika sürebilir, arka planda çalışsın.

### 🌞 Öğleden Sonra — Paralel (2.5 saat)

Burada ayrılıyorsunuz, kendi branch'lerinizde çalışın.

**Kişi A — Task A6 Cloud Function Moderation İskeleti**

1. `functions/src/` klasörüne geç
2. `bad_words_tr.json` oluştur — internet'ten Türkçe küfür listesi bul (CC0/MIT), 50-100 kelime yeterli. Çok kısa kelimeleri (2-3 karakter) dikkatli seç, false positive yaparlar.
3. `moderation.ts` dosyasını yaz:

```typescript
// functions/src/moderation.ts
import { onDocumentCreated } from 'firebase-functions/v2/firestore';
import * as admin from 'firebase-admin';
import badWords from './bad_words_tr.json';

export const moderateNewReview = onDocumentCreated(
  'reviews/{reviewId}',
  async (event) => {
    const review = event.data?.data();
    if (!review) return;
    
    const text = (
      (review.comment || '') + ' ' + 
      (review.pros || []).join(' ') + ' ' +
      (review.cons || []).join(' ')
    ).toLowerCase();
    
    const hasBadWord = badWords.some((word: string) => 
      text.includes(word.toLowerCase())
    );
    
    if (hasBadWord) {
      await event.data?.ref.update({
        isApproved: false,
        moderationReason: 'auto_flagged_language',
      });
      console.log(`Review ${event.params.reviewId} auto-flagged`);
    }
  }
);
```

4. `index.ts`'e export ekle:
```typescript
export { aggregateUniversityRatings } from './aggregator';  // mevcut
export { moderateNewReview } from './moderation';           // yeni
```

> [!WARNING]
> Mevcut `index.ts`'deki `aggregateUniversityRatings`'i başka bir dosyaya taşıman gerekebilir. Eğer hepsini `index.ts`'de tutmak istersen, ikinci function'ı oraya ekle. Önce mevcut yapıyı kır, sonra fix et.

5. Deploy:
```bash
cd functions
npm run build  # TypeScript compile
firebase deploy --only functions
```

6. Test: Firebase Console'dan manuel bir test yorumu oluştur, küfür içeren bir tane dene. 5-10 sn içinde `isApproved: false` olmalı.

**Kişi B — Task B1 ReviewCard İskeleti**

1. `lib/features/reviews/presentation/widgets/review_card.dart` dosyasını oluştur
2. Şimdilik şu yapıyı kur:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/models/review_model.dart';

class ReviewCard extends ConsumerWidget {
  final ReviewModel review;
  final bool showActions;
  final bool showReportMenu;
  final VoidCallback? onTap;
  final bool compact;
  final VoidCallback? onDeleted;
  final VoidCallback? onEdited;

  const ReviewCard({
    super.key,
    required this.review,
    this.showActions = false,
    this.showReportMenu = true,
    this.onTap,
    this.compact = false,
    this.onDeleted,
    this.onEdited,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // TODO: Sonraki günlerde doldurulacak
    return Card(
      child: ListTile(
        title: Text(review.userName),
        subtitle: Text(review.comment, maxLines: 2, overflow: TextOverflow.ellipsis),
        trailing: Text(review.rating.toStringAsFixed(1)),
        onTap: onTap,
      ),
    );
  }
}
```

3. Bu placeholder widget'ı Kişi A'nın `write_review_screen.dart`'ındaki mevcut inline kart yerine kullanarak test et
4. `pubspec.yaml`'e `photo_view: ^0.15.0` ekle:
```bash
flutter pub get
```

### 🌆 Akşam — Birlikte (30dk)

Zoom'a geri dönün.

**1. Göster ve Anlat (15dk)**
- Kişi A: Moderation fonksiyonu çalışıyor mu? Manuel test yap, göster
- Kişi B: ReviewCard placeholder detay ekranında çalışıyor mu? Göster

**2. Merge Ritüeli (10dk)**
```bash
# Her iki kişi:
git push origin feat/sprint3-creation  # veya viewing

# GitHub'da PR aç → develop
# Hızlı review, merge
```

**3. Yarın Planı (5dk)**
Yarın ne yapacaksınız? Somut hedefler söyleyin:
- "Yarın A1 ile write screen kategori formunu bitireceğim"
- "Yarın B1'i görsel olarak tamamlayıp, actions menu ekleyeceğim"

### ✅ Gün 1 Bitişinde Durum

- [x] İkiniz de aynı Sprint 3 planını anladınız
- [x] Branch'ler çalışıyor
- [x] Firestore rules + indexes deploy edildi
- [x] ReviewCard placeholder widget develop'ta var
- [x] Moderation Cloud Function deploy edildi
- [x] `photo_view` paketi eklendi
- [x] Yarının planı netleşti

---

## 📆 GÜN 2: İlk Paralel Çalışma

> **Hedef:** Yazma formunun omurgası hazır, ReviewCard görsel olarak finalize edildi

### 🌅 Sabah Standupı (15dk)

- Dün ne bitirdim? — Moderation Cloud Function / ReviewCard placeholder
- Bugün ne yapacağım? — A1 (write screen kategori formu) / B1 (ReviewCard görsel)
- Blocker? — Muhtemelen yok

Dün pushed olduğundan emin olun, herkes `git pull` yapsın.

### 🌞 Gün İçi — Paralel (4 saat)

**Kişi A — Task A1: Write Review Screen Yeniden Yazımı (1. kısım)**

Dosyalar:
- `lib/features/reviews/presentation/screens/write_review_screen.dart`
- `lib/features/reviews/presentation/widgets/review_form_sections/` (yeni klasör)

Bugün odak: **Kategori puanlaması bölümü**

1. Önce `app_constants.dart`'a preset listeler ekle:

```dart
// AppConstants içine:
static const List<String> commonUniPros = [
  'Geniş kampüs',
  'Kaliteli hocalar',
  'Aktif sosyal hayat',
  'İyi kütüphane',
  'Güvenli ortam',
  'Güçlü mezun ağı',
  'Modern tesisler',
  'Bol öğrenci indirimi',
];

static const List<String> commonUniCons = [
  'Ulaşım zor',
  'Yemekhane pahalı',
  'Az sosyal aktivite',
  'Kalabalık sınıflar',
  'Yetersiz yurt',
  'Bürokratik işlemler',
  'Eski binalar',
];

static const List<String> commonDeptPros = [
  'Deneyimli akademisyenler',
  'Güncel müfredat',
  'İyi staj imkanları',
  'Güçlü mezun kariyeri',
  'Araştırma fırsatları',
];

static const List<String> commonDeptCons = [
  'Ağır ders yükü',
  'Uygulamalı ders az',
  'Zor sınavlar',
  'Az seçmeli ders',
];
```

2. `review_form_sections/category_ratings_section.dart` oluştur:

```dart
import 'package:flutter/material.dart';
import '../../../../../core/constants/app_constants.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../domain/models/review_model.dart';

class CategoryRatingsSection extends StatelessWidget {
  final ReviewType type;
  final Map<String, double> ratings;
  final void Function(String category, double rating) onChanged;

  const CategoryRatingsSection({
    super.key,
    required this.type,
    required this.ratings,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final categories = type == ReviewType.university
        ? AppConstants.uniRatingCategories
        : AppConstants.deptRatingCategories;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Kategori Puanları', style: AppTextStyles.titleMedium),
        Text(
          'Her kategori için 1-5 arası puan verin',
          style: AppTextStyles.bodySmall,
        ),
        const SizedBox(height: 16),
        ...categories.map((category) => _buildCategoryRow(category)),
      ],
    );
  }

  Widget _buildCategoryRow(String category) {
    final rating = ratings[category] ?? 0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(category, style: AppTextStyles.bodyMedium),
          ),
          Expanded(
            flex: 3,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: List.generate(5, (i) => IconButton(
                icon: Icon(
                  i < rating ? Icons.star_rounded : Icons.star_border_rounded,
                  color: AppColors.warning,
                  size: 28,
                ),
                onPressed: () => onChanged(category, (i + 1).toDouble()),
                padding: const EdgeInsets.all(2),
                constraints: const BoxConstraints(),
              )),
            ),
          ),
        ],
      ),
    );
  }
}
```

3. `write_review_screen.dart`'ta bu section'ı kullan:

```dart
class _WriteReviewScreenState extends ConsumerState<WriteReviewScreen> {
  // Mevcut _overallRating, _commentController kalsın
  final Map<String, double> _categoryRatings = {};
  // ...
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ...existing...
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Overall rating (mevcut)
            // ...
            
            // YENİ: Kategori ratings
            CategoryRatingsSection(
              type: ReviewType.university,  // şimdilik sabit
              ratings: _categoryRatings,
              onChanged: (category, rating) {
                setState(() => _categoryRatings[category] = rating);
              },
            ),
            
            // Yorum metni (mevcut)
            // ...
          ],
        ),
      ),
    );
  }
}
```

Bugün pros/cons ve fotoğrafları **yapma**, sadece kategori rating işini oturt.

**Kişi B — Task B1: ReviewCard Görsel Finalize**

Hedef: Görüntü olarak mockup'taki gibi olsun.

1. Kart düzeni:

```dart
@override
Widget build(BuildContext context, WidgetRef ref) {
  return Container(
    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppConstants.radiusLg),
      border: Border.all(color: AppColors.borderLight),
      boxShadow: AppColors.softShadow,
    ),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppConstants.radiusLg),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),           // avatar + isim + üni + rating + menu
            const SizedBox(height: 12),
            _buildComment(),           // yorum + devamını oku
            if (review.pros.isNotEmpty || review.cons.isNotEmpty) ...[
              const SizedBox(height: 10),
              _buildProsConsChips(),
            ],
            if (!compact && review.imageUrls.isNotEmpty) ...[
              const SizedBox(height: 10),
              _buildPhotoGrid(),
            ],
            const SizedBox(height: 10),
            _buildFooter(),            // tarih + like
          ],
        ),
      ),
    ),
  );
}
```

2. Her section'ı ayrı private method olarak yaz
3. Anonim mantığı:
```dart
Widget _buildHeader() {
  final displayName = review.isAnonymous ? 'Anonim Öğrenci' : review.userName;
  final displayUni = review.isAnonymous ? null : review.userUniversity;
  final photoUrl = review.isAnonymous ? null : review.userPhotoUrl;
  // ...
}
```

4. "Devamını oku" için:
```dart
class _CommentExpandable extends StatefulWidget {
  final String text;
  @override
  State<_CommentExpandable> createState() => _CommentExpandableState();
}

class _CommentExpandableState extends State<_CommentExpandable> {
  bool _expanded = false;
  static const _maxChars = 200;

  @override
  Widget build(BuildContext context) {
    final isTooLong = widget.text.length > _maxChars;
    final displayText = isTooLong && !_expanded 
      ? '${widget.text.substring(0, _maxChars)}...' 
      : widget.text;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(displayText, style: AppTextStyles.bodyMedium),
        if (isTooLong)
          TextButton(
            onPressed: () => setState(() => _expanded = !_expanded),
            child: Text(_expanded ? 'Daha az göster' : 'Devamını oku'),
          ),
      ],
    );
  }
}
```

5. `main.dart`'ta `timeago` Türkçe locale'ini initialize et:
```dart
import 'package:timeago/timeago.dart' as timeago;

void main() async {
  // ...existing...
  timeago.setLocaleMessages('tr', timeago.TrMessages());
  timeago.setDefaultLocale('tr');
  // ...existing...
}
```

6. Menu button (3 nokta) şimdilik placeholder — yarın `review_actions_menu.dart` ile finalize edilecek.

### 🌆 Akşam Buluşması (25dk)

**1. Demo (10dk)**
- Kişi A: Kategori formu çalışıyor mu? 6 kategoriye yıldız tıklayabiliyor musun? Göster
- Kişi B: ReviewCard gerçekten güzel mi? Mevcut bir yorum verisini detay ekranda kartla göster

**2. Sorun Tespit Et (5dk)**
- Her iki widget'ın design sistemine uygun mu? (renk, font, spacing)
- Kişi B'nin kartı Kişi A'nın formundaki yorumla görsel olarak sağlam duruyor mu?

**3. Küçük Pair Review (5dk)**
İkiniz aynı ekranda, Kişi B'nin ReviewCard kodunu 3 dakika inceleyin. Kişi A önerilerde bulunsun. Sonra tersini yapın.

Bu ilk pair review önemli — birlikte kodlamayı öğreniyorsunuz.

**4. Push & Sonraki Gün (5dk)**
```bash
# Her iki kişi push
# develop'a merge (ReviewCard'ı merge et ki Kişi A da kullanabilsin)
```

### ✅ Gün 2 Bitişinde Durum

- [x] Kategori rating formu çalışıyor
- [x] ReviewCard görsel olarak hazır (menu hariç)
- [x] `timeago` Türkçe lokalize edildi
- [x] App constants'te preset listeler var
- [x] İlk kod review deneyimini yaşadık

---

## 📆 GÜN 3: Form & Visual Finalize

> **Hedef:** Write screen'de pros/cons + fotoğraf hazır, ReviewCard menu actions çalışıyor, ReviewList iskeleti var

### 🌅 Sabah Standupı (15dk)

Önemli: Bugünden itibaren Kişi B'nin `ReviewCard` widget'ı Kişi A'nın Write Screen test akışında kullanılabilir. Önizleme yapmak için:

```dart
// Write ekranında preview butonu
ElevatedButton(
  onPressed: () => _showPreview(),
  child: Text('Önizle'),
),

void _showPreview() {
  final tempReview = ReviewModel(/* form'daki verilerle oluştur */);
  showDialog(context: context, builder: (_) => Dialog(
    child: ReviewCard(review: tempReview),
  ));
}
```

Bu küçük özellik ikinizin de işini kolaylaştırır.

### 🌞 Gün İçi — Paralel (4 saat)

**Kişi A — Task A1 Devam: Pros/Cons + Fotoğraf**

1. `review_form_sections/pros_cons_section.dart`:

```dart
class ProsConsSection extends StatelessWidget {
  final List<String> presetItems;
  final List<String> selectedItems;
  final String title;
  final Color color;
  final void Function(String item) onToggle;
  final void Function(String item) onAddCustom;
  
  // UI: Wrap<FilterChip> ile preset'ler, + butonu ile özel ekleme
}
```

Özel ekleme için dialog:
```dart
Future<String?> _showAddCustomDialog(BuildContext context, String title) async {
  final controller = TextEditingController();
  return showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text('Özel $title ekle'),
      content: TextField(
        controller: controller,
        maxLength: 30,
        decoration: const InputDecoration(hintText: 'Örn: Renkli kütüphane'),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: Text('İptal')),
        ElevatedButton(
          onPressed: () => Navigator.pop(ctx, controller.text.trim()),
          child: Text('Ekle'),
        ),
      ],
    ),
  );
}
```

2. `review_form_sections/photo_upload_section.dart`:

```dart
class PhotoUploadSection extends StatefulWidget {
  final List<File> localPhotos;      // henüz yüklenmemiş
  final List<String> uploadedUrls;   // düzenleme modunda mevcut olanlar
  final void Function(File) onAdd;
  final void Function(int index, bool isLocal) onRemove;
}
```

Önemli nokta: **Fotoğraf sıkıştırma**. `image_picker`'da şu ayarları kullan:
```dart
final picker = ImagePicker();
final picked = await picker.pickImage(
  source: source,
  maxWidth: 1080,      // 1080px yeterli
  maxHeight: 1080,
  imageQuality: 75,    // JPEG quality
);
```

3. `write_review_screen.dart`'ta tümünü bir araya getir. Ekran yapısı:

```
┌─────────────────────────┐
│ AppBar: Değerlendir     │
├─────────────────────────┤
│ 📌 Genel puan           │
│ [⭐⭐⭐⭐⭐]              │
├─────────────────────────┤
│ Kategori Puanları       │
│ Kampüs    ⭐⭐⭐⭐⭐      │
│ Eğitim    ⭐⭐⭐⭐⭐      │
│ ... 6 kategori          │
├─────────────────────────┤
│ ✅ Artılar (Pros)       │
│ [chip] [chip] [+ özel]  │
├─────────────────────────┤
│ ❌ Eksiler (Cons)       │
│ [chip] [chip] [+ özel]  │
├─────────────────────────┤
│ 📝 Yorumunuz            │
│ [multiline text field]  │
│ 0/500                   │
├─────────────────────────┤
│ 📷 Fotoğraflar (0/3)    │
│ [+] [foto1] [foto2]     │
├─────────────────────────┤
│ [ ] Anonim paylaş       │
├─────────────────────────┤
│   [ Gönder ]            │
└─────────────────────────┘
```

Submit butonu sadece tüm zorunlu alanlar dolu ise aktif:
- Genel puan > 0
- 6 kategori ratings dolu (her biri > 0)
- Yorum min 20 karakter

> [!WARNING]
> Fotoğraflar Firebase Storage'a yüklenirken yorum oluşturma sırası önemli:
> 1. Önce fotoğrafları upload et
> 2. URL'leri al
> 3. Sonra review document'i oluştur
> 
> Eğer review önce oluşup sonra foto yüklenirse ve foto yüklemesi başarısız olursa, yorumun imageUrls'i boş kalır ama yorum kaydedilmiş olur → kullanıcı hayal kırıklığına uğrar.

Upload helper fonksiyon:
```dart
Future<List<String>> _uploadReviewPhotos(List<File> photos, String userId) async {
  final urls = <String>[];
  for (final photo in photos) {
    final imageId = DateTime.now().millisecondsSinceEpoch.toString();
    final ref = FirebaseStorage.instance
      .ref()
      .child('review_images/$userId/$imageId.jpg');
    await ref.putFile(photo, SettableMetadata(contentType: 'image/jpeg'));
    urls.add(await ref.getDownloadURL());
  }
  return urls;
}
```

**Kişi B — Task B1 Finalize: Actions Menu + Task B2 İskeleti**

1. `review_actions_menu.dart` oluştur:

```dart
class ReviewActionsMenu extends ConsumerWidget {
  final ReviewModel review;
  final bool showOwnerActions;
  final bool showReportAction;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert),
      onSelected: (value) async {
        switch (value) {
          case 'edit':
            onEdit?.call();
            break;
          case 'delete':
            final confirmed = await _showDeleteConfirmation(context);
            if (confirmed == true) onDelete?.call();
            break;
          case 'report':
            // Şikayet dialog — Task B6'da eklenecek
            // Şimdilik placeholder
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Şikayet sistemi yakında')),
            );
            break;
        }
      },
      itemBuilder: (context) => [
        if (showOwnerActions)
          const PopupMenuItem(value: 'edit', child: Text('Düzenle')),
        if (showOwnerActions)
          const PopupMenuItem(
            value: 'delete', 
            child: Text('Sil', style: TextStyle(color: AppColors.error)),
          ),
        if (showReportAction && !showOwnerActions)
          const PopupMenuItem(value: 'report', child: Text('Şikayet Et')),
      ],
    );
  }

  Future<bool?> _showDeleteConfirmation(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Yorumu sil'),
        content: Text('Bu yorumu silmek istediğinizden emin misiniz? Bu işlem geri alınamaz.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('İptal')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text('Sil'),
          ),
        ],
      ),
    );
  }
}
```

2. ReviewCard'a bu menüyü entegre et (header'ın sağında)

3. `review_list.dart` iskeletini yaz (implementation yarın):

```dart
class ReviewList extends ConsumerStatefulWidget {
  final String targetId;
  final ReviewType type;
  final bool showSortOptions;
  // ...
}

// Şimdilik sadece mevcut getUniversityReviews'u stream et, sort eklemeden
```

### 🌆 Akşam Buluşması (25dk)

**1. Entegrasyon Kontrolü (15dk)**

Çok önemli an: Kişi B'nin ReviewCard'ını Kişi A'nın yeni write ekran preview'unda gösterin.

```bash
# Kişi A:
git fetch origin
git merge origin/feat/sprint3-viewing  # B'nin branch'ini merge et
flutter run
# Test et: Form doldur, önizle, ReviewCard göster
```

Eğer sorun varsa (import hatası, null check):
- Partnerinden yardım iste
- Birlikte düzelt

**2. Yarın Planı (10dk)**
- Yarın Gün 4 — **Checkpoint 1**
- İlk büyük entegrasyon
- Kişi A: write ekranı bitir (bugün fotoğraf bitmediyse yarın bitir)
- Kişi B: B2 ReviewList + sort mantığı

### ✅ Gün 3 Bitişinde Durum

- [x] Write ekranı kategoriler + pros/cons + fotoğraf çalışıyor
- [x] ReviewCard menu actions yerinde
- [x] ReviewList iskeleti var
- [x] İlk entegrasyon başarılı

---

## 📆 GÜN 4: Checkpoint 1 & Etkileşim

> **Hedef:** İlk büyük entegrasyon yapıldı — write + list + card + repository hep beraber çalışıyor. Bug hunt günü.

### 🌅 Sabah Standupı (20dk — bugün biraz uzun)

**Özel gündem: Dünkü entegrasyonun sorunları varsa listele.**

Birlikte develop branch'e bakın:
```bash
git checkout develop
git pull
flutter run
```

Bir yorum yazmayı deneyin. Sorun varsa not alın.

### 🌞 Sabah 10:00 — 12:00 — CHECKPOINT 1 (BİRLİKTE ÇALIŞMA)

Bugünün sabahı özel. İkiniz aynı ekranda, pair programming gibi çalışın.

**Test Edilecek Akış:**

1. **Yorum Oluşturma:**
   - [ ] Giriş yap (edu.tr olan bir hesapla)
   - [ ] Bir üniversiteye git
   - [ ] "Değerlendir" butonuna bas
   - [ ] Tüm alanları doldur (ratings, pros, cons, yorum, 1 foto)
   - [ ] Gönder
   - [ ] Toast/snackbar gösteriliyor mu?

2. **Yorum Görme:**
   - [ ] Aynı üniversitenin detay sayfasında yorumun görünüyor mu?
   - [ ] Foto thumbnail gözüküyor mu?
   - [ ] Pros/cons chip'leri doğru renkte mi?
   - [ ] "X saat önce" doğru mu gösteriliyor?

3. **Rating Agregasyon:**
   - [ ] Üniversite kartında `avgRating` ve `reviewCount` güncellendi mi? (1-2 dk bekle — Cloud Function)
   - [ ] `categoryRatings` map'i doldu mu?

4. **Moderation:**
   - [ ] Test için küfürlü bir yorum yaz (bad_words_tr.json'daki bir kelimeyle)
   - [ ] 5-10 saniye sonra yorum listeden kayboluyor mu? (`isApproved: false`)
   - [ ] Ancak **kendi** yorumlar listesinde görünüyor mu?

**Bulunan her bug'ı GitHub Issue olarak aç ve "Gün 4 Checkpoint" label'ı koy.**

### 🌞 Öğleden Sonra — Paralel (3 saat)

Sabah bulunan bug'ları bölün: Kimin yaptığı alandaysa o düzeltsin.

**Bug fix + yeni görevler:**

**Kişi A — Write ekran polish:**
- Form validation error mesajlarını görsel hale getir (kırmızı border, hata metni altta)
- Loading overlay (foto upload sırasında "Fotoğraflar yükleniyor... 1/3")
- Submit sonrası başarı animasyonu (`flutter_animate` ile)
- Anonim switch açıldığında: "Anonim modda hesabınız gösterilmez" bilgi metni

**Kişi B — Task B3: Optimistic Like Sistemi**

`like_button.dart` ve provider'lar:

```dart
// review_providers.dart'a ekle

// Kullanıcının beğendiği yorumların ID'leri
final userLikedReviewsProvider = StreamProvider<Set<String>>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return Stream.value({});
  
  return FirebaseFirestore.instance
    .collectionGroup('likes')
    .where(FieldPath.documentId, isEqualTo: user.uid)
    .snapshots()
    .map((snap) {
      // Her like doc'u parent: reviews/{reviewId}/likes/{userId}
      return snap.docs
        .map((d) => d.reference.parent.parent!.id)
        .toSet();
    });
});
```

> [!IMPORTANT]
> `collectionGroup('likes')` için Firebase Console'da **collection group query indexing**'i aktifleştirmen gerekebilir. İlk sorguda hata dönerse console'daki linke tıkla.

Optimistic controller:

```dart
class LikeController extends StateNotifier<Map<String, bool>> {
  LikeController(this._repo) : super({});
  final ReviewRepository _repo;
  
  Future<void> toggleLike({
    required String reviewId, 
    required String userId, 
    required bool currentlyLiked,
  }) async {
    // Optimistic update
    state = {...state, reviewId: !currentlyLiked};
    
    try {
      await _repo.likeReview(reviewId, userId);
    } catch (e) {
      // Rollback
      state = {...state}..remove(reviewId);
      rethrow;
    }
    
    // Server stream güncellediğinde pending'i temizle
    Future.delayed(const Duration(milliseconds: 500), () {
      state = {...state}..remove(reviewId);
    });
  }
}

final likeControllerProvider = 
  StateNotifierProvider<LikeController, Map<String, bool>>((ref) {
    return LikeController(ref.read(reviewRepositoryProvider));
  });
```

LikeButton widget (ReviewCard içinde kullanılacak):

```dart
class LikeButton extends ConsumerWidget {
  final ReviewModel review;
  const LikeButton({super.key, required this.review});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).value;
    final likedIds = ref.watch(userLikedReviewsProvider).value ?? {};
    final pending = ref.watch(likeControllerProvider)[review.id];
    
    final isLiked = pending ?? likedIds.contains(review.id);
    
    return InkWell(
      onTap: user == null ? null : () {
        ref.read(likeControllerProvider.notifier).toggleLike(
          reviewId: review.id,
          userId: user.uid,
          currentlyLiked: isLiked,
        );
      },
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isLiked ? Icons.thumb_up : Icons.thumb_up_outlined,
              size: 16,
              color: isLiked ? AppColors.primary : AppColors.textTertiary,
            ),
            const SizedBox(width: 4),
            Text(
              '${review.likes}', 
              style: AppTextStyles.labelMedium.copyWith(
                color: isLiked ? AppColors.primary : AppColors.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

ReviewCard'da mevcut placeholder like kısmını bu widget ile değiştir.

### 🌆 Akşam Buluşması (30dk — biraz uzun)

**1. Bug Hunt Retrospektifi (10dk)**
- Kaç bug buldunuz?
- Hangi alan en çok sorun çıkarıyor?
- Gün 8 Checkpoint 2'ye kadar nelere dikkat etmeli?

**2. Like Sistemi Demo (5dk)**
- Birden fazla yorumu beğen/beğenme
- Network'ü kapat → beğenmeye çalış → hata görüyor musun?

**3. Karışık Pair Review (15dk)**
Bugün farklı: İkiniz birbirinin kodunu 5 dakika inceleyin, sonra 5 dakika konuşun, son 5 dakika iyileştirme yapın.

### ✅ Gün 4 Bitişinde Durum

- [x] İlk end-to-end yorum akışı çalışıyor
- [x] Agregasyon Cloud Function'ı doğrulandı
- [x] Moderation test edildi
- [x] Optimistic like sistemi yerinde
- [x] Bug'lar issue'lara yazıldı

---

## 📆 GÜN 5: Department & Like Sistemi

> **Hedef:** Bölüm yorumları çalışıyor, sort mantığı canlı

### 🌅 Sabah Standupı (15dk)

Bu sabah odak: Dün bulunan bug'ların hepsi kapanmış olmalı. Açık issue varsa bu sabah kapatılmalı.

### 🌞 Gün İçi — Paralel (4 saat)

**Kişi A — Task A2: Department Review Desteği**

1. `write_review_screen.dart` constructor'ını genişlet:

```dart
class WriteReviewScreen extends ConsumerStatefulWidget {
  final String targetId;
  final ReviewType type;
  final String universityId;

  const WriteReviewScreen({
    super.key,
    required this.targetId,
    required this.type,
    required this.universityId,
  });
}
```

2. `app_router.dart`'ta route güncelle:

```dart
// Önceki /write-review/:uniId'yi kaldır ya da backward compatibility koru
GoRoute(
  path: '/write-review/:type/:targetId',
  builder: (context, state) {
    final typeStr = state.pathParameters['type']!;
    final targetId = state.pathParameters['targetId']!;
    final type = typeStr == 'university' 
      ? ReviewType.university 
      : ReviewType.department;
    
    // Department ise universityId'yi extra parametreden al
    final universityId = state.uri.queryParameters['uni'] ?? targetId;
    
    return WriteReviewScreen(
      type: type,
      targetId: targetId,
      universityId: universityId,
    );
  },
),
```

3. Uni detail'daki değerlendir butonu:
```dart
onPressed: () => context.push('/write-review/university/$universityId'),
```

4. Department detail'a değerlendir butonu ekle:
```dart
onPressed: () => context.push(
  '/write-review/department/${department.id}?uni=${department.universityId}',
),
```

5. Form submit'te type'ı kullan:
```dart
final review = ReviewModel(
  id: '',
  type: widget.type,        // university veya department
  targetId: widget.targetId,
  universityId: widget.universityId,
  // ...
);
```

6. Kategori listesi type'a göre:
```dart
CategoryRatingsSection(
  type: widget.type,  // Dinamik
  // ...
)
```

**Kişi B — Task B2 Devam: Sort/Filter**

1. `review_repository.dart`'taki metotları genişlet:

```dart
Stream<List<ReviewModel>> getUniversityReviews(
  String universityId, {
  int limit = 20,
  String orderBy = 'createdAt',
}) {
  return _reviewsRef
    .where('targetId', isEqualTo: universityId)
    .where('isApproved', isEqualTo: true)
    .orderBy(orderBy, descending: true)
    .limit(limit)
    .snapshots()
    .map((snapshot) => snapshot.docs
        .map((doc) => ReviewModel.fromMap(doc.data(), doc.id))
        .toList());
}

Stream<List<ReviewModel>> getDepartmentReviews(
  String departmentId, {
  int limit = 20,
  String orderBy = 'createdAt',
}) {
  return _reviewsRef
    .where('targetId', isEqualTo: departmentId)
    .where('isApproved', isEqualTo: true)
    .orderBy(orderBy, descending: true)
    .limit(limit)
    .snapshots()
    .map((snapshot) => snapshot.docs
        .map((doc) => ReviewModel.fromMap(doc.data(), doc.id))
        .toList());
}
```

2. Provider'a sort ekle:

```dart
// review_providers.dart
enum ReviewSort { newest, mostLiked }

final reviewSortProvider = StateProvider<ReviewSort>((_) => ReviewSort.newest);

class SortedReviewsParams {
  final String targetId;
  final ReviewType type;
  const SortedReviewsParams({required this.targetId, required this.type});
  
  @override bool operator ==(Object other) => 
    other is SortedReviewsParams && other.targetId == targetId && other.type == type;
  @override int get hashCode => Object.hash(targetId, type);
}

final sortedReviewsProvider = StreamProvider.family<List<ReviewModel>, SortedReviewsParams>(
  (ref, params) {
    final sort = ref.watch(reviewSortProvider);
    final repo = ref.read(reviewRepositoryProvider);
    final orderBy = sort == ReviewSort.newest ? 'createdAt' : 'likes';
    
    if (params.type == ReviewType.university) {
      return repo.getUniversityReviews(params.targetId, orderBy: orderBy);
    } else {
      return repo.getDepartmentReviews(params.targetId, orderBy: orderBy);
    }
  },
);
```

3. `review_list.dart`'ı finalize et:

```dart
class ReviewList extends ConsumerWidget {
  final String targetId;
  final ReviewType type;
  final bool showSortOptions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sort = ref.watch(reviewSortProvider);
    final reviewsAsync = ref.watch(sortedReviewsProvider(
      SortedReviewsParams(targetId: targetId, type: type),
    ));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showSortOptions) _buildSortBar(ref, sort),
        reviewsAsync.when(
          data: (reviews) {
            if (reviews.isEmpty) return _buildEmptyState();
            return ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: reviews.length,
              itemBuilder: (_, i) => ReviewCard(review: reviews[i]),
            );
          },
          loading: () => const ShimmerList(itemCount: 3),
          error: (e, _) => ErrorStateWidget(message: '$e'),
        ),
      ],
    );
  }

  Widget _buildSortBar(WidgetRef ref, ReviewSort current) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Text('Sırala: ', style: AppTextStyles.labelMedium),
          const SizedBox(width: 8),
          ChoiceChip(
            label: Text('En Yeni'),
            selected: current == ReviewSort.newest,
            onSelected: (v) {
              if (v) ref.read(reviewSortProvider.notifier).state = ReviewSort.newest;
            },
          ),
          const SizedBox(width: 8),
          ChoiceChip(
            label: Text('En Beğenilen'),
            selected: current == ReviewSort.mostLiked,
            onSelected: (v) {
              if (v) ref.read(reviewSortProvider.notifier).state = ReviewSort.mostLiked;
            },
          ),
        ],
      ),
    );
  }
  
  // Empty state
}
```

4. `university_detail_screen.dart`'taki `_ReviewSection`'ı `ReviewList` ile değiştir:

```dart
// Önceki inline review loop yerine:
ReviewList(targetId: universityId, type: ReviewType.university)
```

### 🌆 Akşam Buluşması (25dk)

**1. Demo (10dk)**
- Kişi A: Bir bölüme yorum yaz
- Kişi B: "En yeni" ve "En beğenilen" sort arasında geçiş yap, fark görünüyor mu?

**2. Firestore Index Kontrolü (5dk)**
`likes`'a göre sıralama yaptığında Firebase Console'da bir hata linki gelmiş olabilir. Eğer geldiyse tıkla, index'i oluştur. 10dk beklet.

**3. Yarın Planı (10dk)**
Yarın Kişi A edit, Kişi B kategori chart. Bu ikisi birbirine bağımlı değil, güvenle paralel çalışabilirsiniz.

### ✅ Gün 5 Bitişinde Durum

- [x] Bölüm yorumu yazılabiliyor, listeleniyor
- [x] Sort (yeni/beğenilen) çalışıyor
- [x] Firestore index'i aktif
- [x] ReviewList generic widget univers. ve bölümde kullanılıyor

---

## 📆 GÜN 6: Edit & Kategori Chart

> **Hedef:** Yorum düzenleme akışı çalışıyor, üni/bölüm detayında kategori puanları görselleştirildi

### 🌅 Sabah Standupı (15dk)

### 🌞 Gün İçi — Paralel (4 saat)

**Kişi A — Task A3: Review Düzenleme**

1. Repository'ye `getReview` ekle:

```dart
// review_repository.dart (comment separator ile senin bölümün)
Future<ReviewModel?> getReview(String reviewId) async {
  final doc = await _firestore.collection('reviews').doc(reviewId).get();
  if (!doc.exists || doc.data() == null) return null;
  return ReviewModel.fromMap(doc.data()!, doc.id);
}
```

2. `write_review_screen.dart`'a `initialReview` parametresi:

```dart
class WriteReviewScreen extends ConsumerStatefulWidget {
  final String targetId;
  final ReviewType type;
  final String universityId;
  final ReviewModel? initialReview;  // ← YENİ

  const WriteReviewScreen({
    super.key,
    required this.targetId,
    required this.type,
    required this.universityId,
    this.initialReview,
  });
}
```

3. `initState`'te eğer `initialReview` varsa, form'u doldur:

```dart
@override
void initState() {
  super.initState();
  if (widget.initialReview != null) {
    final r = widget.initialReview!;
    _overallRating = r.rating;
    _categoryRatings.addAll(r.categoryRatings);
    _selectedPros.addAll(r.pros);
    _selectedCons.addAll(r.cons);
    _commentController.text = r.comment;
    _isAnonymous = r.isAnonymous;
    _existingPhotoUrls.addAll(r.imageUrls);
  }
}
```

4. Submit'te eğer `initialReview` varsa update, yoksa add:

```dart
Future<void> _submitReview() async {
  // ... validation
  
  final reviewData = ReviewModel(
    id: widget.initialReview?.id ?? '',  // mevcut id veya boş
    // ... diğer alanlar
    createdAt: widget.initialReview?.createdAt ?? DateTime.now(),
    updatedAt: DateTime.now(),
  );
  
  if (widget.initialReview != null) {
    await ref.read(reviewRepositoryProvider).updateReview(reviewData);
  } else {
    await ref.read(reviewRepositoryProvider).addReview(reviewData);
  }
}
```

5. AppBar başlığını dinamik yap:
```dart
title: Text(widget.initialReview != null ? 'Düzenle' : 'Değerlendir'),
```

6. Router'a edit route ekle:

```dart
GoRoute(
  path: '/edit-review/:reviewId',
  builder: (context, state) {
    final reviewId = state.pathParameters['reviewId']!;
    // Bu route async — FutureBuilder veya ref.watch ile review'u çek
    return Consumer(
      builder: (context, ref, _) {
        final reviewAsync = ref.watch(reviewDetailProvider(reviewId));
        return reviewAsync.when(
          data: (r) {
            if (r == null) {
              return Scaffold(body: Center(child: Text('Yorum bulunamadı')));
            }
            return WriteReviewScreen(
              targetId: r.targetId,
              type: r.type,
              universityId: r.universityId,
              initialReview: r,
            );
          },
          loading: () => Scaffold(body: Center(child: CircularProgressIndicator())),
          error: (e, _) => Scaffold(body: Center(child: Text('Hata: $e'))),
        );
      },
    );
  },
),
```

7. Provider ekle:
```dart
// review_providers.dart
final reviewDetailProvider = FutureProvider.family<ReviewModel?, String>((ref, id) {
  return ref.read(reviewRepositoryProvider).getReview(id);
});
```

8. ReviewCard'daki menu'den edit'i bu route'a bağla:
```dart
// Kişi B'ye not: edit callback'i bu şekilde olmalı
onEdit: () => context.push('/edit-review/${review.id}'),
```

**Kişi B — Task B5: Kategori Rating Chart**

1. `category_ratings_chart.dart` oluştur:

```dart
class CategoryRatingsChart extends StatelessWidget {
  final Map<String, double> ratings;
  final int reviewCount;
  
  const CategoryRatingsChart({
    super.key,
    required this.ratings,
    required this.reviewCount,
  });

  @override
  Widget build(BuildContext context) {
    if (ratings.isEmpty || reviewCount == 0) {
      return _buildEmptyState();
    }
    
    return Container(
      padding: const EdgeInsets.all(AppConstants.spacingLg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.radiusLg),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.insights_rounded, color: AppColors.primary),
              const SizedBox(width: 8),
              Text('Kategori Puanları', style: AppTextStyles.titleMedium),
              const Spacer(),
              Text(
                '$reviewCount değerlendirme',
                style: AppTextStyles.labelSmall,
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...ratings.entries.map((e) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: RatingDisplay(
              label: e.key,
              value: e.value,
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.radiusLg),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        children: [
          Icon(Icons.insights_outlined, size: 40, color: AppColors.textTertiary),
          const SizedBox(height: 8),
          Text('Henüz yeterli değerlendirme yok', 
            style: AppTextStyles.titleSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text('İlk değerlendiren siz olun!', 
            style: AppTextStyles.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
```

2. `university_detail_screen.dart`'a yerleştir — Bölümler başlığından önce:

```dart
// SliverToBoxAdapter içine ekle:
Padding(
  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
  child: CategoryRatingsChart(
    ratings: uni.categoryRatings,
    reviewCount: uni.reviewCount,
  ),
),
```

3. Aynısını `department_detail_screen.dart`'a da ekle — "Yorumlar Yakında" placeholder'ın yerine yerleştir.

### 🌆 Akşam Buluşması (25dk)

**1. Entegrasyon Testi (15dk)**
Bu önemli: Edit akışının canlı testi.

- Yeni bir yorum yaz
- Review card'da düzenle menüsü → edit ekranı açılıyor mu?
- Mevcut veriler form'da görünüyor mu? (ratings, pros, cons, text, photo)
- Bir değişiklik yap, kaydet
- Değişiklik list'e yansıdı mı?
- `updatedAt` güncellendi mi? (ReviewCard'da "düzenlendi" etiketi eklemek istersen nice-to-have)

**2. Kategori Chart Görünürlüğü (5dk)**
- Üniversite detayında chart görünüyor mu?
- Chart değerleri yorumlardan hesaplanan ortalamalar mı?
- 0 yorumlu üniversitede empty state görünüyor mu?

**3. Yarın Planı (5dk)**

### ✅ Gün 6 Bitişinde Durum

- [x] Yorum düzenleme çalışıyor
- [x] Kategori chart'ı üni ve bölüm detaylarında görsel
- [x] Form hem yeni yorum hem edit olarak çalışabiliyor

---

## 📆 GÜN 7: Delete & Navigation

> **Hedef:** Silme akışı bitti, home screen navigation çalışıyor, profilde yorumlarım sekmesi var

### 🌅 Sabah Standupı (15dk)

### 🌞 Gün İçi — Paralel (4 saat)

**Kişi A — Task A4: Silme + Task A5: MyReviews Ekranı**

1. Repository'deki delete'i genişlet (foto silme dahil):

```dart
Future<void> deleteReview(String reviewId, String userId, List<String> photoUrls) async {
  // 1. Firestore'dan sil
  await _firestore.collection('reviews').doc(reviewId).delete();
  
  // 2. reviewCount azalt
  await _firestore.collection('users').doc(userId).update({
    'reviewCount': FieldValue.increment(-1),
  });
  
  // 3. Fotoğrafları sil (best effort)
  for (final url in photoUrls) {
    try {
      await FirebaseStorage.instance.refFromURL(url).delete();
    } catch (e) {
      print('Photo delete failed: $e');
    }
  }
}
```

2. Review controller ekle:
```dart
// review_providers.dart'a (Kişi A bölümüne)
class ReviewActionController extends StateNotifier<AsyncValue<void>> {
  ReviewActionController(this._repo) : super(const AsyncValue.data(null));
  final ReviewRepository _repo;

  Future<void> deleteReview(ReviewModel review) async {
    state = const AsyncValue.loading();
    try {
      await _repo.deleteReview(review.id, review.userId, review.imageUrls);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final reviewActionControllerProvider = 
  StateNotifierProvider<ReviewActionController, AsyncValue<void>>((ref) {
    return ReviewActionController(ref.read(reviewRepositoryProvider));
  });
```

3. ReviewActionsMenu'deki delete callback'i bu controller'a bağla (Kişi B'nin kodunda, ortak dosya gibi davran):

```dart
// Kişi B'nin widget'ını kullanırken
ReviewCard(
  review: review,
  showActions: isOwnReview,
  onEdit: () => context.push('/edit-review/${review.id}'),
  onDelete: () async {
    await ref.read(reviewActionControllerProvider.notifier).deleteReview(review);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Yorumunuz silindi')),
    );
  },
)
```

4. `my_reviews_screen.dart` oluştur:

```dart
class MyReviewsScreen extends ConsumerWidget {
  const MyReviewsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).value;
    
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: Text('Yorumlarım')),
        body: _buildUnauthenticatedState(context),
      );
    }
    
    final reviewsAsync = ref.watch(userReviewsProvider(user.uid));

    return Scaffold(
      appBar: AppBar(title: Text('Yorumlarım')),
      body: reviewsAsync.when(
        data: (reviews) {
          if (reviews.isEmpty) return _buildEmptyState(context);
          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 16),
            itemCount: reviews.length,
            itemBuilder: (_, i) {
              final r = reviews[i];
              return ReviewCard(
                review: r,
                showActions: true,
                showReportMenu: false,
                onEdit: () => context.push('/edit-review/${r.id}'),
                onDelete: () async {
                  await ref.read(reviewActionControllerProvider.notifier).deleteReview(r);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Yorumunuz silindi')),
                    );
                  }
                },
              );
            },
          );
        },
        loading: () => const ShimmerList(),
        error: (e, _) => ErrorStateWidget(message: '$e'),
      ),
    );
  }
  
  // _buildEmptyState, _buildUnauthenticatedState
}
```

5. Router'a ekle:
```dart
GoRoute(
  path: '/my-reviews',
  builder: (context, state) => const MyReviewsScreen(),
),
```

6. `profile_screen.dart`'ta "Hesap" bölümüne menü item ekle:
```dart
_SettingsItem(
  icon: Icons.rate_review_rounded,
  title: 'Yorumlarım',
  subtitle: '${profile?.reviewCount ?? 0} yorum',
  onTap: () => context.push('/my-reviews'),
),
```

**Kişi B — Task B7: Home Navigation + Task B8: userReviewsProvider**

1. `userReviewsProvider`'ı ekle:

```dart
// review_providers.dart (senin bölümüne)
final userReviewsProvider = StreamProvider.family<List<ReviewModel>, String>((ref, userId) {
  return ref.read(reviewRepositoryProvider).getUserReviews(userId);
});
```

2. `home_screen.dart`'taki `_RecentReviewCard` yerine `ReviewCard(compact: true)` kullan:

```dart
// Eski _RecentReviewCard'ı sil (veya deprecate et)
// recentReviewsProvider'dan gelen her review için:
ReviewCard(
  review: review,
  compact: true,
  onTap: () => context.push('/university/${review.universityId}'),
  showActions: false,
  showReportMenu: false,
)
```

3. Home empty state güzelleştir:
```dart
// Eğer reviews boşsa
Center(
  child: Padding(
    padding: EdgeInsets.all(40),
    child: Column(
      children: [
        Icon(Icons.rate_review_outlined, size: 48, color: AppColors.textTertiary),
        const SizedBox(height: 12),
        Text('Henüz yorum yok', style: AppTextStyles.titleMedium),
        Text('İlk yorumu yazan siz olun!', 
          style: AppTextStyles.bodySmall,
          textAlign: TextAlign.center,
        ),
      ],
    ),
  ),
)
```

4. Compact mode için ReviewCard'ı güncelle: `compact: true` ise pros/cons gösterme, yorum max 2 satır:

```dart
Widget _buildComment() {
  if (compact) {
    return Text(
      review.comment, 
      maxLines: 2, 
      overflow: TextOverflow.ellipsis,
      style: AppTextStyles.bodySmall,
    );
  }
  return _CommentExpandable(text: review.comment);
}
```

### 🌆 Akşam Buluşması (25dk)

**1. Profil → Yorumlarım Akışı Testi (10dk)**
- Profil sekmesine git
- "Yorumlarım" menüsüne tıkla
- Kendi yorumların listeleniyor mu?
- Bir yorumu sil, listeden kayboluyor mu?
- `reviewCount` profil ana ekranda azaldı mı?

**2. Home Screen Kontrolü (5dk)**
- Ana sayfadaki son yorumlar güzel gözüküyor mu?
- Yoruma tıklayınca ilgili üniversiteye gidiyor mu?
- `compact: true` modunda kart düzgün mü (pros/cons yok, uzun yorum kesilmiş)?

**3. Yarın Planı (10dk)**
Yarın **Checkpoint 2** — büyük entegrasyon + şikayet sistemi.

### ✅ Gün 7 Bitişinde Durum

- [x] Yorum silme çalışıyor (foto silme dahil)
- [x] Profilde "Yorumlarım" ekranı hazır
- [x] Home screen ReviewCard ile navigation bağlı
- [x] Silme sonrası reviewCount güncelleniyor

---

## 📆 GÜN 8: Checkpoint 2 & Şikayet

> **Hedef:** Tüm ana akışlar birlikte çalışıyor. Bug hunt + şikayet sistemi + photo gallery

### 🌅 Sabah Standupı (20dk)

Bugün Checkpoint 2 günü. Öncelik bug fix + yeni özellik değil.

### 🌞 Sabah 10:00 — 12:00 — CHECKPOINT 2 (BİRLİKTE)

Sabah ikiniz aynı ekranda, her akışı sistematik test edin:

**1. Tam Kullanıcı Hikayesi:**
- [ ] Kayıt ol (edu.tr email)
- [ ] Email doğrula
- [ ] Profili düzenle, üniversite seç
- [ ] Ana sayfaya git → bir üniversiteye git
- [ ] "Değerlendir" → tam yorum yaz (ratings + pros + cons + text + photo)
- [ ] Ana sayfaya dön → son yorumlarda kendi yorumun var
- [ ] Yorumuna tıkla → üniversite detayına git
- [ ] Kendi yorumunun menüsünden Düzenle → değişiklik yap, kaydet
- [ ] Değişiklik yansıdı mı?
- [ ] Kendi yorumunun menüsünden Sil → confirm → silindi mi?

**2. Başka Kullanıcı Perspektifi:**
İkinizin de farklı hesapları olsun. 2 cihazda/emülatörde farklı hesaplarla test edin:
- [ ] A: Yorum yaz
- [ ] B: O yorumu gör, beğen
- [ ] A: Beğeni sayısı anında güncellendi mi?
- [ ] B: Aynı yoruma bir daha beğen — unlike oluyor mu?
- [ ] B: Farklı kullanıcı olduğu için menüde "Şikayet Et" görüyor mu? (Düzenle/Sil görmüyor mu?)

**3. Sort Testi:**
- [ ] 3-4 yorum yaz, bazılarını beğen
- [ ] "En Yeni" ile "En Beğenilen" arasında geçiş yap
- [ ] Sıralama doğru mu?

**4. Moderation Testi:**
- [ ] Küfürlü yorum yaz
- [ ] 10 saniye sonra listeden kaybolmalı (`isApproved: false`)
- [ ] Yorumlarım listesinde kendi onaysız yorumunu görebilmelisin

**5. Agregasyon Testi:**
- [ ] Yorumdan önce ve sonra üniversite kartında `avgRating` ve `reviewCount` değerleri
- [ ] Kategori chart'ta ortalamalar mantıklı mı?

**Her bug'ı issue olarak aç!**

### 🌞 Öğleden Sonra — Paralel (3 saat)

Bu öğleden sonra: Sabah bulunan bug'ları düzelt + yeni küçük görevler.

**Kişi A — Sabahki bug'ları düzelt + ekstra polish**

Form validation'ı güçlendir:
- Submit butonunda disable durumunda tooltip: "Tüm kategorilere puan verin"
- Fotoğraf max 3 kontrol
- Yorum 500 karakter üst sınır

Belki kullanıcı deneyim iyileştirmeleri:
- Fotoğraf seçince küçük upload progress
- Submit başarılı olunca success animation

**Kişi B — Task B6: Şikayet Sistemi**

1. `report_repository.dart` oluştur:

```dart
enum ReportReason {
  inappropriate,
  spam,
  offensive,
  misleading,
  other,
}

extension ReportReasonExt on ReportReason {
  String get label {
    switch (this) {
      case ReportReason.inappropriate: return 'Uygunsuz içerik';
      case ReportReason.spam: return 'Spam';
      case ReportReason.offensive: return 'Hakaret / ayrımcılık';
      case ReportReason.misleading: return 'Yanıltıcı bilgi';
      case ReportReason.other: return 'Diğer';
    }
  }
}

class ReportRepository {
  final _firestore = FirebaseFirestore.instance;
  
  Future<void> reportReview({
    required String reviewId,
    required String userId,
    required ReportReason reason,
    String? explanation,
  }) async {
    final docId = '${reviewId}_$userId';
    await _firestore.collection('reports').doc(docId).set({
      'reviewId': reviewId,
      'userId': userId,
      'reason': reason.name,
      'explanation': explanation,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
  
  Future<bool> hasAlreadyReported(String reviewId, String userId) async {
    final doc = await _firestore.collection('reports').doc('${reviewId}_$userId').get();
    return doc.exists;
  }
}
```

2. `report_dialog.dart`:

```dart
class ReportDialog extends ConsumerStatefulWidget {
  final ReviewModel review;
  const ReportDialog({super.key, required this.review});

  @override
  ConsumerState<ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends ConsumerState<ReportDialog> {
  ReportReason? _selectedReason;
  final _explanationController = TextEditingController();
  bool _submitting = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Yorumu Şikayet Et'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Şikayet sebebinizi seçin:', style: AppTextStyles.bodyMedium),
            const SizedBox(height: 12),
            ...ReportReason.values.map((reason) => RadioListTile<ReportReason>(
              title: Text(reason.label),
              value: reason,
              groupValue: _selectedReason,
              onChanged: (v) => setState(() => _selectedReason = v),
              dense: true,
            )),
            if (_selectedReason == ReportReason.other) ...[
              const SizedBox(height: 8),
              TextField(
                controller: _explanationController,
                maxLength: 200,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Lütfen kısaca açıklayın',
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.pop(context),
          child: Text('İptal'),
        ),
        ElevatedButton(
          onPressed: (_selectedReason == null || _submitting) ? null : _submit,
          child: _submitting 
            ? SizedBox(
                width: 20, height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text('Gönder'),
        ),
      ],
    );
  }
  
  Future<void> _submit() async {
    // Implementation
  }
}
```

3. `report_repository_provider.dart`:
```dart
final reportRepositoryProvider = Provider((_) => ReportRepository());
```

4. `ReviewActionsMenu`'deki 'report' case'ini güncelle:
```dart
case 'report':
  final user = ref.read(authStateProvider).value;
  if (user == null) {
    // Giriş yapmamış
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Şikayet etmek için giriş yapın')),
    );
    return;
  }
  
  final alreadyReported = await ref.read(reportRepositoryProvider)
    .hasAlreadyReported(review.id, user.uid);
  
  if (alreadyReported) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Bu yorumu zaten şikayet ettiniz')),
    );
    return;
  }
  
  showDialog(
    context: context,
    builder: (_) => ReportDialog(review: review),
  );
  break;
```

### 🌆 Akşam Buluşması (30dk)

**1. Şikayet Akışı Testi (10dk)**
- Başkasının yorumunu şikayet et
- Aynı yorumu tekrar şikayet etmeye çalış → engellenmeli
- Firestore console'dan `reports` collection'ına bak, doc var mı?

**2. Checkpoint 2 Sonuç Değerlendirmesi (10dk)**
- Sprintin %75'indeyiz
- Eksik ne kaldı? Liste:
  - Photo gallery viewer (nice-to-have, Task B4)
  - Department detail'da review section'ının eklenmesi (eğer eklenmemişse)
  - Edge case'ler (network kesintisi, token expired, vs)

**3. Son 2 Günün Planı (10dk)**
- Gün 9 — Büyük entegrasyon, tüm ekranlar ReviewCard kullansın
- Gün 10 — Polish, nice-to-have'ler, release

### ✅ Gün 8 Bitişinde Durum

- [x] Checkpoint 2'de tüm akışlar end-to-end çalıştı
- [x] Şikayet sistemi tam fonksiyonel
- [x] Sabahki bug'lar düzeltildi
- [x] Sprint sonuna 2 gün kaldı, panik yok

---

## 📆 GÜN 9: Büyük Entegrasyon

> **Hedef:** Tüm ekranlar tutarlı `ReviewCard` kullanıyor, photo gallery viewer (nice-to-have) ekleniyor, son büyük bug avı

### 🌅 Sabah Standupı (15dk)

Bu sabah özel: Birlikte develop branch'ini inceleyin:

```bash
git checkout develop
git pull
flutter run
```

Uygulamayı her ekrandan baştan sona gezin. Tutarsızlıkları not edin:
- Yorum kartı her ekranda aynı mı görünüyor?
- Boyutlar, renkler, spacing tutarlı mı?
- Navigation düzgün mü?

### 🌞 Gün İçi — Birlikte Pair Programming (4 saat)

Bugün ikiniz **aynı ekranda** çalışın. Ekran paylaşımı + voice call.

**Sabah 10:00 — 12:00: Büyük Swap**

Uygulamadaki TÜM yerler `ReviewCard` kullanmalı. Liste:

1. **home_screen.dart** — `_RecentReviewCard` → `ReviewCard(compact: true)` ✅ (muhtemelen dün yapıldı)
2. **university_detail_screen.dart** — `_ReviewSection` içindeki inline kart → `ReviewCard` (veya `ReviewList`) ✅ (muhtemelen Gün 5'te yapıldı)
3. **department_detail_screen.dart** — Eğer `ReviewList` eklenmediyse, ekle
4. **my_reviews_screen.dart** — `ReviewCard(showActions: true)` ✅ (Gün 7)

Her ekranı açın, test edin. Kişi biri yazsın, diğer kontrol etsin. Rolleri her 30dk değiştirin.

**Öğlen 13:00 — 14:00: Edge Case'ler**

Birlikte şu durumları test edin:

- [ ] Network kesintisi → yorum yaz, ne oluyor?
- [ ] Token expired → yorum yaz, logout oluyor mu yoksa tekrar mı denenilmeli?
- [ ] Çok uzun yorum (500 karakter) → düzgün görünüyor mu?
- [ ] 3 fotoğraf + uzun yorum + 6 kategori rating → card'da nasıl görünüyor?
- [ ] Boş fotoğraf, boş pros/cons → card minimum yüksekliği güzel mi?

**Öğleden Sonra 14:00 — 16:00: Task B4 Photo Gallery (Nice-to-Have)**

Eğer zaman yeterliyse:

1. `photo_gallery_screen.dart`:

```dart
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:cached_network_image/cached_network_image.dart';

class PhotoGalleryScreen extends StatefulWidget {
  final List<String> imageUrls;
  final int initialIndex;

  const PhotoGalleryScreen({
    super.key,
    required this.imageUrls,
    this.initialIndex = 0,
  });

  @override
  State<PhotoGalleryScreen> createState() => _PhotoGalleryScreenState();
}

class _PhotoGalleryScreenState extends State<PhotoGalleryScreen> {
  late PageController _controller;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _controller = PageController(initialPage: widget.initialIndex);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          '${_currentIndex + 1} / ${widget.imageUrls.length}',
          style: TextStyle(color: Colors.white),
        ),
      ),
      extendBodyBehindAppBar: true,
      body: PhotoViewGallery.builder(
        pageController: _controller,
        itemCount: widget.imageUrls.length,
        onPageChanged: (i) => setState(() => _currentIndex = i),
        builder: (context, index) => PhotoViewGalleryPageOptions(
          imageProvider: CachedNetworkImageProvider(widget.imageUrls[index]),
          minScale: PhotoViewComputedScale.contained,
          maxScale: PhotoViewComputedScale.covered * 2,
        ),
        backgroundDecoration: const BoxDecoration(color: Colors.black),
      ),
    );
  }
}
```

2. ReviewCard'daki foto thumbnail'larına tıklanınca bu ekranı aç:

```dart
Widget _buildPhotoGrid() {
  return Row(
    children: review.imageUrls.asMap().entries.map((e) {
      final index = e.key;
      final url = e.value;
      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(
            builder: (_) => PhotoGalleryScreen(
              imageUrls: review.imageUrls,
              initialIndex: index,
            ),
          )),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: CachedNetworkImage(
              imageUrl: url,
              width: 80,
              height: 80,
              fit: BoxFit.cover,
            ),
          ),
        ),
      );
    }).toList(),
  );
}
```

### 🌆 Akşam Buluşması (30dk)

**1. Tam Uygulama Turu (15dk)**
Açıldığı andan itibaren baştan sona uygulamayı gezin:
- Onboarding → Login → Home
- Explore → Üniversite detay → Bölüm detay
- Değerlendir → Yorum yaz
- Ana sayfadan yoruma tıkla
- Profil → Yorumlarım → Düzenle → Kaydet

Her ekran tutarlı mı? Yavaşlık yok mu? Crash yok mu?

**2. Son Bug Listesi (10dk)**
Sprint sonuna 1 gün kaldı. Kalan bug'ları önem sırasına koyun:
- Kritik (yarın mutlaka düzelt)
- Orta (yarın düzeltirsen iyi olur)
- Düşük (sprint sonrası)

**3. Yarın Planı (5dk)**
- Yarın: Son polish, nice-to-have'ler, merge to main, tag release

### ✅ Gün 9 Bitişinde Durum

- [x] Her ekran `ReviewCard` kullanıyor, tutarlı görünüm
- [x] Photo gallery viewer çalışıyor (nice-to-have tamam)
- [x] Edge case'ler ele alındı
- [x] Kalan bug'lar kategorize edildi

---

## 📆 GÜN 10: Polish & Release

> **Hedef:** Son polish, release, retrospektif

### 🌅 Sabah Standupı (15dk)

Son gün! Panik yok, 4 saatlik iş kaldı.

### 🌞 Sabah 10:00 — 13:00 — Polish (Paralel ama senkron)

**Kişi A — Sprint genelinde polish + kritik bug fix**

Aklına gelen küçük iyileştirmeler:
- Toast/snackbar mesajları tutarlı mı? ("Başarıyla kaydedildi" vs "Yorumunuz eklendi" gibi)
- Loading state'ler düzgün mü?
- Empty state'ler kullanıcı dostu mı?
- Form error mesajları Türkçe ve net mi?
- Keyboard dismiss davranışı (form alanlarının dışına tıklayınca keyboard kapansın)

**Kişi B — Timeago lokalizasyon + polish**

- `timeago.setLocaleMessages('tr', timeago.TrMessages())` çalışıyor mu?
- Tarih gösterimi "2 saat önce", "3 gün önce" gibi mi yoksa İngilizce mi görünüyor?
- ReviewCard'daki küçük detaylar (rating badge rengi, chip spacing, shadow)

**Ortak: `flutter analyze` ile Lint Temizliği**

Birlikte:
```bash
flutter analyze
```

0 warning, 0 error olmalı. Unused import'ları, unused variable'ları temizleyin.

### 🌞 Öğlen 13:00 — 14:00 — Final QA

Son bir kez birlikte test edin. Bu sefer **yeni bir kullanıcı hesabı açın** ve uygulamayı hiç görmemiş gibi kullanın.

Crash olursa, UI garipse, kafa karıştırıcı ise not alın.

### 🌞 Öğleden Sonra 14:00 — 15:30 — Release

**1. Son Merge**

```bash
# Her iki kişi son commit'lerini push etsin
git push origin feat/sprint3-creation
git push origin feat/sprint3-viewing

# develop'a merge
# PR'ları merge edin GitHub'dan

# develop → main
git checkout develop
git pull
git checkout main
git merge develop
git push origin main
```

**2. Tag'leme**

```bash
git tag -a v0.3.0 -m "Sprint 3: Review system complete"
git push origin v0.3.0
```

**3. Branch Temizliği**

```bash
git branch -d feat/sprint3-creation
git branch -d feat/sprint3-viewing
# Remote branch'leri de sil (GitHub'dan)
```

**4. README Güncelle**

`README.md`'ye sprint özeti ekle:

```markdown
## Sürüm Geçmişi

### v0.3.0 (Sprint 3) — 2026 MM DD
- Yorum yazma, düzenleme, silme
- 6 kategoride yıldız puanlaması
- Pros/cons seçimi + özel ekleme
- Fotoğraf yükleme (max 3)
- Anonim yorumlar
- Bölüm yorumları
- Optimistic like sistemi
- Yorum sıralama (en yeni / en beğenilen)
- Şikayet/raporlama sistemi
- Otomatik küfür filtresi (Cloud Function)
- Kategori bazlı ortalama rating görselleştirme
- Profilde "Yorumlarım" ekranı
```

### 🌆 Akşam 15:30 — 16:30 — Retrospektif 🎉

**1. Sprint 3'te Ne Başardık (15dk)**

Birlikte liste yapın:
- Kaç yeni dosya
- Kaç yeni özellik
- Kaç bug çözüldü

GitHub'da commit history'ye bakın, etkileyici olacak.

**2. İyi Olan Neler? (10dk)**
- Hangi anlaşmalar işe yaradı?
- Hangi sprint ritüelleri faydalıydı?
- En gurur verici özellik hangisi?

**3. Geliştirilebilecek Neler? (10dk)**
- Hangi görev beklenenden uzun sürdü?
- İletişimde nereye takıldık?
- Gelecekte neyi farklı yaparız?

**4. Sprint 4 Hazırlığı (5dk)**
Sonraki hedef: Mekanlar (kafe, yurt, çalışma alanı) + Karşılaştırma ekranı. Bunun için `implementation_planv1.md`'ye bakın.

### 🎉 Gün 10 Bitişinde Durum

- [x] `v0.3.0` production'da
- [x] README güncel
- [x] Branch'ler temiz
- [x] İki geliştirici gururlu
- [x] Sprint 4 için hazırsınız

Kendinize iyi bir akşam yemeği ve sprint kutlaması yapın ☕🍕

---

## 🚨 Blocker Protokolü

Sprint boyunca engelle karşılaşmak normal. İşte nasıl yönetmeli:

### "30 Dakika Kuralı"

Bir konuda 30 dakikadan fazla takıldıysan **dur ve yardım iste**. Google/StackOverflow'da cevap bulamamak, ekip arkadaşına sorma hakkını hak ediyorsun.

### Blocker Kategorileri

**1. Teknik Blocker (kodla ilgili)**
- Partnerin ara: "Şu hata alıyorum, sen gördün mü hiç?"
- Ekran paylaş, 5-10 dakika birlikte debug
- Cevap yoksa → atlanacak bir iş var mı? Başka göreve geç

**2. Altyapı Blocker (Firebase, deploy, rules)**
- Firestore rules bir şeyi engelliyor mu? → Console'dan test et
- Cloud Function hata mı? → Logs'a bak
- Hâlâ çözülmüyorsa partner + belki bir mentor/senior arkadaş

**3. Tasarım Blocker (ne yapmalı belirsiz)**
- Partnerin söyle: "Şu ekranda radio button mı chip mi kullanalım?"
- 5 dakikada karar verin, ilerleyin
- Mükemmel çözümü aramayın — MVP'deyiz, polish sprint sonunda

### Blocker Eskalasyonu

1. **0-30dk:** Kendin debug et
2. **30-60dk:** Partner'e sor
3. **60-120dk:** Birlikte debug, gerekirse Stack Overflow'da soru aç
4. **120+dk:** Bugünü bu göreve harcamaktan vazgeç, başka görev yap, ertesi gün taze gözle tekrar bak

### Engeli Başkasına Aktarma

Bir blocker partnerinin alanındaysa, açıkça söyle:
> "Kişi A, yorum yazarken Firestore rules'ta permission denied alıyorum. Rules'u sen güncelledin, bir bakar mısın?"

Partnerin "bugünün sonunda bakarım" diyebilir. Sen o zaman başka bir göreve geç.

---

## 🎯 Sprint Sonu Retrospektifi Şablonu

Sprint 10. günün sonundaki retrospektif için rehber:

### Ne İyi Gitti?
Örnekler:
- "Günlük standup'lar sayesinde hep aynı sayfadaydık"
- "ReviewCard API kontratını günü bir yazmak merge conflict'leri engelledi"
- "Her gün akşam sync yapmak kritikti"

### Ne Kötü Gitti?
Örnekler:
- "Gün 3'te fotoğraf upload'ı düşündüğümden uzun sürdü"
- "Cloud Function deploy ilk sefer çok sinirlendirdi"
- "Merge conflict'ler yeterince önlem almamıştım"

### Ne Öğrendik?
- Yeni Flutter package
- Yeni Firebase özelliği
- Yeni Git workflow
- Partnerin güçlü yönleri (ki bunu sonraki sprintte daha iyi değerlendirin)

### Sonraki Sprint İçin Ne Değiştirelim?
Örnekler:
- "Pair programming'i daha sık yapalım"
- "Daha küçük PR'lar açalım"
- "Test yazmaya başlayalım"

---

## 📌 Son Not

Bu takvim agresif. Gerçek hayatta işler gecikecek, bazı günler motivasyonunuz olmayacak, bazı görevler 2 katı süre alacak. Bu **normal**.

Eğer Gün 8'de Checkpoint 2'de hâlâ kritik özellikler eksikse:
- **Panik yapmayın**
- Nice-to-have'leri çıkarın (Photo gallery, bazı polish'ler)
- Gerçekçi olun: Must-have'leri bitirip sağlam bir MVP çıkmak, her şeyi yapıp crash'leyen bir uygulamadan iyidir

Ve unutmayın: İki geliştirici ilk kez birlikte çalışıyor. Birbirinize sabırlı olun, sorular sorun, yanlış yaparsanız düzeltin. Bu sprint sadece bir yorum sistemi inşa etmekle ilgili değil — birlikte **nasıl** çalışacağınızı öğrenmekle ilgili.

Başarılar 🚀

---

*Bu takvim Sprint 3 planı üzerine inşa edildi. Sorular için sprint3_plan.md ve sprint2_hardening_review.md referans alın.*
