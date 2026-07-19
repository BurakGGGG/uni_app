/// Faz B — Pro uzak ayrıştırma dikişi (saf Dart, ağ yok).
///
/// Cihazdaki kural ayrıştırıcı cümleyi çözemezse (`WizardIntent.hasAny`
/// false) ve kullanıcı Pro ise, cümle `parseWizardUtterance` callable'ına
/// gider. Sunucu yalnız SEMANTİK alanlar döndürür ([RemoteParse]); istemci
/// bunları [TercihNlu.groundRemote] ile kapalı kümelere oturtur — sunucu
/// uydurması hiçbir değer filtreye giremez. Her hata null'a düşer,
/// kullanıcı "anlayamadım + çipler" davranışından fazlasını görmez.
library;

/// Sunucunun ham semantik çıkarımı — adlar serbest metindir, kimlik
/// çözümü (il adı → plaka, bölüm adı → sorgu) istemcide yapılır.
class RemoteParse {
  final String? scoreType;
  final int? rank;
  final double? score;
  final List<String> cities;
  final List<String> uniTypes;
  final List<String> languages;
  final List<String> programTypes;
  final bool? onlyScholarship;
  final List<String> depts;

  const RemoteParse({
    this.scoreType,
    this.rank,
    this.score,
    this.cities = const [],
    this.uniTypes = const [],
    this.languages = const [],
    this.programTypes = const [],
    this.onlyScholarship,
    this.depts = const [],
  });
}

abstract interface class ChatNluClient {
  Future<RemoteParse?> parse(String utterance);
}
