import 'robot_mood.dart';
import 'robot_scripts.dart';

/// Bir sekmeye özel Üni repliği: "burası ne işe yarar, nasıl kullanılır".
///
/// Notlardan ([UniInsight]) ayrı bir tür çünkü işi başka: not kullanıcının
/// VERİSİ hakkında bir şey söyler ("listende güvenli tercih yok"), ipucu
/// EKRAN hakkında. İkisi tek havuza atılsaydı ipuçları not sıralamasına
/// girip öncelik kavgası çıkarırdı.
class ScreenTip {
  /// `screen.explore` gibi sabit kimlik — metin tablosunun anahtarı, aynı
  /// zamanda "kaç kez gösterildi" sayacının anahtarı.
  final String id;

  final RobotMood mood;

  /// Metindeki `{...}` yer tutucuları.
  final Map<String, String> values;

  const ScreenTip(this.id, {this.mood = RobotMood.happy, this.values = const {}});

  /// Yer tutucuları doldurulmuş balon metni.
  String get text {
    var out = RobotScripts.screenTip(id);
    values.forEach((key, value) => out = out.replaceAll('{$key}', value));
    return out;
  }
}

/// İpucu kararının girdileri. Saf veri — widget'lar buraya dolduruyor,
/// karar mantığı Riverpod'suz test edilebilir kalıyor.
class ScreenTipContext {
  /// Açık sekmenin yolu (`/explore`, `/my-lists`…).
  final String path;

  final bool signedIn;

  /// Kullanıcının en dolu tercih listesindeki program sayısı.
  final int listCount;

  /// Hiç tercih listesi var mı? (Boş liste kurulmuş olabilir.)
  final bool hasAnyList;

  const ScreenTipContext({
    required this.path,
    this.signedIn = false,
    this.listCount = 0,
    this.hasAnyList = false,
  });
}

/// ÖSYM tercih hakkı — ipucu metinlerindeki "24" ile aynı sayı.
const int _kListCapacity = 24;

/// İpuçlu sekmelerin yol önekleri. [uniScreenTip] ile aynı listeye bakarlar;
/// eşliği test kilitliyor.
const List<String> _kTippedPrefixes = [
  '/explore',
  '/compare',
  '/my-lists',
  '/profile',
];

/// [path] için tanımlı bir ipucu var mı?
///
/// Bağlam TOPLAMADAN sorulabilsin diye ayrı: ana sayfada ipucu yok, oraya
/// gelen bir kullanıcı için tercih listesi akışını dinlemeye (Firestore)
/// başlamanın anlamı yok.
bool screenHasTip(String path) => _kTippedPrefixes.any(path.startsWith);

/// [ctx] için söylenecek ipucu; o ekranda söyleyecek bir şey yoksa null.
///
/// **Ana sayfanın ipucu YOKTUR:** orada Üni zaten selamlıyor ve notlarını
/// söylüyor; bir de "burası ana sayfa" demek gereksiz konuşma olur.
ScreenTip? uniScreenTip(ScreenTipContext ctx) {
  // Alt rotalar da sekmeye sayılır: `/my-lists/abc` hâlâ Listelerim'dir.
  final path = ctx.path;

  if (path.startsWith('/explore')) {
    return const ScreenTip('screen.explore');
  }

  // Karşılaştırma sekmesi bir SEÇİM ekranı: asıl karşılaştırma push edilen
  // rotada açılıyor (balon oraya çıkmaz). Bu yüzden tek ipucu, ve yalnız
  // ücretsiz yolu (üniversite) anlatır — bölüm/şehir Plus'lı, Üni satış
  // yapmaz.
  if (path.startsWith('/compare')) {
    return const ScreenTip('screen.compare', mood: RobotMood.thinking);
  }

  if (path.startsWith('/my-lists')) {
    if (!ctx.signedIn) return const ScreenTip('screen.lists.guest');
    if (!ctx.hasAnyList || ctx.listCount == 0) {
      return const ScreenTip('screen.lists.empty');
    }
    if (ctx.listCount >= _kListCapacity) {
      return const ScreenTip(
        'screen.lists.full',
        mood: RobotMood.celebrating,
        values: {'count': '$_kListCapacity'},
      );
    }
    return ScreenTip(
      'screen.lists.partial',
      values: {
        'count': '${ctx.listCount}',
        'remaining': '${_kListCapacity - ctx.listCount}',
      },
    );
  }

  if (path.startsWith('/profile')) {
    return ctx.signedIn
        ? const ScreenTip('screen.profile')
        : const ScreenTip('screen.profile.guest');
  }

  return null;
}
