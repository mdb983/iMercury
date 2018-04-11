//
//  MDPandoraPlayerManager.m
//  iMercury
//
//  Created by Marino di Barbora on 2/3/16.
//  Copyright © 2016 Marino di Barbora. All rights reserved.
//

#import "MDPandoraPlayerManager.h"
#import "MDPandoraInterface.h"
#import "MDAudioTapProcessor.h"
#import "MDConstants.h"
#import "MDStation.h"
#import "MDSong.h"
#import "MDFeedback.h"
#import "MDSearchResult.h"
#import "MDSeedSong.h"
#import "MDSeedArtist.h"
#import "AFImageDownloader.h"


@import MediaPlayer;
@import AVFoundation;

@interface MDPandoraPlayerManager () <MDAudioTapProcessorDelegate>

@property (nonatomic) MDAudioTapProcessor *audioTapProcessor;
@property (nonatomic) id playTimeObserver;

@property (nonatomic) AVPlayer *mainPlayer;
@property (nonatomic) dispatch_queue_t backgroundProcessQueue;
@property (nonatomic,readwrite) NSMutableArray *stationList;
@property (nonatomic) MDStation *currentStation;

@property (assign, nonatomic, readwrite) BOOL isPlaying;
@property (assign, nonatomic) BOOL isSongLoaded;
@property (nonatomic, assign) BOOL didChangeStation;
@property (nonatomic, assign) BOOL repeatSong;
@property (assign, nonatomic, readwrite) BOOL spectrumDataNeeded;
@property (nonatomic) NSNumber *listeningTimeOut;


@end

@implementation MDPandoraPlayerManager


NSInteger PlayerItemContext = 0;

#pragma mark - Lifecycle
+ (instancetype)client
{
    static MDPandoraPlayerManager * requests = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        requests = [[MDPandoraPlayerManager alloc] init];
    });
    return requests;
}

- (instancetype)init{
    self = [super init];
    if (self)
    {
        _mainPlayer = [[AVPlayer alloc]init];
        _backgroundProcessQueue = dispatch_queue_create(kMDBackgroundQueue, NULL);
        _isPlaying = NO;
        _isSongLoaded = NO;
        _stationList = [NSMutableArray array];
        _spectrumDataNeeded = NO;
        _didChangeStation = NO;
        _repeatSong = NO;
    }
    return self;
}

- (void)dealloc{
    if (self.playTimeObserver) {
        [self.mainPlayer removeTimeObserver:self.playTimeObserver];
    }
}

- (MDPandoraInterface*)pandoraInterface{
    if (!_pandoraInterface) {
        _pandoraInterface = [[MDPandoraInterface alloc]initWithBaseURL:nil];
    }
    return _pandoraInterface;
}

- (void)activeAppState:(BOOL) activeState{
    if (self.audioTapProcessor) {
        self.audioTapProcessor.isActiveAppState = activeState;
    }
    
}
#pragma mark - pandora requests
#pragma mark - Authenticate
- (void)authenticateUser:(NSString *)userName password:(NSString *)password success:(nullable void (^)(BOOL * _Nullable))success failure:(nullable void (^)(NSError * _Nullable))failure {
     [self.pandoraInterface startUserAuthentication:userName password:password success:^(id  _Nonnull responseObject) {
        
        NSDictionary *res = [responseObject objectForKey:@"result"];
        self.listeningTimeOut =  [NSNumber numberWithInteger: [[res valueForKey:@"listeningTimeoutMinutes"]integerValue]];
        BOOL didSucceed = YES;
        success(&didSucceed);
    } authenticationFailure:^(NSError * _Nullable error) {
        failure(error);
    }];
}

#pragma mark - Stations

- (void)startListeningToStation:(MDStation * _Nonnull)stationToListenTo{
    if (![self.currentStation.stationId isEqualToString:stationToListenTo.stationId]) {
  
        self.didChangeStation = YES;
        self.currentStation = stationToListenTo;
        [[NSUserDefaults standardUserDefaults]setValue:stationToListenTo.stationToken forKey:@"currentStation"];
        [[NSUserDefaults standardUserDefaults]synchronize];
  
        if ([[self.currentStation songs] count] < 3) {
            [self loadSongsForCurrentStation];
            [self loadCurrentStationExtendedData];
        }else{
            [self playNextTrack];
        }
    }
}

