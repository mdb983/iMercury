//
//  MDGraphicEqualizerBarLayer.h
//  iMercury
//
//  Created by Marino di Barbora on 2/8/16.
//  Copyright © 2016 Marino di Barbora. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

@interface MDGraphicEqualizerBarLayer : CALayer
- (void)updateLevelMeter:(float) passedInValue;
@end
