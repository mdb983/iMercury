//
//  MDSearchResult.m
//  iMercury
//
//  Created by Marino di Barbora on 3/25/16.
//  Copyright © 2016 Marino di Barbora. All rights reserved.
//

#import "MDSearchResult.h"

@interface MDSearchResult ()
@property (nonatomic, readwrite) NSString *musicToken;
@property (nonatomic, readwrite) NSString *songName;
@property (nonatomic, readwrite) NSString *artistName;
@end

@implementation MDSearchResult
- (instancetype)initWithParam:(NSDictionary*) searchDetails{
    self = [super init];
    if (self) {
        _musicToken = [searchDetails valueForKey:@"musicToken"];
        _songName = [searchDetails valueForKey:@"songName"];
        _artistName = [searchDetails valueForKey:@"artistName"];
    }
    return self;
    
}

@end
