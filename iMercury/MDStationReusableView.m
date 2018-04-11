//
//  MDStationReusableView.m
//  iMercury
//
//  Created by Marino di Barbora on 3/7/16.
//  Copyright © 2016 Marino di Barbora. All rights reserved.
//

#import "MDStationReusableView.h"

@interface MDStationReusableView ()

@property (nonatomic, readwrite) UIButton *headerButton;
@property (nonatomic, readwrite) UILabel *headerLabel;
@property (nonatomic) UIFont *font;
@property (nonatomic) float topMargin;
@property (nonatomic,assign) float margin;
@end

@implementation MDStationReusableView


- (instancetype)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if (self) {
        [self commonSetup];
    }
    return self;
}
         
- (instancetype)initWithCoder:(NSCoder *)aDecoder{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self commonSetup];
    }
    return self;
}

- (void) commonSetup{
    self.margin = 70.0f;
    self.topMargin = 16.0f;
    self.font = [UIFont fontWithName:@"AvenirNext-Regular" size:24.0f];
    float fontHeight = ceilf(self.font.capHeight + self.font.ascender );

    self.backgroundColor = [UIColor clearColor];
 //   self.layer.shadowColor = [UIColor blackColor].CGColor;
 //   self.layer.shadowRadius = 3.0f;
 //   self.layer.shadowOffset = CGSizeMake(0.0f, 2.0f);
 //   self.layer.shadowOpacity = 0.5f;
    
    self.headerLabel = [UILabel new];
    self.headerLabel.font = self.font;
    self.headerLabel.textColor = [UIColor whiteColor];
    self.headerLabel.frame = CGRectMake(self.margin,0.0f, self.frame.size.width - self.margin, fontHeight + self.topMargin);
    self.headerLabel.textAlignment = NSTextAlignmentLeft;
    self.headerLabel.center = CGPointMake(self.frame.size.width/2, self.frame.size.height / 2);
    [self addSubview:self.headerLabel];
    self.headerLabel.text = @"Stations";
    
    self.headerButton = [UIButton buttonWithType:UIButtonTypeContactAdd];
    self.headerButton.frame = CGRectMake(0.0f, 0.0f, fontHeight, fontHeight);
    self.headerButton.center = CGPointMake(self.frame.size.width - (fontHeight), self.frame.size.height /2);
    [self addSubview:self.headerButton];
}
@end
