//
//  MDAudioTapProcessor.m
//  iMercury
//
//  Created by Marino di Barbora on 2/8/16.
//  Copyright © 2016 Marino di Barbora. All rights reserved.
// Based on Apple's MTAudioTapProcess - Extended to add EQ and Spectrum analyzer

#import "MDAudioTapProcessor.h"
#import <Accelerate/Accelerate.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreAudioKit/CoreAudioKit.h>


typedef struct MDSpectrumAnalysisContext{
    DSPSplitComplex A;
    float *obtainedReal;
    float *spectrumArray;
    float *hann_window;
    float *in_real ;
    float *bucketPositionArray;
    Float64 maxFrames;
}MDSpectrumAnalysisContext;

typedef struct MDAudioTapProcessorContext {
    Boolean supportedTapProcessingFormat;
    Boolean isNonInterleaved;
    Float64 sampleRate;
    AudioUnit eqAudioUnit;
    Float64 sampleCount;
    UInt32 numberOfBuckets;
    void *spContext;
    void *self;
} MDAudioTapProcessorContext;



static FFTSetup fftSetup;
const Float32 kAdjust0DB = 1.5849e-13;
// array of 3rd octave frequencies used for reference -fudged to allow for greater spread on lower end
// distance between each band can be no smaller than rate sample / number of frames (44100/4096)

const float spectrumFrequenciesArray[32] = {0.005,11.886,23.803,35.850,47.373,59.606,71.500,87.745,
                                            99.213,125.000,157.490,198.425,250.000,314.980,396.850,500.000,
                                            629.961,793.701,1000.000,1259.921,1587.401,2000.000,2519.842,3174.802,
                                            4000.000,5039.684,6349.604,8000.000,10079.368,12699.208,14000.000,16158.737};
#define MAX_FRAMES 4096.0

// MDAudioProcessingTap callbacks.

static void tap_InitCallback(MTAudioProcessingTapRef tap, void *clientInfo, void **tapStorageOut);
static void tap_FinalizeCallback(MTAudioProcessingTapRef tap);
static void tap_PrepareCallback(MTAudioProcessingTapRef tap, CMItemCount maxFrames, const AudioStreamBasicDescription *processingFormat);
static void tap_UnprepareCallback(MTAudioProcessingTapRef tap);
static void tap_ProcessCallback(MTAudioProcessingTapRef tap, CMItemCount numberFrames, MTAudioProcessingTapFlags flags, AudioBufferList *bufferListInOut, CMItemCount *numberFramesOut, MTAudioProcessingTapFlags *flagsOut);

// Audio Unit callbacks.
static OSStatus AU_RenderCallback(void *inRefCon, AudioUnitRenderActionFlags *ioActionFlags, const AudioTimeStamp *inTimeStamp, UInt32 inBusNumber, UInt32 inNumberFrames, AudioBufferList *ioData);

@interface MDAudioTapProcessor ()
@property (nonatomic) AVAssetTrack *audioAssetTrack;
@property (readwrite, nonatomic) AVAudioMix *audioMix;


@end

@implementation MDAudioTapProcessor

- (id)initWithAudioAssetTrack:(AVAssetTrack *)audioAssetTrack
{
    NSParameterAssert(audioAssetTrack && [audioAssetTrack.mediaType isEqualToString:AVMediaTypeAudio]);
    
    self = [super init];
    
    if (self){
        _audioAssetTrack = audioAssetTrack;
         fftSetup = vDSP_create_fftsetup(log2f(MAX_FRAMES), FFT_RADIX2);
        _isSpectrumEnabled = NO;
        _isActiveAppState = YES;
    }
    
    return self;
}

