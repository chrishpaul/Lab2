//
//  ModBViewController.swift
//  Lab2
//
//  Created by Chrishnika Paul on 10/6/24.
//

import UIKit

class ModBViewController: UIViewController {
    
    // setup some constants we will use
    struct AudioConstants{
        static let AUDIO_BUFFER_SIZE = 1024*4
    }
    
    // setup audio model, tell it how large to make a buffer
    let audio = AudioModelB(buffer_size: AudioConstants.AUDIO_BUFFER_SIZE)
    
    // setup a view to show the different graphs
    // this is like the canvas we will use to draw!
    lazy var graph:MetalGraph? = {
        return MetalGraph(userView: self.graphView)
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // add in a graph for displaying the audio
        if let graph = self.graph {
            graph.addGraph(withName: "fftZoomed",
                            shouldNormalizeForFFT: true,
                            numPointsInGraph: 200) // 300 points to display
            
     /*
            graph.addGraph(withName: "fft",
                            shouldNormalizeForFFT: true,
                            numPointsInGraph: AudioConstants.AUDIO_BUFFER_SIZE/2)
            // create a graph called "time" that we can update
            graph.addGraph(withName: "time",
                           numPointsInGraph: AudioConstants.AUDIO_BUFFER_SIZE)
      */
            
            // make some nice vertical grids on the graph
            graph.makeGrids()
        }
        
        // Do any additional setup after loading the view.
        audio.startProcessingSinewaveForPlayback(withFreq: 17000)
        audio.startMicrophoneProcessing(withFps: 20)
        audio.play()
        
        // run the loop for updating the graph peridocially
        // 0.05 is about 20FPS update
        Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
            self.updateGraph()
        }
    }
    
    @IBOutlet weak var graphView: UIView!
    @IBOutlet weak var freqLabel: UILabel!
    @IBAction func changeFrequency(_ sender: UISlider) {
        self.audio.sineFrequency = sender.value
        freqLabel.text = "Frequency: \(sender.value) Hz"
    }
    
    // periodically, update the graph with refreshed FFT Data
    func updateGraph(){
        // display the audio data
        if let graph = self.graph {
            /*
            graph.updateGraph(
                data: self.audio.fftData,
                forKey: "fft"
            )
            
            
            // provide some fresh samples from model for graphing
            graph.updateGraph(
                data: self.audio.timeData, // graph the data
                forKey: "time" // for this graph key (we only have one)
            )
            */
            // we can start at about 150Hz and show the next 300 points
            // actual Hz = f_0 * N/F_s
            let startIdx:Int = 17500 * AudioConstants.AUDIO_BUFFER_SIZE/audio.samplingRate
            let subArray:[Float] = Array(self.audio.fftData[startIdx...startIdx+200])
            graph.updateGraph(
                data: subArray,
                forKey: "fftZoomed"
            )
            //TODO: should this be here in the View controller? Or in Model?
            //var mx:Float = 0
            //vDSP_maxv(&self.audio.fftData[startIdx], 1, &mx, vDSP_Length(300))
        }
        
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
