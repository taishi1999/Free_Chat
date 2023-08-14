/**
 * Import function triggers from their respective submodules:
 *
 * const {onCall} = require("firebase-functions/v2/https");
 * const {onDocumentWritten} = require("firebase-functions/v2/firestore");
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

// const {onRequest} = require("firebase-functions/v2/https");
// const logger = require("firebase-functions/logger");
const { logger } = require("firebase-functions");

const functions = require("firebase-functions");
const admin = require("firebase-admin");

// admin.initializeApp();

// eslint-disable-next-line max-len
// const serviceAccount = require("/Users/karasakitaishi/Downloads/freechat-9b9db-firebase-adminsdk-lle2g-6a90f8a0ee.json");

admin.initializeApp({
  // credential: admin.credential.cert(serviceAccount),
});
const db = admin.firestore();
exports.sendNotification = functions.firestore
  .document("rooms/{roomId}/messages/{messageId}")
  .onCreate(async (snap, context) => {
    // メッセージの内容と送信先ユーザーのトークンを取得します
    const message = snap.data();
    logger.info("Message data:", message);

    const roomId = context.params.roomId;

    // Get the room document using roomId
    const roomDoc = await db.collection("rooms").doc(roomId).get();

    // Get the user IDs of the participants in the room
    const userIds = roomDoc.data().userIds;
    // const userSnapshot = await db
    //   .collection("users")
    //   .doc(message.authorId)
    //   .get();

    // const userName = userSnapshot.data()?.firstName;
    // logger.info("userName:", userName);
    // logger.info("userSnapshot.id:", userSnapshot.id);
    const sendUserSnapshot = await db
      .collection("users")
      .doc(message.authorId)
      .get();

    const sendUserName = sendUserSnapshot.data()?.firstName;

    const promises = userIds.map(async (userId, i) => {
      if (message.authorId !== userId) {
        logger.info(
          `User ID ${i + 1}: ${userId} ,authorId: ${message.authorId}`
        );

        const userSnapshot = await db.collection("users").doc(userId).get();

        const userName = userSnapshot.data()?.firstName;
        logger.info("userName:", userName);
        logger.info("userSnapshot.id:", userSnapshot.id);

        const userToken = userSnapshot.data()?.fcmToken;

        let bodyMessage;
        if (message.type === "text") {
          if (message.metadata.painter) {
            bodyMessage = "落書きを送信しました";
          } else {
            bodyMessage = message.text;
          }
        } else if (message.type === "image") {
          bodyMessage = "写真を送信しました";
        }

        const payload = {
          notification: {
            title: `${sendUserName}`,
            // title: "Norm",
            body: `${bodyMessage}`,
          },
          data: {
            // Add the roomId in the data field
            roomId: roomId,
          },
        };

        return admin
          .messaging()
          .send({
            token: userToken,
            ...payload,
          })
          .then((response) => {
            logger.info("Notification sent successfully:", response);
          })
          .catch((error) => {
            logger.error("Notification sent failed:", error);
          });
      }
      logger.info(`送信者のUser ID: ${userId}`);
      return null; // Add this line
    });

    return Promise.all(promises);
  });

// for (let i = 0; i < userIds.length; i += 1) {
//   // 各userIdをログに出力します
//   if (message.authorId !== userIds[i]) {
//     logger.info(
//       `User ID ${i + 1}: ${userIds[i]} ,authorId: ${message.authorId}`
//     );
//   } else {
//     logger.info(`送信者のUser ID: ${userIds[i]}`);
//   }
// }

// const userToken = message.userToken; // これは送信先ユーザーのFCMトークンです
// logger.info("User token:", userToken);
// あなたのFCMトークンを設定します
//   const userToken =
//     // eslint-disable-next-line max-len
//     "c16UDvLSxkFPlPQQfYTrj6:APA91bHG01g0ZyjO4RMIYYeAtBUJDY9gvDi0frdiWzwT1NTB44Jgnc-vSkshC0v42mRia9Fjx7_q4V3g4Kw8COWDPENWsJwvrXVCHGccV6HyQQTEa9PNiwAxh0864zdBOtY_GiSu_JB0"; // これをあなたのFCMトークンに置き換えてください

//   // 通知のペイロードを設定します
//   const payload = {
//     notification: {
//       title: "Norm",
//       body: `${userName}: ${message.text}`,
//     },
//   };

//   // 通知を送信します
//   return (
//     admin
//       .messaging()
//       .send({
//         token: userToken,
//         ...payload,
//       })

//       // return admin
//       //   .messaging()
//       //   .send(userToken, payload)
//       .then((response) => {
//         // 送信に成功した場合のレスポンスをログに表示します
//         logger.info("Notification sent successfully:", response);
//         return null;
//       })
//       .catch((error) => {
//         // 送信に失敗した場合のエラーをログに表示します
//         logger.error("Notification sent failed:", error);
//         throw error;
//       })
//   );
// });

// Create and deploy your first functions
// https://firebase.google.com/docs/functions/get-started

// exports.helloWorld = onRequest((request, response) => {
//   logger.info("Hello logs!", {structuredData: true});
//   response.send("Hello from Firebase!");
// });
