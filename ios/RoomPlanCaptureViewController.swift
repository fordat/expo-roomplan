//  RoomPlanCaptureViewController.swift

import Foundation
import RealityKit
import RoomPlan
import UIKit

@available(iOS 17.0, *)
class RoomPlanCaptureViewController: UIViewController, RoomCaptureViewDelegate,
    RoomCaptureSessionDelegate
{
    private var roomCaptureView: RoomCaptureView!
    private var roomCaptureSessionConfig: RoomCaptureSession.Configuration =
        RoomCaptureSession.Configuration()

    private var finalResults: CapturedRoom?
    private var finalStructure: CapturedStructure?
    private let structureBuilder = StructureBuilder(options: [.beautifyObjects])

    var onDismiss: (([String: Any]) -> Void)?

    var scanName: String?
    var exportType: String?
    var sendFileLoc: Bool?
    var capturedRoomArray: [CapturedRoom] = []

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

        // add the action for button press
        finishButton.addTarget(
            self,
            action: #selector(stopSession),
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

        // initialize and set up the "anotherScan" button
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

        let buttonStack = UIStackView(arrangedSubviews: [
            exportButton, anotherScanButton,
        ])
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
        // disable finish button
        finishButton.removeTarget(
            self,
            action: #selector(stopSession),
            for: .touchUpInside
        )
        finishButton.isEnabled = false

        NSLayoutConstraint.activate([
            exportButton.heightAnchor.constraint(equalToConstant: 50),
            anotherScanButton.heightAnchor.constraint(equalToConstant: 50),

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
        anotherScanButton.isEnabled = false
        anotherScanButton.removeTarget(
            self,
            action: #selector(restartSession),
            for: .touchUpInside
        )
        UIView.animate(withDuration: 0.5) {
            self.anotherScanButton.backgroundColor = UIColor.white
            self.exportButton.backgroundColor = UIColor.white
        }

        roomCaptureView?.captureSession.stop()

        // create a white overlay view that covers the entire screen
        let overlayView = UIView(frame: self.view.bounds)
        overlayView.backgroundColor = UIColor.white
        overlayView.alpha = 1
        overlayView.tag = 999

        // add the overlay above the roomCaptureView but below other UI elements
        self.view.insertSubview(overlayView, aboveSubview: roomCaptureView!)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.exportResults()
        }
    }

    func exportResults() {

        let destinationFolderURL = FileManager.default.temporaryDirectory
            .appending(path: "Export")
        let destinationURL = destinationFolderURL.appending(path: "Room.usdz")
        let capturedRoomURL = destinationFolderURL.appending(path: "Room.json")

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
                finalStructure = try await structureBuilder.capturedStructure(
                    from: capturedRoomArray
                )

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
                let jsonData = try jsonEncoder.encode(finalStructure)
                try jsonData.write(to: capturedRoomURL)
                try finalStructure?.export(
                    to: destinationURL,
                    exportOptions: finalExportType
                )

                // reset finalStructure before sending data
                finalStructure = nil
                
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
                self.sendScanResultAndDismiss(status: .Error)
                return
            }
        }
    }

    func sendScanResultAndDismiss(status: ScanStatus? = nil, scanUrl: String? = nil, jsonUrl: String? = nil) {
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
            finalStructure = nil
            DispatchQueue.main.async(execute: dismissAction)
        }
    }

    public func startSession() {
        print("[RoomPlan] starting session")
        roomCaptureView?.captureSession.run(
            configuration: roomCaptureSessionConfig
        )
    }

    @IBAction func restartSession() {
        print("[RoomPlan] restarting session")
        exportButton.removeFromSuperview()
        anotherScanButton.removeFromSuperview()
        roomCaptureView?.captureSession.run(
            configuration: roomCaptureSessionConfig
        )
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
        finishButton.addTarget(
            self,
            action: #selector(stopSession),
            for: .touchUpInside
        )
        finishButton.isEnabled = true
    }

    @objc
    public func stopSession() {
        roomCaptureView?.captureSession.stop(pauseARSession: false)
        setupPostScanUI()
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
            // reset final structure on cancel
            self.finalStructure = nil
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

    func captureSession(
        _ session: RoomCaptureSession,
        didEndWith: CapturedRoomData,
        error: (any Error)?
    ) {
        print("[RoomPlan] didEndWith")
        let roomBuilder = RoomBuilder(options: [.beautifyObjects])
        Task {
            if let capturedRoom = try? await roomBuilder.capturedRoom(
                from: didEndWith
            ) {
                print("[RoomPlan] Appending new captured room")
                self.capturedRoomArray.append(capturedRoom)
            } else {
                print("[RoomPlan] Failed to build captured room.")
            }
        }
    }
}

@available(iOS 17.0, *)
extension RoomPlanCaptureViewController {
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
