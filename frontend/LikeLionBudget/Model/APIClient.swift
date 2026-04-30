//
//  APIClient.swift
//  LikeLionBudget
//
//  Created by samuel kim on 2/25/26.
//

import Foundation

// MARK: - API Base URL

enum APIConfig {
    static let baseURLString = "https://ucilikelion-production.up.railway.app/api"
}

// MARK: - API Error

enum APIError: Error {
    case invalidURL
    case transport(Error)
    case serverStatus(Int)
    case decoding(Error)
}

// MARK: - User Identity (x-user-id)

enum UserIdentity {
    private static let key = "LikeLionBudget.UserId"

    static var currentUserId: String {
        if let existing = UserDefaults.standard.string(forKey: key) {
            return existing
        }
        let new = UUID().uuidString
        UserDefaults.standard.set(new, forKey: key)
        return new
    }
}

struct APIClient {
    private let baseURL = URL(string: APIConfig.baseURLString)!

    private let isoDateTime: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()

    // MARK: - Public DTOs

    struct BackendTransaction: Codable {
        let id: String
        let title: String
        let amountCents: Int
        let type: String
        let category: BudgetCategory
        let occurredAt: String
        let isFixed: Bool
        let note: String?

        private enum CodingKeys: String, CodingKey {
            case id, title, amountCents, type, category, occurredAt, isFixed, note
        }

        init(id: String, title: String, amountCents: Int, type: String, category: BudgetCategory, occurredAt: String, isFixed: Bool, note: String?) {
            self.id = id
            self.title = title
            self.amountCents = amountCents
            self.type = type
            self.category = category
            self.occurredAt = occurredAt
            self.isFixed = isFixed
            self.note = note
        }

        init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            id = try c.decode(String.self, forKey: .id)
            title = try c.decode(String.self, forKey: .title)
            amountCents = try c.decode(Int.self, forKey: .amountCents)
            type = try c.decode(String.self, forKey: .type)
            let rawCategory = try c.decodeIfPresent(String.self, forKey: .category)
            category = BudgetCategory(fromServer: rawCategory)
            occurredAt = try c.decode(String.self, forKey: .occurredAt)
            isFixed = try c.decode(Bool.self, forKey: .isFixed)
            note = try c.decodeIfPresent(String.self, forKey: .note)
        }

