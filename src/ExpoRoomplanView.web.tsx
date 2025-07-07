import * as React from 'react';

import { ExpoRoomplanViewProps } from './ExpoRoomplan.types';

export default function ExpoRoomplanView(props: ExpoRoomplanViewProps) {
  return (
    <div>
      <iframe
        style={{ flex: 1 }}
        src={props.url}
        onLoad={() => props.onLoad({ nativeEvent: { url: props.url } })}
      />
    </div>
  );
}
