//
//  playViewController.m
//  iMercury
//
//  Created by Marino di Barbora on 2/8/16.
//  Copyright © 2016 Marino di Barbora. All rights reserved.
//
#import "AFImageDownloader.h"
#import "MDStationCollectionViewController.h"
#import "MDPandoraPlayerManager.h"
#import "MDPlayViewController.h"
#import "MDPlayProgressView.h"
#import "MDConstants.h"
#import "MDSong.h"


@import MediaPlayer;

@interface MDPlayViewController () <playerManagerProtocolDelegate, playerViewProtocolDelegate>

@property (nonatomic) UIView *backgroundImageView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *midContainerViewHeightMultiplierConstraint;
@property (nonatomic) NSLayoutConstraint *fullHeightConstraint;
@property (weak, nonatomic) IBOutlet UIView *midContainerView;
@property (weak, nonatomic) IBOutlet UILabel *songLabel;
@property (weak, nonatomic) IBOutlet UILabel *artistLabel;
@property (weak, nonatomic) IBOutlet UILabel *albumLabel;
@property (weak, nonatomic) IBOutlet UILabel *progressViewLabel;
@property (weak, nonatomic) IBOutlet MDPlayProgressView *progressView;
@property (weak, nonatomic) IBOutlet UIButton *thumbsDownButton;
@property (weak, nonatomic) IBOutlet UIButton *thumbsUpButton;
@property (weak, nonatomic) IBOutlet UIButton *playButton;
@property (weak, nonatomic) IBOutlet UIButton *nextSongButton;
@property (weak, nonatomic) IBOutlet UIButton *rewindButton;
@property (weak, nonatomic) IBOutlet UIButton *repeatButton;

@property (nonatomic, assign) BOOL updatedDiskImageAvailable;



@property (nonatomic, assign) BOOL shouldUpdateProgress;

- (IBAction)thumbDownTouch:(id)sender;
- (IBAction)thumbUpTouch:(id)sender;
- (IBAction)nextSong:(id)sender;
- (IBAction)playOrPauseSong:(id)sender;
- (IBAction)rewindSong:(id)sender;
- (IBAction)repeatSong:(id)sender;

@end

@implementation MDPlayViewController

#pragma mark - lifecycle

- (void)viewDidLoad{
    [super viewDidLoad];
    [MDPandoraPlayerManager client].playerDelegate = self;
    
    self.progressView.playerViewDelegate = self;
    self.backgroundImageView = [[UIView alloc]initWithFrame:self.view.layer.frame];
    [self.view insertSubview:self.backgroundImageView atIndex:0];
    
    UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
    UIVisualEffectView *visualEffectView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];

    // add hint of black to counter overly saturated images
    visualEffectView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.25];
    visualEffectView.bounds = self.backgroundImageView.frame;
    
    // vibrancy
    UIVibrancyEffect *vibrancyEffect = [UIVibrancyEffect effectForBlurEffect:blurEffect];
    UIVisualEffectView *vibrancyView = [[UIVisualEffectView alloc] initWithEffect:vibrancyEffect];
    [visualEffectView.contentView addSubview:vibrancyView];

    
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(firstSongDidLoad:) name:kMDReadyWithfirstSongNotification object:nil];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(trackDidChanged) name:kMDTrackChangeNotification object:nil];
    
    UIImage * blurImage = [UIImage imageNamed:@"DefaultImages" ];
    [self.backgroundImageView.layer setContents:(__bridge id)blurImage.CGImage];
    [self.backgroundImageView insertSubview:visualEffectView atIndex:0];
    visualEffectView.frame = self.backgroundImageView.frame;
    
    self.shouldUpdateProgress = YES;
    self.updatedDiskImageAvailable = NO;
    [self.progressView setDefaultVolumeLevel:[[MDPandoraPlayerManager client]getCurrentVolumeLevel]];
    
    // setup for play
    [[MDPandoraPlayerManager client] loadStationListAtFirstLaunch];

 }

- (void)dealloc{
    [[NSNotificationCenter defaultCenter]removeObserver:self];
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    // enable spectrum data
    [[MDPandoraPlayerManager client]activeAppState:YES ];
}

