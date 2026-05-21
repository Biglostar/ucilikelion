import * as admin from 'firebase-admin';

let firebaseInitialized = false;

function initFirebase() {
  if (firebaseInitialized || admin.apps.length) {
    firebaseInitialized = true;
    return true;
  }
  try {
    let serviceAccount: admin.ServiceAccount | null = null;
    if (process.env.FIREBASE_CONFIG) {
      serviceAccount = JSON.parse(process.env.FIREBASE_CONFIG);
    } else {
      try {
        serviceAccount = require("../config/ucilions-firebase-adminsdk-fbsvc-6cb7827014.json");
      } catch {
        console.warn("[Firebase] 서비스 계정 파일 없음 — 푸시 알림 비활성화");
        return false;
      }
    }
    admin.initializeApp({ credential: admin.credential.cert(serviceAccount!) });
    firebaseInitialized = true;
    return true;
  } catch (e) {
    console.warn("[Firebase] 초기화 실패 — 푸시 알림 비활성화:", e);
    return false;
  }
}

export async function sendPushNotification(deviceToken: string, title: string, body: string) {
  if (!initFirebase()) {
    console.warn("[Firebase] 푸시 알림 스킵 (Firebase 미설정)");
    return null;
  }

  const message = {
    notification: { title, body },
    token: deviceToken,
    data: {
      click_action: "FLUTTER_NOTIFICATION_CLICK",
      type: "ROAST_MESSAGE"
    }
  };

  try {
    const response = await admin.messaging().send(message);
    console.log('푸시 알림 발송 성공:', response);
    return response;
  } catch (error) {
    console.error('푸시 알림 발송 실패:', error);
    throw error;
  }
}
