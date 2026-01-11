# Video Player Example

Custom video player with AVKit, state management, and tvOS focus handling.

## Implementation

### PlayerState
```swift
enum PlayerState: Equatable {
    case idle
    case loading
    case playing
    case paused
    case buffering
    case ended
    case failed(PlayerError)
}
```

### PlayerViewModel
```swift
@MainActor
final class PlayerViewModel: ObservableObject {
    @Published var state: PlayerState = .idle
    @Published var currentTime: Double = 0
    @Published var duration: Double = 0

    private var player: AVPlayer?

    func play(url: URL) {
        state = .loading
        player = AVPlayer(url: url)
        player?.play()
        state = .playing
    }

    func pause() {
        player?.pause()
        state = .paused
    }
}
```

### tvOS Focus Handling
```swift
struct VideoPlayerView: View {
    @StateObject private var viewModel: PlayerViewModel
    @FocusState private var focusedControl: Control?

    var body: some View {
        VStack {
            VideoPlayer(player: viewModel.player)

            HStack {
                Button("Play/Pause") { viewModel.togglePlayPause() }
                    .focusable()
                    .focused($focusedControl, equals: .playPause)
            }
        }
    }
}
```
