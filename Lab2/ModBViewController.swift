//
//  ModBViewController.swift
//  Lab2
//
//  Created by Chrishnika Paul on 10/6/24.
//

import UIKit

class ModBViewController: UIViewController {
    
    //MARK: Outlets
    @IBOutlet weak var gestureLabel: UILabel!
    @IBOutlet weak var graphView: UIView!
    @IBOutlet weak var freqLabel: UILabel!
    @IBOutlet weak var freqSlider: UISlider!
    
    //MARK: Constants
    // setup constants
    struct AudioConstants{
        static let AUDIO_BUFFER_SIZE = 1024*4
    }
    
    //MARK: Variables
    // setup audio model with specified buffer size
    lazy var audio:AudioModel? = {
        return AudioModel(buffer_size: AudioConstants.AUDIO_BUFFER_SIZE)
    }()
    
    // setup a view to show the graph
    lazy var graph:MetalGraph? = {
        return MetalGraph(userView: self.graphView)
    }()
    
    //Timer used to call update graph and gesture label
    private var timer:Timer?
    
    //Used to control size of frequency steps allowed by slider
    let stepValue:Float = 100.0

    //MARK: View Update Functions
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // add in a graph for displaying the zoomed FFT
        if let graph = self.graph {
            graph.addGraph(withName: "fftZoomed",
                            shouldNormalizeForFFT: true,
                            numPointsInGraph: 100) // 100 points to display
            
            // make vertical grids on the graph
            graph.makeGrids()
        }
        
        // Begin playing sinewave on speakers and processing mic input
        audio!.startProcessingSinewaveForPlayback(withFreq: 17000)      //Start playing sine wave with default frequency
        audio!.startMicrophoneProcessing(withFps: 20)                   //
        audio!.play()
        
        // run the loop for updating the graph and gesture peridocially
        // 0.05 is about 20FPS update
        Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
            self.updateGraphAndGesture()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        //Stop and nil audio, timer and graph when navigating away from view
        timer?.invalidate()
        timer = nil
        graph?.teardown()
        graph = nil
        audio?.stop()
        audio = nil
        
        super.viewWillDisappear(animated)
    }
    
    // periodically, update the graph with refreshed FFT Data
    func updateGraphAndGesture(){
        // display the audio data
        if let graph = self.graph,
           let audio = self.audio{
            let freq = Int(audio.sineFrequency)
            
            //Get a subarray centered around the index in fft corresponding to sine frequency
            let centerIdx:Int = freq * AudioConstants.AUDIO_BUFFER_SIZE/audio.samplingRate
            let startIdx = centerIdx - 50
            let endIdx = centerIdx + 50
            let subArray:[Float] = Array(self.audio!.fftData[startIdx...endIdx])

            //Update graph
            graph.updateGraph(
                data: subArray,
                forKey: "fftZoomed"
            )
            
            //Detect gestures and update display label
            audio.detectGestures()
            gestureLabel.text = audio.gesture
        }
    }
    
    //MARK: Actions
    @IBAction func changeFrequency(_ sender: UISlider) {
        //Increment sinewave frequency in increments of step value
        self.audio!.sineFrequency = roundf(sender.value / self.stepValue)*self.stepValue
        
        //Adjust number of neighboring bins considered to detect wave reflection based on sine frequency
        self.audio!.updateBandwidth()
        
        //Update label displaying current frequency
        freqLabel.text = String(format: "Frequency: %.0f Hz", self.audio!.sineFrequency)
    }

}
