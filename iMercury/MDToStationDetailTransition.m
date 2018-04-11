//
//  MDToStationDetailTransition.m
//  iMercury
//
//  Created by Marino di Barbora on 3/17/16.
//  Copyright © 2016 Marino di Barbora. All rights reserved.
//

#import "MDToStationDetailTransition.h"
#import "MDStationCollectionViewController.h"
#import "MDStationDetailsViewController.h"
#import "MDStationReusableView.h"
#import "MDStationViewCell.h"

@implementation MDToStationDetailTransition


-(void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext{
    // create instances of our Controllers
    
    MDStationCollectionViewController *fromViewController = (MDStationCollectionViewController*)[transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    MDStationDetailsViewController *toViewController = (MDStationDetailsViewController*)[transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
   
    // ios 11 requires the addition of this
    [toViewController.navigationController setNavigationBarHidden:FALSE  animated:FALSE];

    // container for image transition
    UIView *containerView = [transitionContext containerView];
    NSTimeInterval duration = [self transitionDuration:transitionContext];
    
    //snapshot selected cell
    MDStationViewCell *transitioningCell =   (MDStationViewCell*)[fromViewController.collectionView cellForItemAtIndexPath:[[fromViewController.collectionView indexPathsForSelectedItems] firstObject]];
 
     UIView *cellImageSnapshot = [transitioningCell resizableSnapshotViewFromRect:transitioningCell.stationImage.frame afterScreenUpdates:NO withCapInsets:UIEdgeInsetsZero];

    CGRect newFrame = [containerView convertRect:transitioningCell.frame fromView:transitioningCell.superview];

    //Adjust from image inset on cell
    CGRect cellImageRect = transitioningCell.stationImage.frame;
    newFrame.origin.x += cellImageRect.origin.x;
    newFrame.origin.y += cellImageRect.origin.y;
    newFrame.size = cellImageRect.size;
    cellImageSnapshot.frame = newFrame;
 
    transitioningCell.hidden = YES;
 
    toViewController.view.frame = [transitionContext finalFrameForViewController:toViewController];
    toViewController.view.alpha = 0.0;
    toViewController.stationImageView.hidden = YES;
    toViewController.stationNameLabel.text = transitioningCell.title.text;

    
    [containerView addSubview:toViewController.view];
    [containerView addSubview:cellImageSnapshot];
    

    
    [UIView animateWithDuration:duration animations:^{
     
        // Fade in the second view controller's view
        toViewController.view.alpha = 1.0;
        CGRect frame = [containerView convertRect:toViewController.stationImageView.frame fromView:toViewController.stationImageView.superview];
        frame.origin.y += 20.0f;
        frame.origin.x += 16.0f;
        cellImageSnapshot.frame = frame;
        
        
    } completion:^(BOOL finished) {
        // Clean up
        [cellImageSnapshot removeFromSuperview];
        toViewController.stationImageView.hidden = NO;
        toViewController.stationNameLabel.hidden = NO;
        transitioningCell.hidden = NO;

        
        // Declare that we've finished
        [transitionContext completeTransition:YES];

    }];


}

-(NSTimeInterval)transitionDuration:(id<UIViewControllerContextTransitioning>)transitionContext{
 
    return 0.35f;
}
@end
