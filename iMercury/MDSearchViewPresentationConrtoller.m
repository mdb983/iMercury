//
//  MDSearchViewPresentationConrtoller.m
//  iMercury
//
//  Created by Marino di Barbora on 3/26/16.
//  Copyright © 2016 Marino di Barbora. All rights reserved.
//
#import <Foundation/Foundation.h>
#import <UIKit/UIViewControllerTransitioning.h>
#import "MDSearchViewPresentationConrtoller.h"
#import "MDSearchViewController.h"


@interface MDSearchViewPresentationConrtoller  () 
@property (nonatomic) UIView *bluredView;
@property (nonatomic) UIView *presentationWrappingView;

@end

@implementation MDSearchViewPresentationConrtoller

- (UIView*)presentedView {
    // Return the wrapping view created in -presentationTransitionWillBegin.
    return self.presentationWrappingView;
}

//the search controller won't be full screen. Set the dimensions here
-(CGRect)frameOfPresentedViewInContainerView{
    CGRect presentedViewFrame = CGRectZero;
    CGRect containerBounds = [[self containerView] bounds];
    presentedViewFrame.size = [self sizeForChildContentContainer:
                               (UIView<UIContentContainer> *)[self presentedView]
                                         withParentContainerSize:containerBounds.size];
    presentedViewFrame.origin.x = floorf((containerBounds.size.width - presentedViewFrame.size.width) /2);
    presentedViewFrame.origin.y = floorf((containerBounds.size.height -
                                   presentedViewFrame.size.height)/2);
    
    return presentedViewFrame;
}


-(CGSize)sizeForChildContentContainer:(id<UIContentContainer>)container withParentContainerSize:(CGSize)parentSize{

        return CGSizeMake(floorf(parentSize.width * 0.85),
                          floorf(parentSize.height * 0.85));
}



#pragma mark - UIViewControllerAnimatedTransitioning protocol
-(void)presentationTransitionWillBegin{
    
    UIView *containerView = [self containerView];
    UIView *presentedView  =[super presentedView];
    containerView.backgroundColor = [UIColor clearColor];
    
    //we need to wrap presented View Controllers view in a container to avoid a bug with incorrect positioning of serarchbar - bug report filed - 25554962
    UIView *presentationWrapperView = [[UIView alloc] initWithFrame:self.frameOfPresentedViewInContainerView];
    presentationWrapperView.backgroundColor = [UIColor clearColor];
    self.presentationWrappingView = presentationWrapperView;
    presentedView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    presentedView.frame = presentationWrapperView.bounds;
    presentedView.backgroundColor = [UIColor clearColor];
    
    
    self.bluredView = [UIView new];
    self.bluredView.frame = containerView.bounds;
    self.bluredView.backgroundColor = [UIColor clearColor];
    self.bluredView.alpha = 0.0;

    
    UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
    UIVisualEffectView *visualEffectView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
    

    visualEffectView.frame = self.bluredView.bounds;
    
    // vibrancy
    UIVibrancyEffect *vibrancyEffect = [UIVibrancyEffect effectForBlurEffect:blurEffect];
    UIVisualEffectView *vibrancyView = [[UIVisualEffectView alloc] initWithEffect:vibrancyEffect];
    [visualEffectView.contentView addSubview:vibrancyView];
    [self.bluredView addSubview:visualEffectView];
    
    [containerView  insertSubview:self.bluredView atIndex:0 ];
    [presentationWrapperView addSubview:presentedView];
    
    [self.presentingViewController.transitionCoordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        self.bluredView.alpha = 0.85;
    } completion:nil];
}

-(void)presentationTransitionDidEnd:(BOOL)completed{
    if (!completed) {
        [self.bluredView removeFromSuperview ];
    }
}
-(void)dismissalTransitionWillBegin{
    [self.presentingViewController.transitionCoordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        self.bluredView.alpha = 0.0;
    } completion:nil];
}

-(void)dismissalTransitionDidEnd:(BOOL)completed{
    if (completed) {
        [self.bluredView removeFromSuperview];
    }
}


-(void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        self.bluredView.frame = self.containerView.bounds;
        
    } completion:nil];
}

@end
