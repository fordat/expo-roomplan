import ExpoModulesCore
import UIKit

@available(iOS 17.0, *)
public class ExpoRoomplanModule: Module {
  private var captureViewController: RoomPlanCaptureViewController?

  public func definition() -> ModuleDefinition {
    Name("ExpoRoomplan")

    Events("onDismissEvent")

    // Ensure functions run on the main thread
    AsyncFunction("startCapture") { (scanName: String, apiToken: String?, apiURL: String?) in
      guard let rootVC = UIApplication.shared.connectedScenes
        .compactMap({ ($0 as? UIWindowScene)?.keyWindow })
        .first?.rootViewController else {
        return
      }

      let captureVC = RoomPlanCaptureViewController()
      captureVC.apiToken = apiToken
      captureVC.apiURL = apiURL
      captureVC.scanName = scanName
      captureVC.modalPresentationStyle = .fullScreen

      captureVC.onDismiss = { status in
        self.emitter?.sendEvent("onDismissEvent", ["value": status.rawValue])
      }

      rootVC.present(captureVC, animated: true, completion: nil)
      self.captureViewController = captureVC
    }

    AsyncFunction("stopCapture") {
      self.captureViewController?.stopSession()
      self.captureViewController?.dismiss(animated: true, completion: nil)
    }
  }
}