import type { ExpoRoomPlanModuleType } from "./ExpoRoomPlan.types";
import { requireNativeModule } from "expo-modules-core";

const ExpoRoomplan =
  requireNativeModule<ExpoRoomPlanModuleType>("ExpoRoomPlan");
export default ExpoRoomplan;
