//
//  MDGraphicEqualizerBarLayer.m
//  iMercury
//
//  Created by Marino di Barbora on 2/8/16.
//  Copyright © 2016 Marino di Barbora. All rights reserved.
//


#import "MDGraphicEqualizerBarLayer.h"

@interface MDGraphicEqualizerBarLayer ()
@property (nonatomic) NSMutableArray *barBlockArray;
@property (nonatomic, assign) NSUInteger blockCount;
@property (nonatomic, assign) float padding;
@property (nonatomic, assign) float blockHeight;
@property (nonatomic, assign) NSUInteger peakBarCount;
@property (nonatomic, assign) NSUInteger currentBarCount;
@property (nonatomic) UIColor *activeColor;
@property (nonatomic) UIColor *inactiveColor;
@end

@implementation MDGraphicEqualizerBarLayer

- (BOOL)needsDisplayOnBoundsChange {
    return YES;
}
#pragma mark - lifecycle
- (instancetype)init{
    
    self = [super init];
    if(self){
        _barBlockArray = [NSMutableArray array];
        _blockCount = 20;
        _padding = 1.0;
        _peakBarCount = 0;
        _currentBarCount = 0;
        [self setupBarBlocks];
    }
    return self;
}

-(void)layoutSublayers{
    CGRect bounds = self.bounds;
    
    float adjustedHeigh = bounds.size.height - self.blockCount*self.padding;
    self.blockHeight = (adjustedHeigh/self.blockCount > 4) ? adjustedHeigh/self.blockCount : 4;
    for (NSUInteger i = 0; i < self.barBlockArray.count; ++i) {
        CAShapeLayer *sl = (CAShapeLayer*)[self.barBlockArray objectAtIndex:i];
        float offset = (adjustedHeigh/self.blockCount +((i*self.blockHeight)+(i*1)));
        sl.frame = CGRectMake(0, (bounds.size.height - offset) ,  bounds.size.width, self.blockHeight);
    }
}

- (void)setupBarBlocks{
    self.inactiveColor = [UIColor clearColor];
    self.activeColor = [UIColor whiteColor];
    
    for (NSUInteger i = 0; i < self.blockCount; ++i) {
        CAShapeLayer *block = [CAShapeLayer layer];
        // we dont want the backgroundColor change to be animated
        NSDictionary *actions = @{@"backgroundColor": [NSNull null]};
        block.actions = actions;
        block.backgroundColor = self.inactiveColor.CGColor ;
        [self.barBlockArray addObject:block];
        [self addSublayer:block];
    }
}

#pragma mark - update

- (void)updateLevelMeter:(float) passedInValue{
    //normalize from db scale - db range reduces for scaling
    float fVal = (passedInValue - -128.0f)/ 99.0f; 

    //convert to block representation
    NSInteger barCount = (lroundf(self.blockCount * fVal) < self.blockCount ) ? lroundf(self.blockCount * fVal) : self.blockCount ;
    
    if (self.currentBarCount < barCount) {
        for (NSInteger i = self.currentBarCount; i < barCount; i++) {
            CAShapeLayer *sl = [self.barBlockArray objectAtIndex:i];
            sl.backgroundColor = self.activeColor.CGColor;
        }
    }else{
        for (NSInteger i = barCount ; i < self.currentBarCount ; i++) {
            CAShapeLayer *sl = [self.barBlockArray objectAtIndex:i];
            sl.backgroundColor = self.inactiveColor.CGColor;
        }
    }
    
    self.currentBarCount = barCount;
}

@end
