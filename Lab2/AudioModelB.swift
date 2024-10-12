//
//  AudioModelB.swift
//  Lab2
//
//  Created by Chrishnika Paul on 10/6/24.
//  Based on template code by Eric Larson. Copyright © 2020 Eric Larson. All rights reserved.

import Foundation
import Accelerate

class AudioModelB {
    
    // MARK: Properties
    private var BUFFER_SIZE:Int
    var timeData:[Float]
    var fftData:[Float]
    var gesture:String
    lazy var samplingRate:Int = {
        return Int(self.audioManager!.samplingRate)
    }()
    var lowBandwidth:Int
    var highBandwidth:Int
    //var volume:Float = 0.1 // user setable volume
    
    // MARK: Public Methods
    init(buffer_size:Int) {
        BUFFER_SIZE = buffer_size
        // anything not lazily instatntiated should be allocated here
        timeData = Array.init(repeating: 0.0, count: BUFFER_SIZE)
        fftData = Array.init(repeating: 0.0, count: BUFFER_SIZE/2)
        gesture = "Not gesturing"
        lowBandwidth = 3
        highBandwidth = 4
    }
    
    // public function for starting processing of microphone data
    func startMicrophoneProcessing(withFps:Double){
        // setup the microphone to copy to circualr buffer
        self.audioManager?.inputBlock = self.handleMicrophone
        
        // repeat this fps times per second using the timer class
        //   every time this is called, we update the arrays "timeData" and "fftData"
        Timer.scheduledTimer(withTimeInterval: 1.0/withFps, repeats: true) { _ in
            self.runEveryInterval()
        }
        
    }
    
    func startProcessingSinewaveForPlayback(withFreq:Float=330.0){
        sineFrequency = withFreq
        if let manager = self.audioManager{
            // swift sine wave loop creation
            manager.outputBlock = self.handleSpeakerQueryWithSinusoid
        }
    }
    
    // You must call this when you want the audio to start being handled by our model
    func play(){
        if let manager = self.audioManager{
            manager.play()
        }
    }
    
    func updateBandwidth(){
        if self.sineFrequency < 18000{
            self.lowBandwidth = 3
            self.highBandwidth = 4
        }else{
            self.lowBandwidth = 2
            self.highBandwidth = 3
        }
    }
    
    //==========================================
    // MARK: Private Properties
    private lazy var audioManager:Novocaine? = {
        return Novocaine.audioManager()
    }()
    
    private lazy var fftHelper:FFTHelper? = {
        return FFTHelper.init(fftSize: Int32(BUFFER_SIZE))
    }()
    
    private lazy var inputBuffer:CircularBuffer? = {
        return CircularBuffer.init(numChannels: Int64(self.audioManager!.numInputChannels),
                                   andBufferSize: Int64(BUFFER_SIZE))
    }()
    
    private lazy var freqRes:Float? = {
       return Float(samplingRate)/Float(BUFFER_SIZE)
    }()
    
    private var meanBelow:Float = 0.0
    private var meanAbove:Float = 0.0
    private var arrayBelow:[Float] = Array.init(repeating: 0.0, count: 10)
    private var arrayAbove:[Float] = Array.init(repeating: 0.0, count: 10)
    
    
    //==========================================
    // MARK: Private Methods
    
    
    //==========================================
    // MARK: Model Callback Methods
   
