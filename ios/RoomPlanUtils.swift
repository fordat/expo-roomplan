enum ScanStatus: String {
  case NotStarted
  case Canceled
  case Error
  case OK
}

struct CaptureOptions {
    let exportType: String?
    let sendFileLoc: Bool?
    
    init(exportType: String? = nil, sendFileLoc: Bool? = nil) {
        self.exportType = exportType
        self.sendFileLoc = sendFileLoc
    }
}