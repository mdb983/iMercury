//
//  MDFeedback.h
//  iMercury
//
//  Created by Marino di Barbora on 2/8/16.
//  Copyright © 2016 Marino di Barbora. All rights reserved.
//



@interface MDFeedback : NSObject

@property (assign, nonatomic, readonly) NSUInteger created;
@property (nonatomic, readonly) NSString * artistName;
@property (nonatomic, readonly) NSString * songName;
@property (nonatomic, readonly) NSString * feedbackId;
@property (nonatomic, readonly) NSNumber * isPositive;
- (id)initWithParams:(NSDictionary*) info;

@end