-(void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
    // disable spectrum data
    [[MDPandoraPlayerManager client]activeAppState:NO ];
}

#pragma mark - visual
-(void) displaySongTitleforSong:(MDSong*)s{
    // if image loaded - continue
    //else - this is the first song and images need to catchup so manually load image 
    if (s.albumImage) {
   
       [UIView animateWithDuration:0.3 animations:^{
           [self changeConstrintMultiplier:self.midContainerViewHeightMultiplierConstraint multiplier:1.0] ;
           [self.view layoutIfNeeded];
       } completion:^(BOOL finished) {
           [self.progressViewLabel setText:[NSString stringWithFormat:@"0:00/0:00"]];
           [self.songLabel setText:s.songTitle];
           [self.artistLabel setText:s.artistName];
           [self.albumLabel setText:s.albumName];
           [self setAlbumCover:s];
       }];
    }else{
        [self manuallyLoadImageForSong:s];
    }

}

- (void)changeConstrintMultiplier:(NSLayoutConstraint*) oldConstraint multiplier:(CGFloat) multiplier{
    NSLayoutConstraint *newConstraint = [NSLayoutConstraint constraintWithItem:oldConstraint.firstItem
                                                                     attribute:oldConstraint.firstAttribute
                                                                     relatedBy:oldConstraint.relation
                                                                        toItem:oldConstraint.secondItem
                                                                     attribute:oldConstraint.secondAttribute
                                                                    multiplier:multiplier
                                                                      constant:oldConstraint.constant];
    
    [self.view removeConstraint:oldConstraint];
    [self.view addConstraint: newConstraint ];
    self.midContainerViewHeightMultiplierConstraint = newConstraint;
}


- (void)animationDidComplete{
    if (self.updatedDiskImageAvailable) {
        MDSong *song = [[MDPandoraPlayerManager client]retrieveCurrentSong];
        [self.progressView switchAlbumImage:song.albumImage];
        [self.backgroundImageView.layer  setContents:(__bridge id)song.albumImage.CGImage];
        self.updatedDiskImageAvailable = NO;
    }
       [UIView animateWithDuration:0.4 animations:^{
           
           [self changeConstrintMultiplier:self.midContainerViewHeightMultiplierConstraint multiplier:0.55] ;
           [self.view layoutIfNeeded];
       } completion:^(BOOL finished) {
           self.shouldUpdateProgress = YES;
       }];
}



-(void)setAlbumCover:(MDSong*) aSong{
    if (aSong.albumImage) {
        [self.progressView setAlbumCoverImage:aSong.albumImage];
        [self.backgroundImageView.layer  setContents:(__bridge id)aSong.albumImage.CGImage];
    }else{
        if (aSong.albumImage == nil) {
            [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(songHasImageAvailable:) name:kMDSongArtworkChangedSongNotification object:aSong];
        }
        UIImage *albumImage = [UIImage imageNamed:@"DefaultImages"];
        UIImage *discImage = [UIImage imageNamed:@"no_album_art.jpg"];
        [self.progressView setAlbumCoverImage:discImage];
        [self.backgroundImageView.layer  setContents:(__bridge id)albumImage.CGImage];
    }
    [self setupFeedbackButtonStatusForSong:aSong];
}


- (void)setupFeedbackButtonStatusForSong:(MDSong*) aSong  {
    self.thumbsUpButton.selected = ([aSong.songRating integerValue] > 0) ? YES : NO;
    self.thumbsDownButton.selected = ([aSong.songRating integerValue] < 0) ? YES : NO;
}


#pragma mark - IBActions
- (IBAction)thumbUpTouch:(id)sender {
    if (![self.thumbsUpButton isSelected]) {
        [self.thumbsUpButton setSelected:YES];
          [[MDPandoraPlayerManager client]addFeedbackForCurrentSong:YES];
    }
}

- (IBAction)thumbDownTouch:(id)sender {
    if (![self.thumbsDownButton isSelected]) {
        [self.thumbsDownButton setSelected:YES];
        [[MDPandoraPlayerManager client]addFeedbackForCurrentSong:NO];
        [[MDPandoraPlayerManager client]playNextSong];
    }
    
}

