---
title: "tvOS Focus Navigation Example"
description: "Complete tvOS focus engine implementation with focus groups, preferred focus, parallax effects, and remote control handling"
platform: "tvOS"
difficulty: "Intermediate"
estimated_time: "2-3 hours"
---

# tvOS Focus Navigation Example

This example demonstrates building a complete tvOS focus navigation system, including:

- **Focus Engine** - SwiftUI @FocusState implementation
- **Focus Groups** - Section-based focus management
- **Preferred Focus** - Set initial and returning focus
- **Parallax Effects** - Visual depth with focus animations
- **Remote Control** - Handle Siri Remote gestures and buttons

---

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Basic Focus Implementation](#basic-focus-implementation)
3. [Focus Groups](#focus-groups)
4. [Preferred Focus](#preferred-focus)
5. [Parallax Effects](#parallax-effects)
6. [Remote Control Handling](#remote-control-handling)
7. [Complete Example](#complete-example)

---

## Architecture Overview

```
┌─────────────────────────────────────────────────┐
│              tvOS Focus System                  │
│                                                 │
│  ┌───────────────────────────────────────────┐  │
│  │  ContentView (@FocusState)                │  │
│  │  - Manages global focus state             │  │
│  │  - Sets preferred initial focus           │  │
│  └──────────────────┬────────────────────────┘  │
│                     │                            │
│  ┌──────────────────┴────────────────────────┐  │
│  │  Focus Sections                           │  │
│  │  ┌─────────────┐  ┌─────────────────────┐ │  │
│  │  │  Navigation │  │  Content Grid       │ │  │
│  │  │  Sidebar    │  │  (Movies/Shows)     │ │  │
│  │  └─────────────┘  └─────────────────────┘ │  │
│  │  ┌──────────────────────────────────────┐ │  │
│  │  │  Detail View                         │ │  │
│  │  │  (Focused content + actions)         │ │  │
│  │  └──────────────────────────────────────┘ │  │
│  └──────────────────────────────────────────┘  │
│                                                 │
│  ┌──────────────────────────────────────────┐  │
│  │  Remote Control Gestures                 │  │
│  │  - Swipe: Move focus                     │  │
│  │  - Click: Select                         │  │
│  │  - Long press: Context menu              │  │
│  │  - Play/Pause: Media control             │  │
│  └──────────────────────────────────────────┘  │
└─────────────────────────────────────────────────┘
```

---

## Basic Focus Implementation

### FocusState with Enum

```swift
// Presentation/Home/HomeView.swift
import SwiftUI

struct HomeView: View {
    enum FocusableField: Hashable {
        case sidebar
        case contentGrid(Int)  // Index of focused item
        case playButton
        case favoriteButton
    }

    @FocusState private var focusedField: FocusableField?

    var body: some View {
        HStack(spacing: 0) {
            // Sidebar
            SidebarView()
                .focused($focusedField, equals: .sidebar)
                .frame(width: 300)

            // Content Grid
            ContentGridView(focusedField: $focusedField)
        }
        .onAppear {
            // Set initial focus to sidebar
            focusedField = .sidebar
        }
    }
}

struct SidebarView: View {
    let categories = ["Home", "Movies", "TV Shows", "Sports", "News"]
    @State private var selectedCategory = "Home"

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Categories")
                .font(.title2)
                .padding(.horizontal)

            ForEach(categories, id: \.self) { category in
                Button(action: {
                    selectedCategory = category
                }) {
                    HStack {
                        Text(category)
                            .font(.headline)
                        Spacer()
                        if selectedCategory == category {
                            Image(systemName: "checkmark")
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.secondary.opacity(0.2))
                    )
                }
                .buttonStyle(.card)
            }

            Spacer()
        }
        .padding()
        .background(Color.black.opacity(0.3))
    }
}

struct ContentGridView: View {
    @Binding var focusedField: HomeView.FocusableField?

    let items = (0..<20).map { "Item \($0)" }
    let columns = [
        GridItem(.adaptive(minimum: 300, maximum: 400), spacing: 40)
    ]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 40) {
                ForEach(items.indices, id: \.self) { index in
                    ContentCard(title: items[index])
                        .focused($focusedField, equals: .contentGrid(index))
                }
            }
            .padding(60)
        }
    }
}

struct ContentCard: View {
    let title: String
    @Environment(\.isFocused) var isFocused

    var body: some View {
        VStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.blue)
                .aspectRatio(16/9, contentMode: .fit)
                .overlay(
                    Text(title)
                        .font(.title)
                        .foregroundColor(.white)
                )
                .scaleEffect(isFocused ? 1.1 : 1.0)
                .animation(.easeInOut(duration: 0.2), value: isFocused)

            Text(title)
                .font(.headline)
                .foregroundColor(isFocused ? .white : .secondary)
        }
        .frame(width: 300, height: 200)
    }
}
```

---

## Focus Groups

### FocusSection for Logical Groups

```swift
// Presentation/Detail/MovieDetailView.swift
import SwiftUI

struct MovieDetailView: View {
    enum DetailFocus: Hashable {
        case playButton
        case trailerButton
        case favoriteButton
        case relatedMovie(Int)
    }

    @FocusState private var focusedField: DetailFocus?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 40) {
                // Hero section
                HeroSection()

                // Action buttons (Focus Group 1)
                FocusSection {
                    HStack(spacing: 30) {
                        ActionButton(title: "Play", icon: "play.fill")
                            .focused($focusedField, equals: .playButton)

                        ActionButton(title: "Trailer", icon: "film")
                            .focused($focusedField, equals: .trailerButton)

                        ActionButton(title: "Favorite", icon: "heart")
                            .focused($focusedField, equals: .favoriteButton)
                    }
                }

                // Related content (Focus Group 2)
                Text("Related Movies")
                    .font(.title2)
                    .padding(.horizontal, 60)

                FocusSection {
                    ScrollView(.horizontal, showsIndicators: false) {
                        LazyHStack(spacing: 30) {
                            ForEach(0..<10, id: \.self) { index in
                                RelatedMovieCard(index: index)
                                    .focused($focusedField, equals: .relatedMovie(index))
                            }
                        }
                        .padding(.horizontal, 60)
                    }
                }
            }
        }
        .onAppear {
            // Set initial focus to Play button
            focusedField = .playButton
        }
    }
}

struct HeroSection: View {
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // Background image
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(height: 600)

            // Title and description
            VStack(alignment: .leading, spacing: 16) {
                Text("The Great Movie")
                    .font(.system(size: 60, weight: .bold))

                Text("An epic adventure across time and space")
                    .font(.title3)
                    .foregroundColor(.secondary)

                HStack(spacing: 20) {
                    Text("2023")
                    Text("•")
                    Text("2h 30m")
                    Text("•")
                    Text("Action, Sci-Fi")
                }
                .font(.headline)
                .foregroundColor(.secondary)
            }
            .padding(60)
        }
    }
}

struct ActionButton: View {
    let title: String
    let icon: String
    @Environment(\.isFocused) var isFocused

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)

            Text(title)
                .font(.headline)
        }
        .padding(.horizontal, 40)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isFocused ? Color.white : Color.white.opacity(0.2))
        )
        .foregroundColor(isFocused ? .black : .white)
        .scaleEffect(isFocused ? 1.05 : 1.0)
        .animation(.easeInOut(duration: 0.15), value: isFocused)
    }
}

struct RelatedMovieCard: View {
    let index: Int
    @Environment(\.isFocused) var isFocused

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.gray)
                .aspectRatio(2/3, contentMode: .fit)
                .frame(width: 250)
                .overlay(
                    Text("Movie \(index + 1)")
                        .font(.title3)
                        .foregroundColor(.white)
                )

            Text("Related Movie \(index + 1)")
                .font(.headline)
                .foregroundColor(isFocused ? .white : .secondary)
        }
        .scaleEffect(isFocused ? 1.1 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isFocused)
    }
}
```

---

## Preferred Focus

### Set Preferred Focus on Appear

```swift
// Presentation/Navigation/RootView.swift
import SwiftUI

struct RootView: View {
    enum Tab: Hashable {
        case home
        case search
        case library
    }

    @State private var selectedTab: Tab = .home
    @FocusState private var focusedTab: Tab?

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house")
                }
                .tag(Tab.home)
                .focused($focusedTab, equals: .home)

            SearchView()
                .tabItem {
                    Label("Search", systemImage: "magnifyingglass")
                }
                .tag(Tab.search)
                .focused($focusedTab, equals: .search)

            LibraryView()
                .tabItem {
                    Label("Library", systemImage: "books.vertical")
                }
                .tag(Tab.library)
                .focused($focusedTab, equals: .library)
        }
        .onAppear {
            // Set preferred initial focus to Home tab
            focusedTab = .home
        }
        .onChange(of: selectedTab) { newTab in
            // Update focus when tab changes
            focusedTab = newTab
        }
    }
}
```

### Restore Focus on Return

```swift
// Presentation/Detail/DetailContainerView.swift
import SwiftUI

struct DetailContainerView: View {
    @State private var showingDetail = false
    @FocusState private var lastFocusedItem: Int?

    let items = (0..<20).map { $0 }

    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 300))], spacing: 40) {
                    ForEach(items, id: \.self) { item in
                        Button(action: {
                            lastFocusedItem = item
                            showingDetail = true
                        }) {
                            ItemCard(item: item)
                        }
                        .focused($lastFocusedItem, equals: item)
                    }
                }
                .padding(60)
            }
            .navigationTitle("Content")
            .sheet(isPresented: $showingDetail) {
                DetailView()
            }
            .onAppear {
                // Restore focus to last focused item, or default to first
                if lastFocusedItem == nil {
                    lastFocusedItem = items.first
                }
            }
        }
    }
}
```

---

## Parallax Effects

### Focus-Driven Parallax Animation

```swift
// DesignSystem/Components/ParallaxCard.swift
import SwiftUI

struct ParallaxCard: View {
    let title: String
    let imageUrl: String?

    @Environment(\.isFocused) var isFocused
    @State private var offset = CGSize.zero

    var body: some View {
        ZStack {
            // Background layer (slower parallax)
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .offset(x: offset.width * 0.3, y: offset.height * 0.3)

            // Middle layer (medium parallax)
            if let imageUrl = imageUrl {
                AsyncImage(url: URL(string: imageUrl)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle().fill(Color.gray.opacity(0.3))
                }
                .offset(x: offset.width * 0.6, y: offset.height * 0.6)
            }

            // Foreground layer (full parallax)
            VStack {
                Spacer()

                Text(title)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.black.opacity(0.6))
                    )
                    .offset(x: offset.width, y: offset.height)
            }
            .padding(20)
        }
        .frame(width: 400, height: 300)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .scaleEffect(isFocused ? 1.1 : 1.0)
        .shadow(
            color: isFocused ? .white.opacity(0.5) : .clear,
            radius: 20
        )
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isFocused)
        .focusEffect { focused in
            // Apply parallax offset when focused
            withAnimation(.easeInOut(duration: 0.3)) {
                offset = focused ? CGSize(width: 10, height: 10) : .zero
            }
        }
    }
}

// Usage
ParallaxCard(
    title: "Epic Movie",
    imageUrl: "https://example.com/poster.jpg"
)
```

---

## Remote Control Handling

### Handle Remote Gestures

```swift
// Presentation/Player/VideoPlayerView.swift
import SwiftUI
import AVKit

struct VideoPlayerView: View {
    @State private var player = AVPlayer(url: URL(string: "https://example.com/video.mp4")!)
    @State private var isPlaying = false
    @FocusState private var isPlayerFocused: Bool

    var body: some View {
        VideoPlayer(player: player)
            .focused($isPlayerFocused)
            .onAppear {
                isPlayerFocused = true
            }
            .onPlayPauseCommand {
                togglePlayPause()
            }
            .onExitCommand {
                player.pause()
            }
    }

    private func togglePlayPause() {
        if isPlaying {
            player.pause()
        } else {
            player.play()
        }
        isPlaying.toggle()
    }
}
```

### Custom Remote Handling

```swift
// Core/Services/RemoteControlService.swift
import SwiftUI
import GameController

final class RemoteControlService: ObservableObject {
    @Published var lastGesture: String = ""

    init() {
        setupRemoteObservers()
    }

    private func setupRemoteObservers() {
        NotificationCenter.default.addObserver(
            forName: .GCControllerDidConnect,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let controller = notification.object as? GCController,
                  let microGamepad = controller.microGamepad else {
                return
            }

            self?.setupMicroGamepad(microGamepad)
        }
    }

    private func setupMicroGamepad(_ microGamepad: GCMicroGamepad) {
        // Button A (Select)
        microGamepad.buttonA.pressedChangedHandler = { [weak self] _, _, pressed in
            if pressed {
                self?.lastGesture = "Select Button Pressed"
                self?.handleSelectButton()
            }
        }

        // Button X (Play/Pause)
        microGamepad.buttonX.pressedChangedHandler = { [weak self] _, _, pressed in
            if pressed {
                self?.lastGesture = "Play/Pause Button Pressed"
                self?.handlePlayPauseButton()
            }
        }

        // D-pad (Navigation)
        microGamepad.dpad.valueChangedHandler = { [weak self] _, xValue, yValue in
            if xValue > 0.5 {
                self?.lastGesture = "Swipe Right"
            } else if xValue < -0.5 {
                self?.lastGesture = "Swipe Left"
            }

            if yValue > 0.5 {
                self?.lastGesture = "Swipe Up"
            } else if yValue < -0.5 {
                self?.lastGesture = "Swipe Down"
            }
        }
    }

    private func handleSelectButton() {
        NotificationCenter.default.post(name: .remoteSelectPressed, object: nil)
    }

    private func handlePlayPauseButton() {
        NotificationCenter.default.post(name: .remotePlayPausePressed, object: nil)
    }
}

extension Notification.Name {
    static let remoteSelectPressed = Notification.Name("remoteSelectPressed")
    static let remotePlayPausePressed = Notification.Name("remotePlayPausePressed")
}
```

---

## Complete Example

### Full tvOS App with Focus Navigation

```swift
// App/MyTVOSApp.swift
import SwiftUI

@main
struct MyTVOSApp: App {
    @StateObject private var remoteControl = RemoteControlService()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(remoteControl)
        }
    }
}

// Presentation/ContentView.swift
struct ContentView: View {
    enum MainFocus: Hashable {
        case tabs
        case content
    }

    @FocusState private var mainFocus: MainFocus?
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeTabView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(0)

            MoviesTabView()
                .tabItem {
                    Label("Movies", systemImage: "film.fill")
                }
                .tag(1)

            TVShowsTabView()
                .tabItem {
                    Label("TV Shows", systemImage: "tv.fill")
                }
                .tag(2)
        }
        .focused($mainFocus, equals: .tabs)
        .onAppear {
            mainFocus = .tabs
        }
    }
}
```

---

## Summary

This example demonstrates:

✅ **Focus State** - @FocusState for managing tvOS focus
✅ **Focus Groups** - FocusSection for logical grouping
✅ **Preferred Focus** - Setting initial and restored focus
✅ **Parallax Effects** - Depth and motion with focus animations
✅ **Scale Animation** - Focus-driven size changes
✅ **Remote Control** - Siri Remote gesture and button handling
✅ **Navigation** - Tab-based navigation with focus management
✅ **Visual Feedback** - Clear focus indicators and animations

**Key Takeaways:**
- Always set initial focus with @FocusState
- Use FocusSection to group related focusable elements
- Provide clear visual feedback for focused items
- Implement smooth animations for focus transitions
- Test with actual Siri Remote for gesture handling
- Consider accessibility for VoiceOver users
- Use environment(\.isFocused) to react to focus state
- Restore focus when returning to views
