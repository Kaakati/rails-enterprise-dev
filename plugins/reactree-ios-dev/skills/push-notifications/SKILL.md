---
name: "Push Notifications"
description: "Remote and local push notification implementation for iOS/tvOS using UNUserNotificationCenter and APNs"
version: "2.0.0"
---

# Push Notifications for iOS/tvOS

Complete guide to implementing push notifications in iOS/tvOS applications using UNUserNotificationCenter, handling remote notifications, and integrating with Apple Push Notification service (APNs).

## Setup and Permissions

### Request Authorization

```swift
import UserNotifications

final class NotificationManager: NSObject, ObservableObject {
    static let shared = NotificationManager()

    func requestAuthorization() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(
                options: [.alert, .sound, .badge]
            )
            return granted
        } catch {
            print("Error requesting notification authorization: \(error)")
            return false
        }
    }

    func checkAuthorizationStatus() async -> UNAuthorizationStatus {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        return settings.authorizationStatus
    }
}

// SwiftUI usage
struct ContentView: View {
    @StateObject private var notificationManager = NotificationManager.shared

    var body: some View {
        VStack {
            Button("Enable Notifications") {
                Task {
                    let granted = await notificationManager.requestAuthorization()
                    print("Authorized: \(granted)")
                }
            }
        }
    }
}
```

### Register for Remote Notifications

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
        UNUserNotificationCenter.current().delegate = self

        Task {
            let granted = await NotificationManager.shared.requestAuthorization()
            if granted {
                await MainActor.run {
                    application.registerForRemoteNotifications()
                }
            }
        }

        return true
    }

    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        let token = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        print("Device Token: \(token)")

        // Send token to backend
        Task {
            await sendTokenToServer(token)
        }
    }

    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        print("Failed to register for remote notifications: \(error)")
    }

    private func sendTokenToServer(_ token: String) async {
        // Send device token to your backend
    }
}
```

## Notification Payload Handling

### Remote Notification Payload

```json
{
  "aps": {
    "alert": {
      "title": "New Message",
      "subtitle": "From John Doe",
      "body": "Hey, how are you doing?"
    },
    "badge": 1,
    "sound": "default",
    "category": "MESSAGE_CATEGORY",
    "thread-id": "conversation-123"
  },
  "customData": {
    "userId": "123",
    "conversationId": "456",
    "messageId": "789"
  }
}
```

### Handle Notification Reception

```swift
extension AppDelegate: UNUserNotificationCenterDelegate {
    // Notification received while app is in foreground
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        print("Received notification: \(notification.request.content.userInfo)")

        // Show banner, play sound, and update badge
        return [.banner, .sound, .badge]
    }

    // User tapped notification
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        let userInfo = response.notification.request.content.userInfo

        // Extract custom data
        if let customData = userInfo["customData"] as? [String: Any],
           let conversationId = customData["conversationId"] as? String {
            // Navigate to conversation
            await openConversation(id: conversationId)
        }
    }

    private func openConversation(id: String) async {
        // Deep link to conversation
    }
}
```

## Local Notifications

### Schedule Local Notification

```swift
final class LocalNotificationService {
    func scheduleNotification(
        title: String,
        body: String,
        date: Date,
        identifier: String
    ) async throws {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.badge = 1

        // Calendar trigger
        let dateComponents = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: date
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)

        // Create request
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )

        try await UNUserNotificationCenter.current().add(request)
    }

    func scheduleRepeatingNotification(
        title: String,
        body: String,
        hour: Int,
        minute: Int,
        identifier: String
    ) async throws {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: dateComponents,
            repeats: true
        )

        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )

        try await UNUserNotificationCenter.current().add(request)
    }

    func cancelNotification(identifier: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: [identifier]
        )
    }

    func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
}
```

## Notification Actions

### Define Categories and Actions

```swift
final class NotificationActionManager {
    static let messageCategory = "MESSAGE_CATEGORY"
    static let reminderCategory = "REMINDER_CATEGORY"

    func registerCategories() {
        // Message actions
        let replyAction = UNTextInputNotificationAction(
            identifier: "REPLY_ACTION",
            title: "Reply",
            options: [],
            textInputButtonTitle: "Send",
            textInputPlaceholder: "Type your message..."
        )

        let markReadAction = UNNotificationAction(
            identifier: "MARK_READ_ACTION",
            title: "Mark as Read",
            options: []
        )

        let messageCategory = UNNotificationCategory(
            identifier: Self.messageCategory,
            actions: [replyAction, markReadAction],
            intentIdentifiers: [],
            options: []
        )

        // Reminder actions
        let snoozeAction = UNNotificationAction(
            identifier: "SNOOZE_ACTION",
            title: "Snooze",
            options: []
        )

        let completeAction = UNNotificationAction(
            identifier: "COMPLETE_ACTION",
            title: "Complete",
            options: [.destructive]
        )

        let reminderCategory = UNNotificationCategory(
            identifier: Self.reminderCategory,
            actions: [snoozeAction, completeAction],
            intentIdentifiers: [],
            options: []
        )

        UNUserNotificationCenter.current().setNotificationCategories([
            messageCategory,
            reminderCategory
        ])
    }
}

