# Browser Router

## Version Management

- `BrowserRouter/Version.swift` contains `appVersion` as a single natural number (`UInt`)
- Increment `appVersion` by 1 on every commit

## Debugging

- `debugLog(_ msg: String)` is a free function defined in `main.swift` that appends to `/tmp/browser-router-debug.log`
- The file is created automatically if it doesn't exist
- Usage: add `debugLog("[label] \(value)")` calls, rebuild/install, restart the app, then `cat /tmp/browser-router-debug.log`
- Remove debug log calls before committing
