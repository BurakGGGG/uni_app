const { assertFails, assertSucceeds, initializeTestEnvironment } = require('@firebase/rules-unit-testing');
const { readFileSync } = require('fs');
const path = require('path');

let testEnv;

before(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: "unisec-test-rules",
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

describe("Firestore Security Rules - Admin Checks", () => {
  
  it("Admin CAN write to cities collection", async () => {
    // Admin claim ile authenticate edilmiş user context oluştur
    const adminContext = testEnv.authenticatedContext('admin_user', {
      admin: true
    });
    
    // Test: Şehir oluşturabilmeli
    await assertSucceeds(
      adminContext.firestore().collection('cities').doc('34').set({ name: 'İstanbul' })
    );
  });

  it("Normal user CANNOT write to cities collection", async () => {
    // Normal user (admin claim'i yok)
    const normalContext = testEnv.authenticatedContext('normal_user', {
      admin: false
    });
    
    // Test: Şehir oluşturamamalı
    await assertFails(
      normalContext.firestore().collection('cities').doc('35').set({ name: 'İzmir' })
    );
  });
  
  it("Unauthenticated user CANNOT write to cities collection", async () => {
    const unauthContext = testEnv.unauthenticatedContext();
    
    await assertFails(
      unauthContext.firestore().collection('cities').doc('06').set({ name: 'Ankara' })
    );
  });

});
