import Vapor
import Cocoa
import CoreImage

// https://docs.vapor.codes/basics/content/
public struct HTML: ResponseEncodable, AsyncResponseEncodable {
    public let value: String
    public init(value: String) { self.value = value }

    public func encodeResponse(for request: Request) -> EventLoopFuture<Response> {
        var headers = HTTPHeaders()
        headers.add(name: .contentType, value: "text/html")
        return request.eventLoop.makeSucceededFuture(.init(
            status: .ok, headers: headers, body: .init(string: value)
        ))
    }

    public func encodeResponse(for request: Request) async throws -> Response {
        var headers = HTTPHeaders()
        headers.add(name: .contentType, value: "text/html")
        return .init(status: .ok, headers: headers, body: .init(string: value))
    }
}

func generateQRCode(from string: String) -> NSImage? {
    let data = string.data(using: String.Encoding.ascii)

    if let filter = CIFilter(name: "CIQRCodeGenerator") {
        filter.setValue(data, forKey: "inputMessage")
        let transform = CGAffineTransform(scaleX: 3, y: 3)

        if let output = filter.outputImage?.transformed(by: transform) {
            let ciImage = output
            let rep = NSCIImageRep(ciImage: ciImage)
            let nsImage = NSImage(size: rep.size)
            nsImage.addRepresentation(rep)
            return nsImage
        }
    }

    return nil
}
