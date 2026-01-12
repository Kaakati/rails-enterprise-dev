---
name: ios-debug
description: "Comprehensive debugging workflow for iOS/tvOS applications with crash analysis, memory debugging, performance profiling, and agent coordination"
color: green
allowed-tools: ["*"]
---

# iOS/tvOS Debugging Workflow

Specialized multi-agent debugging workflow for iOS/tvOS projects using Xcode Instruments, LLDB, and static analysis tools.

## Quick Start

```
/ios-debug [issue description]
```

**Examples:**
- `/ios-debug app crashes on launch with EXC_BAD_ACCESS`
- `/ios-debug memory leak in UserViewModel`
- `/ios-debug network timeout on API calls`
- `/ios-debug SwiftUI view not updating when data changes`
- `/ios-debug navigation stack issues after modal dismiss`
- `/ios-debug tvOS focus not working on custom button`

---

## Table of Contents

1. [Overview](#overview)
2. [Debugging Workflows](#debugging-workflows)
3. [Crash Analysis](#crash-analysis)
4. [Memory Debugging](#memory-debugging)
5. [Performance Profiling](#performance-profiling)
6. [Network Debugging](#network-debugging)
7. [UI Debugging](#ui-debugging)
8. [LLDB Debugging](#lldb-debugging)
9. [Xcode Instruments](#xcode-instruments)
10. [Agent Coordination](#agent-coordination)
11. [Debugging Examples](#debugging-examples)
12. [Best Practices](#best-practices)

---

## Overview

### Debugging Philosophy

iOS/tvOS debugging follows a systematic approach:

1. **Reproduce** - Reliably trigger the issue
2. **Isolate** - Narrow down the source (device, OS version, data)
3. **Analyze** - Use tools to gather diagnostic data
4. **Hypothesize** - Form testable theories
5. **Verify** - Confirm the root cause
6. **Fix** - Implement solution with tests
7. **Validate** - Ensure fix works across all scenarios

### Multi-Agent Debugging Workflow

```
┌─────────────────────────────────────────────────────────┐
│              workflow-orchestrator                       │
│         (coordinates entire debug flow)                  │
└────────────────┬────────────────────────────────────────┘
                 │
      ┌──────────┴──────────┐
      │                     │
┌─────▼──────┐      ┌───────▼────────┐
│   Phase 1  │      │    Phase 2     │
│ Reproduce  │─────▶│ Gather Data    │
│  & Triage  │      │  & Analyze     │
└─────┬──────┘      └───────┬────────┘
      │                     │
      │                     │
┌─────▼──────┐      ┌───────▼────────┐
│   Phase 3  │      │    Phase 4     │
│   Isolate  │─────▶│  Hypothesize   │
│   Cause    │      │  & Test Fix    │
└─────┬──────┘      └───────┬────────┘
      │                     │
      │                     │
┌─────▼──────┐      ┌───────▼────────┐
│   Phase 5  │      │    Phase 6     │
│  Implement │─────▶│    Verify      │
│    Fix     │      │   & Deploy     │
└────────────┘      └────────────────┘
```

### Agents Involved

- **workflow-orchestrator** - Coordinates debug workflow
- **log-analyzer** - Analyzes crash logs and console output
- **file-finder** - Locates source files from stack traces
- **codebase-inspector** - Analyzes code patterns
- **core-lead** - Debugs Core layer issues (services, networking)
- **presentation-lead** - Debugs UI/ViewModel issues
- **test-oracle** - Creates regression tests for bugs

---

## Debugging Workflows

### Workflow 1: Crash Analysis

**Use Case**: App crashes with exception or signal

**Steps**:

1. **Capture Crash Log**
   ```bash
   # Extract crash log from device
   xcrun simctl spawn booted log collect --output crash.logarchive

   # Or from Xcode Organizer
   # Window → Organizer → Crashes
   ```

2. **Symbolicate Crash Log**
   ```bash
   # Ensure dSYM is available
   # Build Settings → Debug Information Format → DWARF with dSYM File

   # Symbolicate using symbolicatecrash
   export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
   ./symbolicatecrash crash.crash YourApp.app.dSYM > symbolicated.crash
   ```

3. **Analyze Stack Trace**
   - Identify thread that crashed (usually Thread 0)
   - Read exception type (EXC_BAD_ACCESS, EXC_BREAKPOINT, etc.)
   - Trace back through call stack to identify source
   - Look for force unwraps, array out of bounds, threading issues

4. **Reproduce Reliably**
   - Identify trigger (specific user action, data condition)
   - Document steps to reproduce
   - Test on multiple devices/OS versions

5. **Fix and Validate**
   - Implement defensive fix (guard statements, optional chaining)
   - Add crash handling if appropriate
   - Write regression test to prevent recurrence

**Common Crash Types**:

| Exception Type | Cause | Solution |
|----------------|-------|----------|
| `EXC_BAD_ACCESS` | Accessing deallocated memory | Check retain cycles, use weak references |
| `EXC_BREAKPOINT` | Force unwrap on nil | Use optional binding or guard |
| `EXC_BAD_INSTRUCTION` | Array out of bounds | Add bounds checking |
| `SIGABRT` | Fatal error or assertion | Check preconditions and assertions |
| `SIGKILL` | System terminated app | Reduce memory usage |

---

### Workflow 2: Memory Leak Detection

**Use Case**: App memory grows unbounded over time

**Steps**:

1. **Profile with Instruments**
   ```bash
   # Launch Instruments with Leaks template
   # Xcode → Product → Profile (⌘I)
   # Select "Leaks" template
   ```

2. **Identify Leak Patterns**
   - Look for memory graph spikes that don't release
   - Check reference counts
   - Identify leaked object types

3. **Use Memory Graph Debugger**
   ```bash
   # While running in Xcode, click Debug Memory Graph button
   # or Debug → Debug Workflow → View Memory Graph Hierarchy
   ```

4. **Analyze Retain Cycles**
   - Look for strong reference cycles (A → B → A)
   - Common in closures capturing `self`
   - Common in delegate patterns without `weak`

5. **Fix Retain Cycles**
   ```swift
   // ✅ Use weak/unowned in closures
   viewModel.fetchData { [weak self] result in
       self?.updateUI(with: result)
   }

   // ✅ Use weak for delegates
   weak var delegate: UserViewDelegate?

   // ✅ Use @MainActor for view models
   @MainActor
   class UserViewModel: ObservableObject {
       // Prevents accidental retain cycles
   }
   ```

6. **Validate Fix**
   - Re-run Instruments Leaks
   - Verify memory releases after operations
   - Test navigation flows that previously leaked

**Common Memory Leak Patterns**:

```swift
// ❌ BAD: Retain cycle in closure
class ViewController: UIViewController {
    var onComplete: (() -> Void)?

    func loadData() {
        service.fetch { data in
            self.data = data  // Retains self
            self.onComplete?()  // Retains self
        }
    }
}

// ✅ GOOD: Use weak self
func loadData() {
    service.fetch { [weak self] data in
        guard let self = self else { return }
        self.data = data
        self.onComplete?()
    }
}

// ❌ BAD: Strong delegate reference
class UserView: UIView {
    var delegate: UserViewDelegate?  // Should be weak
}

// ✅ GOOD: Weak delegate
class UserView: UIView {
    weak var delegate: UserViewDelegate?
}

// ❌ BAD: Timer retains target
class TimerViewController: UIViewController {
    var timer: Timer?

    func startTimer() {
        timer = Timer.scheduledTimer(
            timeInterval: 1.0,
            target: self,  // Strong reference
            selector: #selector(update),
            userInfo: nil,
            repeats: true
        )
    }
}

// ✅ GOOD: Invalidate timer or use weak reference
deinit {
    timer?.invalidate()
}
```

---

### Workflow 3: Performance Profiling

**Use Case**: UI lag, slow operations, poor responsiveness

**Steps**:

1. **Profile with Time Profiler**
   ```bash
   # Xcode → Product → Profile → Time Profiler
   # Record while performing slow operation
   # Stop recording and analyze call tree
   ```

2. **Identify Bottlenecks**
   - Sort by "Self" time (time spent in function itself)
   - Look for unexpected work on main thread
   - Identify expensive operations in tight loops

3. **Analyze Thread Activity**
   - Check if main thread is blocked
   - Verify background work is off main thread
   - Look for thread contention (multiple threads waiting)

4. **Optimize Hot Paths**
   - Move expensive operations off main thread
   - Cache computed properties
   - Reduce view hierarchy complexity
   - Use lazy loading

5. **Profile Memory Allocations**
   ```bash
   # Xcode → Product → Profile → Allocations
   # Look for excessive allocations
   # Identify temporary objects created in loops
   ```

6. **Validate Performance Improvement**
   - Re-profile after optimization
   - Measure with XCTest performance tests
   - Test on older devices (iPhone SE, iPad Air)

**Common Performance Issues**:

```swift
// ❌ BAD: Expensive computation on main thread
class UserListView: View {
    let users: [User]

    var body: some View {
        List(users) { user in
            Text(heavyComputation(user))  // Blocks UI
        }
    }

    func heavyComputation(_ user: User) -> String {
        // Expensive string formatting
        return user.fullProfile  // Computes on every render
    }
}

// ✅ GOOD: Pre-compute or cache
class UserListViewModel: ObservableObject {
    @Published var displayUsers: [DisplayUser] = []

    func loadUsers(_ users: [User]) async {
        // Compute off main thread
        let processed = await Task.detached {
            users.map { DisplayUser(user: $0) }
        }.value

        await MainActor.run {
            self.displayUsers = processed
        }
    }
}

// ❌ BAD: Creating views in loops
ForEach(items) { item in
    VStack {
        Image(systemName: getIcon(item))  // Expensive lookup
        Text(formatText(item))  // Expensive formatting
    }
}

// ✅ GOOD: Pre-compute view data
struct ItemViewData {
    let icon: String
    let text: String
}

@Published var viewData: [ItemViewData] = []

ForEach(viewData, id: \.text) { data in
    VStack {
        Image(systemName: data.icon)
        Text(data.text)
    }
}
```

**Performance Metrics**:

| Metric | Good | Warning | Critical |
|--------|------|---------|----------|
| Main Thread Usage | < 50% | 50-80% | > 80% |
| Frame Rate | 60 FPS | 30-60 FPS | < 30 FPS |
| Launch Time | < 0.4s | 0.4-1.0s | > 1.0s |
| Memory Usage | < 100 MB | 100-300 MB | > 300 MB |
| Network Latency | < 200ms | 200-500ms | > 500ms |

---

### Workflow 4: Network Debugging

**Use Case**: Network requests failing, slow, or returning unexpected data

**Steps**:

1. **Enable Network Debugging**
   ```swift
   // Add to AppDelegate or App struct
   #if DEBUG
   URLSession.shared.configuration.protocolClasses = [NetworkLoggerProtocol.self]
   #endif
   ```

2. **Capture Network Traffic**
   ```bash
   # Option 1: Charles Proxy
   # Configure proxy: Settings → Wi-Fi → Configure Proxy → Manual
   # Server: <Mac IP>, Port: 8888

   # Option 2: Proxyman
   # Certificate setup required for HTTPS

   # Option 3: Network Link Conditioner
   # Additional Tools for Xcode → Network Link Conditioner
   # Simulate slow networks (3G, LTE, etc.)
   ```

3. **Analyze Request/Response**
   - Check request URL, headers, body
   - Verify response status code
   - Inspect response headers and body
   - Check for SSL/TLS errors

4. **Debug Alamofire/URLSession**
   ```swift
   // Enable Alamofire event monitoring
   let monitor = ClosureEventMonitor()
   monitor.requestDidFinish = { request in
       print("✅ Request: \(request.request?.url?.absoluteString ?? "")")
   }
   monitor.requestDidFail = { request, error in
       print("❌ Failed: \(error.localizedDescription)")
   }

   let session = Session(eventMonitors: [monitor])
   ```

5. **Test Error Conditions**
   - Offline mode (airplane mode)
   - Slow network (Network Link Conditioner)
   - Timeout scenarios
   - Server errors (500, 503)

6. **Implement Robust Error Handling**
   ```swift
   enum NetworkError: Error {
       case noConnection
       case timeout
       case serverError(statusCode: Int)
       case decodingError(Error)
       case unknown(Error)
   }

   func handleNetworkError(_ error: Error) -> NetworkError {
       if let urlError = error as? URLError {
           switch urlError.code {
           case .notConnectedToInternet:
               return .noConnection
           case .timedOut:
               return .timeout
           default:
               return .unknown(error)
           }
       }
       return .unknown(error)
   }
   ```

**Common Network Issues**:

| Issue | Symptoms | Solution |
|-------|----------|----------|
| SSL Pinning Failure | "The certificate for this server is invalid" | Update pinned certificates |
| Timeout | Request never completes | Increase timeout, check server |
| Malformed JSON | Decoding error | Validate response with API docs |
| 401 Unauthorized | Authentication failure | Check token, refresh if needed |
| 500 Server Error | Server-side issue | Retry with exponential backoff |

---

### Workflow 5: UI Debugging

**Use Case**: Views not appearing, layout broken, UI not updating

**Steps**:

1. **Use View Debugger**
   ```bash
   # While running in Xcode
   # Debug → View Debugging → Capture View Hierarchy
   # Or click 3D layers button in debug bar
   ```

2. **Inspect View Hierarchy**
   - Check if view is in hierarchy
   - Verify frame/bounds are non-zero
   - Look for overlapping views
   - Check z-order and alpha values

3. **Debug SwiftUI State**
   ```swift
   // Add debug print to body
   var body: some View {
       let _ = Self._printChanges()  // Shows what changed

       VStack {
           Text("Hello")
       }
       .onAppear {
           print("View appeared")
       }
   }
   ```

4. **Check Layout Constraints (UIKit)**
   ```bash
   # Enable constraint debugging
   # Edit Scheme → Run → Arguments → Environment Variables
   # UIViewShowAlignmentRects = YES
   # UIConstraintBasedLayoutLogUnsatisfiable = YES
   ```

5. **Debug SwiftUI Update Issues**
   - Verify `@State`, `@Published`, `@StateObject` usage
   - Check if updates happen on main thread
   - Ensure view is observing correct object
   - Look for view identity issues (missing `id`)

6. **Use Accessibility Inspector**
   ```bash
   # Xcode → Open Developer Tool → Accessibility Inspector
   # Check if elements are accessible
   # Verify labels, traits, hints
   ```

**Common UI Issues**:

```swift
// ❌ BAD: View not updating (wrong property wrapper)
struct UserView: View {
    var viewModel = UserViewModel()  // Not @StateObject

    var body: some View {
        Text(viewModel.name)  // Won't update
    }
}

// ✅ GOOD: Use @StateObject
struct UserView: View {
    @StateObject var viewModel = UserViewModel()

    var body: some View {
        Text(viewModel.name)  // Updates on changes
    }
}

// ❌ BAD: Background thread UI update
Task {
    let data = await fetchData()
    self.items = data  // May be on background thread
}

// ✅ GOOD: Use @MainActor or explicit dispatch
Task {
    let data = await fetchData()
    await MainActor.run {
        self.items = data
    }
}

// ❌ BAD: Missing view identity
List {
    ForEach(items) { item in
        ItemRow(item: item)
    }
}
.onDelete { offsets in
    items.remove(atOffsets: offsets)  // May crash
}

// ✅ GOOD: Explicit ID
List {
    ForEach(items, id: \.id) { item in
        ItemRow(item: item)
    }
}
.onDelete { offsets in
    items.remove(atOffsets: offsets)
}
```

---

### Workflow 6: Breakpoint Debugging

**Use Case**: Step through code to understand execution flow

**Steps**:

1. **Set Breakpoints**
   ```bash
   # Click line number in gutter (blue marker)
   # Or use keyboard: ⌘\
   # Right-click breakpoint for options:
   #   - Condition (break only if true)
   #   - Ignore count (skip N times)
   #   - Action (log, sound, debugger command)
   ```

2. **Use Conditional Breakpoints**
   ```swift
   // Set condition: userId == "12345"
   func processUser(_ userId: String) {
       let user = fetchUser(userId)  // Breakpoint here
       updateUI(user)
   }
   ```

3. **Symbolic Breakpoints**
   ```bash
   # Debug → Breakpoints → Create Symbolic Breakpoint
   # Symbol: UIViewAlertForUnsatisfiableConstraints
   # Break when constraint conflicts occur

   # Symbol: objc_exception_throw
   # Break when Objective-C exception is thrown
   ```

4. **Exception Breakpoints**
   ```bash
   # Debug → Breakpoints → Create Exception Breakpoint
   # Exception: All (break on all exceptions)
   # Exception: Swift Error (break on Swift errors)
   ```

5. **Navigate During Debugging**
   ```bash
   # Continue (⌃⌘Y): Resume execution
   # Step Over (F6): Execute line, don't enter functions
   # Step Into (F7): Enter function calls
   # Step Out (F8): Complete current function and return
   ```

6. **Inspect Variables**
   ```bash
   # Variables View: Shows local variables
   # Hover over variable: Quick peek
   # Right-click → Print Description: po command
   # Right-click → Watch: Track across steps
   ```

---

### Workflow 7: LLDB Debugging

**Use Case**: Advanced debugging, scripting, automation

**Steps**:

1. **Basic LLDB Commands**
   ```lldb
   # Print variable
   (lldb) po self.viewModel.user

   # Print expression
   (lldb) p self.items.count

   # Execute code
   (lldb) expr self.reloadData()

   # Set variable
   (lldb) expr self.debugMode = true
   ```

2. **View Debugging**
   ```lldb
   # Print view hierarchy
   (lldb) po self.view.recursiveDescription()

   # Print constraint conflicts
   (lldb) po [[UIWindow keyWindow] _autolayoutTrace]

   # Flash view (debug overlays)
   (lldb) expr CATransaction.flush()
   (lldb) expr -l objc++ -O -- [CALayer setDrawsAsynchronously:NO]
   ```

3. **Thread Debugging**
   ```lldb
   # List threads
   (lldb) thread list

   # Switch thread
   (lldb) thread select 2

   # Backtrace (stack trace)
   (lldb) bt
   (lldb) bt all  # All threads
   ```

4. **Breakpoint Management**
   ```lldb
   # List breakpoints
   (lldb) breakpoint list

   # Delete breakpoint
   (lldb) breakpoint delete 1

   # Disable breakpoint
   (lldb) breakpoint disable 2

   # Set breakpoint
   (lldb) b ViewController.swift:42
   (lldb) breakpoint set --name viewDidLoad
   ```

5. **Advanced Techniques**
   ```lldb
   # Conditional breakpoint
   (lldb) breakpoint set --name fetchUser --condition userId == "12345"

   # Breakpoint with action
   (lldb) breakpoint command add 1
   Enter commands, one per line. End with CTRL+D.
   > po self.user
   > continue
   > DONE

   # Python scripts
   (lldb) command script import ~/lldb_scripts/custom.py
   ```

---

### Workflow 8: tvOS-Specific Debugging

**Use Case**: Focus issues, remote control, parallax effects

**Steps**:

1. **Debug Focus Engine**
   ```swift
   // Enable focus debugging
   #if DEBUG
   UIView.enableFocusLogging = true
   #endif

   // Override focus environment
   override var preferredFocusEnvironments: [UIFocusEnvironment] {
       return [customButton]
   }

   // Debug focus updates
   override func didUpdateFocus(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
       print("Focus moved from \(context.previouslyFocusedView) to \(context.nextFocusedView)")
   }
   ```

2. **Test Remote Control Events**
   ```swift
   // Enable remote control
   override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
       for press in presses {
           print("Press type: \(press.type.rawValue)")

           switch press.type {
           case .menu:
               print("Menu button pressed")
           case .playPause:
               print("Play/Pause pressed")
           case .select:
               print("Select pressed")
           default:
               super.pressesBegan(presses, with: event)
           }
       }
   }
   ```

3. **Debug Parallax Effects**
   ```swift
   // Verify motion effects
   let motion = UIInterpolatingMotionEffect(keyPath: "center.x", type: .tiltAlongHorizontalAxis)
   motion.minimumRelativeValue = -10
   motion.maximumRelativeValue = 10
   view.addMotionEffect(motion)

   // Debug with Simulator
   // I/O → Parallax → Shift Focus (arrow keys)
   ```

4. **Test Top Shelf Extension**
   ```bash
   # Debug top shelf
   # Edit Scheme → Run → Executable → tvOS App (Top Shelf Extension)
   # Run app, then press Home to see top shelf
   ```

5. **Accessibility on tvOS**
   ```swift
   // Enable VoiceOver testing
   // Settings → Accessibility → VoiceOver → On

   // Set accessibility labels
   button.accessibilityLabel = "Play Video"
   button.accessibilityHint = "Double-click to start playback"
   ```

---

## Crash Analysis

### Crash Log Locations

**Simulator**:
```bash
~/Library/Logs/DiagnosticReports/
~/Library/Logs/CoreSimulator/[Device ID]/system.log
```

**Device** (via Xcode):
```bash
# Window → Devices and Simulators → View Device Logs
# Or sync via iTunes and check:
~/Library/Logs/CrashReporter/MobileDevice/[Device Name]/
```

**Organizer**:
```bash
# Window → Organizer → Crashes
# Requires users to share crash data
```

### Symbolication

**Manual Symbolication**:
```bash
#!/bin/bash
# symbolicate.sh

CRASH_FILE="$1"
APP_BUNDLE="$2"
DSYM_FILE="$3"

# Find symbolicatecrash tool
SYMBOLICATE=$(find /Applications/Xcode.app -name symbolicatecrash | head -n 1)

if [ -z "$SYMBOLICATE" ]; then
  echo "❌ symbolicatecrash not found"
  exit 1
fi

# Set developer directory
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer

# Symbolicate
"$SYMBOLICATE" -v "$CRASH_FILE" "$DSYM_FILE" > symbolicated.crash

if [ $? -eq 0 ]; then
  echo "✅ Symbolicated crash log: symbolicated.crash"
else
  echo "❌ Symbolication failed"
  exit 1
fi
```

**Automatic Symbolication** (Xcode Organizer):
1. Ensure "Automatically manage signing" is enabled
2. Build with dSYM (Release builds include by default)
3. Archive app (Product → Archive)
4. Upload to App Store Connect or TestFlight
5. Crash logs automatically symbolicated in Organizer

### Crash Report Anatomy

```
Exception Type:  EXC_BAD_ACCESS (SIGSEGV)
Exception Subtype: KERN_INVALID_ADDRESS at 0x0000000000000018

Thread 0 Crashed:: Dispatch queue: com.apple.main-thread
0   MyApp                           0x0000000100e52c60 UserViewModel.loadUser() + 64
1   MyApp                           0x0000000100e52b40 UserView.body.getter + 120
2   SwiftUI                         0x00007fff2e4a2180 0x7fff2e000000 + 4858240
3   SwiftUI                         0x00007fff2e4a2000 0x7fff2e000000 + 4857856
...
```

**Key Sections**:
- **Exception Type**: Type of crash (EXC_BAD_ACCESS, EXC_BREAKPOINT, etc.)
- **Exception Subtype**: Specific error (KERN_INVALID_ADDRESS, etc.)
- **Thread**: Which thread crashed (usually Thread 0 = main thread)
- **Stack Trace**: Call stack leading to crash

### Common Crash Patterns

**Force Unwrap on nil**:
```swift
// Crash
let user: User? = nil
let name = user!.name  // EXC_BREAKPOINT

// Fix
guard let user = user else { return }
let name = user.name

// Or
let name = user?.name ?? "Unknown"
```

**Array Index Out of Bounds**:
```swift
// Crash
let items = [1, 2, 3]
let value = items[5]  // EXC_BAD_INSTRUCTION

// Fix
guard items.indices.contains(5) else { return }
let value = items[5]

// Or
let value = items[safe: 5]  // Extension returning optional

extension Array {
    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
```

**Retain Cycle Leading to Crash**:
```swift
// Crash (eventually)
class ViewController: UIViewController {
    var completion: (() -> Void)?

    func setup() {
        completion = {
            self.view.backgroundColor = .red  // Retain cycle
        }
    }
}

// Fix
func setup() {
    completion = { [weak self] in
        self?.view.backgroundColor = .red
    }
}
```

---

## Memory Debugging

### Instruments - Leaks

**Profile with Leaks**:
1. Xcode → Product → Profile (⌘I)
2. Select "Leaks" template
3. Click Record (red button)
4. Perform actions that might leak (navigate, close views)
5. Stop recording
6. Analyze leaks in timeline

**Interpret Leaks Report**:
- **Leaked Object**: Object that was allocated but never deallocated
- **Leaked Bytes**: Total memory leaked
- **Leaked Call Tree**: Stack trace showing where leak was allocated

**Fix Common Leaks**:

```swift
// Leak 1: Strong capture in closure
class UserViewModel {
    var onUpdate: (() -> Void)?

    func startObserving() {
        NotificationCenter.default.addObserver(
            forName: .userUpdated,
            object: nil,
            queue: .main
        ) { [weak self] _ in  // ✅ weak self
            self?.onUpdate?()
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// Leak 2: Timer retaining target
class TimerManager {
    var timer: Timer?
    weak var delegate: TimerDelegate?  // ✅ weak

    func start() {
        timer = Timer.scheduledTimer(
            withTimeInterval: 1.0,
            repeats: true
        ) { [weak self] _ in  // ✅ weak self
            self?.delegate?.timerFired()
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    deinit {
        stop()
    }
}

// Leak 3: Delegate retain cycle
protocol UserViewDelegate: AnyObject {
    func didSelectUser(_ user: User)
}

class UserView: UIView {
    weak var delegate: UserViewDelegate?  // ✅ weak delegate
}
```

### Memory Graph Debugger

**Capture Memory Graph**:
1. Run app in Xcode
2. Click "Debug Memory Graph" button (diamond with circles icon)
3. Or Debug → Debug Workflow → View Memory Graph Hierarchy

**Navigate Memory Graph**:
- **Left Pane**: List of all objects in memory
- **Center Pane**: Visual graph of references
- **Right Pane**: Object details and backtrace

**Find Retain Cycles**:
1. Filter objects by type (e.g., "ViewModel")
2. Look for cycles in reference graph
3. Identify strong references that should be weak
4. Fix and re-test

**Export Memory Graph**:
```bash
# Export memory graph for offline analysis
# Debug → Debug Workflow → Export Memory Graph
# Saves .memgraph file
```

### Allocation Tracking

**Profile with Allocations**:
1. Xcode → Product → Profile → Allocations
2. Record while performing actions
3. Look for:
   - Persistent allocations (memory that never releases)
   - Spikes in memory usage
   - Temporary objects created in loops

**Mark Generation**:
- Click "Mark Generation" to snapshot current allocations
- Perform action (e.g., open/close view)
- Compare generations to see what wasn't released

**Analyze Allocation Backtrace**:
- Select allocation in list
- View backtrace to see where it was allocated
- Determine if deallocation is expected

---

## Performance Profiling

### Time Profiler

**Profile CPU Usage**:
1. Xcode → Product → Profile → Time Profiler
2. Click Record
3. Perform slow operation
4. Stop recording
5. Analyze call tree

**Interpret Time Profiler**:
- **Self Time**: Time spent in function itself (excluding callees)
- **Total Time**: Time spent in function and all callees
- **Weight**: Percentage of total execution time

**Optimize Hot Paths**:

```swift
// Before: Expensive computation in loop
func processItems(_ items: [Item]) {
    for item in items {
        let result = expensiveComputation(item)  // Called N times
        display(result)
    }
}

// After: Batch processing
func processItems(_ items: [Item]) async {
    let results = await Task.detached {
        items.map { expensiveComputation($0) }  // Parallel processing
    }.value

    await MainActor.run {
        displayAll(results)
    }
}

// Before: Main thread blocking
func loadData() {
    let data = syncFetch()  // Blocks main thread
    updateUI(data)
}

// After: Async/await
func loadData() async {
    let data = await asyncFetch()  // Non-blocking
    await MainActor.run {
        updateUI(data)
    }
}
```

### System Trace

**Capture System Trace**:
1. Xcode → Product → Profile → System Trace
2. Record while performing laggy operation
3. Analyze thread activity, system calls, graphics rendering

**Identify Issues**:
- Main thread blocked (red sections)
- Too many context switches
- Excessive I/O operations
- Graphics rendering bottlenecks

### Performance Testing

**XCTest Performance Measurement**:

```swift
import XCTest

class PerformanceTests: XCTestCase {
    func testDataProcessingPerformance() {
        let items = generateTestData(count: 10000)
        let processor = DataProcessor()

        measure {
            processor.process(items)
        }

        // Baseline: 0.350s (±5%)
        // If regression > 10%, test fails
    }

    func testViewRenderingPerformance() {
        let view = ComplexView(data: testData)

        measureMetrics([.wallClockTime], automaticallyStartMeasuring: false) {
            startMeasuring()
            _ = view.body  // Render view
            stopMeasuring()
        }
    }
}
```

---

## Network Debugging

### Charles Proxy Setup

**Install Charles**:
```bash
# Download from https://www.charlesproxy.com/
# Install certificate for HTTPS inspection
# Help → SSL Proxying → Install Charles Root Certificate
```

**Configure iOS Device**:
1. Settings → Wi-Fi → (i) icon
2. Configure Proxy → Manual
3. Server: [Mac IP address]
4. Port: 8888
5. Install Charles certificate on device
6. Settings → General → About → Certificate Trust Settings → Enable

**Filter Traffic**:
- Structure → Focus on specific host
- Sequence → See requests in order
- SSL Proxying Settings → Enable for API domains

### Proxyman Setup

**Install Proxyman**:
```bash
# Download from https://proxyman.io/
# More modern alternative to Charles
# Automatic certificate installation
```

**Features**:
- Automatic HTTPS decryption
- Request/response body formatting (JSON, XML)
- Breakpoints (pause requests to modify)
- Map local (replace responses with local files)
- Repeat requests

### Network Link Conditioner

**Simulate Poor Network**:
1. Download "Additional Tools for Xcode"
2. Install Network Link Conditioner
3. System Settings → Network Link Conditioner
4. Select profile (3G, LTE, 100% Loss, etc.)

**Test Scenarios**:
- Slow network (3G)
- High latency (500ms)
- Packet loss (10%)
- Offline (100% loss)

### URLSession Debugging

**Enable Logging**:

```swift
import Foundation

class NetworkLogger: URLProtocol {
    override class func canInit(with request: URLRequest) -> Bool {
        return true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }

    override func startLoading() {
        print("🌐 Request: \(request.url?.absoluteString ?? "")")
        print("   Method: \(request.httpMethod ?? "")")
        print("   Headers: \(request.allHTTPHeaderFields ?? [:])")

        if let body = request.httpBody {
            print("   Body: \(String(data: body, encoding: .utf8) ?? "")")
        }

        // Pass through to actual network
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let httpResponse = response as? HTTPURLResponse {
                print("📡 Response: \(httpResponse.statusCode)")
                print("   Headers: \(httpResponse.allHeaderFields)")
            }

            if let data = data {
                print("   Body: \(String(data: data, encoding: .utf8) ?? "")")
            }

            if let error = error {
                print("❌ Error: \(error.localizedDescription)")
            }

            self.client?.urlProtocol(self, didLoad: data ?? Data())
            self.client?.urlProtocolDidFinishLoading(self)
        }
        task.resume()
    }

    override func stopLoading() {}
}

// Enable in app delegate
URLProtocol.registerClass(NetworkLogger.self)
```

---

## UI Debugging

### View Debugger

**Capture View Hierarchy**:
- Debug → View Debugging → Capture View Hierarchy
- Or click 3D layers icon in debug bar

**Navigate Hierarchy**:
- Rotate view with mouse/trackpad
- Show/hide layers
- Filter by view type
- Inspect frame, constraints, properties

**Common Checks**:
- Is view in hierarchy?
- Is frame non-zero?
- Is alpha > 0?
- Is view hidden?
- Is view clipped by superview?
- Are constraints satisfied?

### SwiftUI Debug Techniques

**Print Changes**:
```swift
struct ContentView: View {
    @State private var count = 0

    var body: some View {
        let _ = Self._printChanges()  // Prints what triggered re-render

        Text("Count: \(count)")
            .onTapGesture {
                count += 1
            }
    }
}
```

**Debug View Updates**:
```swift
extension View {
    func debugPrint(_ value: Any) -> some View {
        print(value)
        return self
    }

    func debugAction(_ closure: () -> Void) -> some View {
        closure()
        return self
    }
}

// Usage
Text("Hello")
    .debugPrint("Text view rendered")
    .debugAction {
        print("Frame: \(frame)")
    }
```

**Identify View Identity Issues**:
```swift
// Problem: View doesn't update when item changes
List {
    ForEach(items) { item in
        ItemRow(item: item)
    }
}

// Solution: Explicit ID
List {
    ForEach(items, id: \.id) { item in
        ItemRow(item: item)
    }
}

// Or: Equatable conformance
struct ItemRow: View, Equatable {
    let item: Item

    static func == (lhs: ItemRow, rhs: ItemRow) -> Bool {
        lhs.item.id == rhs.item.id
    }
}
```

### Accessibility Inspector

**Launch Accessibility Inspector**:
- Xcode → Open Developer Tool → Accessibility Inspector
- Select running simulator/device

**Audit View**:
1. Click "Inspect" button
2. Hover over elements in simulator
3. View accessibility properties:
   - Label
   - Trait
   - Hint
   - Frame
   - Value

**Run Audit**:
1. Click "Audit" button
2. Select scope (Current Screen, Entire App)
3. Review issues:
   - Missing labels
   - Contrast issues
   - Element not accessible
   - Ambiguous labels

**Fix Common Issues**:
```swift
// Missing label
Button {} label: {
    Image(systemName: "star")
}
.accessibilityLabel("Favorite")  // ✅ Add label

// Low contrast
Text("Light gray")
    .foregroundColor(.gray)  // ❌ Poor contrast
    .foregroundColor(.primary)  // ✅ System adaptive color

// Dynamic Type not supported
Text("Fixed size")
    .font(.system(size: 14))  // ❌ Fixed
    .font(.body)  // ✅ Scales with Dynamic Type
```

---

## LLDB Debugging

### Essential LLDB Commands

**Print Commands**:
```lldb
# Print object description (po = print object)
(lldb) po self.viewModel.user

# Print raw value (p = print)
(lldb) p self.items.count

# Print with type info (v = frame variable)
(lldb) v self.delegate

# Print formatted
(lldb) p/x 255  # Hexadecimal
(lldb) p/t 255  # Binary
(lldb) p/d 0xFF  # Decimal
```

**Expression Evaluation**:
```lldb
# Execute Swift code
(lldb) expr self.reload()
(lldb) e self.isDebugMode = true

# Declare variable
(lldb) expr let user = User(id: "123", name: "Test")
(lldb) po user.name

# Import framework
(lldb) expr import UIKit
(lldb) e UIView.animate(withDuration: 1.0) { self.view.alpha = 0.5 }
```

**Breakpoint Commands**:
```lldb
# List breakpoints
(lldb) breakpoint list
(lldb) br l  # Short form

# Set breakpoint
(lldb) breakpoint set --file ViewController.swift --line 42
(lldb) br s -f ViewController.swift -l 42
(lldb) b ViewController.swift:42  # Shortest

# Set by function name
(lldb) breakpoint set --name viewDidLoad
(lldb) br s -n viewDidLoad
(lldb) b viewDidLoad

# Set by selector (Objective-C)
(lldb) breakpoint set --selector tableView:cellForRowAtIndexPath:
(lldb) br s -S tableView:cellForRowAtIndexPath:

# Delete breakpoint
(lldb) breakpoint delete 1
(lldb) br del 1

# Disable/enable
(lldb) breakpoint disable 1
(lldb) breakpoint enable 1
```

**Conditional Breakpoints**:
```lldb
# Set condition
(lldb) breakpoint set --name fetchUser --condition 'userId == "12345"'

# Modify existing breakpoint
(lldb) breakpoint modify 1 --condition 'count > 100'

# Ignore count (skip first N hits)
(lldb) breakpoint modify 1 --ignore-count 5
```

**Thread Commands**:
```lldb
# List threads
(lldb) thread list
(lldb) th l

# Show backtrace
(lldb) thread backtrace
(lldb) bt

# Backtrace all threads
(lldb) thread backtrace all
(lldb) bt all

# Select thread
(lldb) thread select 2
(lldb) th s 2

# Step commands
(lldb) thread step-over  # F6
(lldb) thread step-into  # F7
(lldb) thread step-out   # F8
(lldb) thread continue   # ⌃⌘Y
```

### Advanced LLDB

**Watchpoints**:
```lldb
# Watch variable for writes
(lldb) watchpoint set variable self.count
(lldb) w s v self.count

# Watch memory address
(lldb) watchpoint set expression -- &self.count

# List watchpoints
(lldb) watchpoint list

# Delete watchpoint
(lldb) watchpoint delete 1
```

**View Debugging**:
```lldb
# Print view hierarchy (UIKit)
(lldb) po self.view.recursiveDescription()

# Print view hierarchy (SwiftUI - requires private APIs)
(lldb) expr import SwiftUI
(lldb) expr -l objc++ -O -- [[[UIApplication sharedApplication] windows] firstObject]

# Constraint debugging
(lldb) po [[UIWindow keyWindow] _autolayoutTrace]

# Print layer tree
(lldb) po self.view.layer.recursiveDescription()
```

**Chisel (Facebook's LLDB Extensions)**:
```bash
# Install via Homebrew
brew install chisel

# Add to ~/.lldbinit
command script import /usr/local/opt/chisel/libexec/fbchisellldb.py

# Commands
(lldb) pviews          # Print view hierarchy
(lldb) pvc             # Print view controller hierarchy
(lldb) visualize self.view  # Open view in Preview.app
(lldb) border self.view 1.0 0 0 1  # Add red border
(lldb) mask self.imageView  # Show which view is blocking taps
```

### LLDB Aliases

**Create Shortcuts**:
```lldb
# In ~/.lldbinit
command alias bd breakpoint disable
command alias be breakpoint enable
command alias bl breakpoint list
command alias bda breakpoint delete

# Usage
(lldb) bd 1   # Disable breakpoint 1
(lldb) bda    # Delete all breakpoints
```

**Custom Commands**:
```python
# In ~/.lldbinit

# Command to print UserDefaults
command regex ud 's/(.+)/po UserDefaults.standard.object(forKey: "%1")/'

# Usage:
(lldb) ud authToken
# Expands to: po UserDefaults.standard.object(forKey: "authToken")

# Command to print view frame
command regex frame 's/(.+)/po %1.frame/'

# Usage:
(lldb) frame self.view
# Expands to: po self.view.frame
```

---

## Xcode Instruments

### Available Instruments

| Instrument | Purpose | Use Case |
|------------|---------|----------|
| Time Profiler | CPU usage analysis | Find slow code paths |
| Allocations | Memory allocation tracking | Find memory bloat |
| Leaks | Memory leak detection | Find retain cycles |
| Zombies | Deallocated object access | Find use-after-free bugs |
| System Trace | System-level performance | Find thread contention |
| Network | Network activity | Analyze API calls |
| Energy Log | Battery usage | Optimize power consumption |
| Core Data | Core Data performance | Optimize database queries |
| SwiftUI | SwiftUI view updates | Debug view rendering |
| Metal System Trace | GPU performance | Optimize graphics rendering |

### Instruments Workflow

**1. Profile Application**:
```bash
# Xcode → Product → Profile (⌘I)
# Select instrument template
# Click Record (red button)
# Perform operations to profile
# Click Stop
```

**2. Analyze Results**:
- Timeline: See when events occurred
- Detail Pane: Inspect specific events
- Call Tree: See function call hierarchy
- Statistics: View aggregate metrics

**3. Filter and Focus**:
- Filter by time range (drag in timeline)
- Filter by thread
- Filter by category
- Focus on specific symbol

**4. Mark Generations** (for Allocations/Leaks):
- Click "Mark Generation"
- Perform operation (e.g., open/close view)
- Click "Mark Generation" again
- Compare generations to see what wasn't released

### Custom Instruments

**Add Signposts**:
```swift
import os.signpost

let log = OSLog(subsystem: "com.yourapp", category: "Networking")

func fetchData() {
    os_signpost(.begin, log: log, name: "Fetch Data", "userId: %{public}s", userId)

    // Perform network request

    os_signpost(.end, log: log, name: "Fetch Data")
}
```

**View in Instruments**:
1. Profile with "Blank" template
2. Add "os_signpost" instrument
3. Filter by subsystem: "com.yourapp"
4. See custom events in timeline

---

## Agent Coordination

### Phase 1: Reproduce & Triage

**Goal**: Reliably reproduce the issue and gather initial data

**Agents**:
- **workflow-orchestrator**: Coordinates entire debug flow
- **codebase-inspector**: Analyzes recent code changes that might have introduced bug

**Steps**:
1. User provides bug description
2. workflow-orchestrator creates investigation plan
3. codebase-inspector reviews recent commits/PRs related to affected area
4. Document reproduction steps
5. Identify affected platform (iOS, tvOS, or both)
6. Determine severity (crash, data loss, UI glitch, performance)

**Output**:
- Reproduction steps documented
- Initial hypothesis about cause
- Affected code area identified
- Severity classification

---

### Phase 2: Gather Data & Analyze

**Goal**: Collect diagnostic data using appropriate tools

**Agents**:
- **log-analyzer**: Analyzes crash logs, console output, system logs
- **file-finder**: Locates source files from stack traces

**Steps**:
1. Choose appropriate debugging tool based on issue type:
   - Crash → Crash logs + symbolication
   - Memory → Instruments Leaks/Allocations
   - Performance → Time Profiler
   - Network → Charles Proxy/Proxyman
   - UI → View Debugger

2. log-analyzer extracts relevant information:
   ```bash
   # Analyze crash log
   bd create --type task \
     --title "Analyze crash log for EXC_BAD_ACCESS" \
     --description "Extract stack trace and identify crashing line"

   # Parse console logs
   bd create --type task \
     --title "Parse console for error messages" \
     --description "Filter logs for ERROR/WARNING levels"
   ```

3. file-finder locates source files:
   ```bash
   # Find file from stack trace
   bd create --type task \
     --title "Locate UserViewModel.swift:145" \
     --description "Find source file referenced in crash"
   ```

**Output**:
- Crash logs symbolicated
- Relevant source files identified
- Diagnostic data collected
- Initial analysis completed

---

### Phase 3: Isolate Cause

**Goal**: Narrow down root cause to specific code

**Agents**:
- **codebase-inspector**: Analyzes code patterns, recent changes
- **core-lead**: Investigates Core layer issues (services, networking)
- **presentation-lead**: Investigates UI/ViewModel issues
- **test-oracle**: Checks if existing tests cover this scenario

**Steps**:
1. codebase-inspector examines code in affected area:
   ```bash
   bd create --type task \
     --title "Analyze UserViewModel for retain cycles" \
     --description "Check for strong reference cycles in closures"
   ```

2. Specialist lead investigates based on layer:
   - Core issues → core-lead
   - UI issues → presentation-lead
   - Design system → design-system-lead

3. test-oracle verifies test coverage:
   ```bash
   bd create --type task \
     --title "Check test coverage for UserViewModel" \
     --description "Verify if crash scenario is tested"
   ```

**Output**:
- Root cause identified (specific line/function)
- Understanding of why bug occurs
- Related code areas that might have same issue

---

### Phase 4: Hypothesize & Test Fix

**Goal**: Develop and test potential fix

**Agents**:
- **Specialist leads**: Propose fixes based on expertise
- **test-oracle**: Creates regression test

**Steps**:
1. Specialist proposes fix:
   ```swift
   // Current (crashing)
   let user = viewModel.users.first!

   // Proposed fix
   guard let user = viewModel.users.first else {
       logger.error("No users available")
       return
   }
   ```

2. test-oracle creates regression test:
   ```swift
   func test_userList_whenEmpty_doesNotCrash() {
       // Given
       let viewModel = UserListViewModel()
       viewModel.users = []

       // When/Then (should not crash)
       XCTAssertNoThrow(viewModel.selectFirstUser())
   }
   ```

3. Test fix locally:
   - Run regression test (should fail before fix)
   - Apply fix
   - Re-run test (should pass)
   - Manual testing of original reproduction steps

**Output**:
- Fix implemented
- Regression test created
- Fix verified locally

---

### Phase 5: Implement Fix

**Goal**: Apply fix across codebase, ensure no regressions

**Agents**:
- **implementation-executor**: Coordinates fix implementation
- **quality-guardian**: Validates fix meets quality gates

**Steps**:
1. implementation-executor applies fix:
   - Update affected files
   - Add defensive code where needed
   - Update error handling

2. quality-guardian runs validation:
   ```bash
   # SwiftLint
   swiftlint lint --strict

   # Build
   xcodebuild clean build -scheme MyApp

   # Tests
   xcodebuild test -scheme MyApp -enableCodeCoverage YES

   # Coverage (ensure no decrease)
   xcov --minimum_coverage_percentage 80.0
   ```

**Output**:
- Fix applied to all affected areas
- Quality gates passed
- Ready for code review

---

### Phase 6: Verify & Deploy

**Goal**: Final verification and deployment

**Agents**:
- **test-oracle**: Runs full test suite
- **workflow-orchestrator**: Creates deployment tasks

**Steps**:
1. Run comprehensive tests:
   - Unit tests (all pass)
   - Integration tests (all pass)
   - UI tests (regression scenarios)

2. Create deployment tasks:
   ```bash
   bd create --type epic \
     --title "Deploy fix for crash on app launch" \
     --description "Deploy v1.2.1 with crash fix"

   bd create --type task \
     --title "Merge fix to main branch" \
     --deps "TEST-123"  # Depends on tests passing

   bd create --type task \
     --title "Create release build" \
     --deps "MERGE-456"

   bd create --type task \
     --title "Submit to TestFlight" \
     --deps "BUILD-789"
   ```

**Output**:
- All tests passing
- Fix merged to main
- Build released to TestFlight
- Monitoring in place for regression

---

## Debugging Examples

### Example 1: Debug Crash on App Launch

**Scenario**: App crashes immediately on launch with `EXC_BAD_ACCESS`

**Reproduction Steps**:
1. Launch app on iOS Simulator
2. App crashes before UI appears
3. Crash occurs consistently

**Phase 1: Reproduce & Triage**

```bash
# Launch workflow
/ios-debug app crashes on launch with EXC_BAD_ACCESS

# workflow-orchestrator creates tasks
bd create --type epic --title "Debug crash on app launch"

bd create --type task --title "Gather crash log" \
  --description "Extract crash log from simulator" \
  --priority 1

bd create --type task --title "Symbolicate crash" \
  --description "Symbolicate to identify crashing line" \
  --deps "CRASH-001" --priority 1
```

**Phase 2: Gather Data & Analyze**

```bash
# log-analyzer extracts crash log
~/Library/Logs/DiagnosticReports/MyApp_2024-01-15_crash.crash

# Symbolicate
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
symbolicatecrash MyApp_2024-01-15_crash.crash MyApp.app.dSYM > symbolicated.crash

# Analyze symbolicated crash
Exception Type:  EXC_BAD_ACCESS (SIGSEGV)
Exception Subtype: KERN_INVALID_ADDRESS at 0x0000000000000008

Thread 0 Crashed:
0   MyApp         0x100e52c60 AppDelegate.application(_:didFinishLaunchingWithOptions:) + 64
1   UIKitCore     0x7fff2e4a2180 -[UIApplication _run] + 890
```

**Analysis**: Crash in `AppDelegate.application(_:didFinishLaunchingWithOptions:)` on line 64, accessing invalid memory address.

**Phase 3: Isolate Cause**

```bash
# file-finder locates AppDelegate.swift
# codebase-inspector analyzes code at line 64

# Read AppDelegate.swift
```

```swift
// AppDelegate.swift:60-70
func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

    // Configure Firebase
    FirebaseApp.configure()

    // Initialize session manager
    let sessionManager = SessionManager.shared  // Line 64 - CRASH HERE
    sessionManager.restoreSession()

    return true
}
```

**Root Cause Found**: `SessionManager.shared` is force-unwrapping a dependency in its initializer:

```swift
class SessionManager {
    static let shared = SessionManager()

    private let keychainManager: KeychainManager

    init() {
        self.keychainManager = KeychainManager.shared!  // ❌ Force unwrap crashes if nil
    }
}
```

**Phase 4: Hypothesize & Test Fix**

**Proposed Fix**:
```swift
class SessionManager {
    static let shared = SessionManager()

    private let keychainManager: KeychainManager

    init() {
        // ✅ Use guard with early exit
        guard let manager = KeychainManager.shared else {
            fatalError("KeychainManager must be initialized before SessionManager")
        }
        self.keychainManager = manager
    }
}

// Better: Initialize in correct order
// In AppDelegate:
func application(...) -> Bool {
    FirebaseApp.configure()

    // Initialize KeychainManager first
    _ = KeychainManager.shared

    // Then SessionManager
    let sessionManager = SessionManager.shared
    sessionManager.restoreSession()

    return true
}
```

**Create Regression Test**:
```swift
func test_sessionManager_initialization_doesNotCrash() {
    // Given: Clean state

    // When: SessionManager is accessed
    let sessionManager = SessionManager.shared

    // Then: Should not crash
    XCTAssertNotNil(sessionManager)
}
```

**Phase 5: Implement Fix**

```bash
# Apply fix
# Edit AppDelegate.swift to initialize in correct order
# Edit SessionManager.swift to add guard statement

# quality-guardian validates
swiftlint lint --strict  # ✅ Pass
xcodebuild clean build -scheme MyApp  # ✅ Pass
xcodebuild test -scheme MyApp  # ✅ All tests pass
```

**Phase 6: Verify & Deploy**

```bash
# Manual test
# Launch app → ✅ No crash

# Create PR
git checkout -b fix/session-manager-crash
git add AppDelegate.swift SessionManager.swift SessionManagerTests.swift
git commit -m "Fix crash on app launch due to SessionManager initialization order"
git push origin fix/session-manager-crash

# Deploy tasks
bd create --type task --title "Merge PR to main"
bd create --type task --title "Release v1.2.1 to TestFlight"
```

**Result**: Crash fixed, regression test added, deployed to TestFlight.

---

### Example 2: Debug Memory Leak in UserViewModel

**Scenario**: Memory usage grows unbounded when navigating to/from user profile

**Reproduction Steps**:
1. Navigate to User Profile screen
2. Navigate back to Home
3. Repeat 10 times
4. Memory usage increases from 50 MB → 200 MB

**Phase 1: Reproduce & Triage**

```bash
/ios-debug memory leak when navigating to user profile

# workflow-orchestrator classifies as memory issue
bd create --type epic --title "Debug memory leak in UserViewModel"

bd create --type task --title "Profile with Instruments Leaks" \
  --priority 1
```

**Phase 2: Gather Data & Analyze**

```bash
# Run Instruments → Leaks
# Xcode → Product → Profile → Leaks
# Navigate to User Profile 5 times
# Observe leaks in timeline

# Leaks Report:
# 5 instances of UserViewModel leaked (88 KB each)
# 5 instances of UserProfileView leaked (24 KB each)
# Total leaked: 560 KB

# Analyze leak backtrace:
# UserViewModel allocated in UserProfileView.init()
# Never deallocated
```

**Phase 3: Isolate Cause**

```bash
# codebase-inspector analyzes UserProfileView and UserViewModel
# presentation-lead investigates retain cycle
```

**Read UserProfileView.swift**:
```swift
struct UserProfileView: View {
    @StateObject var viewModel: UserViewModel

    init(userId: String) {
        _viewModel = StateObject(wrappedValue: UserViewModel(userId: userId))
    }

    var body: some View {
        VStack {
            Text(viewModel.user?.name ?? "Loading...")
        }
        .onAppear {
            viewModel.loadUser()
        }
    }
}
```

**Read UserViewModel.swift**:
```swift
class UserViewModel: ObservableObject {
    @Published var user: User?

    private let userId: String
    private let userService: UserService

    var onUserLoaded: (() -> Void)?  // ❌ Potential issue

    init(userId: String) {
        self.userId = userId
        self.userService = UserService.shared

        // ❌ RETAIN CYCLE: Closure captures self strongly
        self.onUserLoaded = {
            self.logUserActivity()  // Strong reference to self
        }
    }

    func loadUser() async {
        self.user = try? await userService.fetchUser(id: userId)
        onUserLoaded?()
    }
}
```

**Root Cause**: `onUserLoaded` closure captures `self` strongly, creating a retain cycle (`self` → `onUserLoaded` → `self`).

**Phase 4: Hypothesize & Test Fix**

**Proposed Fix**:
```swift
class UserViewModel: ObservableObject {
    @Published var user: User?

    private let userId: String
    private let userService: UserService

    var onUserLoaded: (() -> Void)?

    init(userId: String) {
        self.userId = userId
        self.userService = UserService.shared

        // ✅ FIX: Use weak self
        self.onUserLoaded = { [weak self] in
            self?.logUserActivity()
        }
    }

    func loadUser() async {
        self.user = try? await userService.fetchUser(id: userId)
        onUserLoaded?()
    }

    // ✅ Add deinit to verify deallocation
    deinit {
        print("✅ UserViewModel deallocated")
    }
}
```

**Create Memory Test**:
```swift
func test_userViewModel_deallocatesWhenViewDismissed() {
    // Given
    var viewModel: UserViewModel? = UserViewModel(userId: "123")

    weak var weakViewModel = viewModel

    // When
    viewModel = nil

    // Then
    XCTAssertNil(weakViewModel, "ViewModel should be deallocated")
}
```

**Phase 5: Implement Fix**

```bash
# Apply fix
# Edit UserViewModel.swift with [weak self]

# quality-guardian validates
swiftlint lint --strict  # ✅ Pass
xcodebuild test -scheme MyApp  # ✅ Pass

# Re-profile with Instruments
# Navigate 10 times → ✅ No leaks detected
# Memory stable at 55 MB
```

**Phase 6: Verify & Deploy**

```bash
# Verify deinit called
# Navigate to User Profile → "✅ UserViewModel deallocated" in console

# Deploy
git commit -m "Fix memory leak in UserViewModel retain cycle"
bd close LEAK-001 --reason "Fixed retain cycle with weak self"
```

**Result**: Memory leak fixed, memory usage stable, deinit verification added.

---

### Example 3: Debug Network Timeout

**Scenario**: API calls timeout after 30 seconds

**Reproduction Steps**:
1. Launch app
2. Trigger user profile fetch
3. Request times out after 30s with error "The request timed out"

**Phase 1: Reproduce & Triage**

```bash
/ios-debug API calls timeout after 30 seconds

bd create --type epic --title "Debug network timeout issue"

bd create --type task --title "Capture network traffic with Charles" \
  --priority 1
```

**Phase 2: Gather Data & Analyze**

```bash
# Set up Charles Proxy
# Configure iOS Simulator proxy: localhost:8888
# Filter: api.example.com

# Capture traffic:
# Request URL: https://api.example.com/v1/users/12345
# Method: GET
# Headers: Authorization: Bearer <token>
# Status: -1 (timeout, no response)
```

**Enable Network Logging**:
```swift
// Add to UserService
func fetchUser(id: String) async throws -> User {
    let url = URL(string: "https://api.example.com/v1/users/\(id)")!

    print("🌐 Fetching user: \(url.absoluteString)")
    print("   Timeout: \(URLSession.shared.configuration.timeoutIntervalForRequest)")

    let (data, response) = try await URLSession.shared.data(from: url)

    print("📡 Response: \((response as? HTTPURLResponse)?.statusCode ?? -1)")

    return try JSONDecoder().decode(User.self, from: data)
}
```

**Console Output**:
```
🌐 Fetching user: https://api.example.com/v1/users/12345
   Timeout: 30.0
...30 seconds later...
❌ Error: The request timed out.
```

**Charles Shows**:
- Request sent at 10:30:00
- No response from server
- Connection closed at 10:30:30 (timeout)

**Hypothesis**: Server is slow or not responding. Check server logs.

**Phase 3: Isolate Cause**

```bash
# Check API server logs
# core-lead investigates network layer
```

**API Server Logs**:
```
[ERROR] Database connection pool exhausted
[ERROR] Waiting for available connection...
[ERROR] Request /v1/users/12345 waiting in queue
```

**Root Cause**: Backend database connection pool is saturated, causing requests to queue indefinitely.

**Phase 4: Hypothesize & Test Fix**

**Short-term Fix** (iOS app):
```swift
// Increase timeout for problematic endpoint
func fetchUser(id: String) async throws -> User {
    let url = URL(string: "https://api.example.com/v1/users/\(id)")!

    var request = URLRequest(url: url)
    request.timeoutInterval = 60.0  // Increase from 30s to 60s

    let (data, _) = try await URLSession.shared.data(for: request)
    return try JSONDecoder().decode(User.self, from: data)
}
```

**Better Fix** (iOS app with retry):
```swift
func fetchUser(id: String, retryCount: Int = 3) async throws -> User {
    var lastError: Error?

    for attempt in 1...retryCount {
        do {
            let url = URL(string: "https://api.example.com/v1/users/\(id)")!
            var request = URLRequest(url: url)
            request.timeoutInterval = 45.0

            let (data, _) = try await URLSession.shared.data(for: request)
            return try JSONDecoder().decode(User.self, from: data)

        } catch {
            lastError = error

            if attempt < retryCount {
                let delay = TimeInterval(attempt * 2)  // Exponential backoff
                print("⚠️ Attempt \(attempt) failed, retrying in \(delay)s...")
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            }
        }
    }

    throw lastError ?? NetworkError.unknown
}
```

**Long-term Fix** (Backend):
- Increase database connection pool size
- Add caching layer (Redis)
- Optimize slow queries

**Phase 5: Implement Fix**

```bash
# Apply iOS fix
# Edit UserService.swift with retry logic

# quality-guardian validates
xcodebuild test -scheme MyApp  # ✅ Pass

# Test with Network Link Conditioner
# Settings → Developer → Network Link Conditioner → 3G
# Fetch user → ✅ Succeeds after 1 retry
```

**Phase 6: Verify & Deploy**

```bash
# Coordinate with backend team for long-term fix
bd create --type task --title "Backend: Increase DB connection pool" \
  --assignee "backend-team"

bd create --type task --title "Backend: Add Redis caching for user endpoint" \
  --assignee "backend-team"

# Deploy iOS fix
git commit -m "Add retry logic for network timeout on user fetch"
bd close NETWORK-001 --reason "Added retry with exponential backoff"
```

**Result**: Network timeouts reduced, graceful retry implemented, backend team notified.

---

### Example 4: Debug SwiftUI View Not Updating

**Scenario**: User list doesn't update after adding a new user

**Reproduction Steps**:
1. View user list (shows 3 users)
2. Tap "Add User" button
3. New user is created on backend (verified in logs)
4. UI doesn't refresh (still shows 3 users)
5. Navigating away and back shows 4 users

**Phase 1: Reproduce & Triage**

```bash
/ios-debug SwiftUI view not updating when data changes

bd create --type epic --title "Debug SwiftUI view update issue"

bd create --type task --title "Analyze UserListView and ViewModel" \
  --priority 1
```

**Phase 2: Gather Data & Analyze**

```swift
// presentation-lead reads UserListView.swift
struct UserListView: View {
    @StateObject var viewModel = UserListViewModel()  // ✅ Correct

    var body: some View {
        List {
            ForEach(viewModel.users) { user in  // ❌ Missing id?
                UserRow(user: user)
            }
        }
        .onAppear {
            Task {
                await viewModel.loadUsers()
            }
        }
        .toolbar {
            Button("Add User") {
                Task {
                    await viewModel.addUser()
                }
            }
        }
    }
}

// Read UserListViewModel.swift
class UserListViewModel: ObservableObject {
    @Published var users: [User] = []  // ✅ @Published correct

    private let userService: UserService

    init(userService: UserService = UserService.shared) {
        self.userService = userService
    }

    func loadUsers() async {
        do {
            let fetchedUsers = try await userService.fetchAllUsers()
            self.users = fetchedUsers  // ❌ May be on background thread
        } catch {
            print("Error loading users: \(error)")
        }
    }

    func addUser() async {
        do {
            let newUser = User(id: UUID().uuidString, name: "New User")
            _ = try await userService.createUser(newUser)

            // ❌ Problem: Not updating users array
            // Should be: await loadUsers()

        } catch {
            print("Error adding user: \(error)")
        }
    }
}
```

**Root Cause 1**: `addUser()` creates user on backend but doesn't reload the `users` array.

**Root Cause 2**: `loadUsers()` updates `self.users` potentially on background thread (not guaranteed to be on main thread with async).

**Phase 3: Isolate Cause**

```bash
# Add debug prints
```

```swift
func loadUsers() async {
    print("⏳ Loading users...")
    print("   Current thread: \(Thread.current)")

    do {
        let fetchedUsers = try await userService.fetchAllUsers()

        print("📦 Fetched \(fetchedUsers.count) users")
        print("   Current thread: \(Thread.current)")

        self.users = fetchedUsers

        print("✅ Users updated")
    } catch {
        print("❌ Error loading users: \(error)")
    }
}

func addUser() async {
    print("➕ Adding user...")

    do {
        let newUser = User(id: UUID().uuidString, name: "New User")
        _ = try await userService.createUser(newUser)

        print("✅ User created on backend")
        print("   Users array count: \(users.count)")  // Still 3

        // Missing: reload users

    } catch {
        print("❌ Error adding user: \(error)")
    }
}
```

**Console Output**:
```
⏳ Loading users...
   Current thread: <_NSMainThread: 0x600...>
📦 Fetched 3 users
   Current thread: <NSThread: 0x600...>  ❌ Background thread!
✅ Users updated

➕ Adding user...
✅ User created on backend
   Users array count: 3  ❌ Not reloaded
```

**Issues Confirmed**:
1. `addUser()` doesn't reload users after creating
2. `loadUsers()` updates `users` on background thread (may not trigger SwiftUI update)

**Phase 4: Hypothesize & Test Fix**

**Proposed Fix**:
```swift
@MainActor
class UserListViewModel: ObservableObject {
    @Published var users: [User] = []

    private let userService: UserService

    init(userService: UserService = UserService.shared) {
        self.userService = userService
    }

    // ✅ @MainActor ensures all methods run on main thread
    func loadUsers() async {
        do {
            let fetchedUsers = try await userService.fetchAllUsers()
            self.users = fetchedUsers  // Guaranteed on main thread
        } catch {
            print("Error loading users: \(error)")
        }
    }

    // ✅ Reload users after adding
    func addUser() async {
        do {
            let newUser = User(id: UUID().uuidString, name: "New User")
            _ = try await userService.createUser(newUser)

            await loadUsers()  // ✅ Reload

        } catch {
            print("Error adding user: \(error)")
        }
    }
}
```

**Alternative Fix** (explicit MainActor):
```swift
func loadUsers() async {
    do {
        let fetchedUsers = try await userService.fetchAllUsers()

        // ✅ Explicitly update on main thread
        await MainActor.run {
            self.users = fetchedUsers
        }
    } catch {
        print("Error loading users: \(error)")
    }
}

func addUser() async {
    do {
        let newUser = User(id: UUID().uuidString, name: "New User")
        _ = try await userService.createUser(newUser)

        await loadUsers()  // ✅ Reload

    } catch {
        print("Error adding user: \(error)")
    }
}
```

**Phase 5: Implement Fix**

```bash
# Apply fix
# Edit UserListViewModel.swift with @MainActor and reload

# Test
# Tap "Add User" → ✅ UI updates immediately (4 users shown)

# quality-guardian validates
xcodebuild test -scheme MyApp  # ✅ Pass
```

**Phase 6: Verify & Deploy**

```bash
# Create regression test
```

```swift
@MainActor
func test_userList_afterAddingUser_updatesUI() async {
    // Given
    let viewModel = UserListViewModel()
    await viewModel.loadUsers()

    let initialCount = viewModel.users.count

    // When
    await viewModel.addUser()

    // Then
    XCTAssertEqual(viewModel.users.count, initialCount + 1)
}
```

```bash
# Deploy
git commit -m "Fix SwiftUI view not updating: use @MainActor and reload after add"
bd close SWIFTUI-001 --reason "Fixed with @MainActor and reload logic"
```

**Result**: UI now updates correctly when user is added.

---

### Example 5: Debug Navigation Stack Issues

**Scenario**: After presenting modal and dismissing, navigation back button doesn't work

**Reproduction Steps**:
1. Navigate from Home → Settings
2. Tap "Edit Profile" (presents modal)
3. Dismiss modal
4. Tap back button in Settings
5. Back button doesn't work (app stuck on Settings screen)

**Phase 1: Reproduce & Triage**

```bash
/ios-debug navigation stack issues after modal dismiss

bd create --type epic --title "Debug navigation stack corruption"

bd create --type task --title "Analyze NavigationStack usage" \
  --priority 1
```

**Phase 2: Gather Data & Analyze**

**View Hierarchy**:
```swift
// App.swift
@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            NavigationStack {  // ✅ Root navigation
                HomeView()
            }
        }
    }
}

// HomeView.swift
struct HomeView: View {
    var body: some View {
        VStack {
            NavigationLink("Settings") {
                SettingsView()  // ✅ Push to SettingsView
            }
        }
        .navigationTitle("Home")
    }
}

// SettingsView.swift
struct SettingsView: View {
    @State private var showEditProfile = false

    var body: some View {
        VStack {
            Button("Edit Profile") {
                showEditProfile = true
            }
        }
        .navigationTitle("Settings")
        .sheet(isPresented: $showEditProfile) {
            EditProfileView()  // ✅ Modal presentation
        }
    }
}

// EditProfileView.swift
struct EditProfileView: View {
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {  // ❌ PROBLEM: Nested NavigationStack
            VStack {
                Text("Edit Profile")

                Button("Save") {
                    dismiss()
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarItems(trailing: Button("Cancel") {
                dismiss()
            })
        }
    }
}
```

**Root Cause**: `EditProfileView` creates a nested `NavigationStack` inside a sheet, which can interfere with the parent `NavigationStack` when dismissed.

**Phase 3: Isolate Cause**

**Enable Navigation Debugging**:
```swift
// Add to App.swift
init() {
    #if DEBUG
    print("Navigation debugging enabled")
    #endif
}

// Add to each view
.onAppear {
    print("✅ \(Self.self) appeared")
}
.onDisappear {
    print("❌ \(Self.self) disappeared")
}
```

**Console Output**:
```
✅ HomeView appeared
✅ SettingsView appeared
✅ EditProfileView appeared
❌ EditProfileView disappeared
❌ SettingsView disappeared  ❌ Problem: SettingsView shouldn't disappear
✅ SettingsView appeared  ❌ Problem: Re-appears, but navigation broken
```

**Analysis**: When modal dismisses, `SettingsView` briefly disappears and re-appears, corrupting navigation state.

**Phase 4: Hypothesize & Test Fix**

**Proposed Fix** (remove nested NavigationStack):
```swift
struct EditProfileView: View {
    @Environment(\.dismiss) var dismiss

    var body: some View {
        // ✅ No NavigationStack, just VStack
        VStack {
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                Spacer()
                Text("Edit Profile")
                    .font(.headline)
                Spacer()
                Button("Save") {
                    dismiss()
                }
            }
            .padding()

            Form {
                // Profile editing UI
            }
        }
    }
}
```

**Alternative Fix** (use navigationBarTitleDisplayMode):
```swift
struct EditProfileView: View {
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            VStack {
                Text("Edit Profile")
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)  // ✅ Inline mode
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])  // ✅ Partial sheet
    }
}
```

**Phase 5: Implement Fix**

```bash
# Apply fix (Option 1: Remove nested NavigationStack)

# Test navigation
# Home → Settings → Edit Profile (modal) → Dismiss → Back → ✅ Works!

# quality-guardian validates
xcodebuild test -scheme MyApp  # ✅ Pass
```

**Phase 6: Verify & Deploy**

```bash
# Create UI test
```

```swift
func testUI_navigationAfterModalDismiss_worksCorrectly() {
    let app = XCUIApplication()
    app.launch()

    // Navigate to Settings
    app.buttons["Settings"].tap()
    XCTAssertTrue(app.navigationBars["Settings"].exists)

    // Present modal
    app.buttons["Edit Profile"].tap()
    XCTAssertTrue(app.staticTexts["Edit Profile"].exists)

    // Dismiss modal
    app.buttons["Cancel"].tap()
    XCTAssertFalse(app.staticTexts["Edit Profile"].exists)

    // Navigate back
    app.navigationBars.buttons.element(boundBy: 0).tap()

    // Should be back on Home
    XCTAssertTrue(app.navigationBars["Home"].exists)
}
```

```bash
# Deploy
git commit -m "Fix navigation stack corruption by removing nested NavigationStack in modal"
bd close NAV-001 --reason "Fixed nested NavigationStack issue"
```

**Result**: Navigation works correctly after modal dismissal.

---

### Example 6: Debug tvOS Focus Issues

**Scenario**: Custom button doesn't receive focus on tvOS

**Reproduction Steps**:
1. Launch app on tvOS simulator
2. Navigate to Settings screen
3. Custom "Delete Account" button doesn't receive focus
4. Cannot select button with remote

**Phase 1: Reproduce & Triage**

```bash
/ios-debug tvOS focus not working on custom button

bd create --type epic --title "Debug tvOS focus engine issue"

bd create --type task --title "Analyze focus environment" \
  --priority 1
```

**Phase 2: Gather Data & Analyze**

```swift
// Read SettingsView.swift
struct SettingsView: View {
    var body: some View {
        VStack {
            Button("Logout") {
                // Logout action
            }
            .buttonStyle(.plain)  // ✅ Focusable

            // Custom button
            DeleteAccountButton()  // ❌ Not focusable
        }
    }
}

// Read DeleteAccountButton.swift
struct DeleteAccountButton: View {
    var body: some View {
        VStack {
            Image(systemName: "trash")
            Text("Delete Account")
        }
        .frame(width: 300, height: 100)
        .background(Color.red)
        .cornerRadius(12)
        .onTapGesture {  // ❌ Problem: onTapGesture not focusable
            deleteAccount()
        }
    }

    func deleteAccount() {
        print("Delete account")
    }
}
```

**Root Cause**: `onTapGesture` doesn't make view focusable on tvOS. Need to use `Button` or add `.focusable()` modifier.

**Phase 3: Isolate Cause**

**Enable Focus Debugging**:
```swift
// Add to App.swift
init() {
    #if os(tvOS)
    UIView.enableFocusLogging = true
    #endif
}
```

**Console Output**:
```
Focus moved to: <Button: Logout>
Focus cannot move to: DeleteAccountButton (not focusable)
```

**Phase 4: Hypothesize & Test Fix**

**Fix Option 1** (use Button):
```swift
struct DeleteAccountButton: View {
    var body: some View {
        Button {
            deleteAccount()
        } label: {
            VStack {
                Image(systemName: "trash")
                Text("Delete Account")
            }
            .frame(width: 300, height: 100)
            .background(Color.red)
            .cornerRadius(12)
        }
        .buttonStyle(.plain)  // ✅ Focusable
    }

    func deleteAccount() {
        print("Delete account")
    }
}
```

**Fix Option 2** (add focusable modifier):
```swift
struct DeleteAccountButton: View {
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack {
            Image(systemName: "trash")
            Text("Delete Account")
        }
        .frame(width: 300, height: 100)
        .background(isFocused ? Color.red.opacity(0.8) : Color.red)
        .cornerRadius(12)
        .focusable()  // ✅ Makes view focusable
        .focused($isFocused)  // ✅ Tracks focus state
        .onTapGesture {
            deleteAccount()
        }
    }

    func deleteAccount() {
        print("Delete account")
    }
}
```

**Phase 5: Implement Fix**

```bash
# Apply Fix Option 1 (simpler)

# Test on tvOS simulator
# Navigate to Settings → ✅ Focus moves to Delete Account button
# Press Select → ✅ Delete account action triggered

# quality-guardian validates
xcodebuild test -scheme MyApp-tvOS  # ✅ Pass
```

**Phase 6: Verify & Deploy**

```bash
# Create UI test for tvOS
```

```swift
func testTVOS_deleteAccountButton_isFocusable() {
    let app = XCUIApplication()
    app.launch()

    // Navigate to Settings
    let settingsButton = app.buttons["Settings"]
    settingsButton.tap()

    // Focus should move to Delete Account button
    let deleteButton = app.buttons["Delete Account"]
    XCTAssertTrue(deleteButton.hasFocus)
}
```

```bash
# Deploy
git commit -m "Fix tvOS focus on Delete Account button by using Button instead of onTapGesture"
bd close TVOS-001 --reason "Fixed focus issue with Button wrapper"
```

**Result**: Button now receives focus on tvOS and is selectable.

---

## Best Practices

### 1. Reproduce Reliably

**Why**: Can't fix what you can't reproduce

**How**:
- Document exact steps to trigger bug
- Identify data conditions (empty lists, nil values, specific IDs)
- Test across devices and OS versions
- Use Network Link Conditioner for network issues
- Create automated tests for reproduction

```swift
// ✅ Good: Automated reproduction test
func test_crash_whenUsersEmpty_reproducesIssue() {
    let viewModel = UserListViewModel()
    viewModel.users = []  // Data condition

    // This should reproduce the crash
    XCTAssertNoThrow(viewModel.selectFirstUser())
}
```

---

### 2. Start Simple, Escalate Tools

**Why**: Save time by using simplest tool first

**Debugging Ladder**:
1. **Print debugging** - `print()`, `dump()`, `Self._printChanges()`
2. **Breakpoints** - Standard breakpoints, conditional breakpoints
3. **LLDB** - `po`, `p`, `expr` commands
4. **Instruments** - Leaks, Allocations, Time Profiler
5. **Specialized tools** - Charles Proxy, Accessibility Inspector
6. **Static analysis** - SwiftLint, Xcode warnings

```swift
// ✅ Level 1: Simple print
func fetchUser() {
    print("Fetching user...")
    // ...
}

// ✅ Level 2: Conditional breakpoint at suspicious line
// Set breakpoint with condition: userId == "12345"

// ✅ Level 3: LLDB investigation
// (lldb) po self.viewModel.users.map { $0.id }

// ✅ Level 4: Profile with Instruments if still unclear
```

---

### 3. Use Version Control for Debugging

**Why**: Isolate when bug was introduced

**Techniques**:
```bash
# Binary search for bug introduction
git bisect start
git bisect bad HEAD  # Current version has bug
git bisect good v1.2.0  # v1.2.0 didn't have bug
# Test each commit git suggests

# View file at specific commit
git show abc1234:UserViewModel.swift

# Compare with last working version
git diff v1.2.0..HEAD -- UserViewModel.swift

# Blame to see who changed line
git blame -L 145,145 UserViewModel.swift
```

---

### 4. Test Edge Cases

**Why**: Bugs often lurk in edge cases

**Common Edge Cases**:
- Empty lists/arrays
- Nil values
- Zero values
- Very large numbers
- Very long strings
- Unicode characters
- Slow networks
- Offline mode
- Low memory
- Background/foreground transitions

```swift
// ✅ Good: Test edge cases
func test_userList_whenEmpty_showsEmptyState() {
    viewModel.users = []  // Edge case
    XCTAssertTrue(viewModel.shouldShowEmptyState)
}

func test_userName_withUnicodeEmoji_displaysCorrectly() {
    let user = User(name: "John 👨‍💻 Doe")  // Edge case
    XCTAssertEqual(user.name, "John 👨‍💻 Doe")
}
```

---

### 5. Add Logging and Telemetry

**Why**: Understand production issues

**Levels**:
```swift
enum LogLevel {
    case debug, info, warning, error, fatal
}

func log(_ message: String, level: LogLevel = .info) {
    #if DEBUG
    print("[\(level)] \(message)")
    #endif

    // Production: Send to analytics
    Analytics.log(message, level: level)
}

// Usage
log("User login successful", level: .info)
log("API timeout, retrying...", level: .warning)
log("Crash avoided: nil user", level: .error)
```

**Telemetry**:
```swift
// Track critical paths
Analytics.track("app_launched")
Analytics.track("user_logged_in", properties: ["userId": userId])
Analytics.track("error_occurred", properties: ["error": error.localizedDescription])

// Monitor performance
Analytics.time("api_call_duration") {
    await fetchData()
}
```

---

### 6. Write Regression Tests

**Why**: Prevent bug from reoccurring

**Always Add Test After Fix**:
```swift
// Bug: Crash when users array is empty

// ✅ Regression test
func test_selectFirstUser_whenUsersEmpty_doesNotCrash() {
    // Given
    let viewModel = UserListViewModel()
    viewModel.users = []  // Reproduce crash condition

    // When/Then
    XCTAssertNoThrow(viewModel.selectFirstUser())
}

// Fix in code
func selectFirstUser() {
    guard let firstUser = users.first else {  // ✅ Defensive
        print("No users available")
        return
    }

    selectedUser = firstUser
}
```

---

### 7. Document Known Issues

**Why**: Help future developers (including yourself)

**In Code**:
```swift
// FIXME: Potential memory leak if view never dismisses
// TODO: Add timeout for network request
// NOTE: This workaround is needed because of iOS 16 bug (FB123456)
// WARNING: Do not force unwrap here, crashes in production

// ✅ Good: Link to issue tracker
// See: https://linear.app/company/issue/APP-123
func workaroundForNavigationBug() {
    // ...
}
```

**In Issue Tracker**:
```bash
bd create --type bug \
  --title "Memory leak in UserViewModel when modal doesn't dismiss" \
  --description "Affects iOS 15.0-15.2. Workaround implemented in commit abc1234." \
  --labels "known-issue,workaround"
```

---

### 8. Use Assertions and Preconditions

**Why**: Catch bugs early in development

**Strategic Placement**:
```swift
func processUser(_ user: User?) {
    // ✅ Debug-only assertion
    assert(user != nil, "User should not be nil at this point")

    guard let user = user else {
        assertionFailure("Unexpected nil user")
        return
    }

    // ✅ Production precondition (crashes in release)
    precondition(user.id.count > 0, "User ID must not be empty")

    // Process user...
}
```

**Assertions**:
- `assert()` - Debug only, removed in release
- `assertionFailure()` - Debug only, more severe than assert
- `precondition()` - Always evaluated, crashes in release
- `preconditionFailure()` - Always crashes, even in release
- `fatalError()` - Always crashes with message

---

## References

### Official Documentation

- [Debugging with Xcode](https://developer.apple.com/documentation/xcode/debugging)
- [Instruments User Guide](https://developer.apple.com/library/archive/documentation/DeveloperTools/Conceptual/InstrumentsUserGuide/)
- [LLDB Debugger](https://lldb.llvm.org/)
- [SwiftUI Debugging](https://developer.apple.com/documentation/swiftui/debugging)
- [Network Debugging](https://developer.apple.com/documentation/foundation/url_loading_system/handling_errors)

### Tools

- [Charles Proxy](https://www.charlesproxy.com/)
- [Proxyman](https://proxyman.io/)
- [Network Link Conditioner](https://developer.apple.com/download/all/?q=Additional%20Tools)
- [Chisel (LLDB Extensions)](https://github.com/facebook/chisel)
- [SwiftLint](https://github.com/realm/SwiftLint)

### Videos

- [WWDC: What's New in Xcode](https://developer.apple.com/videos/all-videos/?q=xcode)
- [WWDC: Debugging in Xcode](https://developer.apple.com/videos/all-videos/?q=debugging)
- [WWDC: Instruments](https://developer.apple.com/videos/all-videos/?q=instruments)

---

## Summary

This comprehensive iOS/tvOS debugging workflow provides:

1. **8 Debugging Workflows** - Crash analysis, memory leaks, performance, network, UI, breakpoints, LLDB, tvOS focus
2. **Detailed Tool Guides** - Instruments, Xcode Debugger, Charles/Proxyman, LLDB
3. **6-Phase Agent Coordination** - Reproduce, gather data, isolate, test fix, implement, verify
4. **6 Complete Examples** - Real-world debugging scenarios with step-by-step solutions
5. **Best Practices** - Proven strategies for efficient debugging
6. **Reference Links** - Official documentation and tool guides

**When to Use**:
- App crashes or hangs
- Memory leaks or excessive memory usage
- Performance issues (slow UI, laggy animations)
- Network timeouts or failures
- UI not updating or layout broken
- tvOS focus or remote control issues

**Workflow**:
```bash
/ios-debug [issue description]
```

The multi-agent system will coordinate investigation, analysis, and fix implementation with quality validation at each phase.
