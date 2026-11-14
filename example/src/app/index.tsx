import { Link, type Href } from "expo-router";
import { Platform, Pressable, ScrollView, StyleSheet, Text, View } from "react-native";

import { colors } from "@/components/ui";

const DEMOS: { href: Href; title: string; body: string }[] = [
  {
    href: "/native-ui",
    title: "Apple's capture UI",
    body: "useRoomPlan() presents RoomPlan's own full-screen capture and review flow. Least code; no control over the UI.",
  },
  {
    href: "/embedded",
    title: "Embedded view, custom controls",
    body: "useRoomPlanView() + <RoomPlanView>. Render the scanner inside your own screen and drive it with your own buttons, including multi-room capture.",
  },
  {
    href: "/provider",
    title: "Controls anywhere in the tree",
    body: "<RoomPlanProvider> + useRoomPlanContext(). Same as above, but any descendant can read state or call controls without prop drilling.",
  },
];

export default function Home() {
  return (
    <ScrollView contentContainerStyle={styles.container}>
      {Platform.OS !== "ios" && (
        <View style={styles.warning}>
          <Text style={styles.warningText}>
            RoomPlan is iOS-only. These screens render on {Platform.OS}, but scanning
            will not work.
          </Text>
        </View>
      )}
      <Text style={styles.intro}>
        Requires a LiDAR device (iPhone 12 Pro or newer, recent iPad Pro) on iOS 16+.
        Multi-room capture needs iOS 17+. The simulator can open the screens but cannot
        scan.
      </Text>
      {DEMOS.map((demo) => (
        <Link key={demo.title} href={demo.href} asChild>
          <Pressable style={({ pressed }) => [styles.card, pressed && styles.pressed]}>
            <Text style={styles.cardTitle}>{demo.title}</Text>
            <Text style={styles.cardBody}>{demo.body}</Text>
          </Pressable>
        </Link>
      ))}
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  container: { padding: 16, gap: 12 },
  intro: { color: colors.muted, fontSize: 14, lineHeight: 20 },
  card: { backgroundColor: colors.card, borderRadius: 12, padding: 16, gap: 6 },
  pressed: { opacity: 0.6 },
  cardTitle: { fontSize: 17, fontWeight: "600", color: colors.text },
  cardBody: { fontSize: 14, lineHeight: 20, color: colors.muted },
  warning: { backgroundColor: "#FFF4E5", borderRadius: 12, padding: 12 },
  warningText: { color: "#8A4B00", fontSize: 14 },
});
