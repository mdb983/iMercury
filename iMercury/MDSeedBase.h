//
//  MDBaseSeed.h
//  iMercury
//
//  Created by Marino di Barbora on 2/8/16.
//  Copyright © 2016 Marino di Barbora. All rights reserved.
//



@interface MDSeedBase : NSObject
- (instancetype)initWithParams:(NSDictionary*) baseDetails;
@property (nonatomic,readonly) NSString *artistName;
@property (nonatomic, readonly) NSString *artUrl;
@property (nonatomic, readonly) NSString *seedId;
@end
