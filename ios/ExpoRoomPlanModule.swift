import ExpoModulesCore
import UIKit
import RoomPlan

public class ExpoRoomPlanModule: Module {
    private var captureViewController: RoomPlanCaptureViewController?

    public func definition() -> ModuleDefinition {
        Name("ExpoRoomPlan")

        Events("onDismissEvent")

        Function("isSupported") { () -> Bool in
            guard #available(iOS 17.0, *) else {
                return false
            }
            return RoomCaptureSession.isSupported
        }

        AsyncFunction("startCapture") {
            (scanName: String, exportType: String, sendFileLoc: Bool) in
            guard #available(iOS 17.0, *) else {
                throw Exception(name: "startCapture", description: "RoomPlan requires iOS 17.0 or later")
            }

            DispatchQueue.main.async {
                let captureVC = RoomPlanCaptureViewController()

                captureVC.scanName = scanName
                captureVC.modalPresentationStyle = .fullScreen
                captureVC.exportType = exportType
                captureVC.sendFileLoc = sendFileLoc

                captureVC.onDismiss = { eventData in
                    DispatchQueue.main.async {
                        self.sendEvent("onDismissEvent", eventData)
                    }
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
            guard #available(iOS 17.0, *) else {
                throw Exception(name: "stopCapture", description: "RoomPlan requires iOS 17.0 or later")
            }

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
