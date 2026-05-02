# Firebase Admin Setup & Security Rules

## Admin Claim Tanımlama
Seed data'yı (ve şehir, üniversite, bölüm gibi core verileri) sadece admin yetkisi olan kullanıcılar ekleyip düzenleyebilir.
Bir kullanıcıya admin yetkisi vermek için Firebase Admin SDK kullanarak `customUserClaims` tanımlamanız gerekir.

### Node.js (Admin SDK) ile:
```javascript
const admin = require('firebase-admin');
admin.initializeApp();

const uid = 'YOUR_ADMIN_UID';
admin.auth().setCustomUserClaims(uid, {admin: true})
  .then(() => {
    console.log('Admin claim set for user', uid);
  });
```

Not: Kullanıcıya claim eklendikten sonra, token'ın güncellenmesi için kullanıcının çıkış yapıp tekrar girmesi veya token'ı zorla yenilemesi gerekir.

## Public Profile Güvenliği (v3 Planı)
Şu anda `users/{userId}` koleksiyonu `allow read: if true;` kuralı ile herkese açıktır. Uygulama içinde (client-side) e-posta gibi hassas bilgiler `getPublicProfile()` ile maskeleniyor (nullify ediliyor). 
Ancak, gerçek Firestore güvenliği sağlamak (field-level security) için **v3** sürümünde aşağıdaki yapıya geçilmelidir:

1. Hassas `users` koleksiyonu okumaya kapatılmalı (`allow read: if request.auth.uid == userId;`).
2. Public alanlar (`displayName`, `photoUrl`, `universityId`, `departmentId` vb.) için bir `publicProfiles` koleksiyonu (veya subcollection) oluşturulmalı.
3. Kullanıcı kendi profilini güncellediğinde, bir Firebase Cloud Function (`onWrite` veya `onUpdate` trigger) çalışarak ilgili verileri `publicProfiles` tablosuna senkronize etmeli.
4. Diğer kullanıcıların profil okumaları bu `publicProfiles` koleksiyonundan yapılmalı.