- (void)loadStationListAtFirstLaunch{
    [self.pandoraInterface retrieveStationList:^(id  _Nonnull responseObject) {
      
        NSDictionary *res = [responseObject objectForKey:@"result"];
        [self.stationList removeAllObjects];
        for (NSDictionary *s in res[@"stations"]){
            
            MDStation *station = [[MDStation alloc]initWithParams:s];
            
            if (![station.stationName isEqualToString:@"QuickMix"]) {
                [self loadExtendedDataForStation:station];
                [self.stationList addObject:station];
            }
        }
        [self setupDefaultStation];
    } stationLoadFailure:^(NSError * _Nullable error) {
        NSLog(@"Station List Error with Error Code %@", error);
        
        //action on failure required
    }];
}


- (void)createStationFromSearchResult:(MDSearchResult * _Nonnull)searchResult success:(nullable void (^)(BOOL * _Nullable success))success failure:(nullable void (^)(NSError  * _Nullable error))failure {
    
    [self.pandoraInterface createStationFromSearchResult:searchResult success:^(id  _Nonnull responseObject) {
        NSDictionary *res = [responseObject objectForKey:@"result"];
        MDStation *s = [[MDStation alloc]initWithParams:res];
        [self loadExtendedDataForStation:s];
        [self.stationList addObject:s];
        BOOL didSucceed = YES;
        success(&didSucceed);
    } createStationFailure:^(NSError * _Nullable error) {
        failure(error);
    }];
}



- (void)deleteStationforStation:(MDStation * _Nonnull)stationToDelete success:(nullable void (^)(BOOL * _Nullable success))success{
     BOOL canGo = NO;
    // check for current station is being deleted and select another if possible
    MDStation *replacementSation = nil;
    if ([stationToDelete.stationId isEqualToString:self.currentStation.stationId]  && [self.stationList count] > 1) {
        for (NSUInteger  i = 0; i < [self.stationList count] ; i++) {
            replacementSation = [self.stationList objectAtIndex:i];
            if (![replacementSation.stationId isEqualToString:stationToDelete.stationId]) {
                [self startListeningToStation:replacementSation];
                break;
            }
        }
    }else if ([self.stationList count] == 1){
        // only one station
        success(&canGo);
        return;
    }
    [self.stationList removeObjectIdenticalTo:stationToDelete];
    [self.pandoraInterface deleteStationForStation:stationToDelete];
    canGo = YES;
    success(&canGo);
}

- (void)deleteSeedSongOrArtist:(MDSeedBase * _Nonnull)seedToDelete forStation:(MDStation *_Nonnull )seedForStation success:(nullable void (^)(BOOL * _Nullable success))succeeded{
    [self.pandoraInterface deleteSeedForSeedId:seedToDelete success:^(BOOL success) {
        if (success) {
            
            for (MDStation *s in self.stationList) {
                if(s == seedForStation){
                    if([seedToDelete isKindOfClass:MDSeedSong.class]){
                        [s deleteSeedSong:(MDSeedSong*)seedToDelete];
                    }
                    if([seedToDelete isKindOfClass:MDSeedArtist.class]){
                        [s deleteSeedArtist:(MDSeedArtist*)seedToDelete];
                    }
                }
            }
            
        }
        succeeded(&success);
    }];
}


- (void)addSeedFromSearchResults:(MDSearchResult * _Nonnull)searchResult forStation:(MDStation * _Nonnull)station success:(nullable void (^)(BOOL * _Nullable success))success failure:(nullable void (^)(NSError  * _Nullable error))failure {
    
    [self.pandoraInterface createSeedFromSearchResult:searchResult forStation:station success:^(id  _Nonnull responseObject) {
        NSDictionary *res = [responseObject objectForKey:@"result"];
        // will return song or artist
        NSString *songName = [res valueForKey:@"songName"];
        if (songName) {
            MDSeedSong *seedSong = [[MDSeedSong alloc]initWithParams:res];
            [station addSeedSong:seedSong];
        }else{
            MDSeedArtist *seedArtist = [[MDSeedArtist alloc]initWithParams:res];
            [station addSeedArtist:seedArtist];
        }
        BOOL succesfull = YES;
        success(&succesfull);
        
    } createSeedFailure:^(NSError * _Nullable error) {
        failure(error);
    }];
}


