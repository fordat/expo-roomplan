import type { PropsWithChildren } from "react";
import { Pressable, StyleSheet, Switch, Text, View } from "react-native";
import { ExportType } from "expo-roomplan";

export const colors = {
  background: "#F2F2F7",
  card: "#FFFFFF",
  text: "#111111",
  muted: "#6B6B70",
  tint: "#007AFF",
  error: "#D70015",
};

export function Section({ title, children }: PropsWithChildren<{ title: string }>) {
  return (
    <View style={styles.section}>
      <Text style={styles.sectionTitle}>{title}</Text>
      {children}
    </View>
  );
}

export function PrimaryButton({ title, onPress }: { title: string; onPress: () => void }) {
  return (
    <Pressable
      onPress={onPress}
      style={({ pressed }) => [styles.primaryButton, pressed && { opacity: 0.7 }]}
    >
      <Text style={styles.primaryButtonText}>{title}</Text>
    </Pressable>
  );
}

const EXPORT_TYPES = [ExportType.Parametric, ExportType.Mesh, ExportType.Model];

export function ExportTypePicker({
  value,
  onChange,
}: {
  value: ExportType;
  onChange: (value: ExportType) => void;
}) {
  return (
    <View style={styles.row}>
      <Text style={styles.label}>Export type</Text>
      <View style={styles.segmented}>
        {EXPORT_TYPES.map((type) => (
          <Pressable
            key={type}
            onPress={() => onChange(type)}
            style={[styles.segment, value === type && styles.segmentActive]}
          >
            <Text style={[styles.segmentText, value === type && styles.segmentTextActive]}>
              {type.toLowerCase()}
            </Text>
          </Pressable>
        ))}
      </View>
    </View>
  );
}

export function ToggleRow({
  label,
  value,
  onChange,
}: {
  label: string;
  value: boolean;
  onChange: (value: boolean) => void;
}) {
  return (
    <View style={styles.row}>
      <Text style={styles.label}>{label}</Text>
      <Switch value={value} onValueChange={onChange} />
    </View>
  );
}

/** Label/value line; renders nothing when value is empty. */
export function Field({ label, value, error }: { label: string; value?: string | null; error?: boolean }) {
  if (!value) return null;
  return (
    <View style={styles.field}>
      <Text style={styles.fieldLabel}>{label}</Text>
      <Text selectable style={[styles.fieldValue, error && { color: colors.error }]}>
        {value}
      </Text>
    </View>
  );
}

const styles = StyleSheet.create({
  section: { backgroundColor: colors.card, borderRadius: 12, padding: 16, gap: 12 },
  sectionTitle: { fontSize: 13, fontWeight: "600", color: colors.muted, textTransform: "uppercase" },
  primaryButton: {
    backgroundColor: colors.tint,
    borderRadius: 12,
    paddingVertical: 14,
    alignItems: "center",
  },
  primaryButtonText: { color: "white", fontSize: 16, fontWeight: "600" },
  row: { flexDirection: "row", alignItems: "center", justifyContent: "space-between" },
  label: { fontSize: 16, color: colors.text },
  segmented: { flexDirection: "row", backgroundColor: colors.background, borderRadius: 8, padding: 2 },
  segment: { paddingVertical: 6, paddingHorizontal: 10, borderRadius: 6 },
  segmentActive: { backgroundColor: colors.card },
  segmentText: { fontSize: 13, color: colors.muted },
  segmentTextActive: { color: colors.text, fontWeight: "600" },
  field: { gap: 2 },
  fieldLabel: { fontSize: 12, color: colors.muted },
  fieldValue: { fontSize: 13, color: colors.text, fontFamily: "Menlo" },
});
