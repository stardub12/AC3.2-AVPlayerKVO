//
//  ViewController.swift
//  AVPlayerKVO
//
//  Created by Jason Gresh on 1/25/17.
//  Copyright © 2017 C4Q. All rights reserved.
//

import UIKit
import AVFoundation

private var kvoContext = 0

class ViewController: UIViewController {
    var player: AVPlayer! {
        willSet {
            if player != nil {
                if let item = self.player.currentItem {
                    item.removeObserver(self, forKeyPath: #keyPath(AVPlayerItem.status), context: &kvoContext)
                    item.removeObserver(self, forKeyPath: #keyPath(AVPlayerItem.loadedTimeRanges), context: &kvoContext)
                }
                
                if let token = self.timeObserverToken {
                    player.removeTimeObserver(token)
                }
            }
            
            if let item = newValue.currentItem {
                item.addObserver(self, forKeyPath: #keyPath(AVPlayerItem.status), options: .new, context: &kvoContext)
                item.addObserver(self, forKeyPath: #keyPath(AVPlayerItem.loadedTimeRanges), options: .new, context: &kvoContext)            }
            
            let timeInterval = CMTime(value: 1, timescale: 2)
            self.timeObserverToken = newValue.addPeriodicTimeObserver(forInterval: timeInterval, queue: DispatchQueue.main, using: { (time: CMTime) in
                print(time)
                self.updatePositionSlider()
                self.updateProgressView()
            })
        }
    }
    
    var userPlayRate: Float = 1.0
    var userPlaying: Bool = false
    var timeObserverToken: Any?
    
    @IBOutlet weak var rateSlider: UISlider!
    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var videoContainer: UIView!
    @IBOutlet weak var playPauseButton: UIButton!
    @IBOutlet weak var positionSlider: UISlider!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        loadAssetFromFile(urlString: "debussy.mp3")
        
        if let url = URL(string: "https://archive.org/download/VoyagetothePlanetofPrehistoricWomen/VoyagetothePlanetofPrehistoricWomen.mp4") {
            let playerItem = AVPlayerItem(url: url)
            
            self.player = AVPlayer(playerItem: playerItem)
            
            let playerLayer = AVPlayerLayer(player: player)
            self.videoContainer.layer.addSublayer(playerLayer)
        }
    }
    
    override func viewDidLayoutSubviews() {
        
        
        guard let sublayers = self.videoContainer.layer.sublayers
            else {
                return
        }
        
        for layer in sublayers {
            layer.frame = self.videoContainer.bounds
        }
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        print("***********\n\n\n\n\(UIDevice.current.orientation.isLandscape)\n\n\n\n************")
        
        coordinator.animate(alongsideTransition: { (UIViewControllerTransitionCoordinator) in
            let orientation = UIApplication.shared.statusBarOrientation
            
            switch orientation {
            case .portrait:
                print("Portrait")
            case .landscapeLeft, .landscapeRight:
                print("Landscape")
                self.configureLandscape()
            default:
                print("Neither portrait/landscape")
            }
            
        }, completion: { (UIViewControllerTransitionCoordinator) in
                print("rotation completed")
             self.view.layoutIfNeeded()
        })
        
    }
    
    func configureLandscape() {
        
        _ = [
        videoContainer,
        positionSlider,
        rateSlider,
        playPauseButton
            ].map { $0.translatesAutoresizingMaskIntoConstraints = false }
        
       view.addConstraint(NSLayoutConstraint(item: videoContainer, attribute: .top, relatedBy: .equal, toItem: self.view, attribute: .top, multiplier: 1, constant: 10))
        view.addConstraint(NSLayoutConstraint(item: videoContainer, attribute: .leading, relatedBy: .equal, toItem: self.view, attribute: .leading, multiplier: 1, constant: 10))
        view.addConstraint(NSLayoutConstraint(item: videoContainer, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: self.view.frame.width/2))
        view.addConstraint(NSLayoutConstraint(item: videoContainer, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: self.view.frame.height-50))
        
        view.addConstraint(NSLayoutConstraint(item: positionSlider, attribute: .top, relatedBy: .equal, toItem: videoContainer, attribute: .bottom, multiplier: 1, constant: 10))
        view.addConstraint(NSLayoutConstraint(item: positionSlider, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: self.view.frame.width/2))
        
        view.addConstraint(NSLayoutConstraint(item: rateSlider, attribute: .leading, relatedBy: .equal, toItem: videoContainer, attribute: .trailing, multiplier: 1, constant: 30))
//        view.addConstraint(NSLayoutConstraint(item: rateSlider, attribute: .centerY, relatedBy: .equal, toItem: self.view, attribute: .centerY, multiplier: 1, constant: 0))
//        
//        
//        view.addConstraint(NSLayoutConstraint(item: playPauseButton, attribute: .top, relatedBy: .equal, toItem: rateSlider, attribute: .bottom, multiplier: 1, constant: 30))
        
    }
    
    
    // MARK: - Utility
    func updatePositionSlider() {
        guard let item = player.currentItem else { return }
        
        let currentPlace = Float(item.currentTime().seconds / item.duration.seconds)
        self.positionSlider.value = currentPlace
    }
    
    func updateProgressView() {
        guard let item = player.currentItem else { return }
        
        let currentPlace = Float(item.currentTime().seconds / item.duration.seconds)
        self.progressView.progress = currentPlace
    }
    
    func loadAssetFromFile(urlString: String) {
        guard let dot = urlString.range(of: ".") else { return }
        let fileParts = (resource: urlString.substring(to: dot.lowerBound), extension: urlString.substring(from: dot.upperBound))
        
        if let fileURL = Bundle.main.url(forResource: fileParts.resource, withExtension: fileParts.extension) {
            let asset = AVURLAsset(url: fileURL)
            let playerItem = AVPlayerItem(asset: asset)
            
            self.player = AVPlayer(playerItem: playerItem)
        }
    }
    
    // MARK: - KVO
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        guard let keyPath = keyPath else {
            return
        }
        if context == &kvoContext {
            if let item = object as? AVPlayerItem {
                switch keyPath {
                case #keyPath(AVPlayerItem.status):
                    if item.status == .readyToPlay {
                        playPauseButton.isEnabled = true
                    }
                case #keyPath(AVPlayerItem.loadedTimeRanges):
                    for range in item.loadedTimeRanges {
                        print(range.timeRangeValue)
                    }
                default:
                    break
                }
            }
        }
    }
    
    // MARK: - Actions
    @IBAction func positionSliderChanged(_ sender: UISlider) {
        guard let item = player.currentItem else { return }
        
        let newPosition = Double(sender.value) * item.duration.seconds
        
        player.seek(to: CMTime(seconds: newPosition, preferredTimescale: 1000))
        
        player.playImmediately(atRate: userPlayRate)
    }
    
    @IBAction func rateChange(_ sender: UISlider) {
        guard let item = player.currentItem else { return }
        
        userPlayRate = sender.value
        
        if item.canPlayFastForward {
            print("I can fast forward. Rate requested: \(sender.value).")
        }
        if item.canPlaySlowForward {
            print("I can slow forward")
        }
        
        if userPlaying {
            player.rate = userPlayRate
        }
        //print("NEW rate: \(player.rate).")
        
    }
    
    @IBAction func playPausePressed(_ sender: UIButton) {
        if !userPlaying {
            player.playImmediately(atRate: userPlayRate)
            sender.setTitle("Pause", for: .normal)
            //userPlaying = false
        }
        else {
            player.pause()
            sender.setTitle("Play", for: .normal)
            //userPlaying = true
        }
        userPlaying = !userPlaying
    }
    
    
}
