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
     
    // this is a computed property in swift
    // when asked for, the array will be calculated from the input buffer
    /*
    var timeData:[Float]{
        get{ //override getter, get frech data from buffer
            self.inputBuffer!.fetchFreshData(&_timeData,
                                             withNumSamples: Int64(BUFFER_SIZE))
            return _timeData
        }
    }
     */
    var volume:Float = 0.1 // user setable volume
    
    // MARK: Public Methods
    init(buffer_size:Int) {
        BUFFER_SIZE = buffer_size
        // anything not lazily instatntiated should be allocated here
        timeData = Array.init(repeating: 0.0, count: BUFFER_SIZE)
        fftData = Array.init(repeating: 0.0, count: BUFFER_SIZE/2)
        gesture = "Not gesturing"
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
            
            // at this point, we have saved the data to the arrays:
            //   timeData: the raw audio samples
            //   fftData:  the FFT of those same samples
            // the user can now use these variables however they like
            
            var index = Int(sineFrequency/freqRes!)
            //var startIndex = index - 100
            //print("Index: ", startIndex, " : ", index)
            var newBelow = Array(fftData[index-10..<index])
            var newAbove = Array(fftData[index+1...index+10])
            var diffBelow = vDSP.mean(vDSP.subtract(newBelow, arrayBelow))
            var diffAbove = vDSP.mean(vDSP.subtract(newAbove, arrayAbove))
            if (diffBelow > 1.0 && diffAbove < 0.0) {
                print("Gesturing Away")
            }else if (diffAbove > 1.0 && diffBelow < 0.0) {
                print("Gesturing Towards")
            }
            //print("Diff below: ", diffBelow, " , ", diffAbove)
            arrayBelow = newBelow
            arrayAbove = newAbove
            //vDSP_sve(arrayBelow, 1, &meanBelow, vDSP_Length(arrayBelow.count))
            //vDSP_sve(arrayAbove, 1, &meanAbove, vDSP_Length(arrayAbove.count))
            //vDSP_vrsum(arrayBelow, 1, &meanBelow, <#T##__C: UnsafeMutablePointer<Float>##UnsafeMutablePointer<Float>#>, <#T##__IC: vDSP_Stride##vDSP_Stride#>, <#T##__N: vDSP_Length##vDSP_Length#>)
            //vDSP_measqv(arrayBelow, 1, &meanBelow, vDSP_Length(arrayBelow.count))
            //vDSP_meanv(arrayBelow, 1, &meanBelow,100)
            /*
            var diff = meanAbove - meanBelow
            var gesture = "Not gesturing"
            if diff < 70{
                gesture = "Gesturing away"
                print("Gesture: ", gesture)
            }else if diff > 130{
                gesture = "Gesturing towards"
                print("Gesture: ", gesture)
            }
            //print("Gesture: ", diff)*/
            
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
            // adjust volume of audio file output
            vDSP_vsmul(arrayData, 1, &(self.volume), arrayData, 1, vDSP_Length(numFrames*numChannels))
                            
        }
    }
    
    private func handleMicrophone (data:Optional<UnsafeMutablePointer<Float>>, numFrames:UInt32, numChannels: UInt32) {
        // copy samples from the microphone into circular buffer
        self.inputBuffer?.addNewFloatData(data, withNumSamples: Int64(numFrames))
    }
}
