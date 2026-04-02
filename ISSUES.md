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

