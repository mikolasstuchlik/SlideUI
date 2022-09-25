import Foundation

final class FileCoordinator {
    static let shared = FileCoordinator()
    
    private static let workFolder = "/slides"
    
    let appSupportURL: URL
    var workFolder: String { appSupportURL.path + FileCoordinator.workFolder }
    private var preparedFolders: Set<String> = []
    
    private init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        self.appSupportURL = appSupport
        var isDir = ObjCBool(true)
        if FileManager.default.fileExists(atPath: appSupport.path + FileCoordinator.workFolder, isDirectory: &isDir) {
            guard isDir.boolValue else {
                fatalError()
            }

            try! FileManager.default.removeItem(atPath: appSupport.path + FileCoordinator.workFolder)
        }
        
        try! FileManager.default.createDirectory(atPath: appSupport.path + FileCoordinator.workFolder, withIntermediateDirectories: true)
    }
    
    func pathToFolder(for name: String) -> String {
        if preparedFolders.contains(name) {
            return workFolder + "/" + name
        }
        
        var isDir = ObjCBool(true)
        if FileManager.default.fileExists(atPath: workFolder + "/" + name, isDirectory: &isDir) {
            guard isDir.boolValue else {
                fatalError()
            }

            try! FileManager.default.removeItem(atPath: workFolder + "/" + name)
        }
        
        try! FileManager.default.createDirectory(atPath: workFolder + "/" + name, withIntermediateDirectories: true)
        
        preparedFolders.insert(name)
        return workFolder + "/" + name
    }
    
    deinit {
        var isDir = ObjCBool(true)
        if FileManager.default.fileExists(atPath: workFolder, isDirectory: &isDir) {
            guard isDir.boolValue else {
                fatalError()
            }

            try! FileManager.default.removeItem(atPath: workFolder)
        }
    }
}
