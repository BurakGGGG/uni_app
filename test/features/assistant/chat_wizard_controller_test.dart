import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uni_app/core/providers/shared_preferences_provider.dart';
import 'package:uni_app/features/assistant/domain/chat_models.dart';
import 'package:uni_app/features/assistant/domain/chat_nlu_client.dart';
import 'package:uni_app/features/assistant/presentation/providers/chat_wizard_providers.dart';
import 'package:uni_app/features/monetization/domain/enums/subscription_tier.dart';
import 'package:uni_app/features/monetization/presentation/providers/subscription_providers.dart';
import 'package:uni_app/features/preference_wizard/domain/models/student_score_profile.dart';
import 'package:uni_app/features/preference_wizard/presentation/providers/preference_wizard_providers.dart';
import 'package:uni_app/features/score_calculator/presentation/providers/score_calculator_providers.dart';
import 'package:uni_app/features/university/domain/models/department_model.dart';
import 'package:uni_app/features/university/domain/models/university_model.dart';
import 'package:uni_app/features/university/presentation/providers/university_providers.dart';

/// Kayıtlı sahte uzak ayrıştırıcı (Faz B).
class _FakeNluClient implements ChatNluClient {
  final RemoteParse? result;
  int calls = 0;
  _FakeNluClient({this.result});

  @override
  Future<RemoteParse?> parse(String utterance) async {
    calls++;
    return result;
  }
}

