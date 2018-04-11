//
//  MDSearchViewController.h
//  iMercury
//
//  Created by Marino di Barbora on 2/8/16.
//  Copyright © 2016 Marino di Barbora. All rights reserved.
//



@class MDSearchResult;

@protocol searchViewProtocolDelegate;

@interface MDSearchViewController : UIViewController


@property (nonatomic, weak) id <searchViewProtocolDelegate> searchViewDelegate;

@end

@protocol searchViewProtocolDelegate <NSObject>

- (void)searchResultSelected:(MDSearchResult*)result;

@end