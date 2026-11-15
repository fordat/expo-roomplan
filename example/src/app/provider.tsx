import { ScrollView, StyleSheet } from "react-native";
import { Stack } from "expo-router";
import {
  ExportType,
  RoomPlanProvider,
  RoomPlanViewConsumer,
  useRoomPlanContext,
} from "expo-roomplan";

import { ScannerOverlay } from "@/components/ScannerOverlay";
import { Field, PrimaryButton, Section } from "@/components/ui";

/**
 * <RoomPlanProvider> runs useRoomPlanView() once and shares the result via
 * context. The components below never receive scanner props; each one pulls
 * what it needs from useRoomPlanContext().
 */
export default function ProviderDemo() {
  return (
    <RoomPlanProvider
      scanName="ProviderScan"
      exportType={ExportType.Parametric}
      exportOnFinish
      sendFileLoc
      onStatus={(e) => console.log("[provider] status", e.nativeEvent)}
      onExported={(e) => console.log("[provider] exported", e.nativeEvent)}
    >
      <Screen />
    </RoomPlanProvider>
  );
}

function Screen() {
  const { state } = useRoomPlanContext();
  return (
    <>
      <Stack.Screen options={{ headerShown: !state.isRunning }} />
      {state.isRunning ? <Scanner /> : <Idle />}
    </>
  );
}

function Scanner() {
  const { controls, state } = useRoomPlanContext();
  return (
    <ScannerOverlay
      // RoomPlanViewConsumer = <RoomPlanView {...viewProps} /> from context.
      scanner={<RoomPlanViewConsumer style={StyleSheet.absoluteFill} />}
      controls={controls}
      state={state}
    />
  );
}

function Idle() {
  const { controls } = useRoomPlanContext();
  return (
    <ScrollView contentContainerStyle={styles.container}>
      <PrimaryButton title="Open scanner" onPress={controls.start} />
      <LastResult />
    </ScrollView>
  );
}

function LastResult() {
  const { state } = useRoomPlanContext();
  return (
    <Section title="Last result">
      <Field label="Status" value={state.status ?? "—"} />
      <Field label="USDZ" value={state.lastExport?.scanUrl} />
      <Field label="JSON" value={state.lastExport?.jsonUrl} />
      <Field label="Error" value={state.lastError} error />
    </Section>
  );
}

const styles = StyleSheet.create({
  container: { padding: 16, gap: 16 },
});
