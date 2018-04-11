//
//  MDAudioTapProcessor.h
//  iMercury
//
//  Created by Marino di Barbora on 2/8/16.
//  Copyright © 2016 Marino di Barbora. All rights reserved.
//



#import <AudioToolbox/AudioToolbox.h>

@class AVAudioMix;
@class AVAssetTrack;

@protocol MDAudioTapProcessorDelegate;

@interface MDAudioTapProcessor : NSObject




@property (readonly, nonatomic) AVAudioMix *audioMix;
@property (nonatomic, assign) BOOL isSpectrumEnabled;
@property (nonatomic, assign) BOOL isActiveAppState;
@property (weak, nonatomic) id <MDAudioTapProcessorDelegate> __weak delegate;

- (id)initWithAudioAssetTrack:(AVAssetTrack *)audioAssetTrack;

// EQ Param methods

- (AudioUnitParameterValue)gainForBandAtPosition:(Float32)bandPosition;
- (void)setGain:(AudioUnitParameterValue)gain forBandAtPosition:(Float32)bandPosition;

// Spectrum analyzer methods
- (void)updateSpectrumAnalysisResults:(NSMutableArray*)frequencyBucket bucketCount:(UInt32)buckets;
@end

@protocol MDAudioTapProcessorDelegate <NSObject>


- (void)audioTapProcessor:(MDAudioTapProcessor *)audioTapProcessor hasNewFrequencybucketArray:(NSMutableArray*)frequencyBucket numberOfBuckets:(UInt32)buckets;

@end
