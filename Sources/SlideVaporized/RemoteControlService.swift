import Vapor
import SlideUI
import SwiftUI

public final class RemoteControlService {
    public static var remote = HTML(value:
"""
<!DOCTYPE html>
<html>
<head>
<style>
html, body {
    height: 100%;
}
.container {
    min-height: 75%;
    min-width: 100%;
    background-color: green;
}
.containerLower {
    min-height: 25%;
    min-width: 100%;
    background-color: red;
}
</style>
</head>
<body>

<a href="/remote/forward"><div class="container">Forward</div></a>
<a href="/remote/backward"><div  class="containerLower">Backward</div></a>

</body>
</html>
""")

    public static func register(to app: Application, for presentation: PresentationProperties) {
        app.get("remote") { _ async in
            return remote
        }

        app.get("remote", "forward") { _ async in
            DispatchQueue.main.async {
                presentation.handleMoveForwardEvent()
            }
            return remote
        }

        app.get("remote","backward") { _ async in
            DispatchQueue.main.async {
                presentation.handleMoveBackwardEvent()
            }
            return remote
        }
    }

    public struct QRAccessoryView: SwiftUI.View {
        final class ExposedState: ObservableObject {
            static let shared = ExposedState.init()

            var url: String = "" {
                didSet {
                    if oldValue != url {
                        refreshQr()
                    }
                }
            }

            @Published var qr: NSImage?

            private func refreshQr() {
                qr = generateQRCode(from: url)
            }
        }
        @StateObject var model: ExposedState = ExposedState.shared

        public init() {}
        public var body: some SwiftUI.View {
            if let image = model.qr {
                Image(nsImage: image)
            }
        }
    }

    public static func performAfter(loaded service: VaporService) {
        QRAccessoryView.ExposedState.shared.url = "http://\(service.ipAddress):\(service.port)/remote"
    }
}
