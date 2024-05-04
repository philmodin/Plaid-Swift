import NIOHTTP1

public protocol PlaidClientErrorType: Error {
	var reason: String { get }
	
	var status: HTTPResponseStatus { get }
	
	var headers: HTTPHeaders { get }
	
	var suggestedAction: String { get }
}

extension PlaidClientErrorType {
	public var headers: HTTPHeaders {
		[:]
	}
	
	public var reason: String {
		self.status.reasonPhrase
	}
}

public struct PlaidClientError: PlaidClientErrorType {
	public var suggestedAction: String
	
	public var reason: String
	
	public var status: HTTPResponseStatus
	
	public var headers: HTTPHeaders
	
	public init(
		status: HTTPResponseStatus,
		headers: HTTPHeaders = [:],
		reason: String? = nil,
		suggestedAction: String? = ""
	) {
		self.headers = headers
		self.status = status
		self.reason = reason ?? status.reasonPhrase
		self.suggestedAction = suggestedAction ?? ""
	}
}
