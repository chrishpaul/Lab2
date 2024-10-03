//
//  ViewController.swift
//  Lab2
//
//  Created by Chrishnika Paul on 9/29/24.
//

import UIKit

class ViewController: UIViewController {
    
    @IBOutlet var userView: UIView!
    struct AudioConstants{
        static let AUDIO_BUFFER_SIZE = 1024*8
        static let TONE_SEPARATION = 50
    }
    
    // setup audio model with lazy instantiation and nillable
    lazy var audio:AudioModel? = {
        return AudioModel(buffer_size: AudioConstants.AUDIO_BUFFER_SIZE, tone_separation: AudioConstants.TONE_SEPARATION)
    }()

    lazy var graph:MetalGraph? = {
        return MetalGraph(userView: self.userView)
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        if let graph = self.graph{
            graph.setBackgroundColor(r: 0, g: 0, b: 0, a: 1)
            
            // add in graphs for display
            // note that we need to normalize the scale of this graph
            // because the fft is returned in dB which has very large negative values and some large positive values
            
            
            graph.addGraph(withName: "fft",
                            shouldNormalizeForFFT: true,
                            numPointsInGraph: AudioConstants.AUDIO_BUFFER_SIZE/2)
            
            
            graph.addGraph(withName: "time",
                numPointsInGraph: AudioConstants.AUDIO_BUFFER_SIZE)
            
            
            
            graph.makeGrids() // add grids to graph
        }
        
        // start up the audio model here, querying microphone
        audio!.startMicrophoneProcessing(withFps: 20) // preferred number of FFT calculations per second
        
        audio!.play()
        
        Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
            self.updateGraph()
        }
    }
    
    // periodically, update the graph with refreshed FFT Data
    func updateGraph(){
        
        if let graph = self.graph,
           let audio = self.audio{
            graph.updateGraph(
                data: audio.fftData,
                forKey: "fft"
            )
            
            graph.updateGraph(
                data: audio.timeData,
                forKey: "time"
            )
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        //Pause and nil audio when navigating away from view
        audio?.pause()
        audio = nil;
        
        super.viewWillDisappear(animated)
    }


}

