//
//  MDSearchViewController.m
//  iMercury
//
//  Created by Marino di Barbora on 2/8/16..
//  Copyright © 2016 Marino di Barbora. All rights reserved.
//
#import "MDPandoraPlayerManager.h"
#import "MDSearchViewPresentationConrtoller.h"
#import "MDSearchViewController.h"
#import "MDSearchResult.h"

@interface MDSearchViewController () <UIViewControllerTransitioningDelegate, UITableViewDataSource, UITableViewDelegate, UISearchResultsUpdating, UISearchControllerDelegate >
@property (weak, nonatomic) IBOutlet UITableView *resultTableView;
@property (nonatomic) UISearchController *songOrArtistSearchController;
@property (nonatomic) NSMutableArray *sectionsArray;
@property (nonatomic) NSMutableArray *songSearchArray;
@property (nonatomic) NSMutableArray *artistSearchArray;
@property (nonatomic) NSMutableDictionary *contenetDisctionary;
@property (nonnull) NSMutableArray * responseObjectArray;
@property (nonatomic) dispatch_queue_t concurrent_queue; 

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *tableViewBottomLayoutConstraint;

@end

@implementation MDSearchViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    
    // Do any additional setup after loading the view.
    self.songOrArtistSearchController = [[UISearchController alloc]initWithSearchResultsController:nil];
    [self.songOrArtistSearchController.searchBar sizeToFit];
    self.songOrArtistSearchController.searchBar.showsSearchResultsButton = YES;
    self.songOrArtistSearchController.searchResultsUpdater = self;
    self.songOrArtistSearchController.delegate = self;
    self.songOrArtistSearchController.dimsBackgroundDuringPresentation = NO;
    
    self.resultTableView.tableHeaderView = self.songOrArtistSearchController.searchBar;
    self.resultTableView.delegate = self;
    self.resultTableView.dataSource = self;
    self.resultTableView.backgroundColor = [UIColor clearColor];
    
    self.resultTableView.estimatedRowHeight = ceil(self.view.frame.size.height/16);
    self.resultTableView.rowHeight = UITableViewAutomaticDimension;
    
    self.definesPresentationContext = YES;
    
    self.responseObjectArray = [NSMutableArray new];
    self.concurrent_queue = dispatch_queue_create("com.blackdogsoftware.resultupdatequeue", DISPATCH_QUEUE_CONCURRENT);

   
}


- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    [self.songOrArtistSearchController setActive:YES]  ;
}
- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self addKeyboardObservers];
}

-(void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
    [self removeKeyboardObservers];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(instancetype)initWithCoder:(NSCoder *)aDecoder{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (void)commonInit{
    _songSearchArray = [NSMutableArray new];
    _artistSearchArray = [NSMutableArray new];
    _sectionsArray = [NSMutableArray new];
    _contenetDisctionary = [NSMutableDictionary new];

    self.modalPresentationStyle = UIModalPresentationCustom;
    self.transitioningDelegate = self;
    
    [[UILabel appearanceWhenContainedInInstancesOfClasses:@[[UITableViewHeaderFooterView class]]] setTextColor:[UIColor whiteColor]];
}


#pragma mark - <tableViewDelegate>
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSString *sectionKey = [self.sectionsArray objectAtIndex:section];
    NSArray *arrayForSection = [self.contenetDisctionary objectForKey:sectionKey];
    return arrayForSection.count;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
  return self.sectionsArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"SongAndArtistCell"];
    cell.textLabel.textColor = [UIColor whiteColor];
    return cell;
}

-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath{
    NSString *sectionKey = [self.sectionsArray objectAtIndex:[indexPath section]];
    NSArray *contents = [self.contenetDisctionary objectForKey:sectionKey];
    MDSearchResult *resultContent = [contents objectAtIndex:[indexPath row]];
    
    if ([sectionKey isEqualToString:@"Artists"]) {
        cell.textLabel.text = [NSString stringWithFormat:@"%@",resultContent.artistName ];
    }else{
        cell.textLabel.text = [NSString stringWithFormat:@"%@ by %@",resultContent.songName, resultContent.artistName ];
    }
    
}

-(NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
    return [self.sectionsArray objectAtIndex:section];
}

- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section
{
    view.tintColor =  [UIColor colorWithRed:220.0f/255.0f green:220.0f/255.0f blue:220.0f/255.0f alpha:0.3f];
    
}
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{

    NSString *sectionKey = [self.sectionsArray objectAtIndex:[indexPath section]];
    NSArray *contents = [self.contenetDisctionary objectForKey:sectionKey];
    MDSearchResult *resultContent = [contents objectAtIndex:[indexPath row]];
   
    if ([self.searchViewDelegate respondsToSelector:@selector(searchResultSelected:)]) {
        [self.searchViewDelegate searchResultSelected:resultContent];
    }
     
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
    
}
#pragma mark - observers
- (void)removeKeyboardObservers {
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [center removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}
- (void)addKeyboardObservers{
     NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center addObserver:self selector:@selector(keyboardWillShow:)
                             name:UIKeyboardWillShowNotification
                             object:nil];
    [center addObserver:self selector:@selector(keyboardWillHide:)
                             name:UIKeyboardWillHideNotification
                             object:nil];
    

}
- (void)keyboardWillShow:(NSNotification*)notification{
    float keyboardHeightSize = [[[notification userInfo]objectForKey:UIKeyboardFrameEndUserInfoKey]CGRectValue].size.height;
    self.tableViewBottomLayoutConstraint.constant += floorf(keyboardHeightSize *0.85);
    [self.view setNeedsUpdateConstraints];
}
- (void)keyboardWillHide:(NSNotification*)notification{
    float keyboardHeightSize = [[[notification userInfo]objectForKey:UIKeyboardFrameEndUserInfoKey]CGRectValue].size.height;
    self.tableViewBottomLayoutConstraint.constant -=  floorf(keyboardHeightSize *0.85);
    [self.view setNeedsUpdateConstraints];
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView{

    if (self.responseObjectArray.count > 0) {
       __weak typeof(self) weakSelf = self;
        dispatch_barrier_async(self.concurrent_queue, ^{
            typeof(weakSelf) strongSelf = weakSelf;
            id responseObject = [strongSelf.responseObjectArray objectAtIndex:0];
            [strongSelf.songSearchArray removeAllObjects];
            [strongSelf.artistSearchArray removeAllObjects];
            [strongSelf.sectionsArray removeAllObjects];
            [strongSelf.contenetDisctionary removeAllObjects];

            NSDictionary *res = responseObject[@"result"];
            for (NSDictionary *d in res[@"songs"]) {
                MDSearchResult *s = [[MDSearchResult alloc]initWithParam:d];
                [strongSelf.songSearchArray addObject:s];
            }
            for (NSDictionary *d in res[@"artists"]) {
                MDSearchResult *s = [[MDSearchResult alloc]initWithParam:d];
                [strongSelf.artistSearchArray addObject:s];
            }
            if (strongSelf.songSearchArray.count > 0) {
                [strongSelf.sectionsArray addObject:@"Songs"];
                [strongSelf.contenetDisctionary setObject:self.songSearchArray forKey:@"Songs"];
            }
            if (strongSelf.artistSearchArray.count > 0) {
                [strongSelf.sectionsArray addObject:@"Artists"];
                [strongSelf.contenetDisctionary setObject:self.artistSearchArray forKey:@"Artists"];
            }
            
             dispatch_async(dispatch_get_main_queue(), ^{
                 [self.resultTableView reloadData];
             });
        });
    }
}

- (void)willDismissSearchController:(UISearchController *)searchController{

    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

- (void)updateSearchResultsForSearchController:(UISearchController *)searchController{
    // we use a dispatch_barrier call on our queue to both serialize response and ensure that a reload data isn't triggered mid update.
    // Also testing for user interaction (scrolling) and effectivly suspend updates by storing the last result object for execution on scroll end

  
    NSString *t = searchController.searchBar.text;
        [[MDPandoraPlayerManager client]searchForSongOrArtist:t results:^(id  _Nullable responseObject) {
           // check if response is received after scroll began
 
            if (!self.resultTableView.tracking && !self.resultTableView.dragging && !self.resultTableView.decelerating) {
                __weak typeof(self) weakSelf = self;
                dispatch_barrier_async(self.concurrent_queue, ^{
                    typeof(weakSelf) strongSelf = weakSelf;
                    [strongSelf.songSearchArray removeAllObjects];
                    [strongSelf.artistSearchArray removeAllObjects];
                    [strongSelf.sectionsArray removeAllObjects];
                    [strongSelf.contenetDisctionary removeAllObjects];

                    NSDictionary *res = responseObject[@"result"];
                    for (NSDictionary *d in res[@"songs"]) {
                        MDSearchResult *s = [[MDSearchResult alloc]initWithParam:d];
                        [strongSelf.songSearchArray addObject:s];
                    }
                    for (NSDictionary *d in res[@"artists"]) {
                    MDSearchResult *s = [[MDSearchResult alloc]initWithParam:d];
                    [strongSelf.artistSearchArray addObject:s];
                    }
                    if (strongSelf.songSearchArray.count > 0) {
                        [strongSelf.sectionsArray addObject:@"Songs"];
                        [strongSelf.contenetDisctionary setObject:self.songSearchArray forKey:@"Songs"];
                    }
                    if (strongSelf.artistSearchArray.count > 0) {
                        [strongSelf.sectionsArray addObject:@"Artists"];
                        [strongSelf.contenetDisctionary setObject:self.artistSearchArray forKey:@"Artists"];
                    }
                    
                     dispatch_async(dispatch_get_main_queue(), ^{
                         [self.resultTableView reloadData];
                     });
                });
            }else{
                if(responseObject){
                 [self.responseObjectArray setObject:responseObject atIndexedSubscript:0];
                }
            }
        }];

}

- (void)didPresentSearchController:(UISearchController *)searchController
{
    [searchController.searchBar becomeFirstResponder];
}

#pragma mark - UIViewControllerTransitioningDelegate
-(UIPresentationController *)presentationControllerForPresentedViewController:(UIViewController *)presented presentingViewController:(UIViewController *)presenting sourceViewController:(UIViewController *)source{
    
    MDSearchViewPresentationConrtoller *presentationController = [[MDSearchViewPresentationConrtoller alloc]initWithPresentedViewController:presented presentingViewController:presenting];
    return presentationController;
}



@end
