//  RoomPlanCaptureViewController.swift

import Foundation
import RealityKit
import RoomPlan
import UIKit

@available(iOS 16.0, *)
class RoomPlanCaptureViewController: UIViewController, RoomCaptureViewDelegate,
    RoomCaptureSessionDelegate
{
    private var roomCaptureView: RoomCaptureView!
    private var roomCaptureSessionConfig: RoomCaptureSession.Configuration =
        RoomCaptureSession.Configuration()
    private var isSessionRunning: Bool = false

    // Populated via the RoomCaptureViewDelegate review flow. This is the only
    // source of the final room on iOS 16, where RoomBuilder/StructureBuilder
    // don't exist; on iOS 17+ it's unused since we build from capturedRoomArray.
    private var finalResults: CapturedRoom?

    private var _finalStructure: Any?
    @available(iOS 17.0, *)
    private var finalStructure: CapturedStructure? {
        get { _finalStructure as? CapturedStructure }
        set { _finalStructure = newValue }
    }
    private var _structureBuilder: Any?
    @available(iOS 17.0, *)
    private var structureBuilder: StructureBuilder {
        if let existing = _structureBuilder as? StructureBuilder {
            return existing
        }
        let builder = StructureBuilder(options: [.beautifyObjects])
        _structureBuilder = builder
        return builder
    }

    var onDismiss: (([String: Any]) -> Void)?

    var scanName: String?
    var exportType: String?
    var sendFileLoc: Bool?
    var capturedRoomArray: [CapturedRoom] = []
    // Tracks whether the RoomBuilder Task kicked off by captureSession(_:didEndWith:)
    // is still running, so export can be deferred instead of racing it with a fixed timer.
    private var isBuildingRoom = false
    private var pendingExportAfterBuild = false

    // UI elements
    private let activityIndicator = UIActivityIndicatorView(style: .large)
    @IBOutlet var cancelButton: UIButton!
    @IBOutlet var finishButton: UIButton!
    @IBOutlet var anotherScanButton: UIButton!
    @IBOutlet var exportButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        setupRoomCaptureView()
        setupActivityIndicator()
    }

    private func setupActivityIndicator() {
        activityIndicator.center = self.view.center
        activityIndicator.hidesWhenStopped = true
        activityIndicator.color = UIColor.white
        view.addSubview(activityIndicator)
    }

    private func setupRoomCaptureView() {
        roomCaptureView = RoomCaptureView(frame: view.bounds)
        roomCaptureView?.captureSession.delegate = self
        // On iOS 17+, rooms are built from raw CapturedRoomData via RoomBuilder
        // (see captureSession(_:didEndWith:) below), so the view-level review
        // delegate is left unset to avoid double-presenting RoomPlan's own UI.
        // On iOS 16, RoomBuilder doesn't exist, so we rely on RoomPlan's built-in
        // review flow and capture the finished room via captureView(didPresent:).
        if #unavailable(iOS 17.0) {
            roomCaptureView?.delegate = self
        }
        view.insertSubview(roomCaptureView, at: 0)

        setupButtons()
        setupConstraints()
    }

    private func setupButtons() {
        // initialize and set up the finish button
        finishButton = UIButton()
        finishButton.translatesAutoresizingMaskIntoConstraints = false
        finishButton.setTitleColor(.white, for: .normal)
        finishButton.titleLabel?.textAlignment = .center
        finishButton.titleLabel?.numberOfLines = 0
        finishButton.titleLabel?.font = UIFont.systemFont(
            ofSize: 16,
            weight: .bold
        )
        finishButton.setTitle("Finish", for: .normal)

        // Finish should either stop scanning (if running) or confirm exit (if post-scan)
        finishButton.addTarget(
            self,
            action: #selector(finishTapped),
            for: .touchUpInside
        )

        // add the label on top of roomCaptureView
        view.addSubview(finishButton)

        // initialize and set up the cancel button
        cancelButton = UIButton()
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        cancelButton.setTitleColor(.white, for: .normal)
        cancelButton.titleLabel?.textAlignment = .center
        cancelButton.titleLabel?.numberOfLines = 0
        cancelButton.titleLabel?.font = UIFont.systemFont(
            ofSize: 16,
            weight: .bold
        )
        cancelButton.setTitle("Cancel", for: .normal)
        // round corners
        cancelButton.layer.masksToBounds = true
        cancelButton.layer.cornerRadius = 5

        // add the action for button press
        cancelButton.addTarget(
            self,
            action: #selector(cancelSession),
            for: .touchUpInside
        )

        // add the label on top of roomCaptureView
        view.addSubview(cancelButton)
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            finishButton.topAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.topAnchor,
                constant: 10
            ),
            finishButton.trailingAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.trailingAnchor,
                constant: -20
            ),
            finishButton.widthAnchor.constraint(equalToConstant: 80),
            finishButton.heightAnchor.constraint(equalToConstant: 30),

            cancelButton.topAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.topAnchor,
                constant: 10
            ),
            cancelButton.leadingAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.leadingAnchor,
                constant: 20
            ),
            cancelButton.widthAnchor.constraint(equalToConstant: 80),
            cancelButton.heightAnchor.constraint(equalToConstant: 30),
        ])
    }

    private func setupPostScanUI() {
        let supportsAddAnotherRoom: Bool
        if #available(iOS 17.0, *) {
            supportsAddAnotherRoom = true
        } else {
            supportsAddAnotherRoom = false
        }

        // initialize and set up the export button
        exportButton = UIButton()
        exportButton.translatesAutoresizingMaskIntoConstraints = false
        exportButton.setTitleColor(.white, for: .normal)
        exportButton.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        exportButton.titleLabel?.textAlignment = .center
        exportButton.titleLabel?.numberOfLines = 0
        exportButton.titleLabel?.font = UIFont.systemFont(
            ofSize: 16,
            weight: .bold
        )
        exportButton.setTitle("Export Results", for: .normal)  // text
        // round corners
        exportButton.layer.masksToBounds = true
        exportButton.layer.cornerRadius = 15

        exportButton.addTarget(
            self,
            action: #selector(superExportResults),
            for: .touchUpInside
        )

        var stackedButtons: [UIButton] = [exportButton]

        if supportsAddAnotherRoom {
            anotherScanButton = UIButton()
            anotherScanButton.translatesAutoresizingMaskIntoConstraints = false
            anotherScanButton.setTitleColor(.white, for: .normal)
            anotherScanButton.backgroundColor = UIColor.black.withAlphaComponent(
                0.6
            )
            anotherScanButton.titleLabel?.textAlignment = .center
            anotherScanButton.titleLabel?.numberOfLines = 0
            anotherScanButton.titleLabel?.font = UIFont.systemFont(
                ofSize: 16,
                weight: .bold
            )
            anotherScanButton.setTitle("Add Another Room to Scan", for: .normal)  // text
            // round corners
            anotherScanButton.layer.masksToBounds = true
            anotherScanButton.layer.cornerRadius = 15

            anotherScanButton.addTarget(
                self,
                action: #selector(restartSession),
                for: .touchUpInside
            )

            stackedButtons.append(anotherScanButton)
        }

        let buttonStack = UIStackView(arrangedSubviews: stackedButtons)
        buttonStack.axis = .vertical
        buttonStack.spacing = 16
        buttonStack.distribution = .fillEqually
        buttonStack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(buttonStack)

        // alter text on cancel buttons
        UIView.transition(
            with: cancelButton,
            duration: 0.5,
            options: .transitionCrossDissolve,
            animations: {
                self.cancelButton.backgroundColor = UIColor.black
                    .withAlphaComponent(0.6)  // make button background visible
            },
            completion: nil
        )
        // Keep Finish active; it will now confirm exit when no session is running.

        var buttonConstraints = [
            exportButton.heightAnchor.constraint(equalToConstant: 50)
        ]
        if supportsAddAnotherRoom {
            buttonConstraints.append(
                anotherScanButton.heightAnchor.constraint(equalToConstant: 50)
            )
        }

        NSLayoutConstraint.activate(buttonConstraints + [
            buttonStack.leadingAnchor.constraint(
                equalTo: view.leadingAnchor,
                constant: 20
            ),
            buttonStack.trailingAnchor.constraint(
                equalTo: view.trailingAnchor,
                constant: -20
            ),
            buttonStack.bottomAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.bottomAnchor,
                constant: -40
            ),
        ])
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        startSession()
    }

    override func viewWillDisappear(_ flag: Bool) {
        super.viewWillDisappear(flag)
        stopSession()
    }

    @IBAction func superExportResults(_ sender: Any) {
        // disable buttons after pressing upload
        exportButton.isEnabled = false
        exportButton.removeTarget(
            self,
            action: #selector(superExportResults),
            for: .touchUpInside
        )
        // Also disable Finish to avoid exiting mid-export
        finishButton.isEnabled = false
        if let anotherScanButton {
            anotherScanButton.isEnabled = false
            anotherScanButton.removeTarget(
                self,
                action: #selector(restartSession),
                for: .touchUpInside
            )
        }
        UIView.animate(withDuration: 0.5) {
            self.anotherScanButton?.backgroundColor = UIColor.white
            self.exportButton.backgroundColor = UIColor.white
        }

        if #available(iOS 17.0, *) {
          roomCaptureView?.captureSession.stop(pauseARSession: false)
        } else {
          roomCaptureView?.captureSession.stop()
        }

        // create a white overlay view that covers the entire screen
        let overlayView = UIView(frame: self.view.bounds)
        overlayView.backgroundColor = UIColor.white
        overlayView.alpha = 1
        overlayView.tag = 999

        // add the overlay above the roomCaptureView but below other UI elements
        self.view.insertSubview(overlayView, aboveSubview: roomCaptureView!)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if self.isBuildingRoom {
                // Last room's RoomBuilder Task hasn't finished appending to
                // capturedRoomArray yet; defer export until it does instead of
                // racing it and handing StructureBuilder an incomplete array.
                print("[RoomPlan] Room build still in flight; deferring export.")
                self.pendingExportAfterBuild = true
                // Safety net: if didEndWith/RoomBuilder never completes (or takes
                // far longer than expected), don't hang forever with no feedback.
                DispatchQueue.main.asyncAfter(deadline: .now() + 15) {
                    guard self.pendingExportAfterBuild else { return }
                    self.pendingExportAfterBuild = false
                    self.isBuildingRoom = false
                    print("[RoomPlan] Timed out waiting for room data to finish processing.")
                    self.sendScanResultAndDismiss(
                        status: .Error,
                        errorMessage: "Timed out waiting for the scan to finish processing."
                    )
                }
            } else {
                self.exportResults()
            }
        }
    }

    func exportResults() {
        let exportedScanName = scanName ?? "Room"

        let destinationFolderURL = FileManager.default.temporaryDirectory
            .appending(path: "Export")
        let destinationURL = destinationFolderURL.appending(path: "\(exportedScanName).usdz")
        let capturedRoomURL = destinationFolderURL.appending(path: "\(exportedScanName).json")

        // UI responsiveness, disable cancel button
        cancelButton.removeTarget(
            self,
            action: #selector(cancelSession),
            for: .touchUpInside
        )
        cancelButton.isEnabled = false
        UIView.transition(
            with: cancelButton,
            duration: 0.2,
            options: .transitionCrossDissolve,
            animations: {
                self.cancelButton.backgroundColor = UIColor.white
            },
            completion: nil
        )

        Task {
            do {
                try FileManager.default.createDirectory(
                    at: destinationFolderURL,
                    withIntermediateDirectories: true
                )

                var finalExportType = CapturedRoom.USDExportOptions.parametric;

                if (exportType == "MESH") {
                    finalExportType = CapturedRoom.USDExportOptions.mesh;
                } else if (exportType == "MODEL") {
                    finalExportType = CapturedRoom.USDExportOptions.model;
                }

                let jsonEncoder = JSONEncoder()

                if #available(iOS 17.0, *) {
                    guard !capturedRoomArray.isEmpty else {
                        throw NSError(
                            domain: "ExpoRoomPlan",
                            code: 2,
                            userInfo: [
                                NSLocalizedDescriptionKey: "No rooms were successfully captured. Try scanning again, covering more of the walls and floor before finishing."
                            ]
                        )
                    }
                    finalStructure = try await structureBuilder.capturedStructure(
                        from: capturedRoomArray
                    )

                    let jsonData = try jsonEncoder.encode(finalStructure)
                    try jsonData.write(to: capturedRoomURL)
                    try finalStructure?.export(
                        to: destinationURL,
                        exportOptions: finalExportType
                    )

                    finalStructure = nil
                } else {
                    guard let room = finalResults else {
                        throw NSError(
                            domain: "ExpoRoomPlan",
                            code: 1,
                            userInfo: [
                                NSLocalizedDescriptionKey: "No captured room available to export."
                            ]
                        )
                    }

                    let jsonData = try jsonEncoder.encode(room)
                    try jsonData.write(to: capturedRoomURL)
                    try room.export(
                        to: destinationURL,
                        exportOptions: finalExportType
                    )
                }

                let shouldSendFileLoc = sendFileLoc ?? false

                if (shouldSendFileLoc) {
                    self.sendScanResultAndDismiss(status: .OK, scanUrl: destinationURL.absoluteString, jsonUrl: capturedRoomURL.absoluteString)
                    return
                }

                let activityVC = UIActivityViewController(
                    activityItems: [destinationFolderURL],
                    applicationActivities: nil
                )
                activityVC.modalPresentationStyle = .popover

                activityVC.completionWithItemsHandler = {
                    activityType,
                    completed,
                    returnedItems,
                    activityError in
                    self.sendScanResultAndDismiss(status: .OK)
                }

                if let popOver = activityVC.popoverPresentationController {
                    popOver.sourceView = self.exportButton
                }

                present(activityVC, animated: true, completion: nil)

            } catch {
                print("[RoomPlan] ERROR MERGING")
                print("[RoomPlan] Error = \(error)")
                self.sendScanResultAndDismiss(status: .Error, errorMessage: error.localizedDescription)
                return
            }
        }
    }

    func sendScanResultAndDismiss(status: ScanStatus? = nil, scanUrl: String? = nil, jsonUrl: String? = nil, errorMessage: String? = nil) {
        var eventData: [String: Any] = [:]

        if let status = status {
            eventData["status"] = status.rawValue
        }

        if let jsonUrl = jsonUrl {
            eventData["jsonUrl"] = jsonUrl
        }

        if let scanUrl = scanUrl {
            eventData["scanUrl"] = scanUrl
        }

        if let errorMessage = errorMessage {
            eventData["errorMessage"] = errorMessage
        }

        // Send the unified event
        onDismiss?(eventData)
        
        let dismissAction = {
            self.activityIndicator.stopAnimating()
            self.dismiss(animated: true, completion: nil)
        }
        
        // Handle timing and cleanup based on status
        if status == .OK {
            DispatchQueue.main.asyncAfter(
                deadline: .now() + 0.5,
                execute: dismissAction
            )
        } else {
            if #available(iOS 17.0, *) {
                finalStructure = nil
            }
            DispatchQueue.main.async(execute: dismissAction)
        }
    }

    public func startSession() {
        print("[RoomPlan] starting session")
        roomCaptureView?.captureSession.run(
            configuration: roomCaptureSessionConfig
        )
        isSessionRunning = true
    }

    @IBAction func restartSession() {
        print("[RoomPlan] restarting session")
        exportButton.removeFromSuperview()
        anotherScanButton?.removeFromSuperview()
        roomCaptureView?.captureSession.run(
            configuration: roomCaptureSessionConfig
        )
        isSessionRunning = true
        UIView.transition(
            with: cancelButton,
            duration: 0.5,
            options: .transitionCrossDissolve,
            animations: {
                self.cancelButton.backgroundColor = UIColor.black
                    .withAlphaComponent(0)  // make button background invisible again
            },
            completion: nil
        )
        // finishButton remains bound to finishTapped
        finishButton.isEnabled = true
    }

    @objc
    public func stopSession() {
        // A didEndWith callback (and its RoomBuilder Task) is guaranteed to follow
        // this stop() call, so mark the build as in-flight now rather than waiting
        // for didEndWith to fire — otherwise a fast export tap can race the gap
        // between calling stop() and the delegate callback actually arriving.
        if #available(iOS 17.0, *) {
            isBuildingRoom = true
            roomCaptureView?.captureSession.stop(pauseARSession: false)
        } else {
            roomCaptureView?.captureSession.stop()
        }
        isSessionRunning = false
        setupPostScanUI()
    }

    @objc
    private func finishTapped() {
        if isSessionRunning {
            // Current behavior during scanning: stop the session and show post-scan UI
            stopSession()
        } else {
            // Post-scan (or no active session): confirm finishing and exit the view
            let alertController = UIAlertController(
                title: "Finish Scanning?",
                message:
                    "You're about to close the scanner. You can export results first or finish now.",
                preferredStyle: .alert
            )

            let confirmAction = UIAlertAction(title: "Finish", style: .destructive) { _ in
                self.sendScanResultAndDismiss(status: .OK)
            }
            alertController.addAction(confirmAction)

            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
            alertController.addAction(cancelAction)

            self.present(alertController, animated: true, completion: nil)
        }
    }

    @objc
    func cancelSession() {
        let alertController = UIAlertController(
            title: "Cancel Room Scan?",
            message:
                "If a scan is canceled, you'll have to start over again next time.",
            preferredStyle: .alert
        )

        let confirmAction = UIAlertAction(title: "Confirm", style: .destructive)
        { action in
            if #available(iOS 17.0, *) {
                self.finalStructure = nil
            }
            self.sendScanResultAndDismiss(status: .Canceled)
        }
        alertController.addAction(confirmAction)

        let cancelAction = UIAlertAction(
            title: "Cancel",
            style: .cancel,
            handler: nil
        )
        alertController.addAction(cancelAction)

        self.present(alertController, animated: true, completion: nil)
    }

    @objc
    static func requiresMainQueueSetup() -> Bool {
        return true
    }
}

