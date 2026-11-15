import { Stack } from "expo-router";
import { StatusBar } from "expo-status-bar";

export default function RootLayout() {
  return (
    <>
      <Stack>
        <Stack.Screen name="index" options={{ title: "Expo RoomPlan" }} />
        <Stack.Screen name="native-ui" options={{ title: "useRoomPlan" }} />
        <Stack.Screen name="embedded" options={{ title: "useRoomPlanView" }} />
        <Stack.Screen name="provider" options={{ title: "RoomPlanProvider" }} />
      </Stack>
      <StatusBar style="auto" />
    </>
  );
}
