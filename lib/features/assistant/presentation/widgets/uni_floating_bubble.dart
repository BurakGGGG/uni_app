import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/feature_discovery_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../router/app_router.dart';
import '../../../admin/data/analytics_service.dart';
import '../../../admin/domain/models/analytics_event.dart';
import '../../domain/insights/uni_insight.dart';
import '../../domain/robot_message.dart';
import '../../domain/robot_mood.dart';
import '../../domain/screen_tips.dart';
import '../providers/assistant_providers.dart';
import '../providers/uni_panel_providers.dart';
import '../robot_action_route.dart';
import 'robot_avatar.dart';

/// Konuşma balonu açılmadan önceki bekleme — ekran yerine otursun, kullanıcı
/// daha sekmeyi görmeden Üni lafa girmesin.
const Duration _kSpeakDelay = Duration(milliseconds: 1400);

/// Balon kendi kendine bu süre sonunda kapanır. Kullanıcı hiçbir şey yapmak
/// zorunda değil — kapatmak için uğraştıran bildirim rahatsız eder.
const Duration _kSpeechLifetime = Duration(seconds: 7);

/// Boştaki yüz ifadesi bu aralıkla değişir. Uzun tutuldu: sürekli surat
/// değiştiren bir robot sevimli değil, huzursuz görünür.
const Duration _kMoodInterval = Duration(seconds: 20);

/// Boşta dönen ifadeler — üçü de sakin. `concerned`/`urgent` yüzler yalnız
/// gerçek bir notla gelir, kendi kendine asla.
const List<RobotMood> _kIdleMoods = [
  RobotMood.happy,
  RobotMood.neutral,
  RobotMood.thinking,
];

/// Balonda duran şey: oturum selamı, ekran ipucu ya da Üni'nin bir notu.
///
/// Üçü tek tipte birleşiyor çünkü balonun davranışı aynı: aynı gecikmeyle
/// açılır, kendi kapanır. Fark eylemde ve susturmada — selamın kimliği
/// yoktur, ipucu bir yere GÖTÜRMEZ (kullanıcı zaten anlatılan ekranda).
class _Speech {
  final String text;
  final RobotMood mood;
  final RobotAction action;
  final String? actionArg;

  /// Kapatınca susturulacak not kimliği. Selamda, ipucunda ve susturulamayan
  /// notlarda (kurulum adımı, takvim geri sayımı) null.
  final String? snoozeId;

  final bool isGreeting;

  /// Ekran ipucu mu? Dokununca yalnız kapanır: "Keşfet nasıl kullanılır"
  /// balonundan başka bir ekrana atmak kullanıcıyı anlattığım yerden koparır.
  final bool isTip;

  /// Gösterim sayacının anahtarı; yalnız ipuçlarında dolu.
  final String? tipId;

  _Speech.greeting(RobotMessage message)
      : text = message.text,
        mood = message.mood,
        action = message.action,
        actionArg = message.actionArg,
        snoozeId = null,
        isGreeting = true,
        isTip = false,
        tipId = null;

  /// Balonda notun yalnız BAŞLIĞI durur; gövde panelin kartında.
  _Speech.note(UniInsight insight)
      : text = insight.title,
        mood = insight.mood,
        action = insight.action,
        actionArg = insight.actionArg,
        snoozeId = insight.dismissible ? insight.id : null,
        isGreeting = false,
        isTip = false,
        tipId = null;

  _Speech.tip(ScreenTip tip)
      : text = tip.text,
        mood = tip.mood,
        action = RobotAction.none,
        actionArg = null,
        snoozeId = null,
        isGreeting = false,
        isTip = true,
        tipId = tip.id;

  /// Kapatma düğmesi: selam ve ipucu kapatılabilir, not yalnız
  /// susturulabiliyorsa.
  bool get closable => isGreeting || isTip || snoozeId != null;
}

