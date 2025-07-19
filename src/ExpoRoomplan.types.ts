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

export interface ExpoRoomPlanModuleType {
  startCapture(scanName: string, exportType?: ExportType): Promise<void>;
  stopCapture(): Promise<void>;
  // test
  addListener?(eventName: string, listener: (event: any) => void): { remove: () => void };
  removeListeners?(count: number): void;
}

export interface UseRoomPlanInterface {
  startRoomPlan: (scanName: string, exportType?: ExportType) => Promise<void>;
  roomScanStatus: ScanStatus;
}

export interface UseRoomPlanParams {
  exportType?: ExportType
}