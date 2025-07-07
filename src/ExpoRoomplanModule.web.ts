import { registerWebModule, NativeModule } from 'expo';

import { ExpoRoomplanModuleEvents } from './ExpoRoomplan.types';

class ExpoRoomplanModule extends NativeModule<ExpoRoomplanModuleEvents> {
  PI = Math.PI;
  async setValueAsync(value: string): Promise<void> {
    this.emit('onChange', { value });
  }
  hello() {
    return 'Hello world! 👋';
  }
}

export default registerWebModule(ExpoRoomplanModule, 'ExpoRoomplanModule');
