//
//  DownloadCacheManager.swift
//  OfflineVideoPlayer
//
//  Created by Raju on 24/01/22.
//

import UIKit

enum DownloadState {
    case yetToStart, pending, downloaded, inProgress
    
    func buttonName() -> String {
        switch self {
        case .yetToStart:
            return "Download"
        case .pending:
            return "Resume"
        case .downloaded:
            return "Play"
        case .inProgress:
            return "Downloading..."
        }
    }
};

struct DownloadConfig {
    static let videoURL = "https://v2s3z9v2.stackpathcdn.com/videos/output_03112021.mp4"
    static let filePath = localFilePath(for: "video.mp4")
    static let taskIdentifier = "Ventuno"
    
    static func localFilePath(for fileName: String) -> URL {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
      return documentsPath.appendingPathComponent(fileName)
    }
}

class DownloadCacheManager: NSObject {
    
    static let sharedInstance = DownloadCacheManager()
    let backgroundTaskUtil = BackgroundTaskManager()
    
    func downloadVideo(completionPercentage: @escaping (CGFloat) -> Void, completionHandler: @escaping (Bool) -> Void) {
        if let url = URL(string: DownloadConfig.videoURL) {
            backgroundTaskUtil.checkAndResumeTask(withIdentifier: DownloadConfig.taskIdentifier, url: url, toLocation: DownloadConfig.filePath, completionPercentage: completionPercentage, completionHandler: completionHandler)
            UserDefaults.standard.set(true, forKey: "AlreadyStarted")
            UserDefaults.standard.synchronize()
        }
    }
    
    func downloadState() -> DownloadState {
        if isAlreadyDownloaded() {
            return .downloaded
        } else {
            return UserDefaults.standard.bool(forKey: "AlreadyStarted") ? .pending : .yetToStart
        }
    }
    
    private func isAlreadyDownloaded () -> Bool {
        print("Location : \(DownloadConfig.filePath.path)")
        let fileManager = FileManager.default
        return fileManager.fileExists(atPath: DownloadConfig.filePath.path)
    }
    
}
