import ExpoRoomplan from 'expo-roomplan';
import { Button, SafeAreaView, ScrollView, Text, View } from 'react-native';
import { useRoomPlan } from 'expo-roomplan';

export default function App() {
  const {  } = ExpoRoomplan.startCapture("my_scan");

  const { startRoomPlan, roomScanStatus } = useRoomPlan();


  function handlePress() {

  }

  return (
    <SafeAreaView style={styles.container}>
      <ScrollView style={styles.container}>
        <Text style={styles.header}>Module API Example</Text>
        {/* <Group name="Constants">
          <Text>{ExpoRoomplan.PI}</Text>
        </Group>
        <Group name="Functions">
          <Text>{ExpoRoomplan.hello()}</Text>
        </Group> */}
        <Group name="Async functions">
          {/* <Button
            title="Set value"
            onPress={async () => {
              await ExpoRoomplan.setValueAsync('Hello from JS!');
            }}
          /> */}
          <Button
            title="Start RoomPlan"
            onPress={handlePress}
          />
        </Group>
      </ScrollView>
    </SafeAreaView>
  );
}

function Group(props: { name: string; children: React.ReactNode }) {
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
