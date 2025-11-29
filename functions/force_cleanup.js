const admin = require("firebase-admin");

try {
  const serviceAccount = require("./serviceAccountKey.json");
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount)
  });
} catch (e) {
  if (e.code !== 'app/duplicate-app') {
    console.error("Could not initialize Firebase Admin SDK. Make sure serviceAccountKey.json is present in the functions directory. Error: " + e);
    process.exit(1);
  }
}

const db = admin.firestore();

// This function recursively deletes documents in batches.
async function deleteQueryBatch(query, resolve, reject) {
  try {
    const snapshot = await query.get();

    // When there are no documents left, we are done.
    if (snapshot.size === 0) {
      resolve();
      return;
    }

    // Delete documents in a batch.
    const batch = db.batch();
    snapshot.docs.forEach(doc => {
      console.log(`Deleting quiz_attempt: ${doc.id}`);
      batch.delete(doc.ref);
    });
    await batch.commit();

    // Recurse on the next process tick, to avoid exploding the stack.
    process.nextTick(() => {
      deleteQueryBatch(query, resolve, reject);
    });
  } catch(error) {
    console.error("Error in deleteQueryBatch: ", error);
    // The most likely error is a missing index. The error message from
    // Firestore will contain a link to create the index.
    reject(error);
  }
}

async function runCleanup() {
  console.log("Starting deletion of ALL quiz attempts...");

  const batchSize = 100;

  // The query to find all documents to delete.
  const query = db.collection('quiz_attempts')
    .orderBy('__name__') // Required for pagination with delete
    .limit(batchSize);

  return new Promise((resolve, reject) => {
    deleteQueryBatch(query, resolve, reject).catch(reject);
  });
}

runCleanup()
  .then(() => {
    console.log('Deletion of all quiz attempts has finished successfully.');
    process.exit(0);
  })
  .catch((error) => {
    console.error('Cleanup failed:', error);
    process.exit(1);
  });