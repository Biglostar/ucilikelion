# UI 규격 정리 (LikeLionBudget)

앱 전반에서 통일된 레이아웃·타이포·색상 규격을 정리한 문서입니다.  
**나중에 수정할 때**: 레이아웃/간격/폰트/색은 **Theme.swift 한 곳만** 바꾸면 전 앱에 반영됩니다.  
**기종별 동일 비율**: `Theme.h(pt)`, `Theme.w(pt)` 사용 (ref 390×844 기준 스케일).

---

## 1. Theme 상수 (Features/Theme.swift)

| 구분 | 상수명 | 값 | 용도 |
|------|--------|-----|------|
| **여백** | `screenHorizontal` | 16 | 스크롤 화면 좌우 |
| | `screenTop` | 14 | 스크롤 화면 상단 (기본) |
| | `screenTopNavExtra` | 10 | 설정/리포트/나의 목표 상단 추가 여백 → 실제 상단 = 24 |
| | `screenBottom` | 28 | 스크롤 화면 하단 |
| | `cardPadding` | 14 | 카드/컨테이너 내부 패딩 |
| **모서리** | `cardCorner` | 10 | beige 카드·달력·리스트 등 라운드 반경 통일 |
| **폰트 크기** | `titleSize` | 30 | 탭/메인 타이틀 (설정, 리포트, 나의 목표, 개인정보 관리, 이용 약관 및 정책) |
| | `subtitleSize` | 18 | 서브 타이틀/시트 제목 |
| | `sectionTitleSize` | 20 | 섹션 제목, 설정 행 텍스트, 홈 "X 남았어요" |
| | `dateLabelSize` | 15 | 날짜/부제목, 잔소리 예시 문구 |
| | `bodySize` | 16 | 본문 |
| | `listTitleSize` | 18 | 리스트 금액/제목 |
| | `smallBodySize` | 13 | 예시 문구, 보조 텍스트 |
| | `captionSmallSize` | 12 | 캡션/시간 등 작은 라벨 |
| **간격** | `spacingTight` ~ `spacingSection` | 4, 6, 8, 12, 14, 16, 18, 20 | 공통 간격 (한 곳만 바꿔도 전 앱 반영) |
| **리스트** | `listRowInsetVertical` / `Horizontal` | 8 / 16 | 리스트 행 인셋 |
| | `listIconSize` | 34 | 리스트 이모지/아이콘 크기 |
| **스트로크** | `strokeOpacityLight` 등 | 0.06 ~ 0.12 | 테두리/구분선 투명도 통일 |
| **색상** | `rose` | #A17272 | 메인 타이틀 색 |
| | `text` | #53514E | 일반 텍스트 |
| | `progressFill` / `progressBG` | #74B19E / #DEF3EC | 게이지·버튼 등 |

---

## 2. 화면별 규격 적용 현황

### 2-1. 네비 타이틀 통일 (설정 · 리포트 · 나의 목표)

- **폰트**: `Theme.fontLaundry`, **크기** `Theme.titleSize` (30pt), **색** `Theme.rose`
- **적용 위치**
  - **설정**: `SettingsView` – `ToolbarItem(placement: .principal)`
  - **리포트**: `ReportView` – 동일
  - **나의 목표**: `GoalsListView` – `.llNavTitle("나의 목표")` (View+CardStyle에서 `titleSize` + `rose` 사용)
- **상단 여백**: `Theme.screenTop + Theme.screenTopNavExtra` = 24pt  
  → 설정, 리포트, 나의 목표 모두 동일

### 2-2. 서브 화면 타이틀 (개인정보 관리 · 이용 약관 및 정책)

- **폰트/크기/색**: `Theme.fontLaundry`, `Theme.titleSize` (30pt), `Theme.rose`
- **적용**: `PersonalInfoView`, `TermsPolicyView` 툴바 `principal` 텍스트

### 2-3. 설정 화면 (SettingsView)

