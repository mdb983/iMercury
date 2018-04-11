//
//  MDStationDetailsViewController.h
//  iMercury
//
//  Created by Marino di Barbora on 2/8/16.
//  Copyright © 2016 Marino di Barbora. All rights reserved.
//


#import "MDStation.h"
#import "MDSeedBase.h"

@protocol stationDetailViewProtocol;

@interface MDStationDetailsViewController : UIViewController

@property (weak, nonatomic, readonly) IBOutlet  UIImageView * _Nullable  stationImageView;
@property (weak, nonatomic, readonly) IBOutlet UILabel * _Nullable stationNameLabel;
@property (nonatomic, assign) BOOL stationDeleted;
@property (nonatomic) MDStation * _Nonnull selectedStation;
@property (weak, nonatomic) id <stationDetailViewProtocol> _Nullable stationDetailViewDelegate;

@end

@protocol stationDetailViewProtocol <NSObject>
@required
- (void)stationDeleteRequestedForStation:(MDStation * _Nonnull)stationToDelete;
@end
