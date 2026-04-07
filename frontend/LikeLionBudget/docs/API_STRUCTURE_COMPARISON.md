# API 구조 비교: 앱 vs 백엔드

앱(프론트)이 기대하는 구조와 실제 백엔드(이 레포) 구조를 나란히 정리했습니다.  
**한눈에 안 맞는 부분**은 표에서 ⚠️ 로 표시했습니다.

---

## 1. 공통

| 항목 | 앱 (프론트) | 백엔드 (이 레포) | 비고 |
|------|-------------|------------------|------|
| **User ID 헤더** | `x-user-id` | `user-id` | ⚠️ 이름 불일치 |
| **Base path** | `/api` | `/api` | 동일 |

---

## 2. 대시보드 (Dashboard)

| 항목 | 앱 (프론트) | 백엔드 (이 레포) | 비고 |
|------|-------------|------------------|------|
| **경로** | `GET /api/dashboard` | `GET /api/dashboard/status` | ⚠️ 경로 다름 |
| **응답** | 아래 `DashboardResponse` | 아래 백엔드 응답 | 구조 완전히 다름 |

### 앱이 기대하는 응답 (DashboardResponse)

```json
{
  "summary": {
    "nickname": "string?",
    "totalMonthlyBudgetCents": 0,
    "totalMonthSpentCents": 0
  },
  "activeGoals": [
    {
      "id": "string",
      "title": "string",
      "category": "string",
      "budget": 0,
      "spent": 0,
      "remainingAmount": 0,
      "remainingPct": 0,
      "isOverBudget": false
    }
  ],
  "character": {
    "status": "string",
    "bubbleText": "string"
  }
}
```

- **summary**: nickname, totalMonthlyBudgetCents, totalMonthSpentCents (camelCase)
- **activeGoals**: 배열, 각 항목 id, title, category, budget, spent, remainingAmount, remainingPct, isOverBudget
- **character**: status, bubbleText

### 백엔드가 실제 보내는 응답 (dashboardController)

```json
{
  "total_spent": 0,
  "character_status": "NORMAL",
  "month": 1
}
```

- **total_spent** (snake_case) → 앱의 summary.totalMonthSpentCents에 해당하지만 summary 자체 없음
- **character_status** → 앱의 character.status에 해당하지만 character.bubbleText 없음
- **month** → 앱에 해당 필드 없음
- **activeGoals, summary.nickname, summary.totalMonthlyBudgetCents** → 백엔드에 없음 ⚠️

---

## 3. 목표 (Goals)

| 항목 | 앱 (프론트) | 백엔드 (이 레포) | 비고 |
|------|-------------|------------------|------|
| **목록** | `GET /api/goals` | `GET /api/goals` | 경로 동일 |
| **생성** | `POST /api/goals` | `POST /api/goals` | 경로 동일 |

### 앱이 기대하는 Goal 한 건 (BackendGoal)

| 필드 (앱) | 타입 | 백엔드 필드/비고 |
|-----------|------|------------------|
| id | String | ✅ Prisma `id` |
| title | String | ⚠️ 백엔드 Goal 모델에 없음 |
| memo | String? | ⚠️ 없음 |
| icon | String? | ⚠️ 없음 |
| category | String (→ BudgetCategory 매핑) | ✅ Prisma `category` (문자열) |
| monthlyBudgetCents | Int | ⚠️ 백엔드는 `monthly_budget` (Decimal, snake_case) |
| startDate | String? (yyyy-MM-dd) | ⚠️ 백엔드는 `start_date` (DateTime, snake_case) |
| endDate | String? (yyyy-MM-dd) | ⚠️ 백엔드는 `end_date` (DateTime, snake_case) |
| spentPct | Double | ⚠️ 백엔드는 `current_spent` + 계산한 `percentage` 등 (필드명·의미 다름) |
| remainingPct | Double | ⚠️ 컨트롤러에서 `percentage`로 전송 (이름·의미 다름) |
| overBudget | Bool | ⚠️ 없음 (status_color 등으로 유추 가능) |

- 앱: **camelCase**, 백엔드(Prisma): **snake_case** → 필드명 불일치 ⚠️  
- 앱: title, memo, icon 필요 → 백엔드 스키마에 없음 ⚠️

### 백엔드 Goal (Prisma + goalController 포맷)

