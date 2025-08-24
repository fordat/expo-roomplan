import React, { createContext, useContext, PropsWithChildren } from "react";
import { RoomPlanView } from "./RoomPlanView";
import type { RoomPlanViewProps } from "./ExpoRoomplanView.types";
import type {
  UseRoomPlanViewOptions,
  UseRoomPlanViewReturn,
} from "./useRoomPlanView";
import { useRoomPlanView } from "./useRoomPlanView";

/**
 * React Context carrying the RoomPlan controller API and view props returned by {@link useRoomPlanView}.
 *
 * @internal Prefer using {@link RoomPlanProvider} and {@link useRoomPlanContext} instead of consuming this directly.
 */
const RoomPlanContext = createContext<UseRoomPlanViewReturn | undefined>(
  undefined
);

/**
 * Provides RoomPlan controls, state, and view props to a React subtree.
 *
 * Wrap any part of your UI that needs to start/cancel/finish scanning or render the RoomPlanView through
 * {@link RoomPlanViewConsumer}. Under the hood this initialises {@link useRoomPlanView} with the given options.
 *
 * @param props.providerOptions Options passed to {@link useRoomPlanView} plus children.
 * @remarks This is the easiest way to enable cross-tree control without threading props.
 * @example
 * ```tsx
 * <RoomPlanProvider scanName="MyRoom">
 *   <Toolbar />
 *   <RoomPlanViewConsumer style={StyleSheet.absoluteFill} />
 * </RoomPlanProvider>
 * ```
 */
export function RoomPlanProvider(
  props: PropsWithChildren<UseRoomPlanViewOptions>
) {
  const { children, ...options } = props;
  const value = useRoomPlanView(options);
  return (
    <RoomPlanContext.Provider value={value}>
      {children}
    </RoomPlanContext.Provider>
  );
}

/**
 * Access the RoomPlan context created by {@link RoomPlanProvider}.
 *
 * @returns The same shape returned by {@link useRoomPlanView}: `{ viewProps, controls, state }`.
 * @throws If used outside of a {@link RoomPlanProvider}.
 */
export function useRoomPlanContext(): UseRoomPlanViewReturn {
  const ctx = useContext(RoomPlanContext);
  if (!ctx) {
    throw new Error(
      "useRoomPlanContext must be used within a RoomPlanProvider"
    );
  }
  return ctx;
}

/**
 * Convenience component that renders {@link RoomPlanView} using `viewProps` from {@link useRoomPlanContext}.
 *
 * Pass additional view props (e.g. `style`) to override or extend those from context.
 */
export function RoomPlanViewConsumer(props: Partial<RoomPlanViewProps>) {
  const { viewProps } = useRoomPlanContext();
  return <RoomPlanView {...viewProps} {...(props as any)} />;
}
