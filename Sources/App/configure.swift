import Vapor
import NIOSSL
import FluentMySQLDriver
import APNS
import APNSCore
import APNSURLSession
import Foundation

// configures your application
public func configure(_ app: Application) async throws {
    // uncomment to serve files from /Public folder
     app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))
    app.routes.defaultMaxBodySize = "100mb"
    
    let certs = try NIOSSLCertificate.fromPEMFile(Secrets.certPath)
        .map { NIOSSLCertificateSource.certificate($0) }
    
    let tls = TLSConfiguration.makeServerConfiguration(
        certificateChain: certs,
        privateKey: .file(Secrets.keyPath)
    )
    
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
    
    // register routes
    try routes(app)
    
    // connect database
    var dbTls = TLSConfiguration.makeClientConfiguration()
    dbTls.certificateVerification = .none
    
    app.databases.use(
        .mysql(
            // my server
//            hostname: Secrets.localDBHostName,
//            username: Secrets.localDBUserName,
//            password: Secrets.localDBPassword,
//            database: Secrets.localDBName,
            
            // remote server
            hostname: Secrets.remoteDBHostName,
            username: Secrets.remoteDBUserName,
            password: Secrets.remoteDBPassword,
            database: Secrets.remoteDBName,
            tlsConfiguration: dbTls
        ),
        as: .mysql
    )
}
