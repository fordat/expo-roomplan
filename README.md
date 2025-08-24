# expo-roomplan

React Native implementation of Apple's RoomPlan SDK.

Read more about it here: [Apple - RoomPlan](https://developer.apple.com/augmented-reality/roomplan/)

# Usage

- [RoomPlanProvider](#roomplanprovider) with its [RoomPlanViewConsumer](#roomplanprovider) for cross‑tree, context‑based control.

- [useRoomPlanView](#useroomplanview) - hook for local, component‑scoped control.

- [RoomPlanView](#roomplanview) - embeddable component driven by props.

- [useRoomPlan](#useroomplan) - get up and running quickly with a pre-built view controller.


## useRoomPlan

The simplest way to use this package is with the `useRoomPlan` hook:

```
const { startRoomPlan } = useRoomPlan();

async function startScan() {
  try {
    await startRoomPlan("My Scan");
  } catch (error) {
    console.error("Error: ", error);
  }
}
```

`startRoomPlan` is an async function that starts a new instance of a UIViewController with the RoomCaptureViewDelegate and RoomCaptureSessionDelegate protocols from RoomPlan. It provides instructions throughout the scan. Once it's finished, you can either add another room to the structure or export what you have. You are then redirected back to the previous screen you were on.

It accepts one parameter, a string for the name of the exported USDZ and JSON from RoomPlan. You can also add other options by providing a config object to the hook:

```
const { startRoomPlan } = useRoomPlan({ exportType: ExportType.Mesh, sendFileLoc: true });
```

By default, it exports to parametric generates an ActivityViewController to share via AirDrop or email or other methods.

There are three export types:

- parametric
- mesh
- model

You can read more about them here: [Apple - RoomPlan USD Export Options](https://developer.apple.com/documentation/roomplan/capturedroom/usdexportoptions)

`sendFileLoc` is an option that lets you opt out of the ActivityViewController flow and receive the URLs of the exported files manually.

There's also a const called `roomScanStatus` that the hook returns:

```
const { roomScanStatus } = useRoomPlan();
```

It watches the internal status of the scan. It has 4 different states:

- Not Started
- Canceled
- Error
- OK

## RoomPlanView

This tutorial shows how to embed the native RoomPlan scanning UI directly with RoomPlanView and control it imperatively via props.

1. Render a full-screen overlay with basic controls.

```tsx
import React, { useState } from "react";
import { SafeAreaView, View, Text, Pressable, StyleSheet } from "react-native";
import { RoomPlanView, ExportType } from "expo-roomplan";

export default function SimpleRoomPlanScreen() {
  const [show, setShow] = useState(false);
  const [running, setRunning] = useState(false);
  const [finishTrigger, setFinishTrigger] = useState<number | undefined>();
  const [addAnotherTrigger, setAddAnotherTrigger] = useState<
    number | undefined
  >();

  return (
    <SafeAreaView style={{ flex: 1 }}>
      <Pressable
        onPress={() => {
          setShow(true);
          setRunning(true);
        }}
      >
        <Text>Start Scan</Text>
      </Pressable>

      {show && (
        <View style={StyleSheet.absoluteFill}>
          <RoomPlanView
            style={StyleSheet.absoluteFill}
            scanName="MyRoom"
            exportType={ExportType.Parametric}
            sendFileLoc
            running={running}
            finishTrigger={finishTrigger}
            addAnotherTrigger={addAnotherTrigger}
            onStatus={(e) => console.log("status", e.nativeEvent)}
            onPreview={() => console.log("preview")}
            onExported={(e) => console.log("exported", e.nativeEvent)}
          />

          <SafeAreaView
            style={{
              position: "absolute",
              top: 16,
              left: 16,
              right: 16,
              flexDirection: "row",
              justifyContent: "space-between",
            }}
          >
            <Pressable
              onPress={() => {
                setRunning(false);
                setShow(false);
              }}
            >
              <Text>Cancel</Text>
            </Pressable>
            <Pressable onPress={() => setFinishTrigger(Date.now())}>
              <Text>Finish</Text>
            </Pressable>
            <Pressable onPress={() => setAddAnotherTrigger(Date.now())}>
              <Text>Add Room</Text>
            </Pressable>
          </SafeAreaView>
        </View>
      )}
    </SafeAreaView>
  );
}
```

2. Finish stops capture, shows Apple’s preview, then exports automatically if exportOnFinish is true (default). Add Room stops and restarts to accumulate more rooms.

## useRoomPlanView

Prefer this hook to avoid manually juggling triggers. It returns the props to spread onto RoomPlanView, controller methods, and state.

```tsx
import React, { useEffect, useState } from "react";
import { SafeAreaView, View, Text, Pressable, StyleSheet } from "react-native";
import { RoomPlanView, useRoomPlanView, ExportType } from "expo-roomplan";

export default function HookDemo() {
  const [overlay, setOverlay] = useState(false);
  const { viewProps, controls, state } = useRoomPlanView({
    scanName: "HookRoom",
    exportType: ExportType.Parametric,
    exportOnFinish: true,
    sendFileLoc: true,
    autoCloseOnTerminalStatus: true,
    onStatus: (e) => console.log("status", e.nativeEvent),
    onPreview: () => console.log("preview"),
    onExported: (e) => console.log("exported", e.nativeEvent),
  });

  useEffect(() => {
    if (overlay && !state.isRunning) setOverlay(false);
  }, [overlay, state.isRunning]);

  return (
    <SafeAreaView style={{ flex: 1 }}>
      <Pressable
        onPress={() => {
          setOverlay(true);
          controls.start();
        }}
      >
        <Text>Open Scanner</Text>
      </Pressable>
      {overlay && (
        <View style={StyleSheet.absoluteFill}>
          <RoomPlanView style={StyleSheet.absoluteFill} {...viewProps} />
          <SafeAreaView
            style={{
              position: "absolute",
              top: 16,
              left: 16,
              right: 16,
              flexDirection: "row",
              justifyContent: "space-between",
            }}
          >
            <Pressable
              onPress={() => {
                controls.cancel();
                setOverlay(false);
              }}
            >
              <Text>Cancel</Text>
            </Pressable>
            <Pressable onPress={controls.finishScan}>
              <Text>Finish</Text>
            </Pressable>
            <Pressable onPress={controls.addRoom}>
              <Text>Add Room</Text>
            </Pressable>
          </SafeAreaView>
        </View>
      )}
    </SafeAreaView>
  );
}
```

## RoomPlanProvider

Use the provider to control RoomPlanView anywhere in a subtree via context. Render RoomPlanViewConsumer or call useRoomPlanContext for controls/state.

```tsx
import React, { useState, useEffect } from "react";
import { SafeAreaView, View, Text, Pressable, StyleSheet } from "react-native";
import {
  RoomPlanProvider,
  RoomPlanViewConsumer,
  useRoomPlanContext,
  ExportType,
} from "expo-roomplan";

function TopBar({ onClose }: { onClose: () => void }) {
  const { controls } = useRoomPlanContext();
  return (
    <SafeAreaView
      style={{
        position: "absolute",
        top: 16,
        left: 16,
        right: 16,
        flexDirection: "row",
        justifyContent: "space-between",
      }}
    >
      <Pressable
        onPress={() => {
          controls.cancel();
          onClose();
        }}
      >
        <Text>Cancel</Text>
      </Pressable>
      <Pressable onPress={controls.finishScan}>
        <Text>Finish</Text>
      </Pressable>
      <Pressable onPress={controls.addRoom}>
        <Text>Add Room</Text>
      </Pressable>
    </SafeAreaView>
  );
}

export default function ContextDemo() {
  const [overlay, setOverlay] = useState(false);
  return (
    <RoomPlanProvider
      scanName="ContextRoom"
      exportType={ExportType.Parametric}
      exportOnFinish
      sendFileLoc
      autoCloseOnTerminalStatus
    >
      <Inner overlay={overlay} setOverlay={setOverlay} />
    </RoomPlanProvider>
  );
}

function Inner({
  overlay,
  setOverlay,
}: {
  overlay: boolean;
  setOverlay: (v: boolean) => void;
}) {
  const { controls, state } = useRoomPlanContext();
  useEffect(() => {
    if (overlay && !state.isRunning) setOverlay(false);
  }, [overlay, state.isRunning]);
  return (
    <SafeAreaView style={{ flex: 1 }}>
      <Pressable
        onPress={() => {
          setOverlay(true);
          controls.start();
        }}
      >
        <Text>Open with Context</Text>
      </Pressable>
      {overlay && (
        <View style={StyleSheet.absoluteFill}>
          <RoomPlanViewConsumer style={StyleSheet.absoluteFill as any} />
          <TopBar onClose={() => setOverlay(false)} />
        </View>
      )}
    </SafeAreaView>
  );
}
```

## RoomPlanView (Reference)

Props

| Prop              | Type                                                | Default    | Description                                                                 |
| ----------------- | --------------------------------------------------- | ---------- | --------------------------------------------------------------------------- |
| scanName          | string                                              | "Room"     | Base filename for exported .usdz and .json.                                 |
| exportType        | ExportType                                          | Parametric | Export mode: Parametric, Mesh, or Model.                                    |
| sendFileLoc       | boolean                                             | false      | When true, onExported includes file URLs rather than showing a share sheet. |
| running           | boolean                                             | false      | Starts/stops scanning. Toggle true to begin; false to stop.                 |
| exportTrigger     | number                                              | —          | Bump to trigger export. Queued if no room captured yet.                     |
| finishTrigger     | number                                              | —          | Bump to stop capture and present Apple’s preview UI.                        |
| addAnotherTrigger | number                                              | —          | Bump to finish current room and immediately start another.                  |
| exportOnFinish    | boolean                                             | true       | If true, finishing also exports after preview.                              |
| style             | ViewStyle                                           | —          | Standard React Native style prop.                                           |
| onStatus          | ({ nativeEvent: { status, errorMessage? }}) => void | —          | Receives status updates: OK, Error, Canceled, etc.                          |
| onPreview         | () => void                                          | —          | Called when preview UI is presented.                                        |
| onExported        | ({ nativeEvent: { scanUrl?, jsonUrl? }}) => void    | —          | Emitted after export; URLs when sendFileLoc is true.                        |

Notes

- Finish and Add Room are edge-triggered by changing the trigger numbers (e.g. Date.now()).
- Export is queued until the first processed room exists; no premature "No rooms captured" errors.

## useRoomPlanView (Reference)

Options

| Option                    | Type       | Default    | Description                                           |
| ------------------------- | ---------- | ---------- | ----------------------------------------------------- |
| scanName                  | string     | —          | Base filename for export.                             |
| exportType                | ExportType | Parametric | Export mode.                                          |
| exportOnFinish            | boolean    | true       | Auto-export after finish.                             |
| sendFileLoc               | boolean    | true       | Include file URLs in onExported.                      |
| autoCloseOnTerminalStatus | boolean    | false      | Automatically set running=false on OK/Error/Canceled. |
| onStatus                  | function   | —          | Intercepts status events.                             |
| onPreview                 | function   | —          | Intercepts preview event.                             |
| onExported                | function   | —          | Intercepts exported event.                            |

Return shape

| Key       | Type              | Description                                                     |
| --------- | ----------------- | --------------------------------------------------------------- |
| viewProps | RoomPlanViewProps | Spread onto RoomPlanView.                                       |
| controls  | object            | { start, cancel, finishScan, addRoom, exportScan, reset }.      |
| state     | object            | { isRunning, status, isPreviewVisible, lastExport, lastError }. |

## RoomPlanProvider (Reference)

Props: identical to useRoomPlanView options. Provides a context with the same return shape as the hook.

Exports

- RoomPlanProvider: wraps a subtree and initialises the controller and state.
- useRoomPlanContext(): returns { viewProps, controls, state } from context.
- RoomPlanViewConsumer: convenience component to render RoomPlanView using viewProps from context.

# Installation in managed Expo projects

For a step-by-step guide on using this library in a managed Expo app (including privacy manifests and the config plugin), see the tutorial [here](./example-managed/README.md).

# Installation in bare React Native projects

For bare React Native projects, you must ensure that you have [installed and configured the `expo` package](https://docs.expo.dev/bare/installing-expo-modules/) before continuing.

### Add the package to your npm dependencies

```
npm install expo-roomplan
```

Add this to your `expo-module.config.json`:

```
{
  "platforms": ["android", "ios"],
  "android": {
    "moduleName": "ExpoRoomPlan"
  }
}
```

### Configure for Android

Only compatible with iOS 17.0 or higher.

### Configure for iOS

Only compatible with iOS 17.0 or higher.

Run `npx pod-install` after installing the npm package.

# Contributing

Contributions are very welcome! Please refer to guidelines described in the [contributing guide](https://github.com/expo/expo#contributing).

### Development Notes

Replace `YOUR_TEAM_ID` with a real development team in the example project.