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
    private var BUFFER_SIZE:Int             //Audio buffer size
    private var TONE_SEPARATION:Int         //Minimum difference between tones that must be distinguished in Hz
    private var THRESHOLD:Float = 10.0      //Threshold in dB for frequency magnitude to not be considered noise
    private var timer:Timer?
    private var lowBandwidth:Int = 3
    private var highBandwidth:Int = 4
    
    private lazy var frequencyResolution:Float = {
        //frequency resolution calculation, k = Fs/N
        return Float(samplingRate) / Float(BUFFER_SIZE)
    }()
    
    private lazy var windowSize:Int = {
        //size of window required to distinguish tones based on minimum tone separation
        return Int((Float(TONE_SEPARATION) / frequencyResolution).rounded(.up))
    }()
    
    private lazy var midWindowOffset:Int = {
        //index offset for element in middle of window
        return windowSize/2
    }()

    // these properties are for interfacing with the API
    // the user can access these properties at any time and display them if they like
    var timeData:[Float]
    var fftData:[Float]
    var maxFrequencies:[Float]          //public property that holds the two frequencies with greatest magnitude
    var gesture:String
    
    lazy var samplingRate:Int = {
        return Int(self.audioManager!.samplingRate)
    }()
    

    
    // MARK: Public Methods
    
    init(buffer_size:Int, tone_separation:Int=50) {
        BUFFER_SIZE = buffer_size
        TONE_SEPARATION = tone_separation

        // anything not lazily instatntiated should be allocated here
        timeData = Array.init(repeating: 0.0, count: BUFFER_SIZE)
        fftData = Array.init(repeating: 0.0, count: BUFFER_SIZE/2)
        maxFrequencies = Array.init(repeating: 0.0, count: 2)
        gesture = "Not gesturing"
    }
    
    // public function for starting processing of microphone data
    func startMicrophoneProcessing(withFps:Double){
        // setup the microphone to copy to circular buffer
        if let manager = self.audioManager{
            manager.inputBlock = self.handleMicrophone
            
            // repeat this fps times per second using the timer class
            //   every time this is called, we update the arrays "timeData" and "fftData"
            timer = Timer.scheduledTimer(withTimeInterval: 1.0/withFps, repeats: true) { _ in
                self.runEveryInterval()
            }
        }
    }
    
    func startProcessingSinewaveForPlayback(withFreq:Float){
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
    
    func pause(){
        if let manager = self.audioManager,
           let timer = self.timer{
            manager.pause()
            timer.invalidate()
        }
    }
    
    func stop(){
        if let manager = self.audioManager{
            manager.pause()
            manager.inputBlock = nil
            manager.outputBlock = nil
        }
        
        if let buffer = self.inputBuffer{
            buffer.clear() // just makes zeros
        }
        inputBuffer = nil
        fftHelper = nil
    }
    
    func getSound()->String{
        //Empirically checking the ratio between the two highest frequencies,
        //it appeared that there the second frequency was double the first frequency
        //in the "ooo" case
        
        let f1 = maxFrequencies.min()
        let f2 = maxFrequencies.max()
        
        let freqRatio = (f2!/f1!).rounded()
        
        if freqRatio == 2.0{
            return "ooo"
        }else{
            return "aah"
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

    //==========================================
    // MARK: Private Methods
    private func printProperties(){
        
        print("Sampling rate: ", samplingRate)
        print("Frequency resolution: ", frequencyResolution)
        print("Window size: ", windowSize)
        print("Buffer size: ", self.BUFFER_SIZE)
    }
    
    func findPeaks(){
    
    //private func findPeaks(){
        
        //arrays to hold max magnitudes and index of corresponding window where max found
        var maxMagnitudes: Array<Float> = Array(repeating: THRESHOLD, count: 2)
        var maxWindows: Array<Int> = Array(repeating: -1, count: 2)
        
        //calculate the number of window using length of fft array and peak finding window size
        let numWindows = fftData.count - windowSize + 1
        
        //loop through windows searching for peaks
        for i in 0..<numWindows{
            let window = Array(fftData[i..<i+windowSize])
            let max = window.max()
            
            //peak occurs if max value is in middle of window. If new peak is > than the min peak found so far, replace peak
            if max == window[midWindowOffset] && max! > maxMagnitudes.min()!{
                //Find the index of the lesser peak found so far
                let replaceIndex = maxMagnitudes.firstIndex(of: maxMagnitudes.min()!)
                //Save new peak and the index of the corresponding window
                maxMagnitudes[replaceIndex!] = max!
                maxWindows[replaceIndex!] = i
            }
             
        }

        //Save max frequencies and magnitudes to public properties
        for i in 0..<maxWindows.count {
            //Check that window index has been changed from initialized value of -1
            //else it indicates that no frequency with magnitude above threshold has been detected
            if maxWindows[i] > -1 {
                //Calculate index of peak in fftData array based on window index and offset of element at the middle of the window
                let fftIndex = maxWindows[i] + midWindowOffset
                //Use quadratic approximation to fine tune the frequency
                let fPeak = fPeakByQuadApprox(fftIndex: fftIndex)

                //Update maxFrequencies public property if it does not contain this freq
                if !self.maxFrequencies.contains(fPeak){
                    self.maxFrequencies[i] = fPeak
                }
            }
        }
    }
    
    //Function that uses quadratic approximation to determine the frequency peak
    //as the vertex of a parabaola through neighboring points
    private func fPeakByQuadApprox(fftIndex:Int)->Float{
        let f2 = Float(fftIndex) * frequencyResolution
        let m2 = fftData[fftIndex]
        let m1 = fftData[fftIndex-1]
        let m3 = fftData[fftIndex+1]
        let fPeak = f2 + ((m1 - m3)/(m3 - 2*m2 + m1)) * self.frequencyResolution/2
        return fPeak
    }
    
    func detectGestures(){
    
    //private func detectGestures(){
        let index = Int(sineFrequency/frequencyResolution)     //Index of bin corresponding to sine wave frequency
        var gestureAway:Bool = false                //Flag for conditions for geturing away
        var gestureTowards:Bool = false             //Flag for conditions for geturing towards
        
        
        //The fft magnitude in bins neighboring the bin corresponding to the sine wave were observed to be less than 0.0
        //when there was no doppler effect. For an fft magnitude buffer of size 2048, this was true for bins with index <= index of sine frequency - 2 and index >= index + 3.
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
        
    }
    
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
            
            // Find frequencies with peak magnitude in new fft data
            //findPeaks()
            
            //detectGestures()
        }
    }
    

    
    //==========================================
    // MARK: Audiocard Callbacks
    // in obj-C it was (^InputBlock)(float *data, UInt32 numFrames, UInt32 numChannels)
    // and in swift this translates to:
    
    // SWIFT SINE WAVE
    private var phase:Float = 0.0
    private var phaseIncrement:Float = 0.0
    private var sineWaveRepeatMax:Float = Float(2*Double.pi)
    
    var sineFrequency:Float = 0.0 { // frequency in Hz (changeable by user)
        didSet{
            if let manager = self.audioManager {
                // if using swift for generating the sine wave: when changed, we need to update our increment
                phaseIncrement = Float(2*Double.pi*Double(sineFrequency)/manager.samplingRate)
            }
        }
    }
    
    private func handleMicrophone (data:Optional<UnsafeMutablePointer<Float>>, numFrames:UInt32, numChannels: UInt32) {
        // copy samples from the microphone into circular buffer
        self.inputBuffer?.addNewFloatData(data, withNumSamples: Int64(numFrames))
    }
    
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
        }
    }
}