- (void)setupDefaultStation{
    NSString *savedCurrentStation = [[NSUserDefaults standardUserDefaults] valueForKey:@"currentStation"];
    if (savedCurrentStation != nil) {
        for (MDStation *s in self.stationList) {
            if ([s.stationToken isEqualToString:savedCurrentStation]) {
                self.currentStation = s;
                if ([[self.currentStation songs] count] < 3) {
                    [self loadSongsForCurrentStation];
                }
            }
        }
    }else{
        if (self.stationList) {
            self.currentStation = [self.stationList objectAtIndex:0];
            [[NSUserDefaults standardUserDefaults]setValue:self.currentStation.stationToken forKey:@"currentStation"];
            [[NSUserDefaults standardUserDefaults]synchronize];
            if ([[self.currentStation songs] count] < 3) {
                [self loadSongsForCurrentStation];
            }
        }
    }
}

- (void)loadCurrentStationExtendedData{
    [self loadExtendedDataForStation:self.currentStation];
}

- (void)loadExtendedDataForStation:(MDStation*)station{
    [[self pandoraInterface]loadExtendedDetailsForStation:station success:^(id  _Nonnull responseObject) {
        NSDictionary  *res = [responseObject objectForKey:@"result"];
        [station addExtendedData:res];
    } stationExtendedDetailsFailure:^(NSError * _Nullable error) {
        NSLog(@"Station List Error with Error Code %@", error);
        
    }];

}


#pragma mark - Songs
- (void)loadSongsForCurrentStation{
    [[self pandoraInterface]loadSongsForStation:self.currentStation success:^(id  _Nonnull responseObject) {
        NSDictionary *res = [responseObject objectForKey:@"result"];
        for (NSDictionary *d in res[@"items"]) {
            if (d[@"adToken"] == nil) {
                MDSong *newSong = [[MDSong alloc]initWithParams:d];
                [self.currentStation addSong:newSong];
            }
        }
       
        if (!self.isSongLoaded) {

               [self readyPlayerWithFirstSong];
        }
        if (self.didChangeStation) {
            self.didChangeStation = NO;
            [self playNextTrack];
        }
    } stationSongLoadFailure:^(NSError * _Nullable error) {
        NSLog(@"Station List Error with Error Code %@", error);
        // action on failure
    }];
}

- (void)addFeedbackForCurrentSong: (BOOL)isPositive{
    MDSong *s = [self.currentStation.history objectAtIndex:([self.currentStation.history count ] -1)];
    [s songRatingValue:[NSNumber numberWithBool:isPositive]]  ;
    [[self pandoraInterface]addFeedbackForCurrentSong:s isPositive:isPositive forStation:[self currentStation] success:^(id  _Nonnull responseObject) {
       //stub for future possible requirements ... at this point we set the rating manualy above.
        NSDictionary __unused *res = [responseObject valueForKey:@"result"];
        
    } stationSongLoadFailure:^(NSError * _Nullable error) {
        NSLog(@"Error adding feedback Error Code %@", error);
    }];
}

#pragma mark - search

- (void)searchForSongOrArtist:(NSString *)searchString results:(nonnull void (^)(id _Nullable responseObject))results{
   
    [[self pandoraInterface]searchForSongOrArtist:searchString success:results searchFailure:^(NSError * _Nullable error) {
        //if we have an error, simply return nothing - cant find the details?
        results(nil);
    }];
  
    
}

#pragma mark - Player
- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary<NSString *,id> *)change
                       context:(void *)context {
    // Only handle observations for the PlayerItemContext
    
    NSError *playerItemError;
    
    if (context != &PlayerItemContext) {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
        return;
    }
    
    if ([keyPath isEqualToString:@"status"]) {
        AVPlayerItemStatus status = AVPlayerItemStatusUnknown;
        // Get the status change from the change dictionary
        NSNumber *statusNumber = change[NSKeyValueChangeNewKey];
        if ([statusNumber isKindOfClass:[NSNumber class]]) {
            status = statusNumber.integerValue;
        }
        

        // Switch over the status
        switch (status) {
            case AVPlayerItemStatusReadyToPlay:
                // Ready to Play
                [self addAudioTapProcess];
                break;
            case AVPlayerItemStatusFailed:
                // Failed. Examine AVPlayerItem.error
                // Add a
                playerItemError  = self.mainPlayer.currentItem.error;
                NSLog(@"Failed to Load Song with Error %@", playerItemError);

              
                break;
            case AVPlayerItemStatusUnknown:
                // Not ready
                // This gets called at various points in the loading pipeline, Ignorance is bliss
                break;
        }
    }
}


