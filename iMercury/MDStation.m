//
//  MDStation.m
//  iMercury
//
//  Created by Marino di Barbora on 2/8/16.
//  Copyright © 2016 Marino di Barbora. All rights reserved.
//

#import "AFImageDownloader.h"
#import "MDStation.h"
#import "MDSong.h"
#import "MDFeedback.h"
#import "MDSeedSong.h"
#import "MDSeedArtist.h"


@interface MDStation ()
@property (nonatomic, readwrite) NSString *stationName;
@property (nonatomic, readwrite) NSString *stationToken;
@property (nonatomic) NSArray * stationGenre;
@property (nonatomic, readwrite) NSString *stationId;
@property (nonatomic, readwrite) NSString *stationDetailUrl;
@property (assign, nonatomic) NSUInteger created;
@property (nonatomic, readwrite) NSString *stationArtUrl;
@property (nonatomic, readwrite) UIImage  *stationImage;
@property (nonatomic, readwrite) NSMutableArray *songs;
@property (nonatomic, readwrite) NSMutableArray *history;
@property (nonatomic, readwrite) MDSong *currentSong;
@property (nonatomic) NSNumber *allowRename;
@property (nonatomic) NSNumber *allowDelete;
@property (nonatomic) NSNumber *allowAddMusic;
@property (nonatomic) NSMutableArray *seedSongs;
@property (nonatomic) NSMutableArray *seedArtist;
@property (nonatomic) NSMutableArray *thumbs;
@end

@implementation MDStation


#pragma mark - Lifecycle
- (instancetype)initWithParams:(NSDictionary*) stationDetails{
    self = [super init];
    if (self) {
        _stationName = [stationDetails valueForKey:@"stationName"];
        _stationToken = [stationDetails valueForKey:@"stationToken"];
        _stationId = [stationDetails valueForKey:@"stationId"];
        _stationDetailUrl = [stationDetails valueForKey:@"stationDetailUrl"];
        _stationArtUrl = [stationDetails valueForKey:@"artUrl"];
        _stationGenre = [stationDetails valueForKey:@"genre"];
        _allowAddMusic = [NSNumber numberWithBool:[[stationDetails valueForKey:@"allowAddMusic"]boolValue]];
        _allowDelete = [NSNumber numberWithBool:[[stationDetails valueForKey:@"allowDelete"] boolValue]];
        _allowRename = [NSNumber numberWithBool:[[stationDetails valueForKey:@"allowRename"]boolValue]];
        _created = [[stationDetails[@"dateCreated"] valueForKey:@"time" ] integerValue];
        _songs = [NSMutableArray new];
        _history = [NSMutableArray new];
        _thumbs = [NSMutableArray new];
        _seedArtist = [NSMutableArray new];
        _seedSongs = [NSMutableArray new];
    }
    [self downloadImageArtwork ];
    return self;
}


#pragma mark - Getters

- (MDSong*)getFirstSong{
    if (self.songs.count > 0) {
        MDSong *songToPlay = [self.songs objectAtIndex:0];
        self.currentSong = songToPlay;
        [self.history addObject:[self.songs objectAtIndex:0]];
        [self.songs removeObjectAtIndex:0];
        return songToPlay;
    }
    return nil;
}

- (MDSong*)getNextSong{
    return [self getFirstSong];
}

- (NSString*)getStationToken{
    return self.stationToken;
}

- (void)downloadImageArtwork{
    if ([self.stationArtUrl length] > 7) {
        
        NSURL *albumURL = [NSURL URLWithString:self.stationArtUrl];
 
        AFImageDownloader *imageDownloader = [AFImageDownloader defaultInstance];
        [imageDownloader downloadImageForURLRequest:[NSURLRequest requestWithURL:albumURL] success:^(NSURLRequest * _Nonnull request, NSHTTPURLResponse * _Nullable response, UIImage * _Nonnull responseObject) {
            self.stationImage = responseObject;
        } failure:^(NSURLRequest * _Nonnull request, NSHTTPURLResponse * _Nullable response, NSError * _Nonnull error) {
            self.stationImage  = [UIImage imageNamed:@"DefaultImages"];
        }];
    }else{
        self.stationImage = [UIImage imageNamed:@"DefaultImages"];
    }
}

#pragma mark - Contracts

- (void)addSong:(MDSong*) song{
    [self.songs addObject:song];
}

- (void)addExtendedData: (NSDictionary*) extendedStationData{
    [self.thumbs removeAllObjects];
    [self.seedArtist removeAllObjects];
    [self.seedSongs removeAllObjects];
    
    NSDictionary *returndMusic = extendedStationData[@"music"];
    NSDictionary *thumbsData = extendedStationData[@"feedback"];
    for (NSDictionary *d in thumbsData[@"thumbsUp"]) {
        MDFeedback *f = [[MDFeedback alloc]initWithParams:d];
        [self.thumbs addObject:f];
    }
    for (NSDictionary *d in thumbsData[@"thumbsDown"]) {
        MDFeedback *f = [[MDFeedback alloc]initWithParams:d];
        [self.thumbs addObject:f];
    }
 
    for (NSDictionary *d in returndMusic[@"songs"]) {
        MDSeedSong *s = [[MDSeedSong alloc]initWithParams:d];
        [self.seedSongs addObject:s];
    }
    
    for (NSDictionary *d in returndMusic[@"artists"]) {
        MDSeedArtist *a = [[MDSeedArtist alloc]initWithParams:d];
        [self.seedArtist addObject:a];
    }
 }

- (MDFeedback*)feedbackForsong:(NSString*) songTitle withArtist:(NSString*) artist{
    MDFeedback* returnFeedback = nil;
    
    for (MDFeedback * f in self.thumbs) {
        if ([f.songName isEqualToString:songTitle] && [f.artistName isEqualToString:artist]) {
            returnFeedback =f;
            return returnFeedback;
        }
    }
    return returnFeedback;
}

-(NSString*) getStationName{
    return self.stationName;
}

- (NSString*) getStationId{
    return self.stationId;
}

- (NSMutableArray*)getHistory{
    return self.history;
}

- (NSArray*)getSeedSongs{
    return self.seedSongs;
}
- (NSArray*)getSeedArtists{
    return self.seedArtist;
}
- (NSUInteger)getSeedCount{
    return (self.seedArtist.count + self.seedSongs.count);
}

- (void) addSeedSong:(MDSeedSong*)song {
    [self.seedSongs addObject:song];
}
- (void) addSeedArtist:(MDSeedArtist *)artist  {
    [self.seedArtist addObject:artist];
}
- (void) deleteSeedArtist:(MDSeedArtist*)seedArtistToDelete{
    for (MDSeedArtist* seedArtistBeingDeleted in self.seedArtist) {
        if (seedArtistBeingDeleted.seedId == seedArtistToDelete.seedId) {
            [self.seedArtist removeObject:seedArtistBeingDeleted];
            break;
        }
    }
}
- (void) deleteSeedSong:(MDSeedSong*)seedSongToDelete{
    for (MDSeedSong * seedSongBeingDeleted  in self.seedSongs) {
        if(seedSongBeingDeleted == seedSongToDelete){
            [self.seedSongs removeObject:seedSongToDelete];
            break;
        }
    }
}

@end