@available(iOS 17.0, *)
extension RoomPlanCaptureViewController {
    func captureSession(_ session: RoomCaptureSession, didUpdate: CapturedRoom)
    {
        print("[RoomPlan] didUpdate", didUpdate.objects.count)
    }

    func captureSession(_ session: RoomCaptureSession, didChange: CapturedRoom)
    {
        print("[RoomPlan] didChange", didChange.objects.count)
    }
}

@available(iOS 16.0, *)
extension RoomPlanCaptureViewController {
    // captureSession(_:didEndWith:error:) is a base RoomCaptureSessionDelegate
    // requirement present since iOS 16 (unlike didUpdate/didChange above, which
    // are iOS 17+ additions for multi-room support). It must live at the same
    // availability floor as the class's own protocol conformance — nesting it
    // inside an @available(iOS 17.0, *) extension left it mismatched with the
    // class's iOS 16 floor, which meant it was never wired up as the delegate
    // callback at all and silently never fired.
    func captureSession(
        _ session: RoomCaptureSession,
        didEndWith: CapturedRoomData,
        error: (any Error)?
    ) {
        if let error {
            print("[RoomPlan] Session ended with error: \(error.localizedDescription)")
        }
        print("[RoomPlan] didEndWith")
        guard #available(iOS 17.0, *) else { return }
        let roomBuilder = RoomBuilder(options: [.beautifyObjects])
        isBuildingRoom = true
        Task {
            do {
                let capturedRoom = try await roomBuilder.capturedRoom(
                    from: didEndWith
                )
                print("[RoomPlan] Appending new captured room")
                self.capturedRoomArray.append(capturedRoom)
            } catch {
                print("[RoomPlan] Failed to build captured room: \(error.localizedDescription)")
            }
            await MainActor.run {
                self.isBuildingRoom = false
                if self.pendingExportAfterBuild {
                    self.pendingExportAfterBuild = false
                    self.exportResults()
                }
            }
        }
    }

    func captureView(
        shouldPresent roomDataForProcessing: CapturedRoomData,
        error: Error?
    ) -> Bool {
        return true
    }

    // access the final results
    func captureView(didPresent processedResult: CapturedRoom, error: Error?) {
        finalResults = processedResult
    }
}
