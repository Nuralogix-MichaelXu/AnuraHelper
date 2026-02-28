import Foundation

// MARK: - HTTP Method Enum
enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    // 可扩展更多方法
}

private let host = "https://api.prod.deepaffex.cn"

// MARK: - APIRequest Struct
struct APIRequest {
    let url: URL
    let method: HTTPMethod
    let headers: [String: String]?
    let parameters: [String: Any]?
    
    init(url: URL, method: HTTPMethod = .get, headers: [String: String]? = nil, parameters: [String: Any]? = nil) {
        self.url = url
        self.method = method
        self.headers = headers
        self.parameters = parameters
    }
}

// MARK: - APIClient Extension (Login)
extension APIClient {
    static func login(email: String, password: String, org: String) async throws -> LoginResponse {
        let body: [String: Any] = [
            "Email": email,
            "Password": password,
            "Identifier": org,
            "TokenExpiresIn": 3600*24
        ]
        let data = try await APIClient.shared.sendRequest(
            urlString: host + "/organizations/auth",
            method: .post,
            urlParameters: nil,
            body: body,
            headers: nil
        )
        return try JSONDecoder().decode(LoginResponse.self, from: data)
    }
    
    static func getLicences(orgName: String, limit: Int) async throws -> [LicenseResponse] {
        let urlParameters: [String: Any] = ["Limit": limit]
        
        let data = try await APIClient.shared.sendRequest(
            urlString: host + "/licenses/organization",
            method: .get,
            urlParameters: urlParameters,
            body: nil,
            headers: authHeader(orgName)
        )
        return try JSONDecoder().decode([LicenseResponse].self, from: data)
    }
    
    static func getStudies(orgName: String, limit: Int) async throws -> [StudyResponse] {
        let urlParameters: [String: Any] = ["Limit": limit]
        
        let data = try await APIClient.shared.sendRequest(
            urlString: host + "/studies",
            method: .get,
            urlParameters: urlParameters,
            body: nil,
            headers: authHeader(orgName)
        )
        return try JSONDecoder().decode([StudyResponse].self, from: data)
    }
    
    static func getMeasurements(orgName: String, studyID: String, statusID: String) async throws -> [MeasurementResponse] {
        let urlParameters: [String: Any] = ["Limit": 1,
                                            "StudyID": studyID,
                                            "StatusID": statusID]
        
        let data = try await APIClient.shared.sendRequest(
            urlString: host + "/organizations/measurements",
            method: .get,
            urlParameters: urlParameters,
            body: nil,
            headers: authHeader(orgName)
        )
        return try JSONDecoder().decode([MeasurementResponse].self, from: data)
    }
    
    static func getMeasurementInfo(orgName: String, studyID: String, progress: @escaping () -> Void) async throws -> MeasurementInfo {
        let completeMeasurements = try await getMeasurements(orgName: orgName, studyID: studyID, statusID: "COMPLETE")
        progress()
        let partialMeasurements = try await getMeasurements(orgName: orgName, studyID: studyID, statusID: "PARTIAL")
        progress()
        let completeCount = completeMeasurements.first?.TotalCount ?? 0
        let partialCount = partialMeasurements.first?.TotalCount ?? 0
        let successCount = completeCount + partialCount
        return MeasurementInfo(orgName: orgName, studyID: studyID, successCount: successCount)
    }

    
    static func authHeader(_ orgName: String) async throws -> [String: String] {
        let token = SharedUsers.filter { user in
            return user.orgName == orgName
        }.first?.token
        guard let token = token else {
            throw NSError(domain: "APIClient", code: -4, userInfo: [NSLocalizedDescriptionKey: "未找到对应组织的授权Token"])
        }
        return ["Authorization": "Bearer \(token)"]
    }
}

// MARK: - APIClient Class
class APIClient {
    static let shared = APIClient()
    private init() {}
    
    func request(_ apiRequest: APIRequest, completion: @escaping (Result<Data, Error>) -> Void) {
        var requestURL = apiRequest.url
        var request: URLRequest
        
        if apiRequest.method == .get, let params = apiRequest.parameters {
            var urlComponents = URLComponents(url: apiRequest.url, resolvingAgainstBaseURL: false)
            urlComponents?.queryItems = params.map { key, value in
                URLQueryItem(name: key, value: "\(value)")
            }
            if let urlWithParams = urlComponents?.url {
                requestURL = urlWithParams
            }
        }
        request = URLRequest(url: requestURL)
        request.httpMethod = apiRequest.method.rawValue
        
        apiRequest.headers?.forEach { key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        if apiRequest.method == .post, let params = apiRequest.parameters {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try? JSONSerialization.data(withJSONObject: params, options: [])
        }
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let data = data else {
                completion(.failure(NSError(domain: "APIClient", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data"])))
                return
            }
            if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                var errorMsg = errorResponse.Message
                if errorMsg.isEmpty {
                    errorMsg = "发生错误：\(errorResponse.Code)"
                }
                let apiError = NSError(domain: "APIClient", code: -1, userInfo: [NSLocalizedDescriptionKey: errorMsg])
                completion(.failure(apiError))
                return
            }
            print("API->: \(requestURL)")
            completion(.success(data))
        }
        task.resume()
    }
    
    /// 对外公开的简化方法，支持url、请求类型、url参数、body、headers
    func sendRequest(
        urlString: String,
        method: HTTPMethod = .get,
        urlParameters: [String: Any]? = nil,
        body: [String: Any]? = nil,
        headers: [String: String]? = nil,
        completion: @escaping (Result<Data, Error>) -> Void
    ) {
        guard var urlComponents = URLComponents(string: urlString) else {
            completion(.failure(NSError(domain: "APIClient", code: -2, userInfo: [NSLocalizedDescriptionKey: "Invalid URL string"])))
            return
        }
        if let urlParameters = urlParameters {
            urlComponents.queryItems = urlParameters.map { key, value in
                URLQueryItem(name: key, value: "\(value)")
            }
        }
        guard let url = urlComponents.url else {
            completion(.failure(NSError(domain: "APIClient", code: -3, userInfo: [NSLocalizedDescriptionKey: "Failed to build URL with parameters"])))
            return
        }
        let parameters: [String: Any]? = (method == .get) ? nil : body
        let apiRequest = APIRequest(url: url, method: method, headers: headers, parameters: parameters)
        self.request(apiRequest, completion: completion)
    }
    
    // MARK: - Async sendRequest
    func sendRequest(
        urlString: String,
        method: HTTPMethod = .get,
        urlParameters: [String: Any]? = nil,
        body: [String: Any]? = nil,
        headers: [String: String]? = nil
    ) async throws -> Data {
        return try await withCheckedThrowingContinuation { continuation in
            self.sendRequest(
                urlString: urlString,
                method: method,
                urlParameters: urlParameters,
                body: body,
                headers: headers
            ) { result in
                switch result {
                case .success(let data):
                    continuation.resume(returning: data)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}


extension TimeInterval {
    func toDateString() -> String {
        let date = Date(timeIntervalSince1970: self)
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "zh_CN") // 设置中文locale，确保格式统一
        formatter.timeZone = TimeZone(secondsFromGMT: 8) // 可选：设置时区，默认使用系统时区
        return formatter.string(from: date)
    }
}
