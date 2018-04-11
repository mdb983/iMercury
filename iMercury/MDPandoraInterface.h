//
//  MDPandoraInterface.h
//  iMercury
//
//  Created by Marino di Barbora on 2/3/16.
//  Copyright © 2016 Marino di Barbora. All rights reserved.
//

#import "AFNetworking.h"
@class MDSong;
@class MDStation;
@class MDFeedback;
@class MDSearchResult;
@class MDSeedBase;



@interface MDPandoraInterface  : NSObject

- (instancetype _Nullable)initWithBaseURL:(NSURL * _Nullable)url;


- (void)startUserAuthentication:(NSString * _Nullable)userName password:(NSString * _Nullable)password success:(nullable void (^)(id _Nullable responseObject))success authenticationFailure:(nullable void (^)(NSError  * _Nullable error))authenticationFailure;

- (void)retrieveStationList: (nonnull void (^)(id _Nonnull responseObject))success stationLoadFailure:(nullable void (^)(NSError  * _Nullable error))stationLoadFailure;

- (void)loadExtendedDetailsForStation:(MDStation * _Nonnull) station success:(nonnull void (^)(id _Nonnull responseObject))success stationExtendedDetailsFailure:(nullable void (^)(NSError  * _Nullable error))stationExtendedDetailsFailure;

- (void)loadSongsForStation:(MDStation * _Nonnull)station success:(nonnull void (^)(id _Nonnull responseObject)) success stationSongLoadFailure:(nullable void (^)(NSError  * _Nullable error))stationSongLoadFailure;

- (void)addFeedbackForCurrentSong:(MDSong * _Nonnull)song isPositive:(BOOL)positive forStation:(MDStation * _Nonnull) station success:(nonnull void (^)(id _Nonnull responseObject))success stationSongLoadFailure:(nullable void (^)(NSError  * _Nullable error))feedbackAdditionError;

- (void)searchForSongOrArtist:(NSString * _Nonnull)searchString success:(nonnull void (^)(id _Nonnull responseObject))success searchFailure:(nullable void (^)(NSError  * _Nullable error))feedbackAdditionError;

- (void)createStationFromSearchResult:(MDSearchResult * _Nonnull)searchResult success:(nonnull void (^)(id _Nonnull responseObject))success createStationFailure:(nullable void (^)(NSError  * _Nullable error))createStationError;

- (void)createSeedFromSearchResult:(MDSearchResult * _Nonnull)searchResult forStation:(MDStation * _Nonnull)station success:(nonnull void (^)(id _Nonnull responseObject))success createSeedFailure:(nullable void (^)(NSError  * _Nullable error))createSeedError;

- (void) deleteStationForStation:(MDStation * _Nonnull) stationToDelete;

- (void) deleteSeedForSeedId:(MDSeedBase *_Nonnull) seedId success:(nonnull void(^)(BOOL success))success;

@end
