//
//  MDStationDetailsViewController.m
//  iMercury
//
//  Created by Marino di Barbora on 2/8/16.
//  Copyright © 2016 Marino di Barbora. All rights reserved.
//

#import "MDStationDetailsViewController.h"
#import "MDStationCollectionViewController.h"
#import "MDSearchViewController.h"
#import "MDFromStationDetailTransition.h"
#import "AFImageDownloader.h"
#import "MDPandoraPlayerManager.h"
#import "MDSong.h"
#import "MDConstants.h"
#import "MDSeedSong.h"
#import "MDSeedArtist.h"
#import "MDSeedTableViewCell.h"


@interface MDStationDetailsViewController () <UINavigationControllerDelegate, UITableViewDelegate, UITableViewDataSource, searchViewProtocolDelegate>

@property (weak, nonatomic, readwrite) IBOutlet UIImageView * stationImageView;
@property (weak, nonatomic, readwrite) IBOutlet UILabel *stationNameLabel;
@property (nonatomic) UIView *backingView;
@property (weak, nonatomic) IBOutlet UIButton *loadStation;
@property (weak, nonatomic) IBOutlet UIButton *deleteStation;

- (IBAction)loadStationClick:(id)sender;
- (IBAction)deleteStationClick:(id)sender;
@property (weak, nonatomic) IBOutlet UITableView *seedTableView;
@property (weak, nonatomic) IBOutlet UISegmentedControl *seedSegmentedControl;
- (IBAction)seedSegmentedControlChanged:(id)sender;


@end

@implementation MDStationDetailsViewController



- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    
}

#pragma mark - LifeCycle

- (void)viewDidLoad{
    [super viewDidLoad];
    MDSong *currentSong = [[MDPandoraPlayerManager client]retrieveCurrentSong];
    self.stationDeleted  = NO;
  
    self.backingView  = [[UIView alloc]initWithFrame:self.view.frame];
    
    [self.view addSubview : self.backingView];
    
    
    UIBlurEffect *blurEffect  = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
    UIVisualEffectView *visualEffectView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
    visualEffectView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.25];
    
    // vibrancy
    UIVibrancyEffect *vibrancyEffect = [UIVibrancyEffect effectForBlurEffect:blurEffect];
    UIVisualEffectView *vibrancyView = [[UIVisualEffectView alloc] initWithEffect:vibrancyEffect];
    
    [visualEffectView.contentView addSubview:vibrancyView];
    
    UIImage *currentSongImage = currentSong.albumImage;
    
    [self.backingView.layer setContents:(__bridge id)currentSongImage.CGImage];
    [self.backingView insertSubview:visualEffectView atIndex:0];
    visualEffectView.frame= self.backingView.frame;


    // we want the navigation bar to be transparent
    [self.navigationController setNavigationBarHidden:FALSE animated:FALSE];
    [self.navigationController.navigationBar setBackgroundImage:[UIImage new]
                                                  forBarMetrics:UIBarMetricsDefault];
    self.navigationController.navigationBar.shadowImage = [UIImage new];
    self.navigationController.navigationBar.translucent = YES;
    
    
    [self.view layoutIfNeeded];
    self.stationImageView.layer.cornerRadius = self.stationImageView.frame.size.width/2;
    self.stationImageView.layer.borderColor = [UIColor whiteColor].CGColor;
    self.stationImageView.layer.borderWidth = 1.0f;
    self.stationImageView.clipsToBounds = YES;
    
    // button ui tweeks
    self.loadStation.layer.borderWidth = 0.6f;
    self.loadStation.layer.cornerRadius = 12.0f;
    self.loadStation.layer.borderColor = [UIColor whiteColor].CGColor;
    
    self.deleteStation.layer.borderWidth = 0.6f;
    self.deleteStation.layer.cornerRadius = 12.0f;
    self.deleteStation.layer.borderColor = [UIColor whiteColor].CGColor;
    
    //TableViewCell
    self.seedTableView.delegate = self;
    self.seedTableView.dataSource = self;
    self.seedTableView.backgroundColor = [UIColor clearColor];
    
    
    [self.seedTableView registerNib:[UINib nibWithNibName:@"SeedCell" bundle:nil] forCellReuseIdentifier:@"seedCell"];
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self trackDidChange];
    //recieve notification on song change 
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(trackDidChange) name:kMDTrackChangeNotification object:nil];

    if (self.selectedStation) {
        [self setStationImageToImage];

    }
    //set the load station button status
    if ([[MDPandoraPlayerManager client ].currentStation.stationId isEqualToString:self.selectedStation.stationId]) {
        self.loadStation.enabled = NO;
        self.loadStation.alpha = 0.5f;
    }else{
        self.loadStation.enabled = YES;
        self.loadStation.alpha = 1.0f;

    }
    
    [self.seedTableView reloadData];
}

