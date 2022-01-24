//
//  BackgroundTaskManager.swift
//  OfflineVideoPlayer
//
//  Created by Raju on 24/01/22.
//

import UIKit

class BackgroundTaskManager: NSObject {
    var taskCompletionPercentage: ((CGFloat) -> Void)?
    var taskCompletionHandler: ((Bool) -> Void)?
    var toLocationURL: URL?
    
    private func urlSession(withIdentifier identifier: String) -> URLSession {
        let config = URLSessionConfiguration.background(withIdentifier: identifier)
        return URLSession(configuration: config, delegate: self, delegateQueue: OperationQueue.main)
    }
    
    /// If partially downloaded is there, resume else start new download
    func checkAndResumeTask(withIdentifier identifier:String, url: URL, toLocation: URL, completionPercentage: @escaping (CGFloat) -> Void, completionHandler: @escaping (Bool) -> Void) {
        taskCompletionPercentage = completionPercentage
        taskCompletionHandler = completionHandler
        toLocationURL = toLocation
        let urlSession = urlSession(withIdentifier: identifier)
        urlSession.getAllTasks { tasks in
            print("===========  count: \(tasks.count) =========")
            if tasks.count == 0 {
                let backgroundTask = urlSession.downloadTask(with: url)
                backgroundTask.resume()
            }
        }
    }
    
    /// Start download from start
    func startDownloadFile(withIdentifier identifier:String, url: URL, toLocation: URL, completionPercentage: @escaping (CGFloat) -> Void, completionHandler: @escaping (Bool) -> Void) {
        let urlSession = urlSession(withIdentifier: identifier)
        taskCompletionPercentage = completionPercentage
        taskCompletionHandler = completionHandler
        toLocationURL = toLocation
        let backgroundTask = urlSession.downloadTask(with: url)
        backgroundTask.resume()
    }
}

extension BackgroundTaskManager: URLSessionDownloadDelegate {
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        if let destinationURL = toLocationURL {
            let fileManager = FileManager.default
            try? fileManager.removeItem(at: destinationURL)
            
            do {
              try fileManager.copyItem(at: location, to: destinationURL)
                self.taskCompletionHandler?(true)
            } catch let error {
                self.taskCompletionHandler?(false)
            }
        } else {
            self.taskCompletionHandler?(false)
        }
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        taskCompletionPercentage?(CGFloat(totalBytesWritten)/CGFloat(totalBytesExpectedToWrite))
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didResumeAtOffset fileOffset: Int64, expectedTotalBytes: Int64) {
            print("cool didResumeAtOffset")
    }
    
}

extension BackgroundTaskManager: URLSessionDelegate {
    
    func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        DispatchQueue.main.async {
            guard let appDelegate = UIApplication.shared.delegate as? AppDelegate,
                  let backgroundCompletionHandler =
                    appDelegate.backgroundCompletionHandler else {
                        return
                    }
            backgroundCompletionHandler()
        }
    }
    
    func urlSession(_ session: URLSession, didBecomeInvalidWithError error: Error?) {

    }
}
