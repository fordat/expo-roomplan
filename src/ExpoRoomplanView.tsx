import { requireNativeView } from 'expo';
import * as React from 'react';

import { ExpoRoomplanViewProps } from './ExpoRoomplan.types';

const NativeView: React.ComponentType<ExpoRoomplanViewProps> =
  requireNativeView('ExpoRoomplan');

export default function ExpoRoomplanView(props: ExpoRoomplanViewProps) {
  return <NativeView {...props} />;
}