-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter]removeObserver:self];

    if (self.navigationController.delegate == self) {
        self.navigationController.delegate = nil;
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    // Set ourself as the navigation controller's delegate so we're asked for a transitioning object
    self.navigationController.delegate = self;
}


- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    if ([segue.destinationViewController isKindOfClass:[MDSearchViewController class]]) {
        MDSearchViewController *searchview = (MDSearchViewController*)segue.destinationViewController;
        searchview.searchViewDelegate = self;
    }
}
#pragma mark - Notification

- (void)trackDidChange{
    MDSong *newSong = [[MDPandoraPlayerManager client]retrieveCurrentSong];
    if (newSong.albumImage) {
        [self.backingView.layer  setContents:(__bridge id)newSong.albumImage.CGImage];
    }else{
        [self manualLoadImageForSong:newSong];
    }
}

#pragma mark - UIStuff

- (void)manualLoadImageForSong:(MDSong*)aSong{
    AFImageDownloader *imageDownloader = [AFImageDownloader defaultInstance];
    NSURL *albumArtURL = [NSURL URLWithString:aSong.albumArtURL];

    [imageDownloader downloadImageForURLRequest:[NSURLRequest requestWithURL:albumArtURL] success:^(NSURLRequest * _Nonnull request, NSHTTPURLResponse * _Nullable response, UIImage * _Nonnull responseObject) {
        aSong.albumImage = responseObject;
        [self trackDidChange];
        
    } failure:^(NSURLRequest * _Nonnull request, NSHTTPURLResponse * _Nullable response, NSError * _Nonnull error) {
    }];
}

- (void)setStationImageToImage{
     [self.view layoutIfNeeded];
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    self.stationImageView.image = self.selectedStation.stationImage;
    [CATransaction commit];
}
#pragma mark - <tableViewDelegate>

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    
    NSArray *seedArray = [self getSeedArray]; //(self.seedSegmentedControl.selectedSegmentIndex == 0) ? [self.selectedStation getSeedArtists] :  [self.selectedStation getSeedSongs]  ;
    
    return seedArray.count;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 46.0f;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    MDSeedTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"seedCell"];
    return cell;
}

-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath{
    NSArray *seedArray = [self getSeedArray];//(self.seedSegmentedControl.selectedSegmentIndex == 0) ?  [self.selectedStation getSeedArtists] : [self.selectedStation getSeedSongs] ;
    
    MDSeedTableViewCell * seedCell = (MDSeedTableViewCell*)cell;
    if(self.seedSegmentedControl.selectedSegmentIndex == 0){
        [self  configureCell:seedCell forSeedArtist:(MDSeedArtist*)[seedArray objectAtIndex:indexPath.row]];
    }else if(self.seedSegmentedControl.selectedSegmentIndex == 1){
        [self   configureCell:seedCell forSeedSong:(MDSeedSong*)[seedArray objectAtIndex:indexPath.row]];
    }
}

- (void)configureCell:(MDSeedTableViewCell *)cell forSeedSong:(MDSeedSong *)seedSong{
    
    [cell setupCellForSongSeed:seedSong];
    [self setSeedImageForCell:cell forSeed:seedSong];
}

- (void)configureCell:(MDSeedTableViewCell *)cell forSeedArtist:(MDSeedArtist *)seedArtist{
    [cell setupCellForArtistSeed:seedArtist];
    [self setSeedImageForCell:cell forSeed:seedArtist];

}

- (void)setSeedImageForCell:(MDSeedTableViewCell*)cell forSeed:(MDSeedBase*)seed{
    AFImageDownloader *imageDownloader = [AFImageDownloader defaultInstance];
    NSURL *albumArtURL = [NSURL URLWithString:seed.artUrl];

    [imageDownloader downloadImageForURLRequest:[NSURLRequest requestWithURL:albumArtURL] success:^(NSURLRequest * _Nonnull request, NSHTTPURLResponse * _Nullable response, UIImage * _Nonnull responseObject) {
        [cell setCircleImageFor:responseObject forSeed:seed];
    } failure:^(NSURLRequest * _Nonnull request, NSHTTPURLResponse * _Nullable response, NSError * _Nonnull error) {
        
    }];
}


- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return YES if you want the specified item to be editable.
    return YES;
}

// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // deleting seed artist
        NSArray *seedArray = [self getSeedArray];
        NSUInteger seedCount = [self.selectedStation getSeedCount]; //(seedSongArray.count + seedArtistArray.count);
        if (seedCount == 1 ) {
            NSString * errorString = @"Can not delete the last seed";
            [self showErrordAlertWithMessage:errorString];
            return;
        }
        //delete Seed Artist
        if(self.seedSegmentedControl.selectedSegmentIndex == 0){
             MDSeedArtist * seedArtistToDelete = (MDSeedArtist*)[seedArray objectAtIndex:indexPath.row];
            [[MDPandoraPlayerManager client]deleteSeedSongOrArtist:(MDSeedBase*)seedArtistToDelete forStation:self.selectedStation success:^(BOOL * _Nullable success) {
                if (success) {
                    [self.seedTableView reloadData];
                }else{
                    [self showErrordAlertWithMessage:@"Error deleting Seed Artist"];
                }
            }];
        }
        // deleting seed song
        if(self.seedSegmentedControl.selectedSegmentIndex == 1){
            MDSeedSong *seedSongtoDelete = (MDSeedSong*)[seedArray objectAtIndex:indexPath.row];
            [[MDPandoraPlayerManager client]deleteSeedSongOrArtist:(MDSeedBase*)seedSongtoDelete forStation:self.selectedStation success:^(BOOL * _Nullable success) {
                if (success) {
                    [self.seedTableView reloadData];
                }else{
                    [self showErrordAlertWithMessage:@"Error deleting Seed Song"];
                }
            }];
        }
    }
}

#pragma mark - UINavigationControllerDelegate methods

- (id<UIViewControllerAnimatedTransitioning>)navigationController:(UINavigationController *)navigationController
                                  animationControllerForOperation:(UINavigationControllerOperation)operation
                                               fromViewController:(UIViewController * )fromVC
                                                 toViewController:(UIViewController * )toVC {

    if (fromVC == self && [toVC isKindOfClass:[MDStationCollectionViewController class]]) {
        return [[MDFromStationDetailTransition alloc] init];
    } else {
        return nil;
    }
}

#pragma mark - Actions

- (IBAction)loadStationClick:(id)sender {
    [[MDPandoraPlayerManager client]startListeningToStation:self.selectedStation];
    self.loadStation.enabled = NO;
    self.loadStation.alpha = 0.5f;
}

- (IBAction)deleteStationClick:(id)sender {
    self.stationDeleted = YES;
    if (self.stationDetailViewDelegate && [self.stationDetailViewDelegate respondsToSelector:@selector(stationDeleteRequestedForStation:)]) {
        [self.stationDetailViewDelegate stationDeleteRequestedForStation:self.selectedStation];
   }
}


- (IBAction)seedSegmentedControlChanged:(id)sender {
    [self.seedTableView reloadData];
}

- (void)showErrordAlertWithMessage:(NSString*)message{
    UIAlertController *errorAlert = [UIAlertController alertControllerWithTitle:@"Error" message:message  preferredStyle: UIAlertControllerStyleAlert];
    
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [errorAlert dismissViewControllerAnimated:YES completion:nil];
    }];
    
    [errorAlert addAction:okAction];
    [self presentViewController:errorAlert animated:YES completion:nil];

}



#pragma mark - <searchViewProtocolDelegate>
- (void)searchResultSelected:(MDSearchResult*)result{
  [[MDPandoraPlayerManager client]addSeedFromSearchResults:result forStation:self.selectedStation success:^(BOOL * _Nullable success) {
      [self.seedTableView reloadData];
  } failure:^(NSError * _Nullable error) {
      [self showErrordAlertWithMessage:@"There was an error adding the selected Seed" ];
  }];
}

#pragma - helper
- (NSArray*) getSeedArray{
     NSArray *seedArray = (self.seedSegmentedControl.selectedSegmentIndex == 0) ?  [self.selectedStation getSeedArtists] : [self.selectedStation getSeedSongs] ;
    return seedArray;
}
@end
