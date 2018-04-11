//
//  MDBaseSeed.m
//  iMercury
//
//  Created by Marino di Barbora on 4/15/16.
//  Copyright © 2016 Marino di Barbora. All rights reserved.
//

#import "MDSeedBase.h"

@interface MDSeedBase ()
@property (nonatomic) NSString *artistName;
@property (nonatomic) NSString *musicToken;
@property (nonatomic) NSString *seedId;
@property (nonatomic) NSString *artUrl;
@end

@implementation MDSeedBase

#pragma mark - Lifecycle

- (instancetype)initWithParams:(NSDictionary*) baseDetails{
    self = [super init];
    if (self) {
        _seedId =  [baseDetails valueForKey:@"seedId"];
        _artistName =  [baseDetails valueForKey:@"artistName"];
        _artUrl =  [baseDetails valueForKey:@"artUrl"];
        _musicToken = [baseDetails valueForKey:@"musicToken"];
    }
    
    return self;
}
@end
