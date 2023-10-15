//
//  APNSManager.swift
//  
//
//  Created by Coden on 2023/10/16.
//

import Foundation
import APNS
import APNSCore
import APNSURLSession

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