/// Controller'ı gerçek provider zinciriyle (mock storage + boş veri seti)
/// uçtan uca sürer: sohbet → onay → arama → profil kaydı → done.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<ProviderContainer> makeContainer({
    SubscriptionTier tier = SubscriptionTier.free,
    ChatNluClient? nluClient,
  }) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      allScoredDepartmentsProvider
          .overrideWith((ref) async => <DepartmentModel>[]),
      allUniversitiesProvider
          .overrideWith((ref) async => <UniversityModel>[]),
      subscriptionTierProvider.overrideWith((ref) => Stream.value(tier)),
      if (nluClient != null)
        chatNluClientProvider.overrideWithValue(nluClient),
    ]);
    addTearDown(container.dispose);
    return container;
  }

  // autoDispose controller test boyunca canlı kalsın. Controller İLK
  // dinlemede kurulur — dönen-kullanıcı testinde profil bundan önce
  // kaydedilmeli.
  void keepChatAlive(ProviderContainer container) =>
      container.listen(chatWizardControllerProvider, (_, _) {});

  ChatChip chipLabeled(ChatWizardState s, String label) =>
      s.chips.firstWhere((c) => c.label == label);

  test('yeni kullanıcı: selamlama + puan türü çipleri', () async {
    final container = await makeContainer();
    keepChatAlive(container);
    final state = container.read(chatWizardControllerProvider);

    final first = state.turns.first as UniChatTurn;
    expect(first.message.id, 'chat.hello.new');
    expect(state.step, ChatStep.scoreInfo);
    expect(state.chips.map((c) => c.label), contains('SAY'));
  });

  test('uçtan uca: yaz → çiple geç → ara → profil kaydolur, done', () async {
    final container = await makeContainer();
    keepChatAlive(container);
    final controller = container.read(chatWizardControllerProvider.notifier);

    await controller.sendText('sayısal 80 bin');
    var state = container.read(chatWizardControllerProvider);
    expect(state.draft.scoreType, 'SAY');
    expect(state.draft.rank, 80000);
    expect(state.step, ChatStep.interests);
    // Kullanıcı balonu akışa düştü.
    expect(state.turns.whereType<UserChatTurn>().single.text,
        'sayısal 80 bin');

    await controller.tapChip(chipLabeled(state, 'Farketmez'));
    state = container.read(chatWizardControllerProvider);
    expect(state.step, ChatStep.constraints);

    await controller.tapChip(chipLabeled(state, 'Farketmez'));
    state = container.read(chatWizardControllerProvider);
    expect(state.step, ChatStep.confirm);
    final confirm = (state.turns.last as UniChatTurn).message;
    expect(confirm.id, 'chat.confirm');
    expect(confirm.text, contains('tahmin'));

    final effect =
        await controller.tapChip(chipLabeled(state, 'Ara 🔍'));
    expect(effect, ChatEffect.none); // arama içeride tüketilir
    state = container.read(chatWizardControllerProvider);
    expect(state.busy, isFalse);
    expect(state.step, ChatStep.done);

    // Profil gerçekten kaydedildi (yalnız sıralamayla → puan 0).
    final profile = container.read(studentScoreProfileProvider)!;
    expect(profile.scoreType, 'SAY');
    expect(profile.rank, 80000);
    expect(profile.placementScore, 0);

    // Arama balonu + özet düştü; boş veri setinde önizleme kartı yok.
    final ids = state.turns
        .whereType<UniChatTurn>()
        .map((t) => t.message.id)
        .toList();
    expect(ids, contains('chat.searching'));
    expect(ids.last, startsWith('results.empty'));
    expect(state.turns.whereType<PreviewChatTurn>(), isEmpty);
    expect(state.chips.map((c) => c.label), contains('Tümünü gör'));

    final nav =
        await controller.tapChip(chipLabeled(state, 'Tümünü gör'));
    expect(nav, ChatEffect.goResults);
  });

  test('dönen kullanıcı: profil özeti + hızlı yol', () async {
    final container = await makeContainer();
    await container.read(studentScoreProfileProvider.notifier).save(
          StudentScoreProfile(
            scoreType: 'EA',
            placementScore: 0,
            rank: 120000,
            year: 2026,
            updatedAt: DateTime(2026, 7, 19),
          ),
        );

    keepChatAlive(container);
    final state = container.read(chatWizardControllerProvider);
    final first = state.turns.first as UniChatTurn;
    expect(first.message.id, 'chat.hello.back');
    expect(first.message.text, contains('EA'));
    expect(first.message.text, contains('120.000'));
    expect(state.chips.map((c) => c.label), contains('Sonuçlara geç'));
  });

  test('hesaplayıcı köprüsü etkisi ekrana döner', () async {
    final container = await makeContainer();
    keepChatAlive(container);
    final controller = container.read(chatWizardControllerProvider.notifier);

    await controller.sendText('say');
    final state = container.read(chatWizardControllerProvider);
    final calcChip = state.chips
        .firstWhere((c) => c.command == ChatCommand.calcScore);
    final effect = await controller.tapChip(calcChip);
    expect(effect, ChatEffect.goCalculator);
  });

  group('Faz B — uzak ayrıştırma', () {
    // Kurallar çözemez, sunucu İzmir çıkarır.
    const garbled = 'ege tarafinda deniz kenarinda bi yer olsun';

    test('ücretsiz kullanıcıda sunucu HİÇ aranmaz', () async {
      final fake = _FakeNluClient(
          result: const RemoteParse(cities: ['İzmir']));
      final container = await makeContainer(nluClient: fake);
      keepChatAlive(container);
      final controller =
          container.read(chatWizardControllerProvider.notifier);

      await controller.sendText(garbled);
      expect(fake.calls, 0);
      final state = container.read(chatWizardControllerProvider);
      final last = (state.turns.last as UniChatTurn).message;
      expect(last.id, 'chat.confused');
    });

    test('Pro: çözülemeyen cümle sunucudan gelir ve taslağa oturur',
        () async {
      final fake = _FakeNluClient(
          result: const RemoteParse(cities: ['İzmir']));
      final container = await makeContainer(
          tier: SubscriptionTier.pro, nluClient: fake);
      keepChatAlive(container);
      final controller =
          container.read(chatWizardControllerProvider.notifier);
      // Tier stream'inin valueOrNull'a düşmesi için bir tur bekle.
      await container.read(subscriptionTierProvider.future);

      await controller.sendText(garbled);
      expect(fake.calls, 1);
      final state = container.read(chatWizardControllerProvider);
      expect(state.draft.cityIds, {'35'});
      expect(state.busy, isFalse);
    });

    test('Pro: sunucu da çözemezse "anlayamadım"a düşer', () async {
      final fake = _FakeNluClient(result: null);
      final container = await makeContainer(
          tier: SubscriptionTier.pro, nluClient: fake);
      keepChatAlive(container);
      final controller =
          container.read(chatWizardControllerProvider.notifier);
      await container.read(subscriptionTierProvider.future);

      await controller.sendText(garbled);
      expect(fake.calls, 1);
      final state = container.read(chatWizardControllerProvider);
      final last = (state.turns.last as UniChatTurn).message;
      expect(last.id, 'chat.confused');
      expect(state.busy, isFalse);
    });

    test('kurallar çözüyorsa Pro bile olsa sunucuya gidilmez', () async {
      final fake = _FakeNluClient(
          result: const RemoteParse(cities: ['İzmir']));
      final container = await makeContainer(
          tier: SubscriptionTier.pro, nluClient: fake);
      keepChatAlive(container);
      final controller =
          container.read(chatWizardControllerProvider.notifier);
      await container.read(subscriptionTierProvider.future);

      await controller.sendText('sıralamam 80 bin');
      expect(fake.calls, 0);
    });
  });
}
