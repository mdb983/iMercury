//
//  MDStationCollectionViewController.m
//  iMercury
//
//  Created by Marino di Barbora on 2/8/16..
//  Copyright © 2016 Marino di Barbora. All rights reserved.
//
#import "MDToStationDetailTransition.h"
#import "MDStationCollectionViewController.h"
#import "MDPlayViewController.h"
#import "MDPandoraPlayerManager.h"
#import "MDStationDetailsViewController.h"
#import "AFImageDownloader.h"
#import "MDStation.h"
#import "MDSong.h"
#import "MDStationViewCell.h"
#import "MDStationReusableView.h"
#import "MDConstants.h"
#import "MDSearchViewController.h"
#import "MDFromStationDetailTransition.h"



@interface MDStationCollectionViewController () <UINavigationControllerDelegate, UICollectionViewDelegateFlowLayout, searchViewProtocolDelegate, stationDetailViewProtocol, MDTransitionAnimationCompletionToVCProtocol>
@property (nonatomic) UIView *backingView;
@property (nonatomic) MDStation *selectedStation;
@property (nonatomic) MDStation *stationMarkedForDeletion ;
@end


@implementation MDStationCollectionViewController

static NSString * const reuseCellIdentifier = @"Cell";
static NSString * const reuseHeaderIdentifier = @"HeaderView";


#pragma mark - lifecycle
- (void)viewDidLoad {
    [super viewDidLoad];

    
    MDSong *currentSong = [[MDPandoraPlayerManager client]retrieveCurrentSong];

    self.backingView = [[UIView alloc]initWithFrame:self.collectionView.bounds];
    self.collectionView.backgroundView = self.backingView;

    UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
    UIVisualEffectView *visualEffectView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
    visualEffectView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.25];

    
    // vibrancy
    UIVibrancyEffect *vibrancyEffect = [UIVibrancyEffect effectForBlurEffect:blurEffect];
    UIVisualEffectView *vibrancyView = [[UIVisualEffectView alloc] initWithEffect:vibrancyEffect];
    [visualEffectView.contentView addSubview:vibrancyView];
    
    
    UIImage *currentSongImage = currentSong.albumImage;
    
    [self.backingView.layer setContents:(__bridge id)currentSongImage.CGImage];
    [self.backingView insertSubview:visualEffectView atIndex:0];
    visualEffectView.frame = self.backingView.bounds;

    // we want the navigation bar to be transparent
    [self.navigationController setNavigationBarHidden:FALSE animated:YES];
    [self.navigationController.navigationBar setBackgroundImage:[UIImage new]
                                                  forBarMetrics:UIBarMetricsDefault];
    self.navigationController.navigationBar.shadowImage = [UIImage new];
    self.navigationController.navigationBar.translucent = YES;
    


    // Register cell classes
    [self.collectionView registerClass:[MDStationViewCell class] forCellWithReuseIdentifier:reuseCellIdentifier];
    // Register Header classes
    [self.collectionView registerClass:[MDStationReusableView class] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:reuseHeaderIdentifier];
    UICollectionViewFlowLayout *layout = (UICollectionViewFlowLayout*)self.collectionView.collectionViewLayout;
    layout.sectionHeadersPinToVisibleBounds = YES;

  
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)trackDidChange{
    MDSong *newSong = [[MDPandoraPlayerManager client]retrieveCurrentSong];
    if (newSong.albumImage) {
        [self.backingView.layer  setContents:(__bridge id)newSong.albumImage.CGImage];
    }else{
        UIImage *albumImage = [UIImage imageNamed:@"DefaultImages"];
        [self.backingView.layer  setContents:(__bridge id)albumImage.CGImage];
    }
}
- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    //grab the latest song and setup the background
    [self trackDidChange];
    //recieve notification on song change
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(trackDidChange) name:kMDTrackChangeNotification object:nil];

}

- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    self.navigationController.delegate = self;

}

- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter]removeObserver:self];
    [self.navigationController setNavigationBarHidden:YES animated:YES];
    self.navigationController.navigationBar.alpha = 0;
    //resign delegate
    if (self.navigationController.delegate == self) {
        self.navigationController.delegate = nil;
    }

}

- (void)performAddStationSegue{
    [self performSegueWithIdentifier:@"addStationSegue" sender:self];
}

- (void)showErrordAlertWithMessage:(NSString*)message{
    UIAlertController *errorAlert = [UIAlertController alertControllerWithTitle:@"Error" message:message  preferredStyle: UIAlertControllerStyleAlert];
    
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [errorAlert dismissViewControllerAnimated:YES completion:nil];
    }];
    
    [errorAlert addAction:okAction];
    [self presentViewController:errorAlert animated:YES completion:nil];
    
}

#pragma mark <UICollectionViewDataSource>
-(CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath{
    return [self calculateCellSize];
}

- (CGSize)calculateCellSize{
    //we always want 2 cells
    CGRect bounds = self.backingView.frame;
    float Margin = 15.0f;
    
    float w = (bounds.size.width / 2) - 2 * Margin;
    return CGSizeMake(w,w);
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {

    return 1 ;
}


- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return   [MDPandoraPlayerManager client].stationList.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    MDStationViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:reuseCellIdentifier forIndexPath:indexPath];
    MDStation *station = [[MDPandoraPlayerManager client].stationList objectAtIndex:indexPath.item];
    cell.currentStationId = station.stationId;
 
    
    if (station.stationImage) {
        [cell setCircleImage:station.stationImage];
    }else{
        [self manuallyLoadImageForStationAtIndexPath:(NSIndexPath*)indexPath];
    }
    

    cell.title.text = station.stationName;

    return cell;
}


- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    UICollectionReusableView *reusableview = nil;
   
    if (kind == UICollectionElementKindSectionHeader) {
        MDStationReusableView *headerView = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:reuseHeaderIdentifier forIndexPath:indexPath];
        [headerView.headerButton addTarget:self action:@selector(performAddStationSegue) forControlEvents:UIControlEventTouchUpInside];
         reusableview = headerView;
    }
    return reusableview;
}


- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
    [self performSegueWithIdentifier:@"stationDetailViewSegue" sender:self];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.destinationViewController isKindOfClass:[MDStationDetailsViewController class]]) {
        MDStationDetailsViewController *toViewController = segue.destinationViewController;
        toViewController.stationDetailViewDelegate = self;
        NSIndexPath *selectedIndexPath = [[self.collectionView indexPathsForSelectedItems] firstObject];
        if (selectedIndexPath != nil) {
            
            toViewController.selectedStation = [[MDPandoraPlayerManager client].stationList objectAtIndex:selectedIndexPath.item];
        }
    }
    if ([segue.destinationViewController isKindOfClass:[MDSearchViewController class]]) {
        MDSearchViewController *toViewController = segue.destinationViewController;
        toViewController.searchViewDelegate = self;
    }
 }

- (MDStationViewCell*)collectionViewCellForStation:(MDStation*)station{
    NSUInteger stationIndex =  [[MDPandoraPlayerManager client].stationList indexOfObject:station];
    return (MDStationViewCell*)[self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForRow:stationIndex inSection:0]];
}

- (void) viewDidLayoutSubviews {
 // inset nolonger needed for ios 11
   //CGFloat top = self.topLayoutGuide.length;
   // CGFloat bottom = self.bottomLayoutGuide.length;
   // UIEdgeInsets newInsets = UIEdgeInsetsMake(top, 0, bottom, 0);
   // self.collectionView.contentInset = newInsets;
}

#pragma mark <UICollectionViewDelegate>

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section{
    return UIEdgeInsetsMake(10.0, 20.0, 10.0, 20.0);
}

#pragma mark - searchViewProtocolDelegate
- (void) searchResultSelected:(MDSearchResult*)result{
    [[MDPandoraPlayerManager client]createStationFromSearchResult:result success:^(BOOL * _Nullable success) {
        [self.collectionView reloadData];
    } failure:^(NSError * _Nullable error) {
        [self showErrordAlertWithMessage:@"There was an error adding the station"];
    }];

}

#pragma mark - stationDetailViewProtocol

- (void)stationDeleteRequestedForStation:(MDStation * _Nonnull)stationToDelete;{
    self.stationMarkedForDeletion = stationToDelete;
 }

-(void)toViewControllerActionToPerformOnAnimationCompletion{
    //called from Animated transition <MDTransitionAnimationCompletionToVCProtocol>
    if (self.stationMarkedForDeletion) {
        NSUInteger objectIndex = [[MDPandoraPlayerManager client].stationList indexOfObjectIdenticalTo:self.stationMarkedForDeletion];
        NSIndexPath *cellIPath = [NSIndexPath indexPathForItem:objectIndex inSection:0];
        MDStationViewCell *cell = (MDStationViewCell*)[self.collectionView cellForItemAtIndexPath:cellIPath];
        

        [[MDPandoraPlayerManager client]deleteStationforStation:self.stationMarkedForDeletion success:^(BOOL * _Nullable success) {
            if (*success == YES) {
             [UIView animateWithDuration:0.35f animations:^{
                 CGRect cellFrame = cell.frame;
                 cellFrame.origin.x = -200.0f;
                 cellFrame.origin.y = -200.0f;
                 cell.frame = cellFrame;

             } completion:^(BOOL finished) {
                 cell.alpha = 0.0f;
                 [self.collectionView performBatchUpdates:^{
                     [self.collectionView deleteItemsAtIndexPaths:@[cellIPath]];
                     [self.collectionView reloadData];
                     self.stationMarkedForDeletion = nil;
                 } completion:nil];
                
                 
             }];
            }
        }];
    }
}


- (void)manuallyLoadImageForStationAtIndexPath:(NSIndexPath*)iPath {
    MDStation *station = [[MDPandoraPlayerManager client].stationList objectAtIndex:iPath.item];
    AFImageDownloader *imageDownloader = [AFImageDownloader defaultInstance];
    NSURL *albumArtURL = [NSURL URLWithString:station.stationArtUrl];
    //check if the cell is visible and if it still references the same station
    
    [imageDownloader downloadImageForURLRequest:[NSURLRequest requestWithURL:albumArtURL]
                                        success:^(NSURLRequest * _Nonnull request,
                                             NSHTTPURLResponse * _Nullable response,
                                                       UIImage * _Nonnull responseObject) {
        if ([self.collectionView.indexPathsForVisibleItems containsObject:iPath]) {
            MDStationViewCell *cell = (MDStationViewCell*)[self.collectionView cellForItemAtIndexPath:iPath];
            if ([cell.currentStationId isEqualToString:station.stationId]) {
                [cell setCircleImage:responseObject ];
            }
        }
    } failure:nil];
}

#pragma mark UINavigationControllerDelegate methods

- (id<UIViewControllerAnimatedTransitioning>)navigationController:(UINavigationController *)navigationController
                                  animationControllerForOperation:(UINavigationControllerOperation)operation
                                               fromViewController:(UIViewController *)fromVC
                                                 toViewController:(UIViewController *)toVC {
    // Check if we're transitioning
    if (fromVC == self && [toVC isKindOfClass:[MDStationDetailsViewController class]]) {
        return [[MDToStationDetailTransition alloc] init];
    }
    return nil;
}

- (IBAction)exitAfterStationDelete:(UIStoryboardSegue*)unwindSegue{
    //placeholder for unwind segue

}



@end
