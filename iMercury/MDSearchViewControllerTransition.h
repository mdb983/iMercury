//
//  MDPresentSearchViewAnimation.h
//  iMercury
//
//  Created by Marino di Barbora on 3/26/16.
//  Copyright © 2016 Marino di Barbora. All rights reserved.
//


@interface MDSearchViewControllerTransition : NSObject <UIViewControllerAnimatedTransitioning>
-(instancetype)initWithParam:(BOOL)isPresenting;
@end
