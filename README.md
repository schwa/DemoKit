# DemoKit

## Setting Initial Demo Selection

You can override the initial demo selection using an environment variable:

```bash
DEMO_SELECTION=<demo_id> /path/to/your/app
```

On macOS, you can also use command-line UserDefaults:

```bash
/path/to/your/app -DemosNavigationSplitView.selection <demo_id>
```

(TODO: test this works the . might be a problem)

The selection priority is:
1. `DEMO_SELECTION` environment variable (if set and valid)
2. Previously stored selection from UserDefaults (including command-line overrides)
3. First demo in the list (fallback)

## TODO

Add support for changing demo by URL scheme.
Add support for taking screenshots of demos automatically.

osascript -e 'tell app "System Events" to get the id of every window of (every process whose background only is false)' 
screencapture -l <windowID> window.png
screencapture -x -o clean.png
