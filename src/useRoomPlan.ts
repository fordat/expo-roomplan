import { useEffect, useState } from 'react';
import { Platform } from 'react-native';
import ExpoRoomplan from './ExpoRoomplanModule';
import { ScanStatus, UseRoomPlanInterface, UseRoomPlanParams } from './ExpoRoomplan.types';

export default function useRoomPlan(params?: UseRoomPlanParams): UseRoomPlanInterface {
  const [roomScanStatus, setRoomScanStatus] = useState<ScanStatus>(ScanStatus.NotStarted);

  useEffect(() => {
    const sub = ExpoRoomplan.addListener?.('onDismissEvent', (event: { value: ScanStatus }) => {
      setRoomScanStatus(event.value);
      console.log("RoomScan status: ", event.value);
    });

    return () => {
      sub?.remove();
    };
  }, []);

  const startRoomPlan = async (scanName: string) => {
    if (Platform.OS === "android") {
      throw new Error("RoomPlan SDK only available on iOS.");
    }
    try {
      // optional ExportType from params. defaults internally to "parametric"
      if (params?.exportType) {
        await ExpoRoomplan.startCapture(scanName, params.exportType);
      } else {
        await ExpoRoomplan.startCapture(scanName);
      }
    } catch (err) {
      console.error('startCapture failed:', err);
      throw err;
    }
  };

  return {
    startRoomPlan,
    roomScanStatus,
  };
}