- (AVAudioMix *)audioMix
{
    if (!_audioMix)
    {
        AVMutableAudioMix *audioMix = [AVMutableAudioMix audioMix];
        if (audioMix)
        {
            AVMutableAudioMixInputParameters *audioMixInputParameters = [AVMutableAudioMixInputParameters audioMixInputParametersWithTrack:self.audioAssetTrack];
            if (audioMixInputParameters)
            {
                MTAudioProcessingTapCallbacks callbacks;
                
                callbacks.version = kMTAudioProcessingTapCallbacksVersion_0;
                callbacks.clientInfo = (__bridge void *)self;
                callbacks.init = tap_InitCallback;
                callbacks.finalize = tap_FinalizeCallback;
                callbacks.prepare = tap_PrepareCallback;
                callbacks.unprepare = tap_UnprepareCallback;
                callbacks.process = tap_ProcessCallback;
                
                // an observation - for some reason kMTAudioProcessingTapCreationFlag_PostEffects on a 6s device reduces the frames passed in to 3779 (oddly on an older 4s we still get 4096). 
                // This doesn't happen on the Simulator. Setting the Flag to kMTAudioProcessingTapCreationFlag_PreEffects results in 4096 frames being passed in to the Tap callback, However, apply EQ gain is not reflected in output(as per distinction for _PreEffects/_PostEffects).
              
                MTAudioProcessingTapRef audioProcessingTap;
                if (noErr == MTAudioProcessingTapCreate(kCFAllocatorDefault, &callbacks, kMTAudioProcessingTapCreationFlag_PostEffects, &audioProcessingTap))
                {
                    audioMixInputParameters.audioTapProcessor = audioProcessingTap;
                    
                    CFRelease(audioProcessingTap);
                    
                    audioMix.inputParameters = @[audioMixInputParameters];
                    _audioMix = audioMix;
                }
            }
        }
    }
    
    return _audioMix;
}


- (AudioUnitParameterValue)gainForBandAtPosition:(AudioUnitParameterValue)bandPosition
{
    OSStatus status = noErr;
    AudioUnitParameterValue gain = 0;
    AVAudioMix *audioMix = self.audioMix;
    if (audioMix)
    {
        MTAudioProcessingTapRef audioProcessingTap = ((AVMutableAudioMixInputParameters *)audioMix.inputParameters[0]).audioTapProcessor;
        MDAudioTapProcessorContext *context = (MDAudioTapProcessorContext *)MTAudioProcessingTapGetStorage(audioProcessingTap);
        AudioUnit audioUnit = context->eqAudioUnit;
        if (audioUnit)
        {
            AudioUnitParameterID parameterID = kAUNBandEQParam_Gain + bandPosition;
            status = AudioUnitGetParameter(audioUnit,
                                           parameterID,
                                           kAudioUnitScope_Global,
                                           0,
                                           &gain);
            if (noErr != status){
                NSLog(@"AudioUnitSetParameter(kBandpassParam_Bandwidth): %d", (int)status);
            }
            
        }
    }
    
    return gain;
}


- (void)setGain:(AudioUnitParameterValue)gain forBandAtPosition:(Float32)bandPosition
{
    OSStatus status = noErr;
    AVAudioMix *audioMix = self.audioMix;
    if (audioMix)
    {
        MTAudioProcessingTapRef audioProcessingTap = ((AVMutableAudioMixInputParameters *)audioMix.inputParameters[0]).audioTapProcessor;
        MDAudioTapProcessorContext *context = (MDAudioTapProcessorContext *)MTAudioProcessingTapGetStorage(audioProcessingTap);
        AudioUnit audioUnit = context->eqAudioUnit;
        if (audioUnit)
        {
            AudioUnitParameterID parameterID = kAUNBandEQParam_Gain + bandPosition;
            status = AudioUnitSetParameter(audioUnit,
                                           parameterID,
                                           kAudioUnitScope_Global,
                                           0,
                                           gain,
                                           0);
            if (noErr != status){
                NSLog(@"AudioUnitSetParameter(kBandpassParam_Bandwidth): %d", (int)status);
            }
        }
    }
}


