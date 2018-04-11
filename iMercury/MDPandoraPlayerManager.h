//
//  MDPandoraPlayerManager.h
//  iMercury
//
//  Created by Marino di Barbora on 2/3/16.
//  Copyright © 2016 Marino di Barbora. All rights reserved.
//


#import "MDPandoraInterface.h"

@import AVFoundation;

@protocol playerManagerProtocolDelegate;

@interface MDPandoraPlayerManager : NSObject

@property (nonatomic) MDPandoraInterface * _Nonnull pandoraInterface;

@property (weak, nonatomic)  _Nullable id <playerManagerProtocolDelegate> playerDelegate;
@property (assign, nonatomic, readonly) BOOL isPlaying;
@property (assign, nonatomic, readonly) BOOL spectrumDataNeeded;
@property (nonatomic, readonly) MDStation * _Nullable currentStation;
@property (nonatomic,readonly) NSMutableArray  * _Nonnull stationList;


+ (instancetype _Nullable)client;

- (void)authenticateUser:(NSString *_Nullable) userName password:(NSString * _Nullable)password success:(nullable void (^)(BOOL * _Nullable success))success failure:(nullable void (^)(NSError  * _Nullable error))failure ;
- (void)loadStationListAtFirstLaunch;
- (void)playNextSong;
- (void)playOrStop;
- (void)rewindTrack;
- (void)setShouldRepeatSong: (BOOL) isRepeating;
- (MDSong * _Nullable)retrieveCurrentSong;
- (void)setVolume:(float)toVolumeLevel;
- (void)setBandGainValue:(Float32) gain forBand:(Float32) eqBand;
- (float)getCurrentVolumeLevel;
- (void)setPlayingNowInfo;
- (void)addFeedbackForCurrentSong: (BOOL)isPositive;
- (void)receiveSpectrumData:(BOOL)shouldReceiveSpectrumData;
- (void)activeAppState:(BOOL) activeState;
- (void)searchForSongOrArtist:(NSString * _Nonnull)searchString results:(nonnull void (^)(id _Nullable responseObject))results;
- (void)createStationFromSearchResult:(MDSearchResult * _Nonnull)searchResult success:(nullable void (^)(BOOL * _Nullable success))success failure:(nullable void (^)(NSError  * _Nullable error))failure ;
- (void)deleteStationforStation:(MDStation * _Nonnull)stationToDelete success:(nullable void (^)(BOOL * _Nullable success))success;
- (void)deleteSeedSongOrArtist:(MDSeedBase * _Nonnull)seedToDelete forStation:(MDStation *_Nonnull )seedForStation success:(nullable void (^)(BOOL * _Nullable success))success;
- (void)startListeningToStation:(MDStation * _Nonnull)stationToListenTo;
- (void)addSeedFromSearchResults:(MDSearchResult * _Nonnull)searchResult forStation:(MDStation * _Nonnull)station success:(nullable void (^)(BOOL * _Nullable success))success failure:(nullable void (^)(NSError  * _Nullable error))failure ;
@end

@protocol playerManagerProtocolDelegate <NSObject>
- (void)playTimerUpdate:(CMTime)time currentSeektime:(double)currentSeekTime songDuration:(double)currentSongDuration;
- (void)processingSpectrumData: (NSArray* _Nonnull)spectrumDataArray numberOfElementsInArray:(UInt32)numberOfElementsInArray;

@end