-(void)addAudioTapProcess{
    if (!self.audioTapProcessor) {
        AVAssetTrack *firstTrack = [self findFirstAssetTrack:self.mainPlayer.currentItem.asset.tracks];
        if(firstTrack)
        {
            self.audioTapProcessor = [[MDAudioTapProcessor alloc]initWithAudioAssetTrack:firstTrack];
            self.audioTapProcessor.delegate = self;
        }
    }
    AVAudioMix *audioMix = self.audioTapProcessor.audioMix;
    if (audioMix)
    {
        self.mainPlayer.currentItem.audioMix = audioMix;
    }
}


-(void)readyPlayerWithFirstSong{
    MDSong *song = [self.currentStation getFirstSong];
    NSURL *playURL = [[NSURL alloc] initWithString:[song nextPlayURL]];
  
    AVPlayerItem *playerItem = [AVPlayerItem playerItemWithURL:playURL];
   
    NSKeyValueObservingOptions options =
    NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew;
    
    // Register as an observer of the player item's status property
    [playerItem addObserver:self
                 forKeyPath:@"status"
                    options:options
                    context:&PlayerItemContext];
     
    [self.mainPlayer replaceCurrentItemWithPlayerItem:playerItem];

    self.isPlaying = NO;
    self.isSongLoaded = YES;
  
   [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(itemDidFinishPlaying:) name:AVPlayerItemDidPlayToEndTimeNotification object:playerItem];
    
    [self setupPlayTimeObserver];
    [[NSNotificationCenter defaultCenter] postNotificationName:kMDReadyWithfirstSongNotification object:nil userInfo:nil];
     [self setPlayingNowInfo];
  
}

- (void)itemDidFinishPlaying:(NSNotification*) notificationInfo{
    if (self.repeatSong) {
        [self rewindTrack];
        [self.mainPlayer play];
    }else{
    [self.mainPlayer pause];
    [self playNextTrack];
    }
}

