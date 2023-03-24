import Vapor

public final class VaporService {
    public enum Error: Swift.Error {
        case failedToReadIP
    }

    public static var shared: VaporService!

    // https://stackoverflow.com/questions/25626117/how-to-get-ip-address-in-swift
    private static func getIFAddresses() -> [String] {
        var addresses = [String]()

        // Get list of all interfaces on the local machine:
        var ifaddr : UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0 else { return [] }
        guard let firstAddr = ifaddr else { return [] }

        // For each interface ...
        for ptr in sequence(first: firstAddr, next: { $0.pointee.ifa_next }) {
            let flags = Int32(ptr.pointee.ifa_flags)
            let addr = ptr.pointee.ifa_addr.pointee

            // Check for running IPv4, IPv6 interfaces. Skip the loopback interface.
            if (flags & (IFF_UP|IFF_RUNNING|IFF_LOOPBACK)) == (IFF_UP|IFF_RUNNING) {
                if addr.sa_family == UInt8(AF_INET) || addr.sa_family == UInt8(AF_INET6) {

                    // Convert interface address to a human readable string:
                    var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                    if (getnameinfo(ptr.pointee.ifa_addr, socklen_t(addr.sa_len), &hostname, socklen_t(hostname.count),
                                    nil, socklen_t(0), NI_NUMERICHOST) == 0) {
                        let address = String(cString: hostname)
                        addresses.append(address)
                    }
                }
            }
        }

        freeifaddrs(ifaddr)
        return addresses
    }

    private static func pickFirstIPv4(from addresses: [String]) -> String? {
        addresses.first { $0.components(separatedBy: ".").count == 4 }
    }

    private static func initializeServer(configure: (Application) throws -> Void) throws {
        var env = try Environment.detect()
        try LoggingSystem.bootstrap(from: &env)
        let app = Application(env)
        defer { app.shutdown() }
        try configure(app)
        try app.run()
    }

    public let ipAddress: String
    public let port: UInt16

    public init(ip: String? = nil, port: UInt16 = 30222, routes: @escaping (Application) throws -> Void = { _ in }) throws {
        guard let ip = ip ?? VaporService.pickFirstIPv4(from: VaporService.getIFAddresses()) else {
            throw Error.failedToReadIP
        }
        self.ipAddress = ip
        self.port = port

        Task {
            try! VaporService.initializeServer { app in
                app.http.server.configuration.hostname = ipAddress
                app.http.server.configuration.port = Int(port)
                try routes(app)
            }
        }
    }

}