        func encode(to encoder: Encoder) throws {
            var c = encoder.container(keyedBy: CodingKeys.self)
            try c.encode(id, forKey: .id)
            try c.encode(title, forKey: .title)
            try c.encode(amountCents, forKey: .amountCents)
            try c.encode(type, forKey: .type)
            try c.encode(category.rawValue, forKey: .category)
            try c.encode(occurredAt, forKey: .occurredAt)
            try c.encode(isFixed, forKey: .isFixed)
            try c.encodeIfPresent(note, forKey: .note)
        }
    }

    struct BackendGoal: Codable {
        let id: String
        let title: String
        let memo: String?
        let icon: String?
        let category: BudgetCategory
        let monthlyBudgetCents: Int
        let startDate: String?
        let endDate: String?
        let spentPct: Double
        let remainingPct: Double
        let overBudget: Bool

        private enum CodingKeys: String, CodingKey {
            case id, title, memo, icon, category
            case monthlyBudgetCents
            case monthly_budget = "monthly_budget"
            case startDate
            case start_date = "start_date"
            case endDate
            case end_date = "end_date"
            case spentPct
            case remainingPct
            case percentage = "percentage"
            case overBudget
            case current_spent = "current_spent"
        }

        init(
            id: String,
            title: String,
            memo: String?,
            icon: String?,
            category: BudgetCategory,
            monthlyBudgetCents: Int,
            startDate: String?,
            endDate: String?,
            spentPct: Double,
            remainingPct: Double,
            overBudget: Bool
        ) {
            self.id = id
            self.title = title
            self.memo = memo
            self.icon = icon
            self.category = category
            self.monthlyBudgetCents = monthlyBudgetCents
            self.startDate = startDate
            self.endDate = endDate
            self.spentPct = spentPct
            self.remainingPct = remainingPct
            self.overBudget = overBudget
        }

        /// JSON에서 70(정수) 또는 70.0(실수) 둘 다 받기 위함
        private static func decodeDouble(from c: KeyedDecodingContainer<BackendGoal.CodingKeys>, forKey key: BackendGoal.CodingKeys) -> Double? {
            if let i = try? c.decodeIfPresent(Int.self, forKey: key) { return Double(i) }
            return try? c.decodeIfPresent(Double.self, forKey: key)
        }

        init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            id = try c.decode(String.self, forKey: .id)
            title = try c.decodeIfPresent(String.self, forKey: .title) ?? ""
            memo = try c.decodeIfPresent(String.self, forKey: .memo)
            icon = try c.decodeIfPresent(String.self, forKey: .icon)
            let rawCategory = try c.decodeIfPresent(String.self, forKey: .category)
            category = BudgetCategory(fromServer: rawCategory)
            let budget: Int
            if let v = try c.decodeIfPresent(Int.self, forKey: .monthlyBudgetCents) {
                budget = v
            } else if let v = try c.decodeIfPresent(Double.self, forKey: .monthly_budget) {
                budget = Int(v)
            } else {
                budget = 0
            }
            monthlyBudgetCents = budget
            let start = try c.decodeIfPresent(String.self, forKey: .startDate)
            let startAlt = try c.decodeIfPresent(String.self, forKey: .start_date)
            startDate = start ?? startAlt
            let end = try c.decodeIfPresent(String.self, forKey: .endDate)
            let endAlt = try c.decodeIfPresent(String.self, forKey: .end_date)
            endDate = end ?? endAlt
            remainingPct = Self.decodeDouble(from: c, forKey: .remainingPct) ?? Self.decodeDouble(from: c, forKey: .percentage) ?? 0
            spentPct = Self.decodeDouble(from: c, forKey: .spentPct) ?? 0
            overBudget = try c.decodeIfPresent(Bool.self, forKey: .overBudget) ?? false
        }

        func encode(to encoder: Encoder) throws {
            var c = encoder.container(keyedBy: CodingKeys.self)
            try c.encode(id, forKey: .id)
            try c.encode(title, forKey: .title)
            try c.encodeIfPresent(memo, forKey: .memo)
            try c.encodeIfPresent(icon, forKey: .icon)
            try c.encode(category.rawValue, forKey: .category)
            try c.encode(monthlyBudgetCents, forKey: .monthlyBudgetCents)
            try c.encodeIfPresent(startDate, forKey: .startDate)
            try c.encodeIfPresent(endDate, forKey: .endDate)
            try c.encode(spentPct, forKey: .spentPct)
            try c.encode(remainingPct, forKey: .remainingPct)
            try c.encode(overBudget, forKey: .overBudget)
        }
    }

    struct PlaidLinkTokenResponse: Codable {
        let linkToken: String
    }

    // MARK: - Dashboard

    struct DashboardResponse: Codable {
        let summary: DashboardSummary
        let activeGoals: [DashboardActiveGoal]
        let character: DashboardCharacter
    }

    struct DashboardSummary: Codable {
        let nickname: String?
        let totalMonthlyBudgetCents: Int
        let totalMonthSpentCents: Int
    }

    struct DashboardActiveGoal: Codable {
        let id: String
        let title: String
        let category: String
        let budget: Int
        let spent: Int
        let remainingAmount: Int
        let remainingPct: Double
        let isOverBudget: Bool
    }

    struct DashboardCharacter: Codable {
        let status: String
        let bubbleText: String
    }

    // MARK: - Core request

    private func makeRequest(
        path: String,
        method: String,
        queryItems: [URLQueryItem]? = nil,
        body: Encodable? = nil
    ) throws -> URLRequest {
        guard var components = URLComponents(url: baseURL.appendingPathComponent(path), resolvingAgainstBaseURL: false) else {
            throw APIError.invalidURL
        }
        if let queryItems {
            components.queryItems = queryItems
        }
        guard let url = components.url else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(UserIdentity.currentUserId, forHTTPHeaderField: "x-user-id")

        if let body {
            let data = try JSONEncoder().encode(AnyEncodable(body))
            request.httpBody = data
        }
        return request
    }

    private func sendData(_ request: URLRequest) async throws -> Data {
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw APIError.invalidURL }
        guard (200..<300).contains(http.statusCode) else { throw APIError.serverStatus(http.statusCode) }
        return data
    }

    private func send<T: Decodable>(_ request: URLRequest, as type: T.Type) async throws -> T {
        do {
            let data = try await sendData(request)
            do {
                return try JSONDecoder().decode(T.self, from: data)
            } catch {
                throw APIError.decoding(error)
            }
        } catch {
            if let apiError = error as? APIError {
                throw apiError
            }
            throw APIError.transport(error)
        }
    }

    // MARK: - Transactions

    struct CreateTransactionRequest: Encodable {
        let title: String
        let amountCents: Int
        let type: String
        let category: BudgetCategory
        let occurredAt: String
        let isFixed: Bool
        let note: String?
    }

    func fetchTransactions(from: Date? = nil, to: Date? = nil) async throws -> [BackendTransaction] {
        var items: [URLQueryItem] = []
        if let from {
            items.append(URLQueryItem(name: "from", value: AppFormatters.apiDate.string(from: from)))
        }
        if let to {
            items.append(URLQueryItem(name: "to", value: AppFormatters.apiDate.string(from: to)))
        }

        let request = try makeRequest(
            path: "transactions",
            method: "GET",
            queryItems: items.isEmpty ? nil : items
        )
        return try await send(request, as: [BackendTransaction].self)
    }

    func createTransaction(
        title: String,
        amountCents: Int,
        type: String,
        category: BudgetCategory,
        occurredAt: Date,
        isFixed: Bool,
        note: String?
    ) async throws -> BackendTransaction {
        let body = CreateTransactionRequest(
            title: title,
            amountCents: amountCents,
            type: type,
            category: category,
            occurredAt: isoDateTime.string(from: occurredAt),
            isFixed: isFixed,
            note: note
        )
        let request = try makeRequest(
            path: "transactions",
            method: "POST",
            body: body
        )
        return try await send(request, as: BackendTransaction.self)
    }

    func updateTransaction(
        id: String,
        title: String,
        amountCents: Int,
        type: String,
        category: BudgetCategory,
        occurredAt: Date,
        isFixed: Bool,
        note: String?
    ) async throws -> BackendTransaction {
        let body = CreateTransactionRequest(
            title: title,
            amountCents: amountCents,
            type: type,
            category: category,
            occurredAt: isoDateTime.string(from: occurredAt),
            isFixed: isFixed,
            note: note
        )
        let request = try makeRequest(
            path: "transactions/\(id)",
            method: "PUT",
            body: body
        )
        return try await send(request, as: BackendTransaction.self)
    }

    func deleteTransaction(id: String) async throws {
        let url = baseURL.appendingPathComponent("transactions").appendingPathComponent(id)
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(UserIdentity.currentUserId, forHTTPHeaderField: "x-user-id")
        _ = try await send(request, as: EmptyResponse.self)
    }

    // MARK: - Goals

    struct CreateGoalRequest: Encodable {
        let title: String
        let memo: String?
        let icon: String?
        let category: BudgetCategory
        let monthlyBudgetCents: Int
        let startDate: String
        let endDate: String
    }

    /// Mock/백엔드가 배열 `[...]` 또는 객체 `{ "goals": [...] }` 둘 다 허용
    func fetchGoals() async throws -> [BackendGoal] {
        let request = try makeRequest(
            path: "goals",
            method: "GET"
        )
        let data = try await sendData(request)
        if let wrapped = try? JSONDecoder().decode(GoalsResponseWrapper.self, from: data) {
            return wrapped.goals
        }
        return try JSONDecoder().decode([BackendGoal].self, from: data)
    }

    private struct GoalsResponseWrapper: Decodable {
        let goals: [BackendGoal]
    }

    func createGoal(
        title: String,
        memo: String?,
        icon: String?,
        category: BudgetCategory,
        monthlyBudgetCents: Int,
        startDate: Date,
        endDate: Date
    ) async throws -> BackendGoal {
        let body = CreateGoalRequest(
            title: title,
            memo: memo,
            icon: icon,
            category: category,
            monthlyBudgetCents: monthlyBudgetCents,
            startDate: AppFormatters.apiDate.string(from: startDate),
            endDate: AppFormatters.apiDate.string(from: endDate)
        )
        let request = try makeRequest(
            path: "goals",
            method: "POST",
            body: body
        )
        return try await send(request, as: BackendGoal.self)
    }

    // MARK: - Plaid

    func createPlaidLinkToken() async throws -> PlaidLinkTokenResponse {
        let request = try makeRequest(
            path: "plaid/create_link_token",
            method: "GET"
        )
        return try await send(request, as: PlaidLinkTokenResponse.self)
    }

    struct ExchangePublicTokenRequest: Encodable {
        let public_token: String
    }

    func exchangePlaidPublicToken(_ publicToken: String) async throws {
        let body = ExchangePublicTokenRequest(public_token: publicToken)
        let request = try makeRequest(
            path: "plaid/exchange_public_token",
            method: "POST",
            body: body
        )
        _ = try await send(request, as: EmptyResponse.self)
    }

    func syncPlaid() async throws {
        let request = try makeRequest(
            path: "plaid/sync",
            method: "POST"
        )
        _ = try await send(request, as: EmptyResponse.self)
    }

    // MARK: - Dashboard

    func fetchDashboard() async throws -> DashboardResponse {
        let request = try makeRequest(path: "dashboard", method: "GET")
        return try await send(request, as: DashboardResponse.self)
    }

    // MARK: - FCM Token

    struct FCMTokenRequest: Encodable {
        let fcmToken: String
    }

    func updateFCMToken(_ token: String) async throws {
        let body = FCMTokenRequest(fcmToken: token)
        let request = try makeRequest(path: "users/fcm-token", method: "PATCH", body: body)
        _ = try await sendData(request)
    }
}

// MARK: - Private Helpers

private struct AnyEncodable: Encodable {
    private let encodeFunc: (Encoder) throws -> Void

    init(_ wrapped: Encodable) {
        self.encodeFunc = wrapped.encode
    }

    func encode(to encoder: Encoder) throws {
        try encodeFunc(encoder)
    }
}

private struct EmptyResponse: Decodable {}

