## 1: No View menu item to toggle sidebar
status: new
priority: low
kind: none
created: 2026-04-02T21:10:22.883386+00:00

NavigationSplitView in DemosNavigationSplitView doesn't expose a View > Hide/Show Sidebar menu item. The toolbar button exists but there's no menu equivalent, making it inaccessible to automation tools like steveo.

---

## 2: Add Demos menu for navigating between demos
status: new
priority: low
kind: none
created: 2026-04-02T21:10:31.446371+00:00

The MetalSprocketsExamples app has a Demos menu defined in the app target, but DemoKit itself should provide this as a built-in feature. DemoPickerView/DemoPickerScene should automatically populate a Demos menu with all registered demos, enabling keyboard/menu-driven navigation and automation.

---

## 3: Show description over the demo view
status: new
priority: medium
kind: feature
created: 2026-04-02T22:55:38.899907+00:00


---

## 4: Isolate demos from view
status: new
priority: medium
kind: feature
created: 2026-04-02T22:55:41.936612+00:00
updated: 2026-04-02T23:15:27.906627+00:00

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
created: 2026-04-02T22:55:43.745406+00:00


---

## 6: Add common places for demos to put configuration
status: closed
priority: medium
kind: feature
created: 2026-04-02T22:55:45.860260+00:00
updated: 2026-04-02T23:31:29.051532+00:00
closed: 2026-04-02T23:31:29.051532+00:00

Provide a standard configuration view slot for demos.

Key decisions:
- ViewBuilder-based: DemoView takes an optional configurationView: closure alongside the main content
- Single slot — DemoKit decides placement per platform
- macOS: overlay along the bottom, toggled by a toolbar button
- iOS: popover/sheet
- Hidden by default, toggled on/off
- Can implement now on current DemoView system, migrates to ViewableDemo later when #4 lands

- 2026-04-02T23:31:29.055327+00:00: Implemented configuration view slot. Demos use .demoConfiguration { } modifier. macOS: bottom overlay with toolbar toggle. iOS: sheet with presentation detents.

---

## 7: Automatically generate a screenshot from a demo
status: new
priority: low
kind: none
created: 2026-04-02T23:02:37.990422+00:00


---

