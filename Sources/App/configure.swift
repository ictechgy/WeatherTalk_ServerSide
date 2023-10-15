import Vapor
import NIOSSL
import FluentMySQLDriver
import Foundation

// MARK: - 서버 기본 설정

public func configure(_ app: Application) async throws {
    setUpMiddleware(of: app)
    try configureServerHTTP(of: app)
    configureDatabase(of: app, useLocal: false)
    
    // MARK: routes 등록
    try routes(app)
}


// MARK: - 설정 함수들

// MARK: /Public 폴더에서 파일을 제공하기 위한 설정
private func setUpMiddleware(of app: Application) {
    app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))
    app.routes.defaultMaxBodySize = "100mb"
}

// MARK: 서버 인증서 및 HTTP 설정
private func configureServerHTTP(of app: Application) throws {
    let tls = try generateServerTLSConfiguration()
    
    app.http.server.configuration = .init(
        hostname: Secrets.httpHostName,
        port: Secrets.httpPortNumber,
        backlog: 256,
        reuseAddress: true,
        tcpNoDelay: true,
        responseCompression: .disabled,
        requestDecompression: .disabled,
        supportPipelining: false,
        supportVersions: Set<HTTPVersionMajor>([.two]),
        tlsConfiguration: tls,
        serverName: nil,
        logger: nil
    )
}

private func generateServerTLSConfiguration() throws -> TLSConfiguration {
    let certs = try NIOSSLCertificate.fromPEMFile(Secrets.certPath)
        .map { NIOSSLCertificateSource.certificate($0) }
    
    return TLSConfiguration.makeServerConfiguration(
        certificateChain: certs,
        privateKey: .file(Secrets.keyPath)
    )
}

// MARK: Database 연결
private func configureDatabase(of app: Application, useLocal: Bool) {
    let accessInfo = generateDatabaseAccessInfo(useLocal: useLocal)
    var dbTls = TLSConfiguration.makeClientConfiguration()
    dbTls.certificateVerification = .none
    
    app.databases.use(
        .mysql(
            hostname: accessInfo.hostname,
            username: accessInfo.username,
            password: accessInfo.password,
            database: accessInfo.database,
            tlsConfiguration: dbTls
        ),
        as: .mysql
    )
}

private func generateDatabaseAccessInfo(useLocal: Bool) -> DatabaseAccessInfo {
    .init(
        hostname: useLocal ? Secrets.localDBHostName : Secrets.remoteDBHostName,
        username: useLocal ? Secrets.localDBUserName : Secrets.remoteDBUserName,
        password: useLocal ? Secrets.localDBPassword : Secrets.remoteDBPassword,
        database: useLocal ? Secrets.localDBName : Secrets.remoteDBName
    )
}

private struct DatabaseAccessInfo {
    let hostname: String
    let username: String
    let password: String
    let database: String
}
