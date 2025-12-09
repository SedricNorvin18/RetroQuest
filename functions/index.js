const { onDocumentWritten, onDocumentDeleted } = require("firebase-functions/v2/firestore");
const admin = require("firebase-admin");
const { getStorage } = require("firebase-admin/storage");

admin.initializeApp();

exports.cleanupDeletedAttempts = onDocumentWritten("quiz_attempts/{attemptId}", async (event) => {
  if (!event.data.after.exists) {
    console.log(`Document ${event.params.attemptId} was deleted, no cleanup needed.`);
    return null;
  }
  const data = event.data.after.data();
  if (data.hiddenFromStudent === true && data.hiddenFromTeacher === true) {
    const attemptId = event.params.attemptId;
    console.log(`Permanently deleting quiz attempt: ${attemptId}`);
    try {
      await event.data.after.ref.delete();
      console.log(`Successfully deleted quiz attempt: ${attemptId}`);
    } catch (error) {
      console.error(`Error deleting quiz attempt ${attemptId}:`, error);
    }
  }
  return null;
});

exports.onDeleteQuestion = onDocumentDeleted("questions/{questionId}", async (event) => {
    const deletedData = event.data.data();
    if (!deletedData || !deletedData.imageUrl) {
        console.log(`Question ${event.params.questionId} deleted without an imageUrl.`);
        return null;
    }

    const imageUrl = deletedData.imageUrl;

    try {
        const bucket = getStorage().bucket();
        // The URL is typically in the format: https://firebasestorage.googleapis.com/v0/b/your-bucket.appspot.com/o/folder%2Fimage.jpg?alt=media&token=...
        // We want the part between '/o/' and '?alt=media'.
        const startIndex = imageUrl.indexOf("/o/") + 3;
        const endIndex = imageUrl.indexOf("?alt=media");
        
        if (startIndex === 2 || endIndex === -1) {
             throw new Error("Invalid storage URL format. Could not find start or end tokens.");
        }

        const encodedFilePath = imageUrl.substring(startIndex, endIndex);
        const filePath = decodeURIComponent(encodedFilePath);

        if (!filePath) {
             console.log(`Could not extract file path from URL: ${imageUrl}`);
             return null;
        }

        const file = bucket.file(filePath);
        await file.delete();
        console.log(`Successfully deleted image from storage: ${filePath}`);
    } catch (error) {
        console.error(`Failed to delete image for question ${event.params.questionId}. URL: ${imageUrl}. Error:`, error);
    }
    return null;
});

exports.onDeleteSubject = onDocumentDeleted("subjects/{subjectId}", async (event) => {
    const subjectId = event.params.subjectId;
    const db = admin.firestore();

    console.log(`Starting cascading delete for subject: ${subjectId}`);

    // Find all questions associated with the deleted subject.
    const questionsSnapshot = await db.collection('questions').where('subjectId', '==', subjectId).get();

    if (questionsSnapshot.empty) {
        console.log(`No questions found for subject ${subjectId}. Nothing to delete.`);
        return null;
    }

    // Deleting the question document will automatically trigger the onDeleteQuestion function,
    // which handles deleting the image from Storage.
    const deletionPromises = [];
    questionsSnapshot.forEach(doc => {
        deletionPromises.push(doc.ref.delete());
        console.log(`Queueing deletion for question: ${doc.id}`);
    });

    await Promise.all(deletionPromises);

    console.log(`Finished cascading delete for subject: ${subjectId}. Deleted ${questionsSnapshot.size} questions.`);
    return null;
});
