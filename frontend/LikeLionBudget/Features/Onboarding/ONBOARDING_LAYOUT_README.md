# 온보딩 하이라이트/툴팁 — 무엇을 잡고 어떻게 인식하는지

## 1. 뭘 잡는가 (데이터 소스)

- **단계별로 “이번 단계에서 가리켜야 할 UI”의 화면상 위치**를 잡는다.
- 그 위치는 **SwiftUI PreferenceKey**로 수집한다.
  - 키: `OnboardingFramePreferenceKey`
  - 값: `[Int: [CGRect]]` → `[단계번호: [해당 단계에서 쓰일 사각형들(글로벌 좌표)]]`

### 1.1 프레임을 넣는 쪽 (누가 잡는지)

| 단계 | 어디서 잡는지 | 어떻게 넣는지 |
|------|----------------|----------------|
| 1 | HomeView | `SpendMonthOnlyView(...).onboardingFrame(stepId: 1)` → 그 뷰의 **전체 bounds** 1개 (`.global`) |
| 2 | HomeView | 말풍선+꼬리 3개를 **직접 계산**해서 `preference(key:..., value: [2: [bubbleGlobal, tail1Global, tail2Global]])` |
| 3 | HomeView | 방 일러스트가 들어간 뷰에 `.onboardingFrame(stepId: 3)` → 그 뷰 bounds 1개 |
| 4 | HomeView | “이번 달에 $… 지출했어요” 카드 뷰에 `.onboardingFrame(stepId: 4)` → 그 뷰 bounds 1개 |
| 5 | HomeView | `MonthCalendarView`에 `.onboardingFrame(stepId: 5)` → 캘린더 영역 1개 |
| 6 | DayDetailSheet | **+ 버튼**에 붙인 overlay의 `GeometryReader`에서 버튼 중심 기준 **원형 rect** 하나 계산 후 `preference(key:..., value: [6: [rect]])` |
| 7 | DayDetailSheet | 고정지출 row 등에 `.onboardingFrame(stepId: 7)` → 해당 row bounds |
| 8 | GoalsListView | 목표 카드 컨테이너에 `.onboardingFrame(stepId: 8)` → 그 영역 1개 |
| 9 | GoalsListView | 토글(스위치)에 `.onboardingFrame(stepId: 9)` → 토글 bounds |
| 10 | GoalsListView | “목표 추가” 버튼에 `.onboardingFrame(stepId: 10)` → 버튼 bounds |
| 11 | ReportView | `MonthlyReportExpanded` 등에 `.onboardingFrame(stepId: 11)` → 그 영역 1개 |
| 12 | ReportView | 고정비 카드에 `.onboardingFrame(stepId: 12)` → 그 영역 1개 |

- **`.onboardingFrame(stepId:)`** 쓰는 경우: 그 뷰에 `background(GeometryReader)`를 달아서 **그 콘텐츠의 `g.frame(in: .global)`** 한 개를 preference로 올린다.
- **직접 preference 넣는 경우**: step 2(말풍선 3개), step 6(+ 버튼 원) → 레이아웃/크기를 코드로 계산한 뒤 `[stepId: [CGRect]]` 형태로 넣는다.

정리하면, **“무엇을 잡는가”** = 각 단계에서 가리킬 **실제 컴포넌트(또는 계산된 영역)의 글로벌 CGRect** 이다.

---

## 2. 이걸 어디서 모으는가

- HomeView, DayDetailSheet, GoalsListView, ReportView 등에서 **자식/본인이** preference를 올리면, **그 뷰가 붙어 있는 상위에서** `onPreferenceChange(OnboardingFramePreferenceKey.self) { ... }` 로 합친다.
- reduce 규칙: 같은 stepId면 **배열로 쌓음** (`value[k] = (value[k] ?? []) + rects`).
- 최종적으로 **OnboardingOverlayView**에 `frames: [Int: [CGRect]]` 로 넘어간다.  
  → 즉, **“각 단계별로, 그 단계에서 쓰일 사각형들(글로벌)”** 이 한 딕셔너리로 모인다.

---

## 3. 오버레이에서 어떻게 쓰는가 (두 가지 용도)

오버레이는 **같은 `frames`** 를 두 가지 방식으로 쓴다.

### 3.1 하이라이트(딤 레이어의 “구멍”)

