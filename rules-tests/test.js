const {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} = require('@firebase/rules-unit-testing');
const { serverTimestamp } = require('firebase/firestore');
const { readFileSync } = require('fs');
const path = require('path');

let testEnv;

before(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: 'unisec-test-rules',
    firestore: {
      rules: readFileSync(path.resolve(__dirname, '../firestore.rules'), 'utf8'),
    },
  });
});

after(async () => {
  await testEnv.cleanup();
});

beforeEach(async () => {
  await testEnv.clearFirestore();
});

function authed(
  uid,
  email = `${uid}@example.edu.tr`,
  verified = true,
  extraClaims = {},
) {
  return testEnv.authenticatedContext(uid, {
    email,
    email_verified: verified,
    ...extraClaims,
  });
}

function validUserData(email = 'user@example.edu.tr') {
  return {
    displayName: 'Test User',
    email,
    photoUrl: null,
    isVerifiedStudent: false,
    university: null,
    universityId: null,
    department: null,
    grade: null,
    bio: null,
    role: 'user',
    reviewCount: 0,
    notificationPrefs: {
      reviewLikedEnabled: true,
      reviewModeratedEnabled: true,
      favoriteNewReviewEnabled: true,
    },
    createdAt: new Date(),
    lastLoginAt: new Date(),
  };
}

async function seedUser(uid, data = {}) {
  await testEnv.withSecurityRulesDisabled(async (context) => {
    await context
      .firestore()
      .collection('users')
      .doc(uid)
      .set({
        ...validUserData(`${uid}@example.edu.tr`),
        ...data,
      });
  });
}

function validReviewData(userId = 'user_1', data = {}) {
  return {
    type: 'university',
    targetId: 'uni_1',
    universityId: 'uni_1',
    userId,
    userName: 'Test User',
    userPhotoUrl: null,
    userUniversity: 'Test University',
    rating: 4,
    categoryRatings: {
      genel: 4,
    },
    comment: 'Bu universite hakkinda yeterince detayli ve temiz bir yorum.',
    pros: ['Kampus'],
    cons: [],
    imageUrls: [],
    likes: 0,
    isAnonymous: false,
    isApproved: false,
    createdAt: serverTimestamp(),
    updatedAt: serverTimestamp(),
    ...data,
  };
}

async function seedReview(reviewId = 'review_1', data = {}) {
  await testEnv.withSecurityRulesDisabled(async (context) => {
    await context
      .firestore()
      .collection('reviews')
      .doc(reviewId)
      .set({
        ...validReviewData('user_1', {
          createdAt: new Date(),
          updatedAt: new Date(),
        }),
        ...data,
      });
  });
}

function validPreferenceItem(data = {}) {
  return {
    deptId: 'dept_1',
    uniId: 'uni_1',
    order: 1,
    deptName: 'Bilgisayar Mühendisliği',
    uniName: 'Test University',
    scoreType: 'SAY',
    baseScore: 450.12,
    ranking: 12000,
    quota: 80,
    placedCount: 80,
    uniBrandHex: '#123ABC',
    ...data,
  };
}

function validPreferenceListData(userId = 'user_1', data = {}) {
  return {
    userId,
    userName: 'Test User',
    userPhotoUrl: null,
    title: 'Tercih Listem',
    description: 'Güvenli tercih listesi',
    isPublic: false,
    shareSlug: 'ab23cd45',
    viewCount: 0,
    items: [],
    createdAt: serverTimestamp(),
    updatedAt: serverTimestamp(),
    ...data,
  };
}

async function seedPreferenceList(listId = 'list_1', data = {}) {
  await testEnv.withSecurityRulesDisabled(async (context) => {
    await context
      .firestore()
      .collection('preferenceLists')
      .doc(listId)
      .set({
        ...validPreferenceListData('user_1', {
          createdAt: new Date(),
          updatedAt: new Date(),
        }),
        ...data,
      });
  });
}

