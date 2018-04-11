//
//  MDSeedTableViewCell.m
//  iMercury
//
//  Created by Marino di Barbora on 4/14/16.
//  Copyright © 2016 Marino di Barbora. All rights reserved.
//

#import "MDSeedTableViewCell.h"
#import "MDSeedSong.h"
#import "MDSeedArtist.h"

@interface MDSeedTableViewCell ()
@property (nonatomic) UIView *tintedView;
@property (weak, nonatomic) IBOutlet UIImageView *seedCellImageView;
@property (weak, nonatomic) IBOutlet UILabel *artistOrSong;
@property (weak, nonatomic) IBOutlet UILabel *artist;
@property (nonatomic) NSString *currentSeedId;
@property (nonatomic) UIColor *selectedColor;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *artistOrSongCenterConstraint;

@end

@implementation MDSeedTableViewCell

-(instancetype)initWithCoder:(NSCoder *)aDecoder{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self commonInit];
    }
    return self;
}

-(instancetype)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if (self) {
        [self commonInit];
    }
    return self;
}

-(void)awakeFromNib{
    self.tintedView = [[UIView alloc]initWithFrame:self.bounds];
    self.tintedView.backgroundColor  = [UIColor colorWithRed:220.0f/255.0f green:220.0f/255.0f blue:220.0f/255.0f alpha:0.3f];
    [self setSelectedBackgroundView:self.tintedView ];
    [super awakeFromNib];
}

- (void)commonInit{
    [self layoutSubviews];
    
    self.seedCellImageView.layer.cornerRadius = self.seedCellImageView.frame.size.height/2;
    self.seedCellImageView.layer.borderColor = [UIColor whiteColor].CGColor;
    self.seedCellImageView.layer.borderWidth = 1.0f;
    [self.seedCellImageView.layer setMasksToBounds:YES];

    [self.seedCellImageView setImage: [UIImage imageNamed:@"no_album_art.jpg"]];
    self.artist.text = nil;
    self.artistOrSong.text = nil;

    self.seedCellImageView.layer.rasterizationScale = [UIScreen mainScreen].scale;
    self.seedCellImageView.layer.shouldRasterize = YES;
}


- (void)changeArtistOrSongCenterConstraintConstant:(float)constant{
    self.artistOrSongCenterConstraint.constant = constant;
    [self setNeedsUpdateConstraints];
 
}

- (void)setupCellForSongSeed:(MDSeedSong*)seedSong{
    self.currentSeedId = seedSong.seedId;
    self.artistOrSong.text = seedSong.songName;
    self.artist.text = [NSString stringWithFormat:@"by %@", seedSong.artistName];


    [self changeArtistOrSongCenterConstraintConstant:-11.0f];
}
- (void)setupCellForArtistSeed:(MDSeedArtist*)seedArtist{
    self.currentSeedId = seedArtist.seedId;
    self.artistOrSong.text = seedArtist.artistName;
    [self changeArtistOrSongCenterConstraintConstant:0.0f];
}

-(void)prepareForReuse{
    [super prepareForReuse];
    self.currentSeedId = nil;
    self.seedCellImageView.image = nil;
    self.artist.text = nil;
    self.artistOrSong.text = nil;
}


- (void)setCircleImage:(UIImage* )image{
    
    [self.seedCellImageView setImage:image];
    self.seedCellImageView.layer.cornerRadius = self.seedCellImageView.frame.size.height/2;
    self.seedCellImageView.layer.borderColor = [UIColor whiteColor].CGColor;
    self.seedCellImageView.layer.borderWidth = 1.0f;
    [self.seedCellImageView.layer setMasksToBounds:YES];
}

- (void)setCircleImageFor:(UIImage*)image forSeed:(MDSeedBase*)seed{
    if ([seed.seedId isEqualToString:self.currentSeedId]) {
        [self.seedCellImageView setImage:image];
        self.seedCellImageView.layer.cornerRadius = self.seedCellImageView.frame.size.height/2;
        self.seedCellImageView.layer.borderColor = [UIColor whiteColor].CGColor;
        self.seedCellImageView.layer.borderWidth = 1.0f;
        [self.seedCellImageView.layer setMasksToBounds:YES];
    }
}


@end
