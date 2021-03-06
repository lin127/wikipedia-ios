
public enum WMFAuthLoginError: LocalizedError {
    case cannotExtractInfo
    case cannotAuthenticateNow
    public var errorDescription: String? {
        switch self {
        case .cannotExtractInfo:
            return "Could not extract login info"
        case .cannotAuthenticateNow:
            return "Unable to login at this time"
        }
    }
}

public typealias WMFAuthLoginInfoBlock = (WMFAuthLoginInfo) -> Void

public class WMFAuthLoginInfo: NSObject {
    let canAuthenticateNow:Bool
    init(canAuthenticateNow:Bool) {
        self.canAuthenticateNow = canAuthenticateNow
    }
}

public class WMFAuthLoginInfoFetcher: NSObject {
    private let manager = AFHTTPSessionManager.wmf_createDefault()
    public func isFetching() -> Bool {
        return manager!.operationQueue.operationCount > 0
    }
    public func fetchLoginInfoForSiteURL(_ siteURL: URL, completion: @escaping WMFAuthLoginInfoBlock, failure: @escaping WMFErrorHandler){
        let manager = AFHTTPSessionManager(baseURL: siteURL)
        manager.responseSerializer = WMFApiJsonResponseSerializer.init();
        let parameters = [
            "action": "query",
            "meta": "authmanagerinfo",
            "amirequestsfor": "login",
            "format": "json"
        ]
        _ = manager.wmf_apiPOSTWithParameters(parameters, success: {
            (_, response: Any?) in
            
            guard
                let response = response as? [String : AnyObject],
                let query = response["query"] as? [String : AnyObject],
                let authmanagerinfo = query["authmanagerinfo"] as? [String : AnyObject]
                else {
                    failure(WMFAuthLoginError.cannotExtractInfo)
                    return
            }
            
            guard authmanagerinfo["canauthenticatenow"] != nil else {
                failure(WMFAuthLoginError.cannotAuthenticateNow)
                return
            }
            
            completion(WMFAuthLoginInfo.init(canAuthenticateNow: true))
        }, failure: {
            (_, error: Error) in
            failure(error)
        })
    }
}
