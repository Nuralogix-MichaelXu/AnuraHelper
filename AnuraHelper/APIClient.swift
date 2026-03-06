import Foundation

enum Region: Int, Codable {
    case china = 0
    case international = 1
    
    var host: String {
        switch self {
        case .china:
            return "https://api.prod.deepaffex.cn"
        default:
            return "https://api.as-east.deepaffex.ai"
        }
    }
    
    var name: String {
        switch self {
        case .china:
            return Localized("region_china")
        default:
            return Localized("region_international")
        }
    }
}

// MARK: - HTTP Method Enum
enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
}

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

extension APIClient {
    // 修改 getLicences、getStudies、updateStudies 支持进度回调
    static func getLicences() async throws -> [String: [LicenseResponse]] {
        var licensesDic = [String: [LicenseResponse]]()
        var errors = [Error]()
        await withTaskGroup(of: Result<(String, [LicenseResponse]), Error>.self) { group in
            for user in SharedUsers {
                group.addTask {
                    do {
                        let licenses = try await APIClient.getLicences(orgName: user.orgName, region: user.region, limit: 10)
                        return .success((user.orgName, licenses))
                    } catch {
                        return .failure(error)
                    }
                }
            }
            for await result in group {
                switch result {
                case .success(let (orgName, licenses)):
                    licensesDic[orgName] = licenses
                case .failure(let error):
                    errors.append(error)
                }
            }
        }
        if !errors.isEmpty {
            throw errors.first!
        }
        return licensesDic
    }

    static func getStudies() async throws -> [String: [StudyResponse]] {
        var studiesDic = [String: [StudyResponse]]()
        var errors = [Error]()
        await withTaskGroup(of: Result<(String, [StudyResponse]), Error>.self) { group in
            for user in SharedUsers {
                group.addTask {
                    do {
                        let studies = try await APIClient.getStudies(orgName: user.orgName, region: user.region, limit: 20)
                        return .success((user.orgName, studies))
                    } catch {
                        return .failure(error)
                    }
                }
            }
            for await result in group {
                switch result {
                case .success(let (orgName, studies)):
                    studiesDic[orgName] = studies
                case .failure(let error):
                    errors.append(error)
                }
            }
        }
        if !errors.isEmpty {
            throw errors.first!
        }
        return studiesDic
    }

    static func updateStudies(_ studyDic: inout [String: [StudyResponse]], _ billingDateDic: [String: Date]? = nil, _ startDate: Date?, _ endDate: Date?, progress: @escaping () -> Void) async throws {
        var dateStr: String? = nil
        var endDateStr: String? = nil
        if let startDate = startDate { dateStr = startDate.toUTCString() }
        if let endDate = endDate { endDateStr = endDate.toUTCString() }
        
        for (orgName, studies) in studyDic {
            var updatedStudies: [StudyResponse] = studies
            let startDateStr = billingDateDic?[orgName]?.toUTCString() ?? dateStr
            let region = SharedUsers.first(where: { $0.orgName == orgName })?.region ?? .china
            try await withThrowingTaskGroup(of: (Int, Int?, Int?).self) { group in
                for (index, study) in studies.enumerated() {
                    group.addTask {
                        let info = try await APIClient.getMeasurementInfo(orgName: orgName, region: region, studyID: study.ID, date: startDateStr, endDate: endDateStr, progress: progress)
                        return (index, info.successCount, info.failCount)
                    }
                }
                for try await (index, successCount, failCount) in group {
                    if let count = successCount {
                        updatedStudies[index].totalSuccessMeasurements = count
                    }
                    if let count = failCount {
                        updatedStudies[index].totalFailMeasurements = count
                    }
                }
            }
            studyDic[orgName] = updatedStudies
        }
    }

}

// MARK: - APIClient Extension (Login)
extension APIClient {
    static func login(email: String, password: String, org: String, region: Region) async throws -> LoginResponse {
        let body: [String: Any] = [
            "Email": email,
            "Password": password,
            "Identifier": org,
            "TokenExpiresIn": 3600 * 24
        ]
        let data = try await APIClient.shared.sendRequest(
            urlString: region.host + "/organizations/auth",
            method: .post,
            urlParameters: nil,
            body: body,
            headers: nil
        )
        return try JSONDecoder().decode(LoginResponse.self, from: data)
    }
    