- (IBAction)playOrPauseSong:(id)sender {
    [self.playButton setSelected:YES];
    [[MDPandoraPlayerManager client]playOrStop];
    [self.playButton setSelected:[MDPandoraPlayerManager client].isPlaying];
}

- (IBAction)rewindSong:(id)sender {
    [[MDPandoraPlayerManager client]rewindTrack];
}

- (IBAction)repeatSong:(id)sender {


    [[MDPandoraPlayerManager client] setShouldRepeatSong:(![self.repeatButton isSelected])];
    [self.repeatButton setSelected:!([self.repeatButton isSelected])];
}

- (IBAction)nextSong:(id)sender {
  self.shouldUpdateProgress = NO;

  [[MDPandoraPlayerManager client]playNextSong];

}

#pragma mark - callbacks/Notifications

-(void)songHasImageAvailable:(NSNotification*)info{
    self.updatedDiskImageAvailable = YES;
    MDSong *song = [info object] ;
    [[NSNotificationCenter defaultCenter]removeObserver:self name:kMDSongArtworkChangedSongNotification object:song];

}

- (void)trackDidChanged{
  [self displaySongTitleforSong:[[MDPandoraPlayerManager client]retrieveCurrentSong]];
}


- (void)firstSongDidLoad:(NSNotification*)info{
    [self displaySongTitleforSong:[[MDPandoraPlayerManager client]retrieveCurrentSong]];
}

- (void) playTimerUpdate:(CMTime)time currentSeektime:(double)currentSeekTime songDuration:(double)currentSongDuration{
    if (self.shouldUpdateProgress) {
        float progress = 0.0f;
        NSString *displayTime = [NSString stringWithFormat:@"0:00/0:00"];
        if (currentSeekTime > 0 && currentSongDuration > 0) {
            int pminutes = currentSeekTime / 60;
            int pseconds =  ((int) currentSeekTime % 60);
            int dminutes = currentSongDuration / 60;
            int dseconds = ((int)currentSongDuration % 60);
            progress = currentSeekTime / currentSongDuration;
            displayTime = [NSString stringWithFormat:@"%d:%02d/%d:%02d", pminutes, pseconds, dminutes, dseconds];
        }

        [self.progressView setSongProgress:progress updateFrequency:1.0f];
        [self.progressViewLabel setText:displayTime];
    }
}

- (void)manuallyLoadImageForSong:(MDSong*)aSong{
    AFImageDownloader *imageDownloader = [AFImageDownloader defaultInstance];
    NSURL *albumArtURL = [NSURL URLWithString:aSong.albumArtURL];
    
    [imageDownloader downloadImageForURLRequest:[NSURLRequest requestWithURL:albumArtURL] success:^(NSURLRequest * _Nonnull request, NSHTTPURLResponse * _Nullable response, UIImage * _Nonnull responseObject) {
        aSong.albumImage = responseObject;
        [self displaySongTitleforSong:aSong];
        
    } failure:^(NSURLRequest * _Nonnull request, NSHTTPURLResponse * _Nullable response, NSError * _Nonnull error) {
    }];
}

#pragma mark - playerManagerProtocolDelegate

- (void)processingSpectrumData: (NSMutableArray* _Nonnull)spectrumDataArray numberOfElementsInArray:(UInt32)numberOfElementsInArray{
    [self.progressView updateSpectrumDisplay:spectrumDataArray numberOfElements:numberOfElementsInArray];
}


#pragma mark - playerViewProtocolDelegate

- (void)finishedDiscChangeAnimation{
    [self animationDidComplete];
}

- (void)adjustedVolume:(float)toVolumeLevel {
    dispatch_async(dispatch_get_main_queue(), ^{
      [[MDPandoraPlayerManager client] setVolume:toVolumeLevel];
    });
}


- (void)didReceivedTouchOnMenu:(NSInteger)menuItem{
    if (menuItem == MDProgresViewEQ) {
         [[MDPandoraPlayerManager client]receiveSpectrumData:!([MDPandoraPlayerManager client].spectrumDataNeeded)];
      
    }else if (menuItem == MDProgressViewMenu){
        [self performSegueWithIdentifier:@"stationSegue" sender:self];
    }
    

}
@end
