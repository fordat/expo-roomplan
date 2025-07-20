import { useEffect, useState } from 'react';
import { Platform } from 'react-native';
import ExpoRoomPlan from './ExpoRoomPlanModule';
import { UseRoomPlanParams, ScanStatus, UseRoomPlanInterface, ExportType } from './ExpoRoomPlan.types';

export default function useRoomPlan(params?: UseRoomPlanParams): UseRoomPlanInterface {
  const [roomScanStatus, setRoomScanStatus] = useState<ScanStatus>(ScanStatus.NotStarted);
  const [scanUrl, setScanUrl] = useState<null | string>(null)
  const [jsonUrl, setJsonUrl] = useState<null | string>(null)

  useEffect(() => {
    const sub = ExpoRoomPlan.addListener?.('onDismissEvent', (event: { status: ScanStatus, scanUrl?: string, jsonUrl?: string }) => {
      setRoomScanStatus(event.status);
      console.log('RoomScan status: ', event.status);
      if (event.scanUrl) {
        setScanUrl(event.scanUrl);
        console.log('Scan URL: ', event.scanUrl);
      }
      if (event.jsonUrl) {
        setJsonUrl(event.jsonUrl);
        console.log('JSON URL: ', event.jsonUrl);
      }
    });

    return () => {
      sub?.remove();
    };
  }, []);

  const startRoomPlan = async (scanName: string) => {
    if (Platform.OS === 'android') {
      throw new Error('RoomPlan SDK only available on iOS.');
    }
    try {
      // ExportType: defaults internally to 'parametric'
      // Model file location is not returned by default.
      const exportType = params?.exportType ?? ExportType.Parametric;
      const sendFileLoc = params?.sendFileLoc ?? false;
      ExpoRoomPlan.startCapture(scanName, exportType, sendFileLoc);
    } catch (err) {
      console.error('startCapture failed:', err);
      throw err;
    }
  };

  return {
    startRoomPlan,
    roomScanStatus,
    scanUrl,
    jsonUrl,
  };
}