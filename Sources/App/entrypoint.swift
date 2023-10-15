import Vapor
import Dispatch
import Logging
import APNS
import APNSCore
import APNSURLSession

/// This extension is temporary and can be removed once Vapor gets this support.
private extension Vapor.Application {
    static let baseExecutionQueue = DispatchQueue(label: "vapor.codes.entrypoint")
    
    func runFromAsyncMainEntrypoint() async throws {
        try await withCheckedThrowingContinuation { continuation in
            Vapor.Application.baseExecutionQueue.async { [self] in
                do {
                    try self.run()
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}

@main
enum Entrypoint {
    static func main() async throws {
        var env = try Environment.detect()
        try LoggingSystem.bootstrap(from: &env)
        
        let app = Application(env)
        let apns = APNSManager.shared
        
        do {
            try await configure(app)
        } catch {
            app.logger.report(error: error)
            throw error
        }
        try await app.runFromAsyncMainEntrypoint()
        
        try await apns.shutdown()
        app.shutdown()
    }
}

// MARK: - APNS 담당 Actor

final actor APNSManager {
    // MARK: Properties
    static let shared = APNSManager()
    private let apnsClient: APNSClient<JSONDecoder, JSONEncoder>
    private var didShutdown = false
    
    // MARK: initializer
    private init() {
        do {
            let apnsConfig = APNSClientConfiguration(
                authenticationMethod:
                        .jwt(
                            privateKey: try .init(pemRepresentation: Secrets.apnsKey),
                            keyIdentifier: Secrets.apnsKeyIdentifier,
                            teamIdentifier: Secrets.apnsTeamIdentifier
                        ),
                environment: .sandbox
            )
            
            self.apnsClient = APNSClient(
                configuration: apnsConfig,
                eventLoopGroupProvider: .createNew,
                responseDecoder: JSONDecoder(),
                requestEncoder: JSONEncoder()
            )
            
        } catch {
            fatalError("APNS 서버 설정 실패 - \(error)")
        }
    }
}

// MARK: - Interface

// MARK: push 전송
extension APNSManager {
    func sendSimpleAlert(title: String, subTitle: String) async throws {
        try await self.apnsClient.sendAlertNotification(
            APNSAlertNotification(
                alert:
                    APNSAlertNotificationContent(
                        title: .raw(title),
                        subtitle: .raw(subTitle),
                        body: .raw(""),
                        launchImage: nil
                    ),
                expiration: .immediately,
                priority: .immediately,
                topic: Secrets.apnsAppBundleID,
                payload: EmptyPayload()
            ),
            // let token = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
            deviceToken: Secrets.deviceToken
        )
    }
}

// MARK: 설정 및 종료 관련
extension APNSManager {
    /// APNSClient 종료
    func shutdown() throws {
        assert(!self.didShutdown, "APNS has already shut down")
        
        try self.apnsClient.syncShutdown()
        self.didShutdown = true
    }
}
