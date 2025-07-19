import { useEffect, useState } from 'react';
import { Platform } from 'react-native';
import ExpoRoomPlan from './ExpoRoomPlanModule';
import { ScanStatus, UseRoomPlanInterface, UseRoomPlanParams } from './ExpoRoomPlan.types';

export default function useRoomPlan(params?: UseRoomPlanParams): UseRoomPlanInterface {
  const [roomScanStatus, setRoomScanStatus] = useState<ScanStatus>(ScanStatus.NotStarted);

  useEffect(() => {
    const sub = ExpoRoomPlan.addListener?.('onDismissEvent', (event: { value: ScanStatus }) => {
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
        await ExpoRoomPlan.startCapture(scanName, params.exportType);
      } else {
        await ExpoRoomPlan.startCapture(scanName);
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