- (void)updateSpectrumAnalysisResults:(NSMutableArray*)frequencyBucket bucketCount:(UInt32)buckets;
{
    @autoreleasepool
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            // Forward spectrum data to delegate.
            if (self.delegate && [self.delegate respondsToSelector:@selector(audioTapProcessor:hasNewFrequencybucketArray: numberOfBuckets:)])
                [self.delegate audioTapProcessor:self hasNewFrequencybucketArray:frequencyBucket numberOfBuckets:buckets];
        });
    }
}


@end

#pragma mark - MTAudioProcessingTap Callbacks


static void tap_InitCallback(MTAudioProcessingTapRef tap, void *clientInfo, void **tapStorageOut)
{
    //initialize SpectrumAnalysisContext
    MDSpectrumAnalysisContext *spectrumContext = calloc(1, sizeof(MDSpectrumAnalysisContext));
    spectrumContext->spectrumArray = NULL;
    spectrumContext->in_real = NULL;
    spectrumContext->obtainedReal = NULL;
     spectrumContext->hann_window = NULL;
    spectrumContext->maxFrames = 0.0f;
    
    MDAudioTapProcessorContext *context = calloc(1, sizeof(MDAudioTapProcessorContext));
    
    // Initialize MDAudioProcessingTap context.
    context->supportedTapProcessingFormat = false;
    context->isNonInterleaved = false;
    context->sampleRate = NAN;
    context->eqAudioUnit = NULL;
    context->sampleCount = 0.0f;
    context->spContext =  spectrumContext;
    context->self = clientInfo;
    
    *tapStorageOut = context;
}


static void tap_FinalizeCallback(MTAudioProcessingTapRef tap)
{
    MDAudioTapProcessorContext *context = (MDAudioTapProcessorContext *)MTAudioProcessingTapGetStorage(tap);
    MDSpectrumAnalysisContext *spContext = context->spContext;
    
    free(spContext->A.imagp);
    free(spContext->A.realp);
    free(spContext->hann_window);
    free(spContext->in_real);
    free(spContext->obtainedReal);
    free(spContext->spectrumArray);
    free(spContext->bucketPositionArray);
    free(spContext);
    context->spContext = NULL;
    
    // Clear MDAudioProcessingTap context.
    context->self = NULL;
    
    free(context);

}