- Prisma: `id`, `userId`, `category`, `monthly_budget`, `current_spent`, `status`, `last_alert_threshold`, `start_date`, `end_date`
- 컨트롤러 추가: `current_spent`, `monthly_budget` (숫자), `percentage`, `status_color`

### 앱이 보내는 POST Goal (CreateGoalRequest)

```json
{
  "title": "string",
  "memo": "string?",
  "icon": "string?",
  "category": "string",
  "monthlyBudgetCents": 0,
  "startDate": "yyyy-MM-dd",
  "endDate": "yyyy-MM-dd"
}
```

### 백엔드가 받는 POST Goal (createGoal)

- body: **category**, **monthly_budget** 만 사용 ⚠️  
- title, memo, icon, startDate, endDate 없음. start_date/end_date는 서버에서 “이번 달”로 고정 생성.

---

## 4. 거래 (Transactions)

| 항목 | 앱 (프론트) | 백엔드 (이 레포) | 비고 |
|------|-------------|------------------|------|
| **목록** | `GET /api/transactions` (?from=&to=) | **라우트 없음** | ⚠️ 백엔드에 트랜잭션 API 없음 (Mock만 사용) |
| **생성** | `POST /api/transactions` | **라우트 없음** | ⚠️ 동일 |
| **수정** | `PUT /api/transactions/:id` | **라우트 없음** | ⚠️ 동일 |
| **삭제** | `DELETE /api/transactions/:id` | **라우트 없음** | ⚠️ 동일 |

### 앱이 기대하는 Transaction 한 건 (BackendTransaction)

| 필드 (앱) | 타입 | 백엔드(Prisma) Transaction |
|-----------|------|----------------------------|
| id | String | ✅ id |
| title | String | ⚠️ 없음. 백엔드는 `store_name` |
| amountCents | Int | ⚠️ 백엔드는 `amount` (Decimal, 단위 불명) |
| type | String | ⚠️ 없음 |
| category | String | ✅ category |
| occurredAt | String (ISO8601) | ⚠️ 백엔드는 `date` (DateTime) |
| isFixed | Bool | ⚠️ 없음 |
| note | String? | ⚠️ 없음 |

- 백엔드에는 **transactions 라우트가 아예 없음**. 현재는 Postman Mock 등 외부 Mock으로만 연동 가능.

---

## 5. POST Transaction 응답 (앱 기준)

- 앱: `createTransaction` 응답을 **BackendTransaction 한 건**으로 디코딩.
- 만약 백엔드가 `{ "transaction": {...}, "goal": {...}, "alert": {...} }` 형태로 준다면 ⚠️ 디코딩 실패.  
  → 래퍼 DTO를 두거나, 백엔드가 transaction 객체만 내려주도록 맞추는 것이 필요.

---

## 6. 한눈에 보는 불일치 요약

| 구분 | 불일치 내용 |
|------|-------------|
| **헤더** | 앱 `x-user-id` vs 백엔드 `user-id` |
| **Dashboard** | 경로 `/dashboard` vs `/dashboard/status`, 응답 구조·필드명 완전 상이 (camelCase vs snake_case, summary/activeGoals/character 등) |
| **Goals** | 필드명 snake_case vs camelCase, title/memo/icon/startDate/endDate 등 앱 필드가 백엔드에 없음. POST는 백엔드가 category, monthly_budget만 사용 |
| **Transactions** | 백엔드에 API 없음. Prisma 스키마도 앱 DTO와 다름 (store_name vs title, amount vs amountCents, date vs occurredAt, type/isFixed/note 없음) |
| **POST Transaction 응답** | 앱은 단일 transaction 객체 기대; 래퍼 `{ transaction, goal, alert }`면 디코딩 실패 가능 |

---

## 7. 앱 쪽 DTO 정리 (참고)

- **Dashboard**: `DashboardResponse` → `DashboardSummary`, `DashboardActiveGoal`, `DashboardCharacter`
- **Goals**: `BackendGoal`, `CreateGoalRequest`
- **Transactions**: `BackendTransaction`, `CreateTransactionRequest`
- **Category**: 서버 문자열은 `BudgetCategory.init(fromServer:)`로 매핑 (income, cafe, groceries, util 등)

이 문서는 앱과 백엔드 구조를 맞출 때, **어디를 고칠지** 결정하기 위한 기준으로 사용하면 됩니다.
