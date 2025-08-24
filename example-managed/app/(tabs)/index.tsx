import React, { useEffect, useState } from "react";
import { StyleSheet, View, Pressable, Text, SafeAreaView } from "react-native";
import { RoomPlanView, ExportType, useRoomPlanView } from "expo-roomplan";
import type { ScanStatus } from "expo-roomplan";

export default function HomeScreen() {
  const [showScanner, setShowScanner] = useState(false);
  const [scanName] = useState<string>("DemoRoom");
  const exportType: ExportType = ExportType.Parametric;

  const handleStatus = (e: {
    nativeEvent: { status: ScanStatus; errorMessage?: string };
  }) => {
    const { status, errorMessage } = e.nativeEvent;
    console.log(
      "[RoomPlan Demo] status:",
      status,
      errorMessage ? `- ${errorMessage}` : ""
    );
  };

  const handleExported = (e: {
    nativeEvent: { scanUrl?: string; jsonUrl?: string };
  }) => {
    console.log("[RoomPlan Demo] exported:", e.nativeEvent);
  };
  const handlePreview = () => {
    console.log("[RoomPlan Demo] preview presented");
  };

  const { viewProps, controls, state } = useRoomPlanView({
    scanName,
    exportType,
    exportOnFinish: true,
    sendFileLoc: true,
    autoCloseOnTerminalStatus: false,
    onStatus: handleStatus,
    onPreview: handlePreview,
    onExported: handleExported,
  });

  useEffect(() => {
    if (showScanner && !state.isRunning) {
      setShowScanner(false);
    }
  }, [state.isRunning, showScanner]);

  const openScanner = () => {
    setShowScanner(true);
    controls.start();
  };

  const onCancel = () => {
    controls.cancel();
    setShowScanner(false);
  };

  const onNewRoom = () => {
    controls.addRoom();
  };

  const onFinish = () => {
    controls.finishScan();
  };

  return (
    <SafeAreaView style={styles.safe}>
      {/* Launch demo button */}
      <View style={styles.stepContainer}>
        <Pressable onPress={openScanner} style={styles.primaryButton}>
          <Text style={styles.primaryButtonText}>Open RoomPlan Scanner</Text>
        </Pressable>
      </View>
      {/* Full-screen overlay with RoomPlanView and custom controls */}
      {showScanner && (
        <View style={styles.overlay}>
          {/* Package component */}
          <RoomPlanView style={StyleSheet.absoluteFill} {...viewProps} />

          <SafeAreaView style={styles.topBar}>
            <Pressable
              onPress={onCancel}
              style={[styles.chip, styles.chipCancel]}
            >
              <Text style={styles.chipText}>Cancel</Text>
            </Pressable>
            <Pressable
              onPress={onFinish}
              style={[styles.chip, styles.chipFinish]}
            >
              <Text style={styles.chipText}>Finish</Text>
            </Pressable>
          </SafeAreaView>

          <View style={styles.bottomBar}>
            <Pressable onPress={onNewRoom} style={[styles.actionButton]}>
              <Text style={styles.actionButtonText}>Add Another Room</Text>
            </Pressable>
          </View>
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
  titleContainer: {
    flexDirection: "row",
    alignItems: "center",
    gap: 8,
  },
  stepContainer: {
    gap: 8,
    marginBottom: 8,
  },
  reactLogo: {
    height: 178,
    width: 290,
    bottom: 0,
    left: 0,
    position: "absolute",
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
  bottomBar: {
    position: "absolute",
    left: 16,
    right: 16,
    bottom: 40,
  },
  actionButton: {
    backgroundColor: "rgba(0,0,0,0.6)",
    paddingVertical: 14,
    borderRadius: 14,
    alignItems: "center",
  },
  actionButtonText: {
    color: "white",
    fontWeight: "700",
    fontSize: 16,
  },
});
