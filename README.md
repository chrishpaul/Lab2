# Lab2
Audio Filtering, the FFT, and Doppler Shifts

Requirements & Tasks:
- [ ] Landing view with navigation to either Module A or Module B - Use a table view controller with navigation controller
- [ ] Proper handling of Novocaine Manager input and output blocks when navigating between controllers
-  What is meant by proper handling? Nilling the audio manager so that to avoid lingering input and output blocks from previous controller?
- [ ] Use proper coding techniques and naming conventions for all programming languages.

Module A
- [ ] Read from the microphone
- [ ] Take FFT of the incoming audio stream
- [ ] Design and document an efficent algorithm to find frequencies of 2 loudest tones to +-3Hz (peak finding for two tones)
- [ ] Display the frequency of the two loudest tones within +-3Hz accuracy in UILabels
- [ ] Rapidly update displayed frequencies
- [ ] Show "noise" when frequencies are not playing
- [ ] Display frequencies only when they are of large enough magnitude
- Experiment to figure out the threshold. Might be -20 to -10 dB
- [ ] Have a way to "lock in" the last frequencies of large magnitude detercted on the display
- [ ] Do not update the UILabels if no large magnitude frequencies are detected.
- [ ] Distinguish tones at least 50Hz apart that last for 200ms or more
- How does this constrain buffer size, FFT size, and windows for finding maxima
- [ ] Distinguish between ooooo and ahhhh vowel sounds using the largest two frequencies.
- [ ] Display if the sound is oooo or ahhhh as a separate UILabel
- [ ] Take a video of the app working to verify the functionality using an external sound source
- [ ] Use the audio test app to play different sine waves

Module B
- [ ] Read from the microphone
- [ ] Play a settable inaudible tone to the speakers between 17-20kHz, settable by a slider
- [ ] Display the magnitude of the FFT (in dB) zoomed into the peak that is playing
- [ ] Design and document an algorithm to reliably detect and distinguish when the user is {not gesturing, gestures toward, or guesturing away} from the microphone using Doppler shifts in the frequency

Evaluation Criteria
- [ ] Interface Design. Proper design and use of autolayout. Works in either portrait or landscape (1pt)
- What is expected for "proper design"
- [ ] Algorithm Efficiency: Algorithms for frequency finding and doppler shifts should work well in real time, using accelerate framework where possible. (1pt)
- [ ] Algorithm Design: Mange the audio object effectively and efficiently. Singleton classes used properly among view controllers. (1pt)
- [ ] Algorithm Design: Proper use of the argmax (dilation) method or other appropriate peak finding method. Algorithm should be well documented. (2pt)
- [ ] Frequency Display and Accuracy: Frequencies displayed and do not change when the app detects silence or only small noise. (1pt)
- [ ] 200ms and 50Hz: App can detect bursts of audio that are 200 ms and can detect two separate tones when they differ by at least 50 Hz. (2pt)
- [ ] Settable Tone and Displays dB: Tone for audio is settable above 17kHz and the plot of the FFT (in dB) is shown. (1pt)
- [ ] Accurate across frequency: Accurate "towards" and "away" detection and works at any settable frequency above 17kHz. (2pt)
- [ ] Excpetional Credit: Display if sound is ooo or ahh (1pt)

Turn in:
- [ ] the source code for your app in zipped format or via GitHub. (Upload as "teamNameAssignmentTwo.zip".) 
- [ ] Your team member names should appear somewhere in the Xcode project. 
- [ ] A video of your app working as intended and description of its functionality.
