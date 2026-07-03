import Foundation

/// Ported from Android `data/remote/WebSocketManager.kt`.
/// Uses `URLSessionWebSocketTask` instead of OkHttp. The WS URL is AES-decrypted from
/// `SecretConstants` (same as Android). On connect it sends the `subscribeEmails` action;
/// incoming `newEmailReceived` messages are parsed into `Email` and delivered on
/// `emailStream`.
///
/// Per IMPLEMENTATION_PLAN.md §7, this runs only while the app is foreground/active — iOS
/// does not permit long-lived background sockets, and there is no backend push.
final class WebSocketManager {
    private let session: URLSession
    private var task: URLSessionWebSocketTask?

    let emailStream: AsyncStream<Email>
    private let continuation: AsyncStream<Email>.Continuation

    init(session: URLSession = URLSession(configuration: .default)) {
        self.session = session
        var cont: AsyncStream<Email>.Continuation!
        self.emailStream = AsyncStream(bufferingPolicy: .bufferingNewest(1)) { cont = $0 }
        self.continuation = cont
    }

    func connect(email: String) {
        // Drop any existing socket first (Android's service reconnects when the email changes).
        disconnect()

        guard let urlString = try? Decryptor.decryptBase64(
            encryptedBase64: SecretConstants.WURL,
            keyBase64: SecretConstants.BKEY,
            ivBase64: SecretConstants.BIV
        ), let url = URL(string: urlString) else { return }

        let task = session.webSocketTask(with: url)
        self.task = task
        task.resume()
        subscribe(email: email)
        listen()
    }

    func disconnect() {
        task?.cancel(with: .goingAway, reason: nil)
        task = nil
    }

    // MARK: - Private

    private func subscribe(email: String) {
        let payload: [String: Any] = ["action": "subscribeEmails", "email": email]
        guard let data = try? JSONSerialization.data(withJSONObject: payload),
              let text = String(data: data, encoding: .utf8) else { return }
        task?.send(.string(text)) { _ in }
    }

    private func listen() {
        task?.receive { [weak self] result in
            guard let self else { return }
            switch result {
            case .success(let message):
                if case .string(let text) = message {
                    self.handle(text)
                }
                self.listen() // keep receiving
            case .failure:
                // Socket closed/errored; Android logged and stopped. Foreground reconnect
                // happens when the selected email changes (MainScaffold).
                break
            }
        }
    }

    private func handle(_ text: String) {
        guard let data = text.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              json["action"] as? String == "newEmailReceived",
              let emailObj = json["email"] as? [String: Any] else { return }

        let email = Email(
            id: emailObj["id"] as? String ?? "",
            from: emailObj["senderEmail"] as? String ?? "",
            fromName: emailObj["senderName"] as? String ?? "",
            subject: emailObj["subject"] as? String ?? "",
            receivedAt: 0,
            body: emailObj["body"] as? String ?? "",
            isRead: false
        )
        continuation.yield(email)
    }
}
