//
//  MDSearchResult.h
//  iMercury
//
//  Created by Marino di Barbora on 3/25/16.
//  Copyright © 2016 Marino di Barbora. All rights reserved.
//

@interface MDSearchResult : NSObject
@property (nonatomic, readonly) NSString *musicToken;
@property (nonatomic, readonly) NSString *songName;
@property (nonatomic, readonly) NSString *artistName;
- (instancetype)initWithParam:(NSDictionary*) searchDetails;
@end
