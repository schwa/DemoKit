# ISSUES.md

---

## 1: No View menu item to toggle sidebar

+++
status: closed
priority: low
kind: enhancement
labels: effort:xs
created: 2026-04-02T21:10:22Z
updated: 2026-08-09T18:46:25Z
closed: 2026-08-09T18:46:25Z
+++

NavigationSplitView in DemosNavigationSplitView doesn't expose a View > Hide/Show Sidebar menu item. The toolbar button exists but there's no menu equivalent, making it inaccessible to automation tools like steveo.

- `2026-08-09T18:46:25Z`: Added SidebarCommands() to DemosCommandMenu, which supplies View > Show/Hide Sidebar on macOS. No unit test: this is menu-command wiring with no testable unit. Verified with steveo/System Events that the item exists and hides the sidebar.

---

## 2: Add Demos menu for navigating between demos

+++
status: closed
priority: low
kind: none
created: 2026-04-02T21:10:31Z
updated: 2026-04-03T00:24:23Z
closed: 2026-04-03T00:24:23Z
+++

The MetalSprocketsExamples app has a Demos menu defined in the app target, but DemoKit itself should provide this as a built-in feature. DemoPickerView/DemoPickerScene should automatically populate a Demos menu with all registered demos, enabling keyboard/menu-driven navigation and automation.

- `2026-04-03T00:24:23Z`: Implemented DemosCommandMenu with demo list, next/previous navigation, and configuration toggle.

---

## 3: Show description over the demo view

+++
status: closed
priority: medium
kind: feature
created: 2026-04-02T22:55:38Z
updated: 2026-04-03T22:13:19Z
closed: 2026-04-03T22:13:19Z
+++

- `2026-04-03T22:13:19Z`: Description overlay implemented in DemoDescriptionContainer with toggle via toolbar button and Cmd+I.

---

## 4: Isolate demos from view

+++
status: open
priority: medium
kind: feature
labels: effort:xl
created: 2026-04-02T22:55:41Z
updated: 2026-08-09T18:15:16Z
+++

Separate the concept of a Demo from its View representation.

Key decisions:
- Demo protocol: metadata + discoverability only, no lifecycle/execution model imposed
- ViewableDemo protocol: extends Demo, adds ability to produce a View
- Not all demos need views (headless compute, GPU work, etc.)
- UI only shows ViewableDemo conformers (for now)
- Demos registered via explicit array, same as today
- Demo type semantics (value vs reference) TBD at implementation time
- Big refactor — break into sub-issues when ready to implement

---

## 5: Add long descriptions and short descriptions

+++
status: closed
priority: medium
kind: feature
created: 2026-04-02T22:55:43Z
updated: 2026-04-03T22:13:19Z
closed: 2026-04-03T22:13:19Z
+++

- `2026-04-03T22:13:19Z`: DemoMetadata supports both description and longDescription. Both rendered in sidebar and description overlay with Markdown support.

---

## 6: Add common places for demos to put configuration

+++
status: closed
priority: medium
kind: feature
created: 2026-04-02T22:55:45Z
updated: 2026-04-02T23:31:29Z
closed: 2026-04-02T23:31:29Z
+++

Provide a standard configuration view slot for demos.

Key decisions:
- ViewBuilder-based: DemoView takes an optional configurationView: closure alongside the main content
- Single slot — DemoKit decides placement per platform
- macOS: overlay along the bottom, toggled by a toolbar button
- iOS: popover/sheet
- Hidden by default, toggled on/off
- Can implement now on current DemoView system, migrates to ViewableDemo later when #4 lands

- `2026-04-02T23:31:29Z`: Implemented configuration view slot. Demos use .demoConfiguration { } modifier. macOS: bottom overlay with toolbar toggle. iOS: sheet with presentation detents.

---

## 7: Automatically generate a screenshot from a demo

+++
status: new
priority: low
kind: feature
labels: effort:m, needs-info
created: 2026-04-02T23:02:37Z
updated: 2026-08-09T18:15:21Z
+++

- `2026-08-09T18:15:21Z`: Related: #18 (screenshot URL action options) and #17 (iOS destination). Needs info: unclear whether this means automatic capture at build/CI time, or just a UI action.

---

## 8: Persist configuration panel visibility in @AppStorage

+++
status: closed
priority: medium
kind: enhancement
created: 2026-04-03T00:03:52Z
updated: 2026-04-03T00:05:08Z
closed: 2026-04-03T00:05:08Z
+++

