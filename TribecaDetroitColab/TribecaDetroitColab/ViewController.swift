//
//  ViewController.swift
//  TribecaDetroitColab
//
//  Created by Ivaylo Getov on 11/4/16.
//  Copyright © 2016 Luxloop. All rights reserved.
//

import UIKit
import AudioKit
import MediaPlayer
import AVKit

class ViewController: UIViewController {
  
  @IBOutlet weak var colorBox: UIView!
  @IBOutlet weak var vidContainer: UIView!
  @IBOutlet weak var backgroundVidContainer: UIView!
  
  var mic: AKMicrophone!
  var tracker: AKFrequencyTracker!
  var silence: AKBooster!

  var movPlayer:AVPlayer?
  var backgroundMovie:AVPlayer?
  
  let codeWindow = 5.0
  let updateInterval = 0.05
  var maxCount:Int = 0;
  var listenForCode = false
  
  var counter:Int = 0
  let frequencyRange = 90.0
  
  let startSignal:Double = 17500
  let signalOptions:[(freq:Double,file:String)] =
    [(16000,"PBD_Chapter1"),
     (16500,"PBD_Chapter2"),
     (16250,"PBD_Chapter3"),
     (16750,"PBD_Chapter4")]
  
  func changeAudioMode() {
    do {
      try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayAndRecord)
    } catch let error as NSError {
      print(error)
    }
    
    do {
      try AVAudioSession.sharedInstance().setActive(true)
    } catch let error as NSError {
      print(error)
    }
  }
  
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    changeAudioMode()
    maxCount = Int((1/updateInterval) * codeWindow)
    
    AKSettings.audioInputEnabled = true
    AKSettings.sampleRate = 96000
    mic = AKMicrophone()
    tracker = AKFrequencyTracker.init(mic, hopSize:64, peakCount:4)
    silence = AKBooster(tracker, gain: 0)
    
  }
  
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    
    NotificationCenter.default.addObserver(self, selector: #selector(self.playerDidFinishPlaying), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: nil)
    
    setupBackground()
    setupVideo()
    
    AudioKit.output = silence
    AudioKit.start()
    
    Timer.scheduledTimer(timeInterval: 0.05, target: self, selector: #selector(ViewController.update), userInfo: nil, repeats: true)
  }
  
  deinit {
    NotificationCenter.default.removeObserver(self, name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: nil)
  }
  
  func isMatch(input:Double,reference:Double) -> Bool {
    if (abs(reference - input) < frequencyRange) {
      return true
    }
    return false
  }
  
  func resetListenState() {
    listenForCode = false
    counter = 0
    print("Stop Listen")
  }
  
  func update() {
    if listenForCode {
      if counter < maxCount {
        counter += 1
      } else {
        resetListenState()
      }
    }
    if tracker.frequency > 14000 {
      print(tracker.frequency);
      
      if !listenForCode && isMatch(input: tracker.frequency, reference: startSignal) {
        print("Start Listen")
        listenForCode = true;
        counter = 0
      } else if listenForCode {
        for option in signalOptions {
          if isMatch(input: tracker.frequency, reference: option.freq) {
            print("Match. Will load: \(option.file)")
            resetListenState()
            if let name = getCurrentVideoName() {
              if name == option.file {
                print("Already Loaded")
                playCurrentVideo()
              } else {
                cueAndPlayVideo(fileName: option.file)
              }
            }
            break
          }
        }
      }
    }
  }
  
  func setupBackground() {
    
    let pathToFile = Bundle.main.path(forResource: "Videos/ScreenBackground", ofType: "mp4")
    let pathURL = NSURL.fileURL(withPath: pathToFile!)

    backgroundMovie = AVPlayer(url:pathURL)
    let movLayer = AVPlayerLayer(player: backgroundMovie)
    backgroundVidContainer.layer.addSublayer(movLayer)
    movLayer.frame = backgroundVidContainer.bounds
    movLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
    backgroundMovie?.volume = 0;
    backgroundMovie?.play()
  }
  
  func setupVideo() {
    
    let pathToFile = Bundle.main.path(forResource: "Videos/PBD_Chapter1", ofType: "mp4")
    let pathURL = NSURL.fileURL(withPath: pathToFile!)
    
    movPlayer = AVPlayer(url:pathURL)
  
    let movLayer = AVPlayerLayer(player: movPlayer)
    vidContainer.layer.addSublayer(movLayer)
    movLayer.frame = vidContainer.bounds
    
    movLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
    movPlayer?.volume = 0;
    
    if let name = getCurrentVideoName() {
      print(name)
    }
    
    vidContainer.alpha = 0.0;
  }
  
  func playCurrentVideo() {
    fadeVideoUp()
    movPlayer?.play()
  }
  
  func stopVideo() {
    fadeVideoDown()
//    let t1 = CMTimeMake(5, 100);
//    self.movPlayer?.seek(to: t1)
    movPlayer?.pause()
  }
  
  func playerDidFinishPlaying(note: Notification) {
    if let currentItem = note.object as? AVPlayerItem,
    let asset = currentItem.asset as? AVURLAsset {
      var filename = asset.url.lastPathComponent.characters.split{$0 == "."}.map(String.init)
      print("video ended: \(filename[0])");
      if filename[0] == "ScreenBackground" {
        let t1 = CMTimeMake(5, 100);
        self.backgroundMovie!.seek(to: t1)
        self.backgroundMovie!.play()
      } else {
        stopVideo()
      }
    }
  }
  
  func getCurrentVideoName() -> String? {
    if let asset = movPlayer?.currentItem?.asset as? AVURLAsset {
      var filename = asset.url.lastPathComponent.characters.split{$0 == "."}.map(String.init)
      return filename[0]
    }
    return nil
  }
  
  func cueAndPlayVideo(fileName: String) {
    let pathToEx1 = Bundle.main.path(forResource: "Videos/\(fileName)", ofType: "mp4")
    let pathURL = NSURL.fileURL(withPath: pathToEx1!)
    let asset = AVAsset(url: pathURL)
    let playerItem = AVPlayerItem(asset: asset)
    movPlayer?.pause()
    movPlayer?.replaceCurrentItem(with: playerItem)
    movPlayer?.volume = 0
    fadeVideoUp()
    movPlayer?.play()
  }
  
  func fadeVideoDown() {
    UIView.animate(withDuration: 0.5, delay: 0.0, options: UIViewAnimationOptions.curveEaseOut, animations: { self.vidContainer.alpha = 0.0; }, completion: nil)
  }
  
  func fadeVideoUp() {
    UIView.animate(withDuration: 0.5, delay: 0.0, options: UIViewAnimationOptions.curveEaseOut, animations: { self.vidContainer.alpha = 1.0; }, completion: nil)
  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }
}

