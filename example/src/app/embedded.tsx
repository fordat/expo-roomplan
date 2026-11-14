import { useState } from "react";
import { ScrollView, StyleSheet } from "react-native";
import { Stack } from "expo-router";
import { ExportType, RoomPlanView, useRoomPlanView } from "expo-roomplan";

import { ScannerOverlay } from "@/components/ScannerOverlay";
import { ExportTypePicker, Field, PrimaryButton, Section } from "@/components/ui";

/**
 * useRoomPlanView(): the hook owns scanner state and hands back `viewProps`
 * to spread onto <RoomPlanView>, plus imperative `controls`.
 */
export default function EmbeddedDemo() {
  const [exportType, setExportType] = useState(ExportType.Parametric);

  const { viewProps, controls, state } = useRoomPlanView({
    scanName: "EmbeddedScan",
    exportType,
    exportOnFinish: true,
    sendFileLoc: true,
    // RoomPlan reports OK after every room (including "add another room"),
    // so close the scanner explicitly instead of on the first OK.
    autoCloseOnTerminalStatus: false,
    onStatus: (e) => console.log("[embedded] status", e.nativeEvent),
    onExported: (e) => console.log("[embedded] exported", e.nativeEvent),
  });

  return (
    <>
      <Stack.Screen options={{ headerShown: !state.isRunning }} />

      {state.isRunning ? (
        <ScannerOverlay
          scanner={<RoomPlanView {...viewProps} style={StyleSheet.absoluteFill} />}
          controls={controls}
          state={state}
        />
      ) : (
        <ScrollView contentContainerStyle={styles.container}>
          <Section title="Options">
            <ExportTypePicker value={exportType} onChange={setExportType} />
          </Section>

          <PrimaryButton title="Open scanner" onPress={controls.start} />

          <Section title="Last result">
            <Field label="Status" value={state.status ?? "—"} />
            <Field label="USDZ" value={state.lastExport?.scanUrl} />
            <Field label="JSON" value={state.lastExport?.jsonUrl} />
            <Field label="Error" value={state.lastError} error />
          </Section>
        </ScrollView>
      )}
    </>
  );
}

const styles = StyleSheet.create({
  container: { padding: 16, gap: 16 },
});
