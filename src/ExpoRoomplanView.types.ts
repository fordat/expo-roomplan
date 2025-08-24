import type { ViewProps, StyleProp, ViewStyle } from "react-native";
import type { ScanStatus, ExportType } from "./ExpoRoomplan.types";

/**
 * Props for {@link RoomPlanView}.
 */
export interface RoomPlanViewProps extends ViewProps {
  /** Base filename (no extension) for the exported files. */
  scanName?: string;
  /** Export mode for the USDZ model. */
  exportType?: ExportType;
  /**
   * When true, {@link onExported} will include the file URLs of the exported `.usdz` and `.json` files
   * instead of presenting the system share sheet.
   */
  sendFileLoc?: boolean;
  /** Start/stop the scanning session. */
  running?: boolean; // start/stop scanning
  /**
   * Bump this numeric value (e.g. with Date.now()) to trigger an export.
   * If no rooms have been captured yet, the export is queued until one is available.
   */
  exportTrigger?: number; // bump to trigger an export
  // Stop scanning and present the RoomPlan preview UI. Bump the number to trigger.
  /** Bump to stop capture and present the iOS preview UI. */
  finishTrigger?: number;
  // Continue scanning and accumulate additional rooms. Bump the number to trigger.
  /** Bump to finish the current room and immediately start a new capture. */
  addAnotherTrigger?: number;
  // If true (default), finish will also export the result once ready
  /** When true, finishing a capture automatically exports once preview is shown. */
  exportOnFinish?: boolean;
  /** Standard React Native style prop. */
  style?: StyleProp<ViewStyle>;
  /** Receives status updates such as OK, Error, and Canceled. */
  onStatus?: (e: {
    nativeEvent: { status: ScanStatus; errorMessage?: string };
  }) => void;
  /** Called when the native preview UI is presented after finishing a scan. */
  onPreview?: () => void;
  /** Emitted after export; includes file URLs when `sendFileLoc` is true. */
  onExported?: (e: {
    nativeEvent: { scanUrl?: string; jsonUrl?: string };
  }) => void;
}
