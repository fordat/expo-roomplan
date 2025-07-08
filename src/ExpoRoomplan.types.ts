export enum ScanStatus {
  NotStarted = 'NotStarted',
  PermissionDenied = 'PermissionDenied',
  Canceled = 'Canceled',
  TimedOut = 'TimedOut',
  Error = 'Error',
  OK = 'OK',
}

export interface ExpoRoomplanModuleType {
  startCapture(scanName: string, apiToken?: string, apiURL?: string): Promise<void>;
  stopCapture(): Promise<void>;
  // test
  addListener?(eventName: string, listener: (event: any) => void): { remove: () => void };
  removeListeners?(count: number): void;
}