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
  
  var mic: AKMicrophone!
  var tracker: AKFrequencyTracker!
  var silence: AKBooster!
//  var fft: AKFFTTap!

  var movPlayer:AVPlayer?
  
  let codeWindow = 5.0
  let updateInterval = 0.05
  var maxCount:Int = 0;
  var listenForCode = false
  //var listenTimer:Timer?
  
  var counter:Int = 0
  let frequencyRange = 90.0
  
  let startSignal:Double = 17500
  let signalOptions:[(freq:Double,file:String)] =
    [(17300,"plantTest"),
     (17100,"gwcTest")]
  
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
    //print("maxcount: \(maxCount)")
    
    AKSettings.audioInputEnabled = true
    AKSettings.sampleRate = 96000
    mic = AKMicrophone()
    tracker = AKFrequencyTracker.init(mic, hopSize:64, peakCount:4)
    silence = AKBooster(tracker, gain: 0)
//    fft = AKFFTTap(mic)
    
    setupVideo()
  }
  
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    
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
    //listenTimer?.invalidate()
    //listenTimer = nil;
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
        //listenTimer?.invalidate()
        //listenTimer = Timer.scheduledTimer(timeInterval: codeWindow, target: self, selector: #selector(ViewController.resetListenState), userInfo: nil, repeats: false)
        
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
      
      
      
//      //frequencyLabel.text = String(format: "%0.1f", tracker.frequency)
//      print(tracker.frequency)
//    
//      if tracker.frequency > 17900 {
//        colorBox.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 1)
//      } else if tracker.frequency > 17400 {
//        colorBox.backgroundColor = UIColor(red: 0, green: 1, blue: 0, alpha: 1)
//      } else if tracker.frequency > 16900 {
//        colorBox.backgroundColor = UIColor(red: 0, green: 0, blue: 1, alpha: 1)
//        //setupVideo()
//      } else if tracker.frequency > 16400 {
//        colorBox.backgroundColor = UIColor(red: 1, green: 1, blue: 0, alpha: 1)
//      } else if tracker.frequency > 15900 {
//        colorBox.backgroundColor = UIColor(red: 0, green: 1, blue: 1, alpha: 1)
//      } else if tracker.frequency > 15400 {
//        colorBox.backgroundColor = UIColor(red: 1, green: 0, blue: 1, alpha: 1)
//      } else if tracker.frequency > 14900 {
//        colorBox.backgroundColor = UIColor(red: 1, green: 0, blue: 0, alpha: 1)
//      }
    }
  }
  
  func setupVideo() {
    
    let pathToEx1 = Bundle.main.path(forResource: "Videos/plantTest", ofType: "mp4")
    let pathURL = NSURL.fileURL(withPath: pathToEx1!)
    
    movPlayer = AVPlayer(url:pathURL)
  
    let movLayer = AVPlayerLayer(player: movPlayer)
    vidContainer.layer.addSublayer(movLayer)
    movLayer.frame = vidContainer.bounds
    movLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
    
    //NotificationCenter.default.addObserver(self, selector: "playerDidFinishPlaying:",name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: movPlayer?.currentItem)
    
    //NotificationCenter.default.addObserver(forName: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: nil, queue: nil) { _ in playerDidFinishPlaying }
    
    NotificationCenter.default.addObserver(self, selector: #selector(self.playerDidFinishPlaying), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: nil)


    movPlayer?.volume = 0;
    //movPlayer?.play()
    
    if let name = getCurrentVideoName() {
      print(name)
    }
    
    vidContainer.alpha = 0.0;
    //playCurrentVideo()
    //cueAndPlayVideo(fileName: "plantTest")
  }
  
  func playCurrentVideo() {
    //vidContainer.alpha = 1.0;
    fadeVideoUp()
    movPlayer?.play()
    //changeAudioMode()
  }
  
  func stopVideo() {
    //vidContainer.alpha = 0.0;
    fadeVideoDown()
    movPlayer?.pause()
    //changeAudioMode()
  }
  
  func playerDidFinishPlaying(note: Notification) {
    //print("Video Finished - \(note.object)")
    if let currentItem = note.object as? AVPlayerItem,
    let asset = currentItem.asset as? AVURLAsset {
      var filename = asset.url.lastPathComponent.characters.split{$0 == "."}.map(String.init)
      print(filename[0]);
    }
    stopVideo()
  }
  
  func getCurrentVideoName() -> String? {
    if let asset = movPlayer?.currentItem?.asset as? AVURLAsset {
      var filename = asset.url.lastPathComponent.characters.split{$0 == "."}.map(String.init)
      return filename[0]
    }
    return nil
  }
  
  func cueAndPlayVideo(fileName: String) {
    //changeAudioMode()
    let pathToEx1 = Bundle.main.path(forResource: "Videos/\(fileName)", ofType: "mp4")
    let pathURL = NSURL.fileURL(withPath: pathToEx1!)
    let asset = AVAsset(url: pathURL)
    //let assetKeys = [ "playable" ]
    let playerItem = AVPlayerItem(asset: asset)
    movPlayer?.pause()
    movPlayer?.replaceCurrentItem(with: playerItem)
    movPlayer?.volume = 0
    //vidContainer.alpha = 1.0;
    fadeVideoUp()
    movPlayer?.play()
    //AudioKit.start()
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

