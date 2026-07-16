import { onDocumentWritten } from 'firebase-functions/v2/firestore';
import { evaluateFavoriteBadges } from '../badges/award_badges';

/**
 * Favori eklendiğinde koleksiyon rozetlerini (collector, master_collector)
 * sunucu tarafında değerlendirir. İstemcinin bir olay göndermesine bağlı
 * DEĞİLDİR — favori dokümanı yazıldığı an tetiklenir (yorum/beğeni
 * rozetleriyle aynı desen). Rozetler geri alınmadığından yalnız yeni
 * favori (create) tetikler.
 */
export const syncUserFavoriteBadges = onDocumentWritten(
  {
    region: 'europe-west1',
    document: 'users/{userId}/favorites/{favoriteId}',
  },
  async (event) => {
    const existedBefore = event.data?.before.exists ?? false;
    const existsAfter = event.data?.after.exists ?? false;

    // Yalnız yeni favori eklemede değerlendir (silme rozet etkilemez).
    if (existedBefore || !existsAfter) return;

    await evaluateFavoriteBadges(event.params.userId);
  },
);
