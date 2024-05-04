import Foundation
import OpenAPIAsyncHTTPClient
import OpenAPIRuntime
import HTTPTypes
import NIOHTTP1

public typealias PlaidClientTypes = Components.Schemas

public struct PlaidClientConfiguration {
	let environment: PlaidClientEnvironments, clientId: String, secretKey: String, clientName: String
}

public enum PlaidClientEnvironments {
	case production
	case development
	case sandbox
}

public class PlaidClient {
	
	static let shared = PlaidClient()
	
	private static var config: PlaidClientConfiguration?
		
	private let client: APIProtocol, clientId: String, secretKey: String, clientName: String
	
	private init() {
		guard let config = PlaidClient.config else { fatalError("Error - you must set config as Configuration type before accessing PlaidClient.shared") }
		
		var serverUrl: URL?
		switch config.environment {
		case .production: serverUrl = try? Servers.server1()
		case .development: serverUrl = try? Servers.server2()
		case .sandbox: serverUrl = try? Servers.server3()
		}
		
		guard let serverUrl else { fatalError("Error - failed to construct server URL for \(config.environment)") }
		
		clientId = config.clientId
		secretKey = config.secretKey
		clientName = config.clientName
		client = Client(serverURL: serverUrl, transport: AsyncHTTPClientTransport())
	}
	
	func accountsGet(itemAccessToken: String) async throws -> [PlaidClientTypes.AccountBase] {
		let plaidResponse = try await client.accountsGet(body: .json(.init(access_token: itemAccessToken)))
		switch plaidResponse {
		case .ok(let output):
			return try output.body.json.accounts
		case .default(statusCode: let statusCode, let output):
			let error = try output.body.json
			throw responseError(code: statusCode, error: error)
		}
	}
	
	func linkTokenCreate(userId: String) async throws -> PlaidClientTypes.LinkTokenCreateResponse {
		let plaidResponse = try await client.linkTokenCreate(
			body: .json(
				.init(
					client_name: clientName,
					language: "en",
					country_codes: [.US],
					user: .init(client_user_id: userId),
					products: [.transactions]
				)
			)
		)
		switch plaidResponse {
		case .ok(let output): return try output.body.json
		case .undocumented(let code, let payload):
			throw await responseUndocumented(code: code, payload: payload)
		}
	}
	
	func itemPublicTokenExchange(publicToken: String) async throws -> PlaidClientTypes.ItemPublicTokenExchangeResponse {
		let plaidResponse = try await client.itemPublicTokenExchange(body: .json(.init(public_token: publicToken)))
		switch plaidResponse {
		case .ok(let output): return try output.body.json
		case .undocumented(let code, let payload):
			throw await responseUndocumented(code: code, payload: payload)
		}
	}
	
	func itemGet(accessToken: String) async throws -> PlaidClientTypes.ItemGetResponse {
		let plaidResponse = try await client.itemGet(body: .json(.init(access_token: accessToken)))
		switch plaidResponse {
		case .ok(let output): return try output.body.json
		case .default(statusCode: let statusCode, let output):
			let error = try output.body.json
			throw responseError(code: statusCode, error: error)
		}
	}
	
	func transactionsSync(itemAccessToken: String, cursor: String? = nil) async throws -> PlaidClientTypes.TransactionsSyncResponse {
		let plaidResponse = try await client.transactionsSync(body: .json(.init(access_token: itemAccessToken, cursor: cursor)))
		switch plaidResponse {
		case .ok(let output): return try output.body.json
		case .default(let statusCode, let output):
			let error = try output.body.json
			throw responseError(code: statusCode, error: error)
		}
	}
}

extension PlaidClient {
	
	private func responseError(code: Int, error: PlaidClientTypes.PlaidError) -> PlaidClientError {
		return PlaidClientError(status: HTTPResponseStatus(statusCode: code), reason: error.error_message, suggestedAction: error.suggested_action)
	}
	
	private func responseUndocumented(code: Int, payload: UndocumentedPayload) async -> PlaidClientError {
		do {
			let buffer = try await ArraySlice(collecting: payload.body ?? .init(), upTo: 2 * 1024 * 1024)
			let headers = HTTPHeaders(payload.headerFields.map{ ($0.name.rawName, $0.value) })
			return PlaidClientError(status: HTTPResponseStatus(statusCode: code), headers: headers, reason: String(buffer: .init(bytes: buffer)))
		} catch {
			return PlaidClientError(status: HTTPResponseStatus(statusCode: code), reason: error.localizedDescription)
		}
		
	}
}
