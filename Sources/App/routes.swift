import Vapor
import Fluent
import FluentKit
import APNS
import APNSCore
import APNSURLSession
import MultipartKit

func routes(_ app: Application) throws {
    // user_register (유저 등록)
    app.post("user", "register") { request async throws -> User in
        let userToBeAdded = try request.content.decode(UserToBeAdded.self)
        
        let newUser = User(
            name: userToBeAdded.name,
            imageUrl: userToBeAdded.imageUrl,
            userDescription: userToBeAdded.userDescription
        )
        try await newUser.create(on: request.db)
        
        return newUser
    }
    
    app.on(.POST, "user", "image", body: .collect(maxSize: ByteCount(value: 1024 * 100))) { request in
        struct ImageEntity: Content {
            let name: String
            let file: File
        }
        
        let imageEntity = try request.content.decode(ImageEntity.self)
        try await request.fileio.writeFile(imageEntity.file.data, at: Secrets.imagePath + imageEntity.name)
        
        return try await User.query(on: request.db).with(\.$group).all()
    }
    
    app.get("images", ":imageName") { request in
        let imageName = request.parameters.get("imageName")
        
        let filePath = Secrets.imagePath + "\(imageName!)"
        
        print("\(filePath)")
        
        return request.fileio.streamFile(at: filePath)
    }
    
    app.get("get_users") { request in
        try await User.query(on: request.db).with(\.$group).all()
    }
    
    // user/lists (유저 목록)
    // user/info (유저 정보)
    
    app.get { req async in
        "It works!"
    }

    app.get("hello") { req async -> String in
        "Hello, world!"
    }
    
    app.get("ellen") { req async -> String in
        ""
    }
    
    app.get("dbTest") { req async throws in
        try await User.query(on: req.db).with(\.$group).all()
    }
    
    app.post("post_db") { req async throws -> User in
        let user = try req.content.decode(User.self)
        
        let maxId = try await User.query(on: req.db).max(\.$id) ?? (100...1000).randomElement() ?? 999
        user.id = maxId + 1
        try await user.create(on: req.db)
        
        return user
    }
    
    app.webSocket("echo") { request, webSocket in
        print(request)
        print(webSocket)
        webSocket.onText { ws, text in
            print("received from client - \(text)")
            ws.send("잘 받았어요 from server")
            
            Task {
                try await sendAPNS(title: "코든/앱을 통한 전송", subTitle:"보내지나요?")
            }
        }
        
        webSocket.onPing { ws, buffer in
            print("received from client ping")
            ws.sendPing()
        }
    }
}

private func sendAPNS(title: String, subTitle: String) async throws {
    // APNS
    let apnsConfig = APNSClientConfiguration(
        authenticationMethod: .jwt(privateKey: try .init(pemRepresentation: Secrets.apnsKey), keyIdentifier: Secrets.apnsKeyIdentifier, teamIdentifier: Secrets.apnsTeamIdentifier),
        environment: .sandbox
    )
    
    let client = APNSClient(configuration: apnsConfig, eventLoopGroupProvider: .createNew, responseDecoder: JSONDecoder(), requestEncoder: JSONEncoder())
    
    try await sendSimpleAlert(with: client, title: title, subTitle: subTitle)
    client.shutdown { _ in
        //
    }
}

private func sendSimpleAlert(with client: some APNSClientProtocol, title: String, subTitle: String) async throws {
    try await client.sendAlertNotification(
        .init(
            alert: .init(
                title: .raw(title),
                subtitle: .raw(subTitle),
                body: .raw("Body"),
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
