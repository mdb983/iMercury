//
//  MDPlayProgressView.h
//  iMercury
//
//  Created by Marino di Barbora on 2/8/16.
//  Copyright © 2016 Marino di Barbora. All rights reserved.
//



#import "MDConstants.h"


@protocol playerViewProtocolDelegate;
@interface MDPlayProgressView : UIView <UIGestureRecognizerDelegate>

@property (nonatomic, weak) id <playerViewProtocolDelegate> playerViewDelegate;
- (void)setAlbumCoverImage:(UIImage *)coverImage;
- (void)setSongProgress:(float)toProgress updateFrequency:(float)updateFrequency;
- (void)setDefaultVolumeLevel:(float)toVolume;
- (void)updateSpectrumDisplay:(NSMutableArray*) frequencyArray numberOfElements: (UInt32)elementsAvailable;
- (void)switchAlbumImage:(UIImage*)image;
- (void)clearSpectrumDisplay;

@end

@protocol playerViewProtocolDelegate <NSObject>
- (void)adjustedVolume:(float)toVolumeLevel;
- (void)finishedDiscChangeAnimation;
@optional
- (void)didReceivedTouchOnMenu:(NSInteger)menuItem ;
@end