describe('Firestore Security Rules - users hardening', () => {
  it('owner can create a safe user doc', async () => {
    const ctx = authed('user_1', 'user_1@example.edu.tr');

    await assertSucceeds(
      ctx
        .firestore()
        .collection('users')
        .doc('user_1')
        .set(validUserData('user_1@example.edu.tr')),
    );
  });

  it('owner cannot create themselves as admin', async () => {
    const ctx = authed('user_1', 'user_1@example.edu.tr');

    await assertFails(
      ctx
        .firestore()
        .collection('users')
        .doc('user_1')
        .set({
          ...validUserData('user_1@example.edu.tr'),
          role: 'admin',
        }),
    );
  });

  it('owner can update safe profile fields', async () => {
    await seedUser('user_1');
    const ctx = authed('user_1');

    await assertSucceeds(
      ctx.firestore().collection('users').doc('user_1').update({
        displayName: 'Updated User',
        bio: 'Yeni bio',
      }),
    );
  });

  it('owner cannot update sensitive fields on users doc', async () => {
    await seedUser('user_1');
    const ctx = authed('user_1');
    const ref = ctx.firestore().collection('users').doc('user_1');

    await assertFails(ref.update({ role: 'admin' }));
    await assertFails(ref.update({ email: 'other@example.edu.tr' }));
    await assertFails(ref.update({ universityId: 'itu' }));
    await assertFails(ref.update({ isVerifiedStudent: true }));
    await assertFails(ref.update({ reviewCount: 999 }));
    await assertFails(ref.update({ fcmTokens: ['token'] }));
  });

  it('other users cannot read private user docs', async () => {
    await seedUser('user_1');
    await seedUser('user_2');
    const ctx = authed('user_2');

    await assertFails(
      ctx.firestore().collection('users').doc('user_1').get(),
    );
  });

  it('public profiles are readable but not client writable', async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      await context.firestore().collection('publicProfiles').doc('user_1').set({
        displayName: 'Public User',
      });
    });

    const ctx = authed('user_1');
    await assertSucceeds(
      ctx.firestore().collection('publicProfiles').doc('user_1').get(),
    );
    await assertFails(
      ctx.firestore().collection('publicProfiles').doc('user_1').set({
        displayName: 'Tampered',
      }),
    );
  });

  it('owner can write their FCM token subcollection but not another user token', async () => {
    await seedUser('user_1');
    await seedUser('user_2');
    const ctx = authed('user_1');

    await assertSucceeds(
      ctx
        .firestore()
        .collection('users')
        .doc('user_1')
        .collection('fcmTokens')
        .doc('token_doc')
        .set({
          token: 'token-value',
          platform: 'android',
          createdAt: new Date(),
          updatedAt: new Date(),
        }),
    );

    await assertFails(
      ctx
        .firestore()
        .collection('users')
        .doc('user_2')
        .collection('fcmTokens')
        .doc('token_doc')
        .set({
          token: 'token-value',
          platform: 'android',
          createdAt: new Date(),
          updatedAt: new Date(),
        }),
    );
  });
});

describe('Firestore Security Rules - admin custom claims', () => {
  it('custom claim admin can write admin-managed collections', async () => {
    await seedUser('admin_user', { role: 'user' });
    const ctx = authed('admin_user', 'admin@example.edu.tr', true, {
      admin: true,
    });

    await assertSucceeds(
      ctx.firestore().collection('cities').doc('34').set({ name: 'İstanbul' }),
    );
  });

  it('legacy role admin without custom claim cannot write admin-managed collections', async () => {
    await seedUser('legacy_admin_user', { role: 'admin' });
    const ctx = authed('legacy_admin_user', 'legacy@example.edu.tr');

    await assertFails(
      ctx.firestore().collection('cities').doc('35').set({ name: 'İzmir' }),
    );
  });

  it('custom claim admin can read private user docs', async () => {
    await seedUser('user_1');
    const ctx = authed('admin_user', 'admin@example.edu.tr', true, {
      admin: true,
    });

    await assertSucceeds(
      ctx.firestore().collection('users').doc('user_1').get(),
    );
  });
});

describe('Firestore Security Rules - usage stats hardening', () => {
  it('owner can create a safe initial usage stats doc', async () => {
    const ctx = authed('user_1');

    await assertSucceeds(
      ctx
        .firestore()
        .collection('users')
        .doc('user_1')
        .collection('usageStats')
        .doc('current')
        .set({
          dailyComparisons: 0,
          dailyAiComparisons: 0,
          dailyAiRecommendations: 0,
          lastResetDate: '2026-06-13',
          totalComparisons: 0,
        }),
    );
  });

  it('owner cannot seed AI quota fields on usage stats create', async () => {
    const ctx = authed('user_1');
    const ref = ctx
      .firestore()
      .collection('users')
      .doc('user_1')
      .collection('usageStats')
      .doc('current');

    await assertFails(
      ref.set({
        dailyComparisons: 0,
        dailyAiComparisons: 0,
        dailyAiRecommendations: -999,
        lastResetDate: '2026-06-13',
        totalComparisons: 0,
      }),
    );

    await assertFails(
      ref.set({
        dailyComparisons: 0,
        dailyAiComparisons: 0,
        dailyAiRecommendations: 0,
        lastAiRecommendationResetDate: '2026-06-13',
        lastResetDate: '2026-06-13',
        totalComparisons: 0,
      }),
    );
  });
});

