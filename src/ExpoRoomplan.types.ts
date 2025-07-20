export enum ScanStatus {
  NotStarted = "NotStarted",
  Canceled = "Canceled",
  Error = "Error",
  OK = "OK",
}

export enum ExportType {
  Parametric = "PARAMETRIC",
  Mesh = "MESH",
  Model = "MODEL",
}

export interface CaptureOptions {
  exportType?: ExportType,
  sendFileLoc?: boolean,
}

export interface ExpoRoomPlanModuleType {
  startCapture(scanName: string, options?: CaptureOptions): Promise<void>;
  stopCapture(): Promise<void>;
  // test
  addListener?(eventName: string, listener: (event: any) => void): { remove: () => void };
  removeListeners?(count: number): void;
}

export interface UseRoomPlanInterface {
  startRoomPlan: (scanName: string) => Promise<void>;
  roomScanStatus: ScanStatus;
  jsonUrl: string | null;
  scanUrl: string | null;
}