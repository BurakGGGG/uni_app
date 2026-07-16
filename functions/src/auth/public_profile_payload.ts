import * as admin from 'firebase-admin';

export function buildPublicProfileData(
  data: Record<string, unknown>,
): Record<string, unknown> {
  return {
    displayName: stringOrEmpty(data.displayName),
    photoUrl: nullableString(data.photoUrl),
    university: nullableString(data.university),
    universityId: nullableString(data.universityId),
    department: nullableString(data.department),
    grade: typeof data.grade === 'number' ? data.grade : null,
    bio: nullableString(data.bio),
    isVerifiedStudent: data.isVerifiedStudent === true,
    reviewCount: typeof data.reviewCount === 'number' ? data.reviewCount : 0,
    badges: badgesOrEmpty(data.badges),
    createdAt: data.createdAt ?? admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  };
}

function stringOrEmpty(value: unknown): string {
  return typeof value === 'string' ? value : '';
}

function nullableString(value: unknown): string | null {
  return typeof value === 'string' && value.trim().length > 0 ? value : null;
}

function badgesOrEmpty(value: unknown): Record<string, unknown> {
  return value !== null && typeof value === 'object' && !Array.isArray(value)
    ? (value as Record<string, unknown>)
    : {};
}