The show/hide state of the configuration overlay should be saved in @AppStorage so it persists across app launches.

- `2026-04-03T00:05:08Z`: Implemented in same commit as text label change.

---

## 9: Tags should be tappable to filter the view

+++
status: closed
priority: medium
kind: enhancement
labels: effort:m
created: 2026-04-03T00:50:04Z
updated: 2026-08-09T18:43:33Z
closed: 2026-08-09T18:43:33Z
+++

Tags displayed in the UI should be tappable. Tapping a tag filters the view to show only items with that tag. Need a clear/reset filter mechanism (e.g. a clear button or tapping the active tag again to deselect).

- `2026-08-09T18:43:33Z`: Implemented: keyword tags in the sidebar are now buttons that filter the list to that keyword; tapping the active tag or the 'Clear' button in the filter banner resets it. Sidebar rows are now plain List rows tagged for selection instead of NavigationLinks, because a NavigationLink label swallows clicks and the tags could never be tapped inside one. Filtering logic extracted to DemoFilter and unit tested; the tap/selection behaviour verified manually with steveo.

---

## 10: demoConfiguration view doesn't update when state changes — replace preference-based approach

+++
status: closed
priority: critical
kind: bug
created: 2026-04-03T02:20:16Z
updated: 2026-04-03T03:29:10Z
closed: 2026-04-03T03:29:10Z
+++

---

## 11: URL scheme navigation not working

+++
status: closed
priority: medium
kind: bug
created: 2026-04-03T06:10:32Z
updated: 2026-04-03T22:09:36Z
closed: 2026-04-03T22:09:36Z
+++

Opening URLs like `metalsprockets-examples://GameOfLife` or `metalsprockets-examples://demo/Game%20of%20Life` does not navigate to the demo. The `handleURL` method in `DemoPickerViewModel` parses the URL correctly but the demo selection doesn't change. May be related to the URL scheme only being set via environment on the Scene, or a mismatch between URL host and demo IDs (which are kebab-cased). Needs investigation.

- `2026-04-03T22:09:36Z`: Fixed Scene environment not propagating to View. DemoPickerScene now bridges the urlScheme environment value. Also added fuzzy ID matching: exact, kebab-cased, case-insensitive, and name-based fallback.

---

## 12: kebabCase produces double hyphens for names with spaces and capitals

+++
status: closed
priority: medium
kind: bug
created: 2026-04-03T06:19:06Z
updated: 2026-04-03T21:59:15Z
closed: 2026-04-03T21:59:15Z
+++

The `kebabCase` function replaces spaces with hyphens first, then inserts hyphens before uppercase letters, producing double hyphens. For example `"Game of Life"` becomes `"game-of--life"` instead of `"game-of-life"`. The fix should deduplicate consecutive hyphens after all replacements.

- `2026-04-03T21:59:15Z`: Added regex to deduplicate consecutive hyphens in kebabCase.

---

## 13: Accessibility audit: Main window

+++
status: closed
priority: medium
kind: task
labels: accessibility
created: 2026-04-03T21:02:29Z
updated: 2026-04-03T21:26:33Z
closed: 2026-04-03T21:26:33Z
+++

## Accessibility Issues — Main Window

### Errors (screen reader blockers)

1. **Stepper missing label** — The Stepper in `StateTestDemoView` (`Demo/Demo/DemoViews.swift:87`) has an `AXIncrementor` and two `AXButton` sub-elements with no accessible title or description. Screen readers cannot announce what this control does.
   - **Fix:** Add `.accessibilityLabel("Counter")` to the Stepper.

### Warnings (testing & usability)

2. **"Increment from main view" button missing identifier** — `Demo/Demo/DemoViews.swift:83`. Has a title but no accessibility identifier for UI testing.
   - **Fix:** Add `.accessibilityIdentifier("increment-button")`.

3. **Toolbar buttons missing identifiers** — Configuration gear button (`Sources/DemoKit/DemoConfigurationView.swift:72`) and Description info button (`Sources/DemoKit/DemoDescriptionView.swift:41`) lack accessibility identifiers.
   - **Fix:** Add `.accessibilityIdentifier("toggle-configuration")` and `.accessibilityIdentifier("toggle-description")`.

