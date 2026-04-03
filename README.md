# DemoKit

A SwiftUI library for building organized, searchable demo galleries with navigation, metadata, grouping, pinning, and URL scheme support. Ideal for showcasing components, prototypes, or test views in a single app.

## Requirements

- iOS 18.0+ / macOS 15.0+
- Swift 6.0+
- Xcode 16.0+

## Installation

Add DemoKit as a Swift Package Manager dependency:

```swift
dependencies: [
    .package(url: "https://github.com/schwa/DemoKit.git", from: "0.1.0")
]
```

## Quick Start

### 1. Create a Demo

Conform a view to `DemoView` and provide a static `metadata` property. The view must have a no-argument `init()`.

```swift
import SwiftUI
import DemoKit

struct AnimationDemo: DemoView {
    static var metadata = DemoMetadata(
        type: Self.self,
        systemImage: "wand.and.rays",
        description: "Showcases various SwiftUI animations",
        group: "Visual Effects",
        keywords: ["animation", "motion"],
        color: .purple
    )

    init() {}

    var body: some View {
        Text("Animation Demo")
            .font(.largeTitle)
    }
}
```

### 2. Wire Up Your App

Use `DemoPickerScene` as your app's scene, passing an array of demo types:

```swift
import SwiftUI
import DemoKit

@main
struct DemoApp: App {
    var body: some Scene {
        DemoPickerScene(demos: [
            AnimationDemo.self,
            GestureDemo.self,
            LayoutDemo.self,
        ])
    }
}
```

That's it — you get a sidebar with search, grouping, pinning, and a detail area that displays the selected demo.

## Creating Demos

### The `DemoView` Protocol

```swift
public protocol DemoView: View {
    static var metadata: DemoMetadata { get }
    @MainActor init()
}
```

Every demo view needs a `metadata` property and a parameterless initializer.

### `DemoMetadata`

```swift
DemoMetadata(
    id: .init("my-demo"),       // Unique ID — auto-derived if omitted
    name: "My Demo",            // Display name — auto-derived if omitted
    systemImage: "star.fill",   // SF Symbol for the sidebar icon
    description: "Short text",  // Shown below the name in the sidebar
    longDescription: "Longer text with **Markdown** support",
    group: "Category",          // Groups demos into sidebar sections
    keywords: ["tag1", "tag2"], // Searchable tags shown as pills
    color: .blue,               // Tints the sidebar label
    isEnabled: true,             // Whether the demo is selectable
    variants: []                // Sub-demos (nested metadata)
)
```

**Auto-derived names and IDs:** You can omit both `name` and `id` if you pass the `type:` parameter. DemoKit strips common suffixes (`DemoView`, `Demo`, `View`) from the type name and converts it to a human-readable name and kebab-case ID:

```swift
struct MeshGradientDemoView: DemoView {
    // name → "Mesh Gradient", id → "mesh-gradient"
    static var metadata = DemoMetadata(type: Self.self, group: "Backgrounds")
    // ...
}
```

You can also provide just `name:` (ID is derived) or just `id:` (name is derived).

### Configuration Panels

Add a configuration panel to any demo with the `.demoConfiguration` modifier. On macOS it appears as a material overlay at the bottom of the detail view; on iOS it opens as a sheet.

```swift
struct MyDemo: DemoView {
    @State private var radius: Double = 50

    var body: some View {
        Circle()
            .frame(width: radius * 2, height: radius * 2)
            .demoConfiguration {
                Form {
                    Slider(value: $radius, in: 10...150)
                }
            }
    }
}
```

A gear button appears in the toolbar automatically when `.demoConfiguration` is used.

### Description Overlays

If a demo has a `description` or `longDescription`, an info button appears in the toolbar. Clicking it shows a material overlay with the demo's name, icon, and description text (rendered as Markdown via `LocalizedStringKey`).

## Showing a Menu Bar

Add `DemosCommandMenu` to your app's `.commands` modifier to get a **Demos** menu in the menu bar:

```swift
@main
struct DemoApp: App {
    var body: some Scene {
        DemoPickerScene(demos: demos)
            .commands {
                DemosCommandMenu()
            }
    }
}
```

The menu provides:

