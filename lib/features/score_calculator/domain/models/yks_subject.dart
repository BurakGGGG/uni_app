/// YKS testleri — giriş ekranı bölümleri bu gruplamayı izler.
enum YksSection { tyt, aytSay, aytEaSoz, aytSoz2, ydt }

/// YKS dersleri — soru sayısı, etiket ve test bilgisi tek doğruluk noktası.
/// UI (giriş satırları) ve model (net doğrulama) buradan beslenir.
enum YksSubject {
  tytTurkce(40, 'Türkçe', YksSection.tyt),
  tytSosyal(20, 'Sosyal Bilimler', YksSection.tyt),
  tytMat(40, 'Temel Matematik', YksSection.tyt),
  tytFen(20, 'Fen Bilimleri', YksSection.tyt),
  aytMat(40, 'Matematik', YksSection.aytSay),
  aytFizik(14, 'Fizik', YksSection.aytSay),
  aytKimya(13, 'Kimya', YksSection.aytSay),
  aytBiyo(13, 'Biyoloji', YksSection.aytSay),
  aytEdebiyat(24, 'Türk Dili ve Edebiyatı', YksSection.aytEaSoz),
  aytTarih1(10, 'Tarih-1', YksSection.aytEaSoz),
  aytCografya1(6, 'Coğrafya-1', YksSection.aytEaSoz),
  aytTarih2(11, 'Tarih-2', YksSection.aytSoz2),
  aytCografya2(11, 'Coğrafya-2', YksSection.aytSoz2),
  aytFelsefe(12, 'Felsefe Grubu', YksSection.aytSoz2),
  aytDkab(6, 'Din Kültürü', YksSection.aytSoz2),
  ydt(80, 'Yabancı Dil', YksSection.ydt);

  const YksSubject(this.maxQuestions, this.labelTr, this.section);

  final int maxQuestions;
  final String labelTr;
  final YksSection section;

  /// Tüm yanlış senaryosunda teorik en düşük net.
  double get minNet => -maxQuestions / 4.0;

  static List<YksSubject> bySection(YksSection section) =>
      values.where((s) => s.section == section).toList(growable: false);
}
