//
//  ViewController.swift
//  Lab2
//
//  Created by Chrishnika Paul on 9/29/24.
//

import UIKit

class ViewController: UIViewController {
    
    @IBOutlet weak var frequency1Label: UILabel!        //Displays frequency with highest magnitude
    @IBOutlet weak var frequency2Label: UILabel!        //Displays frequency with second highest magnitude
    @IBOutlet weak var soundLabel: UILabel!             //Displays if sound is 'ooo' or 'aah'
    
    struct AudioConstants{
        static let AUDIO_BUFFER_SIZE = 1024*4           //Max size of buffer to allow detection of tones played for 200ms
        static let TONE_SEPARATION = 50                 //Separation in Hz of tones that need to be distinguished
    }
    
    // setup audio model with lazy instantiation and nillable
    lazy var audio:AudioModel? = {
        return AudioModel(buffer_size: AudioConstants.AUDIO_BUFFER_SIZE, tone_separation: AudioConstants.TONE_SEPARATION)
    }()
    
    private var timer:Timer?

    override func viewDidLoad() {
        print("test")
        super.viewDidLoad()

        // start up the audio model here, querying microphone
        audio!.startMicrophoneProcessing(withFps: 20) // preferred number of FFT calculations per second
        audio!.play()
        
        timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
            self.updateLabels()
        }
    }
    
    // periodically, update the graph with refreshed FFT Data
    func updateLabels(){
        let maxFreqSorted = self.audio?.maxFrequencies.sorted()     //Frequencies sorted in magnitude order
        frequency1Label.text = String(format: "%.2f Hz", maxFreqSorted![0])
        frequency2Label.text = String(format: "%.2f Hz", maxFreqSorted![1])
        soundLabel.text = self.audio?.getSound()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        //Pause and nil audio when navigating away from view
        timer?.invalidate()
        audio?.pause()
        audio = nil
        
        super.viewWillDisappear(animated)
    }
}

