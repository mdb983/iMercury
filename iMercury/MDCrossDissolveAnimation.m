//
//  MDCrossDissolvAnimation.m
//  iMercury
//
//  Created by Marino di Barbora on 4/13/16.
//  Copyright © 2016 Marino di Barbora. All rights reserved.
//

#import "MDCrossDissolveAnimation.h"

@implementation MDCrossDissolveAnimation


- (void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext {

   // UIViewController *fromViewController = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIViewController *toViewController = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    
    UIView *containerView = [transitionContext containerView];
    NSTimeInterval duration = [self transitionDuration:transitionContext];
    
    toViewController.view.frame = [transitionContext finalFrameForViewController:toViewController];
    toViewController.view.alpha = 0.0f;
    
    
    [containerView addSubview:toViewController.view];
    
    [UIView animateWithDuration:duration animations:^{
        toViewController.view.alpha = 1.0f;
        //fromViewController.view.alpha = 0.0f;
    } completion:^(BOOL finished) {
   //     fromViewController.view.alpha = 1.0;
        [transitionContext completeTransition:YES];
    }];
    
}


- (NSTimeInterval)transitionDuration:(id<UIViewControllerContextTransitioning>)transitionContext {
    return 0.35;
}

@end