    private func runEveryInterval(){
        if inputBuffer != nil {
            // copy time data to swift array
            self.inputBuffer!.fetchFreshData(&timeData, // copied into this array
                                             withNumSamples: Int64(BUFFER_SIZE))
            
            // now take FFT
            fftHelper!.performForwardFFT(withData: &timeData,
                                         andCopydBMagnitudeToBuffer: &fftData) // fft result is copied into fftData array
            
            let index = Int(sineFrequency/freqRes!)     //Index of bin corresponding to sine wave frequency
            var gestureAway:Bool = false                //Flag for conditions for geturing away
            var gestureTowards:Bool = false             //Flag for conditions for geturing towards
            
            
            //The fft magnitude in bins neighboring the bin corresponding to the sine wave were observed to be less than 0.0
            //when there was no doppler effect. For an fft magnitude buffer of size 2048, this was true for bins with index <= index of sine frequency - 2 and index >= index + 3.
            print(Array(fftData[index-10...index+10]))
            let lowFreqArray = Array(fftData[index-10...index-self.lowBandwidth])       //Neighboring bins of lower frequency
            var highFreqArray = Array(fftData[index+self.highBandwidth...index+10])      //Neighboring bins of higher frequency
            vDSP.reverse(&highFreqArray)                                //Reverse order of higher frequency bins for later comparison
            let lowFreqLength = vDSP_Length(lowFreqArray.count)
            let highFreqLength = vDSP_Length(highFreqArray.count)
            var lastCrossingLow: vDSP_Length = 0                        //Index in lower frequencies where amplitude sign changes
            var numCrossingsLow: vDSP_Length = 0
            var lastCrossingHigh: vDSP_Length = 0                       //Index in higher frequencies where amplitude sign changes
            var numCrossingsHigh: vDSP_Length = 0
            
            //Find zero crossings in amplitude for frequencies immediately higher and lower than peak frequency.
            vDSP_nzcros(lowFreqArray, 1, lowFreqLength, &lastCrossingLow, &numCrossingsLow, lowFreqLength)
            vDSP_nzcros(highFreqArray, 1, highFreqLength, &lastCrossingHigh, &numCrossingsHigh, highFreqLength)
            
            if numCrossingsLow > 0{     //Magnitude sign changes in neighboring lower frequency bins
                gestureAway = true      //Conditions for gesturing away met
            }
            if numCrossingsHigh > 0{    //Magnitude sign changes in neigboring higher frequency bins
                gestureTowards = true   //Conditions for gesturing towards met
            }
            if gestureAway && gestureTowards{
                if lastCrossingLow < lastCrossingHigh{
                    self.gesture = "Gesturing Away"
                }else if lastCrossingHigh < lastCrossingLow{
                    self.gesture = "Gesturing Towards"
                }else{
                    self.gesture = "Not gesturing"
                }
            }else if gestureAway{
                self.gesture = "Gesturing Away"
            }else if gestureTowards{
                self.gesture = "Gesturing Towards"
            }else{
                self.gesture = "Not gesturing"
            }
            //print(gesture)

        }
    }
    
    //==========================================
    // MARK: Audiocard Callbacks
    //  (^InputBlock)(float *data, UInt32 numFrames, UInt32 numChannels)
    
    //    _     _     _     _     _     _     _     _     _     _
    //   / \   / \   / \   / \   / \   / \   / \   / \   / \   /
    //  /   \_/   \_/   \_/   \_/   \_/   \_/   \_/   \_/   \_/
    var sineFrequency:Float = 0.0 { // frequency in Hz (changeable by user)
        didSet{
            if let manager = self.audioManager {
                // if using swift for generating the sine wave: when changed, we need to update our increment
                phaseIncrement = Float(2*Double.pi*Double(sineFrequency)/manager.samplingRate)
            }
        }
    }
    
    // SWIFT SINE WAVE
    // everything below here is for the swift implementation
    private var phase:Float = 0.0
    private var phaseIncrement:Float = 0.0
    private var sineWaveRepeatMax:Float = Float(2*Double.pi)
    
    private func handleSpeakerQueryWithSinusoid(data:Optional<UnsafeMutablePointer<Float>>, numFrames:UInt32, numChannels: UInt32){
        // while pretty fast, this loop is still not quite as fast as
        // writing the code in c, so I placed a function in Novocaine to do it for you
        // use setOutputBlockToPlaySineWave() in Novocaine
        // EDIT: fixed in 2023
        if let arrayData = data{
            var i = 0
            let chan = Int(numChannels)
            let frame = Int(numFrames)
            if chan==1{
                while i<frame{
                    arrayData[i] = sin(phase)
                    phase += phaseIncrement
                    if (phase >= sineWaveRepeatMax) { phase -= sineWaveRepeatMax }
                    i+=1
                }
            }else if chan==2{
                let len = frame*chan
                while i<len{
                    arrayData[i] = sin(phase)
                    arrayData[i+1] = arrayData[i]
                    phase += phaseIncrement
                    if (phase >= sineWaveRepeatMax) { phase -= sineWaveRepeatMax }
                    i+=2
                }
            }
            //var volume:Float =
            // adjust volume of audio file output
            //vDSP_vsmul(arrayData, 1, &(self.volume), arrayData, 1, vDSP_Length(numFrames*numChannels))
            //vDSP_vsmul(arrayData, 1, &volume, arrayData, 1, vDSP_Length(numFrames*numChannels))
                            
        }
    }
    
    private func handleMicrophone (data:Optional<UnsafeMutablePointer<Float>>, numFrames:UInt32, numChannels: UInt32) {
        // copy samples from the microphone into circular buffer
        self.inputBuffer?.addNewFloatData(data, withNumSamples: Int64(numFrames))
    }
}
