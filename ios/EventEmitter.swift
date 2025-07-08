import ExpoModulesCore

enum ScanStatus: String {
  case NotStarted
  case PermissionDenied
  case Canceled
  case TimedOut
  case Error
  case OK
}

class RoomPlanEventEmitter: EventEmitter {
  override func supportedEvents() -> [String] {
    return ["onDismissEvent"]
  }

  func sendDismissEvent(_ status: ScanStatus) {
    sendEvent("onDismissEvent", [
      "value": status.rawValue
    ])
  }
}