import { NativeModule, requireNativeModule } from 'expo';

import { ExpoRoomplanModuleEvents } from './ExpoRoomplan.types';

declare class ExpoRoomplanModule extends NativeModule<ExpoRoomplanModuleEvents> {
  PI: number;
  hello(): string;
  setValueAsync(value: string): Promise<void>;
}

// This call loads the native module object from the JSI.
export default requireNativeModule<ExpoRoomplanModule>('ExpoRoomplan');
