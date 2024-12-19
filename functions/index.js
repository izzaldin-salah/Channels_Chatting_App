const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

exports.sendNotifications = functions.firestore
  .document('notifications/{notificationId}')
  .onCreate(async (snap, context) => {
    const notification = snap.data();
    const tokens = notification.tokens;

    // Remove the sender's token if it exists
    const messaging = admin.messaging();
    
    try {
      const response = await messaging.sendMulticast({
        tokens: tokens,
        notification: notification.notification,
        data: notification.data,
      });

      console.log('Successfully sent messages:', response);
      return response;
    } catch (error) {
      console.error('Error sending messages:', error);
      throw error;
    }
  }); 