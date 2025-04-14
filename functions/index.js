const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore } = require("firebase-admin/firestore");
const { getMessaging } = require("firebase-admin/messaging");

initializeApp();

exports.sendPushNotification = onDocumentCreated("chats/{chatId}/messages/{messageId}", async (event) => {
  const messageData = event.data?.data();
  const chatId = event.params.chatId;
  const messageId = event.params.messageId;

  const senderId = messageData?.senderId;
  const receiverId = messageData?.receiverId;

  if (!receiverId || !senderId || receiverId === senderId) {
    console.log("❌ Invalid sender/receiver");
    return;
  }

  try {
    const db = getFirestore();

    const receiverDoc = await db.collection("users").doc(receiverId).get();
    if (!receiverDoc.exists) {
      console.log("❌ Receiver does not exist");
      return;
    }

    const receiverData = receiverDoc.data();
    const receiverToken = receiverData?.fcmToken;
    if (!receiverToken) {
      console.log("❌ No FCM token found");
      return;
    }

    const senderDoc = await db.collection("users").doc(senderId).get();
    const senderData = senderDoc.data() || {};
    const senderName = senderData?.username?.trim() || "New message";
    const profileImageUrl = senderData.profileImageUrl || "";
    const messageText = messageData?.message || "You received a new message!";

    const payload = {
      token: receiverToken,
      notification: {
        title: senderName,
        body: messageText,
      },
      data: {
        chatId,
        messageId,
        senderId,
        senderName,
        profileImageUrl,
        messageText,
      },
      android: {
        priority: "high",
        notification: {
          sound: "default",
          channelId: "chat_channel",
        },
      },
      apns: {
        payload: {
          aps: {
            alert: {
              title: senderName,
              body: messageText,
            },
            sound: "default",
          },
        },
        headers: {
          "apns-priority": "10",
        },
      },
    };

    const response = await getMessaging().send(payload);
    console.log("✅ Notification sent:", response);

    // ⭐ Update message and chat status to 'delivered'
    const messageRef = db.collection("chats").doc(chatId).collection("messages").doc(messageId);
    const chatRef = db.collection("chats").doc(chatId);

    await db.runTransaction(async (tx) => {
      tx.update(messageRef, { status: "delivered" });

      const chatSnap = await tx.get(chatRef);
      const lastMessageId = chatSnap.data()?.lastMessageId;

      if (lastMessageId === messageId) {
        tx.update(chatRef, { lastMessageStatus: "delivered" });
      }
    });

    console.log("📬 Message status updated to 'delivered' in Firestore");

  } catch (error) {
    console.error("❌ Error sending notification or updating Firestore:", error);
  }
});
