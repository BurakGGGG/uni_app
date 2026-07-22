import 'tercih_nlu.dart';
import 'wizard_intent.dart';

/// "En iyi tıp bölümleri" tipi ÜSTÜNLÜK sorusunun tespiti.
///
/// Kullanıcı tercih listesi kurmak değil, bir bölümün Türkiye genelindeki
/// sıralamasını görmek istiyor — sohbet akışını (puan/şehir/tercih taslağı)
/// hiç kirletmeden "En İyi Bölümler" ekranına yönlendiririz.
///
/// Bölüm çıkarımı sıfırdan yapılmaz: [TercihNlu] zaten hem asset bölüm
/// sözlüğünü hem halk dilini ("doktor" → Tıp, "mühendis" → Mühendislik)
/// çözüyor; buradaki tek iş üstünlük kalıbını yakalamak.
class BestProgramsIntent {
  /// Ekranda başlık olacak bölüm adı; genel soruda ("en iyi bölümler") null.
  final String? departmentLabel;

  const BestProgramsIntent({this.departmentLabel});
}

/// Üstünlük kalıpları — katlanmış (aksansız küçük harf) biçimde.
const List<String> _superlatives = [
  'en iyi',
  'en yuksek',
  'en guclu',
  'en basarili',
  'en populer',
  'en iyisi',
  'en kaliteli',
  'en tercih edilen',
];

/// [text] bir üstünlük sorusuysa hedef bölümüyle birlikte döner, değilse null.
///
/// Ayrıştırılmış [intent] dışarıdan verilir ki çağıran ikinci kez `parse`
/// etmek zorunda kalmasın.
BestProgramsIntent? detectBestProgramsIntent(
  String text,
  WizardIntent intent,
) {
  final folded = TercihNlu.fold(text);
  final isSuperlative = _superlatives.any(folded.contains);
  if (!isSuperlative) return null;

  // Aynı cümlede puan/sıra/şehir gibi tercih sinyali varsa kullanıcı liste
  // kurmaya çalışıyordur — sohbeti bölmeyiz.
  if (intent.rank != null || intent.score != null || intent.scoreType != null) {
    return null;
  }

  return BestProgramsIntent(
    departmentLabel: intent.depts.isEmpty ? null : intent.depts.first.label,
  );
}
