//
//  MDStation.h
//  iMercury
//
//  Created by Marino di Barbora on 2/8/16.
//  Copyright © 2016 Marino di Barbora. All rights reserved.
//

@class MDSong;
@class MDFeedback;
@class MDSeedSong;
@class MDSeedArtist;

@interface MDStation : NSObject
- (instancetype)initWithParams:(NSDictionary*) stationDetails;

@property (nonatomic, readonly) NSString *stationName;
@property (nonatomic, readonly) NSString *stationArtUrl;
@property (nonatomic, readonly) UIImage  *stationImage;
@property (nonatomic, readonly) NSString *stationDetailUrl;
@property (nonatomic, readonly) NSMutableArray *songs;
@property (nonatomic, readonly) NSString *stationToken;
@property (nonatomic, readonly) NSString *stationId;
@property (nonatomic, readonly) NSMutableArray *history;
@property (nonatomic, readonly) MDSong *currentSong;

- (void)addSong:(MDSong*) song;
- (MDSong*)getFirstSong;
- (MDSong*)getNextSong;
- (void)addExtendedData: (NSDictionary*) extendedStationData;
- (MDFeedback*)feedbackForsong:(NSString*) song withArtist:(NSString*) artist;
- (NSMutableArray*)getHistory;
- (NSArray*)getSeedSongs;
- (NSArray*)getSeedArtists;
- (NSUInteger)getSeedCount;
- (void) addSeedSong:(MDSeedSong*)song ;
- (void) addSeedArtist:(MDSeedArtist*)artist ;
- (void) deleteSeedArtist:(MDSeedArtist*)seedArtistToDelete ;
- (void) deleteSeedSong:(MDSeedSong*)seedSongToDelete;

@end
