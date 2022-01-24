//
//  ViewController.swift
//  OfflineVideoPlayer
//
//  Created by Raju on 24/01/22.
//

import UIKit
import AVKit
import AVFoundation

class ViewController: UIViewController {
    @IBOutlet weak var ctcButton: UIButton!
    @IBOutlet weak var progressBar: UIProgressView!
    @IBOutlet weak var videoContainer: UIView!
    @IBOutlet weak var infoLbl: UILabel!
    var downloadState: DownloadState = .yetToStart
    let playerController = AVPlayerViewController()
    var playerLayer: AVPlayerLayer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        downloadState = DownloadCacheManager.sharedInstance.downloadState()
        ctcButton.setTitle(downloadState.buttonName(), for: .normal)
        progressBar.isHidden = true
        videoContainer.isHidden = false
        self.infoLbl.isHidden = true
    }

    @IBAction func didTapCTCButton(_ sender: UIButton) {
        switch downloadState {
        case .yetToStart, .pending:
            self.downloadState = .inProgress
            self.progressBar.isHidden = false
            self.progressBar.progress = 0
            self.ctcButton.setTitle(downloadState.buttonName(), for: .normal)
            DownloadCacheManager.sharedInstance.downloadVideo { downloadedPersentage in
                print("inprogress: \(downloadedPersentage)%")
                self.progressBar.progress = Float(downloadedPersentage)
            } completionHandler: { completed in
                self.progressBar.isHidden = true
                if completed {
                    self.downloadState = .downloaded
                    self.ctcButton.setTitle(self.downloadState.buttonName(), for: .normal)
                } else {
                    self.downloadState = .pending
                    self.ctcButton.setTitle("Download fail, Try again", for: .normal)
                }
            }
            
        case .downloaded:
            self.addVideoPlayer(pathURL: DownloadConfig.filePath, to: self.videoContainer)
        case .inProgress: break
            // do nothing
        }
    }

    private func playVideo(pathURL: URL) {
        let player = AVPlayer(url: pathURL)
        let playerController = AVPlayerViewController()
        playerController.player = player
        present(playerController, animated: true) {
            player.play()
        }
    }
    
    func addVideoPlayer(pathURL: URL, to view: UIView) {
        if self.playerLayer == nil {
            view.isHidden = false
            let player = AVPlayer(url: pathURL)
            let layer: AVPlayerLayer = AVPlayerLayer(player: player)
            layer.backgroundColor = UIColor.white.cgColor
            layer.frame = view.bounds
            layer.videoGravity = .resizeAspectFill
            view.layer.sublayers?
                .filter { $0 is AVPlayerLayer }
                .forEach { $0.removeFromSuperlayer() }
            view.layer.addSublayer(layer)
            self.playerLayer = layer
            self.infoLbl.isHidden = false
        }
        if let plyr = self.playerLayer?.player, plyr.isPlaying == true {
            self.playerLayer?.player?.pause()
            ctcButton.setTitle("Play", for: .normal)
        } else {
            self.playerLayer?.player?.play()
            ctcButton.setTitle("Pause", for: .normal)
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        ///
        if let layer = self.playerLayer {
            layer.frame = videoContainer.bounds
        }
    }
}

extension AVPlayer {
    var isPlaying: Bool {
        return rate != 0 && error == nil
    }
}

