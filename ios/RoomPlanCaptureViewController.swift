//  RoomPlanCaptureViewController.swift

import Foundation
import UIKit
import RealityKit
import RoomPlan
import Alamofire

@available(iOS 17.0, *)
class RoomPlanCaptureViewController: UIViewController, RoomCaptureViewDelegate, RoomCaptureSessionDelegate {
  private var roomCaptureView: RoomCaptureView!
  private var roomCaptureSessionConfig: RoomCaptureSession.Configuration = RoomCaptureSession.Configuration()
  
  private var finalResults: CapturedRoom?
  private var finalStructure: CapturedStructure?
  private let structureBuilder = StructureBuilder(options: [.beautifyObjects])

  var onDismiss: ((ScanStatus) -> Void)?

  var apiToken: String?
  var apiURL: String?
  var scanName: String?
  var capturedRoomArray: [CapturedRoom] = []
  
  // Alamofire
  private var session: Session?
  
  // UI elements
  private let activityIndicator = UIActivityIndicatorView(style: .large)
  @IBOutlet var cancelButton: UIButton!
  @IBOutlet var finishButton: UIButton!
  @IBOutlet var anotherScanButton: UIButton!
  @IBOutlet var feedbackLabel: UILabel!
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
    setupFeedbackLabel()
    setupConstraints()
    startRecordingReplayKit();
  }

  private func setupButtons() {
    // Initialize and set up the finish button
    finishButton = UIButton()
    finishButton.translatesAutoresizingMaskIntoConstraints = false
    finishButton.setTitleColor(.white, for: .normal)
    finishButton.titleLabel?.textAlignment = .center
    finishButton.titleLabel?.numberOfLines = 0
    finishButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .bold)
    finishButton.setTitle("Finish", for: .normal) // Initial text
    
    // Add the action for button press
    finishButton.addTarget(self, action: #selector(stopSession), for: .touchUpInside)
    
    // Add the label on top of roomCaptureView
    view.addSubview(finishButton)
    
    // Initialize and set up the cancel button
    cancelButton = UIButton()
    cancelButton.translatesAutoresizingMaskIntoConstraints = false
    cancelButton.setTitleColor(.white, for: .normal)
    cancelButton.titleLabel?.textAlignment = .center
    cancelButton.titleLabel?.numberOfLines = 0
    cancelButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .bold)
    cancelButton.setTitle("Cancel", for: .normal)
    // Round corners
    cancelButton.layer.masksToBounds = true
    cancelButton.layer.cornerRadius = 5
    
    // Add the action for button press
    cancelButton.addTarget(self, action: #selector(cancelSession), for: .touchUpInside)
    
    // Add the label on top of roomCaptureView
    view.addSubview(cancelButton)
  }

  private func setupFeedbackLabel() {
    feedbackLabel = UILabel()
    feedbackLabel.translatesAutoresizingMaskIntoConstraints = false
    feedbackLabel.textColor = .white
    feedbackLabel.backgroundColor = UIColor.black.withAlphaComponent(0.6) // Make label background visible
    feedbackLabel.textAlignment = .center
    feedbackLabel.numberOfLines = 0
    feedbackLabel.font = UIFont.systemFont(ofSize: 16, weight: .bold)
    feedbackLabel.text = "..."
    feedbackLabel.isHidden = true
    // Round corners
    feedbackLabel.layer.masksToBounds = true
    feedbackLabel.layer.cornerRadius = 15
    
    view.addSubview(feedbackLabel)
  }

  private func setupConstraints() {
    NSLayoutConstraint.activate([
      finishButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
      finishButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
      finishButton.widthAnchor.constraint(equalToConstant: 80),
      finishButton.heightAnchor.constraint(equalToConstant: 30),
      
      cancelButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
      cancelButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
      cancelButton.widthAnchor.constraint(equalToConstant: 80),
      cancelButton.heightAnchor.constraint(equalToConstant: 30),
      
      feedbackLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 50),
      feedbackLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -50),
      feedbackLabel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -180),
      feedbackLabel.heightAnchor.constraint(equalToConstant: 50)
    ])
  }

  private func setupPostScanUI() {
    // Initialize and set up the export button
    exportButton = UIButton()
    exportButton.translatesAutoresizingMaskIntoConstraints = false
    exportButton.setTitleColor(.white, for: .normal)
    exportButton.backgroundColor = UIColor.black.withAlphaComponent(0.6)
    exportButton.titleLabel?.textAlignment = .center
    exportButton.titleLabel?.numberOfLines = 0
    exportButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .bold)
    exportButton.setTitle("Upload Scan", for: .normal) // text
    // Round corners
    exportButton.layer.masksToBounds = true
    exportButton.layer.cornerRadius = 15
    
    exportButton.addTarget(self, action: #selector(superExportResults), for: .touchUpInside)

    // Initialize and set up the "anotherScan" button
    anotherScanButton = UIButton()
    anotherScanButton.translatesAutoresizingMaskIntoConstraints = false
    anotherScanButton.setTitleColor(.white, for: .normal)
    anotherScanButton.backgroundColor = UIColor.black.withAlphaComponent(0.6)
    anotherScanButton.titleLabel?.textAlignment = .center
    anotherScanButton.titleLabel?.numberOfLines = 0
    anotherScanButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .bold)
    anotherScanButton.setTitle("Add Another Room to Scan", for: .normal) // text
    // Round corners
    anotherScanButton.layer.masksToBounds = true
    anotherScanButton.layer.cornerRadius = 15
    
    anotherScanButton.addTarget(self, action: #selector(restartSession), for: .touchUpInside)

    let buttonStack = UIStackView(arrangedSubviews: [exportButton, anotherScanButton])
    buttonStack.axis = .vertical
    buttonStack.spacing = 16
    buttonStack.distribution = .fillEqually
    buttonStack.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(buttonStack)
    
    // alter text on cancel buttons
    UIView.transition(with: cancelButton, duration: 0.5, options: .transitionCrossDissolve, animations: {
      self.cancelButton.backgroundColor = UIColor.black.withAlphaComponent(0.6) // Make button background visible
    }, completion: nil)
    // disable finish button
    finishButton.removeTarget(self, action: #selector(stopSession), for: .touchUpInside)
    finishButton.isEnabled = false;
    
    // make commentary appear
    NSLayoutConstraint.activate([
      exportButton.heightAnchor.constraint(equalToConstant: 50),
      anotherScanButton.heightAnchor.constraint(equalToConstant: 50),

      buttonStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
      buttonStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
      buttonStack.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -40),
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
    exportButton.isEnabled = false;
    exportButton.removeTarget(self, action: #selector(superExportResults), for: .touchUpInside)
    anotherScanButton.isEnabled = false;
    anotherScanButton.removeTarget(self, action: #selector(restartSession), for: .touchUpInside)
    UIView.transition(with: cancelButton, duration: 0.2, options: .transitionCrossDissolve, animations: {
      self.anotherScanButton.backgroundColor = UIColor.white
    }, completion: nil)

    stopRecordingReplayKit()
    roomCaptureView?.captureSession.stop()

    // Create a white overlay view that covers the entire screen
    let overlayView = UIView(frame: self.view.bounds)
    overlayView.backgroundColor = UIColor.white
    overlayView.alpha = 1
    overlayView.tag = 999
    
    // Add the overlay above the roomCaptureView but below other UI elements
    self.view.insertSubview(overlayView, aboveSubview: roomCaptureView!)

    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
      self.exportResults()
    }
  }
  
  // Export the USDZ output by specifying the `.parametric` export option.
  // Alternatively, `.mesh` exports a nonparametric file and `.all`
  // exports both in a single USDZ.
  func exportResults() {

    let destinationFolderURL = FileManager.default.temporaryDirectory.appending(path: "Export")
    let destinationURL = destinationFolderURL.appending(path: "Room.usdz")
    let capturedRoomURL = destinationFolderURL.appending(path: "Room.json")
        
    // UI responsiveness, disable cancel button
    cancelButton.removeTarget(self, action: #selector(cancelSession), for: .touchUpInside)
    cancelButton.isEnabled = false;
    UIView.transition(with: cancelButton, duration: 0.2, options: .transitionCrossDissolve, animations: {
        self.cancelButton.backgroundColor = UIColor.white
    }, completion: nil)
    
    Task {
      do {
        finalStructure = try await structureBuilder.capturedStructure(from: capturedRoomArray)

        try FileManager.default.createDirectory(at: destinationFolderURL, withIntermediateDirectories: true)
        
        let jsonEncoder = JSONEncoder()
        let jsonData = try jsonEncoder.encode(finalStructure)
        try jsonData.write(to: capturedRoomURL)
        try finalStructure?.export(to: destinationURL, exportOptions: .mesh)
        
        let newUsdz = destinationURL;
        let usdzFileName = "Room.usdz"
        let jsonFileName = "RoomJson.json"
        
        // reset finalStructure before sending data
        finalStructure = nil
        
        sendModelData(
          usdzURL: newUsdz, usdzFileName: usdzFileName,
          jsonURL: capturedRoomURL, jsonFileName: jsonFileName
        );
      } catch {
        print("ERROR MERGING")
        print("Error = \(error)")
        return
      }
    }
  }
  
  func sendModelData(
    usdzURL: URL, usdzFileName: String,
    jsonURL: URL, jsonFileName: String
  ) {
    DispatchQueue.main.async {
        self.activityIndicator.startAnimating()
    }
    
    let configuration = URLSessionConfiguration.default
    configuration.timeoutIntervalForRequest = 300
    configuration.timeoutIntervalForResource = 300
    self.session = Session(configuration: configuration)
    
    // scanId is empty string when it's a new scan
    let finalScanId = scanId ?? "";
    let isNewScan = finalScanId.isEmpty;
    
    let method: HTTPMethod = isNewScan ? .put : .post
    let headers: HTTPHeaders = [
        "Authorization": "Bearer \(apiToken!)",
    ]
    
    let finalScanName = scanName ?? "Room Plan Export"

    let url = URL(string: apiURL!)!
    
    session!.upload(multipartFormData: { formData in
      formData.append(finalScanName.data(using: .utf8)!, withName: "name")  
      formData.append(usdzURL, withName: "usdzFile", fileName: usdzURL.lastPathComponent, mimeType: "model/vnd.pixar.usd")
      formData.append(jsonURL, withName: "jsonFile", fileName: jsonURL.lastPathComponent, mimeType: "application/json")
      
    }, to: url, method: method, headers: headers)
    .uploadProgress { progress in
      print("Upload Progress: \(progress.fractionCompleted * 100)%")
    }
    .validate()
    .response { response in
      switch (response.result) {
      case .failure(let error):
        switch error {
        case .sessionTaskFailed(URLError.timedOut):
          self.sendStatusAndDismiss(status: ScanStatus.TimedOut)
        case .sessionTaskFailed(URLError.notConnectedToInternet):
          self.reuploadTask()
        default:
          self.sendStatusAndDismiss(status: ScanStatus.Error)
        }
      case .success:
        self.sendStatusAndDismiss(status: ScanStatus.OK)
      }
    }
  }
  
  func sendStatusAndDismiss(status: ScanStatus) {
    onDismiss?(status)
    
    let dismissAction = {
      self.activityIndicator.stopAnimating()
      self.dismiss(animated: true, completion: nil)
    }

    if status == .OK {
      DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: dismissAction)
    } else {
      finalStructure = nil
      DispatchQueue.main.async(execute: dismissAction)
    }
  }
  
  // MARK: - Present and Save Preview
  func presentPreview(previewController: RPPreviewViewController?) {
    guard let previewController = previewController else {
      print("Preview controller is nil")
      return
    }
    
    // Present the preview controller to allow the user to save the recording
    previewController.previewControllerDelegate = self
    self.present(previewController, animated: true)
  }
  
  public func startSession() {
    print("starting session")
    roomCaptureView?.captureSession.run(configuration: roomCaptureSessionConfig)
  }
  
  @IBAction func restartSession() {
    print("restarting session")
    exportButton.removeFromSuperview()
    anotherScanButton.removeFromSuperview()
    roomCaptureView?.captureSession.run(configuration: roomCaptureSessionConfig)
    finishButton.addTarget(self, action: #selector(stopSession), for: .touchUpInside)
    finishButton.isEnabled = true;
  }
  
  @objc
  public func stopSession() {
    roomCaptureView?.captureSession.stop(pauseARSession: false)
    setupPostScanUI()
  }

  @objc
  func reuploadTask() {
    let alertController = UIAlertController(title: "You are not connected to the internet.", message: "Connect to the internet, then press OK to attempt another upload. Otherwise, you can cancel the scan.", preferredStyle: .alert)

    let confirmAction = UIAlertAction(title: "Confirm", style: .destructive, handler: superExportResults)
    alertController.addAction(confirmAction)
    
    let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { _ in self.sendStatusAndDismiss(status: ScanStatus.Canceled) }
    alertController.addAction(cancelAction)
    
    self.present(alertController, animated: true, completion: nil)
  }
  
  @objc
  func cancelSession() {
    // Create the alert controller
    let alertController = UIAlertController(
      title: "Cancel Room Scan?", 
      message: "If a scan is canceled, you'll have to start over again next time.", 
      preferredStyle: .alert
    )

    // Add the "Confirm" button
    let confirmAction = UIAlertAction(title: "Confirm", style: .destructive) { action in
      self.sendStatusAndDismiss(status: ScanStatus.Canceled)
    }
    alertController.addAction(confirmAction)
    
    let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
    alertController.addAction(cancelAction)
    
    self.present(alertController, animated: true, completion: nil)
  }
  
  func captureSession(_ session: RoomCaptureSession, didProvide instruction: RoomCaptureSession.Instruction) {
      // Preview instruction to the user
      print("INSTRUCTION: ", instruction)
  }
  
  func captureSession(_ session: RoomCaptureSession, didAdd: CapturedRoom) {
    if (didAdd.objects.count > 0) {
      let objectName = getCategoryNameString(category: didAdd.objects[0].category)
      let confidence = getConfidenceString(object: didAdd.objects[0])
      let text = "Found " + objectName + "."
      DispatchQueue.main.async {
        self.feedbackLabel.isHidden = false
        self.feedbackLabel.text = text
      }
      
      DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
        UIView.transition(with: self.feedbackLabel, duration: 0.4,
                          options: .transitionCrossDissolve,
                          animations: {
          self.feedbackLabel.isHidden = true
        }
        )
      }
    }
    print("didAdd")
  }
  
  func getCategoryNameString(category: CapturedRoom.Object.Category) -> String {
    switch category {
    case .bathtub:
      return "bathtub"
    case .bed:
      return "bed"
    case .chair:
      return "chair"
    case .dishwasher:
      return "dishwasher"
    case .fireplace:
      return "fireplace"
    case .oven:
      return "oven"
    case .refrigerator:
      return "refrigerator"
    case .sink:
      return "sink"
    case .sofa:
      return "sofa"
    case .stairs:
      return "stairs"
    case .storage:
      return "storage"
    case .stove:
      return "stove"
    case .table:
      return "table"
    case .television:
      return "television"
    case .toilet:
      return "toilet"
    case .washerDryer:
      return "washer/dryer"
    default:
      return "object"
    }
  }
  
  func getConfidenceString(object: CapturedRoom.Object) -> String {
    switch object.confidence {
    case .high:
      return "high"
    case .medium:
      return "medium"
    case .low:
      return "low"
    default:
      return "medium"
    }
  }
  
  @objc
  static func requiresMainQueueSetup() -> Bool {
    return true
  }
}


@available(iOS 17.0, *)
extension RoomPlanCaptureViewController: RoomCaptureSessionDelegate {
  func captureSession(_ session: RoomCaptureSession, didUpdate: CapturedRoom) {
    print("didUpdate", didUpdate.objects.count)
  }
  
  func captureSession(_ session: RoomCaptureSession, didChange: CapturedRoom) {
    print("didChange", didChange.objects.count)
  }
  
  func captureSession(_ session: RoomCaptureSession, didEndWith: CapturedRoomData, error: (any Error)?) {
    print("didEndWith")
    let roomBuilder = RoomBuilder(options: [.beautifyObjects])
    Task {
        if let capturedRoom = try? await roomBuilder.capturedRoom(from: didEndWith) {
            print("appending new captured room")
            self.capturedRoomArray.append(capturedRoom)
        } else {
            print("Failed to build captured room.")
        }
    }
  }
}

@available(iOS 17.0, *)
extension RoomPlanCaptureViewController: RoomCaptureViewDelegate {
  func captureView(shouldPresent roomDataForProcessing: CapturedRoomData, error: Error?) -> Bool {
    return true
  }
  
  // Access the final results
  func captureView(didPresent processedResult: CapturedRoom, error: Error?) {
    print("This happened")
    finalResults = processedResult
  }
}