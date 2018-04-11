//
//  MDSong.h
//  iMercury
//
//  Created by Marino di Barbora on 2/8/16.
//  Copyright © 2016 Marino di Barbora. All rights reserved.
//

@import MediaPlayer;

@interface MDSong : NSObject
@property (nonatomic, readonly) NSString *songToken;
@property (nonatomic, readonly) NSString *songTitle;
@property (nonatomic, readonly) NSString *artistName;
@property (nonatomic, readonly) NSString *albumName;
@property (nonatomic) UIImage  *albumImage;
@property (nonatomic) MPMediaItemArtwork *mediaAlbumArtwork;
@property (nonatomic, readonly) NSString *albumArtURL;
@property (nonatomic, readonly) NSNumber *songRating;
@property (nonatomic, readonly) NSString *stationId;

- (id)initWithParams:(NSDictionary*) songDetails;
- (NSString*)nextPlayURL;
- (void)songRatingValue:(NSNumber *)songRating;
@end
