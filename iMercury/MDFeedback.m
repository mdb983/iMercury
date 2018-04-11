//
//  MDFeedback.m
//  iMercury
//
//  Created by Marino di Barbora on 2/8/16.
//  Copyright © 2016 Marino di Barbora. All rights reserved.
//

#import "MDFeedback.h"

@interface MDFeedback ()

@property (assign, nonatomic, readwrite) NSUInteger created;
@property (nonatomic, readwrite) NSString * artistName;
@property (nonatomic, readwrite) NSString * songName;
@property (nonatomic, readwrite) NSString * feedbackId;
@property (nonatomic, readwrite) NSNumber * isPositive;

@end

@implementation MDFeedback

- (instancetype)initWithParams:(NSDictionary*) info{
    self = [super init];
    if (self) {
        _artistName =  [info valueForKey:@"artistName"];
        _songName =  [info valueForKey:@"songName"];
        _created =  [[info[@"dateCreated"] valueForKey:@"time" ] integerValue];
        _feedbackId = [info valueForKey:@"feedbackId"];
        _isPositive = [NSNumber numberWithBool:[[info valueForKey:@"isPositive"] boolValue]];
    }
    return self;
}

@end
