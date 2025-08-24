import { useCallback, useMemo, useRef, useState } from "react";
import type { RoomPlanViewProps } from "./ExpoRoomplanView.types";
import type { ExportType, ScanStatus } from "./ExpoRoomplan.types";

/**
 * Options for {@link useRoomPlanView}.
 */
export type UseRoomPlanViewOptions = {
  /** Base filename (no extension) for the exported files. */
  scanName?: string;
  /** Export mode for the USDZ model. */
  exportType?: ExportType;
  /** If true, finishing a capture also triggers export automatically. Defaults to `true`. */
  exportOnFinish?: boolean;
  /** When true, onExported receives file URLs instead of showing a share sheet. Defaults to `true`. */
  sendFileLoc?: boolean;
  /** Automatically stop scanning when status becomes OK, Error, or Canceled. Defaults to `false`. */
  autoCloseOnTerminalStatus?: boolean;
  /** Tap into status updates from the native view. */
  onStatus?: NonNullable<RoomPlanViewProps["onStatus"]>;
  /** Called when the native preview UI is presented after finishing a scan. */
  onPreview?: RoomPlanViewProps["onPreview"];
  /** Called after export completes with file URLs when `sendFileLoc` is true. */
  onExported?: NonNullable<RoomPlanViewProps["onExported"]>;
};

/**
 * Return type of {@link useRoomPlanView}.
 */
export type UseRoomPlanViewReturn = {
  viewProps: RoomPlanViewProps;
  controls: {
    /** Start a new scanning session. */
    start: () => void;
    /** Stop the current scanning session without exporting. */
    cancel: () => void;
    /** Stop capture and present the iOS preview UI (then export if `exportOnFinish` is true). */
    finishScan: () => void;
    /** Finish the current room and immediately start capturing another. */
    addRoom: () => void;
    /** Trigger export manually. Queued until a room is available if called too early. */
    exportScan: () => void;
    /** Reset all local hook state and triggers to an initial idle state. */
    reset: () => void;
  };
  state: {
    /** Whether the native view is currently scanning. */
    isRunning: boolean;
    /** Latest status reported by the native view. */
    status?: ScanStatus;
    /** True once the iOS preview UI has been presented for the current finish flow. */
    isPreviewVisible: boolean;
    /** Details of the last successful export, if any. */
    lastExport?: { scanUrl?: string; jsonUrl?: string };
    /** Last error message received from the native view, if any. */
    lastError?: string;
  };
};

/**
 * React hook that controls the {@link RoomPlanView} and exposes a friendly API.
 *
 * It returns `viewProps` to spread onto the component, `controls` with imperative methods (start, cancel,
 * finishScan, addRoom, exportScan, reset), and `state` reflecting the current scanning lifecycle.
 *
 * @example
 * ```tsx
 * const { viewProps, controls } = useRoomPlanView({ scanName: 'Demo' });
 * return (
 *   <>
 *     <RoomPlanView {...viewProps} style={StyleSheet.absoluteFill} />
 *     <Button onPress={controls.finishScan} title="Finish" />
 *   </>
 * );
 * ```
 */
export function useRoomPlanView(
  options: UseRoomPlanViewOptions = {}
): UseRoomPlanViewReturn {
  const {
    scanName,
    exportType,
    exportOnFinish = true,
    sendFileLoc = true,
    autoCloseOnTerminalStatus = false,
    onStatus,
    onPreview,
    onExported,
  } = options;

  // Internal control state
  const [running, setRunning] = useState(false);
  const [finishTrigger, setFinishTrigger] = useState<number | undefined>();
  const [addAnotherTrigger, setAddAnotherTrigger] = useState<
    number | undefined
  >();
  const [exportTrigger, setExportTrigger] = useState<number | undefined>();

  // Derived UI state
  const [status, setStatus] = useState<ScanStatus | undefined>(undefined);
  const [isPreviewVisible, setPreviewVisible] = useState(false);
  const [lastExport, setLastExport] = useState<
    { scanUrl?: string; jsonUrl?: string } | undefined
  >(undefined);
  const [lastError, setLastError] = useState<string | undefined>(undefined);

  // Cache callbacks refs to avoid stale closures in event handlers
  const optsRef = useRef({
    onStatus,
    onPreview,
    onExported,
    autoCloseOnTerminalStatus,
  });
  optsRef.current = {
    onStatus,
    onPreview,
    onExported,
    autoCloseOnTerminalStatus,
  };

  // Controller methods
  const start = useCallback(() => {
    setRunning(true);
    setPreviewVisible(false);
    setLastError(undefined);
  }, []);

  const cancel = useCallback(() => {
    setRunning(false);
  }, []);

  const finishScan = useCallback(() => {
    setFinishTrigger(Date.now());
  }, []);

  const addRoom = useCallback(() => {
    setAddAnotherTrigger(Date.now());
    setPreviewVisible(false);
  }, []);

  const exportScan = useCallback(() => {
    setExportTrigger(Date.now());
  }, []);

  const reset = useCallback(() => {
    setRunning(false);
    setFinishTrigger(undefined);
    setAddAnotherTrigger(undefined);
    setExportTrigger(undefined);
    setPreviewVisible(false);
    setStatus(undefined);
    setLastError(undefined);
    setLastExport(undefined);
  }, []);

  // Event handlers that keep internal state in sync but forward to user callbacks
  const handleStatus: NonNullable<RoomPlanViewProps["onStatus"]> = useCallback(
    (e) => {
      const s = e.nativeEvent.status as ScanStatus;
      const errorMessage = e.nativeEvent.errorMessage;
      setStatus(s);
      if (errorMessage) setLastError(errorMessage);
      if (optsRef.current.onStatus) optsRef.current.onStatus(e);

      if (optsRef.current.autoCloseOnTerminalStatus) {
        if (s === "OK" || s === "Error" || s === "Canceled") {
          setRunning(false);
        }
      }
    },
    []
  );

  const handlePreview = useCallback(() => {
    setPreviewVisible(true);
    if (optsRef.current.onPreview) optsRef.current.onPreview();
  }, []);

  const handleExported: NonNullable<RoomPlanViewProps["onExported"]> =
    useCallback((e) => {
      setLastExport({ ...e.nativeEvent });
      if (optsRef.current.onExported) optsRef.current.onExported(e);
    }, []);

  const viewProps: RoomPlanViewProps = useMemo(
    () => ({
      // Identity props
      scanName,
      exportType,
      exportOnFinish,
      sendFileLoc,
      // Control props
      running,
      finishTrigger,
      addAnotherTrigger,
      exportTrigger,
      // Events
      onStatus: handleStatus,
      onPreview: handlePreview,
      onExported: handleExported,
    }),
    [
      scanName,
      exportType,
      exportOnFinish,
      sendFileLoc,
      running,
      finishTrigger,
      addAnotherTrigger,
      exportTrigger,
      handleStatus,
      handlePreview,
      handleExported,
    ]
  );

  return {
    viewProps,
    controls: { start, cancel, finishScan, addRoom, exportScan, reset },
    state: {
      isRunning: running,
      status,
      isPreviewVisible,
      lastExport,
      lastError,
    },
  };
}