describe('Firestore Security Rules - analytics hardening', () => {
  it('authenticated users cannot write analytics counters directly', async () => {
    const ctx = authed('user_1');

    await assertFails(
      ctx.firestore().collection('analytics').doc('counters').set({
        totalUsers: 999,
      }),
    );

    await assertFails(
      ctx
        .firestore()
        .collection('analytics')
        .doc('topUniversities')
        .collection('items')
        .doc('uni_1')
        .set({
          name: 'Tampered University',
          viewCount: 999,
        }),
    );
  });

  it('custom claim admin can read analytics counters', async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      await context.firestore().collection('analytics').doc('counters').set({
        totalUsers: 10,
      });
    });

    const ctx = authed('admin_user', 'admin@example.edu.tr', true, {
      admin: true,
    });

    await assertSucceeds(
      ctx.firestore().collection('analytics').doc('counters').get(),
    );
  });
});

describe('Firestore Security Rules - preference list hardening', () => {
  beforeEach(async () => {
    await seedUser('user_1', {
      displayName: 'Test User',
      photoUrl: null,
    });
    await seedUser('user_2', {
      displayName: 'Other User',
      photoUrl: null,
    });
  });

  it('owner can create a safe preference list', async () => {
    const ctx = authed('user_1');

    await assertSucceeds(
      ctx
        .firestore()
        .collection('preferenceLists')
        .doc('list_1')
        .set(validPreferenceListData('user_1')),
    );
  });

  it('owner can create a preference list with client timestamps', async () => {
    const ctx = authed('user_1');
    const now = new Date();

    await assertSucceeds(
      ctx
        .firestore()
        .collection('preferenceLists')
        .doc('list_1')
        .set(validPreferenceListData('user_1', {
          createdAt: now,
          updatedAt: now,
        })),
    );
  });

  it('owner cannot create preference list with spoofed or unsafe fields', async () => {
    const ctx = authed('user_1');
    const ref = ctx.firestore().collection('preferenceLists').doc('list_1');

    await assertFails(
      ref.set(validPreferenceListData('user_2')),
    );

    await assertFails(
      ref.set(validPreferenceListData('user_1', { userName: '' })),
    );

    await assertFails(
      ref.set(validPreferenceListData('user_1', { userPhotoUrl: 'x'.repeat(2049) })),
    );

    await assertFails(
      ref.set(validPreferenceListData('user_1', { viewCount: 999 })),
    );

    await assertFails(
      ref.set(validPreferenceListData('user_1', { shareSlug: '../bad' })),
    );

    await assertFails(
      ref.set(validPreferenceListData('user_1', { adminOnly: true })),
    );
  });

  it('owner can update mutable preference list fields only', async () => {
    await seedPreferenceList();
    const ctx = authed('user_1');

    await assertSucceeds(
      ctx.firestore().collection('preferenceLists').doc('list_1').update({
        title: 'Güncel Tercih Listem',
        description: 'Güncellendi',
        isPublic: true,
        items: [validPreferenceItem()],
        updatedAt: serverTimestamp(),
      }),
    );
  });

  it('owner can save multiple preference list items', async () => {
    await seedPreferenceList();
    const ctx = authed('user_1');

    await assertSucceeds(
      ctx.firestore().collection('preferenceLists').doc('list_1').update({
        items: [
          validPreferenceItem({ deptId: 'dept_1', order: 1 }),
          validPreferenceItem({ deptId: 'dept_2', order: 2 }),
          validPreferenceItem({ deptId: 'dept_3', order: 3 }),
        ],
        updatedAt: serverTimestamp(),
      }),
    );
  });

  it('owner can update mutable preference list fields with client timestamp', async () => {
    await seedPreferenceList();
    const ctx = authed('user_1');

    await assertSucceeds(
      ctx.firestore().collection('preferenceLists').doc('list_1').update({
        title: 'Güncel Tercih Listem',
        updatedAt: new Date(),
      }),
    );
  });

  it('owner cannot update immutable preference list fields', async () => {
    await seedPreferenceList();
    const ctx = authed('user_1');
    const ref = ctx.firestore().collection('preferenceLists').doc('list_1');

    await assertFails(ref.update({ userId: 'user_2' }));
    await assertFails(ref.update({ userName: 'Fake User' }));
    await assertFails(ref.update({ shareSlug: 'zz99yy88' }));
    await assertFails(ref.update({ viewCount: 1 }));
    await assertFails(ref.update({ createdAt: serverTimestamp() }));
  });

  it('users cannot directly increment preference list viewCount', async () => {
    await seedPreferenceList('list_1', { isPublic: true });
    const ownerCtx = authed('user_1');
    const otherCtx = authed('user_2');

    await assertFails(
      ownerCtx.firestore().collection('preferenceLists').doc('list_1').update({
        viewCount: 1,
      }),
    );

    await assertFails(
      otherCtx.firestore().collection('preferenceLists').doc('list_1').update({
        viewCount: 1,
      }),
    );
  });

  it('rejects preference list payloads over the OSYM item limit', async () => {
    await seedPreferenceList();
    const ctx = authed('user_1');
    const ref = ctx.firestore().collection('preferenceLists').doc('list_1');
    const tooManyItems = Array.from({ length: 25 }, (_, index) =>
      validPreferenceItem({
        deptId: `dept_${index}`,
        order: index + 1,
      }),
    );

    await assertFails(
      ref.update({
        items: tooManyItems,
        updatedAt: serverTimestamp(),
      }),
    );
  });

  it('public preference lists are readable but private lists stay owner-only', async () => {
    await seedPreferenceList('public_list', { isPublic: true });
    await seedPreferenceList('private_list', { isPublic: false });
    const otherCtx = authed('user_2');

    await assertSucceeds(
      otherCtx.firestore().collection('preferenceLists').doc('public_list').get(),
    );

    await assertFails(
      otherCtx.firestore().collection('preferenceLists').doc('private_list').get(),
    );
  });
});

