import { useEffect, useState } from 'react';
import { Platform } from 'react-native';
import ExpoRoomPlan from './ExpoRoomPlanModule';
import { ScanStatus, UseRoomPlanInterface, UseRoomPlanParams } from './ExpoRoomPlan.types';

export default function useRoomPlan(params?: UseRoomPlanParams): UseRoomPlanInterface {
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
      // optional ExportType from params. defaults internally to 'parametric'
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
    scanUrl,
    jsonUrl,
  };
}