//
//  AudioModel.swift
//  Lab2
//
//  Created by Chrishnika Paul on 10/3/24.
//  Based on template created by Eric Larson. Copyright © 2020 Eric Larson. All rights reserved.


import Foundation
import Accelerate

class AudioModel {
    
    // MARK: Properties
    private var BUFFER_SIZE:Int
    //private var FREQUENCY_RESOLUTION:Int
    private var TONE_SEPARATION:Int
    //private var WINDOW_SIZE:Int
    private var timer:Timer?
    private var THRESHOLD:Float = 0.0

    // these properties are for interfaceing with the API
    // the user can access these arrays at any time and plot them if they like
    var timeData:[Float]
    var fftData:[Float]
    
    lazy var samplingRate:Int = {
        return Int(self.audioManager!.samplingRate)
    }()
    
    lazy var frequencyResolution:Float = {
        return Float(samplingRate) / Float(BUFFER_SIZE)
    }()
    
    lazy var windowSize:Int = {
        return Int((Float(TONE_SEPARATION) / frequencyResolution).rounded(.up))
    }()
    
    // MARK: Public Methods
    init(buffer_size:Int, tone_separation:Int) {
        BUFFER_SIZE = buffer_size
        TONE_SEPARATION = tone_separation
        //WINDOW_SIZE = samplingRate / BUFFER_SIZE
        // anything not lazily instatntiated should be allocated here
        timeData = Array.init(repeating: 0.0, count: BUFFER_SIZE)
        fftData = Array.init(repeating: 0.0, count: BUFFER_SIZE/2)
        // TODO: Remove
        printProperties()
    }
    
    // public function for starting processing of microphone data
    func startMicrophoneProcessing(withFps:Double){
        // setup the microphone to copy to circualr buffer
        if let manager = self.audioManager{
            manager.inputBlock = self.handleMicrophone
            
            // repeat this fps times per second using the timer class
            //   every time this is called, we update the arrays "timeData" and "fftData"
            Timer.scheduledTimer(withTimeInterval: 1.0/withFps, repeats: true) { _ in
                self.runEveryInterval()
            }
            
        }
    }
    
    /*
    // public function for starting processing of audio file
    func startAudioFileProcessing(withFps:Double){
        // setup the speakers to read and play audio file
        if let manager = self.audioManager{
            manager.outputBlock = self.handleSpeakerQueryWithAudioFile
            
            // repeat this fps times per second using the timer class
            //   every time this is called, we update the arrays "timeData" and "fftData"
            
            timer = Timer.scheduledTimer(withTimeInterval: 1.0/withFps, repeats: true) { _ in
                self.runEveryInterval()
            }
        }
    }
    */
    
    // TODO: Delete
    /*
    func startProcesingAudioFileForPlayback(){
        // set the output block to read from and play the audio file
        if let manager = self.audioManager,
           let fileReader = self.fileReader{
            manager.outputBlock = self.handleSpeakerQueryWithAudioFile
            fileReader.play() // tell file Reader to start filling its buffer
        }
    }
    */
    
    // You must call this when you want the audio to start being handled by our model
    func play(){
        // TODO: Remove debug
        if windowSize == 0 {
            print("Unknown window size")
        }
        if let manager = self.audioManager{
            manager.play()
        }
    }
    
    // TODO: Delete
    /*
    func play(){
        if let manager = self.audioManager,
           let fileReader = self.fileReader{
            manager.play()
            fileReader.play()
        }
    }
    */
    func pause(){
        if let manager = self.audioManager,
           let timer = self.timer{
            manager.pause()
            timer.invalidate()
        }
    }
    
    // TODO: Delete
    /*
    func pause(){
        if let manager = self.audioManager,
           let fileReader = self.fileReader,
           let timer = self.timer{
            manager.pause()
            fileReader.pause()
            timer.invalidate()
        }
    }
    */
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
    // TODO: Delete
    /*
    private lazy var fileReader:AudioFileReader? = {
        if let url = Bundle.main.url(forResource: "satisfaction", withExtension: "mp3"){
            var tmpFileReader:AudioFileReader? = AudioFileReader.init(audioFileURL: url, samplingRate: Float(audioManager!.samplingRate), numChannels: audioManager!.numOutputChannels)
            tmpFileReader!.currentTime = 0.0
            print("Audio file successfully loaded for \(url)")
            return tmpFileReader
        }else{
            print("Could not initialize audio input file")
            return nil
        }
    }()
    */
    
    //==========================================
    // MARK: Private Methods
    // NONE for this model
    
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
            
            findPeaks()
            
            // TODO: Delete
            /*
            var startIndex = 0
            var endIndex = startIndex + CHUNK_SIZE
            var max:Float = 0
            
            for index in 0..<20{
                let chunk = Array(fftData[startIndex..<endIndex])
                vDSP_maxv(chunk, 1, &max, vDSP_Length(CHUNK_SIZE))
                equalizerData[index] = max
                startIndex = endIndex
                endIndex = startIndex + CHUNK_SIZE
            }
            
            // at this point, we have saved the data to the arrays:
            //   timeData: the raw audio samples
            //   fftData:  the FFT of those same samples
            //   equalizerData: a 20 point equalized version of the FFT
            // the user can now use these variables however they like
             */
            
        }
    }
    
    private func printProperties(){
        
        print("Sampling rate: ", samplingRate)
        print("Frequency resolution: ", frequencyResolution)
        print("Window size: ", windowSize)
        print("Buffer size: ", self.BUFFER_SIZE)
    }
    
    private func findPeaks(){
        let midWindowIndex = windowSize/2
        var maxMagnitudes: Array<Float> = Array(repeating: THRESHOLD, count: 2)
        var maxFrequencies: Array<Int> = Array(repeating: -1, count: 2)
        
        //print("Mid Window Index: ", midWindowIndex)
        //var peakArray: Array<Float> = Array(repeating: THRESHOLD, count: fftData.count - windowSize)
        let numWindows = fftData.count - windowSize + 1
        //for i in 0..<peakArray.count{
        for i in 0..<numWindows{
            let window = Array(fftData[i..<i+windowSize])
            let max = window.max()
            if max == window[midWindowIndex] && max! > maxMagnitudes.min()! {
                let replaceIndex = maxMagnitudes.firstIndex(of: maxMagnitudes.min()!)
                maxMagnitudes[replaceIndex!] = max!
                maxFrequencies[replaceIndex!] = i
            }
        }
        print("Max Magnitudes: ", maxMagnitudes, " Max Frequencies: ", maxFrequencies )
    }
    
    //==========================================
    // MARK: Audiocard Callbacks
    // in obj-C it was (^InputBlock)(float *data, UInt32 numFrames, UInt32 numChannels)
    // and in swift this translates to:
    private func handleMicrophone (data:Optional<UnsafeMutablePointer<Float>>, numFrames:UInt32, numChannels: UInt32) {
        // copy samples from the microphone into circular buffer
        self.inputBuffer?.addNewFloatData(data, withNumSamples: Int64(numFrames))
    }
    // TODO: Delete
    /*
    private func handleSpeakerQueryWithAudioFile(data:Optional<UnsafeMutablePointer<Float>>, numFrames:UInt32, numChannels:UInt32){
        if let file = self.fileReader {
            file.retrieveFreshAudio(data, numFrames: numFrames, numChannels: numChannels)
            self.inputBuffer?.addNewFloatData(data, withNumSamples: Int64(numFrames))
        }
    }
     */
}

