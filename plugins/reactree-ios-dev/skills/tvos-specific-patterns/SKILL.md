---
name: "tvOS Specific Patterns"
description: "tvOS-specific development patterns including focus engine, remote control handling, top shelf, and large card UI layouts"
version: "2.0.0"
---

# tvOS Specific Patterns

Complete guide to tvOS-specific development patterns including focus engine, Siri remote handling, Top Shelf extensions, and TV-optimized UI design.

## Focus Engine

### @FocusState

```swift
struct TVMenuView: View {
    @FocusState private var focusedItem: MenuItem?

    enum MenuItem: Hashable {
        case home, movies, tvShows, settings
    }

    var body: some View {
        HStack(spacing: 40) {
            MenuButton(title: "Home", icon: "house.fill")
                .focused($focusedItem, equals: .home)

            MenuButton(title: "Movies", icon: "film.fill")
                .focused($focusedItem, equals: .movies)

            MenuButton(title: "TV Shows", icon: "tv.fill")
                .focused($focusedItem, equals: .tvShows)

            MenuButton(title: "Settings", icon: "gearshape.fill")
                .focused($focusedItem, equals: .settings)
        }
        .onAppear {
            focusedItem = .home
        }
    }
}

struct MenuButton: View {
    let title: String
    let icon: String
    @Environment(\.isFocused) var isFocused

    var body: some View {
        VStack {
            Image(systemName: icon)
                .font(.system(size: 60))
            Text(title)
                .font(.headline)
        }
        .frame(width: 200, height: 200)
        .background(isFocused ? Color.white.opacity(0.2) : Color.clear)
        .cornerRadius(20)
        .scaleEffect(isFocused ? 1.1 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isFocused)
    }
}
```

### focusable() Modifier

```swift
struct TVCardView: View {
    let movie: Movie
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack {
            AsyncImage(url: movie.posterURL) { image in
                image.resizable().aspectRatio(contentMode: .fill)
            } placeholder: {
                ProgressView()
            }
            .frame(width: 300, height: 450)
            .cornerRadius(12)

            Text(movie.title)
                .font(.headline)
        }
        .focusable()
        .focused($isFocused)
        .scaleEffect(isFocused ? 1.15 : 1.0)
        .shadow(radius: isFocused ? 20 : 0)
        .animation(.spring(), value: isFocused)
    }
}
```

### Custom Focus Effects

```swift
struct ParallaxCardView: View {
    let content: AnyView
    @FocusState private var isFocused: Bool
    @State private var translation: CGSize = .zero

    var body: some View {
        content
            .rotation3DEffect(
                .degrees(isFocused ? 5 : 0),
                axis: (x: -translation.height, y: translation.width, z: 0),
                perspective: 0.5
            )
            .scaleEffect(isFocused ? 1.1 : 1.0)
            .shadow(radius: isFocused ? 20 : 5)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isFocused)
            .focusable()
            .focused($isFocused)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        if isFocused {
                            translation = CGSize(
                                width: value.translation.width / 50,
                                height: value.translation.height / 50
                            )
                        }
                    }
                    .onEnded { _ in
                        translation = .zero
                    }
            )
    }
}
```

## Siri Remote Handling

### Tap Gestures

```swift
struct TVContentView: View {
    var body: some View {
        VStack {
            Text("Content")
        }
        .onTapGesture {
            print("Play/Pause button tapped")
        }
        .onLongPressGesture {
            print("Long press detected")
        }
    }
}
```

### Swipe Gestures

```swift
struct TVNavigationView: View {
    @State private var currentIndex = 0
    let items = ["Item 1", "Item 2", "Item 3"]

    var body: some View {
        VStack {
            Text(items[currentIndex])
                .font(.largeTitle)
        }
        .gesture(
            DragGesture()
                .onEnded { value in
                    if value.translation.width < -100 {
                        // Swipe left
                        navigateForward()
                    } else if value.translation.width > 100 {
                        // Swipe right
                        navigateBackward()
                    }
                }
        )
    }

    private func navigateForward() {
        if currentIndex < items.count - 1 {
            currentIndex += 1
        }
    }

    private func navigateBackward() {
        if currentIndex > 0 {
            currentIndex -= 1
        }
    }
}
```

### Menu Button Handling

```swift
struct TVPlayerView: View {
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VideoPlayer(player: player)
            .onPlayPauseCommand {
                togglePlayback()
            }
            .onExitCommand {
                // Menu button pressed
                dismiss()
            }
    }

    private func togglePlayback() {
        if player.isPlaying {
            player.pause()
        } else {
            player.play()
        }
    }
}
```

