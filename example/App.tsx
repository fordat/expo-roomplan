import { Button, SafeAreaView, ScrollView, Text, View } from 'react-native';
import { useRoomPlan } from 'expo-roomplan';
import React from 'react';

export default function App() {
  const { startRoomPlan } = useRoomPlan();


  async function handlePress() {
    try {
      await startRoomPlan("New Scan");
    } catch (error) {
      console.error("Error: ", error);
    }
  }

  return (
    <SafeAreaView style={styles.container}>
      <ScrollView style={styles.container}>
        <Text style={styles.header}>Expo RoomPlan Example</Text>
        <Group name="Async functions">
          <Button
            title="Start RoomPlan"
            onPress={handlePress}
          />
        </Group>
      </ScrollView>
    </SafeAreaView>
  );
}

function Group(props: React.PropsWithChildren<{ name: string }>) {
  return (
    <View style={styles.group}>
      <Text style={styles.groupHeader}>{props.name}</Text>
      {props.children}
    </View>
  );
}

const styles = {
  header: {
    fontSize: 30,
    margin: 20,
  },
  groupHeader: {
    fontSize: 20,
    marginBottom: 20,
  },
  group: {
    margin: 20,
    backgroundColor: '#fff',
    borderRadius: 10,
    padding: 20,
  },
  container: {
    flex: 1,
    backgroundColor: '#eee',
  },
  view: {
    flex: 1,
    height: 200,
  },
};
