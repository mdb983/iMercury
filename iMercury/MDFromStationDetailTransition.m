//
//  MDFromStationDetailTransition.m
//  iMercury
//
//  Created by Marino di Barbora on 4/8/16.
//  Copyright © 2016 Marino di Barbora. All rights reserved.
//

#import "MDFromStationDetailTransition.h"
#import "MDStationCollectionViewController.h"
#import "MDStationDetailsViewController.h"
#import "MDStationViewCell.h"

@interface MDFromStationDetailTransition ()
@property (nonatomic, weak) UIViewController *fromUIViewController;
@property (nonatomic, weak) UIViewController *toUIViewController;

@end

@implementation MDFromStationDetailTransition

- (void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext {

    
    MDStationDetailsViewController *fromViewController = (MDStationDetailsViewController*)[transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    MDStationCollectionViewController *toViewController = (MDStationCollectionViewController*)[transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    self.fromUIViewController = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    self.toUIViewController = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];

    NSArray *cellArray = [toViewController.collectionView indexPathsForVisibleItems];
    for (NSIndexPath *p in cellArray) {
        MDStationViewCell *c = (MDStationViewCell*)[toViewController.collectionView cellForItemAtIndexPath:p];
       c.alpha = 0.0;
    }
    
    UIView *containerView = [transitionContext containerView];
    NSTimeInterval duration = [self transitionDuration:transitionContext];
    
    UIView *imageSnapshot = [fromViewController.stationImageView snapshotViewAfterScreenUpdates:NO];
    imageSnapshot.frame = [containerView convertRect:fromViewController.stationImageView.frame fromView:fromViewController.stationImageView.superview];
    
    fromViewController.stationImageView.hidden = YES;

    MDStationViewCell *transitioningCell =   [toViewController collectionViewCellForStation:fromViewController.selectedStation];
    toViewController.view.frame = [transitionContext finalFrameForViewController:toViewController];
    [containerView insertSubview:toViewController.view belowSubview:fromViewController.view];
  
    [containerView addSubview:imageSnapshot];
    
    // use 2 animations, move to destinationView then fade in CollectionViewCells
    
    [UIView animateWithDuration:duration animations:^{
        // Fade out the source view controller
        fromViewController.view.alpha = 0.0;
         CGRect newFrame = [containerView convertRect:transitioningCell.stationImage.frame fromView:transitioningCell.superview];
        newFrame.origin.x += transitioningCell.frame.origin.x;
        newFrame.origin.y += transitioningCell.frame.origin.y;
 
        // Move the image view
        imageSnapshot.frame = newFrame;
    } completion:^(BOOL finished) {
        // Clean up
       
        fromViewController.stationImageView.hidden = NO;
        transitioningCell.hidden = NO;

       //at this point we have the destinationViewControllerVisible and the snapshotCell in the correct position
       [UIView animateWithDuration:0.25 animations:^{
           
           for (NSIndexPath *p in cellArray) {
               MDStationViewCell *c = (MDStationViewCell*)[toViewController.collectionView cellForItemAtIndexPath:p];
               c.alpha = 1.0;
           }
           
       } completion:^(BOOL finished) {
           //just need to remove the snapshotCell
           [imageSnapshot removeFromSuperview];

          // Declare we've finished
           [transitionContext completeTransition:YES];

           
       }];
    }];

}



-(void)animationEnded:(BOOL)transitionCompleted{
    if ([self.toUIViewController conformsToProtocol:@protocol(MDTransitionAnimationCompletionToVCProtocol)]) {
            [self.toUIViewController performSelectorOnMainThread:@selector(toViewControllerActionToPerformOnAnimationCompletion) withObject:nil waitUntilDone:NO];
    }
    
    if ([self.fromUIViewController conformsToProtocol:@protocol(MDTransitionAnimationCompletionFromVCProtocol)]) {
            [self.fromUIViewController performSelectorOnMainThread:@selector(fromViewControllerActionToPerformonAnimationCompletion) withObject:nil waitUntilDone:NO];
    }

}


- (NSTimeInterval)transitionDuration:(id<UIViewControllerContextTransitioning>)transitionContext {
    return 0.35;
}


@end
