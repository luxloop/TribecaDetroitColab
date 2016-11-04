//
//  ViewController.swift
//  TribecaDetroitColab
//
//  Created by Ivaylo Getov on 11/4/16.
//  Copyright © 2016 Luxloop. All rights reserved.
//

import UIKit
import AudioKit

class ViewController: UIViewController {
  
  @IBOutlet weak var colorBox: UIView!
  
  var mic: AKMicrophone!
  var tracker: AKFrequencyTracker!
  var silence: AKBooster!
//  var fft: AKFFTTap!
  
  

  override func viewDidLoad() {
    super.viewDidLoad()
    
    AKSettings.audioInputEnabled = true
    AKSettings.sampleRate = 96000
    mic = AKMicrophone()
    tracker = AKFrequencyTracker.init(mic, hopSize:64, peakCount:100)
    silence = AKBooster(tracker, gain: 0)
//    fft = AKFFTTap(mic)
  }
  
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    
    AudioKit.output = silence
    AudioKit.start()
    
    Timer.scheduledTimer(timeInterval: 0.05, target: self, selector: #selector(ViewController.update), userInfo: nil, repeats: true)
  }
  
  
  func update() {
    //print(tracker.frequency)
    //if tracker.amplitude > 0.1 {
    
//    let max = fft.fftData.max()!
//    if let index = fft.fftData.index(of: max) {
//      if index > 80 {
//        print("FFT: max: \(max) at index: \(index) of \(fft.fftData.count)");
//      }
//    }
    
    
    if tracker.frequency > 12000 {
      //frequencyLabel.text = String(format: "%0.1f", tracker.frequency)
      print(tracker.frequency)
    
      if tracker.frequency > 17900 {
        colorBox.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 1)
      } else if tracker.frequency > 17400 {
        colorBox.backgroundColor = UIColor(red: 0, green: 1, blue: 0, alpha: 1)
      } else if tracker.frequency > 16900 {
        colorBox.backgroundColor = UIColor(red: 0, green: 0, blue: 1, alpha: 1)
      } else if tracker.frequency > 16400 {
        colorBox.backgroundColor = UIColor(red: 1, green: 1, blue: 0, alpha: 1)
      } else if tracker.frequency > 15900 {
        colorBox.backgroundColor = UIColor(red: 0, green: 1, blue: 1, alpha: 1)
      } else if tracker.frequency > 15400 {
        colorBox.backgroundColor = UIColor(red: 1, green: 0, blue: 1, alpha: 1)
      } else if tracker.frequency > 14900 {
        colorBox.backgroundColor = UIColor(red: 1, green: 0, blue: 0, alpha: 1)
      }
    }
  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }


}

