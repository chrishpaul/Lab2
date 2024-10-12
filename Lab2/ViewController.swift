//
//  ViewController.swift
//  Lab2
//
//  Created by Chrishnika Paul on 9/29/24.
//

import UIKit

class ViewController: UIViewController {
    
    //MARK: Outlets
    @IBOutlet weak var frequency1Label: UILabel!        //Displays frequency with highest magnitude
    @IBOutlet weak var frequency2Label: UILabel!        //Displays frequency with second highest magnitude
    @IBOutlet weak var soundLabel: UILabel!             //Displays if sound is 'ooo' or 'aah'
    
    //MARK: Constants
    struct AudioConstants{
        //A buffer size of 4096 was selected to allow detection of tones played for at least 200ms
        //With a sampling frequency of 48kHz, the frame length will be 85ms (4096/48000).
        //This ensures that a 200ms tone will span at least 3 frames, which would include at least 1 full frame
        //making it easily detectable
        static let AUDIO_BUFFER_SIZE = 4096           //Max size of buffer to allow detection of tones played for 200ms
        static let TONE_SEPARATION = 50               //Separation in Hz of tones that need to be distinguished
    }
    
    //MARK: Variables
    // setup audio model with lazy instantiation and nillable
    lazy var audio:AudioModel? = {
        return AudioModel(buffer_size: AudioConstants.AUDIO_BUFFER_SIZE, tone_separation: AudioConstants.TONE_SEPARATION)
    }()
    
    // timer to schedule updating display labels
    private var timer:Timer?

    //MARK: View Update Functions
    override func viewDidLoad() {
        super.viewDidLoad()

        // start up the audio model here, querying microphone
        audio!.startMicrophoneProcessing(withFps: 20) // preferred number of FFT calculations per second
        audio!.play()
        
        //periodically update labels
        timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
            self.updateLabels()
        }
    }
    
    // periodically update display labels for frequencies and sound type
    func updateLabels(){
        //Find peak frequency magnitudes
        self.audio?.findPeaks()
        let maxFreqSorted = self.audio?.maxFrequencies.sorted()     //Frequencies sorted in magnitude order
        
        //Update frequency and sound type labels
        frequency1Label.text = String(format: "%.0f Hz", maxFreqSorted![0])
        frequency2Label.text = String(format: "%.0f Hz", maxFreqSorted![1])
        soundLabel.text = self.audio?.getSound()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        //Stop and nil audio when navigating away from view
        timer?.invalidate()
        audio?.stop()
        audio = nil
        
        super.viewWillDisappear(animated)
    }
}

