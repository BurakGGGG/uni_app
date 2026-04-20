import { onDocumentCreated } from 'firebase-functions/v2/firestore';
import * as admin from 'firebase-admin';
import badWords from './bad_words_tr.json';

/**
 * Yeni yorum oluşturulduğunda otomatik küfür filtresi uygular.
 * Küfür tespit edilirse yorumu onaysız olarak işaretler (isApproved: false).
 * 
 * Kontrol edilen alanlar: comment, pros[], cons[]
 * 
 * Not: 2-3 karakterli kısa kelimeler (ör: "am", "ag", "sik") 
 * word-boundary kontrolü ile sarılarak false positive önlenir.
 */

// Kısa kelimeler için word-boundary regex oluştur, uzunlar için basit includes
const SHORT_WORD_THRESHOLD = 4;

const shortWordPatterns = badWords
  .filter((w: string) => w.length < SHORT_WORD_THRESHOLD)
  .map((w: string) => new RegExp(`(?:^|\\s|[^a-zA-ZçÇğĞıİöÖşŞüÜ])${escapeRegex(w.toLowerCase())}(?:$|\\s|[^a-zA-ZçÇğĞıİöÖşŞüÜ])`, 'i'));

const longWords = badWords
  .filter((w: string) => w.length >= SHORT_WORD_THRESHOLD)
  .map((w: string) => w.toLowerCase());

function escapeRegex(str: string): string {
  return str.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}

function containsBadWord(text: string): boolean {
  const normalized = text.toLowerCase();

  // Uzun kelimeler: basit includes yeterli
  for (const word of longWords) {
    if (normalized.includes(word)) {
      return true;
    }
  }

  // Kısa kelimeler: word-boundary regex ile kontrol (false positive önleme)
  for (const pattern of shortWordPatterns) {
    if (pattern.test(normalized)) {
      return true;
    }
  }

  return false;
}

export const moderateNewReview = onDocumentCreated(
  'reviews/{reviewId}',
  async (event) => {
    const review = event.data?.data();
    if (!review) return;

    // Tüm metin alanlarını birleştir
    const text = [
      review.comment || '',
      ...(Array.isArray(review.pros) ? review.pros : []),
      ...(Array.isArray(review.cons) ? review.cons : []),
    ].join(' ');

    if (containsBadWord(text)) {
      await event.data?.ref.update({
        isApproved: false,
        moderationReason: 'auto_flagged_language',
        moderatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      console.log(`Review ${event.params.reviewId} auto-flagged for inappropriate language.`);
    } else {
      console.log(`Review ${event.params.reviewId} passed moderation.`);
    }
  }
);