    static func getLicences(orgName: String, region: Region, limit: Int) async throws -> [LicenseResponse] {
        let urlParameters: [String: Any] = ["Limit": limit]
        
        let data = try await APIClient.shared.sendRequestWithTokenRefresh(
            urlString: region.host + "/licenses/organization",
            method: .get,
            urlParameters: urlParameters,
            body: nil,
            headers: authHeader(orgName),
            orgName: orgName
        )
        return try JSONDecoder().decode([LicenseResponse].self, from: data)
    }
    
    static func getStudies(orgName: String, region: Region, limit: Int) async throws -> [StudyResponse] {
        let urlParameters: [String: Any] = ["Limit": limit]
        
        let data = try await APIClient.shared.sendRequestWithTokenRefresh(
            urlString: region.host + "/studies",
            method: .get,
            urlParameters: urlParameters,
            body: nil,
            headers: authHeader(orgName),
            orgName: orgName
        )
        return try JSONDecoder().decode([StudyResponse].self, from: data)
    }
    
    static func getMeasurements(orgName: String, region: Region, studyID: String, statusID: String? = nil, date: String? = nil, endDate: String? = nil) async throws -> [MeasurementResponse] {
        var urlParameters: [String: Any] = ["Limit": 1,
                                            "StudyID": studyID]
        if let date = date { urlParameters["Date"] = date }
        if let endDate = endDate { urlParameters["EndDate"] = endDate }
        if let statusID = statusID { urlParameters["StatusID"] = statusID }
        let data = try await APIClient.shared.sendRequestWithTokenRefresh(
            urlString: region.host + "/organizations/measurements",
            method: .get,
            urlParameters: urlParameters,
            body: nil,
            headers: authHeader(orgName),
            orgName: orgName
        )
        if let dataString = String(data: data, encoding: .utf8), dataString.isEmpty {
            print("111111")
            return []
        } else {
            return try JSONDecoder().decode([MeasurementResponse].self, from: data)
        }
    }
    
    static func getMeasurementInfo(orgName: String, region: Region, studyID: String, date: String? = nil, endDate: String? = nil, progress: @escaping () -> Void) async throws -> MeasurementInfo {
        let totalMeasurements = try await getMeasurements(orgName: orgName, region: region, studyID: studyID, date: date, endDate: endDate)
        progress()
        let completeMeasurements = try await getMeasurements(orgName: orgName, region: region, studyID: studyID, statusID: "COMPLETE", date: date, endDate: endDate)
        progress()
        let partialMeasurements = try await getMeasurements(orgName: orgName, region: region, studyID: studyID, statusID: "PARTIAL", date: date, endDate: endDate)
        progress()
        let totalCount = totalMeasurements.first?.TotalCount ?? 0
        let completeCount = completeMeasurements.first?.TotalCount ?? 0
        let partialCount = partialMeasurements.first?.TotalCount ?? 0
        let successCount = completeCount + partialCount
        let failCount = totalCount - successCount
        return MeasurementInfo(orgName: orgName, studyID: studyID, successCount: successCount, failCount: failCount)
    }

    
    static func authHeader(_ orgName: String) async throws -> [String: String] {
        // 优先从SharedUsers获取token
        let token = SharedUsers.first(where: { $0.orgName == orgName })?.token
            ?? UserStorage.load().first(where: { $0.orgName == orgName })?.token
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
        
         print("API->: \(requestURL)")

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
    
    // MARK: - Async sendRequest with token refresh
    func sendRequestWithTokenRefresh(
        urlString: String,
        method: HTTPMethod = .get,
        urlParameters: [String: Any]? = nil,
        body: [String: Any]? = nil,
        headers: [String: String]? = nil,
        orgName: String? = nil
    ) async throws -> Data {
        do {
            return try await sendRequest(
                urlString: urlString,
                method: method,
                urlParameters: urlParameters,
                body: body,
                headers: headers
            )
        } catch {
            if (error as NSError).code == -1,
               let orgName = orgName,
               let userIdx = SharedUsers.firstIndex(where: { $0.orgName == orgName }) {
                let user = SharedUsers[userIdx]
                // 自动刷新token
                let loginResponse = try await APIClient.login(email: user.email, password: user.password, org: user.orgName, region: user.region)
                // 更新token到SharedUsers和UserStorage
                var updatedUser = user
                updatedUser.token = loginResponse.Token
                SharedUsers[userIdx] = updatedUser
                UserStorage.save(users: SharedUsers)
                // 重试原请求
                return try await sendRequest(
                    urlString: urlString,
                    method: method,
                    urlParameters: urlParameters,
                    body: body,
                    headers: APIClient.authHeader(orgName)
                )
            } else {
                throw error
            }
        }
    }
}
