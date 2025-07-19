import ExpoModulesCore
import UIKit

@available(iOS 17.0, *)
public class ExpoRoomPlanModule: Module {
    private var captureViewController: RoomPlanCaptureViewController?

    public func definition() -> ModuleDefinition {
        Name("ExpoRoomPlan")

        Events("onDismissEvent")

        AsyncFunction("startCapture") {
            (scanName: String, exportType: String?) in
            DispatchQueue.main.async {
                let captureVC = RoomPlanCaptureViewController()
                captureVC.exportType = exportType
                captureVC.scanName = scanName
                captureVC.modalPresentationStyle = .fullScreen

                captureVC.onDismiss = { status in
                    self.sendEvent("onDismissEvent", ["value": status.rawValue])
                }

                guard
                    let rootVC = UIApplication.shared.connectedScenes
                        .compactMap({ ($0 as? UIWindowScene)?.keyWindow })
                        .first?.rootViewController
                else {
                    return
                }

                rootVC.present(captureVC, animated: true, completion: nil)
                self.captureViewController = captureVC
            }
        }

        AsyncFunction("stopCapture") {
            DispatchQueue.main.async {
                self.captureViewController?.stopSession()
                self.captureViewController?.dismiss(
                    animated: true,
                    completion: nil
                )
            }
        }
    }
}
