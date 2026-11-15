import type { ReactNode } from "react";
import { Pressable, StyleSheet, Text, View } from "react-native";
import { useSafeAreaInsets } from "react-native-safe-area-context";
import type { useRoomPlanView } from "expo-roomplan";

type RoomPlanController = ReturnType<typeof useRoomPlanView>;

/**
 * Full-screen scanner with custom controls drawn on top. `scanner` is the
 * RoomPlanView element; `controls`/`state` come from useRoomPlanView() or
 * useRoomPlanContext().
 */
export function ScannerOverlay({
  scanner,
  controls,
  state,
}: {
  scanner: ReactNode;
  controls: RoomPlanController["controls"];
  state: RoomPlanController["state"];
}) {
  const insets = useSafeAreaInsets();
  // Once the review UI is up the scan is done; closing no longer discards anything.
  const done = state.isPreviewVisible;

  return (
    <View style={StyleSheet.absoluteFill}>
      {scanner}

      <View style={[styles.topBar, { top: insets.top + 8 }]}>
        <Chip title={done ? "Done" : "Cancel"} onPress={controls.cancel} />
        {!done && <Chip title="Finish" onPress={controls.finishScan} />}
      </View>

      {!done && (
        <View style={[styles.bottomBar, { bottom: insets.bottom + 24 }]}>
          <Pressable onPress={controls.addRoom} style={styles.bigButton}>
            <Text style={styles.text}>Add another room</Text>
          </Pressable>
        </View>
      )}
    </View>
  );
}

function Chip({ title, onPress }: { title: string; onPress: () => void }) {
  return (
    <Pressable onPress={onPress} style={styles.chip}>
      <Text style={styles.text}>{title}</Text>
    </Pressable>
  );
}

const styles = StyleSheet.create({
  topBar: {
    position: "absolute",
    left: 16,
    right: 16,
    flexDirection: "row",
    justifyContent: "space-between",
  },
  bottomBar: { position: "absolute", left: 16, right: 16 },
  chip: {
    backgroundColor: "rgba(0,0,0,0.6)",
    borderRadius: 10,
    paddingVertical: 8,
    paddingHorizontal: 14,
  },
  bigButton: {
    backgroundColor: "rgba(0,0,0,0.6)",
    borderRadius: 14,
    paddingVertical: 14,
    alignItems: "center",
  },
  text: { color: "white", fontSize: 16, fontWeight: "700" },
});
