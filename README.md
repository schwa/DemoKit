# DemoKit

SwiftUI library for creating organized, searchable demonstration views with metadata and navigation support.

## Installation

Add DemoKit to your Swift Package Manager dependencies:

```swift
dependencies: [
    .package(url: "https://github.com/yourusername/DemoKit.git", from: "0.1.0")
]
```

Then add it to your target:

```swift
targets: [
    .target(
        name: "YourApp",
        dependencies: ["DemoKit"]
    )
]
```

## Usage

### Basic Setup

1. Create demo views conforming to the `DemoView` protocol. Most metadata fields are optional.

```swift
import SwiftUI
import DemoKit

struct MyDemoView: DemoView {
    static var metadata = DemoMetadata(
        id: .init("my-demo"), // Optional - will default to kebab-case of type name
        name: "My Demo", // Optional - will default to type name split by camel case
        systemImage: "star.fill",
        description: "Demonstrates a cool feature",
        group: "Features",
        keywords: ["animation", "gestures"],
        color: .blue
    )
    
    init() {}
    
    var body: some View {
        Text("Your demo content here")
    }
}
```

2. Use `DemoPickerScene` in your app:

```swift
import SwiftUI
import DemoKit

@main
struct DemoApp: App {
    var body: some Scene {
        DemoPickerScene(demos: [
            MyDemoView.self,
            AnotherDemoView.self,
            ThirdDemoView.self
        ])
    }
}
```

### Alternative: Using DemoPickerView

For more control, use `DemoPickerView` directly in your views:

```swift
struct ContentView: View {
    var body: some View {
        DemoPickerView(demos: [
            MyDemoView.self,
            AnotherDemoView.self
        ])
    }
}
```

## Demo Selection

DemoKit provides three ways to control which demo is displayed:

### 1. At Launch via Environment Variable

Set the `DEMOVIEW` environment variable to launch with a specific demo:

```bash
DEMOVIEW=my-demo /path/to/your/app
```

### 2. At Launch via Command-Line Argument

Pass the demo ID via UserDefaults on the command line:

```bash
/path/to/your/app -demoview my-demo
```

### 3. At Runtime via URL Scheme (Optional)

Enable URL scheme support to open specific demos while the app is running.

#### Setup

1. In your app's `Info.plist`, register your custom URL scheme:
```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>x-demo</string>
        </array>
    </dict>
</array>
```

2. Enable the URL handler in your app:
```swift
DemoPickerScene(demos: demos)
    .handleDemoURLScheme("x-demo")
```

#### Usage

Open demos using either format:
- Direct: `x-demo://my-demo`
- Query parameter: `x-demo://?openDemo=my-demo`

### Selection Priority

When multiple selection methods are present, DemoKit uses this priority:
1. `DEMOVIEW` environment variable (if set and valid)
2. Previously stored selection from UserDefaults (persisted between launches)
3. First demo in the list (fallback)

Note: URL scheme selections override the current selection immediately when received.

## API Reference

### DemoMetadata

Struct containing metadata for a demo view:

```swift
public struct DemoMetadata {
    var id: ID                     // Unique identifier for the demo
    var name: String               // Display name in the sidebar
    var systemImage: String        // SF Symbol name for the icon
    var description: String?       // Optional description shown below the name
    var group: String?             // Optional group name for organization
    var keywords: [String]         // Searchable keywords/tags
    var color: Color?              // Optional color for the demo item
    var isEnabled: Bool            // Whether the demo is selectable (default: true)
    var variants: [DemoMetadata]   // Sub-demos or variants
}
```

### DemoView Protocol

Protocol that demo views must conform to:

```swift
public protocol DemoView: View {
    static var metadata: DemoMetadata { get }
    
    @MainActor
    init()
}
```

### DemoPickerScene

Scene wrapper for creating a demo picker window:

```swift
public struct DemoPickerScene: Scene {
    init(demos: [any DemoView.Type])
}
```

### DemoPickerView

View component for embedding the demo picker in existing views:

```swift
public struct DemoPickerView: View {
    init(demos: [any DemoView.Type])
}
```

### Environment Extensions

Extensions for handling URL schemes:

```swift
// For Views
func handleDemoURLScheme(_ scheme: String) -> some View

// For Scenes
func handleDemoURLScheme(_ scheme: String) -> some Scene
```

## Requirements

- iOS 18.0+ / macOS 15.0+
- Swift 6.0+
- Xcode 16.0+

## Example

Here's a complete example demonstrating various DemoKit features:

```swift
import SwiftUI
import DemoKit

// Define multiple demo views
struct AnimationDemo: DemoView {
    static var metadata = DemoMetadata(
        id: .init("animation-demo"),
        name: "Animation Demo",
        systemImage: "wand.and.rays",
        description: "Showcases various SwiftUI animations",
        group: "Visual Effects",
        keywords: ["animation", "motion", "transitions"],
        color: .purple
    )
    
    init() {}
    
    var body: some View {
        VStack {
            Text("Animation Demo")
                .font(.largeTitle)
            // Your animation code here
        }
    }
}

struct GestureDemo: DemoView {
    static var metadata = DemoMetadata(
        id: .init("gesture-demo"),
        name: "Gesture Recognition",
        systemImage: "hand.tap.fill",
        description: "Demonstrates gesture handling",
        group: "User Input",
        keywords: ["gestures", "touch", "interaction"],
        color: .orange
    )
    
    init() {}
    
    var body: some View {
        Text("Gesture Demo")
        // Your gesture code here
    }
}

// Create the app
@main
struct DemoApp: App {
    var body: some Scene {
        DemoPickerScene(demos: [
            AnimationDemo.self,
            GestureDemo.self
        ])
        .handleDemoURLScheme("x-demo")
    }
}
```

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
