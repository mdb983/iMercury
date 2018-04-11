//
//  MDStationCellCollectionViewCell.m
//  iMercury
//
//  Created by Marino di Barbora on 3/5/16.
//  Copyright © 2016 Marino di Barbora. All rights reserved.
//

#import "MDStationViewCell.h"

@interface MDStationViewCell ()

@property (nonatomic) UIImageView *stationImage;
@property (nonatomic, readwrite) UILabel *title;
@property (nonatomic) UIFont *font;

@end


@implementation MDStationViewCell
- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self commonSetup];
    }
    
    return self;
}

-(instancetype)initWithCoder:(NSCoder *)aDecoder{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self commonSetup];
    }
    return self;
}

- (void)commonSetup{
    self.font = [UIFont fontWithName:@"AvenirNext-Regular" size:14.0f];
    float fontHeight = ceilf(self.font.capHeight + self.font.ascender );
    
    CGRect newFrame =self.frame;
    newFrame.size.width -=fontHeight;
    newFrame.size.height -= fontHeight;
    newFrame.origin.x = fontHeight/2;
    newFrame.origin.y = 0;
    
    self.stationImage = [[UIImageView alloc]initWithFrame:newFrame];
    self.stationImage.layer.cornerRadius = (newFrame.size.width)/2;
    self.stationImage.layer.borderWidth = 1.0f;
    self.stationImage.layer.borderColor = [UIColor whiteColor].CGColor;
    self.stationImage.clipsToBounds = YES;
    [self.contentView addSubview:self.stationImage];
    
    self.backgroundColor = [UIColor clearColor];
    
    // make sure we rasterize nicely for retina
    self.layer.rasterizationScale = [UIScreen mainScreen].scale;
    self.layer.shouldRasterize = YES;

    self.title = [UILabel new];
    self.title.font = self.font;
    self.title.textColor = [UIColor whiteColor];
    self.title.frame = CGRectMake(0.0f,0.0f, self.frame.size.width, fontHeight);
    self.title.textAlignment = NSTextAlignmentCenter;
    self.title.center = CGPointMake(self.frame.size.width/2, self.frame.size.height - (fontHeight/2));
    [self.contentView addSubview:_title];
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    self.stationImage.image = nil;

}
- (void) setCircleImage: (UIImage*) imageToSet{
      self.stationImage.image = imageToSet;
 }


@end
