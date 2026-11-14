# expo-roomplan example

One app showing the three ways to use expo-roomplan:

| Screen | API | Use it when |
| --- | --- | --- |
| `src/app/native-ui.tsx` | `useRoomPlan()` | You want Apple's own capture and review UI with the least code. |
| `src/app/embedded.tsx` | `useRoomPlanView()` + `<RoomPlanView>` | You want the scanner inside your own screen, with your own controls (including multi-room). |
| `src/app/provider.tsx` | `<RoomPlanProvider>` + `useRoomPlanContext()` | Same as above, but controls and state are needed in several components. |

## Requirements

- macOS with Xcode 26 or newer (Expo SDK 58's Swift packages need Swift 6.2)
- A LiDAR device (iPhone 12 Pro or newer, recent iPad Pro) on **iOS 16+**. Multi-room capture ("Add another room") needs **iOS 17+**.
- The simulator can open the app, but it can't scan.
- Expo Go can't load native modules. This runs as a development build.

## Running it

From the repo root:

```sh
npm install          # library dev dependencies
cd example
npm install
npx expo run:ios --device
```

`expo run:ios` runs `expo prebuild` on first launch, generating `ios/` from `app.json`. The native folders are generated (Continuous Native Generation) and gitignored. To regenerate them after changing `app.json` or a config plugin, run `npm run prebuild`.

To open the project in Xcode, e.g. to set a signing team, run `npx expo prebuild -p ios`, then `npm run open:ios` from the repo root.

### How the example uses the local library

- `"expo-roomplan": "file:.."` in `package.json` lets autolinking find the native module in `../ios` and lets Expo find the config plugin in `../app.plugin.js`.
- `metro.config.js` resolves `expo-roomplan` to `../src/index.ts`, so library JS/TS changes hot-reload without `npm run build`. It also blocks `../node_modules` so the library's dev copies of `react` and `react-native` never get bundled.
- `expo-doctor` reports "duplicate dependencies" because of those dev copies in `../node_modules`. Autolinking and Metro only use `example/node_modules`, so this warning is expected here.

---

## Using expo-roomplan in your own Expo app

### 1. Install

```sh
npx expo install expo-roomplan
```

### 2. Add the config plugin

```jsonc
// app.json
{
  "expo": {
    "plugins": [
      ["expo-roomplan", { "cameraPermissionText": "Allow camera access to scan rooms." }]
    ]
  }
}
```

During prebuild the plugin:

- Sets `NSCameraUsageDescription` in Info.plist if it isn't already set, using `cameraPermissionText` or a default.
- Raises the Podfile's `platform :ios` to `16.0` when it's lower. A dynamic platform line, like Expo's default one, is left alone, so set the deployment target with `expo-build-properties` instead (step 3).

It does not add a privacy manifest (see step 4).

### 3. Set the iOS deployment target

RoomPlan needs iOS 16, but React Native's default is 15.1. Expo's Podfile reads the target from a dynamic setting the plugin can't safely rewrite, so set it with `expo-build-properties`:

```sh
npx expo install expo-build-properties
```

```jsonc
["expo-build-properties", { "ios": { "deploymentTarget": "16.0" } }]
```

Use `"17.0"` to guarantee multi-room capture. This example does that.

### 4. Privacy manifest (App Store)

Declare the required-reason APIs under `ios.privacyManifests` in `app.json`. Expo writes them into `PrivacyInfo.xcprivacy` at prebuild. See [`app.json`](./app.json) in this folder for the full block this example uses.

### 5. Build and use it

```sh
npx expo run:ios --device
```

```tsx
import { Button } from "react-native";
import { useRoomPlan, ExportType } from "expo-roomplan";

export default function ScanScreen() {
  const { startRoomPlan, scanUrl } = useRoomPlan({
    exportType: ExportType.Parametric,
    sendFileLoc: true,
  });
  return <Button title="Scan room" onPress={() => startRoomPlan("MyRoom")} />;
}
```

For embedded scanning with custom controls, see `src/app/embedded.tsx` and `src/app/provider.tsx`.

## Troubleshooting

- **"Cannot find native module 'ExpoRoomPlan'"**: the app binary predates the library. Rebuild with `npx expo run:ios`. Expo Go won't work.
- **"Invalid hook call"**: two copies of React are being bundled. In monorepos or with local `file:` packages, make sure Metro resolves `react` and `react-native` from one place (see this example's `metro.config.js`), then run `npx expo start --clear`.
- **"Multiple commands produce PrivacyInfo.xcprivacy"**: a privacy manifest is being added twice. Use only `ios.privacyManifests` in `app.json`, not a manually added `.xcprivacy` file as well.
- **"Add another room" reports an error**: multi-room capture needs iOS 17+.