/// Kabuğun beş sekmesinin üstünde duran yüzen Üni.
///
/// Neden kabukta: Üni eskiden yalnız ana sayfadaki büyük karttaydı, Keşfet /
/// Karşılaştır / Listelerim / Profil'de hiç yoktu — asistan uygulamanın
/// tamamında değil tek ekranda yaşıyordu. Kart kaldırıldı (aynı ekranda iki
/// Üni olmasın), yerine her sekmede duran bu balon geçti.
///
/// Konuşma sırası: **açılışta bir kez selam** ([homeGreetingProvider] — ana
/// sayfa kartıyla birlikte kaybolan karşılama buraya taşındı), sonra
/// **açık sekmenin ipucu** ([uniScreenTipProvider]), sonra varsa Üni'nin en
/// öncelikli notu ([topInsightProvider]).
///
/// İpucu neden nottan ÖNCE: yeni bir sekmeye geçen kullanıcının ilk sorusu
/// "burası ne işe yarıyor". Not her ekranda geçerli olduğu için bekleyebilir.
/// **Ana sayfanın ipucu yoktur** — orada selam + not zaten konuşuyor.
///
/// Kurallar (sırıtmaması için hepsi gerekli):
/// * Selamın dışında **yalnız söyleyecek gerçek bir şeyi varsa** konuşur;
///   metin motorun notundan ya da ipucu tablosundan gelir, uydurma laf yok.
/// * Selam da not da uygulama açılışı boyunca **bir kez**; ipucu sekme
///   başına bir kez ve cihazda toplam [RobotMemory.screenTipMaxShows] kez.
/// * Sıradaki balon ancak öncekinin süresi dolunca açılır; kullanıcı eliyle
///   kapattıysa arkasından yenisi gelmez.
/// * Balon [_kSpeechLifetime] sonunda kendi kapanır; kapatılan not
///   [RobotMemory.insightSnooze] boyunca susar.
/// * Kaydırırken ve klavye açıkken çekilir — hiçbir içeriği kapatmaz.
/// * Uygulama turu bitmeden hiç konuşmaz (tur zaten dikkat istiyor).
class UniFloatingLayer extends ConsumerStatefulWidget {
  final Widget child;

  /// Açık sekmenin yolu (`/explore`, `/my-lists`…). İpucu buna göre seçilir.
  final String currentPath;

  /// Açık sekmenin kendi FAB'ı varsa (Listelerim'in "yeni liste" düğmesi)
  /// balon onun üstüne çıkar — iki yuvarlak üst üste binmesin.
  final bool liftAboveFab;

  const UniFloatingLayer({
    super.key,
    required this.child,
    this.currentPath = '/',
    this.liftAboveFab = false,
  });

  /// Uygulama açılışı boyunca konuşulmuş not id'leri. Statik: sekme
  /// değişiminde katman yeniden kurulsa da aynı not tekrar etmesin.
  static final Set<String> _spokenThisSession = {};

  /// İpucu verilmiş sekmeler. Sekmeler arasında gidip gelmek aynı tanıtımı
  /// tekrar ettirmesin; kalıcı sınır [RobotMemory]'de.
  static final Set<String> _tippedThisSession = {};

  /// Selam oturumda bir kez. Aynı gerekçe: kabuk yeniden kurulsa da Üni her
  /// seferinde "merhaba" dememeli.
  static bool _greetedThisSession = false;

  /// Statik alanlar testler arasında sızar — her test kendi oturumundan
  /// başlasın. [greeted] true verilirse selam adımı atlanır: notlarla ilgili
  /// testler selamın arkasında beklemek zorunda kalmasın.
  @visibleForTesting
  static void resetSpokenSession({bool greeted = false}) {
    _spokenThisSession.clear();
    _tippedThisSession.clear();
    _greetedThisSession = greeted;
  }

  @override
  ConsumerState<UniFloatingLayer> createState() => _UniFloatingLayerState();
}

class _UniFloatingLayerState extends ConsumerState<UniFloatingLayer> {
  _Speech? _speech;
  bool _scrolledAway = false;
  int _moodIndex = 0;

  Timer? _speakTimer;
  Timer? _closeTimer;
  Timer? _moodTimer;