- (void)playNextTrack{
   
    MDSong *song = [self.currentStation getNextSong];
    NSURL *playURL = [[NSURL alloc] initWithString:[song nextPlayURL]];
    if ([self.currentStation.songs count] < 2) {
        dispatch_async(self.backgroundProcessQueue, ^{
            [self loadSongsForCurrentStation];
        });
    }
    
    if (self.mainPlayer.currentItem.audioMix) {
        self.mainPlayer.currentItem.audioMix = nil;
    }
    
    AVPlayerItem *oldItem = self.mainPlayer.currentItem;
    [[NSNotificationCenter defaultCenter]removeObserver:oldItem];
    [[NSNotificationCenter defaultCenter]removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
    
    AVPlayerItem *nextItem = [[AVPlayerItem alloc]initWithURL:playURL];
    
    AVAudioMix *audioMix = self.audioTapProcessor.audioMix;
    if (audioMix) {
        nextItem.audioMix = audioMix;
    }
    
    [self.mainPlayer replaceCurrentItemWithPlayerItem:nextItem];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(itemDidFinishPlaying:) name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
    [[NSNotificationCenter defaultCenter]postNotificationName:kMDTrackChangeNotification object:self];
    if (self.isPlaying) {
        [self.mainPlayer play];
    }
   
    UIApplicationState state = [[UIApplication sharedApplication] applicationState];
    if (state == UIApplicationStateBackground || state == UIApplicationStateInactive)
    {
        [self setPlayingNowInfo];
    }
}

#pragma mark - Helper
- (AVAssetTrack*)findFirstAssetTrack: (NSArray*) firstTrackAssets{
         AVAssetTrack *returnAssetTrack ;
         for (AVAssetTrack *assetTrack in firstTrackAssets)
         {
             if ([assetTrack.mediaType isEqualToString:AVMediaTypeAudio])
             {
                 returnAssetTrack = assetTrack;
                 break;
             }
         }
         return returnAssetTrack;
}

- (void)setupPlayTimeObserver{
    if (!self.playTimeObserver) {
        double calbackTimeInterval = 1.0f;
        __block AVPlayer __weak *weakPlayer = self.mainPlayer;
        __block id <playerManagerProtocolDelegate>  __weak weakDelegate = _playerDelegate;
        self.playTimeObserver   = [self.mainPlayer addPeriodicTimeObserverForInterval:CMTimeMakeWithSeconds(calbackTimeInterval, NSEC_PER_SEC) queue: dispatch_get_main_queue() usingBlock:^(CMTime time) {
            if(weakDelegate)
            {
              double currentPlayerSeekTime = 0.0;
              double songDuration = 0.0;
              AVPlayerItem *currentPlayerItem = [weakPlayer currentItem];
                if (currentPlayerItem) {
                    currentPlayerSeekTime = CMTimeGetSeconds([currentPlayerItem currentTime]);
                    songDuration = CMTimeGetSeconds(currentPlayerItem.duration);
                }
              [weakDelegate playTimerUpdate:time currentSeektime:currentPlayerSeekTime songDuration:songDuration];
            }
        }];
    }
}


- (MDSong * )retrieveCurrentSong{
    return [self.currentStation currentSong];
}

- (void)setPlayingNowInfo{
    MDSong *currentSong = self.currentStation.currentSong;
    NSNumber *currentSongDuration = [NSNumber numberWithDouble:CMTimeGetSeconds(self.mainPlayer.currentItem.duration)];
    NSNumber *playBackRate = [NSNumber numberWithFloat:1.0f];
    CMTime currentPlayTime = self.mainPlayer.currentTime;
    NSNumber *currentPlayPosition = [NSNumber numberWithDouble:0.0f];
    if (CMTIME_IS_NUMERIC(currentPlayTime)) {
        currentPlayPosition = [NSNumber numberWithDouble:CMTimeGetSeconds(currentPlayTime) ];
        
    }
    
    [MPNowPlayingInfoCenter defaultCenter].nowPlayingInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                                                             currentSong.songTitle, MPMediaItemPropertyTitle,
                                                             currentSong.artistName, MPMediaItemPropertyArtist,
                                                             currentSong.mediaAlbumArtwork, MPMediaItemPropertyArtwork,
                                                             playBackRate, MPNowPlayingInfoPropertyPlaybackRate,
                                                             currentSongDuration, MPMediaItemPropertyPlaybackDuration,
                                                             currentPlayPosition, MPNowPlayingInfoPropertyElapsedPlaybackTime,
                                                             0.0f, MPNowPlayingInfoPropertyPlaybackProgress,
                                                             nil];
}

#pragma mark - player controls
- (void)rewindTrack{
    AVPlayerItem *currentItem = self.mainPlayer.currentItem;
    [currentItem seekToTime:kCMTimeZero completionHandler:^(BOOL finished) {
        // update play now as time will not reset on lock screen
        dispatch_async(dispatch_get_main_queue(), ^{
              [self setPlayingNowInfo];
        });
    }];
}

- (void)setShouldRepeatSong: (BOOL) isRepeating{
    self.repeatSong = isRepeating;
}

- (void)playOrStop{
    if (self.isPlaying) {
        [self.mainPlayer pause];
        self.isPlaying = NO;
    }else{
        [self.mainPlayer play];
        self.isPlaying = YES;
    }
}

- (void)playNextSong{
    [self.mainPlayer pause];
    [self playNextTrack];
}

- (void) setVolume:(float)toVolumeLevel{
    self.mainPlayer.volume = toVolumeLevel;
}

- (float) getCurrentVolumeLevel{
    return self.mainPlayer.volume;
}

#pragma mark - MDAudioTapProcessorDelegate callbacks
- (void)audioTapProcessor:(MDAudioTapProcessor *)audioTapProcessor hasNewFrequencybucketArray:(NSMutableArray*)frequencyBucket numberOfBuckets:(UInt32)buckets{
    
   [self.playerDelegate processingSpectrumData: frequencyBucket numberOfElementsInArray:buckets];
    
}

- (void)receiveSpectrumData:(BOOL)shouldReceiveSpectrumData{
    self.audioTapProcessor.isSpectrumEnabled = shouldReceiveSpectrumData;
    self.spectrumDataNeeded = shouldReceiveSpectrumData;
}

- (void)setBandGainValue:(Float32) gain forBand:(Float32) eqBand{
    [self.audioTapProcessor setGain:gain  forBandAtPosition:eqBand];
}
@end
