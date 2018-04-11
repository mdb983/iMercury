//
//  MDFromStationDetailTransition.h
//  iMercury
//
//  Created by Marino di Barbora on 4/8/16.
//  Copyright © 2016 Marino di Barbora. All rights reserved.
//



@protocol MDTransitionAnimationCompletionFromVCProtocol <NSObject>

- (void) fromViewControllerActionToPerformonAnimationCompletion;
@end

@protocol MDTransitionAnimationCompletionToVCProtocol <NSObject>

- (void) toViewControllerActionToPerformOnAnimationCompletion;

@end

@interface MDFromStationDetailTransition : NSObject <UIViewControllerAnimatedTransitioning>

@end
