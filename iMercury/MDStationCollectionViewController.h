//
//  MDStationCollectionViewController.h
//  iMercury
//
//  Created by Marino di Barbora on 2/8/16.
//  Copyright © 2016 Marino di Barbora. All rights reserved.
//


@class MDStationViewCell;
@class MDStation;

@interface MDStationCollectionViewController : UICollectionViewController
- (MDStationViewCell * _Nonnull)collectionViewCellForStation:(MDStation * _Nonnull)station;
- (void)stationDeleteRequestedForStation:(MDStation * _Nonnull)stationToDelete;
- (void)toViewControllerActionToPerformOnAnimationCompletion;
@end
