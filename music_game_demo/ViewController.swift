//
//  ViewController.swift
//  music_game_demo
//
//  Created by Do Xuan Thanh on 9/6/19.
//  Copyright © 2019 monstar-lab. All rights reserved.
//

import UIKit
import AVFoundation
import CoreAudio

class ViewController: UIViewController {

    @IBOutlet weak var startButton: UIButton!
    @IBOutlet weak var scoreLabel: UILabel!
    @IBOutlet weak var missLabel: UILabel!
    var timer: Timer?
    var running = false
    let shapeLayer = CAShapeLayer()
    var viewWidth = CGFloat(0.0)
    let loaderLayer = CAShapeLayer()
    var score = 0
    let pointers = [CAShapeLayer(), CAShapeLayer()]
    var targets: [CGFloat] = [0.0, 0.0]
    var player = AVAudioPlayer()
    var soundPlayer = AVAudioPlayer()
    //recorder
    var recorder: AVAudioRecorder!
    var levelTimer = Timer()
    let LEVEL_THRESHOLD: Float = -10.0
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        startButton.setTitle("play", for: .normal)
        reloadBar()
        let tap = UITapGestureRecognizer(target: self, action: #selector(tapped))
        view.addGestureRecognizer(tap)
        scoreLabel.text = String(score)
        scoreLabel.font = UIFont.systemFont(ofSize: 50)
        scoreLabel.textColor = UIColor.white
        missLabel.font = UIFont.systemFont(ofSize: 50)
        missLabel.textColor = UIColor.white
        missLabel.isHidden = true
        view.backgroundColor = UIColor(patternImage: UIImage(named: "danceStage")!)
        //clap detection
        let documents = URL(fileURLWithPath: NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)[0])
        let url = documents.appendingPathComponent("record.caf")
        
        let recoredSettings: [String: Any] = [
            AVFormatIDKey:              kAudioFormatAppleIMA4,
            AVSampleRateKey:            44100.0,
            AVNumberOfChannelsKey:      2,
            AVEncoderBitRateKey:        12800,
            AVLinearPCMBitDepthKey:     16,
            AVEncoderAudioQualityKey:   AVAudioQuality.max.rawValue
        ]
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(AVAudioSession.Category.playAndRecord)
            try audioSession.setActive(true)
            try recorder = AVAudioRecorder(url: url, settings: recoredSettings)
        } catch {
            return
        }
        recorder.prepareToRecord()
        recorder.isMeteringEnabled = true
        recorder.record()
        levelTimer = Timer.scheduledTimer(timeInterval: 0.02, target: self, selector: #selector(levelTimerCallback), userInfo: nil, repeats: true)
        
    }
    
    @objc func levelTimerCallback() {
        recorder.updateMeters()
        let level = recorder.averagePower(forChannel: 0)
        print(level)
//        let isLoud = level > LEVEL_THRESHOLD
//        print("isLoad: \(isLoud)")
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        reloadBar()
    }
    
    func reloadBar() {
        viewWidth = view.bounds.width
        let rect = CGRect(x: viewWidth / 4, y: 100, width: viewWidth / 2, height: 50)
        let roundedRect = UIBezierPath(roundedRect: rect, cornerRadius: 50)
        shapeLayer.path = roundedRect.cgPath
        shapeLayer.fillColor = UIColor.white.cgColor
        shapeLayer.strokeColor = UIColor.green.cgColor
        shapeLayer.lineWidth = 2
        view.layer.addSublayer(shapeLayer)
        
        let loaderRect = CGRect(x: viewWidth / 4, y: 100, width: 5, height: 50)
        let loaderPath = UIBezierPath(roundedRect: loaderRect, cornerRadius: 20)
        loaderLayer.path = loaderPath.cgPath
        loaderLayer.fillColor = UIColor.red.cgColor
        shapeLayer.addSublayer(loaderLayer)
    }

    @IBAction func play(_ sender: Any) {
        if running {
            startButton.setTitle("play", for: .normal)
            running = false
            //handle pause
        } else {
            startButton.setTitle("pause", for: .normal)
            playSound()
            running = true
            newLoop()
        }
    }
    
    @objc func updateProgress() {
        
    }
    
    @objc func tapped() {
        handleAction()
    }
    
    func newLoop() {
        sufflePointer()
        let anm = CABasicAnimation(keyPath: "position")
        anm.fromValue = loaderLayer.position
        anm.toValue = CGPoint(x: viewWidth / 2, y: 0)
        anm.duration = 3.0
//        anm.repeatCount = 100 // (song length / loop duration)
        anm.delegate = self
        loaderLayer.add(anm, forKey: "test")
    }
    
    func sufflePointer() {
        targets.removeAll()
        for pointer in pointers {
            let rand = CGFloat(Float(arc4random()) / Float(UINT32_MAX)) // random 0...1
            let x_val = viewWidth / 4 + (viewWidth * rand / 2 )
            let pointerRect = CGRect(x: x_val, y: 100, width: 10, height: 50)
            let pointerPath = UIBezierPath(roundedRect: pointerRect, cornerRadius: 20)
            pointer.path = pointerPath.cgPath
            pointer.fillColor = UIColor.green.cgColor
            shapeLayer.addSublayer(pointer)
            targets.append(x_val - viewWidth / 4)
        }
    }
    
    func playSound() {
        guard let url = Bundle.main.url(forResource: "sound", withExtension: "mp3") else { return }
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
            player = try AVAudioPlayer(contentsOf: url, fileTypeHint: AVFileType.mp3.rawValue)
            player.play()
        } catch let error {
            print(error.localizedDescription)
        }
    }
    
    override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        if motion == .motionShake {
            print("shaked")
            handleAction()
        }
    }
    
    func handleAction() {
        if let pos = loaderLayer.presentation()?.position {
            print(pos.x)
            for target in targets {
                if abs(target - pos.x) <= 20 {
                    score += 1
                    guard let url = Bundle.main.url(forResource: "catch", withExtension: "wav") else { return }
                    do {
                        soundPlayer = try AVAudioPlayer(contentsOf: url, fileTypeHint: AVFileType.wav.rawValue)
                        soundPlayer.play()
                    } catch let error {
                        print(error.localizedDescription)
                    }
                    UIView.transition(with: scoreLabel, duration: 0.5, options: .transitionCurlUp, animations: { [weak self] in
                        if let self = self {
                            self.scoreLabel.text = String(self.score)
                        }
                        }, completion: nil)
                    return
                }
            }
        }
        showMiss()
    }
    
    func showMiss() {
        guard let url = Bundle.main.url(forResource: "failed", withExtension: "wav") else { return }
        do {
            soundPlayer = try AVAudioPlayer(contentsOf: url, fileTypeHint: AVFileType.wav.rawValue)
            soundPlayer.play()
        } catch let error {
            print(error.localizedDescription)
        }
        UIView.transition(with: missLabel, duration: 0.5, options: .transitionCrossDissolve, animations: { [weak self] in
            self?.missLabel.isHidden = false
            
            }, completion: {result in
                self.missLabel.isHidden = true
        })
    }
    
}

extension ViewController : CAAnimationDelegate {
    func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        print("stopped")
        loaderLayer.removeAllAnimations()
        newLoop()
    }
}

