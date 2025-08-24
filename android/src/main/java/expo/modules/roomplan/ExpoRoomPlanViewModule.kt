package expo.modules.roomplan

import expo.modules.kotlin.modules.Module
import expo.modules.kotlin.modules.ModuleDefinition

class ExpoRoomPlanViewModule : Module() {
  override fun definition() = ModuleDefinition {
    // Name must match the iOS view module so JS can require the same manager
    Name("ExpoRoomPlanView")

    // Register a View factory. The View itself will throw on Android.
    View(::RoomPlanView) {
      // Mirror props to satisfy the JS/TS surface. They are no-ops here.
      Prop("scanName") { _: RoomPlanView, _: String? -> }
      Prop("exportType") { _: RoomPlanView, _: String? -> }
      Prop("sendFileLoc") { _: RoomPlanView, _: Boolean? -> }
      Prop("running") { _: RoomPlanView, _: Boolean? -> }
      Prop("exportTrigger") { _: RoomPlanView, _: Double? -> }

      Events("onStatus", "onExported")
    }
  }
}
