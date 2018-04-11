//
//  MDGraphicEqualizerDisplayLayer.m
//  iMercury
//
//  Created by Marino di Barbora on 2/8/16.
//  Copyright © 2016 Marino di Barbora. All rights reserved.
//
#import <UIKit/UIKit.h>
#import "MDGraphicEqualizerDisplayLayer.h"
#import "MDGraphicEqualizerBarLayer.h"

@interface MDGraphicEqualizerDisplayLayer ()
@property (nonatomic, readwrite) NSUInteger displayBarCount;
@property (nonatomic) NSMutableArray *barsArray;
@property(nonatomic,assign) float padding;

@end

@implementation MDGraphicEqualizerDisplayLayer

#pragma mark - lifecycle

- (instancetype)initWithNumberOfBars:(NSUInteger)numberOfBars{
    self = [super init];
    if (self) {
        _displayBarCount = numberOfBars;
        _padding = 1.0;
        [self setupLayers];
    }
    return self;
}

- (void)setupLayers{
    self.barsArray = [NSMutableArray array];
    for (NSUInteger i = 0; i < self.displayBarCount; ++i) {
        MDGraphicEqualizerBarLayer *barLayer = [[MDGraphicEqualizerBarLayer  alloc]init];
        [self.barsArray addObject:barLayer];
    }
}


- (void)layoutSublayers{
    CGRect selfBounds = self.bounds;


    float adjustedWidth =  ( self.frame.size.width - ((self.displayBarCount -1)* self.padding) );
    float barWidth = (adjustedWidth/self.displayBarCount );
    
    for (NSUInteger i = 0; i < self.barsArray.count; ++i) {
        MDGraphicEqualizerBarLayer *barLayer = [self.barsArray objectAtIndex:i];
        barLayer.frame =  CGRectMake(((barWidth*i)+(self.padding * i)),0, barWidth, selfBounds.size.height);
        [self addSublayer:barLayer];
    }
}

#pragma mark - update

- (void)updateDisplayBars:(NSMutableArray*) passedInArray{
    for (NSUInteger i = 0; i < passedInArray.count; ++i) {
        if (i < self.barsArray.count) {
            MDGraphicEqualizerBarLayer *bl = [self.barsArray objectAtIndex:i];
            [bl updateLevelMeter:[[passedInArray objectAtIndex:i]floatValue]];
        }
    }
}

@end
