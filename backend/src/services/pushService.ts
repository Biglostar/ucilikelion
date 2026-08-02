import * as admin from 'firebase-admin';
import { prisma } from '../prisma';

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

  const message: admin.messaging.Message = {
    notification: { title, body },
    token: deviceToken,
    data: {
      type: "ROAST_MESSAGE"
    },
    apns: {
      payload: {
        aps: {
          sound: "default",
          badge: 1
        }
      }
    }
  };

  try {
    const response = await admin.messaging().send(message);
    console.log('푸시 알림 발송 성공:', response);
    return response;
  } catch (error) {
    const code = (error as { code?: string }).code;
    if (code === 'messaging/registration-token-not-registered' || code === 'messaging/invalid-registration-token') {
      console.warn('[Firebase] 무효 토큰 감지, DB에서 제거:', deviceToken);
      await prisma.user.updateMany({
        where: { fcmToken: deviceToken },
        data: { fcmToken: null }
      }).catch(e => console.error('무효 토큰 제거 실패:', e));
    } else {
      console.error('푸시 알림 발송 실패:', error);
    }
    throw error;
  }
}
