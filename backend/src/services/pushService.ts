import * as admin from 'firebase-admin';

const serviceAccount = process.env.FIREBASE_CONFIG 
  ? JSON.parse(process.env.FIREBASE_CONFIG) 
  : require("../config/ucilions-firebase-adminsdk-fbsvc-6cb7827014.json");

if (!admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount)
  });
}

/**
 * 특정 유저에게 푸시 알림을 발송하는 함수
 * @param deviceToken 유저의 기기 토큰 (프론트에서 받아 DB에 저장해둔 값)
 * @param title 알림 제목 (예: "🚨 예산 초과 경보!")
 * @param body 알림 내용 (Gemini가 만든 팩폭 멘트)
 */
export async function sendPushNotification(deviceToken: string, title: string, body: string) {
  const message = {
    notification: {
      title: title,
      body: body,
    },
    token: deviceToken,
    // 데이터 페이로드를 추가하면 앱 내에서 특정 페이지로 이동시키기 좋습니다.
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