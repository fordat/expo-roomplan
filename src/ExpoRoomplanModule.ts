// import { NativeModule, requireNativeModule } from 'expo';

// import { ExpoRoomplanModule } from './ExpoRoomplan.types';

// declare class ExpoRoomplanModule extends NativeModule<ExpoRoomplanModuleEvents> {
//   PI: number;
//   hello(): string;
//   setValueAsync(value: string): Promise<void>;
// }

// // This call loads the native module object from the JSI.
// export default requireNativeModule<ExpoRoomplanModule>('ExpoRoomplan');

import type { ExpoRoomplanModuleType } from './ExpoRoomplan.types';
import { requireNativeModule } from 'expo-modules-core';

const ExpoRoomplan = requireNativeModule<ExpoRoomplanModuleType>('ExpoRoomplan');
export default ExpoRoomplan;

// declare class ExpoRoomplanModule extends NativeModule<ExpoRoomplanModuleType> {
//   startCapture(scanName: string, apiToken: string, apiURL: string): void;
//   stopCapture(): void;
// }

// export default requireNativeModule<ExpoRoomplanModule>('ExpoRoomplan');


// const ExpoRoomplanModule = requireNativeModule<ExpoRoomplanModuleType>('ExpoRoomplan');

// export function startCapture(scanName: string, apiToken: string, apiURL: string): void {
//   ExpoRoomplanModule.startCapture(scanName, apiToken, apiURL);
// }

// export function stopCapture(): void {
//   ExpoRoomplanModule.stopCapture();
// }

// export default ExpoRoomplanModule