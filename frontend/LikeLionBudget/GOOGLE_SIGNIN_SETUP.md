# Google Sign-In 설정 (진짜 로그인)

앱에서 구글 로그인 후 이메일/이름이 설정 > 개인정보관리에 나오려면, **Google Cloud Console**에서 OAuth 클라이언트를 만들고 아래 값을 채워야 합니다.

## 1. Google Cloud Console 설정

1. [Google Cloud Console](https://console.cloud.google.com/) 접속 후 프로젝트 선택(또는 새 프로젝트 생성).
2. **API 및 서비스** > **사용자 인증 정보** > **+ 사용자 인증 정보 만들기** > **OAuth 클라이언트 ID**.
3. 애플리케이션 유형: **iOS** 선택.
4. **번들 ID**에 앱 번들 ID 입력: `com.samuelkim.LikeLionBudget` (또는 실제 사용 중인 번들 ID).
5. 만들기 후 **클라이언트 ID**가 생성됩니다. 형식 예: `123456789012-abcdefghijk.apps.googleusercontent.com`.

## 2. Info.plist 수정

`LikeLionBudget/Info.plist`에서 다음 두 곳의 **placeholder를 실제 값으로** 바꿉니다.

### GIDClientID

- **키**: `GIDClientID`
- **값**: 위에서 복사한 **전체 클라이언트 ID**  
  예: `123456789012-abcdefghijk.apps.googleusercontent.com`

### CFBundleURLSchemes (리다이렉트용)

- **키**: `CFBundleURLTypes` > 첫 번째 항목 > `CFBundleURLSchemes` > 첫 번째 문자열
- **값**: 클라이언트 ID에서 `.apps.googleusercontent.com` **앞부분만** 가져와서  
  `com.googleusercontent.apps.` **뒤에** 붙인 문자열  
  예: 클라이언트 ID가 `123456789012-abcdefghijk.apps.googleusercontent.com` 이면  
  → `com.googleusercontent.apps.123456789012-abcdefghijk`

정리하면:

| Info.plist 항목 | 예시 값 |
|-----------------|--------|
| GIDClientID | `123456789012-abcdefghijk.apps.googleusercontent.com` |
| CFBundleURLSchemes (0) | `com.googleusercontent.apps.123456789012-abcdefghijk` |

## 3. 확인

1. Xcode에서 **Clean Build** 후 실제 기기 또는 시뮬레이터에서 실행.
2. **계정 연결** > **Google 로그인** 탭 후 구글 계정 선택.
3. 로그인 성공 시 로그인 시트가 닫히고 약관 동의로 진행.
4. **설정** > **개인정보** 에서 이메일/이름이 표시되는지 확인.

문제가 있으면 Xcode 콘솔에 `GIDClientID` / URL scheme 관련 로그가 있을 수 있으니 확인해 보세요.