4. **Sidebar navigation links missing identifiers** — Each demo row in `Sources/DemoKit/DemosNavigationSplitView.swift` `navigationLink(for:)` has no accessibility identifier.
   - **Fix:** Add `.accessibilityIdentifier(metadata.id.rawValue)` to each navigation link.

5. **Keyword tags not accessible** — `TagView` / `KeywordsView` (`Sources/DemoKit/TagView.swift`, `KeywordsView.swift`) are visual-only with no accessibility grouping.
   - **Fix:** Either mark tags `.accessibilityHidden(true)` (decorative) or include keyword text in the parent row's accessibility label.

6. **Slider controls missing identifiers** — Scale and Rotation sliders in `DemoView1` (`Demo/Demo/DemoViews.swift:23-26`) lack `.accessibilityIdentifier()`.
   - **Fix:** Add `.accessibilityIdentifier("scale-slider")` and `.accessibilityIdentifier("rotation-slider")`.

### Not actionable (system/framework)

- ~60 AXMenuItem violations from macOS system menus (separators, Services, etc.)
- Window control buttons (close/minimize/zoom) missing labels — standard macOS controls

### Reference
- [Apple HIG — Accessibility](https://developer.apple.com/design/human-interface-guidelines/accessibility)

- `2026-04-03T21:26:33Z`: All actionable items addressed: (1) Stepper accessibility label, (2) increment button identifier, (3) toolbar button identifiers, (4) sidebar navigation link identifiers, (5) keyword tags hidden from accessibility. Item 6 N/A — DemoView1 was removed. Slider accessibility labels added in earlier commit.

---

## 14: Allow calling app to control sidebar visual options (tags, descriptions, etc.)

+++
status: closed
priority: low
kind: feature
labels: api, sidebar
created: 2026-04-03T21:36:01Z
updated: 2026-04-03T21:37:55Z
closed: 2026-04-03T21:37:55Z
+++

The calling app should be able to control which visual elements appear in the sidebar — e.g. whether keyword tags, descriptions, or icons are shown.

## Possible approaches

### 1. Environment values (recommended)
A `DemoKitConfiguration` struct propagated via SwiftUI environment:

```swift
struct DemoKitConfiguration {
    var showKeywordTags: Bool = true
    var showDescriptions: Bool = true
    var showIcons: Bool = true
    var labelStyle: DemoLabelStyle = .titleAndIcon
}

// Usage:
DemoPickerScene(demos: [...])
    .demoKitConfiguration(.init(showKeywordTags: false))
```

Internally, `DemosNavigationSplitView` and `navigationLink(for:)` read the config from `@Environment(\.demoKitConfiguration)`.

### 2. Individual environment keys
Separate `@Entry` values for each option:

```swift
.environment(\.demoShowTags, false)
.environment(\.demoShowDescriptions, false)
```

More granular but more boilerplate.

### 3. View modifier on DemoPickerScene
A modifier that wraps the config:

```swift
DemoPickerScene(demos: [...])
    .demoSidebarStyle(tags: false, descriptions: true)
```

## Recommendation
Option 1 (single config struct via environment) is cleanest. It is a single type, easy to extend, and follows the pattern used by SwiftUI for `NavigationSplitViewStyle`, `ListStyle`, etc.

- `2026-04-03T21:37:55Z`: Implemented DemoKitConfiguration struct with environment propagation. Supports: showKeywordTags, showDescriptions, showIcons, showPinButton, showColors. Applied via .demoKitConfiguration() modifier on View or Scene.

---

## 15: Support clickable links in demo descriptions

+++
status: closed
priority: low
kind: feature
labels: ui
created: 2026-04-03T21:36:50Z
updated: 2026-04-03T21:39:34Z
closed: 2026-04-03T21:39:34Z
+++

Demo descriptions and long descriptions already use `LocalizedStringKey` (which supports Markdown), but links in the description overlay and sidebar are not interactive.

The description text in `DemoDescriptionView` and sidebar rows should support tappable/clickable Markdown links, e.g.:

```swift
static var metadata = DemoMetadata(
    description: "See [Apple docs](https://developer.apple.com) for details"
)
```

Needs:
- Verify `Text(LocalizedStringKey(...))` is used for description rendering (it already is in `DemoDescriptionView`)
- Check sidebar description text uses `LocalizedStringKey` too
- Ensure `.tint()` or link styling makes links visually distinct

- `2026-04-03T21:39:34Z`: Sidebar description now uses LocalizedStringKey for Markdown link support. DemoDescriptionView already did. Added LinksDemoView to test.

---

## 16: Ensure demos are properly torn down when navigating away

+++
status: closed
priority: medium
kind: task
labels: lifecycle, reliability
created: 2026-04-03T21:38:19Z
updated: 2026-04-03T21:38:55Z
closed: 2026-04-03T21:38:55Z
+++

When switching between demos in the sidebar, the previously selected demo should be fully torn down. Currently demos that use timers, animations, or other ongoing resources may continue running in the background after navigating away.

## Concerns

- Demos with `Timer.scheduledTimer` (e.g. `TimerDemoView`) may keep firing after deselection
- Repeating animations (`.repeatForever`) may continue consuming resources
- Any demo holding resources (network, file handles, etc.) should release them

## Investigation needed

- Verify that SwiftUI tears down the demo view when selection changes (the detail view uses `.id(id)` which should force recreation)
- Check if `.onDisappear` is reliably called
- Consider whether demos need an explicit lifecycle protocol (e.g. `func tearDown()`) or if SwiftUI view lifecycle is sufficient
- Test with Instruments to confirm no leaked timers or orphaned views

- `2026-04-03T21:38:55Z`: Already handled: detail view uses .id(id) forcing SwiftUI to destroy/recreate on selection change. TimerDemoView has .onDisappear { stopTimer() }. Basic lifecycle is sufficient.

---

## 17: Decide iOS screenshot destination

+++
status: open
priority: low
kind: task
labels: ios, screenshot, effort:s
created: 2026-04-03T22:25:03Z
updated: 2026-08-09T18:50:34Z
+++

The `screenshot` URL action saves to `/tmp` on macOS and reveals via `NSWorkspace`. On iOS we need to decide where screenshots go.

Options:
- Save to photo library (needs permission)
- Save to app documents directory
- Share sheet
- UIPasteboard

Defer until iOS support is actively needed.

- `2026-08-09T18:15:21Z`: Related: #18 (screenshot URL parameters incl. destination).
- `2026-08-09T18:50:34Z`: Punting: this is a product decision (photo library vs documents dir vs share sheet vs pasteboard), not something the code can resolve, and the issue itself says to defer until iOS support is needed. Note that #18 has since landed a 'destination' parameter, so an iOS default just needs picking — tell me which of the four you want and it's a small change.

---

## 18: Screenshot URL action: configurable width, height, scale, destination, and format

+++
status: closed
priority: low
kind: feature
labels: screenshot, url, effort:m
created: 2026-04-03T22:28:33Z
updated: 2026-08-09T18:50:23Z
closed: 2026-08-09T18:50:23Z
+++

The `x-demo://screenshot` action currently hardcodes 800×600, 2x scale, PNG format, and saves to the temp directory. These should be configurable via query parameters:

```
x-demo://screenshot?width=1200&height=800&scale=3&format=png
x-demo://screenshot?width=400&height=300&format=jpg
```

### Parameters to support
- `width` — render width in points (default: 800)
- `height` — render height in points (default: 600)
- `scale` — rendering scale factor (default: 2.0)
- `format` — `png` or `jpg` (default: png)
- `destination` — output path or directory (default: temp directory)
- `reveal` — whether to reveal in Finder, `true`/`false` (default: true on macOS)
- `background` — background color, e.g. `white`, `black`, `clear` (default: white)

- `2026-08-09T18:15:21Z`: Related: #7 (automatic screenshot generation), #17 (iOS destination).
- `2026-08-09T18:50:23Z`: Implemented: screenshot URL action now takes width, height, scale, format (png/jpg), destination (file or directory, ~ expanded), reveal, and background (named colours or hex). Parsing lives in ScreenshotOptions with unit tests; verified end-to-end with the Demo app (400x300 scale-1 JPEG on black, reveal disabled). Note: sandboxed apps can only write where entitlements allow — out-of-container destinations fail and are logged. README updated.

---

## 19: URL scheme: demo/<id> navigation doesn't work, next/previous do

+++
status: closed
priority: high
kind: bug
labels: url, effort:m
created: 2026-04-03T23:11:20Z
updated: 2026-08-09T18:36:54Z
closed: 2026-08-09T18:36:54Z
+++

When using `DemoPickerScene` with `.handleDemoURL(scheme:)`, the `next` and `previous` URL actions work correctly (window title changes to the new demo), but `demo/<id>` does nothing — the window stays on the current demo.

Tested with:
- `open -a "MetalSprockets-Examples" "metalsprockets-examples://demo/grass"` — no effect
- `open -a "MetalSprockets-Examples" "metalsprockets-examples://demo/Grass"` — no effect  
- `open -a "MetalSprockets-Examples" "metalsprockets-examples://demo/Grass Sphere"` — not tested but likely same
- `open -a "MetalSprockets-Examples" "metalsprockets-examples://next"` — works
- `open -a "MetalSprockets-Examples" "metalsprockets-examples://previous"` — works

The app setup matches the README pattern:
```swift
DemoPickerScene(demos: allDemos)
    .handleDemoURL(scheme: "metalsprockets-examples")
```

Demo metadata has `name: "Grass Sphere"` (no explicit `id:`), so DemoKit should derive the ID. The README says IDs are matched loosely (exact, kebab-case, case-insensitive, whitespace-stripped). None of the obvious variants work.

Previously the app used `Window` + `DemoPickerView` + `.handleDemoURL` on the view (instead of on `DemoPickerScene`) — that also didn't work for direct navigation.

- `2026-08-09T18:36:54Z`: Could not reproduce as a hard failure: demo/<id> navigation works end-to-end (verified with the Demo app, x-demo://demo/pulse and x-demo://demo/symbols both switch demos). The reported URLs failed because 'grass' does not match the derived id 'grass-sphere' — the loose matcher only handled exact/kebab/case/whitespace variants. Added a unique partial-match fallback (a substring that matches exactly one demo now resolves, ambiguous ones are ignored and logged), and the not-found warning now lists all known demo IDs.

---

## 20: Configuration panel is a dead snapshot: every demo's controls are frozen in inspector mode

+++
status: closed
priority: critical
kind: bug
labels: effort:m
created: 2026-08-09T18:13:28Z
updated: 2026-08-09T18:27:35Z
closed: 2026-08-09T18:27:35Z
+++

Every interactive control in every demo's configuration panel is non-functional in inspector mode. Sliders spring back, labels never update, toggles will not reflect their state. This is the whole point of the panel, and it is broken for all consumers.

Cause, DemoConfigurationView.swift:44-49:

    content
        .preference(key: HasDemoConfigurationPreferenceKey.self, value: true)
        .onAppear {
            store?.content = AnyView(configuration())   // captured once, never refreshed
        }

The configuration content is snapshotted into an AnyView exactly once, in onAppear, and the inspector renders that dead value forever. Nothing reassigns store.content afterwards, so the panel never re-evaluates. Consequences:

- Text("Voxel Size: \(voxelSize.width)") is baked into the snapshot as a literal string. It reads 32 forever while the real state is 512.
- A Slider bound with $state writes through fine, but its thumb never redraws, so it appears to snap back to its starting position.
- Worse, and much harder to diagnose: any computed Binding in a demo captures self into that escaping snapshot. Writes go through the @State box while reads come from a frozen by-value copy. In MetalSprocketsExamples#389 an instrumented build showed the setter's own read-back going 32 -> 256 -> 512 while 620 consecutive getter calls returned 32. That is a silent, split-brain state bug, and DemoKit is what turns an otherwise ordinary SwiftUI pattern into one.

Verified against a running MetalSprockets-Examples build with steveo: drag a slider, screenshot-diff the window. The 3D viewport changes; the panel region is pixel-identical. Reproduced on both the Voxel demo and Particle Effects, so it is not demo-specific.

Overlay/sheet mode (ConfigurationOverlayPresentation) is fine — it calls configuration() inline, which re-evaluates normally. Only the inspector path snapshots.

Fix direction: the panel content has to be re-evaluated on every body pass rather than captured once. Carrying the view through a PreferenceKey (values are recomputed each pass) rather than assigning to an @Observable store from onAppear is the idiomatic option; storing a closure and calling it at render time is not enough on its own, because the closure still captures a single generation of the demo view.

Whatever the fix, it is worth a regression test: a demo with a @State-backed slider, driven programmatically, asserting the rendered panel reflects the new value.

- `2026-08-09T18:27:35Z`: Fixed by presenting the inspector inline via a new ConfigurationInspectorPresentation modifier; DemoConfigurationStore removed. No unit test: the failure is only observable in rendered SwiftUI inspector output and is not reachable from a unit test. Verified manually with steveo against the Demo app (State Test demo): incrementing the counter in the main view now updates the inspector panel live (was frozen before).

---