static void tap_PrepareCallback(MTAudioProcessingTapRef tap, CMItemCount maxFrames, const AudioStreamBasicDescription *processingFormat)
{
    MDAudioTapProcessorContext *context = (MDAudioTapProcessorContext *)MTAudioProcessingTapGetStorage(tap);
    
    // Store sample rate
    context->sampleRate = processingFormat->mSampleRate;
    
  /*
    NSLog(@"frames per packet %u", (unsigned int)processingFormat->mFramesPerPacket);
    NSLog(@"bytes per frame %u", (unsigned int)processingFormat->mBytesPerFrame);
    NSLog(@"bytes per packet %u", (unsigned int)processingFormat->mBytesPerPacket);
    NSLog(@"bits per channel %u", (unsigned int)processingFormat->mBitsPerChannel);
    NSLog(@"sample rate %u", (unsigned int)processingFormat->mSampleRate);
    NSLog(@"bits per channel %u", (unsigned int)processingFormat->mFormatFlags);
    NSLog(@"max frames %ld", (long)maxFrames);
   */
    /* Verify processing format (this is not needed for Audio Unit, but for RMS calculation). */
    // NSLog(@"format flag %u", (unsigned int)processingFormat->mFormatFlags);
   //      NSLog(@"formatID %u", (unsigned int)processingFormat->mFormatID);
   //   NSLog(@"bits per channel %u", (unsigned int)processingFormat->mBitsPerChannel);
    
    context->supportedTapProcessingFormat = true;
    
    if (processingFormat->mFormatID != kAudioFormatLinearPCM)
    {
        NSLog(@"Unsupported audio format ID for audioProcessingTap. LinearPCM only.");
        context->supportedTapProcessingFormat = false;
    }
    
    if (!(processingFormat->mFormatFlags & kAudioFormatFlagIsFloat))
    {
        NSLog(@"Unsupported audio format flag for audioProcessingTap. Float only.");
        context->supportedTapProcessingFormat = false;
    }
    
    if (processingFormat->mFormatFlags & kAudioFormatFlagIsNonInterleaved)
    {
        context->isNonInterleaved = true;
    }
    
    //To avoid expensive alloc's during processing loop, we'll create a struct and initialize memory needed
    
    MDSpectrumAnalysisContext *spContext = context->spContext;
    spContext->maxFrames = maxFrames;
    spContext->spectrumArray = (float*)malloc(maxFrames/2/64 * sizeof(float));
    spContext->bucketPositionArray = (float*)malloc((maxFrames/2/64) * sizeof(float));
    spContext->obtainedReal = (float *) malloc(maxFrames * sizeof(float));
    spContext->in_real = (float *) malloc(maxFrames * sizeof(float));
    spContext->A.realp = (float *) malloc(maxFrames/2 * sizeof(float));
    spContext->A.imagp = (float *) malloc(maxFrames/2 * sizeof(float));
    memset(spContext->A.imagp, 0, maxFrames/2 * sizeof(float));
    memset(spContext->A.realp, 0, maxFrames/2 * sizeof(float));
    spContext->hann_window = (float *) malloc(maxFrames * sizeof(float));
    memset(spContext->hann_window, 0, maxFrames * sizeof(float));
    vDSP_hann_window(spContext->hann_window, maxFrames, vDSP_HANN_DENORM);
  
    // we'll populate the array referencing the frequency buckets we're interested in
    
    for (int i = 0 ; i < (sizeof(spectrumFrequenciesArray) / sizeof(float)); i++)
    {
        spContext->bucketPositionArray[i] = ceilf( spectrumFrequenciesArray[i] / (processingFormat->mSampleRate / maxFrames));
    }
    
    /* Create 10 band 1 octive (roughly) EQBand Audio Unit -interface to adjust frequency not implemented, all hooks are here. */
     AudioUnit audioUnit;
    
    AudioComponentDescription audioComponentDescription;
    audioComponentDescription.componentType = kAudioUnitType_Effect;
    audioComponentDescription.componentSubType = kAudioUnitSubType_NBandEQ;
    audioComponentDescription.componentManufacturer = kAudioUnitManufacturer_Apple;
    audioComponentDescription.componentFlags = 0;
    audioComponentDescription.componentFlagsMask = 0;
    
    AudioComponent audioComponent = AudioComponentFindNext(NULL, &audioComponentDescription);
    if (audioComponent){
        if (noErr == AudioComponentInstanceNew(audioComponent, &audioUnit))
        {
            OSStatus status = noErr;
            if (noErr == status)
            {
                status = AudioUnitSetProperty(audioUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, 0, processingFormat, sizeof(AudioStreamBasicDescription));
            }
            if (noErr == status)
            {
                status = AudioUnitSetProperty(audioUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, 0, processingFormat, sizeof(AudioStreamBasicDescription));
            }
            
            //setup bands/frequency for equalizer
            NSArray *eqFrequencies = @[ @32.0f, @64.0f, @125.0f, @250.0f, @500.0f,  @1000.0f, @2000.0f, @4000.0f, @8000.0f,  @16000.0f ];
            UInt32 numBands;
            numBands = (UInt32)eqFrequencies.count;
            
            if (noErr == status)
            {
                
                status = AudioUnitSetProperty(audioUnit,
                                              kAUNBandEQProperty_NumberOfBands,
                                              kAudioUnitScope_Global,
                                              0,
                                              &numBands,
                                              sizeof(numBands));
            }
            
            if (noErr == status)
            {
                for (UInt32 i=0; i<eqFrequencies.count; i++) {
                    status =   AudioUnitSetParameter(audioUnit,
                                                     kAUNBandEQParam_Frequency+i,
                                                     kAudioUnitScope_Global,
                                                     0,
                                                     (AudioUnitParameterValue)[[eqFrequencies objectAtIndex:i] floatValue],
                                                     0);
                    // setting the bypassBand paramter
                    if (noErr == status) {
                        
                    
                        status =      AudioUnitSetParameter(audioUnit,
                                                        kAUNBandEQParam_BypassBand+i,
                                                        kAudioUnitScope_Global,
                                                        0,
                                                        0,
                                                        0);
                    }
                }
            }
            // Set audio unit render callback.
            if (noErr == status)
            {
                AURenderCallbackStruct renderCallbackStruct;
                renderCallbackStruct.inputProc = AU_RenderCallback;
                renderCallbackStruct.inputProcRefCon = (void *)tap;
                status = AudioUnitSetProperty(audioUnit, kAudioUnitProperty_SetRenderCallback, kAudioUnitScope_Input, 0, &renderCallbackStruct, sizeof(AURenderCallbackStruct));
            }
            
            // Set audio unit maximum frames per slice to max frames.
            if (noErr == status)
            {
                CMItemCount maximumFramesPerSlice = maxFrames;
                status = AudioUnitSetProperty(audioUnit, kAudioUnitProperty_MaximumFramesPerSlice, kAudioUnitScope_Global, 0, &maximumFramesPerSlice, (UInt32)sizeof(UInt32));
            }
            
            // Initialize audio unit.
            if (noErr == status)
            {
                status = AudioUnitInitialize(audioUnit);
            }
            
            if (noErr != status)
            {
                AudioComponentInstanceDispose(audioUnit);
                audioUnit = NULL;
            }
            
            context->eqAudioUnit = audioUnit;
            
            
        }
    }
    
}

