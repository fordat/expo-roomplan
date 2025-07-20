import { useEffect, useState } from 'react';
import { Platform } from 'react-native';
import ExpoRoomPlan from './ExpoRoomPlanModule';
import { CaptureOptions, ScanStatus, UseRoomPlanInterface } from './ExpoRoomPlan.types';

export default function useRoomPlan(options?: CaptureOptions): UseRoomPlanInterface {
  const [roomScanStatus, setRoomScanStatus] = useState<ScanStatus>(ScanStatus.NotStarted);
  const [scanUrl, setScanUrl] = useState<null | string>(null)
  const [jsonUrl, setJsonUrl] = useState<null | string>(null)

  useEffect(() => {
    const sub = ExpoRoomPlan.addListener?.('onDismissEvent', (event: { status: ScanStatus, usdzUrl?: string, jsonUrl?: string }) => {
      setRoomScanStatus(event.status);
      console.log('RoomScan status: ', event.status);
      if (event.usdzUrl) {
        setScanUrl(event.usdzUrl);
        console.log('Scan URL: ', event.usdzUrl);
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
      if (options?.exportType || options?.sendFileLoc) {
        await ExpoRoomPlan.startCapture(scanName, options);
      } else if (options?.sendFileLoc) {
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
    scanUrl,
    jsonUrl,
  };
}