  @override
  void initState() {
    super.initState();
    _moodTimer = Timer.periodic(_kMoodInterval, (_) {
      if (!mounted) return;
      setState(() => _moodIndex = (_moodIndex + 1) % _kIdleMoods.length);
    });
    // İlk not katman kurulmadan önce hazır olabilir; `ref.listen` yalnız
    // DEĞİŞİMDE tetiklendiği için ilk turu elle başlat.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _scheduleSpeech();
    });
  }

  @override
  void dispose() {
    _speakTimer?.cancel();
    _closeTimer?.cancel();
    _moodTimer?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant UniFloatingLayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentPath == widget.currentPath) return;
    // Yalnız İPUCU kapanır: Keşfet'i anlatan cümlenin Profil'de asılı kalması
    // kafa karıştırır. Selam ve notlar sekmeden bağımsız, sözleri kesilmez —
    // süreleri dolunca zaten sıradaki (yeni sekmenin) ipucuna geçerler.
    if (_speech?.isTip ?? false) _closeSpeech();
    _scheduleSpeech();
  }

  /// Sırada ne var: oturum selamı (bir kez) → açık sekmenin ipucu → Üni'nin
  /// notu. Söylenecek bir şey kalmadıysa null.
  _Speech? _nextSpeech() {
    if (!UniFloatingLayer._greetedThisSession) {
      return _Speech.greeting(ref.read(homeGreetingProvider));
    }
    final tip = _pendingTip();
    if (tip != null) return _Speech.tip(tip);

    final insight = ref.read(topInsightProvider);
    if (insight == null ||
        UniFloatingLayer._spokenThisSession.contains(insight.id)) {
      return null;
    }
    return _Speech.note(insight);
  }

  /// Bu sekmede henüz söylenmemiş ve cihazda kotası dolmamış ipucu.
  ScreenTip? _pendingTip() {
    if (UniFloatingLayer._tippedThisSession.contains(widget.currentPath)) {
      return null;
    }
    final tip = ref.read(uniScreenTipProvider(widget.currentPath));
    if (tip == null) return null;
    return ref.read(robotMemoryProvider).canShowScreenTip(tip.id) ? tip : null;
  }

  void _scheduleSpeech() {
    if (_speech != null || _scrolledAway) return;
    // Tur sürerken Üni susar; iki dikkat çeken şey aynı anda olmaz.
    if (!ref
        .read(featureDiscoveryProvider)
        .isCompleted(FeatureDiscoveryService.homeCompleted)) {
      return;
    }
    final next = _nextSpeech();
    if (next == null) return;

    _speakTimer?.cancel();
    _speakTimer = Timer(_kSpeakDelay, () {
      if (!mounted || _scrolledAway) return;
      setState(() {
        _speech = next;
        if (next.isGreeting) {
          UniFloatingLayer._greetedThisSession = true;
        } else if (next.tipId != null) {
          UniFloatingLayer._tippedThisSession.add(widget.currentPath);
          unawaited(
            ref.read(robotMemoryProvider).recordScreenTipShown(next.tipId!),
          );
        } else if (next.snoozeId != null) {
          UniFloatingLayer._spokenThisSession.add(next.snoozeId!);
        }
      });
      _closeTimer?.cancel();
      // Süresi dolunca sıradakine geç: selamın ardından not gelir.
      _closeTimer = Timer(_kSpeechLifetime, () {
        _closeSpeech();
        _scheduleSpeech();
      });
    });
  }

  void _closeSpeech() {
    _speakTimer?.cancel();
    _closeTimer?.cancel();
    if (!mounted || _speech == null) return;
    setState(() => _speech = null);
  }

  /// Kapatma = "bunu şimdilik duymak istemiyorum": not susturulur
  /// ([RobotMemory.insightSnooze] kadar), sonra geri gelir. Kullanıcı balonu
  /// eliyle kapattıysa sıradaki hemen ARDINDAN açılmaz — susturduğu şeyin
  /// yerine yenisini koymak dırdır olur.
  Future<void> _dismissSpeech() async {
    final id = _speech?.snoozeId;
    _closeSpeech();
    if (id == null) return;
    await ref.read(robotMemoryProvider).dismissInsight(id);
    if (!mounted) return;
    // Susturma shared_preferences'ta; provider onu izlemiyor.
    ref.invalidate(insightContextProvider);
  }

  bool _onScroll(UserScrollNotification notification) {
    final away = notification.direction == ScrollDirection.reverse;
    if (away && _speech != null) _closeSpeech();
    if (away != _scrolledAway) {
      setState(() => _scrolledAway = away);
      // Kaydırma bitince sırada bekleyen varsa açılsın.
      if (!away) _scheduleSpeech();
    }
    return false; // bildirimi yutma — asıl dinleyiciler de görsün
  }

  void _openPanel() {
    _closeSpeech();
    navigateToRoute(context, AppRoutes.uniPanel);
  }

  /// Balona dokunmak mesajın kendi eylemine gider (varlık sebebi o);
  /// avatara dokunmak her zaman Üni'nin evine. İkisi ayrı bilinçli: hedefi
  /// mesaja göre değişen tek bir düğme kullanıcıyı şaşırtır.
  void _followSpeech() {
    final speech = _speech;
    if (speech == null) return;
    // İpucu anlattığı ekranın üstünde duruyor; dokunuş onu yalnız kapatır.
    if (speech.isTip) {
      _closeSpeech();
      return;
    }
    final route = robotActionRoute(speech.action, arg: speech.actionArg);
    _closeSpeech();
    if (route == null) {
      navigateToRoute(context, AppRoutes.uniPanel);
      return;
    }
    if (!speech.isGreeting) {
      AnalyticsService.instance.trackEvent(AnalyticsEvent.uniInsightTapped);
    }
    navigateToRoute(context, route);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<UniInsight?>(topInsightProvider, (_, _) => _scheduleSpeech());

    final insight = ref.watch(topInsightProvider);
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    final visible = !keyboardOpen && !_scrolledAway;
    final speech = _speech;

    return Stack(
      children: [
        NotificationListener<UserScrollNotification>(
          onNotification: _onScroll,
          child: widget.child,
        ),
        AnimatedPositioned(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          left: 16,
          right: 16,
          bottom: 16 + (widget.liftAboveFab ? 72 : 0),
          child: AnimatedSlide(
            offset: visible ? Offset.zero : const Offset(0, 1.6),
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeOut,
            child: AnimatedOpacity(
              opacity: visible ? 1 : 0,
              duration: const Duration(milliseconds: 200),
              // Boş alan dokunuşu yutmaz: Row yalnız çocuklarının olduğu
              // yerde hit test alır, kalanı alttaki içeriğe geçer.
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (speech != null)
                    Flexible(
                      child: _SpeechCard(
                        speech: speech,
                        onTap: _followSpeech,
                        onClose: _dismissSpeech,
                      ),
                    ),
                  const SizedBox(width: 8),
                  _AvatarButton(
                    mood: speech?.mood ?? _kIdleMoods[_moodIndex],
                    alert: speech == null && _needsAttention(insight),
                    onTap: _openPanel,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Rozet yalnız gerçekten dikkat isteyen notta yanar. Her notta yansaydı
  /// (ör. "YKS'ye 120 gün") kalıcı kırmızı nokta olur ve anlamını yitirirdi.
  static bool _needsAttention(UniInsight? insight) =>
      insight != null &&
      (insight.tone == InsightTone.urgent ||
          insight.tone == InsightTone.warning);
}

/// Üni'nin yüzü — dokununca paneli açar.
class _AvatarButton extends StatelessWidget {
  final RobotMood mood;
  final bool alert;
  final VoidCallback onTap;

  const _AvatarButton({
    required this.mood,
    required this.alert,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Üni',
      child: GestureDetector(
        onTap: onTap,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                // Marka gradyanlı robot beyaz daire üstünde okunur — ana
                // sayfa kartındaki ile aynı kural.
                color: AppColors.surfaceFor(context),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.25),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.28),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Center(child: RobotAvatar(size: 38, mood: mood)),
            ),
            if (alert)
              Positioned(
                right: 2,
                top: 2,
                child: Container(
                  width: 13,
                  height: 13,
                  decoration: BoxDecoration(
                    color: AppColors.error,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.surfaceFor(context),
                      width: 2,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Avatarın yanında açılan minik konuşma balonu — tek satırlık mesaj.
///
/// Notlarda gövde bilerek yok: yüzen balon okunacak yer değil, davet.
/// Ayrıntı bir dokunuş ötede, panelin kartında.
class _SpeechCard extends StatelessWidget {
  final _Speech speech;
  final VoidCallback onTap;
  final VoidCallback onClose;

  const _SpeechCard({
    required this.speech,
    required this.onTap,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
        decoration: BoxDecoration(
          color: AppColors.surfaceFor(context),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
            bottomLeft: Radius.circular(18),
            bottomRight: Radius.circular(4),
          ),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.28)),
          boxShadow: AppColors.cardShadowFor(context),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                speech.text,
                style: AppTextStyles.bodySmall.copyWith(
                  fontWeight: FontWeight.w700,
                  height: 1.35,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (speech.closable)
              IconButton(
                tooltip: 'Kapat',
                icon: Icon(
                  Icons.close_rounded,
                  size: 15,
                  color: AppColors.textTertiaryFor(context),
                ),
                visualDensity: VisualDensity.compact,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                padding: EdgeInsets.zero,
                onPressed: onClose,
              )
            else
              const SizedBox(width: 6),
          ],
        ),
      ),
    );
  }
}
