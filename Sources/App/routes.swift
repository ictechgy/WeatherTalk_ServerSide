import Vapor
import Fluent
import FluentKit
import MultipartKit

// MARK: - 클라이언트 요청 처리

func routes(_ app: Application) throws {
    // MARK: GET
    routeGETUserList(app: app)
    routeGETImage(app: app)
    
    
    // TODO: - todo list
    // user/info (유저 정보)
    
    
    // MARK: POST
    routePOSTUserRegister(app: app)
    routePOSTUserImage(app: app)
    
    
    // MARK: Socket
    routeSocketEcho(app: app)
    
    
    // MARK: Test
    app.get { req async in
        "It works!"
    }

    app.get("hello") { req async -> String in
        "Hello, world!"
    }
}

// MARK: - GET 정의

/// `/user/list` 유저 리스트 얻기
private func routeGETUserList(app: Application) {
    app.get("user", "list") { request in
        try await User.query(on: request.db).with(\.$group).all()
    }
}

/// `/image/{image name}` 이미지 얻기
private func routeGETImage(app: Application) {
    app.get("image", ":imageName") { request in
        let imageName = request.parameters.get("imageName")
        let defaultImageName = ""
        let filePath = Secrets.imagePath + "\(imageName ?? defaultImageName)"
        
        print("\(filePath)")
        
        return request.fileio.streamFile(at: filePath)
    }
}

// MARK: - POST 정의

/// `/user/register` 유저 등록
private func routePOSTUserRegister(app: Application) {
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
}

/// `/user/image` 유저 이미지 등록
private func routePOSTUserImage(app: Application) {
    let oneMilionMegaBytes = ByteCount(value: 1024 * 100)
    app.on(.POST, "user", "image", body: .collect(maxSize: oneMilionMegaBytes)) { request in
        struct ImageEntity: Content {
            let name: String
            let file: File
        }
        
        let imageEntity = try request.content.decode(ImageEntity.self)
        try await request.fileio.writeFile(imageEntity.file.data, at: Secrets.imagePath + imageEntity.name)
        
        // FIXME: - 임시 return
        return try await User.query(on: request.db).with(\.$group).all()
    }
}

/// `/add/user` 유저 등록
@available(*, deprecated, renamed: "routePOSTUserRegister", message: "`routePOSTUserRegister`를 사용하세요.")
private func routePOSTAddUser(app: Application) {
    app.post("add", "user") { req async throws -> User in
        let user = try req.content.decode(User.self)
        
        // id값을 직접 만들어주던 방식
        let maxId = try await User.query(on: req.db).max(\.$id) ?? Int.random(in: 10000...1000000)
        user.id = maxId + 1
        try await user.create(on: req.db)
        
        return user
    }
}

// MARK: - Socket 정의

/// `/echo` echo 소켓
private func routeSocketEcho(app: Application) {
    app.webSocket("echo") { request, webSocket in
        // MARK: 연결 완료
        print(request)
        print(webSocket)
        
        // MARK: Text 수신 시
        webSocket.onText { ws, text in
            print("received from client - \(text)")
            ws.send("잘 받았어요 from server")
            
            Task {
                try await APNSManager.shared.sendSimpleAlert(title: "코든/앱을 통한 전송", subTitle:"보내지나요?")
            }
        }
        
        // MARK: Ping 수신 시
        webSocket.onPing { ws, buffer in
            print("received from client ping")
            ws.sendPing()
        }
    }
}
