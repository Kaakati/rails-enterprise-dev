---
title: "Push Notifications Feature Example"
description: "Complete push notifications implementation with remote notifications, rich media, actions, and testing"
platform: "iOS/tvOS"
difficulty: "Intermediate"
estimated_time: "2-3 hours"
---

# Push Notifications Feature Example

This example demonstrates building a complete push notifications system for iOS/tvOS applications, including:

- **Remote Notification Setup** - APNs registration and token management
- **Notification Payload Handling** - Process and display notifications
- **Rich Notifications** - Images, videos, and custom UI
- **Notification Actions** - Interactive notification responses
- **Testing Strategies** - Simulator and device testing

---

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [APNs Setup](#apns-setup)
3. [Notification Registration](#notification-registration)
4. [Payload Handling](#payload-handling)
5. [Rich Notifications](#rich-notifications)
6. [Notification Actions](#notification-actions)
7. [Testing](#testing)

---

## Architecture Overview

```
┌─────────────────────────────────────────────────┐
│              Application Layer                  │
│  ┌───────────────────────────────────────────┐  │
│  │  AppDelegate / App                        │  │
│  │  - Register for notifications             │  │
│  │  - Handle device token                    │  │
│  │  - Process notification responses         │  │
│  └──────────────────┬────────────────────────┘  │
└────────────────────┼────────────────────────────┘
                     │
┌────────────────────┼────────────────────────────┐
│              Core Layer (Services)              │
│  ┌──────────────────┴──────────────────────┐   │
│  │  NotificationService                    │   │
│  │  - Token registration                   │   │
│  │  - Permission management                │   │
│  │  - Payload parsing                      │   │
│  └──────────┬──────────────────────────────┘   │
│             │                                   │
│  ┌──────────┴──────────────────────────────┐   │
│  │  NotificationCenterDelegate             │   │
│  │  - willPresent notification             │   │
│  │  - didReceive response                  │   │
│  └─────────────────────────────────────────┘   │
└─────────────────────────────────────────────────┘
                     │
┌────────────────────┼────────────────────────────┐
│           Notification Extensions               │
│  ┌──────────────────┴──────────────────────┐   │
│  │  NotificationService Extension          │   │
│  │  - Download rich media                  │   │
│  │  - Modify notification content          │   │
│  └─────────────────────────────────────────┘   │
│  ┌─────────────────────────────────────────┐   │
│  │  NotificationContent Extension          │   │
│  │  - Custom notification UI               │   │
│  └─────────────────────────────────────────┘   │
└─────────────────────────────────────────────────┘
```

---

## APNs Setup

### Enable Push Notifications Capability

```bash
#!/bin/bash
cat <<EOF
═══════════════════════════════════════════════════
        APNs Setup Instructions
═══════════════════════════════════════════════════

1. Xcode Project Configuration:
   - Select project in navigator
   - Select target
   - Signing & Capabilities tab
   - Click "+ Capability"
   - Add "Push Notifications"

2. Apple Developer Portal:
   - Certificates, Identifiers & Profiles
   - Select App ID
   - Enable "Push Notifications"
   - Create APNs certificates (Development & Production)

3. Download and Install Certificates:
   - Download .cer files
   - Double-click to add to Keychain
   - Export as .p12 for server use

4. Info.plist Configuration:
   - No special keys required for basic push
   - Optional: UIBackgroundModes → remote-notification (for silent push)

EOF
```

---

## Notification Registration

### NotificationService

```swift
// Core/Services/NotificationService.swift
import Foundation
import UserNotifications

@MainActor
final class NotificationService: NSObject, ObservableObject {
    static let shared = NotificationService()

    @Published private(set) var deviceToken: String?
    @Published private(set) var authorizationStatus: UNAuthorizationStatus = .notDetermined
    @Published private(set) var lastNotification: UNNotification?

    private let center = UNUserNotificationCenter.current()

    override init() {
        super.init()
        center.delegate = self
    }

    // MARK: - Public Methods

    /// Request notification permissions
    func requestAuthorization() async throws {
        let options: UNAuthorizationOptions = [.alert, .sound, .badge]

        let granted = try await center.requestAuthorization(options: options)

        if granted {
            print("✅ Notification permission granted")
            await updateAuthorizationStatus()
            await registerForRemoteNotifications()
        } else {
            print("❌ Notification permission denied")
        }
    }

    /// Register for remote notifications (get device token)
    func registerForRemoteNotifications() async {
        await UIApplication.shared.registerForRemoteNotifications()
    }

    /// Update authorization status
    func updateAuthorizationStatus() async {
        let settings = await center.notificationSettings()
        authorizationStatus = settings.authorizationStatus
    }

    /// Handle device token registration
    func didRegisterForRemoteNotifications(withDeviceToken deviceToken: Data) {
        let tokenString = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        self.deviceToken = tokenString

        print("📱 Device token: \(tokenString)")

        // Send token to your server
        Task {
            await sendTokenToServer(tokenString)
        }
    }

    /// Handle registration failure
    func didFailToRegisterForRemoteNotifications(withError error: Error) {
        print("❌ Failed to register for remote notifications: \(error)")
    }

    /// Send device token to backend server
    private func sendTokenToServer(_ token: String) async {
        // Example: POST /api/devices
        let endpoint = "/api/devices"
        let body = ["device_token": token, "platform": "ios"]

        // Make API request to register token
        // let response = try await networkService.request(endpoint: endpoint, method: .post, body: body)
        print("📤 Sent device token to server")
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension NotificationService: UNUserNotificationCenterDelegate {
    /// Called when notification arrives while app is in foreground
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        print("📬 Received notification in foreground: \(notification.request.content.title)")

        lastNotification = notification

        // Show notification banner, sound, and badge even in foreground
        completionHandler([.banner, .sound, .badge])
    }

    /// Called when user interacts with notification
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        print("👆 User tapped notification")

        let notification = response.notification
        let userInfo = notification.request.content.userInfo

        // Handle different action identifiers
        switch response.actionIdentifier {
        case UNNotificationDefaultActionIdentifier:
            // User tapped notification body
            handleNotificationTap(userInfo: userInfo)

        case "ACCEPT_ACTION":
            handleAcceptAction(userInfo: userInfo)

        case "DECLINE_ACTION":
            handleDeclineAction(userInfo: userInfo)

        default:
            break
        }

        completionHandler()
    }

    // MARK: - Action Handlers

    private func handleNotificationTap(userInfo: [AnyHashable: Any]) {
        print("Handling notification tap: \(userInfo)")

        // Example: Navigate to specific screen
        if let screen = userInfo["screen"] as? String {
            navigateToScreen(screen)
        }
    }

    private func handleAcceptAction(userInfo: [AnyHashable: Any]) {
        print("User accepted: \(userInfo)")
        // Handle accept action
    }

    private func handleDeclineAction(userInfo: [AnyHashable: Any]) {
        print("User declined: \(userInfo)")
        // Handle decline action
    }

    private func navigateToScreen(_ screen: String) {
        // Use NotificationCenter or deep linking to navigate
        NotificationCenter.default.post(
            name: .navigateToScreen,
            object: nil,
            userInfo: ["screen": screen]
        )
    }
}

extension Notification.Name {
    static let navigateToScreen = Notification.Name("navigateToScreen")
}
```

### AppDelegate Integration

```swift
// AppDelegate.swift
import UIKit
import UserNotifications

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        // Request notification permissions
        Task { @MainActor in
            try? await NotificationService.shared.requestAuthorization()
        }

        return true
    }

    // MARK: - Remote Notification Registration

    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        Task { @MainActor in
            NotificationService.shared.didRegisterForRemoteNotifications(
                withDeviceToken: deviceToken
            )
        }
    }

    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        Task { @MainActor in
            NotificationService.shared.didFailToRegisterForRemoteNotifications(
                withError: error
            )
        }
    }
}
```

---

## Payload Handling

### Notification Payloads

```json
// Basic Notification
{
  "aps": {
    "alert": {
      "title": "New Message",
      "body": "You have a new message from John"
    },
    "badge": 1,
    "sound": "default"
  },
  "custom_data": {
    "message_id": "123",
    "sender_id": "456",
    "screen": "messages"
  }
}

// Silent Notification (Background)
{
  "aps": {
    "content-available": 1
  },
  "sync_data": {
    "type": "new_content",
    "entity_id": "789"
  }
}

// Rich Notification with Image
{
  "aps": {
    "alert": {
      "title": "Photo Shared",
      "body": "Sarah shared a photo with you"
    },
    "mutable-content": 1
  },
  "media_url": "https://example.com/photo.jpg",
  "screen": "photo_detail"
}
```

### Parse Custom Payload

```swift
// Core/Models/NotificationPayload.swift
import Foundation

struct NotificationPayload: Codable {
    let messageId: String?
    let senderId: String?
    let screen: String?
    let mediaUrl: String?

    enum CodingKeys: String, CodingKey {
        case messageId = "message_id"
        case senderId = "sender_id"
        case screen
        case mediaUrl = "media_url"
    }

    static func parse(from userInfo: [AnyHashable: Any]) -> NotificationPayload? {
        guard let data = try? JSONSerialization.data(withJSONObject: userInfo),
              let payload = try? JSONDecoder().decode(NotificationPayload.self, from: data) else {
            return nil
        }
        return payload
    }
}
```

---

## Rich Notifications

### Notification Service Extension

```bash
# Create Notification Service Extension
# File → New → Target → Notification Service Extension
# Name: NotificationServiceExtension
```

```swift
// NotificationServiceExtension/NotificationService.swift
import UserNotifications

class NotificationService: UNNotificationServiceExtension {
    var contentHandler: ((UNNotificationContent) -> Void)?
    var bestAttemptContent: UNMutableNotificationContent?

    override func didReceive(
        _ request: UNNotificationRequest,
        withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void
    ) {
        self.contentHandler = contentHandler
        bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)

        if let bestAttemptContent = bestAttemptContent {
            // Download and attach media
            if let mediaUrlString = request.content.userInfo["media_url"] as? String,
               let mediaUrl = URL(string: mediaUrlString) {
                downloadAndAttachMedia(url: mediaUrl, to: bestAttemptContent) {
                    contentHandler(bestAttemptContent)
                }
            } else {
                contentHandler(bestAttemptContent)
            }
        }
    }

    override func serviceExtensionTimeWillExpire() {
        // Called just before extension terminates
        if let contentHandler = contentHandler,
           let bestAttemptContent = bestAttemptContent {
            contentHandler(bestAttemptContent)
        }
    }

    private func downloadAndAttachMedia(
        url: URL,
        to content: UNMutableNotificationContent,
        completion: @escaping () -> Void
    ) {
        let task = URLSession.shared.downloadTask(with: url) { localURL, response, error in
            guard let localURL = localURL else {
                completion()
                return
            }

            // Determine file type
            let fileExtension = url.pathExtension
            let tempDirectory = FileManager.default.temporaryDirectory
            let tempFile = tempDirectory.appendingPathComponent(UUID().uuidString)
                .appendingPathExtension(fileExtension)

            do {
                // Move downloaded file to temp location
                try FileManager.default.moveItem(at: localURL, to: tempFile)

                // Create attachment
                let attachment = try UNNotificationAttachment(
                    identifier: "media",
                    url: tempFile,
                    options: nil
                )

                content.attachments = [attachment]
            } catch {
                print("Failed to attach media: \(error)")
            }

            completion()
        }

        task.resume()
    }
}
```

---

## Notification Actions

### Define Notification Categories

```swift
// Core/Services/NotificationService+Categories.swift
extension NotificationService {
    /// Register notification categories and actions
    func registerNotificationCategories() {
        // Define actions
        let acceptAction = UNNotificationAction(
            identifier: "ACCEPT_ACTION",
            title: "Accept",
            options: [.foreground]
        )

        let declineAction = UNNotificationAction(
            identifier: "DECLINE_ACTION",
            title: "Decline",
            options: [.destructive]
        )

        let replyAction = UNTextInputNotificationAction(
            identifier: "REPLY_ACTION",
            title: "Reply",
            options: [],
            textInputButtonTitle: "Send",
            textInputPlaceholder: "Type your message"
        )

        // Define category
        let messageCategory = UNNotificationCategory(
            identifier: "MESSAGE_CATEGORY",
            actions: [acceptAction, declineAction, replyAction],
            intentIdentifiers: [],
            options: []
        )

        // Register categories
        center.setNotificationCategories([messageCategory])

        print("✅ Notification categories registered")
    }
}

// Call in app initialization
// NotificationService.shared.registerNotificationCategories()
```

### Server Payload with Category

```json
{
  "aps": {
    "alert": {
      "title": "Friend Request",
      "body": "John wants to be your friend"
    },
    "category": "MESSAGE_CATEGORY"
  },
  "request_id": "123"
}
```

---

## Testing

### Simulator Testing

```bash
#!/bin/bash
cat <<EOF
═══════════════════════════════════════════════════
    Push Notification Testing (Simulator)
═══════════════════════════════════════════════════

1. Create .apns file:

{
  "Simulator Target Bundle": "com.yourcompany.yourapp",
  "aps": {
    "alert": {
      "title": "Test Notification",
      "body": "This is a test notification"
    },
    "badge": 1,
    "sound": "default"
  }
}

2. Send via xcrun:

xcrun simctl push booted com.yourcompany.yourapp test_notification.apns

3. Send via drag & drop:
   - Drag .apns file onto Simulator
   - Notification appears immediately

EOF
```

### Device Testing (APNs)

```bash
#!/bin/bash
cat <<EOF
═══════════════════════════════════════════════════
    Push Notification Testing (Device)
═══════════════════════════════════════════════════

Tools:
1. Pusher (macOS app) - https://github.com/noodlewerk/NWPusher
2. Knuff (macOS app) - https://github.com/KnuffApp/Knuff
3. Terminal (curl):

curl -v \\
  --header "apns-topic: com.yourcompany.yourapp" \\
  --header "apns-push-type: alert" \\
  --cert YourAPNsCertificate.pem \\
  --data '{"aps":{"alert":"Test"}}' \\
  --http2 \\
  https://api.sandbox.push.apple.com/3/device/DEVICE_TOKEN

4. Server Implementation:
   - Use node-apn (Node.js)
   - Use PyAPNs (Python)
   - Use houston (Ruby)

EOF
```

### Unit Tests

```swift
// Tests/NotificationServiceTests.swift
import XCTest
@testable import MyApp

final class NotificationServiceTests: XCTestCase {
    @MainActor
    func testDeviceTokenParsing() {
        let tokenData = Data([0x12, 0x34, 0x56, 0x78])
        let service = NotificationService.shared

        service.didRegisterForRemoteNotifications(withDeviceToken: tokenData)

        XCTAssertEqual(service.deviceToken, "12345678")
    }

    func testPayloadParsing() {
        let userInfo: [AnyHashable: Any] = [
            "message_id": "123",
            "sender_id": "456",
            "screen": "messages"
        ]

        let payload = NotificationPayload.parse(from: userInfo)

        XCTAssertNotNil(payload)
        XCTAssertEqual(payload?.messageId, "123")
        XCTAssertEqual(payload?.senderId, "456")
        XCTAssertEqual(payload?.screen, "messages")
    }
}
```

---

## Summary

This example demonstrates:

✅ **APNs Registration** - Device token management and server integration
✅ **Permission Handling** - Request and track authorization status
✅ **Payload Processing** - Parse and handle custom notification data
✅ **Rich Notifications** - Images and media attachments
✅ **Interactive Actions** - Notification categories with custom actions
✅ **Foreground Handling** - Display notifications while app is active
✅ **Testing Strategy** - Simulator and device testing approaches

**Key Takeaways:**
- Always request permissions before registering for remote notifications
- Handle both foreground and background notification scenarios
- Use Notification Service Extension for rich media
- Define notification categories for interactive actions
- Test on both simulator and device
- Secure device tokens when sending to server
- Provide fallback for notification permission denied
