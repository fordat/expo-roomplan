import Foundation
import UIKit
import RoomPlan
import ExpoModulesCore
import AVFoundation

@available(iOS 17.0, *)
class RoomPlanCaptureUIView: ExpoView, RoomCaptureSessionDelegate, RoomCaptureViewDelegate {
  private var roomCaptureView: RoomCaptureView!
  private let configuration = RoomCaptureSession.Configuration()
  // Events
  let onStatus = EventDispatcher()
  let onExported = EventDispatcher()
  let onPreview = EventDispatcher()

  // Props
  var scanName: String? = nil
  var exportType: String? = nil
  var sendFileLoc: Bool = false
  var exportOnFinish: Bool = true

  private var capturedRooms: [CapturedRoom] = []
  private let structureBuilder = StructureBuilder(options: [.beautifyObjects])
  private var isRunning: Bool = false
  private var lastExportTrigger: Double? = nil
  private var lastFinishTrigger: Double? = nil
  private var lastAddAnotherTrigger: Double? = nil
  private var pendingFinish: Bool = false
  private var pendingExport: Bool = false
  private var previewEmitted: Bool = false

  required init(appContext: AppContext? = nil) {
    super.init(appContext: appContext)

    roomCaptureView = RoomCaptureView(frame: .zero)
    roomCaptureView.translatesAutoresizingMaskIntoConstraints = false
    roomCaptureView.captureSession.delegate = self
    addSubview(roomCaptureView)

    NSLayoutConstraint.activate([
      roomCaptureView.topAnchor.constraint(equalTo: topAnchor),
      roomCaptureView.bottomAnchor.constraint(equalTo: bottomAnchor),
      roomCaptureView.leadingAnchor.constraint(equalTo: leadingAnchor),
      roomCaptureView.trailingAnchor.constraint(equalTo: trailingAnchor)
    ])
  }

  // Control running state from JS prop
  func setRunning(_ running: Bool) {
    guard running != isRunning else { return }
    isRunning = running
    if running {
      // Check device support before starting
      if !RoomCaptureSession.isSupported {
        sendError("RoomPlan is not supported on this device.")
        return
      }
      // Check/request camera permission
      let status = AVCaptureDevice.authorizationStatus(for: .video)
      switch status {
      case .authorized:
  previewEmitted = false
  roomCaptureView.captureSession.run(configuration: configuration)
      case .notDetermined:
        AVCaptureDevice.requestAccess(for: .video) { granted in
          DispatchQueue.main.async {
            if granted {
              self.previewEmitted = false
              self.roomCaptureView.captureSession.run(configuration: self.configuration)
            } else {
              self.sendError("Camera permission was not granted.")
            }
          }
        }
      case .denied, .restricted:
        sendError("Camera permission is denied or restricted.")
      @unknown default:
  previewEmitted = false
  roomCaptureView.captureSession.run(configuration: configuration)
      }
    } else {
      roomCaptureView.captureSession.stop(pauseARSession: false)
    }
  }

  func handleExportTrigger(_ trigger: Double?) {
    // Only handle when a non-nil trigger value actually changes
    guard let trigger else { return }
    if lastExportTrigger != trigger {
      lastExportTrigger = trigger
      // If nothing captured yet, queue export until capture ends
      guard !capturedRooms.isEmpty else {
        pendingExport = true
        return
      }
      exportResults()
    }
  }

  // Stop current capture, present the preview UI, and prepare to export.
  func handleFinishTrigger(_ trigger: Double?) {
    guard let trigger else { return }
    if lastFinishTrigger == trigger { return }
    lastFinishTrigger = trigger
  // Stop capturing to finalize current room; preview will be presented by RoomPlan
  pendingFinish = true
    roomCaptureView.captureSession.stop(pauseARSession: false)
  }

  // Restart session to accumulate another room like the controller-based flow
  func handleAddAnotherTrigger(_ trigger: Double?) {
    guard let trigger else { return }
    if lastAddAnotherTrigger == trigger { return }
    lastAddAnotherTrigger = trigger
    // Ensure current session is stopped, then start again to capture the next room
  pendingFinish = false
  pendingExport = false
  previewEmitted = false
  roomCaptureView.captureSession.stop(pauseARSession: false)
    DispatchQueue.main.async {
      self.roomCaptureView.captureSession.run(configuration: self.configuration)
    }
  }

  // MARK: - RoomPlan delegates
  func captureSession(_ session: RoomCaptureSession, didEndWith data: CapturedRoomData, error: (any Error)?) {
    if let error {
      sendError(error.localizedDescription)
      return
    }
    let roomBuilder = RoomBuilder(options: [.beautifyObjects])
    Task {
      do {
        let capturedRoom = try await roomBuilder.capturedRoom(from: data)
        self.capturedRooms.append(capturedRoom)
        // If finishing, emit preview now that the processed room exists
        if self.pendingFinish && !self.previewEmitted {
          self.onPreview([:])
          self.previewEmitted = true
          // If requested, export right after preview
          if self.exportOnFinish {
            self.exportResults()
          }
          self.pendingFinish = false
        }
        // If an export was queued, export now
        if self.pendingExport {
          self.pendingExport = false
          self.exportResults()
        } else {
          self.sendStatus(.OK)
        }
      } catch {
        self.sendError("Failed to build captured room: \(error.localizedDescription)")
      }
    }
  }

  func captureSession(_ session: RoomCaptureSession, didFailWith error: any Error) {
    sendError(error.localizedDescription)
  }

  func captureView(shouldPresent roomDataForProcessing: CapturedRoomData, error: Error?) -> Bool {
    return true
  }
  
  func captureView(didPresent processedResult: CapturedRoom, error: Error?) {
    // RoomPlan presented its own preview UI; notify JS once
    if !previewEmitted {
      onPreview([:])
      previewEmitted = true
    }
  }

  // MARK: - Export
  private func exportResults() {
    let exportedScanName = scanName ?? "Room"

    let destinationFolderURL = FileManager.default.temporaryDirectory.appending(path: "Export")
    let destinationURL = destinationFolderURL.appending(path: "\(exportedScanName).usdz")
    let capturedRoomURL = destinationFolderURL.appending(path: "\(exportedScanName).json")

    Task {
      do {
        let structure = try await structureBuilder.capturedStructure(from: capturedRooms)

        try FileManager.default.createDirectory(at: destinationFolderURL, withIntermediateDirectories: true)

        var finalExportType = CapturedRoom.USDExportOptions.parametric
        if exportType == "MESH" { finalExportType = .mesh }
        if exportType == "MODEL" { finalExportType = .model }

        let jsonEncoder = JSONEncoder()
        let jsonData = try jsonEncoder.encode(structure)
        try jsonData.write(to: capturedRoomURL)
        try structure.export(to: destinationURL, exportOptions: finalExportType)

        if sendFileLoc {
          self.onExported([
            "scanUrl": destinationURL.absoluteString,
            "jsonUrl": capturedRoomURL.absoluteString
          ])
        }
  // Also emit a final OK status after export
  self.sendStatus(.OK)
      } catch {
        self.sendError("Export failed: \(error.localizedDescription)")
      }
    }
  }

  // MARK: - Events
  private func sendStatus(_ status: ScanStatus) {
  self.onStatus(["status": status.rawValue])
  }

  private func sendError(_ message: String) {
    self.onStatus(["status": ScanStatus.Error.rawValue, "errorMessage": message])
  }
}