- **입력**: `frames[step]` 로 그 단계의 rect들.
  - step 2가 아니면 → **unifiedRect** = rect들 **union** 한 개의 사각형.
  - step 2면 → 말풍선 3개 **그대로** `step2Rects` 로 넘김 (union 안 함).
- **좌표**:  
  - `highlightFrame` = 위에서 정한 “이번 단계 하이라이트 영역” (글로벌 1개 또는 step2는 3개).  
  - 오버레이 자신의 `GeometryReader` 로 **오버레이 로컬**로 변환:  
    `toLocal(r) = r을 글로벌 → (r - geo.frame(in: .global).origin)`  
  - 이 **로컬 사각형**에 대해서만 **갭** 적용:
    - step 1, 3: `raw.insetBy(dx: i, dy: i)` (안쪽으로 갭 → 구멍이 컴포넌트보다 살짝 작게)
    - step 4, 9, 10: `raw.insetBy(dx: -p, dy: -p)` (바깥으로 갭 → 구멍이 컴포넌트보다 여유 있게)
    - step 7: 가로/세로 패딩 등 별도 상수로 확장
    - step 2: 말풍선/꼬리 각각 `toLocal` 후 `step2HighlightOffsetY` 만 적용 (말풍선 위치 보정)
    - step 6: 하이라이트 구멍 없음 (딤만 있고 툴팁만 있음)
- **정리**: 하이라이트 = **preference로 잡은 “실제 컴포넌트(또는 계산 영역)”** 를 오버레이 로컬로 옮긴 뒤, **갭(inset/outset)만** 넣어서 구멍을 뚫는다. **위치를 밀어내는 오프셋은 넣지 않음** (넣으면 실제 컴포넌트와 어긋남).

### 3.2 툴팁/화살표 위치 (ref 락)

- **입력**: 같은 `frames` 에서 **툴팁이 가리킬 대상**만 정함.
  - step 2 → `frames[2]` 의 **첫 번째** (말풍선 본체).
  - 나머지 → **unifiedRect** (위와 동일).
- **좌표계 변환**:
  - 이 대상을 **오버레이 로컬**로 바꾼 뒤 (`tooltipTargetLocal`),
  - **ref 공간(393×852)** 으로 바꿈:  
    `refHighlight = (tooltipTargetLocal - layoutOffset) / layoutScale`  
  - 여기서 `layoutScale`, `layoutOffset` = **OnboardingLayoutLock.uniformScaleAndOffset(overlaySize)** (단일 스케일 + 중앙 정렬).
- **툴팁/화살표 그리기**:
  - **FloatingTooltipView**는 **전부 ref 좌표**로 동작한다 (overlaySize도 393×852로 고정).
  - `TooltipLayout.compute(highlight: refHighlight, overlaySize: refSize, ...)` 로 **설명 박스/화살표 위치**를 ref 공간에서 계산.
  - 화면에 그릴 때만:  
    `screen = ref * layoutScale + layoutOffset`  
    그리고 **refPushDownY / refTextPushDownY / refArrowPushDownY** 를 ref Y에 더해서 “설명/화살표를 아래로 밀기” 적용.
- **정리**: 툴팁/화살표는 **preference로 잡은 대상**을 ref로 옮긴 뒤, **ref 공간에서 레이아웃 락**으로 위치·스케일을 고정하고, 기기마다 `layoutScale`/`layoutOffset` 만 바꿔서 같은 비율로 그린다.

---

## 4. 한 줄 요약

- **무엇을 잡는가**: 각 단계에서 가리킬 **실제 UI 컴포넌트(또는 말풍선/버튼 등 계산 영역)의 글로벌 CGRect**.
- **어떻게 인식하는가**:  
  - **PreferenceKey**로 위 rect들을 `[stepId: [CGRect]]` 로 모아서 오버레이에 전달.  
  - **하이라이트**: 그 rect를 **오버레이 로컬**로만 변환 후 **갭(inset/outset)** 만 적용해 구멍 위치/크기 결정.  
  - **툴팁/화살표**: 같은 rect를 **ref(393×852)** 로 변환한 뒤, ref 기준으로 레이아웃 락 적용하고, 그 결과를 다시 `layoutScale`/`layoutOffset` 으로 화면에 매핑.

즉, **“컴포넌트 영역 잡고, 거기서 갭만 넣어서 여유 있게”** 하는 부분은 **하이라이트(딤 구멍)** 쪽이고, **위치를 고정하는 락**은 **툴팁/화살표(ref 공간)** 쪽에만 적용된다.
