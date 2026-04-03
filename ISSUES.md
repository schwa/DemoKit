## 1: No View menu item to toggle sidebar
status: new
priority: low
kind: none
created: 2026-04-02T21:10:22Z

NavigationSplitView in DemosNavigationSplitView doesn't expose a View > Hide/Show Sidebar menu item. The toolbar button exists but there's no menu equivalent, making it inaccessible to automation tools like steveo.

---

## 2: Add Demos menu for navigating between demos
status: closed
priority: low
kind: none
created: 2026-04-02T21:10:31Z
updated: 2026-04-03T00:24:23Z
closed: 2026-04-03T00:24:23Z

The MetalSprocketsExamples app has a Demos menu defined in the app target, but DemoKit itself should provide this as a built-in feature. DemoPickerView/DemoPickerScene should automatically populate a Demos menu with all registered demos, enabling keyboard/menu-driven navigation and automation.

- `2026-04-03T00:24:23Z`: Implemented DemosCommandMenu with demo list, next/previous navigation, and configuration toggle.

---

## 3: Show description over the demo view
status: new
priority: medium
kind: feature
created: 2026-04-02T22:55:38Z


---

## 4: Isolate demos from view
status: new
priority: medium
kind: feature
created: 2026-04-02T22:55:41Z
updated: 2026-04-02T23:15:27Z

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
status: new
priority: medium
kind: feature
created: 2026-04-02T22:55:43Z


---

## 6: Add common places for demos to put configuration
status: closed
priority: medium
kind: feature
created: 2026-04-02T22:55:45Z
updated: 2026-04-02T23:31:29Z
closed: 2026-04-02T23:31:29Z

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
status: new
priority: low
kind: none
created: 2026-04-02T23:02:37Z


---

## 8: Persist configuration panel visibility in @AppStorage
status: closed
priority: medium
kind: enhancement
created: 2026-04-03T00:03:52Z
updated: 2026-04-03T00:05:08Z
closed: 2026-04-03T00:05:08Z

The show/hide state of the configuration overlay should be saved in @AppStorage so it persists across app launches.

- `2026-04-03T00:05:08Z`: Implemented in same commit as text label change.

---

## 9: Tags should be tappable to filter the view
status: new
priority: medium
kind: none
created: 2026-04-03T00:50:04Z

Tags displayed in the UI should be tappable. Tapping a tag filters the view to show only items with that tag. Need a clear/reset filter mechanism (e.g. a clear button or tapping the active tag again to deselect).

---

## 10: demoConfiguration view doesn't update when state changes — replace preference-based approach
status: closed
priority: critical
kind: bug
created: 2026-04-03T02:20:16Z
updated: 2026-04-03T03:29:10Z
closed: 2026-04-03T03:29:10Z


---

## 11: URL scheme navigation not working
status: new
priority: medium
kind: bug
created: 2026-04-03T06:10:32Z

Opening URLs like `metalsprockets-examples://GameOfLife` or `metalsprockets-examples://demo/Game%20of%20Life` does not navigate to the demo. The `handleURL` method in `DemoPickerViewModel` parses the URL correctly but the demo selection doesn't change. May be related to the URL scheme only being set via environment on the Scene, or a mismatch between URL host and demo IDs (which are kebab-cased). Needs investigation.

---

## 12: kebabCase produces double hyphens for names with spaces and capitals
status: new
priority: medium
kind: bug
created: 2026-04-03T06:19:06Z

The `kebabCase` function replaces spaces with hyphens first, then inserts hyphens before uppercase letters, producing double hyphens. For example `"Game of Life"` becomes `"game-of--life"` instead of `"game-of-life"`. The fix should deduplicate consecutive hyphens after all replacements.

---

## 13: Accessibility audit: Main window
status: closed
priority: medium
kind: task
labels: accessibility
created: 2026-04-03T21:02:29Z
updated: 2026-04-03T21:26:33Z
closed: 2026-04-03T21:26:33Z

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
status: closed
priority: low
kind: feature
labels: api, sidebar
created: 2026-04-03T21:36:01Z
updated: 2026-04-03T21:37:55Z
closed: 2026-04-03T21:37:55Z

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
status: new
priority: low
kind: feature
labels: ui
created: 2026-04-03T21:36:50Z

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

---