static void tap_UnprepareCallback(MTAudioProcessingTapRef tap)
{
    MDAudioTapProcessorContext *context = (MDAudioTapProcessorContext *)MTAudioProcessingTapGetStorage(tap);
    
    /* Release the Equalizer Audio Unit */
    if (context->eqAudioUnit)
    {
        AudioUnitUninitialize(context->eqAudioUnit);
        AudioComponentInstanceDispose(context->eqAudioUnit);
        context->eqAudioUnit = NULL;
    }
}

static void tap_ProcessCallback(MTAudioProcessingTapRef tap, CMItemCount numberFrames, MTAudioProcessingTapFlags flags, AudioBufferList *bufferListInOut, CMItemCount *numberFramesOut, MTAudioProcessingTapFlags *flagsOut)
{
    MDAudioTapProcessorContext *context = (MDAudioTapProcessorContext *)MTAudioProcessingTapGetStorage(tap);
    MDSpectrumAnalysisContext *spContext = context->spContext;
    
    //default to 4096 samples, if otherwise recalculate reference positions
    if(numberFrames != spContext->maxFrames){
        for (int i = 0 ; i < (sizeof(spectrumFrequenciesArray) / sizeof(float)); i++)
        {
            spContext->bucketPositionArray[i] = ceilf( spectrumFrequenciesArray[i] / (context->sampleRate / numberFrames));
        }
        spContext->maxFrames = numberFrames;
    }
    
    
    OSStatus status;

    // Skip processing when format not supported.
    if (!context->supportedTapProcessingFormat)
    {
         return;
    }
    
    MDAudioTapProcessor *self = ((__bridge MDAudioTapProcessor *)context->self);

    // Apply bandpass filter Audio Unit.

        AudioUnit audioUnit = context->eqAudioUnit;
        if (audioUnit)
        {
            AudioTimeStamp audioTimeStamp;
            audioTimeStamp.mSampleTime = context->sampleCount;
            audioTimeStamp.mFlags = kAudioTimeStampSampleTimeValid;
            
            status = AudioUnitRender(audioUnit, 0, &audioTimeStamp, 0, (UInt32)numberFrames, bufferListInOut);
            if (noErr != status)
            {
                NSLog(@"AudioUnitRender(): %d", (int)status);
                return;
            }
            // Increment sample count for audio unit.
            context->sampleCount += numberFrames;
            
            // Set number of frames out.
            *numberFramesOut = numberFrames;

        }

    //Spectrum analyzer code
    // if the spectrum frame is being displayed and app not in background, generate data
    if (self.isSpectrumEnabled && self.isActiveAppState)
    {

        //ref to allocated memory
        CMItemCount maxSamples = numberFrames ;
        float scale =  (1.0/(20*maxSamples));
        UInt32 log2n = log2f(maxSamples);
        UInt32 n = 1 << log2n;
        UInt32 nOver2 = n/2;

        DSPSplitComplex   A = spContext->A;
        
        //apply hann window to raw data -
        vDSP_vmul(bufferListInOut->mBuffers[0].mData, 1,spContext->hann_window, 1, spContext->in_real, 1, maxSamples);
 
        //copy interleved to split complex
        vDSP_ctoz((COMPLEX*)spContext->in_real, 2, &A, 1, nOver2);
        
        // Compute FFT
        vDSP_fft_zrip(fftSetup, &A, 1, log2n, kFFTDirection_Forward);
        
        // apply scaling
        vDSP_vsmul(A.realp, 1, &scale, A.realp, 1, nOver2);
        vDSP_vsmul(A.imagp, 1, &scale, A.imagp, 1, nOver2);
        
        //square magnituded of obtained values
        vDSP_zvmags(&A, 1, spContext->obtainedReal, 1, nOver2);
        
        //add a small adjustment to prevent taking 0 of niquist
        vDSP_vsadd(spContext->obtainedReal, 1, &kAdjust0DB, spContext->obtainedReal, 1, nOver2);
        
        //convert to db Scale
        Float32 one = 1;
        vDSP_vdbcon(spContext->obtainedReal, 1, &one, spContext->obtainedReal, 1, nOver2, 0);
     

        //extract samples

        UInt32 passcount = (sizeof(spContext->bucketPositionArray) * sizeof(float));
        context->numberOfBuckets = passcount;
        
        float maxSupportedFrequency = ((context->sampleRate / numberFrames) * nOver2);
        UInt32 stopPoint = 0;
        
        for (UInt32 i = passcount - 1; i > 0; i--) {
            if (spectrumFrequenciesArray[i] < maxSupportedFrequency) {
                stopPoint = i + 1;
                break;
            }
        }
        context->numberOfBuckets = stopPoint;
        
        for (UInt32 i = 0; i < stopPoint; i++ ) {
            
            UInt32 st = spContext->bucketPositionArray[i];
            float sum = spContext->obtainedReal[st];
            spContext->spectrumArray[i] =    sum;
        }
 
        NSMutableArray *freqArray = [NSMutableArray new];
        for (UInt32 i = 0; i < passcount; i++) {
            [freqArray insertObject:[NSNumber numberWithFloat:spContext->spectrumArray[i]] atIndex:i ];
        }
        
        // Pass frequency
        [self updateSpectrumAnalysisResults:freqArray bucketCount:context->numberOfBuckets];
         
    }
    else
    {
        // Get actual audio buffers from MTAudioProcessingTap (AudioUnitRender() will fill bufferListInOut otherwise).
        status = MTAudioProcessingTapGetSourceAudio(tap, numberFrames, bufferListInOut, flagsOut, NULL, numberFramesOut);
        if (noErr != status)
        {
            NSLog(@"MTAudioProcessingTapGetSourceAudio: %d", (int)status);
            return;
        }

    }
 

}



#pragma mark - Audio Unit Callbacks

OSStatus AU_RenderCallback(void *inRefCon, AudioUnitRenderActionFlags *ioActionFlags, const AudioTimeStamp *inTimeStamp, UInt32 inBusNumber, UInt32 inNumberFrames, AudioBufferList *ioData)
{
    // Just return audio buffers from MTAudioProcessingTap.
    return MTAudioProcessingTapGetSourceAudio(inRefCon, inNumberFrames, ioData, NULL, NULL, NULL);
}
