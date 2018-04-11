//
//  MDSeedTableViewCell.h
//  iMercury
//
//  Created by Marino di Barbora on 4/14/16.
//  Copyright © 2016 Marino di Barbora. All rights reserved.
//


@class MDSeedArtist;
@class MDSeedSong;
@class MDSeedBase;

@interface MDSeedTableViewCell : UITableViewCell
- (void)setupCellForSongSeed:(MDSeedSong*)seedSong;
- (void)setupCellForArtistSeed:(MDSeedArtist*)seedArtist;
- (void)setCircleImage:(UIImage* )image;
- (void)setCircleImageFor:(UIImage*)image forSeed:(MDSeedBase*)seed;
@end
