import Vapor
import SlideUI
import SwiftUI
import Combine
import Ink

// https://theswiftdev.com/websockets-for-beginners-using-vapor-4-and-vanilla-javascript/
class WebSocketClient {
    var id: UUID
    var socket: WebSocket

    init(id: UUID, socket: WebSocket) {
        self.id = id
        self.socket = socket
    }
}

class WebsocketClients {
    var eventLoop: EventLoop
    var storage: [UUID: WebSocketClient]

    var active: [WebSocketClient] {
        self.storage.values.filter { !$0.socket.isClosed }
    }

    init(eventLoop: EventLoop, clients: [UUID: WebSocketClient] = [:]) {
        self.eventLoop = eventLoop
        self.storage = clients
    }

    func add(_ client: WebSocketClient) {
        self.storage[client.id] = client
    }

    func remove(_ client: WebSocketClient) {
        self.storage[client.id] = nil
    }

    func find(_ uuid: UUID) -> WebSocketClient? {
        self.storage[uuid]
    }

    deinit {
        let futures = self.storage.values.map { $0.socket.close() }
        try! self.eventLoop.flatten(futures).wait()
    }
}

struct WebsocketMessage<T: Codable>: Codable {
    let client: UUID
    let data: T
}

extension ByteBuffer {
    func decodeWebsocketMessage<T: Codable>(_ type: T.Type) -> WebsocketMessage<T>? {
        try? JSONDecoder().decode(WebsocketMessage<T>.self, from: self)
    }
}

struct Connect: Codable {
    let connect: Bool
}

class GameSystem {
    static var shared: GameSystem!

    var cancellables: Set<AnyCancellable> = []

    var clients: WebsocketClients

    init(eventLoop: EventLoop) {
        self.clients = WebsocketClients(eventLoop: eventLoop)
    }

    func connect(_ ws: WebSocket) {
        ws.onBinary { [unowned self] ws, buffer in
            if let msg = buffer.decodeWebsocketMessage(Connect.self) {
                let player = WebSocketClient(id: msg.client, socket: ws)
                self.clients.add(player)
            }
        }
    }
}

public final class RemoteHitnSocketService {
    public static var remote = HTML(value:
"""
<html>
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Sockets</title>
</head>

<body>
    <div style="float: left; margin-right: 16px;">
        <div>
            <a href="javascript:WebSocketStart()">Start</a>
            <a href="javascript:WebSocketStop()">Stop</a>
        </div>
        <div id="content">

        </div>
    </div>

    <script>
function blobToJson(blob) {
    return new Promise((resolve, reject) => {
        let fr = new FileReader();
        fr.onload = () => {
            resolve(JSON.parse(fr.result));
        };
        fr.readAsText(blob);
    });
}

function uuidv4() {
    return ([1e7]+-1e3+-4e3+-8e3+-1e11).replace(/[018]/g, c => (c ^ crypto.getRandomValues(new Uint8Array(1))[0] & 15 >> c / 4).toString(16));
}

WebSocket.prototype.sendJsonBlob = function(data) {
    const string = JSON.stringify({ client: uuid, data: data })
    const blob = new Blob([string], {type: "application/json"});
    this.send(blob)
};

const uuid = uuidv4()
let ws = undefined

function WebSocketStart() {
    ws = new WebSocket("ws://" + window.location.host + "/hint/channel")
    ws.onopen = () => {
        console.log("Socket is opened.");
        ws.sendJsonBlob({ connect: true })
    }

    ws.onmessage = (event) => {
        blobToJson(event.data).then((obj) => {
            document.getElementById("content").innerHTML = obj.payload
            console.log("Message received.");
        })
    };

    ws.onclose = () => {
        console.log("Socket is closed.");
    };
}

function WebSocketStop() {
    if ( ws !== undefined ) {
        ws.close()
    }
}
    </script>
</body>
</html>
""")

    struct HintPayload: Codable {
        var payload: String
    }

    public static func register(to app: Application, for presentation: PresentationProperties) {
        GameSystem.shared = .init(eventLoop: app.eventLoopGroup.next())

        let jsonEncoder = JSONEncoder()
        let parser = MarkdownParser()

        presentation.$hint.sink { newHint in
            guard let newHint else { return }
            let html = parser.html(from: newHint)
            let data = try! jsonEncoder.encode(HintPayload(payload: html))
            GameSystem.shared.clients.storage.values.forEach { socket in
                socket.socket.send(raw: data, opcode: .binary)
            }
        }.store(in: &GameSystem.shared.cancellables)

        app.webSocket("hint", "channel") { req, ws in
            GameSystem.shared?.connect(ws)
        }

        app.get("hint") { req in
            remote
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
        QRAccessoryView.ExposedState.shared.url = "http://\(service.ipAddress):\(service.port)/hint"
    }
}