// Handle actions
extension AppDelegate: UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        switch response.actionIdentifier {
        case "REPLY_ACTION":
            if let textResponse = response as? UNTextInputNotificationResponse {
                await handleReply(text: textResponse.userText)
            }

        case "MARK_READ_ACTION":
            await markAsRead()

        case "SNOOZE_ACTION":
            await snoozeReminder()

        case "COMPLETE_ACTION":
            await completeReminder()

        default:
            // Default tap (no action selected)
            break
        }
    }
}
```

## Silent Notifications

### Background Updates

```swift
// Enable background modes in Xcode: Remote notifications

// AppDelegate
func application(
    _ application: UIApplication,
    didReceiveRemoteNotification userInfo: [AnyHashable: Any]
) async -> UIBackgroundFetchResult {
    print("Received silent notification: \(userInfo)")

    // Perform background update
    do {
        await updateData()
        return .newData
    } catch {
        return .failed
    }
}

// Silent notification payload
{
  "aps": {
    "content-available": 1
  },
  "customData": {
    "type": "dataUpdate",
    "timestamp": 1234567890
  }
}
```

## Rich Notifications

### Notification Service Extension

```swift
// 1. Create Notification Service Extension target in Xcode
// 2. Implement NotificationService class

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

        guard let bestAttemptContent = bestAttemptContent else {
            contentHandler(request.content)
            return
        }

        // Download image attachment
        if let attachmentURLString = bestAttemptContent.userInfo["image_url"] as? String,
           let attachmentURL = URL(string: attachmentURLString) {
            Task {
                await downloadAndAttachImage(url: attachmentURL, content: bestAttemptContent)
                contentHandler(bestAttemptContent)
            }
        } else {
            contentHandler(bestAttemptContent)
        }
    }

    private func downloadAndAttachImage(url: URL, content: UNMutableNotificationContent) async {
        do {
            let (localURL, _) = try await URLSession.shared.download(from: url)

            let attachment = try UNNotificationAttachment(
                identifier: "image",
                url: localURL,
                options: nil
            )
            content.attachments = [attachment]
        } catch {
            print("Error downloading image: \(error)")
        }
    }
}

// Rich notification payload
{
  "aps": {
    "alert": {
      "title": "New Photo",
      "body": "Check out this amazing sunset!"
    },
    "mutable-content": 1
  },
  "image_url": "https://example.com/sunset.jpg"
}
```

## Badge Management

### Update App Badge

```swift
final class BadgeManager {
    static func setBadge(_ count: Int) async {
        do {
            try await UNUserNotificationCenter.current().setBadgeCount(count)
        } catch {
            print("Error setting badge: \(error)")
        }
    }

    static func incrementBadge() async {
        let current = await UNUserNotificationCenter.current().deliveredNotifications().count
        await setBadge(current + 1)
    }

    static func clearBadge() async {
        await setBadge(0)
    }
}

// SwiftUI usage
struct ContentView: View {
    var body: some View {
        VStack {
            Button("Clear Badge") {
                Task {
                    await BadgeManager.clearBadge()
                }
            }
        }
    }
}
```

## Testing Push Notifications

### Simulator Testing (iOS 16+)

```bash
# Create payload.json
{
  "Simulator Target Bundle": "com.yourcompany.yourapp",
  "aps": {
    "alert": {
      "title": "Test Notification",
      "body": "This is a test notification"
    },
    "badge": 1
  }
}

# Send notification
xcrun simctl push booted com.yourcompany.yourapp payload.json
```

### Testing on Device

1. Export .p12 certificate from Keychain
2. Use testing tool (e.g., Pusher, APNS Tool)
3. Send test notification with device token

## Best Practices

### 1. Request Permission at Right Time

```swift
// ✅ Good: Request after user action
Button("Enable Notifications") {
    Task {
        await NotificationManager.shared.requestAuthorization()
    }
}

// ❌ Avoid: Request immediately on launch
// Confusing and likely to be denied
```

### 2. Handle All Notification States

```swift
func checkNotificationStatus() async {
    let status = await NotificationManager.shared.checkAuthorizationStatus()

    switch status {
    case .authorized:
        print("Authorized")
    case .denied:
        print("Show settings prompt")
    case .notDetermined:
        print("Not requested yet")
    case .provisional:
        print("Provisional authorization")
    case .ephemeral:
        print("Temporary authorization")
    @unknown default:
        break
    }
}
```

### 3. Clear Delivered Notifications

```swift
// Clear specific notification
UNUserNotificationCenter.current().removeDeliveredNotifications(
    withIdentifiers: ["notification-id"]
)

// Clear all
UNUserNotificationCenter.current().removeAllDeliveredNotifications()
```

## References

- [UserNotifications Framework](https://developer.apple.com/documentation/usernotifications)
- [APNs Overview](https://developer.apple.com/documentation/usernotifications/setting_up_a_remote_notification_server)
- [Rich Notifications](https://developer.apple.com/documentation/usernotifications/unnotificationserviceextension)
