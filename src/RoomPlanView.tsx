import * as React from "react";
import { requireNativeViewManager } from "expo-modules-core";
import type { RoomPlanViewProps } from "./ExpoRoomplanView.types";

const NativeRoomPlanView: React.ComponentType<RoomPlanViewProps> =
  requireNativeViewManager("ExpoRoomPlanView");

/**
 * React component that renders the native iOS RoomPlan scanning UI.
 *
 * Prefer using {@link useRoomPlanView} or {@link RoomPlanProvider} to manage its props,
 * but you can also drive it directly by toggling `running` and bumping the numeric triggers
 * (finishTrigger, addAnotherTrigger, exportTrigger).
 */
export function RoomPlanView(props: RoomPlanViewProps) {
  return <NativeRoomPlanView {...props} />;
}