## Top Shelf Extension

### Top Shelf Configuration

```swift
// Create Top Shelf extension target in Xcode
// Info.plist:
// NSExtensionPrincipalClass: ContentProvider
// NSExtensionPointIdentifier: com.apple.tv-top-shelf

import TVServices

class ContentProvider: TVTopShelfContentProvider {
    override func loadTopShelfContent(completionHandler: @escaping (TVTopShelfContent?) -> Void) {
        // Create carousel content
        let items = createCarouselItems()

        let content = TVTopShelfCarouselContent(
            style: .actions,
            items: items
        )

        completionHandler(content)
    }

    private func createCarouselItems() -> [TVTopShelfCarouselItem] {
        let movies = fetchFeaturedMovies()

        return movies.map { movie in
            let item = TVTopShelfCarouselItem(identifier: movie.id)

            // Set images
            item.setImageURL(movie.posterURL, for: .screenScale1x)
            item.setImageURL(movie.posterURL, for: .screenScale2x)

            // Title and subtitle
            item.title = movie.title
            item.subtitle = movie.genre

            // Action URL (deep link)
            item.displayAction = TVTopShelfAction(url: URL(string: "myapp://movie/\(movie.id)")!)

            // Play action
            item.playAction = TVTopShelfAction(url: URL(string: "myapp://play/\(movie.id)")!)

            return item
        }
    }

    private func fetchFeaturedMovies() -> [Movie] {
        // Fetch from cache or network
        return []
    }
}
```

### Sectioned Top Shelf

```swift
override func loadTopShelfContent(completionHandler: @escaping (TVTopShelfContent?) -> Void) {
    var sections: [TVTopShelfItemCollection] = []

    // Continue Watching section
    let continueWatchingItems = createContinueWatchingItems()
    let continueSection = TVTopShelfItemCollection(items: continueWatchingItems)
    continueSection.title = "Continue Watching"
    sections.append(continueSection)

    // Trending section
    let trendingItems = createTrendingItems()
    let trendingSection = TVTopShelfItemCollection(items: trendingItems)
    trendingSection.title = "Trending Now"
    sections.append(trendingSection)

    let content = TVTopShelfSectionedContent(sections: sections)
    completionHandler(content)
}
```

## Large Card UI Patterns

### Grid Layout

```swift
struct TVMovieGridView: View {
    let movies: [Movie]

    private let columns = [
        GridItem(.adaptive(minimum: 300, maximum: 400), spacing: 40)
    ]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 40) {
                ForEach(movies) { movie in
                    MovieCard(movie: movie)
                }
            }
            .padding(60)
        }
    }
}

struct MovieCard: View {
    let movie: Movie
    @Environment(\.isFocused) var isFocused

    var body: some View {
        VStack(alignment: .leading) {
            AsyncImage(url: movie.posterURL) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle().fill(Color.gray)
            }
            .frame(width: 300, height: 450)
            .cornerRadius(12)

            VStack(alignment: .leading, spacing: 8) {
                Text(movie.title)
                    .font(.title2)
                    .lineLimit(1)

                Text(movie.genre)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 12)
        }
        .scaleEffect(isFocused ? 1.08 : 1.0)
        .shadow(radius: isFocused ? 20 : 0)
        .animation(.easeOut(duration: 0.2), value: isFocused)
    }
}
```

### Hero Banner

```swift
struct TVHeroBanner: View {
    let featuredMovie: Movie
    @State private var isFocused = false

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // Background image
            AsyncImage(url: featuredMovie.backdropURL) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Color.black
            }
            .frame(height: 800)
            .overlay(
                LinearGradient(
                    colors: [.clear, .black.opacity(0.8)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )

            // Content overlay
            VStack(alignment: .leading, spacing: 20) {
                Text(featuredMovie.title)
                    .font(.system(size: 72, weight: .bold))

                Text(featuredMovie.description)
                    .font(.title3)
                    .lineLimit(3)

                HStack(spacing: 30) {
                    Button(action: playMovie) {
                        HStack {
                            Image(systemName: "play.fill")
                            Text("Play")
                        }
                        .font(.title2)
                        .padding(.horizontal, 40)
                        .padding(.vertical, 20)
                        .background(Color.white)
                        .foregroundColor(.black)
                        .cornerRadius(10)
                    }
                    .buttonStyle(.card)

                    Button(action: addToWatchlist) {
                        HStack {
                            Image(systemName: "plus")
                            Text("Watchlist")
                        }
                        .font(.title2)
                        .padding(.horizontal, 40)
                        .padding(.vertical, 20)
                        .background(Color.white.opacity(0.2))
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .buttonStyle(.card)
                }
            }
            .padding(60)
        }
    }

    private func playMovie() {
        // Play movie
    }

    private func addToWatchlist() {
        // Add to watchlist
    }
}
```

