# Lab2
Audio Filtering, the FFT, and Doppler Shifts

Requirements & Tasks:
- [x] Landing view with navigation to either Module A or Module B - Use a table view controller with navigation controller
- [x] Proper handling of Novocaine Manager input and output blocks when navigating between controllers
-  What is meant by proper handling? Nilling the audio manager so that to avoid lingering input and output blocks from previous controller?
- [x] Use proper coding techniques and naming conventions for all programming languages.

Module A
- [x] Read from the microphone
- [x] Take FFT of the incoming audio stream
- [x] Design and document an efficent algorithm to find frequencies of 2 loudest tones to +-3Hz (peak finding for two tones)
- [x] Display the frequency of the two loudest tones within +-3Hz accuracy in UILabels
- [x] Rapidly update displayed frequencies
- [x] Show "noise" when frequencies are not playing
- [x] Display frequencies only when they are of large enough magnitude
- Experiment to figure out the threshold. Might be -20 to -10 dB
- [x] Have a way to "lock in" the last frequencies of large magnitude detected on the display
- [x] Do not update the UILabels if no large magnitude frequencies are detected.
- [x] Distinguish tones at least 50Hz apart that last for 200ms or more
- How does this constrain buffer size, FFT size, and windows for finding maxima
- [x] Distinguish between ooooo and ahhhh vowel sounds using the largest two frequencies.
- [x] Display if the sound is oooo or ahhhh as a separate UILabel
- [x] Take a video of the app working to verify the functionality using an external sound source
- [x] Use the audio test app to play different sine waves

Module B
- [x] Read from the microphone
- [x] Play a settable inaudible tone to the speakers between 17-20kHz, settable by a slider
- [x] Display the magnitude of the FFT (in dB) zoomed into the peak that is playing
- [x] Design and document an algorithm to reliably detect and distinguish when the user is {not gesturing, gestures toward, or guesturing away} from the microphone using Doppler shifts in the frequency

Evaluation Criteria
- [x] Interface Design. Proper design and use of autolayout. Works in either portrait or landscape (1pt)
- What is expected for "proper design"
- [x] Algorithm Efficiency: Algorithms for frequency finding and doppler shifts should work well in real time, using accelerate framework where possible. (1pt)
- [x] Algorithm Design: Mange the audio object effectively and efficiently. Singleton classes used properly among view controllers. (1pt)
- [x] Algorithm Design: Proper use of the argmax (dilation) method or other appropriate peak finding method. Algorithm should be well documented. (2pt)
- [x] Frequency Display and Accuracy: Frequencies displayed and do not change when the app detects silence or only small noise. (1pt)
- [x] 200ms and 50Hz: App can detect bursts of audio that are 200 ms and can detect two separate tones when they differ by at least 50 Hz. (2pt)
- [x] Settable Tone and Displays dB: Tone for audio is settable above 17kHz and the plot of the FFT (in dB) is shown. (1pt)
- [x] Accurate across frequency: Accurate "towards" and "away" detection and works at any settable frequency above 17kHz. (2pt)
- [x] Excpetional Credit: Display if sound is ooo or ahh (1pt)

Turn in:
- [x] the source code for your app in zipped format or via GitHub. (Upload as "teamNameAssignmentTwo.zip".) 
- [x] Your team member names should appear somewhere in the Xcode project. 
- [x] A video of your app working as intended and description of its functionality.
