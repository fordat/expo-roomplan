package expo.modules.roomplan

import expo.modules.kotlin.modules.Module
import expo.modules.kotlin.modules.ModuleDefinition
import expo.modules.kotlin.Promise
import expo.modules.kotlin.events.EventEmitter

class ExpoRoomPlanModule : Module() {
  
  override fun definition() = ModuleDefinition {
    // Module name - should match your TypeScript module name
    Name("ExpoRoomPlan")

    // Async function to start capture
    AsyncFunction("startCapture") { scanName: String, exportType: String?, promise: Promise ->
      promise.reject("NOT_IMPLEMENTED", "RoomPlan is not available to Android.")
    }

    // Async function to stop capture
    AsyncFunction("stopCapture") { promise: Promise ->
      promise.reject("NOT_IMPLEMENTED", "RoomPlan is not available to Android.")
    }
  }
}