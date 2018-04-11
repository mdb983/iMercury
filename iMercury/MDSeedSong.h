//
//  MDSeedSong.h
//  iMercury
//
//  Created by Marino di Barbora on 3/4/16.
//  Copyright © 2016 Marino di Barbora. All rights reserved.
//

#import "MDSeedBase.h"


@interface MDSeedSong : MDSeedBase
- (instancetype)initWithParams:(NSDictionary*) songDetails;
@property (nonatomic, readonly) NSString *songName;
@end
