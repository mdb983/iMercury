//
//  MDSeedSong.m
//  iMercury
//
//  Created by Marino di Barbora on 3/4/16.
//  Copyright © 2016 Marino di Barbora. All rights reserved.
//
#import <UIKit/UIKit.h>
#import "AFImageDownloader.h"
#import "MDSeedSong.h"

@interface MDSeedSong ()
@property (nonatomic) NSString *songName;
@end

@implementation MDSeedSong


#pragma mark - Lifecycle

- (instancetype)initWithParams:(NSDictionary*) songDetails{
    self = [super initWithParams:songDetails];
    if (self) {
        _songName =  [songDetails valueForKey:@"songName"];
    }

    return self;
}


@end
