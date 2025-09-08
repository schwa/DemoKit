# DemoKit

## Demo Selection

DemoKit provides three ways to control which demo is displayed:

### 1. At Launch via Environment Variable

Set the `DEMOVIEW` environment variable to launch with a specific demo:

```bash
DEMOVIEW=<demo_id> /path/to/your/app
```

### 2. At Launch via Command-Line Argument

Pass the demo ID via UserDefaults on the command line:

```bash
/path/to/your/app -demoview <demo_id>
```

### 3. At Runtime via URL Scheme (Optional)

You can enable URL scheme support to open specific demos while the app is running.

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

2. In your SwiftUI app, enable the URL handler:
```swift
DemoPickerScene(demos: demos)
    .handleDemoURLScheme("x-demo")
```

#### Usage

Open demos using either format:
- Direct: `x-demo://Demo1`
- Query parameter: `x-demo://?openDemo=Demo1`

### Selection Priority

When multiple selection methods are present, DemoKit uses this priority:
1. `DEMOVIEW` environment variable (if set and valid)
2. Previously stored selection from UserDefaults (persisted between launches)
3. First demo in the list (fallback)

Note: URL scheme selections override the current selection immediately when received.

## TODO
Add support for taking screenshots of demos automatically.

osascript -e 'tell app "System Events" to get the id of every window of (every process whose background only is false)' 
screencapture -l <windowID> window.png
screencapture -x -o clean.png
