
const admin = require('firebase-admin');

// IMPORTANT: You must download your service account key for this script to work.
// 1. Go to your Firebase project settings -> "Service accounts".
// 2. Click "Generate new private key" and download the JSON file.
// 3. Save the file as 'serviceAccountKey.json' in this 'functions' directory.
// 4. IMPORTANT: Make sure 'serviceAccountKey.json' is added to your .gitignore file!
try {
  const serviceAccount = require('./serviceAccountKey.json');
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount)
  });
} catch (error) {
  console.error("ERROR: Could not initialize Firebase Admin SDK. Make sure the 'serviceAccountKey.json' file is in the 'functions' directory. See instructions in the script file.");
  process.exit(1);
}


const db = admin.firestore();

async function cleanupQuizAttempts() {
  console.log('Connecting to Firestore and searching for documents to clean up...');

  const query = db.collection('quiz_attempts')
    .where('hiddenFromStudent', '==', true)
    .where('hiddenFromTeacher', '==', true);

  try {
    const snapshot = await query.get();

    if (snapshot.empty) {
      console.log('Scan complete. No documents found that match the cleanup criteria.');
      return;
    }

    console.log(`Found ${snapshot.size} documents to delete.`);

    // Firestore allows a maximum of 500 operations in a single batch.
    // We will process documents in chunks of 500.
    const chunks = [];
    for (let i = 0; i < snapshot.docs.length; i += 500) {
        chunks.push(snapshot.docs.slice(i, i + 500));
    }

    for (const [index, chunk] of chunks.entries()) {
        const batch = db.batch();
        chunk.forEach(doc => {
            console.log(`  - Scheduling deletion for: ${doc.id}`);
            batch.delete(doc.ref);
        });
        
        console.log(`Committing batch ${index + 1} of ${chunks.length}...`);
        await batch.commit();
        console.log(`Batch ${index + 1} successfully deleted.`);
    }

    console.log('Successfully deleted all matching documents.');

  } catch (error) {
    console.error('Error during cleanup process:', error);
  }
}

cleanupQuizAttempts().then(() => {
    console.log('Cleanup script finished.');
}).catch(error => {
    console.error('An unexpected error occurred during script execution:', error);
});


// to manually clean the query database
// npm run cleanup --prefix functions
