//
//  MDPresentSearchViewAnimation.m
//  iMercury
//
//  Created by Marino di Barbora on 3/26/16.
//  Copyright © 2016 Marino di Barbora. All rights reserved.
//

#import "MDSearchViewControllerTransition.h"

@interface MDSearchViewControllerTransition ()
@property (nonatomic) BOOL isPresenting;
@end

@implementation MDSearchViewControllerTransition

-(instancetype)initWithParam:(BOOL)isPresenting{
    self = [super init];
    if (self) {
        _isPresenting = isPresenting;
    }
    return self;
}

-(NSTimeInterval)transitionDuration:(id<UIViewControllerContextTransitioning>)transitionContext{
    return 1.35f;
}

-(void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext{
 
    if (self.isPresenting) {
      //  [self animatePresentationWithTransitionContext:transitionContext];
    }else{
      //  [self animateDismissalWithTransitionContext:transitionContext];
    }
}

- (void)animatePresentationWithTransitionContext:(id<UIViewControllerContextTransitioning>)transitioningContext{
    UIViewController *toViewController = (UIViewController*)[transitioningContext viewControllerForKey:UITransitionContextToViewControllerKey];
    UIView  *toView = (UIView*)[transitioningContext viewForKey:UITransitionContextToViewKey];
    
    UIView *containerView = [transitioningContext containerView];
    toView.frame = [transitioningContext finalFrameForViewController:toViewController];
    CGPoint centerPos = CGPointMake(toView.center.x, toView.center.y);
    centerPos.y -= containerView.bounds.size.height;
    toView.center = centerPos;
    [containerView addSubview:toView];

    
    [UIView animateWithDuration:1.35f delay:0.0f usingSpringWithDamping:1.0 initialSpringVelocity:0.0 options:UIViewAnimationOptionAllowUserInteraction animations:^{
        CGPoint centerPos = CGPointMake(toView.center.x, toView.center.y);
        centerPos.y -= containerView.bounds.size.height;
        toView.center = centerPos;

    } completion:^(BOOL finished) {
        [transitioningContext completeTransition:finished];
    }];
}

- (void)animateDismissalWithTransitionContext:(id<UIViewControllerContextTransitioning>)transitioningContext{
    UIView  *toView = (UIView*)[transitioningContext viewForKey:UITransitionContextToViewKey];
    UIView *containerView = [transitioningContext containerView];
    
    [UIView animateWithDuration:1.35 delay:0.0 usingSpringWithDamping:1.0 initialSpringVelocity:0.0 options:UIViewAnimationOptionAllowUserInteraction animations:^{
        CGPoint centerPos = CGPointMake(toView.center.x, toView.center.y);
        centerPos.y += containerView.bounds.size.height;
        toView.center = centerPos;

    } completion:^(BOOL finished) {
        [transitioningContext completeTransition:finished];
    }];

}

@end
