//
//  APIClient.swift
//  LikeLionBudget
//
//  Created by samuel kim on 2/25/26.
//

import Foundation

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
    private let baseURL = URL(string: "http://localhost:3000/api")!

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
    }

    struct BackendGoal: Codable {
        let id: String
        let title: String
        let memo: String?
        let icon: String?
        let category: BudgetCategory
        let monthlyBudgetCents: Int
        let startDate: String
        let endDate: String
        let spentPct: Double
        let remainingPct: Double
        let overBudget: Bool
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

    private func send<T: Decodable>(_ request: URLRequest, as type: T.Type) async throws -> T {
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse else {
                throw APIError.invalidURL
            }
            guard (200..<300).contains(http.statusCode) else {
                throw APIError.serverStatus(http.statusCode)
            }
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
        let dateFormatter = DateFormatter()
        dateFormatter.calendar = Calendar(identifier: .gregorian)
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = "yyyy-MM-dd"

        if let from {
            items.append(URLQueryItem(name: "from", value: dateFormatter.string(from: from)))
        }
        if let to {
            items.append(URLQueryItem(name: "to", value: dateFormatter.string(from: to)))
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

    func fetchGoals() async throws -> [BackendGoal] {
        let request = try makeRequest(
            path: "goals",
            method: "GET"
        )
        return try await send(request, as: [BackendGoal].self)
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
        let dateFormatter = DateFormatter()
        dateFormatter.calendar = Calendar(identifier: .gregorian)
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = "yyyy-MM-dd"

        let body = CreateGoalRequest(
            title: title,
            memo: memo,
            icon: icon,
            category: category,
            monthlyBudgetCents: monthlyBudgetCents,
            startDate: dateFormatter.string(from: startDate),
            endDate: dateFormatter.string(from: endDate)
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
        // We don't care about body; ensure status is OK
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

