import { useEffect, useState } from 'react';
import { requireNativeModule } from 'expo-modules-core';

import type { ExpoRoomplanModuleType } from './ExpoRoomplan.types';

export enum ScanStatus {
  NotStarted = 'NotStarted',
  PermissionDenied = 'PermissionDenied',
  Canceled = 'Canceled',
  TimedOut = 'TimedOut',
  Error = 'Error',
  OK = 'OK',
}

const RoomPlan = requireNativeModule<ExpoRoomplanModuleType>('ExpoRoomplan');

export interface UseRoomPlanInterface {
  startRoomPlan: (scanName: string, api?: { url: string; token: string }) => Promise<void>;
  roomScanStatus: ScanStatus;
}

export default function useRoomplan(): UseRoomPlanInterface {
  const [roomScanStatus, setRoomScanStatus] = useState<ScanStatus>(ScanStatus.NotStarted);

  useEffect(() => {
    const sub = RoomPlan.addListener?.('onDismissEvent', (event: { value: ScanStatus }) => {
      setRoomScanStatus(event.value);
    });

    return () => {
      sub?.remove();
    };
  }, []);

  const startRoomPlan = async (scanName: string, api?: { url: string; token: string }) => {
    try {
      if (api) {
        await RoomPlan.startCapture(scanName, api.token, api.url);
      } else {
        await RoomPlan.startCapture(scanName);
      }
    } catch (err) {
      console.error('[RoomPlan] startCapture failed:', err);
      throw new Error('Unable to start room scan.');
    }
  };

  return {
    startRoomPlan,
    roomScanStatus,
  };
}