## Side Menu Navigation

### Sidebar Pattern

```swift
struct TVSidebarView: View {
    @State private var selection: MenuItem? = .home

    enum MenuItem: String, CaseIterable {
        case home = "Home"
        case movies = "Movies"
        case tvShows = "TV Shows"
        case sports = "Sports"
        case settings = "Settings"

        var icon: String {
            switch self {
            case .home: return "house.fill"
            case .movies: return "film.fill"
            case .tvShows: return "tv.fill"
            case .sports: return "sportscourt.fill"
            case .settings: return "gearshape.fill"
            }
        }
    }

    var body: some View {
        NavigationSplitView {
            List(MenuItem.allCases, id: \.self, selection: $selection) { item in
                NavigationLink(value: item) {
                    Label(item.rawValue, systemImage: item.icon)
                        .font(.title3)
                }
            }
            .listStyle(.sidebar)
            .frame(width: 400)
        } detail: {
            destinationView(for: selection)
        }
    }

    @ViewBuilder
    private func destinationView(for item: MenuItem?) -> some View {
        switch item {
        case .home:
            HomeView()
        case .movies:
            MoviesView()
        case .tvShows:
            TVShowsView()
        case .sports:
            SportsView()
        case .settings:
            SettingsView()
        case nil:
            Text("Select an item")
        }
    }
}
```

## Video Playback

### AVPlayerViewController

```swift
import AVKit
import SwiftUI

struct TVVideoPlayerView: View {
    let videoURL: URL
    @State private var player: AVPlayer?

    var body: some View {
        VideoPlayer(player: player)
            .onAppear {
                player = AVPlayer(url: videoURL)
                player?.play()
            }
            .onDisappear {
                player?.pause()
                player = nil
            }
    }
}
```

### Picture in Picture

```swift
class PlayerViewController: AVPlayerViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        // Enable PiP
        if #available(tvOS 14.0, *) {
            allowsPictureInPicturePlayback = true
        }
    }
}
```

## Accessibility for tvOS

### VoiceOver Support

```swift
struct TVAccessibleCard: View {
    let movie: Movie

    var body: some View {
        VStack {
            Image(movie.posterName)
                .accessibilityLabel("\(movie.title) poster")

            Text(movie.title)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(movie.title), \(movie.genre), rated \(movie.rating)")
        .accessibilityAddTraits(.isButton)
    }
}
```

## Best Practices

### 1. Large Touch Targets

```swift
// ✅ Good: Large focusable areas
Button("Play") {
    playMovie()
}
.frame(minWidth: 200, minHeight: 80)
.buttonStyle(.card)

// ❌ Avoid: Small buttons
Button("Play") {
    playMovie()
}
.frame(width: 44, height: 44)  // Too small for TV!
```

### 2. Focus Groups

```swift
// ✅ Good: Logical focus order
VStack {
    ForEach(items) { item in
        ItemView(item: item)
            .focusable()
    }
}
.focusSection()  // Group related items

// Sections navigate as units
```

### 3. Readable Text

```swift
// ✅ Good: Large, readable text
Text("Movie Title")
    .font(.system(size: 48, weight: .bold))

Text("Description")
    .font(.title3)

// ❌ Avoid: Small text
Text("Details")
    .font(.caption)  // Hard to read from 10 feet away!
```

### 4. Remote-Friendly Interactions

```swift
// ✅ Good: Simple tap interactions
Button("Play") {
    playMovie()
}

// ❌ Avoid: Complex gestures
// Pinch, rotate, multi-finger gestures don't work with Siri Remote
```

## References

- [tvOS Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/tvos)
- [Focus Engine Documentation](https://developer.apple.com/documentation/swiftui/focus-management)
- [Top Shelf Extensions](https://developer.apple.com/documentation/tvservices)
- [Siri Remote Interactions](https://developer.apple.com/design/human-interface-guidelines/tvos/remote-and-controllers/remote/)
