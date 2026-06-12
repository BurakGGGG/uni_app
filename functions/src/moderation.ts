import { onDocumentWritten } from 'firebase-functions/v2/firestore';
import * as admin from 'firebase-admin';
import badWords from './bad_words_tr.json';

/**
 * Yeni yorum oluşturulduğunda veya kullanıcı yorumu düzenlediğinde otomatik
 * küfür filtresi uygular. Temiz içerik onaylanır, uygunsuz içerik onaysız kalır.
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

export const moderateNewReview = onDocumentWritten(
  'reviews/{reviewId}',
  async (event) => {
    const before = event.data?.before.data();
    const after = event.data?.after.data();
    const afterExists = event.data?.after.exists === true;

    if (!afterExists) return;

    const review = after;
    if (!review) return;

    if (before && !hasReviewContentChanged(before, review)) {
      return;
    }

    // Tüm metin alanlarını birleştir
    const text = [
      review.comment || '',
      ...(Array.isArray(review.pros) ? review.pros : []),
      ...(Array.isArray(review.cons) ? review.cons : []),
    ].join(' ');

    if (containsBadWord(text)) {
      await event.data?.after.ref.update({
        isApproved: false,
        moderationStatus: 'auto_flagged',
        moderationReason: 'auto_flagged_language',
        moderatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      console.log(`Review ${event.params.reviewId} auto-flagged for inappropriate language.`);
    } else {
      await event.data?.after.ref.update({
        isApproved: true,
        moderationStatus: 'approved',
        moderationReason: admin.firestore.FieldValue.delete(),
        moderatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      console.log(`Review ${event.params.reviewId} approved by auto-moderation.`);
    }
  }
);

function hasReviewContentChanged(
  before: admin.firestore.DocumentData,
  after: admin.firestore.DocumentData,
): boolean {
  const fields = [
    'rating',
    'categoryRatings',
    'comment',
    'pros',
    'cons',
    'imageUrls',
    'isAnonymous',
  ];

  return fields.some((field) => stableJson(before[field]) !== stableJson(after[field]));
}

function stableJson(value: unknown): string {
  if (value === undefined) return 'undefined';
  return JSON.stringify(value);
}
