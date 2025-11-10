const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

exports.cleanupDeletedAttemptsOnUpdate = functions.firestore
    .document("quiz_attempts/{attemptId}")
    .onUpdate(async (change, context) => {

      const newValue = change.after.data();

      const hiddenFromStudent = newValue.hiddenFromStudent === true;
      const hiddenFromTeacher = newValue.hiddenFromTeacher === true;

      // If both flags are true, permanently delete the document.
      if (hiddenFromStudent && hiddenFromTeacher) {
        const attemptId = context.params.attemptId;
        console.log(`Permanently deleting quiz attempt on update: ${attemptId}`);
        try {
          await admin.firestore().collection("quiz_attempts").doc(attemptId).delete();
          console.log(`Successfully deleted quiz attempt: ${attemptId}`);
        } catch (error) {
          console.error(`Error deleting quiz attempt ${attemptId}:`, error);
        }
      }
      return null;
    });

exports.cleanupDeletedAttemptsOnCreate = functions.firestore
    .document("quiz_attempts/{attemptId}")
    .onCreate(async (snap, context) => {
      const data = snap.data();

      const hiddenFromStudent = data.hiddenFromStudent === true;
      const hiddenFromTeacher = data.hiddenFromTeacher === true;

      // If both flags are true at creation, permanently delete the document.
      if (hiddenFromStudent && hiddenFromTeacher) {
        const attemptId = context.params.attemptId;
        console.log(`Permanently deleting quiz attempt on create: ${attemptId}`);
        try {
          await admin.firestore().collection("quiz_attempts").doc(attemptId).delete();
          console.log(`Successfully deleted quiz attempt: ${attemptId}`);
        } catch (error) {
          console.error(`Error deleting quiz attempt ${attemptId}:`, error);
        }
      }
      return null;
    });