describe('Firestore Security Rules - review moderation hardening', () => {
  beforeEach(async () => {
    await seedUser('user_1', {
      displayName: 'Test User',
      photoUrl: null,
      university: 'Test University',
      universityId: 'uni_1',
    });
  });

  it('verified owner can create a pending safe review', async () => {
    const ctx = authed('user_1', 'user_1@example.edu.tr', true);

    await assertSucceeds(
      ctx.firestore().collection('reviews').doc('review_1').set(
        validReviewData('user_1'),
      ),
    );
  });

  it('owner cannot create an already approved review', async () => {
    const ctx = authed('user_1', 'user_1@example.edu.tr', true);

    await assertFails(
      ctx.firestore().collection('reviews').doc('review_1').set(
        validReviewData('user_1', { isApproved: true }),
      ),
    );
  });

  it('owner cannot create a review for another university', async () => {
    const ctx = authed('user_1', 'user_1@example.edu.tr', true);

    await assertFails(
      ctx.firestore().collection('reviews').doc('review_1').set(
        validReviewData('user_1', {
          targetId: 'uni_2',
          universityId: 'uni_2',
        }),
      ),
    );
  });

  it('owner can edit content only when review goes back to pending', async () => {
    await seedReview('review_1', { isApproved: true });
    const ctx = authed('user_1', 'user_1@example.edu.tr', true);

    await assertSucceeds(
      ctx.firestore().collection('reviews').doc('review_1').update({
        comment: 'Duzenlenmis ve yeniden moderasyona girecek temiz yorum.',
        isApproved: false,
        updatedAt: serverTimestamp(),
      }),
    );
  });

  it('owner cannot edit immutable or moderation-controlled review fields', async () => {
    await seedReview('review_1', { isApproved: true });
    const ctx = authed('user_1', 'user_1@example.edu.tr', true);
    const ref = ctx.firestore().collection('reviews').doc('review_1');

    await assertFails(ref.update({ likes: 999 }));
    await assertFails(ref.update({ createdAt: serverTimestamp() }));
    await assertFails(ref.update({ universityId: 'uni_2' }));
    await assertFails(ref.update({ isApproved: true }));
  });

  it('users can like approved reviews but cannot directly update parent likes', async () => {
    await seedReview('review_1', { isApproved: true });
    const ctx = authed('user_1', 'user_1@example.edu.tr', true);

    await assertSucceeds(
      ctx
        .firestore()
        .collection('reviews')
        .doc('review_1')
        .collection('likes')
        .doc('user_1')
        .set({ createdAt: serverTimestamp() }),
    );

    await assertFails(
      ctx.firestore().collection('reviews').doc('review_1').update({
        likes: 1,
      }),
    );
  });

  it('users cannot like pending reviews', async () => {
    await seedReview('review_1', { isApproved: false });
    const ctx = authed('user_1', 'user_1@example.edu.tr', true);

    await assertFails(
      ctx
        .firestore()
        .collection('reviews')
        .doc('review_1')
        .collection('likes')
        .doc('user_1')
        .set({ createdAt: serverTimestamp() }),
    );
  });
});
