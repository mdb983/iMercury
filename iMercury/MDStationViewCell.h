//
//  MDStationCellCollectionViewCell.h
//  iMercury
//
//  Created by Marino di Barbora on 3/5/16.
//  Copyright © 2016 Marino di Barbora. All rights reserved.
//


@interface MDStationViewCell : UICollectionViewCell
@property (nonatomic, readonly) UILabel *title;
@property (nonatomic, readonly) UIImageView *stationImage;
@property (nonatomic) NSString *currentStationId;
- (void) setCircleImage: (UIImage*) imageToSet;

@end
