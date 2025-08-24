import React, { useEffect, useState } from "react";
import { SafeAreaView, StyleSheet, Text, View, Pressable } from "react-native";
import {
  RoomPlanProvider,
  RoomPlanViewConsumer,
  useRoomPlanContext,
} from "expo-roomplan";
import type { ExportType, ScanStatus } from "expo-roomplan";

function ControlsBar({ onClose }: { onClose: () => void }) {
  const { controls } = useRoomPlanContext();
  return (
    <SafeAreaView style={styles.topBar}>
      <Pressable
        onPress={() => {
          controls.cancel();
          onClose();
        }}
        style={[styles.chip, styles.chipCancel]}
      >
        <Text style={styles.chipText}>Cancel</Text>
      </Pressable>
      <Pressable
        onPress={controls.finishScan}
        style={[styles.chip, styles.chipFinish]}
      >
        <Text style={styles.chipText}>Finish</Text>
      </Pressable>
      <Pressable
        onPress={controls.addRoom}
        style={[styles.chip, styles.chipFinish]}
      >
        <Text style={styles.chipText}>Add Room</Text>
      </Pressable>
    </SafeAreaView>
  );
}

export default function ContextDemoScreen() {
  const [showScanner, setShowScanner] = useState(false);

  return (
    <RoomPlanProvider
      scanName="ContextRoom"
      exportType={"PARAMETRIC" as ExportType}
      exportOnFinish
      sendFileLoc
      onStatus={(e: {
        nativeEvent: { status: ScanStatus; errorMessage?: string };
      }) => {
        const { status, errorMessage } = e.nativeEvent;
        console.log("[Context Demo] status:", status, errorMessage ?? "");
      }}
      onPreview={() => console.log("[Context Demo] preview")}
      onExported={(e) => console.log("[Context Demo] exported", e.nativeEvent)}
    >
      <ContextDemoInner
        showScanner={showScanner}
        setShowScanner={setShowScanner}
      />
    </RoomPlanProvider>
  );
}

function ContextDemoInner({
  showScanner,
  setShowScanner,
}: {
  showScanner: boolean;
  setShowScanner: (v: boolean) => void;
}) {
  const { controls, state } = useRoomPlanContext();

  useEffect(() => {
    if (showScanner && !state.isRunning) {
      setShowScanner(false);
    }
  }, [state.isRunning, showScanner, setShowScanner]);

  return (
    <SafeAreaView style={styles.safe}>
      <View style={styles.stepContainer}>
        <Pressable
          onPress={() => {
            setShowScanner(true);
            controls.start();
          }}
          style={styles.primaryButton}
        >
          <Text style={styles.primaryButtonText}>Open with Context</Text>
        </Pressable>
      </View>
      {showScanner && (
        <View style={styles.overlay}>
          <RoomPlanViewConsumer style={StyleSheet.absoluteFill} />
          <ControlsBar onClose={() => setShowScanner(false)} />
        </View>
      )}
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  overlay: {
    ...StyleSheet.absoluteFillObject,
    zIndex: 100,
    height: "100%",
  },
  safe: {
    height: "100%",
  },
  stepContainer: {
    gap: 8,
    marginBottom: 8,
  },
  primaryButton: {
    backgroundColor: "#007AFF",
    paddingVertical: 12,
    paddingHorizontal: 16,
    borderRadius: 12,
    alignSelf: "flex-start",
  },
  primaryButtonText: {
    color: "white",
    fontWeight: "600",
    fontSize: 16,
  },
  topBar: {
    position: "absolute",
    top: 20,
    left: 16,
    right: 16,
    flexDirection: "row",
    justifyContent: "space-between",
    alignItems: "center",
  },
  chip: {
    paddingVertical: 8,
    paddingHorizontal: 12,
    borderRadius: 10,
    backgroundColor: "rgba(0,0,0,0.6)",
  },
  chipCancel: {
    backgroundColor: "rgba(0,0,0,0.6)",
  },
  chipFinish: {
    backgroundColor: "rgba(0,0,0,0.6)",
  },
  chipText: {
    color: "white",
    fontWeight: "700",
  },
});