| 항목 | 규격 |
|------|------|
| 박스 테두리 | `RoundedRectangle(cornerRadius: Theme.cardCorner).stroke(Color.black.opacity(0.12), lineWidth: 1)` |
| 칸 구분선 | 박스 테두리와 동일: `Rectangle().fill(Color.black.opacity(0.12)).frame(height: 1)` |
| 카드 내부 가로 패딩 | 20pt (행 공통) |
| 행 세로 패딩 | 16pt |
| 섹션 제목·행 텍스트 | `Theme.sectionTitleSize` (20pt), `Theme.fontLaundry`, `Theme.text` |
| 잔소리 강도 예시 | 박스 작게, 가운데 정렬, `Theme.dateLabelSize` (15pt), `fontWeight(.medium)` |

### 2-4. 홈 (HomeView)

| 항목 | 규격 |
|------|------|
| 게이지–달력 블록 좌우 여백 | `goalCalendarHorizontal` = 20pt |
| 게이지 ↔ 달력 사이 갭 | `gapGoalToCalendar` = 20pt |
| "X 남았어요" | 게이지와 달력 **가운데** 한 줄 배치, `Theme.sectionTitleSize` (20pt), `Theme.fontLaundry`, `Theme.text` |
| 게이지 영역 높이 | 진행 바만 표시, TabView 높이 44pt |

### 2-5. 리포트 (ReportView)

- 타이틀: `Theme.titleSize` + `Theme.rose`
- 상단 여백: `screenTop + screenTopNavExtra`
- 섹션 제목 등: `Theme.sectionTitleSize` (20pt), 날짜 등: `Theme.dateLabelSize` (15pt) 등 기존 Theme 활용

### 2-6. 인증 플로우 (로그인 · 약관 동의 · Plaid 안내)

- **로그인 (LoginView)**
  - 상단 타이틀: `Theme.fontLaundry` + `Theme.titleSize` + `Theme.text`
  - 상하 여백: 상단 `Theme.screenTop + Theme.screenTopNavExtra`, 내부 스택 `Theme.spacingLarge`
  - 필드/버튼: `Theme.cardPadding`, `Theme.buttonVerticalPadding`, 모서리 `Theme.cardCorner`
- **약관 동의 (TermsAndConsentView)**
  - 제목/본문: `Theme.titleSize`, `Theme.bodySize` + `Theme.text`
  - 카드 모양: `Theme.cardCorner`, 테두리 `Color.black.opacity(0.12)` (Settings 카드와 동일 계열)
  - 섹션 간 간격: `Theme.spacingRegular`, `Theme.spacingSection`, 바닥 버튼 패딩 `Theme.buttonVerticalPadding`
- **Plaid 안내 (PlaidIntroView)**
  - 상단 닫기 버튼 정렬: 로그인/시트와 동일 우측 상단
  - 안내 카드: 내부 패딩 `Theme.cardPadding`, 모서리 `Theme.cardCorner`, 테두리 `Theme.strokeLineWidth`
  - 텍스트 크기: 타이틀 `Theme.subtitleSize`, 카드 타이틀 `Theme.bodySize`, 부제목/하단 안내 `Theme.captionSmallSize`
  - 버튼: 텍스트 크기 `Theme.dateLabelSize`, 세로 패딩 `Theme.buttonVerticalPadding`, 배경 `Theme.progressFill`

---

## 3. 공통 패턴

- **탭/메인 타이틀**: `Theme.fontLaundry` + `Theme.titleSize` + `Theme.rose`
- **카드/박스 테두리**: `Color.black.opacity(0.12)`, `lineWidth: 1`
- **설정처럼 칸 나누는 선**: 박스 테두리와 동일 스타일 (`opacity(0.12)`, 높이 1pt)
- **섹션 제목**: `Theme.sectionTitleSize` (20pt)
- **네비 타이틀 있는 스크롤 화면**: 상단 `Theme.screenTop + Theme.screenTopNavExtra`

---

## 4. 참고 파일

- `Features/Theme.swift` – 모든 상수 정의
- `Features/View+CardStyle.swift` – `llNavTitle()` (나의 목표 등)
- `Features/Settings/SettingsView.swift` – 설정 카드·구분선·예시 박스
- `Features/Home/HomeView.swift` – 게이지·남았어요·달력 레이아웃

이 문서는 규격 적용 후 정리한 것이며, Theme 값 변경 시 여기 표를 함께 수정하면 됩니다.
