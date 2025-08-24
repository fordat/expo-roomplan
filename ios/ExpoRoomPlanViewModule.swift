import ExpoModulesCore
import UIKit
import RoomPlan

@available(iOS 17.0, *)
public class ExpoRoomPlanViewModule: Module {
  public func definition() -> ModuleDefinition {
    Name("ExpoRoomPlanView")

    // Register a React Native view that embeds RoomCaptureView
    View(RoomPlanCaptureUIView.self) {
      Events("onStatus", "onExported", "onPreview")

      // Props to control flow
      Prop("scanName") { (view, value: String?) in
        view.scanName = value
      }
      Prop("exportType") { (view, value: String?) in
        view.exportType = value
      }
      Prop("sendFileLoc") { (view, value: Bool?) in
        view.sendFileLoc = value ?? false
      }
      Prop("exportOnFinish") { (view, value: Bool?) in
        view.exportOnFinish = value ?? true
      }
      Prop("running") { (view, value: Bool?) in
        view.setRunning(value ?? false)
      }
      // Bump this number to trigger an export on demand
      Prop("exportTrigger") { (view, value: Double?) in
        view.handleExportTrigger(value)
      }
      // Stop capture and show RoomPlan preview UI
      Prop("finishTrigger") { (view, value: Double?) in
        view.handleFinishTrigger(value)
      }
      // Continue scanning and add another room to the set
      Prop("addAnotherTrigger") { (view, value: Double?) in
        view.handleAddAnotherTrigger(value)
      }
    }
  }
}
