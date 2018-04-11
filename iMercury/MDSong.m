//
//  MDSong.m
//  iMercury
//
//  Created by Marino di Barbora on 2/8/16.
//  Copyright © 2016 Marino di Barbora. All rights reserved.
//


@import MediaPlayer;

#import "AFImageDownloader.h"
#import "MDConstants.h"
#import "MDSong.h"


@interface MDSong ()
@property (nonatomic, readwrite) NSString *songToken;
@property (nonatomic, readwrite) NSString *artistName;
@property (nonatomic, readwrite) NSString *songTitle;
@property (nonatomic, readwrite) NSString *albumName;
@property (nonatomic, readwrite) NSString *albumArtURL;
@property (nonatomic, readwrite) NSNumber *songRating;
@property (nonatomic, readwrite) NSString *stationId;

@property (nonatomic) NSString *albumUrl;
@property (nonatomic) NSString *artistUrl;
@property (nonatomic) NSString *songDetailsUrl;


@property (nonatomic) NSNumber *trackGain;
@property (nonatomic) NSString *highUrl;
@property (nonatomic) NSString *medUrl;
@property (nonatomic) NSString *lowUrl;

@property (nonatomic) NSString *defaultSongUrl;

@end

@implementation MDSong

#pragma mark - Lifecycle

- (instancetype)initWithParams:(NSDictionary*) songDetails{
    self = [super init];
    if (self) {
        _artistName =  [songDetails valueForKey:@"artistName"];
        _songTitle =  [songDetails valueForKey:@"songName"];
        _albumName =  [songDetails valueForKey:@"albumName"];
        _albumArtURL =  [songDetails valueForKey:@"albumArtUrl"];
        _stationId =  [songDetails valueForKey:@"stationId"];
        _songRating = [NSNumber numberWithInteger: [[songDetails valueForKey:@"songRating"]integerValue]];
        
        _albumUrl = [songDetails valueForKey:@"albumDetailUrl"];
        _artistUrl = [songDetails valueForKey:@"artistDetailUrl"];
        _songDetailsUrl = [songDetails valueForKey:@"songDetailUrl"];
         _songToken = [songDetails valueForKey:@"trackToken"];       

        _trackGain = [NSNumber numberWithFloat:[[songDetails valueForKey:@"trackGain"] floatValue]];
        _defaultSongUrl = [songDetails valueForKey:@"audioUrl"];
        
        id songAdditionalUrls = [songDetails valueForKey:@"additionalAudioUrl"] ;
        if ([songAdditionalUrls isKindOfClass:[NSArray class]]) {
            NSArray *urlArray = songAdditionalUrls;
            for (int i = 0; i< [urlArray count]; i++) {
                switch (i) {
                    case 0:
                        _lowUrl = [urlArray objectAtIndex:i];
                        break;
                    case 1:
                        _medUrl = [urlArray objectAtIndex:i];
                        break;
                    case 2:
                        _highUrl = [urlArray objectAtIndex:i];
                        break;
                        
                    default:
                        break;
                }
            }
        }
    }
   [self downloadImageArtwork];
    return self;
}

#pragma mark - Contracts

- (NSString *)nextPlayURL{
    return self.highUrl;
}

- (void)songRatingValue:(NSNumber *)songRating{
    self.songRating = songRating;
}

- (void)downloadImageArtwork{
    NSString *albumArtURLString = self.albumArtURL;
    
    if ([albumArtURLString length] > 7) {
        
        NSURL *albumURL = [NSURL URLWithString:self.albumArtURL];
        
        AFImageDownloader *imageDownloader = [AFImageDownloader defaultInstance];
        [imageDownloader downloadImageForURLRequest:[NSURLRequest requestWithURL:albumURL] success:^(NSURLRequest * _Nonnull request, NSHTTPURLResponse * _Nullable response, UIImage * _Nonnull responseObject) {
            
            self.albumImage = responseObject;
            [self setAlbumArtwork];
            
        } failure:^(NSURLRequest * _Nonnull request, NSHTTPURLResponse * _Nullable response, NSError * _Nonnull error) {
            
            self.albumImage  = [UIImage imageNamed:@"DefaultImages"];
            [self setAlbumArtwork];
        }];
    }else{
        
        self.albumImage = [UIImage imageNamed:@"DefaultImages"];
         [self setAlbumArtwork];
    }
}

- (void) setAlbumArtwork{
   self.mediaAlbumArtwork = [[MPMediaItemArtwork alloc]initWithBoundsSize:self.albumImage.size requestHandler:^UIImage * _Nonnull(CGSize size) {
        size = self.albumImage.size;
        return self.albumImage;
    }];
}

@end