- **Previous Demo** (`⌘[`) and **Next Demo** (`⌘]`) navigation
- **Show/Hide Configuration** (`⌘K`)
- **Show/Hide Description** (`⌘I`)
- A list of all visible demos, grouped by section, with a checkmark on the current selection

## Configuring Appearance

Use `DemoKitConfiguration` to control what's shown in the sidebar:

```swift
DemoPickerScene(demos: demos)
    .demoKitConfiguration(DemoKitConfiguration(
        showKeywordTags: false,  // Hide keyword pill tags
        showDescriptions: true,  // Show description text
        showIcons: true,         // Show SF Symbol icons
        showPinButton: true,     // Show pin buttons
        showColors: true         // Use demo-specified colors
    ))
```

### Hiding Tags

To hide keyword tags from the sidebar, set `showKeywordTags: false`:

```swift
.demoKitConfiguration(DemoKitConfiguration(showKeywordTags: false))
```

Keywords are still searchable even when tags are hidden.

## URL Schemes

DemoKit supports a custom URL scheme for deep-linking into demos from outside the app.

### Setup

1. Register a URL scheme in your `Info.plist`:

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

2. Enable the URL handler on your scene:

```swift
DemoPickerScene(demos: demos)
    .handleDemoURL(scheme: "x-demo")
```

### URL Formats

| URL | Action |
|-----|--------|
| `x-demo://demo/my-demo-id` | Navigate to a specific demo by ID |
| `x-demo://next` | Select the next demo |
| `x-demo://previous` | Select the previous demo |
| `x-demo://screenshot` | Take a screenshot of the current demo |

Demo IDs are matched flexibly — exact match, kebab-case conversion, case-insensitive, and whitespace-stripped name matching are all tried.

### Testing from the Terminal

```bash
open "x-demo://demo/animation-demo"
open "x-demo://next"
```

## Demo Selection at Launch

DemoKit provides multiple ways to launch directly into a specific demo:

### Environment Variable

```bash
DEMOVIEW=my-demo-id ./MyApp
```

### Command-Line Argument (UserDefaults)

```bash
./MyApp -demoview my-demo-id
```

### Priority Order

1. `DEMOVIEW` environment variable (highest)
2. Stored selection from UserDefaults (persisted between launches)
3. First demo in the list (fallback; `nil` on iOS)

URL scheme selections override the current selection immediately when received.

## Crash Detection

Install the crash detector to automatically clear the stored demo selection if the app crashes on launch (preventing a crash loop):

```swift
@main
struct DemoApp: App {
    init() {
        DemoCrashDetector.install()
    }
    // ...
}
```

## Sidebar Features

- **Search** — Appears automatically when there are 6+ demos. Searches names, descriptions, and keywords.
- **Grouping** — Demos with a `group` are organized into collapsible sections.
- **Pinning** — Pin demos to a "Pinned" section at the top. Toggle via the pin button or context menu.
- **Hiding** — Hide demos via context menu. Unhide all from the list's context menu or the empty-state button.

## Using `DemoPickerView` Directly

For more control over your scene structure, use `DemoPickerView` instead of `DemoPickerScene`:

```swift
struct ContentView: View {
    var body: some View {
        DemoPickerView(demos: [
            AnimationDemo.self,
            GestureDemo.self,
        ])
    }
}
```

## Complete Example

```swift
import SwiftUI
import DemoKit

struct GradientDemo: DemoView {
    static var metadata = DemoMetadata(
        type: Self.self,
        systemImage: "paintpalette",
        description: "A configurable linear gradient",
        group: "Backgrounds",
        keywords: ["gradient", "color"],
        color: .indigo
    )

    @State private var hue: Double = 0.6

    init() {}

    var body: some View {
        LinearGradient(
            colors: [Color(hue: hue, saturation: 0.8, brightness: 0.9), .black],
            startPoint: .top,
            endPoint: .bottom
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .demoConfiguration {
            Form {
                LabeledContent("Hue") {
                    Slider(value: $hue, in: 0...1)
                }
            }
        }
    }
}

@main
struct DemoApp: App {
    init() {
        DemoCrashDetector.install()
    }

    var body: some Scene {
        DemoPickerScene(demos: [
            GradientDemo.self,
        ])
        .handleDemoURL(scheme: "x-demo")
        .commands {
            DemosCommandMenu()
        }
    }
}
```

## License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.
