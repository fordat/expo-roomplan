import { useState } from "react";
import { Alert, ScrollView, StyleSheet, Text } from "react-native";
import { ExportType, ScanStatus, useRoomPlan } from "expo-roomplan";

import {
  ExportTypePicker,
  Field,
  PrimaryButton,
  Section,
  ToggleRow,
  colors,
} from "@/components/ui";

/**
 * useRoomPlan(): Apple's RoomPlan capture + review UI, presented modally.
 * The hook's return values update when the modal is dismissed.
 */
export default function NativeUiDemo() {
  const [exportType, setExportType] = useState(ExportType.Parametric);
  const [sendFileLoc, setSendFileLoc] = useState(true);

  const { startRoomPlan, roomScanStatus, scanUrl, jsonUrl, errorMessage } = useRoomPlan({
    exportType,
    sendFileLoc,
  });

  const start = async () => {
    try {
      await startRoomPlan("NativeUIScan");
    } catch (e) {
      Alert.alert("Could not start RoomPlan", String(e));
    }
  };

  return (
    <ScrollView contentContainerStyle={styles.container}>
      <Section title="Options">
        <ExportTypePicker value={exportType} onChange={setExportType} />
        <ToggleRow label="Return file URLs" value={sendFileLoc} onChange={setSendFileLoc} />
        <Text style={styles.hint}>
          {sendFileLoc
            ? "Exported file URLs are returned to JS below."
            : "Exports are handed to the iOS share sheet instead."}
        </Text>
      </Section>

      <PrimaryButton title="Start scan" onPress={start} />

      <Section title="Result">
        <Field label="Status" value={roomScanStatus} />
        <Field label="USDZ" value={scanUrl} />
        <Field label="JSON" value={jsonUrl} />
        <Field
          label="Error"
          value={roomScanStatus === ScanStatus.Error ? errorMessage : null}
          error
        />
      </Section>
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  container: { padding: 16, gap: 16 },
  hint: { fontSize: 13, color: colors.muted },
});
